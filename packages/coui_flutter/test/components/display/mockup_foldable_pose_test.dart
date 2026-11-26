// MockupFoldable — where each part of the device is painted.
//
// The poses are the table the Core rules and the Web component read too
// (`coui_core/test/fixtures/mockup_fold_vectors.json`): every corner expected
// here is the table's, derived there with plain trigonometry, and what is
// read back is what the widget lays out, hands the canvas and leaves in the
// pixels. A fix made on one platform alone fails on the other's copy of this
// test.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mockup_foldable_harness.dart';

/// A corner may differ from the table by rounding only: the table keeps six
/// decimals, and a render transform is single precision in places.
const double _kCornerTolerance = 1e-3;

/// A pixel edge may differ from the table by the pixel it falls in and the
/// one anti-aliased beside it.
const double _kPixelTolerance = 1.5;

typedef _Call = ({Symbol method, List<dynamic> arguments});

/// Everything the render object under [finder] hands the canvas, in order.
List<_Call> _callsOf(Finder finder) {
  final calls = <_Call>[];
  expect(
    finder,
    paints..everything((method, arguments) {
      calls.add((method: method, arguments: arguments));

      return true;
    }),
  );

  return calls;
}

void _expectCorners(List<Offset> drawn, List<Offset> table, String what) {
  final misses = [
    for (var i = 0; i < table.length; i++)
      if ((drawn[i] - table[i]).distance > _kCornerTolerance)
        '$what corner $i: drawn ${drawn[i]}, table ${table[i]}',
  ];
  expect(misses, isEmpty, reason: misses.join('\n'));
}

/// A solid screen whose colour its own state decides — changed without the
/// foldable being rebuilt.
class _Lamp extends StatefulWidget {
  const _Lamp({super.key});

  @override
  State<_Lamp> createState() => _LampState();
}

class _LampState extends State<_Lamp> {
  static const Color off = Color(0xFFFF0000);
  static const Color on = Color(0xFF0000FF);

  bool lit = false;

  void light() => setState(() => lit = true);

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: lit ? on : off, child: const SizedBox.expand());
}

