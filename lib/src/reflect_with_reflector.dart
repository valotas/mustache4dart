import 'package:reflectable/reflectable.dart' as reflectable;
import "./reflect.dart";

class MustacheContext extends reflectable.Reflectable {
  const MustacheContext()
      : super(
          reflectable.declarationsCapability,
          reflectable.invokingCapability,
          reflectable.typeAnnotationQuantifyCapability,
          reflectable.typeRelationsCapability,
        );
}

const _reflector = MustacheContext();

Reflection createReflection(o) {
  try {
    if (_reflector.canReflect(o)) {
      return _ReflectorMirror(o, _reflector.reflect(o));
    }
    return null;
  } catch (e) {
    return null;
  }
}

class _ReflectorMirror extends Reflection {
  static const _bracketsOperator = "[]";
  final _stringType = _reflector.reflectType(String);

  final reflectable.InstanceMirror instanceMirror;
  _ReflectorMirror(object, this.instanceMirror) : super(object);

  Field field(String name) {
    final Map<String, reflectable.MethodMirror> members =
        instanceMirror.type.instanceMembers;
    if (_isStringAssignableToBracketsOperator(members)) {
      return new BracketsField(object, name);
    }

    final methodMirror = members[name];
    if (methodMirror == null) {
      return noField;
    }
    return new _ReflectableMethodMirrorField(this.instanceMirror, methodMirror);
  }

  _isStringAssignableToBracketsOperator(
      Map<String, reflectable.MethodMirror> members) {
    if (!members.containsKey(_bracketsOperator)) {
      return false;
    }
    try {
      reflectable.MethodMirror m = members[_bracketsOperator];
      return m.parameters[0].type.reflectedType == _stringType.reflectedType;
    } catch (e) {
      return false;
    }
  }
}

class _ReflectableMethodMirrorField extends Field {
  final reflectable.InstanceMirror instance;
  final reflectable.MethodMirror method;
  _ReflectableMethodMirrorField(this.instance, this.method);
  bool get exists => isVariable || isGetter || isLambda;
  bool get isGetter => method.isGetter;
  bool get isVariable => method is reflectable.VariableMirror;
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
