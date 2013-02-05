import 'package:/unittest/unittest.dart';

import '../lib/mustache4dart.dart';

void main() {
  test('Simple context with map test', () {
    var ctx = new MustacheContext({'k1': 'value1', 'k2': 'value2'});
    expect(ctx.getIterable('k1'), null);
    expect(ctx.getIterable('k2'), null);
    expect(ctx.getIterable('k3'), null);
    expect(ctx.getValue('k1'), 'value1');
    expect(ctx.getValue('k3'), null);
  });
  
  test('Simple context with object test', () {
    var ctx = new MustacheContext(new _Person('Γιώργος', 'Βαλοτάσιος'));
    expect(ctx.getValue('name'), 'Γιώργος');
    expect(ctx.getValue('lastname'), 'Βαλοτάσιος');
    expect(ctx.getValue('last'), null);
    expect(ctx.getIterable('name'), null);
    expect(ctx.getIterable('lastname'), null);
    expect(ctx.getIterable('l'), null);
  });
  
  test('Simple map with list of maps test', () {
    var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                         {'k2': 'item2'}, 
                                         {'k3': {'kk1' : 'subitem1', 'kk2': 'subitem2'}}]});
    expect(ctx.getIterable('k').length, 3);
  });
  
  test('Map with list of lists test', () {
    var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                         {'k3': [{'kk1' : 'subitem1'}, {'kk2': 'subitem2'}]}]});
    expect(ctx.getIterable('k').length, 2);
    expect(ctx.getIterable('k').last.getIterable('k3').length, 2);
  });
  
  test('Obect with iterables test', () {
    var p = new _Person('Νικόλας', 'Νικολάου');
    p.contactInfos.add(new _ContactInfo('Address', {
      'Street': 'Κολοκωτρόνη',
      'Num': '31',
      'Zip': '42100',
      'Country': 'GR'
    }));
    p.contactInfos.add(new _ContactInfo('skype', 'some1'));
    var ctx = new MustacheContext(p);
    expect(ctx.getIterable('contactInfos').length, 2);
  });
}

class _Person {
  final name;
  final lastname;
  List<_ContactInfo> contactInfos = [];
  
  _Person(this.name, this.lastname);
}

class _ContactInfo {
  final String type;
  final value;
  
  _ContactInfo(this.type, this.value);
}