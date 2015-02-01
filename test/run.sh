#!/bin/bash

# bail on error
set -e

# TODO(sigmund): replace with a real test runner
DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

# Note: dart_analyzer needs to be run from the root directory for proper path
# canonicalization.
pushd $DIR/..
#echo Analyzing library for warnings or type errors
dartanalyzer --fatal-warnings lib/*.dart \
  || echo -e "Ignoring analyzer errors"
#pd
dart --enable-type-checks --enable-asserts test/all_test.dart $@
