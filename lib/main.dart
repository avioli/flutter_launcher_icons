import 'dart:io';

import 'package:flutter_launcher_icons/arguments.dart';
import 'package:flutter_launcher_icons/android.dart' as android_launcher_icons;
import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/ios.dart' as ios_launcher_icons;

import 'config.dart';
import 'constants.dart';

Future<void> createIconsFromArguments(List<String> arguments) async {
  final args = Arguments.parse(arguments);

  final flavors =
      args.flavors == null || args.flavors.isEmpty ? [null] : args.flavors;

  for (final flavor in flavors) {
    final config = Config.file(
      args.configFile,
      flavor: flavor,
    );

    try {
      createIconsFromConfig(config, flavor: flavor);
    } catch (e) {
      stderr.writeln(e);
      exit(2);
    }
  }
}

Future<void> createIconsFromConfig(Config config, {String flavor}) async {
  final flavorConfig = config.base;
  if (!isImagePathInConfig(flavorConfig)) {
    throw const InvalidConfigException(errorMissingImagePath);
  }
  if (!hasAndroidOrIOSConfig(flavorConfig)) {
    throw const InvalidConfigException(errorMissingPlatform);
  }
  final int minSdk = android_launcher_icons.minSdk();
  if (minSdk < 26 &&
      hasAndroidAdaptiveConfig(flavorConfig) &&
      !hasAndroidConfig(flavorConfig)) {
    throw const InvalidConfigException(errorMissingRegularAndroid);
  }

  if (isNeedingNewAndroidIcon(flavorConfig)) {
    android_launcher_icons.createDefaultIcons(flavorConfig.toMap(), flavor);
  }
  if (hasAndroidAdaptiveConfig(flavorConfig)) {
    android_launcher_icons.createAdaptiveIcons(flavorConfig.toMap(), flavor);
  }
  if (isNeedingNewIOSIcon(flavorConfig)) {
    ios_launcher_icons.createIcons(flavorConfig.toMap(), flavor);
  }
}

bool isImagePathInConfig(FlavorConfig cfg) =>
    cfg.baseImage != null || cfg.androidImage != null && cfg.iosImage != null;

bool hasAndroidOrIOSConfig(FlavorConfig cfg) =>
    cfg.generateForAndroid || cfg.generateForIos;

bool hasAndroidConfig(FlavorConfig cfg) => cfg.generateForAndroid;

bool isNeedingNewAndroidIcon(FlavorConfig cfg) =>
    hasAndroidConfig(cfg) && cfg.generateForAndroid;

bool hasAndroidAdaptiveConfig(FlavorConfig cfg) =>
    isNeedingNewAndroidIcon(cfg) &&
    cfg.adaptiveIconBg != null &&
    cfg.adaptiveIconFg != null;

bool hasIOSConfig(FlavorConfig cfg) => cfg.generateForIos;

bool isNeedingNewIOSIcon(FlavorConfig cfg) =>
    hasIOSConfig(cfg) && cfg.generateForIos;
