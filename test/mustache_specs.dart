library mustache_specs;

import 'dart:io';
import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

main() {
  defineTests();
}

defineTests () {
  var specs_dir = new Directory('spec/specs');
  specs_dir
    .listSync()
    .forEach((File f) {
      var filename = f.path;
      if (shouldRun(filename)) {
        var text = f.readAsStringSync(encoding: UTF8);
        _defineGroupFromFile(filename, text);
      }
    });
}

_defineGroupFromFile(filename, text) {
  var json = JSON.decode(text);
  var tests = json['tests'];
  filename = filename.substring(filename.lastIndexOf('/') + 1);
  group("Specs of $filename", () {
    
    //Make sure that we reset the state of the Interpolation - Multiple Calls test
    //as for some reason dart can run the group more than once causing the test
    //to fail the second time it runs
    tearDown (() =>lambdas['Interpolation - Multiple Calls'].reset());
    
    tests.forEach( (t) {
      var testDescription = new StringBuffer(t['name']);
      testDescription.write(': ');
      testDescription.write(t['desc']);
      var template = t['template'];
      var data = t['data'];
      var templateOneline = template.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
      var reason = new StringBuffer("Could not render right '''$templateOneline'''");
      var expected = t['expected'];
      var partials = t['partials'];
      var partial = (String name) {
        if (partials == null) {
          return null;
        }
        return partials[name];
      };
      
      //swap the data.lambda with a dart real function
      if (data['lambda'] != null) {
        data['lambda'] = lambdas[t['name']];
      }
      reason.write(" with '$data'");
      if (partials != null) {
        reason.write(" and partial: $partials");
      }
      test(testDescription.toString(), () => expect(render(template, data, partial: partial), expected, reason: reason.toString())); 
    });            
  });
}

bool shouldRun(String filename) {
  // filter out only .json files
  if (!filename.endsWith('.json')) {
    return false;
  }
  return true;
}

//Until we'll find a way to load a piece of code dynamically,
//we provide the lambdas at the test here
class _DummyCallableWithState {
  var _callCounter = 0;
  
  call (arg, ctx) => "${++_callCounter}";
  
  reset () => _callCounter = 0; 
}

var lambdas = {
               'Interpolation' : (t, ctx) => 'world',
               'Interpolation - Expansion': (t, ctx) => '{{planet}}',
               'Interpolation - Alternate Delimiters': (t, ctx) => "|planet| => {{planet}}",
               'Interpolation - Multiple Calls': new _DummyCallableWithState(), //function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }
               'Escaping': (t, ctx) => '>',
               'Section': (txt, ctx) => txt == "{{x}}" ? "yes" : "no",
               'Section - Expansion': (txt, ctx) => "$txt{{planet}}$txt",
               'Section - Alternate Delimiters': (txt, ctx) => "$txt{{planet}} => |planet|$txt",
               'Section - Multiple Calls': (t, ctx) => "__${t}__",
               'Inverted Section': (txt, ctx) => false
               
};
