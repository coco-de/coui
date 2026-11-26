import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('NavigationMenu', () {
    // `Button` routes hover through `FocusableActionDetector`, which only
    // reports hover while the focus highlight mode is `traditional`. A
    // real pointer session flips it there on first mouse movement; a
    // widget test starts in `touch`, so hover-to-open would silently
    // never fire.
    setUp(() {
      FocusManager.instance.highlightStrategy = .alwaysTraditional;
    });
    tearDown(() {
      FocusManager.instance.highlightStrategy = .automatic;
    });

    testWidgets('renders with empty items', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationMenu(items: []),
      );

      expect(find.byType(NavigationMenu), findsOneWidget);
    });

    testWidgets('renders item labels', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationMenu(
          items: [
            CoreNavigationMenuItem(
              label: 'Home',
              content: Text('Welcome home'),
            ),
            CoreNavigationMenuItem(label: 'Products'),
          ],
        ),
      );

      expect(find.byType(NavigationMenu), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('honors activeIndex', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationMenu(
          activeIndex: 1,
          items: [
            CoreNavigationMenuItem(label: 'One'),
            CoreNavigationMenuItem(label: 'Two'),
          ],
        ),
      );

      expect(find.byType(NavigationMenu), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('onActiveIndexChanged callback is wired up', (tester) async {
      int? activeIndex;

      await pumpTestApp(
        tester,
        NavigationMenu(
          onActiveIndexChanged: (index) {
            activeIndex = index;
          },
          items: const [
            CoreNavigationMenuItem(label: 'One'),
            CoreNavigationMenuItem(label: 'Two'),
          ],
        ),
      );

      expect(find.byType(NavigationMenu), findsOneWidget);
      expect(activeIndex, isNull);
    });

    testWidgets(
      'panel anchors to the active trigger, not always the bar start',
      (tester) async {
        await pumpTestApp(
          tester,
          const NavigationMenu(
            items: [
              CoreNavigationMenuItem(
                label: 'Products',
                content: Text('Products content'),
              ),
              CoreNavigationMenuItem(
                label: 'Solutions',
                content: Text('Solutions content'),
              ),
            ],
          ),
        );

        final productsTriggerX = tester.getTopLeft(find.text('Products')).dx;
        final solutionsTriggerX = tester.getTopLeft(find.text('Solutions')).dx;
        // Sanity check: the two triggers actually sit at different x
        // positions (otherwise the assertions below wouldn't distinguish
        // bar-anchored from trigger-anchored).
        expect(solutionsTriggerX, greaterThan(productsTriggerX));

        // Activate the SECOND trigger directly (never touching the
        // first) — the panel must anchor beneath it, not the bar's left
        // edge (which coincides with the first trigger's left edge, the
        // regression this test guards against).
        await tester.tap(find.text('Solutions'));
        await tester.pump();
        await tester.pumpAndSettle();

        final panelX = tester.getTopLeft(find.byType(Popup)).dx;
        expect(panelX, closeTo(solutionsTriggerX, 20));
        expect((panelX - productsTriggerX).abs(), greaterThan(50));
      },
    );

    testWidgets(
      'panel slides to the new trigger when the active trigger switches '
      'while open (controlled mode)',
      (tester) async {
        await pumpTestApp(
          tester,
          const _ControlledNavigationMenuHarness(),
        );

        final productsTriggerX = tester.getTopLeft(find.text('Products')).dx;
        final solutionsTriggerX = tester.getTopLeft(find.text('Solutions')).dx;

        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byType(Popup)).dx,
          closeTo(productsTriggerX, 20),
        );

        // Flips `activeIndex` on the already-mounted harness (in place,
        // not a fresh `pumpTestApp`) so the update reconciles through the
        // same `_syncEngine` → `_reanchorEngine` path a hover switch would
        // take (see `didUpdateWidget`) — the still-open panel must slide
        // to the new trigger instead of staying at the old one.
        final state = tester.state<_ControlledNavigationMenuHarnessState>(
          find.byType(_ControlledNavigationMenuHarness),
        );
        state.setActiveIndex(1);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byType(Popup)).dx,
          closeTo(solutionsTriggerX, 20),
        );
      },
    );

    testWidgets(
      'switching triggers keeps the panel mounted and crosses the two '
      'contents over, settling on the new one',
      (tester) async {
        await pumpTestApp(tester, const _ControlledNavigationMenuHarness());
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsOneWidget);

        final state = tester.state<_ControlledNavigationMenuHarnessState>(
          find.byType(_ControlledNavigationMenuHarness),
        );
        state.setActiveIndex(1);
        await tester.pump();
        // Mid-travel: the panel never unmounted, and both halves are on
        // screen — this is the cross-fade, not a close followed by an
        // open (which would show the new content alone from frame one).
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(Popup), findsOneWidget);
        expect(find.text('Products content'), findsOneWidget);
        expect(find.text('Solutions content'), findsOneWidget);

        // Settled: the outgoing half is gone, not merely transparent.
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsNothing);
        expect(find.text('Solutions content'), findsOneWidget);
      },
    );

    testWidgets(
      'a pointer leaving a trigger arms a delayed close rather than '
      'closing at once',
      (tester) async {
        await pumpTestApp(tester, const _HoverNavigationMenuHarness());

        final pointer = await tester.createGesture(kind: .mouse);
        await pointer.addPointer(location: Offset.zero);
        addTearDown(pointer.removePointer);

        await pointer.moveTo(tester.getCenter(find.text('Products')));
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsOneWidget);

        // Leaving the trigger heads for the panel across the menu offset
        // gap. Closing here would flicker the panel shut mid-travel.
        await pointer.moveTo(Offset.zero);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Products content'), findsOneWidget);

        // Nothing re-claimed the pointer, so the armed close fires.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsNothing);
      },
    );

    testWidgets(
      'the travel starts where the panel actually was when the engine '
      'clamped the two panels to different origins',
      (tester) async {
        // The repro. Both panels collide with the right edge, but they are
        // different widths so the engine clamps them to *different*
        // origins — which is what makes the trigger-delta guess wrong.
        //
        // A same-origin collision would not do: there the true travel is
        // ~0px, so `t≈0 == settled` passes for a correct travel, a no-op
        // travel, and no travel at all.
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpTestApp(
          tester,
          const _ControlledNavigationMenuHarness(
            alignEnd: true,
            contentWidths: [640, 300],
          ),
        );
        await tester.pumpAndSettle();
        final settledFrom = tester.getTopLeft(find.byType(Popup)).dx;

        tester
            .state<_ControlledNavigationMenuHarnessState>(
              find.byType(_ControlledNavigationMenuHarness),
            )
            .setActiveIndex(1);
        await tester.pump();
        // First frame of the travel: the engine has already re-anchored,
        // so this is exactly where the old code jumped.
        await tester.pump(const Duration(milliseconds: 1));
        final atStart = tester.getTopLeft(find.byType(Popup)).dx;

        await tester.pump(const Duration(milliseconds: 150));
        final midway = tester.getTopLeft(find.byType(Popup)).dx;

        await tester.pumpAndSettle();
        final settledTo = tester.getTopLeft(find.byType(Popup)).dx;

        // The two panels really do land at different clamped origins —
        // otherwise this test proves nothing.
        expect((settledTo - settledFrom).abs(), greaterThan(100));
        // The travel begins where the panel was, not where a trigger was.
        expect(atStart, closeTo(settledFrom, 2));
        // ...and it is a travel, not a jump: strictly between the ends.
        expect(midway, greaterThan(math.min(settledFrom, settledTo) + 1));
        expect(midway, lessThan(math.max(settledFrom, settledTo) - 1));
      },
    );

    testWidgets(
      'the travel also holds when nothing collides (guards the travel '
      'being dropped, not the clamp)',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpTestApp(tester, const _ControlledNavigationMenuHarness());
        await tester.pumpAndSettle();
        final settledFrom = tester.getTopLeft(find.byType(Popup)).dx;

        tester
            .state<_ControlledNavigationMenuHarnessState>(
              find.byType(_ControlledNavigationMenuHarness),
            )
            .setActiveIndex(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expect(
          tester.getTopLeft(find.byType(Popup)).dx,
          closeTo(settledFrom, 2),
        );

        await tester.pumpAndSettle();
        expect(
          (tester.getTopLeft(find.byType(Popup)).dx - settledFrom).abs(),
          greaterThan(10),
        );
      },
    );

    testWidgets(
      'a switch interrupted mid-travel continues from the painted position',
      (tester) async {
        await pumpTestApp(
          tester,
          const _ControlledNavigationMenuHarness(itemCount: 3),
        );
        await tester.pumpAndSettle();

        final state = tester.state<_ControlledNavigationMenuHarnessState>(
          find.byType(_ControlledNavigationMenuHarness),
        );
        state.setActiveIndex(1);
        await tester.pump();
        // 120ms into a 300ms travel — the panel is between the two origins.
        await tester.pump(const Duration(milliseconds: 120));
        final inFlight = tester.getTopLeft(find.byType(Popup)).dx;

        state.setActiveIndex(2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        // The second travel picks up where the panel is on screen. Reading
        // the *laid-out* origin instead would restart it from trigger 1's
        // settled position — a forward snap.
        expect(tester.getTopLeft(find.byType(Popup)).dx, closeTo(inFlight, 2));
      },
    );

    testWidgets(
      'a zero-length travel settles instantly instead of throwing',
      (tester) async {
        // Reduced motion collapses `panelSwitchDuration` to zero, and a
        // caller may pass zero outright. Handing that to
        // `TweenAnimationBuilder` makes it complete synchronously inside
        // its own `initState`, so `onEnd` writes the panel phase while the
        // build is still running — `!_dirty`, and the panel is replaced by
        // an ErrorWidget.
        await pumpTestApp(
          tester,
          const _ControlledNavigationMenuHarness(
            navigationMenuStyle: CoreNavigationMenuStyle(
              panelSwitchDuration: Duration.zero,
            ),
          ),
        );
        await tester.pumpAndSettle();

        tester
            .state<_ControlledNavigationMenuHarnessState>(
              find.byType(_ControlledNavigationMenuHarness),
            )
            .setActiveIndex(1);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        // Still a correct switch — just without the travel.
        expect(find.text('Solutions content'), findsOneWidget);
        expect(find.text('Products content'), findsNothing);
      },
    );

    testWidgets(
      'items shrinking under the open index during a switch does not throw',
      (tester) async {
        await pumpTestApp(tester, const _ControlledNavigationMenuHarness());
        await tester.pumpAndSettle();

        final state = tester.state<_ControlledNavigationMenuHarnessState>(
          find.byType(_ControlledNavigationMenuHarness),
        );
        // The switch is decided against the old, longer list; by the time
        // the travel distance is measured the keys have already shrunk.
        state.setActiveIndex(1);
        await tester.pump();
        state.shrinkToFirstItemOnly();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'an ancestor rebuild mid-travel does not drop the outgoing half',
      (tester) async {
        // `Widget` has no value equality, so content built inline — as this
        // component's own default example does — is a fresh instance every
        // frame. The steady-state content sync must not mistake that for a
        // content change and replace the in-flight travel.
        await pumpTestApp(
          tester,
          const _ControlledNavigationMenuHarness(constContent: false),
        );
        await tester.pumpAndSettle();

        final state = tester.state<_ControlledNavigationMenuHarnessState>(
          find.byType(_ControlledNavigationMenuHarness),
        );
        state.setActiveIndex(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        // Force the ancestor to rebuild mid-flight, minting fresh content.
        state.bump();
        // Two pumps, deliberately: the phase is reconciled in a post-frame
        // callback, so a clobber would only reach the panel on the frame
        // after that. Asserting one pump early would pass either way.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Still travelling: both halves on screen, one panel.
        expect(find.byType(Popup), findsOneWidget);
        expect(find.text('Products content'), findsOneWidget);
        expect(find.text('Solutions content'), findsOneWidget);
      },
    );

    testWidgets(
      're-entering the menu before the delay elapses cancels the close',
      (tester) async {
        await pumpTestApp(tester, const _HoverNavigationMenuHarness());

        final pointer = await tester.createGesture(kind: .mouse);
        await pointer.addPointer(location: Offset.zero);
        addTearDown(pointer.removePointer);

        await pointer.moveTo(tester.getCenter(find.text('Products')));
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsOneWidget);

        await pointer.moveTo(Offset.zero);
        await tester.pump(const Duration(milliseconds: 100));
        // Back on a trigger before the grace period is up — the armed
        // close must be stranded, not merely postponed.
        await pointer.moveTo(tester.getCenter(find.text('Products')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Products content'), findsOneWidget);
      },
    );

    testWidgets(
      'the root is a labelled navigation landmark — the twin of Web <nav>',
      (tester) async {
        // A labelled container without the role reads as a group, so a
        // reader's landmark list would skip this navigation on Flutter
        // alone. Reverting the root to a bare `Semantics(label:)` turns
        // the role assertion red. A single trigger is deliberate: without
        // explicit child nodes it folds into the landmark and the label
        // becomes "<landmark>\n<trigger>", which the label assertion
        // catches.
        final handle = tester.ensureSemantics();
        await pumpTestApp(
          tester,
          const NavigationMenu(
            items: [
              CoreNavigationMenuItem(label: 'Products'),
            ],
          ),
        );

        final data = tester
            .getSemantics(find.byType(NavigationMenu))
            .getSemanticsData();
        final expectedLabel = CoUILocalizations.of(
          tester.element(find.byType(NavigationMenu)),
        ).navigationLabel;

        expect(data.role, SemanticsRole.navigation);
        expect(data.label, expectedLabel);
        handle.dispose();
      },
    );

    testWidgets(
      'a content trigger is a disclosure button; a link trigger is a link',
      (tester) async {
        // Same structure as the Web twin: `<button aria-expanded>` for a
        // trigger that owns a panel, `<a href>` for a destination.
        final handle = tester.ensureSemantics();
        await pumpTestApp(
          tester,
          const NavigationMenu(
            items: [
              CoreNavigationMenuItem(
                label: 'Products',
                content: Text('Products content'),
              ),
              CoreNavigationMenuItem(label: 'Pricing', href: '/pricing'),
            ],
          ),
        );

        final disclosure = tester
            .getSemantics(find.text('Products'))
            .getSemanticsData();
        expect(disclosure.flagsCollection.isButton, isTrue);
        expect(disclosure.flagsCollection.isExpanded, isNot(Tristate.none));

        final link = tester
            .getSemantics(find.text('Pricing'))
            .getSemanticsData();
        expect(link.flagsCollection.isLink, isTrue);
        expect(link.flagsCollection.isExpanded, Tristate.none);
        handle.dispose();
      },
    );
  });
}

/// Uncontrolled harness for the pointer-intent tests — hover drives the
/// open state, which is the path `closeDelay` guards.
class _HoverNavigationMenuHarness extends StatelessWidget {
  const _HoverNavigationMenuHarness();

  @override
  Widget build(BuildContext context) {
    return const NavigationMenu(
      items: [
        CoreNavigationMenuItem(
          label: 'Products',
          content: Text('Products content'),
        ),
        CoreNavigationMenuItem(
          label: 'Solutions',
          content: Text('Solutions content'),
        ),
      ],
    );
  }
}

/// Test-only harness holding `activeIndex` in local state so a test can
/// flip it via [setActiveIndex] on an already-mounted tree — driving
/// `NavigationMenu`'s controlled-mode `didUpdateWidget` reconciliation
/// without needing a fresh `pumpTestApp` (which would re-seed the shared
/// `Overlay(initialEntries:)` test harness and never actually reach the
/// already-mounted overlay entry).
class _ControlledNavigationMenuHarness extends StatefulWidget {
  const _ControlledNavigationMenuHarness({
    this.navigationMenuStyle,
    this.constContent = true,
    this.alignEnd = false,
    this.contentWidths,
    this.itemCount = 2,
  });

  /// Pushes the bar to the trailing edge, so the panels collide with the
  /// viewport and the engine has to clamp them.
  final bool alignEnd;

  /// Per-item panel content width. Different widths make the engine clamp
  /// the two panels to *different* origins — the case where a travel
  /// computed from trigger geometry is wrong.
  final List<double>? contentWidths;

  /// How many triggers to render.
  final int itemCount;

  /// Passed straight through, so a test can drive a resolved value (e.g.
  /// a zero-length travel) without reaching into the widget.
  final CoreNavigationMenuStyle? navigationMenuStyle;

  /// When false, the item content is built inline on every frame — fresh
  /// `Widget` instances, which is what real callers produce and what
  /// canonicalised `const` content hides.
  final bool constContent;

  @override
  State<_ControlledNavigationMenuHarness> createState() =>
      _ControlledNavigationMenuHarnessState();
}

class _ControlledNavigationMenuHarnessState
    extends State<_ControlledNavigationMenuHarness> {
  int? _activeIndex = 0;
  bool _shrunk = false;
  int _rebuildTick = 0;

  void setActiveIndex(int? index) => setState(() => _activeIndex = index);

  /// Drops every item after the first, so an index captured a frame ago is
  /// now out of range.
  void shrinkToFirstItemOnly() => setState(() {
    _shrunk = true;
    _activeIndex = 0;
  });

  /// Rebuilds without changing anything the menu should care about.
  void bump() => setState(() => _rebuildTick++);

  static const _kLabels = ['Products', 'Solutions', 'Company'];

  List<CoreNavigationMenuItem<Widget>> get _items {
    final widths = widget.contentWidths;
    final List<CoreNavigationMenuItem<Widget>> items;
    if (widths != null) {
      // Sized content so the panel width — and therefore where the engine
      // clamps it — is under the test's control.
      items = [
        for (var i = 0; i < widths.length; i++)
          CoreNavigationMenuItem(
            label: _kLabels[i],
            content: SizedBox(
              width: widths[i],
              height: 80,
              child: Text('${_kLabels[i]} content'),
            ),
          ),
      ];
    } else if (widget.constContent) {
      items = [
        for (var i = 0; i < widget.itemCount; i++)
          CoreNavigationMenuItem(
            label: _kLabels[i],
            content: Text('${_kLabels[i]} content'),
          ),
      ];
    } else {
      items = [
        for (var i = 0; i < widget.itemCount; i++)
          // Deliberately not const — a new instance every build.
          CoreNavigationMenuItem(
            label: _kLabels[i],
            content: Text(
              '${_kLabels[i]} content',
              key: ValueKey(_rebuildTick),
            ),
          ),
      ];
    }

    return _shrunk ? items.take(1).toList() : items;
  }

  @override
  Widget build(BuildContext context) {
    final menu = NavigationMenu(
      activeIndex: _activeIndex,
      navigationMenuStyle: widget.navigationMenuStyle,
      items: _items,
    );
    if (!widget.alignEnd) return menu;

    return Align(alignment: .centerRight, child: menu);
  }
}
