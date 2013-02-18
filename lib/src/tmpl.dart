part of mustache4dart;

class _Template extends Iterable<_Token> {
  static final RegExp _EXP = new RegExp("\{{2,3}([^\}]+)(\}{2,3})", multiLine: true);
  final Iterable<_Token> tokens;
  
  factory _Template(String template) {
    TokenList tokens = new TokenList();
    num lastStart = 0;
    _EXP.allMatches(template).forEach((m) {
      StringBuffer b = new StringBuffer(m[1]);
      tokens.add(new _Token(template.substring(lastStart, m.start)));
      tokens.add(new _Token(m[0]));
      lastStart = m.end;
    });
    
    if (lastStart == 0) { //The case of no match found
      tokens.add(new _StringToken(template));
    }
    else if (lastStart < template.length) { //add the stuff after the last found expression
      tokens.add(new _StringToken(template.substring(lastStart)));
    }
    return new _Template._internal(tokens);
  }
  
  _Template._internal(this.tokens);
  
  Iterator<_Token> get iterator => tokens.iterator;
  
  String toString() {
    return "Template($tokens)";
  }
}
