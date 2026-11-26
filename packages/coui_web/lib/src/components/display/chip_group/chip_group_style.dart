import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ChipGroup`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // flex column, full-width container
///   ├─ header (<div>)                       // flex column — renders only when title || hint
///   │    ├─ title (<div>)                   // co_chip_group renders only when title != null
///   │    ├─ Gap(titleHintGapStyle)          // co_chip_group renders only when title != null && hint != null
///   │    └─ hint (<div>)                    // co_chip_group renders only when hint != null
///   ├─ Gap(titleGapStyle)                 // co_chip_group renders only when header present
///   └─ chips container — one of:
///        ├─ wrap (<div>)                    // wrap layout — flex-wrap row+column gap layout
///        └─ FadeScroll(fadeScrollStyle)   // scroll layout — wraps the inner row
///             └─ scrollInner (<div>)        // flex row no-wrap with native column-gap
///                  ├─ chip
///                  ├─ chip
///                  └─ …
/// ```
///
/// `co_chip_group.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [titleHintGapStyle] and [titleGapStyle] are forwarded to
///   `Gap(gapStyle: …)`;
///   [fadeScrollStyle] is forwarded to `FadeScroll(fadeScrollStyle: …)`.
///
/// Inter-chip spacing flows through native `column-gap` baked into the
/// inline styles of [ResolvedChipGroup.wrap] and
/// [ResolvedChipGroup.scrollInner] — no `Gap` indirection (parity with
/// Flutter `Wrap.spacing` / `Row.spacing`).
class ResolvedChipGroup implements WebResolvedChrome {
  /// Creates a [ResolvedChipGroup].
  const ResolvedChipGroup({
    required this.root,
    required this.header,
    required this.title,
    required this.hint,
    required this.wrap,
    required this.scrollInner,
    required this.titleHintGapStyle,
    required this.titleGapStyle,
    required this.fadeScrollStyle,
  });

  /// Paint-ready chrome for the outer wrapper `<div>` — `inline-flex
  /// flex-col max-w-full min-w-0`. Flutter `Column` is `mainAxisSize.min`
  /// and bounded by its parent's max width.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the header `<div>` — `flex flex-col
  /// items-start`: the title stacked over the selection hint (Flutter
  /// `Column(crossAxisAlignment: start)`). Reused regardless of which
  /// individual slot is populated.
  /// Always non-null — `co_chip_group` skips this element when both
  /// `title` and `selectionHint` are null.
  final WebElementChrome header;

  /// Paint-ready chrome for the title text wrapper `<div>` — typography
  /// + colour className plus optional [CoreTextStyle] override inline
  /// CSS. Always non-null — `co_chip_group` skips this element when
  /// `title` is null.
  final WebElementChrome title;

  /// Paint-ready chrome for the selection-hint text wrapper `<div>` —
  /// typography + colour className plus optional [CoreTextStyle]
  /// override inline CSS. Always non-null — `co_chip_group` skips this
  /// element when `selectionHint` is null.
  final WebElementChrome hint;

  /// Paint-ready chrome for the wrap-layout chips container `<div>` —
  /// `flex flex-wrap` className plus runtime `column-gap` / `row-gap`
  /// inline CSS. Always non-null — `co_chip_group` renders this only in
  /// `CoreChipGroupLayout.wrap` mode.
  final WebElementChrome wrap;

  /// Paint-ready chrome for the scroll-layout inner row `<div>` —
  /// `flex flex-row flex-nowrap w-max` className plus runtime `column-gap`
  /// inline CSS. Always non-null — `co_chip_group` renders this only
  /// in `CoreChipGroupLayout.scroll` mode (wrapped inside `FadeScroll`).
  final WebElementChrome scrollInner;

  /// Nested [CoreGapStyle] for the title → hint spacer inside the header —
  /// forwarded to `Gap(gapStyle: …)`. `co_chip_group` renders the gap only
  /// when both the title and the hint are present.
  final CoreGapStyle titleHintGapStyle;

  /// Nested [CoreGapStyle] for the header → chips spacer — forwarded to
  /// `Gap(gapStyle: …)`. `co_chip_group` renders the gap only when
  /// the header is present.
  final CoreGapStyle titleGapStyle;

  /// Nested [CoreFadeScrollStyle] for the scroll-layout outer wrapper
  /// — forwarded to `FadeScroll(fadeScrollStyle: …)`. Carries the
  /// resolved edge fade offsets and gradient (or zero offsets +
  /// `null` gradient when `showFade` is false).
  final CoreFadeScrollStyle fadeScrollStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChipGroup] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.chipGroup.style
