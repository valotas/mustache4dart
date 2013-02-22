part of mustache4dart;

compile(String template) {
  _Template tmpl = new _Template(template);
  return (context) {
    MustacheContext ctx = new MustacheContext(context);
    StringBuffer result = new StringBuffer();
    tmpl.forEach((t) => result.write(t.apply(ctx)));
    return result.toString();
  };
}

String render(String template, Object context) {
  Function renderer = compile(template);
  return renderer(context);
}
