/// Paint-ready chrome for Web `Select`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Select`.
///
/// DOM shape:
///
/// ```text
/// root (Popover — owns its own outermost DOM element)
///   ├─ trigger (TextField, readOnly, role="combobox")
///   │    └─ Icon(chevronDown) — chevronIconStyle
///   └─ panel (<div role="listbox">)             // scroll region + row gap
///         ├─ option (<div role="option">)       // one per item
///         │    └─ MenuItem — optionStyle
///         └─ emptyState (<div>)                 // only when the list is empty
/// ```
///
/// The trigger is a field and the rows are menu rows, so almost nothing
/// here is Select's own: [triggerStyle] and [optionStyle] are raw-forwarded
/// and each child resolver fills its own ladder. What Select settles is the
/// panel ([popoverStyle] + the scroll region below), the chevron, and the
/// empty-state copy.
class ResolvedSelect implements WebResolvedChrome {
  /// Creates a [ResolvedSelect].
  const ResolvedSelect({
    required this.root,
    required this.panel,
    required this.option,
    required this.emptyState,
    required this.popoverStyle,
    required this.triggerStyle,
    required this.optionStyle,
    required this.emptyStateStyle,
    required this.chevronIconStyle,
  });

  /// Paint-ready chrome for the outermost element. Empty: `Select`
  /// returns the `Popover` directly and the popover owns its own root.
  @override
  final WebElementChrome root;

  /// The options panel `<div role="listbox">` — the scroll region and the
  /// row gap. The panel's box (fill / border / corner / inset / shadow)
  /// belongs to the composed `Popup`.
  final WebElementChrome panel;

  /// The wrapper each row sits in — it carries the `option` role and the
  /// selected state, because the container states what its rows are.
  final WebElementChrome option;

  /// The empty-state `<div>` shown when the list has no rows.
  final WebElementChrome emptyState;

  /// Nested [CorePopoverStyle] slot — forwarded to the wrapping
  /// `Popover`.
  final CorePopoverStyle popoverStyle;

  /// Nested [CoreTextFieldStyle] slot — forwarded to the trigger field.
  final CoreTextFieldStyle triggerStyle;

  /// Nested [CoreMenuItemStyle] slot — forwarded to each option row.
  final CoreMenuItemStyle optionStyle;

  /// Nested [CoreTextStyle] slot — the "no results" copy's overlay.
  final CoreTextStyle emptyStateStyle;

  /// Nested [CoreIconStyle] slot — forwarded to the trigger chevron.
  final CoreIconStyle chevronIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSelect] for the given `context`.
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.select.style
///   → theme.coreComponentTheme.select.variantStyles[variant]
///   → widget.selectStyle
/// ```
ResolvedSelect resolveSelect(
  BuildContext context, {
  CoreSelectSize size = CoreSelectSize.defaultSize,
  CoreSelectVariant variant = CoreSelectVariant.defaultSelectVariant,
  CoreSelectStyle? selectStyle,
  bool enabled = true,
}) {
  final selectTheme = context.theme.coreComponentTheme?.select;

  final merged = resolveStyleChain(const CoreSelectStyle(), [
    selectTheme?.style,
    selectTheme?.variantStyles?[variant],
    selectStyle,
  ]);
  final sizeStyle = CoreSelectStyle.defaultsBySize[size]!;

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final maxHeight =
      merged.optionsPanelMaxHeight ??
      CoreSelectStyle.defaultOptionsPanelMaxHeight;
  final optionSpacing =
      merged.optionSpacing ?? CoreSelectStyle.defaultOptionSpacing;
  final emptyStateInsets =
      merged.emptyStateInsets ?? CoreSelectStyle.defaultEmptyStateInsets;
  final emptyStateColor =
      merged.emptyStateColor ?? CoreSelectStyle.defaultEmptyStateColor;

  final popoverStyle = CoreSelectStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  // guard-nested-override: contentColor — `merged.contentColor` is folded
  // into `effectiveTriggerStyle` as the value text colour.
  // guard-nested-override: selectedIconColor — `merged.selectedIconColor`
  // is folded into `effectiveOptionStyle` as the mark colour.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;
  final optionStyle = merged.effectiveOptionStyle;
  final emptyStateStyle = const CoreTextStyle().merge(merged.emptyStateStyle);
  // The chevron is tinted like the placeholder — the field's affordance,
  // not its content. That tint wins over a caller-supplied
  // `trailingIconStyle.color`; the dedicated entry point is
  // `placeholderColor`.
  // guard-nested-override: color — placeholder tint wins over
  // `trailingIconStyle.color`; override via `placeholderColor` instead.
  // A disabled select leaves the chevron untinted: the field's own icon
  // tone for a disabled control applies (`disabledContent`).
  final chevronRung = sizeStyle.trailingIconStyle!.merge(
    merged.trailingIconStyle,
  );
  final chevronIconStyle = enabled
      ? chevronRung.copyWith(
          color:
              merged.placeholderColor ??
              CoreSelectStyle.defaultPlaceholderColor,
        )
      : chevronRung;

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final panelStyles = Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'row-gap': spaceCss(optionSpacing),
      'max-height': '${maxHeight / kRemDivisor}rem',
      'overflow-y': 'auto',
    },
  );
  final emptyStateStyles = Styles(
    raw: {
      'padding': emptyStateInsets.toValue(),
      'color': emptyStateColor.toValue(),
      ...emptyStateStyle.toInlineCss(),
    },
  );

  return ResolvedSelect(
    root: const WebElementChrome(className: ''),
    panel: WebElementChrome(className: '', inlineStyles: panelStyles),
    // The wrapper is layout-transparent: the row inside it paints
    // everything, and this element exists to carry the role.
    option: const WebElementChrome(className: 'contents'),
    emptyState: WebElementChrome(className: '', inlineStyles: emptyStateStyles),
    popoverStyle: popoverStyle,
    triggerStyle: triggerStyle,
    optionStyle: optionStyle,
    emptyStateStyle: emptyStateStyle,
    chevronIconStyle: chevronIconStyle,
  );
}
