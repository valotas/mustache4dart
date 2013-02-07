import 'package:/unittest/unittest.dart';

import '../lib/mustache4dart.dart';

void main() {
  test('Simple context with map test', () {
    var ctx = new MustacheContext({'k1': 'value1', 'k2': 'value2'});
    expect(ctx['k1'], 'value1');
    expect(ctx['k2'], 'value2');
    expect(ctx['k3'], null);
  });
  
  test('Simple context with object test', () {
    var ctx = new MustacheContext(new _Person('Γιώργος', 'Βαλοτάσιος'));
    expect(ctx['name'], 'Γιώργος');
    expect(ctx['lastname'], 'Βαλοτάσιος');
    expect(ctx['last'], null);
    expect(ctx['fullname'], 'Γιώργος Βαλοτάσιος');
    expect(ctx['reversedName'], 'ςογρώιΓ');
    expect(ctx['reversedLastName'], 'ςοισάτολαΒ');
  });
  
  test('Simple map with list of maps test', () {
    var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                         {'k2': 'item2'}, 
                                         {'k3': {'kk1' : 'subitem1', 'kk2': 'subitem2'}}]});
    expect(ctx['k'].length, 3);
  });
  
  test('Map with list of lists test', () {
    var ctx = new MustacheContext({'k': [{'k1': 'item1'}, 
                                         {'k3': [{'kk1' : 'subitem1'}, {'kk2': 'subitem2'}]}]});
    expect(ctx['k'].length, 2);
    expect(ctx['k'].last['k3'].length, 2);
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
    expect(ctx['contactInfos'].length, 2);
  });
}

class _Person {
  final name;
  final lastname;
  List<_ContactInfo> contactInfos = [];
  
  _Person(this.name, this.lastname);
  
  get fullname => "$name $lastname";
  
  getReversedName() => _reverse(name);
  
  static _reverse(String str) {
    StringBuffer out = new StringBuffer();
    for (int i = str.length; i >= 0; i--) {
      out.add(str[i -1]);
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