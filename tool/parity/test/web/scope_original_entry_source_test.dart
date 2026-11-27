// Regression coverage through the normal SSR entry point.
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

final _source = BoxObservationSourceSpec.fromJson(const {
  'schemaVersion': 1,
  'logicalUnitId': 'classic-scope-showcase-allocation-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'classic-scope-showcase-allocation-host-v1',
  'webAdapterId': 'classic-scope-showcase-allocation-host-v1',
});

const _kCases = <(String, String), (String, int)>{
  ('drag', 'default'): ('DragScope', 2),
  ('drag', 'board'): ('DragScope', 2),
  ('drag', 'overlay'): ('DragScope', 2),
  ('subfocus', 'default'): ('SubfocusScope', 3),
};
void main() {
  for (final row in _kCases.entries) {
    for (final theme in ['light', 'dark']) {
      test('scope original normal Web ${row.key}/$theme', () async {
        final (component, variant) = row.key;
        final (className, count) = row.value;
        final key = '$component-$variant-$theme-defaultStyle';
        final entry = MatrixEntry.fromJson({
          'component': component,
          'variant': variant,
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't2',
          'probes': [
            rootProbeSpec(
              key: key,
              flutterClassName: className,
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
        final selected = parsed.querySelectorAll(
          entry.probes.single.webSelector,
        );
        expect(captures, hasLength(1));
        expect(selected, hasLength(1));
        final owner = selected.single;
        expect(owner.parent, same(captures.single));
        expect(owner.localName, 'div');
        expect(owner.children.first.localName, 'div');
        expect(owner.children.first.children, isNotEmpty);
        // Raw occurrence count is not DOM element count: idle DragOverlay
        // keeps its supplied occurrence with an empty rendered frontier.
        if (component == 'drag') {
          expect(owner.children, hasLength(2));
          final live = owner.children.last;
          expect(live.attributes['aria-live'], 'polite');
          expect(live.attributes['aria-atomic'], 'true');
          expect(live.children.single.localName, 'span');
          // Empty or nonempty actual owned text is allowed, never foreign.
        } else {
          expect(owner.children, hasLength(1));
          expect(owner.attributes['role'], 'group');
          expect(owner.attributes['tabindex'], '0');
        }
        // Normal original generated root/layout/live-region health precedes
        // the exact missing provenance receipt target, with no browser/Node.
        expect(
          receipts,
          hasLength(1),
          reason: 'SCOPE_WEB_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(receipts.single['kind'], 'canonical-ssr-scope-allocation-v1');
        expect(receipts.single['entryKey'], key);
        expect(receipts.single['source'], _source.toJson());
        final raw = receipts.single['currentRaw']! as Map;
        expect(raw['rawSlotCount'], count + 1);
        expect(raw['scopeChild'], {
          'seat': 0,
          'present': true,
          'ownedLayout': true,
        });
        expect(raw['layoutSlots'], hasLength(count));
      });
    }
  }
}
