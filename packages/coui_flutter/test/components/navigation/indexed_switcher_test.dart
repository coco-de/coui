import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const Duration _kExit = CoreIndexedSwitcherStyle.defaultExitDuration;
const Duration _kEnter = CoreIndexedSwitcherStyle.defaultEnterDuration;

/// A destination that counts its own taps — the count lives in its
/// `State`, so it survives only if the switcher never rebuilds the subtree.
class _Destination extends StatefulWidget {
  const _Destination(this.label, {super.key});

  final String label;

  @override
  State<_Destination> createState() => _DestinationState();
}

class _DestinationState extends State<_Destination> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _taps++),
      child: SizedBox(
        width: 200,
        height: 120,
        child: Text('${widget.label} $_taps'),
      ),
    );
  }
}

List<Widget> _destinations() => const [
  _Destination('home', key: ValueKey('home')),
  _Destination('search', key: ValueKey('search')),
  _Destination('profile', key: ValueKey('profile')),
];

/// Drives one switcher through index changes.
///
/// The harness hosts its child in an `OverlayEntry` that is built once, so a
/// second `pumpTestApp` would not reach the switcher. The index travels
/// through this notifier instead, and the switcher is updated in place —
/// the path a real index change takes.
class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final ValueNotifier<int> index = ValueNotifier(0);

  Future<void> pump({
    int initial = 0,
    CoreComponentTheme? componentTheme,
    CoreIndexedSwitcherStyle? style,
    bool disableAnimations = false,
  }) {
    index.value = initial;

    return pumpTestApp(
      tester,
      ValueListenableBuilder<int>(
        valueListenable: index,
        builder: (context, value, _) => IndexedSwitcher(
          index: value,
          indexedSwitcherStyle: style,
          children: _destinations(),
        ),
      ),
      componentTheme: componentTheme,
      disableAnimations: disableAnimations,
    );
  }

  Future<void> switchTo(int value) async {
    index.value = value;
    await tester.pump();
  }
}

/// The opacity the switcher gives the destination keyed [key].
double _opacityOf(WidgetTester tester, String key) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(FadeTransition),
        )
        .first,
  );

  return fade.opacity.value;
}

/// Whether the destination keyed [key] is painted at all.
bool _isVisible(WidgetTester tester, String key) {
  final visibility = tester.widget<Visibility>(
    find
        .ancestor(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Visibility),
        )
        .first,
  );

  return visibility.visible;
}

