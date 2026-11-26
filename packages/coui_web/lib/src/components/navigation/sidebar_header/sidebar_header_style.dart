import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules paint — the overlay inside a header.
const String _kSidebarHeaderWashMarker = 'co-sidebar-header-wash';

/// Paint-ready chrome for Web `SidebarHeader`.
///
/// DOM shape:
///
/// ```text
/// root (<div> — the composed Clickable's box when pressable)
///   ├─ wash (<div>)          // * pressable only — :hover / :focus-visible / :active
///   ├─ leading               // caller-supplied Component, optional
///   ├─ text (<div>)
///   │    ├─ title (<div>)
///   │    └─ subtitle (<div>) // * when the caller gives one
///   └─ trailing (<div>)      // * when the caller gives one
/// ```
class ResolvedSidebarHeader implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarHeader].
  const ResolvedSidebarHeader({
    required this.root,
    required this.wash,
    required this.text,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingIconStyle,
    required this.clickableStyle,
  });

  /// The row box — insets, spacing, face, line and corner.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside a pressable header.
  final WebElementChrome wash;

  /// The column holding the title and the subtitle.
  final WebElementChrome text;

  /// The name's text.
  final WebElementChrome title;

  /// The second line's text.
  final WebElementChrome subtitle;

  /// The switch glyph's seat — its ink.
  final WebElementChrome trailing;

  /// The switch glyph's chrome.
  final CoreIconStyle trailingIconStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in a pressable `SidebarHeader`.
class ResolvedSidebarHeaderRules {
  /// Creates a [ResolvedSidebarHeaderRules].
  const ResolvedSidebarHeaderRules({required this.css});

  /// The rule text — empty when the header is not pressable.
  final String css;
}

CoreSidebarHeaderStyle _merged(
  BuildContext context,
  CoreSidebarHeaderVariant variant,
  CoreSidebarHeaderStyle? sidebarHeaderStyle,
) {
  final headerTheme = context.theme.coreComponentTheme?.sidebarHeader;
  return resolveStyleChain(const CoreSidebarHeaderStyle(), [
    headerTheme?.style,
    headerTheme?.variantStyles?[variant],
    sidebarHeaderStyle,
  ]);
}

/// Resolves [ResolvedSidebarHeader] for the given [context].
///
/// ```text
/// CoreSidebarHeaderStyle.defaultX → defaultsByVariant[variant]
///   → CoreSidebarHeaderTheme.style
///   → CoreSidebarHeaderTheme.variantStyles[variant]
///   → sidebarHeaderStyle
/// ```
ResolvedSidebarHeader resolveSidebarHeader(
  BuildContext context, {
  required CoreSidebarHeaderVariant variant,
  CoreSidebarHeaderStyle? sidebarHeaderStyle,
}) {
  final merged = _merged(context, variant, sidebarHeaderStyle);
  final variantStyle = CoreSidebarHeaderStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final padding = merged.padding ?? CoreSidebarHeaderStyle.defaultPadding;
  final contentSpacing =
      merged.contentSpacing ?? CoreSidebarHeaderStyle.defaultContentSpacing;
  final borderRadius =
      merged.borderRadius ?? CoreSidebarHeaderStyle.defaultBorderRadius;
  final backgroundColor =
      merged.backgroundColor ?? variantStyle.backgroundColor!;
  final borderColor = merged.borderColor ?? variantStyle.borderColor;
  final borderWidth =
      merged.borderWidth ?? CoreSidebarHeaderStyle.defaultBorderWidth;
  final titleStyle = CoreSidebarHeaderStyle.defaultTitleStyle.merge(
    merged.titleStyle,
  );
  final subtitleStyle = CoreSidebarHeaderStyle.defaultSubtitleStyle.merge(
    merged.subtitleStyle,
  );
  final trailingIconStyle = CoreSidebarHeaderStyle.defaultTrailingIconStyle
      .merge(merged.trailingIconStyle);
  final clickableStyle = CoreSidebarHeaderStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final fillEmit = emitColor(
    backgroundColor,
    backgroundColor,
    ColorTarget.background,
  );
  final borderEmit = emitColorOrInherit(borderColor, ColorTarget.border);
  final radiusEmit = emitRadius(borderRadius, borderRadius);
  final titleEmit = emitTypography(titleStyle, titleStyle);
  final subtitleEmit = emitTypography(subtitleStyle, subtitleStyle);
  final trailingEmit = emitColor(
    trailingIconStyle.color,
    trailingIconStyle.color!,
    ColorTarget.text,
  );

  return ResolvedSidebarHeader(
    root: WebElementChrome(
      className:
          'relative flex w-full items-center text-start '
          '${fillEmit.className} ${borderEmit.className} '
          '${radiusEmit.className}',
      inlineStyles: Styles(
        raw: {
          'padding': padding.toValue(),
          'gap': spaceCss(contentSpacing),
          // Only where a line colour resolved — the Flutter twin draws no
          // line without one.
          if (borderColor != null) 'border-width': strokeWidthCss(borderWidth),
          if (borderColor != null) 'border-style': 'solid',
          ...?fillEmit.inline,
          ...?borderEmit.inline,
          ...?radiusEmit.inline,
        },
      ),
    ),
    wash: WebElementChrome(
      className:
          '$_kSidebarHeaderWashMarker pointer-events-none absolute inset-0',
      inlineStyles: Styles(raw: {...?radiusEmit.inline}),
    ),
    text: const WebElementChrome(
      className: 'flex min-w-0 flex-1 flex-col items-start',
    ),
    title: WebElementChrome(
      className: 'w-full truncate ${titleEmit.className}',
      inlineStyles: titleEmit.inline == null
          ? null
          : Styles(raw: titleEmit.inline),
    ),
    subtitle: WebElementChrome(
      className: 'w-full truncate ${subtitleEmit.className}',
      inlineStyles: subtitleEmit.inline == null
          ? null
          : Styles(raw: subtitleEmit.inline),
    ),
    trailing: WebElementChrome(
      className: 'flex shrink-0 items-center ${trailingEmit.className}',
      inlineStyles: trailingEmit.inline == null
          ? null
          : Styles(raw: trailingEmit.inline),
    ),
    trailingIconStyle: trailingIconStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the pressable header carrying [scopeClass].
ResolvedSidebarHeaderRules resolveSidebarHeaderRules(
  BuildContext context, {
  required String scopeClass,
  required CoreSidebarHeaderVariant variant,
  required bool pressable,
  CoreSidebarHeaderStyle? sidebarHeaderStyle,
}) {
  if (!pressable) return const ResolvedSidebarHeaderRules(css: '');
  final merged = _merged(context, variant, sidebarHeaderStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarHeaderStyle.defaultStateLayer;
  final ink =
      merged.stateLayerColor ?? CoreSidebarHeaderStyle.defaultStateLayerColor;
  final root = '.$scopeClass';
  const wash = '.$_kSidebarHeaderWashMarker';
  final buffer = StringBuffer()
    ..write('$root:hover > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.hover).toValue())
    ..write(';}')
    ..write('$root:focus-visible > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.focus).toValue())
    ..write(';}')
    ..write('$root:active > $wash{background-color:')
    ..write(ink.scaleAlpha(stateLayer.pressed).toValue())
    ..write(';}');
  return ResolvedSidebarHeaderRules(css: buffer.toString());
}
