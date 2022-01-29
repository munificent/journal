default: build

build:
	@ dart packages/journal/bin/build.dart

serve:
	@ dart packages/journal/bin/build.dart --serve

# Run the tests for all of the packages.
test:
	@ cd packages/betwixt; dart test
	@ cd packages/chromatophore; dart test
	@ cd packages/minibuild; dart test
	@ cd packages/typographic_markdown; dart test

# Remove all build outputs and intermediate files.
clean:
	@ rm -rf build

.PHONY: build clean serve test
