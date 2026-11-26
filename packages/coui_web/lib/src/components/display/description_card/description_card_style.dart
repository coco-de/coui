import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DescriptionCard`.
///
/// DOM shape:
///
/// ```text
/// root (OutlinedContainer, containerStyle)      // composed surface primitive — #4362
///   ├─ body (<div>)                             // content / disabledContent — title, rows, bottom action
///   ├─ title (<div>)?                           // co_description_card renders only when title != null
///   │    ├─ titleLeading (caller-supplied)?
///   │    ├─ Gap(iconLabelGapStyle)?           // only when titleLeading != null
///   │    ├─ titleText (<span>)                  // typography + title colour
///   │    ├─ titleSpacer (<div>)?                // flex-1 spacer (only when titleTrailing)
///   │    ├─ Gap(iconLabelGapStyle)?           // only when titleTrailing != null
///   │    └─ titleTrailing (caller-supplied)?
///   ├─ Gap(titleContentGapStyle)              // co_description_card emits before/after each divider
///   ├─ Divider(dividerStyle)?                 // co_description_card renders after title / between rows / before bottomAction
///   ├─ Gap(titleContentGapStyle)              // co_description_card emits before/after each divider
///   ├─ rows (<div>)                             // flex-col with per-size rowSpacing
///   │    └─ row (<div>) *                       // per-row chrome resolved by resolveDescriptionCardRow
///   └─ bottomAction (caller-supplied)?          // co_description_card renders only when bottomAction != null
/// ```
///
/// All slot chromes are non-null — `co_description_card` decides
/// whether to render each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [titleContentGapStyle] / [iconLabelGapStyle] are
///   forwarded to `Gap` for title/bottom-action and leading-icon
///   spacing; [dividerStyle] is forwarded to `Divider` for the
///   title / inter-row / bottom-action lines (mirrors the Flutter
///   `Divider(dividerStyle: …)` / `Gap(gapStyle: …)`
///   source-of-truth tree, #1659).
///
/// No scalar metadata (size / layout / alignment / dividerColor / text
/// style overrides / displayValue …) is exposed — semantic identifiers
/// stay on the widget prop and the per-row resolver consumes merged
/// style internally.
class ResolvedDescriptionCard implements WebResolvedChrome {
  /// Creates a [ResolvedDescriptionCard].
  const ResolvedDescriptionCard({
    required this.root,
    required this.containerStyle,
    required this.boxShadowOverride,
    required this.title,
    required this.titleText,
    required this.titleSpacer,
    required this.content,
    required this.disabledContent,
    required this.dividerStyle,
    required this.rows,
    required this.titleContentGapStyle,
    required this.iconLabelGapStyle,
    required this.titleLeadingIconStyle,
    required this.clickableStyle,
  });

  /// Structural chrome for the outer card element — `flex flex-col
  /// w-full h-full` only. Forwarded as `OutlinedContainer(classes: …)`
  /// so it merges with that primitive's own chrome classes on the same
  /// root (#4362 — no chrome lives here any more, only layout).
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the composed
  /// `OutlinedContainer` root (#4362) — raw-forwarded straight to
  /// `OutlinedContainer(containerStyle: …)`; that widget's own resolver
  /// owns border/radius/background/material emit (no className /
  /// inlineStyles assembly here). Mirrors the Flutter
  /// `ResolvedDescriptionCard.containerStyle`.
  final CoreOutlinedContainerStyle containerStyle;

  /// Chrome for the caller-supplied box-shadow override's wrapper
  /// `<div>` — empty className, inline `box-shadow` tinted with this
  /// card's own `shadowBaseColor` override. `null` when the caller did
  /// not override (the composed `OutlinedContainer`'s own elevation /
  /// injected rest-cast then drives the shadow, and `co_description_card`
  /// renders no wrapper at all — this slot is design-optional, not
  /// merely instance-optional). Mirrors the Flutter
  /// `ResolvedDescriptionCard.boxShadowOverride` / `ResolvedCard
  /// .boxShadowOverride`.
  final WebElementChrome? boxShadowOverride;

