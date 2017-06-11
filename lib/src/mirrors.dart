import 'dart:mirrors' as mirrors;

reflect(o) {
  return new Mirror(o, mirrors.reflect(o));
}

final bracketsOperator = new Symbol("[]");

class Mirror {
  final mirrors.InstanceMirror instanceMirror;
  final dynamic object;

  Mirror(this.object, this.instanceMirror);

  Field field(String name) {
    final Map<Symbol, mirrors.MethodMirror> members =
        _instanceMembers(instanceMirror);
    if (members == null) {
      return noField;
    }
    if (_isStringAssignableToBracketsOperator(members)) {
      return new BracketsField(object, name);
    }
    final methodMirror = members[new Symbol(name)];
    if (methodMirror == null) {
      return noField;
    }
    return new MethodMirrorField(this.instanceMirror, methodMirror);
  }
}

_instanceMembers(mirrors.InstanceMirror m) {
  if (m != null && m.type != null) {
    return m.type.instanceMembers;
  }
}

_isStringAssignableToBracketsOperator(
    Map<Symbol, mirrors.MethodMirror> members) {
  if (!members.containsKey(bracketsOperator)) {
    return false;
  }
  try {
    mirrors.MethodMirror m = members[bracketsOperator];
    return mirrors.reflectType(String).isAssignableTo(m.parameters[0].type);
  } catch (e) {
    return false;
  }
}

class Field {
  bool get exists {
    return false;
  }

  dynamic val() {
    return null;
  }
}

final noField = new Field();

class MethodMirrorField extends Field {
  final mirrors.InstanceMirror instance;
  final mirrors.MethodMirror method;

  MethodMirrorField(this.instance, this.method);

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

class BracketsField extends Field {
  var value;

  BracketsField(objectWithBracketsOperator, String key) {
    this.value = objectWithBracketsOperator[key];
  }

  bool get exists => value != null;

  val() {
    return value;
  }
}
