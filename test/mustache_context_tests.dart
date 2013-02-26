library mustache_context_tests;

import 'package:/unittest/unittest.dart';
import 'package:mustache4dart/mustache4dart.dart';

void main() {
  group ('Mustache contexts', () {
    test('Simple context with map', () {
      var ctx = new MustacheContext({'k1': 'value1', 'k2': 'value2'});
      expect(ctx['k1'], 'value1');
      expect(ctx['k2'], 'value2');
      expect(ctx['k3'], null);
    });
    
    test('Simple context with object', () {
      var ctx = new MustacheContext(new _Person('Γιώργος', 'Βαλοτάσιος'));
      expect(ctx['name'], 'Γιώργος');
      expect(ctx['lastname'], 'Βαλοτάσιος');
      expect(ctx['last'], null);
      expect(ctx['fullname'], 'Γιώργος Βαλοτάσιος');
      expect(ctx['reversedName'], 'ςογρώιΓ');
      expect(ctx['reversedLastName'], 'ςοισάτολαΒ');
    });
    
    test('Simple map with list of maps', () {
      var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                           {'k2': 'item2'}, 
                                           {'k3': {'kk1' : 'subitem1', 'kk2': 'subitem2'}}]});
      expect(ctx['k'].length, 3);
    });
    
    test('Map with list of lists', () {
      var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                           {'k3': [{'kk1' : 'subitem1'}, {'kk2': 'subitem2'}]}]});
      expect(ctx['k'].length, 2);
      expect(ctx['k'].last['k3'].length, 2);
    });
    
    test('Object with iterables', () {
      var p = new _Person('Νικόλας', 'Νικολάου');
      p.contactInfos.add(new _ContactInfo('Address', {
        'Street': 'Κολοκωτρόνη',
        'Num': '31',
        'Zip': '42100',
        'Country': 'GR'
      }));
      p.contactInfos.add(new _ContactInfo('skype', 'some1'));
      var ctx = new MustacheContext(p);
      expect(ctx['contactInfos'].length, 2);
      expect(ctx['contactInfos'].first['value']['Num'], '31');
    });
    
    test('Deep search with object', () {
      //create our model:
      _Person p = null;
      for (int i = 10; i > 0; i--) {
        p = new _Person("name$i", "lastname$i", p);
      }
      
      
      MustacheContext ctx = new MustacheContext(p);
      expect(ctx['name'], 'name1');
      expect(ctx['parent']['lastname'], 'lastname2');
      expect(ctx['parent']['parent']['fullname'], 'name3 lastname3');
    });
    
    test('simple MustacheFunction value', () {
      var t = new _Transformer();
      var ctx = new MustacheContext(t);
      var f = ctx['transform'];
      
      expect(f is Function, true);
      expect(f('123 456 777'), t.transform('123 456 777'));
    });
    
    test('MustacheFunction from anonymus function', () {
      var map = {'transform': (String val) => "$val!"};
      var ctx = new MustacheContext(map);
      var f = ctx['transform'];
      
      expect(f is Function, true);
      expect(f('woh'), 'woh!');
    });
    
    test('Dotted names', () {
      var ctx = new MustacheContext({'person': new _Person('George', 'Valotasios')});
      expect(ctx['person.name'], 'George');
    });
    
    test('Context with another context', () {
      var ctx = new MustacheContext(new _Person('George', 'Valotasios'), new MustacheContext({'a' : {'one': 1}, 'b': {'two': 2}}));
      expect(ctx['name'], 'George');
      expect(ctx['a']['one'], '1');
      expect(ctx['b']['two'], '2');
    });
    
    test('Deep subcontext test', () {
      var map = {'a': {'one': 1}, 'b': {'two': 2}, 'c': {'three': 3}};
      var ctx = new MustacheContext({'a': {'one': 1}, 'b': {'two': 2}, 'c': {'three': 3}});
      expect(ctx['a'], isNotNull, reason: "a should exists when using $map");
      expect(ctx['a']['one'], '1');
      expect(ctx['a']['two'], isNull);
      expect(ctx['a']['b'], isNotNull, reason: "a.b should exists when using $map");
      expect(ctx['a']['b']['one'], '1', reason: "a.b.one == a.own when using $map");
      expect(ctx['a']['b']['two'], '2', reason: "a.b.two == b.two when using $map");
      expect(ctx['a']['b']['three'], isNull);
      expect(ctx['a']['b']['c'], isNotNull, reason: "a.b.c should not be null when using $map");
      expect(ctx['a']['b']['c']['one'], '1', reason: "a.b.c.one == a.one when using $map");
      expect(ctx['a']['b']['c']['two'], '2', reason: "a.b.c.two == b.two when using $map");
      expect(ctx['a']['b']['c']['three'], '3');
    });
  });
}

class _Person {
  final name;
  final lastname;
  final _Person parent;
  List<_ContactInfo> contactInfos = [];
  
  _Person(this.name, this.lastname, [this.parent = null]);
  
  get fullname => "$name $lastname";
  
  getReversedName() => _reverse(name);
  
  static _reverse(String str) {
    StringBuffer out = new StringBuffer();
    for (int i = str.length; i > 0; i--) {
      out.write(str[i - 1]);
    }
    return out.toString();
  }
  
  reversedLastName() => _reverse(lastname);
}

class _ContactInfo {
  final String type;
  final value;
  
  _ContactInfo(this.type, this.value);
}

class _Transformer {
  String transform(String val) => "<b>$val</b>";
}
