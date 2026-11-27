import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/mockup_foldable/mockup_foldable_angle_example.dart';
import 'package:docs_core/previews/examples/web/mockup_foldable/mockup_foldable_default_example.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/showcase_allocation_ssr_source.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';

MatrixEntry _entry({(String, String) recipe = ('chip', 'variant')}) =>
    MatrixEntry.fromJson({
      'component': recipe.$1,
      'variant': recipe.$2,
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': captureProbes(
        key: '${recipe.$1}-${recipe.$2}-light-defaultStyle',
        component: recipe.$1,
        variant: recipe.$2,
        flutterClassName: 'actual-canonical',
      ).map((probe) => probe.toJson()).toList(),
    });

Future<void> _mounted(
  void Function(
    Element root,
    Element owner,
    div declaration,
    ShowcaseAllocationSsrSource source,
  )
  run, {
  (String, String) recipe = ('chip', 'variant'),
}) async {
  final entry = _entry(recipe: recipe);
  final source = ShowcaseAllocationSsrSource.forEntry(entry)!;
  div? capture;
  var builds = 0;
  await renderComponentBodyHtml(
    coui.CoUIWeb(
      theme: .coui,
      child: _Capture(
        entry,
        source,
        onBuild: () => builds++,
        onCapture: (value) => capture = value,
      ),
    ),
    onMountedRoot: (root) {
      final captureDom = currentSsrGeneratedDiv(
        currentSsrIdentityElement(root, capture!),
        capture!,
      );
      final example = soleCurrentSsrChild(captureDom);
      // The registry returns its owned width DIV for this exact recipe.
      final registryWidth = recipe == ('mockup-foldable', 'default');
      final returned = registryWidth ? example : soleCurrentSsrChild(example);
      final declaration = returned.component as div;
      final owner = currentSsrGeneratedDiv(returned, declaration);
      run(root, owner, declaration, source);
    },
  );
  expect(builds, 1, reason: 'No observer may replay the registry builder');
}

