import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

final _kSource = BoxObservationSourceSpec.fromJson(const {
  'schemaVersion': 1,
  'logicalUnitId': 'stage-container-callback-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stage-current-callback-content-inset-v1',
  'webAdapterId': 'stage-current-callback-content-inset-v1',
});

void main() {
  for (final theme in ['light', 'dark']) {
    test('Stage original normal SSR $theme', () async {
      final key = 'stage-container-default-$theme-defaultStyle';
      final entry = MatrixEntry.fromJson({
        'component': 'stage-container',
        'variant': 'default',
        'theme': theme,
        'surfaceStyle': 'defaultStyle',
        'tier': 't2',
        'probes': [
          rootProbeSpec(
            key: key,
            flutterClassName: 'StageContainer',
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
      expect(root.children, hasLength(1));
      expect(root.children.single.localName, 'div');
      expect(root.children.single.children, hasLength(1));
      // Original outer root/two-DIV/whole callback-body health comes first.
      expect(
        receipts,
        hasLength(1),
        reason: 'STAGE_WEB_ORIGINAL_ENTRY_SOURCE_RED',
      );
      expect(
        receipts.single.containsKey('error'),
        false,
        reason: receipts.toString(),
      );
      expect(receipts.single['kind'], 'canonical-ssr-stage-callback-v1');
      expect(
        receipts.single['source'],
        entry.probes.single.boxObservationSource!.toJson(),
      );
      final raw = receipts.single['currentRaw']! as Map;
      expect(raw['callbackReexecuted'], false);
      expect(raw['bodyInteriorIsSourceAuthority'], false);
      expect(raw['bodyFrontier'], hasLength(1));
      expect(raw['captureNodes'], isNotEmpty);
      expect(raw['frameNodes'], isNotEmpty);
      expect(raw['paddingNodes'], isNotEmpty);
    });
  }
}
