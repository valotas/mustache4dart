part of mustache4dart;

//We start with a very dummy approach!
class MustacheContext {
  final Map<String, String> ctx;
  
  MustacheContext(this.ctx);
  
  bool hasValue(String key) => ctx[key] != null;
  
  String getValue(String key) => ctx[key];
}
