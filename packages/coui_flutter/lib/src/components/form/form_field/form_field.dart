import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';

/// Unified cross-platform form field wrapper with label, error, and description.
///
/// Renders a vertical layout containing an optional label row (with required
/// indicator), the main [child] widget, and either [description] or [error]
/// text below.
///
/// When wrapped in a [Form] that has a [FormController], `FormField` becomes
/// the per-field orchestration entry: it owns a [FormKey], registers the
/// child's value + [validator] with the controller, and surfaces the
/// controller's validation result automatically (so the displayed error is
/// the live validation message). The child input (any widget mixing in
/// `FormValueSupplier`, e.g. `Checkbox` / `Toggle` / `RadioGroup` /
/// `TextField`) reports its value to this field via the inherited
/// [FormFieldHandle] — no per-field wiring needed by the caller.
///
/// Gap spacing resolves through the nested [CoreGapStyle] slots on
/// [CoreFormFieldStyle] (`labelInputGapStyle`, `requiredIndicatorGapStyle`),
/// which forward straight to the inner `Gap` widgets. `Gap` runs its
/// own resolve step so scaling stays owned by the receiving widget.
///
/// Example:
/// ```dart
/// final controller = FormController();
/// Form(
///   controller: controller,
///   children: [
///     FormField(
///       label: 'Plan',
///       required: true,
///       validator: const RequiredValidator<String>(),
///       child: RadioGroup<String>(value: plan, onChanged: setPlan, items: [...]),
///     ),
///     Button(
///       onPressed: () => controller.revalidate(
///         CoUIValidationContext(context),
///         FormValidationMode.submitted,
///       ),
///       child: const Text('Submit'),
///     ),
///   ],
/// )
/// ```
class FormField extends StatefulWidget
    implements CoreFormFieldContract<Widget> {
  /// Creates a [FormField].
  const FormField({
    super.key,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.labelWidget,
    this.labelAction,
    this.error,
    this.description,
    this.counterText,
    this.required = false,
    this.enabled = true,
    this.size = CoreFormFieldStyle.defaultSize,
    this.child,
    this.validator,
    this.formKey,
    this.formFieldStyle,
  });

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final Widget? labelWidget;

  @override
  final Widget? labelAction;

  @override
  final Widget? child;

  @override
  final String? error;

  @override
  final String? description;

  @override
  final String? counterText;

  @override
  final bool required;

  @override
  final bool enabled;

  @override
  final CoreComponentSize size;

  /// Validator applied to the child input's value. When the field is inside
  /// a [Form] with a [FormController], the validator runs on the configured
  /// [FormValidationMode] and its message is displayed as the field error.
  /// Null disables per-field validation.
  final Validator<dynamic>? validator;

  /// Stable identity for this field within the [FormController]. Lets the
  /// caller read `controller.getValue(formKey)` and enables cross-field
  /// validation (`shouldRevalidate`). Auto-generated (unique per field
  /// instance) when omitted.
  final FormKey<dynamic>? formKey;

  @override
  final CoreFormFieldStyle? formFieldStyle;

  /// Returns a copy of this [FormField] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FormField copyWith({
    Key? key,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    Widget? labelWidget,
    Widget? labelAction,
    String? error,
    String? description,
    String? counterText,
    bool? required,
    bool? enabled,
    CoreComponentSize? size,
    Validator<dynamic>? validator,
    FormKey<dynamic>? formKey,
    CoreFormFieldStyle? formFieldStyle,
    Widget? child,
  }) {
    return FormField(
      key: key ?? this.key,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      labelWidget: labelWidget ?? this.labelWidget,
      labelAction: labelAction ?? this.labelAction,
      error: error ?? this.error,
      description: description ?? this.description,
      counterText: counterText ?? this.counterText,
      required: required ?? this.required,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      validator: validator ?? this.validator,
      formKey: formKey ?? this.formKey,
      formFieldStyle: formFieldStyle ?? this.formFieldStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<FormField> with FormFieldHandle {
  late FormKey<dynamic> _formKey;
  final ValueNotifier<ValidationResult?> _validity = ValueNotifier(null);
  FormController? _controller;
  Object? _lastValue;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? FormKey<Object?>(Object());
  }

  // Syncs the displayed validity from the controller. Updates the
  // [_validity] notifier only — the error section rebuilds reactively via a
  // `ValueListenableBuilder`, so no `setState` is needed (safe to call from
  // `didChangeDependencies`).
  void _handleControllerChanged() {
    _validity.value = _controller?.getSyncError(_formKey);
  }

  Widget _buildLabel(ResolvedFormField resolved) {
    final formLabel = FormLabel(
      label:
          widget.labelWidget ??
          Text(
            widget.label!,
            maxLines: widget.labelMaxLines,
            overflow: widget.labelOverflow?.toValue(),
          ),
      isRequired: widget.required,
      size: widget.size,
      formLabelStyle: resolved.formLabelStyle,
    );
    final action = widget.labelAction;
    if (action == null) return formLabel;
    // Pushed to the far ends, with the gap as the FLOOR on their
    // separation rather than their usual distance — `spaceBetween` gives
    // them the row, and the `Gap` only shows on a field narrow enough
    // that the two nearly meet.
    //
    // `Flexible` on the label, not the action: when the row does run out,
    // it is the label that should wrap. An affordance clipped to "Forgot
    // pass…" is worse than a label on two lines, and the action is the
    // shorter of the two in every case this is reached for.
    return Row(
      mainAxisSize: .min,
      mainAxisAlignment: .spaceBetween,
      crossAxisAlignment: .center,
      children: [
        Flexible(child: formLabel),
        Gap(gapStyle: resolved.labelActionGapStyle),
        action,
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Data.maybeOf<FormController>(context);
    if (controller != _controller) {
      _controller?.removeListener(_handleControllerChanged);
      _controller = controller;
      _controller?.addListener(_handleControllerChanged);
      _handleControllerChanged();
    }
  }

  @override
  void didUpdateWidget(covariant FormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formKey != null && widget.formKey != _formKey) {
      _formKey = widget.formKey!;
    }
  }

  @override
  FormKey<dynamic> get formKey => _formKey;

  @override
  ValueListenable<ValidationResult?> get validity => _validity;

  @override
  FutureOr<ValidationResult?> reportNewFormValue<T>(T? value) {
    _lastValue = value;
    return _controller?.attach(
      CoUIValidationContext(context),
      this,
      value,
      widget.validator,
    );
  }

  @override
  FutureOr<ValidationResult?> revalidate() {
    return _controller?.attach(
      CoUIValidationContext(context),
      this,
      _lastValue,
      widget.validator,
      forceRevalidate: true,
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    _validity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // An enclosing `Fieldset(enabled: false)` always wins over this
    // field's own `enabled: true` (HTML `<fieldset disabled>`
    // semantics) — `Fieldset` is the only publisher above a `FormField`
    // today, but any ambient `CoreFormFieldScope` combines the same way.
    final ambientScope = FormFieldScope.maybeOf(context);
    final effectiveEnabled = widget.enabled && ambientScope?.disabled != true;

    final resolved = resolveFormField(
      context,
      enabled: effectiveEnabled,
      formFieldStyle: widget.formFieldStyle,
    );

    final labelInputGapStyle = resolved.labelInputGapStyle;
    final hasLabel = widget.label != null || widget.labelWidget != null;
    final child = widget.child;

    Widget column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (hasLabel) ...[
          _buildLabel(resolved),
          Gap(gapStyle: labelInputGapStyle),
        ],
        // The child input reaches this field's [FormFieldHandle] (value
        // reporting + validation) through the inherited `Data`, and this
        // field's own disabled / error state through [FormFieldScope] —
        // the same live-validation message the footer below shows is
        // what the child's chrome reacts to, so this re-reads `_validity`
        // in its own `ValueListenableBuilder` rather than the field
        // snapshot the outer `build()` closed over (`_validity` changes
        // do not call `setState` — only listenables rebuild).
        if (child != null)
          ValueListenableBuilder<ValidationResult?>(
            valueListenable: _validity,
            builder: (context, validity, staticChild) {
              final error = validity is InvalidResult
                  ? validity.message
                  : widget.error;
              final childScope = CoreFormFieldScope(
                disabled: !effectiveEnabled,
                hasError: error != null,
              );
              return Data<FormFieldHandle>.inherit(
                data: this,
                child: FormFieldScope(scope: childScope, child: staticChild!),
              );
            },
            child: child,
          ),
        // Error (live validation message > manual `error`) / description
        // react to the controller via the validity notifier — no setState.
        ValueListenableBuilder<ValidationResult?>(
          valueListenable: _validity,
          builder: (context, validity, _) {
            final error = validity is InvalidResult
                ? validity.message
                : widget.error;
            final hasError = error != null;
            final hasDescription = widget.description != null && !hasError;
            final counter = widget.counterText;
            // The counter holds the row open on its own. A length-capped
            // field with nothing else to say still shows `0 / 20`, and
            // collapsing on "no message" would take it with them.
            if (!hasError && !hasDescription && counter == null) {
              return const SizedBox.shrink();
            }
            final message = hasError
                // Composed unified ValidatorHint — the severity icon +
                // message chrome are its responsibility; FormField
                // raw-forwards the nested validatorHintStyle slot.
                ? ValidatorHint.error(
                    message: Text(error),
                    validatorHintStyle: resolved.validatorHintStyle,
                  )
                : hasDescription
                ? Text(
                    widget.description!,
                    style: resolved.descriptionTextStyle,
                  )
                : null;
            return Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                Gap(gapStyle: labelInputGapStyle),
                if (counter == null)
                  message!
                else
                  // Same shape as the label row above, and the same
                  // reason for `Flexible` being on the message: the
                  // counter is the short, fixed-width half, so a narrow
                  // field should wrap the sentence rather than clip the
                  // tally.
                  //
                  // `message` may be absent while the counter is not —
                  // `spaceBetween` would then park a lone counter on the
                  // LEFT, where it reads as the helper line. The empty
                  // box keeps it at the end it belongs to.
                  Row(
                    mainAxisSize: .min,
                    mainAxisAlignment: .spaceBetween,
                    crossAxisAlignment: .start,
                    children: [
                      Flexible(child: message ?? const SizedBox.shrink()),
                      Gap(gapStyle: resolved.footerGapStyle),
                      Text(counter, style: resolved.counterTextStyle),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );

    // Disable pointer interactions for the whole field when disabled —
    // combining the ambient scope, so an enclosing `Fieldset(enabled:
    // false)` blocks pointer interaction on this field too, not just
    // its own. Visual disabled state is expressed via color tokens
    // (onSurfaceSubtle), not via Opacity wrapper (cautions).
    if (!effectiveEnabled) {
      column = IgnorePointer(child: column);
    }

    // The label, the description and the error were siblings in a column
    // with nothing joining them — what a sighted user reads as one field
    // a screen reader read as three unrelated things, and a validation
    // message that appeared after submit was announced by nobody.
    //
    // Grouped and described here rather than on the input, because the
    // input is the caller's own widget and this cannot reach inside it.
    // The Web twin states the same thing as `role="group"` with
    // `aria-labelledby` / `aria-describedby`.
    //
    // Driven by the validity notifier with the column passed through, so
    // the description switching to an error updates what is announced
    // without rebuilding the field. Read in the outer build instead and
    // the hint would be the message at first paint, forever.
    //
    // `enabled` is the other half: disabling only blocked the pointer, so
    // a disabled field announced as an ordinary one that silently did
    // nothing.
    return ValueListenableBuilder<ValidationResult?>(
      valueListenable: _validity,
      builder: (context, validity, child) {
        final error = validity is InvalidResult
            ? validity.message
            : widget.error;

        return Semantics(
          container: true,
          enabled: effectiveEnabled,
          label: widget.label,
          hint: error ?? widget.description,
          child: child!,
        );
      },
      child: column,
    );
  }
}

/// Chain sugar for merging a [CoreFormFieldStyle] patch into
/// [FormField.formFieldStyle] without hand-reconstructing every field.
/// Mirrors the Web `FormField.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFormFieldStyle.merge` right-side-wins semantics).
extension FormFieldStyleChain on FormField {
  /// Returns a copy of this [FormField] with [patch] merged into
  /// [formFieldStyle] (patch fields win on conflict).
  FormField withStyle(CoreFormFieldStyle patch) => copyWith(
    formFieldStyle: (formFieldStyle ?? const CoreFormFieldStyle()).merge(patch),
  );
}
