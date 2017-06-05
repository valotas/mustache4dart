#!/bin/bash

# bail on error
set -e

echo "Analyzing with `dartanalyzer --version`"
dartanalyzer --strong --fatal-warnings lib/*.dart test/*.dart

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
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --retry 2 \
    --exclude-test-files \
    test/mustache_all.dart
fi

which google-chrome
which firefox
pub run test test/mustache_context_test.dart -p chrome,firefox