import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String deployYaml;

  setUpAll(() {
    deployYaml = File('../.github/workflows/deploy.yaml').readAsStringSync();
  });

  group('deploy.yaml CI/CD pipeline', () {
    test('includes Flutter SDK setup', () {
      expect(deployYaml, contains('subosito/flutter-action'));
    });

    test('runs dart pub get for docs_site', () {
      expect(deployYaml, contains('dart pub get'));
    });

    test('runs flutter pub get for embedded previews', () {
      expect(deployYaml, contains('flutter pub get'));
    });

    test('runs jaspr build', () {
      expect(deployYaml, contains('jaspr build'));
    });

    test('merges Flutter build artifacts', () {
      expect(deployYaml, contains('build/flutter'));
    });

    test('deploys to GitHub Pages', () {
      expect(deployYaml, contains('deploy-pages'));
    });

    test('sets CNAME to coui.cocode.im', () {
      expect(deployYaml, contains('coui.cocode.im'));
    });
  });

  group('version snapshot archive (#3564/#3587)', () {
    test('exposes an optional snapshot_tag workflow_dispatch input', () {
      expect(deployYaml, contains('snapshot_tag'));
    });

    test('checkout fetches full history (tags needed by the snapshot script)', () {
      expect(deployYaml, contains('fetch-depth: 0'));
    });

    test('invokes the snapshot build script', () {
      expect(deployYaml, contains('build_version_snapshot.sh'));
    });

    test('commits the version manifest after a snapshot build', () {
      expect(deployYaml, contains('versions.json'));
    });

    test('elevates contents permission for the manifest commit', () {
      // The workflow-level default is `contents: read` — the commit step
      // only works because build-docs overrides it to `write`.
      expect(deployYaml, contains('contents: write'));
    });
  });
}
