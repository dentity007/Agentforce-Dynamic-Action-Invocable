#!/usr/bin/env python3
"""Deploy generated code artifacts to Salesforce using sfdx."""
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

CLASS_META_TEMPLATE = """<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<ApexClass xmlns=\"http://soap.sforce.com/2006/04/metadata\">\n    <apiVersion>64.0</apiVersion>\n    <status>Active</status>\n</ApexClass>\n"""

def write_artifacts(artifacts: dict, target_dir: Path) -> None:
    classes_dir = target_dir / "classes"
    classes_dir.mkdir(parents=True, exist_ok=True)

    written = set()

    def write_class(entry: dict) -> None:
        name = entry.get("name")
        content = entry.get("content")
        if not name or not content:
            return
        class_path = classes_dir / f"{name}.cls"
        class_path.write_text(content)
        meta_path = classes_dir / f"{name}.cls-meta.xml"
        if name not in written:
            meta_path.write_text(CLASS_META_TEMPLATE)
        written.add(name)

    for entry in artifacts.get("apex", []):
        write_class(entry)
    for entry in artifacts.get("tests", []):
        write_class(entry)

    metadata_path = target_dir / "artifacts-metadata.json"
    metadata_path.write_text(json.dumps(artifacts.get("metadata", {}), indent=2))


def run_command(cmd: list, cwd: Path) -> subprocess.CompletedProcess:
    result = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    output = result.stdout.strip()
    error = result.stderr.strip()
    if output:
        print(output)
    if error:
        print(error, file=sys.stderr)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Deploy generated Apex artifacts")
    parser.add_argument("json_file", help="Path to JSON file containing PlanModels.CodeArtifacts")
    parser.add_argument("--run-tests", action="store_true", help="Execute local tests after deployment")
    parser.add_argument("--wait", type=int, default=30, help="Minutes to wait for test run when --run-tests is set")
    args = parser.parse_args()

    json_path = Path(args.json_file).expanduser().resolve()
    if not json_path.exists():
        print(f"Artifact file not found: {json_path}", file=sys.stderr)
        return 1

    with json_path.open() as fh:
        artifacts = json.load(fh)

    with tempfile.TemporaryDirectory() as tmp_dir:
        src_root = Path(tmp_dir) / "force-app" / "main" / "default"
        write_artifacts(artifacts, src_root)

        deploy_cmd = [
            "sfdx",
            "force:source:deploy",
            "--sourcepath",
            str(src_root),
            "--json"
        ]
        deploy_result = run_command(deploy_cmd, Path(tmp_dir))
        if deploy_result.returncode != 0:
            return deploy_result.returncode

        if args.run_tests:
            test_cmd = [
                "sfdx",
                "force:apex:test:run",
                "-l",
                "RunLocalTests",
                "--wait",
                str(args.wait),
                "--resultformat",
                "human"
            ]
            test_result = run_command(test_cmd, Path(tmp_dir))
            if test_result.returncode != 0:
                return test_result.returncode

    return 0


if __name__ == "__main__":
    sys.exit(main())
