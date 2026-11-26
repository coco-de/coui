/// Per-instance style for `Skeleton`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/skeleton/skeleton_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Skeleton` should render.
///
/// `CoreSkeletonStyle` is **platform-neutral** (Epic #1415 option D /
/// Phase 6f). Every chrome / dimensional / animation field is exposed
/// as a nullable override that flows through the nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → theme.skeleton.style
///   → parent component slot override
///   → widget.skeletonStyle
/// ```
///
/// Semantic enums (`variant`) and behavioural fields
/// (`width` / `height`) stay flat on the widget — see
/// Epic #1302 원칙 6/7.
///
/// **D-cat reclassification (Epic #2228)**: the inter-line spacing
/// between text-variant lines is a **N-sibling uniform distribution**
/// (for-loop interleave with the same gap between every pair of
/// adjacent lines). Per the 4-principle naming sub-rule it is
/// rendered through the native paint API — `Column(spacing:)` on
/// Flutter and `row-gap` inline CSS on Web — and exposed as a flat
/// `double? lineSpacing` (not a `CoreGapStyle?` slot).
@immutable
class CoreSkeletonStyle implements CoreStyle<CoreSkeletonStyle> {
  /// Creates a [CoreSkeletonStyle].
  const CoreSkeletonStyle({
    this.backgroundColor,
    this.borderRadius,
    this.lineSpacing,
    this.lineHeight,
    this.lastLineWidth,
    this.lines,
    this.duration,
    this.curve,
    this.fromOpacity,
    this.toOpacity,
  });

  // ─── Design-system defaults (Phase 6f / 6g) ───────────────────────
  // Variant-independent defaults live here as static const.
  // Variant-dependent chrome (background colour + border radius) is
  // supplied by [defaultsByVariant].

