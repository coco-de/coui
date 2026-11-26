import 'dart:convert';
import 'dart:io';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:test/test.dart';

import '../../src/source/playground_value_authority.dart';

void main() {
  final root = findRepoRoot();
  final scene = readDocsScenes(
    'button',
  ).firstWhere((value) => value.tag == 'Playground');
  late Directory temporary;
  late File manifest;
  late Map<String, Object?> payload;
  setUp(() {
    temporary = Directory.systemTemp.createTempSync('playground-authority-');
    manifest = File('${temporary.path}/manifest.json')
      ..writeAsStringSync(
        jsonEncode({
          'entries': [
            {'key': 'entry', 'component': 'button', 'variant': scene.reference},
          ],
        }),
      );
    payload = {
      'key': 'entry',
      'component': 'button',
      'variant': scene.reference,
      'width': 800,
      'scene': scene.toJson(),
    };
  });
  tearDown(() => temporary.deleteSync(recursive: true));

  Map<String, Object?> receipt({Uri? url}) =>
      preparePlaygroundNavigationReceipt(
        sourceRoot: root,
        manifestFile: manifest,
        navigationURL:
            url ??
            Uri.file(
              '${temporary.path}/runtime.html',
            ).replace(fragment: jsonEncode(payload)),
        actualRuntimePayload: payload,
      );

  test(
    'actual navigation carries an independently parsed source scene proof',
    () {
      final value = receipt();
      expect(value['kind'], 'canonical-runtime-navigation-v1');
      expect(value['preparedPayload'], same(payload));
      expect(value['payloadAuthority'], value['authority']);
      expect((value['authority']! as Map)['reference'], scene.reference);
      expect(
        (value['authority']! as Map)['sceneValueSha256'],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    },
  );
  test(
    'diagnostic origins do not change the existing scene value identity',
    () {
      final original = receipt()['authority'];
      payload['scene'] = {
        ...scene.toJson(),
        'origins': ['another-job/source.md:1'],
      };
      expect(receipt()['payloadAuthority'], original);
    },
  );
  test('a prepared payload cannot authorize a different navigation URL', () {
    expect(
      () => receipt(
        url: Uri.file(
          '${temporary.path}/runtime.html',
        ).replace(fragment: jsonEncode({...payload, 'width': 801})),
      ),
      throwsFormatException,
    );
  });
  test(
    'a real payload scene with changed values cannot reuse the source proof',
    () {
      payload['scene'] = {
        ...scene.toJson(),
        'attributes': {
          ...scene.attributes,
          'measurement-extra': 'not-authored',
        },
      };
      expect(receipt, throwsFormatException);
    },
  );
  test('an entry absent from the actual manifest cannot borrow its hash', () {
    payload['key'] = 'not-in-manifest';
    expect(receipt, throwsFormatException);
  });
  test('ambiguous manifest membership is rejected', () {
    final row = {
      'key': 'entry',
      'component': 'button',
      'variant': scene.reference,
    };
    manifest.writeAsStringSync(
      jsonEncode({
        'entries': [row, row],
      }),
    );
    expect(receipt, throwsFormatException);
  });
}
