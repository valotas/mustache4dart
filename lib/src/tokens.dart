part of mustache4dart;

/**
 * This is the main class describing a compiled token.
 */

abstract class _Token { 
  final String _source;
  final Delimiter _delimiter;

  _Token _next;
  _Token prev;
  bool rendable = true;
  
  _Token.withSource(this._source, this._delimiter);
 
  factory _Token(String token, Function partial, Delimiter d, String ident) {
    if (token == '' || token == null) {
      return null;
    }
    if (token.startsWith('{{{') && d.opening == '{{') {
      return new _ExpressionToken(token.substring(3, token.length - 3), false, token, partial, d);
    } 
    else if (token.startsWith(d.opening)) {
      return new _ExpressionToken(token.substring(d.openingLength, token.length - d.closingLength), true, token, partial, d);
    }
    else if (token == ' ' || token == '\n' || token == '\r\n') {
      return new _SpecialCharToken(token, d, ident);
    }
    else {
      return new _StringToken(token, d);
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
  String get _val;
  
  void set next (_Token n) {
    _next = n;
    n.prev = this;
  }
  
  _Token get next => _next;
  
  Delimiter get delimiter => _delimiter;

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

  _StringToken(_val, Delimiter d) : super.withSource(_val, d);
  
  apply(context) => _val;
  
  String get _val => _source;

  String toString() => "StringToken($_val)";
}

class _SpecialCharToken extends _StringToken {
  final String ident;
  
  _SpecialCharToken(_val, Delimiter d, [this.ident = '']) : super(_val, d);
  
  apply(context) {
    if (_isNewLineOrEmpty) {
      _markNextStandAloneLineIfAny();      
    }
    if (!rendable) {
      return '';
    }
    
    return _isNewLine ? "${super.apply(context)}$ident" : super.apply(context);
  }
  
  _markNextStandAloneLineIfAny() {
    var n = next;
    if (n == null) {
      return;
    }
    int tokensMarked = 0;
    bool foundSection = false;
    while (n != null && n._val != '\n' && n._val != '\r\n') { //find the next endline
      if ((n._val == ' ' && !foundSection) 
          || n is _StartSectionToken 
          || n is _EndSectionToken 
          || (n is _PartialToken && _val != '' && n.next != null && n.next._val != '') 
          || n is _CommentToken 
          || n is _DelimiterToken) {
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
  
  bool get _isNewLineOrEmpty => _isNewLine || _val == '';
  
  bool get _isNewLine => _val == '\n' || _val == '\r\n'; 
  
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

  factory _ExpressionToken(String val, bool escapeHtml, String source, Function partial, Delimiter delimiter) {
    val = val.trim();
    if (escapeHtml && val.startsWith('&')) {
      escapeHtml = false;
      val = val.substring(1).trim();
    }
    if (!escapeHtml) {
      return new _ExpressionToken.withSource(val, source, delimiter);
    }

    String control = val.substring(0, 1);
    String newVal = val.substring(1).trim();

    if ('#' == control) {
      return new _StartSectionToken.withSource(newVal, source, delimiter);
    } else if ('/' == control) {
      return new _EndSectionToken.withSource(newVal, source, delimiter);
    } else if ('^' == control) {
      return new _InvertedSectionToken.withSource(newVal, source, delimiter);
    } else if ('!' == control) {
      return new _CommentToken.withSource(newVal, source, delimiter);
    } else if ('>' == control) {
      return new _PartialToken(partial, newVal, source, delimiter);
    } else if ('=' == control) {
      return new _DelimiterToken(newVal, source, delimiter);
    } else {
      return new _EscapeHtmlToken.withSource(val, source, delimiter);
    }
  }

  _ExpressionToken.withSource(this._val, source, delimiter) : super.withSource(source, delimiter);
  
  apply(MustacheContext ctx) {
    var val = ctx[_val];
    if (val == null) {
      return '';
    }
    if (val is Function) {
      //A lambda's return value should be parsed
      return render(val(null), ctx);
    }
    return val;
  }
  
  String toString() => "ExpressionToken($_val)";
}

class _DelimiterToken extends _ExpressionToken {
  
  _DelimiterToken(String val, String source, Delimiter del) : super.withSource(val, source, del);
  
  apply(MustacheContext ctx) => '';
  
  bool get rendable => false;
  
  Delimiter get delimiter {
    List delimiters = _val
        .substring(0, _val.length - 1)
        .split(' ');
    return new Delimiter(delimiters[0], delimiters[1]);
  }
}

class _PartialToken extends _ExpressionToken {
  final Function partial;
  _PartialToken(this.partial, String val, String source, Delimiter del) : super.withSource(val, source, del);
  
  apply(MustacheContext ctx) {
    if (standAloneWithoutPreviousLine) {
      next.rendable = false;
    }
    if (partial != null) {
      return render(partial(_val), ctx, partial: partial, ident: ident);      
    }
    return '';
  }
  
  bool get standAloneWithoutPreviousLine {
    if (next == null || next._val != '\n') {
      return false;
    }
    _Token p = prev;
    while (p != null) {
      if (p._val != ' ' && p._val != '') {
        return false;
      }
      p = p.prev;
    }
    return true;
  }
  
  String get ident {
    StringBuffer ident = new StringBuffer();
    _Token p = this.prev;
    while (p._val == ' ') {
      ident.write(' ');
      p = p.prev;
    }
    if (p._val == '\n' || p._val == '') {
      return ident.toString();      
    }
    else {
      return '';
    }
  }
  
  bool get rendable => true;
}

class _CommentToken extends _ExpressionToken {
  _Token _computedNext;
  
  _CommentToken.withSource(String val, String source, Delimiter del) : super.withSource(val, source, del);
  
  apply(MustacheContext ctx) => '';
}

class _EscapeHtmlToken extends _ExpressionToken {
  _EscapeHtmlToken.withSource(String val, String source, Delimiter del) : super.withSource(val, source, del);

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
  
  _StartSectionToken.withSource(String val, String source, Delimiter del) : super.withSource(val, source, del);

  //Override the next getter
  _Token get next => _computedNext != null ? _computedNext : super.next;

  apply(MustacheContext ctx) {
    var val = ctx[_val];
    if (val == true) {
      // we do not have to find the end section and apply
      //it's content here
      return '';
    }
    if (val == null) {
      _computedNext = forEachUntilEndSection(null);
      return '';
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
    Iterator<_Token> it = new _TokenIterator(super.next);
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
  
  //The token itself is always rendable
  bool get rendable => true;
  
  String toString() => "StartSectionToken($_val)";
}

class _EndSectionToken extends _ExpressionToken {
  _EndSectionToken.withSource(String val, String source, Delimiter del) : super.withSource(val, source, del);

  apply(MustacheContext ctx, [partial]) => '';
  
  String toString() => "EndSectionToken($_val)";
}

class _InvertedSectionToken extends _StartSectionToken {
  _InvertedSectionToken.withSource(String val, String source, Delimiter del) : super.withSource(val, source, del);
  
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

class _TokenIterator implements Iterator<_Token> {
  _Token start;
  _Token current;

  _TokenIterator(this.start);

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