  /// Paint-ready chrome for the optional title row `<div>` — flex row
  /// (no inline `gap-*` chrome — the leading/trailing `Gap`
  /// siblings carry the icon-label spacing). `co_description_card`
  /// renders this slot only when `title != null`.
  final WebElementChrome title;

  /// Paint-ready chrome for the title text `<span>` — typography +
  /// title-colour Tailwind class.
  final WebElementChrome titleText;

  /// Paint-ready chrome for the `flex-1` spacer `<div>` between
  /// `titleText` and `titleTrailing`. `co_description_card` renders
  /// this slot only when `titleTrailing != null`.
  final WebElementChrome titleSpacer;

  /// The content column (title, rows, bottom action region) at rest.
  final WebElementChrome content;

  /// The content column while the card is disabled — the same column at
  /// `disabledContentOpacity`. The box keeps its full strength.
  final WebElementChrome disabledContent;

  /// Nested [CoreDividerStyle] for the title / inter-row /
  /// bottom-action separator lines — forwarded to
  /// `Divider(dividerStyle: …)`. Carries the resolved divider colour
  /// (caller override → `defaultDividerColor`, the same `CoreColor`
  /// token the Flutter side passes to its `Divider`, #1659).
  final CoreDividerStyle dividerStyle;

  /// Paint-ready chrome for the rows wrapper `<div>` — `flex flex-col
  /// gap-{rowSpacing}`.
  final WebElementChrome rows;

  /// Nested [CoreGapStyle] for the title / bottom-action spacers —
  /// forwarded to `Gap(gapStyle: …)`. Carries the resolved title
  /// content gap.
  final CoreGapStyle titleContentGapStyle;

  /// Nested [CoreGapStyle] for the inline gap between a row's
  /// leading/trailing icon (or title's `titleLeading`/`titleTrailing`)
  /// and the adjacent text — forwarded to `Gap(gapStyle: …)`. Same
  /// `CoreGapStyle` slot the Flutter side passes to its `Gap`
  /// (#1659).
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreDescriptionCardStyle.defaultClickableStyle` (press shrink off)
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` when the card / a row is tappable.
  final CoreClickableStyle clickableStyle;

  /// Per-size `titleLeadingIconStyle` merged with the caller's override —
  /// handed to the `titleLeading` slot as its ambient `IconTheme`, so an
  /// `Icon` passed there without its own size / colour takes these.
  final CoreIconStyle titleLeadingIconStyle;
}

/// Paint-ready chrome for a single row of `DescriptionCard` (Web).
///
/// DOM shape (per layout / alignment chosen by `co_description_card`):
///
/// ```text
/// root (<div>)                                  // per-row flex layout (tap chrome owned by the composing Clickable)
///   ├─ rowLeadingBlock (<div>)?                 // wraps row.leading + Gap(rowLeadingGapStyle) + label (vertical layout)
///   ├─ row.leading (caller-supplied)?
///   ├─ Gap(iconLabelGapStyle | rowLeadingGapStyle)?
///   ├─ label (<span>)                           // typography + rowWeight label colour
///   ├─ Gap(columnGapStyle | labelValueGapStyle)?  // depending on layout
///   ├─ rowSpacer (<div>)?                       // flex-1 spacer (spaceBetween layout)
///   ├─ value (<span>) | rowValueExpand (<div>)  // value text container
///   ├─ Gap(iconLabelGapStyle)?                // before row.trailing
///   └─ row.trailing (caller-supplied)?
/// ```
///
/// All slot chromes are non-null — `co_description_card` decides which
/// optional elements actually render based on `row.leading` /
/// `row.trailing` / `row.valueWidget` and the chosen `layout` /
/// `alignment` semantic enums.
///
/// Per Epic #1603 (옵션 B 최종) the row resolver carries only
/// Cat 1 (`WebElementChrome`) slots and Cat 2 nested `CoreGapStyle`
/// slots for child `Gap` widgets — placeholder / emphasis / display
/// logic is folded into the value slot's chrome at resolve time, and
/// the widget decides which value variant (`value` vs `rowValueExpand`)
/// to render based on the widget-level `layout` / `alignment` props.
class ResolvedDescriptionCardRow implements WebResolvedChrome {
  /// Creates a [ResolvedDescriptionCardRow].
  const ResolvedDescriptionCardRow({
    required this.root,
    required this.rowLeadingBlock,
    required this.label,
    required this.rowSpacer,
    required this.value,
    required this.rowValueExpand,
    required this.columnGapStyle,
    required this.iconLabelGapStyle,
    required this.labelValueGapStyle,
    required this.rowLeadingGapStyle,
  });

