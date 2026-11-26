/// Per-instance style for `AvatarGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `AvatarGroup` should render.
///
/// `CoreAvatarGroupStyle` carries chrome / dimensional flat fields for
/// the overlapping group container — both the per-item border that
/// separates overlapping avatars from each other and the negative gap
/// that controls overlap distance.
///
/// ```text
/// CoreAvatarGroupStyle.defaultX
///   → parent component slot override
///   → widget.avatarGroupStyle
/// ```
@immutable
class CoreAvatarGroupStyle implements CoreStyle<CoreAvatarGroupStyle> {
  /// Creates a [CoreAvatarGroupStyle].
  const CoreAvatarGroupStyle({
    this.extraSpacing,
    this.overlap,
    this.borderColor,
    this.borderWidth,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default extra positive offset added on top of the negative
  /// `overlap` translation (logical px). 0 by default — the overlapping
  /// group has no positive whitespace between avatars.
  static const double defaultExtraSpacing = 0;

  /// Default overlap distance between adjacent avatars (logical px).
  ///
  /// Matches the legacy Flutter `_kDefaultOverlapSpacing` and the Web
  /// `-space-x-4` token (4 × 4px = 16px).
  static const double defaultOverlap = CoreSpace.space16;

  /// Default per-item separator border colour (`surface`). Renders the
  /// background colour so adjacent avatars look separated.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default per-item separator border width (`stroke2` = 2px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke2;

  // ── Chrome (flat) ────────────────────────────

  /// Extra positive paint-time offset added on top of the negative
  /// [overlap] translation (logical px). `null` → [defaultExtraSpacing].
  ///
  /// Unlike a structural sibling gap (which would map to native
  /// `Row.spacing` / `column-gap`), this is a per-item paint-time
  /// offset multiplier — the Flutter `Transform.translate` adds
  /// `extraSpacing * i` and the Web inline `column-gap` re-injects the
  /// same positive value on top of the negative `-space-x-*` token.
  final double? extraSpacing;

  /// Overlap distance between adjacent avatars (logical px). Renders
  /// as a negative offset — bigger value = more overlap. `null` →
  /// [defaultOverlap].
  final double? overlap;

  /// Per-item separator border colour. `null` → [defaultBorderColor].
  final CoreColor? borderColor;

  /// Per-item separator border width (logical px). `null` →
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreAvatarGroupStyle merge(CoreAvatarGroupStyle? other) {
    if (other == null) return this;
    return CoreAvatarGroupStyle(
      extraSpacing: other.extraSpacing ?? extraSpacing,
      overlap: other.overlap ?? overlap,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAvatarGroupStyle copyWith({
    double? extraSpacing,
    double? overlap,
    CoreColor? borderColor,
    double? borderWidth,
  }) {
    return CoreAvatarGroupStyle(
      extraSpacing: extraSpacing ?? this.extraSpacing,
      overlap: overlap ?? this.overlap,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAvatarGroupStyle &&
          runtimeType == other.runtimeType &&
          extraSpacing == other.extraSpacing &&
          overlap == other.overlap &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode =>
      Object.hash(extraSpacing, overlap, borderColor, borderWidth);
}
