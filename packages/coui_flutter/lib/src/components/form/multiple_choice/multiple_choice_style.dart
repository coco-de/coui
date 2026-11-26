import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMultipleChoice
// ═══════════════════════════════════════════════════

/// Resolver output for `MultipleChoice`.
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has been merged through:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.multipleChoice.style
///   → widget.multipleChoiceStyle
/// ```
///
/// The option face is a composed `Chip`; the group states only the gap
/// between chips and the partial [CoreChipStyle] each chip is handed.
class ResolvedMultipleChoice {
  /// Creates a [ResolvedMultipleChoice].
  const ResolvedMultipleChoice({
    required this.optionSpacing,
    required this.selectedChipStyle,
    required this.unselectedChipStyle,
  });

  /// Gap between consecutive options (`Wrap.spacing` / `runSpacing`),
  /// theme geometry and scaling already applied.
  final double optionSpacing;

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

/// Resolves [ResolvedMultipleChoice] for `MultipleChoice`.
///
/// All chrome / dimensional overrides flow through the single
/// [multipleChoiceStyle] slot. [enabled] is the semantic prop that picks
/// the disabled label slot of the deprecated flat fields.
ResolvedMultipleChoice resolveMultipleChoice(
  BuildContext context, {
  required bool enabled,
  CoreMultipleChoiceStyle? multipleChoiceStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final mcTheme = theme.coreComponentTheme?.multipleChoice;

  final merged = resolveStyleChain(const CoreMultipleChoiceStyle(), [
    mcTheme?.style,
    multipleChoiceStyle,
  ]);

  // Flat option spacing — N-sibling 균등 분포 → Wrap(spacing:) native.
  // Resolver pre-applies scaling (Stage2 EMIT in the local).
  final optionSpacing =
      theme.geometry.space(
        merged.optionSpacing ?? CoreMultipleChoiceStyle.defaultOptionSpacing,
      ) *
      scaling;

  // Nested Chip slot — partial, raw-forwarded: the `Chip` runs its own
  // scheme / geometry / scaling resolution for whatever flows through.
  final selectedChipStyle = merged.chipStyleFor(
    selected: true,
    enabled: enabled,
  );
  final unselectedChipStyle = merged.chipStyleFor(
    selected: false,
    enabled: enabled,
  );

  return ResolvedMultipleChoice(
    optionSpacing: optionSpacing,
    selectedChipStyle: selectedChipStyle,
    unselectedChipStyle: unselectedChipStyle,
  );
}
