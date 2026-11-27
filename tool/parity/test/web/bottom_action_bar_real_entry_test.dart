import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

const BoxObservationSourceSpec _source =
    BoxObservationSourceSpec.bottomActionBarContentInset;
const _expectedSource = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'bottom-action-bar-owned-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'bottom-action-bar-owned-content-inset-v1',
  'webAdapterId': 'bottom-action-bar-owned-content-inset-v1',
};
void main() {
  for (final variant in ['default', 'horizontal', 'summary-compact']) {
    for (final theme in ['light', 'dark']) {
      test('BottomActionBar original Web entry $variant/$theme', () async {
        expect(_source.toJson(), _expectedSource);
        final key = 'bottom-action-bar-$variant-$theme-defaultStyle';
        final entry = MatrixEntry.fromJson({
          'component': 'bottom-action-bar',
          'variant': variant,
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't2',
          'probes': [
            rootProbeSpec(
              key: key,
              flutterClassName: 'BottomActionBar',
              boxObservationSource: _source,
            ).toJson(),
          ],
        });
        final receipts = <Map<String, Object?>>[];
        final body = await renderCaptureBodyHtml(
          entry,
          onCurrentBoxSource: receipts.add,
        );
        final parsed = html.parseFragment(body);
        final captures = parsed.querySelectorAll('[data-parity-key]');
        expect(captures, hasLength(1));
        final selected = parsed.querySelectorAll(
          entry.probes.single.webSelector,
        );
        expect(selected, hasLength(1));
        expect(selected.single.parent, same(captures.single));
        expect(selected.single.attributes['role'], 'group');
        expect(selected.single.querySelectorAll('button'), isNotEmpty);
        // Original normal public product/action health precedes target RED.
        expect(
          receipts,
          hasLength(1),
          reason: 'BOTTOM_ACTION_BAR_WEB_ORIGINAL_SOURCE_RED',
        );
        expect(receipts.single['kind'], 'canonical-ssr-bottom-action-bar-v1');
        expect(receipts.single['entryKey'], key);
        expect(receipts.single['source'], _source.toJson());
      });
    }
  }
}
