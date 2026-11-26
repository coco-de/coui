/// Per-instance style for `Status`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/status/status_contract.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Status` should render.
///
/// `CoreStatusStyle` is **platform-neutral** (Epic #1415 option D /
/// Phase 6f). Chrome / dimensional overrides flow through the
/// nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX` /
///   `defaultsBySize[size]` / `defaultsByColor[color]`)
///   → CoreStatusTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget.statusStyle                             // 인스턴스별
/// ```
///
/// Behavioural / semantic enums (`color`, `size`, `semanticLabel`)
/// stay flat on the widget / contract (Epic #1302 원칙 6/7).
@immutable
class CoreStatusStyle implements CoreStyle<CoreStatusStyle> {
  /// Creates a [CoreStatusStyle].
  const CoreStatusStyle({
    this.size,
    this.color,
    this.borderRadius,
    this.ringWidth,
    this.barLength,
    this.barWidth,
    this.barColor,
    this.barBorderRadius,
    this.labelStyle,
    this.labelSpacing,
  });

  // ─── Design-system defaults (Phase 6f / 6g, Epic #1696 Phase 4) ──
  // Size-variant defaults live in [defaultsBySize]; colour-variant
  // defaults live in [defaultsByColor]. Both are single sources of
  // truth shared by Flutter (resolves through the active
  // `CoreColorScheme`) and Web (stringifies `CoreColor` token names
  // into `bg-${token}` Tailwind class fragments).

