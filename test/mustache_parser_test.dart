import 'package:test/test.dart';
import 'package:mustache4dart/src/parser.dart';

void main() {
  group('simple templates', () {
    test('returns lines', () {
      final tokens = parse("one!");
      expect(tokens.length, greaterThan(0));
      expect(tokens[0].type, TokenType.Line);
    });
  });
}
