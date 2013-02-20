library mustache_tests;

import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  Mustache m = new Mustache();
  test('Contextless template', () => expect(m.render('Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Simple template with map context', () => expect(m.render('Hello {{name}}!', {'name': 'George'}), 'Hello George!'));
  test('Html escaped output', () => expect(m.render('Escaped: {{html}}', {'html': '!@#\$%^&*()?<>'}), 'Escaped: !@#\$%^&amp;*()?&lt;&gt;'));
  test('No html escaped with tripple brackets', () => expect(m.render('Not escaped: {{{html}}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('No html escaped with & at the beginning of a key', () => expect(m.render('Not escaped: {{& html}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('Simple non existing section', () => expect(m.render('Shown. {{#nothin}}Never shown!{{/nothin}}', {'person': true}), 'Shown. '));
  test('False value', () => expect(m.render('Shown. {{#show}}Never shown!{{/show}}', {'show': false}), 'Shown. '));
  test('Empty list', () => expect(m.render('Shown. {{#list}}Never shown!{{/list}}', {'list': []}), 'Shown. '));
  test('True value', () => expect(m.render('Shown? {{#show}}Yes it is shown!{{/show}}', {'show': true}), 'Shown? Yes it is shown!'));
  test('Simple existing section', () => expect(m.render('Shown: {{#person}}Yes, there is a person{{/person}}', {'person': true}), 'Shown: Yes, there is a person'));
  test('Existing section with list', () => expect(m.render('Persons: {{#persons}}{{name}},{{/persons}}', {'persons': [{'name': 'name1'}, {'name': 'name2'}] }), 'Persons: name1,name2,'));
  test('Inverted section', () => expect(m.render('Persons: {{#persons}}{{name}},{{/persons}}{{^persons}}none!{{/persons}}', {}), 'Persons: none!'));
  test('Simple lambda value', () => expect(m.render('{{#ff}}{{name}} is awesome{{/ff}}', {'name': 'George', 'ff': (t) => "$t!!!"}), '{{name}} is awesome!!!'));
  test('Inverted section with lambda content', () => expect(m.render('Persons: {{#persons}}{{name}},{{/persons}}{{^persons}}{{#format}}none{{/format}}{{/persons}}', {'format': (t) => "$t!!!"}), 'Persons: none!!!'));
  test('Comment test', () => expect(m.render('{{! this is a comment}}Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Comment with in a lambda', () => expect(m.render('{{#format}}{{! ignore this}}none{{/format}}', {'format': (t) => "$t!!!"}), '{{! ignore this}}none!!!'));
}