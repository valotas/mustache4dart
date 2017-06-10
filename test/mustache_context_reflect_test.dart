library mustache_context_tests;

import 'dart:mirrors' as mirrors;
import 'package:test/test.dart';
import 'package:mustache4dart/src/mirrors.dart';

@mirrors.MirrorsUsed()
class Person {
  final String name;
  final String lastname;
  final Person parent;

  Person(this.name, {this.lastname = null, this.parent = null});

  get fullname {
    return "$name $lastname";
  }

  getFullnameWithInitial() {
    final initial = this.parent.name[0].toUpperCase();
    return "$name $initial. $lastname";
  }
}

class ClassWithLambda {
  final int num;

  ClassWithLambda(this.num);

  lambdaWithArity1(str) => "[[$str $num]]";
}

@mirrors.MirrorsUsed()
class ClassWithBrackets {
  operator [](String input) {
    return new Person(input);
  }
}

void main() {
  group('reflect', () {
    test('returns a mirror object', () {
      var cat = new Person("cat");
      expect(reflect(cat), isNotNull);
    });

    group('field', () {
      test('should return an object', () {
        var cat = new Person("cat");

        var actual = reflect(cat).field('name');

        expect(actual, isNotNull);
        expect(actual, new isInstanceOf<Field>());
      });

      group(".exists", () {
        final cat = new Person("cat");

        test('returns true if the field exists', () {
          expect(reflect(cat).field('name').exists, isTrue);
        });

        test('returns true if the getter exists', () {
          expect(reflect(cat).field('fullname').exists, isTrue);
        });

        test('returns true if the get method exists', () {
          expect(reflect(cat).field('fullnameWithInitial').exists, isTrue);
        });

        test('returns false no field exists', () {
          expect(reflect(cat).field('fullnameWithInitial2').exists, isFalse);
        });
      });

      group(".val()", () {
        test('returns the value of a field', () {
          var cat = new Person("cat");

          var actual = reflect(cat);

          expect(actual.field('name').val(), "cat");
        });

        test('returns the value of a getter', () {
          var george = new Person("George", lastname: "Valotasios");

          var actual = reflect(george);

          expect(actual.field('fullname').val(), "George Valotasios");
        });

        test('returns the value of a get method', () {
          var george = new Person("George",
              lastname: "Valotasios", parent: new Person("Thomas"));

          var actual = reflect(george);

          expect(actual.field('fullnameWithInitial').val(),
              "George T. Valotasios");
        });

        test('returns the value from a [] operator', () {
          final object = new ClassWithBrackets();

          final actual = reflect(object).field('xyz');

          expect(actual.val(), isNotNull);
          expect(actual.val(), new isInstanceOf<Person>());
          expect(actual.val().name, 'xyz');
        }, onPlatform: {
          "js": new Skip("[] operator can not be reflected in javascript")
        });

        test('returns always a reference to the value', () {
          var thomas = new Person("Thomas");
          var george =
              new Person("George", lastname: "Valotasios", parent: thomas);

          var actual = reflect(george);

          expect(actual.field('parent').val(), thomas);
        });

        test('returns a ref to the function if it has an arity of 1', () {
          final labmbda = new ClassWithLambda(1);

          final actual = reflect(labmbda).field('lambdaWithArity1');

          expect(actual.val(), new isInstanceOf<Function>());
          expect(actual.val()("-"), "[[- 1]]");
        });
      });
    });
  });
}
