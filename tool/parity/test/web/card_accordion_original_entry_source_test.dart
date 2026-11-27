import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

const _card = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'card-surface-frame-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'card-current-outlined-frame-content-v1',
  'webAdapterId': 'card-current-outlined-frame-content-v1',
};
const _accordion = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'accordion-surface-frame-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'accordion-current-outlined-frame-content-v1',
  'webAdapterId': 'accordion-current-outlined-frame-content-v1',
};
const _cases = [
  ('card', 'default'),
  ('card', 'filled'),
  ('card', 'elevated'),
  ('accordion', 'default'),
];

void main() {
  for (final (component, variant) in _cases) {
    for (final theme in ['light', 'dark']) {
      test('frame original normal Web $component/$variant/$theme', () async {
        final key = '$component-$variant-$theme-defaultStyle';
        MatrixEntry entry(bool declared) => MatrixEntry.fromJson({
          'component': component,
          'variant': variant,
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't2',
          'probes': [
            rootProbeSpec(
              key: key,
              flutterClassName: component == 'card' ? 'Card' : 'Accordion',
              boxObservationSource: declared
                  ? BoxObservationSourceSpec.fromJson(
                      component == 'card' ? _card : _accordion,
                    )
                  : null,
            ).toJson(),
          ],
        });
        // First prove the original normal public response,
        // without the new source declaration.
        final health = await renderCaptureBodyHtml(entry(false));
        final parsed = html.parseFragment(health);
        final owner = parsed.querySelectorAll(
          entry(false).probes.single.webSelector,
        );
        expect(owner, hasLength(1));
        expect(owner.single.localName, 'div');
        expect(parsed.querySelectorAll('[data-parity-key]'), hasLength(1));
        expect(owner.single.children, hasLength(component == 'card' ? 1 : 6));
        final receipts = <Map<String, Object?>>[];
        final body = await renderCaptureBodyHtml(
          entry(true),
          onCurrentBoxSource: receipts.add,
        );
        expect(
          html
              .parseFragment(body)
              .querySelectorAll(entry(true).probes.single.webSelector),
          hasLength(1),
        );
        expect(
          receipts,
          hasLength(1),
          reason: 'FRAME_WEB_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(
          receipts.single.containsKey('error'),
          false,
          reason: '${receipts.single}',
        );
        expect(receipts.single['kind'], 'canonical-ssr-surface-frame-v1');
        expect(
          receipts.single['source'],
          component == 'card' ? _card : _accordion,
        );
        final raw = receipts.single['currentRaw']! as Map<dynamic, dynamic>;
        expect(raw['rawSlotCount'], component == 'card' ? 6 : 3);
        expect(raw['rawDeclarationMountAuthority'], false);
        expect(raw['distributedSlotAndItemInsetsIncluded'], false);
        expect(raw['capture'], isA<Map<dynamic, dynamic>>());
      });
    }
  }
}
