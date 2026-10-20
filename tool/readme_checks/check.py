"""Check README navigation and run its exact Dart programs against this checkout."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[2]


def markdown_parts(markdown):
    blocks, prose, body = [], [], []
    language = None
    for line in markdown.splitlines(keepends=True):
        marker = re.fullmatch(r"```([^`\s]*)[ \t]*\n?", line)
        if marker:
            if language is None:
                language = marker[1]
            elif not marker[1]:
                blocks.append((language, "".join(body)))
                language, body = None, []
            else:
                raise ValueError("Nested code fence")
        elif language is None:
            prose.append(line)
        else:
            body.append(line)
    if language is not None:
        raise ValueError("Unclosed code fence")
    return blocks, "".join(prose)


def dart_programs(markdown):
    programs = [body for language, body in markdown_parts(markdown)[0] if language == "dart"]
    if not programs or any(not program.strip() for program in programs):
        raise ValueError("Expected non-empty standalone Dart programs")
    return programs


def heading_ids(markdown):
    counts, anchors = {}, set()
    for heading in re.findall(r"^#{1,6} +(.+?) *#* *$", markdown_parts(markdown)[1], re.M):
        slug = re.sub(r"[^\w -]", "", heading.lower()).replace(" ", "-")
        count = counts.get(slug, 0)
        anchors.add(f"{slug}-{count}" if count else slug)
        counts[slug] = count + 1
    return anchors


def check_links(markdown, root):
    prose = markdown_parts(markdown)[1]
    for image, label, target in re.findall(r"(!?)\[([^\]]*)\]\(([^)\s]+)\)", prose):
        if image and not label.strip():
            raise ValueError(f"Image needs alt text: {target}")
        url = urlsplit(target)
        if url.scheme in ("http", "https", "mailto"):
            continue
        if url.scheme or url.netloc:
            raise ValueError(f"Unsupported local reference: {target}")
        if url.path:
            path = (root / unquote(url.path)).resolve()
            if not path.is_relative_to(root.resolve()) or not path.exists():
                raise ValueError(f"Broken or external local reference: {target}")
            content = path.read_text() if path.suffix == ".md" else None
        else:
            content = markdown
        if url.fragment and (content is None or unquote(url.fragment) not in heading_ids(content)):
            raise ValueError(f"Missing heading: {target}")


def run(command, cwd):
    result = subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False)
    if result.returncode:
        raise RuntimeError(f"Command failed: {command}\n{result.stdout}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", default="dart")
    args = parser.parse_args()
    markdown = (ROOT / "README.md").read_text()
    check_links(markdown, ROOT)
    programs = dart_programs(markdown)
    with tempfile.TemporaryDirectory(prefix="domain-error-readme-") as directory:
        package = Path(directory)
        (package / "pubspec.yaml").write_text(
            "name: domain_error_readme\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\n"
            "dependencies:\n  domain_error:\n    path: " + json.dumps(ROOT.as_posix()) + "\n"
        )
        for index, program in enumerate(programs, 1):
            (package / f"example_{index}.dart").write_text(program)
        run([args.dart, "pub", "get"], package)
        run([args.dart, "analyze", "--fatal-infos"], package)
        run([args.dart, "format", "--line-length=120", "--output=none",
             "--set-exit-if-changed", "."], package)
        for index in range(1, len(programs) + 1):
            run([args.dart, "--enable-asserts", "run", f"example_{index}.dart"], package)
    print(f"Passed README: {len(programs)} exact Dart programs, local links and anchors", flush=True)


if __name__ == "__main__":
    main()
