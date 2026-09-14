#!/usr/bin/env python3
"""Guard the S3 Files IAM policies against silent change.

Domino publishes these policies to customers, who apply them by hand when they run their own
Terraform. A policy that drifts from the published page is an AccessDenied in someone else's
cluster, so a change here has to be a deliberate, reviewed fixture update rather than a side effect.

Renders modules/pod-identity through `terraform plan` for the three bucket shapes whose conditionals
differ, and compares against bin/pre-commit/filetask-expected-policies.json. Also checks the mount
policy in modules/eks, which cannot be rendered offline because that module reads aws_caller_identity
and tls_certificate -- so that one is a text check of a static four-action statement.

Offline: aws_iam_policy_document renders locally, so this plans with fake credentials and is never
applied.

Run from the repository root:  bin/pre-commit/validate-filetask-policies.py
"""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).parent / "filetask-expected-policies.json"
MOUNT_TF = ROOT / "modules" / "eks" / "filetask-mount-iam.tf"
KMS_KEY = "arn:{}:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab".format("aws")

HARNESS = """
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
# ServiceAccount must fail at plan, not at apply.
COLLISION = """
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
    name                = "filetask-objectstore"
    namespace           = "domino-compute"
    serviceaccount_name = "domino-filetask-objectstore"
    policy              = "{\\"Version\\":\\"2012-10-17\\",\\"Statement\\":[]}"
  }]
}
"""


def terraform(workdir, *args):
    return subprocess.run(
        ["terraform", f"-chdir={workdir}", *args], capture_output=True, text=True
    )


def plan(hcl):
    """Write a harness, plan it, and return (returncode, plan-json-or-None, stderr)."""
    work = Path(tempfile.mkdtemp(prefix="filetask-policies-"))
    try:
        (work / "main.tf").write_text(
            hcl % {"module": (ROOT / "modules" / "pod-identity").as_posix(), "kms": KMS_KEY}
        )
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
    code, _, err = plan(COLLISION)
    if code and "filetask_objectstore is enabled" in err:
        print("a colliding additional_pod_identity_configs entry is rejected at plan, as required")
        return True
    print("a colliding additional_pod_identity_configs entry was NOT rejected at plan")
    if err:
        print(f"  stderr: {err[:400]}")
    return False


def check_mount_policy():
    """The mount policy attaches to the node role, so an s3: action here would be dataset read
    access for every pod that can reach instance metadata."""
    source = MOUNT_TF.read_text()
    block = source[source.index("actions = [") :]
    actions = re.findall(r'"([^"]+)"', block[: block.index("]")])

    expected = [
        "s3files:ClientMount",
        "s3files:ClientWrite",
        "s3files:ClientRootAccess",
        "s3files:GetFileSystem",
    ]
    if sorted(actions) != sorted(expected):
        print(f"mount policy actions changed\n  found: {sorted(actions)}\n  want : {sorted(expected)}")
        return False
    if not all(a.startswith("s3files:") for a in actions):
        print(f"mount policy grants a non-s3files action: {actions}")
        return False
    print(f"mount policy holds its {len(actions)} actions, none of them s3: (text check, not a render)")
    return True


def main():
    if not shutil.which("terraform"):
        raise SystemExit("terraform is not on PATH")
    ok = check_rendered()
    ok &= check_collision_is_rejected()
    ok &= check_mount_policy()
    if not ok:
        raise SystemExit(
            "S3 Files IAM policies changed. If that was deliberate, update "
            "bin/pre-commit/filetask-expected-policies.json and the customer-facing IAM page together."
        )


if __name__ == "__main__":
    main()