void main() {
  final table = FoldTable.read();

  Future<void> pumpAt(
    WidgetTester tester,
    double angle, {
    Widget child = const SizedBox.expand(),
    GlobalKey? boundary,
    CoreMockupFoldableStyle? style,
  }) async {
    await tester.pumpWidget(
      foldableApp(
        MockupFoldable(
          foldAngle: angle,
          width: table.width,
          // Nothing of the device's own over the screen: what the screen
          // shows is the child, the whole of it.
          showCamera: false,
          showStatus: false,
          mockupFoldableStyle: style ?? table.style,
          child: child,
        ),
        boundary: boundary,
      ),
    );
    final stage = stageOf(tester).size;
    expect(stage.width, table.width);
    expect(
      stage.height,
      closeTo(table.height, 1e-9),
      reason: 'the device on screen is not the table device',
    );
  }

  test('the table covers shut, half open and flat', () {
    final angles = [for (final vector in table.vectors) vector.angle];

    expect(
      angles,
      containsAll([
        CoreMockupFold.closed,
        CoreMockupFold.halfOpen,
        CoreMockupFold.flat,
      ]),
    );
  });

  test('an edge box runs from the slab face the table says it does', () {
    // What `MockupFoldable` cuts an edge's ends by: the left slab's edge
    // starts at its cover and ends at its inner face, the right slab's
    // starts at its inner face.
    for (final vector in table.vectors) {
      final parts = vector.parts;
      for (final (edge, face, edgeCorner, faceCorner) in const [
        ('edgeLeft', 'cover', 0, 1),
        ('edgeLeft', 'innerLeft', 1, 0),
        ('edgeRight', 'innerRight', 0, 1),
      ]) {
        expect(
          (parts[edge]!.corners[edgeCorner] - parts[face]!.corners[faceCorner])
              .distance,
          lessThan(_kCornerTolerance),
          reason: '${vector.angle}°: $edge meets $face',
        );
      }
    }
  });

  group('MockupFoldable — the cover and the edges', () {
    for (final vector in table.vectors) {
      testWidgets('at ${vector.angle}° — each is drawn where the table says, '
          'and not at all where the table hides it', (tester) async {
        await pumpAt(tester, vector.angle);
        final stage = stageOf(tester);
        final boxes = {
          'cover': (kCoverPart, faceOf(CoreMockupDevice.phone)),
          'edgeLeft': (kEdgeLeftPart, edgeBox(kEdgeLeftPart)),
          'edgeRight': (kEdgeRightPart, edgeBox(kEdgeRightPart)),
        };

        for (final MapEntry(key: name, value: (part, box)) in boxes.entries) {
          final stated = vector.parts[name]!;
          expect(
            find.byKey(part),
            stated.visible ? findsOneWidget : findsNothing,
            reason: name,
          );
          if (!stated.visible) continue;

          _expectCorners(
            cornersOn(stage, tester.renderObject<RenderBox>(box)),
            stated.corners,
            name,
          );
        }
      });
    }
  });

  group('MockupFoldable — how the edges end', () {
    test('the table states a cut for an edge wherever it draws one', () {
      // The table's corners are circles, as a device style states them.
      expect(table.innerCorner.x, table.innerCorner.y);
      expect(table.coverCorner.x, table.coverCorner.y);
      expect(table.coverCorner, isNot(table.innerCorner));
      for (final vector in table.vectors) {
        expect(
          vector.edgeCuts['right'] != null,
          vector.parts['edgeRight']!.visible,
          reason: '${vector.angle}° right',
        );
        expect(
          vector.edgeCuts['left'] != null,
          vector.parts['edgeLeft']!.visible,
          reason: '${vector.angle}° left',
        );
      }
    });

    for (final vector in table.vectors) {
      if (vector.edgeCuts.values.every((cut) => cut == null)) continue;

      testWidgets('at ${vector.angle}° — each edge is the shape the table '
          'cuts it to', (tester) async {
        await pumpAt(
          tester,
          vector.angle,
          style: table.styleWithTableCorners,
        );

        for (final (name, part) in const [
          ('right', kEdgeRightPart),
          ('left', kEdgeLeftPart),
        ]) {
          final cut = vector.edgeCuts[name];
          if (cut == null) {
            expect(find.byKey(part), findsNothing, reason: name);
            continue;
          }
          final box = tester.getSize(edgeBox(part));
          expect(box.width, table.thickness, reason: name);

          final shapes = [
            for (final call in _callsOf(edgeBox(part)))
              if (call.method == #drawRRect) call.arguments.first as RRect,
          ];
          expect(shapes, hasLength(1), reason: name);
          final shape = shapes.single;
          final (
            outlineTop,
            outlineBottom,
            innerTop,
            innerBottom,
          ) = cut.outlineAtEnd
              ? (
                  shape.trRadius,
                  shape.brRadius,
                  shape.tlRadius,
                  shape.blRadius,
                )
              : (
                  shape.tlRadius,
                  shape.blRadius,
                  shape.trRadius,
                  shape.brRadius,
                );

          // A cut can be many times the strip: within a part in a thousand
          // of what the table states.
          for (final (end, drawn, stated) in [
            ('top', outlineTop, cut.top),
            ('bottom', outlineBottom, cut.bottom),
          ]) {
            expect(
              drawn.x,
              closeTo(stated.x, _kCornerTolerance * math.max(1, stated.x)),
              reason: '$name $end across',
            );
            expect(drawn.y, closeTo(stated.y, 1e-9), reason: '$name $end');
          }
          // The side away from the outline is square …
          expect(innerTop, Radius.zero, reason: name);
          expect(innerBottom, Radius.zero, reason: name);
          // … and the shape is the box, widened from the outline side as
          // far as its wider corner reaches.
          final reach = [
            table.thickness,
            cut.top.x,
            cut.bottom.x,
          ].reduce(math.max);
          expect(
            shape.width,
            closeTo(reach, _kCornerTolerance * math.max(1, reach)),
            reason: name,
          );
          expect(
            cut.outlineAtEnd ? shape.right : shape.left,
            cut.outlineAtEnd ? table.thickness : 0,
            reason: name,
          );
          expect(shape.top, 0, reason: name);
          expect(shape.height, closeTo(table.height, 1e-9), reason: name);
        }
      });
    }
  });

  group('MockupFoldable — the inner screen', () {
    for (final vector in table.vectors) {
      testWidgets('at ${vector.angle}° — its halves are painted where the '
          'table says', (tester) async {
        await pumpAt(tester, vector.angle);
        final stage = stageOf(tester);
        final still = tester.renderObject<RenderBox>(
          find.byType(SnapshotWidget),
        );
        final calls = _callsOf(find.byType(SnapshotWidget));
        final stills = [
          for (final call in calls)
            if (call.method == #drawImageRect) call,
        ];

        if (vector.isFlat) {
          // Flat, the body is painted as it is: nothing is a still.
          expect(stills, isEmpty);

          return;
        }

        // The halves the table shows, in the order they are painted.
        final shown = [
          for (final name in const ['innerRight', 'innerLeft'])
            if (vector.parts[name]!.visible) name,
        ];
        expect(stills, hasLength(shown.length));

        // The canvas is moved to the stage's corner once; each half is then
        // one matrix, one clip, one copy of the still.
        final origin = still.localToGlobal(Offset.zero, ancestor: stage);
        final moved = calls.firstWhere((call) => call.method == #translate);
        expect(moved.arguments, [-origin.dx, -origin.dy]);
        final matrices = [
          for (final call in calls)
            if (call.method == #transform)
              Matrix4.fromFloat64List(call.arguments.single as Float64List),
        ];
        final clips = [
          for (final call in calls)
            if (call.method == #clipRect) call.arguments.first as Rect,
        ];
        expect(matrices, hasLength(shown.length));
        expect(clips, hasLength(shown.length));

        final body = Offset.zero & table.size;
        final picture = origin & still.size;
        for (var i = 0; i < shown.length; i++) {
          _expectCorners(
            [
              body.topLeft,
              body.topRight,
              body.bottomLeft,
              body.bottomRight,
            ].map((p) => MatrixUtils.transformPoint(matrices[i], p)).toList(),
            vector.parts[shown[i]]!.corners,
            shown[i],
          );
          // Each half is the still cut at the hinge, with all the still holds
          // beyond the body on its own side.
          expect(
            clips[i],
            shown[i] == 'innerRight'
                ? Rect.fromLTRB(
                    table.width / 2,
                    picture.top,
                    picture.right,
                    picture.bottom,
                  )
                : Rect.fromLTRB(
                    picture.left,
                    picture.top,
                    table.width / 2,
                    picture.bottom,
                  ),
            reason: shown[i],
          );
          expect(stills[i].arguments[2], picture, reason: shown[i]);
        }
      });
    }

    for (final vector in table.vectors) {
      testWidgets('at ${vector.angle}° — a screen that is off is covered as '
          'far as the table says', (tester) async {
        await pumpAt(tester, vector.angle);
        final stage = stageOf(tester);
        Rect screenOf(CoreMockupDevice device) {
          final screen = screenBoxOf(tester, device);
          final face = tester.renderObject<RenderBox>(faceOf(device));

          return screen.localToGlobal(Offset.zero, ancestor: face) &
              screen.size;
        }

        // The inner screen: a scrim over the screen of the device beneath,
        // in every half that is painted.
        final innerScreen = screenOf(CoreMockupDevice.tablet);
        final scrims = [
          for (final call in _callsOf(find.byType(SnapshotWidget)))
            if (call.method == #drawRRect &&
                (call.arguments.first as RRect).outerRect == innerScreen)
              (call.arguments.last as Paint).color,
        ];
        final halves = [
          for (final name in const ['innerRight', 'innerLeft'])
            if (vector.parts[name]!.visible) name,
        ];
        if (vector.isFlat || vector.innerScreenDim == 0) {
          expect(scrims, isEmpty);
        } else {
          expect(scrims, hasLength(halves.length));
          for (final scrim in scrims) {
            expect(scrim.a, closeTo(vector.innerScreenDim, 1e-6));
          }
        }

        // The cover screen: a veil over the cover device's screen.
        if (!vector.parts['cover']!.visible) return;

        final coverScreen = screenOf(CoreMockupDevice.phone);
        final cover = tester.renderObject<RenderBox>(
          faceOf(CoreMockupDevice.phone),
        );
        final veils = [
          for (final element
              in find
                  .descendant(
                    of: find.byKey(kCoverPart),
                    matching: find.byType(DecoratedBox),
                  )
                  .evaluate())
            if (element.findAncestorWidgetOfExactType<MockupDevice>() == null)
              element,
        ];
        final screenVeils = [
          for (final element in veils)
            if (cornersOn(
                  cover,
                  element.renderObject! as RenderBox,
                ).first ==
                coverScreen.topLeft)
              ((element.widget as DecoratedBox).decoration as BoxDecoration)
                  .color!,
        ];
        if (vector.coverScreenDim == 0) {
          expect(screenVeils, isEmpty);
        } else {
          expect(screenVeils, hasLength(1));
          expect(screenVeils.single.a, closeTo(vector.coverScreenDim, 1e-6));
        }
        // Every veil lets input through to the screen under it.
        for (final element in veils) {
          expect(
            element.findAncestorWidgetOfExactType<IgnorePointer>()!.ignoring,
            isTrue,
          );
        }
        expect(stage.size, table.size);
      });
    }
  });

  group('MockupFoldable — the pixels', () {
    /// How far the table's device reaches left and right at half its height:
    /// the outer side of every part the table shows.
    ({double left, double right}) reachOf(FoldVector vector) {
      double leftOf(FoldPartVector part) =>
          (part.corners.first.dx + part.corners[2].dx) / 2;
      double rightOf(FoldPartVector part) =>
          (part.corners[1].dx + part.corners.last.dx) / 2;
      final sides = [
        for (final name in const ['cover', 'edgeLeft', 'edgeRight'])
          if (vector.parts[name]!.visible) ...[
            leftOf(vector.parts[name]!),
            rightOf(vector.parts[name]!),
          ],
        // A half of the inner screen is shown from the hinge to its free
        // side; the hinge is never the outside of the device.
        if (vector.parts['innerRight']!.visible)
          rightOf(vector.parts['innerRight']!),
        if (vector.parts['innerLeft']!.visible)
          leftOf(vector.parts['innerLeft']!),
      ];

      return (left: sides.reduce(math.min), right: sides.reduce(math.max));
    }

    for (final vector in table.vectors) {
      testWidgets('at ${vector.angle}° — the device reaches as far left and '
          'right as the table says', (tester) async {
        useOneToOneView(tester, table.size);
        final boundary = GlobalKey();
        await pumpAt(tester, vector.angle, boundary: boundary);

        final drawn = (await capture(
          tester,
          boundary,
        )).reachOnStageRow(table.height / 2);
        final stated = reachOf(vector);

        expect(drawn.left, closeTo(stated.left, _kPixelTolerance));
        expect(drawn.right, closeTo(stated.right, _kPixelTolerance));
      });
    }

    testWidgets('an edge ends where the corner of the face behind it cuts '
        'it, not at the corner of its box', (tester) async {
      // Nearly shut, the cover is face on and the left slab's edge is a
      // strip a few pixels wide beside its rounded corners.
      final vector = table.vectors.singleWhere((v) => v.angle == 20);
      final edge = vector.parts['edgeLeft']!;
      expect(edge.visible, isTrue);
      final x = (edge.corners.first.dx + edge.corners[1].dx) / 2;
      final top = (edge.corners.first.dy + edge.corners[1].dy) / 2;
      final bottom = (edge.corners[2].dy + edge.corners.last.dy) / 2;
      expect(edge.corners[1].dx - edge.corners.first.dx, greaterThan(3));

      useOneToOneView(tester, table.size);
      final boundary = GlobalKey();
      await pumpAt(tester, vector.angle, boundary: boundary);
      final pixels = await capture(tester, boundary);
      bool edgeAt(double y) =>
          pixels.isDevice((x + kMargin).floor(), (y + kMargin).floor());

      // The strip itself, half way down …
      expect(edgeAt((top + bottom) / 2), isTrue);
      // … and no peg past the rounded corners at either end of its box.
      expect(edgeAt(top + 3), isFalse);
      expect(edgeAt(bottom - 3), isFalse);
    });

    testWidgets('a bent screen is redrawn when its content repaints', (
      tester,
    ) async {
      useOneToOneView(tester, table.size);
      final boundary = GlobalKey();
      final lamp = GlobalKey<_LampState>();
      // A point of the right half's screen at every angle past a right angle.
      final onScreen = Offset(table.width * 0.75, table.height / 2);
      await pumpAt(
        tester,
        CoreMockupFold.halfOpen,
        child: _Lamp(key: lamp),
        boundary: boundary,
      );
      final before = (await capture(tester, boundary)).onStage(onScreen);
      expect(before.r, greaterThan(before.b));

      // The content repaints by itself: nothing rebuilds the foldable.
      lamp.currentState!.light();
      await tester.pump();

      final after = (await capture(tester, boundary)).onStage(onScreen);
      expect(after.b, greaterThan(after.r));
    });

    testWidgets('content behind a repaint boundary of its own is caught up '
        'with when the foldable is rebuilt', (tester) async {
      useOneToOneView(tester, table.size);
      final boundary = GlobalKey();
      final lamp = GlobalKey<_LampState>();
      final onScreen = Offset(table.width * 0.75, table.height / 2);
      Future<void> pump() => pumpAt(
        tester,
        CoreMockupFold.halfOpen,
        child: RepaintBoundary(child: _Lamp(key: lamp)),
        boundary: boundary,
      );
      await pump();

      // A repaint asked for behind a boundary stops at the boundary: the
      // still does not hear of it. This is the reach of a bent screen.
      lamp.currentState!.light();
      await tester.pump();
      final unheard = (await capture(tester, boundary)).onStage(onScreen);
      expect(unheard.r, greaterThan(unheard.b));

      await pump();
      final caughtUp = (await capture(tester, boundary)).onStage(onScreen);
      expect(caughtUp.b, greaterThan(caughtUp.r));
    });
  });
}
