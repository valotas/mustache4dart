part of mustache4dart;

//We start with a very dummy approach!
class MustacheContext {
  final Map<String, Object> ctx;
  
  MustacheContext(this.ctx);
  
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
  
  String getValue(String key) => ctx[key];
}
