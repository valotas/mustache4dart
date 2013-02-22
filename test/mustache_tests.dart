library mustache_tests;

import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  test('Contextless template', () => expect(render('Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Simple template with map context', () => expect(render('Hello {{name}}!', {'name': 'George'}), 'Hello George!'));
  test('Html escaped output', () => expect(render('Escaped: {{html}}', {'html': '!@#\$%^&*()?<>'}), 'Escaped: !@#\$%^&amp;*()?&lt;&gt;'));
  test('No html escaped with tripple brackets', () => expect(render('Not escaped: {{{html}}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('No html escaped with & at the beginning of a key', () => expect(render('Not escaped: {{& html}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('Simple non existing section', () => expect(render('Shown. {{#nothin}}Never shown!{{/nothin}}', {'person': true}), 'Shown. '));
  test('False value', () => expect(render('Shown. {{#show}}Never shown!{{/show}}', {'show': false}), 'Shown. '));
  test('Empty list', () => expect(render('Shown. {{#list}}Never shown!{{/list}}', {'list': []}), 'Shown. '));
  test('True value', () => expect(render('Shown? {{#show}}Yes it is shown!{{/show}}', {'show': true}), 'Shown? Yes it is shown!'));
  test('Simple existing section', () => expect(render('Shown: {{#person}}Yes, there is a person{{/person}}', {'person': true}), 'Shown: Yes, there is a person'));
  test('Existing section with list', () => expect(render('Persons: {{#persons}}{{name}},{{/persons}}', {'persons': [{'name': 'name1'}, {'name': 'name2'}] }), 'Persons: name1,name2,'));
  test('Inverted section', () => expect(render('Persons: {{#persons}}{{name}},{{/persons}}{{^persons}}none!{{/persons}}', {}), 'Persons: none!'));
  test('Simple lambda value', () => expect(render('{{#ff}}{{name}} is awesome{{/ff}}', {'name': 'George', 'ff': (t) => "$t!!!"}), '{{name}} is awesome!!!'));
  test('Inverted section with lambda content', () => expect(render('Persons: {{#persons}}{{name}},{{/persons}}{{^persons}}{{#format}}none{{/format}}{{/persons}}', {'format': (t) => "$t!!!"}), 'Persons: none!!!'));
  test('Simple comment', () => expect(render('{{! this is a comment}}Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Comment with in a lambda', () => expect(render('{{#format}}{{! ignore this}}none{{/format}}', {'format': (t) => "$t!!!"}), '{{! ignore this}}none!!!'));
  
  var salutTemplate = 'Hi {{name}}{{^name}}customer{{/name}}';
  var salut = compile(salutTemplate);
  test('Compiled function with existing context', () => expect(salut({'name': 'George'}), 'Hi George'));
  test('Compiled function with non existing context', () => expect(salut({}), 'Hi customer'));
  test('Compiled function with existing context same with render', () => expect(salut({'name': 'George'}), render(salutTemplate, {'name': 'George'})));
  test('Compiled function with non existing context same with render', () => expect(salut({}), render(salutTemplate, {})));
    

  test('Contextless one letter template', () => expect(render('!', null), '!'));
  test('Template with string context after closing one', () => expect(render('{{^x}}No x{{/x}}!!!', null), 'No x!!!'));
}