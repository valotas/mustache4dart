import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'mustache_context_tests.dart' as mustache_context_tests;
import 'mustache_tests.dart' as mustache_tests;
import 'mustache_specs.dart' as specs;

main() {
  mustache_context_tests.main();
  mustache_tests.main();
  specs.main();
}