
class _Template {
  static final RegExp _EXP = new RegExp("(^\}\}).|\{\{([^\}]+)\}\}", multiLine: true);
  List<String> tokens = [];
  
  factory _Template(String template) {
    print(template);
    List<String> tokens = [];
    num lastStart = 0;
    _EXP.allMatches(template).forEach((m) {
      tokens.add(template.substring(lastStart, m.start));
      tokens.add(m[0]);
      lastStart = m.end;
      print("0: ${m[0]}, 1: ${m[1]}, 2: ${m[2]}, start: ${m.start}, end: ${m.end}");
    });
    //print(_tokens);
    return new _Template._internal(tokens);
  }
  
  _Template._internal(this.tokens);
}
