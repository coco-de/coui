/// Per-instance style for `FadeScroll`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `FadeScroll` should render.
///
/// `CoreFadeScrollStyle` carries every chrome / dimensional override for
/// the unified fade-scroll component. Behavioural fields (`child`,
/// `controller`, `showScrollbar`) and the semantic enum (`direction`)
/// remain flat on the widget — they are not chrome.
///
/// Defaults live as `static const` fields on this class (Phase 6f
/// option D — single source of truth shared by Flutter and Web).
///
/// ```text
/// CoreFadeScrollStyle.defaultX             ← static const default
///   → CoreComponentTheme.fadeScroll.style  ← project-level override
///   → widget.fadeScrollStyle               ← per-instance override
/// ```
@immutable
class CoreFadeScrollStyle implements CoreStyle<CoreFadeScrollStyle> {
  /// Creates a [CoreFadeScrollStyle].
  const CoreFadeScrollStyle({
    this.startOffset,
    this.endOffset,
    this.gradient,
  });

  // ─── Design-system defaults (Phase 6f option D) ────────────────────
  //
  // Variant-independent defaults — `FadeScroll` has no variant enum so
  // there is no `defaultsByVariant` map.

  /// Default start-edge fade ramp length in logical pixels.
  ///
  /// Single source of truth shared by Flutter and Web. Picking
  /// [CoreSpace.space40] matches the legacy `_kFadeScrollDefaultOffset`
  /// value used by both platforms.
  static const double defaultStartOffset = CoreSpace.space40;

  /// Default end-edge fade ramp length in logical pixels.
  static const double defaultEndOffset = CoreSpace.space40;

  /// Default gradient stops applied to the fade.
  ///
  /// The list is interpolated from the visible edge inward. The fade
  /// mask is monochrome (only alpha matters); the default ramps from
  /// fully-opaque to fully-transparent so the edge cleanly dissolves.
  /// Flutter applies the colours via `LinearGradient` / `ShaderMask`;
  /// Web applies them via `mask-image: linear-gradient(...)`.
  static const List<CoreColor> defaultGradient = [
    CoreColor.token(CoreColors.onSurface),
    CoreColor.transparent,
  ];

  // ─── Fields ────────────────────────────────────────────────────────

  /// Pixel offset from the start edge over which the fade ramps up.
  final double? startOffset;

  /// Pixel offset from the end edge over which the fade ramps down.
  final double? endOffset;

  /// Optional gradient color stops applied to the fade. The list is
  /// interpolated from the visible edge inward.
  final List<CoreColor>? gradient;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreFadeScrollStyle merge(CoreFadeScrollStyle? other) {
    if (other == null) return this;
    return CoreFadeScrollStyle(
      startOffset: other.startOffset ?? startOffset,
      endOffset: other.endOffset ?? endOffset,
      gradient: other.gradient ?? gradient,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFadeScrollStyle copyWith({
    double? startOffset,
    double? endOffset,
    List<CoreColor>? gradient,
  }) {
    return CoreFadeScrollStyle(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreFadeScrollStyle) return false;
    if (other.startOffset != startOffset) return false;
    if (other.endOffset != endOffset) return false;
    final a = gradient;
    final b = other.gradient;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    startOffset,
    endOffset,
    Object.hashAll(gradient ?? const []),
  );
}
