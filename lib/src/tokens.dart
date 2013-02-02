part of mustache4dart;

/**
 * This is the main class describing a compiled token.
 */
abstract class _Token {
  _Token next;

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
}

/**
 * The simplest implementation of a token is the _StringToken which is any string that is not within
 * an opening and closing mustache.
 */
class _StringToken extends _Token {
  final String _val;

  _StringToken(this._val);

  apply(context) => _val;

  String toString() => "StringToken($_val)";
}

/**
 * This is a token that represends a mustache expression. That is anything between an opening and
 * closing mustache.
 */
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
    int iterations = ctx.getIterations(_val);
    if (iterations == 0) {
      _computedNext = forEachUntilEndSection(null);
      return "";
    }
    else {
      StringBuffer result = new StringBuffer("");
      print("Iterations: $iterations");
      while (iterations-- > 0) {
        _computedNext = forEachUntilEndSection((_Token t) {
          result.add(t.apply(ctx));
        });
      }
      return result;
    }
  }

  forEachUntilEndSection(void f(_Token)) {
    Iterator<_Token> it = new TokenIterator(super.next);
    while (it.moveNext()) {
      _Token n = it.current;
      if (f != null) {
        f(n);
      }
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

class TokenList extends Iterable<_Token> {
  _Token head;
  _Token tail;

  Iterator<_Token> get iterator => new TokenIterator(head);

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

