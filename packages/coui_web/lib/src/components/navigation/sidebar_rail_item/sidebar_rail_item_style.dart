import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules paint — the overlay inside a square.
const String _kSidebarRailItemWashMarker = 'co-sidebar-rail-item-wash';

/// Paint-ready chrome for Web `SidebarRailItem`.
///
/// DOM shape:
///
/// ```text
/// Tooltip (label)
///   └─ root (<div role="button"> — the composed Clickable's box)
///        ├─ wash (<div>)        // absolute overlay — :hover / :focus-visible / :active
///        ├─ icon                // caller-supplied Component
///        └─ dot (<span>)        // * when `dot`, top-end corner
/// ```
class ResolvedSidebarRailItem implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarRailItem].
  const ResolvedSidebarRailItem({
    required this.root,
    required this.wash,
    required this.dot,
    required this.iconStyle,
    required this.clickableStyle,
  });

  /// The square — size, corner, fill and the glyph's ink.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside an enabled square; the scoped rules paint it.
  final WebElementChrome wash;

  /// The unread dot.
  final WebElementChrome dot;

  /// The glyph's chrome — its size reaches the glyph through the ambient
  /// `IconTheme`.
  final CoreIconStyle iconStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `SidebarRailItem`.
class ResolvedSidebarRailItemRules {
  /// Creates a [ResolvedSidebarRailItemRules].
  const ResolvedSidebarRailItemRules({required this.css});

  /// The rule text — empty when the destination is disabled.
  final String css;
}

CoreSidebarRailItemStyle _merged(
  BuildContext context,
  CoreSidebarRailItemStyle? sidebarRailItemStyle,
) => resolveStyleChain(const CoreSidebarRailItemStyle(), [
  context.theme.coreComponentTheme?.sidebarRailItem?.style,
  sidebarRailItemStyle,
]);

/// Resolves [ResolvedSidebarRailItem] for the given [context].
///
/// ```text
/// CoreSidebarRailItemStyle.defaultX
///   → CoreSidebarRailItemTheme.style
///   → sidebarRailItemStyle
/// ```
ResolvedSidebarRailItem resolveSidebarRailItem(
  BuildContext context, {
  bool selected = false,
  bool enabled = true,
  CoreSidebarRailItemStyle? sidebarRailItemStyle,
}) {
  final merged = _merged(context, sidebarRailItemStyle);

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final size = merged.size ?? CoreSidebarRailItemStyle.defaultSize;
  final borderRadius =
      merged.borderRadius ?? CoreSidebarRailItemStyle.defaultBorderRadius;
  final iconStyle = CoreSidebarRailItemStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final stateIconStyle = !enabled
      ? iconStyle
            .merge(CoreSidebarRailItemStyle.defaultDisabledIconStyle)
            .merge(merged.disabledIconStyle)
      : selected
      ? iconStyle
            .merge(CoreSidebarRailItemStyle.defaultSelectedIconStyle)
            .merge(merged.selectedIconStyle)
      : iconStyle;
  final fill = selected
      ? merged.selectedBackgroundColor ??
            CoreSidebarRailItemStyle.defaultSelectedBackgroundColor
      : merged.backgroundColor ??
            CoreSidebarRailItemStyle.defaultBackgroundColor;
  final dotColor = merged.dotColor ?? CoreSidebarRailItemStyle.defaultDotColor;
  final dotSize = merged.dotSize ?? CoreSidebarRailItemStyle.defaultDotSize;
  final clickableStyle = CoreSidebarRailItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final fillEmit = emitColor(fill, fill, ColorTarget.background);
  final inkEmit = emitColor(
    stateIconStyle.color,
    stateIconStyle.color!,
    ColorTarget.text,
  );
  final radiusEmit = emitRadius(borderRadius, borderRadius);
  final dotEmit = emitColor(dotColor, dotColor, ColorTarget.background);

  return ResolvedSidebarRailItem(
    root: WebElementChrome(
      className:
          'relative flex shrink-0 items-center justify-center select-none '
          '${fillEmit.className} ${radiusEmit.className} '
          '${inkEmit.className} $kWebTouchTargetMarker',
      inlineStyles: Styles(
        raw: {
          'width': pinnedLengthCss(size),
          'height': pinnedLengthCss(size),
          ...?fillEmit.inline,
          ...?radiusEmit.inline,
          ...?inkEmit.inline,
        },
      ),
    ),
    wash: WebElementChrome(
      className:
          '$_kSidebarRailItemWashMarker pointer-events-none absolute inset-0',
      inlineStyles: Styles(raw: {...?radiusEmit.inline}),
    ),
    dot: WebElementChrome(
      className: 'absolute rounded-full ${dotEmit.className}',
      inlineStyles: Styles(
        raw: {
          // One dot's width in from the top-end corner — the Flutter twin
          // insets it by the same length.
          'top': pinnedLengthCss(dotSize),
          'right': pinnedLengthCss(dotSize),
          'width': pinnedLengthCss(dotSize),
          'height': pinnedLengthCss(dotSize),
          ...?dotEmit.inline,
        },
      ),
    ),
    iconStyle: stateIconStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the square carrying [scopeClass].
ResolvedSidebarRailItemRules resolveSidebarRailItemRules(
  BuildContext context, {
  required String scopeClass,
  bool enabled = true,
  CoreSidebarRailItemStyle? sidebarRailItemStyle,
}) {
  if (!enabled) return const ResolvedSidebarRailItemRules(css: '');
  final merged = _merged(context, sidebarRailItemStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarRailItemStyle.defaultStateLayer;
  final ink =
      merged.stateLayerColor ?? CoreSidebarRailItemStyle.defaultStateLayerColor;
  final root = '.$scopeClass';
  const wash = '.$_kSidebarRailItemWashMarker';
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
  return ResolvedSidebarRailItemRules(css: buffer.toString());
}
