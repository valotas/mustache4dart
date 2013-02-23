library mustache_specs;

import 'dart:io';
import 'dart:json';
import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

main() {
  print("Running mustache specs");
  var specs_dir = new Directory('spec/specs');
  specs_dir
    .listSync()
    .forEach((f) {
      // filter out only .json files and not the lambda tests at the moment
      if (f.name.endsWith('.json') && !f.name.endsWith('~lambdas.json')) {
        f.readAsString(Encoding.UTF_8)
          .then((text) {
            var json = parse(text);
            var tests = json['tests'];
            tests.forEach( (t) {
              var testDescription = new StringBuffer(t['name']);
              testDescription.write(': ');
              testDescription.write(t['desc']);
              var template = t['template'];
              var data = t['data'];
              testDescription.write(" When rendering '''$template''' with '$data'");
              var expected = t['expected'];
              test(testDescription.toString(), () => expect(render(template, data), expected)); 
            });
          });
      }
    });
}
