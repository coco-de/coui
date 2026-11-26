import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules paint — the overlay inside a row.
const String _kSidebarItemWashMarker = 'co-sidebar-item-wash';

/// Paint-ready chrome for Web `SidebarItem`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="button"> — the composed Clickable's box)
///   ├─ wash (<div>)          // absolute overlay — :hover / :focus-visible / :active
///   ├─ leading               // caller-supplied Component, optional
///   ├─ label (<div>)
///   ├─ dot (<span>)          // * when `dot`
///   ├─ count                 // caller-supplied Component, optional
///   └─ trailing (<div>)      // * when the caller gives one
/// ```
///
/// `sidebar_item.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>`. The glyphs take the root's ink
/// (`currentColor`); the trailing seat states its own.
class ResolvedSidebarItem implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarItem].
  const ResolvedSidebarItem({
    required this.root,
    required this.wash,
    required this.label,
    required this.dot,
    required this.trailing,
    required this.iconStyle,
    required this.trailingIconStyle,
    required this.clickableStyle,
  });

  /// The row box — layout, insets, corner, fill and the ink every glyph
  /// inherits.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside an enabled row; the scoped rules paint it.
  final WebElementChrome wash;

  /// Label typography.
  final WebElementChrome label;

  /// The unread dot.
  final WebElementChrome dot;

  /// The trailing glyph's seat.
  final WebElementChrome trailing;

  /// The leading glyph's chrome — its size reaches the glyph through the
  /// ambient `IconTheme`.
  final CoreIconStyle iconStyle;

  /// The trailing glyph's chrome.
  final CoreIconStyle trailingIconStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `SidebarItem`.
///
/// The wash is the state-layer ink at [CoreStateLayer] weight — a derived
/// colour no preset class names — so it rides scoped rules on an overlay.
class ResolvedSidebarItemRules {
  /// Creates a [ResolvedSidebarItemRules].
  const ResolvedSidebarItemRules({required this.css});

  /// The rule text — empty when the row is disabled.
  final String css;
}

/// The merged style for [level] — one chain both resolvers walk, so the
/// chrome and the wash cannot disagree.
CoreSidebarItemStyle _merged(
  BuildContext context,
  CoreSidebarItemLevel level,
  CoreSidebarItemStyle? sidebarItemStyle,
) {
  final itemTheme = context.theme.coreComponentTheme?.sidebarItem;
  return resolveStyleChain(const CoreSidebarItemStyle(), [
    itemTheme?.style,
    itemTheme?.variantStyles?[level],
    sidebarItemStyle,
  ]);
}

