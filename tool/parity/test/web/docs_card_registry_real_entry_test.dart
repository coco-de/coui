import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show Style, Styles, div;
import 'package:jaspr/server.dart';
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/docs_card_registry_ssr_source.dart';
import '../../src/web/ssr_render.dart';

typedef DocsFrameFixture = ({
  MatrixEntry entry,
  DocsScene scene,
  String body,
  Map<String, Object?>? receipt,
  html_dom.Element capture,
  html_dom.Element owner,
  int builds,
  int observations,
});

MatrixEntry docsFrameEntry(String component, DocsScene scene, String theme) {
  final key = '$component-${scene.reference}-$theme-defaultStyle';
  return MatrixEntry.fromJson({
    'component': component,
    'variant': scene.reference,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: component,
      variant: scene.reference,
      flutterClassName: scene.flutterOwnerType,
      docsScene: scene,
    ).map((p) => p.toJson()).toList(),
  });
}

/// The original registry callback and documentation host run once in their
/// ordinary context. Only the test supplies the not-yet-integrated tool hook.
Future<DocsFrameFixture> renderDocsFrameFixture(
  String component,
  DocsScene scene, {
  String theme = 'light',
  void Function(Element root)? beforeObserve,
  void Function(Element root)? afterResponseBeforeComplete,
}) async {
  final entry = docsFrameEntry(component, scene, theme);
  final recorder = DocsCardRegistrySsrSource.forEntry(entry, scene);
  var builds = 0;
  var observations = 0;
  Element? normalRoot;
  final body = await renderComponentBodyHtml(
    _OriginalDocumentationBuild(entry, scene, recorder, () => builds++),
    onMountedRoot: recorder == null
        ? null
        : (root) {
            observations++;
            normalRoot = root;
            beforeObserve?.call(root);
            recorder.observe(root);
          },
  );
  if (normalRoot != null) afterResponseBeforeComplete?.call(normalRoot!);
  final receipt = recorder?.completeWithSerializedBody(body);
  final fragment = html.parseFragment(body);
  return (
    entry: entry,
    scene: scene,
    body: body,
    receipt: receipt,
    capture: fragment.querySelectorAll('[data-parity-key]').single,
    owner: fragment.querySelectorAll(entry.probes.single.webSelector).single,
    builds: builds,
    observations: observations,
  );
}

class _OriginalDocumentationBuild extends StatelessComponent {
  const _OriginalDocumentationBuild(
    this.entry,
    this.scene,
    this.recorder,
    this.onBuild,
  );
  final MatrixEntry entry;
  final DocsScene scene;
  final DocsCardRegistrySsrSource? recorder;
  final void Function() onBuild;
  @override
  Component build(BuildContext context) {
    onBuild();
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      entry.variant,
    );
    final capture = div(
      [docsSceneHost(scene, result)],
      styles: const Styles(raw: {'display': 'inline-block', 'width': '800px'}),
      attributes: {'data-parity-key': entry.key},
    );
    recorder?.recordBuild(result, capture);
    return Component.fragment([
      Style(styles: docsContentTheme().styles),
      coui.CoUIWeb(theme: coui.ThemeData.coui, child: capture),
    ]);
  }
}

List<(String, DocsScene)> documentationBranchFixtures() {
  // Preselected from the source-only whole-cohort constructor map, before any
  // new observation: four Cards, Preview none/hug/240/140/340, VariantRow.
  const selected = [
    ('button', 'docs-v2-daf0078dab52b7a9b88d2e26e188ae75'),
    ('button', 'docs-v2-a37bdf19d0d983e7c0027788f76202f1'),
    ('button', 'docs-v2-12a9a06e88068f14e1d6f1b81aa25358'),
    ('button', 'docs-v2-1b63de6d7b75edaad6f28a9d63467140'),
    ('color-picker', 'docs-v2-222b32286fce55b1d4d0b65b3a992e13'),
    ('banner', 'docs-v2-d9e0aba1d436d95a15a7352cb0f24e99'),
    ('carousel', 'docs-v2-071e020b600224e5fb0bc26041c1fea2'),
    ('kbd', 'docs-v2-49fefef3cd11b31e6724e311026e5e94'),
    ('menubar', 'docs-v2-eae2b682e43be6ba96f03f4d6612202c'),
    ('drawer', 'docs-v2-e2b740c92cac5fb337db22695a5ffc22'),
  ];
  return [
    for (final (component, reference) in selected)
      (
        component,
        readDocsScenes(component).singleWhere((s) => s.reference == reference),
      ),
  ];
}

