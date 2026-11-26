// #3376 — FlutterCaptureBackend (Component ②, `.bmad/architecture-*.md`):
// converts the typed values `../src/parity_probe/widget_tree_probe.dart`
// (Epic A) reads off the widget tree into the same JSON shape
// `tool/parity/src/model/property_snapshot.dart`'s `PropertySnapshot`
// serializes to, so `tool/parity/compare.dart` (#3607) can load a
// `<key>.flutter.json` file this test package writes without knowing it
// came from a different Dart package.
//
// This file cannot import `tool/parity/src/model/property_snapshot.dart`
// directly — `coui_flutter` doesn't (and shouldn't) depend on the
// workspace-root `tool/` package, and `PropertySnapshot`'s own conversion
// math (`tool/parity/src/normalize/flutter_property_normalizer.dart`)
// needs `dart:ui` types it can't import either (that file is deliberately
// pure-Dart so `tool/parity` stays runnable outside the Flutter engine).
// The contract between the two sides is the **JSON shape**, not a shared
// Dart type — matching every other cross-platform token conversion in
// this repo ("플랫폼 경유 경로 비대칭은 허용", `core/design-tokens.md`). The
// RGB byte decoding and line-height conversion share the units and
// precision of `flutter_property_normalizer.dart`. Alpha reads the actual
// typed `Color.a` before rounding: converting through ARGB would discard
// precision still present in that observation. The pure-Dart ARGB normalizer
// instead has an integer input, with no additional alpha precision to read.
import 'package:flutter/painting.dart';

/// RGB bit positions in `Color.toARGB32()` — matching the integer-input
/// normalizer. Alpha is observed independently through `Color.a`.
const int _kRedShift = 16;
const int _kGreenShift = 8;
const int _kByteMask = 0xFF;

const int _kPxRoundingDecimals = 2;
const int _kAlphaRoundingDecimals = 3;

double _roundPx(double value) =>
    double.parse(value.toStringAsFixed(_kPxRoundingDecimals));

double _roundAlpha(double value) =>
    double.parse(value.toStringAsFixed(_kAlphaRoundingDecimals));

/// `Color` → the `{r,g,b,a}` map shape `NormalizedColor.toJson()` emits.
Map<String, Object?> normalizedColorJson(Color color) {
  final argb = color.toARGB32();
  return {
    'r': (argb >> _kRedShift) & _kByteMask,
    'g': (argb >> _kGreenShift) & _kByteMask,
    'b': argb & _kByteMask,
    'a': _roundAlpha(color.a),
  };
}

/// Four physical values → the `[a,b,c,d]` list shape `FourSidePx.toJson()`
/// emits, rounded to match `PropertySnapshot`'s px precision.
List<double> fourSidePxJson(double a, double b, double c, double d) =>
    [a, b, c, d].map(_roundPx).toList(growable: false);

