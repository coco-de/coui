import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/mask/mask_style.dart';
import 'package:flutter/widgets.dart';

/// Unified mask component for CoUI Flutter.
///
/// Clips [child] to the given [shape]. Mirrors Web `Mask` — same parameter
/// names and visual outcome.
class Mask extends StatelessWidget implements CoreMaskContract<Widget> {
  /// Creates a [Mask].
  const Mask({
    required this.child,
    super.key,
    this.shape = .squircle,
    this.half = .none,
  });

  @override
  final Widget child;

  @override
  final CoreMaskShape shape;

  @override
  final CoreMaskHalf half;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMask(
      context,
      shape: shape,
      half: half,
    );
    if (resolved.shape == .square && resolved.half == .none) {
      return child;
    }
    final shaped = ClipPath(
      clipper: _MaskClipper(shape: resolved.shape),
      child: child,
    );
    if (resolved.half == .none) return shaped;
    // The half is a second clip around the shape, not an intersected path:
    // nested clips intersect on every rasteriser, whereas boolean path ops
    // are not trusted in the web build (`Path.combine` came back with its
    // operation unperformed there, while `flutter test` performed it).
    return ClipRect(
      clipper: _HalfRectClipper(half: resolved.half),
      child: shaped,
    );
  }
}

class _HalfRectClipper extends CustomClipper<Rect> {
  const _HalfRectClipper({required this.half});

  final CoreMaskHalf half;

  @override
  Rect getClip(Size size) {
    return switch (half) {
      .first => Rect.fromLTWH(0, 0, size.width, size.height / 2),
      .second => Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      .none => Offset.zero & size,
    };
  }

  @override
  bool shouldReclip(covariant _HalfRectClipper oldClipper) {
    return oldClipper.half != half;
  }
}

class _MaskClipper extends CustomClipper<Path> {
  const _MaskClipper({required this.shape});

  final CoreMaskShape shape;

  @override
  Path getClip(Size size) => _shapePath(size, shape);

  @override
  bool shouldReclip(covariant _MaskClipper oldClipper) {
    return oldClipper.shape != shape;
  }

  Path _shapePath(Size size, CoreMaskShape s) {
    return switch (s) {
      .circle => Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)),
      .square => Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      .squircle => _squirclePath(size),
      .heart => _heartPath(size),
      .hexagon => _polygonPath(size, kMaskHexagonSides, rotateQuarter: false),
      .hexagon2 => _polygonPath(size, kMaskHexagonSides, rotateQuarter: true),
      .decagon => _polygonPath(size, kMaskDecagonSides, rotateQuarter: false),
      .pentagon => _polygonPath(size, kMaskPentagonSides, rotateQuarter: false),
      .diamond => _diamondPath(size),
      .star => _starPath(size, kMaskStarInnerRadiusFactor),
      .star2 => _starPath(size, kMaskStar2InnerRadiusFactor),
      .triangle => _trianglePath(size, .up),
      .triangle2 => _trianglePath(size, .down),
      .triangle3 => _trianglePath(size, .left),
      .triangle4 => _trianglePath(size, .right),
    };
  }

  Path _squirclePath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.min(w, h) * kMaskSquircleRadiusFactor;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  Path _diamondPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    return Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, cy)
      ..lineTo(cx, size.height)
      ..lineTo(0, cy)
      ..close();
  }

  Path _polygonPath(
    Size size,
    int sides, {
    required bool rotateQuarter,
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);
    final startAngle = rotateQuarter ? 0.0 : -math.pi / 2;
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) + startAngle;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _starPath(Size size, double innerRatio) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy);
    final innerR = outerR * innerRatio;
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final angle = (math.pi * i / points) - (math.pi / 2);
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _trianglePath(Size size, _TriangleDirection dir) {
    final w = size.width;
    final h = size.height;
    return switch (dir) {
      .up =>
        (Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close()),
      .down =>
        (Path()
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w / 2, h)
          ..close()),
      .left =>
        (Path()
          ..moveTo(0, h / 2)
          ..lineTo(w, 0)
          ..lineTo(w, h)
          ..close()),
      .right =>
        (Path()
          ..moveTo(0, 0)
          ..lineTo(w, h / 2)
          ..lineTo(0, h)
          ..close()),
    };
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    final halfW = w / 2;
    final topY = h * kMaskHeartTopFactor;
    final curveY = h * kMaskHeartCurveY;
    // One outline: down the left lobe to the tip, then back up the right
    // lobe (the right curve traversed in reverse). Each lobe's control
    // points stay on its own side of the centre line, so this covers
    // exactly the two halves without a boolean union — see the half clip in
    // `Mask.build` for why boolean path ops are avoided.
    return Path()
      ..moveTo(halfW, topY)
      ..cubicTo(w * kMaskHeartLeftControlX, 0, 0, curveY, halfW, h)
      ..cubicTo(w, curveY, w * kMaskHeartRightControlX, 0, halfW, topY)
      ..close();
  }
}

enum _TriangleDirection { up, down, left, right }
