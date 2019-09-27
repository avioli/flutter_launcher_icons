import 'dart:io';

import 'package:args/args.dart';

import 'constants.dart';

class Arguments {
  factory Arguments.parse(List<String> arguments) {
    final parser = ArgParser(allowTrailingOptions: true);
    parser.addFlag(
      'help',
      abbr: 'h',
      help: 'Usage help',
      negatable: false,
    );
    parser.addOption(
      'file',
      abbr: 'f',
      help: 'Config file (default: $defaultConfigFile)',
    );
    parser.addOption(
      'flavor',
      help: 'Use flavor',
    );

    try {
      final argResults = parser.parse(arguments);

      final args = Arguments._internal(
        help: argResults['help'] as bool,
        configFile: argResults['file'] as String,
        flavor: argResults['flavor'] as String,
      );

      if (args.help) {
        stdout.writeln('''
Generates icons for iOS and Android

Usage:
${parser.usage}

Notes:
Config is read from -f, --file, if set, otherwise defaults to `$defaultConfigFile`.
If a flavor is set, `${flavorConfigFile('<flavor>')}` is looked up and used, if found.
Final fallback is to read config from `pubspec.yaml`.

The configuration in any of those files should be under the `flutter_icons:` key.
''');
        exit(0);
      }

      return args;
    } on FormatException catch (e) {
      stdout.writeln(e.message);
      stdout.writeln(parser.usage);
      exit(1);
      return null;
    }
  }

  Arguments._internal({
    this.help = false,
    String configFile,
    this.flavor,
  }) : configFile = configFile == null ? null : File(configFile);

  final bool help;
  final File configFile;
  final String flavor;
}
