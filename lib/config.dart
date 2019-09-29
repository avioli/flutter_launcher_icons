import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:meta/meta.dart';

import 'constants.dart';
import 'custom_exceptions.dart';

const _pubspecFile = 'pubspec.yaml';
const _imagePathKey = 'image_path';
const _imagePathAndroidKey = 'image_path_android';
const _imagePathIosKey = 'image_path_ios';
const _androidKey = 'android';
const _iosKey = 'ios';
const _adaptiveIconBgKey = 'adaptive_icon_background';
const _adaptiveIconFgKey = 'adaptive_icon_foreground';
const _flavorsKey = 'flavors';

class Config {
  factory Config.file(File file, {String flavor}) {
    file = _findFile(file, flavor);
    if (file == null) {
      throw const NoConfigFoundException('No config file was found');
    }

    final map = _readFile(file);
    FlavorConfig base = FlavorConfig.fromMap(map);

    final List<FlavorConfig> flavors = [];
    final flavorsMap = map[_flavorsKey] is Map<String, dynamic>
        ? map[_flavorsKey] as Map<String, dynamic>
        : null;
    if (flavor != null) {
      // NOTE: the Config will become the flavor itself
      if (flavorsMap != null && flavorsMap[flavor] is Map) {
        final result = FlavorConfig.fromMap(
          flavorsMap[flavor] as Map<String, dynamic>,
          flavor: flavor,
        );
        base = result.withDefaults(base);
      } else {
        throw NoConfigFoundException('No config found for flavor `$flavor`');
      }
    } else if (flavorsMap != null) {
      for (final name in flavorsMap.keys) {
        final dynamic map = flavorsMap[name];
        if (map is Map<String, dynamic>) {
          flavors.add(FlavorConfig.fromMap(map, flavor: name));
        }
      }
    }

    return Config._internal(
      base: base,
      flavors: flavors,
    );
  }

  Config._internal({
    @required this.base,
    @required this.flavors,
  });

  final FlavorConfig base;
  final List<FlavorConfig> flavors;

  @override
  String toString() {
    return '$runtimeType('
        'base: $base'
        ', flavors: $flavors'
        ')';
  }
}

class FlavorConfig {
  factory FlavorConfig.fromMap(Map<String, dynamic> map, {String flavor}) {
    final dynamic androidValue = map[_androidKey];
    final dynamic iosValue = map[_iosKey];
    final generateForAndroid = androidValue is bool && androidValue == true;
    final generateForIos = iosValue is bool && iosValue == true;
    final androidName = _getString(androidValue);
    final iosName = _getString(iosValue);

    return FlavorConfig._internal(
      flavor: flavor,
      baseImage: _getFile(map[_imagePathKey]),
      androidImage: _getFile(map[_imagePathAndroidKey]),
      iosImage: _getFile(map[_imagePathIosKey]),
      generateForAndroid: generateForAndroid || androidName != null,
      generateForIos: generateForIos || iosName != null,
      androidName: androidName,
      iosName: iosName,
      adaptiveIconBg: _getString(map[_adaptiveIconBgKey]),
      adaptiveIconFg: _getString(map[_adaptiveIconFgKey]),
    );
  }

  FlavorConfig._internal({
    this.flavor,
    @required this.baseImage,
    @required this.androidImage,
    @required this.iosImage,
    @required this.generateForAndroid,
    @required this.generateForIos,
    @required this.androidName,
    @required this.iosName,
    @required this.adaptiveIconBg,
    @required this.adaptiveIconFg,
  });

  final String flavor;

  final File baseImage;
  final File androidImage;
  final File iosImage;

  final bool generateForAndroid;
  final bool generateForIos;
  final String androidName;
  final String iosName;

  final String adaptiveIconBg;
  final String adaptiveIconFg;

  FlavorConfig withDefaults(FlavorConfig other) {
    if (other == null) {
      return this;
    }
    return FlavorConfig._internal(
      flavor: flavor ?? other.flavor,
      baseImage: baseImage ?? other.baseImage,
      androidImage: androidImage ?? other.androidImage,
      iosImage: iosImage ?? other.iosImage,
      generateForAndroid: generateForAndroid ?? other.generateForAndroid,
      generateForIos: generateForIos ?? other.generateForIos,
      androidName: androidName ?? other.androidName,
      iosName: iosName ?? other.iosName,
      adaptiveIconBg: adaptiveIconBg ?? other.adaptiveIconBg,
      adaptiveIconFg: adaptiveIconFg ?? other.adaptiveIconFg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      _imagePathKey: baseImage?.path,
      _imagePathAndroidKey: androidImage?.path,
      _imagePathIosKey: iosImage?.path,
      _androidKey: androidName != null ? androidName : generateForAndroid,
      _iosKey: iosName != null ? iosName : generateForIos,
      _adaptiveIconBgKey: adaptiveIconBg,
      _adaptiveIconFgKey: adaptiveIconFg,
    };
  }

  @override
  String toString() {
    return '$runtimeType('
        'flavor: $flavor'
        ', baseImage: ${baseImage?.path}'
        ', androidImage: ${androidImage?.path}'
        ', iosImage: ${iosImage?.path}'
        ', generateForAndroid: $generateForAndroid'
        ', generateForIos: $generateForIos'
        ', androidName: $androidName'
        ', iosName: $iosName'
        ', adaptiveIconBg: $adaptiveIconBg'
        ', adaptiveIconFg: $adaptiveIconFg'
        ')';
  }
}

File _findFile(File file, String flavor) {
  if (file != null && file.existsSync()) {
    return file;
  }

  if (flavor != null && flavor.trim().isNotEmpty) {
    file = File(flavorConfigFile(flavor));
    if (file.existsSync()) {
      return file;
    }
  }

  file = File(defaultConfigFile);
  if (file.existsSync()) {
    return file;
  }

  file = File(_pubspecFile);
  if (file.existsSync()) {
    return file;
  }

  return null;
}

Map<String, dynamic> _readFile(File file) {
  final yamlString = file.readAsStringSync();

  final dynamic yamlMap = loadYaml(yamlString);
  if (yamlMap is! YamlMap) {
    throw NoConfigFoundException('Invalid config file `${file.path}`');
  }

  if (yamlMap['flutter_icons'] is! YamlMap) {
    throw NoConfigFoundException('Check that your config file '
        '`${file.path}` has a `flutter_icons` section');
  }

  // NOTE: yamlMap has the type YamlMap, which has several unwanted side effects
  return _yamlMapToMap(yamlMap['flutter_icons'] as YamlMap);
}

Map<String, dynamic> _yamlMapToMap(YamlMap yamlMap) {
  final Map<String, dynamic> map = <String, dynamic>{};
  for (MapEntry<dynamic, dynamic> entry in yamlMap.entries) {
    if (entry.key is! String) {
      continue;
    }
    final key = entry.key as String;
    if (entry.value is YamlMap) {
      map[key] = _yamlMapToMap(entry.value as YamlMap);
    } else {
      map[key] = entry.value;
    }
  }
  return map;
}

File _getFile(dynamic filePath) {
  if (filePath is String && filePath.trim().isNotEmpty) {
    return File(filePath.trim());
  }
  return null;
}

String _getString(dynamic string) {
  if (string is String && string.trim().isNotEmpty) {
    return string.trim();
  }
  return null;
}

List<String> _getFlavors() {
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
