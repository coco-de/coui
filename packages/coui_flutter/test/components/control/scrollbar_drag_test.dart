import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show SemanticsNode, SemanticsOwner;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kItemCount = 50;
const _kItemHeight = 40.0;

/// Side of the square viewport every test pumps the bar into — short
/// enough that [_kItemCount] items overflow it, so there is always a
/// thumb shorter than its track to drag.
const _kViewportSide = 300.0;

/// How far the thumb is dragged down its track. Small enough to stay
/// inside the track at every start position these tests use.
const _kThumbDragDistance = 60.0;

/// Inset from the bar's trailing edge that the probe presses at — inside
/// the default thumb, which spans 2–8 from that edge (6 thick, 2 clear of
/// it).
const _kThumbProbeInset = 4.0;

/// Vertical step the thumb probe walks the trailing edge with.
const _kThumbProbeStep = 2.0;

Widget _list([ScrollController? controller]) => ListView.builder(
  controller: controller,
  itemBuilder: (_, index) =>
      SizedBox(height: _kItemHeight, child: Text('Item $index')),
  itemCount: _kItemCount,
);

/// Bounds [child] to the shared [_kViewportSide] square.
Widget _boxed(Widget child) =>
    SizedBox(width: _kViewportSide, height: _kViewportSide, child: child);

/// The `CustomPaint` that hosts the live [ScrollbarPainter] — the same
/// one `RawScrollbar`'s own gesture recognizers consult through their
/// `GlobalKey`, so what it answers here is what they would answer.
Finder get _painterHost => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint && widget.foregroundPainter is ScrollbarPainter,
);

/// The live scroll position of the wrapped list, read without a
/// controller — these tests exist precisely because there is none.
ScrollPosition _listPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

/// The semantics owner of the view the bar is pumped into.
SemanticsOwner? _semanticsOwner(WidgetTester tester) =>
    tester.binding.renderViews.first.owner?.semanticsOwner;

/// Walks the current semantics tree for the first node flagged
/// `isSlider` — the phantom accessibility node `Scrollbar` adds
/// alongside the wrapped scrollable's own semantics.
SemanticsNode? _findSliderNode(WidgetTester tester) {
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (found != null) return;
    if (node.getSemanticsData().flagsCollection.isSlider) {
      found = node;
      return;
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root = _semanticsOwner(tester)?.rootSemanticsNode;
  if (root != null) visit(root);
  return found;
}

/// Walks down the bar's trailing edge asking the live painter where the
/// thumb is, and returns the first global point it claims as thumb — or
/// null if the painter claims none of them.
///
/// Asking the painter rather than computing a thumb rect here is what
/// makes the drag tests falsifiable in the direction that matters: a
/// press that missed the thumb would also move nothing, and would look
/// exactly like the defect. `hitTestOnlyThumbInteractive` is the same
/// predicate `_isThumbEvent` gates the SDK's thumb drag recognizer on,
/// so a point it accepts is a point the recognizer would have accepted.
Offset? _findThumbPoint(WidgetTester tester) {
  final painter =
      tester.widget<CustomPaint>(_painterHost).foregroundPainter!
          as ScrollbarPainter;
  final rect = tester.getRect(_painterHost);
  for (var dy = 0.0; dy < rect.height; dy += _kThumbProbeStep) {
    final local = Offset(rect.width - _kThumbProbeInset, dy);
    if (painter.hitTestOnlyThumbInteractive(local, PointerDeviceKind.mouse)) {
      return rect.topLeft + local;
    }
  }
  return null;
}

/// Scrolls the wrapped list far enough to fade the thumb in, then leaves
/// it visible.
///
/// The list is scrolled with a touch pointer because the desktop
/// `ScrollBehavior` drops [PointerDeviceKind.mouse] from `dragDevices` —
/// a mouse drag here would move nothing and every assertion downstream
/// would read as the defect under test.
///
/// `pumpAndSettle` is deliberately not used between here and the thumb
/// press: it would run the fade-out timer to completion and hide the
/// thumb, so the press would land on nothing.
Future<void> _revealThumb(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -200));
  await tester.pump();
  await tester.pump(
    const Duration(milliseconds: CoreScrollbarContract.fadeDurationMs),
  );
}

