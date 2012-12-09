import 'package:/unittest/unittest.dart';

part '../lib/src/tmpl.dart';
part '../lib/src/mustache.dart';

void main() {
  test('Create template', () {
    var t = new _Template('Hello {{name}}!\nMy name is {{name2}}');
    expect(t[0], new _StringToken('Hello '));
    expect(t[1], new _ExpressionToken('name'));
    expect(t[2], new _StringToken('!\nMy name is '));
    expect(t[3], new _ExpressionToken('name2'));
  });
  
  test('Contextless template', () {
    Mustache m = new Mustache();
    expect(m.render('Ένα φανταστικό template', null), 'Ένα φανταστικό template');
  });
}