/// Assembles one probe role's `PropertySnapshot.toJson()`-shaped map from
/// the raw values `widget_tree_probe.dart`'s functions read off the widget
/// tree — every field optional, matching how `PropertySnapshot`'s
/// constructor leaves an unprobed field `null` rather than guessing one.
///
/// [textStyle] should be the *effective* style
/// (`probeEffectiveTextStyle`'s return value) — this function does not
/// merge with `DefaultTextStyle` itself, it only converts what it's given.
///
/// Shadow blur is captured in CSS-radius units (twice the SDK's painted
/// sigma), with `shadowBlurUnit` identifying fresh observations. Older
/// snapshots remain unchanged; their stored radii are not migrated on read.
Map<String, Object?> buildFlutterPropertySnapshotJson({
  required String key,
  required String probeRole,
  TextStyle? textStyle,
  BoxDecoration? decoration,
  EdgeInsets? padding,
  double? outlineWidthPx,
  double? outlineOffsetPx,
  double? opacity,
  // `RenderBox.size` — the border box, which is the edge Web's
  // `getBoundingClientRect()` reports. Not the content box: Chrome's
  // `getComputedStyle().width` is content-box whatever `box-sizing`
  // says, so measuring that side there and this side here would call
  // every padded component divergent.
  Size? size,
}) {
  final fontSizePx = textStyle?.fontSize;
  // TextStyle.height is a unitless multiplier of fontSize, not a length —
  // the same conversion `flutter_property_normalizer.dart`'s
  // normalizeFlutterLineHeightPx documents.
  final lineHeightPx = textStyle?.height == null || fontSizePx == null
      ? null
      : _roundPx(textStyle!.height! * fontSizePx);
  // TextStyle.letterSpacing is already absolute px in Flutter — identity,
  // not arithmetic (the opposite asymmetry from CoreTextStyle's em ratio).
  final letterSpacingPx = textStyle?.letterSpacing == null
      ? null
      : _roundPx(textStyle!.letterSpacing!);

  final borderSide = decoration?.border?.top;
  // Compare the layers that paint. Inspect the raw alpha before ARGB/JSON
  // rounding so a faint positive layer is not mistaken for absence.
  final boxShadowJson = decoration?.boxShadow
      ?.where((shadow) => shadow.color.a != 0)
      .map(
        (shadow) => {
          'offsetX': _roundPx(shadow.offset.dx),
          'offsetY': _roundPx(shadow.offset.dy),
          // CSS blur radius is 2*sigma; SDK blurRadius uses a different
          // convention. Read the SDK's actual sigma before rounding rather
          // than duplicating its radius-to-sigma implementation.
          'blur': _roundPx(shadow.blurSigma * 2),
          'spread': _roundPx(shadow.spreadRadius),
          'color': normalizedColorJson(shadow.color),
          if (shadow.blurStyle != BlurStyle.normal)
            'blurStyle': shadow.blurStyle.name,
        },
      )
      .toList(growable: false);
  final radius = decoration?.borderRadius?.resolve(.ltr);

  return {
    'key': key,
    'platform': 'flutter',
    'probeRole': probeRole,
    // An additive capture marker; legacy artifacts remain as recorded.
    // Their numeric blur values must not be converted again on read.
    if (boxShadowJson != null) 'shadowBlurUnit': 'css-radius',
    'fontFamily': textStyle?.fontFamily,
    // FontWeight.value is already the CSS-style 100..900 int — identity,
    // not arithmetic (flutter_property_normalizer.dart's
    // normalizeFlutterFontWeight).
    'fontWeight': textStyle?.fontWeight?.value,
    'fontSizePx': fontSizePx == null ? null : _roundPx(fontSizePx),
    'lineHeightPx': lineHeightPx,
    'letterSpacingPx': letterSpacingPx,
    'color': textStyle?.color == null
        ? null
        : normalizedColorJson(textStyle!.color!),
    // `null` here means the chrome walk found NO node to attribute a fill
    // to — an absence of measurement. A chrome node that was found and
    // states no fill is a different fact: it measured, and the answer is
    // "nothing is painted". Web says that second fact as `rgba(0,0,0,0)`,
    // so saying it as `null` made 274 entries look divergent while both
    // platforms painted the same nothing.
    //
    // Keeping the two apart is the point. Collapsing `null` into
    // transparent at the comparator instead would report "verified"
    // exactly when the walk breaks — the failure this probe exists to
    // catch would become the failure it hides.
    'backgroundColor': decoration == null
        ? null
        : normalizedColorJson(decoration.color ?? const Color(0x00000000)),
    'borderColor': borderSide == null
        ? null
        : normalizedColorJson(borderSide.color),
    'borderWidthPx': borderSide == null ? null : _roundPx(borderSide.width),
    // Same absence-vs-measured split as `backgroundColor`. A found chrome
    // node that states no radius has square corners, which is `0` — not
    // "unknown". Guarded on the shape: a circle has no square corners to
    // report, so there `null` stays the honest answer.
    'borderRadiusPx': radius == null
        ? (decoration == null || decoration.shape != BoxShape.rectangle
              ? null
              : fourSidePxJson(0, 0, 0, 0))
        : fourSidePxJson(
            radius.topLeft.x,
            radius.topRight.x,
            radius.bottomRight.x,
            radius.bottomLeft.x,
          ),
    'paddingPx': padding == null
        ? null
        : fourSidePxJson(
            padding.top,
            padding.right,
            padding.bottom,
            padding.left,
          ),
    'outlineWidthPx': outlineWidthPx == null ? null : _roundPx(outlineWidthPx),
    'outlineOffsetPx': outlineOffsetPx == null
        ? null
        : _roundPx(outlineOffsetPx),
    'boxShadow': boxShadowJson,
    'opacity': opacity == null ? null : _roundAlpha(opacity),
    'widthPx': size == null ? null : _roundPx(size.width),
    'heightPx': size == null ? null : _roundPx(size.height),
  };
}
