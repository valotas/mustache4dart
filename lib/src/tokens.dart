part of mustache4dart;

/**
 * This is the main class describing a compiled token.
 */

abstract class Token { 
  final String _source;

  Token _next;
  Token prev;
  bool rendable = true;
  
  Token.withSource(this._source);
 
  factory Token(String token, Function partial, Delimiter d, String ident) {
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
  
  void render(MustacheContext context, StringSink out) {
    if (out == null) throw new Exception("Need an output to write the rendered result");
    var string = apply(context);
    if (rendable) {
      out.write(string);
    }
    if (next != null) {
      next.render(context, out);
    }
  }
  
  StringBuffer apply(MustacheContext context);

  /**
   * This describes the value of the token.
   */
  String get name;
  
  void set next (Token n) {
    _next = n;
    n.prev = this;
  }
  
  Token get next => _next;
  
  /**
   * Two tokens are the same if their _val are the same.
   */
  bool operator ==(other) {
    if (other is Token) {
     Token st = other;
     return name == st.name;
    }
    if (other is String) {
      return name == other;
    }
    return false;
  }  
  
  int get hashCode => name.hashCode;
}

abstract class StandAloneLineCapable {
  
}

/**
 * The simplest implementation of a token is the _StringToken which is any string that is not within
 * an opening and closing mustache.
 */
class _StringToken extends Token {

  _StringToken(_val) : super.withSource(_val);
  
  apply(context) => name;
  
  String get name => _source;

  String toString() => "StringToken($name)";
}

class _SpecialCharToken extends _StringToken implements StandAloneLineCapable {
  final String ident;
  
  _SpecialCharToken(_val, [this.ident = EMPTY_STRING]) : super(_val);
  
  apply(context) {
    if (!rendable) {
      return EMPTY_STRING;
    }
    
    if (next == null) {
      return super.apply(context);
    }
    if (_isNewLineOrEmpty) {
      return "${super.apply(context)}$ident";
    }
    return super.apply(context);
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
class _ExpressionToken extends Token {
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
    return val.asString();
  }
  
  String toString() => "ExpressionToken($name)";
}

class _DelimiterToken extends _ExpressionToken implements StandAloneLineCapable {
  
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

class _PartialToken extends _ExpressionToken implements StandAloneLineCapable {
  final Function partial;
  _PartialToken(this.partial, String val) : super.withSource(val, null);
  
  apply(MustacheContext ctx) {
    if (partial != null) {
      var partialTemplate = partial(name);
      if (partialTemplate != null) {
        return render(partial(name), ctx, partial: partial, ident: _ident);        
      }
    }
    return EMPTY_STRING;
  }
  
  String get _ident {
    StringBuffer ident = new StringBuffer();
    Token p = this.prev;
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

class _CommentToken extends _ExpressionToken implements StandAloneLineCapable {
  
  _CommentToken() : super.withSource(EMPTY_STRING, EMPTY_STRING);
  
  apply(MustacheContext ctx) => EMPTY_STRING;

  String toString() => "_CommentsToken()";
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

class _StartSectionToken extends _ExpressionToken implements StandAloneLineCapable {
  final Delimiter delimiter;
  _EndSectionToken endSection;
  
  _StartSectionToken(String val, this.delimiter) : super.withSource(val, null);

  //Override the next getter
  Token get next =>  endSection.next;

  apply(MustacheContext ctx) {
    var val = ctx[name];
    if (val == null) {
      return EMPTY_STRING;
    }
    StringBuffer str = new StringBuffer();
    if (val is Function) { //apply the source to the given function
      forEachUntilEndSection((Token t) => str.write(t._source));
      //A lambda's return value should be parsed
      return render(val(str.toString()), ctx, delimiter: delimiter);
    }
    if (val is MustacheContext) { //apply the new context to each of the tokens until the end
      forEachUntilEndSection((Token t) => str.write(t.apply(val)));
      return str;
    }
    if (val is Iterable) {
      val.forEach((v) {
        forEachUntilEndSection((Token t) => str.write(t.apply(v)));
      });
      return str;
    }
    //in any other case
    return EMPTY_STRING;
  }

  forEachUntilEndSection(void f(Token)) {
    if (f == null) {
      throw new Exception('Can not apply a null function!');
    }
    Token n = super.next;
    while (!identical(n, endSection)) {
      f(n);
      n = n.next;
    }
  }
  
  //The token itself is always rendable
  bool get rendable => true;

  String toString() => "StartSectionToken($name)";
}

class _EndSectionToken extends _ExpressionToken implements StandAloneLineCapable {
  _EndSectionToken(String val) : super.withSource(val, null);

  apply(MustacheContext ctx, [partial]) => EMPTY_STRING;
  
  String toString() => "EndSectionToken($name)";
}

class _InvertedSectionToken extends _StartSectionToken {
  _InvertedSectionToken(String val, Delimiter del) : super(val, del);
  
  apply(MustacheContext ctx) {
    if (ctx[name] == null) {
      StringBuffer buf = new StringBuffer();
      forEachUntilEndSection((Token t) {
        var val2 = t.apply(ctx);
        buf.write(val2);
      });
      return buf.toString();
    }
    //else just return an empty string
    return EMPTY_STRING;
  }
  
  String toString() => "InvertedSectionToken($name)";
}

