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
          if (buf.length > 0) {
            tokens.add(new _Token(buf.toString()));
            buf = new StringBuffer(); //resut our buffer: new token starts
          }
          searchFor = '}';
        }
        else if (char == '}' && template[i-1] == '}' && (i + 1 == template.length || template[i+1] != '}')) {
          buf.write(char);
          tokens.add(new _Token(buf.toString()));
          buf = new StringBuffer(); //resut our buffer: new token starts
          searchFor = '{';
          continue;
        }
      }
      else if (isSingleCharToken(char, searchFor)) {
        if (buf.length > 0) {
          tokens.add(new _Token(buf.toString()));
          buf = new StringBuffer();
        }
        tokens.add(new _Token(char));
        continue;
      }
      else if (isSpecialNewLine(template, i)) {
        if (buf.length > 0) {
          tokens.add(new _Token(buf.toString()));
          buf = new StringBuffer();
        }
        tokens.add(new _Token('\r\n'));
        i++;
        continue;
      }
      buf.write(char);
    }
    tokens.add(new _Token(buf.toString()));

    return new _Template._internal(tokens);
  }
  
  static bool isSingleCharToken(String char, String searchFor) {
   if (char == '\n' && searchFor != '}') {
     return true;
   }
   if (char == ' ' && searchFor == '{') {
     return true;
   }
   return false; 
  }
  
  static bool isSpecialNewLine(String template, int position) {
    if (position + 1 == template.length) {
      return false;
    }
    var char = template[position];
    var nextChar = template[position + 1];
    return char == '\r' && nextChar == '\n'; 
  }
  
  _Template._internal(this.tokens);
  
  Iterator<_Token> get iterator => tokens.iterator;
  
  String renderWith(MustacheContext ctx, [StringBuffer buf]) {
    if (buf == null) {
      buf = new StringBuffer();
    }
    tokens.forEach((t) {
      var value = t.apply(ctx);
      if (t.rendable) {
        buf.write(value);        
      }
    });
    return buf.toString();
  }
  
  String toString() {
    return "Template($tokens)";
  }
}
