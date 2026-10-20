SHELL := /bin/sh

.PHONY: help deps format format-check analyze test check flutter-deps flutter-format flutter-check publish-dry-run diagrams

help:
	@echo "domain_error package commands"
	@echo ""
	@echo "  make deps"
	@echo "  make format"
	@echo "  make format-check"
	@echo "  make analyze"
	@echo "  make test"
	@echo "  make check"
	@echo "  make flutter-deps"
	@echo "  make flutter-format"
	@echo "  make flutter-check"
	@echo "  make publish-dry-run"
	@echo "  make diagrams"

deps:
	dart pub get

format:
	dart format --line-length=120 lib test example

format-check:
	dart format --line-length=120 --output=none --set-exit-if-changed lib test example

analyze:
	dart analyze --fatal-infos

test:
	dart test

check: format-check analyze test

flutter-deps:
	cd tool/flutter_consumer && flutter pub get

flutter-format:
	cd tool/flutter_consumer && dart format --line-length=120 test

flutter-check:
	cd tool/flutter_consumer && dart format --line-length=120 --output=none --set-exit-if-changed test
	cd tool/flutter_consumer && flutter analyze --no-pub --fatal-infos
	cd tool/flutter_consumer && flutter test --no-pub

publish-dry-run:
	dart pub publish --dry-run

diagrams:
	./tool/render_diagrams.sh
