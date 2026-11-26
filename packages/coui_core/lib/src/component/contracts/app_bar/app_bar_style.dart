/// Per-instance style for `AppBar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/app_bar/app_bar_variant.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how an `AppBar` should render.
///
/// Carries every chrome / dimensional override for the bar surface, its
/// leading / title / actions clusters, the bottom hairline divider and
/// the elevated drop shadow. Platform-neutral — Flutter and Web
/// resolvers read the same static defaults so a single source of truth
/// feeds both renders. The hairline is border chrome (like
/// `CoreScaffoldStyle.headerBorderColor`), not a composed `Divider`.
///
/// ```text
/// design system default (CoreAppBarStyle.defaultX / defaultsByVariant)
///   → CoreAppBarTheme.style                    // 프로젝트 공통
///   → CoreAppBarTheme.variantStyles[variant]   // 프로젝트 per-variant
///   → widget.appBarStyle                       // 인스턴스별
/// ```
@immutable
class CoreAppBarStyle implements CoreStyle<CoreAppBarStyle> {
  /// Creates a [CoreAppBarStyle].
  const CoreAppBarStyle({
    this.surfaceStyle,
    this.backgroundColor,
    this.padding,
    this.spacing,
    this.actionSpacing,
    this.height,
    this.topRowHeight,
    this.titleStyle,
    this.titlePadding,
    this.dividerColor,
    this.dividerWidth,
    this.elevatedShadow,
  });

  /// Material of the bar (e.g. glass), set without changing its colours,
  /// text or sizes. `null` keeps the material of whatever surrounds the
  /// bar; `defaultStyle` turns glass off.
  ///
  /// Theme, variant and instance overrides use the usual merge chain.
  /// Deliberately no default: null inherits the active theme material axis;
  /// a fixed default would override that axis before the resolver sees it.
  final CoreSurfaceStyleId? surfaceStyle;

  // ═══════════════════════════════════════════════════
  // 1. Defaults — variant-independent chrome
  // ═══════════════════════════════════════════════════

  /// Default bar surface colour — the designer set binds the root fill of
  /// standard, compact, medium and prominent to `color/surface`. Dense is the
  /// exception: its [defaultsByVariant] row states its own face.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default horizontal bar inset (8) — the cluster row of the variants
  /// whose [defaultsByVariant] entry states no `padding` (the root for
  /// standard, the 48px top row for medium).
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// Default gap between the leading / title / actions clusters
  /// (logical px) — the designer set's root auto-layout gap is 4. Read by
  /// the variants whose [defaultsByVariant] entry states no `spacing`
  /// (every variant but dense).
  static const double defaultSpacing = CoreSpace.space4;

  /// Default gap between adjacent action widgets inside the trailing
  /// cluster (logical px) — the designer set's actions cluster gap is 4.
  /// Same value as [defaultSpacing] but a separate field: a caller must
  /// be able to widen one without moving the other. Read by the variants
  /// whose [defaultsByVariant] entry states no `actionSpacing` (every
  /// variant but dense).
  static const double defaultActionSpacing = CoreSpace.space4;

  /// Native glass chrome belongs to action capsules, not the title host.
  /// Shared by Flutter and DOM so both use the same hit area and silhouette.
  static const double glassActionMinSize = CoreSize.size44;

  /// Scroll distance over which the soft edge gains contrast.
  static const double glassScrollEdgeDistance = CoreSpace.space24;

