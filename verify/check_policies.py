"""Assert the Terraform-rendered S3 Files policies match what the deployer's builders emit.

This replaces the half of `s3-files-epic-docs/check_customer_policy.py` that compared the
customer-facing page against `filetask_objectstore_policy` / `filetask_mount_policy`. Once the
policies live in Terraform those Python builders go away, and the page has to be checked against
this instead -- otherwise the move silently removes the only guard against the documented policy
drifting from the applied one.

Runs offline: aws_iam_policy_document renders locally, so the harness plans with fake credentials
and is never applied.

Usage:  python3 check_policies.py [path-to-deployer-src]
"""
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
KMS = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

# While both exist, compare against the builders. After they are deleted this argument goes and the
# expectations below become the literal source of truth.
DEPLOYER_SRC = sys.argv[1] if len(sys.argv) > 1 else (
    "/Users/muratcetin/github.com/cerebrotech/worktrees/dom-79880/platform-apps/src"
)
sys.path.insert(0, DEPLOYER_SRC)
from deployer.terraform.generators.eks import (  # noqa: E402
    filetask_mount_policy,
    filetask_objectstore_policy,
)

CASES = {
    "module.prefixed": [{"name": "example-bucket", "prefix": "datasets", "kms_key_arn": KMS}],
    "module.whole_bucket": [{"name": "example-bucket"}],
    "module.two_buckets": [
        {"name": "plain-bucket", "prefix": "one"},
        {"name": "kms-bucket", "prefix": "two", "kms_key_arn": KMS},
    ],
}


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def plan():
    out = HERE / "tf.plan"
    run("terraform", f"-chdir={HERE}", "init", "-input=false", "-no-color")
    run("terraform", f"-chdir={HERE}", "plan", "-input=false", "-no-color", f"-out={out}")
    return json.loads(run("terraform", f"-chdir={HERE}", "show", "-json", str(out)))


def policies_by_module(p):
    """{module address: {resource name: policy dict}} for every planned aws_iam_policy."""
    found = {}
    for cm in p["planned_values"]["root_module"].get("child_modules", []):
        for r in cm.get("resources", []):
            if r["type"] == "aws_iam_policy":
                found.setdefault(cm["address"], {})[r["name"]] = json.loads(r["values"]["policy"])
    return found


def norm(policy):
    """Statements as a comparable set.

    Order differs by construction -- the HCL groups by statement kind, the Python loops per bucket --
    and IAM is order-insensitive, so compare as sets. Sid is included: it is what a customer diffs
    against their own copy, so it must match even though its position need not.
    """
    out = []
    for s in policy["Statement"]:
        d = dict(s)
        for key in ("Action", "Resource"):
            if key in d:
                d[key] = sorted([d[key]] if isinstance(d[key], str) else d[key])
        out.append(json.dumps(d, sort_keys=True))
    return sorted(out)


MOUNT_TF = HERE.parent / "modules" / "eks" / "filetask-mount-iam.tf"


def check_mount_policy_text():
    """Compare the four actions declared in modules/eks against the builder.

    Not a render: see the caller. The statement is four literal strings and one resource ARN, so the
    thing worth guarding is the action list -- in particular that no `s3:` action appears, since this
    policy is attached to a role every pod reaching IMDS can assume.
    """
    src = MOUNT_TF.read_text()
    block = src[src.index("actions = ["):]
    block = block[: block.index("]")]
    actions = re.findall(r'"([^"]+)"', block)

    want = [
        a
        for s in json.loads(filetask_mount_policy())["Statement"]
        for a in ([s["Action"]] if isinstance(s["Action"], str) else s["Action"])
    ]
    if sorted(actions) != sorted(want):
        print(f"mount policy MISMATCH\n  terraform: {sorted(actions)}\n  builder  : {sorted(want)}")
        return False
    if not all(a.startswith("s3files:") for a in actions):
        print(f"mount policy grants a non-s3files action: {actions}")
        return False
    print(f"mount policy matches builder ({len(actions)} actions, none of them s3:) -- text check, not a render")
    return True


def main():
    rendered = policies_by_module(plan())
    failed = False

    for address, buckets in CASES.items():
        got = norm(rendered[address]["filetask_objectstore"])
        want = norm(json.loads(filetask_objectstore_policy(buckets)))
        if got == want:
            print(f"{address}: task policy matches builder ({len(got)} statements)")
        else:
            failed = True
            print(f"{address}: TASK POLICY MISMATCH")
            for s in got:
                if s not in want:
                    print("  only in terraform:", s[:200])
            for s in want:
                if s not in got:
                    print("  only in builder  :", s[:200])

    # The mount policy now lives in modules/eks (it lands on the node role, and making it a
    # pod-identity output while pod-identity consumes module.eks.info is a Terraform cycle --
    # verified, `Error: Cycle:`). modules/eks cannot plan offline: it reads aws_caller_identity,
    # aws_iam_role, aws_iam_session_context and tls_certificate. So this is a text-level check of a
    # static four-action statement rather than a render, and it says so.
    failed |= not check_mount_policy_text()

    # A whole-bucket ListBucket must carry no Condition at all.
    wb = rendered["module.whole_bucket"]["filetask_objectstore"]
    list_stmt = next(s for s in wb["Statement"] if s.get("Sid") == "ListPrefix0")
    if "Condition" in list_stmt:
        failed = True
        print(f"whole-bucket ListPrefix0 has a Condition it must not: {list_stmt['Condition']}")
    else:
        print("whole-bucket ListPrefix0 carries no Condition, as required")

    if "module.disabled" in rendered:
        failed = True
        print(f"disabled module planned IAM policies: {list(rendered['module.disabled'])}")
    else:
        print("disabled module plans no IAM at all, as required")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
