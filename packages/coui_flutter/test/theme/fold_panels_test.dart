// The panels the kit places itself keep to one segment of a viewport a fold
// splits: a drawer docked to an edge, the toasts stacked at a corner, and a
// panel anchored to a trigger. Which segment is read against the table the
// Core rule and the Web read (`coui_core/test/fixtures/fold_vectors.json`,
// `aligned`), so the platforms open a panel on the same side — and where
// nothing splits the viewport a panel is where it always was.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

const String _kVectorsPath = '../coui_core/test/fixtures/fold_vectors.json';

const w.Key _content = w.ValueKey('content');
const w.Key _panel = w.ValueKey('panel');

Rect _rect(List<dynamic> value) => Rect.fromLTWH(
  (value[0] as num).toDouble(),
  (value[1] as num).toDouble(),
  (value[2] as num).toDouble(),
  (value[3] as num).toDouble(),
);

Size _viewportOf(Map<String, dynamic> vector) {
  final viewport = vector['viewport'] as List<dynamic>;

  return Size(
    (viewport[0] as num).toDouble(),
    (viewport[1] as num).toDouble(),
  );
}

List<Rect> _segmentsOf(Map<String, dynamic> vector) => [
  for (final segment in vector['segments'] as List<dynamic>)
    _rect(segment as List<dynamic>),
];

/// Puts [vector]'s viewport and folds on the test view, the way Android
/// reports them: a line is a fold, a strip is a hinge.
void _showFolds(WidgetTester tester, Map<String, dynamic> vector) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _viewportOf(vector)
    ..displayFeatures = [
      for (final raw in vector['folds'] as List<dynamic>)
        _feature(raw as Map<String, dynamic>),
    ];
  addTearDown(tester.view.reset);
}

ui.DisplayFeature _feature(Map<String, dynamic> fold) {
  final bounds = _rect(fold['bounds'] as List<dynamic>);

  return ui.DisplayFeature(
    bounds: bounds,
    type: bounds.shortestSide > 0
        ? ui.DisplayFeatureType.hinge
        : ui.DisplayFeatureType.fold,
    state: switch (fold['state'] as String) {
      'flat' => ui.DisplayFeatureState.postureFlat,
      'halfOpened' => ui.DisplayFeatureState.postureHalfOpened,
      _ => ui.DisplayFeatureState.unknown,
    },
  );
}

/// The segment the table names for a panel placed at [alignment], read in
/// [direction].
Rect _alignedSegment(
  Map<String, dynamic> vector,
  w.TextDirection direction,
  Alignment alignment,
) {
  final grid =
      (vector['aligned'] as Map<String, dynamic>)[direction.name]
          as List<dynamic>;
  final row = grid[alignment.y.round() + 1] as List<dynamic>;

  return _segmentsOf(vector)[row[alignment.x.round() + 1] as int];
}

Alignment _edgeOf(CoreDrawerSide side) => switch (side) {
  CoreDrawerSide.left => Alignment.centerLeft,
  CoreDrawerSide.right => Alignment.centerRight,
  CoreDrawerSide.top => Alignment.topCenter,
  CoreDrawerSide.bottom => Alignment.bottomCenter,
};

/// Whether [inner] lies inside [outer], to the rounding of a layout pass.
bool _inside(Rect inner, Rect outer) =>
    inner.left >= outer.left - 0.01 &&
    inner.top >= outer.top - 0.01 &&
    inner.right <= outer.right + 0.01 &&
    inner.bottom <= outer.bottom + 0.01;

Future<w.BuildContext> _pumpApp(
  WidgetTester tester,
  w.TextDirection direction, {
  w.Widget? home,
}) async {
  late w.BuildContext app;
  await tester.pumpWidget(
    CoUIApp(
      locale: direction == w.TextDirection.rtl
          ? const Locale('ar')
          : const Locale('en', 'US'),
      supportedLocales: const [Locale('ar'), Locale('en', 'US')],
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: w.Builder(
        builder: (context) {
          app = context;

          return home ?? const w.SizedBox.shrink();
        },
      ),
    ),
  );

  return app;
}

/// Counts its mounts, to tell a panel that moved from one that was rebuilt
/// from nothing.
class _Probe extends w.StatefulWidget {
  const _Probe({required this.mounts});

  final Set<int> mounts;

