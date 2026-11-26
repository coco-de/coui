import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Paint-ready chrome for Web `SidebarSection`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="heading">)
///   ├─ label (<div>)
///   └─ action (<div>)        // * when the caller gives one
/// ```
class ResolvedSidebarSection implements WebResolvedChrome {
  /// Creates a [ResolvedSidebarSection].
  const ResolvedSidebarSection({
    required this.root,
    required this.label,
    required this.action,
    required this.actionIconStyle,
  });

  /// The heading row — insets and the spacing between its seats.
  @override
  final WebElementChrome root;

  /// The heading's text.
  final WebElementChrome label;

  /// The action's seat — its ink.
  final WebElementChrome action;

  /// The action glyph's chrome.
  final CoreIconStyle actionIconStyle;
}

/// Resolves [ResolvedSidebarSection] for the given [context].
///
/// ```text
/// CoreSidebarSectionStyle.defaultX
///   → CoreSidebarSectionTheme.style
///   → sidebarSectionStyle
/// ```
ResolvedSidebarSection resolveSidebarSection(
  BuildContext context, {
  CoreSidebarSectionStyle? sidebarSectionStyle,
}) {
  final merged = resolveStyleChain(const CoreSidebarSectionStyle(), [
    context.theme.coreComponentTheme?.sidebarSection?.style,
    sidebarSectionStyle,
  ]);

  final padding = merged.padding ?? CoreSidebarSectionStyle.defaultPadding;
  final contentSpacing =
      merged.contentSpacing ?? CoreSidebarSectionStyle.defaultContentSpacing;
  final labelStyle = CoreSidebarSectionStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  final actionIconStyle = CoreSidebarSectionStyle.defaultActionIconStyle.merge(
    merged.actionIconStyle,
  );

  final labelEmit = emitTypography(labelStyle, labelStyle);
  final actionEmit = emitColor(
    actionIconStyle.color,
    actionIconStyle.color!,
    ColorTarget.text,
  );

  return ResolvedSidebarSection(
    root: WebElementChrome(
      className: 'flex w-full items-center',
      inlineStyles: Styles(
        raw: {
          ...padding.toLogicalDeclarations('padding'),
          'gap': spaceCss(contentSpacing),
        },
      ),
    ),
    label: WebElementChrome(
      className: 'min-w-0 flex-1 truncate ${labelEmit.className}',
      inlineStyles: labelEmit.inline == null
          ? null
          : Styles(raw: labelEmit.inline),
    ),
    action: WebElementChrome(
      className: 'flex shrink-0 items-center ${actionEmit.className}',
      inlineStyles: actionEmit.inline == null
          ? null
          : Styles(raw: actionEmit.inline),
    ),
    actionIconStyle: actionIconStyle,
  );
}
