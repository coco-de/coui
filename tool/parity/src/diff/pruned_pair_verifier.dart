// #3663 item 1 — adds PropertyDiff (this repo's 1st/primary comparison
// signal, `property_diff.dart`) to pruned-pair verification, which until
// now only ran PixelDiff (`pixel_diff.dart`, the 2nd/secondary signal) —
// making `pruned_verify.dart` this repo's fourth tautological gate.
//
// Empirically, a `liquidGlass` surface style changes CSS/property values
// (e.g. `backgroundColor` from an opaque `rgb(...)` to a translucent
// `rgba(..., 0.7)`) without moving any *pixel* when the composited surface
// sits on a same-colour, flat backdrop and the blur is a no-op there — so
// PixelDiff alone reports the pruning as "matched" even on a marker
// component (`card`) where the property snapshot visibly diverges. Without
// this file, `pruned_verify.dart` could not falsify a wrong pruning rule
// unless that rule also happened to move pixels — a pruning rule that is
// wrong only on paint-invisible properties would sail through green
// forever, which is exactly the gap `surface_style_pruning.dart`'s pruning
// rules are supposed to be checked against.
import 'dart:typed_data';

import '../model/property_snapshot.dart';
import 'pixel_diff.dart';
import 'property_diff.dart';

/// One (prunedKey, baselineKey, platform) verification outcome. Either
/// signal failing means the pair does not deserve its exclusion from the
/// PR-gate manifest — `surface_style_pruning.dart`'s claim that the pruned
/// combination renders pixel-identical to `defaultStyle` was wrong.
class PrunedPairVerifyResult {
  const PrunedPairVerifyResult({
    required this.prunedKey,
    required this.baselineKey,
    required this.platform,
    this.pixelDiff,
    this.propertyDiff,
  });

  final String prunedKey;
  final String baselineKey;
  final String platform;

  /// `null` only when no PNG pair was supplied to [verifyPrunedPair].
  final PixelDiffResult? pixelDiff;

  /// `null` only when no property-snapshot pair was supplied to
  /// [verifyPrunedPair].
  final PropertyDiffResult? propertyDiff;

  /// Whether *both* signals that did run passed. A signal that wasn't run
  /// (its inputs were `null`) contributes no failure of its own — same
  /// convention as `ComparisonResult.passed` in `comparator.dart`.
  bool get passed {
    if (pixelDiff != null && !pixelDiff!.passed) return false;
    if (propertyDiff != null && propertyDiff!.hasFailures) return false;
    return true;
  }

  /// Human-readable failure lines — empty when [passed]. Deliberately does
  /// NOT call `PropertyDiffResult.describeFailures()`/`FieldDivergence
  /// .describe()` verbatim: those label their two sides `flutter=`/`web=`
  /// (this comparison's actual two sides are the *pruned* capture and its
  /// *baseline* capture, same platform) — reusing that formatting here
  /// would mislabel every line.
  List<String> describeFailures() {
    if (passed) return const [];
    final lines = <String>[];
    final pixel = pixelDiff;
    if (pixel != null && !pixel.passed) {
      lines.add('pixel: $pixel');
    }
    final property = propertyDiff;
    if (property != null && property.hasFailures) {
      for (final field in property.failures) {
        lines.add(
          'property ${field.field}: pruned=${field.flutterDescription} '
          'baseline=${field.webDescription}',
        );
      }
    }
    return lines;
  }
}

/// Compares one pruned/baseline pair on one platform. Supply [prunedPng]/
/// [baselinePng] to run PixelDiff, [prunedProperty]/[baselineProperty] to
/// run PropertyDiff — either pair, or both, may be non-null; whichever is
/// supplied runs that signal.
///
/// Reuses [comparePropertySnapshots] (written for a Flutter-vs-Web pair)
/// by passing [prunedProperty] as its `flutter` argument and
/// [baselineProperty] as `web`, with `reconcilePlatforms: false`.
/// [PrunedPairVerifyResult.describeFailures] on the result re-labels the
/// output correctly rather than trusting the reused function's own
/// descriptions.
///
/// The compatibility flag remains explicit for existing callers. Both
/// same-platform and cross-platform comparisons use the captured padding
/// without reconstructing an authored value from the border.
PrunedPairVerifyResult verifyPrunedPair({
  required String prunedKey,
  required String baselineKey,
  required String platform,
  Uint8List? prunedPng,
  Uint8List? baselinePng,
  PropertySnapshot? prunedProperty,
  PropertySnapshot? baselineProperty,
}) {
  // (baseline, pruned) — comparePixels 의 regression 인자 규약(전 → 후)과
  // 일치시킨다. ColorTransition/diff-PNG 배경이 baseline 쪽에서 나와
  // report.dart 의 regression diff 산출물과 같은 의미를 갖는다. ratio 는
  // 대칭이라 판정은 불변.
  final pixelDiff = prunedPng != null && baselinePng != null
      ? comparePixels(baselinePng, prunedPng, mode: .regression)
      : null;

  final propertyDiff = prunedProperty != null && baselineProperty != null
      ? comparePropertySnapshots(
          flutter: prunedProperty,
          web: baselineProperty,
          reconcilePlatforms: false,
        )
      : null;

  return PrunedPairVerifyResult(
    prunedKey: prunedKey,
    baselineKey: baselineKey,
    platform: platform,
    pixelDiff: pixelDiff,
    propertyDiff: propertyDiff,
  );
}
