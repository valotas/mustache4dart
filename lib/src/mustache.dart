part of mustache4dart;

class Mustache {
  final Map<String, _Template> templates = {};
  
  String render(String template, Object context) {
    _Template tmpl = templates[template];
    if (tmpl == null) {
      tmpl = new _Template(template);
      templates[template] = tmpl;
    }
    MustacheContext ctx = new MustacheContext(context);
    StringBuffer result = new StringBuffer();
    for (_Token t in tmpl) {
      result.add(t.apply(ctx));
    }
    return result.toString();
  }
}
