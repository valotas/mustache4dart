part of mustache4dart;

class MustacheContext {
  final ctx;
  final InstanceMirror ctxIm;
  
  factory MustacheContext(ob) => new MustacheContext._internal(ob, reflect(ob));
  
  MustacheContext._internal(this.ctx, this.ctxIm);
    
  Iterable<MustacheContext> getIterable(val) {
    var v = _getValue(val);
    Iterable i = getIterableValue(v);
    if (i == null) {
      return null;
    }
    else {
      return new IterableMustacheContextDecorator(i);
    }
  }
  
  Iterable getIterableValue(val) {
    InstanceMirror im = reflect(val);
    var t = im.type;
    if ('dart:core.Iterable' == t.qualifiedName) {
      return val;
    }
    if ('dart:core.Iterable' == t.superclass.qualifiedName) {
      return val;
    }
    for (ClassMirror cm in t.superinterfaces) {
      if ('dart:core.Iterable' == cm.qualifiedName) {
        return val;
      }
      if ('dart:core.Iterable' == cm.superclass.qualifiedName) {
        return val;
      }
    }
    return null;
  }
  
  operator [](String key) {
    return _getValue(key);
  }
  
  _getValue(String key) {
    try {
      return ctx[key];      
    } catch (NoSuchMethodError) {
      //There is no sync API as I see: http://code.google.com/p/dart/issues/detail?id=4633 
      //As I do not feel switching everything to Future at the moment, we use the 
      //deprecatedFutureValue as seen at 
      //http://code.google.com/p/dart/source/browse/experimental/lib_v2/dart/sdk/lib/_internal/dartdoc/lib/src/json_serializer.dart?spec=svn16262&r=16262
      var im = deprecatedFutureValue(ctxIm.getField(key));
      if (im is InstanceMirror) {
        return im.reflectee;
      }
      else {
        return null;
      }
    }
  }
  
  MustacheContext getSubContext(String key) => new MustacheContext(_getValue(key));
}

class IterableMustacheContextDecorator extends Iterable<MustacheContext> {
  final Iterable delegate;
  
  IterableMustacheContextDecorator(this.delegate);
  
  Iterator<MustacheContext> get iterator => new MustachContextIteratorDecorator(delegate.iterator);
  
  int get length {
    return delegate.length;
  }
  
}

class MustachContextIteratorDecorator extends Iterator<MustacheContext> {
  Iterator delegate;
  MustacheContext current;
  
  MustachContextIteratorDecorator(this.delegate);
  
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