  /// Paint-ready chrome for the outer row `<div>` — layout-specific
  /// flex chrome. Tap affordance (cursor / focus ring) is owned by the
  /// composing `Clickable` that wraps this row when `row.onTap` is
  /// supplied. Inline gap chrome is NOT emitted here — the inter-slot
  /// `Gap` siblings carry the spacing.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the optional `<div>` wrapping
  /// `row.leading + Gap(rowLeadingGapStyle) + label` in the
  /// `vertical` layout. Empty className when not applicable.
  final WebElementChrome rowLeadingBlock;

  /// Paint-ready chrome for the label `<span>` — typography +
  /// rowWeight-colour className plus row-level `CoreTextStyle`
  /// overrides.
  final WebElementChrome label;

  /// Paint-ready chrome for the `flex-1` spacer `<div>` between label
  /// and value in `spaceBetween` layout.
  final WebElementChrome rowSpacer;

  /// Paint-ready chrome for the value `<span>` — typography +
  /// rowWeight-colour className plus row-level `CoreTextStyle`
  /// overrides plus optional placeholder colour (when the row's value
  /// is empty).
  final WebElementChrome value;

  /// Paint-ready chrome for the `flex-1`-wrapped value `<div>` for the
  /// default horizontal `fixed` layout — same colour / typography
  /// classes as [value] plus `flex-1`.
  final WebElementChrome rowValueExpand;

  /// Nested [CoreGapStyle] for the horizontal label↔value gap (used in
  /// horizontal `fixed` and `spaceBetween` layouts) — forwarded to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle columnGapStyle;

  /// Nested [CoreGapStyle] for the inline gap between a row's
  /// leading/trailing icon and the adjacent text/value — forwarded to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreGapStyle] for the vertical label↔value gap in the
  /// `vertical` layout — forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle labelValueGapStyle;