/// Resolves [ResolvedSidebarItem] for the given [context].
///
/// ```text
/// CoreSidebarItemStyle.defaultX → defaultsByLevel[level]
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → sidebarItemStyle
/// ```
///
/// [selected] and [enabled] are build-time semantic state (the Flutter
/// twin reads the same two); hover, focus and press stay with the browser.
ResolvedSidebarItem resolveSidebarItem(
  BuildContext context, {
  required CoreSidebarItemLevel level,
  bool selected = false,
  bool enabled = true,
  CoreSidebarItemStyle? sidebarItemStyle,
}) {
  final merged = _merged(context, level, sidebarItemStyle);
  final levelStyle = CoreSidebarItemStyle.defaultsByLevel[level]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final minHeight = merged.minHeight ?? levelStyle.minHeight!;
  final padding = merged.padding ?? CoreSidebarItemStyle.defaultPadding;
  final contentSpacing =
      merged.contentSpacing ?? CoreSidebarItemStyle.defaultContentSpacing;
  final borderRadius =
      merged.borderRadius ?? CoreSidebarItemStyle.defaultBorderRadius;
  final iconStyle = CoreSidebarItemStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final stateIconStyle = !enabled
      ? iconStyle
            .merge(CoreSidebarItemStyle.defaultDisabledIconStyle)
            .merge(merged.disabledIconStyle)
      : selected
      ? iconStyle
            .merge(CoreSidebarItemStyle.defaultSelectedIconStyle)
            .merge(merged.selectedIconStyle)
      : iconStyle;
  final restingTrailingIconStyle = CoreSidebarItemStyle.defaultTrailingIconStyle
      .merge(merged.trailingIconStyle);
  final trailingIconStyle = !enabled
      ? restingTrailingIconStyle
            .merge(CoreSidebarItemStyle.defaultDisabledTrailingIconStyle)
            .merge(merged.disabledTrailingIconStyle)
      : restingTrailingIconStyle;
  final restingLabel = levelStyle.labelStyle!
      .merge(CoreSidebarItemStyle.defaultLabelStyle)
      .merge(merged.labelStyle);
  final labelStyle = !enabled
      ? restingLabel
            .merge(CoreSidebarItemStyle.defaultDisabledLabelStyle)
            .merge(merged.disabledLabelStyle)
      : selected
      ? restingLabel
            .merge(CoreSidebarItemStyle.defaultSelectedLabelStyle)
            .merge(merged.selectedLabelStyle)
      : restingLabel;
  final fill = selected
      ? merged.selectedBackgroundColor ??
            CoreSidebarItemStyle.defaultSelectedBackgroundColor
      : merged.backgroundColor ?? CoreSidebarItemStyle.defaultBackgroundColor;
  final dotColor = merged.dotColor ?? CoreSidebarItemStyle.defaultDotColor;
  final dotSize = merged.dotSize ?? CoreSidebarItemStyle.defaultDotSize;
  final clickableStyle = CoreSidebarItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final fillEmit = emitColor(fill, fill, ColorTarget.background);
  // The glyphs take the row's ink through `currentColor`.
  final inkEmit = emitColor(
    stateIconStyle.color,
    stateIconStyle.color!,
    ColorTarget.text,
  );
  final radiusEmit = emitRadius(borderRadius, borderRadius);
  final labelEmit = emitTypography(labelStyle, labelStyle);
  final trailingEmit = emitColor(
    trailingIconStyle.color,
    trailingIconStyle.color!,
    ColorTarget.text,
  );
  final dotEmit = emitColor(dotColor, dotColor, ColorTarget.background);

  return ResolvedSidebarItem(
    root: WebElementChrome(
      className:
          'relative flex w-full items-center text-start select-none '
          '${fillEmit.className} ${radiusEmit.className} '
          '${inkEmit.className} $kWebTouchTargetMarker',
      inlineStyles: Styles(
        raw: {
          // The row's own height, not a control rung: density does not move
          // it on either platform.
          'min-height': pinnedLengthCss(minHeight),
          ...padding.toLogicalDeclarations('padding'),
          'gap': spaceCss(contentSpacing),
          ...?fillEmit.inline,
          ...?radiusEmit.inline,
          ...?inkEmit.inline,
        },
      ),
    ),
    wash: WebElementChrome(
      className:
          '$_kSidebarItemWashMarker pointer-events-none absolute inset-0',
      inlineStyles: Styles(raw: {...?radiusEmit.inline}),
    ),
    label: WebElementChrome(
      className: 'min-w-0 flex-1 truncate ${labelEmit.className}',
      inlineStyles: labelEmit.inline == null
          ? null
          : Styles(raw: labelEmit.inline),
    ),
    dot: WebElementChrome(
      className: 'shrink-0 rounded-full ${dotEmit.className}',
      inlineStyles: Styles(
        raw: {
          'width': pinnedLengthCss(dotSize),
          'height': pinnedLengthCss(dotSize),
          ...?dotEmit.inline,
        },
      ),
    ),
    trailing: WebElementChrome(
      className: 'flex shrink-0 items-center ${trailingEmit.className}',
      inlineStyles: trailingEmit.inline == null
          ? null
          : Styles(raw: trailingEmit.inline),
    ),
    iconStyle: stateIconStyle,
    trailingIconStyle: trailingIconStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the row carrying [scopeClass].
///
/// Walks the same chain as [resolveSidebarItem].
ResolvedSidebarItemRules resolveSidebarItemRules(
  BuildContext context, {
  required String scopeClass,
  required CoreSidebarItemLevel level,
  bool enabled = true,
  CoreSidebarItemStyle? sidebarItemStyle,
}) {
  if (!enabled) return const ResolvedSidebarItemRules(css: '');
  final merged = _merged(context, level, sidebarItemStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarItemStyle.defaultStateLayer;
  final ink =
      merged.stateLayerColor ?? CoreSidebarItemStyle.defaultStateLayerColor;
  final row = '.$scopeClass';
  const wash = '.$_kSidebarItemWashMarker';
  final buffer = StringBuffer()
    ..write('$row:hover > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.hover).toValue())
    ..write(';}')
    ..write('$row:focus-visible > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.focus).toValue())
    ..write(';}')
    ..write('$row:active > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.pressed).toValue())
    ..write(';}');
  return ResolvedSidebarItemRules(css: buffer.toString());
}
