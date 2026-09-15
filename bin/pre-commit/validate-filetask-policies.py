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


def terraform(workdir, *args):
    return subprocess.run(
        ["terraform", f"-chdir={workdir}", *args], capture_output=True, text=True
    )


def plan(hcl, **params):
    """Write a harness, plan it, and return (returncode, plan-json-or-None, stderr)."""
    work = Path(tempfile.mkdtemp(prefix="filetask-policies-"))
    try:
        substitutions = {
            "module": (ROOT / "modules" / "pod-identity").as_posix(),
            "kms": KMS_KEY,
            **params,
        }
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
    code, plan_json, err = plan(CHINA)
    if code:
        print(f"china harness failed to plan:\n{err[:400]}")
        return False

    policy = rendered_policies(plan_json)["china"]["filetask_objectstore"]
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
    if any(arn.startswith("arn:aws:") for arn in arns):
        print(f"china: policy contains an aws-partition ARN: {[a for a in arns if a.startswith('arn:aws:')]}")
        ok = False

    if ok:
        print("china: ViaService and every ARN follow the partition, as required")
    return ok


def blank_comments(source):
    """Replace HCL comments with spaces, leaving strings and offsets intact.

    Regexes cannot do this: a `#` inside an action string is not a comment, and a `]` inside a
    comment is not the end of a list. Both of those were live bypasses before this existed, so the
    scanner tracks which of the two it is in rather than guessing.
    """
    out = []
    index = 0
    while index < len(source):
        character = source[index]
        if character == '"':
            end = index + 1
            while end < len(source):
                if source[end] == "\\":
                    end += 2
                    continue
                if source[end] == '"':
                    end += 1
                    break
                end += 1
            out.append(source[index:end])
            index = end
        elif source.startswith("/*", index):
            end = source.find("*/", index + 2)
            end = len(source) if end == -1 else end + 2
            out.append(" " * (end - index))
            index = end
        elif source.startswith("//", index) or character == "#":
            end = source.find("\n", index)
            end = len(source) if end == -1 else end
            out.append(" " * (end - index))
            index = end
        else:
            out.append(character)
            index += 1
    return "".join(out)


def list_body(source, open_bracket):
    """The text between `[` and its matching `]`, or None if unterminated.

    Depth-aware and string-aware so a bracket inside either cannot close the list early.
    """
    depth = 0
    index = open_bracket
    while index < len(source):
        character = source[index]
        if character == '"':
            index += 1
            while index < len(source):
                if source[index] == "\\":
                    index += 2
                    continue
                if source[index] == '"':
                    break
                index += 1
        elif character == "[":
            depth += 1
        elif character == "]":
            depth -= 1
            if depth == 0:
                return source[open_bracket + 1 : index]
        index += 1
    return None


def literal_strings(body):
    """The quoted strings in a list body, or None if it holds anything else.

    `["a", "b", local.extra]` reads as two actions unless the leftovers are checked. Expects a body
    whose comments are already blanked, so what survives removing the strings must be commas and
    whitespace.
    """
    if re.search(r"[^\s,]", re.sub(r'"(?:[^"\\]|\\.)*"', "", body)):
        return None
    return re.findall(r'"((?:[^"\\]|\\.)*)"', body)


def check_parser():
    """Run the scanner against the inputs that have fooled it before.

    Three rounds of review found a different hole in this parsing, each time in a case nobody had
    written down. These are those cases, checked on every run so a fourth cannot be introduced
    quietly. They cost nothing: no files, no terraform.
    """
    cases = [
        # A bracket inside a comment must not end the list, or a computed element after it hides.
        ('["a", "b", # ]\n local.extra]', None),
        # Quoted text inside a comment is not an action, and must not be reported as one.
        ('# "s3:GetObject" is forbidden\n "a", "b"', ["a", "b"]),
        (' "a", "b", ', ["a", "b"]),
        (' "a", /* note */ "b" ', ["a", "b"]),
        (' "a", local.extra ', None),
        # A `#` inside a string is part of the action, not the start of a comment.
        (' "a#b" ', ["a#b"]),
    ]
    ok = True
    for body, expected in cases:
        actual = literal_strings(blank_comments(body))
        if actual != expected:
            print(f"parser self-check failed on {body!r}: expected {expected}, got {actual}")
            ok = False
    if ok:
        print(f"parser self-check: {len(cases)} known-tricky inputs read correctly")
    return ok


def check_mount_policy():
    """The mount policy attaches to the node role, so an s3: action anywhere in it would be dataset
    read access for every pod that can reach instance metadata.

    Every actions list in the file, not just the first: a second statement granting s3: would
    otherwise go unnoticed and defeat exactly the invariant this exists to hold. Text rather than a
    render because modules/eks reads aws_caller_identity and tls_certificate, so it cannot plan
    offline.
    """
    # Everything below reads the comment-free view, so a commented-out declaration is not mistaken
    # for a real one and a bracket inside a comment cannot end a list early.
    source = blank_comments(MOUNT_TF.read_text())

    # not_actions inverts the grant -- everything *except* those -- so it can never be right here,
    # and reading it as if it were an allow-list would report the opposite of the truth.
    if re.search(r"\bnot_actions\s*=", source):
        print("mount policy uses not_actions, which inverts the grant; refusing to guess at it")
        return False

    actions = []
    found = 0
    for assignment in re.finditer(r"\bactions\s*=\s*", source):
        found += 1
        if not source[assignment.end() :].startswith("["):
            print(
                "mount policy computes an actions value rather than listing it, so reading the file "
                "cannot tell what it grants -- inline it, or render the policy instead."
            )
            return False
        body = list_body(source, assignment.end())
        parsed = None if body is None else literal_strings(body)
        if parsed is None:
            print(
                "mount policy has an actions list this cannot read as plain strings -- inline it, "
                f"or render the policy instead: [{(body or '').strip()}]"
            )
            return False
        actions.extend(parsed)

    if not found:
        print("mount policy declares no actions at all")
        return False

    expected = [
        "s3files:ClientMount",
        "s3files:ClientWrite",
        "s3files:ClientRootAccess",
        "s3files:GetFileSystem",
    ]
    if sorted(actions) != sorted(expected):
        print(f"mount policy actions changed\n  found: {sorted(actions)}\n  want : {sorted(expected)}")
        return False
    print(
        f"mount policy holds its {len(actions)} actions across {found} statement(s), "
        "none of them s3: (text check, not a render)"
    )
    return True


def main():
    if not shutil.which("terraform"):
        raise SystemExit("terraform is not on PATH")
    ok = check_parser()
    ok &= check_rendered()
    ok &= check_china_partition()
    ok &= check_collision_is_rejected()
    ok &= check_mount_policy()
    if not ok:
        raise SystemExit(
            "S3 Files IAM policies changed. If that was deliberate, update "
            "bin/pre-commit/filetask-expected-policies.json and the customer-facing IAM page together."
        )


if __name__ == "__main__":
    main()
