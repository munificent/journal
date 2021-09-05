# Remove all build outputs and intermediate files.
clean:
	@ rm -rf build

# Generate test coverage report.
# Requires lcov package for genhtml: brew install lcov.
coverage:
	@ dart test --coverage=build/coverage
	@ dart run coverage:format_coverage --lcov --in=build/coverage \
			--out=build/coverage.lcov --packages=.packages --report-on=lib
	@ genhtml build/coverage.lcov -o build/report
	@ echo "Coverage report at build/report/index.html."

.PHONY: clean coverage
