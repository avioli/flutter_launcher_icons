import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_launcher_icons/android.dart' as android_launcher_icons;
import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/ios.dart' as ios_launcher_icons;
import 'package:yaml/yaml.dart';

const String defaultConfigFile = 'flutter_launcher_icons.yaml';
const String flavorConfigFilePattern = "\./flutter_launcher_icons-(.*).yaml";
String flavorConfigFile(String flavor) => "flutter_launcher_icons-$flavor.yaml";

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

Future<void> createIconsFromArguments(List<String> arguments) async {
  final args = Arguments.parse(arguments);

  // Flavors manangement
  var flavors = getFlavors();
  var hasFlavors = flavors.isNotEmpty;

  // Load the config file
  final Map<String, dynamic> yamlConfig = loadConfig(
    args.configFile,
    verbose: true,
  );

  // Create icons
  if ( !hasFlavors ) {
    try {
      final String flavor = args.flavor;
      final Map<String, dynamic> flavors = yamlConfig['flavors'];
      if (flavor != null && flavor.isNotEmpty && flavors != null && flavors[flavor] != null)
        createIconsFromConfig(flavors[flavor], flavor);
      else
        createIconsFromConfig(yamlConfig);
    } catch (e) {
      stderr.writeln(e);
      exit(2);
    }
  } else {
    try {
      for (var flavor in flavors) {
        final Map<String, dynamic> yamlConfig = loadConfigFile(flavorConfigFile(flavor), flavorConfigFile(flavor));
        await createIconsFromConfig(yamlConfig, flavor);
      }
    } catch (e) {
      stderr.writeln(e);
      exit(2);
    }
  }
}

Future<void> createIconsFromConfig(Map<String, dynamic> config, [String flavor]) async {
  if (!isImagePathInConfig(config)) {
    throw const InvalidConfigException(errorMissingImagePath);
  }
  if (!hasAndroidOrIOSConfig(config)) {
    throw const InvalidConfigException(errorMissingPlatform);
  }
  final int minSdk = android_launcher_icons.minSdk();
  if (minSdk < 26 &&
      hasAndroidAdaptiveConfig(config) &&
      !hasAndroidConfig(config)) {
    throw const InvalidConfigException(errorMissingRegularAndroid);
  }

  if (isNeedingNewAndroidIcon(config)) {
    android_launcher_icons.createDefaultIcons(config, flavor);
  }
  if (hasAndroidAdaptiveConfig(config)) {
    android_launcher_icons.createAdaptiveIcons(config, flavor);
  }
  if (isNeedingNewIOSIcon(config)) {
    ios_launcher_icons.createIcons(config, flavor);
  }
}

Map<String, dynamic> loadConfig(File file, {bool verbose}) {
  verbose ??= false;
  final String configFile = file?.path;
  final String fileOptionResult = file?.path;

  // if icon is given, try to load icon
  if (configFile != null && configFile != defaultConfigFile) {
    try {
      return loadConfigFile(configFile, fileOptionResult);
    } catch (e) {
      if (verbose) {
        stderr.writeln(e);
      }

      return null;
    }
  }

  // If none set try flutter_launcher_icons.yaml first then pubspec.yaml
  // for compatibility
  try {
    return loadConfigFile(defaultConfigFile, fileOptionResult);
  } catch (e) {
    // Try pubspec.yaml for compatibility
    if (configFile == null) {
      try {
        return loadConfigFile('pubspec.yaml', fileOptionResult);
      } catch (_) {}
    }

    // if nothing got returned, print error
    if (verbose) {
      stderr.writeln(e);
    }
  }

  return null;
}

Map<String, dynamic> loadConfigFile(
  String path, [
  String configFile = defaultConfigFile,
]) {
  final file = File(path);
  final yamlString = file.readAsStringSync();

  final dynamic yamlMap = loadYaml(yamlString);
  if (yamlMap is! YamlMap) {
    stderr.writeln(NoConfigFoundException('Invalid config file '
        '`$configFile`'));
    exit(1);
  }

  if (yamlMap['flutter_icons'] is! YamlMap) {
    stderr.writeln(NoConfigFoundException('Check that your config file '
        '`$configFile` has a `flutter_icons` section'));
    exit(1);
  }

  // yamlMap has the type YamlMap, which has several unwanted sideeffects
  return yamlMapToMap(yamlMap['flutter_icons'] as YamlMap);
}

Map<String, dynamic> yamlMapToMap(YamlMap yamlMap) {
  final Map<String, dynamic> map = <String, dynamic>{};
  for (MapEntry<dynamic, dynamic> entry in yamlMap.entries) {
    if (entry.value is YamlMap) {
      map[entry.key] = yamlMapToMap(entry.value);
    } else {
      map[entry.key] = entry.value;
    }
  }
  return map;
}

List<String> getFlavors() {
  final List<String> flavors = <String>[];
  for (final dynamic item in Directory('.').listSync()) {
    if (item is File) {
      final RegExpMatch match =
          RegExp(flavorConfigFilePattern).firstMatch(item.path);
      if (match != null) {
        flavors.add(match.group(1));
      }
    }
  }
  return flavors;
}

bool isImagePathInConfig(Map<String, dynamic> flutterIconsConfig) {
  return flutterIconsConfig.containsKey('image_path') ||
      (flutterIconsConfig.containsKey('image_path_android') &&
          flutterIconsConfig.containsKey('image_path_ios'));
}

bool hasAndroidOrIOSConfig(Map<String, dynamic> flutterIconsConfig) {
  return flutterIconsConfig.containsKey('android') ||
      flutterIconsConfig.containsKey('ios');
}

bool hasAndroidConfig(Map<String, dynamic> flutterLauncherIcons) {
  return flutterLauncherIcons.containsKey('android');
}

bool isNeedingNewAndroidIcon(Map<String, dynamic> flutterLauncherIconsConfig) {
  return hasAndroidConfig(flutterLauncherIconsConfig) &&
      flutterLauncherIconsConfig['android'] != false;
}

bool hasAndroidAdaptiveConfig(Map<String, dynamic> flutterLauncherIconsConfig) {
  return isNeedingNewAndroidIcon(flutterLauncherIconsConfig) &&
      flutterLauncherIconsConfig.containsKey('adaptive_icon_background') &&
      flutterLauncherIconsConfig.containsKey('adaptive_icon_foreground');
}

bool hasIOSConfig(Map<String, dynamic> flutterLauncherIconsConfig) {
  return flutterLauncherIconsConfig.containsKey('ios');
}

bool isNeedingNewIOSIcon(Map<String, dynamic> flutterLauncherIconsConfig) {
  return hasIOSConfig(flutterLauncherIconsConfig) &&
      flutterLauncherIconsConfig['ios'] != false;
}
