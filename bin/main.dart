import 'dart:io';

import 'package:flutter_launcher_icons/main.dart' as flutter_launcher_icons;
import 'package:flutter_launcher_icons/custom_exceptions.dart';

void main(List<String> arguments) {
  try {
    flutter_launcher_icons.createIconsFromArguments(arguments);
  } catch (e) {
    if (e is NoConfigFoundException || e is InvalidConfigException) {
      stderr.writeln(e.message);
    } else {
      stderr.writeln(e);
    }
    exit(2);
  }
}
