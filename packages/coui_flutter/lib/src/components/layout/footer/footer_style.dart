import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Footer].
class ResolvedFooter {
  /// Creates a [ResolvedFooter].
  const ResolvedFooter({
    required this.layout,
    required this.containerStyle,
    required this.padding,
    required this.blockSpacing,
    required this.sectionSpacing,
    required this.legalSpacing,
    required this.companyRowSpacing,
    required this.linkRowSpacing,
    required this.inlineDividerLength,
    required this.sectionTitleGapStyle,
    required this.titleStyle,
    required this.bodyStyle,
    required this.companyStyle,
    required this.copyrightStyle,
    required this.dividerStyle,
    required this.inlineDividerStyle,
    required this.collapsibleStyle,
  });

  /// Effective layout mode.
  final CoreFooterLayout layout;

  /// Composed-`OutlinedContainer` chrome for the footer band (pre-EMIT
  /// `CoreOutlinedContainerStyle`) — fill / full-bleed width.
  /// `OutlinedContainer` runs the scheme-resolve / scaling bend itself;
  /// carrying Core values (not resolved Flutter ones) keeps that bend
  /// applied exactly once. `boxShadow` is forced to an explicit empty
  /// stack — this band never painted a cast of its own, so composing
  /// the primitive must not let its `controlShadow` fallback add one.
  ///
  /// Its `padding` is pinned to zero and re-issued as [padding] below:
  /// the top rule is full-bleed *and* flush on the designer set (640
  /// wide at `y=0`, inside a 640 root whose other children are 592 and
  /// start at `y=40`), so it has to sit outside the band's inset on all
  /// four sides. Keeping the inset inside `OutlinedContainer` would put
  /// the rule inside it too.
  final CoreOutlinedContainerStyle containerStyle;

  /// Padding of the content box below the opt-in top rule (already
  /// scaled).
  ///
  /// Applied by the widget around the block column rather than by the
  /// composed `OutlinedContainer`, so the rule can sit flush at the top
  /// edge and span the band's full width above it.
  /// `EdgeInsetsGeometry` rather than `EdgeInsets` because a caller may
  /// state the inset directionally.
  final EdgeInsetsGeometry padding;

  /// Spacing between the blocks inside the padded content box —
  /// navigation band and legal block (already scaled). The rule takes
  /// none of it: it is not inside that box.
  final double blockSpacing;

  /// Spacing between top-level sections (already scaled).
  final double sectionSpacing;

  /// Spacing between the legal block's rows (already scaled).
  final double legalSpacing;

  /// Spacing inside the company row (already scaled).
  final double companyRowSpacing;

  /// Spacing inside the legal link row (already scaled).
  final double linkRowSpacing;

  /// Length of the hairline tick separating inline legal items
  /// (already scaled). Sizes the box the composed `Divider` draws
  /// into — a divider takes its length from the box it is given.
  final double inlineDividerLength;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between a nav section title and its children. Merged
  /// with [CoreFooterStyle.defaultSectionTitleGapStyle].
  final CoreGapStyle sectionTitleGapStyle;

  /// Text style for nav section titles (titleSmall, the role's own
  /// weight).
  final TextStyle titleStyle;

  /// Default body/link text style (bodyMedium).
  final TextStyle bodyStyle;

  /// Ambient text style installed around the `company` slot.
  ///
  /// Carries its own colour (the `onSurface` token in
  /// [CoreFooterStyle.defaultCompanyTextStyle]) rather than the colour
  /// folded into [bodyStyle] — the designer set draws the company name a
  /// step darker than the rest of the legal block.
  final TextStyle companyStyle;

  /// Ambient text style installed around the `copyright` slot.
  final TextStyle copyrightStyle;

  /// Nested [CoreDividerStyle] slot raw-forwarded to the composed
  /// `Divider` that draws the optional top rule. `Divider`'s own
  /// resolver fills every field left null here.
  final CoreDividerStyle dividerStyle;

