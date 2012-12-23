part of mustache4dart;

class Mustache {
  String render(String template, Object context) {
    _Template tmpl = new _Template(template);
    MustacheContext ctx = new MustacheContext(context);
    StringBuffer result = new StringBuffer();
    for (_Token t in tmpl) {
      result.add(t.apply(ctx));
    }
    return result.toString();
  }
}
