import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules paint — the overlay inside a trigger.
const String _kSidebarSearchWashMarker = 'co-sidebar-search-wash';

/// Paint-ready chrome for Web `SidebarSearch`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="button"> — the composed Clickable's box)
///   ├─ wash (<div>)          // absolute overlay — :hover / :focus-visible / :active
///   ├─ Icon (iconStyle)
///   ├─ placeholder (<div>)
///   └─ Kbd (kbdStyle)        // * when a shortcut is given
/// ```
class ResolvedSidebarSearch implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarSearch].
  const ResolvedSidebarSearch({
    required this.root,
    required this.wash,
    required this.placeholder,
    required this.iconStyle,
    required this.kbdStyle,
    required this.clickableStyle,
  });

  /// The trigger box — height, insets, spacing, face, line and corner.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside an enabled trigger.
  final WebElementChrome wash;

  /// The placeholder's text.
  final WebElementChrome placeholder;

  /// The search glyph, raw-forwarded to the composed `Icon`.
  final CoreIconStyle iconStyle;

  /// The composed `Kbd`'s chrome, raw-forwarded.
  final CoreKbdStyle? kbdStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `SidebarSearch`.
class ResolvedSidebarSearchRules {
  /// Creates a [ResolvedSidebarSearchRules].
  const ResolvedSidebarSearchRules({required this.css});

  /// The rule text — empty when the trigger is disabled.
  final String css;
}

CoreSidebarSearchStyle _merged(
  BuildContext context,
  CoreSidebarSearchStyle? sidebarSearchStyle,
) => resolveStyleChain(const CoreSidebarSearchStyle(), [
  context.theme.coreComponentTheme?.sidebarSearch?.style,
  sidebarSearchStyle,
]);

/// Resolves [ResolvedSidebarSearch] for the given [context].
///
/// ```text
/// CoreSidebarSearchStyle.defaultX
///   → CoreSidebarSearchTheme.style
///   → sidebarSearchStyle
/// ```
ResolvedSidebarSearch resolveSidebarSearch(
  BuildContext context, {
  CoreSidebarSearchStyle? sidebarSearchStyle,
}) {
  final merged = _merged(context, sidebarSearchStyle);

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final minHeight = merged.minHeight ?? CoreSidebarSearchStyle.defaultMinHeight;
  final padding = merged.padding ?? CoreSidebarSearchStyle.defaultPadding;
  final contentSpacing =
      merged.contentSpacing ?? CoreSidebarSearchStyle.defaultContentSpacing;
  final borderRadius =
      merged.borderRadius ?? CoreSidebarSearchStyle.defaultBorderRadius;
  final borderWidth =
      merged.borderWidth ?? CoreSidebarSearchStyle.defaultBorderWidth;
  final iconStyle = CoreSidebarSearchStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final placeholderStyle = CoreSidebarSearchStyle.defaultPlaceholderStyle.merge(
    merged.placeholderStyle,
  );
  final clickableStyle = CoreSidebarSearchStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final fillEmit = emitColor(
    merged.backgroundColor,
    CoreSidebarSearchStyle.defaultBackgroundColor,
    ColorTarget.background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    CoreSidebarSearchStyle.defaultBorderColor,
    ColorTarget.border,
  );
  final radiusEmit = emitRadius(borderRadius, borderRadius);
  final placeholderEmit = emitTypography(placeholderStyle, placeholderStyle);

  return ResolvedSidebarSearch(
    root: WebElementChrome(
      className:
          'relative flex w-full items-center text-start select-none '
          '${fillEmit.className} ${borderEmit.className} '
          '${radiusEmit.className}',
      inlineStyles: Styles(
        raw: {
          'min-height': pinnedLengthCss(minHeight),
          ...padding.toLogicalDeclarations('padding'),
          'gap': spaceCss(contentSpacing),
          'border-width': strokeWidthCss(borderWidth),
          'border-style': 'solid',
          ...?fillEmit.inline,
          ...?borderEmit.inline,
          ...?radiusEmit.inline,
        },
      ),
    ),
    wash: WebElementChrome(
      className:
          '$_kSidebarSearchWashMarker pointer-events-none absolute inset-0',
      inlineStyles: Styles(raw: {...?radiusEmit.inline}),
    ),
    placeholder: WebElementChrome(
      className: 'min-w-0 flex-1 truncate ${placeholderEmit.className}',
      inlineStyles: placeholderEmit.inline == null
          ? null
          : Styles(raw: placeholderEmit.inline),
    ),
    iconStyle: iconStyle,
    kbdStyle: merged.kbdStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the trigger carrying [scopeClass].
ResolvedSidebarSearchRules resolveSidebarSearchRules(
  BuildContext context, {
  required String scopeClass,
  bool enabled = true,
  CoreSidebarSearchStyle? sidebarSearchStyle,
}) {
  if (!enabled) return const ResolvedSidebarSearchRules(css: '');
  final merged = _merged(context, sidebarSearchStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarSearchStyle.defaultStateLayer;
  final ink =
      merged.stateLayerColor ?? CoreSidebarSearchStyle.defaultStateLayerColor;
  final root = '.$scopeClass';
  const wash = '.$_kSidebarSearchWashMarker';
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
  return ResolvedSidebarSearchRules(css: buffer.toString());
}
