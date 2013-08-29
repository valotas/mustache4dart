library mustache_issues;

import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group('mustache4dart issues', () {    
    test('#9', () => expect(render("{{#sec}}[{{var}}]{{/sec}}", {'sec': 42}), '[]'));
    test('#10', () => expect(render('|\n{{#bob}}\n{{/bob}}\n|', {'bob': []}), '|\n|'));
    test('#11', () => expect(() => render("{{#sec}}[{{var}}]{{/somethingelse}}", {'sec': 42}), throwsFormatException));
    test('#12: Write to a StringSink', () {
      StringSink out = new StringBuffer();
      StringSink outcome = render("{{name}}!", {'name': "George"}, out: out);
      expect(out, outcome);
      expect(out.toString(), "George!");
    });
    test('#16', () => expect(render('{{^x}}x{{/x}}!!!', null), 'x!!!'));
    test('#16 root cause: For null objects the value of any property should be null', () {
      var ctx = new MustacheContext(null);
      expect(ctx['xxx'], null);
      expect(ctx['123'], null);
      expect(ctx[''], null);
      expect(ctx[null], null);
    });
  });
}