  /// Nested [CoreGapStyle] for the inline `row.leading + label` gap
  /// inside [rowLeadingBlock] (vertical layout) — forwarded to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle rowLeadingGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDescriptionCard] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant + per size)
///   → theme.coreComponentTheme.descriptionCard.style
///   → widget.descriptionCardStyle
/// ```
ResolvedDescriptionCard resolveDescriptionCard(
  BuildContext context, {
  required CoreDescriptionCardVariant variant,
  required CoreDescriptionCardSize size,
  CoreDescriptionCardStyle? descriptionCardStyle,
}) {
  final cardTheme = context.theme.coreComponentTheme?.descriptionCard;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDescriptionCardStyle(), [
    cardTheme?.style,
    descriptionCardStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantChrome = CoreDescriptionCardStyle.defaultsByVariant[variant]!;
  final sizeChrome = CoreDescriptionCardStyle.defaultsBySize[size]!;

  // ─── Resolved chrome values ───────────────────────────
  // Padding / border-radius now flow through `containerStyle` below
  // (domain types, unmaterialized) instead of a locally-inlined CSS
  // string — the composed `OutlinedContainer` owns that emit (#4362).
  //
  // Title bottom-spacing — forwarded straight to `Gap(gapStyle: …)`
  // siblings (around dividers, around bottom action). No inline CSS or
  // Tailwind `pb-*` class is emitted; the `Gap` widget owns its
  // chrome (#1659 nested `CoreGapStyle` slot).
  final titleContentGapStyle = sizeChrome.titleContentGapStyle!.merge(
    merged.titleContentGapStyle,
  );
  // Icon ↔ label gap — forwarded to `Gap(gapStyle: …)` siblings on
  // either side of `titleLeading` / `titleTrailing` and a row's
  // `leading` / `trailing`. The previous Tailwind `gap-*` class on the
  // title row is replaced by explicit `Gap` widgets.
  final iconLabelGapStyle = sizeChrome.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // Title text colour — caller override wins, else design-system
  // default (Epic #1603 coverage gate — `titleColor` reflected here).
  // Token colour drives the `text-<token>` class; a per-instance
  // override suppresses the class and emits an inline `color` rule.
  final titleColor =
      merged.titleColor ?? CoreDescriptionCardStyle.defaultTitleColor;
  // Only an explicit role needs a new class. Unset/scalar overrides keep
  // the existing size-role class and its reactive theme typography.
  final titleTokenTypography = merged.titleTextStyle?.token == null
      ? null
      : emitTypography(
          merged.titleTextStyle,
          // SemiBold rides the size role (Core merge keeps a weight
          // overlay across a later role) — the same chain Flutter folds.
          sizeChrome.titleTextStyle!.merge(
            CoreDescriptionCardStyle.defaultTitleTextStyle,
          ),
        );
  // Shadow base colour — caller override wins, else design-system
  // default (Epic #1603 coverage gate — `shadowBaseColor` reflected).
  // `.toValue()` emits `rgb(var(--coui-<token>))` for tokens / `rgb(...)`
  // for raw overrides so `color-mix` layering works for both. No
  // `scheme.resolve` — it's a Web no-op (CSS resolves tokens at runtime).
  final shadowBase =
      (merged.shadowBaseColor ??
              CoreDescriptionCardStyle.defaultShadowBaseColor)
          .toValue();
  // Divider colour — caller override wins, else design-system default.
  // Forwarded to the child `Divider` via [dividerStyle] (same
  // resolved `CoreColor` the Flutter side passes, #1659).
  final dividerColor =
      merged.dividerColor ?? CoreDescriptionCardStyle.defaultDividerColor;
  // Nested Clickable slot — partial default (press shrink off) merged
  // with the override, raw-forwarded (the Clickable's own resolver
  // fills the rest).
  final clickableStyle = CoreDescriptionCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // Content opacity while the card is disabled — the box stays full.
  final disabledContentOpacity =
      merged.disabledContentOpacity ??
      CoreDescriptionCardStyle.defaultDisabledContentOpacity;
  // Ambient icon style for the `titleLeading` slot — composite merge so a
  // colour-only override keeps the per-size glyph size.
  final titleLeadingIconStyle = sizeChrome.titleLeadingIconStyle!.merge(
    merged.titleLeadingIconStyle,
  );
  // The title is SemiBold on every rung (`defaultTitleTextStyle`) unless
  // the caller states a weight — that one rides the inline overlay below.
  final titleWeight =
      CoreDescriptionCardStyle.defaultTitleTextStyle.fontWeight!;
  // An explicit role carries the weight in its inline overlay instead.
  final titleWeightClass =
      titleTokenTypography == null && merged.titleTextStyle?.fontWeight == null
      ? 'font-${titleWeight.tailwindFontWeight}'
      : '';

  // ─── Nested containerStyle for the composed OutlinedContainer ──
  // Theme-free (Web, #4362) — pass `CoreColor` / `CoreBorderRadius` /
  // `CoreEdgeInsets` straight through unmaterialized; the composed
  // `OutlinedContainer`'s own resolver runs the emit-family class/inline
  // decision, the surface-material lookup (`context.theme.surfaceFor`
  // equivalent — Web reads it via its own theme-free path), and the
  // injected-rest-cast fallback itself. Mirrors the Flutter
  // `containerStyle` assembly exactly.
  //
  // `null` background/border on the `ghost` variant means "no fill", not
  // "use OutlinedContainer's own default (M3 surface token)" — coerce to
  // the shared `CoreColor.transparent` sentinel so ghost stays
  // transparent instead of picking up a surface fill it never had.
  final backgroundOverride =
      merged.backgroundColor ?? variantChrome.backgroundColor;
  final hasFill = backgroundOverride != null;
  final backgroundCore = backgroundOverride ?? .transparent;
  final borderCore =
      merged.borderColor ?? variantChrome.borderColor ?? .transparent;
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundCore,
    borderColor: borderCore,
    borderRadius: merged.borderRadius ?? sizeChrome.borderRadius,
    borderWidth: merged.borderWidth ?? variantChrome.borderWidth,
    // Suppressed whenever the box has no fill (`ghost`) — mirrors the
    // Flutter `containerStyle` assembly: a surface that states no fill
    // and no border never declared itself a surface, so the theme's
    // ambient cast has nothing to attach to
    // (`core/theme-axis-composition.md` — "표면 처리는 표면이 자기를
    // 표면으로 말할 때만 닿는다"). Also forwarded for an *explicit
    // empty* override — a non-empty override on a filled surface paints
    // through [boxShadowOverride] below instead.
    boxShadow:
        !hasFill || (merged.boxShadow != null && merged.boxShadow!.isEmpty)
        ? const []
        : null,
    // `ghost` drops the size row's left / right inset (Core owns the rule
    // via `paddingFor`); a caller `padding` still wins whole.
    padding: merged.padding ?? variantChrome.paddingFor(sizeChrome.padding!),
    // A variant may state no fill (`ghost`) — suppress the theme's
    // material for exactly that variant rather than let
    // `OutlinedContainer`'s own (fill-unaware) material lookup blur
    // behind nothing.
    surfaceBlur: hasFill ? null : 0,
  );
  // Explicit non-empty override — tinted with this card's own
  // `shadowBaseColor` (the `containerStyle.boxShadow` slot above only
  // conveys the empty-suppress signal; `OutlinedContainer`'s own
  // elevation shadow always tints with the design-system
  // `CoreColors.shadow` token — the same token `defaultShadowBaseColor`
  // aliases, so the override tint only matters here). Wrapped as paint-
  // ready chrome for the wrapper `<div>` `co_description_card` renders
  // around the composed `OutlinedContainer` when this is non-null.
  final boxShadowOverride =
      merged.boxShadow != null && merged.boxShadow!.isNotEmpty
      ? WebElementChrome(
          className: '',
          inlineStyles: Styles(
            raw: {
              'box-shadow': emitShadow(merged.boxShadow!, base: shadowBase),
            },
          ),
        )
      : null;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer card element's structural className — sizing
  /// only (the card fills its container horizontally, matching the
  /// pre-#4362 single `<div>`'s `w-full`). Vertical arrangement of the
  /// title / rows / bottom-action slots lives on the composed
  /// `OutlinedContainer`'s content wrapper instead (`co_description_card`
  /// owns that div). Chrome (fill / border / radius / padding / shadow /
  /// material) is owned entirely by the composed `OutlinedContainer` via
  /// [containerStyle].
  String buildRootClassName() => WebLayout.wFull;

  /// Composes the title row `<div>` Tailwind className. Inline gap /
  /// bottom-padding chrome is NOT emitted — the icon-label spacing is
  /// rendered by the `Gap(iconLabelGapStyle)` siblings inside the
  /// title row, and the title↔content spacing is rendered by the
  /// `Gap(titleContentGapStyle)` siblings outside the row (#1659
  /// nested `CoreGapStyle` slot).
  String buildTitleClassName() {
    return WebLayout.flexItemsCenter;
  }

  /// Composes the title text `<span>` Tailwind className. The
  /// title-colour token class is suppressed when `titleColor` is
  /// overridden so the inline `color` rule wins (Epic #1603 chaining
  /// gate — colour token class + override inline).
  String buildTitleTextClassName() {
    final typographyClass =
        titleTokenTypography?.className ??
        (sizeChrome.titleTextStyle != null
            ? 'text-${sizeChrome.titleTextStyle!.tailwindTypographyRole}'
            : '');
    return <String>[
      if (typographyClass.isNotEmpty) typographyClass,
      if (titleWeightClass.isNotEmpty) titleWeightClass,
      if (merged.titleColor == null &&
          (titleTokenTypography == null ||
              merged.titleTextStyle?.color == null))
        'text-${titleColor.tailwindColor}',
    ].join(' ');
  }

  /// Composes the title text `<span>` inline-CSS — the resolved
  /// `titleColor` override (token class suppressed above) plus
  /// caller-supplied `titleTextStyle` overrides.
  Styles? buildTitleTextInlineStyles() {
    final style = merged.titleTextStyle;
    final raw = <String, String>{
      // A role's own slot color is already emitted canonically as a
      // token class or raw inline value, and retains this path's priority.
      if (merged.titleColor != null &&
          (titleTokenTypography == null || style?.color == null))
        'color': titleColor.toValue(),
      ...?(titleTokenTypography?.inline ?? style?.toInlineCss()),
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the `flex-1` spacer Tailwind className.
  String buildTitleSpacerClassName() => WebLayout.flex1;

  String buildContentClassName() => '${WebLayout.flex} ${WebLayout.flexCol}';

  Styles buildDisabledContentInlineStyles() =>
      Styles(raw: {'opacity': '$disabledContentOpacity'});

  /// Composes the rows wrapper `<div>` Tailwind className.
  String buildRowsClassName() {
    final rowGapClass = merged.rowSpacing == null
        ? 'gap-${sizeChrome.rowSpacing!.tailwindSpace}'
        : '';
    return <String>[
      '${WebLayout.flex} ${WebLayout.flexCol}',
      if (rowGapClass.isNotEmpty) rowGapClass,
    ].join(' ');
  }

  /// Composes the rows wrapper `<div>` inline-CSS — only emitted when
  /// the caller overrode the per-size `rowSpacing`.
  Styles? buildRowsInlineStyles() {
    if (merged.rowSpacing == null) return null;
    return Styles(raw: {'gap': spaceCss(merged.rowSpacing!)});
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDescriptionCard(
    root: WebElementChrome(className: buildRootClassName()),
    containerStyle: containerStyle,
    boxShadowOverride: boxShadowOverride,
    title: WebElementChrome(className: buildTitleClassName()),
    titleText: WebElementChrome(
      className: buildTitleTextClassName(),
      inlineStyles: buildTitleTextInlineStyles(),
    ),
    titleSpacer: WebElementChrome(className: buildTitleSpacerClassName()),
    content: WebElementChrome(className: buildContentClassName()),
    disabledContent: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildDisabledContentInlineStyles(),
    ),
    dividerStyle: CoreDividerStyle(color: dividerColor),
    rows: WebElementChrome(
      className: buildRowsClassName(),
      inlineStyles: buildRowsInlineStyles(),
    ),
    titleContentGapStyle: titleContentGapStyle,
    iconLabelGapStyle: iconLabelGapStyle,
    titleLeadingIconStyle: titleLeadingIconStyle,
    clickableStyle: clickableStyle,
  );
}

// ═══════════════════════════════════════════════════
// Per-row resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDescriptionCardRow] for a single row of
/// `DescriptionCard` (Web).
///
/// Closes over the per-row [CoreDescriptionRow.isEmphasized] +
/// `row.value == null` (placeholder) decisions plus the per-instance
/// chrome resolved from the same merge chain `resolveDescriptionCard`
/// uses. The widget reads each `WebElementChrome` slot directly — no
/// chrome composition stays in the widget. The `emptyValueBehavior`
/// filter (hide / placeholder) runs in the widget itself; the resolver
/// always builds full row chrome for the rows the widget chose to
/// render.
ResolvedDescriptionCardRow resolveDescriptionCardRow(
  BuildContext context, {
  required CoreDescriptionRow<Component> row,
  required CoreDescriptionCardSize size,
  required CoreDescriptionCardLayout layout,
  required CoreDescriptionCardOverflow valueOverflow,
  required CoreDescriptionCardRowWeight rowWeight,
  required bool isEmptyValue,
  CoreDescriptionCardStyle? descriptionCardStyle,
}) {
  final cardTheme = context.theme.coreComponentTheme?.descriptionCard;
  final merged = resolveStyleChain(const CoreDescriptionCardStyle(), [
    cardTheme?.style,
    descriptionCardStyle,
  ]);
  final sizeChrome = CoreDescriptionCardStyle.defaultsBySize[size]!;

  // Nested `CoreGapStyle` slots — design-system default per size +
  // per-instance override merged together. All four are forwarded
  // straight to `Gap(gapStyle: …)` siblings rendered by the widget
  // between row leading / label / value / trailing — no inline gap CSS
  // (#1659).
  final rowLeadingGapStyle = CoreDescriptionCardStyle.defaultRowLeadingGapStyle
      .merge(merged.rowLeadingGapStyle);
  final columnGapStyle = sizeChrome.columnGapStyle!.merge(
    merged.columnGapStyle,
  );
  final iconLabelGapStyle = sizeChrome.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  final labelValueGapStyle = sizeChrome.labelValueGapStyle!.merge(
    merged.labelValueGapStyle,
  );
  // Row inset — every side through `spaceCss` (density-routed). The
  // divider under the row sits at the bottom of this inset.
  final rowPadding = merged.rowPadding ?? sizeChrome.rowPadding!;
  // Value alignment — horizontal layouts only; the vertical layout keeps
  // the value under its label at the start.
  final valueTextAlign =
      merged.valueTextAlign ?? CoreDescriptionCardStyle.defaultValueTextAlign;

  // `isEmphasized: true` 만으로도 기본 bold 효과를 자동 적용한다.
  final emphasisAutoBold =
      row.isEmphasized &&
      !isEmptyValue &&
      merged.emphasizedValueTextStyle?.fontWeight == null &&
      row.valueTextStyle?.fontWeight == null;

  // ─── Local builders ───────────────────────────────────

  /// Composes a `CoreTextStyle` overrides map (CSS properties for the
  /// populated fields only). Returns an empty map when [style] is null.
  Map<String, String> textStyleInline(CoreTextStyle? style) {
    if (style == null) return const {};
    return {
      if (style.color != null) 'color': style.color!.toValue(),
      if (style.fontWeight != null) 'font-weight': '${style.fontWeight}',
      if (style.fontSize != null)
        'font-size': '${style.fontSize! / kRemDivisor}rem',
      ...lineBoxCss(style),
      if (style.letterSpacing != null)
        'letter-spacing': '${style.letterSpacing}em',
      if (style.fontFamily != null)
        'font-family': CssVariableGenerator.fontFamilyCss(style.fontFamily!),
    };
  }

  /// Composes the outer row `<div>` Tailwind className per `layout`.
  /// Inline gap chrome is NOT emitted — the inter-slot `Gap`
  /// siblings carry the spacing (#1659 nested `CoreGapStyle` slot).
  /// Cursor / focus / tap affordance is owned by the composing
  /// `Clickable` (`co_description_card` wraps the row when `row.onTap`
  /// is supplied) — no `cursor-pointer` class here.
  String buildRootClassName() {
    return layout == .vertical
        ? '${WebLayout.flex} ${WebLayout.flexCol}'
        : WebLayout.flexItemsCenter;
  }

  Styles buildRootInlineStyles() =>
      Styles(raw: {'padding': rowPadding.toValue()});

  /// Composes the `rowLeadingBlock` Tailwind className — wraps
  /// `row.leading + Gap(rowLeadingGapStyle) + label` in the
  /// `vertical` layout. Empty when not applicable. The leading gap is
  /// rendered as a sibling `Gap` — no inline `gap` CSS.
  String buildRowLeadingBlockClassName() {
    if (layout != .vertical || row.leading == null) return '';
    return WebLayout.flexItemsCenter;
  }

  /// Composes the label `<span>` Tailwind className.
  String buildLabelClassName() {
    final typographyClass =
        'text-${sizeChrome.labelTextStyle!.tailwindTypographyRole}';
    final colors = kCoreDescriptionCardRowWeightColors[rowWeight]!;
    return '$typographyClass text-${colors.labelColor}';
  }

  /// Composes the label `<span>` inline-CSS — default → emphasised →
  /// per-row `CoreTextStyle` overrides flattened in order so per-row
  /// wins.
  Styles? buildLabelInlineStyles() {
    final raw = <String, String>{
      ...textStyleInline(merged.labelTextStyle),
      if (row.isEmphasized) ...textStyleInline(merged.emphasizedLabelTextStyle),
      ...textStyleInline(row.labelTextStyle),
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the value `<span>` Tailwind className.
  String buildValueClassName() {
    final typographyClass =
        'text-${sizeChrome.valueTextStyle!.tailwindTypographyRole}';
    final colors = kCoreDescriptionCardRowWeightColors[rowWeight]!;
    final overflowClass = valueOverflow == .ellipsis ? WebLayout.truncate : '';
    return <String>[
      typographyClass,
      'text-${colors.valueColor}',
      if (layout != .vertical) 'text-${valueTextAlign.toValue()}',
      if (overflowClass.isNotEmpty) overflowClass,
    ].join(' ');
  }

  /// Composes the `flex-1`-wrapped value Tailwind className for the
  /// default horizontal `fixed` layout.
  String buildRowValueExpandClassName() =>
      '${WebLayout.flex1} ${buildValueClassName()}';

  /// Composes the `flex-1` spacer Tailwind className for the
  /// `spaceBetween` horizontal layout.
  String buildRowSpacerClassName() => WebLayout.flex1;

  /// Composes the value inline-CSS — default → emphasised → per-row
  /// `CoreTextStyle` overrides plus the auto-emphasis bold and the
  /// optional placeholder colour (when [isEmptyValue]).
  Styles? buildValueInlineStyles() {
    final String? placeholderColor;
    if (isEmptyValue) {
      // Placeholder colour reads `kCoreDescriptionCardRowWeightColors`
      // (Core single-source map). Web stringifies the token into
      // `rgb(var(--coui-<token>) / alpha)` because the CSS variable
      // holds an RGB triplet — `oklch(...)` would interpret the RGB
      // digits as L C H and produce a wildly different colour.
      final placeholderToken =
          kCoreDescriptionCardRowWeightColors[rowWeight]!.valueColor;
      placeholderColor =
          'rgb(var(--coui-$placeholderToken) / ${CoreOpacity.opacity40})';
    } else {
      placeholderColor = null;
    }
    final raw = <String, String>{
      ...textStyleInline(merged.valueTextStyle),
      if (row.isEmphasized) ...textStyleInline(merged.emphasizedValueTextStyle),
      ...textStyleInline(row.valueTextStyle),
      if (emphasisAutoBold) 'font-weight': '${CoreFontWeight.bold}',
      'color': ?placeholderColor,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  // `value` and `rowValueExpand` share the same overrides bundle —
  // they display the same string content but live in different DOM
  // wrappers depending on layout/alignment.
  final sharedValueInline = buildValueInlineStyles();

  return ResolvedDescriptionCardRow(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    rowLeadingBlock: WebElementChrome(
      className: buildRowLeadingBlockClassName(),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
    rowSpacer: WebElementChrome(className: buildRowSpacerClassName()),
    value: WebElementChrome(
      className: buildValueClassName(),
      inlineStyles: sharedValueInline,
    ),
    rowValueExpand: WebElementChrome(
      className: buildRowValueExpandClassName(),
      inlineStyles: sharedValueInline,
    ),
    columnGapStyle: columnGapStyle,
    iconLabelGapStyle: iconLabelGapStyle,
    labelValueGapStyle: labelValueGapStyle,
    rowLeadingGapStyle: rowLeadingGapStyle,
  );
}
