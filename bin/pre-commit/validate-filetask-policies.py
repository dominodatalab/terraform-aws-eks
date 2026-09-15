#!/usr/bin/env python3
"""Guard the S3 Files IAM policies against silent change.

Domino publishes these policies to customers, who apply them by hand when they run their own
Terraform. A policy that drifts from the published page is an AccessDenied in someone else's
cluster, so a change here has to be a deliberate, reviewed fixture update rather than a side effect.

Renders modules/pod-identity through `terraform plan` for the three bucket shapes whose conditionals
differ, and compares against bin/pre-commit/filetask-expected-policies.json. The mount policy in
modules/eks renders the same way: that module as a whole cannot plan offline, because it reads
aws_caller_identity and tls_certificate, but the single file holding the policy can once a harness
supplies the names it references.

Offline: aws_iam_policy_document renders locally, so this plans with fake credentials and is never
applied.

Run from the repository root:  bin/pre-commit/validate-filetask-policies.py
"""

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).parent / "filetask-expected-policies.json"
MOUNT_FIXTURE = Path(__file__).parent / "filetask-expected-mount-policy.json"
MOUNT_TF = ROOT / "modules" / "eks" / "filetask-mount-iam.tf"
KMS_KEY = "arn:{}:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab".format("aws")

# Pinned so a provider release cannot silently change the rendering this golden file compares
# against. The repo gitignores .terraform.lock.hcl, so there is no committed lockfile to copy into
# the temporary root instead. Bump deliberately, and expect the fixture to need regenerating.
PROVIDER = """
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.62.0"
    }
  }
}
"""

HARNESS = PROVIDER + """
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "harness"
  secret_key                  = "harness"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

locals {
  eks_info    = { cluster = { specs = { name = "example-cluster", account_id = "111122223333" } } }
  kms_key_arn = "%(kms)s"
}

module "prefixed" {
  source               = "%(module)s"
  region               = "us-west-2"
  eks_info             = local.eks_info
  filetask_objectstore = {
    enabled = true
    buckets = [{ name = "example-bucket", prefix = "datasets", kms_key_arn = local.kms_key_arn }]
  }
}

# No prefix and no KMS: the branch where the ListBucket condition must be absent, because a
# StringLike on the absent s3:prefix key would deny every list rather than widen it.
module "whole_bucket" {
  source               = "%(module)s"
  region               = "us-west-2"
  eks_info             = local.eks_info
  filetask_objectstore = {
    enabled = true
    buckets = [{ name = "example-bucket" }]
  }
}

# Two buckets, only the second encrypted: each Sid index must track its own bucket, and filtering
# the unencrypted one out of the KMS list must not renumber the encrypted one.
module "two_buckets" {
  source               = "%(module)s"
  region               = "us-west-2"
  eks_info             = local.eks_info
  filetask_objectstore = {
    enabled = true
    buckets = [
      { name = "plain-bucket", prefix = "one" },
      { name = "kms-bucket", prefix = "two", kms_key_arn = local.kms_key_arn },
    ]
  }
}

module "disabled" {
  source   = "%(module)s"
  region   = "us-west-2"
  eks_info = local.eks_info
}
"""

# Enabling the feature alongside an additional_pod_identity_configs entry that names the same
# ServiceAccount must fail at plan, not at apply. Deliberately mixed case: IAM does not distinguish
# names by case, so an exact comparison in the precondition would let this one through to apply.
COLLISION = PROVIDER + """
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "harness"
  secret_key                  = "harness"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

module "collision" {
  source   = "%(module)s"
  region   = "us-west-2"
  eks_info = { cluster = { specs = { name = "example-cluster", account_id = "111122223333" } } }

  filetask_objectstore = {
    enabled = true
    buckets = [{ name = "example-bucket" }]
  }

  additional_pod_identity_configs = [{
    name                = "%(name)s"
    namespace           = "%(namespace)s"
    serviceaccount_name = "%(serviceaccount)s"
    policy              = "{\\"Version\\":\\"2012-10-17\\",\\"Statement\\":[]}"
  }]
}"""

# The precondition has two independent halves, so each needs its own case: removing either one must
# fail something. The first collides only on the IAM name -- deliberately mixed case, since IAM does
# not distinguish names by case. The second collides only on the association's namespace/account
# pair, which EKS permits once.
COLLISION_CASES = [
    (
        "an IAM name differing only by case",
        {"name": "FileTask-ObjectStore", "namespace": "other-ns", "serviceaccount": "other-account"},
    ),
    (
        "the same namespace and ServiceAccount under another name",
        {
            "name": "something-else",
            "namespace": "domino-compute",
            "serviceaccount": "domino-filetask-objectstore",
        },
    ),
]

