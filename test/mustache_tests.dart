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
}