void main() {
  for (final theme in ['light', 'dark']) {
    test('original Avatar SVG frontier / $theme', () async {
      final scene = readDocsScenes('avatar').singleWhere(
        (s) => s.reference == 'docs-v2-63b2a10b59591e46f2d0201badbf8d67',
      );
      final actual = await renderDocsFrameFixture(
        'avatar',
        scene,
        theme: theme,
      );
      final raw = actual.receipt!['currentRaw']! as Map;
      final frontiers = raw['opaqueFrontiers']! as List;
      final preview = (frontiers.first as Map)['nodes']! as List;
      expect(preview, [
        {
          'nodeType': 1,
          'namespaceURI': 'http://www.w3.org/2000/svg',
          'localName': 'svg',
        },
      ]);
      final svg = actual.owner.querySelector('.docs-stage > svg')!;
      expect(svg.namespaceUri, 'http://www.w3.org/2000/svg');
      expect(actual.builds, 1);
      expect(actual.observations, 1);
      final retain = Platform.environment['PARITY_DOCS_FRAME_FIXTURE_OUT'];
      if (retain != null) {
        final directory = Directory(retain)..createSync(recursive: true);
        File(
          '${directory.path}/${actual.entry.key}.normal-body.html',
        ).writeAsStringSync(actual.body);
        File(
          '${directory.path}/${actual.entry.key}.source-receipt.json',
        ).writeAsStringSync(jsonEncode(actual.receipt));
      }
    });
  }

  test('closed declaration keeps Anatomy explicitly unproved', () {
    final scene = readDocsScenes(
      'button',
    ).firstWhere((s) => s.tag == 'Anatomy');
    final entry = docsFrameEntry('button', scene, 'light');
    expect(
      entry.probes.single.boxObservationSource,
      BoxObservationSourceSpec.docsStage,
    );
    expect(DocsCardRegistrySsrSource.forEntry(entry, scene), isNull);
    expect(requiredDocsCardRegistrySsrKind(entry, scene), isNull);
  });

  test('borrowed or absent original scene is rejected before mount', () {
    final scenes = readDocsScenes(
      'button',
    ).where((s) => s.tag == 'Preview').take(2).toList();
    final entry = docsFrameEntry('button', scenes.first, 'light');
    expect(
      () => DocsCardRegistrySsrSource.forEntry(entry, null),
      throwsStateError,
    );
    expect(
      () => DocsCardRegistrySsrSource.forEntry(entry, scenes.last),
      throwsStateError,
    );
  });

  test(
    'all four original Card branches and both registry tags are represented',
    () {
      final fixtures = documentationBranchFixtures();
      final cards = fixtures
          .where((v) => v.$2.tag == 'Card')
          .map((v) => v.$2.attributes)
          .toList();
      expect(cards.any((a) => a['href'] != null), isTrue);
      expect(
        cards.any((a) => a['eyebrow'] != null && a['title'] != null),
        isTrue,
      );
      expect(
        cards.any((a) => a['eyebrow'] != null && a['title'] == null),
        isTrue,
      );
      expect(
        cards.any((a) => a['eyebrow'] == null && a['title'] != null),
        isTrue,
      );
      expect(fixtures.any((v) => v.$2.tag == 'Preview'), isTrue);
      expect(fixtures.any((v) => v.$2.tag == 'VariantRow'), isTrue);
    },
  );

  for (final theme in ['light', 'dark']) {
    test('original documentation branch roster / $theme', () async {
      for (final (component, scene) in documentationBranchFixtures()) {
        final actual = await renderDocsFrameFixture(
          component,
          scene,
          theme: theme,
        );
        expect(actual.builds, 1);
        expect(actual.observations, 1);
        expect(actual.receipt!['kind'], kDocsCardRegistrySsrKind);
        expect(actual.receipt!['entryKey'], actual.entry.key);
        final raw = actual.receipt!['currentRaw']! as Map;
        expect(raw['sceneTag'], scene.tag);
        expect(raw['originalSceneInput'], scene.toJson());
        expect(raw['quantityBoundary'], 'own-frame-only');
        expect(raw['opaqueInteriorsRead'], false);
        expect(
          actual.owner.localName,
          scene.attributes['href'] != null && scene.tag == 'Card' ? 'a' : 'div',
        );
        final frontiers = raw['opaqueFrontiers']! as List;
        expect((frontiers.first as Map)['purpose'], 'preview');
      }
    });
  }

  test(
    'normal-completion reread rejects a post-observation own parameter change',
    () async {
      final scene = readDocsScenes(
        'button',
      ).firstWhere((s) => s.tag == 'Preview');
      await expectLater(
        renderDocsFrameFixture(
          'button',
          scene,
          afterResponseBeforeComplete: (root) {
            final capture = _currentCaptureInput(root);
            capture.attributes!['data-parity-key'] =
                'changed-after-normal-response';
          },
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'source error',
            contains('DOCS_FRAME_SOURCE_CHANGED'),
          ),
        ),
      );
    },
  );

  test(
    'normal-completion reread accepts exact restored own parameters',
    () async {
      final scene = readDocsScenes(
        'button',
      ).firstWhere((s) => s.tag == 'Preview');
      final actual = await renderDocsFrameFixture(
        'button',
        scene,
        afterResponseBeforeComplete: (root) {
          final capture = _currentCaptureInput(root);
          final key = capture.attributes!['data-parity-key']!;
          capture.attributes!['data-parity-key'] = 'temporary-control';
          capture.attributes!['data-parity-key'] = key;
        },
      );
      expect(actual.receipt!['kind'], kDocsCardRegistrySsrKind);
    },
  );
}

div _currentCaptureInput(Element root) {
  final found = <div>[];
  void visit(Element element) {
    final component = element.component;
    if (component is div &&
        component.attributes?.containsKey('data-parity-key') == true) {
      found.add(component);
      return;
    }
    element.visitChildren(visit);
  }

  visit(root);
  expect(found, hasLength(1));
  return found.single;
}
