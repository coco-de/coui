// #3607 — PixelDiff, the 2nd (secondary) comparison signal.
//
// `.bmad/architecture-*.md` Component ⑤. PropertyDiff (property_diff.dart)
// is the primary signal — it catches "same token, different render"
// defects a pixel threshold can't see. PixelDiff exists for the opposite
// failure mode: renders that agree on every field PropertyDiff checks but
// still look wrong (a font hinting difference, a shadow that PropertyDiff
// approximates as geometry-equal but paints differently, anything outside
// the fields PropertyField enumerates).
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'png_color_space.dart';

/// Which comparison this run is — the two modes use *different* thresholds
/// because they compare fundamentally different things.
enum PixelDiffMode {
  /// Same platform, this capture vs its own committed baseline. Same
  /// rasterizer twice — any real change is deterministic, so the
  /// threshold is strict.
  regression,

  /// Flutter's render vs Web's render of the same design intent. Two
  /// different rasterizers (Skia software renderer vs a browser's own
  /// engine) producing visually-equivalent-but-byte-different output is
  /// expected and not a defect, so the threshold is loose.
  parity,
}

/// Per-mode pixel-diff-ratio thresholds (fraction of pixels allowed to
/// differ before the comparison fails).
///
/// **Provisional — still.** The pre-#3378 docs_site scaffolding's 0.5%/2%
/// figures could not be inherited (that pipeline compared two *browser*
/// screenshots — same text rasterizer on both sides; this pipeline
/// compares a Flutter golden PNG against a Chrome screenshot, a much
/// larger cross-rasterizer antialiasing delta), so [kParityThreshold] was
/// set looser than that old parity figure and [kRegressionThreshold]
/// tighter than that old regression figure (same-renderer output really
/// should be near-pixel-identical). That reasoning still holds, but
/// SPIKE-4's real calibration (#3619) has not replaced these constants
/// with a measured distribution yet.
///
/// **#3657 (canvas-size normalization) is resolved — a prerequisite for
/// #3619, not the calibration itself.** SPIKE-4's initial real-capture run
/// found `flutter_capture_test.dart` + `capture_web.dart` producing a
/// **116×40 Flutter capture vs an 80×40 Web capture** for Button
/// (`button-primary-light-defaultStyle`) despite every normalized property
/// matching exactly — [PixelDiffResult.passed] requires
/// `dimensionMismatch == null` unconditionally, so no threshold value here
/// could make that pair pass. Root cause, confirmed by direct
/// measurement: the two captures rendered **different label text**
/// (`flutter_capture_test.dart` hard-coded `Text('Submit')`;
/// `docs_core`'s shared preview registry — what the real Web capture
/// consumes — renders `Text('Primary')` for this key), not a
/// rasterizer/font-shaping divergence. With both platforms' widget-under-
/// test sourced from the same registry entry, and Flutter's own capture
/// pinned to a rounded-to-nearest integer width the same way
/// `flutter_capture_matrix_test.dart` (#3652) already is, the two
/// captures land on the same 80×40 with **zero** dimension mismatch. A
/// ratio-based threshold is now measurable for real Tier1 components —
/// SPIKE-4's remaining, real calibration work is #3619's own; `GatePhase.c`
/// (`../gate/gate_phase.dart`) still stays un-promoted until *that*
/// measurement (not this dimension prerequisite) lands, so pixel-parity
/// enforcement doesn't gate merges on an uncalibrated threshold.
const double kRegressionThreshold = 0.001; // 0.1%
const double kParityThreshold = 0.05; // 5%

double thresholdFor(PixelDiffMode mode) => switch (mode) {
  .regression => kRegressionThreshold,
  .parity => kParityThreshold,
};

/// A single RGBA channel delta beyond this (out of 255) counts a pixel as
/// "different" — absorbs the kind of ±1-2 gamma/dithering noise a
/// pixel-perfect comparison would otherwise flag on every single pixel of
/// an otherwise-identical image.
const int kChannelDeltaThreshold = 32;

/// The max value of one 8-bit color channel — named so the marker color
/// below reads as "full red, full alpha" rather than a bare `255`.
const int _kFullChannel = 255;

/// RGBA — the diff image needs an alpha channel (package:image's default
/// `Image` is 3-channel RGB).
const int _kRgbaChannelCount = 4;

/// The color a differing pixel is painted in the emitted diff image —
/// opaque red, maximally visible against either a light or dark capture.
img.Color _diffMarkerColor() =>
    img.ColorRgba8(_kFullChannel, 0, 0, _kFullChannel);

/// How many dominant color transitions [PixelDiffResult.topColorTransitions]
/// keeps — matches the "주요 변화" block of the regression-report format
/// (a handful of representative `#old → #new` pairs, not the full
/// histogram).
const int kTopColorTransitionCount = 3;

