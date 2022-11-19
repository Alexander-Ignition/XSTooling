test:
	# swift test --enable-code-coverage
	./.github/scripts/codecov.sh $(shell swift test --show-codecov-path)

clean:
	swift package clean
