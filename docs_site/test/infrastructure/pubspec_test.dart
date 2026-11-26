import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String pubspecContent;

  setUpAll(() {
    pubspecContent = File('pubspec.yaml').readAsStringSync();
  });

  group('docs_site pubspec.yaml', () {
    test('has jaspr_flutter_embed dependency', () {
      expect(pubspecContent, contains('jaspr_flutter_embed'));
    });

    test('has coui_web dependency', () {
      expect(pubspecContent, contains('coui_web:'));
    });

    test('has coui_flutter dependency', () {
      expect(pubspecContent, contains('coui_flutter:'));
    });

    test('has coui_core dependency', () {
      expect(pubspecContent, contains('coui_core:'));
    });

    test('has jaspr mode: static', () {
      expect(pubspecContent, contains('mode: static'));
    });

    test('has flutter: embedded', () {
      expect(pubspecContent, contains('flutter: embedded'));
    });

    test('requires Flutter SDK', () {
      expect(pubspecContent, contains('flutter:'));
    });
  });

  group('build infrastructure', () {
    test('flutter_bootstrap.js exists', () {
      expect(File('web/flutter_bootstrap.js').existsSync(), isTrue);
    });

    test('preview_skeleton.dart exists', () {
      expect(
        File('lib/components/preview_skeleton.dart').existsSync(),
        isTrue,
      );
    });

    test('flutter_preview.imports.dart exists (generated)', () {
      expect(
        File('lib/components/flutter_preview.imports.dart').existsSync(),
        isTrue,
      );
    });
  });
}
