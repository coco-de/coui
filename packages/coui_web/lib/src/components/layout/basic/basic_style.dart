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

/// Paint-ready chrome for Web `Basic`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // outer flex-row container
///   ├─ leadingSlot (<div>)                  // co_basic renders only when leading != null
///   ├─ Gap (titleContentGapStyle)         // co_basic renders only when leading + body present
///   ├─ body (<div>)                         // title / subtitle / content stack
///   │    ├─ titleSlot (<div>)               // co_basic renders only when title != null
///   │    ├─ Gap (titleSubtitleGapStyle)   // co_basic renders only when title && subtitle
///   │    ├─ subtitleSlot (<div>)            // co_basic renders only when subtitle != null
///   │    ├─ Gap (leadingTitleGapStyle)    // co_basic renders only when (title||subtitle) && content
///   │    └─ contentSlot (<div>)             // co_basic renders only when content != null
///   ├─ Gap (titleContentGapStyle)         // co_basic renders only when body + trailing present
///   └─ trailingSlot (<div>)                 // co_basic renders only when trailing != null
/// ```
///
/// All slot chromes are non-null — `co_basic` decides whether to render
/// each optional element based on instance slot presence. Per-slot
/// chrome (alignment + optional typography / text style override) is
/// pre-composed by [resolveBasic]; the three gap slots are returned
/// as nested [CoreGapStyle] values that the widget forwards straight
/// to inner `Gap` children, so each `Gap` runs its own resolve
/// step (Epic #2228 4-principle).
class ResolvedBasic implements WebResolvedChrome {
  /// Creates a [ResolvedBasic].
  const ResolvedBasic({
    required this.root,
    required this.body,
    required this.leadingSlot,
    required this.trailingSlot,
    required this.titleSlot,
    required this.subtitleSlot,
    required this.contentSlot,
    required this.titleContentGapStyle,
    required this.leadingTitleGapStyle,
    required this.titleSubtitleGapStyle,
    required this.trailingCell,
    required this.trailingText,
    required this.trailingGapStyle,
    required this.trailingIconStyle,
  });

  /// Paint-ready chrome for the outer row `<div>` — `flex flex-row
  /// items-stretch justify-…` className driven by the resolved
  /// main-axis alignment plus the optional `padding` inline-CSS bundle
  /// when the merged style sets a non-zero `padding` slot.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the body column `<div>` — the
  /// `flex flex-col flex-1 min-w-0` stack that holds title / subtitle
  /// / content slots.
  final WebElementChrome body;

  /// Paint-ready chrome for the leading slot wrapper `<div>` — `flex`
  /// className plus `justify-content` / `align-items` inline-CSS
  /// derived from the leading slot's [CoreBasicAlignment].
  final WebElementChrome leadingSlot;

  /// Paint-ready chrome for the trailing slot wrapper `<div>` — `flex`
  /// className plus `justify-content` / `align-items` inline-CSS
  /// derived from the trailing slot's [CoreBasicAlignment].
  final WebElementChrome trailingSlot;

  /// Paint-ready chrome for the title slot wrapper `<div>` — `flex`
  /// className (with the merged `titleTextStyle` typography / colour /
  /// weight token classes appended when `forceTextStyle == true`) plus
  /// alignment + per-instance `titleTextStyle` override inline-CSS (the
  /// matching token class is suppressed when the override sets that
  /// field).
  final WebElementChrome titleSlot;

  /// Paint-ready chrome for the subtitle slot wrapper `<div>` — `flex`
  /// className (with the merged `subtitleTextStyle` typography / colour
  /// token classes appended when `forceTextStyle == true`) plus
  /// alignment + per-instance `subtitleTextStyle` override inline-CSS.
  final WebElementChrome subtitleSlot;

  /// Paint-ready chrome for the content slot wrapper `<div>` — `flex`
  /// className (with the merged `contentTextStyle` typography / colour
  /// token classes appended when `forceTextStyle == true`) plus
  /// alignment + per-instance `contentTextStyle` override inline-CSS.
  final WebElementChrome contentSlot;

