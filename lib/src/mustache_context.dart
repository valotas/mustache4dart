part of mustache4dart;

class MustacheContext {
  static const String DOT = '\.';
  final Map cache = {}; 
  final ctx;
  MustacheContext other;

  MustacheContext(this.ctx, [MustacheContext this.other]);

  String asString() => ctx.toString();

  operator [](String key) {
    if (ctx == null) return null;
    var result = cache[key];
    if (result == null) {
      result = _getInThisOrOtherContext(key);
      if (result != null) {
        cache[key] = result;
      }
    }
    return result;
  }
  
  _getInThisOrOtherContext(String key) {
    var result = _get(key);
    
    //if the result is null, try the other context
    if (result == null && other != null) {
      result = other[key];
      if (result != null && result is MustacheContext && !identical(result, this)) {
        result.other = this;
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
    if (v is Function) {
      return v;
    }
    return new MustacheContext(v, this);
  }
  
  _getValue(String key) {
    try {
      return ctx[key];
    } catch (NoSuchMethodError) {
      return _getValueWithReflection(key);
    } 
  }

  _getValueWithReflection(String key) {
    var m = mirror;
    var membersMirror = _findMemberMirror(m, key);
    
    if (membersMirror == null) {
      return null;
    }
    
    if (membersMirror is MethodMirror && membersMirror.parameters.length == 1) {
      //this is the case of a lambda value
      return _toFuncion(m, membersMirror.simpleName); 
    }
    
    //Now we try to find out a field or a getter named after the given name
    var im = null;
    if (membersMirror is VariableMirror) {
      im = m.getField(membersMirror.simpleName);
    }
    else if (membersMirror is MethodMirror && membersMirror.isGetter) {
      im = m.getField(membersMirror.simpleName);
    }
    else if (membersMirror is MethodMirror && membersMirror.parameters.length == 0) {
      im = m.invoke(membersMirror.simpleName, []);
    }
    if (im != null && im is InstanceMirror) {
      return im.reflectee;
    }
    return null;
  }
  
  InstanceMirror get mirror => reflect(ctx);
  
  static _findMemberMirror(InstanceMirror m, String memberName) {
    var members = m.type.members;
    //members.forEach( (s, v) => print("${s} - ${v}"));
    var membersMirror = members[new Symbol(memberName)];
    if (membersMirror == null) {
      //try out a getter:
      memberName = "get${memberName[0].toUpperCase()}${memberName.substring(1)}";
      membersMirror = members[new Symbol(memberName)];
    }
    return membersMirror;
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
  
  String toString() => "MustacheContext($ctx, $other)";
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
