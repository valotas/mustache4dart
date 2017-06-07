library mustache_context_tests;

import 'package:test/test.dart';
import 'package:mustache4dart/src/mirrors.dart';

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

void main() {
  group('reflect', () {
    test('returns a mirror object', () {
      var cat = new Person("cat");
      expect(reflect(cat), isNotNull);
    });

    group('field', () {
      test('should return an object', () {
        var cat = new Person("cat");

        var actual = reflect(cat);

        expect(actual.field('name'), isNotNull);
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

          expect(actual.field('fullname').val(),
              "George Valotasios");
        });

        test('returns the value of a getter method', () {
          var george = new Person("George",
              lastname: "Valotasios",
              parent: new Person("Thomas"));

          var actual = reflect(george);

          expect(actual.field('fullnameWithInitial').val(),
              "George T. Valotasios");
        });

        test('returns the value from a [] operator', () {
          var george = {
            "name": "George"
          };

          var actual = reflect(george);

          expect(actual.field('name').val(), "George");
        });
      });
    });

    test(
        "isLambda == true when the object is a function" +
            "with more than one parameters", () {
      var f = (s) => "[$s]";

      var actual = reflect(f);

      expect(actual, isNotNull);
      expect(actual.isLambda, true);
    });
  });
}
