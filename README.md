[![Flutter Community: flutter_launcher_icons](https://fluttercommunity.dev/_github/header/flutter_launcher_icons)](https://github.com/fluttercommunity/community)

[![Build Status](https://travis-ci.org/fluttercommunity/flutter_launcher_icons.svg?branch=master)](https://travis-ci.org/MarkOSullivan94/flutter_launcher_icons) [![pub package](https://img.shields.io/pub/v/flutter_launcher_icons.svg)](https://pub.dartlang.org/packages/flutter_launcher_icons)

# Flutter Launcher Icons

A command-line tool which simplifies the task of updating your Flutter app's launcher icon. Fully flexible, allowing you to choose what platform you wish to update the launcher icon for and if you want, the option to keep your old launcher icon in case you want to revert back sometime in the future.


## :sparkles: What's New

#### Version 0.7.2 (25th May 2019)
 * Reverted back using old interpolation method

#### Version 0.7.1 (24th May 2019)
 * Fixed issue with image dependency not working on latest version of Flutter (thanks to @sboutet06)
 * Fixed iOS icon sizes which were incorrect (thanks to @sestegra)
 * Removed dart_config git dependency and replaced with yaml dependency 

#### Version 0.7.0 (22nd November 2018)
 * Added check to ensure the Android file name is valid
 * Fixed issue where there was a git diff when there was no change
 * Fixed issue where iOS icon would be generated when it shouldn't be
 * Added support for drawables to be used for adaptive icon backgrounds
 * Added support for Flutter Launcher Icons to be able to run with it's own config file (no longer necessary to add to pubspec.yaml)

#### Version 0.6.1 (26th August 2018)
 * Upgraded dependencies so that it should now work with Dart 2.1.0

#### Version 0.6.0 (8th August 2018)
 * Moved the package to [Flutter Community](https://github.com/fluttercommunity/community)

#### Version 0.5.0 (12th June 2018)
 * [Android] Support for adaptive icons added


## :book: Guide

#### 1. Setup the config file

Add your Flutter Launcher Icons configuration to your `pubspec.yaml` or create a new config file called `flutter_launcher_icons.yaml`. 
An example is shown below. A more complex example [can be found in the example project](https://github.com/fluttercommunity/flutter_launcher_icons/blob/master/example/pubspec.yaml).
```yaml
dev_dependencies: 
  flutter_launcher_icons: "^0.7.2"
  
flutter_icons:
  android: "launcher_icon" 
  ios: true
  image_path: "assets/icon/icon.png"
```
If you name your configuration file something other than `flutter_launcher_icons.yaml` or `pubspec.yaml` you will need to specify 
the name of the file when running the package.

```
flutter pub get
flutter pub run flutter_launcher_icons:main -f <your config file name here>
```

Note: If you are not using the existing `pubspec.yaml` ensure that your config file is located in the same directory as it.

#### 2. Run the package

After setting up the configuration, all that is left to do is run the package.

```
flutter pub get
flutter pub pub run flutter_launcher_icons:main
```

If you encounter any issues [please report them here](https://github.com/fluttercommunity/flutter_launcher_icons/issues).


In the above configuration, the package is setup to replace the existing launcher icons in both the Android and iOS project 
with the icon located in the image path specified above and given the name "launcher_icon" in the Android project and "Example-Icon" in the iOS project.


## :mag: Attributes

Shown below is the full list of attributes which you can specify within your Flutter Launcher Icons configuration.

- `android`/`ios`
  - `true`: Override the default existing Flutter launcher icon for the platform specified
  - `false`: Ignore making launcher icons for this platform
  - `icon/path/here.png`: This will generate a new launcher icons for the platform with the name you specify, without removing the old default existing Flutter launcher icon.

- `image_path`: The location of the icon image file which you want to use as the app launcher icon 

- `image_path_android`: The location of the icon image file specific for Android platform (optional - if not defined then the image_path is used)

- `image_path_ios`: The location of the icon image file specific for iOS platform (optional - if not defined then the image_path is used)

_Note: iOS icons should [fill the entire image](https://stackoverflow.com/questions/26014461/black-border-on-my-ios-icon) and not contain transparent borders._

The next two attributes are only used when generating Android launcher icon

- `adaptive_icon_background`: The color (E.g. `"#ffffff"`) or image asset (E.g. `"assets/images/christmas-background.png"`) which will 
be used to fill out the background of the adaptive icon. 

- `adaptive_icon_foreground`: The image asset which will be used for the icon foreground of the adaptive icon


## :question: Troubleshooting

Listed a couple common issues with solutions for them


#### Generated icon color is different from the original icon

Caused by an update to the image dependency which is used by Flutter Launcher Icons. 

```
Use #AARRGGBB for colors instead of ##AABBGGRR, to be compatible with Flutter image class.
```

[Related issue](https://github.com/fluttercommunity/flutter_launcher_icons/issues/98)


#### Image foreground is too big / too small

For best results try and use a foreground image which has padding much like [the one in the example](https://github.com/fluttercommunity/flutter_launcher_icons/blob/master/example/assets/images/icon-foreground-432x432.png).

[Related issue](https://github.com/fluttercommunity/flutter_launcher_icons/issues/96)
 
=======
## Flavor support

Create a Flutter Launcher Icons configuration file for your flavor. The config file is called `flutter_laucher_icons-<flavor>.yaml` by replacing `<flavor>` by the name of your desired flavor.

The configuration file format is the same.

## :eyes: Example

[![Video Example](https://img.youtube.com/vi/RjNAxwcP3Tc/0.jpg)](https://www.youtube.com/watch?v=RjNAxwcP3Tc)

Note: This is showing a very old version (v0.0.5)

### Special thanks

- Thanks to Brendan Duncan for the underlying [image package](https://pub.dev/packages/image) to transform the icons. 
- Big thank you to all the contributors to the project. Every PR / reported issue is greatly appreciated! 