/// Bits dropped per channel when bucketing color transitions — 16 levels
/// per channel. Groups anti-aliasing neighbors of the same underlying
/// color shift into one bucket so the top transitions read as "the mint
/// button turned teal", not as hundreds of near-identical AA shades.
const int _kTransitionQuantShiftBits = 4;

/// Bit width of one quantized RGB channel
/// (8 - [_kTransitionQuantShiftBits]).
const int _kQuantChannelBits = 4;

/// Bit width of a full quantized RGB triple.
const int _kQuantRgbBits = _kQuantChannelBits * 3;

/// Digits of a `#rrggbb` hex color body.
const int _kHexRgbDigits = 6;

/// One dominant `before → after` color shift among the differing pixels —
/// the "주요 변화: #2eb8a1 → #207e6f" line of the report format.
class ColorTransition {
  /// Creates one transition with its representative colors and pixel
  /// count.
  const ColorTransition({
    required this.fromRgb,
    required this.toRgb,
    required this.count,
  });

  /// Representative source color (0xRRGGBB) — the exact color of the
  /// first pixel that landed in this quantized bucket.
  final int fromRgb;

  /// Representative destination color (0xRRGGBB).
  final int toRgb;

  /// How many differing pixels fell into this bucket.
  final int count;

  /// `#rrggbb` form of [fromRgb].
  String get fromHex => _rgbToHex(fromRgb);

  /// `#rrggbb` form of [toRgb].
  String get toHex => _rgbToHex(toRgb);

  @override
  String toString() => '$fromHex → $toHex (${formatThousands(count)} px)';
}

String _rgbToHex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(_kHexRgbDigits, '0')}';

/// Mutable tally for one quantized (from, to) bucket while the pixel loop
/// runs — folded into immutable [ColorTransition]s afterwards.
class _TransitionBucket {
  _TransitionBucket({required this.fromRgb, required this.toRgb});

  final int fromRgb;
  final int toRgb;
  int count = 0;
}

/// Grouping size for [formatThousands].
const int _kThousandsGroup = 3;

/// Formats [value] with thousands separators (`836964` → `836,964`) — the
/// report format writes pixel counts this way so a reviewer can read the
/// magnitude at a glance.
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % _kThousandsGroup == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

class PixelDiffResult {
  const PixelDiffResult({
    required this.mode,
    required this.totalPixels,
    required this.diffPixelCount,
    required this.diffImageBytes,
    this.dimensionMismatch,
    this.width = 0,
    this.height = 0,
    this.maxChannelDelta = 0,
    this.topColorTransitions = const [],
  });

  final PixelDiffMode mode;
  final int totalPixels;
  final int diffPixelCount;

  /// Compared image width in px — `0` when [dimensionMismatch] made the
  /// shared geometry undefined.
  final int width;

  /// Compared image height in px — `0` when [dimensionMismatch] is set.
  final int height;

  /// Largest channel delta across all pixels, rounded up for floating ICC
  /// coordinates — the "최대 채널차" figure. ICC comparisons use extended
  /// sRGB8-bit units; two unmanaged inputs retain their original sample
  /// units, including non8-bit PNGs. Wider-gamut coordinates can exceed255.
  /// Nonzero even on a passing comparison (sub-threshold noise has a max).
  final int maxChannelDelta;

  /// Up to [kTopColorTransitionCount] dominant `before → after` color
  /// shifts among the differing pixels, largest bucket first. Empty when
  /// nothing differed or [dimensionMismatch] is set.
  final List<ColorTransition> topColorTransitions;

  /// A PNG (same dimensions as the inputs) with every differing pixel
  /// marked in a bright marker color — emitted only when [passed] is
  /// `false` (completion definition: "임계 초과 시 diff 이미지 출력").
  /// `null` when the comparison passed, or when [dimensionMismatch] made a
  /// pixel-level diff meaningless to draw.
  ///
  /// Non-differing pixels pass through from [comparePixels]' **first**
  /// argument — for regression that is the *baseline* render (callers pass
  /// (baseline, captured)), so a regression diff PNG shows the old render
  /// under the markers.
  final Uint8List? diffImageBytes;

  /// Set instead of doing a pixel comparison when the two images aren't
  /// the same size — a dimension mismatch is its own distinct failure
  /// (layout diverged enough that "which pixels differ" isn't a
  /// meaningful question), not a diff ratio.
  final String? dimensionMismatch;

  double get diffRatio => totalPixels == 0 ? 0 : diffPixelCount / totalPixels;

  bool get passed =>
      dimensionMismatch == null && diffRatio <= thresholdFor(mode);

