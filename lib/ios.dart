import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';

import 'config.dart';
import 'constants.dart';

Future<void> createIcons(FlavorConfig config, String flavor) async {
  final file = config.iosImage ?? config.baseImage;
  final sourceImage = decodeImage(await file.readAsBytes());

  final iconsetName =
      config.iosName ?? (flavor != null ? 'AppIcon-$flavor' : 'AppIcon');
  print('Building iOS app icon set - $iconsetName');

  final iconsetPrefix = config.iconsetPrefix ?? iosDefaultIconName;
  final imageObjects = ContentsImageObject.createImageList(iconsetPrefix);
  final Map doneMap = <String, bool>{};

  for (final obj in imageObjects) {
    final filename = obj.filename;
    if (doneMap.containsKey(filename)) {
      continue;
    }
    doneMap[filename] = true;
    final newIconFolder = iosAssetFolder + iconsetName + '.appiconset/';
    final imageFile = File(newIconFolder + filename);
    await imageFile.create(recursive: true);
    final int side = obj.scaledSide.round();
    final resizedImage = createResizedImage(sourceImage, side);
    await imageFile.writeAsBytes(encodePng(resizedImage));
  }

  await changeIosLauncherIcon(iconsetName, flavor);
  await modifyContentsFile(iconsetName, imageObjects);
}

Image createResizedImage(Image image, int side) {
  if (image.width == side && image.height == side) {
    return image;
  }
  return copyResize(
    image,
    width: side,
    height: side,
    // Note: Do not change interpolation unless you end up with better results
    //       (see issue for result when using cubic interpolation)
    // https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
    interpolation: image.width >= side
        // NOTE: fighting the formatter
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
Future<void> modifyContentsFile(
    String iconsetName, List<ContentsImageObject> images) async {
  final String newIconFolder =
      iosAssetFolder + iconsetName + '.appiconset/Contents.json';
  final contentsJsonFile = await File(newIconFolder).create(recursive: true);
  final String contentsFileContent = generateContentsFileAsString(images);
  await contentsJsonFile.writeAsString(contentsFileContent);
}

String generateContentsFileAsString(List<ContentsImageObject> images) {
  final data = {
    'images': images,
    'info': ContentsInfoObject(version: 1, author: 'xcode'),
  };
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data);
}

final _zeroesPattern = RegExp('.0+\$');

class ContentsImageObject {
  ContentsImageObject({
    this.side,
    this.idiom,
    this.prefix,
    this.scale = 1,
  })  : _side = side.toStringAsFixed(1).replaceAll(_zeroesPattern, ''),
        _scale = '${scale}x';

  final double side;
  final String idiom;
  final String prefix;
  final int scale;

  String get filename => '$prefix-$size@$strScale.png';

  final String _side;
  String get size => '${_side}x$_side';

  final String _scale;
  String get strScale => _scale;

  double get scaledSide => side * scale;

  static List<ContentsImageObject> createImageList(
    String prefix, {
    bool includeIphone = true,
    bool includeIpad = true,
    bool includeAppStore = true,
  }) {
    final result = <ContentsImageObject>[];
    if (includeIphone) {
      result.addAll(forIphone(prefix));
    }
    if (includeIpad) {
      result.addAll(forIpad(prefix));
    }
    if (includeAppStore) {
      result.add(marketingImageObject(prefix));
    }
    return result;
  }

  static List<ContentsImageObject> forIphone(String prefix) {
    return [
      // NOTE: iPhone Notification - iOS 7-13
      ContentsImageObject(side: 20, idiom: 'iphone', prefix: prefix, scale: 2),
      ContentsImageObject(side: 20, idiom: 'iphone', prefix: prefix, scale: 3),
      // NOTE: iPhone Settings - iOS 7-13
      ContentsImageObject(side: 29, idiom: 'iphone', prefix: prefix, scale: 1),
      ContentsImageObject(side: 29, idiom: 'iphone', prefix: prefix, scale: 2),
      ContentsImageObject(side: 29, idiom: 'iphone', prefix: prefix, scale: 3),
      // NOTE: iPhone Spotlight - iOS 7-13
      ContentsImageObject(side: 40, idiom: 'iphone', prefix: prefix, scale: 2),
      ContentsImageObject(side: 40, idiom: 'iphone', prefix: prefix, scale: 3),
      // NOTE: iPhone App - iOS 7-13
      ContentsImageObject(side: 60, idiom: 'iphone', prefix: prefix, scale: 2),
      ContentsImageObject(side: 60, idiom: 'iphone', prefix: prefix, scale: 3),
    ];
  }

  static List<ContentsImageObject> forIpad(String prefix) {
    return [
      // NOTE: iPad Notifications - iOS 7-13
      ContentsImageObject(side: 20, idiom: 'ipad', prefix: prefix, scale: 1),
      ContentsImageObject(side: 20, idiom: 'ipad', prefix: prefix, scale: 2),
      // NOTE: iPad Settings - iOS 7-13
      ContentsImageObject(side: 29, idiom: 'ipad', prefix: prefix, scale: 1),
      ContentsImageObject(side: 29, idiom: 'ipad', prefix: prefix, scale: 2),
      // NOTE: iPad Spotlight - iOS 7-13
      ContentsImageObject(side: 40, idiom: 'ipad', prefix: prefix, scale: 1),
      ContentsImageObject(side: 40, idiom: 'ipad', prefix: prefix, scale: 2),
      // NOTE: iPad App - iOS 7-13
      ContentsImageObject(side: 76, idiom: 'ipad', prefix: prefix, scale: 1),
      ContentsImageObject(side: 76, idiom: 'ipad', prefix: prefix, scale: 2),
      // NOTE: iPad Pro (12.9-inch) App - iOS 9-13
      ContentsImageObject(side: 83.5, idiom: 'ipad', prefix: prefix, scale: 2),
    ];
  }

  static ContentsImageObject marketingImageObject(String prefix) {
    // NOTE: App Store
    return ContentsImageObject(
      side: 1024,
      idiom: 'ios-marketing',
      prefix: prefix,
      scale: 1,
    );
  }

  Map<String, String> toJson() {
    return <String, String>{
      'size': size,
      'idiom': idiom,
      'filename': filename,
      'scale': strScale,
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
