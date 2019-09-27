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

  // Flavors manangement
  var flavors = getFlavors();
  var hasFlavors = flavors.isNotEmpty;

  // Load the config file
  final Map<String, dynamic> yamlConfig = loadConfig(
    args.configFile,
    verbose: true,
  );

  // Create icons
  if (!hasFlavors) {
    try {
      final String flavor = args.flavor;
      final Map<String, dynamic> flavors = yamlConfig['flavors'];
      if (flavor != null &&
          flavor.isNotEmpty &&
          flavors != null &&
          flavors[flavor] != null)
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
        final Map<String, dynamic> yamlConfig =
            loadConfigFile(flavorConfigFile(flavor), flavorConfigFile(flavor));
        await createIconsFromConfig(yamlConfig, flavor);
      }
    } catch (e) {
      stderr.writeln(e);
      exit(2);
    }
  }
}

Future<void> createIconsFromConfig(Map<String, dynamic> config,
    [String flavor]) async {
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
