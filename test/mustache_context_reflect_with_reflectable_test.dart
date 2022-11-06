import 'package:test/test.dart';
import 'package:mustache4dart/src/reflect.dart';
import "mustache_context_reflect_with_reflectable_test.reflectable.dart";

@MustacheContext()
class Person {
  final String name;
  final String lastname;
  final Person parent;
  Person(this.name, {this.lastname: null, this.parent: null});
  get fullname {
    return "$name $lastname";
  }

  getFullnameWithInitial() {
    final initial = this.parent.name[0].toUpperCase();
    return "$name $initial. $lastname";
  }
}

@MustacheContext()
class ClassWithLambda {
  final int num;
  ClassWithLambda(this.num);
  lambdaWithArity1(str) => "[[$str $num]]";
}

@MustacheContext()
class ClassWithBrackets {
  operator [](String input) {
    if (input == 'nullval') {
      return null;
    }
    return new Person(input);
  }
}

void main() {
  initializeReflectable();

  group('reflect', () {
    test('returns a mirror object', () {
      final cat = new Person("cat");
      expect(reflect(cat), isNotNull);
    });
    group('field([name])', () {
      test('should return an object', () {
        final cat = new Person("cat");
        final actual = reflect(cat).field('name');
        expect(actual, isNotNull);
        expect(actual, TypeMatcher<Field>());
      });
      group(".exists", () {
        final cat = new Person("cat");
        test('returns true if the field exists', () {
          expect(reflect(cat).field('name').exists, isTrue);
        });
        test('returns true if the getter exists', () {
          expect(reflect(cat).field('fullname').exists, isTrue);
        });
        test('returns false if the method does not exist', () {
          expect(reflect(cat).field('fullnameWithInitial').exists, isFalse);
        });
        test('returns false if no field exists', () {
          expect(reflect(cat).field('xyz').exists, isFalse);
        });
        test('returns false if [] operator returns a null value', () {
          expect(reflect(new ClassWithBrackets()).field('nullval').exists,
              isFalse);
        });
        test('returns true for map containing a field with a null value', () {
          expect(reflect({'a': null}).field('a').exists, isTrue);
        });
      });
      group(".val()", () {
        test('returns the value of a field', () {
          final cat = new Person("cat");
          final actual = reflect(cat);
          expect(actual.field('name').val(), "cat");
        });
        test('returns the value of a getter', () {
          final george = new Person("George", lastname: "Valotasios");
          final actual = reflect(george);
          expect(actual.field('fullname').val(), "George Valotasios");
        });
        test('does not returns the value of a get methods', () {
          final george = new Person("George",
              lastname: "Valotasios", parent: new Person("Thomas"));
          final actual = reflect(george);
          expect(actual.field('fullnameWithInitial').exists, isFalse);
        });
        test('returns the value from a [] operator', () {
          final object = new ClassWithBrackets();
          final actual = reflect(object).field('xyz');
          expect(actual.val(), isNotNull);
          expect(actual.val(), TypeMatcher<Person>());
          expect(actual.val().name, 'xyz');
        }, onPlatform: {
          "js": new Skip("[] operator can not be reflected in javascript")
        });
        test('returns always a reference to the value', () {
          final thomas = new Person("Thomas");
          final george =
              new Person("George", lastname: "Valotasios", parent: thomas);
          final actual = reflect(george);
          expect(actual.field('parent').val(), thomas);
        });
        test('returns a ref to the function if it has an arity of 1', () {
          final labmbda = new ClassWithLambda(1);
          final actual = reflect(labmbda).field('lambdaWithArity1');
          expect(actual.val(), TypeMatcher<Function>());
          expect(actual.val()("-"), "[[- 1]]");
        });
      });
    });
    test('does not use reflection with Maps', () {
      final reflection = reflect({'name': "g"});
      expect(reflection, isNot(TypeMatcher<ReflMirror>()));
    });
  });
}