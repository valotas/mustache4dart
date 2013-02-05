part of mustache4dart;

class MustacheContext {
  final ctx;
  final InstanceMirror ctxIm;
  
  factory MustacheContext(ob) => new MustacheContext._internal(ob, reflect(ob));
  
  MustacheContext._internal(this.ctx, this.ctxIm);
  
  int getIterations(String key) {
    var val = ctx[key];
    if (val == null) {
      return 0;
    }
    
    Iterable it = getIterable(val);
    if (it != null) {
      return it.length;
    }
    return 1;
  }
  
  Iterable getIterable(val) {
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
  
  String getValue(String key) {
    try {
      return ctx[key];      
    } catch (NoSuchMethodError) {
      //There is no sync API as I see: http://code.google.com/p/dart/issues/detail?id=4633 
      //As I do not feel switching everything to Future at the moment, we use the 
      //deprecatedFutureValue as seen at 
      //http://code.google.com/p/dart/source/browse/experimental/lib_v2/dart/sdk/lib/_internal/dartdoc/lib/src/json_serializer.dart?spec=svn16262&r=16262
      return deprecatedFutureValue(ctxIm.getField(key)).reflectee;
    }
  }
  
  MustacheContext getSubContext(String key) => new MustacheContext(ctx[key]);
  
}
