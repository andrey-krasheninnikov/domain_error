"""Check portable references and run their Dart programs in temporary packages."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
SKILL = ROOT / "skills/flutter-domain-errors"


def dart_program(markdown):
    blocks = re.findall(r"^```dart\n(.*?)^```[ \t]*$", markdown, re.M | re.S)
    if len(blocks) != 1:
        raise ValueError("Expected one complete Dart program per version reference")
    return blocks[0]


def check_links(root):
    for source in root.rglob("*.md"):
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", source.read_text()):
            if "://" in target or target.startswith("#"):
                continue
            resolved = (source.parent / target.split("#", 1)[0]).resolve()
            if not resolved.is_relative_to(root.resolve()) or not resolved.exists():
                raise ValueError(f"Broken or external local reference: {source.name}: {target}")


def run(command, cwd):
    result = subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False)
    if result.returncode:
        raise RuntimeError(f"Command failed: {command}\n{result.stdout}")


def check_example(version, dart):
    major = 5 if version == "current" else int(version.split(".")[0])
    program = dart_program((SKILL / f"references/v{major}.md").read_text())
    with tempfile.TemporaryDirectory(prefix="domain-error-example-") as directory:
        package = Path(directory)
        dependency = f"    path: {json.dumps(ROOT.as_posix())}" if version == "current" else f"  domain_error: {version}"
        if version == "current":
            dependency = "  domain_error:\n" + dependency
        (package / "pubspec.yaml").write_text(
            "name: domain_error_skill_example\n"
            "environment:\n  sdk: '>=3.0.0 <4.0.0'\n"
            "dependencies:\n" + dependency + "\n"
        )
        (package / "example.dart").write_text(program)
        run([dart, "pub", "get"], package)
        run([dart, "analyze", "--fatal-infos"], package)
        run([dart, "--enable-asserts", "run", "example.dart"], package)
    print(f"Passed domain_error {version}: public example and assertions", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", default="dart")
    parser.add_argument("--versions", nargs="+", default=["3.0.0", "3.1.0", "4.0.0", "current"],
                        choices=["3.0.0", "3.1.0", "4.0.0", "current"])
    args = parser.parse_args()
    check_links(SKILL)
    for major in (3, 4, 5):
        dart_program((SKILL / f"references/v{major}.md").read_text())
    for version in args.versions:
        check_example(version, args.dart)


if __name__ == "__main__":
    main()
