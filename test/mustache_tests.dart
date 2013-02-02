import 'package:/unittest/unittest.dart';

part '../lib/src/tmpl.dart';
part '../lib/src/tokens.dart';
part '../lib/src/mustache.dart';
part '../lib/src/mustache_context.dart';

void main() {
  Mustache m = new Mustache();
  test('Contextless template', () => expect(m.render('Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Simple template with map context', () => expect(m.render('Hello {{name}}!', {'name': 'George'}), 'Hello George!'));
  test('Html escaped output', () => expect(m.render('Escaped: {{html}}', {'html': '!@#\$%^&*()?<>'}), 'Escaped: !@#\$%^&amp;*()?&lt;&gt;'));
  test('No html escaped with tripple brackets', () => expect(m.render('Not escaped: {{{html}}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('No html escaped with & at the beginning of a key', () => expect(m.render('Not escaped: {{& html}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('Simple non existing section', () => expect(m.render('Shown. {{#nothin}}Never shown!{{/nothin}}', {'person': true}), 'Shown. '));  
  test('Simple existing section', () => expect(m.render('Shown: {{#person}}Yes, there is a person{{/person}}', {'person': true}), 'Shown: Yes, there is a person'));
  test('Existing section with list', () => expect(m.render('Persons: {{#persons}}{{name}},{{/persons}}', {'persons': [{'name': 'name1'}, {'name': 'name2'}] }), 'Persons: name1,name2,'));
}