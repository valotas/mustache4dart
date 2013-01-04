part of mustache4dart;

class TokenList extends Iterable<_Token> {
  _Token head;
  _Token tail;
  
  Iterator<_Token> iterator() => new TokenIterator(head);
  
  void add(_Token other) {
    if (head == null) {
      head = other;
      tail = other;
    }
    else {
      tail.next = other;
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

class TokenIterator implements Iterator<_Token> {
  _Token start;
  _Token current;
  
  TokenIterator(this.start);
  
  bool get hasNext => start != null || (current != null && current.next != null);

  _Token next() {
    if (current == null && start != null) {
      current = start;
      start = null;
    }
    else {
      current = current.next;
    }
    return current;
  }
}

abstract class _Token {
  _Token next;
  
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
    if (escapeHtml && val.startsWith('& ')) {
      escapeHtml = false;
      val = val.substring(2);
    }
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
  _Token _computedNext;
  
  _StartSectionToken(String val) : super.simple(val);
  
  //Override the next getter
  _Token get next => _computedNext != null ? _computedNext : super.next;
  
  apply(MustacheContext ctx) {
    _computedNext = ctx.hasValue(_val) ? null : findEndSectionToken();
    return "";
  }
  
  _Token findEndSectionToken() {
    Iterator<_Token> it = new TokenIterator(super.next);
    while (it.hasNext) {
      _Token n = it.next();
      if (n._val == _val) {
        return n;
      }
    }
    return null;
  }
  
  String toString() => "StartSectionToken($_val)";
}

class _EndSectionToken extends _ExpressionToken {
  _EndSectionToken(String val) : super.simple(val);
  
  apply(MustacheContext ctx) {
    return "";
  }
  
  _Token get next {
    _Token n = super.next;
    return n == null ? null : n.next;
  }
  
  String toString() => "EndSectionToken($_val)";
}
