library mustache_context;

import 'dart:collection';

@MirrorsUsed(symbols: '*')
import 'dart:mirrors';

const USE_MIRRORS = const bool.fromEnvironment('MIRRORS', defaultValue: true);

class MustacheContext {
  static const String DOT = '\.';
  static final FALSEY_CONTEXT = new MustacheContext(false);
  final ctx;
  final MustacheContext parent;
  bool useMirrors = USE_MIRRORS;
  _ObjectReflector ctxReflector;

  MustacheContext(this.ctx, [MustacheContext this.parent]);

  bool get isLambda => ctx is Function;
  
  bool get isFalsey => ctx == null || ctx == false;

  call([arg]) => isLambda ? ctx(arg) : ctx.toString();

  operator [](String key) {
    if (ctx == null) return null;
    return _getInThisOrParent(key);
  }
  
  _getInThisOrParent(String key) {
    var result = _get(key);
    //if the result is null, try the parent context
    if (result == null && parent != null) {
      result = parent[key];
      if (result != null) {
        return _newMustachContextOrNull(result.ctx);        
      }
    }
    return result;
  }

  _get(String key) {
    if (key == DOT) {
      return this;
    }
    if (key.contains(DOT)) {
      Iterator<String> i = key.split(DOT).iterator;
      var val = this;
      while(i.moveNext()) {
        val = val._getValidValueOrContext(i.current);
        if (val == null) {
          return null;
        }
      }
      return val;
    }
    //else
    return _getValidValueOrContext(key);
  }
  
  _getValidValueOrContext(String key) {
    var v = _getValue(key);
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
    return new MustacheContext(v, this);
  }
  
  _getValue(String key) {
    try {
      return ctx[key];
    } catch (NoSuchMethodError) {
      //Try to make dart2js understand that when we define USE_MIRRORS = false
      //we do not want to use any reflector
      return (useMirrors && USE_MIRRORS) ? _ctxReflector[key] : null;
    } 
  }
  
  get _ctxReflector {
    if (ctxReflector == null) {
      ctxReflector = new _ObjectReflector(ctx);
    }
    return ctxReflector;
  }
    
  String toString() => "MustacheContext($ctx, $parent)";
}

class _IterableMustacheContextDecorator extends IterableBase<MustacheContext> {
  final Iterable ctx;
  final MustacheContext parent;
  
  _IterableMustacheContextDecorator(this.ctx, this.parent);
  
  Iterator<MustacheContext> get iterator => new _MustachContextIteratorDecorator(ctx.iterator, parent);
  
  int get length => ctx.length;
  
  bool get isEmpty => ctx.isEmpty;
  
  bool get isFalsey => isEmpty;
}



class _MustachContextIteratorDecorator extends Iterator<MustacheContext> {
  final Iterator delegate;
  final MustacheContext parent;
  
  MustacheContext current;
  
  _MustachContextIteratorDecorator(this.delegate, this.parent);
  
  bool moveNext() {
    if (delegate.moveNext()) {
      current = new MustacheContext(delegate.current, parent);
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
  final DeclarationMirror declaration;
  
  factory _ObjectReflectorDeclaration(InstanceMirror m, String declarationName) {
    var declarations = m.type.declarations;
    var declarationMirror = declarations[new Symbol(declarationName)];
    if (declarationMirror == null) {
      //try out a getter:
      declarationName = "get${declarationName[0].toUpperCase()}${declarationName.substring(1)}";
      declarationMirror = declarations[new Symbol(declarationName)];
    }
    return declarationMirror == null ? null : new _ObjectReflectorDeclaration._(m, declarationMirror);
  }
  
  _ObjectReflectorDeclaration._(this.mirror, this.declaration);
  
  bool get isLambda => declaration is MethodMirror && (declaration as MethodMirror).parameters.length == 1;
  
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
  
  bool get isVariableOrGetter => (declaration is VariableMirror) || (declaration is MethodMirror && (declaration as MethodMirror).isGetter);
  
  bool get isParameterlessMethod => declaration is MethodMirror && (declaration as MethodMirror).parameters.length == 0;
}