import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Paint-ready chrome for Web `OptionList`.
///
/// ```text
/// root (<div role="group">)            // flex column, rows stretch, gap
///   └─ the OptionItem rows
/// ```
class ResolvedOptionList implements WebResolvedChrome {
  /// Creates a [ResolvedOptionList].
  const ResolvedOptionList({required this.root});

  /// The list — a flex column whose rows take the list's width.
  @override
  final WebElementChrome root;
}

/// Resolves the chrome of a Web `OptionList`.
///
/// ```text
/// CoreOptionListStyle.default*
///   → CoreOptionListTheme.style
///   → widget.optionListStyle
/// ```
ResolvedOptionList resolveOptionList(
  BuildContext context, {
  CoreOptionListStyle? optionListStyle,
}) {
  final merged = resolveStyleChain(const CoreOptionListStyle(), [
    context.theme.coreComponentTheme?.optionList?.style,
    optionListStyle,
  ]);
  final spacing = merged.spacing ?? CoreOptionListStyle.defaultSpacing;
  return ResolvedOptionList(
    root: WebElementChrome(
      className: 'flex w-full flex-col',
      inlineStyles: Styles(raw: {'gap': spaceCss(spacing)}),
    ),
  );
}
