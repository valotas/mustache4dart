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
    //InstanceMirror im = reflect(val);
    //print(im);
    return 1;
  }
  
  String getValue(String key) => ctx[key];
}
