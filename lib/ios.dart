import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';

import 'config.dart';
import 'constants.dart';

/// File to handle the creation of icons for iOS platform
class IosIconTemplate {
  IosIconTemplate({this.size, this.name});
  final String name;
  final int size;
}

List<IosIconTemplate> iosIcons = <IosIconTemplate>[
  IosIconTemplate(name: '-20x20@1x', size: 20),
  IosIconTemplate(name: '-20x20@2x', size: 40),
  IosIconTemplate(name: '-20x20@3x', size: 60),
  IosIconTemplate(name: '-29x29@1x', size: 29),
  IosIconTemplate(name: '-29x29@2x', size: 58),
  IosIconTemplate(name: '-29x29@3x', size: 87),
  IosIconTemplate(name: '-40x40@1x', size: 40),
  IosIconTemplate(name: '-40x40@2x', size: 80),
  IosIconTemplate(name: '-40x40@3x', size: 120),
  IosIconTemplate(name: '-60x60@2x', size: 120),
  IosIconTemplate(name: '-60x60@3x', size: 180),
  IosIconTemplate(name: '-76x76@1x', size: 76),
  IosIconTemplate(name: '-76x76@2x', size: 152),
  IosIconTemplate(name: '-83.5x83.5@2x', size: 167),
  IosIconTemplate(name: '-1024x1024@1x', size: 1024),
];

Future<void> createIcons(FlavorConfig config, String flavor) async {
  if (!config.shouldGenerateForIos) {
    return;
  }

  final file = config.iosImage ?? config.baseImage;
  final sourceImage = decodeImage(await file.readAsBytes());

  final iconsetName =
      config.iosName ?? (flavor != null ? 'AppIcon-$flavor' : 'AppIcon');
  print('Building iOS app icon set - $iconsetName');

  for (IosIconTemplate template in iosIcons) {
    final newIconFolder = iosAssetFolder + iconsetName + '.appiconset/';
    final fileName = config.iconsetPrefix ?? iosDefaultIconName;
    final imageFile = File(newIconFolder + fileName + template.name + '.png');
    await imageFile.create(recursive: true);
    final resizedImage = createResizedImage(template, sourceImage);
    await imageFile.writeAsBytes(encodePng(resizedImage));
  }

  await changeIosLauncherIcon(iconsetName, flavor);
  await modifyContentsFile(iconsetName);
}

Image createResizedImage(IosIconTemplate template, Image image) {
  return copyResize(
    image,
    width: template.size,
    height: template.size,
    // Note: Do not change interpolation unless you end up with better results
    //       (see issue for result when using cubic interpolation)
    // https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
    interpolation: image.width >= template.size
        ? Interpolation.average
        : Interpolation.linear,
  );
}

Future<void> changeIosLauncherIcon(String iconName, String flavor) async {
  final File iOSConfigFile = File(iosConfigFile);
  final String text = await iOSConfigFile.readAsString();
  final lines = text.split('\n');

  bool onConfigurationSection = false;
  String currentConfig;

  final xcconfigPattern = RegExp('.*/\\* (.*)\.xcconfig \\*/;');
  final equalsPattern = RegExp('\=(.*);');

  for (int x = 0; x < lines.length; x++) {
    final String line = lines[x];
    if (line.contains('/* Begin XCBuildConfiguration section */')) {
      onConfigurationSection = true;
    }
    if (line.contains('/* End XCBuildConfiguration section */')) {
      onConfigurationSection = false;
    }
    if (onConfigurationSection) {
      final match = xcconfigPattern.firstMatch(line);
      if (match != null) {
        currentConfig = match.group(1);
      }

      if (currentConfig != null &&
          (flavor == null || currentConfig.contains('-$flavor')) &&
          line.contains('ASSETCATALOG')) {
        lines[x] = line.replaceAll(equalsPattern, '= $iconName;');
      }
    }
  }
  final String entireFile = lines.join('\n');
  await iOSConfigFile.writeAsString(entireFile);
}

/// Create the Contents.json file
Future<void> modifyContentsFile(String newIconName) async {
  final String newIconFolder =
      iosAssetFolder + newIconName + '.appiconset/Contents.json';
  final contentsJsonFile = await File(newIconFolder).create(recursive: true);
  final String contentsFileContent = generateContentsFileAsString(newIconName);
  await contentsJsonFile.writeAsString(contentsFileContent);
}

String generateContentsFileAsString(String newIconName) {
  final Map<String, dynamic> contentJson = <String, dynamic>{
    'images': createImageList(newIconName),
    'info': ContentsInfoObject(version: 1, author: 'xcode').toJson()
  };
  return json.encode(contentJson);
}

class ContentsImageObject {
  ContentsImageObject({this.size, this.idiom, this.filename, this.scale});
  final String size;
  final String idiom;
  final String filename;
  final String scale;

  Map<String, String> toJson() {
    return <String, String>{
      'size': size,
      'idiom': idiom,
      'filename': filename,
      'scale': scale
    };
  }
}

class ContentsInfoObject {
  ContentsInfoObject({this.version, this.author});
  final int version;
  final String author;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'author': author,
    };
  }
}

List<Map<String, String>> createImageList(String fileNamePrefix) {
  final List<Map<String, String>> imageList = <Map<String, String>>[
    ContentsImageObject(
            size: '20x20',
            idiom: 'iphone',
            filename: '$fileNamePrefix-20x20@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '20x20',
            idiom: 'iphone',
            filename: '$fileNamePrefix-20x20@3x.png',
            scale: '3x')
        .toJson(),
    ContentsImageObject(
            size: '29x29',
            idiom: 'iphone',
            filename: '$fileNamePrefix-29x29@1x.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '29x29',
            idiom: 'iphone',
            filename: '$fileNamePrefix-29x29@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '29x29',
            idiom: 'iphone',
            filename: '$fileNamePrefix-29x29@3x.png',
            scale: '3x')
        .toJson(),
    ContentsImageObject(
            size: '40x40',
            idiom: 'iphone',
            filename: '$fileNamePrefix-40x40@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '40x40',
            idiom: 'iphone',
            filename: '$fileNamePrefix-40x40@3x.png',
            scale: '3x')
        .toJson(),
    ContentsImageObject(
            size: '60x60',
            idiom: 'iphone',
            filename: '$fileNamePrefix-60x60@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '60x60',
            idiom: 'iphone',
            filename: '$fileNamePrefix-60x60@3x.png',
            scale: '3x')
        .toJson(),
    ContentsImageObject(
            size: '20x20',
            idiom: 'ipad',
            filename: '$fileNamePrefix-20x20@1x.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '20x20',
            idiom: 'ipad',
            filename: '$fileNamePrefix-20x20@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '29x29',
            idiom: 'ipad',
            filename: '$fileNamePrefix-29x29@1x.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '29x29',
            idiom: 'ipad',
            filename: '$fileNamePrefix-29x29@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '40x40',
            idiom: 'ipad',
            filename: '$fileNamePrefix-40x40@1x.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '40x40',
            idiom: 'ipad',
            filename: '$fileNamePrefix-40x40@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '76x76',
            idiom: 'ipad',
            filename: '$fileNamePrefix-76x76@1x.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '76x76',
            idiom: 'ipad',
            filename: '$fileNamePrefix-76x76@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '83.5x83.5',
            idiom: 'ipad',
            filename: '$fileNamePrefix-83.5x83.5@2x.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '1024x1024',
            idiom: 'ios-marketing',
            filename: fileNamePrefix + '-1024x1024@1x.png',
            scale: '1x')
        .toJson()
  ];
  return imageList;
}
