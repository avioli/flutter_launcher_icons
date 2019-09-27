import 'dart:io';

import 'package:yaml/yaml.dart';

import 'constants.dart';
import 'custom_exceptions.dart';

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
  final flavors = <String>[];
  for (final item in Directory('.').listSync()) {
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

