/// Per-instance style for `FormField`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/form_label/form_label_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `FormField` should render.
///
/// `CoreFormFieldStyle` carries nested gap-style slots (gap between the
/// label / child / helper-error rows; gap between the label text and the
/// required indicator), the required-asterisk colour, plus the
/// label (enabled / disabled) / error / description nested
/// [CoreTextStyle] slots. Each typography slot carries both the role
/// token AND its colour in one field, so the override surface stays
/// single-fielded. Both gap slots forward straight to `Gap` widgets so
/// the receiving `Gap` owns its own scaling (Epic #2228 4-principle).
///
/// ```text
/// design system default
///   → CoreFormFieldTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.formFieldStyle                         // 인스턴스별
/// ```
@immutable
class CoreFormFieldStyle implements CoreStyle<CoreFormFieldStyle> {
  /// Creates a [CoreFormFieldStyle].
  const CoreFormFieldStyle({
    this.labelInputGapStyle,
    this.formLabelStyle,
    this.validatorHintStyle,
    this.descriptionTextStyle,
    this.disabledFormLabelStyle,
    this.errorValidatorHintStyle,
    this.labelActionGapStyle,
    this.counterTextStyle,
    this.footerGapStyle,
  });

  /// Default nested [CoreGapStyle] slot — `CoreGapStyle(size: 8)` — for
  /// the gap between a form field's label, child, and helper / error
  /// text. The whole nested [CoreGapStyle] slot is forwarded to the
  /// `Gap` widget that separates the rows. Per-instance override flows
  /// through [labelInputGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultLabelInputGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default `CoreFormFieldContract.size` — `md`, matching the
  /// composed `FormLabel`'s own `CoreFormLabelStyle.defaultSize`.
  static const CoreComponentSize defaultSize = CoreComponentSize.md;

