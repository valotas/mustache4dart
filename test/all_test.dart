import 'package:unittest/vm_config.dart';
import 'mustache_context_tests.dart' as mustache_context_tests;
import 'mustache_tests.dart' as mustache_tests;
import 'mustache_specs.dart' as specs;
import 'mustache_issues.dart' as issues;

main() {
  useVMConfiguration();
  mustache_context_tests.defineTests();
  mustache_tests.defineTests();
  specs.defineTests();
  issues.defineTests();
}
