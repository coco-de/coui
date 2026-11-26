/// Per-instance style for `AvatarBadge`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `AvatarBadge` should render.
///
/// `CoreAvatarBadgeStyle` carries chrome / dimensional flat fields for
/// the small circular indicator overlaid on a `Avatar`.
///
/// ```text
/// CoreAvatarBadgeStyle.defaultX
///   → the enclosing Avatar's badgeStyle (its step's size and border)
///   → widget.avatarBadgeStyle
/// ```
@immutable
class CoreAvatarBadgeStyle implements CoreStyle<CoreAvatarBadgeStyle> {
  /// Creates a [CoreAvatarBadgeStyle].
  const CoreAvatarBadgeStyle({
    this.backgroundColor,
    this.size,
    this.borderColor,
    this.borderWidth,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default badge fill colour (`primary`).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default badge diameter (logical px, `size12`) — a badge drawn on its
  /// own. Inside an `Avatar` the avatar hands the badge its step's size
  /// (`CoreAvatarStyle.badgeStyle`, 8 at `xs` up to 20 at `xl2`), which this
  /// default sits under; a [size] the badge states wins over both.
  static const double defaultSize = CoreSize.size12;

  /// Default border colour (`surface`) — the ring that separates the dot
  /// from the photo or the avatar fill it sits on, so a `primary` dot on a
  /// `primaryContainer` disc still reads as its own mark.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default border width (`stroke2`). Inside an `Avatar` the two smallest
  /// steps hand the badge `stroke1` (`CoreAvatarStyle.badgeStyle`) — a 2px
  /// ring would leave a 4px dot of an 8px badge.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke2;

  // ── Chrome (flat) ────────────────────────────

  /// Badge fill colour. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Badge diameter (logical px). `null` → the size the enclosing `Avatar`
  /// hands it, then [defaultSize].
  final double? size;

  /// Colour of the ring drawn inside the dot's edge. `null` →
  /// [defaultBorderColor].
  final CoreColor? borderColor;

  /// Width of the ring drawn inside the dot's edge (logical px). The ring
  /// is painted inward, so the dot keeps its [size]. `null` → the width the
  /// enclosing `Avatar` hands it, then [defaultBorderWidth]; 0 draws none.
  final double? borderWidth;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreAvatarBadgeStyle merge(CoreAvatarBadgeStyle? other) {
    if (other == null) return this;
    return CoreAvatarBadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      size: other.size ?? size,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAvatarBadgeStyle copyWith({
    CoreColor? backgroundColor,
    double? size,
    CoreColor? borderColor,
    double? borderWidth,
  }) {
    return CoreAvatarBadgeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      size: size ?? this.size,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAvatarBadgeStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          size == other.size &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, size, borderColor, borderWidth);
}
