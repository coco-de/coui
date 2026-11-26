// The clip's behaviour over time, and the three ways it must refuse to run.
//
// The shape and the interpolation are Core's and are held by Core's tests.
// What this file holds is the widget's contract: that it stops when the
// spring settles, that it never clips a panel away, and that a
// reduced-motion request removes the animation rather than accelerating it.
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _kAnchor = CoreMorphBlob(
  centerX: 168,
  centerY: 218,
  halfWidth: 48,
  halfHeight: 18,
  radius: 8,
);
const _kPanel = CoreMorphBlob(
  centerX: 170,
  centerY: 110,
  halfWidth: 110,
  halfHeight: 70,
  radius: 16,
);

/// A body nobody has measured yet.
const _kUnmeasured = CoreMorphBlob(
  centerX: 0,
  centerY: 0,
  halfWidth: 0,
  halfHeight: 0,
);

/// A child that reports being built from scratch.
///
/// Deliberately **not** keyed with a `GlobalKey`: a global key survives
/// reparenting by design, so a probe holding one cannot see this failure at
/// all. The first version of this test used one and passed against the
/// broken widget.
class _Probe extends StatefulWidget {
  const _Probe({required this.onInit, super.key});

  final void Function() onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0xFF203040));
}

Widget _harness({
  bool reduceMotion = false,
  CoreMorphBlob anchor = _kAnchor,
  CoreMorphBlob panel = _kPanel,
  Widget child = const ColoredBox(color: Color(0xFF203040)),
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: 320,
        height: 260,
        child: LiquidMorphClip(
          anchor: anchor,
          panel: panel,
          child: child,
        ),
      ),
    ),
  ),
);

/// Whether a clip is currently carving the child.
///
/// A `ClipPath` is always present — its element type has to stay stable or
/// the subtree it wraps remounts. What varies is whether it was given a
/// clipper, so that is what "carving" means here.
bool _isClipping(WidgetTester tester) =>
    tester.widget<ClipPath>(find.byType(ClipPath)).clipper != null;

void main() {
  group('the clip runs while the spring does', () {
    testWidgets('it carves from the very first frame', (tester) async {
      // The regression this pins shipped once: the clip was gated on a
      // curve-derived "is anything happening yet", and that value was
      // exactly zero at `t = 0`. So the opening frame rendered the panel
      // **unclipped at full size** and the second frame snapped it small —
      // every morph began with a flash of its own destination.
      //
      // Pumping past the first frame would hide it, which is what the
      // original version of this test did.
      await tester.pumpWidget(_harness());

      expect(_isClipping(tester), isTrue);
    });

    testWidgets('and keeps carving as it runs', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 80));

      expect(_isClipping(tester), isTrue);
    });

    testWidgets('and stops once the spring settles', (tester) async {
      // Left ticking, this would trace an outline every frame for the rest
      // of the panel's life — for a shape that stopped changing, on a
      // surface that is probably also compositing a blur.
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 80));
      expect(_isClipping(tester), isTrue, reason: 'never started');

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(_isClipping(tester), isFalse);
    });
  });

  group('it refuses to run rather than running badly', () {
    testWidgets('a reduced-motion request removes it, not speeds it up', (
      tester,
    ) async {
      // A morph is transition-tier motion, and this kit suppresses that
      // tier to zero. Someone who asked for less motion is asking for
      // none — a faster spring is still a spring.
      await tester.pumpWidget(_harness(reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 80));

      expect(_isClipping(tester), isFalse);
      expect(find.byType(ColoredBox), findsOneWidget);
    });

    testWidgets('and an unmeasured body passes the child through', (
      tester,
    ) async {
      // Measured, and it is the sharpest hazard here: two zero-sized
      // bodies do **not** trace nothing. The smooth union pulls by `k / 4`
      // even where both fields are a single point, so a caller that has
      // not measured its trigger yet would have its panel carved into a
      // dot. "No effect yet" and "the panel disappeared" have to be
      // different states.
      await tester.pumpWidget(
        _harness(anchor: _kUnmeasured, panel: _kUnmeasured),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(_isClipping(tester), isFalse);
      expect(find.byType(ColoredBox), findsOneWidget);
    });

    testWidgets('and the child survives every frame of the morph', (
      tester,
    ) async {
      // The assertion that would catch a clip that carved the panel away
      // mid-flight — a state no single-instant check would see.
      await tester.pumpWidget(_harness());

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        expect(
          find.byType(ColoredBox),
          findsOneWidget,
          reason: 'the panel vanished at frame $i',
        );
      }
    });
  });

  group('it does not remount what it wraps', () {
    testWidgets('the panel is not rebuilt from scratch at settle', (
      tester,
    ) async {
      // The sharpest bug in this widget, and it has no visual symptom.
      //
      // Returning `ClipPath(child: child)` while morphing and a bare
      // `child` afterwards changes the widget's runtimeType at that slot,
      // so `Widget.canUpdate` fails, the element is deactivated, and the
      // **whole panel subtree is rebuilt from scratch** — at settle, which
      // is most of a second after opening, while the user is already
      // typing into it. A popover with a text field loses focus; a
      // scrolled list loses its position. It reads as a flaky focus bug
      // three files away from its cause.
      var mounts = 0;
      await tester.pumpWidget(_harness(child: _Probe(onInit: () => mounts++)));
      await tester.pump(const Duration(milliseconds: 80));
      expect(_isClipping(tester), isTrue, reason: 'never morphed');
      expect(mounts, 1, reason: 'the panel was not mounted once to begin with');

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(
        mounts,
        1,
        reason: 'the panel was rebuilt from scratch when the clip stopped',
      );
    });

    testWidgets('and across a reduced-motion pass-through', (tester) async {
      // The same swap, reached by the other door.
      var mounts = 0;
      await tester.pumpWidget(
        _harness(reduceMotion: true, child: _Probe(onInit: () => mounts++)),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(mounts, 1);
    });
  });

  group('it owns the clock, not the position', () {
    testWidgets('the child keeps the size its layout gave it', (tester) async {
      // The overlay position engine decides where a panel is. If this
      // widget also moved it, two things would be in charge of one
      // position and they would disagree during the animation.
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        tester.getSize(find.byType(ColoredBox)),
        const Size(320, 260),
      );
    });
  });

  group('the clip reaches the pixels', () {
    // The one thing every earlier test in this file could not see: a
    // `ClipPath` whose behaviour is `Clip.none` paints its child straight
    // through, clipper or no clipper. Reading the clipper back was green
    // while nothing on screen was carved. So this reads a pixel.
    testWidgets('a fill outside the silhouette is carved away in flight', (
      tester,
    ) async {
      final key = GlobalKey();
      // Two small bodies far apart inside a 200×100 fill; the corner of
      // the fill is nowhere near either and must be transparent mid-air.
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 200,
              height: 100,
              child: LiquidMorphClip(
                anchor: const CoreMorphBlob(
                  centerX: 30,
                  centerY: 50,
                  halfWidth: 12,
                  halfHeight: 12,
                  radius: 12,
                ),
                panel: const CoreMorphBlob(
                  centerX: 170,
                  centerY: 50,
                  halfWidth: 12,
                  halfHeight: 12,
                  radius: 12,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFFF0000)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      final bytes = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        image.dispose();

        return data;
      });
      int alphaAt(int x, int y) => bytes!.getUint8((((y * 200) + x) * 4) + 3);

      expect(alphaAt(2, 2), 0, reason: 'the fill s corner survived the clip');
      expect(alphaAt(30, 50), 255, reason: 'the anchor body was carved away');
    });
  });
}
