library mustache_context;

import 'dart:collection';

import 'package:mustache4dart/src/mirrors.dart';

const String DOT = '\.';

typedef NoParamLambda();
typedef OptionalParamLambda({nestedContext});
typedef TwoParamLambda(String s, {nestedContext});

abstract class MustacheContext {
  factory MustacheContext(ctx,
      {MustacheContext parent, errorOnMissingProperty: false}) {
    return _createMustacheContext(ctx,
        parent: parent, errorOnMissingProperty: errorOnMissingProperty);
  }

  get ctx;

  value([arg]);

  bool get isFalsey;

  bool get isLambda;

  MustacheContext field(String key);

  MustacheContext _getMustacheContext(String key);
}

_createMustacheContext(obj,
    {MustacheContext parent, bool errorOnMissingProperty}) {
  if (obj is Iterable) {
    return new _IterableMustacheContextDecorator(obj,
        parent: parent, errorOnMissingProperty: errorOnMissingProperty);
  }
  if (obj == false) {
    return falseyContext;
  }
  return new _MustacheContext(obj,
      parent: parent, errorOnMissingProperty: errorOnMissingProperty);
}

final falseyContext = new _MustacheContext(false);

class _MustacheContext implements MustacheContext {
  final ctx;
  final _MustacheContext parent;
  final bool errorOnMissingProperty;
  Reflection _ctxReflection;

  _MustacheContext(this.ctx,
      {_MustacheContext this.parent, this.errorOnMissingProperty});

  bool get isLambda => ctx is Function;

  bool get isFalsey => ctx == null || ctx == false;

  value([arg]) => isLambda ? callLambda(arg) : ctx.toString();

  callLambda(arg) {
    if (ctx is NoParamLambda) {
      return ctx is OptionalParamLambda ? ctx(nestedContext: this) : ctx();
    }
    if (ctx is TwoParamLambda) {
      return ctx(arg, nestedContext: this);
    }
    return ctx(arg);
  }

  MustacheContext field(String key) {
    if (ctx == null) return null;
    return _getInThisOrParent(key);
  }

  MustacheContext _getInThisOrParent(String key) {
    var result = _getContextForKey(key);

    if (result == null) {
      final hasSlot = ctxReflector.field(key).exists;
      if (errorOnMissingProperty && !hasSlot && parent == null) {
        throw new StateError('Could not find "$key" in given context');
      }

      //if the result is null, try the parent context
      if (!hasSlot && parent != null) {
        result = parent.field(key);
        if (result != null) {
          return _createChildMustacheContext(result.ctx);
        }
      }
    }
    return result;
  }

  MustacheContext _getContextForKey(String key) {
    if (key == DOT) {
      return this;
    }
    final Iterator<String> i = key.split(DOT).iterator;
    var val = this;
    while (i.moveNext()) {
      val = val._getMustacheContext(i.current);
      if (val == null) {
        return null;
      }
    }
    return val;
  }

  MustacheContext _getMustacheContext(String fieldName) {
    final v = ctxReflector.field(fieldName).val();
    return _createChildMustacheContext(v);
  }

  _createChildMustacheContext(obj) {
    if (obj == null) {
      return null;
    }
    return _createMustacheContext(obj,
        parent: this, errorOnMissingProperty: this.errorOnMissingProperty);
  }

  Reflection get ctxReflector {
    if (_ctxReflection == null) {
      _ctxReflection = reflect(ctx);
    }
    return _ctxReflection;
  }
}

class _IterableMustacheContextDecorator extends IterableBase<_MustacheContext>
    implements MustacheContext {
  final Iterable ctx;
  final _MustacheContext parent;
  final bool errorOnMissingProperty;

  _IterableMustacheContextDecorator(this.ctx,
      {this.parent, this.errorOnMissingProperty});

  value([arg]) =>
      throw new Exception('Iterable can not be called as a function');

  Iterator<_MustacheContext> get iterator =>
      new _MustacheContextIteratorDecorator(ctx.iterator,
          parent: parent, errorOnMissingProperty: errorOnMissingProperty);

  int get length => ctx.length;

  bool get isEmpty => ctx.isEmpty;

  bool get isFalsey => isEmpty;

  bool get isLambda => false;

  field(String key) {
    assert(key ==
        DOT); // 'Iterable can only be iterated. No [] implementation is available'
    return this;
  }

  _getMustacheContext(String key) {
    // 'Iterable can only be asked for empty or isEmpty keys or be iterated'
    assert(key == 'empty' || key == 'isEmpty');
    return new _MustacheContext(isEmpty, parent: parent);
  }
}

class _MustacheContextIteratorDecorator extends Iterator<_MustacheContext> {
  final Iterator delegate;
  final _MustacheContext parent;
  final bool errorOnMissingProperty;

  _MustacheContext current;

  _MustacheContextIteratorDecorator(this.delegate,
      {this.parent, this.errorOnMissingProperty});

  bool moveNext() {
    if (delegate.moveNext()) {
      current = new _MustacheContext(delegate.current,
          parent: parent, errorOnMissingProperty: errorOnMissingProperty);
      return true;
    } else {
      current = null;
      return false;
    }
  }
}