///   → widget.chipGroupStyle
/// ```
///
/// The semantic enums (`layout` / `selectionMode`) and the behaviour
/// flag (`showFade`) are widget props — they stay on the widget. The
/// resolver folds them into chrome (e.g. `showFade=false` zeroes the
/// fade offsets on [ResolvedChipGroup.fadeScrollStyle]) but never
/// re-exposes them as scalar fields.
ResolvedChipGroup resolveChipGroup(
  BuildContext context, {
  required bool showFade,
  CoreChipGroupStyle? chipGroupStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.chipGroup;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreChipGroupStyle(), [
    coreTheme?.style,
    chipGroupStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final titleHintGapStyle = CoreChipGroupStyle.defaultTitleHintGapStyle.merge(
    merged.titleHintGapStyle,
  );
  final titleGapStyle = CoreChipGroupStyle.defaultTitleGapStyle.merge(
    merged.titleGapStyle,
  );
  final itemSpacing =
      merged.itemSpacing ?? CoreChipGroupStyle.defaultItemSpacing;
  final rowSpacing = merged.rowSpacing ?? CoreChipGroupStyle.defaultRowSpacing;
  final fadeWidth = merged.fadeWidth ?? CoreChipGroupStyle.defaultFadeWidth;
  final fadeColor = merged.fadeColor;

  // Title / hint text style — `emitTypography` is the single canonical
  // path: it composes `default.merge(override)`, emits the role on a
  // `text-{role}` class (+ token colour class — dark-mode / scale
  // reactive) and any explicit scalar / raw-colour overlay inline. No
  // hand-rolled `text-${...token!.name}` + `scheme.resolve` (no-op on
  // Web) assembly.
  final titleEmit = emitTypography(
    merged.titleTextStyle,
    CoreChipGroupStyle.defaultTitleTextStyle,
  );
  final hintEmit = emitTypography(
    merged.selectionHintTextStyle,
    CoreChipGroupStyle.defaultSelectionHintTextStyle,
  );

  // Nested CoreFadeScrollStyle slot — forwarded to
  // `FadeScroll(fadeScrollStyle: …)`. `showFade=false` zeroes the
  // edge ramp and drops the gradient so no fade renders.
  final effectiveFadeOffset = showFade ? fadeWidth : 0.0;
  final effectiveGradient = (showFade && fadeColor != null)
      ? [fadeColor, CoreColor.transparent]
      : null;
  final fadeScrollStyle = CoreFadeScrollStyle(
    startOffset: effectiveFadeOffset,
    endOffset: effectiveFadeOffset,
    gradient: effectiveGradient,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer wrapper `<div>` Tailwind className — inline-flex
  /// column (hug, matching Flutter `Column(mainAxisSize: min)`), clamped
  /// to the available width.
  ///
  /// The clamp is what lets the scroll layout scroll. A shrink-to-fit box
  /// is `min(max-content, max(min-content, available))`, and the scroll
  /// viewport's `w-full` is a cyclic percentage that counts as `auto` for
  /// intrinsic sizing — so the chip row's full width becomes the root's
  /// `min-content`. Without `max-w-full min-w-0` the root grows to the whole
  /// row, the viewport is as wide as its content and nothing can scroll.
  /// Flutter's `Column` gets the same clamp from its parent's max-width
  /// constraint. The wrap layout already breaks at the available width, so
  /// the clamp changes nothing there.
  String buildRootClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.flexCol} '
      '${WebLayout.maxWFull} ${WebLayout.minWZero}';

  /// Composes the header `<div>` Tailwind className — flex column
  /// stacking the title over the hint, start-aligned.
  String buildHeaderClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStart}';

  /// Composes the wrap-layout chips container `<div>` className.
  String buildWrapClassName() => '${WebLayout.flex} ${WebLayout.flexWrap}';

  /// Composes the scroll-layout inner row `<div>` className.
  ///
  /// `w-max` sizes the row to its chips instead of to the scroll viewport —
  /// Flutter's scrolling `Row` lays out against unbounded width, so chips
  /// keep their natural width. Clamped to the viewport, a chip whose label
  /// is wider than the group would be ellipsized (its `max-w-full`) where
  /// Flutter lets it scroll.
  String buildScrollInnerClassName() =>
      '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.flexNowrap} '
      '${WebLayout.wMax}';

  /// Composes the wrap-layout chips container inline-CSS bundle —
  /// runtime `column-gap` / `row-gap` overrides emitted through
  /// `spaceCss` — rem lengths, so the gap scales with the user's root
  /// font-size (accessibility parity with Flutter `theme.scaling`).
  Styles buildWrapInlineStyles() => .new(
    raw: {
      'column-gap': spaceCss(itemSpacing),
      'row-gap': spaceCss(rowSpacing),
    },
  );

  /// Composes the scroll-layout inner row inline-CSS bundle — runtime
  /// `column-gap` for inter-chip spacing (native CSS flex gap, parity
  /// with Flutter `Row.spacing`).
  Styles buildScrollInnerInlineStyles() => .new(
    raw: {
      'column-gap': spaceCss(itemSpacing),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  // Wrap each emit-family inline map (or null) into a paint-ready
  // `Styles?` here so the return literal stays a bare mapping.
  final titleInline = titleEmit.inline;
  final hintInline = hintEmit.inline;
  final titleInlineStyles = titleInline == null
      ? null
      : Styles(raw: titleInline);
  final hintInlineStyles = hintInline == null ? null : Styles(raw: hintInline);
  return ResolvedChipGroup(
    root: WebElementChrome(className: buildRootClassName()),
    header: WebElementChrome(className: buildHeaderClassName()),
    title: WebElementChrome(
      className: titleEmit.className,
      inlineStyles: titleInlineStyles,
    ),
    hint: WebElementChrome(
      className: hintEmit.className,
      inlineStyles: hintInlineStyles,
    ),
    wrap: WebElementChrome(
      className: buildWrapClassName(),
      inlineStyles: buildWrapInlineStyles(),
    ),
    scrollInner: WebElementChrome(
      className: buildScrollInnerClassName(),
      inlineStyles: buildScrollInnerInlineStyles(),
    ),
    titleHintGapStyle: titleHintGapStyle,
    titleGapStyle: titleGapStyle,
    fadeScrollStyle: fadeScrollStyle,
  );
}
