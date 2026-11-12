import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'App Launcher Icon Integration & Quality Tests - Shree Shakti Electric',
    () {
      test('1. Master 1024x1024 icon assets exist in assets/icons/', () {
        final masterIcon = File('assets/icons/app_icon.png');
        final fgIcon = File('assets/icons/app_icon_foreground.png');
        final bgIcon = File('assets/icons/app_icon_background.png');
        final icoFile = File('assets/icons/app_icon.ico');

        expect(
          masterIcon.existsSync(),
          isTrue,
          reason: 'assets/icons/app_icon.png must exist',
        );
        expect(
          fgIcon.existsSync(),
          isTrue,
          reason: 'assets/icons/app_icon_foreground.png must exist',
        );
        expect(
          bgIcon.existsSync(),
          isTrue,
          reason: 'assets/icons/app_icon_background.png must exist',
        );
        expect(
          icoFile.existsSync(),
          isTrue,
          reason: 'assets/icons/app_icon.ico must exist',
        );

        expect(masterIcon.lengthSync(), greaterThan(10000));
        expect(fgIcon.lengthSync(), greaterThan(10000));
        expect(bgIcon.lengthSync(), greaterThan(10000));
      });

      test(
        '2. Android launcher icons exist for all standard mipmap densities',
        () {
          final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

          for (final density in densities) {
            final stdIcon = File(
              'android/app/src/main/res/mipmap-$density/ic_launcher.png',
            );
            final roundIcon = File(
              'android/app/src/main/res/mipmap-$density/ic_launcher_round.png',
            );
            final fgIcon = File(
              'android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png',
            );

            expect(
              stdIcon.existsSync(),
              isTrue,
              reason: 'Standard icon for $density must exist',
            );
            expect(
              roundIcon.existsSync(),
              isTrue,
              reason: 'Round icon for $density must exist',
            );
            expect(
              fgIcon.existsSync(),
              isTrue,
              reason: 'Foreground icon for $density must exist',
            );

            expect(stdIcon.lengthSync(), greaterThan(500));
            expect(roundIcon.lengthSync(), greaterThan(500));
          }
        },
      );

      test(
        '3. Android adaptive icon XML definitions exist in mipmap-anydpi-v26/',
        () {
          final adaptiveXml = File(
            'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
          );
          final roundAdaptiveXml = File(
            'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
          );

          expect(adaptiveXml.existsSync(), isTrue);
          expect(roundAdaptiveXml.existsSync(), isTrue);

          final content = adaptiveXml.readAsStringSync();
          expect(content, contains('<adaptive-icon'));
          expect(content, contains('ic_launcher_background'));
          expect(content, contains('ic_launcher_foreground'));
        },
      );

      test(
        '4. AndroidManifest.xml registers application name and both icon types',
        () {
          final manifest = File('android/app/src/main/AndroidManifest.xml');
          expect(manifest.existsSync(), isTrue);

          final content = manifest.readAsStringSync();
          expect(content, contains('android:label="Shree Shakti Electric"'));
          expect(content, contains('android:icon="@mipmap/ic_launcher"'));
          expect(
            content,
            contains('android:roundIcon="@mipmap/ic_launcher_round"'),
          );
        },
      );

      test(
        '5. Windows application icon exists in windows/runner/resources/ and is referenced in Runner.rc',
        () {
          final winIco = File('windows/runner/resources/app_icon.ico');
          expect(winIco.existsSync(), isTrue);
          expect(winIco.lengthSync(), greaterThan(10000));

          final runnerRc = File('windows/runner/Runner.rc');
          expect(runnerRc.existsSync(), isTrue);
          expect(
            runnerRc.readAsStringSync(),
            contains('resources\\\\app_icon.ico'),
          );
        },
      );

      test(
        '6. Pubspec.yaml registers icon assets and launcher icon configuration',
        () {
          final pubspec = File('pubspec.yaml');
          expect(pubspec.existsSync(), isTrue);

          final content = pubspec.readAsStringSync();
          expect(content, contains('assets/icons/app_icon.png'));
          expect(content, contains('flutter_launcher_icons:'));
          expect(content, contains('image_path: "assets/icons/app_icon.png"'));
        },
      );
    },
  );
}