# The China partition, which is the whole point of building kms:ViaService and every ARN from the
# partition data source rather than writing amazonaws.com. Without this case the previous hardcoded
# implementation would still pass, because in the aws partition the two render identically.
CHINA = PROVIDER + """
provider "aws" {
  region                      = "cn-north-1"
  access_key                  = "harness"
  secret_key                  = "harness"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

module "china_mount" {
  source                             = "%(mount)s"
  deploy_id                          = "harness"
  filetask_objectstore_mount_enabled = true
}

module "china" {
  source   = "%(module)s"
  region   = "cn-north-1"
  eks_info = { cluster = { specs = { name = "example-cluster", account_id = "111122223333" } } }

  filetask_objectstore = {
    enabled = true
    buckets = [{
      name        = "example-bucket"
      prefix      = "datasets"
      kms_key_arn = "arn:aws-cn:kms:cn-north-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }]
  }
}
"""


# modules/eks cannot plan offline -- it reads aws_caller_identity, aws_iam_session_context and
# tls_certificate -- but the one file holding the mount policy can, once something supplies the four
# names it references. It is copied in verbatim, so nothing here parses or edits it.
MOUNT_STUB = """
variable "deploy_id" {
  type = string
}

variable "filetask_objectstore_mount_enabled" {
  type = bool
}

data "aws_partition" "current" {}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.deploy_id}-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.${data.aws_partition.current.dns_suffix}" }
      Action    = "sts:AssumeRole"
    }]
  })
}
"""

MOUNT = PROVIDER + """
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "harness"
  secret_key                  = "harness"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

module "enabled" {
  source                             = "%(mount)s"
  deploy_id                          = "harness"
  filetask_objectstore_mount_enabled = true
}

module "disabled" {
  source                             = "%(mount)s"
  deploy_id                          = "harness"
  filetask_objectstore_mount_enabled = false
}
"""


def mount_files():
    """The copied policy file plus the names it needs, keyed by path inside the harness."""
    return {
        "mount/filetask-mount-iam.tf": MOUNT_TF.read_text(),
        "mount/harness.tf": MOUNT_STUB,
    }


def terraform(workdir, *args):
    return subprocess.run(
        ["terraform", f"-chdir={workdir}", *args], capture_output=True, text=True
    )


def plan(hcl, files=None, **params):
    """Write a harness, plan it, and return (returncode, plan-json-or-None, stderr).

    `files` maps paths relative to the harness root to their contents, for a case that needs more
    than a root module. Those are written verbatim, never through the substitutions below.
    """
    work = Path(tempfile.mkdtemp(prefix="filetask-policies-"))
    try:
        substitutions = {
            "module": (ROOT / "modules" / "pod-identity").as_posix(),
            "kms": KMS_KEY,
            **params,
        }
        for relative, content in (files or {}).items():
            target = work / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
        (work / "main.tf").write_text(hcl % substitutions)
        init = terraform(work, "init", "-input=false", "-no-color")
        if init.returncode:
            return init.returncode, None, init.stderr
        result = terraform(work, "plan", "-input=false", "-no-color", "-out=tf.plan")
        if result.returncode:
            return result.returncode, None, result.stderr
        shown = terraform(work, "show", "-json", "tf.plan")
        return 0, json.loads(shown.stdout), ""
    finally:
        shutil.rmtree(work, ignore_errors=True)


def rendered_policies(plan_json):
    found = {}
    for child in plan_json["planned_values"]["root_module"].get("child_modules", []):
        name = child["address"].removeprefix("module.")
        for resource in child.get("resources", []):
            if resource["type"] == "aws_iam_policy":
                found.setdefault(name, {})[resource["name"]] = json.loads(
                    resource["values"]["policy"]
                )
    return found


def check_rendered():
    code, plan_json, err = plan(HARNESS)
    if code:
        print(f"harness failed to plan:\n{err}")
        return False

    got = rendered_policies(plan_json)
    want = json.loads(FIXTURES.read_text())
    ok = True

    if "disabled" in got:
        print(f"disabled module planned IAM policies it should not: {sorted(got['disabled'])}")
        ok = False

    for case in sorted(want):
        if got.get(case) == want[case]:
            statements = len(want[case]["filetask_objectstore"]["Statement"])
            print(f"{case}: matches fixture ({statements} statements)")
            continue
        ok = False
        print(f"{case}: DIFFERS from bin/pre-commit/filetask-expected-policies.json")
        print(f"  rendered: {json.dumps(got.get(case), sort_keys=True)[:400]}")
        print(f"  expected: {json.dumps(want[case], sort_keys=True)[:400]}")

    # Stated separately because it is the property that makes the whole design safe, and a diff
    # against a fixture would not say so out loud.
    whole = got.get("whole_bucket", {}).get("filetask_objectstore", {}).get("Statement", [])
    list_stmt = next((s for s in whole if s.get("Sid") == "ListPrefix0"), None)
    if list_stmt is None or "Condition" in list_stmt:
        print("whole-bucket ListPrefix0 must exist and carry no Condition")
        ok = False
    else:
        print("whole-bucket ListPrefix0 carries no Condition, as required")

    return ok


def check_collision_is_rejected():
    ok = True
    for description, params in COLLISION_CASES:
        code, _, err = plan(COLLISION, **params)
        if code and "filetask_objectstore is enabled" in err:
            print(f"rejected at plan, as required: {description}")
            continue
        ok = False
        print(f"NOT rejected at plan: {description}")
        if err:
            print(f"  stderr: {err[:300]}")
    return ok


