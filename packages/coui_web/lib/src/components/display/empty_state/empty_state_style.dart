import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `EmptyState`.
///
/// DOM shape (redesign — chromeless content stack, no composed
/// `OutlinedContainer` any more):
///
/// ```text
/// root (<div>)
///   ├─ iconWrapper (<div>)                  // co_empty_state renders only when icon shown
///   ├─ Gap(iconTitleGapStyle)                // co_empty_state renders only when icon shown
///   ├─ textBlock (<div>)                     // width-capped title + description stack
///   │    ├─ title (<div>)
///   │    ├─ Gap(titleDescriptionGapStyle)    // co_empty_state renders only when description shown
///   │    └─ description (<div>)              // co_empty_state renders only when description shown
///   ├─ Gap(descriptionActionGapStyle)        // co_empty_state renders only when action != null
///   └─ action (caller-supplied Component)    // co_empty_state renders only when action != null
/// ```
///
/// All paint-ready slot chromes are non-null — `co_empty_state` decides
/// whether to render each optional slot based on instance state.
class ResolvedEmptyState implements WebResolvedChrome {
  /// Creates a [ResolvedEmptyState].
  const ResolvedEmptyState({
    required this.root,
    required this.iconBox,
    required this.iconWrapper,
    required this.iconTitleGapStyle,
    required this.textBlock,
    required this.title,
    required this.titleDescriptionGapStyle,
    required this.description,
    required this.descriptionActionGapStyle,
  });

  /// Structural chrome for the outer element — centred flex-column
  /// className, plus padding + min-height (class when the design-system
  /// default applies, inline when a caller override supplies an
  /// arbitrary value — the single class-XOR-inline emit rule,
  /// `web/web-specifics.md`).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the circular icon box `<div>` — fixed size,
  /// fill colour, corner radius, flex centring. Hosts [iconWrapper].
  final WebElementChrome iconBox;

  /// Paint-ready chrome for the icon wrapper `<div>` — flex centring
  /// className + colour, plus size inline CSS (icon logical-px sizes
  /// have no `w-`/`h-` Tailwind scale, so size always rides inline —
  /// `core/design-tokens.md`'s "size 토큰 함정"). `co_empty_state`
  /// skips this element entirely when the icon is hidden.
  final WebElementChrome iconWrapper;

  /// Nested [CoreGapStyle] for the icon → title spacer — forwarded
  /// straight to `Gap(gapStyle: …)` by `co_empty_state`. The widget
  /// renders the gap only when the icon is shown.
  final CoreGapStyle iconTitleGapStyle;

  /// Paint-ready chrome for the title + description wrapper `<div>` —
  /// the only element the redesign caps at a max width
  /// (`CoreLayout.layout400`); the stack itself fills its host.
  final WebElementChrome textBlock;

  /// Paint-ready chrome for the title text `<div>`.
  final WebElementChrome title;

  /// Nested [CoreGapStyle] for the title → description spacer —
  /// forwarded straight to `Gap(gapStyle: …)` by `co_empty_state`.
  /// The widget renders the gap only when the description is shown.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Paint-ready chrome for the description `<div>` —
  /// `co_empty_state` skips this element when the description is
  /// hidden.
  final WebElementChrome description;

  /// Nested [CoreGapStyle] for the description → action spacer —
  /// forwarded straight to `Gap(gapStyle: …)` by `co_empty_state`.
  /// The widget renders the gap only when `action != null`.
  final CoreGapStyle descriptionActionGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedEmptyState] for the given [context].
