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

  factory _ExpressionToken(String val, bool escapeHtml) {
    if (escapeHtml && val.startsWith('& ')) {
      escapeHtml = false;
      val = val.substring(2);
    }
    if (escapeHtml) {
      return new _EscapeHtmlToken(val);
    }
    else {
      return new _ExpressionToken.simple(val); 
    }
  }
  
  _ExpressionToken.simple(this._val);
  
  apply(MustacheContext ctx) => ctx.getValue(_val);
  
  String toString() => "ExpressionToken($_val)";
}

class _EscapeHtmlToken extends _ExpressionToken { 
  _EscapeHtmlToken(String val) : super.simple(val);
  
  apply(MustacheContext ctx) => super.apply(ctx)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&apos;");
  
  String toString() => "EscapeHtml($_val)";
}
