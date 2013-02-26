part of mustache4dart;

class _Template {
  final _TokenList list;
  
  factory _Template(String template) {
    _TokenList tokens = new _TokenList();
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
  
  _Template._internal(this.list);
    
  String renderWith(MustacheContext ctx, [Function partial]) {
    return list.head.render(ctx, null, partial);
  }
  
  String toString() {
    return "Template($list)";
  }
}

class _TokenList {
  _Token head;
  _Token tail;

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
