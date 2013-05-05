library mustache_tests;

import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart issues', () {    
    test('#9', () => expect(render("{{#sec}}[{{var}}]{{/sec}}", {'sec': 42}), '[]'));
    test('#11', () => expect(() => render("{{#sec}}[{{var}}]{{/somethingelse}}", {'sec': 42}), throwsFormatException));
  });
}
