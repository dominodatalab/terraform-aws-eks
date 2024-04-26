#!/usr/bin/env python3

from pathlib import Path
import json
from glob import glob

for bootstrap in glob("modules/iam-bootstrap/bootstrap-*.json"):
    text = json.loads(Path(bootstrap).read_text())
    if len(json.dumps(text, separators=(",", ":"))) > 6000:
        raise SystemExit(
            f"{bootstrap} is over 6k characters, make sure it's under the IAM PolicySize quota (6144)"
        )