  /// Disabled-state overlay for the composed `FormLabel` — the only
  /// label value FormField diverges on (muted `onSurfaceSubtle` label
  /// colour, one text tier below the enabled label's `onSurfaceVariant`).
  /// FormField does not hand `enabled` to the composed `FormLabel`, so
  /// this overlay is the whole of the disabled signal: with the enabled
  /// label at `onSurfaceVariant`, an overlay held at the same token
  /// would make a disabled label identical to an enabled one. It is the
  /// same tier `CoreTextFieldStyle.defaultLabelDisabledColor` states.
  /// Partial: everything else flows from the FormLabel's own
  /// defaults. The resolver selects it when the field is disabled and
  /// merges the per-instance [formLabelStyle] on top.
  ///
  /// Colour only, no typography role. The role is the composed
  /// `FormLabel`'s to pick from its own size ladder
  /// (`CoreFormLabelStyle.defaultsBySize`), and this overlay merges on
  /// top of that ladder rung — a role stated here would replace it, so a
  /// disabled `FormField(size: lg)` would fall back to the `md` rung the
  /// moment it went disabled (and every `lg` field inside a disabled
  /// `Fieldset` with it).
  static const CoreFormLabelStyle defaultDisabledFormLabelStyle =
      CoreFormLabelStyle(
        labelStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onSurfaceSubtle),
        ),
      );

  /// Divergent defaults for the composed error `ValidatorHint` — the
  /// FormField error message keeps the `bodySmall` role its description
  /// and counter read (the ValidatorHint's own default is `bodyXs`, the
  /// role a `TextField`'s helper reads). Partial: colour
  /// comes from the ValidatorHint's error-type accent, everything else
  /// from its own defaults. The resolver merges the per-instance
  /// [validatorHintStyle] on top.
  static const CoreValidatorHintStyle defaultErrorValidatorHintStyle =
      CoreValidatorHintStyle(
        messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      );

  /// Default description / helper text style — `bodySmall` slot, muted
  /// `onSurfaceVariant` colour.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Gap between the label and the action at the far end of its row.
  ///
  /// The row is `[label] … [action]` pushed apart, so this is the FLOOR
  /// on their separation, not their usual distance — it only shows on a
  /// field narrow enough that the two nearly meet.
  static const CoreGapStyle defaultLabelActionGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Gap between the footer's message and its counter.
  ///
  /// Same shape as [defaultLabelActionGapStyle] and for the same reason:
  /// the footer is `[message] … [counter]`, so this is the floor.
  static const CoreGapStyle defaultFooterGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// The counter's typography.
  ///
  /// The same role and tone as [defaultDescriptionTextStyle] — the two sit
  /// on one line, and a tally that outweighed the helper beside it would
  /// read as the more important of the two. It is the quieter fact.
  static const CoreTextStyle defaultCounterTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  // ── Chrome (nested gap-style slots) ──────────

  /// Nested [CoreGapStyle] slot for the gap between the form field's
  /// label, child, and helper / error text — forwarded straight to the
  /// `Gap` widget that separates the rows. `null` defers to
  /// [defaultLabelInputGapStyle].
  final CoreGapStyle? labelInputGapStyle;

  /// Nested [CoreFormLabelStyle] slot for the composed `FormLabel`
  /// (label text + required `*` indicator chrome). Raw-forwarded — the
  /// FormLabel's own resolver fills the defaults; only the
  /// disabled-state overlay ([defaultDisabledFormLabelStyle]) diverges.
  ///
  /// Carries no `defaultFormLabelStyle`, and that is what makes the
  /// enabled / disabled split work. Both resolvers read
  /// `enabled ? merged.formLabelStyle : defaultDisabledFormLabelStyle
  /// .merge(disabledFormLabelStyle).merge(formLabelStyle)`: the enabled arm
  /// forwards the raw nullable slot precisely so `FormLabel` supplies the
  /// un-muted label colour, and the *only* FormField-level divergence is
  /// the disabled overlay, which already has its own named default. A
  /// constant here would put a permanent FormField-level overlay on the
  /// enabled arm — a second copy of `CoreFormLabelStyle`'s own defaults
  /// (`style-contract.md`: the parent must not reach into the child's
  /// defaults), leaving the two states no longer distinguished by
  /// "child default vs muted overlay".
  final CoreFormLabelStyle? formLabelStyle;

  // ── Slot Styles (nested) ─────────────────────

  /// Nested [CoreValidatorHintStyle] slot for the composed
  /// `ValidatorHint` that renders the error message. Raw-forwarded on
  /// top of [defaultErrorValidatorHintStyle] — the ValidatorHint's own
  /// resolver fills the rest (error-type accent colour, icon).
  ///
  /// Carries no `defaultValidatorHintStyle` because its baseline already
  /// exists on this class under the name of the state it belongs to:
  /// both resolvers chain `defaultErrorValidatorHintStyle
  /// .merge(errorValidatorHintStyle).merge(validatorHintStyle)`, so that
  /// partial IS this slot's default and is the one place FormField's
  /// `bodySmall` divergence from `ValidatorHint`'s own `labelMedium` is
  /// stated. A second constant under this field's name would be either a
  /// duplicate of it or a rival base under it — two identities for one
  /// decision, and the chain would then have to pick a winner.
  final CoreValidatorHintStyle? validatorHintStyle;

  /// Description / helper text style (typography + colour). Merged with
  /// [defaultDescriptionTextStyle] by the resolver.
  final CoreTextStyle? descriptionTextStyle;

  /// Disabled-state overlay override for the composed `FormLabel`.
  /// Merged on top of [defaultDisabledFormLabelStyle]; the per-instance
  /// [formLabelStyle] then layers on top of the result.
  final CoreFormLabelStyle? disabledFormLabelStyle;

  /// Error-state overlay override for the composed error `ValidatorHint`.
  /// Merged on top of [defaultErrorValidatorHintStyle]; the per-instance
  /// [validatorHintStyle] then layers on top of the result.
  final CoreValidatorHintStyle? errorValidatorHintStyle;

  /// Nested [CoreGapStyle] slot for the label↔action gap. Merged on top
  /// of [defaultLabelActionGapStyle].
  final CoreGapStyle? labelActionGapStyle;

  /// Counter text style (typography + colour). Merged with
  /// [defaultCounterTextStyle] by the resolver.
  final CoreTextStyle? counterTextStyle;

  /// Nested [CoreGapStyle] slot for the footer's message↔counter gap.
  /// Merged on top of [defaultFooterGapStyle].
  final CoreGapStyle? footerGapStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreFormFieldStyle merge(CoreFormFieldStyle? other) {
    if (other == null) return this;
    return CoreFormFieldStyle(
      labelInputGapStyle: _mergeGap(
        labelInputGapStyle,
        other.labelInputGapStyle,
      ),
      formLabelStyle:
          formLabelStyle?.merge(other.formLabelStyle) ?? other.formLabelStyle,
      validatorHintStyle:
          validatorHintStyle?.merge(other.validatorHintStyle) ??
          other.validatorHintStyle,
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
      disabledFormLabelStyle:
          disabledFormLabelStyle?.merge(other.disabledFormLabelStyle) ??
          other.disabledFormLabelStyle,
      errorValidatorHintStyle:
          errorValidatorHintStyle?.merge(other.errorValidatorHintStyle) ??
          other.errorValidatorHintStyle,
      labelActionGapStyle: _mergeGap(
        labelActionGapStyle,
        other.labelActionGapStyle,
      ),
      counterTextStyle: _mergeText(counterTextStyle, other.counterTextStyle),
      footerGapStyle: _mergeGap(footerGapStyle, other.footerGapStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFormFieldStyle copyWith({
    CoreGapStyle? labelInputGapStyle,
    CoreFormLabelStyle? formLabelStyle,
    CoreValidatorHintStyle? validatorHintStyle,
    CoreTextStyle? descriptionTextStyle,
    CoreFormLabelStyle? disabledFormLabelStyle,
    CoreValidatorHintStyle? errorValidatorHintStyle,
    CoreGapStyle? labelActionGapStyle,
    CoreTextStyle? counterTextStyle,
    CoreGapStyle? footerGapStyle,
  }) {
    return CoreFormFieldStyle(
      labelInputGapStyle: labelInputGapStyle ?? this.labelInputGapStyle,
      formLabelStyle: formLabelStyle ?? this.formLabelStyle,
      validatorHintStyle: validatorHintStyle ?? this.validatorHintStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      disabledFormLabelStyle:
          disabledFormLabelStyle ?? this.disabledFormLabelStyle,
      errorValidatorHintStyle:
          errorValidatorHintStyle ?? this.errorValidatorHintStyle,
      labelActionGapStyle: labelActionGapStyle ?? this.labelActionGapStyle,
      counterTextStyle: counterTextStyle ?? this.counterTextStyle,
      footerGapStyle: footerGapStyle ?? this.footerGapStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormFieldStyle &&
          runtimeType == other.runtimeType &&
          labelInputGapStyle == other.labelInputGapStyle &&
          formLabelStyle == other.formLabelStyle &&
          validatorHintStyle == other.validatorHintStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          disabledFormLabelStyle == other.disabledFormLabelStyle &&
          errorValidatorHintStyle == other.errorValidatorHintStyle &&
          labelActionGapStyle == other.labelActionGapStyle &&
          counterTextStyle == other.counterTextStyle &&
          footerGapStyle == other.footerGapStyle;

  @override
  int get hashCode => Object.hash(
    labelInputGapStyle,
    formLabelStyle,
    validatorHintStyle,
    descriptionTextStyle,
    disabledFormLabelStyle,
    errorValidatorHintStyle,
    labelActionGapStyle,
    counterTextStyle,
    footerGapStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
