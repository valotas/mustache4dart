part of mustache4dart;

class MustacheContext {
  static const String DOT = '\.';
  final Map cache = {}; 
  final ctx;
  MustacheContext _parent;

  MustacheContext(this.ctx, [MustacheContext this._parent]);
  
  bool get isLambda => ctx is Function;

  call([arg]) => isLambda ? ctx(arg) : ctx.toString();

  operator [](String key) {
    if (ctx == null) return null;
    var result = cache[key];
    if (result == null) {
      result = _getInThisOrParent(key);
      if (result != null) {
        cache[key] = result;
      }
    }
    return result;
  }
  
  _getInThisOrParent(String key) {
    var result = _get(key);
    
    //if the result is null, try the parent context
    if (result == null && _parent != null) {
      result = _parent[key];
      if (result != null && result is MustacheContext && !identical(result, this)) {
        result._parent = this;
      }
    }
    return result;
  }
  
  _get(String key) {
    if (key == DOT) {
      return this;
    }
    if (key.contains(DOT)) {
      Iterator<String> k = key.split(DOT).iterator;
      var val = this;
      while(k.moveNext()) {
        val = val._getValidValueOrContext(k.current);
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
    if (v == null) {
      return null;
    }
    if (v is Iterable) {
      if (v.isEmpty) {
        return null;
      }
      return new _IterableMustacheContextDecorator(v, this);
    }
    if (v == false) {
      return null;
    }
    return new MustacheContext(v, this);
  }
  
  _getValue(String key) {
    try {
      return ctx[key];
    } catch (NoSuchMethodError) {
      return new _ObjectReflector(ctx).get(key);
    } 
  }
    
  String toString() => "MustacheContext($ctx, $_parent)";
}

class _IterableMustacheContextDecorator extends IterableBase<MustacheContext> {
  final Iterable delegate;
  final MustacheContext other;
  
  _IterableMustacheContextDecorator(this.delegate, this.other);
  
  Iterator<MustacheContext> get iterator => new _MustachContextIteratorDecorator(delegate.iterator, other);
  
  int get length => delegate.length;
  
}

class _MustachContextIteratorDecorator extends Iterator<MustacheContext> {
  final Iterator delegate;
  final MustacheContext other;
  MustacheContext current;
  
  _MustachContextIteratorDecorator(this.delegate, this.other);
  
  bool moveNext() {
    if (delegate.moveNext()) {
      current = new MustacheContext(delegate.current);
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
  
  _ObjectReflector.fromMirror(this.m);
  
  factory _ObjectReflector(o) {
    return new _ObjectReflector.fromMirror(reflect(o));
  }
  
  get(String key) {
    var declarationMirror = _findMemberMirror(m, key);
    
    if (declarationMirror == null) {
      return null;
    }
    
    if (declarationMirror is MethodMirror && declarationMirror.parameters.length == 1) {
      //this is the case of a lambda value
      return _toFuncion(m, declarationMirror.simpleName); 
    }
    
    //Now we try to find out a field or a getter named after the given name
    var im = null;
    if (declarationMirror is VariableMirror) {
      im = m.getField(declarationMirror.simpleName);
    }
    else if (declarationMirror is MethodMirror && declarationMirror.isGetter) {
      im = m.getField(declarationMirror.simpleName);
    }
    else if (declarationMirror is MethodMirror && declarationMirror.parameters.length == 0) {
      im = m.invoke(declarationMirror.simpleName, []);
    }
    if (im != null && im is InstanceMirror) {
      return im.reflectee;
    }
    return null;
  }
  
  static DeclarationMirror _findMemberMirror(InstanceMirror m, String declarationName) {
    var declarations = m.type.declarations;
    //members.forEach( (s, v) => print("${s} - ${v}"));
    var declarationMirror = declarations[new Symbol(declarationName)];
    if (declarationMirror == null) {
      //try out a getter:
      declarationName = "get${declarationName[0].toUpperCase()}${declarationName.substring(1)}";
      declarationMirror = declarations[new Symbol(declarationName)];
    }
    return declarationMirror;
  }
  
  static Function _toFuncion(InstanceMirror mirror, Symbol method) {
    return (val) {
      var im = mirror.invoke(method, [val]);
      if (im is InstanceMirror) {
        var r = im.reflectee;
        return r;
      }
      else {
        return null;
      }
    };
  }
}