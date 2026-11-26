import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Paint-ready chrome for Web `Sidebar`.
///
/// DOM shape:
///
/// ```text
/// root (<nav>)                     // row, the column heights stretch
///   ├─ rail (<div>)                // * twoPane / collapsed
///   │    ├─ railHeader · Gap (railHeaderGapStyle)
///   │    ├─ railItems (<div>)      // scrolls
///   │    └─ railFooter
///   └─ panel (<div>)               // * standard / twoPane
///        ├─ top (<div>)            // header · panel title row · search
///        │    └─ panelTitle (<div>) · panelAction (<div>)
///        ├─ body (<div>)           // scrolls
///        └─ bottom (<div>)         // footer · help · user
/// ```
class ResolvedSidebar implements WebResolvedChrome {
  /// Creates a [ResolvedSidebar].
  const ResolvedSidebar({
    required this.root,
    required this.rail,
    required this.railItems,
    required this.panel,
    required this.top,
    required this.panelTitleRow,
    required this.panelTitle,
    required this.panelAction,
    required this.body,
    required this.bottom,
    required this.railHeaderGapStyle,
    required this.panelActionIconStyle,
  });

  /// The landmark row.
  @override
  final WebElementChrome root;

  /// The icon rail.
  final WebElementChrome rail;

  /// The rail's scrolling destinations.
  final WebElementChrome railItems;

  /// The panel.
  final WebElementChrome panel;

  /// The panel's top region.
  final WebElementChrome top;

  /// The two-pane panel title row.
  final WebElementChrome panelTitleRow;

  /// The panel title's text.
  final WebElementChrome panelTitle;

  /// The panel title action's seat.
  final WebElementChrome panelAction;

  /// The panel's scrolling body.
  final WebElementChrome body;

  /// The panel's bottom region.
  final WebElementChrome bottom;

  /// Extra room after the rail's header, raw-forwarded to the composed
  /// `Gap`.
  final CoreGapStyle railHeaderGapStyle;

  /// The panel title action's glyph chrome.
  final CoreIconStyle panelActionIconStyle;
}

