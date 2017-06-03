library mustache_usage;

import 'dart:io';
import "package:mustache4dart/mustache4dart.dart";
import "package:mustache4dart/utils_io.dart";

void main() {
  //Basic use of the library as you can find it at http://mustache.github.io/mustache.5.html
  var template = '''Hello {{name}}
You have just won \${{value}}!
{{#in_ca}}
Well, \${{taxed_value}}, after taxes.
{{/in_ca}}''';

  num value = 10000,
      taxed_value = value - value * 0.4,
      major = 0.02,
      state = 0.18,
      nation = 0.21,
      city = 0.59;

  var obj = {
    "name": "Chris",
    "value": value,
    "taxed_value": taxed_value,
    "in_ca": true,
    "taxes_details": [
      {"name": "major", "amount": taxed_value * major},
      {"name": "state", "amount": taxed_value * state},
      {"name": "nation", "amount": taxed_value * nation},
      {"name": "city", "amount": taxed_value * city}
    ]
  };

  print(render(template, obj));

  //Print something to a StringSink
  var out = new StringBuffer();
  render(template, obj, out: out);
  print(out);

  //Use the templates from the Filesystem with utils_io
  PartialsHandler handler =
      new PartialsHandler(directoriesPaths: ["./example/partials"]);
  File file = new File("example/template.mustache");
  renderFromFileAsync(file, obj, partial: handler.partialSearchFunction)
      .then(print);
  renderFromFilePathAsync("example/template.mustache", obj,
          partial: handler.partialSearchFunction)
      .then(print);
  print(renderFromFileSync(file, obj, partial: handler.partialSearchFunction));
  print(renderFromFilePathSync("example/template.mustache", obj,
      partial: handler.partialSearchFunction));
}
