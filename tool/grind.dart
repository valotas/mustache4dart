import 'package:grinder/grinder.dart';
import 'package:glob/glob.dart';

main(args) => grind(args);

final isStable = Dart.version() == "1.24.0";

@Task('Analyze dart files with dartanalyzer')
analyze() {
  final files = new Glob('{lib,test}/**.dart')
    .listSync()
    .map((f) => f.path);

  run(sdkBin('dartanalyzer'), arguments: [
    '--strong',
    '--fatal-warnings'
  ]..addAll(files));
}

@Task('Format .dart files')
formatCheck() {
  if (!isStable) {
    log("No dartfmt check on ${Dart.version()} is needed");
    return;
  }
  final needsFormat = DartFmt.dryRun('./lib');
  if (needsFormat) {
    throw 'Code needs formatting';
  }
}

@DefaultTask('Build the project.')
@Depends(analyze, formatCheck)
build() {
  log("Built on ${Dart.version()}, stable: $isStable");
}