/// Resolves [ResolvedSidebar] for the given [context].
///
/// ```text
/// CoreSidebarStyle.defaultX → defaultsByType[type]
///   → CoreSidebarTheme.style
///   → CoreSidebarTheme.variantStyles[type]
///   → sidebarStyle
/// ```
ResolvedSidebar resolveSidebar(
  BuildContext context, {
  required CoreSidebarType type,
  CoreSidebarStyle? sidebarStyle,
}) {
  final sidebarTheme = context.theme.coreComponentTheme?.sidebar;
  final merged = resolveStyleChain(const CoreSidebarStyle(), [
    sidebarTheme?.style,
    sidebarTheme?.variantStyles?[type],
    sidebarStyle,
  ]);
  final typeStyle = CoreSidebarStyle.defaultsByType[type]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final backgroundColor =
      merged.backgroundColor ?? CoreSidebarStyle.defaultBackgroundColor;
  final borderColor = merged.borderColor ?? CoreSidebarStyle.defaultBorderColor;
  final borderWidth = merged.borderWidth ?? CoreSidebarStyle.defaultBorderWidth;
  final panelWidth = merged.panelWidth ?? typeStyle.panelWidth!;
  final railWidth = merged.railWidth ?? CoreSidebarStyle.defaultRailWidth;
  final railBackgroundColor =
      merged.railBackgroundColor ?? typeStyle.railBackgroundColor!;
  final railPadding = merged.railPadding ?? CoreSidebarStyle.defaultRailPadding;
  final railSpacing = merged.railSpacing ?? CoreSidebarStyle.defaultRailSpacing;
  final topPadding = merged.topPadding ?? typeStyle.topPadding!;
  final topSpacing = merged.topSpacing ?? CoreSidebarStyle.defaultTopSpacing;
  final bodyPadding = merged.bodyPadding ?? typeStyle.bodyPadding!;
  final bodySpacing = merged.bodySpacing ?? CoreSidebarStyle.defaultBodySpacing;
  final bottomPadding =
      merged.bottomPadding ?? CoreSidebarStyle.defaultBottomPadding;
  final bottomSpacing =
      merged.bottomSpacing ?? CoreSidebarStyle.defaultBottomSpacing;
  final panelTitlePadding =
      merged.panelTitlePadding ?? CoreSidebarStyle.defaultPanelTitlePadding;
  final panelTitleSpacing =
      merged.panelTitleSpacing ?? CoreSidebarStyle.defaultPanelTitleSpacing;
  final railHeaderGapStyle = CoreSidebarStyle.defaultRailHeaderGapStyle.merge(
    merged.railHeaderGapStyle,
  );
  final panelTitleStyle = CoreSidebarStyle.defaultPanelTitleStyle.merge(
    merged.panelTitleStyle,
  );
  final panelActionIconStyle = CoreSidebarStyle.defaultPanelActionIconStyle
      .merge(merged.panelActionIconStyle);

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final fillEmit = emitColor(
    backgroundColor,
    backgroundColor,
    ColorTarget.background,
  );
  final railFillEmit = emitColor(
    railBackgroundColor,
    railBackgroundColor,
    ColorTarget.background,
  );
  final borderEmit = emitColor(borderColor, borderColor, ColorTarget.border);
  final titleEmit = emitTypography(panelTitleStyle, panelTitleStyle);
  final actionEmit = emitColor(
    panelActionIconStyle.color,
    panelActionIconStyle.color!,
    ColorTarget.text,
  );
  // The line on the edge that meets the page — the end side, so a
  // right-to-left page mirrors it. The rail carries it only when it is the
  // outermost column; in two-pane the panel beside it meets the page.
  final edge = {
    'border-inline-end-width': strokeWidthCss(borderWidth),
    'border-inline-end-style': 'solid',
    ...?borderEmit.inline,
  };
  final railEdged = type == CoreSidebarType.collapsed;

  return ResolvedSidebar(
    root: const WebElementChrome(className: 'flex h-full items-stretch'),
    rail: WebElementChrome(
      className:
          'flex h-full shrink-0 flex-col items-center '
          '${railFillEmit.className} '
          '${railEdged ? borderEmit.className : ''}',
      inlineStyles: Styles(
        raw: {
          'width': pinnedLengthCss(railWidth),
          'padding': railPadding.toValue(),
          'gap': spaceCss(railSpacing),
          ...?railFillEmit.inline,
          if (railEdged) ...edge,
        },
      ),
    ),
    railItems: WebElementChrome(
      className: 'flex min-h-0 flex-1 flex-col items-center overflow-y-auto',
      inlineStyles: Styles(raw: {'gap': spaceCss(railSpacing)}),
    ),
    panel: WebElementChrome(
      className:
          'flex h-full shrink-0 flex-col '
          '${fillEmit.className} ${borderEmit.className}',
      inlineStyles: Styles(
        raw: {
          'width': pinnedLengthCss(panelWidth),
          ...?fillEmit.inline,
          ...edge,
        },
      ),
    ),
    top: WebElementChrome(
      className: 'flex shrink-0 flex-col',
      inlineStyles: Styles(
        raw: {'padding': topPadding.toValue(), 'gap': spaceCss(topSpacing)},
      ),
    ),
    panelTitleRow: WebElementChrome(
      className: 'flex items-center',
      inlineStyles: Styles(
        raw: {
          ...panelTitlePadding.toLogicalDeclarations('padding'),
          'gap': spaceCss(panelTitleSpacing),
        },
      ),
    ),
    panelTitle: WebElementChrome(
      className: 'min-w-0 flex-1 truncate ${titleEmit.className}',
      inlineStyles: titleEmit.inline == null
          ? null
          : Styles(raw: titleEmit.inline),
    ),
    panelAction: WebElementChrome(
      className: 'flex shrink-0 items-center ${actionEmit.className}',
      inlineStyles: actionEmit.inline == null
          ? null
          : Styles(raw: actionEmit.inline),
    ),
    body: WebElementChrome(
      className: 'flex min-h-0 flex-1 flex-col overflow-y-auto',
      inlineStyles: Styles(
        raw: {'padding': bodyPadding.toValue(), 'gap': spaceCss(bodySpacing)},
      ),
    ),
    bottom: WebElementChrome(
      className: 'flex shrink-0 flex-col',
      inlineStyles: Styles(
        raw: {
          'padding': bottomPadding.toValue(),
          'gap': spaceCss(bottomSpacing),
        },
      ),
    ),
    railHeaderGapStyle: railHeaderGapStyle,
    panelActionIconStyle: panelActionIconStyle,
  );
}
