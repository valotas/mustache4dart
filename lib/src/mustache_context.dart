part of mustache4dart;

class MustacheContext {
  static final String DOT = '\.';
  final ctx;
  final MustacheContext other;

  MustacheContext(this.ctx, [MustacheContext this.other]);

  operator [](String key) => _get(key);
  
  _get(String key, [MustacheContext additionalCtx]) {
    if (key == DOT) {
      return ctx;
    }
    if (key.contains(DOT)) {
      List<String> keys = key.split(DOT);
      Iterator<String> k = keys.iterator;
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
    var result = _getContext(key, additionalCtx == null ? this : additionalCtx);
    if (result == null && other != null) {
      result = other._get(key, this);
    }
    return result; 
  }
  
  _getContext(String key, [MustacheContext other]) {
    var v = _getValue(key);
    if (v == null) {
      return null;
    }
    if (v is Iterable) {
      if (v.isEmpty) {
        return null;
      }
      return new _IterableMustacheContextDecorator(v, other);
    }
    if (v == false) {
      return null;
    }
    if (v == true) {
      return true;
    }
    if (v is MustacheFunction) {
      return v;
    }
    if (v is num) {
      return "$v";
    }
    if (!(v is String)) {
      return new MustacheContext(v, other);
    }
    return v;
  }
  
  _getValue(String key) {
    try {
      var val = ctx[key];
      if (val is Function) {
        return new MustacheFunction(val);
      }
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
        return new MustacheFunction(m, membersMirror.simpleName); 
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

class MustacheFunction {
  final Function _func;
  final InstanceMirror _mirror;
  final String _methodName;
  
  factory MustacheFunction(func, [name]) {
    if (name != null && func is InstanceMirror) {
      return new MustacheFunction._internal(func, name, null);
    }
    if (name == null && func is Function) {
      return new MustacheFunction._internal(null, null, func);
    }
  }
  
  MustacheFunction._internal(this._mirror, this._methodName, this._func);
  
  apply(String val) {
    if (_func != null) {
      return Function.apply(_func, [val]);
    }
    //otherwise:
    var fim = _mirror.invoke(_methodName, [val]);
    var im = deprecatedFutureValue(fim);
    if (im is InstanceMirror) {
      var r = im.reflectee;
      return r;
    }
    else {
      return null;
    }
  }
}
