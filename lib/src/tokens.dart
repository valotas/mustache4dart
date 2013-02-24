part of mustache4dart;

/**
 * This is the main class describing a compiled token.
 */

abstract class _Token { 
  final String _source;
  _Token next;
  bool rendable = true;
  
  _Token.withSource(this._source);
 
  factory _Token(String token) {
    if (token == '' || token == null) {
      return null;
    }
    if (token.startsWith('{{{')) {
      return new _ExpressionToken(token.substring(3, token.length - 3), false, token);
    } 
    else if (token.startsWith('{{')) {
      return new _ExpressionToken(token.substring(2, token.length - 2), true, token);
    }
    else if (token == ' ' || token == '\n' || token == '\r\n') {
      return new _SpecialCharToken(token);
    }
    else {
      return new _StringToken(token);
    }
  }
  
  StringBuffer apply(MustacheContext context);

  /**
   * This describes the value of the token.
   */
  String get _val;

  /**
   * Two tokens are the same if their _val are the same.
   */
  bool operator ==(other) {
    if (other is _Token) {
     _Token st = other;
     return _val == st._val;
    }
    return false;
  }
  
  int get hashCode => _val.hashCode;
}

/**
 * The simplest implementation of a token is the _StringToken which is any string that is not within
 * an opening and closing mustache.
 */
class _StringToken extends _Token {

  _StringToken(_val) : super.withSource(_val);
  
  apply(context) => _val;
  
  String get _val => _source;

  String toString() => "StringToken($_val)";
}

class _SpecialCharToken extends _StringToken {
  _SpecialCharToken(_val) : super(_val);
  
  apply(context) {
    if (_val == '\n' || _val =='\r\n' || _val == '') {
      _markNextStandAloneLineIfAny();      
    }
    return super.apply(context);
  }
  
  _markNextStandAloneLineIfAny() {
    var n = next;
    if (n == null) {
      return;
    }
    int nextSectionsMarked = 0;
    while (n != null && n._val != '\n' && n._val != '\r\n') { //find the next endline
      if (n._val == ' ' || n is _StartSectionToken || n is _EndSectionToken) {
        n.rendable = false;
        nextSectionsMarked++;
        n = n.next;
      }
      else {
        _resetNext(nextSectionsMarked);
        return;
      }
    }
    if (nextSectionsMarked > 0 && n != null) {
      n.rendable = false;
    }
  }

  _resetNext(int counter) {
    var n = next;
    while (counter -- >= 0) {
      n.rendable = true;
      n = n.next;
    }
  }
  
  String toString() {
    var val = _val.replaceAll('\r', '\\r').replaceAll('\n', '\\n');
    return "SpecialCharToken($val)";
  }
}

/**
 * This is a token that represends a mustache expression. That is anything between an opening and
 * closing mustache.
 */
class _ExpressionToken extends _Token {
  final String _val;

  factory _ExpressionToken(String val, bool escapeHtml, String source) {
    val = val.trim();
    if (escapeHtml && val.startsWith('&')) {
      escapeHtml = false;
      val = val.substring(1).trim();
    }
    if (!escapeHtml) {
      return new _ExpressionToken.withSource(val, source);
    }

    String control = val.substring(0, 1);
    String newVal = val.substring(1).trim();

    if ('#' == control) {
      return new _StartSectionToken.withSource(newVal, source);
    } else if ('/' == control) {
      return new _EndSectionToken.withSource(newVal, source);
    } else if ('^' == control) {
      return new _InvertedSectionToken.withSource(newVal, source);
    } else if ('!' == control) {
      return new _CommentToken.withSource(newVal, source);
    } else {
      return new _EscapeHtmlToken.withSource(val, source);
    }
  }

  _ExpressionToken.withSource(this._val, source) : super.withSource(source);
  
  apply(MustacheContext ctx) {
    var val = ctx[_val];
    if (val == null) {
      return '';
    }
    return val;
  }
  
  String toString() => "ExpressionToken($_val)";
}

class _CommentToken extends _ExpressionToken {
  _Token _computedNext;
  
  _CommentToken.withSource(String val, String source) : super.withSource(val, source);
  
