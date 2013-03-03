part of mustache4dart;

String render(String template, Object context, [partial = null, delimiter = null, ident = '']) {
  return compile(template, partial, delimiter)(context);
}

Function compile(String template, [partial = null, delimiter = null, ident = '']) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  _Template tmpl = new _Template(template, delimiter, partial);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}