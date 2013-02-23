library mustache_specs;

import 'dart:io';
import 'dart:json';
import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  print("Running mustache specs");
  var specs_dir = new Directory('spec/specs');
  specs_dir
    .listSync()
    .forEach((f) {
      if (f.name.endsWith('.json') && !f.name.endsWith('~lambdas.json')) {
        print(f.name);
        f.readAsString(Encoding.UTF_8)
          .then((text) {
            var json = parse(text);
            var tests = json['tests'];
            tests.forEach( (t) => test(t['desc'], () => expect(render(t['template'], t['data']), t['expected'])) );
          });
      }
    });
}
