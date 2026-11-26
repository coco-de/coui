library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Stat`.
///
/// DOM shape:
///
/// ```text
/// root (OutlinedContainer, containerStyle)  // composed surface primitive — #4362
///   └─ content (<div>)                      // space-y-{gap} wrapper
///        ├─ labelRow (<div>)                 // flex row, label + optional icon
///        │    ├─ labelText (<span>)          // label typography + colour
///        │    └─ ...icon                     // passthrough (optional)
///        ├─ valueRow (<div>)                 // flex row on the baseline
///        │    ├─ valueText (<div>)           // value typography + colour
///        │    │    — or emptyValueText (<div>, '—') when value == null
///        │    └─ unitText (<span>)           // only when unit != null and value != null
///        ├─ changeRow (<div>)                // co_stat renders only when change != null
///        │    ├─ <span>(arrow glyph)
///        │    └─ <span>(change text)
///        └─ descriptionText (<div>)          // only when description != null
/// ```
///
/// The card box (background / border / radius / padding) is composed
/// via `OutlinedContainer` (`containerStyle`) rather than hand-drawn —
/// the same primitive `DescriptionCard` composes — so `co_stat` picks
/// up the active theme's surface marker, control-shadow-rest fallback,
/// and fill-var publish (and, on Flutter, the material lookup) for
/// free (`core/style-contract.md`'s child-component-composition rule).
/// [root] itself carries no chrome — only the structural classes
/// forwarded to `OutlinedContainer(classes: …)`.
///
/// All slot chromes are non-null — `co_stat` decides whether to render
/// the optional `unitText` / `changeRow` / `descriptionText` based on
/// whether `unit` / `change` + `changeType` / `description` are supplied,
/// and picks `emptyValueText` over `valueText` when `value` is `null`.
/// The per-state colour for the change row is pre-composed
/// into three [WebElementChrome] bundles ([changeRowPositive] /
/// [changeRowNegative] / [changeRowNeutral]) so the widget picks the
/// correct slot via a `switch` on the semantic enum prop — there is no
/// secondary resolver entry point.
///
/// No scalar metadata (variant / colour strings), no Component slots,
/// no logic meta — semantic identifiers stay on the widget prop, and
/// the change-row colour is baked into the pre-composed per-state
/// slots.
class ResolvedStat implements WebResolvedChrome {
  /// Creates a [ResolvedStat].
  const ResolvedStat({
    required this.root,
    required this.containerStyle,
    required this.content,
    required this.labelRow,
    required this.labelText,
    required this.valueRow,
    required this.valueText,
    required this.emptyValueText,
    required this.unitText,
    required this.changeRowPositive,
    required this.changeRowNegative,
    required this.changeRowNeutral,
    required this.descriptionText,
  });

  /// Structural chrome for the outer card element — `w-full` only.
  /// Forwarded as `OutlinedContainer(classes: …)` so it merges with
  /// that primitive's own chrome classes on the same root (#4362 — no
  /// chrome lives here, only layout).
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the composed
  /// `OutlinedContainer` root (#4362) — raw-forwarded straight to
  /// `OutlinedContainer(containerStyle: …)`; that widget's own resolver
  /// owns border / radius / background / material emit (no className /
  /// inlineStyles assembly here).
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready chrome for the content wrapper `<div>` inside the
  /// composed `OutlinedContainer` — `space-y-{gap}` only, no chrome.
  final WebElementChrome content;

  /// Paint-ready chrome for the label-row wrapper `<div>` — `flex
  /// items-center justify-between` className, no inline CSS.
  final WebElementChrome labelRow;

  /// Paint-ready chrome for the label `<span>` — typography role +
  /// colour token classes (`emitTypography` / `emitColor`); raw colour /
  /// typography overlays go to the inline CSS bundle.
  final WebElementChrome labelText;

  /// Paint-ready chrome for the value-row wrapper `<div>` — a flex row
  /// that aligns the value and its unit on their baseline, with the
  /// value-unit gap between them. No chrome.
  final WebElementChrome valueRow;

  /// Paint-ready chrome for the value `<div>` — typography role + colour
  /// token classes; raw overlays go inline.
  final WebElementChrome valueText;