  @override
  String toString() {
    if (dimensionMismatch != null) {
      return 'PixelDiffResult(${mode.name}, '
          'dimension mismatch: $dimensionMismatch)';
    }
    final diffPercent = (diffRatio * _kPercentMultiplier).toStringAsFixed(
      _kPercentDisplayDecimals,
    );
    final thresholdPercent = (thresholdFor(mode) * _kPercentMultiplier)
        .toStringAsFixed(_kPercentDisplayDecimals);
    return 'PixelDiffResult(${mode.name}, $diffPercent% '
        '($diffPixelCount/$totalPixels px), threshold=$thresholdPercent%, '
        'maxChannelDelta=$maxChannelDelta, '
        '${passed ? "PASS" : "FAIL"})';
  }

  /// The human-facing multi-line block the regression report format uses —
  /// resolution check, pixel-diff statistics ("N / M px (P%), 최대 채널차
  /// D"), and the dominant color shifts:
  ///
  /// ```text
  /// 해상도: 1041×804 (동일)
  /// 픽셀 diff: 20,622 / 836,964 px (2.464%) — 임계 0.100%, 최대 채널차 74
  /// 주요 변화:  #2eb8a1 → #207e6f   (12,400 px)
  /// ```
  ///
  /// Ratio and threshold print at the same precision
  /// ([_kPercentDisplayDecimals]) — rounding the ratio coarser than the
  /// threshold lets a marginal FAIL (e.g. 0.104%) display as a figure at
  /// or below its own printed threshold, which reads as a pass.
  String describe() {
    if (dimensionMismatch != null) {
      return '해상도 불일치: $dimensionMismatch — 레이아웃 자체가 달라져 픽셀 '
          'diff 를 계산하지 않음';
    }
    final diffPercent = (diffRatio * _kPercentMultiplier).toStringAsFixed(
      _kPercentDisplayDecimals,
    );
    final thresholdPercent = (thresholdFor(mode) * _kPercentMultiplier)
        .toStringAsFixed(_kPercentDisplayDecimals);
    final buffer = StringBuffer()
      ..writeln('해상도: $width×$height (동일)')
      ..write(
        '픽셀 diff: ${formatThousands(diffPixelCount)} / '
        '${formatThousands(totalPixels)} px ($diffPercent%) — '
        '임계 $thresholdPercent%, 최대 채널차 $maxChannelDelta',
      );
    if (topColorTransitions.isNotEmpty) {
      buffer.write('\n주요 변화:');
      for (final transition in topColorTransitions) {
        buffer.write(
          '\n  ${transition.fromHex} → ${transition.toHex}   '
          '(${formatThousands(transition.count)} px)',
        );
      }
    }
    return buffer.toString();
  }
}

/// Converts a `0.0..1.0` ratio to a percentage for display.
const int _kPercentMultiplier = 100;

/// Decimal places shown for a displayed percentage — fine enough to
/// distinguish [kRegressionThreshold] (0.1%) from a passing result.
const int _kPercentDisplayDecimals = 3;

