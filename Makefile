test:
	swift test --enable-code-coverage
	xcrun llvm-cov report \
		.build/x86_64-apple-macosx/debug/XSToolingPackageTests.xctest/Contents/MacOS/XSToolingPackageTests \
		-instr-profile=.build/x86_64-apple-macosx/debug/codecov/default.profdata \
		-ignore-filename-regex=Tests

clean:
	swift package clean
