import "dart:async";

final int _lf = "\n".runes.first;
final int _cr = "\r".runes.first;
final int _open = "{".runes.first;
final int _close = "}".runes.first;
final _crlf = [_cr, _lf];

Stream<Token> tokenize(String input) {
  return _tokenize(new Stream.fromIterable([input]));
}

Stream<Token> _tokenize(Stream<String> chunks) {
  final position = new _PositionMarker();
  return chunks
      .expand((chunk) => chunk.runes)
      .transform(position.trackColumns())
      .transform(new _TokenizeTransformer(position))
      .transform(_lineMerger())
      .transform(position.trackLines());
}

class _PositionMarker {
  int column = 1;
  int line = 1;

  trackColumns() {
    return new StreamTransformer.fromHandlers(
        handleData: (final int input, final EventSink<int> out) {
          column++;
          out.add(input);
        }
    );
  }

  trackLines() {
    return new StreamTransformer.fromHandlers(
        handleData: (final Token token, final EventSink<Token> out) {
          if (token.type == TokenType.newLine) {
            line++;
            column = 1;
          }
          out.add(token);
        }
    );
  }
}

class _TokenizeTransformer implements StreamTransformer<int, Token> {
  final _PositionMarker positionMarker;

  _TokenizeTransformer(this.positionMarker);

  Stream<Token> bind(Stream<int> input) =>
      new Stream.eventTransformed(input,
              (EventSink sink) =>
          new _TokenizerSink(sink, this.positionMarker));
}


_lineMerger() {
  Token lastCarriageReturn = null;

  return new StreamTransformer<Token, Token>.fromHandlers(
      handleData: (final Token input, final EventSink<Token> out) {
        if (input.type != TokenType.newLine) {
          out.add(input);
          return;
        }
        if (input.codeUnits[0] == _cr) {
          lastCarriageReturn = input;
          return;
        }
        if (lastCarriageReturn != null) {
          final merged = new Token(
              TokenType.newLine, _crlf,
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
  final _PositionMarker _position;

  TokenType _tokenType = null;
  List<int> _buffer = [];
  List<int> _expressionBuffer = [];

  _TokenizerSink(this._out, this._position);

  void add(int unit) {
    if (unit == _lf || unit == _cr) {
      _addNewLine(unit);
    } else if (canBeExpression(unit)) {
      _expressionBuffer.add(unit);
      _addToken(TokenType.expression);
    } else {
      _addToken(TokenType.literal);
    }
    _buffer.add(unit);
  }

  bool canBeExpression(int unit) {
    return unit == _open;
  }

  void _addNewLine(unit) {
    _flush();
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
        _tokenType, _buffer, col: _position.column, line: _position.line);
    _out.add(token);
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
        this.line = codeUnits.length == 1 && codeUnits.single == _lf
            ? line - 1
            : line;
}

enum TokenType {
  literal,
  newLine,
  expression,
  openingDelimiter,
  closingDelimiter
}