  /// Nested [CoreGapStyle] slot for the horizontal gap between the
  /// outer row slots (leading↔body and body↔trailing) — forwarded
  /// straight to `Gap(gapStyle: …)`. The receiving `Gap` runs its
  /// own resolve step, so this slot is the merged design-system
  /// default + per-instance override in pre-scaling units.
  final CoreGapStyle titleContentGapStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the
  /// title+subtitle block and the content row inside the body column —
  /// forwarded straight to `Gap(gapStyle: …)`.
  final CoreGapStyle leadingTitleGapStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the title
  /// and subtitle rows inside the body column — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle titleSubtitleGapStyle;

  /// Paint-ready chrome for the trailing cell `<div>` that holds the
  /// trailing value text, its gap and the trailing icon in one row —
  /// `inline-flex items-center`.
  final WebElementChrome trailingCell;

  /// Paint-ready chrome for the trailing value text `<div>` — the
  /// `trailingTextStyle` role / colour / weight token classes when
  /// `forceTextStyle == true`.
  final WebElementChrome trailingText;

  /// Nested [CoreGapStyle] slot for the gap between the trailing value
  /// text and the trailing icon — forwarded straight to `Gap`.
  final CoreGapStyle trailingGapStyle;

  /// Nested [CoreIconStyle] slot for the built-in trailing chevron —
  /// forwarded straight to `Icon(iconStyle: …)`.
  final CoreIconStyle trailingIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedBasic] for the given [context].
