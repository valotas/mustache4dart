library mustache4dart.utils_io;

import 'dart:async';
import "dart:io";
import "mustache4dart.dart";
import "package:path/path.dart" as path;

TemplateRenderer renderFromFileSync(File file, Object context,
    {Function partial: null,
    Delimiter delimiter: null,
    String ident: EMPTY_STRING,
    StringSink out: null,
    bool errorOnMissingProperty: false,
    bool assumeNullNonExistingProperty: true}) {
  String template = file.readAsStringSync();
  return compile(template,
      partial: partial,
      delimiter: delimiter,
      ident:
          ident)(context,
      out: out,
      errorOnMissingProperty: errorOnMissingProperty,
      assumeNullNonExistingProperty: assumeNullNonExistingProperty);
}

TemplateRenderer renderFromFilePathSync(String path, Object context,
    {Function partial: null,
    Delimiter delimiter: null,
    String ident: EMPTY_STRING,
    StringSink out: null,
    bool errorOnMissingProperty: false,
    bool assumeNullNonExistingProperty: true}) {
  File file = new File(path);
  if (!file.existsSync()) throw new Exception("File (?) $path doesn't exists");
  return renderFromFileSync(file, context,
      partial: partial,
      delimiter: delimiter,
      ident: ident,
      out: out,
      errorOnMissingProperty: errorOnMissingProperty,
      assumeNullNonExistingProperty: assumeNullNonExistingProperty);
}

Future<TemplateRenderer> renderFromFilePathAsync(String path, Object context,
    {Function partial: null,
    Delimiter delimiter: null,
    String ident: EMPTY_STRING,
    StringSink out: null,
    bool errorOnMissingProperty: false,
    bool assumeNullNonExistingProperty: true}) async {
  File file = new File(path);
  String template = file.readAsStringSync();
  return renderFromFileSync(file, context,
      partial: partial,
      delimiter: delimiter,
      ident: ident,
      out: out,
      errorOnMissingProperty: errorOnMissingProperty,
      assumeNullNonExistingProperty: assumeNullNonExistingProperty);
}

Future<TemplateRenderer> renderFromFileAsync(File file, Object context,
    {Function partial: null,
    Delimiter delimiter: null,
    String ident: EMPTY_STRING,
    StringSink out: null,
    bool errorOnMissingProperty: false,
    bool assumeNullNonExistingProperty: true}) async {
  return renderFromFileSync(file, context,
      partial: partial,
      delimiter: delimiter,
      ident: ident,
      out: out,
      errorOnMissingProperty: errorOnMissingProperty,
      assumeNullNonExistingProperty: assumeNullNonExistingProperty);
}

/// Contains [directories] where the partials will be searched when invoking the
/// [_searchPartial] function. By default the only directory is the current one.
/// The partials will be searched with the pattern "partialName(_partial)?.[ext]"
/// where ext is the [extensions] property that defaults to "mustache".
/// Example:
/// partialsHandlerVar.searchPartial("name") will search beneath all partialsHandlerVar's
/// defined directories for the first match of name.mustache or name_partial.mustache
class PartialsHandler {
  Map<String, Directory> _dirs = {};
  Set<String> _paths;

  /// Whether to fail execution with a BadStateError or continue it with the
  /// [notFoundMessage] property.
  bool failWhenNotFound;

  /// Paths of the directories where the partials will be searched.
  Set<String> get paths => _paths;

  /// Function to be provided on the [render]/[compile] functions, in the
  /// [partial:] argument.
  Function get partialSearchFunction => _searchPartial;

  /// All the provided extensions to be matched when searching the partial.
  /// default is ".mustache"
  Set<String> extensions;

  /// Output text that will be given to the template if the requested partial is
  /// not found. If null (the default) will output a large predefined striking
  /// verbose error message.
  String notFoundMessage;

  PartialsHandler(
      {List<String> directoriesPaths: const ["./"],
      List<String> extensions: const [".mustache"],
      this.failWhenNotFound: true,
      this.notFoundMessage: null}) {
    this.extensions = new Set.from(extensions);
    _paths = new Set.from(
        directoriesPaths.map((p) => path.canonicalize(path.absolute(p))));
    _paths.forEach((String dirPath) {
      if (FileSystemEntity.isDirectorySync(dirPath))
        _dirs[dirPath] = new Directory(dirPath);
      else
        throw new StateError("The provided path ($dirPath) is not a Directory");
    });
  }

  /// Add a new [Directory] other than the provided in the constructor
  bool addDirectory(Directory dir) {
    if (_dirs.containsValue(dir)) return false;
    if (dir.existsSync() == false) return false;
    String p = path.canonicalize(path.absolute(dir.path));
    if (_paths.add(p)) {
      _dirs[p] = dir;
      return true;
    } else
      return false;
  }

  /// Add a new [Directory] other than the provided in the constructor by its path
  bool addDirectoryPath(String path) {
    Directory dir;
    try {
      dir = new Directory(path);
      if (dir.existsSync() == false) return false;
    } catch (e) {
      return false;
    }
    return addDirectory(dir);
  }

  String _searchPartial(String partialName) {
    for (Directory dir in _dirs.values) {
      for (FileSystemEntity entity in dir.listSync()) {
        if (entity is File) {
          String filePath;
          filePath = (entity as File).path;
          if (extensions.contains(path.extension(filePath))) {
            String fileName = path.basenameWithoutExtension(filePath);
            if (fileName == partialName || fileName == "${partialName}_partial")
              return entity.readAsStringSync();
          }
        }
      }
    }
    if (failWhenNotFound) {
      String msg = ">$partialName requested but no $partialName[_partial]";
      msg += (extensions.length > 1)
          ? "{${extensions.join('|')}} found in "
          : "${extensions.single} found in ";
      msg += (_paths.length > 1)
          ? "any of the \"${_paths.join('\", \"')}\" paths."
          : "${_paths.single} path.";
      throw new StateError(msg);
    }
    return notFoundMessage ??
        '''
¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡ #PARTIAL NOT FOUND !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Couldn't find the partial requested with '>$partialName' in the following paths:
 ${_paths.join(', ')}
¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡ /PARTIAL NOT FOUND !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
''';
  }
}
