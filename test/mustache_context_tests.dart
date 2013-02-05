import 'package:/unittest/unittest.dart';

import '../lib/mustache4dart.dart';

void main() {
  test('Simple context with map test', () {
    var ctx = new MustacheContext({'k1': 'value1', 'k2': 'value2'});
    expect(ctx.getIterations('k1'), 1);
    expect(ctx.getIterations('k2'), 1);
    expect(ctx.getIterations('k3'), 0);
    expect(ctx.getValue('k1'), 'value1');
  });
  
  test('Simple context with object test', () {
    var ctx = new MustacheContext(new _Person('Γιώργος', 'Βαλοτάσιος'));
    //expect(ctx.getIterations('name'), 1);
    //expect(ctx.getIterations('lastname'), 1);
    expect(ctx.getValue('name'), 'Γιώργος');
    expect(ctx.getValue('lastname'), 'Βαλοτάσιος');
  });
}

class _Person {
  final name;
  final lastname;
  
  _Person(this.name, this.lastname);
}