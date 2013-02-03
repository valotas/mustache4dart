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
      //No idea how to get a field value via reflection. There is no sync API as
      //I see: http://code.google.com/p/dart/issues/detail?id=4633 and I do not
      //feel switching everything to Future at the moment.
      var completed = false;
      var val = null;
      var fim = ctxIm.getField(key)
          .catchError((e) => print("Could not compute value of $key"), test: (e) => true)
          .then((v) {
            print("Completed computation of $key and got value: $v");
            val = v;
            completed = true;
          })
          .whenComplete(() => print("Completed computation of $key"));
      Future.wait([fim]);
      return val;
    }
  }
  
  MustacheContext getSubContext(String key) => new MustacheContext(ctx[key]);
  
}
