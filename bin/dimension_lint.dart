import 'dart:io';

import 'package:dimension_lint/src/install.dart';

const String _usage = '''
Configures the dimension_lint analyzer plugin for a project.

Usage: dimension_lint init [-C <directory>]

  -C, --directory    The project to configure. Defaults to the current
                     directory.
  -h, --help         Print this usage information.

The plugin is enabled in analysis_options.yaml rather than pubspec.yaml, so it
is never a dependency of the app it analyzes.''';

Future<void> main(List<String> arguments) async {
  var args = [...arguments];

  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(_usage);
    return;
  }

  var command = args.removeAt(0);
  if (command != 'init') {
    stderr.writeln("Unknown command '$command'.\n");
    stderr.writeln(_usage);
    exitCode = 64; // EX_USAGE
    return;
  }

  var directory = '.';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '-C' || args[i] == '--directory') {
      if (i + 1 >= args.length) {
        stderr.writeln('${args[i]} requires a directory.');
        exitCode = 64;
        return;
      }
      directory = args[i + 1];
      i++;
    } else {
      stderr.writeln("Unexpected argument '${args[i]}'.");
      exitCode = 64;
      return;
    }
  }

  if (!Directory(directory).existsSync()) {
    stderr.writeln("Directory '$directory' does not exist.");
    exitCode = 66; // EX_NOINPUT
    return;
  }

  // Refuse to configure something that is not a Dart project: without a
  // pubspec the analysis server has no package to analyze, so the block would
  // sit in a file nothing reads.
  if (!File('$directory/pubspec.yaml').existsSync()) {
    stderr.writeln(
      "No pubspec.yaml in '$directory'. Run this from a Dart or Flutter "
      'project.',
    );
    exitCode = 66;
    return;
  }

  var file = File('$directory/analysis_options.yaml');
  var existing = file.existsSync() ? file.readAsStringSync() : '';
  var result = configurePlugins(existing);

  switch (result.outcome) {
    case InstallOutcome.configured:
      file.writeAsStringSync(result.contents!);
      stdout.writeln('Enabled dimension_lint in ${file.path}.');
      stdout.writeln(
        '\nNext: run `dart pub get`, then restart the Dart Analysis Server\n'
        '(VS Code: "Dart: Restart Analysis Server"). In CI, use\n'
        '`dart analyze --fatal-infos` -- `flutter analyze` drops plugin\n'
        'diagnostics.',
      );
    case InstallOutcome.alreadyConfigured:
      stdout.writeln('dimension_lint is already enabled in ${file.path}.');
    case InstallOutcome.otherPluginsPresent:
      stderr.writeln(
        '${file.path} already has a `plugins:` key for other plugins.\n'
        'Merging into it automatically would rewrite a block you own, so add\n'
        'this under the existing `plugins:` key instead:\n',
      );
      stderr.writeln(
        pluginBlock
            .split('\n')
            .skip(1) // Drop the `plugins:` line; one already exists.
            .join('\n'),
      );
      exitCode = 65; // EX_DATAERR
    case InstallOutcome.malformed:
      stderr.writeln('${file.path} is not valid YAML. Fix it, then re-run.');
      exitCode = 65;
  }
}
