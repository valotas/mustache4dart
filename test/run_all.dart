library test.run_all;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'mustache_context_tests.dart' as mustache_context_tests;
import 'mustache_tests.dart' as mustache_tests;

main() {
  var args = new Options().arguments;
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');
  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('mustache_context_tests.dart', mustache_context_tests.main);
  addGroup('mustache_tests.dart', mustache_tests.main);
}