def check_china_partition():
    """Every ARN and kms:ViaService must come from the partition, not a literal.

    In the aws partition dns_suffix *is* amazonaws.com, so the fixture cases above cannot tell a
    hardcoded value from a derived one. This case can.
    """
    code, plan_json, err = plan(CHINA, files=mount_files(), mount="./mount")
    if code:
        print(f"china harness failed to plan:\n{err[:400]}")
        return False

    rendered = rendered_policies(plan_json)
    policy = rendered["china"]["filetask_objectstore"]
    # The mount policy rides along here for the same reason: in the aws partition its ARN renders
    # identically whether it comes from the data source or a literal.
    policy["Statement"] = policy["Statement"] + rendered["china_mount"]["filetask_mount"]["Statement"]
    ok = True

    via = []
    for statement in policy["Statement"]:
        value = statement.get("Condition", {}).get("StringEquals", {}).get("kms:ViaService")
        if value is not None:
            via.extend([value] if isinstance(value, str) else value)

    if not via or not all(v.endswith(".amazonaws.com.cn") for v in via):
        print(f"china: kms:ViaService is not partition-aware: {via}")
        ok = False

    arns = [
        arn
        for statement in policy["Statement"]
        for arn in (
            [statement["Resource"]] if isinstance(statement["Resource"], str) else statement["Resource"]
        )
    ]
    # Every ARN must be *in* the china partition, not merely not in the aws one: a hardcoded
    # arn:aws-us-gov: or a bare * is just as wrong and would pass a check that only rejects arn:aws:.
    wrong = [arn for arn in arns if not arn.startswith("arn:aws-cn:")]
    if wrong:
        print(f"china: policy contains an ARN outside the china partition: {wrong}")
        ok = False

    if ok:
        print("china: ViaService and every ARN in both policies follow the partition, as required")
    return ok


def check_mount_policy():
    """The mount policy attaches to the node role, so an s3: action anywhere in it would be dataset
    read access for every pod that can reach instance metadata.

    Rendered, not read. Every attempt to read it as text missed a case that HCL allows, and a render
    also sees Effect, Resource and NotAction, which reading the actions list never did.
    """
    code, plan_json, err = plan(MOUNT, files=mount_files(), mount="./mount")
    if code:
        print(f"mount harness failed to plan:\n{err[:400]}")
        return False

    rendered = {}
    for child in plan_json["planned_values"]["root_module"].get("child_modules", []):
        rendered[child["address"].removeprefix("module.")] = {
            resource["name"]: json.loads(resource["values"]["policy"])
            for resource in child.get("resources", [])
            if resource["type"] == "aws_iam_policy"
        }

    ok = True
    if rendered.get("disabled"):
        print(f"mount policy planned while disabled: {sorted(rendered['disabled'])}")
        ok = False

    got = rendered.get("enabled", {})
    want = json.loads(MOUNT_FIXTURE.read_text())
    if got != want:
        ok = False
        print("mount policy DIFFERS from bin/pre-commit/filetask-expected-mount-policy.json")
        print(f"  rendered: {json.dumps(got, sort_keys=True)[:400]}")
        print(f"  expected: {json.dumps(want, sort_keys=True)[:400]}")

    # Stated separately from the fixture, because these two are the reason the policy is allowed on
    # the node role at all: a fixture diff would report them as a change like any other.
    statements = [s for policy in got.values() for s in policy.get("Statement", [])]
    inverted = [s.get("Sid") for s in statements if "NotAction" in s or "NotResource" in s]
    if inverted:
        print(f"mount policy inverts a grant, so it allows everything else: {inverted}")
        ok = False

    granted = sorted(
        {
            action
            for statement in statements
            for action in (
                [statement["Action"]]
                if isinstance(statement.get("Action"), str)
                else statement.get("Action", [])
            )
        }
    )
    # Stated as an allow-list rather than a ban on `s3:`: IAM does not match action names by case,
    # and `*` grants object access without naming a service at all.
    beyond = [
        action
        for action in granted
        if not action.lower().startswith("s3files:") or "*" in action
    ]
    if beyond:
        print(f"mount policy grants more than an S3 Files mount on the node role: {beyond}")
        ok = False

    if ok:
        print(
            f"mount policy renders {len(granted)} actions, every one a literal s3files: action, "
            "none inverted"
        )
    return ok


def main():
    if not shutil.which("terraform"):
        raise SystemExit("terraform is not on PATH")
    ok = check_rendered()
    ok &= check_china_partition()
    ok &= check_collision_is_rejected()
    ok &= check_mount_policy()
    if not ok:
        raise SystemExit(
            "S3 Files IAM policies changed. If that was deliberate, update the fixture it names "
            "-- filetask-expected-policies.json or filetask-expected-mount-policy.json, both in "
            "bin/pre-commit -- and the customer-facing IAM page together."
        )


if __name__ == "__main__":
    main()
