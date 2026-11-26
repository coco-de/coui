import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// A drag-scroll viewport is reachable by pointer whether or not anyone
// wired it up, so nothing here is visible from a screenshot: the widget
// renders identically with and without the semantics and the key map.
// What these pin is the part only a keyboard or a screen reader can see.

const _kViewportExtent = 200.0;
const _kContentExtent = 800.0;

material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Center(
      child: material.SizedBox(
        width: _kViewportExtent,
        height: _kViewportExtent,
        child: child,
      ),
    ),
  ),
);

material.Widget _viewport({
  String? semanticLabel,
  material.ScrollController? vertical,
  material.ScrollController? horizontal,
}) => ScrollableClient(
  semanticLabel: semanticLabel,
  flutterVerticalDetails: vertical == null
      ? null
      : material.ScrollableDetails.vertical(controller: vertical),
  flutterHorizontalDetails: horizontal == null
      ? null
      : material.ScrollableDetails.horizontal(controller: horizontal),
  builder: (context, offset, viewportSize, child) => const material.SizedBox(
    width: _kContentExtent,
    height: _kContentExtent,
    child: material.Text('content'),
  ),
);

/// Every semantics node in the tree, root first.
List<SemanticsNode> _allNodes(WidgetTester tester) {
  final out = <SemanticsNode>[];
  void walk(SemanticsNode node) {
    out.add(node);
    node.visitChildren((child) {
      walk(child);

      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);

  return out;
}

Future<void> _focusViewport(WidgetTester tester) async {
  final node = tester.widget<FocusableActionDetector>(
    find.byType(FocusableActionDetector),
  );
  node.focusNode!.requestFocus();
  await tester.pump();
}

void main() {
  group('the viewport announces itself', () {
    testWidgets('a viewport nobody named still has a name', (tester) async {
      // Falling back to the locale rather than staying anonymous: an
      // unnamed region is read out as nothing at all, which is the state
      // this component shipped in.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_viewport()));

      final labels = _allNodes(tester).map((n) => n.getSemanticsData().label);
      expect(labels, contains(isNotEmpty));
      expect(labels, contains('Scrollable region'));

      handle.dispose();
    });

    testWidgets('an explicit label wins over the fallback', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_viewport(semanticLabel: 'Order table')));

      final labels = _allNodes(tester).map((n) => n.getSemanticsData().label);
      expect(labels, contains('Order table'));
      expect(labels, isNot(contains('Scrollable region')));

      handle.dispose();
    });

    testWidgets('naming it does not cost the scroll semantics it already had', (
      tester,
    ) async {
      // `TwoDimensionalScrollable` publishes position, extent and the
      // scroll actions a reader performs — all of it below the node this
      // change adds. Wrapping is the cheapest way to lose them, so the
      // assertion is that both survive together.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_viewport()));

      final data = _allNodes(tester).map((n) => n.getSemanticsData());
      final scrollers = data.where((d) => d.scrollExtentMax != null).toList();

      expect(
        scrollers,
        hasLength(2),
        reason: 'one scroll node per axis, as before this change',
      );
      expect(
        scrollers.every((d) => d.scrollExtentMax! > 0),
        isTrue,
        reason: 'both axes still report how far they can go',
      );
      expect(
        scrollers.any((d) => d.hasAction(SemanticsAction.scrollUp)),
        isTrue,
        reason: 'the vertical axis still offers a scroll action',
      );
      expect(
        scrollers.any((d) => d.hasAction(SemanticsAction.scrollLeft)),
        isTrue,
        reason: 'the horizontal axis still offers a scroll action',
      );

      handle.dispose();
    });
  });

  group('the viewport can be scrolled without a pointer', () {
    testWidgets('down arrow moves the vertical axis one line', (tester) async {
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await _focusViewport(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        vertical.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
      );
    });

    testWidgets('right arrow moves the horizontal axis, which Flutter\'s own '
        'ScrollAction cannot', (tester) async {
      // `ScrollAction` resolves the nearest `Scrollable` — inside a
      // `TwoDimensionalScrollable` that is always the inner horizontal
      // one — and then returns a zero increment for any intent naming
      // the other axis. Relying on it would leave one axis dead; this is
      // the axis that proves the widget routes keys itself.
      final horizontal = material.ScrollController();
      addTearDown(horizontal.dispose);
      await tester.pumpWidget(_app(_viewport(horizontal: horizontal)));
      await _focusViewport(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(
        horizontal.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
      );
    });

    testWidgets('page down moves a fraction of the viewport', (tester) async {
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      // The page step is read off the measured viewport, which is
      // published a frame after layout.
      await tester.pumpAndSettle();
      await _focusViewport(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();

      expect(
        vertical.position.pixels,
        _kViewportExtent *
            CoreScrollableClientContract.keyboardPageStepFraction,
      );
    });

    testWidgets('end jumps to the bottom and home comes back', (tester) async {
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await _focusViewport(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(vertical.position.pixels, vertical.position.maxScrollExtent);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(vertical.position.pixels, 0);
    });

    testWidgets('a key press at the edge is left for the page to handle', (
      tester,
    ) async {
      // Native scroll chaining: a browser hands the key to the enclosing
      // scroller once the inner one is at its edge. Consuming it anyway
      // would trap the user at the bottom of the content.
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await _focusViewport(tester);

      final detector = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector),
      );
      final node = detector.focusNode!;

      // Already at the top — an up arrow has nowhere to go.
      expect(
        node.onKeyEvent!(
          node,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowUp,
            logicalKey: LogicalKeyboardKey.arrowUp,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.ignored,
      );

      // A down arrow does have somewhere to go, and is consumed.
      expect(
        node.onKeyEvent!(
          node,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowDown,
            logicalKey: LogicalKeyboardKey.arrowDown,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.handled,
      );
    });

    testWidgets('holding a key keeps scrolling', (tester) async {
      // A held key arrives as `KeyRepeatEvent`, not as a second
      // `KeyDownEvent`. Handling only the latter looks correct in every
      // single-press test and stops dead the moment a user holds the key.
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await _focusViewport(tester);

      final detector = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector),
      );
      final node = detector.focusNode!;

      expect(
        node.onKeyEvent!(
          node,
          const KeyRepeatEvent(
            physicalKey: PhysicalKeyboardKey.arrowDown,
            logicalKey: LogicalKeyboardKey.arrowDown,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.handled,
      );
      expect(
        vertical.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
      );
    });

    testWidgets('a focused field inside keeps its own keys', (tester) async {
      // Flutter walks a key up the focused node's ancestors, and this
      // widget's node sits *below* the app-level text-editing shortcuts.
      // Without a primary-focus guard the viewport answers first and
      // scrolls, so `End` moves the content instead of the caret — and
      // `Table` composes this widget, so a field inside a scroll area is
      // the ordinary case, not a contrived one.
      final controller = material.TextEditingController(text: 'hello world');
      final fieldFocus = FocusNode();
      final vertical = material.ScrollController();
      addTearDown(controller.dispose);
      addTearDown(fieldFocus.dispose);
      addTearDown(vertical.dispose);

      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.Material(
              child: material.Center(
                child: material.SizedBox(
                  width: _kViewportExtent,
                  height: _kViewportExtent,
                  child: ScrollableClient(
                    flutterVerticalDetails: material.ScrollableDetails.vertical(
                      controller: vertical,
                    ),
                    builder: (context, offset, viewportSize, child) =>
                        material.SizedBox(
                          width: _kContentExtent,
                          height: _kContentExtent,
                          child: material.TextField(
                            controller: controller,
                            focusNode: fieldFocus,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      fieldFocus.requestFocus();
      await tester.pumpAndSettle();
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      expect(
        vertical.position.pixels,
        0,
        reason: 'the viewport must not scroll while a field owns the keys',
      );
      expect(
        controller.selection.baseOffset,
        controller.text.length,
        reason: 'End belongs to the caret here',
      );
    });

    testWidgets('a key outside the map is never claimed', (tester) async {
      await tester.pumpWidget(_app(_viewport()));
      await _focusViewport(tester);

      final detector = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector),
      );
      final node = detector.focusNode!;

      expect(
        node.onKeyEvent!(
          node,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.ignored,
      );
    });
  });

  group('the key map matches the shared one', () {
    testWidgets('every key the Core map knows is routed on Flutter too', (
      tester,
    ) async {
      // `_domKeyName` is the one hand-written, unshared half of the key
      // story — its own doc calls it that — so it is exactly where a
      // silent divergence from the Core map would live. Testing three of
      // its eight entries would leave the other five free to rot.
      final vertical = material.ScrollController();
      final horizontal = material.ScrollController();
      addTearDown(vertical.dispose);
      addTearDown(horizontal.dispose);
      await tester.pumpWidget(
        _app(_viewport(vertical: vertical, horizontal: horizontal)),
      );
      await tester.pumpAndSettle();
      await _focusViewport(tester);

      final node = tester
          .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
          .focusNode!;

      // Start mid-content so every key has somewhere to go in both
      // directions and none of them is ignored for lack of room.
      vertical.jumpTo(300);
      horizontal.jumpTo(300);
      await tester.pump();

      for (final key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.pageDown,
        LogicalKeyboardKey.pageUp,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
      ]) {
        expect(
          node.onKeyEvent!(
            node,
            KeyDownEvent(
              physicalKey: PhysicalKeyboardKey.space,
              logicalKey: key,
              timeStamp: Duration.zero,
            ),
          ),
          KeyEventResult.handled,
          reason: '${key.keyLabel} is in the Core map and must be routed here',
        );
        vertical.jumpTo(300);
        horizontal.jumpTo(300);
        await tester.pump();
      }
    });

    testWidgets('a reversed axis scrolls along its own direction', (
      tester,
    ) async {
      // Recorded, not corrected. With `AxisDirection.up` the offset still
      // runs 0..max and a forward key still increases it, so the view
      // travels the reversed way — the same thing `ListView(reverse:)`
      // does, and the same thing the Web twin's `scaleY(-1)` flip does
      // with its own 0..max `scrollTop`. Changing it here would make the
      // two platforms disagree, which is worse than an unfamiliar
      // direction that at least matches everywhere.
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(
        _app(
          ScrollableClient(
            verticalDetails: const CoreScrollableDetails.verticalReverse(),
            flutterVerticalDetails: material.ScrollableDetails.vertical(
              controller: vertical,
            ),
            builder: (context, offset, viewportSize, child) =>
                const material.SizedBox(
                  width: _kContentExtent,
                  height: _kContentExtent,
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _focusViewport(tester);

      expect(vertical.position.axisDirection, AxisDirection.up);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        vertical.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
      );
    });

    testWidgets('a modified combination is left to the platform', (
      tester,
    ) async {
      // Alt+Arrow is history navigation and Ctrl/Cmd+Home jumps the page.
      // Swallowing them would take a shortcut away and hand back a scroll
      // nobody asked for.
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await _focusViewport(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(vertical.position.pixels, 0);
    });

    testWidgets('the inherited PrimaryScrollController is the one that moves', (
      tester,
    ) async {
      // When the main axis inherits, the local fallback controller has no
      // clients at all — a key handler reading it would scroll nothing and
      // report success.
      final primary = material.ScrollController();
      addTearDown(primary.dispose);
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.PrimaryScrollController(
              controller: primary,
              child: material.Center(
                child: material.SizedBox(
                  width: _kViewportExtent,
                  height: _kViewportExtent,
                  child: ScrollableClient(
                    primary: true,
                    // Off because of a defect that predates this change and
                    // is not part of it: with `primary: true` the axis is
                    // driven by the inherited controller, but the two
                    // `Scrollbar`s are still wired to the local fallback
                    // fields, which then have no attached position and
                    // assert. Filed separately; turning the scrollbar off
                    // isolates the branch under test here.
                    showScrollbar: false,
                    builder: (context, offset, viewportSize, child) =>
                        const material.SizedBox(
                          width: _kContentExtent,
                          height: _kContentExtent,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _focusViewport(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        primary.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
      );
    });
  });

  group('a keyboard can actually reach it', () {
    testWidgets('Tab lands on the viewport', (tester) async {
      // `requestFocus` elsewhere in this file is a programmatic grab that
      // bypasses the traversal policy entirely — it would keep passing if
      // the node became unreachable by Tab. This one presses the key.
      await tester.pumpWidget(_app(_viewport()));
      await tester.pumpAndSettle();

      final node = tester
          .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
          .focusNode!;
      expect(node.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        node.hasFocus,
        isTrue,
        reason:
            'the viewport has to be in the traversal order, not merely '
            'focusable on request',
      );
    });

    testWidgets('a pointer press focuses it, as a click does on Web', (
      tester,
    ) async {
      // A browser focuses an element carrying an explicit `tabindex` on
      // mousedown, so on Web click-then-arrow scrolls. Nothing in
      // `FocusableActionDetector` takes focus on a tap, so without an
      // explicit listener the same gesture reaches the keyboard feature
      // on one platform only.
      final vertical = material.ScrollController();
      addTearDown(vertical.dispose);
      await tester.pumpWidget(_app(_viewport(vertical: vertical)));
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.byType(ScrollableClient)));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        vertical.position.pixels,
        CoreScrollableClientContract.keyboardLineStep,
        reason: 'click then arrow must scroll here as it does in a browser',
      );
    });
  });

  group('landing on it is visible', () {
    testWidgets('the ring appears for keyboard focus', (tester) async {
      // WCAG 2.4.7 — the viewport is in the tab order now, so a keyboard
      // user has to be able to see where they are standing.
      await tester.pumpWidget(_app(_viewport()));

      expect(
        tester.widget<FocusOutline>(find.byType(FocusOutline)).focused,
        isFalse,
      );

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        // Global, so it leaks into whatever runs next unless put back.
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });
      await _focusViewport(tester);

      expect(
        tester.widget<FocusOutline>(find.byType(FocusOutline)).focused,
        isTrue,
      );
    });

    testWidgets('but not for a pointer press', (tester) async {
      // The half the previous test cannot see. Focus is taken either way —
      // that is what makes click-then-arrow work — so the thing that has
      // to differ is the *highlight*, which is why the widget tracks
      // `onShowFocusHighlight` and not `onFocusChange`. Reading the ring
      // after a real tap is the only way to tell those two apart.
      await tester.pumpWidget(_app(_viewport()));
      await tester.pumpAndSettle();

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await tester.tapAt(tester.getCenter(find.byType(ScrollableClient)));
      await tester.pumpAndSettle();

      final node = tester
          .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
          .focusNode!;
      expect(node.hasFocus, isTrue, reason: 'the press still takes focus');
      expect(
        tester.widget<FocusOutline>(find.byType(FocusOutline)).focused,
        isFalse,
        reason: 'a mouse user must not get a ring they did not ask for',
      );
    });
  });
}
