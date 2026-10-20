"""Regression checks for the README extraction and navigation boundary."""

from pathlib import Path
import tempfile
import unittest

from check import check_links, dart_programs


class ReadmeChecks(unittest.TestCase):
    def test_extracts_exact_programs_and_ignores_other_fences(self):
        text = "```sh\n# false heading\n```\n```dart\nvoid main() {}\n```\n```dart\nvoid main() { assert(true); }\n```\n"
        self.assertEqual(dart_programs(text), ["void main() {}\n", "void main() { assert(true); }\n"])

    def test_missing_empty_and_unclosed_programs_fail(self):
        for text in ("No program", "```dart\n```\n", "```dart\nvoid main() {}\n"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                dart_programs(text)

    def test_missing_local_target_and_heading_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                check_links("[missing](absent.md)", root)
            (root / "guide.md").write_text("# Guide\n\n## Capture results\n")
            check_links("[guide](guide.md#capture-results)", root)
            with self.assertRaises(ValueError):
                check_links("[missing heading](guide.md#unknown)", root)

    def test_navigation_uses_real_headings_not_code(self):
        text = "# Guide\n\n## Handle `Result`\n\n```dart\n# fake\n```\n"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            check_links(text + "[real](#handle-result)", root)
            with self.assertRaises(ValueError):
                check_links(text + "[fake](#fake)", root)

    def test_image_alt_text_and_repository_boundaries(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "project"
            root.mkdir()
            (root / "cover.png").write_bytes(b"image")
            (root.parent / "outside.md").write_text("Existing file outside the checkout")
            check_links("![Cover](cover.png)", root)
            for text in ("![](cover.png)", "[outside](../outside.md)", "![missing](absent.png)"):
                with self.subTest(text=text), self.assertRaises(ValueError):
                    check_links(text, root)


if __name__ == "__main__":
    unittest.main()
