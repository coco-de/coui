// Pins that a refracting surface is told where it is at the moment the scene
// is built, so a move that never repainted it cannot leave the bend behind.
//
// The refraction program does not run in the surface's own space: it is
// handed the surface's rectangle in the backdrop's pixels, as uniforms
// (`surface_backdrop.dart`). Flutter reuses a repaint boundary's layers
// across a pure translation — a list scrolls, a route slides, a parent moves
// its child by layout — and a layer that is retained keeps the filter it was
// built with. A filter holding the old rectangle bends the old place: a
// stale band for as long as the layer stays retained.
//
// What prevents it is one line: the backdrop layer reports
// `alwaysNeedsAddToScene`, which keeps it out of the retained-layer cache,
// so every scene asks for the rectangle again. Nothing else fails when that
// line is flipped — the geometry test covers the arithmetic, the device
// probe covers a surface at rest — so a change to it passes the whole suite
// and ships a band that lags every scroll.
//
// What this file observes is the rectangle the **last scene build** resolved
// (`debugResolvedRect`) and how many scene builds resolved it
// (`debugResolveCount`). The shader itself cannot run under `flutter_tester`
// (its `ImageFilter.shader` is an unconditional throw), so the uniform write
// is not seen; the rectangle that would be written is, and it is computed by
// the same call, before the capability gate.
//
// It also holds that answering the move costs no frame of its own. A
// correction deferred to "the next frame" would be a frame the move did not
// need, and it would still show one frame late; the comparison below is
// against the same move over a box that paints nothing, because a scrolling
// list asks for frames of its own that the surface must not add to. For the
// same reason the list scenario is the weakest on this point: a frame the
// list already asked for absorbs one the surface might add, so only
// `debugNeedsPaint` sees a deferred repaint there. The layout and transform
// scenarios are where an added frame is visible.
//
// Mutation check (run, and recorded in the change that added this file):
//   * `_SurfaceBackdropLayer.alwaysNeedsAddToScene` => false: every scenario
//     fails on the rectangle (the stale one is the one before the move).
//   * a moved rectangle calls `markNeedsPaint()` from the resolve: every
//     scenario fails on `debugNeedsPaint`.
//   * a moved rectangle calls `scheduleFrame()` from the resolve: the three
//     non-list scenarios fail on the frame count.
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ratio the surface under test is told, deliberately not the test
/// view's own so a rectangle scaled by the wrong one cannot match.
const double _kRatio = 2;

const Size _kGlass = Size(80, 40);

/// A rectangle of the glass's size at [topLeft] in the root's logical
/// pixels, as the backdrop texture measures it.
Rect _inBackdropPixels(Offset topLeft) => Rect.fromLTWH(
  topLeft.dx * _kRatio,
  topLeft.dy * _kRatio,
  _kGlass.width * _kRatio,
  _kGlass.height * _kRatio,
);

Widget _glass(FragmentProgram program) => SurfaceBackdrop(
  material: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
  program: program,
  refraction: const CoreSurfaceRefraction(bezel: 0.2, dispersion: 0.5),
  cornerRadius: 12,
  devicePixelRatio: _kRatio,
  child: SizedBox.fromSize(size: _kGlass),
);

/// One way to move a child without rebuilding it, with the child's
/// top-left (root logical pixels) before and after.
///
/// A fresh one is made per run: its notifier or controller belongs to the
/// tree it was mounted in.
class _Move {
  _Move({
    required this.host,
    required this.move,
    required this.from,
    required this.to,
  });

  /// Wraps the child. The child is built once, outside, so the move is a
  /// layout or paint change only — `updateRenderObject` never runs, which
  /// is what makes a stale rectangle possible at all.
  final Widget Function(Widget child) host;

  final void Function() move;
  final Offset from;
  final Offset to;
}

/// Counts the frames the binding draws.
class _Frames {
  _Frames(WidgetTester tester) {
    tester.binding.addPersistentFrameCallback((_) => count++);
  }

  int count = 0;
}

/// What carrying [move] cost: whether a frame was still wanted right after
/// the move's own, and how many frames were drawn until the binding went
/// quiet.
Future<({bool stillScheduled, int framesDrawn})> _costOf(
  WidgetTester tester,
  _Frames frames,
  void Function() move,
) async {
  final before = frames.count;
  move();
  await tester.pump();
  final stillScheduled = tester.binding.hasScheduledFrame;
  await tester.pumpAndSettle();

  return (stillScheduled: stillScheduled, framesDrawn: frames.count - before);
}

