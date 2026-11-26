import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedNumberInput
// ═══════════════════════════════════════════════════

/// Resolver output for `NumberInput`.
///
/// Every chrome / dimensional / nested-slot override has been merged
/// through:
///
/// ```text
/// design system default for the size
///   → theme.coreComponentTheme.numberInput.style
///   → theme.coreComponentTheme.numberInput.variantStyles[variant]
///   → widget.numberInputStyle
/// ```
///
/// Widget tree:
///
/// ```text
/// SizedBox(width)
///   └─ TextField (fieldStyle · centred value · label · description)
///        ├─ prefix: Button(plain · square · size.toStepButtonSize()) — minus
///        └─ suffix: Button(plain · square · size.toStepButtonSize()) — plus
/// ```
///
/// The field is a composed `TextField` and the ends are composed `Button`s,
/// so almost nothing here is NumberInput's own: [fieldStyle] and
/// [buttonStyle] are raw-forwarded and each child resolver fills its own
/// ladder. What NumberInput settles is the field's [width].
///
/// surface:content — draws no box of its own; the composed `TextField` draws
/// it.
class ResolvedNumberInput {
  /// Creates a [ResolvedNumberInput].
  const ResolvedNumberInput({
    required this.width,
    required this.buttonStyle,
    required this.fieldStyle,
  });

  /// The whole field's width, border to border (logical px,
  /// scaling-applied).
  final double width;

  /// Nested button style — forwarded to both step [Button]s.
  final CoreButtonStyle buttonStyle;

  /// Nested field style — forwarded to the composed [TextField].
  final CoreTextFieldStyle fieldStyle;
}

// ═══════════════════════════════════════════════════
// resolveNumberInput — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNumberInput] for the given [context].
ResolvedNumberInput resolveNumberInput(
  BuildContext context, {
  required CoreNumberInputSize size,
  required CoreNumberInputVariant variant,
  CoreNumberInputStyle? numberInputStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final inputTheme = theme.coreComponentTheme?.numberInput;

  final merged = resolveStyleChain(const CoreNumberInputStyle(), [
    inputTheme?.style,
    inputTheme?.variantStyles?[variant],
    numberInputStyle,
  ]);
  final sizeRow = CoreNumberInputStyle.defaultsBySize[size]!;

  // Stage1 RESOLVE
  final widthCore = merged.width ?? sizeRow.width!;
  final buttonStyle = CoreNumberInputStyle.defaultButtonStyle.merge(
    merged.buttonStyle,
  );
  final fieldStyle = CoreNumberInputStyle.defaultFieldStyle.merge(
    merged.fieldStyle,
  );

  // Stage2 EMIT
  final width = widthCore * scaling;

  return ResolvedNumberInput(
    width: width,
    buttonStyle: buttonStyle,
    fieldStyle: fieldStyle,
  );
}