  /// Nested [CoreDividerStyle] slot raw-forwarded to the composed
  /// `Divider` that draws each hairline tick between inline legal
  /// items. Its length is [inlineDividerLength], not part of this slot.
  final CoreDividerStyle inlineDividerStyle;

  /// Nested [CoreCollapsibleStyle] slot raw-forwarded to the composed
  /// `Collapsible` that carries the business-info disclosure — trigger
  /// typography, label ↔ chevron gap, chevron icon, expand duration.
  final CoreCollapsibleStyle collapsibleStyle;
}

/// Resolves [ResolvedFooter] for [Footer].
///
/// Priority (per-field): widget value > merged composite style
/// (`widget.footerStyle` over `CoreFooterTheme.style`) >
/// design-system default (`CoreFooterStyle.defaultX`).
ResolvedFooter resolveFooter(
  BuildContext context, {
  CoreFooterLayout? layout,
  CoreFooterStyle? footerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.footer;

  // ─── Merge chain (Stage1 RESOLVE — Flutter = Web) ─────
  final merged = resolveStyleChain(const CoreFooterStyle(), [
    coreTheme?.style,
    footerStyle,
  ]);

  // Semantic identifier — widget prop only. The theme cannot override it
  // (render-only.md (c)); Web resolves it identically so the two stay 1:1.
  final effectiveLayout =
      layout ?? merged.layout ?? CoreFooterStyle.defaultLayout;

  // ─── Stage1 RESOLVE — paint-direct Core values (local) ─
  // background / text colour 는 `CoreFooterStyle.default*` (Core single
  // source — same tokens Web reads via `bg-${...}` / `text-${...}`).
  final backgroundColor =
      merged.backgroundColor ?? CoreFooterStyle.defaultBackgroundColor;
  // Text colour is folded into the nested `titleTextStyle.color` /
  // `bodyTextStyle.color` slots (sb8 — raw `textColor` field removed).
  // Either slot's `color` override wins; otherwise the shared
  // `defaultBodyTextStyle.color` token applies. This single colour is
  // forced onto both the title and body label styles below.
  final textColor =
      merged.bodyTextStyle?.color ??
      merged.titleTextStyle?.color ??
      CoreFooterStyle.defaultBodyTextStyle.color!;
  // Padding leaves the composed `OutlinedContainer` and is applied by
  // the widget to the content box instead, so the optional top rule can
  // sit flush at the top edge and span the band's full width above it.
  // `toGeometry()` (not `toValue()`) because a caller may state the
  // inset directionally, and flattening that would be right in English
  // and wrong in Arabic.
  final padding =
      (merged.padding ?? CoreFooterStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final blockSpacing =
      theme.geometry.space(
        merged.blockSpacing ?? CoreFooterStyle.defaultBlockSpacing,
      ) *
      scaling;
  final sectionSpacing =
      theme.geometry.space(
        merged.sectionSpacing ?? CoreFooterStyle.defaultSectionSpacing,
      ) *
      scaling;
  final legalSpacing =
      theme.geometry.space(
        merged.legalSpacing ?? CoreFooterStyle.defaultLegalSpacing,
      ) *
      scaling;
  final companyRowSpacing =
      theme.geometry.space(
        merged.companyRowSpacing ?? CoreFooterStyle.defaultCompanyRowSpacing,
      ) *
      scaling;
  final linkRowSpacing =
      theme.geometry.space(
        merged.linkRowSpacing ?? CoreFooterStyle.defaultLinkRowSpacing,
      ) *
      scaling;
  final inlineDividerLength =
      (merged.inlineDividerLength ??
          CoreFooterStyle.defaultInlineDividerLength) *
      scaling;
  // Nested child-component slots — merged with the footer's partial
  // default and raw-forwarded. Each child's own resolver fills the
  // fields left null, so the footer never clones a child's defaults.
  final dividerStyle = CoreFooterStyle.defaultDividerStyle.merge(
    merged.dividerStyle,
  );
  final inlineDividerStyle = CoreFooterStyle.defaultInlineDividerStyle.merge(
    merged.inlineDividerStyle,
  );
  final collapsibleStyle = CoreFooterStyle.defaultCollapsibleStyle.merge(
    merged.collapsibleStyle,
  );
  // Nested `CoreGapStyle` slot — merge the design-system default with the
  // per-instance override and forward the resulting slot to the `Gap`
  // widget rendered between a section title and its children (raw-forward —
  // `Gap` self-applies scaling).
  final sectionTitleGapStyle = CoreFooterStyle.defaultSectionTitleGapStyle
      .merge(
        merged.sectionTitleGapStyle,
      );
  // Title / body text style — design-system default token-backed
  // `CoreTextStyle` merged with the per-instance override (card model).
  final titleTextStyle = CoreFooterStyle.defaultTitleTextStyle.merge(
    merged.titleTextStyle,
  );
  final bodyTextStyle = CoreFooterStyle.defaultBodyTextStyle.merge(
    merged.bodyTextStyle,
  );
  // The legal block's two named text roles keep the colour their own
  // slot states — the company name sits on `onSurface`, a step darker
  // than the shared colour the nav band uses. Forcing the shared colour
  // onto them would erase that step.
  final companyTextStyle = CoreFooterStyle.defaultCompanyTextStyle.merge(
    merged.companyTextStyle,
  );
  final copyrightTextStyle = CoreFooterStyle.defaultCopyrightTextStyle.merge(
    merged.copyrightTextStyle,
  );

  // ─── Stage2 EMIT — Flutter native (theme-dependent, local) ─
  // 색 = `.resolve(scheme).toValue()`; 타이포 = `.toValue(theme:, color:)`.
  // The shared text colour is forced onto both label styles via `color:`
  // so the footer's title / body track the same resolved colour. It is
  // not re-exposed on `ResolvedFooter` — the four `*Style` fields below
  // are the only readers, so a bare colour field would be a value
  // nothing reads.
  final textColorValue = scheme.resolve(textColor).toValue();
  final titleStyle = titleTextStyle.toValue(
    color: textColorValue,
    theme: theme,
  );
  final bodyStyle = bodyTextStyle.toValue(color: textColorValue, theme: theme);
  final companyStyle = companyTextStyle.toValue(theme: theme);
  final copyrightStyle = copyrightTextStyle.toValue(theme: theme);

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ────────────────
  // The footer band is the box `Card` / `Fieldset` compose, not a
  // hand-rolled decoration (Epic #4349) — passing Core values (not
  // resolved ones) keeps the scheme-resolve / scaling bend applied
  // exactly once, by `OutlinedContainer` itself. `boxShadow: []` is
  // forced because this band never painted a cast of its own — an
  // unset value would let `OutlinedContainer`'s own `controlShadow`
  // fallback add a shadow under presets (neo-brutalism) that state one.
  // `padding: .zero` is deliberate, not an omission — the band's inset
  // is re-issued as `ResolvedFooter.padding` and applied by the widget,
  // so the full-bleed top rule can sit above it. Passing `null` here
  // would let `OutlinedContainer` fall back to *its* default inset.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColor,
    borderRadius: .zero,
    borderWidth: 0,
    boxShadow: const [],
    padding: .zero,
    width: .infinity,
  );

  // ─── RETURN — bare 매핑 ───
  return ResolvedFooter(
    layout: effectiveLayout,
    containerStyle: containerStyle,
    padding: padding,
    blockSpacing: blockSpacing,
    sectionSpacing: sectionSpacing,
    legalSpacing: legalSpacing,
    companyRowSpacing: companyRowSpacing,
    linkRowSpacing: linkRowSpacing,
    inlineDividerLength: inlineDividerLength,
    sectionTitleGapStyle: sectionTitleGapStyle,
    titleStyle: titleStyle,
    bodyStyle: bodyStyle,
    companyStyle: companyStyle,
    copyrightStyle: copyrightStyle,
    dividerStyle: dividerStyle,
    inlineDividerStyle: inlineDividerStyle,
    collapsibleStyle: collapsibleStyle,
  );
}
