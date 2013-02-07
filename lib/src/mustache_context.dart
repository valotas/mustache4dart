part of mustache4dart;

class MustacheContext {
  final ctx;

  MustacheContext(this.ctx);

  operator [](String key) {
    var v = _getValue(key);
    if (v is Iterable) {
      v = new _IterableMustacheContextDecorator(v);
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
      var im = deprecatedFutureValue(mirror.getField(key));
      if (im is InstanceMirror) {
        return im.reflectee;
      }
      else {
        return null;
      }
    }
  }
  
  InstanceMirror get mirror => reflect(ctx);
  
  MustacheContext getSubContext(String key) => new MustacheContext(_getValue(key));
}

class _IterableMustacheContextDecorator extends Iterable<MustacheContext> {
  final Iterable delegate;
  
  _IterableMustacheContextDecorator(this.delegate);
  
  Iterator<MustacheContext> get iterator => new _MustachContextIteratorDecorator(delegate.iterator);
  
  int get length => delegate.length;
  
}

class _MustachContextIteratorDecorator extends Iterator<MustacheContext> {
  Iterator delegate;
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
