/// Per-instance style for `Validated`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Per-state chrome — the ring colour applied around the wrapped child.
///
/// Immutable style describing how a `Validated` should render.
///
/// Carries the validation-ring border radius / width, the gap between
/// the wrapped child and the message, and an optional override ring
/// colour. Platform-neutral (Epic #1415 option D) — colour fields use
/// [CoreColor].
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth. The
/// invalid state itself is propagated to the wrapped field via an
/// ambient scope — the field applies its own error variant (border +
/// focus ring), so no ring chrome lives here.
@immutable
class CoreValidatedStyle implements CoreStyle<CoreValidatedStyle> {
  /// Creates a [CoreValidatedStyle].
  const CoreValidatedStyle({
    this.validatorHintStyle,
    this.fieldMessageGapStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Divergent defaults for the composed message `ValidatorHint` — the
  /// Validated message keeps the `bodySmall` role (matching the
  /// FormField error hint). Partial: colour comes from the
  /// ValidatorHint's per-type accent, everything else from its own
  /// defaults.
  static const CoreValidatorHintStyle defaultValidatorHintStyle =
      CoreValidatorHintStyle(
        messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      );

  /// Default gap between the wrapped child and the message — nested
  /// [CoreGapStyle] slot forwarded to the `Gap` widget that
  /// separates the field from the message. Per-instance override flows
  /// through [fieldMessageGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultFieldMessageGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Style of the `ValidatorHint` that shows the message under the field.
  /// Laid over [defaultValidatorHintStyle] and passed to it as is.
  final CoreValidatorHintStyle? validatorHintStyle;

  /// Gap between the wrapped child and the message, passed to the `Gap`
  /// that separates them. `null` defers to [defaultFieldMessageGapStyle].
  final CoreGapStyle? fieldMessageGapStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreValidatedStyle merge(CoreValidatedStyle? other) {
    if (other == null) return this;
    return CoreValidatedStyle(
      validatorHintStyle:
          validatorHintStyle?.merge(other.validatorHintStyle) ??
          other.validatorHintStyle,
      fieldMessageGapStyle: _mergeGapStyle(
        fieldMessageGapStyle,
        other.fieldMessageGapStyle,
      ),
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreValidatedStyle copyWith({
    CoreValidatorHintStyle? validatorHintStyle,
    CoreGapStyle? fieldMessageGapStyle,
  }) {
    return CoreValidatedStyle(
      validatorHintStyle: validatorHintStyle ?? this.validatorHintStyle,
      fieldMessageGapStyle: fieldMessageGapStyle ?? this.fieldMessageGapStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreValidatedStyle &&
          runtimeType == other.runtimeType &&
          validatorHintStyle == other.validatorHintStyle &&
          fieldMessageGapStyle == other.fieldMessageGapStyle;

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  @override
  int get hashCode => Object.hash(
    validatorHintStyle,
    fieldMessageGapStyle,
  );
}