/// Mounts the child from [make] around the surface, applies its move, and
/// holds what the scene build resolved and what the move cost.
Future<void> _followsTheMove(WidgetTester tester, _Move Function() make) async {
  final program = await FragmentProgram.fromAsset(
    'shaders/surface_refraction.frag',
  );
  final frames = _Frames(tester);

  // The same move over a box that paints nothing: the frames the framework
  // itself needs to carry it. A scrolling list asks for one of its own.
  final control = make();
  await tester.pumpWidget(control.host(SizedBox.fromSize(size: _kGlass)));
  await tester.pumpAndSettle();
  final withoutSurface = await _costOf(tester, frames, control.move);
  await tester.pumpWidget(const SizedBox.shrink());

  final run = make();
  await tester.pumpWidget(run.host(_glass(program)));
  await tester.pumpAndSettle();
  final render = tester.renderObject<RenderSurfaceBackdrop>(
    find.byType(SurfaceBackdrop),
  );
  expect(
    render.debugResolvedRect,
    _inBackdropPixels(run.from),
    reason: 'baseline: the first scene resolved the starting rectangle',
  );
  final resolvedBefore = render.debugResolveCount;
  final framesBefore = frames.count;

  run.move();
  await tester.pump();
  final stillScheduled = tester.binding.hasScheduledFrame;

  expect(
    render.debugResolvedRect,
    _inBackdropPixels(run.to),
    reason: 'the rectangle follows a move that did not repaint the surface',
  );
  expect(
    render.debugResolveCount,
    resolvedBefore + 1,
    reason: 'one scene, one resolve — the layer was re-added, not retained',
  );
  expect(
    render.debugNeedsPaint,
    isFalse,
    reason: 'the surface asked for nothing to be redone to catch up',
  );

  expect(
    stillScheduled,
    withoutSurface.stillScheduled,
    reason: 'a move is answered inside the frame that carried it',
  );

  await tester.pumpAndSettle();
  expect(
    frames.count - framesBefore,
    withoutSurface.framesDrawn,
    reason:
        'answering the move cost no frame beyond the ones the same move '
        'needs over a box that paints nothing',
  );
  expect(render.debugResolvedRect, _inBackdropPixels(run.to));
}

void main() {
  group('a surface is told where it is when the scene is built', () {
    testWidgets('after a layout move with no repaint boundary', (
      tester,
    ) async {
      await _followsTheMove(tester, () {
        final left = ValueNotifier<double>(10);
        addTearDown(left.dispose);

        return _Move(
          host: (child) => ValueListenableBuilder<double>(
            valueListenable: left,
            child: child,
            builder: (context, x, child) => Stack(
              textDirection: TextDirection.ltr,
              children: [Positioned(left: x, top: 20, child: child!)],
            ),
          ),
          move: () => left.value = 57,
          from: const Offset(10, 20),
          to: const Offset(57, 20),
        );
      });
    });

    testWidgets('after a layout move with a repaint boundary in between', (
      tester,
    ) async {
      // The case Flutter optimises: the boundary does not repaint, its
      // layers are reused at a new offset, and everything inside it — this
      // surface's layer included — is only re-added if it insists on it.
      await _followsTheMove(tester, () {
        final left = ValueNotifier<double>(10);
        addTearDown(left.dispose);

        return _Move(
          host: (child) => ValueListenableBuilder<double>(
            valueListenable: left,
            child: RepaintBoundary(child: child),
            builder: (context, x, child) => Stack(
              textDirection: TextDirection.ltr,
              children: [Positioned(left: x, top: 20, child: child!)],
            ),
          ),
          move: () => left.value = 57,
          from: const Offset(10, 20),
          to: const Offset(57, 20),
        );
      });
    });

    testWidgets('after a Transform.translate ancestor moves it', (
      tester,
    ) async {
      // A paint-time move: nothing is laid out again, the surface's own
      // offset in its parent is unchanged, and only the ancestor's matrix
      // differs — which `getTransformTo` has to be asked about afresh.
      await _followsTheMove(tester, () {
        final dx = ValueNotifier<double>(10);
        addTearDown(dx.dispose);

        return _Move(
          host: (child) => Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder<double>(
              valueListenable: dx,
              child: RepaintBoundary(child: child),
              builder: (context, x, child) =>
                  Transform.translate(offset: Offset(x, 20), child: child),
            ),
          ),
          move: () => dx.value = 57,
          from: const Offset(10, 20),
          to: const Offset(57, 20),
        );
      });
    });

    testWidgets('after a list scrolls under it', (tester) async {
      // The everyday case. `ListView` wraps each child in a repaint
      // boundary, and a scroll moves the boundary's layer without
      // repainting what is inside.
      await _followsTheMove(tester, () {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);

        return _Move(
          host: (child) => Directionality(
            textDirection: TextDirection.ltr,
            child: ListView(
              controller: scroll,
              children: [
                const SizedBox(height: 300),
                Align(alignment: Alignment.centerLeft, child: child),
                const SizedBox(height: 2000),
              ],
            ),
          ),
          move: () => scroll.jumpTo(57),
          from: const Offset(0, 300),
          to: const Offset(0, 243),
        );
      });
    });
  });
}
