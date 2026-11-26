/// Per-instance style for `Tooltip`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Tooltip` should render.
///
/// `CoreTooltipStyle` carries panel chrome /
/// dimensional / surface-effect overrides as flat fields, plus a
/// nested `CoreTextStyle` for the label slot.
///
/// **Semantic enums (`position`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreTooltipTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.tooltipStyle                          // 인스턴스별
/// ```
@immutable
class CoreTooltipStyle implements CoreStyle<CoreTooltipStyle> {
  /// Creates a [CoreTooltipStyle].
  const CoreTooltipStyle({
    this.panelBackgroundColor,
    this.panelBorderRadius,
    this.panelMaxWidth,
    this.panelPadding,
    this.placementOffset,
    this.tailWidth,
    this.tailHeight,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.labelStyle,
  });

  /// Default panel background fill colour — single source of truth
  /// shared by Flutter (`scheme.resolve(...).toValue()`) and Web
  /// (`bg-${color.tailwindColor}` class / inline `background-color`).
  /// Matches the [panelBackgroundColor] override slot.
  static const CoreColor defaultPanelBackgroundColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default label slot text style — the single source for the label's
  /// typography role (`labelSmall`: 12 Medium) + foreground colour
  /// (`surface`), matched 1:1 with the [labelStyle] nested slot. Both
  /// platforms drive the label from this: Flutter `resolveTypographyRole(theme,
  /// defaultLabelStyle)` + `defaultLabelStyle.color`, Web
  /// `defaultLabelStyle.color` token class. The role states the weight, so
  /// the slot carries no weight overlay of its own. Mirrors
  /// `CoreCheckboxStyle.defaultLabelStyle`.
  // A label role, not a body one — the slot is a control's LABEL.
  // `labelSmall` is 12 / 500 / 1.4, and the tooltip speaks it as it is. The
  // panel is 6 + 16.8 + 6 = 28.8 tall — a hint that sits beside its trigger,
  // not a line of copy.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.surface),
  );

  /// Default panel content padding — single source of truth shared by
  /// Flutter (`.toValue()` → `EdgeInsets`) and Web (inline rem
  /// shorthand). Matches the [panelPadding] override slot.
  static const CoreEdgeInsets defaultPanelPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space10,
    vertical: CoreSpace.space6,
  );

  /// Default panel border radius — single source of truth shared by
  /// Flutter (`.toValue()` → `BorderRadius`) and Web (inline
  /// `border-radius`). Matches the [panelBorderRadius] override slot.
  static const CoreBorderRadius defaultPanelBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default overlay placement offset (logical px) between the trigger
  /// anchor and the floating tooltip panel — single source of truth
  /// shared by Flutter (`Padding` around the bubble) and Web (anchor
  /// rect ± offset for `top` / `left`). Matches the [placementOffset]
  /// override slot.
  static const double defaultPlacementOffset = CoreSpace.space8;

  /// Default tail base width (logical px) — `0`: a tooltip draws no tail.
  /// The triangle edge that sits flush against the panel side facing the
  /// trigger is stated per instance through [tailWidth] together with
  /// [tailHeight]; either axis at `0` removes the tail. Single source
  /// shared by both platforms. Matches the [tailWidth] override slot.
  static const double defaultTailWidth = CoreSpace.space0;

  /// Default tail protrusion height (logical px) — `0`, see
  /// [defaultTailWidth]. How far the triangle tip would extend beyond the
  /// panel edge toward the trigger. Matches the [tailHeight] override
  /// slot.
  static const double defaultTailHeight = CoreSpace.space0;

  // ── Panel chrome (flat) ──────────────────────

  /// Panel background fill colour override.
  final CoreColor? panelBackgroundColor;

  /// Panel border radius override.
  final CoreBorderRadius? panelBorderRadius;

  /// Maximum panel width (logical px) override — the ceiling the bubble
  /// grows to before its content wraps onto another line. Setting it
  /// makes the bubble wrap on both platforms: Flutter constrains the
  /// bubble, Web drops the single-line `white-space: nowrap` it
  /// otherwise carries. `null` leaves the panel unconstrained, and has
  /// no paired `default*` on purpose — a shared ceiling would silently
  /// re-wrap every existing tooltip.
  ///
  /// **Deliberately has no `default*` — absence is the design.** PRE-
  /// EXISTING exemption, already written before this task — left
  /// untouched. Web adds `whitespace-nowrap` only `if (panelMaxWidth ==
  /// null)`, so a shared ceiling would drop nowrap, add an inline max-
  /// width, and silently re-wrap every existing tooltip; Flutter's
  /// ConstrainedBox is likewise mounted only when non-null.
  final double? panelMaxWidth;

  /// Panel content padding override.
  final CoreEdgeInsets? panelPadding;

  /// Overlay placement offset (logical px) override — how far the
  /// floating panel sits from its trigger anchor along the placement
  /// axis (not content padding, not axis spacing).
  final double? placementOffset;

  /// Tail base width override — the triangle edge flush against the
  /// panel side. `0` removes the tail.
  final double? tailWidth;

  /// Tail protrusion height override — how far the tip extends beyond
  /// the panel edge toward the trigger. `0` removes the tail.
  final double? tailHeight;

  /// Backdrop blur sigma applied behind the panel.
  final double? surfaceBlur;

  /// Panel surface opacity multiplier (0.0 – 1.0).
  final double? surfaceOpacity;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override (applied when the contract's
  /// `message` string is rendered). Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `panelForegroundColor` field removed).
  final CoreTextStyle? labelStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested labelStyle is
  /// merged recursively.
  @override
  CoreTooltipStyle merge(
    CoreTooltipStyle? other,
  ) {
    if (other == null) return this;
    return CoreTooltipStyle(
      panelBackgroundColor: other.panelBackgroundColor ?? panelBackgroundColor,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelMaxWidth: other.panelMaxWidth ?? panelMaxWidth,
      panelPadding: other.panelPadding ?? panelPadding,
      placementOffset: other.placementOffset ?? placementOffset,
      tailWidth: other.tailWidth ?? tailWidth,
      tailHeight: other.tailHeight ?? tailHeight,
      surfaceBlur: other.surfaceBlur ?? surfaceBlur,
      surfaceOpacity: other.surfaceOpacity ?? surfaceOpacity,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTooltipStyle copyWith({
    CoreColor? panelBackgroundColor,
    CoreBorderRadius? panelBorderRadius,
    double? panelMaxWidth,
    CoreEdgeInsets? panelPadding,
    double? placementOffset,
    double? tailWidth,
    double? tailHeight,
    double? surfaceBlur,
    double? surfaceOpacity,
    CoreTextStyle? labelStyle,
  }) {
    return CoreTooltipStyle(
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      panelPadding: panelPadding ?? this.panelPadding,
      placementOffset: placementOffset ?? this.placementOffset,
      tailWidth: tailWidth ?? this.tailWidth,
      tailHeight: tailHeight ?? this.tailHeight,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTooltipStyle &&
          runtimeType == other.runtimeType &&
          panelBackgroundColor == other.panelBackgroundColor &&
          panelBorderRadius == other.panelBorderRadius &&
          panelMaxWidth == other.panelMaxWidth &&
          panelPadding == other.panelPadding &&
          placementOffset == other.placementOffset &&
          tailWidth == other.tailWidth &&
          tailHeight == other.tailHeight &&
          surfaceBlur == other.surfaceBlur &&
          surfaceOpacity == other.surfaceOpacity &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    panelBackgroundColor,
    panelBorderRadius,
    panelMaxWidth,
    panelPadding,
    placementOffset,
    tailWidth,
    tailHeight,
    surfaceBlur,
    surfaceOpacity,
    labelStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
