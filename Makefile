default: build

build:
	@ dart packages/journal/bin/build.dart

serve:
	@ dart packages/journal/bin/build.dart --serve

# Remove all build outputs and intermediate files.
clean:
	@ rm -rf build

.PHONY: build clean serve