///
/// Merge chain (per-field): `widget.basicStyle` > `CoreBasicTheme.style`
/// > design-system default (`CoreBasicStyle.defaultX`).
///
/// [forceTextStyle] controls whether the title / subtitle / content
/// slot wrappers apply CoUI's default typography classes (title =
/// labelXl/semiBold, subtitle = bodySmall muted, content = bodySmall).
/// The widget exposes the same flag on `Basic`. The default slot text
/// styles are folded into the nested `titleTextStyle` /
/// `subtitleTextStyle` / `contentTextStyle` slots and merged with the
/// per-instance override — the default typography / colour / weight
/// token classes are emitted unless the override sets that field, in
/// which case an inline rule wins (card resolver model).
ResolvedBasic resolveBasic(
  BuildContext context, {
  required bool forceTextStyle,
  CoreBasicStyle? basicStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.basic;

  final merged = resolveStyleChain(const CoreBasicStyle(), [
    coreTheme?.style,
    basicStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final resolvedPadding = merged.padding ?? CoreBasicStyle.defaultPadding;
  final mainAxisAlignment =
      merged.mainAxisAlignment ?? CoreBasicStyle.defaultMainAxisAlignment;
  final leadingAlignment =
      merged.leadingAlignment ?? CoreBasicStyle.defaultLeadingAlignment;
  final trailingAlignment =
      merged.trailingAlignment ?? CoreBasicStyle.defaultTrailingAlignment;
  final titleAlignment =
      merged.titleAlignment ?? CoreBasicStyle.defaultTitleAlignment;
  final subtitleAlignment =
      merged.subtitleAlignment ?? CoreBasicStyle.defaultSubtitleAlignment;
  final contentAlignment =
      merged.contentAlignment ?? CoreBasicStyle.defaultContentAlignment;
  // ─── Nested gap-style slots (pre-scaling — Gap self-scales) ──
  final titleContentGapStyle = CoreBasicStyle.defaultTitleContentGapStyle.merge(
    merged.titleContentGapStyle,
  );
  final leadingTitleGapStyle = CoreBasicStyle.defaultLeadingTitleGapStyle.merge(
    merged.leadingTitleGapStyle,
  );
  final titleSubtitleGapStyle = CoreBasicStyle.defaultTitleSubtitleGapStyle
      .merge(merged.titleSubtitleGapStyle);
  final trailingGapStyle = CoreBasicStyle.defaultTrailingGapStyle.merge(
    merged.trailingGapStyle,
  );
  final trailingIconStyle = CoreBasicStyle.defaultTrailingIconStyle.merge(
    merged.trailingIconStyle,
  );
  // Slot typography — routed through the canonical `emitTypography`
  // family (theme-free, single class-XOR-inline decision per slot). When
  // `forceTextStyle` is true the fallback default is the design-system
  // slot `CoreTextStyle` (role + colour + weight token), so the merged
  // slot emits a `text-{role}` class (+ token colour / weight classes)
  // with any per-instance scalar overlay inline. When `forceTextStyle`
  // is false there is no enforced role — the fallback default is the
  // empty style, so only an explicit per-instance override emits
  // (legacy `BasicLayout` parity: slots render with whatever the caller
  // passes). `emitTypography` itself decides class vs inline by token
  // identity, so no hand-rolled `text-${...token!.name}` / `scheme.resolve`.
  const emptyTextStyle = CoreTextStyle();
  final titleEmit = emitTypography(
    merged.titleTextStyle,
    forceTextStyle ? CoreBasicStyle.defaultTitleTextStyle : emptyTextStyle,
  );
  final subtitleEmit = emitTypography(
    merged.subtitleTextStyle,
    forceTextStyle ? CoreBasicStyle.defaultSubtitleTextStyle : emptyTextStyle,
  );
  final contentEmit = emitTypography(
    merged.contentTextStyle,
    forceTextStyle ? CoreBasicStyle.defaultContentTextStyle : emptyTextStyle,
  );

  final trailingEmit = emitTypography(
    merged.trailingTextStyle,
    forceTextStyle ? CoreBasicStyle.defaultTrailingTextStyle : emptyTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer row `<div>` Tailwind className —
  /// `inline-flex items-stretch` plus the `justify-…` token derived
  /// from the resolved main-axis alignment. Flutter `Row` is
  /// `mainAxisSize.min`; `flex` (block) would fill the capture width.
  String buildRootClassName() =>
      '${WebLayout.inlineFlexItemsStretch} '
      '${_mainAxisAlignmentToTailwind(mainAxisAlignment)}';

  /// Composes the outer row `<div>` inline CSS — the merged `padding`
  /// shorthand when the resolved padding is non-zero. Returns `null`
  /// when the resolved padding is `CoreEdgeInsets.zero` so the widget
  /// can skip the `styles` attribute entirely.
  Styles? buildRootInlineStyles() {
    if (resolvedPadding == .zero) return null;
    // Logical longhands for a padding that follows the reading direction
    // (`CardImage`'s text row), the one-line shorthand otherwise.
    return Styles(raw: resolvedPadding.toLogicalDeclarations('padding'));
  }

  /// Composes the body column `<div>` Tailwind className —
  /// `flex flex-col flex-1 min-w-0`.
  String buildBodyClassName() => [
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.flex1,
    WebLayout.minWZero,
  ].join(' ');

  /// Composes a leading / trailing slot wrapper `<div>` Tailwind
  /// className — `flex`.
  String buildOuterSlotClassName() => WebLayout.flex;

  /// Composes a leading / trailing slot wrapper `<div>` inline CSS —
  /// `justify-content` / `align-items` derived from the slot's
  /// alignment (mirrors Flutter's slot alignment behaviour).
  Styles buildOuterSlotInlineStyles(CoreBasicAlignment alignment) {
    final self = _alignmentToFlexSelf(alignment);
    return Styles(
      raw: {
        'justify-content': self.justify,
        'align-items': self.align,
      },
    );
  }

  /// Composes a body slot wrapper (`title` / `subtitle` / `content`)
  /// `<div>` Tailwind className — `flex` plus the slot's [emit] role /
  /// colour / weight token classes (inherited by the inner `Text`). The
  /// class-vs-inline split is owned by `emitTypography`, so token-bound
  /// values stay on classes (dark-mode reactive) and scalar overlays /
  /// raw colours move inline via [buildBodySlotInlineStyles].
  String buildBodySlotClassName(Emit emit) {
    final cls = emit.className;
    return cls.isEmpty ? WebLayout.flex : '${WebLayout.flex} $cls';
  }

  /// Composes a body slot wrapper `<div>` inline CSS — alignment plus the
  /// slot [emit]'s inline overlay (explicit `font-size` / weight /
  /// line-height / letter-spacing / font-family and any raw colour). The
  /// matching token class for an overridden field is suppressed inside
  /// `emitTypography` so this inline rule takes over.
  Styles buildBodySlotInlineStyles(CoreBasicAlignment alignment, Emit emit) {
    final self = _alignmentToFlexSelf(alignment);
    return Styles(
      raw: {
        'justify-content': self.justify,
        'align-items': self.align,
        ...?emit.inline,
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBasic(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    body: WebElementChrome(className: buildBodyClassName()),
    leadingSlot: WebElementChrome(
      className: buildOuterSlotClassName(),
      inlineStyles: buildOuterSlotInlineStyles(leadingAlignment),
    ),
    trailingSlot: WebElementChrome(
      className: buildOuterSlotClassName(),
      inlineStyles: buildOuterSlotInlineStyles(trailingAlignment),
    ),
    titleSlot: WebElementChrome(
      className: buildBodySlotClassName(titleEmit),
      inlineStyles: buildBodySlotInlineStyles(titleAlignment, titleEmit),
    ),
    subtitleSlot: WebElementChrome(
      className: buildBodySlotClassName(subtitleEmit),
      inlineStyles: buildBodySlotInlineStyles(subtitleAlignment, subtitleEmit),
    ),
    contentSlot: WebElementChrome(
      className: buildBodySlotClassName(contentEmit),
      inlineStyles: buildBodySlotInlineStyles(contentAlignment, contentEmit),
    ),
    titleContentGapStyle: titleContentGapStyle,
    leadingTitleGapStyle: leadingTitleGapStyle,
    titleSubtitleGapStyle: titleSubtitleGapStyle,
    trailingCell: const WebElementChrome(
      className: '${WebLayout.inlineFlex} ${WebLayout.itemsCenter}',
    ),
    trailingText: WebElementChrome(
      className: trailingEmit.className,
      inlineStyles: switch (trailingEmit.inline) {
        final inline? => Styles(raw: inline),
        null => null,
      },
    ),
    trailingGapStyle: trailingGapStyle,
    trailingIconStyle: trailingIconStyle,
  );
}

// ═══════════════════════════════════════════════════
// Internal helpers
// ═══════════════════════════════════════════════════

/// Converts a [CoreBasicAlignment] preset to a pair of CSS flex
/// alignment values: `(justify-self, align-self)`.
({String justify, String align}) _alignmentToFlexSelf(
  CoreBasicAlignment value,
) {
  switch (value) {
    case .topStart:
      return (justify: 'flex-start', align: 'flex-start');
    case .topCenter:
      return (justify: 'center', align: 'flex-start');
    case .topEnd:
      return (justify: 'flex-end', align: 'flex-start');
    case .centerStart:
      return (justify: 'flex-start', align: 'center');
    case .center:
      return (justify: 'center', align: 'center');
    case .centerEnd:
      return (justify: 'flex-end', align: 'center');
    case .bottomStart:
      return (justify: 'flex-start', align: 'flex-end');
    case .bottomCenter:
      return (justify: 'center', align: 'flex-end');
    case .bottomEnd:
      return (justify: 'flex-end', align: 'flex-end');
  }
}

/// Converts a [CoreBasicMainAxisAlignment] preset to a Tailwind
/// `justify-*` class fragment.
String _mainAxisAlignmentToTailwind(CoreBasicMainAxisAlignment value) {
  switch (value) {
    case .start:
      return WebLayout.justifyStart;
    case .end:
      return WebLayout.justifyEnd;
    case .center:
      return WebLayout.justifyCenter;
    case .spaceBetween:
      return WebLayout.justifyBetween;
    case .spaceAround:
      return WebLayout.justifyAround;
    case .spaceEvenly:
      return WebLayout.justifyEvenly;
  }
}