  /// Paint-ready chrome for the empty-value placeholder `<div>` — the
  /// value's typography role + the empty-value colour. Rendered in place
  /// of [valueText] when the value is `null`.
  final WebElementChrome emptyValueText;

  /// Paint-ready chrome for the unit `<span>` — typography role (its
  /// weight overlay inline) + unit colour.
  final WebElementChrome unitText;

  /// Paint-ready chrome for the change-row `<div>` when
  /// `changeType == positive` — flex layout / gap / change typography
  /// role + the positive colour token class (raw colour goes inline).
  final WebElementChrome changeRowPositive;

  /// Paint-ready chrome for the change-row `<div>` when
  /// `changeType == negative` — flex layout / gap / change typography
  /// role + the negative colour token class.
  final WebElementChrome changeRowNegative;

  /// Paint-ready chrome for the change-row `<div>` when
  /// `changeType == neutral` — flex layout / gap / change typography
  /// role + the neutral colour token class.
  final WebElementChrome changeRowNeutral;

  /// Paint-ready chrome for the description `<div>` — typography role +
  /// description colour.
  final WebElementChrome descriptionText;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStat] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.stat.style
///   → theme.coreComponentTheme.stat.variantStyles[variant]
///   → widget.statStyle
/// ```
ResolvedStat resolveStat(
  BuildContext context, {
  required CoreStatVariant variant,
  CoreComponentSize size = CoreComponentSize.md,
  CoreStatStyle? statStyle,
}) {
  final statTheme = context.theme.coreComponentTheme?.stat;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreStatStyle(), [
    statTheme?.style,
    statTheme?.variantStyles?[variant],
    statStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreStatStyle.defaultsByVariant[variant]!;
  final sizeStyle = resolveSizeRow(CoreStatStyle.defaultsBySize, size);

  // The card box (background / border / radius / padding) is composed
  // via `OutlinedContainer` rather than assembled here — the same
  // primitive `DescriptionCard` composes for its own box
  // (`core/style-contract.md`'s child-component-composition rule).
  // Passing Core values (not emitted CSS) is what keeps the box a
  // single-source surface: `OutlinedContainer`'s own resolver owns the
  // class-vs-inline decision, the surface marker, the control-shadow
  // fallback, and the material lookup.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: merged.backgroundColor ?? variantStyle.backgroundColor,
    borderColor: merged.borderColor ?? variantStyle.borderColor,
    borderRadius: merged.borderRadius ?? CoreStatStyle.defaultBorderRadius,
    borderWidth: merged.borderWidth ?? variantStyle.borderWidth,
    padding: merged.padding ?? sizeStyle.padding!,
  );

  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and extract `size` for the Tailwind class
  // keys. Single source of truth for the suffix lives in
  // `CoreSpaceValue.tailwindSpace` ('space${toInt()}').
  final contentGapStyleResolved = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  final changeIconGapStyleResolved = CoreStatStyle.defaultChangeIconGapStyle
      .merge(merged.changeIconGapStyle);
  final valueUnitGapStyleResolved = CoreStatStyle.defaultValueUnitGapStyle
      .merge(merged.valueUnitGapStyle);
  final contentGapTailwind = contentGapStyleResolved.size!.tailwindSpace;
  final changeIconGapTailwind = changeIconGapStyleResolved.size!.tailwindSpace;
  final valueUnitGapTailwind = valueUnitGapStyleResolved.size!.tailwindSpace;

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound
  // values (variant defaults AND token overrides) emit Tailwind classes
  // so they stay dark-mode reactive; raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` branches.
  final labelColorEmit = emitColor(
    merged.labelColor,
    CoreStatStyle.defaultLabelColor,
    .text,
  );
  final valueColorEmit = emitColor(
    merged.valueColor,
    CoreStatStyle.defaultValueColor,
    .text,
  );
  final emptyValueColorEmit = emitColor(
    merged.emptyValueColor,
    CoreStatStyle.defaultEmptyValueColor,
    .text,
  );
  final unitColorEmit = emitColor(
    merged.unitColor,
    CoreStatStyle.defaultUnitColor,
    .text,
  );
  final positiveColorEmit = emitColor(
    merged.positiveColor,
    CoreStatStyle.defaultPositiveColor,
    .text,
  );
  final negativeColorEmit = emitColor(
    merged.negativeColor,
    CoreStatStyle.defaultNegativeColor,
    .text,
  );
  final neutralColorEmit = emitColor(
    merged.neutralColor,
    CoreStatStyle.defaultNeutralColor,
    .text,
  );
  final descriptionColorEmit = emitColor(
    merged.descriptionColor,
    CoreStatStyle.defaultDescriptionColor,
    .text,
  );

  // Typography roles — `emitTypography` emits a `text-{role}` class for
  // the token-backed default role (`label-large` / `headline-large` /
  // `title-medium` / `label-medium`) plus any explicit scalar overlay
  // inline (the unit's 500 weight over its role). The single canonical
  // path — no hand-rolled `text-${...token!.name}` identity reverse-lookup.
  final labelTypographyEmit = emitTypography(
    merged.labelTextStyle,
    sizeStyle.labelTextStyle!,
  );
  final valueTypographyEmit = emitTypography(
    merged.valueTextStyle,
    sizeStyle.valueTextStyle!,
  );
  final unitTypographyEmit = emitTypography(
    merged.unitTextStyle,
    sizeStyle.unitTextStyle!,
  );
  final changeTypographyEmit = emitTypography(
    merged.changeTextStyle,
    sizeStyle.changeTextStyle!,
  );
  final descriptionTypographyEmit = emitTypography(
    merged.descriptionTextStyle,
    sizeStyle.descriptionTextStyle!,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every emit result above — no named-arg explosion.
  // Local to the resolver, inaccessible from outside.

  /// Joins non-empty Tailwind class fragments into one className string.
  String joinClasses(List<String> parts) =>
      parts.where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the structural classes forwarded to
  /// `OutlinedContainer(classes: …)` — full width only; the box itself
  /// (background / border / radius / padding) is that primitive's own
  /// chrome, not assembled here.
  String buildRootClassName() => WebLayout.wFull;

  /// Composes the content wrapper `<div>` Tailwind className — vertical
  /// spacing between the label row / value row / change row /
  /// description. Lives one level inside the composed `OutlinedContainer`,
  /// which accepts a single `child:`.
  String buildContentClassName() => 'space-y-$contentGapTailwind';

  /// Composes the label-row wrapper `<div>` Tailwind className — flex
  /// row with `items-center justify-between` so the label stretches
  /// left and the optional icon sits right.
  String buildLabelRowClassName() => WebLayout.flexBetween;

  /// Composes the label `<span>` Tailwind className — typography role +
  /// colour token class (raw colour / typography overlay go inline).
  String buildLabelTextClassName() =>
      joinClasses([labelTypographyEmit.className, labelColorEmit.className]);

  /// Composes the label `<span>` inline-CSS bundle — raw colour /
  /// typography overlay fragments only (token values stay on classes).
  Styles? buildLabelTextInlineStyles() {
    final raw = {...?labelColorEmit.inline, ...?labelTypographyEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the value-row wrapper `<div>` Tailwind className — a flex
  /// row aligning the value and its unit on their baseline, with the
  /// value-unit gap.
  String buildValueRowClassName() => joinClasses([
    WebLayout.flex,
    WebLayout.itemsBaseline,
    'gap-$valueUnitGapTailwind',
  ]);

  /// The figure's place in the value row, the Flutter `Flexible` twin: it
  /// may shrink below its content and break inside a long figure, so the
  /// figure wraps inside the card instead of overflowing it.
  const figureLayout = '${WebLayout.minWZero} ${WebLayout.breakWords}';

  /// Joins a text element's typography role class and colour token
  /// class (raw colour / typography overlay go inline instead).
  String textClasses(Emit typographyEmit, Emit colorEmit) =>
      joinClasses([typographyEmit.className, colorEmit.className]);

  /// Collects a text element's inline-CSS bundle — raw colour /
  /// typography overlay fragments only (token values stay on classes).
  Styles? textInlineStyles(Emit typographyEmit, Emit colorEmit) {
    final raw = {...?colorEmit.inline, ...?typographyEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the value `<div>` Tailwind className — typography role +
  /// colour token class.
  String buildValueTextClassName() => joinClasses([
    figureLayout,
    textClasses(valueTypographyEmit, valueColorEmit),
  ]);

  /// Composes the value `<div>` inline-CSS bundle — raw overlay only.
  Styles? buildValueTextInlineStyles() =>
      textInlineStyles(valueTypographyEmit, valueColorEmit);

  /// Composes the empty-value `<div>` Tailwind className — the value's
  /// typography role + the empty-value colour token class.
  String buildEmptyValueTextClassName() => joinClasses([
    figureLayout,
    textClasses(valueTypographyEmit, emptyValueColorEmit),
  ]);

  /// Composes the empty-value `<div>` inline-CSS bundle — raw overlay
  /// only.
  Styles? buildEmptyValueTextInlineStyles() =>
      textInlineStyles(valueTypographyEmit, emptyValueColorEmit);

  /// Composes the unit `<span>` Tailwind className — typography role +
  /// unit colour token class, held at its own width (the Flutter unit is
  /// not flexible either). The role's weight overlay rides inline.
  String buildUnitTextClassName() => joinClasses([
    WebLayout.shrinkZero,
    textClasses(unitTypographyEmit, unitColorEmit),
  ]);

  /// Composes the unit `<span>` inline-CSS bundle — the 500 weight over
  /// the role, plus any raw overlay.
  Styles? buildUnitTextInlineStyles() =>
      textInlineStyles(unitTypographyEmit, unitColorEmit);

  /// Composes the description `<div>` Tailwind className — typography
  /// role + description colour token class.
  String buildDescriptionTextClassName() =>
      textClasses(descriptionTypographyEmit, descriptionColorEmit);

  /// Composes the description `<div>` inline-CSS bundle — raw overlay
  /// only.
  Styles? buildDescriptionTextInlineStyles() =>
      textInlineStyles(descriptionTypographyEmit, descriptionColorEmit);

  /// Composes the change-row `<div>` Tailwind className for [colorEmit]
  /// (per-change-type) — flex row with icon-text gap, the change
  /// typography role, and the change colour token class.
  String buildChangeRowClassName(Emit colorEmit) => joinClasses([
    '${WebLayout.flex} ${WebLayout.itemsCenter} gap-$changeIconGapTailwind',
    changeTypographyEmit.className,
    colorEmit.className,
  ]);

  /// Composes a per-state change-row inline-CSS bundle — raw colour /
  /// typography overlay fragments only.
  Styles? buildChangeRowInlineStyles(Emit colorEmit) {
    final raw = {...?colorEmit.inline, ...?changeTypographyEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedStat(
    root: WebElementChrome(className: buildRootClassName()),
    containerStyle: containerStyle,
    content: WebElementChrome(className: buildContentClassName()),
    labelRow: WebElementChrome(className: buildLabelRowClassName()),
    labelText: WebElementChrome(
      className: buildLabelTextClassName(),
      inlineStyles: buildLabelTextInlineStyles(),
    ),
    valueRow: WebElementChrome(className: buildValueRowClassName()),
    valueText: WebElementChrome(
      className: buildValueTextClassName(),
      inlineStyles: buildValueTextInlineStyles(),
    ),
    emptyValueText: WebElementChrome(
      className: buildEmptyValueTextClassName(),
      inlineStyles: buildEmptyValueTextInlineStyles(),
    ),
    unitText: WebElementChrome(
      className: buildUnitTextClassName(),
      inlineStyles: buildUnitTextInlineStyles(),
    ),
    changeRowPositive: WebElementChrome(
      className: buildChangeRowClassName(positiveColorEmit),
      inlineStyles: buildChangeRowInlineStyles(positiveColorEmit),
    ),
    changeRowNegative: WebElementChrome(
      className: buildChangeRowClassName(negativeColorEmit),
      inlineStyles: buildChangeRowInlineStyles(negativeColorEmit),
    ),
    changeRowNeutral: WebElementChrome(
      className: buildChangeRowClassName(neutralColorEmit),
      inlineStyles: buildChangeRowInlineStyles(neutralColorEmit),
    ),
    descriptionText: WebElementChrome(
      className: buildDescriptionTextClassName(),
      inlineStyles: buildDescriptionTextInlineStyles(),
    ),
  );
}
