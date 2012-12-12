part of mustache4dart;

//We start with a very dummy approach!
class MustacheContext {
  final Map<String, String> ctx;
  
  MustacheContext(this.ctx);
  
  String getValue(String key) => ctx[key];
}
