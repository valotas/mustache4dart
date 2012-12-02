library mustache4dart;

import 'dart:core';

class Mustache {
 static String render(String template, context) {
   _Template t = new _Template(template);
   return null;
 }
}

class _Template {
  static final RegExp _EXP = new RegExp("(^\}\}).|\{\{([^\}]+)\}\}", multiLine: true);
  List<String> _tokens = [];
  
  _Template(String template) {
    print(template);
    num lastStart = 0;
    _EXP.allMatches(template).forEach((m) {
      _tokens.add(template.substring(lastStart, m.start));
      _tokens.add(m[0]);
      lastStart = m.end;
      print("0: ${m[0]}, 1: ${m[1]}, 2: ${m[2]}, start: ${m.start}, end: ${m.end}");
    });
    print(_tokens);
  }
}