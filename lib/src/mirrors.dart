import 'package:reflectable/reflectable.dart';

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);

class MustacheContext extends Reflectable {
  const MustacheContext()
      : super(
          declarationsCapability,
          invokingCapability,
          typeAnnotationQuantifyCapability,
          typeRelationsCapability,
        );
}

const _reflector = const MustacheContext();
final _stringType = _reflector.reflectType(String);

Reflection reflect(o, {bool useMirrors: USE_MIRRORS}) {
  if (o is Map) {
    return new MapReflection(o);
  }
  if (useMirrors && USE_MIRRORS) {
    return new Mirror(o, _reflector.reflect(o));
  }

  // in any other case fallback to a mirrorless reflection
  return new Reflection(o);
}

class Reflection {
  final dynamic object;

  Reflection(this.object);

  Field field(String name) {
    return new _BracketsField(object, name);
  }
}

class Field {
  const Field();

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
      return new _BracketsField(map, name, existingKey: true);
    }
    return _noField;
  }
}

const _noField = const Field();
const _bracketsOperator = "[]";

class Mirror extends Reflection {
  final InstanceMirror instanceMirror;

  Mirror(object, this.instanceMirror) : super(object);

  Field field(String name) {
    final Map<String, MethodMirror> members =
        instanceMirror.type.instanceMembers;
    if (_isStringAssignableToBracketsOperator(members)) {
      return new _BracketsField(object, name);
    }
    final methodMirror = members[name];
    if (methodMirror == null) {
      return _noField;
    }
    return new _MethodMirrorField(this.instanceMirror, methodMirror);
  }

  _isStringAssignableToBracketsOperator(Map<String, MethodMirror> members) {
    if (!members.containsKey(_bracketsOperator)) {
      return false;
    }
    try {
      MethodMirror m = members[_bracketsOperator];
      return _stringType.isAssignableTo(m.parameters[0].type);
    } catch (e) {
      return false;
    }
  }
}

class _MethodMirrorField extends Field {
  final InstanceMirror instance;
  final MethodMirror method;

  _MethodMirrorField(this.instance, this.method);

  bool get exists => isVariable || isGetter || isLambda;

  bool get isGetter => method.isGetter;

  bool get isVariable => method is VariableMirror;

  bool get isLambda => method.parameters.length >= 0;

  val() {
    if (!exists) {
      return null;
    }
    if (isGetter) {
      return instance.invokeGetter(method.simpleName);
    }
    // isLambda
    return (input) => instance.invoke(method.simpleName, [input]);
  }
}

const Object empty = const Object();

class _BracketsField extends Field {
  final dynamic objectWithBracketsOperator;
  final String key;
  final bool existingKey;
  var value;

  _BracketsField(this.objectWithBracketsOperator, this.key,
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
