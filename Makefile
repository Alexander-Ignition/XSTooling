.PHONY: clean test lint format

test:
	swift test --enable-code-coverage
	./.github/scripts/codecov.sh $(shell swift test --show-codecov-path)

clean:
	swift package clean

# MARK: - format

lint:
	xcrun swift-format lint --recursive --strict ./

format:
	xcrun swift-format --recursive --in-place ./
