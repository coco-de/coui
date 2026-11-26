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

/// Paint-ready chrome for Web `PageHeader`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // w-full · flex-col · gap: textSpacing
///   ├─ eyebrow (<div>)  → eyebrow       // optional
///   ├─ titleRow (<div>)                 // flex-wrap · items-center ·
///   │                                   //   gap: textActionsSpacing ·
///   │                                   //   only when there are actions
///   │   ├─ titleBlock (<div>)           // flex: 1 1 <minTextWidth> · min-w-0
///   │   │   └─ title (<h1>…<h6>)        // headingLevel, margin 0
///   │   └─ actions (<div>) → actions    // flex-wrap · gap: actionSpacing
///   └─ description (<div>)              // optional, the header's full width
/// ```
///
/// Without actions the title is the root's child directly. With actions the
/// title's basis is the narrowest it may get: the row holds it and the
/// actions while there is room for both, and `flex-wrap` moves the actions
/// under it when there is not — the rule the Flutter twin's
/// `HeaderWrapLayout` follows. The description sits under the row at the
/// header's full width, so it wraps there.
///
/// The root fills its container's width even where a parent would size it
/// to its content (a flex row, an inline-block): the Flutter twin takes the
/// whole bounded width it is given, and a content-sized row would measure
/// the title by its content rather than its basis and wrap the actions where
/// Flutter keeps them beside it.
class ResolvedPageHeader implements WebResolvedChrome {
  /// Creates a [ResolvedPageHeader].
  const ResolvedPageHeader({
    required this.root,
    required this.titleRow,
    required this.titleBlock,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  final WebElementChrome root;

  /// The title's line, shared with the actions.
  final WebElementChrome titleRow;

  /// The title's cell in [titleRow] — its basis is the title's floor.
  final WebElementChrome titleBlock;

  /// The eyebrow line — its role and colour.
  final WebElementChrome eyebrow;

  /// The title heading — its role and colour, and no heading margin.
  final WebElementChrome title;

  /// The description line — its role and colour.
  final WebElementChrome description;

  /// The row of actions.
  final WebElementChrome actions;
}

/// Resolves the chrome of a Web `PageHeader`.
///
/// ```text
/// CorePageHeaderStyle.default*
///   → CorePageHeaderTheme.style
///   → widget.pageHeaderStyle
/// ```
ResolvedPageHeader resolvePageHeader(
  BuildContext context, {
  CorePageHeaderStyle? pageHeaderStyle,
}) {
  final merged = resolveStyleChain(const CorePageHeaderStyle(), [
    context.theme.coreComponentTheme?.pageHeader?.style,
    pageHeaderStyle,
  ]);

  final eyebrowEmit = emitTypography(
    merged.eyebrowTextStyle,
    CorePageHeaderStyle.defaultEyebrowTextStyle,
  );
  final titleEmit = emitTypography(
    merged.titleTextStyle,
    CorePageHeaderStyle.defaultTitleTextStyle,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CorePageHeaderStyle.defaultDescriptionTextStyle,
  );
  final textSpacing =
      merged.textSpacing ?? CorePageHeaderStyle.defaultTextSpacing;
  final textActionsSpacing =
      merged.textActionsSpacing ??
      CorePageHeaderStyle.defaultTextActionsSpacing;
  final actionSpacing =
      merged.actionSpacing ?? CorePageHeaderStyle.defaultActionSpacing;
  final minTextWidth =
      merged.minTextWidth ?? CorePageHeaderStyle.defaultMinTextWidth;

  /// A text line's chrome — its role class and any stated overlay.
  WebElementChrome buildLine(
    Emit emit, {
    Map<String, String> extra = const {},
  }) {
    final raw = {...extra, ...?emit.inline};
    return WebElementChrome(
      className: emit.className,
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  return ResolvedPageHeader(
    root: WebElementChrome(
      className: [WebLayout.flex, WebLayout.flexCol, WebLayout.wFull].join(' '),
      inlineStyles: Styles(raw: {'gap': spaceCss(textSpacing)}),
    ),
    titleRow: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexWrap,
        WebLayout.itemsCenter,
      ].join(' '),
      inlineStyles: Styles(raw: {'gap': spaceCss(textActionsSpacing)}),
    ),
    titleBlock: WebElementChrome(
      className: WebLayout.minWZero,
      inlineStyles: Styles(
        raw: {
          // The narrowest the title may get beside the actions: below it the
          // actions wrap onto a line of their own.
          'flex': '1 1 ${minTextWidth / kRemDivisor}rem',
        },
      ),
    ),
    eyebrow: buildLine(eyebrowEmit),
    // A heading element's own margin is not part of the design.
    title: buildLine(titleEmit, extra: {'margin': spaceCss(0)}),
    description: buildLine(descriptionEmit),
    actions: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexWrap,
        WebLayout.itemsCenter,
      ].join(' '),
      inlineStyles: Styles(raw: {'gap': spaceCss(actionSpacing)}),
    ),
  );
}
