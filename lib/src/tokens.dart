part of mustache4dart;

class TokenList extends Iterable<_Token> {
  _Token head;
  _Token tail;
  
  Iterator<_Token> iterator() => new TokenListIterator(head);
  
  void add(_Token other) {
    if (head == null) {
      head = other;
      tail = other;
    }
    else {
      tail._next = other;
      tail = other;      
    }
  }
  
  String toString() {
    StringBuffer str = new StringBuffer("TokenList(");
    if (head == null) {
      //Do not display anything
    }
    else if (head == tail) {
      str.add("$head");
    }
    else {
      str.add("$head...$tail");
    }
    str.add(")");
    return str.toString();
  }
}

class TokenListIterator implements Iterator<_Token> {
  _Token current;
  
  TokenListIterator(this.current);
  
  bool get hasNext => current != null;

  _Token next() {
    if (current == null) {
     return null; 
    }
    _Token next = current._next;
    _Token result = current;
    current = next;
    return result;
  }
}

abstract class _Token {
  _Token _next;
  
  StringBuffer apply(MustacheContext context);
  
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
    //print("1> $val, $escapeHtml");
    if (escapeHtml && val.startsWith('& ')) {
      escapeHtml = false;
      val = val.substring(2);
    }
    //print("2> $val, $escapeHtml");
    if (!escapeHtml) {
      return new _ExpressionToken.simple(val);
    }
    
    String control = val.substring(0, 1);
    String newVal = val.substring(1);
    
    if ('#' == control) {
      return new _StartSectionToken(newVal); 
    } else if ('/' == control) {
      return new _EndSectionToken(newVal);
    } else {
      return new _EscapeHtmlToken(val);
    }
  }
  
  _ExpressionToken.simple(this._val);
  
  apply(MustacheContext ctx) {
    var val = ctx.getValue(_val);
    if (val == null) {
      return '';
    }
    return val;
  }
  
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
  
  String toString() => "EscapeHtmlToken($_val)";
}

class _StartSectionToken extends _ExpressionToken {
  _StartSectionToken(String val) : super.simple(val);
  
  String toString() => "StartSectionToken($_val)";
}

class _EndSectionToken extends _ExpressionToken {
  _EndSectionToken(String val) : super.simple(val);
  
  String toString() => "EndSectionToken($_val)";
}
