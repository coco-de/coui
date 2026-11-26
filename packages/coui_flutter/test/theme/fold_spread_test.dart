// A box a fold runs through is not always centred on it: an app's frame
// keeps clear of the device's controls along one edge only. `FoldSpread`
// takes the difference off the longer side, so content in two columns
// divides at the fold — and where no fold splits the viewport, or none runs
// through the box, the content is where it always was.
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

const w.Key _first = w.ValueKey('first');
const w.Key _second = w.ValueKey('second');
const w.Key _content = w.ValueKey('content');

/// A folding phone held like a book: 951 × 669 with the strip the system
/// reserves from 455.5 to 495.5.
const Size _viewport = Size(951, 669);

ui.DisplayFeature _strip({
  ui.DisplayFeatureState state = ui.DisplayFeatureState.postureHalfOpened,
  Rect bounds = const Rect.fromLTWH(455.5, 0, 40, 669),
}) => ui.DisplayFeature(
  bounds: bounds,
  type: ui.DisplayFeatureType.fold,
  state: state,
);

void _show(WidgetTester tester, List<ui.DisplayFeature> features) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _viewport
    ..displayFeatures = features;
  addTearDown(tester.view.reset);
}

/// Two equal columns with a 24 gutter, as an app's page lays them out.
const w.Widget _columns = w.Row(
  spacing: 24,
  children: [
    w.Expanded(child: w.SizedBox.expand(key: _first)),
    w.Expanded(child: w.SizedBox.expand(key: _second)),
  ],
);

w.Widget _spread(
  w.EdgeInsets frame, {
  w.Widget child = _columns,
  w.Axis axis = w.Axis.horizontal,
}) => w.Directionality(
  textDirection: w.TextDirection.ltr,
  child: w.Padding(
    padding: frame,
    child: FoldSpread(axis: axis, child: child),
  ),
);

