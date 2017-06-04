library mustache_context;

import 'dart:collection';

@MirrorsUsed(symbols: '*')
import 'dart:mirrors';

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);
const String DOT = '\.';

typedef NoParamLambda();
typedef OptionalParamLambda({nestedContext});
typedef TwoParamLambda(String s, {nestedContext});

abstract class MustacheContext {
  factory MustacheContext(ctx,
      {MustacheContext parent, assumeNullNonExistingProperty: true}) {
    if (ctx is Iterable) {
      return new _IterableMustacheContextDecorator(ctx,
          parent: parent,
          assumeNullNonExistingProperty: assumeNullNonExistingProperty);
    }
    return new _MustacheContext(ctx,
        parent: parent,
        assumeNullNonExistingProperty: assumeNullNonExistingProperty);
  }

  value([arg]);

  bool get isFalsey;

  bool get isLambda;

  MustacheContext field(String key);

  MustacheContext _getMustachContext(String key);
}

class _MustacheContext implements MustacheContext {
  static final FALSEY_CONTEXT = new _MustacheContext(false);

  final ctx;
  final _MustacheContext parent;
  final bool assumeNullNonExistingProperty;
  bool useMirrors = USE_MIRRORS;
  _ObjectReflector _ctxReflector;

  _MustacheContext(this.ctx,
      {_MustacheContext this.parent, this.assumeNullNonExistingProperty});

  bool get isLambda => ctx is Function;

  bool get isFalsey => ctx == null || ctx == false;

  value([arg]) => isLambda ? callLambda(arg) : ctx.toString();

  callLambda(arg) => ctx is NoParamLambda
      ? ctx()
      : ctx is TwoParamLambda
          ? ctx(arg, nestedContext: this)
          : ctx is OptionalParamLambda ? ctx(nestedContext: this) : ctx(arg);

  field(String key) {
    if (ctx == null) return null;
    return _getInThisOrParent(key);
  }

  _getInThisOrParent(String key) {
    var result = _getContextForKey(key);
    //if the result is null, try the parent context
    if (result == null && !_hasActualValueSlot(key) && parent != null) {
      result = parent.field(key);
      if (result != null) {
        return _newMustachContextOrNull(result.ctx);
      }
    }
    return result;
  }

  _getContextForKey(String key) {
    if (key == DOT) {
      return this;
    }
    if (key.contains(DOT)) {
      Iterator<String> i = key.split(DOT).iterator;
      var val = this;
      while (i.moveNext()) {
        val = val._getMustachContext(i.current);
        if (val == null) {
          return null;
        }
      }
      return val;
    }
    //else
    return _getMustachContext(key);
  }

  _getMustachContext(String key) {
    var v = _getActualValue(key);
    return _newMustachContextOrNull(v);
  }

  _newMustachContextOrNull(v) {
    if (v == null) {
      return null;
    }
    if (v is Iterable) {
      return new _IterableMustacheContextDecorator(v,
          parent: this,
          assumeNullNonExistingProperty: this.assumeNullNonExistingProperty);
    }
    if (v == false) {
      return FALSEY_CONTEXT;
    }
    return new _MustacheContext(v,
        parent: this,
        assumeNullNonExistingProperty: assumeNullNonExistingProperty);
  }

  dynamic _getActualValue(String key) {
    if (useMirrors && USE_MIRRORS) {
      return ctxReflector[key];
    } else {
      try {
        return ctx[key];
      } catch (NoSuchMethodError) {
        return null;
      }
    }
  }

  bool _hasActualValueSlot(String key) {
    if (assumeNullNonExistingProperty) {
      return false;
    }
    if (ctx is Map) {
      return (ctx as Map).containsKey(key);
    } else if (useMirrors && USE_MIRRORS) {
      //TODO test the case of no mirrors
      return ctxReflector.hasSlot(key);
    }
    return false;
  }

  get ctxReflector {
    if (_ctxReflector == null) {
      _ctxReflector = new _ObjectReflector(ctx);
    }
    return _ctxReflector;
  }

  String toString() => "MustacheContext($ctx, $parent)";
}

class _IterableMustacheContextDecorator extends IterableBase<_MustacheContext>
    implements MustacheContext {
  final Iterable ctx;
  final _MustacheContext parent;
  final bool assumeNullNonExistingProperty;

  _IterableMustacheContextDecorator(this.ctx,
      {this.parent, this.assumeNullNonExistingProperty});

  value([arg]) =>
      throw new Exception('Iterable can not be called as a function');

  Iterator<_MustacheContext> get iterator =>
      new _MustachContextIteratorDecorator(ctx.iterator,
          parent: parent,
          assumeNullNonExistingProperty: assumeNullNonExistingProperty);

  int get length => ctx.length;

  bool get isEmpty => ctx.isEmpty;

  bool get isFalsey => isEmpty;

  bool get isLambda => false;

  field(String key) {
    if (key == DOT) {
      return this;
    }
    throw new Exception(
        'Iterable can only be iterated. No [] implementation is available');
  }

  _getMustachContext(String key) {
    if (key == 'empty' || key == 'isEmpty') {
      return new _MustacheContext(isEmpty,
          parent: parent,
          assumeNullNonExistingProperty: assumeNullNonExistingProperty);
    }
    throw new Exception(
        'Iterable can only be asked for empty or isEmpty keys or be iterated');
  }
}

