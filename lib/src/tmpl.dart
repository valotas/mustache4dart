part of mustache4dart;

class _Template extends Iterable<_Token> {
  final Iterable<_Token> tokens;
  
  factory _Template(String template) {
    TokenList tokens = new TokenList();
    StringBuffer buf = new StringBuffer();
    String searchFor = '{';
    for (int i = 0; i < template.length; i++) {
      String char = template[i];
      if (char == searchFor) {
        if (char == '{' && template[i+1] == '{') {
          tokens.add(new _Token(buf.toString()));
          buf = new StringBuffer(); //resut our buffer: new token starts
          searchFor = '}';
        }
        else if (char == '}' && template[i-1] == '}' && (i + 1 == template.length || template[i+1] != '}')) {
          buf.add(char);
          tokens.add(new _Token(buf.toString()));
          buf = new StringBuffer(); //resut our buffer: new token starts
          searchFor = '{';
          continue;
        }
      }
      buf.add(char);
    }
    tokens.add(new _Token(buf.toString()));

    return new _Template._internal(tokens);
  }
  
  _Template._internal(this.tokens);
  
  Iterator<_Token> get iterator => tokens.iterator;
  
  String toString() {
    return "Template($tokens)";
  }
}
