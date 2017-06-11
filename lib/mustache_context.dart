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
  Mirror _ctxReflection;

  _MustacheContext(this.ctx,
      {_MustacheContext this.parent, this.assumeNullNonExistingProperty});

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
      Iterator<String> i = key
          .split(DOT)
          .iterator;
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
    if (assumeNullNonExistingProperty) {
      return false;
    }
    if (ctx is Map) {
      return (ctx as Map).containsKey(key);
    } else if (useMirrors && USE_MIRRORS) {
      //TODO test the case of no mirrors
      return ctxReflector
          .field(key)
          .exists;
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
