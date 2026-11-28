import 'dart:isolate';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart';
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/web/docs_card_registry_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';
import 'docs_card_registry_real_entry_test.dart' as fixture;

DocsScene _scene() => readDocsScenes('button').singleWhere(
  (scene) => scene.tag == 'Anatomy',
);

/// This is the test's mutation lookup, not the production observer. It stops
/// at the source-owned stage and never visits its target/preview descendants.
Element _stage(Element root) {
  final matches = <Element>[];
  void visit(Element current) {
    final component = current.component;
    if (component is div &&
        component.classes == 'docs-stage docs-stage--240 docs-anatomy-stage') {
      matches.add(current);
      return;
    }
    current.visitChildren(visit);
  }

  visit(root);
  expect(matches, hasLength(1));
  return matches.single;
}

Future<Map<String, Object?>> _normal(
  Map<String, Object?> input,
  bool requested,
) => Isolate.run(() async {
  final entry = MatrixEntry.fromJson(input);
  final original = kWebPreviewRegistry[entry.component]!;
  var builds = 0;
  final receipts = <Map<String, Object?>>[];
  final routes = <Map<String, Object?>>[];
  kWebPreviewRegistry[entry.component] = (context, variant) {
    builds++;
    return original(context, variant);
  };
  try {
    final body = await renderCaptureBodyHtml(
      entry,
      onCurrentBoxSource: requested ? receipts.add : null,
      onDocumentationSceneRoute: (route, kind) =>
          routes.add({'route': route, 'kind': kind}),
    );
    return {
      'body': body,
      'receipts': receipts,
      'routes': routes,
      'builds': builds,
    };
  } finally {
    kWebPreviewRegistry[entry.component] = original;
  }
});

void main() {
  for (final theme in ['light', 'dark']) {
    test(
      'original Anatomy normal SSR owns stage and target / $theme',
      () async {
        final scene = _scene();
        final actual = await fixture.renderDocsFrameFixture(
          'button',
          scene,
          theme: theme,
        );
        expect(actual.builds, 1);
        expect(actual.observations, 1);
        expect(actual.receipt!['kind'], kDocsCardRegistrySsrKind);
        final raw = actual.receipt!['currentRaw']! as Map;
        expect(raw['sceneTag'], 'Anatomy');
        expect(raw['entryComponent'], actual.entry.component);
        expect(raw['originalSceneInput'], scene.toJson());
        expect(raw['quantityBoundary'], 'own-frame-only');
        expect(raw['opaqueInteriorsRead'], false);
        final frontiers = raw['opaqueFrontiers']! as List;
        expect(frontiers.map((f) => (f as Map)['purpose']), [
          'preview',
          'anatomy-legend',
        ]);
        final stage = html
            .parseFragment(actual.body)
            .querySelector(
              actual.entry.probes.single.webSelector,
            )!;
        expect(stage.attributes, {
          'class': 'docs-stage docs-stage--240 docs-anatomy-stage',
          'data-docs-anatomy': scene.anatomyParts.join(';'),
        });
        expect(stage.children, hasLength(1));
        expect(stage.children.single.attributes, {
          'class': 'docs-anatomy-target',
        });
        // No observer invents runtime marker children in a server response.
        expect(stage.children.where((n) => n.localName == 'span'), isEmpty);
      },
    );

    test(
      'actual canonical preparation is passive and body exact / $theme',
      () async {
        final entry = fixture.docsFrameEntry('button', _scene(), theme);
        final without = await _normal(entry.toJson(), false);
        final withSource = await _normal(entry.toJson(), true);
        expect(withSource['body'], without['body']);
        expect(withSource['builds'], 1);
        expect(without['builds'], 1);
        expect(without['receipts'], isEmpty);
        final receipts = withSource['receipts']! as List;
        expect(receipts, hasLength(1));
        expect((receipts.single as Map).containsKey('error'), false);
        expect((receipts.single as Map)['kind'], kDocsCardRegistrySsrKind);
        expect((withSource['routes']! as List).single, {
          'route': docsCardRegistrySceneRoute(entry, _scene()),
          'kind': kDocsCardRegistrySsrKind,
        });
        // This verifies normal preparation, not execution of docs-shell.js or
        // browser geometry. A separate real canonical runtime fixture
        // is required.
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  test('joint declared stage padding is rejected before observation', () async {
    await expectLater(
      fixture.renderDocsFrameFixture(
        'button',
        _scene(),
        beforeObserve: (root) {
          final component = _stage(root).component as div;
          component.attributes!['style'] = 'padding: 91px';
        },
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('required target removal is rejected without zero inference', () async {
    await expectLater(
      fixture.renderDocsFrameFixture(
        'button',
        _scene(),
        beforeObserve: (root) {
          final component = _stage(root).component as div;
          component.children.clear();
        },
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('extra target wrapper breaks exact original child identity', () async {
    await expectLater(
      fixture.renderDocsFrameFixture(
        'button',
        _scene(),
        beforeObserve: (root) {
          final component = _stage(root).component as div;
          component.children[0] = div([component.children.single]);
        },
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'owned parameters remain held through actual normal completion',
    () async {
      await expectLater(
        fixture.renderDocsFrameFixture(
          'button',
          _scene(),
          afterResponseBeforeComplete: (root) {
            final component = _stage(root).component as div;
            component.attributes!['id'] = 'changed-after-response';
          },
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
