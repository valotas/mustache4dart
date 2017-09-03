import "dart:async";

final int _LF = "\n".runes.first;
final int _CR = "\r".runes.first;
final int _OPEN = "{".runes.first;
final int _CLOSE = "}".runes.first;
final _CRLF = [_CR, _LF];

Stream<Token> tokenize(String input) {
  return _tokenize(new Stream.fromIterable([input]));
}

Stream<Token> _tokenize(Stream<String> chunks) {
  return chunks
      .expand((chunk) => chunk.runes)
      .transform(new _TokenizeTransformer())
      .transform(_lineMerger());
}

class _TokenizeTransformer implements StreamTransformer<int, Token> {
  Stream<Token> bind(Stream<int> input) =>
      new Stream.eventTransformed(input,
              (EventSink sink) => new _TokenizerSink(sink));
}


_lineMerger() {
  Token lastCarriageReturn = null;
  return new StreamTransformer<Token, Token>.fromHandlers(
      handleData: (final Token input, final EventSink<Token> out) {
        if (input.type != TokenType.newLine) {
          out.add(input);
          return;
        }
        if (input.codeUnits[0] == _CR) {
          lastCarriageReturn = input;
          return;
        }
        if (lastCarriageReturn != null) {
          final merged = new Token(
              TokenType.newLine, _CRLF,
              col: lastCarriageReturn.col,
              line: lastCarriageReturn.line);
          out.add(merged);
          lastCarriageReturn = null;
          return;
        }
        out.add(input);
      }
  );
}

class _TokenizerSink extends EventSink<int> {
  final EventSink<Token> _out;

  TokenType _tokenType = null;
  List<int> _buffer = [];
  int _currColumn = 1;
  int _currLine = 1;
  int _lastFlushColumn = 1;

  _TokenizerSink(this._out);

  void add(int unit) {
    if (unit == _LF || unit == _CR) {
      _addNewLine(unit);
    } else if (unit == _OPEN) {
      _addToken(TokenType.opening);
    } else if (unit == _CLOSE) {
      _addToken(TokenType.closing);
    } else {
      _addToken(TokenType.literal);
    }
    _currColumn++;
    _buffer.add(unit);
  }

  void _addNewLine(unit) {
    _flush();
    if (unit == _LF) {
      _currColumn = 0;
      _currLine++;
    }
    _tokenType = TokenType.newLine;
  }

  void _addToken(TokenType type) {
    if (_tokenType != type) {
      _flush();
    }
    _tokenType = type;
  }

  void _flush() {
    if (_tokenType == null) {
      return;
    }
    final token = new Token(
        _tokenType, _buffer, col: _lastFlushColumn, line: _currLine);
    _out.add(token);
    _lastFlushColumn = _currColumn;
    _buffer = [];
  }

  void addError(e, [st]) {
    _out.addError(e, st);
  }

  void close() {
    _flush();
    _out.close();
  }
}

class Token {
  final TokenType type;
  final List<int> codeUnits;
  final String value;
  final int col;
  final int line;

  Token(this.type, this.codeUnits, {this.col, line})
      :
        this.value = new String.fromCharCodes(codeUnits),
        this.line = codeUnits.length == 1 && codeUnits.single == _LF
            ? line - 1
            : line;
}

enum TokenType {
  literal,
  newLine,
  opening,
  closing
}