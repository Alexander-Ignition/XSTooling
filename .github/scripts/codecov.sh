#!/usr/bin/env bash

# Usage:
#    ./.github/scripts/codecov.sh $(swift test --show-codecov-path)

set -eu

# /Users/<user-name>/<package-name>/.build/<platform>/debug/codecov/<package-name>.json
CODECOV_PATH=$1
CODECOV_DIR=$(dirname "$CODECOV_PATH")
PACKAGE_NAME=$(basename "$CODECOV_PATH" .json)

# /Users/<user-name>/<package-name>/.build/<platform>/debug/codecov/default.profdata
PROFDATA_PATH="$CODECOV_DIR/default.profdata"

# /Users/<user-name>/<package-name>/.build/<platform>/debug/XSToolingPackageTests.xctest/Contents/MacOS/XSToolingPackageTests
EXCUTABLE_PATH="$(dirname "$CODECOV_DIR")/${PACKAGE_NAME}PackageTests.xctest/Contents/MacOS/${PACKAGE_NAME}PackageTests"

echo '```'

xcrun llvm-cov report \
    "$EXCUTABLE_PATH" \
    --instr-profile="$PROFDATA_PATH" \
    --ignore-filename-regex=".build|Tests"

echo '```'
