import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Paint-ready chrome for Web `SidebarGroup`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // column, childrenSpacing
///   ├─ SidebarItem (itemStyle)       // the group's own row, chevron at its end
///   └─ collapse (<div>)              // grid-template-rows 0fr ↔ 1fr
///        └─ clip (<div>)             // min-height 0, overflow hidden
///             └─ nested (<div>)      // relative, childrenPadding
///                  ├─ line (<div>)   // treeLineColor × treeLineWidth at treeLineInset
///                  └─ children
/// ```
class ResolvedSidebarGroup implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarGroup].
  const ResolvedSidebarGroup({
    required this.root,
    required this.collapse,
    required this.clip,
    required this.nested,
    required this.line,
    required this.chevronIconStyle,
    required this.itemStyle,
  });

  /// The group column.
  @override
  final WebElementChrome root;

  /// The open / close track.
  final WebElementChrome collapse;

  /// The clip inside the track.
  final WebElementChrome clip;

  /// The nested rows' column.
  final WebElementChrome nested;

  /// The line beside the nested rows.
  final WebElementChrome line;

  /// The chevron, raw-forwarded to the composed `Icon`.
  final CoreIconStyle chevronIconStyle;

  /// The group row's chrome, raw-forwarded to its `SidebarItem`.
  final CoreSidebarItemStyle? itemStyle;
}

/// Resolves [ResolvedSidebarGroup] for the given [context].
///
/// ```text
/// CoreSidebarGroupStyle.defaultX
///   → CoreSidebarGroupTheme.style
///   → sidebarGroupStyle
/// ```
ResolvedSidebarGroup resolveSidebarGroup(
  BuildContext context, {
  required bool expanded,
  CoreSidebarGroupStyle? sidebarGroupStyle,
}) {
  final merged = resolveStyleChain(const CoreSidebarGroupStyle(), [
    context.theme.coreComponentTheme?.sidebarGroup?.style,
    sidebarGroupStyle,
  ]);

  final childrenPadding =
      merged.childrenPadding ?? CoreSidebarGroupStyle.defaultChildrenPadding;
  final childrenSpacing =
      merged.childrenSpacing ?? CoreSidebarGroupStyle.defaultChildrenSpacing;
  final treeLineColor =
      merged.treeLineColor ?? CoreSidebarGroupStyle.defaultTreeLineColor;
  final treeLineWidth =
      merged.treeLineWidth ?? CoreSidebarGroupStyle.defaultTreeLineWidth;
  final treeLineInset =
      merged.treeLineInset ?? CoreSidebarGroupStyle.defaultTreeLineInset;
  final chevronIconStyle = CoreSidebarGroupStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final durationMs =
      (merged.duration ?? CoreSidebarGroupStyle.defaultDuration).inMilliseconds;
  final transitionTiming =
      '${durationMsCss(durationMs)} ${CoreEasing.move.toVarCss()}';
  final lineEmit = emitColor(
    treeLineColor,
    treeLineColor,
    ColorTarget.background,
  );

  return ResolvedSidebarGroup(
    root: WebElementChrome(
      className: 'flex w-full flex-col',
      inlineStyles: Styles(
        // The gap between the row and the nested rows is there only while
        // the group is open, as on the Flutter twin.
        raw: {if (expanded) 'gap': spaceCss(childrenSpacing)},
      ),
    ),
    collapse: WebElementChrome(
      className: 'grid',
      inlineStyles: Styles(
        raw: {
          'grid-template-rows': expanded ? '1fr' : '0fr',
          'transition': 'grid-template-rows $transitionTiming',
        },
      ),
    ),
    clip: const WebElementChrome(className: 'min-h-0 overflow-hidden'),
    nested: WebElementChrome(
      className: 'relative flex flex-col',
      inlineStyles: Styles(
        raw: {
          ...childrenPadding.toLogicalDeclarations('padding'),
          'gap': spaceCss(childrenSpacing),
        },
      ),
    ),
    line: WebElementChrome(
      className: 'absolute inset-y-0 ${lineEmit.className}',
      inlineStyles: Styles(
        raw: {
          // A position, not a gap: the line marks where the group row's
          // glyph sits, so density does not move it.
          'inset-inline-start': pinnedLengthCss(treeLineInset),
          'width': strokeWidthCss(treeLineWidth),
          ...?lineEmit.inline,
        },
      ),
    ),
    chevronIconStyle: chevronIconStyle,
    itemStyle: merged.itemStyle,
  );
}
