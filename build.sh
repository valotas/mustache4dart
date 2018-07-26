#!/bin/bash

# bail on error
set -e

echo "Analyzing with `dartanalyzer --version`"
dartanalyzer --fatal-warnings lib/*.dart test/*.dart

pub deps

# run the tests
pub run test

# Only run with the dev (v2) version of dart.
if [ "$TRAVIS_DART_VERSION" = "dev" ]; then
  dartfmt -n --set-exit-if-changed

  # Install dart_coveralls; gather and send coverage data.
  if [ "$COVERALLS_TOKEN" ]; then
    pub global activate dart_coveralls
    pub global run dart_coveralls report \
      --retry 2 \
      --exclude-test-files \
      test/mustache_all.dart
  fi

  # TODO: re-enable browser tests - at least the ones not needing mirrors
  # pub run test -p chrome,firefox
fi
