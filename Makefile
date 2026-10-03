.PHONY: clean test test-linux lint format

clean:
	swift package clean

# MARK: - test

test:
	swift test --enable-code-coverage
	./.github/scripts/codecov.sh $(shell swift test --show-codecov-path)

CONTAINER ?= container

test-linux:
	$(CONTAINER) run --rm -t --init -v "$(PWD):/src" -w /src swift:latest swift test --traits EnableSubprocess

# MARK: - format

lint:
	xcrun swift-format lint --recursive --strict ./

format:
	xcrun swift-format --recursive --in-place ./
