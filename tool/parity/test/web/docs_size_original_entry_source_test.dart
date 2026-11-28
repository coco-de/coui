import 'dart:isolate';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show Style, Styles, div, section;
import 'package:jaspr/server.dart';
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/docs_size_ssr_source.dart';
import '../../src/web/ssr_render.dart';
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
  for (final control in [
    'missing mounted head',
    'wrong mounted head order',
    'head retained in completed body',
    'wrong completed body slot',
  ]) {
    test('actual normal Content lifecycle rejects $control', () async {
      final entry = entries.firstWhere(
        (e) => e.component == 'button' && e.theme.name == 'light',
      );
      await _checkNormalHeadLifecycle(entry, control);
    });
  }
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

// Test-only controls use the original public scene/registry/host route. Mutation
// is restored around the actual collector call, so the existing shared mounted
// markup nonmutation guard remains active and the normal response is unchanged.
Future<void> _checkNormalHeadLifecycle(
  MatrixEntry entry,
  String control,
) async {
  final scene = resolveDocsScene(entry.component, entry.variant);
  final source = DocsSizeSsrSource.forEntry(entry)!;
  Element? actualRoot;
  var builds = 0;
  final body = await renderComponentBodyHtml(
    _LifecycleBuild(entry, scene, source, () => builds++),
    onMountedRoot: (root) {
      actualRoot = root;
      if (control.startsWith('missing') ||
          control.startsWith('wrong mounted')) {
        final undo = _mutateHeadPhase(root, control);
        try {
          expect(
            () => source.observe(root),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'exact mounted guard',
                contains('normal mounted head then body render order'),
              ),
            ),
          );
        } finally {
          undo();
        }
      }
      expect(source.observe(root)['docsSizeAwaitingExactNormalBody'], true);
    },
  );
  if (control.contains('completed')) {
    final undo = _mutateHeadPhase(actualRoot!, control);
    try {
      expect(
        () => source.completeWithSerializedBody(body),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'exact completed guard',
            contains('normal completed body excludes original head output'),
          ),
        ),
      );
    } finally {
      undo();
    }
  }
  expect(
    source.completeWithSerializedBody(body)['kind'],
    'canonical-ssr-docs-size-preview-v1',
  );
  expect(builds, 1, reason: 'one actual original registry build');
}

void Function() _mutateHeadPhase(Element root, String control) {
  final fragments = <RenderObjectElement>[];
  void visit(Element e) {
    final c = e.component;
    if (c is Fragment &&
        c.children.length == 2 &&
        c.children[0].runtimeType == const Document.head().runtimeType &&
        c.children[1].runtimeType == section) {
      fragments.add(e as RenderObjectElement);
      return; // Never traverse the opaque preview or excluded table.
    }
    e.visitChildren(visit);
  }

  visit(root);
  expect(fragments, hasLength(1));
  final fragment = fragments.single;
  final children = <Element>[];
  fragment.visitChildren(children.add);
  final render = fragment.renderObject as MarkupRenderFragment;
  final head = children[0].slot.target!.renderObject as MarkupRenderObject;
  final sectionRender =
      children[1].slot.target!.renderObject as MarkupRenderObject;
  switch (control) {
    case 'missing mounted head':
      render.children.remove(head);
      return () => render.children.insertBefore(head, before: sectionRender);
    case 'wrong mounted head order':
      render.children.insertAfter(head, after: sectionRender);
      return () => render.children.insertBefore(head, before: sectionRender);
    case 'head retained in completed body':
      render.children.insertBefore(head, before: sectionRender);
      return () => render.children.remove(head);
    case 'wrong completed body slot':
      final original = children[1].slot.target;
      children[1].slot.target = children[0].slot.target;
      return () => children[1].slot.target = original;
    default:
      throw StateError('unknown lifecycle fixture control');
  }
}

class _LifecycleBuild extends StatelessComponent {
  const _LifecycleBuild(this.entry, this.scene, this.source, this.onBuild);
  final MatrixEntry entry;
  final DocsScene scene;
  final DocsSizeSsrSource source;
  final void Function() onBuild;
  @override
  Component build(BuildContext context) {
    onBuild();
    source.recordScene(scene);
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      entry.variant,
    );
    final capture = div(
      [docsSceneHost(scene, result)],
      styles: const Styles(raw: {'display': 'inline-block', 'width': '800px'}),
      attributes: {'data-parity-key': entry.key},
    );
    source.recordBuild(result, capture);
    return Component.fragment([
      Style(styles: docsContentTheme().styles),
      coui.CoUIWeb(theme: coui.ThemeData.coui, child: capture),
    ]);
  }
}