void main() {
  // The frame an app keeps on this phone: clear of the controls down the
  // right edge.
  const frame = w.EdgeInsets.only(right: 84);

  testWidgets('the gutter of two columns falls on the fold', (tester) async {
    _show(tester, [_strip()]);

    await tester.pumpWidget(_spread(frame));
    await tester.pump();

    final first = tester.getRect(find.byKey(_first));
    final second = tester.getRect(find.byKey(_second));
    // The frame reaches 455.5 left of the strip and 371.5 right of it: 84 is
    // taken off the left, and the two columns are equally wide.
    expect(first.left, 84);
    expect(second.right, 867);
    expect(first.width, moreOrLessEquals(second.width, epsilon: 0.01));
    // The gutter's middle is the fold's.
    expect(
      (first.right + second.left) / 2,
      moreOrLessEquals(475.5, epsilon: 0.01),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a box already centred on the fold is left as it is', (
    tester,
  ) async {
    _show(tester, [_strip()]);

    await tester.pumpWidget(_spread(w.EdgeInsets.zero));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 0);
    expect(tester.getRect(find.byKey(_second)).right, 951);
  });

  testWidgets('the longer side gives way, whichever it is', (tester) async {
    _show(tester, [_strip()]);

    // The controls on the left edge, as they stand beside another app.
    await tester.pumpWidget(_spread(const w.EdgeInsets.only(left: 84)));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 84);
    expect(tester.getRect(find.byKey(_second)).right, 867);
  });

  testWidgets('a fold lying flat moves nothing', (tester) async {
    _show(tester, [
      _strip(
        state: ui.DisplayFeatureState.postureFlat,
        bounds: const Rect.fromLTWH(475.5, 0, 0, 669),
      ),
    ]);

    await tester.pumpWidget(_spread(frame));

    expect(tester.getRect(find.byKey(_first)).left, 0);
    expect(tester.getRect(find.byKey(_second)).right, 867);
    // Nothing was measured, and nothing is left to set right.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('with no fold nothing moves', (tester) async {
    _show(tester, const []);

    await tester.pumpWidget(_spread(frame));

    expect(tester.getRect(find.byKey(_first)).left, 0);
    expect(tester.getRect(find.byKey(_second)).right, 867);
  });

  testWidgets('a fold that does not run through the box moves nothing', (
    tester,
  ) async {
    _show(tester, [_strip()]);

    // A pane in the right half.
    await tester.pumpWidget(_spread(const w.EdgeInsets.only(left: 520)));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 520);
    expect(tester.getRect(find.byKey(_second)).right, 951);
  });

  group('inside scrolling content', () {
    // A page that scrolls, its content padded 30 on the left and 10 on the
    // right by the sliver: the box lies from 30 to 941, 425.5 left of the
    // strip and 445.5 right of it.
    w.Widget page(w.ScrollController controller) => w.Directionality(
      textDirection: w.TextDirection.ltr,
      child: w.CustomScrollView(
        controller: controller,
        slivers: const [
          w.SliverToBoxAdapter(child: w.SizedBox(height: 120)),
          w.SliverPadding(
            padding: w.EdgeInsets.only(left: 30, right: 10),
            sliver: w.SliverToBoxAdapter(
              child: w.SizedBox(
                height: 900,
                child: FoldSpread(child: _columns),
              ),
            ),
          ),
        ],
      ),
    );

    testWidgets('the side padding of a sliver counts', (tester) async {
      _show(tester, [_strip()]);
      final controller = w.ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(page(controller));
      await tester.pump();

      final first = tester.getRect(find.byKey(_first));
      final second = tester.getRect(find.byKey(_second));
      // 20 is taken off the right, the longer side.
      expect(first.left, 30);
      expect(second.right, 921);
      expect(first.width, moreOrLessEquals(second.width, epsilon: 0.01));
      expect(
        (first.right + second.left) / 2,
        moreOrLessEquals(475.5, epsilon: 0.01),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('how far it is scrolled does not', (tester) async {
      _show(tester, [_strip()]);
      final controller = w.ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pump();
      final before = tester.getRect(find.byKey(_first));
      final box = tester.renderObject<w.RenderBox>(find.byKey(_first));
      final lies = FoldScope.rectOf(box, viewport: _viewport);
      // Across the way the page scrolls it lies where it is laid out: 30 in.
      expect(lies.left, 30);

      controller.jumpTo(200);
      // The frame that draws the jump, and the one the scroll view itself
      // asks for after it.
      await tester.pump();
      await tester.pump();

      final after = tester.getRect(find.byKey(_first));
      expect(after.left, before.left);
      expect(after.width, before.width);
      expect(after.top, before.top - 200);
      // Scrolled, it is drawn elsewhere and lies where it lay: nothing is
      // built again.
      expect(FoldScope.rectOf(box, viewport: _viewport), lies);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('a fold along the edge of the box moves nothing', (tester) async {
    _show(tester, [_strip()]);

    // A pane that begins where the strip does: the strip is its edge, not
    // its middle.
    await tester.pumpWidget(_spread(const w.EdgeInsets.only(left: 455.5)));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 455.5);
    expect(tester.getRect(find.byKey(_second)).right, 951);
  });

  testWidgets('a fold lying flat beside one that splits is not counted', (
    tester,
  ) async {
    // A screen that bends at 300, lying flat, and the strip half open: only
    // the strip divides the viewport, so the spread is about the strip.
    _show(tester, [
      _strip(
        state: ui.DisplayFeatureState.postureFlat,
        bounds: const Rect.fromLTWH(300, 0, 0, 669),
      ),
      _strip(),
    ]);

    await tester.pumpWidget(_spread(frame));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 84);
    expect(tester.getRect(find.byKey(_second)).right, 867);
  });

  testWidgets('a fold across the box does not divide columns', (tester) async {
    // The phone on its side, standing: the strip runs across.
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(669, 951)
      ..displayFeatures = [
        _strip(bounds: const Rect.fromLTWH(0, 455.5, 669, 40)),
      ];
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_spread(const w.EdgeInsets.only(bottom: 84)));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).top, 0);
    expect(tester.getRect(find.byKey(_first)).bottom, 867);
  });

  testWidgets('rows stacked divide at a fold across the box', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(669, 951)
      ..displayFeatures = [
        _strip(bounds: const Rect.fromLTWH(0, 455.5, 669, 40)),
      ];
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _spread(
        const w.EdgeInsets.only(bottom: 84),
        axis: w.Axis.vertical,
        child: const w.SizedBox.expand(key: _content),
      ),
    );
    await tester.pump();

    // 455.5 above the strip, 371.5 below it within the frame: 84 off the top.
    expect(
      tester.getRect(find.byKey(_content)),
      const Rect.fromLTRB(0, 84, 669, 867),
    );
  });

  testWidgets('two folds have no one middle: nothing moves', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1200, 669)
      ..displayFeatures = [
        _strip(bounds: const Rect.fromLTWH(380, 0, 20, 669)),
        _strip(bounds: const Rect.fromLTWH(780, 0, 20, 669)),
      ];
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_spread(frame));
    await tester.pump();

    expect(tester.getRect(find.byKey(_first)).left, 0);
    expect(tester.getRect(find.byKey(_second)).right, 1116);
  });

  testWidgets('folding the device moves the content and remounts nothing', (
    tester,
  ) async {
    var mounts = 0;
    final content = _CountMounts(onMount: () => mounts += 1);
    _show(tester, [
      _strip(
        state: ui.DisplayFeatureState.postureFlat,
        bounds: const Rect.fromLTWH(475.5, 0, 0, 669),
      ),
    ]);
    await tester.pumpWidget(_spread(frame, child: content));
    expect(tester.getRect(find.byKey(_content)).left, 0);

    tester.view.displayFeatures = [_strip()];
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(_content)).left, 84);
    expect(mounts, 1);
  });
}

class _CountMounts extends w.StatefulWidget {
  const _CountMounts({required this.onMount});

  final void Function() onMount;

  @override
  w.State<_CountMounts> createState() => _CountMountsState();
}

class _CountMountsState extends w.State<_CountMounts> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  w.Widget build(w.BuildContext context) =>
      const w.SizedBox.expand(key: _content);
}
