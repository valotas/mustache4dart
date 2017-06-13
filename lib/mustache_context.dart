library mustache_context;

import 'dart:collection';

import 'package:mustache4dart/src/mirrors.dart';

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);
const String DOT = '\.';

typedef NoParamLambda();
typedef OptionalParamLambda({nestedContext});
typedef TwoParamLambda(String s, {nestedContext});

abstract class MustacheContext {
  factory MustacheContext(ctx,
      {MustacheContext parent, errorOnMissingProperty: false}) {
    if (ctx is Iterable) {
      return new _IterableMustacheContextDecorator(ctx,
          parent: parent, errorOnMissingProperty: errorOnMissingProperty);
    }
    return new _MustacheContext(ctx,
        parent: parent, errorOnMissingProperty: errorOnMissingProperty);
  }

  get ctx;

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
  final bool errorOnMissingProperty;
  bool useMirrors = USE_MIRRORS;
  Mirror _ctxReflection;

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
    var hasSlot = _hasActualValueSlot(key);
    if (errorOnMissingProperty && !hasSlot && parent == null) {
      throw new StateError('Could not find "$key" in given context');
    }
    //if the result is null, try the parent context
    if (result == null && !hasSlot && parent != null) {
      result = parent.field(key);;
      if (result != null) {
        return _newMustachContextOrNull(result.ctx);
      }
    }
    return result;
  }

  MustacheContext _getContextForKey(String key) {
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

  MustacheContext _getMustachContext(String key) {
    final v = _getActualValue(key);
    return _newMustachContextOrNull(v);
  }

  MustacheContext _newMustachContextOrNull(v) {
    if (v == null) {
      return null;
    }
    if (v is Iterable) {
      return new _IterableMustacheContextDecorator(v,
          parent: this, errorOnMissingProperty: this.errorOnMissingProperty);
    }
    if (v == false) {
      return FALSEY_CONTEXT;
    }
    return new _MustacheContext(v,
        parent: this, errorOnMissingProperty: errorOnMissingProperty);
  }

  dynamic _getActualValue(String key) {
    if (ctx is Map) {
      return ctx[key];
    }
    if (useMirrors && USE_MIRRORS) {
      return ctxReflector.field(key).val();
    } else {
      try {
        return ctx[key];
      } catch (NoSuchMethodError) {
        return null;
      }
    }
  }

  bool _hasActualValueSlot(String key) {
    if (ctx is Map) {
      return (ctx as Map).containsKey(key);
    } else if (useMirrors && USE_MIRRORS) {
      //TODO test the case of no mirrors
      return ctxReflector.field(key).exists;
    }
    return false;
  }

  Mirror get ctxReflector {
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
      new _MustachContextIteratorDecorator(ctx.iterator,
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

  _getMustachContext(String key) {
    // 'Iterable can only be asked for empty or isEmpty keys or be iterated'
    assert(key == 'empty' || key == 'isEmpty');
    return new _MustacheContext(isEmpty,
        parent: parent,
        assumeNullNonExistingProperty: assumeNullNonExistingProperty);
  }
}

class _MustachContextIteratorDecorator extends Iterator<_MustacheContext> {
  final Iterator delegate;
  final _MustacheContext parent;
  final bool errorOnMissingProperty;

  _MustacheContext current;

  _MustachContextIteratorDecorator(this.delegate,
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
