import "dart:async";

final int _LF = "\n".runes.first;
final int _CR = "\r".runes.first;
final int _OPEN = "{".runes.first;
final int _CLOSE = "}".runes.first;

Stream<Token> tokenize(String input) {
  return _tokenize(new Stream.fromIterable([input]));
}

Stream<Token> _tokenize(Stream<String> chunks) {
  return chunks
      .expand((chunk) => chunk.runes)
      .transform(new _TokenizeTransformer());
}

enum TokenType {
  Literal,
  NewLine,
  Open,
  Close
}

class Token {
  final TokenType type;
  final List<int> codeUnits;
  final String value;
  final int col;
  final int line;

  Token(this.type, this.codeUnits, {this.col, line}) :
        this.value = new String.fromCharCodes(codeUnits),
        this.line = type == TokenType.NewLine ? line - 1 : line;
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
      _addToken(TokenType.Open);
    } else if (unit == _CLOSE) {
      _addToken(TokenType.Close);
    } else {
      _addToken(TokenType.Literal);
    }
    _currColumn++;
    _buffer.add(unit);
  }

  void _addNewLine(unit) {
    if (unit == _LF) {
      _flush();
      _currLine++;
    }
    _currColumn = 0;
    _tokenType = TokenType.NewLine;
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
    _out.add(new Token(_tokenType, _buffer, col: _lastFlushColumn, line: _currLine));
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

class _TokenizeTransformer implements StreamTransformer<int, Token> {
  Stream<Token> bind(Stream<int> input) =>
      new Stream.eventTransformed(input,
              (EventSink sink) => new _TokenizerSink(sink));
}