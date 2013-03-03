part of mustache4dart;

String render(String template, Object context, [Function partial, Delimiter delimiter]) {
  return compile(template, partial, delimiter)(context);
}

Function compile(String template, [Function partial, Delimiter delimiter]) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  _Template tmpl = new _Template(template, delimiter, partial);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}