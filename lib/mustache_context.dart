library mustache_context;

import 'dart:collection';

@MirrorsUsed(symbols: '*')
import 'dart:mirrors';

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);
const String DOT = '\.';

abstract class MustacheContext {

  factory MustacheContext(ctx, [MustacheContext parent]) {
    if (ctx is Iterable) {
      return new _IterableMustacheContextDecorator(ctx, parent);
    }
    return new _MustacheContext(ctx, parent);
  }
  
  call([arg]);

  bool get isFalsey;
  bool get isLambda;
  MustacheContext operator [](String key);
  String get rootContextString;
}

abstract class MustacheToString {
  final ctx;
  final MustacheContext parent;

  String get rootContextString => parent == null ? ctx.toString() : parent.rootContextString;
}

class _MustacheContext extends MustacheToString implements MustacheContext {
  static final FALSEY_CONTEXT = new _MustacheContext(false);
  final ctx;
  final _MustacheContext parent;
  bool useMirrors = USE_MIRRORS;
  _ObjectReflector _ctxReflector;

  _MustacheContext(this.ctx, [_MustacheContext this.parent]);

  bool get isLambda => ctx is Function;
  
  bool get isFalsey => ctx == null || ctx == false;

  call([arg]) => isLambda ? ctx(arg) : ctx.toString();

  operator [](String key) {
    if (ctx == null) return null;
    return _getInThisOrParent(key);
  }
  
  _getInThisOrParent(String key) {
    var result = _getContextForKey(key);
    //if the result is null, try the parent context
    if (result == null && parent != null) {
      result = parent[key];
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
      while(i.moveNext()) {
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
      return new _IterableMustacheContextDecorator(v, this);
    }
    if (v == false) {
      return FALSEY_CONTEXT;
    }
    return new _MustacheContext(v, this);
  }
  
  _getActualValue(String key) {
    try {
      return ctx[key];
    } catch (NoSuchMethodError) {
      //Try to make dart2js understand that when we define USE_MIRRORS = false
      //we do not want to use any reflector
      return (useMirrors && USE_MIRRORS) ? ctxReflector[key] : null;
    } 
  }
  
  get ctxReflector {
    if (_ctxReflector == null) {
      _ctxReflector = new _ObjectReflector(ctx);
    }
    return _ctxReflector;
  }
    
  String toString() => "MustacheContext($ctx, $parent)";
}

class _IterableMustacheContextDecorator extends IterableBase<_MustacheContext> with MustacheToString implements MustacheContext {
  final Iterable ctx;
  final _MustacheContext parent;
  
  _IterableMustacheContextDecorator(this.ctx, this.parent);
  
  call([arg]) => throw new Exception('Iterable can be called as a function');
  
  Iterator<_MustacheContext> get iterator => new _MustachContextIteratorDecorator(ctx.iterator, parent);
  
  int get length => ctx.length;
  
  bool get isEmpty => ctx.isEmpty;
  
  bool get isFalsey => isEmpty;
  
  bool get isLambda => false;
  
  operator [](String key) {
    if (key == DOT) {
      return this;
    }
    throw new Exception('Iterable can only be iterated. No [] implementation is available');
  }
}



class _MustachContextIteratorDecorator extends Iterator<_MustacheContext> {
  final Iterator delegate;
  final _MustacheContext parent;
  
  _MustacheContext current;
  
  _MustachContextIteratorDecorator(this.delegate, this.parent);
  
  bool moveNext() {
    if (delegate.moveNext()) {
      current = new _MustacheContext(delegate.current, parent);
      return true;
    } else {
      current = null;
      return false;
    }
  }
}

/**
 * Helper class which given an object it will try to get a value by key analyzing
 * the object by reflection
 */
class _ObjectReflector {
  final InstanceMirror m;
  
  factory _ObjectReflector(o) {
    return new _ObjectReflector._(reflect(o));
  }
  
  _ObjectReflector._(this.m);
  
  operator [](String key) {
    var declaration = new _ObjectReflectorDeclaration(m, key);
    
    if (declaration == null) {
      return null;
    }
    
    return declaration.value;
  }
}

class _ObjectReflectorDeclaration {
  final InstanceMirror mirror;
  final MethodMirror declaration;
  
  factory _ObjectReflectorDeclaration(InstanceMirror m, String declarationName) {
    var methodMirror = m.type.instanceMembers[new Symbol(declarationName)];
    if (methodMirror == null) {
      //try appending the word get to the name:
      var nameWithGet = "get${declarationName[0].toUpperCase()}${declarationName.substring(1)}";
      methodMirror = m.type.instanceMembers[new Symbol(nameWithGet)];
    }
    return methodMirror == null ? null : new _ObjectReflectorDeclaration._(m, methodMirror);
  }
  
  _ObjectReflectorDeclaration._(this.mirror, this.declaration);
  
  bool get isLambda => declaration.parameters.length == 1;
  
  Function get lambda => (val) {
    var im = mirror.invoke(declaration.simpleName, [val]);
    if (im is InstanceMirror) {
      var r = im.reflectee;
      return r;
     }
     else {
      return null;
     }
  };
  
  get value {
    if (isLambda) {
      return lambda;
    }
    
    //Now we try to find out a field or a getter named after the given name
    var im = null;
    if (isVariableOrGetter) {
      im = mirror.getField(declaration.simpleName);
    }
    else if (isParameterlessMethod) {
      im = mirror.invoke(declaration.simpleName, []);
    }
    if (im != null && im is InstanceMirror) {
      return im.reflectee;
    }
    return null;
  }
  
  //TODO check if we really need the declation is VariableMirror test
  bool get isVariableOrGetter => (declaration is VariableMirror) || (declaration is MethodMirror && declaration.isGetter);
  
  bool get isParameterlessMethod => declaration is MethodMirror && declaration.parameters.length == 0;
}