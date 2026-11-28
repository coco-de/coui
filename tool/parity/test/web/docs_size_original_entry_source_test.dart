import 'dart:isolate';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/web_capture_backend.dart';

void main() {
  // Enumerate the whole current declared family before any result is read.
  final scenes = <(String, DocsScene)>[
    for (final component in (kDocsSizeSpecComponents.toList()..sort()))
      for (final scene in readDocsScenes(component))
        if (scene.tag == 'SizeSpec') (component, scene),
  ];
  final entries = <MatrixEntry>[
    for (final (component, scene) in scenes)
      for (final theme in ['light', 'dark'])
        MatrixEntry.fromJson({
          'component': component,
          'variant': scene.reference,
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't1',
          'probes': captureProbes(
            key: '$component-${scene.reference}-$theme-defaultStyle',
            component: component,
            variant: scene.reference,
            flutterClassName: 'FlutterDocsSizeSpec',
            docsScene: scene,
          ).map((p) => p.toJson()).toList(),
        }),
  ];
  test('all SizeSpec default roots are selected before source outcomes', () {
    expect(entries, hasLength(56));
    expect(entries.map((e) => e.key).toSet(), hasLength(entries.length));
    expect(
      entries.every(
        (e) =>
            e.probes.single.boxObservationSource?.logicalUnitId ==
            'documentation-size-preview-frame',
      ),
      true,
    );
  });
  for (final entry in entries) {
    test('SizeSpec original normal source ${entry.key}', () async {
      final (original, _, originalBuilds) = await _freshNormalRender(
        entry.toJson(),
        false,
      );
      final (requested, receipts, requestedBuilds) = await _freshNormalRender(
        entry.toJson(),
        true,
      );
      final fragment = html.parseFragment(requested);
      final capture = fragment.querySelectorAll('[data-parity-key]').single;
      final result = capture.querySelectorAll('.docs-size-spec').single;
      expect(capture.attributes['data-parity-key'], entry.key);
      expect(result.children, hasLength(2));
      expect(result.children[0].classes, [
        'docs-stage',
        'docs-stage--hug',
        'docs-stage--row',
      ]);
      expect(result.children[1].classes, ['docs-table']);
      expect(result.children[0].children, isNotEmpty);
      expect(originalBuilds, 1);
      expect(
        requestedBuilds,
        1,
        reason: 'observer never replays the original builder',
      );
      if (const ['menu', 'select'].contains(entry.component)) {
        final (secondOriginal, _, builds) = await _freshNormalRender(
          entry.toJson(),
          false,
        );
        expect(builds, 1);
        expect(
          original == secondOriginal,
          false,
          reason:
              'original identityHashCode IDs differ even without observation',
        );
        // No cross-document ID normalization. The unchanged shared SSR guard
        // validates THIS requested response's actual IDs/DOM before and after
        // mounted observation; completion consumes that exact returned body.
      } else {
        expect(
          requested,
          original,
          reason: 'ordinary SSR bytes and IDs unchanged',
        );
      }
      // Genuine original-entry health precedes the source requirement.
      expect(
        receipts,
        hasLength(1),
        reason: 'SIZE_WEB_ORIGINAL_ENTRY_SOURCE_RED',
      );
      expect(
        receipts.single.containsKey('error'),
        false,
        reason: receipts.toString(),
      );
      expect(receipts.single['kind'], 'canonical-ssr-docs-size-preview-v1');
      expect(
        receipts.single['source'],
        entry.probes.single.boxObservationSource!.toJson(),
      );
    });
  }
}

// Each normal document starts at the same original counter state. Reusing one
// isolate increments existing interceptor IDs even without a source observer.
Future<(String, List<Map<String, Object?>>, int)> _freshNormalRender(
  Map<String, Object?> entry,
  bool requested,
) => Isolate.run(() async {
  final receipts = <Map<String, Object?>>[];
  final original = kWebPreviewRegistry[entry['component']]!;
  var builds = 0;
  kWebPreviewRegistry[entry['component']! as String] = (context, variant) {
    builds++;
    return original(context, variant);
  };
  try {
    final body = await renderCaptureBodyHtml(
      MatrixEntry.fromJson(entry),
      onCurrentBoxSource: requested ? receipts.add : null,
    );
    return (body, receipts, builds);
  } finally {
    kWebPreviewRegistry[entry['component']! as String] = original;
  }
});
