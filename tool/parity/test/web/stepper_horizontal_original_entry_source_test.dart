import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

final _kSource = BoxObservationSourceSpec.fromJson(const {
  'schemaVersion': 1,
  'logicalUnitId': 'stepper-horizontal-generated-layout-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stepper-normal-horizontal-generated-host-v1',
  'webAdapterId': 'stepper-normal-horizontal-generated-host-v1',
});

void main() {
  for (final variant in ['default', 'disabled']) {
    for (final theme in ['light', 'dark']) {
      test('Stepper original normal SSR $variant $theme', () async {
        final key = 'stepper-$variant-$theme-defaultStyle';
        final entry = MatrixEntry.fromJson({
          'component': 'stepper',
          'variant': variant,
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't2',
          'probes': [
            rootProbeSpec(
              key: key,
              flutterClassName: 'Stepper',
              boxObservationSource: _kSource,
            ).toJson(),
          ],
        });
        final receipts = <Map<String, Object?>>[];
        final body = await renderCaptureBodyHtml(
          entry,
          onCurrentBoxSource: receipts.add,
        );
        final parsed = html.parseFragment(body);
        final capture = parsed.querySelectorAll('[data-parity-key]').single;
        final root = parsed
            .querySelectorAll(entry.probes.single.webSelector)
            .single;
        expect(root.parent, same(capture));
        expect(root.localName, 'div');
        expect(root.children, hasLength(3));
        expect(root.children.every((c) => c.localName == 'div'), true);
        // Original root and all three generated column frontiers
        // are healthy before the source matcher.
        expect(
          receipts,
          hasLength(1),
          reason: 'STEPPER_WEB_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(
          receipts.single.containsKey('error'),
          false,
          reason: receipts.toString(),
        );
        expect(receipts.single['kind'], 'canonical-ssr-stepper-horizontal-v1');
        expect(
          receipts.single['source'],
          entry.probes.single.boxObservationSource!.toJson(),
        );
        final raw = receipts.single['currentRaw']! as Map;
        expect(raw['buildOrResolverReexecuted'], false);
        expect(raw['columnInteriorsAreSourceAuthority'], false);
        expect(raw['rawStepItems'], hasLength(3));
        expect(raw['generatedColumns'], hasLength(3));
        expect(raw['captureNodes'], isNotEmpty);
        expect(raw['frameNodes'], isNotEmpty);
      });
    }
  }
}
