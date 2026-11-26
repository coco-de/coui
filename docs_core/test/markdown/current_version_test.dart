@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/current_version.dart';
import 'package:test/test.dart';

void main() {
  group('parsePubspecVersion', () {
    test('reads the top-level version key', () {
      expect(
        parsePubspecVersion('name: coui_flutter\nversion: 0.128.1\npublish_to: none\n'),
        '0.128.1',
      );
    });

    test('does not match version: nested under another key', () {
      // A pubspec's own `version:` is always top-level (col 0); this guards
      // the anchoring, not a real-world shape — pubspec.yaml has no reason
      // to nest a `version:` key today, but a false match here would silently
      // pick up the wrong string if one were ever added.
      expect(parsePubspecVersion('environment:\n  version: not-this\n'), isNull);
    });

    test('returns null when the key is missing', () {
      expect(parsePubspecVersion('name: coui_flutter\n'), isNull);
    });
  });

  group('releaseTag', () {
    test('matches release-please include-component-in-tag format', () {
      expect(releaseTag('coui_flutter', '0.128.1'), 'coui_flutter-v0.128.1');
    });
  });

  group('real package pubspec.yaml files parse to a semver version', () {
    for (final package in ['coui_flutter', 'coui_web', 'coui_core']) {
      test('packages/$package/pubspec.yaml has a version', () {
        final file = File('../packages/$package/pubspec.yaml');
        expect(file.existsSync(), isTrue, reason: '${file.path} must exist');

        final version = parsePubspecVersion(file.readAsStringSync());
        expect(
          version,
          isNotNull,
          reason: '${file.path} has no top-level `version:` key.',
        );
        expect(version, matches(RegExp(r'^\d+\.\d+\.\d+')));
      });
    }
  });

  group('currentVersionView — what both documentation surfaces show', () {
    const pubspec = 'name: coui_flutter\nversion: 0.128.1\n';

    test('the bare version by default, the release tag with tag="true"', () {
      final plain = currentVersionView(
        package: 'coui_flutter',
        attributes: const {'package': 'coui_flutter'},
        pubspecSource: pubspec,
      );
      final tagged = currentVersionView(
        package: 'coui_flutter',
        attributes: const {'package': 'coui_flutter', 'tag': 'TRUE'},
        pubspecSource: pubspec,
      );
      expect((plain as CurrentVersionText).text, '0.128.1');
      expect((tagged as CurrentVersionText).text, 'coui_flutter-v0.128.1');
    });

    test('a pubspec without a version degrades to a notice', () {
      final view = currentVersionView(
        package: 'coui_flutter',
        attributes: const {'package': 'coui_flutter'},
        pubspecSource: 'name: coui_flutter\n',
      );
      expect((view as CurrentVersionNotice).message, 'coui_flutter/pubspec.yaml has no `version:` key.');
    });

    test('package attribute: missing and empty both read as absent', () {
      expect(currentVersionPackage(const {}), isNull);
      expect(currentVersionPackage(const {'package': ''}), isNull);
      expect(currentVersionPackage(const {'package': 'coui_web'}), 'coui_web');
    });
  });
}
