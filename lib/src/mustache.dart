part of mustache4dart;

String render(String template, Object context, {Function partial: null, Delimiter delimiter: null, String ident: EMPTY_STRING}) {
  return compile(template, partial: partial, delimiter: delimiter, ident: ident)(context);
}

Function compile(String template, {Function partial: null, Delimiter delimiter: null, String ident: EMPTY_STRING}) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  _Template tmpl = new _Template(template, delimiter, ident, partial);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}