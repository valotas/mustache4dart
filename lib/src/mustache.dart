part of mustache4dart;

compile(String template) {
  _Template tmpl = new _Template(template);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}

String render(String template, Object context) {
  Function renderer = compile(template);
  return renderer(context);
}
