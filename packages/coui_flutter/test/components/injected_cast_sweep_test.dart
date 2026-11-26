import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// One case per surface that opted into the style's cast without
/// composing `OutlinedContainer`.
///
/// Kept as a table rather than a file each: the assertion is identical
/// for every one of them, and what actually differs — which widget draws
/// the box — is exactly the one thing worth reading side by side.
typedef _Surface = ({String name, Widget child, Type box});

const _surfaces = <_Surface>[
  (name: 'Fieldset', child: Fieldset(children: [Text('f')]), box: Container),
  (name: 'Chip', child: Chip(label: 'c'), box: AnimatedContainer),
  // `Kbd` is not here: it states its own key shadow (none by default), so
  // the style bends a stack stated there instead of contributing its cast —
  // a key that states none gets none, which is outside this table's premise.
  // `kbd_style_test.dart` holds that case.
  // `EmptyState` no longer belongs here — the 2026-09-14 redesign drops
  // its box entirely (no border / radius / background), so there is no
  // `InjectedCast` to sweep.
  (
    // Composes `OutlinedContainer` (#4362) — the cast now lands on that
    // primitive's own `AnimatedContainer`, not a hand-drawn `Container`.
    name: 'CodeSnippet',
    child: CodeSnippet(code: 'x', mode: 'dart'),
    box: AnimatedContainer,
  ),
  (name: 'Table', child: Table(rows: []), box: DecoratedBox),
  // The left accent / bottom rule blocks composing `OutlinedContainer`,
  // so the band restates the cast that primitive hands a surface at rest
  // — the cast its Web twin takes through `kControlShadowRestMarker`.
  (name: 'Banner', child: Banner(message: Text('b')), box: Container),
  (name: 'Avatar', child: Avatar(initials: 'AB'), box: Container),
  // `Command` is gone with it, and for the same reason one step removed:
  // the cast this row measured was never Command's own. Measured on both
  // sides — `Command(groups: [])` under `neoBrutalism` held TWO
  // `OutlinedContainer`s and ONE `InjectedCast` before the redesign, and
  // ONE / ZERO after. The second container was the `EmptyState` Command
  // composes when it has nothing to list, and the cast was on that. Its
  // own panel container carries none, so this row asserted a surface
  // Command does not have. Whether that panel should opt in is a decision
  // about `Command`, not about this redesign.
  (
    name: 'Checkbox',
    child: Checkbox(checked: false, onChanged: null),
    box: AnimatedContainer,
  ),
  (name: 'ChipInput', child: ChipInput(), box: Container),
  (
    // Composes `OutlinedContainer` (#4362) — the cast now lands on that
    // primitive's own `AnimatedContainer`, not a hand-drawn `Container`.
    name: 'CodeDiff',
    child: CodeDiff(lines: []),
    box: AnimatedContainer,
  ),
];

/// Surfaces that AUTHOR a resting shadow of their own (`stack`
/// — `CoreShadow.xl` for the browser, the device's pinned v1 cast for the
/// device), so the style bends what they authored rather than substituting its
/// cast — `CoreSurfaceGeometryConstraint.shadow` is pure, and
/// `OutlinedContainer` only reads `controlShadow` for a stack that
/// resolves empty.
///
/// `MockupBrowser` is here in both of its compositions (web page and the
/// app window that replaced `MockupWindow`): the shadow is on the body,
/// which both share. `MockupDevice` is here rather than in the table
/// above for the same reason — it composes `OutlinedContainer` and
/// authors the device shadow itself, so the table's premise (a surface
/// handed the injected cast) does not hold for it.
typedef _AuthoredSurface = ({
  String name,
  Widget child,
  List<CoreShadowLayer> stack,
});

const _authoredSurfaces = <_AuthoredSurface>[
  (
    name: 'MockupBrowser (web page)',
    child: MockupBrowser(addressBar: 'u', child: Text('c')),
    stack: CoreShadow.xl,
  ),
  (
    name: 'MockupBrowser (app window)',
    child: MockupBrowser(addressBar: null, child: Text('m')),
    stack: CoreShadow.xl,
  ),
  (
    name: 'MockupDevice',
    child: MockupDevice(child: Text('p')),
    stack: CoreMockupDeviceStyle.defaultBodyShadow,
  ),
];