/// Compares two PNGs (raw bytes, as written by either capture backend) and
/// returns a [PixelDiffResult] for [mode].
///
/// Argument order matters for [PixelDiffResult.topColorTransitions]: [a]
/// is the "before"/reference side and [b] the "after" side — a transition
/// renders as `a-color → b-color`. Regression callers pass (baseline,
/// captured); the parity caller passes (flutter, web).
PixelDiffResult comparePixels(
  Uint8List a,
  Uint8List b, {
  required PixelDiffMode mode,
}) {
  final imageA = img.decodePng(a);
  final imageB = img.decodePng(b);
  if (imageA == null || imageB == null) {
    throw FormatException(
      'PNG 디코딩 실패 — a: ${imageA != null}, b: ${imageB != null}',
    );
  }

  if (imageA.width != imageB.width || imageA.height != imageB.height) {
    final sizeA = '${imageA.width}x${imageA.height}';
    final sizeB = '${imageB.width}x${imageB.height}';
    return PixelDiffResult(
      mode: mode,
      totalPixels: 0,
      diffPixelCount: 0,
      diffImageBytes: null,
      dimensionMismatch: '$sizeA vs $sizeB',
    );
  }

  final spaceA = PngColorSpace.fromPng(a);
  final spaceB = PngColorSpace.fromPng(b);
  spaceA.requireCompatible(spaceB);

  final width = imageA.width;
  final height = imageA.height;
  // package:image's `Image`, not a Flutter widget — avoid-missing-image-alt
  // is a Flutter-widget lint misfiring on the shared class name.
  final diffImage = img.Image(
    width: width,
    height: height,
    // Not the default 3 (RGB) — the diff marker and the pass-through
    // original pixels both carry an alpha channel.
    numChannels: _kRgbaChannelCount,
    // Diagnostic pass-through pixels stay in the reference image's encoding.
    // The original input PNG/profile is never modified.
    iccp: imageA.iccProfile?.clone(),
  );
  var diffPixelCount = 0;
  var maxChannelDelta = 0;
  final transitionBuckets = <int, _TransitionBucket>{};

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixelA = imageA.getPixel(x, y);
      final pixelB = imageB.getPixel(x, y);
      final rgbA = spaceA.rgb(pixelA.r, pixelA.g, pixelA.b);
      final rgbB = spaceB.rgb(pixelB.r, pixelB.g, pixelB.b);
      final deltaR = (rgbA[0] - rgbB[0]).abs();
      final deltaG = (rgbA[1] - rgbB[1]).abs();
      final deltaB = (rgbA[2] - rgbB[2]).abs();
      final deltaA = (pixelA.a - pixelB.a).abs().toInt();
      final pixelMaxDelta = [
        deltaR,
        deltaG,
        deltaB,
        deltaA,
      ].reduce((a, b) => a > b ? a : b);
      // Keep the original >32 comparison before rounding. The integer
      // diagnostic rounds up so a differing32.1 is never reported as32.
      if (pixelMaxDelta > maxChannelDelta) {
        maxChannelDelta = pixelMaxDelta.ceil();
      }

      final isDifferent =
          deltaR > kChannelDeltaThreshold ||
          deltaG > kChannelDeltaThreshold ||
          deltaB > kChannelDeltaThreshold ||
          deltaA > kChannelDeltaThreshold;

      if (isDifferent) {
        diffPixelCount++;
        diffImage.setPixel(x, y, _diffMarkerColor());
        _tallyTransition(transitionBuckets, pixelA, pixelB);
      } else {
        diffImage.setPixel(x, y, pixelA);
      }
    }
  }

  final totalPixels = width * height;
  final topColorTransitions = _topTransitions(transitionBuckets);
  final result = PixelDiffResult(
    mode: mode,
    totalPixels: totalPixels,
    diffPixelCount: diffPixelCount,
    diffImageBytes: null,
    width: width,
    height: height,
    maxChannelDelta: maxChannelDelta,
    topColorTransitions: topColorTransitions,
  );

  if (result.passed) {
    return result;
  }

  return PixelDiffResult(
    mode: mode,
    totalPixels: totalPixels,
    diffPixelCount: diffPixelCount,
    diffImageBytes: Uint8List.fromList(img.encodePng(diffImage)),
    width: width,
    height: height,
    maxChannelDelta: maxChannelDelta,
    topColorTransitions: topColorTransitions,
  );
}

/// Adds one differing pixel to its quantized `(from, to)` bucket. The
/// bucket keeps the exact colors of the *first* pixel it saw as its
/// representative pair — a real color from the capture, not a bucket
/// midpoint that exists in neither image.
/// These are source-encoded RGB diagnostics, not common-space coordinates:
/// equal hex values may denote different colours under different profiles.
void _tallyTransition(
  Map<int, _TransitionBucket> buckets,
  img.Pixel pixelA,
  img.Pixel pixelB,
) {
  final fromRgb = _packRgb(pixelA);
  final toRgb = _packRgb(pixelB);
  final bucketKey =
      (_quantizeRgb(fromRgb) << _kQuantRgbBits) | _quantizeRgb(toRgb);
  buckets
      .putIfAbsent(
        bucketKey,
        () => _TransitionBucket(fromRgb: fromRgb, toRgb: toRgb),
      )
      .count++;
}

/// Bits per 8-bit color channel.
const int _kChannelBits = 8;

int _packRgb(img.Pixel pixel) =>
    (pixel.r.toInt() << (_kChannelBits * 2)) |
    (pixel.g.toInt() << _kChannelBits) |
    pixel.b.toInt();

/// Drops the low [_kTransitionQuantShiftBits] bits of each channel of a
/// packed 0xRRGGBB value, producing a [_kQuantRgbBits]-bit bucket
/// component.
int _quantizeRgb(int rgb) {
  final r = (rgb >> (_kChannelBits * 2)) & _kChannelMask;
  final g = (rgb >> _kChannelBits) & _kChannelMask;
  final b = rgb & _kChannelMask;
  return ((r >> _kTransitionQuantShiftBits) << (_kQuantChannelBits * 2)) |
      ((g >> _kTransitionQuantShiftBits) << _kQuantChannelBits) |
      (b >> _kTransitionQuantShiftBits);
}

/// Mask for one 8-bit channel.
const int _kChannelMask = 0xFF;

/// Folds the buckets into the [kTopColorTransitionCount] largest
/// [ColorTransition]s, biggest first.
List<ColorTransition> _topTransitions(Map<int, _TransitionBucket> buckets) {
  final sorted = buckets.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return [
    for (final bucket in sorted.take(kTopColorTransitionCount))
      ColorTransition(
        fromRgb: bucket.fromRgb,
        toRgb: bucket.toRgb,
        count: bucket.count,
      ),
  ];
}
