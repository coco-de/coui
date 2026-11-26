/// Style resolver for Web `Command`.
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

/// Paint-ready chrome for Web `Command`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="combobox">)                 // panel: fill / border / radius / cast / width bounds
///   ├─ header (<div>)                          // search row
///   │    ├─ Button(plain) > Icon               // back — fullscreen with onDismiss only
///   │    ├─ Icon                               // search glyph (otherwise)
///   │    ├─ Gap(searchGapStyle)
///   │    ├─ searchInput (<div> > TextField)     // chromeless, size ← Command.size
///   │    └─ Gap + Kbd esc                       // dialog with onDismiss only
///   ├─ scope (<div>)                           // Chip × n — only when scopes is non-empty
///   ├─ Divider
///   ├─ list (<div role="listbox">)             // listMinHeight / listMaxHeight / listPadding / listSpacing
///   │    ├─ Divider                            // between groups, hidden while a query filters
///   │    ├─ heading (<div>)
///   │    └─ item (<div role="option">)         // itemEnabled · itemActive · itemDisabled
///   │         ├─ itemWash (<div>)              // absolute overlay — :hover / :active wash (scoped rules)
///   │         ├─ leading + Gap(itemGapStyle)   // optional — itemIconStyle / itemActiveIconStyle / itemDisabledIconStyle
///   │         ├─ text (<div>)                  // overline + title, or label
///   │         └─ Gap + shortcut (<span>)       // optional
///   ├─ empty                                   // composed EmptyState (emptyStateStyle)
///   ├─ Divider                                 // footer only
///   └─ footer (<div>)                          // Kbd + footerLabel × n
/// ```
///
/// `command.dart` reads each slot's `className` + `inlineStyles` straight
/// from `resolved.<slot>` — no merge / fallback / conversion in the widget
/// body. Row state is a select between [itemEnabled], [itemActive] and
/// [itemDisabled]; the hover / pressed washes are pseudo-state and live in
/// [ResolvedCommandRules] as scoped CSS, because a token colour with an
/// opacity has no Tailwind class.
class ResolvedCommand implements WebResolvedChrome {
  /// Creates the paint-ready bundle.
  const ResolvedCommand({
    required this.root,
    required this.header,
    required this.searchInput,
    required this.scope,
    required this.list,
    required this.heading,
    required this.empty,
    required this.itemEnabled,
    required this.itemActive,
    required this.itemDisabled,
    required this.itemWash,
    required this.text,
    required this.label,
    required this.overline,
    required this.title,
    required this.shortcut,
    required this.footer,
    required this.footerLabel,
    required this.kbdStyle,
    required this.footerKbdIconStyle,
    required this.searchIconStyle,
    required this.backIconStyle,
    required this.searchGapStyle,
    required this.itemGapStyle,
    required this.itemIconStyle,
    required this.itemActiveIconStyle,
    required this.itemDisabledIconStyle,
    required this.itemClickableStyle,
    required this.scopeChipStyle,
    required this.searchFieldStyle,
    required this.emptyStateStyle,
  });

  @override
  final WebElementChrome root;

  /// Search row.
  final WebElementChrome header;

  /// Search-field wrapper.
  final WebElementChrome searchInput;

  /// Scope chip row.
  final WebElementChrome scope;

  /// Scrolling list.
  final WebElementChrome list;

  /// Group heading.
  final WebElementChrome heading;

  /// Wrapper around the composed `EmptyState`.
  final WebElementChrome empty;

  /// Resting row.
  final WebElementChrome itemEnabled;

  /// Active row — the keyboard cursor: the fill and nothing else.
  final WebElementChrome itemActive;

  /// Disabled row — disabled foreground, no fill, no pointer.
  final WebElementChrome itemDisabled;

  /// Absolute overlay inside every enabled row; the scoped rules paint the
  /// hover / pressed wash on it so the wash stacks over the active fill.
  final WebElementChrome itemWash;

