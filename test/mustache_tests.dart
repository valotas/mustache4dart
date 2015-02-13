library mustache_tests;

import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  defineTests();
}

class A {
  String name;
  A(this.name);
}

void defineTests() {
  group('mustache4dart tests', () {    
    var salutTemplate = 'Hi {{name}}{{^name}}customer{{/name}}';
    var salut = compile(salutTemplate);
    test('Compiled function with existing context', () => expect(salut({'name': 'George'}), 'Hi George'));
    test('Compiled function with non existing context', () => expect(salut({}), 'Hi customer'));
    test('Compiled function with existing context same with render', () => expect(salut({'name': 'George'}), render(salutTemplate, {'name': 'George'})));
    test('Compiled function with non existing context same with render', () => expect(salut({}), render(salutTemplate, {})));
    
    test('Contextless one letter template', () => expect(render('!', null), '!'));
    test('Template with string context after closing one', () => expect(render('{{^x}}No x{{/x}}!!!', null), 'No x!!!'));
    
    var map = {'a': {'one': 1}, 'b': {'two': 2}, 'c': {'three': 3}};
    test('Simple context test', () => expect(render('{{#a}}{{one}}{{/a}}', map), '1'));
    test('Deeper context test', () => expect(render('{{#a}}{{one}}{{#b}}-{{one}}{{two}}{{#c}}-{{one}}{{two}}{{three}}{{/c}}{{/b}}{{/a}}', map), '1-12-123'));
    test('Idented rendering', () => expect(render('Yeah!\nbaby!', null, ident: '--'), '--Yeah!\n--baby!'));
    test('Standalone without new line', () => expect(render('#{{#a}}\n/\n  {{/a}}', map), '#\n/\n'));
    test('Should render emtpy lines', () => expect(render('{{#a}}\n{{one}}\n{{/a}}\n\n{{b.two}}\n', map), '1\n\n2\n'));
  });
  
  group('Performance tests', () {
    test('Compiled templates should be at least 2 times faster', () {
      var tmpl = '{{#a}}{{one}}{{#b}}-{{one}}{{two}}{{#c}}-{{one}}{{two}}{{three}}{{#d}}-{{one}}{{two}}{{three}}{{four}}{{#e}}{{one}}{{two}}{{three}}{{four}}{{/e}}{{/d}}{{/c}}{{/b}}{{/a}}';
      StringBuffer buf = new StringBuffer(tmpl);
      for (int i = 0; i < 10; i++) {
        buf.write('dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd');
        buf.write(tmpl);
      }
      tmpl = buf.toString();
      
      var map = {'a': {'one': 1}, 
                 'b': {'two': 2}, 
                 'c': {'three': 3}, 
                 'd': {'four': 4}, 
                 'e': false};
      var ctmpl = compile(tmpl);
      
      var warmup = duration(100, () => "${ctmpl(map)}--${render(tmpl, map)}");
      print("Warmup rendering of template with length ${tmpl.length} took ${warmup}millis");
      
      var d = duration(100, () => render(tmpl, map));
      print("100 iterations of uncompiled rendering took ${d}millis");
      
      var d2 = duration(100, () => ctmpl(map));
      print("100 iterations of compiled rendering tool ${d2}millis");
      expect(d2 < (d/2), isTrue);
    });
  });

  group('mustache4dart enhancements', () {
    test('Throw exception on unknown tag', () {
      try {
        render('Hi {{name}}', {'namee': 'George'});
      } catch (e) {
        expect(e, "Could not find 'name' property in {namee: George}}");
      }
    });
    
    test('Throw exception on unknown start tag', () {
      try {
        render('Hi {{#name}}man!{{/name}}', {'namee': 'George'});
      } catch (e) {
        expect(e, "Could not find 'name' property in {namee: George}}");
      }
    });
    
    test('Provide lambdas with the current nested context when they have two parameters (#39)', () {
      var context = { 
        'map': {
          'things': [ new A('a'), new A('b') ]  
        },
        'lambda': (String s, ctx) => "[" + render(s, ctx) + "]"
      };
      var  template = '''
{{#map.things}}
{{#lambda}}{{name}}{{/lambda}}|
{{/map.things}}
''';
      expect(render(template, context), "[a]|\n[b]|\n");
    });
  });
}

num duration(int reps, f()) {
  var start = new DateTime.now();
  for (int i = 0; i < reps; i++) {
    f();
  }
  var end = new DateTime.now();
  return end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
}
