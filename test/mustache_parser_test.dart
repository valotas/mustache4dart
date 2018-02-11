import 'package:test/test.dart';
import 'package:mustache4dart/src/parser.dart';

void main() {
  group('tokenize', () {
    test('return literals', () async {
      final tokens = await tokenize("one!").toList();
      expect(tokens.length, 1);
      expect(tokens[0].type, TokenType.literal);
      expect(tokens[0].value, "one!");
    });

    test('return newLines', () async {
      final tokens = await tokenize("one\n").toList();
      expect(tokens.length, 2);
      expect(tokens[1].type, TokenType.newLine);
    });

    test('return \r\n as one newLine token', () async {
      final tokens = await tokenize("one\r\ntrow").toList();
      expect(tokens.length, 3);
      expect(tokens[1].type, TokenType.newLine);
    });

    test('returns expressions', () async {
      final tokens = await tokenize("one {{m}}").toList();
      expect(tokens.length, 2);
      expect(tokens[1].type, TokenType.expression);
    });

    test('accepts {{{, }}} as delimiters', () async {
      final tokens = await tokenize("one {{{m}}}").toList();
      expect(tokens.length, 2);
      expect(tokens[1].type, TokenType.expression);
    });

    test('return the right line of the token', () async {
      final tokens = await tokenize("one\ntwo\r\nthree").toList();
      expect(tokens.length, 5);
      expect(tokens[0].line, 1);
      expect(tokens[1].line, 1);
      expect(tokens[2].line, 2);
      expect(tokens[3].line, 2);
      expect(tokens[4].line, 3);
    });

    test('handles more than one line feed in a row', () async {
      final tokens = await tokenize("one\n\r\n\nthree").toList();
      expect(tokens.length, 5);
      expect(tokens[0].line, 1);
      expect(tokens[1].line, 1);
      expect(tokens[2].value, "\r\n");
      expect(tokens[2].line, 2, reason: "${tokens[2].codeUnits}, col: ${tokens[2].col}, line: ${tokens[2].line}");
      expect(tokens[3].line, 3);
      expect(tokens[4].line, 4);
    });

    test('return the column of the token', () async {
      final tokens = await tokenize("one\ntwo\r\nthree").toList();
      expect(tokens.length, 5);
      expect(tokens[0].col, 1);
      expect(tokens[1].col, 4);
      expect(tokens[2].col, 1);
      expect(tokens[3].col, 4);
      expect(tokens[4].col, 1);
    });

    test('return a literal foreach line', () async {
      final tokens = await tokenize("one\ntwo").toList();
      expect(tokens.length, 3);
      expect(tokens[0].type, TokenType.literal);
      expect(tokens[0].value, "one");
      expect(tokens[0].col, 1);
      expect(tokens[0].line, 1);
      expect(tokens[1].type, TokenType.newLine);
      expect(tokens[1].value, "\n");
      expect(tokens[1].col, 4);
      expect(tokens[1].line, 1);
      expect(tokens[2].type, TokenType.literal);
      expect(tokens[2].value, "two");
      expect(tokens[2].col, 1);
      expect(tokens[2].line, 2);
    });
  });
}
