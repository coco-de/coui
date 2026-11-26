/// Per-instance style for `ScrollableClient`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Platform-neutral per-instance style for the scrollbar skin of a
/// `ScrollableClient`.
///
/// The scrollbar thumb / track dimensions are shared by the Flutter
/// `RawScrollbar` and the Web `::-webkit-scrollbar` skin. Each field is a
/// nullable override that flows through the nested-merge chain:
///
/// ```text
/// design system default (`CoreScrollableClientStyle.defaultX`)
///   → theme.scrollableClient.style
///   → widget per-instance style
/// ```
@immutable
class CoreScrollableClientStyle
    implements CoreStyle<CoreScrollableClientStyle> {
  /// Creates a [CoreScrollableClientStyle].
  const CoreScrollableClientStyle({
    this.scrollbarThickness,
    this.scrollbarRadius,
    this.scrollbarThumbColor,
    this.scrollbarTrackColor,
    this.focusOutlineStyle,
  });

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default scrollbar thumb / track thickness (logical px). Both
  /// platforms convert this to their native unit — Flutter uses it for
  /// `RawScrollbar.thickness`, Web emits a `rem`-based CSS width.
  static const double defaultScrollbarThickness = CoreSpace.space8;

  /// Default scrollbar thumb / track corner radius (logical px).
  static const double defaultScrollbarRadius = CoreRadius.radius4;

  /// Default scrollbar thumb colour — the `onSurface` token at 50 % opacity.
  /// Both platforms emit the same tint (Flutter `RawScrollbar` thumb, Web
  /// `scrollbar-color` thumb + `::-webkit-scrollbar-thumb`).
  static const CoreColor defaultScrollbarThumbColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity50,
  );

  /// Default scrollbar track colour — the `surfaceContainer` token. Used by
  /// the Web `scrollbar-color` track + `::-webkit-scrollbar-track`.
  static const CoreColor defaultScrollbarTrackColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default focus-ring style — a fully filled slot the resolvers use as
  /// the base before merging the per-instance [focusOutlineStyle] on top.
  ///
  /// Every field restates the shared `CoreFocusOutlineStyle` default
  /// rather than picking its own, so the viewport's ring is the same ring
  /// every other focusable component draws. It is filled rather than left
  /// partial because the Web side composes the ring as a scoped
  /// `outline` rule and needs concrete width / offset / colours — the
  /// same reason `CoreButtonStyle.defaultFocusOutlineStyle` is filled.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
      );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Scrollbar thumb / track thickness override (logical px). `null`
  /// defers to [defaultScrollbarThickness].
  final double? scrollbarThickness;

  /// Scrollbar thumb / track corner radius override (logical px).
  /// `null` defers to [defaultScrollbarRadius].
  final double? scrollbarRadius;

  /// Scrollbar thumb colour override. `null` defers to
  /// [defaultScrollbarThumbColor].
  final CoreColor? scrollbarThumbColor;

  /// Scrollbar track colour override. `null` defers to
  /// [defaultScrollbarTrackColor].
  final CoreColor? scrollbarTrackColor;

  /// Focus-ring override for the viewport itself. The viewport takes
  /// keyboard focus (it is scrollable by arrow keys), so it draws the
  /// shared ring — Flutter through `FocusOutline`, Web through a scoped
  /// `:focus-visible` `outline` rule. `null` (or any unset field on
  /// the slot) defers to [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreScrollableClientStyle merge(CoreScrollableClientStyle? other) {
    if (other == null) return this;
    return CoreScrollableClientStyle(
      scrollbarThickness: other.scrollbarThickness ?? scrollbarThickness,
      scrollbarRadius: other.scrollbarRadius ?? scrollbarRadius,
      scrollbarThumbColor: other.scrollbarThumbColor ?? scrollbarThumbColor,
      scrollbarTrackColor: other.scrollbarTrackColor ?? scrollbarTrackColor,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreScrollableClientStyle copyWith({
    double? scrollbarThickness,
    double? scrollbarRadius,
    CoreColor? scrollbarThumbColor,
    CoreColor? scrollbarTrackColor,
    CoreFocusOutlineStyle? focusOutlineStyle,
  }) {
    return CoreScrollableClientStyle(
      scrollbarThickness: scrollbarThickness ?? this.scrollbarThickness,
      scrollbarRadius: scrollbarRadius ?? this.scrollbarRadius,
      scrollbarThumbColor: scrollbarThumbColor ?? this.scrollbarThumbColor,
      scrollbarTrackColor: scrollbarTrackColor ?? this.scrollbarTrackColor,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreScrollableClientStyle &&
          runtimeType == other.runtimeType &&
          other.scrollbarThickness == scrollbarThickness &&
          other.scrollbarRadius == scrollbarRadius &&
          other.scrollbarThumbColor == scrollbarThumbColor &&
          other.scrollbarTrackColor == scrollbarTrackColor &&
          other.focusOutlineStyle == focusOutlineStyle);

  @override
  int get hashCode => Object.hash(
    scrollbarThickness,
    scrollbarRadius,
    scrollbarThumbColor,
    scrollbarTrackColor,
    focusOutlineStyle,
  );
}
