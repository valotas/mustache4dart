part of mustache4dart;

render(String template, Object context,
    {Function partial,
    Delimiter delimiter,
    String ident: EMPTY_STRING,
    StringSink out,
    bool errorOnMissingProperty: false}) {
  return compile(template,
          partial: partial, delimiter: delimiter, ident: ident)(context,
      out: out, errorOnMissingProperty: errorOnMissingProperty);
}

TemplateRenderer compile(String template,
    {Function partial, Delimiter delimiter, String ident: EMPTY_STRING}) {
  if (delimiter == null) {
    delimiter = new Delimiter('{{', '}}');
  }
  return new _Template(
      template: template, delimiter: delimiter, ident: ident, partial: partial);
}
