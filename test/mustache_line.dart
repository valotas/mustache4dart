
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart Line', () {
    var del = new Delimiter('{{', '}}');

    newToken (String s) => new Token(s, null, del, null);

    test('Should not accept more tokens when it is full', () {
      var l = new Line(newToken('Random text'));
      l.add(newToken('Random text2'));
      l.add(newToken(NL));
      expect(() => l.add(newToken('Some more random text')), throwsStateError);
    });

    test('add method should return the right line to add more stuff', () {
      var l = new Line(newToken('some text'));
      var l2 = l.add(newToken('some more text'));
      expect(l2, same(l));
      var nl = l.add(newToken(NL));
      expect(nl, isNot(same(l)));
    });

    test('Should not be standalone if it contains a string token', () {
      var l = new Line(newToken('Some text!'));
      expect(l.standAlone, isFalse);
    });

    test("Expression tokens should be considered stand alone capable", () {
      var l = new Line(newToken(' '));
      l.add(newToken(' '));
      l.add(newToken('{{/xxx}}'));
      expect(l.standAlone, isTrue);
    });

    test("Last line with an expression only should be considered standalone", () {
      var l = new Line(newToken(' '));
      l = l.add(newToken(NL))
        .add(newToken(' '))
        .add(newToken(' '))
        .add(newToken('{{/ending}}'));

      expect(l.standAlone, isTrue);
    });

    test("Last line should not end with a new line", () {
      var l = new Line(newToken('#'))
        .add(newToken('{{#a}}'));
      var l2 = l.add(newToken(NL))
        .add(newToken('/'));
      var l3 = l2.add(newToken(NL))
        .add(newToken(' '))
        .add(newToken(' '));

      expect(l2, isNot(same(l)));
      expect(l3, isNot(same(l2)));
      expect(l.standAlone, isFalse);
      expect(l2.standAlone, isFalse);
      expect(l3.standAlone, isTrue);
    });

  });
}
