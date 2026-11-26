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

/// Paint-ready chrome for Web `PanelHeader`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                         // w-full · flex-wrap · items-center ·
///                                      //   gap: titleActionSpacing ·
///                                      //   padding
///   ├─ title (<h1>…<h6>) → title       // headingLevel · margin 0 ·
///   │                                  //   flex: 1 1 <minTitleWidth>
///   └─ action (<div>) → action         // optional
/// ```
///
/// The title's basis is the narrowest it may get: the row holds it and the
/// action while there is room for both, and `flex-wrap` moves the action
/// under it when there is not — the rule the Flutter twin's
/// `HeaderWrapLayout` follows. The root fills its container's width for the
/// reason `ResolvedPageHeader` gives.
class ResolvedPanelHeader implements WebResolvedChrome {
  /// Creates a [ResolvedPanelHeader].
  const ResolvedPanelHeader({
    required this.root,
    required this.title,
    required this.action,
  });

  @override
  final WebElementChrome root;

  /// The title heading — its role, colour and basis, and no heading margin.
  final WebElementChrome title;

  /// The wrapper of the action.
  final WebElementChrome action;
}

/// Resolves the chrome of a Web `PanelHeader`.
///
/// ```text
/// CorePanelHeaderStyle.default*
///   → CorePanelHeaderTheme.style
///   → widget.panelHeaderStyle
/// ```
ResolvedPanelHeader resolvePanelHeader(
  BuildContext context, {
  CorePanelHeaderStyle? panelHeaderStyle,
}) {
  final merged = resolveStyleChain(const CorePanelHeaderStyle(), [
    context.theme.coreComponentTheme?.panelHeader?.style,
    panelHeaderStyle,
  ]);

  final titleEmit = emitTypography(
    merged.titleTextStyle,
    CorePanelHeaderStyle.defaultTitleTextStyle,
  );
  final paddingEmit = emitSpacing(
    merged.padding,
    CorePanelHeaderStyle.defaultPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final titleActionSpacing =
      merged.titleActionSpacing ??
      CorePanelHeaderStyle.defaultTitleActionSpacing;
  final minTitleWidth =
      merged.minTitleWidth ?? CorePanelHeaderStyle.defaultMinTitleWidth;

  return ResolvedPanelHeader(
    root: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexWrap,
        WebLayout.itemsCenter,
        WebLayout.wFull,
        paddingEmit.className,
      ].where((c) => c.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {'gap': spaceCss(titleActionSpacing), ...?paddingEmit.inline},
      ),
    ),
    title: WebElementChrome(
      className: [titleEmit.className, WebLayout.minWZero].join(' '),
      inlineStyles: Styles(
        raw: {
          // A heading element's own margin is not part of the design.
          'margin': spaceCss(0),
          // The narrowest the title may get beside the action: below it the
          // action wraps onto a line of its own.
          'flex': '1 1 ${minTitleWidth / kRemDivisor}rem',
          ...?titleEmit.inline,
        },
      ),
    ),
    action: const WebElementChrome(className: WebLayout.flex),
  );
}
