// The active pill on Web: the settled pill is the active item's own slot,
// the flight is a fill over the track that the morph clip carves, and the
// server renders the first and never the second.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/dock/dock_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

Iterable<DomComponent> _dom(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// The inert elements: the settled pill, and the flight when there is one.
Iterable<DomComponent> _inert(ComponentTester tester) =>
    _dom(tester).where((c) => c.attributes?['aria-hidden'] == 'true');

/// Asserts a pill sits under its box's content: a negative z-index, and
/// carried inline — the value is a local stacking order inside an
/// `isolate` context, not a `CoreZIndex` rung, so it has no Tailwind class.
void _expectBehindContent(String? className, Styles? styles) {
  expect(
    (className ?? '').split(' ').where((c) => RegExp('^-?z-').hasMatch(c)),
    isEmpty,
  );
  final zIndex = styles?.properties['z-index'];
  expect(zIndex, isNotNull);
  expect(int.parse(zIndex!), isNegative);
}

Dock _dock(int active) => Dock(
  items: [
    for (var i = 0; i < 3; i++)
      CoreDockItemData<Component>(
        icon: const Icon(LucideIcons.house),
        label: 'Item $i',
        isActive: i == active,
        onPressed: () {},
      ),
  ],
);

void main() {
  group('the settled pill', () {
    testComponents('is the active item s slot and nobody else s', (
      tester,
    ) async {
      pumpWithTheme(tester, _dock(1));

      // One inert element: the pill. The flight would be a second, and
      // the server never renders one — nor a clip for it.
      final pills = _inert(tester).toList();
      expect(pills, hasLength(1));
      _expectBehindContent(pills.single.classes, pills.single.styles);
      expect(
        _dom(tester).any(
          (c) => c.styles?.properties.containsKey('clip-path') ?? false,
        ),
        isFalse,
      );
    });

    testComponents('carries the fill, the corners and the overhang', (
      tester,
    ) async {
      late ResolvedDock resolved;
      late ResolvedDockItem active;
      late ResolvedDockItem idle;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveDock(context);
            active = resolveDockItem(
              context,
              resolved: resolved,
              size: CoreDockSize.md,
              isActive: true,
              hasLabel: true,
              showIndicator: true,
            );
            idle = resolveDockItem(
              context,
              resolved: resolved,
              size: CoreDockSize.md,
              isActive: false,
              hasLabel: true,
            );

            return const Text('probe');
          },
        ),
      );

      expect(idle.indicator, isNull);
      final pill = active.indicator!;
      expect(pill.className, contains('absolute'));
      _expectBehindContent(pill.className, pill.inlineStyles);
      expect(pill.className, contains('pointer-events-none'));
      // Token fill as a class — dark-mode reactive.
      expect(pill.className, contains('bg-surface-container-high'));
      expect(pill.className, contains('rounded-tl-radius10'));
      // The reach past the icon row on every side — each side negated
      // around `spaceCss` (the Flutter twin bends the same `CoreEdgeInsets`
      // through the theme geometry). md: 5 above and below, none beside.
      final padding =
          CoreDockStyle.defaultsBySize[CoreDockSize.md]!.indicatorPadding!;
      final inset = pill.inlineStyles!.properties['inset']!;
      expect(
        inset,
        'calc(-1 * ${spaceCss(padding.top)}) '
        'calc(-1 * ${spaceCss(padding.right)}) '
        'calc(-1 * ${spaceCss(padding.bottom)}) '
        'calc(-1 * ${spaceCss(padding.left)})',
      );
      // The icon row is the box the plate is positioned against.
      expect(active.icon.className, contains('relative'));
      expect(active.icon.className, contains('isolate'));
    });
  });

  group('the flight', () {
    testComponents('is a fill over the whole track, under the items', (
      tester,
    ) async {
      late ResolvedDock resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveDock(context);

            return const Text('probe');
          },
        ),
      );

      expect(resolved.flight.className, contains('absolute'));
      expect(resolved.flight.className, contains('inset-0'));
      _expectBehindContent(
        resolved.flight.className,
        resolved.flight.inlineStyles,
      );
      expect(resolved.flight.className, contains('pointer-events-none'));
      // Same fill emit as the settled pill.
      expect(resolved.flight.className, contains('bg-'));
      // The track is positioned and isolates its stacking context, so
      // the negative z-index lands under the items and not under the page.
      expect(resolved.root.className, contains('relative'));
      expect(resolved.root.className, contains('isolate'));
      expect(resolved.root.className, contains(kWebSurfaceMarker));
    });

    testComponents('reads its tempo and geometry off the merged style', (
      tester,
    ) async {
      late ResolvedDockIndicatorRuntime runtime;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            runtime = resolveDockIndicatorRuntime(
              context,
              resolved: resolveDock(
                context,
                dockStyle: const CoreDockStyle(
                  indicatorSpring: CoreMorphSpring(speed: CoreMorphSpeed.slow),
                ),
              ),
            );

            return const Text('probe');
          },
        ),
      );

      expect(runtime.spring.speed, CoreMorphSpeed.slow);
      final md = CoreDockStyle.defaultsBySize[CoreDockSize.md]!;
      expect(runtime.padding, md.indicatorPadding);
      expect(runtime.radius, md.indicatorRadius!.topLeft);
    });
  });
}
