import 'package:mustache4dart/mustache4dart.dart';

const ITERATIONS = 1000;

main() {
  final tmpl = createTemplate();

  final map = {
    'a': {'one': 1},
    'b': {'two': 2},
    'c': {'three': 3},
    'd': {'four': 4},
    'e': false
  };
  final ctmpl = compile(tmpl);

  final warmup = duration(() => "${ctmpl(map)}--${render(tmpl, map)}");
  print(
      "Warmup rendering of template with length ${tmpl.length} took ${warmup}millis");

  final d = duration(() => render(tmpl, map));
  print("Uncompiled rendering took ${d}millis");

  final d2 = duration(() => ctmpl(map));
  print("Compiled rendering took ${d2}millis");

  print("Score relation: ${d2/d}");
}

createTemplate() {
  final tmpl =
      '''{{#a}}{{one}}{{#b}}-{{one}}{{two}}{{#c}}-{{one}}{{two}}{{three}}
        {{#d}}-{{one}}{{two}}{{three}}{{four}}{{#e}}{{one}}{{two}}{{three}}
        {{four}}{{/e}}{{/d}}{{/c}}{{/b}}{{/a}}''';
  final buf = new StringBuffer(tmpl);
  for (int i = 0; i < 10; i++) {
    buf.write('dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd');
    buf.write(tmpl);
  }
  return buf.toString();

}

num duration(f()) {
  final start = new DateTime.now();
  for (int i = 0; i < ITERATIONS; i++) {
    f();
  }
  final end = new DateTime.now();
  return end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
}
