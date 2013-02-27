part of mustache4dart;

String render(String template, Object context, [Function partial]) {
  return compile(template, partial)(context);
}

compile(String template, [Function partial]) {
  _Template tmpl = new _Template(template, partial);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}