class _MustachContextIteratorDecorator extends Iterator<_MustacheContext> {
  final Iterator delegate;
  final _MustacheContext parent;
  final bool assumeNullNonExistingProperty;

  _MustacheContext current;

  _MustachContextIteratorDecorator(this.delegate,
      {this.parent, this.assumeNullNonExistingProperty});

  bool moveNext() {
    if (delegate.moveNext()) {
      current = new _MustacheContext(delegate.current,
          parent: parent,
          assumeNullNonExistingProperty: assumeNullNonExistingProperty);
      return true;
    } else {
      current = null;
      return false;
    }
  }
}

final Symbol BRACKETS_OPERATOR = new Symbol("[]");
final STRING_TYPE = reflectType(String);

/**
 * Helper class which given an object it will try to get a value by key analyzing
 * the object by reflection
 */
class _ObjectReflector {
  final InstanceMirror m;
  final dynamic object;

  factory _ObjectReflector(o) {
    return new _ObjectReflector._(o, reflect(o));
  }

  _ObjectReflector._(this.object, this.m);

  operator [](String key) {
    var fieldWithValue = fieldValue(key);

    if (fieldWithValue == null) {
      return null;
    }

    return fieldWithValue.value;
  }

  bool hasSlot(String key) {
    return fieldValue(key) != null;
  }

  _FieldValue fieldValue(String key) {
    var bracketsOp = m.type.instanceMembers[BRACKETS_OPERATOR];
    if (bracketsOp != null &&
        STRING_TYPE.isAssignableTo(bracketsOp.parameters[0].type)) {
      return new _BracketsValue(object, key);
    }
    return new _ObjectReflectorDeclaration(m, key);
  }
}

abstract class _FieldValue {
  get value;
}

class _BracketsValue extends _FieldValue {
  var value;

  _BracketsValue(objectWithBracketsOperator, String key) {
    this.value = objectWithBracketsOperator[key];
  }
}

class _ObjectReflectorDeclaration extends _FieldValue {
  final InstanceMirror mirror;
  final MethodMirror declaration;

  factory _ObjectReflectorDeclaration(
      InstanceMirror m, String declarationName) {
    var methodMirror = m.type.instanceMembers[new Symbol(declarationName)];
    if (methodMirror == null) {
      //try appending the word get to the name:
      var nameWithGet =
          "get${declarationName[0].toUpperCase()}${declarationName.substring(
          1)}";
      methodMirror = m.type.instanceMembers[new Symbol(nameWithGet)];
    }
    return methodMirror == null
        ? null
        : new _ObjectReflectorDeclaration._(m, methodMirror);
  }

  _ObjectReflectorDeclaration._(this.mirror, this.declaration);

  bool get isLambda => declaration.parameters.length >= 1;

  Function get lambda => (val, {MustacheContext nestedContext}) {
        var im = mirror.invoke(
            declaration.simpleName,
            _createPositionalArguments(val),
            _createNamedArguments(nestedContext));
        return im is InstanceMirror ? im.reflectee : null;
      };

  _createPositionalArguments(val) {
    var positionalParam = declaration.parameters
        .firstWhere((p) => !p.isOptional, orElse: () => null);
    if (positionalParam == null) {
      return [];
    } else {
      return [val];
    }
  }

  Map<Symbol, dynamic> _createNamedArguments(MustacheContext ctx) {
    var map = new Map<Symbol, dynamic>();
    var nestedContextParameterExists = declaration.parameters.firstWhere(
        (p) => p.simpleName == new Symbol('nestedContext'),
        orElse: () => null);
    if (nestedContextParameterExists != null) {
      map[nestedContextParameterExists.simpleName] = ctx;
    }
    return map;
  }

  get value {
    if (isLambda) {
      return lambda;
    }

    //Now we try to find out a field or a getter named after the given name
    var im = null;
    if (isVariableOrGetter) {
      im = mirror.getField(declaration.simpleName);
    } else if (isParameterlessMethod) {
      im = mirror.invoke(declaration.simpleName, []);
    }
    if (im != null && im is InstanceMirror) {
      return im.reflectee;
    }
    return null;
  }

  //TODO check if we really need the declaration is VariableMirror test
  bool get isVariableOrGetter =>
      (declaration is VariableMirror) ||
      (declaration is MethodMirror && declaration.isGetter);

  bool get isParameterlessMethod =>
      declaration is MethodMirror && declaration.parameters.length == 0;
}
