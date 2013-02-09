part of mustache4dart;

class MustacheContext {
  final ctx;

  MustacheContext(this.ctx);

  operator [](String key) {
    var v = _getValue(key);
    if (v == null) {
      return null;
    }
    if (v is Iterable) {
      return new _IterableMustacheContextDecorator(v);
    }
    if (v == false) {
      return null;
    }
    if (!(v is String)) {
      return new MustacheContext(v);
    }
    return v;
  }
  
  _getValue(String key) {
    try {
      return ctx[key];      
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
      else {
        return null;
      }
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
    out.add(name[0].toUpperCase());
    out.add(name.substring(1));
    return out.toString();
  }  
}

class _IterableMustacheContextDecorator extends Iterable<MustacheContext> {
  final Iterable delegate;
  
  _IterableMustacheContextDecorator(this.delegate);
  
  Iterator<MustacheContext> get iterator => new _MustachContextIteratorDecorator(delegate.iterator);
  
  int get length => delegate.length;
  
}

class _MustachContextIteratorDecorator extends Iterator<MustacheContext> {
  final Iterator delegate;
  MustacheContext current;
  
  _MustachContextIteratorDecorator(this.delegate);
  
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
