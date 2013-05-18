
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart Line', () {
    var del = new Delimiter('{{', '}}');

    test('Should not accept more tokens when it is full', () {
      var l = new Line(new Token('Random text', null, del, null));
      l.add(new Token('Random text2', null, del, null));
      l.add(new Token(NL, null, del, null));
      expect(() => l.add(new Token('Some more random text', null, del, null)), throwsStateError);
    });

    test('add method should return the right line to add more stuff', () {
      var l = new Line(new Token('some text', null, del, null));
      var l2 = l.add(new Token('some more text', null, del, null));
      expect(l2, same(l));
      var nl = l.add(new Token(NL, null, del, null));
      expect(nl, isNot(same(l)));
    });

    test('Should not be standalone if it contains a string token', () {
      var l = new Line(new Token('Some text!', null, del, null));
      expect(l.standAlone, isFalse);
    });

    test("Expression tokens should be considered stand alone capable", () {
      var l = new Line(new Token(' ', null, del, null));
      l.add(new Token(' ', null, del, null));
      l.add(new Token('{{/xxx}}', null, del, null));
      expect(l.standAlone, isTrue);
    });
  });
}
