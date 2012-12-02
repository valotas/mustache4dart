import 'package:/unittest/unittest.dart';

part '../lib/src/tmpl.dart';

void main() {
  test('create_template', () => 
      expect(['Hello ', '{{name}}', '!\nMy name is ', '{{name2}}'], new _Template('Hello {{name}}!\nMy name is {{name2}}').tokens));
  //test('simple_render', () => 
  //    expect('Hello George!', Mustache.render('Hello {{name}}! My name is {{name2}}', {'name': 'George'})));
}