  @override
  w.State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends w.State<_Probe> {
  static int _mounted = 0;

  @override
  void initState() {
    super.initState();
    widget.mounts.add(_mounted += 1);
  }

  @override
  w.Widget build(w.BuildContext context) =>
      const w.SizedBox(key: _content, width: 80, height: 80);
}

void main() {
  final vectors = [
    for (final raw
        in (jsonDecode(File(_kVectorsPath).readAsStringSync())
                as Map<String, dynamic>)['cases']
            as List<dynamic>)
      raw as Map<String, dynamic>,
  ];
  final split = [
    for (final vector in vectors)
      if ((vector['segments'] as List<dynamic>).length > 1) vector,
  ];
  Map<String, dynamic> named(String name) =>
      vectors.firstWhere((vector) => vector['name'] == name);

  group('a drawer keeps to the segment its edge lies in', () {
    Future<void> openIn(
      WidgetTester tester,
      Map<String, dynamic> vector,
      w.TextDirection direction,
      CoreDrawerSide side, {
      required bool transformBackdrop,
    }) async {
      _showFolds(tester, vector);
      final app = await _pumpApp(tester, direction);
      unawaited(
        openDrawer<void>(
          context: app,
          side: side,
          transformBackdrop: transformBackdrop,
          builder: (_) => Drawer(
            side: side,
            content: const w.SizedBox(key: _content, width: 80, height: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void expectDocked(
      WidgetTester tester,
      Map<String, dynamic> vector,
      w.TextDirection direction,
      CoreDrawerSide side,
    ) {
      final segment = _alignedSegment(vector, direction, _edgeOf(side));
      final panel = tester.getRect(find.byType(Drawer));

      expect(
        _inside(panel, segment),
        isTrue,
        reason: 'the panel ($panel) lies inside its segment ($segment)',
      );
      expect(
        _inside(tester.getRect(find.byKey(_content)), segment),
        isTrue,
        reason: 'the content lies inside the segment ($segment)',
      );
      // Docked: the panel meets the edge of the segment it opens from.
      final (docked, edge) = switch (side) {
        CoreDrawerSide.left => (panel.left, segment.left),
        CoreDrawerSide.right => (panel.right, segment.right),
        CoreDrawerSide.top => (panel.top, segment.top),
        CoreDrawerSide.bottom => (panel.bottom, segment.bottom),
      };
      expect(docked, moreOrLessEquals(edge, epsilon: 0.01));
    }

    // Under `CoUIApp` a drawer is drawn through the backdrop layer; that is
    // the path an app takes, so it reads the whole table.
    for (final vector in vectors) {
      for (final direction in w.TextDirection.values) {
        for (final side in CoreDrawerSide.values) {
          testWidgets('${vector['name']}, ${direction.name}, ${side.name}', (
            tester,
          ) async {
            await openIn(
              tester,
              vector,
              direction,
              side,
              transformBackdrop: true,
            );

            expectDocked(tester, vector, direction, side);
          });
        }
      }
    }

    // Drawn as a route's page — an embed with no backdrop layer, or the
    // transform turned off — it keeps to the same segment.
    for (final vector in split) {
      for (final direction in w.TextDirection.values) {
        for (final side in CoreDrawerSide.values) {
          testWidgets('${vector['name']}, ${direction.name}, ${side.name}, as '
              "a route's page", (tester) async {
            await openIn(
              tester,
              vector,
              direction,
              side,
              transformBackdrop: false,
            );

            expectDocked(tester, vector, direction, side);
          });
        }
      }
    }

    testWidgets('across a fold that lies flat it spans the viewport as '
        'before', (tester) async {
      await openIn(
        tester,
        named('a fold, open flat'),
        w.TextDirection.ltr,
        CoreDrawerSide.bottom,
        transformBackdrop: true,
      );

      final panel = tester.getRect(find.byType(Drawer));
      expect(panel.left, 0);
      expect(panel.right, 690);
    });

    testWidgets('folding the device moves an open drawer and remounts '
        'nothing in it', (tester) async {
      _showFolds(tester, named('a fold, open flat'));
      final app = await _pumpApp(tester, w.TextDirection.ltr);
      final mounts = <int>{};
      unawaited(
        openDrawer<void>(
          context: app,
          side: CoreDrawerSide.bottom,
          builder: (_) => Drawer(
            side: CoreDrawerSide.bottom,
            content: _Probe(mounts: mounts),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Drawer)).width, 690);

      _showFolds(tester, named('a fold, half open as a book'));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(Drawer)).right, 345);
      expect(mounts, hasLength(1));
    });
  });

  group('a stack of toasts keeps to the segment its corner lies in', () {
    for (final vector in vectors) {
      for (final direction in w.TextDirection.values) {
        for (final location in ToastLocation.values) {
          testWidgets('${vector['name']}, ${direction.name}, '
              '${location.name}', (tester) async {
            _showFolds(tester, vector);
            final app = await _pumpApp(tester, direction);
            final toast = showToast(
              context: app,
              location: location,
              builder: (_, _) =>
                  const w.SizedBox(key: _content, width: 200, height: 48),
            );
            await tester.pumpAndSettle();

            final segment = _alignedSegment(
              vector,
              direction,
              location.alignment.resolve(direction),
            );
            final content = tester.getRect(find.byKey(_content));
            expect(
              _inside(content, segment),
              isTrue,
              reason: 'the toast ($content) lies inside its segment ($segment)',
            );

            toast.close();
            await tester.pumpAndSettle();
          });
        }
      }
    }
  });

  group('an anchored panel keeps to the segment its anchor is in', () {
    // A trigger beside the fold in each segment, and a panel wide and tall
    // enough to reach across the fold from there.
    const anchorSize = Size(40, 40);
    const panelSize = Size(280, 200);

    Rect anchorIn(Rect segment, Size viewport) {
      final centre = viewport.center(Offset.zero);
      // The point of the segment nearest the middle of the viewport, pulled
      // in so the trigger sits wholly inside the segment.
      final nearest = Offset(
        centre.dx.clamp(
          segment.left + anchorSize.width,
          segment.right - anchorSize.width,
        ),
        centre.dy.clamp(
          segment.top + anchorSize.height,
          segment.bottom - anchorSize.height,
        ),
      );

      return Rect.fromCenter(
        center: nearest,
        width: anchorSize.width,
        height: anchorSize.height,
      );
    }

    Future<Rect> openAt(WidgetTester tester, Rect anchor) async {
      final anchorKey = w.GlobalKey();
      await _pumpApp(
        tester,
        w.TextDirection.ltr,
        home: w.Stack(
          children: [
            w.Positioned.fromRect(
              rect: anchor,
              child: w.SizedBox(key: anchorKey),
            ),
          ],
        ),
      );
      final handle = const PopoverOverlayHandler().show<void>(
        context: anchorKey.currentContext!,
        alignment: Alignment.topCenter,
        anchorAlignment: Alignment.bottomCenter,
        modal: false,
        builder: (_) => w.SizedBox(
          key: _panel,
          width: panelSize.width,
          height: panelSize.height,
        ),
      );
      // Not `pumpAndSettle`: a panel that follows its anchor asks for a
      // frame on every frame. One frame lays it out; the second is past the
      // open animation.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final panel = tester.getRect(find.byKey(_panel));
      handle.dismissImmediately();
      await tester.pump();

      return panel;
    }

    for (final vector in split) {
      final segments = _segmentsOf(vector);
      for (var index = 0; index < segments.length; index++) {
        testWidgets('${vector['name']}, anchored in segment $index', (
          tester,
        ) async {
          _showFolds(tester, vector);
          final segment = segments[index];

          final panel = await openAt(
            tester,
            anchorIn(segment, _viewportOf(vector)),
          );

          expect(panel.size, panelSize);
          expect(
            _inside(panel, segment),
            isTrue,
            reason: 'the panel ($panel) lies inside segment $index ($segment)',
          );
        });
      }
    }

    testWidgets('across a fold that lies flat it is placed as on a screen '
        'with none', (tester) async {
      final flat = named('a fold, open flat');
      final viewport = _viewportOf(flat);
      // Beside the fold's line, so the panel lies across it.
      final anchor = Rect.fromCenter(
        center: viewport.center(Offset.zero),
        width: anchorSize.width,
        height: anchorSize.height,
      );

      _showFolds(tester, flat);
      final acrossFlatFold = await openAt(tester, anchor);
      tester.view.displayFeatures = const [];
      final withNoFold = await openAt(tester, anchor);

      expect(acrossFlatFold, withNoFold);
      expect(acrossFlatFold.left < 345 && acrossFlatFold.right > 345, isTrue);
    });
  });

  group('FoldSegment', () {
    // A folding phone held like a book: 951 × 669 with the strip the system
    // reserves from 455.5 to 495.5, and its controls down the right edge.
    const viewport = Size(951, 669);
    const strip = ui.DisplayFeature(
      bounds: Rect.fromLTWH(455.5, 0, 40, 669),
      type: ui.DisplayFeatureType.fold,
      state: ui.DisplayFeatureState.postureHalfOpened,
    );
    const controls = w.EdgeInsets.only(right: 84, bottom: 34);

    w.Widget under(
      Alignment alignment,
      void Function(w.BuildContext context) read, {
      List<ui.DisplayFeature> features = const [strip],
    }) => w.Directionality(
      textDirection: w.TextDirection.ltr,
      child: w.MediaQuery(
        data: w.MediaQueryData(
          size: viewport,
          padding: controls,
          viewPadding: controls,
          displayFeatures: features,
        ),
        child: FoldSegment(
          alignment: alignment,
          child: w.Builder(
            builder: (context) {
              read(context);

              return const w.SizedBox.expand(key: _content);
            },
          ),
        ),
      ),
    );

    testWidgets('lays its child out in the segment', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(under(Alignment.bottomLeft, (_) {}));
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(0, 0, 455.5, 669),
      );

      await tester.pumpWidget(under(Alignment.bottomRight, (_) {}));
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(495.5, 0, 455.5, 669),
      );
    });

    testWidgets('the insets below are the bars that border the segment', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      addTearDown(tester.view.reset);
      late w.EdgeInsets padding;

      // The controls are on the right edge: the left half does not meet
      // them, the right half does.
      await tester.pumpWidget(
        under(
          Alignment.bottomLeft,
          (context) => padding = w.MediaQuery.paddingOf(context),
        ),
      );
      expect(padding, const w.EdgeInsets.only(bottom: 34));

      await tester.pumpWidget(
        under(
          Alignment.bottomRight,
          (context) => padding = w.MediaQuery.paddingOf(context),
        ),
      );
      expect(padding, controls);
    });

    testWidgets('what is below reads no fold, so nothing is narrowed twice', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      addTearDown(tester.view.reset);
      late CoreFoldLayout layout;

      await tester.pumpWidget(
        under(
          Alignment.bottomLeft,
          (context) => layout = FoldScope.of(context),
        ),
      );

      expect(layout.isSplit, isFalse);
      expect(layout.folds, isEmpty);
    });

    testWidgets('is the whole viewport where nothing splits it', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      addTearDown(tester.view.reset);
      late w.EdgeInsets padding;

      await tester.pumpWidget(
        under(
          Alignment.bottomCenter,
          (context) => padding = w.MediaQuery.paddingOf(context),
          features: const [],
        ),
      );

      expect(
        tester.getRect(find.byKey(_content)),
        Offset.zero & viewport,
      );
      expect(padding, controls);
    });
  });

  // A layer is not always the viewport: an app's frame keeps its pages clear
  // of the device's controls, a navigator fills one pane, a device mockup
  // draws a screen inside the page. The segment is the viewport's; what a
  // layer keeps to is the part of it its own box covers.
  group('in a box that is not the viewport', () {
    // The folding phone again, half open as a book, and a frame that keeps
    // clear of a banner at the top and of the controls down the right edge.
    const viewport = Size(951, 669);
    const strip = ui.DisplayFeature(
      bounds: Rect.fromLTWH(455.5, 0, 40, 669),
      type: ui.DisplayFeatureType.fold,
      state: ui.DisplayFeatureState.postureHalfOpened,
    );
    const frame = w.EdgeInsets.only(top: 60, right: 84);
    const framed = Rect.fromLTRB(0, 60, 867, 669);
    const left = Rect.fromLTWH(0, 0, 455.5, 669);
    const right = Rect.fromLTWH(495.5, 0, 455.5, 669);

    void showPhone(WidgetTester tester) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport
        ..displayFeatures = const [strip];
      addTearDown(tester.view.reset);
    }

    w.Widget segmentIn(
      w.Widget Function(w.Widget child) box,
      Alignment alignment, {
      w.TextDirection direction = w.TextDirection.ltr,
      void Function(w.BuildContext context)? read,
    }) => w.Directionality(
      textDirection: direction,
      child: box(
        FoldSegment(
          alignment: alignment,
          child: w.Builder(
            builder: (context) {
              read?.call(context);

              return const w.SizedBox.expand(key: _content);
            },
          ),
        ),
      ),
    );

    w.Widget inFrame(w.Widget child) => w.Padding(padding: frame, child: child);

    testWidgets('a layer keeps to the part of the segment its box covers', (
      tester,
    ) async {
      showPhone(tester);
      for (final (alignment, segment) in [
        (Alignment.bottomLeft, left),
        (Alignment.bottomRight, right),
        (Alignment.topLeft, left),
        (Alignment.topRight, right),
      ]) {
        await tester.pumpWidget(segmentIn(inFrame, alignment));
        // Where a box lies is known after its first layout; the frame after
        // has it right.
        await tester.pump();

        expect(
          tester.getRect(find.byKey(_content)),
          framed.intersect(segment),
          reason: '$alignment',
        );
        // Nothing is left to set right.
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
    });

    testWidgets("the middle is the box's own, whichever way the page reads", (
      tester,
    ) async {
      showPhone(tester);
      // The frame's middle is at 433.5 — left of the fold, in the left half.
      // The viewport's is on the fold, where the reading direction decides.
      for (final direction in w.TextDirection.values) {
        await tester.pumpWidget(
          segmentIn(inFrame, Alignment.bottomCenter, direction: direction),
        );
        await tester.pump();

        expect(
          tester.getRect(find.byKey(_content)),
          framed.intersect(left),
          reason: direction.name,
        );
      }
    });

    testWidgets('a box in one segment is left as it is, and told so', (
      tester,
    ) async {
      showPhone(tester);
      const pane = Rect.fromLTWH(520, 40, 300, 400);
      late CoreFoldLayout below;
      late w.EdgeInsets padding;

      await tester.pumpWidget(
        w.MediaQuery(
          data: w.MediaQueryData.fromView(tester.view).copyWith(
            padding: const w.EdgeInsets.only(right: 84, bottom: 34),
          ),
          child: segmentIn(
            (child) => w.Stack(
              children: [w.Positioned.fromRect(rect: pane, child: child)],
            ),
            Alignment.bottomLeft,
            read: (context) {
              below = FoldScope.of(context);
              padding = w.MediaQuery.paddingOf(context);
            },
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byKey(_content)), pane);
      expect(below.isSplit, isFalse);
      // The right half meets the controls and the bottom bar.
      expect(padding, const w.EdgeInsets.only(right: 84, bottom: 34));
    });

    testWidgets('a box the fold runs through the middle of keeps to the '
        'reading start', (tester) async {
      showPhone(tester);
      // 120 wide about the fold's middle: 40 of each half.
      const astride = Rect.fromLTWH(415.5, 100, 120, 200);
      w.Widget at(w.Widget child) => w.Stack(
        children: [w.Positioned.fromRect(rect: astride, child: child)],
      );

      await tester.pumpWidget(segmentIn(at, Alignment.center));
      await tester.pump();
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(415.5, 100, 40, 200),
      );

      await tester.pumpWidget(
        segmentIn(at, Alignment.center, direction: w.TextDirection.rtl),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTWH(495.5, 100, 40, 200),
      );
    });

    testWidgets('a box the fold does not reach is not narrowed to nothing', (
      tester,
    ) async {
      showPhone(tester);
      // Inside the strip the system reserves: no segment covers any of it.
      const inStrip = Rect.fromLTWH(460, 100, 30, 200);

      await tester.pumpWidget(
        segmentIn(
          (child) => w.Stack(
            children: [w.Positioned.fromRect(rect: inStrip, child: child)],
          ),
          Alignment.center,
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byKey(_content)), inStrip);
    });

    testWidgets('a box that moves when the frame changes follows', (
      tester,
    ) async {
      showPhone(tester);
      await tester.pumpWidget(segmentIn(inFrame, Alignment.bottomRight));
      await tester.pump();
      expect(
        tester.getRect(find.byKey(_content)),
        framed.intersect(right),
      );

      // The controls move to the left edge, as they do beside another app.
      const turned = w.EdgeInsets.only(top: 60, left: 84);
      await tester.pumpWidget(
        segmentIn(
          (child) => w.Padding(padding: turned, child: child),
          Alignment.bottomLeft,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(_content)),
        const Rect.fromLTRB(84, 60, 455.5, 669),
      );
    });

    testWidgets('a box sized by its child is set right a few times, then '
        'left', (tester) async {
      showPhone(tester);
      // Nothing gives this box a size but its child and the padding the
      // segment adds, and its parent centres it: each time it is set right
      // the padding moves it, halving what is left to correct without ever
      // being done.
      await tester.pumpWidget(
        const w.Directionality(
          textDirection: w.TextDirection.ltr,
          child: w.Center(
            child: FoldSegment(
              alignment: Alignment.center,
              child: w.SizedBox(key: _content, width: 100, height: 100),
            ),
          ),
        ),
      );

      var frames = 0;
      while (tester.binding.hasScheduledFrame) {
        await tester.pump();
        frames += 1;
        expect(frames, lessThan(10), reason: 'it stops asking for frames');
      }
      expect(frames, 3);
      // Wherever it stopped, the child lies in one half.
      expect(
        _inside(tester.getRect(find.byKey(_content)), left),
        isTrue,
        reason: '${tester.getRect(find.byKey(_content))}',
      );
    });

    testWidgets('where nothing splits the viewport nothing is measured', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(segmentIn(inFrame, Alignment.bottomRight));

      expect(tester.getRect(find.byKey(_content)), framed);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    for (final direction in w.TextDirection.values) {
      for (final location in ToastLocation.values) {
        testWidgets('toasts in a framed layer, ${direction.name}, '
            '${location.name}', (tester) async {
          showPhone(tester);
          late w.BuildContext layer;
          await _pumpApp(
            tester,
            direction,
            home: w.Padding(
              padding: frame,
              child: ToastLayer(
                child: w.Builder(
                  builder: (context) {
                    layer = context;

                    return const w.SizedBox.expand();
                  },
                ),
              ),
            ),
          );
          final toast = showToast(
            context: layer,
            location: location,
            builder: (_, _) =>
                const w.SizedBox(key: _content, width: 200, height: 48),
          );
          await tester.pumpAndSettle();

          // The frame's middle is in the left half, so the centred stacks
          // open there in both directions.
          final segment = location.alignment.resolve(direction).x > 0
              ? right
              : left;
          final content = tester.getRect(find.byKey(_content));
          expect(
            _inside(content, framed.intersect(segment)),
            isTrue,
            reason:
                'the toast ($content) lies inside its part of the frame '
                '(${framed.intersect(segment)})',
          );

          toast.close();
          await tester.pumpAndSettle();
        });
      }
    }

    for (final side in CoreDrawerSide.values) {
      testWidgets("a drawer on a framed navigator's page, ${side.name}", (
        tester,
      ) async {
        showPhone(tester);
        late w.BuildContext page;
        await _pumpApp(
          tester,
          w.TextDirection.ltr,
          home: w.Padding(
            padding: frame,
            child: w.Navigator(
              onGenerateRoute: (settings) => w.PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (context, _, _) {
                  page = context;

                  return const w.SizedBox.expand();
                },
              ),
            ),
          ),
        );
        unawaited(
          openDrawer<void>(
            context: page,
            side: side,
            transformBackdrop: false,
            useRootNavigator: false,
            builder: (_) => Drawer(
              side: side,
              content: const w.SizedBox(key: _content, width: 80, height: 80),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The frame's left, top and bottom edges have their middle in the
        // left half; its right edge is in the right half.
        final part = framed.intersect(
          side == CoreDrawerSide.right ? right : left,
        );
        final panel = tester.getRect(find.byType(Drawer));
        expect(
          _inside(panel, part),
          isTrue,
          reason:
              'the panel ($panel) lies inside its part of the frame ($part)',
        );
        final (docked, edge) = switch (side) {
          CoreDrawerSide.left => (panel.left, part.left),
          CoreDrawerSide.right => (panel.right, part.right),
          CoreDrawerSide.top => (panel.top, part.top),
          CoreDrawerSide.bottom => (panel.bottom, part.bottom),
        };
        expect(docked, moreOrLessEquals(edge, epsilon: 0.01));
      });
    }

    group('a screen drawn inside the page', () {
      // A device mockup: a 400 × 300 screen at (100, 50) of a larger page,
      // with a media query of its own and a fold down its middle. The
      // segments are the screen's, measured from the screen's corner.
      const screen = Size(400, 300);
      const origin = Offset(100, 50);
      const screenFold = ui.DisplayFeature(
        bounds: Rect.fromLTWH(200, 0, 0, 300),
        type: ui.DisplayFeatureType.fold,
        state: ui.DisplayFeatureState.postureHalfOpened,
      );

      w.Widget onScreen(w.Widget child, {double scale = 1}) => w.Directionality(
        textDirection: w.TextDirection.ltr,
        child: w.Align(
          alignment: Alignment.topLeft,
          child: w.Padding(
            padding: w.EdgeInsets.only(left: origin.dx, top: origin.dy),
            child: w.Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: w.SizedBox.fromSize(
                size: screen,
                child: w.MediaQuery(
                  data: const w.MediaQueryData(
                    size: screen,
                    displayFeatures: [screenFold],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );

      testWidgets('a layer keeps to the half of the screen', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(1000, 700);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          onScreen(
            const FoldSegment(
              alignment: Alignment.bottomRight,
              child: w.SizedBox.expand(key: _content),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.getRect(find.byKey(_content)),
          const Rect.fromLTWH(300, 50, 200, 300),
        );

        // Inside a frame of the screen's own, 20 clear of its left edge.
        await tester.pumpWidget(
          onScreen(
            const w.Padding(
              padding: w.EdgeInsets.only(left: 20),
              child: FoldSegment(
                alignment: Alignment.bottomLeft,
                child: w.SizedBox.expand(key: _content),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.getRect(find.byKey(_content)),
          const Rect.fromLTWH(120, 50, 180, 300),
        );
      });

      testWidgets('drawn at half size, it is still the screen that is '
          'measured', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(1000, 700);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          onScreen(
            scale: 0.5,
            const w.Padding(
              padding: w.EdgeInsets.only(top: 40),
              child: FoldSegment(
                alignment: Alignment.bottomRight,
                child: w.SizedBox.expand(key: _content),
              ),
            ),
          ),
        );
        await tester.pump();

        // The right half of the screen below its 40 frame, at half size.
        expect(
          tester.getRect(find.byKey(_content)),
          const Rect.fromLTWH(200, 70, 100, 130),
        );
      });

      testWidgets('an anchored panel keeps to the half of the screen its '
          'anchor is in', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(1000, 700);
        addTearDown(tester.view.reset);
        const panelSize = Size(160, 80);

        Future<Rect> openAt(Rect anchor) async {
          final anchorKey = w.GlobalKey();
          await tester.pumpWidget(
            CoUIApp(
              theme: ThemeData.fromCore(CoreThemePresets.light),
              home: onScreen(
                // The screen has an overlay of its own, as an app shown in
                // a mockup has. Keyed by the anchor: an overlay takes its
                // first entries once.
                w.Overlay(
                  key: w.ValueKey(anchor),
                  initialEntries: [
                    w.OverlayEntry(
                      builder: (_) => w.Stack(
                        children: [
                          w.Positioned.fromRect(
                            rect: anchor,
                            child: w.SizedBox(key: anchorKey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          final handle = const PopoverOverlayHandler().show<void>(
            context: anchorKey.currentContext!,
            alignment: Alignment.topCenter,
            anchorAlignment: Alignment.bottomCenter,
            modal: false,
            // Into the screen's overlay. The page's own overlay is outside
            // the screen's media query, and reads the page's folds.
            rootOverlay: false,
            builder: (_) => w.SizedBox(
              key: _panel,
              width: panelSize.width,
              height: panelSize.height,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          final panel = tester.getRect(find.byKey(_panel));
          handle.dismissImmediately();
          await tester.pump();

          return panel;
        }

        // Beside the fold on either side: centred under its anchor the
        // panel would lie across it.
        final inLeft = await openAt(const Rect.fromLTWH(150, 40, 40, 40));
        expect(inLeft.size, panelSize);
        expect(
          _inside(inLeft, origin & const Size(200, 300)),
          isTrue,
          reason: 'the panel ($inLeft) lies in the left half of the screen',
        );

        final inRight = await openAt(const Rect.fromLTWH(210, 40, 40, 40));
        expect(inRight.size, panelSize);
        expect(
          _inside(
            inRight,
            Rect.fromLTWH(origin.dx + 200, origin.dy, 200, 300),
          ),
          isTrue,
          reason: 'the panel ($inRight) lies in the right half of the screen',
        );
      });
    });
  });
}
