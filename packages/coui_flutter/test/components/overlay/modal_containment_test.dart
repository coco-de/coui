import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _background = 'background action';
const _panel = 'panel content';

/// Whether any node in the merged semantics tree carries [label].
///
/// Reads the rendered tree rather than the widget tree — the question
/// is what assistive technology can reach, and a widget that is still
/// mounted but blocked answers "yes" to `find.text` while answering
/// "no" here. That gap is the whole defect.
bool _reachable(WidgetTester tester, String label) {
  var found = false;

  void walk(SemanticsNode node) {
    if (node.label.contains(label)) found = true;
    node.visitChildren((child) {
      walk(child);

      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);

  return found;
}

/// Mounts an app whose background holds a labelled, focusable control.
Future<void> _pumpApp(
  WidgetTester tester,
  GlobalKey anchorKey, {
  Locale? locale,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('ko')],
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: Button(
          key: anchorKey,
          onPressed: () {},
          child: const Text(_background),
        ),
      ),
    ),
  );
}

/// Opens a modal popover anchored to [anchorKey].
///
/// `follow: false` because the follow ticker runs a callback every
/// frame to track the anchor, so `pumpAndSettle` never returns with it
/// on. Following is orthogonal to containment.
PopoverEntryHandle<void> _open(
  GlobalKey anchorKey, {
  bool consumeOutsideTaps = true,
  bool modal = true,
}) => const PopoverOverlayHandler().show<void>(
  context: anchorKey.currentContext!,
  alignment: Alignment.topCenter,
  follow: false,
  consumeOutsideTaps: consumeOutsideTaps,
  modal: modal,
  builder: (_) => const Text(_panel),
);

/// The nodes that carry the dismiss action, in the merged semantics tree.
///
/// Read off the rendered tree for the same reason as [_reachable]: the
/// question is what assistive technology is offered, not which widget is
/// mounted.
Iterable<SemanticsNode> _dismissNodes(WidgetTester tester) =>
    find.semantics.byAction(SemanticsAction.dismiss).evaluate();

void main() {
  testWidgets('the background leaves the semantics tree while a modal '
      'overlay is open', (tester) async {
    final handle = tester.ensureSemantics();
    final anchorKey = GlobalKey();

    await _pumpApp(tester, anchorKey);
    expect(
      _reachable(tester, _background),
      isTrue,
      reason:
          'the control has to be reachable before the overlay opens, '
          'or this test would pass on a broken tree',
    );

    _open(anchorKey);
    await tester.pumpAndSettle();

    expect(_reachable(tester, _panel), isTrue);
    expect(
      _reachable(tester, _background),
      isFalse,
      reason:
          'a screen-reader user could still walk into content the '
          'sighted user cannot reach — the barrier swallowed pointers '
          'and nothing else',
    );

    handle.dispose();
  });

  testWidgets('the background comes back when the overlay closes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final anchorKey = GlobalKey();

    await _pumpApp(tester, anchorKey);

    final entry = _open(anchorKey);
    await tester.pumpAndSettle();
    expect(_reachable(tester, _background), isFalse);

    entry.close();
    await tester.pumpAndSettle();

    expect(_reachable(tester, _background), isTrue);
    handle.dispose();
  });

  testWidgets('Escape closes a dismissible modal overlay', (tester) async {
    final anchorKey = GlobalKey();

    await _pumpApp(tester, anchorKey);

    _open(anchorKey);
    await tester.pumpAndSettle();
    expect(find.text(_panel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(_panel), findsNothing);
  });

  testWidgets('a surface that ignores outside taps also ignores Escape', (
    tester,
  ) async {
    // The two are the same statement about the surface: "clicking away
    // does not close this". Wiring Escape to a different condition
    // would make one dismissal path work and the other not, which is
    // worse than neither.
    final anchorKey = GlobalKey();

    await _pumpApp(tester, anchorKey);

    _open(anchorKey, consumeOutsideTaps: false);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(_panel), findsOneWidget);
  });
  group('the dismiss action', () {
    // The assistive-technology twin of Escape. The barrier is out of reach of
    // a screen reader by design, so without an action on the panel the
    // platform's escape gesture falls through to whatever lies underneath,
    // and there is nothing for a user who cannot click away to activate.
    testWidgets('a dismissible modal overlay offers it, named in the locale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey);
      _open(anchorKey);
      await tester.pumpAndSettle();

      final nodes = _dismissNodes(tester).toList();
      expect(nodes, hasLength(1));
      final data = nodes.single.getSemanticsData();
      expect(data.label, 'Dismiss');
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the named node is also something to activate',
      );
      expect(
        _reachable(tester, _panel),
        isTrue,
        reason: 'the panel still has its own nodes beside the dismiss node',
      );

      handle.dispose();
    });

    testWidgets("the name is the locale's dismiss label", (tester) async {
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey, locale: const Locale('ko'));
      _open(anchorKey);
      await tester.pumpAndSettle();

      expect(_dismissNodes(tester).single.getSemanticsData().label, '닫기');

      handle.dispose();
    });

    testWidgets('performing it closes the overlay', (tester) async {
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey);
      final entry = _open(anchorKey);
      await tester.pumpAndSettle();
      expect(find.text(_panel), findsOneWidget);

      tester.semantics.performAction(
        find.semantics.byAction(SemanticsAction.dismiss),
        SemanticsAction.dismiss,
      );
      await tester.pumpAndSettle();

      expect(find.text(_panel), findsNothing);
      expect(entry.isCompleted, isTrue);
      expect(
        _reachable(tester, _background),
        isTrue,
        reason: 'closing gives the background back',
      );

      handle.dispose();
    });

    testWidgets('activating the named node closes the overlay too', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey);
      _open(anchorKey);
      await tester.pumpAndSettle();

      tester.semantics.tap(find.semantics.byLabel('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text(_panel), findsNothing);

      handle.dispose();
    });

    testWidgets('a surface that ignores outside taps offers none', (
      tester,
    ) async {
      // Same condition as Escape and the barrier: "clicking away does not
      // close this" holds for every way of saying it.
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey);
      _open(anchorKey, consumeOutsideTaps: false);
      await tester.pumpAndSettle();

      expect(_dismissNodes(tester), isEmpty);

      handle.dispose();
    });

    testWidgets('a non-modal overlay offers none', (tester) async {
      final handle = tester.ensureSemantics();
      final anchorKey = GlobalKey();

      await _pumpApp(tester, anchorKey);
      _open(anchorKey, modal: false);
      await tester.pumpAndSettle();

      expect(_dismissNodes(tester), isEmpty);
      expect(
        _reachable(tester, _background),
        isTrue,
        reason: 'a non-modal overlay leaves the page reachable',
      );

      handle.dispose();
    });
  });
}
