/// Per-instance style for `Footer`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/collapsible/collapsible_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/footer/core_footer_layout.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Footer` should render.
///
/// `CoreFooterStyle` carries chrome flat fields (layout / padding /
/// colours / block and row spacing) plus nested style slots for the
/// title→body gap (`CoreGapStyle`), the rendered text roles, and the
/// child components the footer composes — `Divider` for the top rule
/// and the hairline ticks, `Collapsible` for the business-info
/// disclosure.
///
/// ```text
/// design system default
///   → CoreFooterTheme (legacy flat fields)
///   → CoreFooterTheme.style                         // 프로젝트 공통
///   → parent component slot override
///   → widget.footerStyle                            // 인스턴스별
/// ```
@immutable
class CoreFooterStyle implements CoreStyle<CoreFooterStyle> {
  /// Creates a [CoreFooterStyle].
  const CoreFooterStyle({
    this.layout,
    this.padding,
    this.blockSpacing,
    this.sectionSpacing,
    this.legalSpacing,
    this.companyRowSpacing,
    this.linkRowSpacing,
    this.inlineDividerLength,
    this.sectionTitleGapStyle,
    this.backgroundColor,
    this.titleTextStyle,
    this.bodyTextStyle,
    this.companyTextStyle,
    this.copyrightTextStyle,
    this.dividerStyle,
    this.inlineDividerStyle,
    this.collapsibleStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// Default layout mode — sections flow in a wrapping row.
  ///
  /// Single source of truth shared by Flutter and Web resolvers: both
  /// resolve the semantic layout as
  /// `widget.layout ?? merged.layout ?? CoreFooterStyle.defaultLayout`,
  /// so the widget prop still wins and a per-instance [layout] override
  /// still beats this default.
  static const CoreFooterLayout defaultLayout = .horizontal;

  /// Default background colour — the designer's `Footer` set fills its
  /// root with `color/surface`, so the band sits on the page tone rather
  /// than a raised container tone.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default section title text style — token-backed reference to the
  /// `titleSmall` slot with the shared `onSurfaceVariant` text colour.
  /// The weight is the role's own (bold), the same weight the company
  /// name ([defaultCompanyTextStyle]) takes from the same role, so a
  /// section title never reads lighter than the company name. Web emits
  /// `text-title-small` from `token.name`; Flutter materialises the slot
  /// through `style.toValue(theme:)`. Per-instance override flows
  /// through [titleTextStyle] (merged on top).
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default body/content text style — token-backed reference to the
  /// `bodyMedium` slot carrying the shared `onSurfaceVariant` text
  /// colour. Web emits `text-body-medium` from `token.name`; Flutter
  /// materialises the slot through `theme.coreTypography.resolve(...)`.
  /// Per-instance override flows through [bodyTextStyle] (merged on top).
  static const CoreTextStyle defaultBodyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default padding of the footer bar (pre-scaling).
  ///
  /// Single source of truth shared by Flutter and Web resolvers. Both
  /// apply it to the padded content box rather than the root, so the
  /// opt-in top rule lands outside it on all four sides.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space24,
    vertical: CoreSpace.space40,
  );

  /// Default spacing between top-level sections (logical px, pre-scaling).
  ///
  /// Single source of truth shared by Flutter and Web resolvers.
  static const double defaultSectionSpacing = CoreSpace.space24;

  /// Default nested [CoreGapStyle] slot for the gap between a nav
  /// section title and its children — size matches the historical
  /// `CoreSpace.space8` scalar. Both Flutter and Web resolvers merge
  /// per-instance [sectionTitleGapStyle] on top of this default and
  /// forward the resulting slot (Flutter → `Gap`, Web → inline
  /// `margin-bottom` derived from `size`).
  static const CoreGapStyle defaultSectionTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default spacing between the blocks inside the padded content box —
  /// the navigation band and the legal block. The designer set's root
  /// frame stacks them with `space/24`.
  ///
  /// The top rule is not one of them: it sits above the content box and
  /// adds no gap after itself (see [defaultDividerStyle]).
  ///
  /// Distinct from [defaultSectionSpacing], which spaces the nav
  /// sections *inside* the band: the two carry the same number today but
  /// answer different questions, and a project that widens the gap
  /// between blocks does not thereby want wider gaps between columns.
  static const double defaultBlockSpacing = CoreSpace.space24;

  /// Default spacing between the legal block's rows — company row, the
  /// disclosure paragraph, the link row, and the copyright line. The
  /// designer set's `legal` frame stacks them with `space/16`.
  static const double defaultLegalSpacing = CoreSpace.space16;

  /// Default spacing inside the company row — company name, hairline
  /// tick, disclosure trigger. The designer set uses `space/12`.
  static const double defaultCompanyRowSpacing = CoreSpace.space12;

  /// Default spacing inside the legal link row — each link and the
  /// hairline tick between them. The designer set uses `space/12`.
  static const double defaultLinkRowSpacing = CoreSpace.space12;

  /// Default length of the hairline tick that separates inline legal
  /// items (logical px, pre-scaling). The designer set draws each mark
  /// as a 1×12 rectangle, and `CoreDividerStyle` has no length field —
  /// a `Divider` takes its length from the box it is given, so the
  /// footer states that box here.
  static const double defaultInlineDividerLength = CoreSize.size12;

  /// Default company-name text style — `titleSmall` on `onSurface`,
  /// the designer set's `Title/Small` on `color/on-surface`.
  ///
  /// The platform installs this as the ambient text style around the
  /// `company` slot, so a plain `Text('…')` inherits it while a
  /// `Text('…').titleMedium` chain still wins. Honoured in full (role
  /// *and* colour) — this is a `CoreTextStyle` slot, not a colour-only
  /// one (style-contract.md "색-only 면 `CoreColor`, full 텍스트면
  /// `CoreTextStyle`").
  static const CoreTextStyle defaultCompanyTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default copyright-line text style — `labelLarge` on
  /// `onSurfaceVariant`, the designer set's `Label/Large` on
  /// `color/on-surface-variant`. Installed as ambient text style around
  /// the `copyright` slot, same as [defaultCompanyTextStyle].
  ///
  /// The disclosure trigger and paragraph carry the same role on the
  /// canvas but are *not* this field: they belong to the composed
  /// `Collapsible` and reach it through [defaultCollapsibleStyle], so
  /// each value keeps exactly one consumer.
  static const CoreTextStyle defaultCopyrightTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default nested [CoreDividerStyle] slot for the top rule.
  ///
  /// Deliberately empty: `Divider`'s own defaults — `outlineVariant`
  /// over `outline`, `stroke1` — are already what the designer set
  /// draws, so restating them here would clone the child's defaults
  /// (style-contract.md "합성 = 재구현 금지" facet 3). The constant
  /// exists so the resolver's forward is uniform
  /// (`defaultDividerStyle.merge(merged.dividerStyle)`) and so a future
  /// divergence has one place to be written.
  ///
  /// The rule is full-bleed and flush: on the designer set it is 640
  /// wide at `y=0` inside a 640-wide root whose other children are 592
  /// and start at `y=40` (the root's own `paddingTop`). So it escapes
  /// the padding on all four counts — it is outside the horizontal
  /// inset, it sits above the vertical one, and it adds no
  /// [blockSpacing] after itself.
  ///
  /// That is structure, not chrome, and both platforms build it the same
  /// way: the root owns no padding at all, the rule is its first child,
  /// and a padded content box below carries [padding] plus the
  /// [blockSpacing] between the navigation band and the legal block.
  /// (The canvas states this with `layoutPositioning: ABSOLUTE`, which
  /// is how a designer escapes a frame's padding — not a claim that the
  /// line overlaps the content.)
  static const CoreDividerStyle defaultDividerStyle = CoreDividerStyle();

  /// Default nested [CoreDividerStyle] slot for the hairline ticks
  /// between inline legal items.
  ///
  /// Deliberately empty for the same reason as [defaultDividerStyle] —
  /// the tick is `outlineVariant` at `stroke1`, which is what a
  /// `Divider` already is. Its length is the footer's own
  /// [inlineDividerLength], because a divider has no length of its own.
  ///
  /// One slot, not one per row: the company row and the link row draw
  /// the identical mark from the identical canvas node, and a project
  /// that re-tones the tick means both. Named for the `Divider` it
  /// composes — the kit has exactly one line component, and this slot is
  /// the *inline* one, told apart from [dividerStyle] (the top rule) by
  /// where it is drawn rather than by a second word for "line".
  static const CoreDividerStyle defaultInlineDividerStyle = CoreDividerStyle();

  /// Default nested [CoreCollapsibleStyle] slot for the composed
  /// business-info disclosure — a partial stating only where the footer
  /// diverges from `Collapsible`'s own defaults. Everything unstated
  /// stays null and resolves inside the `Collapsible`'s resolver, so
  /// this is a partial forward, not a clone of the child defaults.
  ///
  /// The three divergences, all read off the designer set:
  /// - `contentInset` → zero. The trigger hugs its row and the
  ///   paragraph runs the full width of the legal block; `Collapsible`'s
  ///   own `space16` inset would indent both.
  /// - `iconLabelGapStyle` → `space4`. The trigger frame sets its label
  ///   ↔ chevron gap to `space/4`, against the child's `space16`.
  /// - `triggerTextStyle` / `contentTextStyle` → `labelLarge` on
  ///   `onSurfaceVariant`, against the child's `bodyMedium` on
  ///   `onSurface`.
  ///
  /// The chevron size is left unstated: `Collapsible` already defaults
  /// to 16, which is the `Icon / Size=16` instance on the canvas.
  ///
  /// One value rides along that the canvas does not state — the child's
  /// `medium` weight overlay survives the merge, because a merge can
  /// add a field but never clear one. It matches `Label/Large`'s own
  /// weight today; if that role's weight ever moves, this trigger label
  /// stays pinned at `medium` until the overlay is stated here.
  static const CoreCollapsibleStyle defaultCollapsibleStyle =
      CoreCollapsibleStyle(
        contentInset: CoreEdgeInsets.zero,
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
        contentTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );

  // ── Chrome (flat) ────────────────────────────

  /// Layout mode override.
  final CoreFooterLayout? layout;

  /// Padding of the content box below the opt-in top rule
  /// (pre-scaling).
  final CoreEdgeInsets? padding;

  /// Spacing between the blocks inside the padded content box —
  /// navigation band and legal block (logical px).
  final double? blockSpacing;

  /// Spacing between top-level sections (logical px).
  final double? sectionSpacing;

  /// Spacing between the legal block's rows (logical px).
  final double? legalSpacing;

  /// Spacing inside the company row — name, tick, disclosure trigger
  /// (logical px).
  final double? companyRowSpacing;

  /// Spacing inside the legal link row — links and the ticks between
  /// them (logical px).
  final double? linkRowSpacing;

  /// Length of the hairline tick separating inline legal items
  /// (logical px, pre-scaling). Sizes the box the composed `Divider`
  /// draws into — the divider itself has no length.
  final double? inlineDividerLength;

  /// Style of the `Gap` between a nav section title and the section body.
  /// Merged on top of [defaultSectionTitleGapStyle].
  final CoreGapStyle? sectionTitleGapStyle;

  /// Default background colour.
  final CoreColor? backgroundColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Nav section title text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw `textColor`
  /// field removed and folded into both this and [bodyTextStyle]).
  final CoreTextStyle? titleTextStyle;

  /// Body / link text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8).
  final CoreTextStyle? bodyTextStyle;

  /// Company-name text style override, merged on top of
  /// [defaultCompanyTextStyle] and set as the text style the `company`
  /// slot inherits. Honoured in full — role and colour.
  final CoreTextStyle? companyTextStyle;

  /// Copyright-line text style override, merged on top of
  /// [defaultCopyrightTextStyle] and set as the text style the `copyright`
  /// slot inherits. Honoured in full — role and colour.
  final CoreTextStyle? copyrightTextStyle;

  /// Style of the `Divider` drawn as the top rule. Merged on top of
  /// [defaultDividerStyle] and passed to the `Divider` as is; the
  /// `Divider` fills whatever is left unset from its own defaults.
  final CoreDividerStyle? dividerStyle;

  /// Style of the `Divider` ticks between inline legal items. Merged on
  /// top of [defaultInlineDividerStyle] and passed to the `Divider` as is.
  /// The tick's length is set by [inlineDividerLength], not here.
  final CoreDividerStyle? inlineDividerStyle;

  /// Style of the `Collapsible` that holds the business info — trigger
  /// typography, label ↔ chevron gap, chevron icon, expand duration.
  /// Merged on top of [defaultCollapsibleStyle] and passed to the
  /// `Collapsible` as is; the `Collapsible` fills the rest from its own
  /// defaults.
  final CoreCollapsibleStyle? collapsibleStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreFooterStyle merge(CoreFooterStyle? other) {
    if (other == null) return this;
    return CoreFooterStyle(
      layout: other.layout ?? layout,
      padding: other.padding ?? padding,
      blockSpacing: other.blockSpacing ?? blockSpacing,
      sectionSpacing: other.sectionSpacing ?? sectionSpacing,
      legalSpacing: other.legalSpacing ?? legalSpacing,
      companyRowSpacing: other.companyRowSpacing ?? companyRowSpacing,
      linkRowSpacing: other.linkRowSpacing ?? linkRowSpacing,
      inlineDividerLength: other.inlineDividerLength ?? inlineDividerLength,
      sectionTitleGapStyle: _mergeGap(
        sectionTitleGapStyle,
        other.sectionTitleGapStyle,
      ),
      backgroundColor: other.backgroundColor ?? backgroundColor,
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      bodyTextStyle: _mergeText(bodyTextStyle, other.bodyTextStyle),
      companyTextStyle: _mergeText(companyTextStyle, other.companyTextStyle),
      copyrightTextStyle: _mergeText(
        copyrightTextStyle,
        other.copyrightTextStyle,
      ),
      dividerStyle:
          dividerStyle?.merge(other.dividerStyle) ?? other.dividerStyle,
      inlineDividerStyle:
          inlineDividerStyle?.merge(other.inlineDividerStyle) ??
          other.inlineDividerStyle,
      collapsibleStyle:
          collapsibleStyle?.merge(other.collapsibleStyle) ??
          other.collapsibleStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFooterStyle copyWith({
    CoreFooterLayout? layout,
    CoreEdgeInsets? padding,
    double? blockSpacing,
    double? sectionSpacing,
    double? legalSpacing,
    double? companyRowSpacing,
    double? linkRowSpacing,
    double? inlineDividerLength,
    CoreGapStyle? sectionTitleGapStyle,
    CoreColor? backgroundColor,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? bodyTextStyle,
    CoreTextStyle? companyTextStyle,
    CoreTextStyle? copyrightTextStyle,
    CoreDividerStyle? dividerStyle,
    CoreDividerStyle? inlineDividerStyle,
    CoreCollapsibleStyle? collapsibleStyle,
  }) {
    return CoreFooterStyle(
      layout: layout ?? this.layout,
      padding: padding ?? this.padding,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      legalSpacing: legalSpacing ?? this.legalSpacing,
      companyRowSpacing: companyRowSpacing ?? this.companyRowSpacing,
      linkRowSpacing: linkRowSpacing ?? this.linkRowSpacing,
      inlineDividerLength: inlineDividerLength ?? this.inlineDividerLength,
      sectionTitleGapStyle: sectionTitleGapStyle ?? this.sectionTitleGapStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      companyTextStyle: companyTextStyle ?? this.companyTextStyle,
      copyrightTextStyle: copyrightTextStyle ?? this.copyrightTextStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      inlineDividerStyle: inlineDividerStyle ?? this.inlineDividerStyle,
      collapsibleStyle: collapsibleStyle ?? this.collapsibleStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFooterStyle &&
          runtimeType == other.runtimeType &&
          layout == other.layout &&
          padding == other.padding &&
          blockSpacing == other.blockSpacing &&
          sectionSpacing == other.sectionSpacing &&
          legalSpacing == other.legalSpacing &&
          companyRowSpacing == other.companyRowSpacing &&
          linkRowSpacing == other.linkRowSpacing &&
          inlineDividerLength == other.inlineDividerLength &&
          sectionTitleGapStyle == other.sectionTitleGapStyle &&
          backgroundColor == other.backgroundColor &&
          titleTextStyle == other.titleTextStyle &&
          bodyTextStyle == other.bodyTextStyle &&
          companyTextStyle == other.companyTextStyle &&
          copyrightTextStyle == other.copyrightTextStyle &&
          dividerStyle == other.dividerStyle &&
          inlineDividerStyle == other.inlineDividerStyle &&
          collapsibleStyle == other.collapsibleStyle;

  @override
  int get hashCode => Object.hash(
    layout,
    padding,
    blockSpacing,
    sectionSpacing,
    legalSpacing,
    companyRowSpacing,
    linkRowSpacing,
    inlineDividerLength,
    sectionTitleGapStyle,
    backgroundColor,
    titleTextStyle,
    bodyTextStyle,
    companyTextStyle,
    copyrightTextStyle,
    dividerStyle,
    inlineDividerStyle,
    collapsibleStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
