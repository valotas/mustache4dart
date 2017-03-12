import 'package:mustache4dart/mustache4dart.dart';

main() {
  var tmpl =
      '{{#a}}{{one}}{{#b}}-{{one}}{{two}}{{#c}}-{{one}}{{two}}{{three}}{{#d}}-{{one}}{{two}}{{three}}{{four}}{{#e}}{{one}}{{two}}{{three}}{{four}}{{/e}}{{/d}}{{/c}}{{/b}}{{/a}}';
  StringBuffer buf = new StringBuffer(tmpl);
  for (int i = 0; i < 10; i++) {
    buf.write(
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd');
    buf.write(tmpl);
  }
  tmpl = buf.toString();

  var map = {
    'a': {'one': 1},
    'b': {'two': 2},
    'c': {'three': 3},
    'd': {'four': 4},
    'e': false
  };
  var ctmpl = compile(tmpl);

  var warmup = duration(100, () => "${ctmpl(map)}--${render(tmpl, map)}");
  print(
      "Warmup rendering of template with length ${tmpl.length} took ${warmup}millis");

  var d = duration(100, () => render(tmpl, map));
  print("100 iterations of uncompiled rendering took ${d}millis");

  var d2 = duration(100, () => ctmpl(map));
  print("100 iterations of compiled rendering tool ${d2}millis");
}

num duration(int reps, f()) {
  var start = new DateTime.now();
  for (int i = 0; i < reps; i++) {
    f();
  }
  var end = new DateTime.now();
  return end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
}
