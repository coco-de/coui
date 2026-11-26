import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

/// Side of the square the mask is laid out in, in logical pixels.
const double _kSide = 100;

/// Sample-grid step; odd so no sample lands exactly on a lobe's centre
/// seam or on the half boundary, where "inside" is a tie.
const double _kStep = 7;

const _kChildKey = widgets.ValueKey<String>('mask-child');

Future<void> _pumpMask(
  WidgetTester tester, {
  required CoreMaskShape shape,
  CoreMaskHalf half = .none,
}) async {
  await tester.pumpWidget(
    widgets.Directionality(
      textDirection: .ltr,
      child: Theme(
        data: const ThemeData(),
        child: widgets.Center(
          child: widgets.SizedBox.square(
            dimension: _kSide,
            child: Mask(
              shape: shape,
              half: half,
              child: const widgets.ColoredBox(
                key: _kChildKey,
                color: widgets.Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Whether a hit at [local] (in the mask's own coordinates) reaches the
/// child — i.e. whether every clip in the mask lets it through.
bool _reachesChild(WidgetTester tester, Offset local) {
  final child = tester.renderObject<RenderBox>(find.byKey(_kChildKey));
  final origin = child.localToGlobal(Offset.zero);
  final result = HitTestResult();
  tester.binding.hitTestInView(
    result,
    origin + local,
    tester.view.viewId,
  );
  return result.path.any((entry) => entry.target == child);
}

Iterable<Offset> _grid() sync* {
  for (var y = _kStep / 2; y < _kSide; y += _kStep) {
    for (var x = _kStep / 2; x < _kSide; x += _kStep) {
      yield Offset(x, y);
    }
  }
}

/// The heart as two separately closed lobes — the shape the mask must
/// cover. Built as a reference only: a point is inside the heart when it
/// is inside either lobe, which is the union without a boolean path op.
bool _insideReferenceHeart(Offset p) {
  const w = _kSide;
  const h = _kSide;
  const halfW = w / 2;
  const topY = h * kMaskHeartTopFactor;
  const curveY = h * kMaskHeartCurveY;
  final left = ui.Path()
    ..moveTo(halfW, topY)
    ..cubicTo(w * kMaskHeartLeftControlX, 0, 0, curveY, halfW, h)
    ..close();
  final right = ui.Path()
    ..moveTo(halfW, topY)
    ..cubicTo(w * kMaskHeartRightControlX, 0, w, curveY, halfW, h)
    ..close();
  return left.contains(p) || right.contains(p);
}

bool _insideCircle(Offset p) {
  const r = _kSide / 2;
  return (p - const Offset(r, r)).distance <= r;
}

void main() {
  group('Mask geometry', () {
    testWidgets('heart covers both lobes, and only them', (tester) async {
      await _pumpMask(tester, shape: .heart);

      final mismatches = <Offset>[
        for (final p in _grid())
          if (_reachesChild(tester, p) != _insideReferenceHeart(p)) p,
      ];
      expect(mismatches, isEmpty);
    });

    testWidgets('heart is mirror-symmetric about the centre line', (
      tester,
    ) async {
      await _pumpMask(tester, shape: .heart);

      // A lobe-only outline would reach the child on one side and miss
      // the mirrored point on the other.
      for (final p in _grid()) {
        final mirrored = Offset(_kSide - p.dx, p.dy);
        expect(
          _reachesChild(tester, p),
          _reachesChild(tester, mirrored),
          reason: 'asymmetric at $p / $mirrored',
        );
      }
      expect(
        _reachesChild(tester, const Offset(_kSide * 0.3, _kSide * 0.4)),
        isTrue,
      );
      expect(
        _reachesChild(tester, const Offset(_kSide * 0.7, _kSide * 0.4)),
        isTrue,
      );
    });

    for (final half in [CoreMaskHalf.first, CoreMaskHalf.second]) {
      testWidgets('half ${half.name} keeps only its half of the shape', (
        tester,
      ) async {
        await _pumpMask(tester, shape: .circle, half: half);

        bool expected(Offset p) {
          final inHalf = half == .first ? p.dy < _kSide / 2 : p.dy > _kSide / 2;
          return inHalf && _insideCircle(p);
        }

        final mismatches = <Offset>[
          for (final p in _grid())
            if (_reachesChild(tester, p) != expected(p)) p,
        ];
        expect(mismatches, isEmpty);

        // Centre of the dropped half is inside the circle but must be
        // clipped away.
        final dropped = half == .first
            ? const Offset(_kSide / 2, _kSide * 0.75)
            : const Offset(_kSide / 2, _kSide * 0.25);
        expect(_reachesChild(tester, dropped), isFalse);
      });
    }

    testWidgets('half applies to non-rect shapes too (heart, first)', (
      tester,
    ) async {
      await _pumpMask(tester, shape: .heart, half: .first);

      final mismatches = <Offset>[
        for (final p in _grid())
          if (_reachesChild(tester, p) !=
              (p.dy < _kSide / 2 && _insideReferenceHeart(p)))
            p,
      ];
      expect(mismatches, isEmpty);
    });

    testWidgets('square with no half adds no clip', (tester) async {
      await _pumpMask(tester, shape: .square);

      expect(find.byType(widgets.ClipPath), findsNothing);
      expect(find.byType(widgets.ClipRect), findsNothing);
    });
  });
}
