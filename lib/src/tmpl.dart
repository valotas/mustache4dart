part of mustache4dart;

class _Template extends Collection<_Token> {
  static final RegExp _EXP = new RegExp("\{{2,3}([^\}]+)(\}{2,3})", multiLine: true);
  final List<_Token> tokens;
  
  factory _Template(String template) {
    //print(template);
    List<_Token> tokens = [];
    num lastStart = 0;
    _EXP.allMatches(template).forEach((m) {
      tokens.add(new _StringToken(template.substring(lastStart, m.start)));
      tokens.add(new _ExpressionToken(m[1], m[2].length == 2));
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
  
  Iterator<_Token> iterator() => tokens.iterator();
  
  _Token operator [](int index) {
    return tokens[index];
  }
  
  Collection<_Token> map(f(_Token element)) => tokens.map(f);
  Collection<_Token> filter(bool f(_Token element)) => tokens.filter(f);
  int get length => tokens.length;

}
