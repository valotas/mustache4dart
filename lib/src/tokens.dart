part of mustache4dart;

/**
 * This is the main class describing a compiled token.
 */

abstract class _Token { 
  final String _source;

  _Token _next;
  _Token prev;
  bool rendable = true;
  
  _Token.withSource(this._source);
 
  factory _Token(String token, Function partial, Delimiter d, String ident) {
    if (token == EMPTY_STRING || token == null) {
      return null;
    }
    if (token.startsWith('{{{') && d.opening == '{{') {
      return new _ExpressionToken(token.substring(3, token.length - 3), false, token, partial, d);
    } 
    else if (token.startsWith(d.opening)) {
      return new _ExpressionToken(token.substring(d.openingLength, token.length - d.closingLength), true, token, partial, d);
    }
    else if (token == SPACE || token == NL || token == CRNL) {
      return new _SpecialCharToken(token, ident);
    }
    else {
      return new _StringToken(token);
    }
  }
  
  String render(MustacheContext context, [StringBuffer buf]) {
    var string = apply(context);
    if (buf == null) {
      buf = new StringBuffer();
    }
    if (rendable) {
      buf.write(string);
    }
    if (next != null) {
      next.render(context, buf);
    }
    return buf.toString();
  }
  
  StringBuffer apply(MustacheContext context);

  /**
   * This describes the value of the token.
   */
  String get name;
  
  void set next (_Token n) {
    _next = n;
    n.prev = this;
  }
  
  _Token get next => _next;
  
  /**
   * Two tokens are the same if their _val are the same.
   */
  bool operator ==(other) {
    if (other is _Token) {
     _Token st = other;
     return name == st.name;
    }
    if (other is String) {
      return name == other;
    }
    return false;
  }  
  
  int get hashCode => name.hashCode;
}

abstract class _StandAloneLineCapable {
  
}

/**
 * The simplest implementation of a token is the _StringToken which is any string that is not within
 * an opening and closing mustache.
 */
class _StringToken extends _Token {

  _StringToken(_val) : super.withSource(_val);
  
  apply(context) => name;
  
  String get name => _source;

  String toString() => "StringToken($name)";
}

class _SpecialCharToken extends _StringToken {
  final String ident;
  
  _SpecialCharToken(_val, [this.ident = EMPTY_STRING]) : super(_val);
  
  apply(context) {
    if (_isNewLineOrEmpty) {
      _markNextStandAloneLineIfAny();      
    }
    if (!rendable) {
      return EMPTY_STRING;
    }
    
    if (next == null) {
      return super.apply(context);
    }
    if (_isNewLine) {
      return "${super.apply(context)}$ident";
    }
    return super.apply(context);
  }
  
  _markNextStandAloneLineIfAny() {
    var n = next;
    if (n == null) {
      return;
    }
    int tokensMarked = 0;
    bool foundSection = false;
    while (n != null && n.name != NL && n.name != CRNL) { //find the next endline
      if ((n.name == SPACE && !foundSection) 
          || n is _StandAloneLineCapable) {
        n.rendable = false;
        tokensMarked++;
        n = n.next;
        foundSection = n is _StartSectionToken || n is _EndSectionToken;
      }
      else {
        _resetNext(tokensMarked);
        return;
      }
      
    }
    if (tokensMarked > 0 && n != null) {
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
  
  bool get _isNewLineOrEmpty => _isNewLine || name == EMPTY_STRING;
  
  bool get _isNewLine => name == NL || name == CRNL; 
  
  String toString() {
    var val = name.replaceAll('\r', '\\r').replaceAll(NL, '\\n');
    return "SpecialCharToken($val)";
  }
}

/**
 * This is a token that represends a mustache expression. That is anything between an opening and
 * closing mustache.
 */
class _ExpressionToken extends _Token {
  final String name;

  factory _ExpressionToken(String val, bool escapeHtml, String source, Function partial, Delimiter delimiter) {
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
      return new _StartSectionToken(newVal, delimiter);
    } else if ('/' == control) {
      return new _EndSectionToken(newVal);
    } else if ('^' == control) {
      return new _InvertedSectionToken(newVal, delimiter);
    } else if ('!' == control) {
      return new _CommentToken();
    } else if ('>' == control) {
      return new _PartialToken(partial, newVal);
    } else if ('=' == control) {
      return new _DelimiterToken(newVal);
    } else {
      return new _EscapeHtmlToken(val, source);
    }
  }

  _ExpressionToken.withSource(this.name, source) : super.withSource(source);
  
  apply(MustacheContext ctx) {
    var val = ctx[name];
    if (val == null) {
      return EMPTY_STRING;
    }
    if (val is Function) {
      //A lambda's return value should be parsed
      return render(val(null), ctx);
    }
    return val;
  }
  
  String toString() => "ExpressionToken($name)";
}

class _DelimiterToken extends _ExpressionToken implements _StandAloneLineCapable {
  
