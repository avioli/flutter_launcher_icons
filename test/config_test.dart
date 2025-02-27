import 'dart:io';

import 'package:flutter_launcher_icons/config.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class MockFile extends Mock implements File {}

MockFile getMockFileWithContents(
  String contents, [
  String path = 'mock_path/mock_file',
]) {
  final file = MockFile();
  when(file.path).thenReturn(path);
  when(file.readAsStringSync()).thenReturn(contents);
  return file;
}

MockFile getNonExistingMockFile([String path = 'mock_path/mock_file']) {
  const notFoundErrorCode = 2;
  const osError = OSError('No such file or directory', notFoundErrorCode);
  final file = MockFile();
  when(file.path).thenReturn(path);
  when(file.readAsStringSync()).thenThrow(
    FileSystemException('mock_message', path, osError),
  );
  return file;
}

void main() {
  group('FlavorConfig', () {
    test('blank', () {
      final cfg = FlavorConfig.fromMap(<String, dynamic>{});

      expect(cfg.flavor, isNull);
      expect(cfg.baseImage, isNull);
      expect(cfg.androidImage, isNull);
      expect(cfg.iosImage, isNull);
      expect(cfg.generateForAndroid, isNull);
      expect(cfg.generateForIos, isNull);
      expect(cfg.androidName, isNull);
      expect(cfg.iosName, isNull);
      expect(cfg.adaptiveIconBg, isNull);
      expect(cfg.adaptiveIconFg, isNull);
    });

    test('all set', () {
      final cfg1 = FlavorConfig.fromMap(<String, dynamic>{
        'image_path': 'path/to/image',
        'image_path_android': 'android/path/to/image',
        'image_path_ios': 'ios/path/to/image',
        'android': 'ic_launcher',
        'ios': 'Icon-App',
        'adaptive_icon_background': 'android/path/to/bg',
        'adaptive_icon_foreground': 'android/path/to/fg',
      }, flavor: 'all_set');

      expect(cfg1.flavor, 'all_set');
      expect(cfg1.baseImage?.path, 'path/to/image');
      expect(cfg1.androidImage?.path, 'android/path/to/image');
      expect(cfg1.iosImage?.path, 'ios/path/to/image');
      expect(cfg1.generateForAndroid, isNull);
      expect(cfg1.generateForIos, isNull);
      expect(cfg1.androidName, 'ic_launcher');
      expect(cfg1.iosName, 'Icon-App');
      expect(cfg1.adaptiveIconBg, 'android/path/to/bg');
      expect(cfg1.adaptiveIconFg, 'android/path/to/fg');

      final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
        'android': true,
        'ios': false,
      });
      expect(cfg2.generateForAndroid, isTrue);
      expect(cfg2.generateForIos, isFalse);
    });

    test('wrong value types', () {
      final cfg = FlavorConfig.fromMap(<String, dynamic>{
        'image_path': 123,
        'image_path_android': 123,
        'image_path_ios': 123,
        'android': 123,
        'ios': 123,
        'adaptive_icon_background': 123,
        'adaptive_icon_foreground': 123,
      });
      expect(cfg.baseImage, isNull);
      expect(cfg.androidImage, isNull);
      expect(cfg.iosImage, isNull);
      expect(cfg.generateForAndroid, isNull);
      expect(cfg.generateForIos, isNull);
      expect(cfg.androidName, isNull);
      expect(cfg.iosName, isNull);
      expect(cfg.adaptiveIconBg, isNull);
      expect(cfg.adaptiveIconFg, isNull);
    });

    void testShouldGenerate(String platform, bool getActual(FlavorConfig cfg)) {
      group('should generate for $platform', () {
        test('image_path', () {
          final cfg1 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path': 'path/to/image',
          });
          expect(getActual(cfg1), isTrue);

          final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path': 'path/to/image',
            platform: true,
          });
          expect(getActual(cfg2), isTrue);

          final cfg3 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path': 'path/to/image',
            platform: 'ic_launcher',
          });
          expect(getActual(cfg3), isTrue);
        });

        test('image_path_$platform', () {
          final cfg1 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path_$platform': '$platform/path/to/image',
          });
          expect(getActual(cfg1), isTrue);

          final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path_$platform': '$platform/path/to/image',
            platform: true,
          });
          expect(getActual(cfg2), isTrue);

          final cfg3 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path_$platform': '$platform/path/to/image',
            platform: 'ic_launcher',
          });
          expect(getActual(cfg3), isTrue);
        });
      });

      group('should not generate for $platform', () {
        test('image_path', () {
          final cfg1 = FlavorConfig.fromMap(<String, dynamic>{});
          expect(getActual(cfg1), isFalse);

          final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path': 'path/to/image',
            platform: false,
          });
          expect(getActual(cfg2), isFalse);
        });

        test('image_path_android', () {
          final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
            'image_path_android': '$platform/path/to/image',
            platform: false,
          });
          expect(getActual(cfg2), isFalse);
        });
      });
    }

    testShouldGenerate('android', (cfg) => cfg.shouldGenerateForAndroid);
    testShouldGenerate('ios', (cfg) => cfg.shouldGenerateForIos);

    test('withDefaults', () {
      final base = FlavorConfig.fromMap(<String, dynamic>{
        'image_path': 'path/to/image',
        'image_path_android': 'android/path/to/image',
        'image_path_ios': 'ios/path/to/image',
      });

      final partial = FlavorConfig.fromMap(<String, dynamic>{
        'image_path': 'path/to/image-alt',
      });

      final combined = partial.withDefaults(base);

      expect(combined.baseImage?.path, 'path/to/image-alt');
      expect(combined.androidImage?.path, 'android/path/to/image');
      expect(combined.iosImage?.path, 'ios/path/to/image');
    });

    test('toMap', () {
      final cfg1 = FlavorConfig.fromMap(<String, dynamic>{
        'image_path': 'path/to/image',
        'image_path_android': 'android/path/to/image',
        'image_path_ios': 'ios/path/to/image',
        'android': 'ic_launcher',
        'ios': 'Icon-App',
        'adaptive_icon_background': 'android/path/to/bg',
        'adaptive_icon_foreground': 'android/path/to/fg',
      }, flavor: 'all_set');

      final expectedMap1 = <String, dynamic>{
        'image_path': 'path/to/image',
        'image_path_android': 'android/path/to/image',
        'image_path_ios': 'ios/path/to/image',
        'android': 'ic_launcher',
        'ios': 'Icon-App',
        'adaptive_icon_background': 'android/path/to/bg',
        'adaptive_icon_foreground': 'android/path/to/fg',
      };
      expect(cfg1.toMap(), equals(expectedMap1));

      final cfg2 = FlavorConfig.fromMap(<String, dynamic>{
        'android': true,
        'ios': false,
      });
      final expectedMap2 = <String, dynamic>{
        'image_path': null,
        'image_path_android': null,
        'image_path_ios': null,
        'android': true,
        'ios': false,
        'adaptive_icon_background': null,
        'adaptive_icon_foreground': null,
      };
      expect(cfg2.toMap(), equals(expectedMap2));
    });
  });

  group('ConfigFile class', () {
    test('constructor sets file', () {
      final cf1 = ConfigFile(null);
      expect(cf1.file, isNull);

      final cf2 = ConfigFile(File('dummy'));
      expect(cf2.file.path, 'dummy');
    });

    test('getMap reads specified file', () {
      final file = getMockFileWithContents('''
flutter_icons:
  image_path: path/to/image
''');

      final cf = ConfigFile(file);
      expect(cf.file, file);
      expect(
        cf.getMap(),
        equals(<String, dynamic>{
          'image_path': 'path/to/image',
        }),
      );
      verify(file.readAsStringSync()).called(1);
      verifyNoMoreInteractions(file);
    });

    test('getMap reads fallback file', () {
      final file = getMockFileWithContents('''
flutter_icons:
  image_path: path/to/fallback-image
''');

      final cf = ConfigFile(null, fallbacks: [file]);
      expect(cf.file, isNull);
      expect(
        cf.getMap(),
        equals(<String, dynamic>{
          'image_path': 'path/to/fallback-image',
        }),
      );
      verify(file.readAsStringSync()).called(1);
      verifyNoMoreInteractions(file);
      expect(cf.file, file);
    });

    test('getMap reads following fallback file if first doesn\'t exist', () {
      final file1 = getNonExistingMockFile();
      final file2 = getMockFileWithContents('''
flutter_icons:
  image_path: path/to/fallback2
''');

      final cf = ConfigFile(null, fallbacks: [file1, file2]);
      expect(cf.file, isNull);
      expect(
        cf.getMap(),
        equals(<String, dynamic>{
          'image_path': 'path/to/fallback2',
        }),
      );
      verify(file1.readAsStringSync()).called(1);
      verifyNoMoreInteractions(file1);
      verify(file2.readAsStringSync()).called(1);
      verifyNoMoreInteractions(file2);
      expect(cf.file, file2);
    });

    test('getMap throws if non-existing file is given', () {
      final file = getNonExistingMockFile();
      final cf = ConfigFile(file);
      expect(cf.file, file);
      expect(
        () => cf.getMap(),
        throwsA(const TypeMatcher<FileSystemException>().having(
            (e) => e.osError?.errorCode, 'osError.errorCode', equals(2))),
      );
      verify(file.readAsStringSync()).called(1);
      verifyNoMoreInteractions(file);
    });

    test('getMap throws if an invalid file is given', () {
      {
        final file = getMockFileWithContents('', 'a_mock_file.yaml');
        final cf = ConfigFile(file);
        expect(
          () => cf.getMap(),
          throwsA(const TypeMatcher<NoConfigFoundException>().having(
              (e) => e.message, 'message', contains('a_mock_file.yaml'))),
        );
        verify(file.readAsStringSync()).called(1);
        verify(file.path).called(1);
        verifyNoMoreInteractions(file);
      }

      {
        final file = getMockFileWithContents('''
123
''', 'a_mock_file.yaml');
        final cf = ConfigFile(file);
        expect(
          () => cf.getMap(),
          throwsA(const TypeMatcher<NoConfigFoundException>().having(
              (e) => e.message, 'message', contains('a_mock_file.yaml'))),
        );
        verify(file.readAsStringSync()).called(1);
        verify(file.path).called(1);
        verifyNoMoreInteractions(file);
      }
    });

    test('getMap throws if an file with no flutter_icons key is given', () {
      final file = getMockFileWithContents('''
dymmy: 1
''', 'a_mock_config.yaml');
      final cf = ConfigFile(file);
      expect(
        () => cf.getMap(),
        throwsA(const TypeMatcher<NoConfigFoundException>().having(
          (e) => e.message,
          'message',
          allOf([
            contains('a_mock_config.yaml'),
            contains('flutter_icons'),
          ]),
        )),
      );
      verify(file.readAsStringSync()).called(1);
      verify(file.path).called(1);
      verifyNoMoreInteractions(file);
    });
  });
}