/// The shadows a surface's own subtree paints.
///
/// Scoped to that subtree: a search across the whole tree could be
/// satisfied by some other widget and would pass whether or not the
/// component under test takes anything.
///
/// Reads both paint sites. A cast can be painted behind the box by
/// `BoxDecoration.boxShadow` or outside it by [InjectedCast], and which
/// one a component uses depends on whether its fill can be non-opaque —
/// a detail this question does not turn on. Asking only the decoration
/// would report "no cast" for a component that paints one perfectly
/// well.
List<BoxShadow> _shadows(WidgetTester tester, Widget subtree, Type box) => [
  ...tester
      .widgetList<Widget>(
        find.descendant(
          of: find.byWidget(subtree),
          matching: find.byType(box),
        ),
      )
      .map(
        (w) => switch (w) {
          Container(:final decoration) => decoration,
          AnimatedContainer(:final decoration) => decoration,
          DecoratedBox(:final decoration) => decoration,
          _ => null,
        },
      )
      .whereType<BoxDecoration>()
      .expand((d) => d.boxShadow ?? const <BoxShadow>[]),
  ...tester
      .widgetList<InjectedCast>(
        find.descendant(
          of: find.byWidget(subtree),
          matching: find.byType(InjectedCast),
        ),
      )
      .expand((c) => c.shadows),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  CoreSurfaceStyleId style,
) async {
  // Bigger than the 800x600 default: a phone frame is taller than that,
  // and an overflow there fails the test for a reason that has nothing
  // to do with what it measures.
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final surface in _surfaces) {
    group('${surface.name} takes the style it is under', () {
      testWidgets('a style with a cast reaches it', (tester) async {
        await _pump(tester, surface.child, .neoBrutalism);

        final shadows = _shadows(tester, surface.child, surface.box);
        expect(shadows, isNotEmpty);

        final cast = shadows.first;
        expect(cast.blurRadius, 0, reason: 'the cast is hard-edged');
        // The recipe throws the cast by its own stroke floor, so matching
        // that number is what separates the injected cast from any shadow
        // that merely happens to be present.
        expect(cast.offset.dx, CoreStrokeWidth.stroke4);
        expect(cast.offset.dy, CoreStrokeWidth.stroke4);
      });

      testWidgets('a style without one does not gain a shadow', (tester) async {
        // The negative control: without it, a test that passes because
        // *something* paints a shadow reads the same as one that passes
        // because the cast arrived.
        await _pump(tester, surface.child, .defaultStyle);

        expect(_shadows(tester, surface.child, surface.box), isEmpty);
      });
    });
  }

  for (final surface in _authoredSurfaces) {
    group('${surface.name} authors its own shadow and the style bends it', () {
      testWidgets('the resting stack is the authored one', (tester) async {
        await _pump(tester, surface.child, .defaultStyle);

        final shadows = _shadows(tester, surface.child, AnimatedContainer);
        // The authored stack is soft layers thrown straight down; a
        // surface that took the (empty) default cast instead would paint
        // nothing here, and a hard cast would have no blur and a
        // sideways offset. The blur is compared as "soft" rather than
        // against the authored number because the Flutter conversion
        // re-expresses it — the shape, not the figure, is what this
        // asserts.
        expect(shadows, hasLength(surface.stack.length));
        for (final layer in shadows) {
          expect(layer.blurRadius, greaterThan(0), reason: 'soft, unbent');
          expect(layer.offset.dx, 0, reason: 'thrown straight down');
          expect(layer.offset.dy, greaterThan(0));
        }
      });

      testWidgets('a style with a cast bends the stack, not replaces it', (
        tester,
      ) async {
        await _pump(tester, surface.child, .neoBrutalism);

        final shadows = _shadows(tester, surface.child, AnimatedContainer);
        expect(shadows, hasLength(surface.stack.length));
        for (final (i, bent) in shadows.indexed) {
          final authored = surface.stack[i];
          expect(bent.blurRadius, 0, reason: 'the bend hard-edges every layer');
          // Offsets are the authored ones plus the recipe's diagonal — a
          // substituted cast would sit at exactly (stroke4, stroke4) for
          // every layer and lose the authored `offsetY` ladder.
          expect(bent.offset.dx, authored.offsetX + CoreStrokeWidth.stroke4);
          expect(bent.offset.dy, authored.offsetY + CoreStrokeWidth.stroke4);
        }
      });
    });
  }
}
