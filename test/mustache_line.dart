
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart Line', () {
    var del = new Delimiter('{{', '}}');
    test('Should start with a new line token', () => expect(() => new Line(new Token(SPACE, null, del, null)), throwsException));
  });
}