void main() {
  group('IndexedSwitcher', () {
    testWidgets('shows only the indexed child but builds every child', (
      tester,
    ) async {
      await _Harness(tester).pump();

      expect(find.text('home 0'), findsOneWidget);
      // Hidden destinations are built (their state exists) …
      expect(find.text('search 0', skipOffstage: false), findsOneWidget);
      expect(find.text('profile 0', skipOffstage: false), findsOneWidget);
      // … but not painted.
      expect(_isVisible(tester, 'home'), isTrue);
      expect(_isVisible(tester, 'search'), isFalse);
      expect(_isVisible(tester, 'profile'), isFalse);
    });

    testWidgets('a destination keeps its state across switches', (
      tester,
    ) async {
      final harness = _Harness(tester);
      await harness.pump();
      await tester.tap(find.text('home 0'));
      await tester.pump();
      expect(find.text('home 1'), findsOneWidget);

      await harness.switchTo(1);
      await tester.pumpAndSettle();
      await harness.switchTo(0);
      await tester.pumpAndSettle();

      expect(find.text('home 1'), findsOneWidget);
    });

    testWidgets('fades through: the old view leaves before the new one '
        'arrives', (tester) async {
      final harness = _Harness(tester);
      await harness.pump();
      await harness.switchTo(1);

      // Halfway through the fade-out: home is leaving, search has not
      // started.
      await tester.pump(_kExit ~/ 2);
      expect(_opacityOf(tester, 'home'), inExclusiveRange(0, 1));
      expect(_opacityOf(tester, 'search'), 0);
      expect(_isVisible(tester, 'home'), isTrue);

      // Halfway through the fade-in: home is gone, search is arriving.
      await tester.pump(_kExit ~/ 2 + _kEnter ~/ 2);
      expect(_opacityOf(tester, 'home'), 0);
      expect(_opacityOf(tester, 'search'), inExclusiveRange(0, 1));

      // Settled: only search is painted, at full strength.
      await tester.pump(_kEnter);
      expect(_opacityOf(tester, 'search'), 1);
      expect(_isVisible(tester, 'home'), isFalse);
      expect(_isVisible(tester, 'search'), isTrue);
    });

    testWidgets('the whole switch takes exit + enter', (tester) async {
      final harness = _Harness(tester);
      await harness.pump();
      await harness.switchTo(2);

      await tester.pump(_kExit + _kEnter - const Duration(milliseconds: 1));
      expect(_opacityOf(tester, 'profile'), lessThan(1));
      expect(_isVisible(tester, 'home'), isTrue);

      // The controller reports completion on the first frame past the end.
      await tester.pump(const Duration(milliseconds: 2));
      expect(_opacityOf(tester, 'profile'), 1);
      expect(_isVisible(tester, 'home'), isFalse);
    });

    testWidgets('the leaving view takes no taps while it fades out', (
      tester,
    ) async {
      final harness = _Harness(tester);
      // Search sits above home in paint order, so leaving search for home
      // keeps the leaving view on top — the case where a tap could land on
      // it.
      await harness.pump(initial: 1);
      await harness.switchTo(0);
      await tester.pump(_kExit ~/ 4);
      expect(_isVisible(tester, 'search'), isTrue);

      await tester.tap(find.text('search 0'));
      await tester.pumpAndSettle();

      // The tap went through the fading view to the shown one.
      expect(find.text('home 1'), findsOneWidget);
      await harness.switchTo(1);
      await tester.pumpAndSettle();
      expect(find.text('search 0'), findsOneWidget);
    });

    testWidgets('only the shown view is in the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final harness = _Harness(tester);
      await harness.pump();
      await harness.switchTo(1);
      await tester.pump(_kExit ~/ 2);

      // Mid-fade, home is still painted but already out of the tree.
      expect(_isVisible(tester, 'home'), isTrue);
      // `find.semantics` reads the rendered semantics tree; a widget finder
      // would read a render object's last node, which an excluded subtree
      // can still hold.
      expect(find.semantics.byLabel('home 0'), findsNothing);
      expect(find.semantics.byLabel('search 0'), findsOne);

      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('home 0'), findsNothing);
      expect(find.semantics.byLabel('profile 0'), findsNothing);
      handle.dispose();
    });

    testWidgets('only the shown view can take focus', (tester) async {
      final homeFocus = FocusNode(debugLabel: 'home');
      final searchFocus = FocusNode(debugLabel: 'search');
      final index = ValueNotifier(0);
      addTearDown(homeFocus.dispose);
      addTearDown(searchFocus.dispose);
      addTearDown(index.dispose);

      await pumpTestApp(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (context, value, _) => IndexedSwitcher(
            index: value,
            children: [
              Focus(focusNode: homeFocus, child: const SizedBox(height: 10)),
              Focus(focusNode: searchFocus, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      );

      homeFocus.requestFocus();
      await tester.pump();
      expect(homeFocus.hasFocus, isTrue);
      expect(searchFocus.canRequestFocus, isFalse);

      index.value = 1;
      await tester.pump();
      // Leaving drops focus at once, even while the view is fading out.
      expect(homeFocus.hasFocus, isFalse);
      expect(homeFocus.canRequestFocus, isFalse);
      expect(searchFocus.canRequestFocus, isTrue);
    });

    testWidgets('a reduced-motion request makes the switch instant', (
      tester,
    ) async {
      final harness = _Harness(tester);
      await harness.pump(disableAnimations: true);
      await harness.switchTo(1);

      expect(_opacityOf(tester, 'search'), 1);
      expect(_isVisible(tester, 'home'), isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the component theme sets the timing', (tester) async {
      const theme = CoreComponentTheme(
        indexedSwitcher: CoreIndexedSwitcherTheme(
          style: CoreIndexedSwitcherStyle(
            exitDuration: Duration.zero,
            enterDuration: Duration(milliseconds: CoreDuration.slow),
          ),
        ),
      );
      final harness = _Harness(tester);
      await harness.pump(componentTheme: theme);
      await harness.switchTo(1);

      // No fade-out: home is gone on the first frame, search fades in over
      // the theme's slow enter — still under way past the default's whole
      // switch.
      expect(_opacityOf(tester, 'home'), 0);
      await tester.pump(const Duration(milliseconds: CoreDuration.moderate));
      expect(_opacityOf(tester, 'search'), inExclusiveRange(0, 1));
    });

    testWidgets('the instance style wins over the theme', (tester) async {
      const theme = CoreComponentTheme(
        indexedSwitcher: CoreIndexedSwitcherTheme(
          style: CoreIndexedSwitcherStyle(
            enterDuration: Duration(milliseconds: CoreDuration.slow),
          ),
        ),
      );
      const instant = CoreIndexedSwitcherStyle(
        exitDuration: Duration.zero,
        enterDuration: Duration.zero,
      );
      final harness = _Harness(tester);
      await harness.pump(componentTheme: theme, style: instant);
      await harness.switchTo(1);

      expect(_opacityOf(tester, 'search'), 1);
      expect(_isVisible(tester, 'home'), isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a switch that cuts into another never flashes the '
        'half-faded view back to full strength', (tester) async {
      final harness = _Harness(tester);
      await harness.pump();
      await harness.switchTo(1);
      // Into search's fade-in.
      await tester.pump(_kExit + _kEnter ~/ 4);
      final searchMidway = _opacityOf(tester, 'search');
      expect(searchMidway, inExclusiveRange(0, 1));

      await harness.switchTo(2);
      // Search leaves from where it was, never above it.
      expect(_opacityOf(tester, 'search'), lessThanOrEqualTo(searchMidway));
      await tester.pump(_kExit ~/ 2);
      expect(_opacityOf(tester, 'search'), lessThan(searchMidway));
      // Home, which the first switch had already hidden, stays hidden.
      expect(_isVisible(tester, 'home'), isFalse);

      await tester.pumpAndSettle();
      expect(_opacityOf(tester, 'profile'), 1);
      expect(_isVisible(tester, 'search'), isFalse);
    });

    testWidgets('a switch from a view that has not appeared still waits out '
        'the fade-out, as the Web transition does', (tester) async {
      final harness = _Harness(tester);
      await harness.pump();
      await harness.switchTo(1);
      // Still in home's fade-out: search has shown nothing yet.
      await tester.pump(_kExit ~/ 2);
      expect(_opacityOf(tester, 'search'), 0);

      await harness.switchTo(2);
      // One timeline on both platforms: profile waits for the fade-out even
      // though search has nothing to fade.
      await tester.pump(_kExit ~/ 2);
      expect(_opacityOf(tester, 'profile'), 0);
      await tester.pump(_kExit ~/ 2 + _kEnter ~/ 2);
      expect(_opacityOf(tester, 'profile'), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, 'profile'), 1);
    });

    testWidgets('sizes to its largest child, like IndexedStack', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const IndexedSwitcher(
          children: [
            SizedBox(width: 40, height: 30),
            SizedBox(width: 90, height: 10),
          ],
        ),
      );

      final size = tester.getSize(find.byType(IndexedSwitcher));
      expect(size, const Size(90, 30));
    });

    testWidgets('withStyle merges onto the instance style', (tester) async {
      final switcher = const IndexedSwitcher(
        indexedSwitcherStyle: CoreIndexedSwitcherStyle(
          exitDuration: Duration.zero,
        ),
        children: [SizedBox()],
      ).withStyle(const CoreIndexedSwitcherStyle(enterCurve: CoreEasing.move));

      expect(switcher.indexedSwitcherStyle?.exitDuration, Duration.zero);
      expect(switcher.indexedSwitcherStyle?.enterCurve, CoreEasing.move);
    });
  });
}
