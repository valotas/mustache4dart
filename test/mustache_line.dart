
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart Line', () {
    var del = new Delimiter('{{', '}}');

    //test('Should throw an argument error when trying to initialize it with a space', () => expect(() => new Line(new Token(SPACE, null, del, null)), throwsArgumentError));

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
  });
}
