import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/showcase_allocation_ssr_source.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';

MatrixEntry _entry() => MatrixEntry.fromJson({
  'component': 'chip',
  'variant': 'variant',
  'theme': 'light',
  'surfaceStyle': 'defaultStyle',
  'tier': 't2',
  'probes': captureProbes(
    key: 'chip-variant-light-defaultStyle',
    component: 'chip',
    variant: 'variant',
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
  run,
) async {
  final entry = _entry();
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
      final returned = soleCurrentSsrChild(example);
      final declaration = returned.component as div;
      final owner = currentSsrGeneratedDiv(returned, declaration);
      run(root, owner, declaration, source);
    },
  );
  expect(builds, 1, reason: 'No observer may replay the registry builder');
}

void main() {
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
