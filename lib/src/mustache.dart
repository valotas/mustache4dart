part of mustache4dart;

compile(String template) {
  _Template tmpl = new _Template(template);
  return (context, [Function partial]) {
    return tmpl.renderWith(new MustacheContext(context), partial);
  };
}

String render(String template, Object context, [Function partial]) {
  Function renderer = compile(template);
  return renderer(context, partial);
}
