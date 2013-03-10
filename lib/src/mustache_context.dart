part of mustache4dart;

class MustacheContext {
  static const String DOT = '\.';
  final Map cache = {}; 
  final ctx;
  MustacheContext other;

  MustacheContext(this.ctx, [MustacheContext this.other]);

  operator [](String key) {
    var result = cache[key];
    if (result == null) {
      result = _compute(key);
      if (result != null) {
        cache[key] = result;
      }
    }
    return result;
  }
  
  _compute(String key) {
    var result = _get(key);
    if (result == null && other != null) {
      result = other[key];
      if (result != null && result is MustacheContext) {
        result.other = this;
      }
    }
    return result;
  }
  
  _get(String key) {
    if (key == DOT) {
      return ctx;
    }
    if (key.contains(DOT)) {
      Iterator<String> k = key.split(DOT).iterator;
      var val = this;
      while(k.moveNext()) {
        val = val._getContext(k.current);
        if (val == null) {
          return null;
        }
      }
      return val;
    }
    //else
    return _getContext(key);
  }
  
  _getContext(String key) {
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
    if (v == true) {
      return true;
    }
    if (v is Function) {
      return v;
    }
    if (v is num) {
      return "$v";
    }
    if (!(v is String)) {
      return new MustacheContext(v, this);
    }
    return v;
  }
  
  _getValue(String key) {
    try {
      var val = ctx[key];
      return val;
    } catch (NoSuchMethodError) {
      //There is no sync API as I see: http://code.google.com/p/dart/issues/detail?id=4633 
      //As I do not feel switching everything to Future at the moment, we use the 
      //deprecatedFutureValue as seen at 
      //http://code.google.com/p/dart/source/browse/experimental/lib_v2/dart/sdk/lib/_internal/dartdoc/lib/src/json_serializer.dart?spec=svn16262&r=16262
      var m = mirror;
      var membersMirror = _findMemberMirror(m, key);

      if (membersMirror == null) {
        return null;
      }
      
      var fim = null;
      if (membersMirror is VariableMirror) {
        fim = m.getField(key);
      }
      else if (membersMirror is MethodMirror && membersMirror.isGetter) {
        fim = m.getField(key);
      }
      else if (membersMirror is MethodMirror && membersMirror.parameters.length == 0) {
        fim = m.invoke(membersMirror.simpleName, []);
      }
      else if (membersMirror is MethodMirror && membersMirror.parameters.length == 1) {
        return _toFuncion(m, membersMirror.simpleName); 
      }
      if (fim != null) {
        var im = deprecatedFutureValue(fim);
        if (im is InstanceMirror) {
          return im.reflectee;
        }
      }
      return null;
    } 
  }
  
  InstanceMirror get mirror => reflect(ctx);
  
  static _findMemberMirror(InstanceMirror m, String memberName) {
    var members = m.type.members;
    var membersMirror = members[memberName];
    if (membersMirror == null) {
      //try out a getter:
      membersMirror = members[_getterName(memberName)];
    }
    return membersMirror;
  }
  
  static String _getterName(String name) {
    StringBuffer out = new StringBuffer('get');
    out.write(name[0].toUpperCase());
    out.write(name.substring(1));
    return out.toString();
  }
  
  static Function _toFuncion(InstanceMirror mirror, String method) {
    return (val) {
      var fim = mirror.invoke(method, [val]);
      var im = deprecatedFutureValue(fim);
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

class _IterableMustacheContextDecorator extends Iterable<MustacheContext> {
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
