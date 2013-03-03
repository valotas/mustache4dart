part of mustache4dart;

String render(String template, Object context, {Function partial: null, Delimiter delimiter: null, String ident: ''}) {
  return compile(template, partial: partial, delimiter: delimiter)(context);
}

Function compile(String template, {Function partial: null, Delimiter delimiter: null, String ident: ''}) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  _Template tmpl = new _Template(template, delimiter, partial);
  return (context) {
    return tmpl.renderWith(new MustacheContext(context));
  };
}