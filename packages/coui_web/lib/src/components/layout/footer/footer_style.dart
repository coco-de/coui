library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Footer`.
///
/// DOM shape:
///
/// ```text
/// root (<footer>)                                // fill + cascade text colour; NO padding, NO gap
///   ├─ Divider(dividerStyle)                   // footer.dart renders only when showDivider
///   └─ content (<div>)                           // all four padding sides + blockSpacing between bands
///        ├─ main (<div>)                         // footer.dart renders only when aside or sections exist
///        │    ├─ aside                           // caller-supplied Component, only when aside != null
///        │    └─ sections (<div>)                // only when sections is not empty
///        │         └─ section (<div>)            // one per CoreFooterNavData
///        │              ├─ title (<div>)         // only when section.title is non-empty
///        │              ├─ Gap(sectionTitleGapStyle)
///        │              └─ section.children      // caller-supplied Components
///        └─ legal (<div>)                        // only when any legal slot is filled
///             ├─ companyRow (<div>)              // only when company or businessInfo exists
///             │    ├─ company (<div>)            // only when company != null
///             │    ├─ Divider(inlineDividerStyle) // tick, only between company and the disclosure
///             │    └─ Collapsible(…)           // disclosure, only when businessInfo != null
///             ├─ linkRow (<div>)                 // only when links is not empty
///             │    └─ link · Divider(inlineDividerStyle) · link · …
///             └─ copyright (<div>)               // only when copyright != null
/// ```
///
/// `footer.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// The resolver carries only [WebElementChrome] paint-ready slots plus
/// nested style slots forwarded to the unified children the footer
/// composes (`Gap`, `Divider`, `Collapsible`). The semantic
/// [CoreFooterLayout] is folded into the [main] / [sections] / [section]
/// classNames here — it is not re-exposed as a scalar field (the widget
/// never branches on it).
///
/// ### Why the root owns no padding
///
/// On the designer set the rule is 640 wide at `y=0` inside a 640-wide
/// root whose other children are 592 and start at `y=40` — the root's
/// own `paddingTop`. So the rule escapes the inset on every side and
/// contributes no gap after itself.
///
/// The honest structure for that is a root that carries only the fill,
/// with the rule as its first child and **all four** padding sides on
/// [content] below. Splitting the padding across the two boxes — the
/// vertical half on the root, the horizontal half here — would put the
/// rule 40px down from the top edge, which is not where it is drawn.
class ResolvedFooter implements WebResolvedChrome {
  /// Creates a [ResolvedFooter].
  const ResolvedFooter({
    required this.root,
    required this.content,
    required this.main,
    required this.sections,
    required this.section,
    required this.title,
    required this.legal,
    required this.companyRow,
    required this.company,
    required this.inlineDividerBox,
    required this.linkRow,
    required this.copyright,
    required this.sectionTitleGapStyle,
    required this.dividerStyle,
    required this.inlineDividerStyle,
    required this.collapsibleStyle,
  });

  /// Paint-ready chrome for the outer `<footer>` — a vertical stack
  /// carrying the band fill and the cascade text colour (both emitted
  /// through the `emitColor` family: a Tailwind class for a token,
  /// inline CSS for a raw override).
  ///
  /// No padding and no gap: the whole inset lives on [content] so the
  /// top rule sits flush at the top edge, full width, with nothing
  /// separating it from the box below.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the padded content box — all four padding
  /// sides (logical longhands when the caller stated the inset
  /// directionally) plus `blockSpacing` between the navigation band and
  /// the legal block.
  final WebElementChrome content;

  /// Paint-ready chrome for the navigation band holding the caller's
  /// `aside` and the [sections] wrapper — direction flipped by the
  /// resolved layout, `sectionSpacing` between the two.
  final WebElementChrome main;

  /// Paint-ready chrome for the wrapper around every nav column —
  /// direction flipped by the resolved layout, `sectionSpacing` between
  /// columns. Grows to fill the row in the horizontal layout, full width
  /// otherwise.
  final WebElementChrome sections;

  /// Paint-ready chrome for each per-section `<div>` — `flex flex-col`
  /// plus layout-driven alignment (centred for `CoreFooterLayout.center`,
  /// start-aligned otherwise) plus the body typography emitted through
  /// `emitTypography` (role + weight token classes for a pure role,
  /// inline overlays for explicit scalars / raw colour). Single drop-in
  /// className / inlineStyles pair — `footer.dart` never composes
  /// additional classes onto it.
  final WebElementChrome section;

