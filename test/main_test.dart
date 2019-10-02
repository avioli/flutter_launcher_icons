import 'dart:io';

import 'package:flutter_launcher_icons/constants.dart' show defaultConfigFile;
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:flutter_launcher_icons/ios.dart' as ios;
import 'package:flutter_launcher_icons/android.dart' as android;
import 'package:flutter_launcher_icons/main.dart' as main_dart;
import 'package:flutter_launcher_icons/config.dart';

// Unit tests for main.dart
void main() {
  group('sanity checks', () {
    test('iOS icon list is correct size', () {
      expect(ios.iosIcons.length, 15);
    });

    test('Android icon list is correct size', () {
      expect(android.androidIcons.length, 5);
    });

    test(
      'iOS image list used to generate Contents.json '
      'for icon directory is correct size',
      () {
        expect(ios.createImageList('blah').length, 19);
      },
    );

    test('pubspec.yaml file exists', () {
      final result = File('test/config/test_pubspec.yaml').existsSync();
      expect(result, isTrue);
    });
  });

  group('config file from args', () {
    final String testDir = join(
      '.dart_tool',
      'flutter_launcher_icons',
      'test',
      'config_file',
    );

    String currentDirectory;
    void setCurrentDirectory(String path) {
      path = join(testDir, path);
      Directory(path).createSync(recursive: true);
      Directory.current = path;
    }

    setUp(() {
      currentDirectory = Directory.current.path;
    });

    tearDown(() {
      Directory.current = currentDirectory;
      Directory(testDir).deleteSync(recursive: true);
    });

    test('default', () {
      setCurrentDirectory('default');
      File('flutter_launcher_icons.yaml').writeAsStringSync('''
flutter_icons:
  android: true
  ios: false
''');
      final config = Config.file(null);
      expect(config.base.generateForAndroid, true);
      expect(config.base.generateForIos, false);
    });

    test('default_use_pubspec', () {
      setCurrentDirectory('pubspec_only');
      File('pubspec.yaml').writeAsStringSync('''
flutter_icons:
  android: true
  ios: false
''');
      final config = Config.file(null);
      expect(config.base.generateForAndroid, true);
      expect(config.base.generateForIos, false);

      // fails if forcing default file
      expect(() => Config.file(File(defaultConfigFile)), throwsException);
    });

    test('custom', () {
      setCurrentDirectory('custom');
      File('custom.yaml').writeAsStringSync('''
flutter_icons:
  android: true
  ios: false
''');
      final config = Config.file(File('custom.yaml'));
      expect(config.base.generateForAndroid, true);
      expect(config.base.generateForIos, false);

      // should fail if no argument
      expect(() => Config.file(null), throwsException);

      // or missing file
      expect(() => Config.file(File('missing_custom.yaml')), throwsException);
    });
  });

//   test('Incorrect pubspec.yaml path throws correct error message', () async {
//     const String incorrectPath = 'test/config/test_pubspec.yam';
//     expect(() => Config.file(File(incorrectPath)), throwsA(const TypeMatcher<FileSystemException>()));
//   });

  // test('image_path is in config', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'android': true,
  //     'ios': true
  //   };
  //   expect(main_dart.isImagePathInConfig(Config.fromMap(flutterIconsConfig).base), true);
  //   final Map<String, dynamic> flutterIconsConfigAndroid = <String, dynamic>{
  //     'image_path_android': 'assets/images/icon-710x599.png',
  //     'android': true,
  //     'ios': true
  //   };
  //   expect(main_dart.isImagePathInConfig(Config.fromMap(flutterIconsConfigAndroid).base), false);
  //   final Map<String, dynamic> flutterIconsConfigBoth = <String, dynamic>{
  //     'image_path_android': 'assets/images/icon-710x599.png',
  //     'image_path_ios': 'assets/images/icon-710x599.png',
  //     'android': true,
  //     'ios': true
  //   };
  //   expect(main_dart.isImagePathInConfig(Config.fromMap(flutterIconsConfigBoth).base), true);
  // });

  // test('At least one platform is in config file', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'android': true,
  //     'ios': true
  //   };
  //   expect(main_dart.hasAndroidOrIOSConfig(Config.fromMap(flutterIconsConfig).base), true);
  // });

  // test('No platform specified in config', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png'
  //   };
  //   expect(main_dart.hasAndroidOrIOSConfig(Config.fromMap(flutterIconsConfig).base), false);
  // });

  // test('No new Android icon needed - android: false', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'android': false,
  //     'ios': true
  //   };
  //   expect(main_dart.isNeedingNewAndroidIcon(Config.fromMap(flutterIconsConfig).base), false);
  // });

  // test('No new Android icon needed - no Android config', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'ios': true
  //   };
  //   expect(main_dart.isNeedingNewAndroidIcon(Config.fromMap(flutterIconsConfig).base), false);
  // });

  // test('No new iOS icon needed - ios: false', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'android': true,
  //     'ios': false
  //   };
  //   expect(main_dart.isNeedingNewIOSIcon(Config.fromMap(flutterIconsConfig).base), false);
  // });

  // test('No new iOS icon needed - no iOS config', () {
  //   final Map<String, dynamic> flutterIconsConfig = <String, dynamic>{
  //     'image_path': 'assets/images/icon-710x599.png',
  //     'android': true
  //   };
  //   expect(main_dart.isNeedingNewIOSIcon(Config.fromMap(flutterIconsConfig).base), false);
  // });
}
