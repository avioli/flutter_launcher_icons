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
    parser.addMultiOption(
      'flavor',
      help: 'Use flavor',
    );
    parser.addFlag(
      'all-flavors',
      help: 'Find and generate for all flavors',
      negatable: false,
    );

    try {
      final argResults = parser.parse(arguments);

      final args = Arguments._internal(
        help: argResults['help'] as bool,
        configFile: argResults['file'] as String,
        flavors: argResults['flavor'] as List<String>,
        allFlavors: argResults['all-flavors'] as bool,
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

Both `$defaultConfigFile` and `pubspec.yaml` could have a key, named `flavors:` where
a list of flavors holds the per-flavor config. These flavors are merged with the
top-level configuration:

flutter_icons:
  image_path: resources/icon/icon.png
  ios: true
  android: ic_launcher
  flavors:
    alpha:
      image_path: resources/icon/icon-alpha.png
      ios: false
    beta:
      image_path: resources/icon/icon-beta.png

Flavor `alpha` will inherit `android`, while `beta` will inherit both `ios` and
`android` from the top-level config.
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
    this.flavors,
    this.allFlavors,
  }) : configFile = configFile == null ? null : File(configFile);

  final bool help;
  final File configFile;
  final List<String> flavors;
  final bool allFlavors;
}