///
/// Walks the merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.emptyState.style
///   → theme.coreComponentTheme.emptyState.variantStyles[variant]
///   → widget.emptyStateStyle
/// ```
///
/// The semantic [variant] is a widget prop — it threads through to
/// pick the variant token table here and the title typography token.
/// The theme cannot override it.
ResolvedEmptyState resolveEmptyState(
  BuildContext context, {
  required CoreEmptyStateVariant variant,
  CoreEmptyStateTone tone = .defaultTone,
  CoreEmptyStateStyle? emptyStateStyle,
}) {
  final esTheme = context.theme.coreComponentTheme?.emptyState;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreEmptyStateStyle(), [
    esTheme?.style,
    esTheme?.variantStyles?[variant],
    emptyStateStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantChrome = CoreEmptyStateStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome values ───────────────────────────
  final iconSize = merged.iconStyle?.size ?? variantChrome.iconSize;
  final iconBoxSize = merged.iconBoxSize ?? variantChrome.iconBoxSize;
  // Nested [CoreGapStyle] slots forwarded straight to `Gap`. The variant
  // default carries the gap, the per-instance override is merged on top,
  // and the merged slot is forwarded raw — `Gap` resolves its own
  // dimensions.
  final iconTitleGapStyle = variantChrome.iconTitleGapStyle.merge(
    merged.iconTitleGapStyle,
  );
  final titleDescriptionGapStyle = variantChrome.titleDescriptionGapStyle.merge(
    merged.titleDescriptionGapStyle,
  );
  final descriptionActionGapStyle = variantChrome.descriptionActionGapStyle
      .merge(merged.descriptionActionGapStyle);

  // Padding / min-height / max-text-width — class-XOR-inline via the
  // shared emit family ([emitSpacing]) or the same rule spelled out by
  // hand for the two `CoreLayout` bounds (no shared `emitLayout` helper
  // yet; `CoreLayout.scale` classes ARE wired to the `minHeight` /
  // `maxWidth` Tailwind theme keys — `theme_config.dart`).
  final paddingEmit = emitSpacing(
    merged.padding,
    variantChrome.padding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  // The floor is the variant's own: `normal` holds the 240 scale step (a
  // class), `compact` has none, and a caller's value is always inline.
  final minHeightOverride = merged.minHeight;
  final minHeight = minHeightOverride ?? variantChrome.minHeight;
  final minHeightIsScaleStep =
      minHeightOverride == null && minHeight == CoreLayout.layout240;
  final maxTextWidthOverride = merged.maxTextWidth;

  // The icon colour resolves through the same tone table Flutter reads.
  // It is total: both members state their icon colour outright (`neutral`
  // restates `defaultIconColor`, `failure` the `error` token), so the
  // per-instance slot is the only thing that can be absent here.
  final toneChrome = CoreEmptyStateStyle.defaultsByTone[tone]!;
  final iconColorEmit = emitColor(
    merged.iconStyle?.color,
    toneChrome.iconStyle!.color!,
    .text,
  );

  final iconBoxColorEmit = emitColor(
    merged.iconBoxColor,
    toneChrome.iconBoxColor!,
    .background,
  );
  final iconBoxRadiusEmit = emitRadius(
    merged.iconBoxBorderRadius,
    CoreEmptyStateStyle.defaultIconBoxBorderRadius,
  );

  // The variant's role (`defaultsByVariant[variant].titleTextStyle`) merged
  // onto the default title style — the same composition Flutter reads. It
  // states no weight, so the `text-{role}` class carries the role's own and
  // only a caller's weight arrives inline.
  final titleBase = CoreEmptyStateStyle.defaultTitleTextStyle.merge(
    variantChrome.titleTextStyle,
  );
  final titleEmit = emitTypography(merged.titleTextStyle, titleBase);
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreEmptyStateStyle.defaultDescriptionTextStyle.merge(
      variantChrome.descriptionTextStyle,
    ),
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer element's className — centred flex column,
  /// layout + padding class (when default) + min-height class (when the
  /// variant's floor is the 240 scale step).
  String buildRootClassName() => [
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    paddingEmit.className,
    if (minHeightIsScaleStep) 'min-h-${CoreLayout.scale.layout240}',
  ].where((c) => c.isNotEmpty).join(' ');

  Styles? buildRootInlineStyles() {
    final raw = {...?paddingEmit.inline};
    if (!minHeightIsScaleStep && minHeight > 0) {
      raw['min-height'] = '${minHeight / kRemDivisor}rem';
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  String buildIconBoxClassName() => [
    WebLayout.flexCenter,
    iconBoxColorEmit.className,
    iconBoxRadiusEmit.className,
  ].where((c) => c.isNotEmpty).join(' ');

  Styles buildIconBoxInlineStyles() => Styles(
    raw: {
      'width': '${iconBoxSize / kRemDivisor}rem',
      'height': '${iconBoxSize / kRemDivisor}rem',
      ...?iconBoxColorEmit.inline,
      ...?iconBoxRadiusEmit.inline,
    },
  );

  /// Composes the icon wrapper `<div>` className — flex centring +
  /// colour class (when token-bound).
  String buildIconWrapperClassName() =>
      '${WebLayout.flexCenter} ${iconColorEmit.className}'.trim();

  /// Composes the icon wrapper `<div>` inline CSS — size always inline
  /// (no `w-`/`h-` Tailwind scale for arbitrary icon px), colour inline
  /// only when the override is a raw (non-token) colour.
  Styles buildIconWrapperInlineStyles() => Styles(
    raw: {
      'width': '${iconSize / kRemDivisor}rem',
      'height': '${iconSize / kRemDivisor}rem',
      ...?iconColorEmit.inline,
    },
  );

  /// Composes the title + description wrapper `<div>` className — flex
  /// column + max-width class (when default).
  String buildTextBlockClassName() => [
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.itemsCenter,
    if (maxTextWidthOverride == null) 'max-w-${CoreLayout.scale.layout400}',
  ].join(' ');

  Styles? buildTextBlockInlineStyles() {
    if (maxTextWidthOverride == null) return null;
    final rem = maxTextWidthOverride / kRemDivisor;
    return Styles(raw: {'max-width': '${rem}rem'});
  }

  /// Composes the title `<div>` className — typography role + colour
  /// class (via [emitTypography]) plus `text-center`.
  String buildTitleClassName() => '${titleEmit.className} text-center'.trim();

  Styles? buildTitleInlineStyles() {
    final inline = titleEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the description `<div>` className — typography role +
  /// colour class plus `text-center`.
  String buildDescriptionClassName() =>
      '${descriptionEmit.className} text-center'.trim();

  Styles? buildDescriptionInlineStyles() {
    final inline = descriptionEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedEmptyState(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    iconBox: WebElementChrome(
      className: buildIconBoxClassName(),
      inlineStyles: buildIconBoxInlineStyles(),
    ),
    iconWrapper: WebElementChrome(
      className: buildIconWrapperClassName(),
      inlineStyles: buildIconWrapperInlineStyles(),
    ),
    iconTitleGapStyle: iconTitleGapStyle,
    textBlock: WebElementChrome(
      className: buildTextBlockClassName(),
      inlineStyles: buildTextBlockInlineStyles(),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    descriptionActionGapStyle: descriptionActionGapStyle,
  );
}
