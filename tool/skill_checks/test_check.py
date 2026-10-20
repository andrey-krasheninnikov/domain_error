"""Regression checks for extracting and locating the maintained examples."""

from pathlib import Path
import tempfile
import unittest

from check import check_links, dart_program


class ReferenceChecks(unittest.TestCase):
    def test_extracts_only_the_complete_program(self):
        self.assertEqual(dart_program("Text\n```dart\nvoid main() {}\n```\n"), "void main() {}\n")
        for text in ("No program", "```dart\nvoid main() {}", "```dart\na\n```\n```dart\nb\n```\n"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                dart_program(text)

    def test_links_cannot_escape_the_installed_skill(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "skill"
            root.mkdir()
            outside = Path(directory) / "outside.md"
            outside.write_text("Existing file outside the skill")
            (root / "SKILL.md").write_text("[escape](../outside.md)")
            with self.assertRaises(ValueError):
                check_links(root)

    def test_missing_local_reference_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            entry = root / "SKILL.md"
            entry.write_text("[contract](contract.md#capture) [external](https://example.org)")
            with self.assertRaises(ValueError):
                check_links(root)
            (root / "contract.md").write_text("# Capture")
            check_links(root)


if __name__ == "__main__":
    unittest.main()