  apply(MustacheContext ctx) {
    _Token n = super.next;
    if (n != null && n._source == '\n') {
      _computedNext = n.next;
    }
    return '';
  }
  
  _Token get next => _computedNext != null ? _computedNext : super.next;
}

class _EscapeHtmlToken extends _ExpressionToken {
  _EscapeHtmlToken.withSource(String val, String source) : super.withSource(val, source);

  apply(MustacheContext ctx) {
    var val = super.apply(ctx);
    if (val is String) {
      return val.replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll('"', "&quot;")
          .replaceAll("'", "&apos;");
    }
    else {
      return val;
    }
  }
  
  String toString() => "EscapeHtmlToken($_val)";
}

class _StartSectionToken extends _ExpressionToken {
  _Token _computedNext;

  _StartSectionToken.withSource(String val, String source) : super.withSource(val, source);

  //Override the next getter
  _Token get next => _computedNext != null ? _computedNext : super.next;

  apply(MustacheContext ctx) {
    var val = ctx[_val];
    if (val == null) {
      _computedNext = forEachUntilEndSection(null);
      return '';
    }
    if (val == true) {
      return '';
    }
    if (val is MustacheFunction) {
      StringBuffer str = new StringBuffer();
      _computedNext = forEachUntilEndSection((_Token t) => str.write(t._source));
      return val.apply(str.toString());
    }
    if (val is MustacheContext) {
      StringBuffer str = new StringBuffer();
      _computedNext = forEachUntilEndSection((_Token t) => str.write(t.apply(val)));
      return str;
    }
    if (val is Iterable) {
      StringBuffer result = new StringBuffer();

      val.forEach((v) {
        _computedNext = forEachUntilEndSection((_Token t) => result.write(t.apply(v)));
      });
      return result;
    }
  }

  forEachUntilEndSection(void f(_Token)) {
    Iterator<_Token> it = new TokenIterator(super.next);
    int counter = 1;
    while (it.moveNext()) {
      _Token n = it.current;
      if (n._val == _val) {
        if (n is _StartSectionToken) {
          counter++;
        }
        if (n is _EndSectionToken) {
          counter--;
        }
        if (counter == 0) {
          return n;          
        }
      }
      if (f != null) {
        f(n);
      }
    }
    return null;
  }
  
  String toString() => "StartSectionToken($_val)";
}

class _EndSectionToken extends _ExpressionToken {
  _EndSectionToken.withSource(String val, String source) : super.withSource(val, source);

  apply(MustacheContext ctx) {
    return "";
  }
  
  String toString() => "EndSectionToken($_val)";
}

class _InvertedSectionToken extends _StartSectionToken {
  _InvertedSectionToken.withSource(String val, String source) : super.withSource(val, source);
  
  apply(MustacheContext ctx) {
    var val = ctx[_val];
    if (val == null) {
      StringBuffer buf = new StringBuffer();
      _computedNext = forEachUntilEndSection((_Token t) {
        var val2 = t.apply(ctx);
        buf.write(val2);
      });
      return buf.toString();
    }
    //else just return an empty string
    _computedNext = forEachUntilEndSection(null);
    return '';
  }
}

class TokenList extends Iterable<_Token> {
  _Token head;
  _Token tail;

  Iterator<_Token> get iterator => new TokenIterator(head);

  void add(_Token other) {
    if (other == null) {
      return;
    }
    if (head == null) {
      //Our template should start as an empty string token
      head = new _SpecialCharToken('');
      tail = head;
    }
    tail.next = other;
    tail = other;
  }

  String toString() {
    StringBuffer str = new StringBuffer("TokenList(");
    if (head == null) {
      //Do not display anything
    }
    else if (head == tail) {
      str.write(head);
    }
    else {
      str.write("$head...$tail");
    }
    str.write(")");
    return str.toString();
  }
}

class TokenIterator implements Iterator<_Token> {
  _Token start;
  _Token current;

  TokenIterator(this.start);

  bool moveNext() {
    if (current == null && start != null) {
      current = start;
      start = null;
    }
    else {
      current = current.next;
    }
    return current != null;
  }
}

