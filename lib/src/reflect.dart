import "./reflect_with_reflector.dart"
    // ignore: uri_does_not_exist
    if (dart.library.mirrors) "./reflect_with_mirrors.dart";
export "./reflect_with_reflector.dart";

Reflection reflect(o) {
  if (o is Map) {
    return new MapReflection(o);
  }

  Reflection reflection = createReflection(o);
  if (reflection != null) {
    return reflection;
  }

  // in any other case fallback to a mirrorless reflection
  return new Reflection(o);
}

class Reflection {
  final dynamic object;

  Reflection(this.object);

  Field field(String name) {
    return new BracketsField(object, name);
  }
}

class Field {
  bool get exists {
    return false;
  }

  dynamic val() => null;
}

class MapReflection extends Reflection {
  final Map map;

  MapReflection(map)
      : this.map = map,
        super(map);

  Field field(String name) {
    if (map.containsKey(name)) {
      return new BracketsField(map, name, existingKey: true);
    }
    return noField;
  }
}

final noField = new Field();

const Object empty = const Object();

class BracketsField extends Field {
  final dynamic objectWithBracketsOperator;
  final String key;
  final bool existingKey;
  var value;

  BracketsField(this.objectWithBracketsOperator, this.key,
      {this.existingKey: false}) {
    this.value = empty;
  }

  bool get exists => existingKey || val() != null;

  val() {
    if (value == empty) {
      try {
        value = objectWithBracketsOperator[key];
      } catch (e) {
        value = null;
      }
    }
    return value;
  }
}
