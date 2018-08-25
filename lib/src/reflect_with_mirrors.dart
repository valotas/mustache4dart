import 'dart:mirrors' as mirrors;
import "./reflect.dart";

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);

const _bracketsOperator = Symbol("[]");

class MustacheContext extends mirrors.MirrorsUsed {
  const MustacheContext();
}

Reflection createReflection(o) {
  try {
    if (USE_MIRRORS) {
      return new Mirror(o, mirrors.reflect(o));
    }
    return null;
  } catch (e) {
    return null;
  }
}

class Mirror extends Reflection {
  final mirrors.InstanceMirror instanceMirror;

  Mirror(object, this.instanceMirror) : super(object);

  Field field(String name) {
    final Map<Symbol, mirrors.MethodMirror> members =
        _instanceMembers(instanceMirror);
    if (_isStringAssignableToBracketsOperator(members)) {
      return new BracketsField(object, name);
    }
    final methodMirror = members[new Symbol(name)];
    if (methodMirror == null) {
      return noField;
    }
    return new _MethodMirrorField(this.instanceMirror, methodMirror);
  }

  Map<Symbol, mirrors.MethodMirror> _instanceMembers(mirrors.InstanceMirror m) {
    if (m != null && m.type != null) {
      return m.type.instanceMembers;
    }
    return null;
  }

  _isStringAssignableToBracketsOperator(
      Map<Symbol, mirrors.MethodMirror> members) {
    if (!members.containsKey(_bracketsOperator)) {
      return false;
    }
    try {
      mirrors.MethodMirror m = members[_bracketsOperator];
      return mirrors.reflectType(String).isAssignableTo(m.parameters[0].type);
    } catch (e) {
      return false;
    }
  }
}

class _MethodMirrorField extends Field {
  final mirrors.InstanceMirror instance;
  final mirrors.MethodMirror method;

  _MethodMirrorField(this.instance, this.method);

  bool get exists => isVariable || isGetter || isLambda;

  bool get isGetter => method.isGetter;

  bool get isVariable => method is mirrors.VariableMirror;

  bool get isLambda => method.parameters.length >= 0;

  val() {
    if (!exists) {
      return null;
    }
    final resultMirror = instance.getField(method.simpleName);
    return resultMirror.reflectee;
  }
}