  /// One optical surface for a contiguous cluster of toolbar actions.
  ///
  /// The cluster is translucent glass, not a floating panel, so it keeps the
  /// quiet `outlineSubtle` line instead of following the `Popup` panel line
  /// (`outlineVariant`) — a darker line would break the glass reading. The
  /// line is stated here, in the AppBar's own default, rather than in a
  /// resolver, so both platforms read the same value.
  ///
  /// Written out as a `const` (the Figma exporter reads defaults from const
  /// initialisers) and pinned to
  /// `CoreToolbarGroupContract.glassPopupStyle` plus that one line by a test,
  /// so the shared glass capsule geometry cannot drift from this copy.
  static const CorePopupStyle glassActionStyle = CorePopupStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    padding: CoreEdgeInsets.zero,
    borderWidth: 0,
    borderColor: CoreColor.token(CoreColors.outlineSubtle),
    minWidth: 0,
    maxWidth: double.infinity,
    spacing: 0,
    boxShadow: CoreShadow.sm,
  );

  /// Default height of the medium variant's top row (logical px) — the
  /// designer set measures the leading + actions row at h=48. Consumed
  /// only by the medium render branch.
  static const double defaultTopRowHeight = CoreSize.size48;

  /// Default colour of the bottom hairline — the designer set fills the
  /// divider rectangle with `color/outline-variant`. Same shape as
  /// `CoreScaffoldStyle.defaultHeaderBorderColor` (hairline is border
  /// chrome, not a composed `Divider`).
  static const CoreColor defaultDividerColor = CoreColor.token(
    CoreColors.outlineVariant,
    fallbacks: [CoreColors.outline],
  );

  /// Default thickness of the bottom hairline (logical px) — the
  /// designer set's divider rectangle is 1px tall.
  static const double defaultDividerWidth = CoreStrokeWidth.stroke1;

  /// Default drop shadow shown while `elevated` is on — the designer
  /// set's two measured layers (0,2,4,-1) + (0,1,2,0) are exactly
  /// [CoreShadow.sm].
  static const List<CoreShadowLayer> defaultElevatedShadow = CoreShadow.sm;

  // ═══════════════════════════════════════════════════
  // 2. Defaults — variant-keyed
  // ═══════════════════════════════════════════════════

  /// Per-variant default chrome — single source of truth shared by the
  /// Flutter and Web resolvers. The map value is [CoreAppBarStyle]
  /// itself so the flat slot fields stay 1:1 with the per-variant
  /// defaults (checkbox `defaultsBySize` precedent). Heights and title
  /// typography are the designer set's measurements: standard 64 /
  /// compact 56 / medium 112 / dense 48, title `titleMedium` (standard /
  /// compact) vs `titleLarge` bottom-aligned with a 16/16/12 inset
  /// (medium) — those three use the code typography roles verbatim.
  /// Compact and dense state a bar `padding` (16); standard and medium
  /// leave it unset and read [defaultPadding].
  ///
  /// Prominent is the one-line large title of a tab's first screen: the
  /// compact height (56) with a `headlineSmall` title. The title starts 20
  /// in from the bar edge — a 4 bar `padding` plus a 16 title inset — so a
  /// words-only action (a ghost `Button`, whose own inset is 16) ends 20
  /// in from the other edge. The bar states no face or gap of its own.
  ///
  /// Dense is the desktop title bar: one row of 32px controls with 8
  /// above and below. It sits on the chrome tier (`surfaceContainerLow`)
  /// instead of `surface`, spreads its clusters 14 apart with 8 between
  /// actions, sets a `labelLarge` title at semibold, and states no title
  /// inset — the cluster gap is the only distance between the title and
  /// its neighbours. The semibold overlay is why this map is `final`.
  static final Map<CoreAppBarVariant, CoreAppBarStyle> defaultsByVariant = {
    CoreAppBarVariant.standard: const CoreAppBarStyle(
      height: CoreSize.size64,
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      titlePadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
    ),
    CoreAppBarVariant.compact: const CoreAppBarStyle(
      height: CoreSize.size56,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      titlePadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
    ),
    CoreAppBarVariant.medium: const CoreAppBarStyle(
      height: CoreSize.size112,
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      titlePadding: CoreEdgeInsets.only(
        left: CoreSpace.space16,
        right: CoreSpace.space16,
        bottom: CoreSpace.space12,
      ),
    ),
    CoreAppBarVariant.dense: CoreAppBarStyle(
      backgroundColor: const CoreColor.token(CoreColors.surfaceContainerLow),
      padding: const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
      spacing: CoreSpace.space14,
      actionSpacing: CoreSpace.space8,
      height: CoreSize.size48,
      titleStyle: const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.semiBold),
      titlePadding: CoreEdgeInsets.zero,
    ),
    CoreAppBarVariant.prominent: const CoreAppBarStyle(
      height: CoreSize.size56,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4),
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.headlineSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      titlePadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
    ),
  };

  // ═══════════════════════════════════════════════════
  // 3. Props
  // ═══════════════════════════════════════════════════

  /// Bar surface colour override. `null` defers to the active variant's
  /// entry in [defaultsByVariant], then to [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Horizontal bar inset override — the outer inset of the cluster row
  /// (the root for standard / compact / dense / prominent, the top row for
  /// medium). `null` defers to the active variant's entry in
  /// [defaultsByVariant], then to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Gap between the leading / title / actions clusters (logical px).
  /// Mirrors Flutter `Row.spacing` between the clusters. `null` defers
  /// to the active variant's entry in [defaultsByVariant], then to
  /// [defaultSpacing].
  final double? spacing;

  /// Gap between adjacent widgets inside the leading or trailing action
  /// cluster (logical px). Mirrors Flutter `Row.spacing` applied to each
  /// cluster. `null` defers to the active variant's entry in
  /// [defaultsByVariant], then to [defaultActionSpacing].
  final double? actionSpacing;

  /// Total bar height override (logical px). `null` defers to the
  /// active variant's entry in [defaultsByVariant].
  final double? height;

  /// Height of the medium variant's top row (logical px). Consumed only
  /// by the medium render branch. `null` defers to [defaultTopRowHeight].
  final double? topRowHeight;

  /// Title typography override. Text colour is carried via
  /// `CoreTextStyle.color` inside this slot. `null` (or any unset
  /// field) defers to the active variant's entry in [defaultsByVariant].
  final CoreTextStyle? titleStyle;

  /// Inset of the title block. `null` defers to the active variant's
  /// entry in [defaultsByVariant].
  final CoreEdgeInsets? titlePadding;

  /// Bottom hairline colour override. `null` defers to
  /// [defaultDividerColor].
  final CoreColor? dividerColor;

  /// Bottom hairline thickness override (logical px). `null` defers to
  /// [defaultDividerWidth].
  final double? dividerWidth;

  /// Drop shadow shown while `elevated` is on. `null` defers to
  /// [defaultElevatedShadow].
  final List<CoreShadowLayer>? elevatedShadow;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. The nested [titleStyle] slot is merged
  /// recursively so a partial override only affects the fields it
  /// specifies.
  @override
  CoreAppBarStyle merge(CoreAppBarStyle? other) {
    if (other == null) return this;
    return CoreAppBarStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      spacing: other.spacing ?? spacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      height: other.height ?? height,
      topRowHeight: other.topRowHeight ?? topRowHeight,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      titlePadding: other.titlePadding ?? titlePadding,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      elevatedShadow: other.elevatedShadow ?? elevatedShadow,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAppBarStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreColor? backgroundColor,
    CoreEdgeInsets? padding,
    double? spacing,
    double? actionSpacing,
    double? height,
    double? topRowHeight,
    CoreTextStyle? titleStyle,
    CoreEdgeInsets? titlePadding,
    CoreColor? dividerColor,
    double? dividerWidth,
    List<CoreShadowLayer>? elevatedShadow,
  }) {
    return CoreAppBarStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      spacing: spacing ?? this.spacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      height: height ?? this.height,
      topRowHeight: topRowHeight ?? this.topRowHeight,
      titleStyle: titleStyle ?? this.titleStyle,
      titlePadding: titlePadding ?? this.titlePadding,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerWidth: dividerWidth ?? this.dividerWidth,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAppBarStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          backgroundColor == other.backgroundColor &&
          padding == other.padding &&
          spacing == other.spacing &&
          actionSpacing == other.actionSpacing &&
          height == other.height &&
          topRowHeight == other.topRowHeight &&
          titleStyle == other.titleStyle &&
          titlePadding == other.titlePadding &&
          dividerColor == other.dividerColor &&
          dividerWidth == other.dividerWidth &&
          _shadowEq(elevatedShadow, other.elevatedShadow);

  @override
  int get hashCode => Object.hash(
    surfaceStyle,
    backgroundColor,
    padding,
    spacing,
    actionSpacing,
    height,
    topRowHeight,
    titleStyle,
    titlePadding,
    dividerColor,
    dividerWidth,
    elevatedShadow == null ? null : Object.hashAll(elevatedShadow!),
  );

  static bool _shadowEq(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