  /// Per-[CoreStatusSize] preset dot diameter (logical px). Each entry
  /// is a [CoreStatusStyle] whose only set field is [size] — the
  /// resolver reads `defaultsBySize[size]!.size!` when the user has
  /// not overridden [size] directly.
  ///
  /// Value type is [CoreStatusStyle] itself (not a record) so the
  /// 1:1:1:1 mapping between `CoreStatusStyle` field and per-size
  /// default is preserved without a separate holder shape.
  static const Map<CoreStatusSize, CoreStatusStyle> defaultsBySize = {
    CoreStatusSize.xs: CoreStatusStyle(
      size: CoreSize.size6,
      barLength: CoreSize.size4,
      labelStyle: CoreTextStyle.token(
        CoreTextStyles.bodyXs,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      labelSpacing: CoreSpace.space4,
    ),
    CoreStatusSize.sm: CoreStatusStyle(
      size: CoreSize.size8,
      barLength: CoreSize.size4,
      labelStyle: CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      labelSpacing: CoreSpace.space6,
    ),
    CoreStatusSize.md: CoreStatusStyle(
      size: CoreSize.size10,
      barLength: CoreSize.size6,
      labelStyle: CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      labelSpacing: CoreSpace.space6,
    ),
    CoreStatusSize.lg: CoreStatusStyle(
      size: CoreSize.size12,
      barLength: CoreSize.size8,
      labelStyle: CoreTextStyle.token(
        CoreTextStyles.bodyLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      labelSpacing: CoreSpace.space8,
    ),
    CoreStatusSize.xl: CoreStatusStyle(
      size: CoreSize.size14,
      barLength: CoreSize.size8,
      labelStyle: CoreTextStyle.token(
        CoreTextStyles.bodyLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      labelSpacing: CoreSpace.space8,
    ),
  };

  /// Per-[CoreStatusVariant] preset colour. A state draws with the same
  /// semantic colours the plain dot offers — success, destructive (error),
  /// warning, neutral — so the two ways of colouring a dot never disagree.
  static const Map<CoreStatusVariant, CoreStatusStyle> defaultsByVariant = {
    CoreStatusVariant.online: CoreStatusStyle(
      color: CoreColor.token(CoreColors.success),
    ),
    CoreStatusVariant.busy: CoreStatusStyle(
      color: CoreColor.token(CoreColors.error),
    ),
    CoreStatusVariant.away: CoreStatusStyle(
      color: CoreColor.token(CoreColors.warning),
    ),
    // The ring is `outline` (the designer's answer: not on-surface-variant);
    // the label of this state alone reads `on-surface-variant`, every other
    // state keeps the size row's `on-surface`.
    CoreStatusVariant.offline: CoreStatusStyle(
      color: CoreColor.token(CoreColors.outline),
      labelStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
  };

  /// Default stroke of a ring state (`away`, `offline`).
  static const double defaultRingWidth = CoreStrokeWidth.stroke2;

  /// Default thickness of the bar across a `busy` dot.
  static const double defaultBarWidth = CoreStrokeWidth.stroke2;

  /// Default colour of the bar across a `busy` dot — the content colour that
  /// sits on the destructive fill.
  static const CoreColor defaultBarColor = CoreColor.token(
    CoreColors.onError,
  );

  /// Default corners of the bar across a `busy` dot — fully round, so the
  /// bar's ends are half its thickness (1 at the default [defaultBarWidth]
  /// of 2) and stay round when [barWidth] is stated. Both platforms clamp the
  /// full radius to the bar's half-height.
  static const CoreBorderRadius defaultBarBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Per-[CoreStatusColor] preset indicator colour. Each entry is a
  /// [CoreStatusStyle] whose only set field is [color] — the resolver
  /// reads `defaultsByColor[color]!.color!` when the user has not
  /// overridden [color] directly.
  ///
  /// Value type is [CoreStatusStyle] itself (not a record) so the
  /// 1:1:1:1 mapping between `CoreStatusStyle` field and per-colour
  /// default is preserved without a separate holder shape.
  static const Map<CoreStatusColor, CoreStatusStyle> defaultsByColor = {
    CoreStatusColor.neutral: CoreStatusStyle(
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
    CoreStatusColor.primary: CoreStatusStyle(
      color: CoreColor.token(CoreColors.primary),
    ),
    CoreStatusColor.secondary: CoreStatusStyle(
      color: CoreColor.token(CoreColors.secondary),
    ),
    CoreStatusColor.tertiary: CoreStatusStyle(
      color: CoreColor.token(CoreColors.tertiary),
    ),
    CoreStatusColor.info: CoreStatusStyle(
      color: CoreColor.token(CoreColors.info),
    ),
    CoreStatusColor.success: CoreStatusStyle(
      color: CoreColor.token(CoreColors.success),
    ),
    CoreStatusColor.warning: CoreStatusStyle(
      color: CoreColor.token(CoreColors.warning),
    ),
    CoreStatusColor.error: CoreStatusStyle(
      color: CoreColor.token(CoreColors.error),
    ),
  };

  /// Default status dot border radius (pill / circle shape). The dot
  /// is a square box, so the full radius renders a perfect circle on
  /// both platforms — Flutter maps it through `CoreBorderRadius.
  /// toValue()` → `BorderRadius`, Web emits it inline as the
  /// `border-radius` CSS shorthand (Epic #1603 single-signature gate —
  /// radius is always-inline, never a `rounded-*` class).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Status dot size (logical px). When set, it replaces the size
  /// [defaultsBySize] gives the dot's size variant.
  ///
  /// Raw double — single-axis pixel value (verify.md u-1 exception).
  final double? size;

  /// Status dot colour. When set, it replaces the colour [defaultsByColor]
  /// gives the dot's colour variant.
  final CoreColor? color;

  /// Status dot border radius override. When non-null, overrides
  /// [defaultBorderRadius] (the full pill / circle radius).
  final CoreBorderRadius? borderRadius;

  /// Stroke of a ring state. `null` → [defaultRingWidth].
  final double? ringWidth;

  /// Length of the bar across a `busy` dot — the bar's width as the eye reads
  /// it, running across the dot (the designer's "막대 폭"); [barWidth] is its
  /// thickness. `null` → the size row's value in [defaultsBySize]: 4 · 4 · 6 ·
  /// 8 · 8 from xs to xl.
  final double? barLength;

  /// Thickness of the bar across a `busy` dot. `null` → [defaultBarWidth].
  final double? barWidth;

  /// Colour of the bar across a `busy` dot. `null` → [defaultBarColor].
  final CoreColor? barColor;

  /// Corners of the bar across a `busy` dot. `null` →
  /// [defaultBarBorderRadius] (round ends — half the bar's thickness).
  final CoreBorderRadius? barBorderRadius;

  /// Text style of the visible label. `null` → the size row's role in
  /// [defaultsBySize] (xs 12 · sm 13 · md 14 · lg, xl 15 — the body roles)
  /// in `on-surface`, merged with the state's own label colour in
  /// [defaultsByVariant] (`offline` reads `on-surface-variant`).
  final CoreTextStyle? labelStyle;

  /// Space between the dot and the visible label. `null` → the size row's
  /// value in [defaultsBySize].
  final double? labelSpacing;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreStatusStyle merge(CoreStatusStyle? other) {
    if (other == null) return this;
    return CoreStatusStyle(
      size: other.size ?? size,
      color: other.color ?? color,
      borderRadius: other.borderRadius ?? borderRadius,
      ringWidth: other.ringWidth ?? ringWidth,
      barLength: other.barLength ?? barLength,
      barWidth: other.barWidth ?? barWidth,
      barColor: other.barColor ?? barColor,
      barBorderRadius: other.barBorderRadius ?? barBorderRadius,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      labelSpacing: other.labelSpacing ?? labelSpacing,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStatusStyle copyWith({
    double? size,
    CoreColor? color,
    CoreBorderRadius? borderRadius,
    double? ringWidth,
    double? barLength,
    double? barWidth,
    CoreColor? barColor,
    CoreBorderRadius? barBorderRadius,
    CoreTextStyle? labelStyle,
    double? labelSpacing,
  }) {
    return CoreStatusStyle(
      size: size ?? this.size,
      color: color ?? this.color,
      borderRadius: borderRadius ?? this.borderRadius,
      ringWidth: ringWidth ?? this.ringWidth,
      barLength: barLength ?? this.barLength,
      barWidth: barWidth ?? this.barWidth,
      barColor: barColor ?? this.barColor,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      labelStyle: labelStyle ?? this.labelStyle,
      labelSpacing: labelSpacing ?? this.labelSpacing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStatusStyle &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          color == other.color &&
          borderRadius == other.borderRadius &&
          ringWidth == other.ringWidth &&
          barLength == other.barLength &&
          barWidth == other.barWidth &&
          barColor == other.barColor &&
          barBorderRadius == other.barBorderRadius &&
          labelStyle == other.labelStyle &&
          labelSpacing == other.labelSpacing;

  @override
  int get hashCode => Object.hash(
    size,
    color,
    borderRadius,
    ringWidth,
    barLength,
    barWidth,
    barColor,
    barBorderRadius,
    labelStyle,
    labelSpacing,
  );
}
