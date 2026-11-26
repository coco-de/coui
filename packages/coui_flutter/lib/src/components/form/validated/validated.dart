import 'package:coui_flutter/coui_flutter.dart';

/// A unified validation wrapper for form fields.
///
/// `Validated` wraps a form field and visually indicates its
/// validation [state] through a coloured ring around the field, plus
/// an optional [message] rendered below it. It is the unified
/// presentational replacement for the legacy Web `Validated` and the
/// visual layer of the legacy Flutter `Validated<T>` — same parameter
/// names, same semantics, full visual parity.
///
/// When [state] is [CoreValidationState.pending] no ring is drawn and
/// the message is hidden; the `invalid` / `valid` states apply the
/// matching ring colour.
///
/// Every chrome / dimensional override flows through the single
/// [validatedStyle] field — see [CoreValidatedStyle] for the merge
/// chain.
///
/// Mirrors Web `Validated` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Validated(
///   state: CoreValidationState.invalid,
///   message: Text('This field is required.'),
///   child: TextField(placeholder: 'Enter value'),
/// )
/// ```
class Validated extends StatelessWidget
    implements CoreValidatedContract<Widget> {
  /// Creates a [Validated].
  const Validated({
    this.state = CoreValidationState.defaultState,
    this.message,
    this.child,
    this.validatedStyle,
    super.key,
  });

  @override
  final CoreValidationState state;

  @override
  final Widget? message;

  @override
  final Widget? child;

  @override
  final CoreValidatedStyle? validatedStyle;

  /// Returns a copy of this [Validated] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Validated copyWith({
    Key? key,
    CoreValidationState? state,
    Widget? message,
    CoreValidatedStyle? validatedStyle,
    Widget? child,
  }) {
    return Validated(
      key: key ?? this.key,
      state: state ?? this.state,
      message: message ?? this.message,
      validatedStyle: validatedStyle ?? this.validatedStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveValidated(
      context,
      validatedStyle: validatedStyle,
    );

    Widget? fieldWrapper;
    if (child != null) {
      // Propagate the validation state to the wrapped field via the
      // ambient Data scope — the field applies its own error variant
      // (border + focus ring switch to the error tone), so one ring
      // changes colour instead of a second ring stacking on top.
      fieldWrapper = Data.inherit(
        data: state,
        child: child!,
      );
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        ?fieldWrapper,
        if (message != null && state != .pending) ...[
          Gap(gapStyle: resolved.fieldMessageGapStyle),
          // Composed unified ValidatorHint — severity icon + message
          // chrome; the type follows the validation state.
          ValidatorHint(
            message: message,
            type: state == .invalid ? .error : .success,
            validatorHintStyle: resolved.validatorHintStyle,
          ),
        ],
      ],
    );
  }
}

/// Chain sugar for merging a [CoreValidatedStyle] patch into
/// [Validated.validatedStyle] without hand-reconstructing every field.
/// Mirrors the Web `Validated.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreValidatedStyle.merge` right-side-wins semantics).
extension ValidatedStyleChain on Validated {
  /// Returns a copy of this [Validated] with [patch] merged into
  /// [validatedStyle] (patch fields win on conflict).
  Validated withStyle(CoreValidatedStyle patch) => copyWith(
    validatedStyle: (validatedStyle ?? const CoreValidatedStyle()).merge(patch),
  );
}
