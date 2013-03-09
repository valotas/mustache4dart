library mustache_tests;

import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
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
    test('Idented rendering', () => expect(render('Yeah!\nbaby!', null, ident: '--'), 'Yeah!\n--baby!'));
  });
  
  group('Performance tests', () {
    var tmpl = '{{#a}}{{one}}{{#b}}-{{one}}{{two}}{{#c}}-{{one}}{{two}}{{three}}{{#d}}-{{one}}{{two}}{{three}}{{four}}{{/d}}{{/c}}{{/b}}{{/a}}';
    var map = {'a': {'one': 1}, 'b': {'two': 2}, 'c': {'three': 3}, 'd': {'four': 4}};
    var d = duration(100, () => render(tmpl, map));
    
    var ctmpl = compile(tmpl);
    var d2 = duration(100, () => ctmpl(map));
    
    test('Compiled templates should be at least 7 times faster', () => expect(d2 < (d/7), isTrue));
  });
}

num duration(int reps, f()) {
  var start = new DateTime.now();
  for (int i = 0; i < reps; i++) {
    f();
  }
  var end = new DateTime.now();
  return end.millisecond - start.millisecond;
}
