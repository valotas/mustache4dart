#!/bin/bash

# bail on error
set -e

dartanalyzer --fatal-warnings lib/*.dart test/*.dart

# Assert that code is formatted.
pub global activate dart_style
dirty_code=$(pub global run dart_style:format --dry-run lib/ test/ example/)
if [[ -n "$dirty_code" ]]; then
  echo Unformatted files:
  echo "$dirty_code" | sed 's/^/    /'
  exit 1
else
  echo All Dart source files are formatted.
fi

# run the tests
pub run test

# Install dart_coveralls; gather and send coverage data.
if [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --retry 2 \
    --exclude-test-files \
    --debug \
    test/mustache_all.dart
fi