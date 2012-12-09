part of mustache4dart;

class Mustache {
  String render(String template, Object context) {
    _Template tmpl = new _Template(template);
    StringBuffer result = new StringBuffer();
    tmpl.forEach((t) {
      result.add(t.apply(context));
    });
    return result.toString();
  }
}