void main() {
  test(
    'actual default registry width host owns one opaque Example seat',
    () async {
      await _mounted((root, owner, declaration, source) {
        expect(declaration.runtimeType, div);
        expect(declaration.children, hasLength(1));
        expect(
          declaration.children.single.runtimeType,
          MockupFoldableDefaultExample,
        );
        final seats = <Element>[];
        owner.visitChildren(seats.add);
        expect(seats, hasLength(1));
        expect(seats.single.component, same(declaration.children.single));
        expect(seats.single.parent, same(owner));
        final receipt = source.observe(root);
        expect(receipt['completeRawSlotCount'], 1);
        expect((receipt['currentRaw']! as Map)['opaqueSlots'], hasLength(1));
        for (final mode in [
          'drop',
          'extra',
          'different Example',
          'double wrapper',
        ]) {
          final original = declaration.children.single;
          try {
            if (mode == 'drop') declaration.children.clear();
            if (mode == 'extra') declaration.children.add(original);
            if (mode == 'different Example') {
              declaration.children[0] = const MockupFoldableAngleExample();
            }
            if (mode == 'double wrapper') {
              declaration.children[0] = div([original]);
            }
            expect(() => source.observe(root), throwsStateError);
          } finally {
            declaration.children
              ..clear()
              ..add(original);
          }
          expect(source.observe(root)['completeRawSlotCount'], 1);
        }
        final original = declaration.children.single;
        const createSameTypeCopy = MockupFoldableDefaultExample.new;
        final sameTypeCopy = createSameTypeCopy();
        expect(sameTypeCopy.runtimeType, original.runtimeType);
        expect(sameTypeCopy, isNot(same(original)));
        try {
          declaration.children[0] = sameTypeCopy;
          expect(
            () => source.observe(root),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'SHOWCASE_ALLOCATION_REGISTRY_EXAMPLE_CHANGED',
              ),
            ),
          );
        } finally {
          declaration.children[0] = original;
        }
        expect(source.observe(root)['completeRawSlotCount'], 1);
        // A source cannot replace the actual registry route with an inner
        // Example or a second allocation wrapper before mounting either.
        final entry = _entry(recipe: ('mockup-foldable', 'default'));
        for (final result in <Component>[
          declaration.children.single,
          div([declaration]),
          const div([]),
          div([declaration.children.single, declaration.children.single]),
          const div([MockupFoldableAngleExample()]),
        ]) {
          final other = ShowcaseAllocationSsrSource.forEntry(entry)!;
          final capture = div(
            [result],
            attributes: {'data-parity-key': entry.key},
          );
          expect(() => other.recordBuild(result, capture), throwsStateError);
        }
      }, recipe: ('mockup-foldable', 'default'));
    },
  );

  for (final entry in const <(String, String), int>{
    ('card-image', 'default'): 1,
    ('hidden', 'default'): 3,
    ('window', 'default'): 3,
    ('draggable-panel', 'default'): 1,
    ('draggable-panel', 'outside'): 1,
    ('scrollable-client', 'default'): 1,
    ('table', 'scrollable'): 1,
    ('mockup-foldable', 'angle'): 2,
    ('mockup-foldable', 'default'): 1,
    ('scaffold', 'default'): 1,
    ('bottom-action-bar', 'scaffold'): 1,
    ('scrollview', 'default'): 1,
  }.entries) {
    test(
      '${entry.key} original product is a complete opaque raw boundary',
      () async {
        await _mounted((root, owner, declaration, source) {
          final raw = declaration.children;
          final seats = <Element>[];
          owner.visitChildren(seats.add);
          expect(raw, hasLength(entry.value));
          expect(seats, hasLength(raw.length));
          expect(Set<Element>.identity()..addAll(seats), hasLength(raw.length));
          final frontiers = <MarkupRenderObject>[];
          for (var i = 0; i < raw.length; i++) {
            expect(seats[i].component, same(raw[i]));
            expect(seats[i].parent, same(owner));
            frontiers.addAll(_frontier(seats[i]));
          }
          final markup =
              (owner as RenderObjectElement).renderObject as MarkupRenderObject;
          expect(markup.children.toList(), orderedEquals(frontiers));
          expect(
            Set<MarkupRenderObject>.identity()..addAll(frontiers),
            hasLength(frontiers.length),
          );
          final receipt = source.observe(root);
          expect(receipt['completeRawSlotCount'], raw.length);
          final records =
              (receipt['currentRaw']! as Map)['opaqueSlots']! as List;
          expect(records, hasLength(raw.length));
          for (var i = 0; i < raw.length; i++) {
            final record = records[i] as Map;
            expect(record.keys.toSet(), {'seat', 'sourceAliasOf', 'nodes'});
            expect(record['seat'], i);
            // Top frontier shapes do not expose product attrs, children,
            // controllers or builder callbacks; interiors remain opaque.
            for (final node in record['nodes']! as List) {
              expect(
                (node as Map).keys.toSet(),
                node['nodeType'] == 1
                    ? {'nodeType', 'namespaceURI', 'localName'}
                    : {'nodeType'},
              );
            }
          }
        }, recipe: entry.key);
      },
    );
  }

  test(
    'real nonempty repeated Components have distinct current mounted seats',
    () async {
      await _mounted((root, owner, declaration, source) {
        final raw = declaration.children;
        final seats = <Element>[];
        owner.visitChildren(seats.add);
        expect(raw, hasLength(11));
        expect(seats, hasLength(raw.length));
        expect(
          (Set<Component>.identity()..addAll(raw)).length,
          lessThan(raw.length),
        );
        expect(Set<Element>.identity()..addAll(seats), hasLength(raw.length));
        final frontiers = <MarkupRenderObject>[];
        for (var i = 0; i < raw.length; i++) {
          expect(seats[i].component, same(raw[i]));
          expect(seats[i].parent, same(owner));
          frontiers.addAll(_frontier(seats[i]));
        }
        final actual =
            (owner as RenderObjectElement).renderObject as MarkupRenderObject;
        expect(actual.children.toList(), orderedEquals(frontiers));
        expect(
          Set<MarkupRenderObject>.identity()..addAll(frontiers),
          hasLength(frontiers.length),
        );
        final receipt = source.observe(root);
        expect(receipt['completeRawSlotCount'], 11);
        final slots = (receipt['currentRaw']! as Map)['opaqueSlots']! as List;
        expect(
          slots.where((s) => (s as Map)['sourceAliasOf'] != null),
          isNotEmpty,
        );
      });
    },
  );

  for (final change in ['drop', 'reorder', 'extra repeated seat']) {
    test('actual $change cannot erase or collapse a raw occurrence', () async {
      await _mounted((root, owner, declaration, source) {
        source.observe(root);
        final original = List<Component>.of(declaration.children);
        try {
          if (change == 'drop') declaration.children.removeLast();
          if (change == 'reorder') {
            final a = declaration.children[0];
            declaration.children[0] = declaration.children[1];
            declaration.children[1] = a;
          }
          if (change == 'extra repeated seat') {
            declaration.children.add(declaration.children[1]);
          }
          expect(() => source.observe(root), throwsStateError);
        } finally {
          declaration.children
            ..clear()
            ..addAll(original);
        }
        expect(source.observe(root)['completeRawSlotCount'], original.length);
      });
    });
  }

  test(
    'actual render frontier reorder fails with unchanged source/Element seats',
    () async {
      await _mounted((root, owner, declaration, source) {
        source.observe(root);
        final markup =
            (owner as RenderObjectElement).renderObject as MarkupRenderObject;
        final first = markup.children.first;
        final second = markup.children.skip(1).first;
        try {
          markup
            ..remove(first)
            ..attach(first, after: second);
          expect(() => source.observe(root), throwsStateError);
        } finally {
          markup
            ..remove(first)
            ..attach(first);
        }
        expect(source.observe(root)['completeRawSlotCount'], 11);
      });
    },
  );

  for (final text in ['anonymous', '\u00a0']) {
    test(
      'actual undeclared $text outside foreign boundaries rejects',
      () async {
        await _mounted((root, owner, declaration, source) {
          source.observe(root);
          final markup =
              (owner as RenderObjectElement).renderObject as MarkupRenderObject;
          final injected = markup.createChildRenderText(text);
          markup.attach(injected, after: markup.children.last);
          try {
            expect(() => source.observe(root), throwsStateError);
          } finally {
            markup.remove(injected);
          }
          expect(source.observe(root)['completeRawSlotCount'], 11);
        });
      },
    );
  }

  test('complete foreign element interior is opaque', () async {
    await _mounted((root, owner, declaration, source) {
      final seats = <Element>[];
      owner.visitChildren(seats.add);
      final foreign = _frontier(seats.last).single;
      final before = foreign.renderToHtml();
      final injected = foreign.createChildRenderText(
        'opaque foreign \u00a0 text',
      );
      foreign.attach(injected, after: foreign.children.last);
      try {
        expect(source.observe(root)['completeRawSlotCount'], 11);
      } finally {
        foreign.remove(injected);
      }
      expect(foreign.renderToHtml(), before);
    });
  });
}

List<MarkupRenderObject> _frontier(Element element) {
  if (element is RenderObjectElement) {
    return [element.renderObject as MarkupRenderObject];
  }
  final children = <Element>[];
  element.visitChildren(children.add);
  return [for (final child in children) ..._frontier(child)];
}

class _Capture extends StatelessComponent {
  const _Capture(
    this.entry,
    this.source, {
    required this.onBuild,
    required this.onCapture,
  });
  final MatrixEntry entry;
  final ShowcaseAllocationSsrSource source;
  final void Function() onBuild;
  final void Function(div) onCapture;
  @override
  Component build(BuildContext context) {
    onBuild();
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      entry.variant,
    );
    final capture = div([result], attributes: {'data-parity-key': entry.key});
    source.recordBuild(result, capture);
    onCapture(capture);
    return capture;
  }
}
