import 'dart:io' show Platform;
import 'package:grinder/grinder.dart';
import 'package:glob/glob.dart';

main(args) => grind(args);

const List<String> EXPECTED_STABLE = const [ '1.24.0', '1.24.1' ];
final dartFiles = new Glob('{lib,test}/**.dart').listSync().map((f) => f.path);

@Task('Check if version is stable')
isStable() {
  final v = Dart.version();
  if (Platform.environment['TRAVIS_DART_VERSION'] == 'stable') {
    if (!EXPECTED_STABLE.contains(v)) {
      throw "Travis stable version ($v) different than expected ($EXPECTED_STABLE)";
    }
    return true;
  }
  return EXPECTED_STABLE.contains(v);
}

@Task('Analyze dart files with dartanalyzer')
analyze() {
  log("Analyzing following files with dartanalyzer:");
  log(dartFiles.join("\n"));

  run(sdkBin('dartanalyzer'),
      quiet: true,
      arguments: ['--strong', '--fatal-warnings']..addAll(dartFiles));
}

@Task('Check format .dart files')
formatCheck() {
  if (!isStable()) {
    log("No dartfmt check on ${Dart.version()} is needed");
    return;
  }
  final needsFormat = DartFmt.dryRun(dartFiles);
  if (needsFormat) {
    throw 'Code needs formatting';
  }
}

@Task('Format .dart files')
format() {
  if (!isStable()) {
    log("No dartfmt should be used on ${Dart.version()}");
    return;
  }
  DartFmt.format(dartFiles);
}

@Task('Testing')
test() {
  final List<String> args = ['-pvm'];
  if (isStable()) {
    log("${Dart
        .version()} is stable. Tests will be run also on chrome and firefox");
    args.add('-pchrome');
    args.add('-pfirefox');
  } else {
    log("${Dart.version()} is not stable. Tests will not be run on browser");
  }

  Pub.run('test', arguments: args);
}

@Task('Check coverage')
cover() {
  if (!isStable()) {
    log("${Dart.version()} is not stable. Skipping coveralls");
    return;
  }
  if (Platform.environment["COVERALLS_TOKEN"] == null) {
    log("No COVERALLS_TOKEN found. Skipping coveralls");
    return;
  }
  final coveralls = new PubApp.global('dart_coveralls');
  coveralls.run([
    'report',
    '--retry 2',
    '--exclude-test-files',
    'test/mustasche_all.dart'
  ]);
}

@DefaultTask('Build the project.')
@Depends(isStable, analyze, formatCheck, test, cover)
build() {
  log("Built on ${Dart.version()}, stable: $isStable");
}
