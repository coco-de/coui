import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedEmptyState
// ═══════════════════════════════════════════════════

/// Resolver output for `EmptyState`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus variant default fallback, token
/// resolution, and `scaling` applied. No box any more — the redesign
/// drops the bordered/filled panel, so there is no `containerStyle` /
/// `boxShadow` / border-radius here.
class ResolvedEmptyState {
  /// Creates a [ResolvedEmptyState].
  const ResolvedEmptyState({
    required this.padding,
    required this.minHeight,
    required this.maxTextWidth,
    required this.iconTitleGapStyle,
    required this.titleDescriptionGapStyle,
    required this.descriptionActionGapStyle,
    required this.iconSize,
    required this.iconColor,
    required this.iconBoxSize,
    required this.iconBoxColor,
    required this.iconBoxBorderRadius,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
  });

  /// Effective outer padding (post-scaling).
  final EdgeInsets padding;

  /// Effective minimum stack height (logical px, post-scaling).
  final double minHeight;

  /// Effective maximum title + description text-block width (logical
  /// px, post-scaling).
  final double maxTextWidth;

  /// Nested [CoreGapStyle] for the icon → title spacer — forwarded
  /// straight to `Gap(gapStyle: …)` inside the widget. The slot is
  /// **not** pre-scaled here; `Gap` applies `theme.scaling` itself in
  /// its own resolver, so the forwarded slot stays in pre-scaling units
  /// (avoids double-scaling under non-default text scaler).
  final CoreGapStyle iconTitleGapStyle;

  /// Nested [CoreGapStyle] for the title → description spacer —
  /// forwarded straight to `Gap(gapStyle: …)` inside the widget. Same
  /// scaling contract as [iconTitleGapStyle].
  final CoreGapStyle titleDescriptionGapStyle;

  /// Nested [CoreGapStyle] for the description → action spacer —
  /// forwarded straight to `Gap(gapStyle: …)` inside the widget. Same
  /// scaling contract as [iconTitleGapStyle].
  final CoreGapStyle descriptionActionGapStyle;

  /// Effective icon size (logical px, post-scaling). Fed to the
  /// ambient `IconThemeData` wrapping the caller-supplied icon widget
  /// — the same "caller-supplied Widget, not our own `Icon`" fallback
  /// `Button`'s leading/trailing slot uses (`widget/render-only.md`).
  final double iconSize;

  /// Effective icon colour.
  final Color iconColor;

  /// Effective icon box edge (logical px, post-scaling).
  final double iconBoxSize;

  /// Effective icon box fill.
  final Color iconBoxColor;

  /// Effective icon box corner radius (post-scaling).
  final BorderRadius iconBoxBorderRadius;

  /// Paint-ready title [TextStyle] — the variant's title role (title
  /// colour, the role's own weight) with the per-instance
  /// `CoreEmptyStateStyle.titleTextStyle` override layered on top.
  final TextStyle titleTextStyle;

  /// Paint-ready description [TextStyle] — `bodySmall` typography base
  /// (`on-surface-variant`) with the per-instance
  /// `CoreEmptyStateStyle.descriptionTextStyle` override layered on top.
  final TextStyle descriptionTextStyle;
}

