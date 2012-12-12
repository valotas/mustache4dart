import 'package:/unittest/unittest.dart';

part '../lib/src/tmpl.dart';
part '../lib/src/mustache.dart';
part '../lib/src/mustache_context.dart';

void main() {
  test('Create template', () {
    var t = new _Template('Hello {{name}}!\nMy name is {{name2}}');
    expect(t[0], new _StringToken('Hello '));
    expect(t[1], new _ExpressionToken('name'));
    expect(t[2], new _StringToken('!\nMy name is '));
    expect(t[3], new _ExpressionToken('name2'));
  });
  
  Mustache m = new Mustache();
  test('Contextless template', () => expect(m.render('Ένα φανταστικό template', null), 'Ένα φανταστικό template'));
  test('Simple template with map context', () => expect(m.render('Hello {{name}}!', {'name': 'George'}), 'Hello George!'));
  test('Html escaped output', () => expect(m.render('Escaped: {{html}}', {'html': '!@#\$%^&*()?<>'}), 'Escaped: !@#\$%^&amp;*()?&lt;&gt;'));
  test('No html escaped with tripple brackets', () => expect(m.render('Not escaped: {{{html}}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
  test('No html escaped with & at the beginning of a key', () => expect(m.render('Not escaped: {{& html}}', {'html': '!@#\$%^&*()?<>'}), 'Not escaped: !@#\$%^&*()?<>'));
}