  /// Text column (`flex-1 min-w-0`).
  final WebElementChrome text;

  /// One-line label.
  final WebElementChrome label;

  /// Two-line overline.
  final WebElementChrome overline;

  /// Two-line title.
  final WebElementChrome title;

  /// Shortcut hint.
  final WebElementChrome shortcut;

  /// Footer row.
  final WebElementChrome footer;

  /// Footer hint text.
  final WebElementChrome footerLabel;

  /// Nested `Kbd` slot for the footer key caps — raw-forwarded.
  final CoreKbdStyle kbdStyle;

  /// Footer key-cap glyph — raw-forwarded to `Icon`.
  final CoreIconStyle footerKbdIconStyle;

  /// Search glyph — raw-forwarded to `Icon`.
  final CoreIconStyle searchIconStyle;

  /// Fullscreen back glyph — raw-forwarded to `Icon`.
  final CoreIconStyle backIconStyle;

  /// Search glyph ↔ field gap — raw-forwarded to `Gap`.
  final CoreGapStyle searchGapStyle;

  /// Row icon ↔ label ↔ shortcut gap — raw-forwarded to `Gap`.
  final CoreGapStyle itemGapStyle;

  /// Resting row glyph — ambient-forwarded to a caller-supplied icon.
  final CoreIconStyle itemIconStyle;

  /// Active row glyph — ambient-forwarded to a caller-supplied icon.
  final CoreIconStyle itemActiveIconStyle;

  /// Disabled row glyph — ambient-forwarded to a caller-supplied icon.
  final CoreIconStyle itemDisabledIconStyle;

  /// Nested `Clickable` slot for each row — raw-forwarded.
  final CoreClickableStyle itemClickableStyle;

  /// Nested `Chip` slot for the scope chips — raw-forwarded.
  final CoreChipStyle scopeChipStyle;

  /// Embedded search field chrome.
  final CoreTextFieldStyle searchFieldStyle;

  /// Nested `EmptyState` slot — raw-forwarded.
  final CoreEmptyStateStyle emptyStateStyle;
}

/// Scoped CSS text for the `<style>` block in `Command`. Carries the two
/// pseudo-state washes — `:hover` and `:active` on a row paint the row's
/// wash overlay — because a token colour at an opacity (`on-surface` at
/// 3% / 12%) has no preset Tailwind class and a class would drop the
/// opacity.
class ResolvedCommandRules {
  /// Creates the rule bundle.
  const ResolvedCommandRules({required this.css});

  /// Rule text; empty when nothing needs a rule.
  final String css;
}

/// Class marker the scoped wash rules target on a row.
const String kCommandRowMarker = 'co-command-row';

/// Class marker the scoped wash rules paint — the overlay inside a row.
const String kCommandWashMarker = 'co-command-wash';

// ═══════════════════════════════════════════════════
// resolveCommand — single entry point
// ═══════════════════════════════════════════════════

