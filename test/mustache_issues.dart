library mustache_issues;

import 'dart:io';
import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'package:mustache4dart/mustache_context.dart';

void main() {
  defineTests();
}

defineTests() {
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
    test('#17', () => expect(render('{{#a}}[{{{a}}}|{{b}}]{{/a}}', {'a': 'aa', 'b': 'bb'}),'[aa|bb]'));
    test('#17 root cause: setting the same context as a subcontext', () {
      var ctx = new MustacheContext({'a': 'aa', 'b': 'bb'});
      expect(ctx, isNotNull);
      expect(ctx['a'].toString(), isNotNull);
      
      //Here lies a problem if the subaa.other == suba 
      expect(ctx['a']['a'].toString(), isNotNull);
    });
    test('#20', () {
      var currentPath = Directory.current.path;
      if (!currentPath.endsWith('/test')) {
        currentPath = "$currentPath/test";
      }
      var template = new File("$currentPath/lorem-ipsum.txt")
        .readAsStringSync(encoding: UTF8);
      
      String out = render(template, {'ma': 'ma'});
      expect(out, template);
    });

    test('#25', () {
      var ctx = {
        "parent_name": "John",
        "children": [{"name": "child"}] 
      };
      expect(render('{{#children}}Parent: {{parent_name}}{{/children}}', ctx), 'Parent: John');
    });
    
    test('#28', () {
      var model = {
        "name": "God",
        "hasChildren": true,
        "children": [
          { "name": "granpa", "hasChildren": true},
          { "name": "granma", "hasChildren": false}
        ]
      };
      
      expect(render('{{#children}}{{name}}{{#hasChildren}} has children{{/hasChildren}},{{/children}}', model), 'granpa has children,granma,');
    });
    
    test('#29', () {
      var list = [1, 'two', 'three', '4'];
      expect(render('{{#.}}{{.}},{{/.}}', list), '1,two,three,4,');
    });
  });
}
