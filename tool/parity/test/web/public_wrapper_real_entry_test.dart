import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/public_wrapper_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes = <(String, String, Map<String, Object?>)>[
  (
    'tree',
    'trailing',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'tree-generated-outer-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'tree-generated-outer-layout-host-v1',
      'webAdapterId': 'tree-generated-outer-layout-host-v1',
    },
  ),
  (
    'media-query',
    'default',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'media-query-generated-visibility-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'media-query-generated-visibility-layout-host-v1',
      'webAdapterId': 'media-query-generated-visibility-layout-host-v1',
    },
  ),
  (
    'swipe-actions',
    'default',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'swipe-actions-generated-outer-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'swipe-actions-generated-outer-layout-host-v1',
      'webAdapterId': 'swipe-actions-generated-outer-layout-host-v1',
    },
  ),
];
void main() {
  test(
    'source factory agrees with declaration for every actual surface enum',
    () {
      for (final recipe in _kRecipes) {
        for (final style in CoreSurfaceStyleId.values) {
          final entry = MatrixEntry.fromJson({
            'component': recipe.$1,
            'variant': recipe.$2,
            'theme': 'light',
            'surfaceStyle': style.name,
            'tier': 't2',
            'probes': [
              rootProbeSpec(
                key: 'k',
                flutterClassName: 'F',
                boxObservationSource: BoxObservationSourceSpec.fromJson(
                  recipe.$3,
                ),
              ).toJson(),
            ],
          });
          expect(PublicWrapperSsrSource.forEntry(entry), isNotNull);
        }
      }
    },
  );
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        'Public wrapper original Web ${recipe.$1}/${recipe.$2}/$theme',
        () async {
          final key = '${recipe.$1}-${recipe.$2}-$theme-defaultStyle';
          final source = BoxObservationSourceSpec.fromJson(recipe.$3);
          final entry = MatrixEntry.fromJson({
            'component': recipe.$1,
            'variant': recipe.$2,
            'theme': theme,
            'surfaceStyle': 'defaultStyle',
            'tier': 't2',
            'probes': [
              rootProbeSpec(
                key: key,
                flutterClassName: 'unused-original-entry',
                boxObservationSource: source,
              ).toJson(),
            ],
          });
          final receipts = <Map<String, Object?>>[];
          final body = await renderCaptureBodyHtml(
            entry,
            onCurrentBoxSource: receipts.add,
          );
          final fragment = html.parseFragment(body);
          final capture = fragment.querySelectorAll('[data-parity-key]');
          expect(capture, hasLength(1));
          expect(capture.single.attributes['data-parity-key'], key);
          expect(capture.single.children, hasLength(1));
          final root = capture.single.children.single;
          switch (recipe.$1) {
            case 'tree':
              expect(root.attributes['role'], 'tree');
              expect(root.text, contains('src'));
              expect(root.text, contains('app.dart'));
            case 'media-query':
              expect(root.querySelectorAll('style'), isNotEmpty);
              expect(root.text, contains('md 이상'));
              expect(root.text, contains('md 미만'));
            case 'swipe-actions':
              expect(root.attributes.containsKey('data-swipe-actions'), true);
              expect(root.text, contains('주간 보고서'));
              expect(root.text, contains('보관'));
          }
          expect(
            receipts,
            hasLength(1),
            reason: 'PUBLIC_WRAPPER_WEB_ORIGINAL_SOURCE_RED',
          );
          expect(receipts.single['source'], recipe.$3);
          expect(receipts.single['entryKey'], key);
        },
      );
    }
  }
}