/// Resolves the paint-ready [ResolvedCommand] for the given [context].
///
/// Every field falls through `merged.X ?? presentation.X ?? size.X ??
/// defaultX` — the same chain the Flutter twin walks. Web EMIT is
/// theme-free: token names go out as classes or `var(--coui-*)` and the
/// browser resolves them.
ResolvedCommand resolveCommand(
  BuildContext context, {
  CoreCommandVariant variant = .defaultVariant,
  CoreCommandPresentation presentation = .defaultPresentation,
  CoreCommandSize size = .defaultSize,
  CoreCommandStyle? commandStyle,
}) {
  final commandTheme = context.theme.coreComponentTheme?.command;

  final merged = resolveStyleChain(const CoreCommandStyle(), [
    commandTheme?.style,
    commandTheme?.variantStyles?[variant],
    commandStyle,
  ]);
  final ps = CoreCommandStyle.defaultsByPresentation[presentation]!;
  final ss = CoreCommandStyle.defaultsBySize[size]!;

  // ── Stage1 RESOLVE ──
  final backgroundColor =
      merged.backgroundColor ?? CoreCommandStyle.defaultBackgroundColor;
  final borderColor =
      merged.borderColor ??
      ps.borderColor ??
      CoreCommandStyle.defaultBorderColor;
  final borderRadius =
      (merged.borderRadius ??
              ps.borderRadius ??
              CoreCommandStyle.defaultBorderRadius)
          .toValue();
  final borderWidth =
      merged.borderWidth ??
      ps.borderWidth ??
      CoreCommandStyle.defaultBorderWidth;
  final panelShadow =
      merged.panelShadow ??
      ps.panelShadow ??
      CoreCommandStyle.defaultPanelShadow;
  final panelMinWidth =
      merged.panelMinWidth ??
      ps.panelMinWidth ??
      CoreCommandStyle.defaultPanelMinWidth;
  final panelMaxWidth =
      merged.panelMaxWidth ??
      ps.panelMaxWidth ??
      CoreCommandStyle.defaultPanelMaxWidth;

  final searchPadding =
      (merged.searchPadding ??
              ss.searchPadding ??
              CoreCommandStyle.defaultSearchPadding)
          .toValue();
  // The search input and the item rows are rows of the control ladder:
  // their size-row heights go out as the row variable, so a density moves
  // them. A caller's own height stays as stated, as on Flutter.
  final searchInputHeight = merged.searchInputHeight == null
      ? controlHeightCss(
          ss.searchInputHeight ?? CoreCommandStyle.defaultSearchInputHeight,
        )
      : '${merged.searchInputHeight! / kRemDivisor}rem';

  final scopePadding =
      (merged.scopePadding ??
              ss.scopePadding ??
              CoreCommandStyle.defaultScopePadding)
          .toValue();
  final scopeSpacing =
      merged.scopeSpacing ?? CoreCommandStyle.defaultScopeSpacing;

  final listPadding =
      (merged.listPadding ??
              ps.listPadding ??
              CoreCommandStyle.defaultListPadding)
          .toValue();
  final listSpacing = merged.listSpacing ?? CoreCommandStyle.defaultListSpacing;
  final listMinHeight =
      merged.listMinHeight ??
      ps.listMinHeight ??
      CoreCommandStyle.defaultListMinHeight;
  final listMaxHeight =
      merged.listMaxHeight ??
      ps.listMaxHeight ??
      CoreCommandStyle.defaultListMaxHeight;
  final headingPadding =
      (merged.headingPadding ??
              ss.headingPadding ??
              CoreCommandStyle.defaultHeadingPadding)
          .toLogicalDeclarations('padding');

  final itemPadding =
      (merged.itemPadding ??
              ss.itemPadding ??
              CoreCommandStyle.defaultItemPadding)
          .toValue();
  final itemMinHeight = merged.itemMinHeight == null
      ? controlHeightCss(
          ss.itemMinHeight ?? CoreCommandStyle.defaultItemMinHeight,
        )
      : '${merged.itemMinHeight! / kRemDivisor}rem';
  final itemBorderRadius =
      (merged.itemBorderRadius ?? CoreCommandStyle.defaultItemBorderRadius)
          .toValue();
  final itemTextStyleSlot = CoreCommandStyle.defaultItemTextStyle.merge(
    merged.itemTextStyle,
  );
  final highlightDuration =
      (merged.highlightDuration ?? CoreCommandStyle.defaultHighlightDuration)
          .inMilliseconds;

  final footerPadding =
      (merged.footerPadding ??
              ss.footerPadding ??
              CoreCommandStyle.defaultFooterPadding)
          .toValue();
  final footerSpacing =
      merged.footerSpacing ?? CoreCommandStyle.defaultFooterSpacing;
  final emptyPadding =
      (merged.emptyPadding ?? CoreCommandStyle.defaultEmptyPadding).toValue();

  // ── Stage2 EMIT — typography (role class + explicit overlay inline) ──
  final headingEmit = emitTypography(
    merged.headingStyle,
    CoreCommandStyle.defaultHeadingStyle,
  );
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreCommandStyle.defaultLabelStyle.merge(ss.labelStyle),
  );
  final overlineEmit = emitTypography(
    merged.overlineStyle,
    CoreCommandStyle.defaultOverlineStyle.merge(ss.overlineStyle),
  );
  final titleEmit = emitTypography(
    merged.itemTitleStyle,
    CoreCommandStyle.defaultItemTitleStyle.merge(ss.itemTitleStyle),
  );
  final shortcutEmit = emitTypography(
    merged.shortcutStyle,
    CoreCommandStyle.defaultShortcutStyle,
  );
  final footerEmit = emitTypography(
    merged.footerStyle,
    CoreCommandStyle.defaultFooterStyle,
  );

  // ── Stage2 EMIT — colours (class XOR inline) ──
  final dividerEmit = emitColor(
    merged.borderColor,
    ps.borderColor ?? CoreCommandStyle.defaultBorderColor,
    .border,
  );
  final backgroundEmit = emitColor(
    backgroundColor,
    CoreCommandStyle.defaultBackgroundColor,
    .background,
  );
  final footerBackgroundEmit = emitColor(
    merged.footerBackgroundColor,
    CoreCommandStyle.defaultFooterBackgroundColor,
    .background,
  );
  final activeFillEmit = emitColor(
    merged.itemHighlightColor,
    CoreCommandStyle.defaultItemHighlightColor,
    .background,
  );
  final foregroundEmit = emitColor(
    merged.itemForegroundColor,
    itemTextStyleSlot.color ?? CoreCommandStyle.defaultItemForegroundColor,
    .text,
  );
  // Disabled rows paint the `disabled-content` token as is — an alpha over
  // the resting colour is not a token and the contrast guards cannot read it.
  final disabledForegroundEmit = emitColor(
    merged.itemDisabledForegroundColor,
    CoreCommandStyle.defaultItemDisabledForegroundColor,
    .text,
  );
  // Web EMIT is theme-free — the cast rides `rgb(var(--coui-shadow))` and
  // the browser resolves it; `none` when the shape states no cast.
  final panelShadowCss = emitShadow(panelShadow, base: kShadowVariableBase);

  // ── Nested slots — raw-forwarded ──
  final searchIconStyle = CoreCommandStyle.defaultSearchIconStyle
      .merge(ss.searchIconStyle)
      .merge(merged.searchIconStyle)
      .merge(
        CoreIconStyle(
          color:
              merged.placeholderColor ??
              CoreCommandStyle.defaultPlaceholderColor,
        ),
      );
  final backIconStyle = CoreCommandStyle.defaultBackIconStyle
      .merge(ss.backIconStyle)
      .merge(merged.backIconStyle);
  final searchGapStyle = CoreCommandStyle.defaultSearchGapStyle
      .merge(ss.searchGapStyle)
      .merge(merged.searchGapStyle);
  final itemGapStyle = CoreCommandStyle.defaultItemGapStyle
      .merge(ss.itemGapStyle)
      .merge(merged.itemGapStyle);
  final itemIconStyle = CoreCommandStyle.defaultItemIconStyle
      .merge(ss.itemIconStyle)
      .merge(merged.itemIconStyle);
  final itemActiveIconStyle = itemIconStyle.merge(
    CoreCommandStyle.defaultItemActiveIconStyle.merge(
      merged.itemActiveIconStyle,
    ),
  );
  final itemDisabledIconStyle = itemIconStyle.merge(
    CoreIconStyle(
      color:
          merged.itemDisabledForegroundColor ??
          CoreCommandStyle.defaultItemDisabledForegroundColor,
    ),
  );
  final footerKbdIconStyle = CoreCommandStyle.defaultFooterKbdIconStyle.merge(
    merged.footerKbdIconStyle,
  );
  final kbdStyle = CoreCommandStyle.defaultKbdStyle.merge(merged.kbdStyle);
  final searchFieldStyle = CoreCommandStyle.defaultSearchFieldStyle.merge(
    merged.searchFieldStyle,
  );
  final scopeChipStyle = CoreCommandStyle.defaultScopeChipStyle.merge(
    merged.scopeChipStyle,
  );
  final emptyStateStyle = CoreCommandStyle.defaultEmptyStateStyle.merge(
    merged.emptyStateStyle,
  );
  final itemClickableStyle = CoreCommandStyle.defaultItemClickableStyle.merge(
    merged.itemClickableStyle,
  );

  // A bound on the `CoreLayout` scale becomes its Tailwind key; anything
  // else (an override off the scale) goes inline. Infinity is "no bound".
  String? layoutClass(String axis, double v) =>
      v.isFinite && CoreLayout.values.contains(v)
      ? '$axis-${v.tailwindLayout}'
      : null;
  String? layoutInline(double v) => v.isFinite && !CoreLayout.values.contains(v)
      ? '${v / kRemDivisor}rem'
      : null;

  String buildRootClassName() => <String>[
    // No injected-cast marker: the panel states its shadow per presentation
    // (`panelShadow`), and a shape that states none states it outright —
    // the Flutter twin hands that empty stack to its `OutlinedContainer`,
    // which leaves an explicitly empty stack empty. The inline `box-shadow`
    // below out-ranks the marker's class rule anyway, so it drew nothing.
    // A command palette is a full-front overlay: it opens over whatever
    // the user was reading and that page stays behind it. Paired with the
    // fill published below — the marker alone resolves a preset's restated
    // colour to nothing and the panel loses its background.
    ...webSurfaceMarkerFor(CoreSurfaceRole.content),
    WebLayout.flex,
    WebLayout.wFull,
    WebLayout.flexCol,
    WebLayout.overflowHidden,
    // The panel clips its content and keeps a border — a material that draws
    // its own edge reaches its band over that line (`kWebSurfaceClipMarker`).
    if (borderWidth > 0) kWebSurfaceClipMarker,
    if (!backgroundColor.isTransparent) 'bg-${backgroundColor.tailwindColor}',
    if (!borderColor.isTransparent && borderWidth > 0)
      'border border-${borderColor.tailwindColor}',
    ?layoutClass('min-w', panelMinWidth),
    ?layoutClass('max-w', panelMaxWidth),
  ].join(' ');

  Styles buildRootInlineStyles() => .new(
    raw: {
      'border-radius': borderRadius,
      'border-width': strokeWidthCss(borderWidth),
      if (borderWidth > 0) ...surfaceClipFold(strokeWidthCss(borderWidth)),
      // The rim rides beside the cast in one `box-shadow` list — a rim
      // decorates a panel that casts, and the dialog presentation does. An
      // inline or fullscreen palette states no cast, so it takes no rim:
      // the Flutter twin's `OutlinedContainer` keys the rim on the same
      // stack, and naming it anyway lit those two on this platform alone.
      'box-shadow': panelShadow.isNotEmpty
          ? '$panelShadowCss, $kSurfaceRimVar'
          : 'none',
      'min-width': ?layoutInline(panelMinWidth),
      'max-width': ?layoutInline(panelMaxWidth),
      if (borderWidth > 0) ...?dividerEmit.inline,
      if (!backgroundColor.paintsNothing) ...?backgroundEmit.inline,
      ...surfaceFillVar(backgroundColor),
    },
  );

  String buildHeaderClassName() => <String>[
    WebLayout.flexItemsCenter,
    dividerEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildHeaderInlineStyles() => .new(
    raw: {
      'height': searchInputHeight,
      'padding': searchPadding,
      ...?dividerEmit.inline,
    },
  );

  String buildSearchInputClassName() =>
      '${WebLayout.flexFull} ${WebLayout.itemsCenter}';

  String buildScopeClassName() =>
      '${WebLayout.flex} ${WebLayout.flexWrap} ${WebLayout.itemsCenter}';

  Styles buildScopeInlineStyles() => .new(
    raw: {
      'padding': scopePadding,
      'gap': spaceCss(scopeSpacing),
    },
  );

  String buildListClassName() => <String>[
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.overflowYAuto,
    WebLayout.overflowXHidden,
    ?layoutClass('min-h', listMinHeight),
    ?layoutClass('max-h', listMaxHeight),
  ].join(' ');

  Styles buildListInlineStyles() => .new(
    raw: {
      'padding': listPadding,
      'gap': spaceCss(listSpacing),
      'min-height': ?layoutInline(listMinHeight),
      'max-height': ?layoutInline(listMaxHeight),
    },
  );

  String buildHeadingClassName() => headingEmit.className;

  Styles buildHeadingInlineStyles() => .new(
    raw: {...headingPadding, ...?headingEmit.inline},
  );

  String buildEmptyClassName() => <String>[
    WebLayout.flexCenter,
    ?layoutClass('min-h', listMinHeight),
  ].join(' ');

  Styles buildEmptyInlineStyles() => .new(raw: {'padding': emptyPadding});

  String buildItemClassName({
    required bool enabled,
    required bool active,
  }) => <String>[
    kCommandRowMarker,
    WebLayout.relative,
    WebLayout.flex,
    WebLayout.wFull,
    'select-none',
    WebLayout.itemsCenter,
    'transition-colors',
    if (!enabled) ...[
      disabledForegroundEmit.className,
      WebLayout.pointerEventsNone,
    ] else ...[
      foregroundEmit.className,
      if (active) activeFillEmit.className,
    ],
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildItemInlineStyles({required bool enabled, required bool active}) =>
      Styles(
        raw: {
          'border-radius': itemBorderRadius,
          'padding': itemPadding,
          'min-height': itemMinHeight,
          'transition-duration': '${highlightDuration}ms',
          if (!enabled)
            ...?disabledForegroundEmit.inline
          else
            ...?foregroundEmit.inline,
          if (enabled && active) ...?activeFillEmit.inline,
        },
      );

  String buildItemWashClassName() => <String>[
    kCommandWashMarker,
    WebLayout.absoluteFull,
    WebLayout.pointerEventsNone,
    'transition-colors',
  ].join(' ');

  Styles buildItemWashInlineStyles() => .new(
    raw: {
      'border-radius': itemBorderRadius,
      'transition-duration': '${highlightDuration}ms',
    },
  );

  String buildTextClassName() => <String>[
    WebLayout.minWZero,
    WebLayout.flex1,
    WebLayout.flex,
    WebLayout.flexCol,
  ].join(' ');

  String buildLabelClassName() => <String>[
    WebLayout.truncate,
    labelEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles? inlineOf(({String className, Map<String, String>? inline}) e) {
    final inline = e.inline;
    if (inline == null || inline.isEmpty) return null;
    return Styles(raw: inline);
  }

  String buildOverlineClassName() => <String>[
    WebLayout.truncate,
    overlineEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  String buildTitleClassName() => <String>[
    WebLayout.truncate,
    titleEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  String buildShortcutClassName() => <String>[
    'ml-auto',
    WebLayout.shrinkZero,
    shortcutEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  String buildFooterClassName() => <String>[
    WebLayout.flexItemsCenter,
    footerBackgroundEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildFooterInlineStyles() => .new(
    raw: {
      'padding': footerPadding,
      'gap': spaceCss(footerSpacing),
      ...?footerBackgroundEmit.inline,
    },
  );

  String buildFooterLabelClassName() => footerEmit.className;

  return ResolvedCommand(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    header: WebElementChrome(
      className: buildHeaderClassName(),
      inlineStyles: buildHeaderInlineStyles(),
    ),
    searchInput: WebElementChrome(className: buildSearchInputClassName()),
    scope: WebElementChrome(
      className: buildScopeClassName(),
      inlineStyles: buildScopeInlineStyles(),
    ),
    list: WebElementChrome(
      className: buildListClassName(),
      inlineStyles: buildListInlineStyles(),
    ),
    heading: WebElementChrome(
      className: buildHeadingClassName(),
      inlineStyles: buildHeadingInlineStyles(),
    ),
    empty: WebElementChrome(
      className: buildEmptyClassName(),
      inlineStyles: buildEmptyInlineStyles(),
    ),
    itemEnabled: WebElementChrome(
      className: buildItemClassName(enabled: true, active: false),
      inlineStyles: buildItemInlineStyles(enabled: true, active: false),
    ),
    itemActive: WebElementChrome(
      className: buildItemClassName(enabled: true, active: true),
      inlineStyles: buildItemInlineStyles(enabled: true, active: true),
    ),
    itemDisabled: WebElementChrome(
      className: buildItemClassName(enabled: false, active: false),
      inlineStyles: buildItemInlineStyles(enabled: false, active: false),
    ),
    itemWash: WebElementChrome(
      className: buildItemWashClassName(),
      inlineStyles: buildItemWashInlineStyles(),
    ),
    text: WebElementChrome(className: buildTextClassName()),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: inlineOf(labelEmit),
    ),
    overline: WebElementChrome(
      className: buildOverlineClassName(),
      inlineStyles: inlineOf(overlineEmit),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: inlineOf(titleEmit),
    ),
    shortcut: WebElementChrome(
      className: buildShortcutClassName(),
      inlineStyles: inlineOf(shortcutEmit),
    ),
    footer: WebElementChrome(
      className: buildFooterClassName(),
      inlineStyles: buildFooterInlineStyles(),
    ),
    footerLabel: WebElementChrome(
      className: buildFooterLabelClassName(),
      inlineStyles: inlineOf(footerEmit),
    ),
    kbdStyle: kbdStyle,
    footerKbdIconStyle: footerKbdIconStyle,
    searchIconStyle: searchIconStyle,
    backIconStyle: backIconStyle,
    searchGapStyle: searchGapStyle,
    itemGapStyle: itemGapStyle,
    itemIconStyle: itemIconStyle,
    itemActiveIconStyle: itemActiveIconStyle,
    itemDisabledIconStyle: itemDisabledIconStyle,
    itemClickableStyle: itemClickableStyle,
    scopeChipStyle: scopeChipStyle,
    searchFieldStyle: searchFieldStyle,
    emptyStateStyle: emptyStateStyle,
  );
}

/// Resolves the scoped pseudo-state rules for a palette rooted at
/// [scopeId] — `:hover` and `:active` on an enabled row paint the wash
/// overlay inside it. Walks the same merge chain as [resolveCommand] so a
/// theme or instance override of the wash colours lands here too.
ResolvedCommandRules resolveCommandRules(
  BuildContext context, {
  required String scopeId,
  CoreCommandVariant variant = .defaultVariant,
  CoreCommandStyle? commandStyle,
}) {
  final commandTheme = context.theme.coreComponentTheme?.command;
  final merged = resolveStyleChain(const CoreCommandStyle(), [
    commandTheme?.style,
    commandTheme?.variantStyles?[variant],
    commandStyle,
  ]);
  final hover = merged.itemHoverColor ?? CoreCommandStyle.defaultItemHoverColor;
  final pressed =
      merged.itemPressedColor ?? CoreCommandStyle.defaultItemPressedColor;

  final row = '#$scopeId .$kCommandRowMarker';
  final buffer = StringBuffer()
    ..write('$row:hover > .$kCommandWashMarker{background-color:')
    ..write(hover.toValue())
    ..write(';}')
    ..write('$row:active > .$kCommandWashMarker{background-color:')
    ..write(pressed.toValue())
    ..write(';}');
  return ResolvedCommandRules(css: buffer.toString());
}
