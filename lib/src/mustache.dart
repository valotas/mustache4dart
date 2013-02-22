part of mustache4dart;

String render(String template, Object context) {
  _Template tmpl = new _Template(template);
  MustacheContext ctx = new MustacheContext(context);
  StringBuffer result = new StringBuffer();
  tmpl.forEach((t) => result.write(t.apply(ctx)));
  return result.toString();
}
