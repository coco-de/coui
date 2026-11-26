import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// ResolvedMultipleChoice
// ═══════════════════════════════════════════════════

/// Resolver output for `MultipleChoice` on Web.
///
/// DOM shape:
///
/// ```text
/// root (<div role="radiogroup">)    // inline-flex wrap, gap between options
///   └─ Chip (role="radio")          // one composed Chip per option —
///                                      its own Clickable / box / label
/// ```
///
/// The option face is a composed `Chip`; the group's chrome is the row
/// ([root]) and the partial [CoreChipStyle] each chip is handed.
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.multipleChoice.style
///   → widget.multipleChoiceStyle
/// ```
class ResolvedMultipleChoice implements WebResolvedChrome {
  /// Creates a [ResolvedMultipleChoice].
  const ResolvedMultipleChoice({
    required this.root,
    required this.selectedChipStyle,
    required this.unselectedChipStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="radiogroup">` row.
  @override
  final WebElementChrome root;

  /// Partial [CoreChipStyle] raw-forwarded to the selected option's
  /// `Chip(chipStyle:)` — `CoreMultipleChoiceStyle.defaultChipStyle`
  /// folded with the deprecated flat option fields and the per-instance
  /// `chipStyle` override. The chip's own resolver fills the rest.
  final CoreChipStyle selectedChipStyle;

  /// Same as [selectedChipStyle] for an unselected option.
  final CoreChipStyle unselectedChipStyle;
}

// ═══════════════════════════════════════════════════
// resolveMultipleChoice — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMultipleChoice] for the given build context.
///
/// [enabled] is the semantic prop that picks the disabled label slot of
/// the deprecated flat fields.
ResolvedMultipleChoice resolveMultipleChoice(
  BuildContext context, {
  required bool enabled,
  CoreMultipleChoiceStyle? multipleChoiceStyle,
}) {
  final mcTheme = context.theme.coreComponentTheme?.multipleChoice;

  final merged = resolveStyleChain(const CoreMultipleChoiceStyle(), [
    mcTheme?.style,
    multipleChoiceStyle,
  ]);

  // Flat option spacing — N-sibling 균등 분포 (Web flex container gap).
  final gap =
      merged.optionSpacing ?? CoreMultipleChoiceStyle.defaultOptionSpacing;

  // ─── Local builders ───────────────────────────────────

  /// Composes the option-group root `<div role="radiogroup">` Tailwind
  /// className.
  // 좁은 폭에서 옵션이 줄바꿈되도록 — Flutter 의 Wrap 과 동일 동작.
  String buildRootClassName() =>
      '${WebLayout.inlineFlex} flex-wrap ${WebLayout.maxWFull}';

  /// Inline CSS for the option-group root — per-instance gap between
  /// the options.
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(gap)});

  // Nested Chip slot — partial, raw-forwarded (the Chip's own resolver
  // fills the rest).
  final selectedChipStyle = merged.chipStyleFor(
    selected: true,
    enabled: enabled,
  );
  final unselectedChipStyle = merged.chipStyleFor(
    selected: false,
    enabled: enabled,
  );

  return ResolvedMultipleChoice(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    selectedChipStyle: selectedChipStyle,
    unselectedChipStyle: unselectedChipStyle,
  );
}