  /// Paint-ready chrome for the per-section title `<div>` — the title
  /// typography emitted through `emitTypography` (role + weight token
  /// classes for a pure role, inline overlays for explicit scalars / raw
  /// colour). `footer.dart` skips the element when `section.title` is
  /// null / empty. The bottom-margin spacer to the section children is
  /// rendered as an explicit `Gap(gapStyle: sectionTitleGapStyle)`
  /// sibling (no inline `margin-bottom` here — Web/Flutter parity).
  final WebElementChrome title;

  /// Paint-ready chrome for the legal block — a vertical stack with
  /// `legalSpacing` between the company row, the link row, and the
  /// copyright line.
  final WebElementChrome legal;

  /// Paint-ready chrome for the company row — a wrapping horizontal row
  /// with `companyRowSpacing` between the company name, the hairline
  /// tick, and the composed disclosure.
  ///
  /// Start-aligned rather than centre-aligned on purpose: the composed
  /// `Collapsible` grows downward when it expands, and centring would
  /// re-centre the company name against the taller row every time the
  /// disclosure is toggled — a visible jump on a control that is not
  /// supposed to move anything above it.
  final WebElementChrome companyRow;

  /// Paint-ready chrome for the company-name wrapper — the company
  /// typography emitted through `emitTypography`, installed as the
  /// ambient text style so a plain `Text('…')` in the slot inherits it
  /// and a `Text('…').titleMedium` chain still wins.
  final WebElementChrome company;

  /// Paint-ready chrome for the hairline tick that separates inline
  /// legal items — a fixed-height box whose className / inlineStyles are
  /// forwarded to the composed `Divider` as layout passthrough.
  ///
  /// The height is the footer's own `inlineDividerLength`: a vertical
  /// `Divider` sizes itself `h-full`, so it draws nothing until
  /// something states the box it lives in.
  final WebElementChrome inlineDividerBox;

  /// Paint-ready chrome for the legal link row — a wrapping horizontal
  /// row with `linkRowSpacing` between each link and the ticks. Centred
  /// alignment is safe here (unlike [companyRow]) because nothing in the
  /// row changes height.
  final WebElementChrome linkRow;

