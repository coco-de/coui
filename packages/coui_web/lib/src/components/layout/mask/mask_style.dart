import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Static className for the outer mask `<div>` — acts as a stable hook for
/// ad-hoc CSS overrides; the actual masking ships via inline-CSS so the
/// component stays self-contained (no external daisyUI dependency).
const _kMaskRootClassName = 'co-mask';

/// Resolved styling values for [Mask].
///
/// DOM shape:
///
/// ```text
/// root (<div class="co-mask">)   // outer mask container
///   └─ child                     // caller-supplied content (clipped by mask)
/// ```
///
/// `root` carries the outer mask chrome — `co-mask` className plus
/// the inline-CSS bundle (`mask-image` SVG data-URL, plus optional
/// `clip-path` for half-crop). Per-instance `shape` / `half` are
/// folded into [root]'s inline CSS here so the widget reads
/// `resolved.root.*` straight back into `div(...)` — they are paint
/// chrome, not separate scalar identifiers on this struct (Epic #1603
/// 옵션 B 최종 — `ResolvedCo*` carries only `WebElementChrome` slots).
class ResolvedMask implements WebResolvedChrome {
  /// Creates a [ResolvedMask].
  const ResolvedMask({required this.root});

  /// Paint-ready chrome for the outer `<div>` — `co-mask` className
  /// plus the inline-CSS bundle that paints the mask SVG (folded from
  /// the effective `shape`) and optional half-crop (folded from the
  /// effective `half`).
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedMask] for [Mask].
///
/// Priority: widget value > `CoreComponentTheme.mask` > design-system default.
ResolvedMask resolveMask(
  BuildContext context, {
  CoreMaskShape? shape,
  CoreMaskHalf? half,
}) {
  final coreTheme = context.theme.coreComponentTheme?.mask;
  // Same standard chain as the Flutter twin — see its comment for why the
  // widget params are a chain layer rather than a Style slot.
  final merged = resolveStyleChain(const CoreMaskStyle(), [
    coreTheme?.style,
    CoreMaskStyle(shape: shape, half: half),
  ]);
  final effectiveShape = merged.shape ?? CoreMaskStyle.defaultShape;
  final effectiveHalf = merged.half ?? CoreMaskStyle.defaultHalf;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div>` inline CSS — a self-contained
  /// `mask-image` SVG data URL generated from the shared
  /// `mask_shape_constants` (so rendering stays in parity with Flutter
  /// without any external CSS dependency — no daisyUI required), plus
  /// the matching `-webkit-` prefixes and an optional `clip-path`
  /// when [effectiveHalf] crops the shape.
  Styles buildRootInlineStyles() {
    final svg = _svgDocument(effectiveShape);
    final url = 'url("data:image/svg+xml;utf8,${_encodeSvg(svg)}")';
    final styles = {
      'display': 'inline-block',
      'mask-image': url,
      '-webkit-mask-image': url,
      'mask-size': '100% 100%',
      '-webkit-mask-size': '100% 100%',
      'mask-repeat': 'no-repeat',
      '-webkit-mask-repeat': 'no-repeat',
    };
    final halfClip = _halfClipPath(effectiveHalf);
    if (halfClip != null) {
      styles['clip-path'] = halfClip;
      styles['-webkit-clip-path'] = halfClip;
    }
    return Styles(raw: styles);
  }

  return ResolvedMask(
    root: WebElementChrome(
      className: _kMaskRootClassName,
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

/// SVG path fraction digits — tight enough to keep the path string short,
/// wide enough to preserve sub-pixel control point precision. Not a design
/// token.
const _kSvgFractionDigits = 3;

String? _halfClipPath(CoreMaskHalf h) {
  return switch (h) {
    .none => null,
    .first => 'inset(0 0 50% 0)',
    .second => 'inset(50% 0 0 0)',
  };
}

/// Minimal URL encoding for `data:image/svg+xml` inside a CSS `url()`.
String _encodeSvg(String svg) {
  return svg
      .replaceAll('%', '%25')
      .replaceAll('"', '%22')
      .replaceAll("'", '%27')
      .replaceAll('#', '%23')
      .replaceAll('<', '%3C')
      .replaceAll('>', '%3E')
      .replaceAll('\n', '%0A');
}

String _svgDocument(CoreMaskShape shape) {
  final d = _svgPath(shape);
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" '
      'preserveAspectRatio="none">'
      ' <path d="$d" fill="#000"/>'
      ' </svg>';
}

String _svgPath(CoreMaskShape shape) {
  return switch (shape) {
    .circle => _circlePath(),
    .square => _squarePath(),
    .squircle => _squirclePath(),
    .heart => _heartPath(),
    .hexagon => _polygonPath(kMaskHexagonSides, rotateQuarter: false),
    .hexagon2 => _polygonPath(kMaskHexagonSides, rotateQuarter: true),
    .decagon => _polygonPath(kMaskDecagonSides, rotateQuarter: false),
    .pentagon => _polygonPath(kMaskPentagonSides, rotateQuarter: false),
    .diamond => _diamondPath(),
    .star => _starPath(kMaskStarInnerRadiusFactor),
    .star2 => _starPath(kMaskStar2InnerRadiusFactor),
    .triangle => _trianglePath(.up),
    .triangle2 => _trianglePath(.down),
    .triangle3 => _trianglePath(.left),
    .triangle4 => _trianglePath(.right),
  };
}

String _circlePath() => 'M 50 0 A 50 50 0 1 0 50 100 A 50 50 0 1 0 50 0 Z';

String _squarePath() => 'M 0 0 L 100 0 L 100 100 L 0 100 Z';

String _squirclePath() {
  const max = kMaskSvgViewBox;
  const r = max * kMaskSquircleRadiusFactor;
  return 'M $r 0 '
      'L ${max - r} 0 '
      'Q $max 0 $max $r '
      'L $max ${max - r} '
      'Q $max $max ${max - r} $max '
      'L $r $max '
      'Q 0 $max 0 ${max - r} '
      'L 0 $r '
      'Q 0 0 $r 0 '
      'Z';
}

String _diamondPath() {
  const c = kMaskSvgViewBox / 2;
  return 'M $c 0 L $kMaskSvgViewBox $c L $c $kMaskSvgViewBox L 0 $c Z';
}

String _polygonPath(int sides, {required bool rotateQuarter}) {
  const c = kMaskSvgViewBox / 2;
  const r = c;
  final start = rotateQuarter ? 0.0 : -math.pi / 2;
  final buffer = StringBuffer();
  for (var i = 0; i < sides; i++) {
    final angle = (2 * math.pi * i / sides) + start;
    final x = c + r * math.cos(angle);
    final y = c + r * math.sin(angle);
    buffer
      ..write(i == 0 ? 'M ' : 'L ')
      ..write('${_fmt(x)} ${_fmt(y)} ');
  }
  buffer.write('Z');
  return buffer.toString();
}

String _starPath(double innerRatio) {
  const c = kMaskSvgViewBox / 2;
  const outer = c;
  final inner = outer * innerRatio;
  final buffer = StringBuffer();
  const points = 5;
  for (var i = 0; i < points * 2; i++) {
    final angle = (math.pi * i / points) - (math.pi / 2);
    final r = i.isEven ? outer : inner;
    final x = c + r * math.cos(angle);
    final y = c + r * math.sin(angle);
    buffer
      ..write(i == 0 ? 'M ' : 'L ')
      ..write('${_fmt(x)} ${_fmt(y)} ');
  }
  buffer.write('Z');
  return buffer.toString();
}

String _trianglePath(_TriangleDirection dir) {
  const w = kMaskSvgViewBox;
  return switch (dir) {
    .up => 'M ${w / 2} 0 L $w $w L 0 $w Z',
    .down => 'M 0 0 L $w 0 L ${w / 2} $w Z',
    .left => 'M 0 ${w / 2} L $w 0 L $w $w Z',
    .right => 'M 0 0 L $w ${w / 2} L 0 $w Z',
  };
}

String _heartPath() {
  const w = kMaskSvgViewBox;
  const h = kMaskSvgViewBox;
  const halfW = w / 2;
  const topY = h * kMaskHeartTopFactor;
  const curveY = h * kMaskHeartCurveY;
  const lcx = w * kMaskHeartLeftControlX;
  const rcx = w * kMaskHeartRightControlX;
  return 'M $halfW $topY '
      'C ${_fmt(lcx)} 0 0 ${_fmt(curveY)} $halfW $h '
      'C $w ${_fmt(curveY)} ${_fmt(rcx)} 0 $halfW $topY '
      'Z';
}

String _fmt(double v) {
  final rounded = double.parse(v.toStringAsFixed(_kSvgFractionDigits));
  if (rounded == rounded.roundToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toString();
}

enum _TriangleDirection { up, down, left, right }
