import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `DescriptionCard`.
///
/// Widget tree (`co_description_card` decides which optional branches
/// render):
///
/// ```text
/// optional Clickable (when onTap != null — tap / cursor / focus ring)
///   └─ optional DecoratedBox (when boxShadowOverride != null)
///        └─ OutlinedContainer (containerStyle)
///             └─ Column
///                  ├─ (whole column wrapped in
///                  │  Opacity(disabledContentOpacity) while disabled)
///                  ├─ optional title section
///                  │    └─ Row (IconTheme(titleLeadingIconTheme)
///                  │         → titleLeading + Text(titleTextStyle)
///                  │         + titleTrailing)
///                  │    └─ Gap (titleContentGapStyle) + optional Divider + Gap
///                  ├─ rows Column (spacing: rowSpacing)
///                  │    └─ per-row Padding (rowPadding)
///                  │         └─ Row/Column (labelValueTextStyle + per-row merge)
///                  │       interleaved with optional Divider
///                  └─ optional bottom-action section
///                       └─ Gap + optional Divider + Gap + bottomAction
/// ```
///
/// Inter-slot spacers are rendered through the unified `Gap` widget
/// (Epic #1603 옵션 B — raw `SizedBox` chrome is forbidden). The
/// nested `*GapStyle: CoreGapStyle` slots are forwarded to
/// `Gap(gapStyle: …)` raw (Gap self-scales); the `rowSpacing`
/// flat double is consumed natively as `Column(spacing: rowSpacing)`
/// in `co_description_card` so the inter-row gap doesn't require a
/// `Gap` interleave.
///
/// Field grouping:
///
/// 1. **Paint-ready typography** — `titleTextStyle` /
///    `labelValueTextStyle: TextStyle` carry the resolved base
///    typography (with the title colour already applied to
///    `titleTextStyle`). The widget layers per-row emphasis / overrides
///    on top via the shared `applyCoreTextStyle` helper.
/// 2. **Nested text slots** — `labelTextStyle` / `valueTextStyle` /
///    `emphasizedLabelTextStyle` / `emphasizedValueTextStyle:
///    CoreTextStyle?` stay as `coui_core` types so the widget composes
///    them onto the per-row base style at render time.
/// 3. **Surface chrome** — `containerStyle: CoreOutlinedContainerStyle`
///    for the composed `OutlinedContainer` (#4362 — this card composes
///    the shared surface primitive instead of drawing its own
///    `DecoratedBox`, so the active preset's material / injected cast /
///    forced-colours boundary reach it the same way they reach `Card`).
///    `boxShadowOverride` surfaces `CoreDescriptionCardStyle.boxShadow`
///    because `OutlinedContainer` only exposes elevation — the widget
///    wraps the composed surface in a `DecoratedBox` when the override
///    is non-null (mirrors `ResolvedCard.boxShadowOverride`).
/// 4. **Child-component contract slot** — `dividerColor: CoreColor?`
///    forwarded straight to `Divider(dividerStyle:)` (the child runs
///    its own colour resolution / default fallback).
/// 5. **Dimensional gaps** — the `*Gap` / `*Spacing` doubles drive the
///    `Gap` spacers between rows / around the title / leading icons.
/// 6. **Interaction slot** — `clickableStyle: CoreClickableStyle`
///    raw-forwarded to the composed `Clickable` that wraps the card /
///    a tappable row (press shrink off by default).
class ResolvedDescriptionCard {
  /// Creates a [ResolvedDescriptionCard].
  const ResolvedDescriptionCard({
    required this.containerStyle,
    required this.backgroundColor,
    required this.surfaceBlur,
    required this.surfaceSheen,
    required this.boxShadowOverride,
    required this.titleTextStyle,
    required this.titleLeadingIconTheme,
    required this.labelValueTextStyle,
    required this.labelTextStyle,
    required this.valueTextStyle,
    required this.emphasizedLabelTextStyle,
    required this.emphasizedValueTextStyle,
    required this.dividerColor,
    required this.rowSpacing,
    required this.rowPadding,
    required this.valueTextAlign,
    required this.columnGapStyle,
    required this.iconLabelGapStyle,
    required this.labelValueGapStyle,
    required this.titleContentGapStyle,
    required this.rowLeadingGapStyle,
    required this.clickableStyle,
    required this.disabledContentOpacity,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// surface (#4362) — background / border / radius / padding are all
  /// merged and expressed as `coui_core` domain types so the receiving
  /// widget runs its own colour / radius resolution once. Surface
  /// material (blur / opacity / sheen) is resolved by `OutlinedContainer`
  /// itself from the active theme's `content`-role surface preset — this
  /// resolver no longer reimplements that logic.
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready fill colour the composed `OutlinedContainer` actually
  /// resolves [containerStyle] to — read back via `resolveOutlinedContainer`
  /// (not recomputed here, `합성 = 재구현 금지`) so a caller that needs to
  /// know whether this card carries a fill (e.g. an adjacent surface
  /// deciding whether to draw its own boundary) doesn't have to re-derive
  /// `containerStyle` itself. `.a == 0` for `ghost` (no fill).
  final Color backgroundColor;

  /// Whether this card's composed surface takes the active material —
  /// read back from the same `resolveOutlinedContainer` call, then
  /// forced to `null` when [backgroundColor] has no fill. `ghost` states
  /// no fill, so it is left out of the material pass entirely rather
  /// than showing a `0`-radius blur (`core/theme-axis-composition.md` —
  /// "표면 처리는 표면이 자기를 표면으로 말할 때만 닿는다").
  final double? surfaceBlur;

  /// Edge sheen riding the same material pass as [surfaceBlur] — `null`
  /// under the same no-fill gate.
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Caller-supplied box-shadow override (resolved to Flutter
  /// `BoxShadow` list, tinted with this card's own `shadowBaseColor`
  /// override — mirrors `ResolvedCard.boxShadowOverride`). `null` when
  /// the caller did not override — the composed `OutlinedContainer`'s
  /// own elevation (or the active style's injected rest cast) then
  /// drives the shadow.
  final List<BoxShadow>? boxShadowOverride;

  /// Paint-ready title slot [TextStyle] — the per-size typography role
  /// merged with the caller's title style. An explicit title colour
  /// overrides the slot colour, then falls back to `defaultTitleColor`.
  final TextStyle titleTextStyle;

  /// Paint-ready ambient icon theme for the `titleLeading` slot — the
  /// per-size `titleLeadingIconStyle` (size + colour) merged with the
  /// caller's override. The widget wraps the slot in `IconTheme.merge`
  /// so an `Icon` handed there without its own size / colour takes these
  /// (the `Icon` self-scales from the token size).
  final IconThemeData titleLeadingIconTheme;

  /// Paint-ready base [TextStyle] for the label / value slots — the
  /// per-size typography role (no colour; the widget applies the
  /// per-`rowWeight` label / value colours and per-row overrides on
  /// top).
  final TextStyle labelValueTextStyle;

  /// Default label text style override — merged with
  /// [labelValueTextStyle] per row. `null` when no override is set.
  final CoreTextStyle? labelTextStyle;

  /// Value text style — the per-size value role
  /// (`CoreDescriptionCardStyle` default) merged with the caller's
  /// override, applied over [labelValueTextStyle] per row. The base is the
  /// *label* role, so without this the value would keep the label's weight
  /// and line height instead of its own role's.
  final CoreTextStyle? valueTextStyle;

  /// Emphasised label text style override (applied when a row has
  /// `isEmphasized: true`). `null` when no override is set.
  final CoreTextStyle? emphasizedLabelTextStyle;

  /// Emphasised value text style override (applied when a row has
  /// `isEmphasized: true`). `null` when no override is set.
  final CoreTextStyle? emphasizedValueTextStyle;

  /// Divider line colour slot — forwarded straight to
  /// `Divider(dividerStyle: CoreDividerStyle(color: …))`. Already
  /// carries `CoreDescriptionCardStyle.defaultDividerColor` when the
  /// caller did not override it — always non-null.
  final CoreColor dividerColor;

  /// Effective vertical spacing between rows (logical px). Stays flat
  /// — the widget builds a `CoreGapStyle(size: rowSpacing)` at the
  /// render site so the inter-row spacer reuses the same `Gap`
  /// pipeline.
  final double rowSpacing;

  /// Paint-ready inset around each row's content (per-size
  /// `rowPadding`, density-folded and scaled). The row divider sits at
  /// the bottom of this inset.
  final EdgeInsets rowPadding;

  /// Horizontal alignment of the value text in the horizontal layouts.
  final TextAlign valueTextAlign;

  /// Nested [CoreGapStyle] for the horizontal label↔value gap —
  /// forwarded straight to `Gap(gapStyle: …)` (Flutter Gap
  /// self-scales).
  final CoreGapStyle columnGapStyle;

  /// Nested [CoreGapStyle] for the row leading/trailing icon ↔ adjacent
  /// text gap — forwarded straight to `Gap(gapStyle: …)`.
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreGapStyle] for the label ↔ value gap in vertical
  /// layout — forwarded straight to `Gap(gapStyle: …)`.
  final CoreGapStyle labelValueGapStyle;

  /// Nested [CoreGapStyle] for the vertical spacing around the title
  /// divider / bottom-action separator — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle titleContentGapStyle;

  /// Nested [CoreGapStyle] for the inline row leading-icon ↔ label gap
  /// in the vertical layout — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle rowLeadingGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreDescriptionCardStyle.defaultClickableStyle` (press shrink off)
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` when the card / a row is tappable.
  final CoreClickableStyle clickableStyle;

  /// Opacity the widget wraps the content (title, rows, bottom action) in
  /// while the card is disabled —
  /// `CoreDescriptionCardStyle.defaultDisabledContentOpacity` unless
  /// overridden. The box keeps its full strength.
  final double disabledContentOpacity;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDescriptionCard] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (+ defaultsBySize / defaultsByVariant chrome)
///   → theme.coreComponentTheme.descriptionCard.style
///   → widget.descriptionCardStyle
/// ```
ResolvedDescriptionCard resolveDescriptionCard(
  BuildContext context, {
  required CoreDescriptionCardVariant variant,
  required CoreDescriptionCardSize size,
  CoreDescriptionCardStyle? descriptionCardStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final cardTheme = theme.coreComponentTheme?.descriptionCard;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDescriptionCardStyle(), [
    cardTheme?.style,
    descriptionCardStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Variant-specific chrome defaults (background / border / borderWidth)
  // flow through `CoreDescriptionCardStyle.defaultsByVariant`; per-size
  // dimensional + typography defaults flow through `defaultsBySize` —
  // both Core single source shared with Web.
  final chrome = CoreDescriptionCardStyle.defaultsByVariant[variant]!;
  final sizeDefaults = CoreDescriptionCardStyle.defaultsBySize[size]!;

  // ─── Resolved chrome (domain types for OutlinedContainer) ─
  // `OutlinedContainer` accepts `CoreOutlinedContainerStyle` — its
  // contract input runs the final `scheme.resolve` / `.toValue()` step,
  // the surface-material lookup (`theme.surfaceFor(role, depth:)`) and
  // the injected-rest-cast fallback itself (#4362 — 합성, 재구현 아님).
  // Pass `CoreColor` / `CoreBorderRadius` through as-is; scaling is
  // applied widget-side (`OutlinedContainer` handles it).
  //
  // `null` background/border on the `ghost` variant means "no fill", not
  // "use OutlinedContainer's own default (M3 surface token)" — coerce to
  // the shared `CoreColor.transparent` sentinel so ghost stays
  // transparent instead of picking up a surface fill it never had.
  // `ghost` drops the size row's left / right inset (no box edge to
  // inset from); a caller `padding` still wins whole.
  final padding = chrome.paddingFor(sizeDefaults.padding!);
  final backgroundOverride = merged.backgroundColor ?? chrome.backgroundColor;
  final hasFill = backgroundOverride != null;
  final backgroundCore = backgroundOverride ?? .transparent;
  final borderCore = merged.borderColor ?? chrome.borderColor ?? .transparent;
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundCore,
    borderColor: borderCore,
    borderRadius: merged.borderRadius ?? sizeDefaults.borderRadius,
    borderWidth: merged.borderWidth ?? chrome.borderWidth,
    // Suppressed whenever the box has no fill (`ghost`) — a surface
    // that states no fill and no border never declared itself a
    // surface, so the theme's ambient cast has nothing to attach to
    // and would read as a detached smear beside the content
    // (`core/theme-axis-composition.md` — "표면 처리는 표면이 자기를
    // 표면으로 말할 때만 닿는다"). Also forwarded for an *explicit
    // empty* override — the caller's way of stating "no shadow, not
    // even the active style's ambient cast" (mirrors `CoreCardStyle`'s
    // identical handling). A *non-empty* override on a filled surface
    // is left alone here — it keeps painting through
    // `boxShadowOverride` below, unchanged.
    boxShadow:
        !hasFill || (merged.boxShadow != null && merged.boxShadow!.isEmpty)
        ? const []
        : null,
    padding: merged.padding ?? padding,
    // A variant may state no fill (`ghost`) — a material handed to a
    // fill-less box stacks a backdrop pass behind nothing and lights the
    // edge of a box that is not there, so the theme's material is
    // suppressed for exactly that variant rather than left to
    // `OutlinedContainer`'s own (fill-unaware) material lookup.
    surfaceBlur: hasFill ? null : 0,
  );

  // Read back what the composed `OutlinedContainer` actually resolved
  // `containerStyle` to — the shared resolver already ran the
  // `content`-role material lookup + `scheme.resolve` step above (line
  // ~211), so this calls it once more through its own public entry
  // point rather than re-deriving those values here (`합성 = 재구현
  // 금지`). `surfaceBlur`/`surfaceSheen` still need the `hasFill` gate:
  // `OutlinedContainer` itself does not know this card left its own fill
  // out, so its `surfaceBlur` reads `0.0` (a real, if invisible, blur
  // pass) rather than `null` (no pass at all) for `ghost`.
  final outlinedResolved = resolveOutlinedContainer(
    context,
    containerStyle: containerStyle,
  );
  final backgroundColor = outlinedResolved.backgroundColor;
  final surfaceBlur = hasFill ? outlinedResolved.surfaceBlur : null;
  final surfaceSheen = hasFill ? outlinedResolved.surfaceSheen : null;

  // Shadow base colour — this card's own override, used only for the
  // explicit `boxShadowOverride` path below (`OutlinedContainer`'s own
  // elevation / injected-cast shadow always tints with the design-system
  // `CoreColors.shadow` token, the same token `defaultShadowBaseColor`
  // aliases — so the override tint only matters when there is an actual
  // override stack to tint).
  final shadowBase = scheme
      .resolve(
        merged.shadowBaseColor ??
            CoreDescriptionCardStyle.defaultShadowBaseColor,
      )
      .toValue();
  final boxShadowOverride =
      merged.boxShadow != null && merged.boxShadow!.isNotEmpty
      ? merged.boxShadow!.toValue(base: shadowBase, geometry: theme.geometry)
      : null;

  // ─── Paint-ready typography ───────────────────────────
  // Base title / label-value typography are materialised here through
  // the per-size role. The title slot is merged before materialising so
  // partial overrides retain that role's remaining fields. The title
  // colour (explicit titleColor → slot colour → design-system
  // default) is baked into `titleTextStyle` via the single-primitive
  // `style.toValue(theme:, color:)` path; per-row emphasis / overrides
  // + per-`rowWeight` label / value colours are layered widget-side via
  // the shared `applyCoreTextStyle` helper.
  final titleCore = sizeDefaults.titleTextStyle!
      .merge(CoreDescriptionCardStyle.defaultTitleTextStyle)
      .merge(merged.titleTextStyle);
  final titleColor = scheme
      .resolve(
        merged.titleColor ??
            titleCore.color ??
            CoreDescriptionCardStyle.defaultTitleColor,
      )
      .toValue();
  final titleTextStyle = titleCore.toValue(
    color: titleColor,
    theme: theme,
  );
  // Ambient icon theme for the `titleLeading` slot — composite merge so a
  // colour-only override keeps the per-size glyph size.
  final titleLeadingIconSlot = sizeDefaults.titleLeadingIconStyle!.merge(
    merged.titleLeadingIconStyle,
  );
  final titleLeadingIconTheme = IconThemeData(
    size: titleLeadingIconSlot.size,
    color: scheme.resolve(titleLeadingIconSlot.color!).toValue(),
  );
  final valueTextAlign =
      (merged.valueTextAlign ?? CoreDescriptionCardStyle.defaultValueTextAlign)
          .toValue();
  final labelValueTextStyle = sizeDefaults.labelTextStyle!.toValue(
    theme: theme,
  );
  // The value role is its own per-size default (a heavier, tighter role
  // than the label's) — composite merge so a partial override keeps the
  // rest of the role.
  final valueTextStyle = sizeDefaults.valueTextStyle!.merge(
    merged.valueTextStyle,
  );
  // Divider colour — `merged.dividerColor` (caller override) else the
  // card's own `defaultDividerColor` (#4815 디자이너 결정 #1 —
  // outline-variant). Forwarded raw to `Divider(dividerStyle:)` below;
  // this fallback used to be missing here, so an unset override fell
  // through to `Divider`'s own default instead of this card's — the
  // two happened to agree only because both defaults were `outline` at
  // the time.
  final dividerColor =
      merged.dividerColor ?? CoreDescriptionCardStyle.defaultDividerColor;

  // ─── Dimensional + nested gap synthesis (Anti-Pattern B — all
  //     composite merge / scaling math lives in local vars so the
  //     return literal stays a bare mapping). ─────────────────────
  final rowSpacing =
      theme.geometry.space(merged.rowSpacing ?? sizeDefaults.rowSpacing!) *
      scaling;
  final rowPadding =
      (merged.rowPadding ?? sizeDefaults.rowPadding!).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final columnGapStyle = sizeDefaults.columnGapStyle!.merge(
    merged.columnGapStyle,
  );
  final iconLabelGapStyle = sizeDefaults.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  final labelValueGapStyle = sizeDefaults.labelValueGapStyle!.merge(
    merged.labelValueGapStyle,
  );
  final titleContentGapStyle = sizeDefaults.titleContentGapStyle!.merge(
    merged.titleContentGapStyle,
  );
  final rowLeadingGapStyle = CoreDescriptionCardStyle.defaultRowLeadingGapStyle
      .merge(merged.rowLeadingGapStyle);
  // Nested Clickable slot — partial default (press shrink off) merged
  // with the override, raw-forwarded (the Clickable's own resolver
  // fills the rest).
  final clickableStyle = CoreDescriptionCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  final disabledContentOpacity =
      merged.disabledContentOpacity ??
      CoreDescriptionCardStyle.defaultDisabledContentOpacity;

  return ResolvedDescriptionCard(
    containerStyle: containerStyle,
    backgroundColor: backgroundColor,
    surfaceBlur: surfaceBlur,
    surfaceSheen: surfaceSheen,
    boxShadowOverride: boxShadowOverride,
    titleTextStyle: titleTextStyle,
    titleLeadingIconTheme: titleLeadingIconTheme,
    labelValueTextStyle: labelValueTextStyle,
    labelTextStyle: merged.labelTextStyle,
    valueTextStyle: valueTextStyle,
    emphasizedLabelTextStyle: merged.emphasizedLabelTextStyle,
    emphasizedValueTextStyle: merged.emphasizedValueTextStyle,
    dividerColor: dividerColor,
    rowSpacing: rowSpacing,
    rowPadding: rowPadding,
    valueTextAlign: valueTextAlign,
    columnGapStyle: columnGapStyle,
    iconLabelGapStyle: iconLabelGapStyle,
    labelValueGapStyle: labelValueGapStyle,
    titleContentGapStyle: titleContentGapStyle,
    rowLeadingGapStyle: rowLeadingGapStyle,
    clickableStyle: clickableStyle,
    disabledContentOpacity: disabledContentOpacity,
  );
}
