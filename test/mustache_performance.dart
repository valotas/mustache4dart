import 'package:mustache4dart/mustache4dart.dart';

const ITERATIONS = 1000;

var AVAILABLE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

main() {
  final iterations = findIterations();

  final tmpl = createTemplate();

  final map = {
    'a': {'one': 1},
    'b': {'two': 2},
    'c': {'three': 3},
    'd': {'four': 4},
    'e': false
  };
  final ctmpl = compile(tmpl);

  final warmup =
      duration(() => "${ctmpl(map)}--${render(tmpl, map)}", iterations);
  print(
      "Warmup rendering of template with length ${tmpl.length} took ${warmup}millis");

  final d = duration(() => render(tmpl, map), iterations);
  print("Uncompiled rendering took ${d}millis");

  final d2 = duration(() => ctmpl(map), iterations);
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

findIterations([num initialIterations = ITERATIONS]) {
  var iterations = initialIterations;
  var time = duration(baselineTest, iterations);
  while (time < 100) {
    iterations = iterations * 2;
    time = duration(baselineTest, iterations);
    print("Baseline test took: ${time}millis for ${iterations} iterations");
  }
  return iterations;
}

baselineTest() {
  final length = AVAILABLE_CHARS.length;
  var newString = '';
  for (var i = length - 1; i >= 0; i--) {
    newString += '-' + AVAILABLE_CHARS[i];
  }
  return newString;
}

num duration(f(), [numOfIterations = ITERATIONS]) {
  final start = new DateTime.now();
  for (int i = 0; i < numOfIterations; i++) {
    f();
  }
  final end = new DateTime.now();
  return end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
}