  _DelimiterToken(String val) : super.withSource(val, null);
  
  apply(MustacheContext ctx) => EMPTY_STRING;
  
  bool get rendable => false;
  
  Delimiter get newDelimiter {
    List delimiters = name
        .substring(0, name.length - 1)
        .split(SPACE);
    return new Delimiter(delimiters[0], delimiters[1]);
  }
}

class _PartialToken extends _ExpressionToken {
  final Function partial;
  _PartialToken(this.partial, String val) : super.withSource(val, null);
  
  apply(MustacheContext ctx) {
    if (_standAlone) {
      next.rendable = false;
    }
    if (partial != null) {
      return render(partial(name), ctx, partial: partial, ident: _ident);      
    }
    return EMPTY_STRING;
  }
  
  bool get _standAlone {
    if (next == null) {
      return false;
    }
    if (next == NL || next == CRNL) {
      _Token p = prev;
      while (p != CRNL && p != NL) {
        if (p == EMPTY_STRING) {
          return true;
        }
        if (p != SPACE) {
          return false;
        }
        p = p.prev;
      }
      return true;
    }
    else {
      return false;
    }
  }
  
  String get _ident {
    StringBuffer ident = new StringBuffer();
    _Token p = this.prev;
    while (p.name == SPACE) {
      ident.write(SPACE);
      p = p.prev;
    }
    if (p.name == NL || p.name == EMPTY_STRING) {
      return ident.toString();      
    }
    else {
      return EMPTY_STRING;
    }
  }
  
  bool get rendable => true;
}

class _CommentToken extends _ExpressionToken implements _StandAloneLineCapable {
  
  _CommentToken() : super.withSource(EMPTY_STRING, EMPTY_STRING);
  
  apply(MustacheContext ctx) => EMPTY_STRING;
}

class _EscapeHtmlToken extends _ExpressionToken {
  _EscapeHtmlToken(String val, String source) : super.withSource(val, source);

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
  
  String toString() => "EscapeHtmlToken($name)";
}

class _StartSectionToken extends _ExpressionToken implements _StandAloneLineCapable {
  final Delimiter delimiter;
  _Token _computedNext;
  
  _StartSectionToken(String val, this.delimiter) : super.withSource(val, null);

  //Override the next getter
  _Token get next => _computedNext != null ? _computedNext : super.next;

  apply(MustacheContext ctx) {
    var val = ctx[name];
    if (val == true) {
      // we do not have to find the end section and apply
      //it's content here
      return EMPTY_STRING;
    }
    if (val == null) {
      _computedNext = forEachUntilEndSection(null);
      return EMPTY_STRING;
    }
    StringBuffer str = new StringBuffer();
    if (val is Function) { //apply the source to the given function
      _computedNext = forEachUntilEndSection((_Token t) => str.write(t._source));
      //A lambda's return value should be parsed
      return render(val(str.toString()), ctx, delimiter: delimiter);
    }
    if (val is MustacheContext) { //apply the new context to each of the tokens until the end
      _computedNext = forEachUntilEndSection((_Token t) => str.write(t.apply(val)));
      return str;
    }
    if (val is Iterable) {
      val.forEach((v) {
        _computedNext = forEachUntilEndSection((_Token t) => str.write(t.apply(v)));
      });
      return str;
    }
  }

  forEachUntilEndSection(void f(_Token)) {
    int counter = 1;
    _Token n = super.next;
    while (n != null) {
      if (n.name == name) {
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
      n = n.next;
    }
    return null;
  }
  
  //The token itself is always rendable
  bool get rendable => true;
  
  String toString() => "StartSectionToken($name)";
}

class _EndSectionToken extends _ExpressionToken implements _StandAloneLineCapable {
  _EndSectionToken(String val) : super.withSource(val, null);

  apply(MustacheContext ctx, [partial]) => EMPTY_STRING;
  
  String toString() => "EndSectionToken($name)";
}

class _InvertedSectionToken extends _StartSectionToken {
  _InvertedSectionToken(String val, Delimiter del) : super(val, del);
  
  apply(MustacheContext ctx) {
    var val = ctx[name];
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
    return EMPTY_STRING;
  }
}

