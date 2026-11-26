library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `FormField`.
///
/// Widget tree (`co_form_field.dart`):
///
/// ```text
/// optional IgnorePointer (when !enabled)
///   └─ Column (mainAxisSize.min, crossAxisAlignment.stretch)
///        ├─ optional label Row
///        │     ├─ DefaultTextStyle (labelTextStyle) > label content
///        │     ├─ Gap (requiredIndicatorGapStyle)  // when required
///        │     └─ optional '*' (requiredIndicatorColor)
///        ├─ Gap (labelInputGapStyle)               // between label and child
///        ├─ child
///        ├─ Gap (labelInputGapStyle) + error    (errorTextStyle)     // when error != null
///        └─ Gap (labelInputGapStyle) + helper   (descriptionTextStyle) // when description
/// ```
///
/// Single struct that the widget reads — the nested-merge chain
/// (theme.style → widget.formFieldStyle) plus the
/// `CoreFormFieldStyle.defaultX` static const fallback and Flutter type
/// conversion are all applied once here, so the widget reads only
/// fully-resolved paint-ready values.
class ResolvedFormField {
  /// Creates a [ResolvedFormField].
  const ResolvedFormField({
    required this.labelInputGapStyle,
    required this.formLabelStyle,
    required this.validatorHintStyle,
    required this.descriptionTextStyle,
    required this.labelActionGapStyle,
    required this.counterTextStyle,
    required this.footerGapStyle,
  });

  /// Nested [CoreGapStyle] slot for the gap between the label, the
  /// child, and the helper / error text — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve step, so this
  /// slot is the merged design-system default + per-instance override
  /// in pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle labelInputGapStyle;

  /// Nested [CoreFormLabelStyle] slot — raw-forwarded to the composed
  /// `FormLabel` (its own resolver fills defaults; the disabled-state
  /// overlay is already merged when the field is disabled). `null` when
  /// enabled with no per-instance override.
  final CoreFormLabelStyle? formLabelStyle;

  /// Nested [CoreValidatorHintStyle] slot — raw-forwarded to the
  /// composed error `ValidatorHint` (its own resolver fills the
  /// error-type accent / icon defaults).
  final CoreValidatorHintStyle validatorHintStyle;

  /// Paint-ready description / helper [TextStyle].
  final TextStyle descriptionTextStyle;

  /// Nested [CoreGapStyle] slot for the label↔action gap — the floor on
  /// their separation, since the row pushes the two apart.
  final CoreGapStyle labelActionGapStyle;

  /// Paint-ready counter [TextStyle].
  final TextStyle counterTextStyle;

  /// Nested [CoreGapStyle] slot for the footer's message↔counter gap —
  /// the floor, for the same reason as [labelActionGapStyle].
  final CoreGapStyle footerGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFormField] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default (CoreFormFieldStyle.defaultX)
///   → theme.coreComponentTheme.formField.style
///   → widget.formFieldStyle
/// ```
///
/// [enabled] is a semantic widget prop (C13): a disabled field renders
/// its label through the disabled overlay
/// (`CoreFormFieldStyle.defaultDisabledFormLabelStyle`, muted
/// `onSurfaceSubtle`) instead of the `FormLabel`'s own enabled colour.
ResolvedFormField resolveFormField(
  BuildContext context, {
  required bool enabled,
  CoreFormFieldStyle? formFieldStyle,
}) {
  final theme = Theme.of(context);
  final fieldTheme = theme.coreComponentTheme?.formField;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFormFieldStyle(), [
    fieldTheme?.style,
    formFieldStyle,
  ]);

  // ─── Nested gap-style slots (pre-scaling — Gap self-scales) ──
  final labelInputGapStyle = CoreFormFieldStyle.defaultLabelInputGapStyle.merge(
    merged.labelInputGapStyle,
  );
  // ─── Nested FormLabel slot (raw-forward) ─────────────
  // The composed `FormLabel` owns the label + required-`*` chrome and
  // fills its own defaults; FormField only overlays its disabled-state
  // divergence (muted label colour) before forwarding.
  final formLabelStyle = enabled
      ? merged.formLabelStyle
      : CoreFormFieldStyle.defaultDisabledFormLabelStyle
            .merge(merged.disabledFormLabelStyle)
            .merge(merged.formLabelStyle);

  // ─── Paint-ready typography ───────────────────────────
  // Nested ValidatorHint slot (raw-forward) — historic bodySmall role
  // partial merged with the per-instance override; the ValidatorHint's
  // own resolver fills the error-type accent and the rest.
  final validatorHintStyle = CoreFormFieldStyle.defaultErrorValidatorHintStyle
      .merge(merged.errorValidatorHintStyle)
      .merge(merged.validatorHintStyle);
  final descriptionTextStyle = CoreFormFieldStyle.defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);
  final labelActionGapStyle = CoreFormFieldStyle.defaultLabelActionGapStyle
      .merge(merged.labelActionGapStyle);
  final counterTextStyle = CoreFormFieldStyle.defaultCounterTextStyle
      .merge(merged.counterTextStyle)
      .toValue(theme: theme);
  final footerGapStyle = CoreFormFieldStyle.defaultFooterGapStyle.merge(
    merged.footerGapStyle,
  );

  return ResolvedFormField(
    labelInputGapStyle: labelInputGapStyle,
    formLabelStyle: formLabelStyle,
    validatorHintStyle: validatorHintStyle,
    descriptionTextStyle: descriptionTextStyle,
    labelActionGapStyle: labelActionGapStyle,
    counterTextStyle: counterTextStyle,
    footerGapStyle: footerGapStyle,
  );
}