  /// Default length of one full pulse — rest → peak → rest.
  ///
  /// Display tier (`core/design-tokens.md`): the pulse says how long the
  /// placeholder keeps cycling, not how fast something moves, so a
  /// reduced-motion transition override does not shorten it. Reduced
  /// motion stops the pulse instead — at its resting end — through
  /// `CoreReducedMotion.runsPlaceholderPulse`.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.ms2000,
  );

  /// Default easing of each half of the pulse.
  ///
  /// [CoreEasing.move] — the alias for a change between two resting
  /// states, which is what each half is (rest → peak, then peak → rest).
  static const CoreCubicBezier defaultCurve = CoreEasing.move;

  /// Default pulse animation start opacity — the resting end of the pulse.
  ///
  /// At its faintest the pulse still has to read against the surface the fill
  /// stands on: 70% keeps it visible there, and the swing is 70 ↔ 100.
  static const double defaultFromOpacity = CoreOpacity.opacity70;

  /// Default pulse animation end opacity.
  static const double defaultToOpacity = 1;

  /// Default gap between text-variant lines (logical px) — consumed by
  /// the native `Column.spacing` paint-API (Epic #1659 D-cat — N-sibling
  /// uniform distribution pattern). 12 logical px — with the 12px line
  /// height that is a 24px pitch, close to the line box of body text
  /// (19.5–22.5 across 13–15px).
  static const double defaultLineSpacing = CoreSpace.space12;

  /// Default per-line height for the text variant (logical px), 12px — a bar
  /// the height of a body-text glyph run rather than of its whole line box.
  /// The single Core source used by both the Flutter and Web resolvers.
  static const double defaultLineHeight = CoreSize.size12;

  /// Default width fraction of the last line in text variant.
  static const double defaultLastLineWidth = 0.6;

  /// Default number of lines for text variant.
  static const int defaultLines = 3;

  /// Skeleton fill (background) colour override.
  final CoreColor? backgroundColor;

  /// Border radius override.
  final CoreBorderRadius? borderRadius;

  /// Gap between text-variant lines (logical px) — applied to the
  /// native `Column.spacing` paint-API on Flutter and to the flex
  /// `row-gap` inline CSS on Web. `null` defers to
  /// [defaultLineSpacing].
  final double? lineSpacing;

  /// Per-line height for the text variant (logical px). `null` defers to
  /// [defaultLineHeight]. Applied as `Container.height` on Flutter and
  /// inline `height` CSS on Web.
  final double? lineHeight;

  /// Width fraction of the last line in text variant (0.0–1.0).
  final double? lastLineWidth;

  /// Default number of lines for text variant.
  final int? lines;

  /// Length of one full pulse — rest → peak → rest — on both platforms.
  /// `null` → [defaultDuration].
  ///
  /// One value, one meaning: Web runs it as the keyframe cycle and Flutter
  /// as one controller period split into the same two halves, so the same
  /// override pulses at the same speed everywhere.
  final Duration? duration;

  /// Easing of each half of the pulse, as cubic-bezier control points —
  /// applied forward to rest → peak and again to peak → rest, the way a
  /// CSS timing function applies per keyframe interval. `null` →
  /// [defaultCurve].
  final CoreCubicBezier? curve;

  /// Pulse animation start opacity (0.0–1.0), multiplied into the fill's
  /// own alpha at the resting end — a transparent fill stays transparent.
  final double? fromOpacity;

  /// Pulse animation end opacity (0.0–1.0), multiplied into the fill's own
  /// alpha at the peak.
  final double? toOpacity;

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] /
  /// [CoreBorderRadius] via its own extension (`.toValue()`).
  ///
  /// The fill is `surfaceContainerHighest` for all three: a placeholder has
  /// to read on a white page and on a filled container alike, where
  /// `surfaceContainer` vanished. It stops short of a 3:1 block — the
  /// loading announcement carries accessibility, the fill only has to be
  /// seen. A box takes corner 8, which sits with the 40px-high controls and
  /// list rows its default size stands in for; a text line is a 12px bar and
  /// takes corner 4; a circle is full. Which corner role a skeleton belongs
  /// to is not decided here — the element it stands for gets its own corner
  /// from the caller.
  static const Map<CoreSkeletonVariant, CoreSkeletonVariantStyle>
  defaultsByVariant = {
    CoreSkeletonVariant.rectangular: CoreSkeletonVariantStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
    ),
    CoreSkeletonVariant.circular: CoreSkeletonVariantStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
    ),
    CoreSkeletonVariant.text: CoreSkeletonVariantStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
    ),
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreSkeletonStyle merge(CoreSkeletonStyle? other) {
    if (other == null) return this;
    return CoreSkeletonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      lineSpacing: other.lineSpacing ?? lineSpacing,
      lineHeight: other.lineHeight ?? lineHeight,
      lastLineWidth: other.lastLineWidth ?? lastLineWidth,
      lines: other.lines ?? lines,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      fromOpacity: other.fromOpacity ?? fromOpacity,
      toOpacity: other.toOpacity ?? toOpacity,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSkeletonStyle copyWith({
    CoreColor? backgroundColor,
    CoreBorderRadius? borderRadius,
    double? lineSpacing,
    double? lineHeight,
    double? lastLineWidth,
    int? lines,
    Duration? duration,
    CoreCubicBezier? curve,
    double? fromOpacity,
    double? toOpacity,
  }) {
    return CoreSkeletonStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      lastLineWidth: lastLineWidth ?? this.lastLineWidth,
      lines: lines ?? this.lines,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      fromOpacity: fromOpacity ?? this.fromOpacity,
      toOpacity: toOpacity ?? this.toOpacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSkeletonStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderRadius == other.borderRadius &&
          lineSpacing == other.lineSpacing &&
          lineHeight == other.lineHeight &&
          lastLineWidth == other.lastLineWidth &&
          lines == other.lines &&
          duration == other.duration &&
          curve == other.curve &&
          fromOpacity == other.fromOpacity &&
          toOpacity == other.toOpacity;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderRadius,
    lineSpacing,
    lineHeight,
    lastLineWidth,
    lines,
    duration,
    curve,
    fromOpacity,
    toOpacity,
  );
}

/// Variant-dependent chrome (border-radius + background colour).
///
/// Defines border-radius and background colour per variant. All values
/// are platform-neutral ([CoreColor] / [CoreBorderRadius]); the
/// consuming renderer converts at use-site via `.toValue()`.
@immutable
class CoreSkeletonVariantStyle {
  /// Creates a skeleton variant style.
  const CoreSkeletonVariantStyle({
    required this.borderRadius,
    required this.backgroundColor,
  });

  /// Default border radius.
  final CoreBorderRadius borderRadius;

  /// Default background colour.
  final CoreColor backgroundColor;
}