/// Presses the thumb and drags it [_kThumbDragDistance] down the track,
/// returning how far the list moved.
///
/// The press uses a mouse pointer on purpose. On desktop the wrapped
/// list cannot respond to a mouse drag at all (`dragDevices` excludes
/// it), so any movement this reports came from the bar's own thumb
/// recognizer and nothing else — with a touch pointer a list that
/// happened to receive the drag directly would produce the same number.
Future<double> _dragThumbBy(WidgetTester tester) async {
  final before = _listPosition(tester).pixels;
  final thumbPoint = _findThumbPoint(tester);
  expect(
    thumbPoint,
    isNotNull,
    reason:
        'the painter claims no thumb along the bar, so the drag below '
        'would prove nothing about whether dragging works',
  );

  await tester.dragFrom(
    thumbPoint!,
    const Offset(0, _kThumbDragDistance),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pumpAndSettle();
  return _listPosition(tester).pixels - before;
}

void main() {
  // The bar paints a thumb whether or not a controller reached it, and
  // `hitTestOnlyThumbInteractive` accepts presses on that thumb either
  // way — so the press lands, and then nothing happens. No exception, no
  // log: the affordance simply lies. Reproduced at 0.0px against a
  // control that moves 400+px through the identical gesture.
  group('Scrollbar thumb drag without a controller (#3994)', () {
    testWidgets(
      'dragging the thumb scrolls the list when no controller was passed '
      'to either the bar or the list',
      (tester) async {
        await pumpTestApp(tester, _boxed(Scrollbar(child: _list())));
        await tester.pumpAndSettle();
        await _revealThumb(tester);

        expect(await _dragThumbBy(tester), greaterThan(0));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // The same shape inside a route, where an ambient
    // `PrimaryScrollController` exists but the list never attaches to it
    // off mobile — the lookup finds a controller, and it has no clients,
    // which is a different way of having nothing to drive.
    testWidgets(
      'dragging the thumb scrolls the list inside a route, where the '
      'ambient PrimaryScrollController has no clients',
      (tester) async {
        await tester.pumpWidget(
          material.MaterialApp(
            home: buildTestApp(_boxed(Scrollbar(child: _list()))),
          ),
        );
        await tester.pumpAndSettle();

        // Guards the premise: a list that had attached to the route's
        // controller would make this test about something else.
        final primary = PrimaryScrollController.maybeOf(
          tester.element(find.byType(ListView)),
        );
        expect(primary, isNotNull);
        expect(primary!.hasClients, isFalse);

        await _revealThumb(tester);
        expect(await _dragThumbBy(tester), greaterThan(0));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // The bar never sees this controller; the list owns it. The thumb the
    // bar paints tracks that list, so the thumb the user drags has to move
    // that list.
    testWidgets(
      'dragging the thumb scrolls the list that owns its own controller, '
      'which the bar never sees',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(Scrollbar(child: _list(controller))),
        );
        await tester.pumpAndSettle();
        await _revealThumb(tester);

        final moved = await _dragThumbBy(tester);
        expect(moved, greaterThan(0));
        // Same position, reached through the caller's own handle — the
        // bar moved the list the caller holds, not some other one.
        expect(controller.position.pixels, _listPosition(tester).pixels);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // The control. If this ever fails, the harness stopped being able to
    // drag a thumb at all and the tests above are measuring the harness
    // rather than the bar.
    testWidgets(
      'the same gesture through an explicit controller moves the list',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await pumpTestApp(
          tester,
          _boxed(Scrollbar(controller: controller, child: _list(controller))),
        );
        await tester.pumpAndSettle();
        await _revealThumb(tester);

        expect(await _dragThumbBy(tester), greaterThan(0));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // `interactive: false` still means what it meant. Reviving the drag
    // for controller-less bars must not revive it for bars that asked
    // not to be operated — and this is the one shape where the old code
    // was accidentally right, so it is the easiest thing to break.
    testWidgets(
      'a non-interactive bar without a controller still does not drag',
      (tester) async {
        await pumpTestApp(
          tester,
          _boxed(Scrollbar(interactive: false, child: _list())),
        );
        await tester.pumpAndSettle();
        await _revealThumb(tester);

        final before = _listPosition(tester).pixels;
        // The painter is asked nothing here: a non-interactive bar
        // deliberately hit-tests as absent, so `_findThumbPoint` would
        // find no thumb and the shared helper would (correctly) fail.
        // Press where the thumb is drawn regardless.
        final rect = tester.getRect(_painterHost);
        await tester.dragFrom(
          Offset(rect.right - _kThumbProbeInset, rect.center.dy),
          const Offset(0, _kThumbDragDistance),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(_listPosition(tester).pixels, before);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    // The bar holds the tracked scrollable as a context and resolves a
    // position from it on every question, so a scrollable that has gone
    // away answers "none" rather than handing back the position it left
    // behind. That liveness check predates this change but had one
    // consumer that merely did nothing with a dead position; lending one
    // to `RawScrollbar` would have it dragged.
    //
    // The accessibility step is what this fires, because it is the one
    // consumer reachable from a test: the drag needs a thumb, and a bar
    // whose scrollable has vanished paints none.
    testWidgets(
      'a scrollable that has gone away is not resolved',
      (tester) async {
        final handle = tester.ensureSemantics();
        var showList = true;
        late StateSetter rebuildOuter;

        await pumpTestApp(
          tester,
          _boxed(
            StatefulBuilder(
              builder: (context, setState) {
                rebuildOuter = setState;
                return Scrollbar(
                  child: showList ? _list() : const SizedBox.expand(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Park mid-range so the node advertises a step in both
        // directions — at 0% it withholds `decrease` for reasons that
        // have nothing to do with liveness.
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(
          _findSliderNode(tester)!.getSemanticsData().hasAction(.increase),
          isTrue,
        );

        rebuildOuter(() => showList = false);
        await tester.pumpAndSettle();
        expect(find.byType(ListView), findsNothing);

        // The node still advertises the step it was last told about —
        // nothing arrived to say otherwise. Firing it must not reach the
        // position the vanished list left behind.
        final stale = _findSliderNode(tester);
        expect(
          stale,
          isNotNull,
          reason: 'the node has to survive the swap for this to test anything',
        );
        expect(stale!.getSemanticsData().hasAction(.increase), isTrue);
        _semanticsOwner(tester)!.performAction(
          stale.id,
          .increase,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        handle.dispose();
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });
}
