import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedValidated
// ═══════════════════════════════════════════════════

/// Resolver output for [Validated].
///
/// Widget tree (`co_validated` decides which optional branches render):
///
/// ```text
/// Column
///   ├─ optional DecoratedBox (when child != null && ringColor != null)
///   │    └─ child
///   ├─ optional child (when child != null && ringColor == null)
///   ├─ Gap(fieldMessageGapStyle)     // when message != null && state != pending
///   └─ optional message                 // when message != null && state != pending
/// ```
///
/// Every chrome / dimensional override has had the nested-merge chain
/// applied plus the `CoreValidatedStyle.defaultX` static const
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreValidatedStyle.defaultX            // design system default
///   → theme.coreComponentTheme.validated.style
///   → widget.validatedStyle
/// ```
class ResolvedValidated {
  /// Creates a [ResolvedValidated].
  const ResolvedValidated({
    required this.validatorHintStyle,
    required this.fieldMessageGapStyle,
  });

  /// Nested [CoreValidatorHintStyle] slot — raw-forwarded to the
  /// composed message `ValidatorHint`.
  final CoreValidatorHintStyle validatorHintStyle;

  /// Nested [CoreGapStyle] for the field → message spacer — forwarded
  /// straight to `Gap(gapStyle: …)`.
  final CoreGapStyle fieldMessageGapStyle;
}

// ═══════════════════════════════════════════════════
// resolveValidated — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidated] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreValidatedStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values. The semantic state
/// itself is not chrome here — the widget propagates it to the wrapped
/// field, whose own error variant draws the border / focus ring.
ResolvedValidated resolveValidated(
  BuildContext context, {
  CoreValidatedStyle? validatedStyle,
}) {
  final theme = Theme.of(context);
  final validatedTheme = theme.coreComponentTheme?.validated;

  // 2-stage merge chain — theme.style → widget.validatedStyle.
  final merged = resolveStyleChain(const CoreValidatedStyle(), [
    validatedTheme?.style,
    validatedStyle,
  ]);

  // Nested ValidatorHint slot (raw-forward) — bodySmall role partial
  // merged with the per-instance override; the ValidatorHint's own
  // resolver fills the per-type accent and the rest.
  final validatorHintStyle = CoreValidatedStyle.defaultValidatorHintStyle.merge(
    merged.validatorHintStyle,
  );

  // ─── Layout gap (nested CoreGapStyle slot forwarded to Gap) ───
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override and forward the raw slot to `Gap`. The
  // `Gap` widget runs its own resolver which applies `theme.scaling`
  // — the resolver here MUST NOT mutate the slot's `size` (Epic #1603
  // 옵션 B 최종 — nested Style slots are forwarded raw so the receiving
  // child component owns its own scale step).
  final fieldMessageGapStyle = CoreValidatedStyle.defaultFieldMessageGapStyle
      .merge(merged.fieldMessageGapStyle);

  return ResolvedValidated(
    validatorHintStyle: validatorHintStyle,
    fieldMessageGapStyle: fieldMessageGapStyle,
  );
}
