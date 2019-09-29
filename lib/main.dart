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

  try {
    if (args.allFlavors) {
      await processAllFlavors(configFile: args.configFile);
    } else {
      await processConfigFile(
        configFile: args.configFile,
        specificFlavors: args.flavors,
      );
    }
  } catch (e) {
    stderr.writeln(e);
    exit(2);
  }
}

Future<void> processAllFlavors({File configFile}) async {
  if (configFile == null) {
    final configs = Config.findAllFlavorConfigs();
    if (configs.isNotEmpty) {
      for (final config in configs) {
        await createIconsFromConfig(config, flavor: config.base.flavor);
      }
      return;
    }
  }

  final config = Config.file(configFile);
  for (final flavorCfg in config.flavors) {
    await createIconsFromConfig(
      config.mergeFlavorConfig(flavorCfg),
      flavor: flavorCfg.flavor,
    );
  }
}

Future<void> processConfigFile({
  File configFile,
  List<String> specificFlavors,
}) async {
  final flavors = specificFlavors == null || specificFlavors.isEmpty
      ? [null]
      : specificFlavors;

  for (final flavor in flavors) {
    final config = Config.file(
      configFile,
      flavor: flavor,
    );

    await createIconsFromConfig(config, flavor: flavor);
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
