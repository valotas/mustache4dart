library mustache_specs;

import 'dart:io';
import 'dart:json';
import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

final List<String> EXCLUDES = ['~~lambdas.json']; 

main() {
  print("Running mustache specs");
  var specs_dir = new Directory('spec/specs');
  specs_dir
    .listSync()
    .forEach((f) {
      var filename = f.name;
      if (shouldRun(filename)) {
        f.readAsString(Encoding.UTF_8)
        .then((text) {
          var json = parse(text);
          var tests = json['tests'];
          filename = filename.substring(filename.lastIndexOf('/') + 1);
          group("Specs of $filename", () {
            tests.forEach( (t) {
              var testDescription = new StringBuffer(t['name']);
              testDescription.write(': ');
              testDescription.write(t['desc']);
              var template = t['template'];
              var data = t['data'];
              var templateOnline = template.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
              testDescription.write(" When rendering '''$templateOnline''' with '$data'");
              var expected = t['expected'];
              var partials = t['partials'];
              var partial = (String name) {
                if (partials == null) {
                  return null;
                }
                return partials[name];
              };
              if (partials != null) {
                testDescription.write(" and partials: $partials");
              }
              if (data['lambda'] != null) {
                data['lambda'] = lambdas[t['name']];
              }
              test(testDescription.toString(), () => expect(render(template, data, partial), expected)); 
            });            
          });
        });
      }
    });
}

bool shouldRun(String filename) {
  // filter out only .json files
  if (!filename.endsWith('.json')) {
    return false;
  }
  String name = filename.substring(filename.lastIndexOf('/') + 1);
  // do not include the exluded test
  return !EXCLUDES.contains(name);
}

//Until we'll find a way to load a piece of code dynamically,
//we provide the lambdas at the test here
var lambdas = {
               'Interpolation' : () => 'world',
               'Interpolation - Expansion': () => '{{planet}}',
               'Interpolation - Alternate Delimiters': () => "|planet| => {{planet}}",
               'Interpolation - Multiple Calls': () => 'Not implemented', //function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }
               'Escaping': () => '>',
               'Section': (txt) => txt == "{{x}}" ? "yes" : "no",
               'Section - Expansion': (txt) => "$txt{{planet}}$txt",
               'Section - Alternate Delimiters': (txt) => "$txt{{planet}} => |planet|$txt",
               'Section - Multiple Calls': (t) {
                 var s = new StringBuffer("__$t");
                 s.write('__');
                 return s.toString();
               },
               'Inverted Section': (txt) => false
               
};