// ═══════════════════════════════════════════════════
// resolveEmptyState — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedEmptyState] for the given [context] and
/// [variant].
///
/// Applies the full merge chain:
///
/// ```text
/// CoreEmptyStateStyle.defaults*
///   → CoreEmptyStateStyle.defaultsByVariant[variant]
///   → CoreEmptyStateTheme.style
///   → CoreEmptyStateTheme.variantStyles[variant]
///   → widget.emptyStateStyle
/// ```
///
/// Final fallback values come from `coui_core` —
/// [CoreEmptyStateStyle.defaultsByVariant] and the `defaultX` static
/// const fields. The widget never spells out fallback logic inline.
ResolvedEmptyState resolveEmptyState(
  BuildContext context, {
  required CoreEmptyStateVariant variant,
  CoreEmptyStateTone tone = .defaultTone,
  CoreEmptyStateStyle? emptyStateStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final esTheme = theme.coreComponentTheme?.emptyState;

  final variantChrome = CoreEmptyStateStyle.defaultsByVariant[variant]!;

  // ── Merge chain: project → variant → instance ──
  final merged = resolveStyleChain(const CoreEmptyStateStyle(), [
    esTheme?.style,
    esTheme?.variantStyles?[variant],
    emptyStateStyle,
  ]);

  // ── Numeric resolution (variant chrome → static defaults) ──
  final padding =
      (merged.padding ?? variantChrome.padding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final minHeight = (merged.minHeight ?? variantChrome.minHeight) * scaling;
  final maxTextWidth =
      (merged.maxTextWidth ?? CoreEmptyStateStyle.defaultMaxTextWidth) *
      scaling;
  final iconSize = (merged.iconStyle?.size ?? variantChrome.iconSize) * scaling;
  final iconBoxSize =
      (merged.iconBoxSize ?? variantChrome.iconBoxSize) * scaling;
  final iconBoxBorderRadius =
      (merged.iconBoxBorderRadius ??
              CoreEmptyStateStyle.defaultIconBoxBorderRadius)
          .toValue(geometry: theme.geometry);
  // Nested [CoreGapStyle] slots forwarded straight to `Gap`. The
  // variant default is merged with the per-instance override, and the
  // merged slot is forwarded raw — `Gap`'s own resolver multiplies
  // `size` by `theme.scaling`, so pre-applying scaling would
  // double-scale under a non-default text scaler.
  final iconTitleGapStyle = variantChrome.iconTitleGapStyle.merge(
    merged.iconTitleGapStyle,
  );
  final titleDescriptionGapStyle = variantChrome.titleDescriptionGapStyle.merge(
    merged.titleDescriptionGapStyle,
  );
  final descriptionActionGapStyle = variantChrome.descriptionActionGapStyle
      .merge(merged.descriptionActionGapStyle);

  // ── Colour resolution (token → Color) ──
  // The tone table is total: both members state their icon colour outright
  // (`neutral` restates `defaultIconColor`, `failure` the `error` token), so
  // the per-instance slot is the only thing that can be absent here.
  final toneChrome = CoreEmptyStateStyle.defaultsByTone[tone]!;
  final iconColorToken =
      merged.iconStyle?.color ?? toneChrome.iconStyle!.color!;
  final iconColor = scheme.resolve(iconColorToken).toValue();
  final iconBoxColor = scheme
      .resolve(merged.iconBoxColor ?? toneChrome.iconBoxColor!)
      .toValue();

  // ── Paint-ready typography (EMIT Stage 2, Flutter) ──
  // The label roles materialise through the single primitive
  // `default.merge(override).toValue(theme:)` — no hand-rolled
  // `theme.typography.<role>.copyWith(...)` assembly. The variant's role
  // (`defaultsByVariant[variant].titleTextStyle`) is merged onto the
  // default title style, so the title takes the role's own weight and
  // stays dark-mode / accessibility-scale reactive; the per-instance
  // override is merged on top of that.
  final titleTextStyle = CoreEmptyStateStyle.defaultTitleTextStyle
      .merge(variantChrome.titleTextStyle)
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final descriptionTextStyle = CoreEmptyStateStyle.defaultDescriptionTextStyle
      .merge(variantChrome.descriptionTextStyle)
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);

  return ResolvedEmptyState(
    padding: padding,
    minHeight: minHeight,
    maxTextWidth: maxTextWidth,
    iconTitleGapStyle: iconTitleGapStyle,
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    descriptionActionGapStyle: descriptionActionGapStyle,
    iconSize: iconSize,
    iconColor: iconColor,
    iconBoxSize: iconBoxSize,
    iconBoxColor: iconBoxColor,
    iconBoxBorderRadius: iconBoxBorderRadius,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
  );
}
