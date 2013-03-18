part of mustache4dart;

String render(String template, Object context, {Function partial: null, Delimiter delimiter: null, String ident: EMPTY_STRING}) {
  return compile(template, partial: partial, delimiter: delimiter, ident: ident)(context);
}

compile(String template, {Function partial: null, Delimiter delimiter: null, String ident: EMPTY_STRING}) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  return new _Template(template, delimiter, ident, partial);
}