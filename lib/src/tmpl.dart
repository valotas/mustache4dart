part of mustache4dart;

class _Template {
  final _TokenList list;
  
  factory _Template(String template, Delimiter del, String ident, [Function partial]) {
    _TokenList tokens = new _TokenList(del, ident);
    if (template == null) {
      tokens.add(new _Token('', null, del, ident));
      return new _Template._internal(tokens);
    }
    
    StringBuffer buf = new StringBuffer();
    bool searchForOpening = true;
    for (int i = 0; i < template.length; i++) {
      String char = template[i];
      if (del.isDelimiter(template, i, searchForOpening)) {
        if (searchForOpening) { //opening delimiter
          if (buf.length > 0) {
            tokens.add(new _Token(buf.toString(), partial, del, ident));
            buf = new StringBuffer(); //resut our buffer: new token starts
          }
          searchForOpening = false;
        }
        else { //closing delimiter
          buf.write(del.closing); //add the closing delimiter
          var t = new _Token(buf.toString(), partial, del, ident);
          tokens.add(t); //add the token
          buf = new StringBuffer(); //resut our buffer: new token starts
          i = i + del.closingLength - 1;
          del = t.delimiter; //get the next delimiter to use
          searchForOpening = true;
          continue;
        }
      }
      else if (isSingleCharToken(char, searchForOpening)) {
        if (buf.length > 0) {
          tokens.add(new _Token(buf.toString(), partial, del, ident));
          buf = new StringBuffer();
        }
        tokens.add(new _Token(char, partial, del, ident));
        continue;
      }
      else if (isSpecialNewLine(template, i)) {
        if (buf.length > 0) {
          tokens.add(new _Token(buf.toString(), partial, del, ident));
          buf = new StringBuffer();
        }
        tokens.add(new _Token('\r\n', partial, del, ident));
        i++;
        continue;
      }
      buf.write(char);
    }
    tokens.add(new _Token(buf.toString(), partial, del, ident));
    if (buf.length > 0) {
      tokens.add(new _Token('', partial, del, ident)); //to mark the end of the template  
    }

    return new _Template._internal(tokens);
  }
  
  static bool isSingleCharToken(String char, bool opening) {
    if (!opening) {
      return false;
    }
    if (char == '\n') {
      return true;
    }
    if (char == ' ') {
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
    
  String renderWith(MustacheContext ctx) {
    if (list.head == null) {
      return '';
    }
    return list.head.render(ctx, null);
  }
  
  String toString() {
    return "Template($list)";
  }
}

class _TokenList {
  _Token head;
  _Token tail;
  
  _TokenList(Delimiter delimiter, String ident) {
    //Our template should start as an empty string token
    head = new _SpecialCharToken('', delimiter, ident);
    tail = head;
  }

  void add(_Token other) {
    if (other == null) {
      return;
    }
    tail.next = other;
    tail = other;
  }
  
  Delimiter get delimiter => tail.delimiter;

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

class Delimiter {
  final String opening;
  final String _closing;
  String realClosingTag;
  
  Delimiter(this.opening, this._closing);
  
  bool isDelimiter(String template, int position, bool opening) {
    String d = opening ? this.opening : this._closing;
    if (d.length == 1) {
      return d == template[position];
    }
    //else:
    int endIndex = position + d.length;
    if (endIndex >= template.length) {
      return false;
    }
    String dd = template.substring(position, endIndex);
    if (d != dd) {
      return false;
    }
    //A hack to support tripple brackets
    if (!opening && _closing == '}}' && template[endIndex] == '}') {
      realClosingTag = '}}}';
    }
    else {
      realClosingTag = null;
    }
    return true;
  }
  
  String get closing => realClosingTag != null ? realClosingTag : _closing;
  
  int get closingLength => closing.length;
  
  int get openingLength => opening.length;
  
  toString() => "Delimiter($opening, $closing)";
}
