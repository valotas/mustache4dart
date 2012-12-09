part of mustache4dart;

abstract class _Token {
  
  apply(MustacheContext context);
  
  String get _val;
  
  bool operator ==(other) {
    if (other is _Token) {
     _Token st = other;
     return _val == st._val;
    }
    return false;
  }
}

class _StringToken extends _Token {
  final String _val;
  
  _StringToken(this._val);
  
  apply(context) => _val;
  
  String toString() => "StringToken($_val)";
}

class _ExpressionToken extends _Token {
  final String _val;
  
  _ExpressionToken(this._val);
  
  apply(context) => throw new Exception('Not implemented');
  
  String toString() => "ExpressionToken($_val)";
}

class _Template implements Iterable<_Token> {
  static final RegExp _EXP = new RegExp("\{\{([^\}]+)\}\}", multiLine: true);
  final List<_Token> tokens;
  
  factory _Template(String template) {
    //print(template);
    List<_Token> tokens = [];
    num lastStart = 0;
    _EXP.allMatches(template).forEach((m) {
      tokens.add(new _StringToken(template.substring(lastStart, m.start)));
      tokens.add(new _ExpressionToken(m[1]));
      lastStart = m.end;
    });
    return new _Template._internal(tokens);
  }
  
  _Template._internal(this.tokens);
  
  Iterator<_Token> iterator() => tokens.iterator();
  
  _Token operator [](int index) {
    return tokens[index];
  }
}