  /// Paint-ready chrome for the copyright wrapper — the copyright
  /// typography emitted through `emitTypography`, installed as the
  /// ambient text style the same way as [company].
  final WebElementChrome copyright;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)` between
  /// a section title and its children (mirrors Flutter, which forwards
  /// the slot to the `Gap` widget rendered at the same position).
  final CoreGapStyle sectionTitleGapStyle;

  /// Nested [CoreDividerStyle] slot — passed to the `Divider` drawing
  /// the opt-in top rule. Raw-forwarded; the `Divider`'s own resolver
  /// fills the remaining defaults.
  final CoreDividerStyle dividerStyle;

  /// Nested [CoreDividerStyle] slot — passed to every `Divider` drawing
  /// a hairline tick between inline legal items. Raw-forwarded; the
  /// tick's length rides [inlineDividerBox], because a divider has no
  /// length of its own.
  final CoreDividerStyle inlineDividerStyle;

  /// Nested [CoreCollapsibleStyle] slot — passed to the `Collapsible`
  /// drawing the business-info disclosure. Raw-forwarded; the
  /// `Collapsible`'s own resolver fills the remaining defaults and draws
  /// the chevron.
  final CoreCollapsibleStyle collapsibleStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFooter] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.footer.style
///   → widget.footerStyle
/// ```
///
/// The semantic [layout] is a widget prop — it threads through to pick
/// the layout-derived classes here (flex direction / alignment). The
/// theme can only supply it when the caller left it null (render-only.md
/// (c) — a theme-override of a semantic identifier would split Flutter
/// from Web).
ResolvedFooter resolveFooter(
  BuildContext context, {
  CoreFooterLayout? layout,
  CoreFooterStyle? footerStyle,
}) {
  final footerTheme = context.theme.coreComponentTheme?.footer;

  // ─── Merge chain (Stage1 RESOLVE — Flutter = Web) ─────
  final merged = resolveStyleChain(const CoreFooterStyle(), [
    footerTheme?.style,
    footerStyle,
  ]);

  // ─── Stage1 RESOLVE — paint-direct Core values (local) ─
  // Semantic identifier — widget prop only (render-only.md (c)).
  final effectiveLayout =
      layout ?? merged.layout ?? CoreFooterStyle.defaultLayout;
  // Dimensional chrome (padding / the four gaps / tick length) is
  // **always** emitted inline (`(merged.X ?? default)` → rem) — no
  // `p-*` / `gap-*` Tailwind class. Default and override share one CSS
  // surface so the resolved chrome reflects `merged.X` directly. The
  // title gap is forwarded as a nested `CoreGapStyle` slot to `Gap`.
  // Logical longhands when the value is directional — a caller may state
  // the inset as `start` / `end`, and the `padding` shorthand is
  // physical by construction, so flattening it would be right in English
  // and wrong in Arabic with nothing to see in between. The Flutter twin
  // preserves the same distinction with `toGeometry()`.
  final paddingDeclarations = (merged.padding ?? CoreFooterStyle.defaultPadding)
      .toLogicalDeclarations('padding');
  final blockSpacing =
      merged.blockSpacing ?? CoreFooterStyle.defaultBlockSpacing;
  final sectionSpacing =
      merged.sectionSpacing ?? CoreFooterStyle.defaultSectionSpacing;
  final legalSpacing =
      merged.legalSpacing ?? CoreFooterStyle.defaultLegalSpacing;
  final companyRowSpacing =
      merged.companyRowSpacing ?? CoreFooterStyle.defaultCompanyRowSpacing;
  final linkRowSpacing =
      merged.linkRowSpacing ?? CoreFooterStyle.defaultLinkRowSpacing;
  final inlineDividerLength =
      merged.inlineDividerLength ?? CoreFooterStyle.defaultInlineDividerLength;
  // Nested slots — the design-system default merged with the
  // per-instance override, forwarded raw (pre-scaling) to the child that
  // owns them. Each receiving component runs its own resolve step, so
  // the footer never reaches into a child's defaults field-by-field
  // (style-contract.md "합성 = 재구현 금지" facet 3).
  final sectionTitleGapStyle = CoreFooterStyle.defaultSectionTitleGapStyle
      .merge(
        merged.sectionTitleGapStyle,
      );
  final dividerStyle = CoreFooterStyle.defaultDividerStyle.merge(
    merged.dividerStyle,
  );
  final inlineDividerStyle = CoreFooterStyle.defaultInlineDividerStyle.merge(
    merged.inlineDividerStyle,
  );
  final collapsibleStyle = CoreFooterStyle.defaultCollapsibleStyle.merge(
    merged.collapsibleStyle,
  );

  // ─── Stage2 EMIT — Web (theme-free, token names only) ──
  // Every colour / typography value routes through the emit family —
  // a single class-XOR-inline decision per design value. Token-bound
  // values emit Tailwind classes (dark-mode reactive); raw overrides go
  // inline. No `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `.token!.name` role-class construction.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreFooterStyle.defaultBackgroundColor,
    .background,
  );
  // Default cascade text colour on the root — the body slot's colour
  // (override or shared default) drives it. The same colour also lands on
  // the section / title typography emit below (CSS inheritance makes the
  // duplicate harmless); emitting it here keeps the caller-supplied
  // `aside` (outside any section) tracking the footer text colour.
  final textEmit = emitColor(
    merged.bodyTextStyle?.color,
    CoreFooterStyle.defaultBodyTextStyle.color!,
    .text,
  );
  // Section body / title typography — role + weight token classes for a
  // pure role; explicit scalar overlays + raw colour go inline. The
  // design-system default token-backed `CoreTextStyle` is the fallback.
  final sectionTypographyEmit = emitTypography(
    merged.bodyTextStyle,
    CoreFooterStyle.defaultBodyTextStyle,
  );
  final titleTypographyEmit = emitTypography(
    merged.titleTextStyle,
    CoreFooterStyle.defaultTitleTextStyle,
  );
  // Legal-block typography — the company name and the copyright line each
  // carry their own role, so each gets its own emit. The disclosure's
  // trigger / paragraph typography is NOT here: it belongs to the composed
  // `Collapsible` and travels in [collapsibleStyle].
  final companyTypographyEmit = emitTypography(
    merged.companyTextStyle,
    CoreFooterStyle.defaultCompanyTextStyle,
  );
  final copyrightTypographyEmit = emitTypography(
    merged.copyrightTextStyle,
    CoreFooterStyle.defaultCopyrightTextStyle,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg explosion.

  /// Converts a logical-pixel dimension to an inline `rem` string. Gaps
  /// go through `spaceCss` instead, so a step names its `--coui-space-*`
  /// variable.
  String rem(double px) => '${px / kRemDivisor}rem';

  /// The direction / cross-axis alignment classes the resolved layout
  /// puts on both bands the Layout axis flips — the `main` row holding
  /// `aside` + `sections`, and the `sections` wrapper itself.
  List<String> bandDirectionClasses() => switch (effectiveLayout) {
    .horizontal => const [
      WebLayout.flexRow,
      WebLayout.flexWrap,
      WebLayout.itemsStart,
    ],
    .vertical => const [WebLayout.flexCol, WebLayout.itemsStart],
    .center => const [WebLayout.flexCol, WebLayout.itemsCenter],
  };

  /// Composes the outer `<footer>` Tailwind className — a `flex w-full`
  /// column, the centred-layout text alignment, and the background /
  /// cascade-text colour class fragments from the emit family (empty
  /// when the value went inline). No padding and no gap: both ride the
  /// content box so the top rule bleeds (see [buildContentChrome]).
  String buildRootClassName() {
    return [
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.wFull,
      if (effectiveLayout == .center) 'text-center',
      backgroundEmit.className,
      textEmit.className,
      // Marks this band as a component surface, so a material preset
      // reaches it. Its Flutter twin gets the same treatment by
      // composing `OutlinedContainer`. Unconditional (unlike
      // `Fieldset`/`Accordion`) — the background always resolves to a
      // real, opaque design token (`CoreFooterStyle.defaultBackgroundColor`),
      // never the transparent sentinel, so there is no fill-less-band
      // risk to gate against.
      ...webSurfaceMarkerFor(.content),
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer `<footer>` inline-CSS bundle — background /
  /// cascade-text colour fragments from the emit family (raw overrides
  /// only; token values stay on classes) plus the surface fill variable.
  ///
  /// No padding and no gap here. The rule is drawn flush — against the
  /// top edge, and against the box below it — so an inset or a gap on
  /// this box would move it off the edge the designer drew it on.
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        ...?backgroundEmit.inline,
        ...?textEmit.inline,
        // The other half of the surface marker above.
        ...surfaceFillVar(
          merged.backgroundColor ?? CoreFooterStyle.defaultBackgroundColor,
        ),
      },
    );
  }

  /// Composes the padded content box `<div>` chrome — all four padding
  /// sides plus the block gap between the navigation band and the legal
  /// block.
  ///
  /// This box, not the root, is what the band's inset applies to: the
  /// rule above it is full-bleed and flush, so every side of the inset
  /// has to start below it.
  WebElementChrome buildContentChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.wFull,
    ].join(' '),
    inlineStyles: Styles(
      raw: {
        ...paddingDeclarations,
        'gap': spaceCss(blockSpacing),
      },
    ),
  );

  /// Composes the navigation band `<div>` chrome — the layout-driven
  /// direction plus `sectionSpacing` between `aside` and the sections
  /// wrapper (the gap the two carried as siblings of one row before the
  /// band existed, so an existing footer's spacing is unchanged).
  WebElementChrome buildMainChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      ...bandDirectionClasses(),
      WebLayout.wFull,
    ].join(' '),
    inlineStyles: Styles(raw: {'gap': spaceCss(sectionSpacing)}),
  );

  /// Composes the sections-wrapper `<div>` chrome — the same
  /// layout-driven direction as the band, plus `sectionSpacing` between
  /// the nav columns.
  ///
  /// In the horizontal layout it grows into whatever the `aside` leaves
  /// (`flex-1 min-w-0`, so a long column can wrap instead of forcing the
  /// row wider); in the stacked layouts it simply spans the column.
  WebElementChrome buildSectionsChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      ...bandDirectionClasses(),
      if (effectiveLayout == .horizontal) ...[
        WebLayout.flex1,
        WebLayout.minWZero,
      ] else
        WebLayout.wFull,
    ].join(' '),
    inlineStyles: Styles(raw: {'gap': spaceCss(sectionSpacing)}),
  );

  /// Composes the per-section `<div>` Tailwind className — `flex
  /// flex-col` plus layout-driven alignment plus the body typography
  /// class fragment from the emit family (`text-{role} font-{weight}` for
  /// a pure role; empty when the body style went fully inline).
  String buildSectionClassName() {
    final alignClass = effectiveLayout == .center
        ? WebLayout.itemsCenter
        : WebLayout.itemsStart;
    return [
      WebLayout.flex,
      WebLayout.flexCol,
      alignClass,
      sectionTypographyEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the per-section `<div>` inline-CSS bundle — the body
  /// typography inline fragment from the emit family (explicit scalar
  /// overlays + raw colour). Returns `null` when no override applies.
  Styles? buildSectionInlineStyles() {
    final inline = sectionTypographyEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the per-section title `<div>` Tailwind className — the
  /// title typography class fragment from the emit family
  /// (`text-{role} font-{weight}` for a pure role; empty when fully
  /// inline).
  String buildTitleClassName() {
    return titleTypographyEmit.className;
  }

  /// Composes the per-section title `<div>` inline-CSS bundle — the title
  /// typography inline fragment from the emit family (explicit scalar
  /// overlays + raw colour). Returns `null` when no override applies — the
  /// bottom-margin spacer is rendered as an explicit `Gap` sibling in
  /// `footer.dart`, not as inline CSS here.
  Styles? buildTitleInlineStyles() {
    final inline = titleTypographyEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the legal block `<div>` chrome — a vertical stack with
  /// `legalSpacing` between its rows, aligned the way the resolved
  /// layout aligns everything else.
  WebElementChrome buildLegalChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.wFull,
      if (effectiveLayout == .center)
        WebLayout.itemsCenter
      else
        WebLayout.itemsStart,
    ].join(' '),
    inlineStyles: Styles(raw: {'gap': spaceCss(legalSpacing)}),
  );

  /// Composes the company row `<div>` chrome — a wrapping horizontal row
  /// with `companyRowSpacing` between its items.
  ///
  /// Start-aligned, not centred: the composed `Collapsible` grows
  /// downward when expanded, and centring would move the company name
  /// every time the disclosure is toggled.
  WebElementChrome buildCompanyRowChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      WebLayout.flexRow,
      WebLayout.flexWrap,
      WebLayout.itemsStart,
      WebLayout.wFull,
      if (effectiveLayout == .center) WebLayout.justifyCenter,
    ].join(' '),
    inlineStyles: Styles(raw: {'gap': spaceCss(companyRowSpacing)}),
  );

  /// Composes the company-name wrapper `<div>` chrome — the company
  /// typography from the emit family (role + colour classes for a pure
  /// role, explicit overlays inline) plus `break-words` so a long legal
  /// name wraps instead of widening the row.
  WebElementChrome buildCompanyChrome() {
    final inline = companyTypographyEmit.inline;
    return WebElementChrome(
      className: [
        WebLayout.breakWords,
        companyTypographyEmit.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: inline == null ? null : Styles(raw: inline),
    );
  }

  /// Composes the hairline-tick box chrome — a fixed-height,
  /// non-shrinking box forwarded to the composed `Divider` as layout
  /// passthrough (`classes` / `css`).
  ///
  /// A vertical `Divider` states `h-full`, which resolves to nothing in a
  /// row whose items are start-aligned. The length the designer drew
  /// (`inlineDividerLength`) is the footer's own field precisely because
  /// `CoreDividerStyle` has none.
  WebElementChrome buildInlineDividerBoxChrome() => WebElementChrome(
    className: WebLayout.shrinkZero,
    inlineStyles: Styles(raw: {'height': rem(inlineDividerLength)}),
  );

  /// Composes the legal link row `<div>` chrome — a wrapping horizontal
  /// row with `linkRowSpacing` between the links and the ticks. Centred
  /// alignment is safe here: nothing in this row changes height.
  WebElementChrome buildLinkRowChrome() => WebElementChrome(
    className: [
      WebLayout.flex,
      WebLayout.flexRow,
      WebLayout.flexWrap,
      WebLayout.itemsCenter,
      WebLayout.wFull,
      if (effectiveLayout == .center) WebLayout.justifyCenter,
    ].join(' '),
    inlineStyles: Styles(raw: {'gap': spaceCss(linkRowSpacing)}),
  );

  /// Composes the copyright wrapper `<div>` chrome — the copyright
  /// typography from the emit family plus `break-words`, same shape as
  /// [buildCompanyChrome].
  WebElementChrome buildCopyrightChrome() {
    final inline = copyrightTypographyEmit.inline;
    return WebElementChrome(
      className: [
        WebLayout.breakWords,
        copyrightTypographyEmit.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: inline == null ? null : Styles(raw: inline),
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedFooter(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    content: buildContentChrome(),
    main: buildMainChrome(),
    sections: buildSectionsChrome(),
    section: WebElementChrome(
      className: buildSectionClassName(),
      inlineStyles: buildSectionInlineStyles(),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    legal: buildLegalChrome(),
    companyRow: buildCompanyRowChrome(),
    company: buildCompanyChrome(),
    inlineDividerBox: buildInlineDividerBoxChrome(),
    linkRow: buildLinkRowChrome(),
    copyright: buildCopyrightChrome(),
    sectionTitleGapStyle: sectionTitleGapStyle,
    dividerStyle: dividerStyle,
    inlineDividerStyle: inlineDividerStyle,
    collapsibleStyle: collapsibleStyle,
  );
}
