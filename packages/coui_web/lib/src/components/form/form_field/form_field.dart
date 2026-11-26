import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/form_field/form_field_scope.dart';
import 'package:coui_web/src/components/form/form_field/form_field_style.dart';
import 'package:coui_web/src/components/form/form_label/form_label.dart';
import 'package:coui_web/src/components/form/validator_hint/validator_hint.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;

int _coFormFieldScopeCounter = 0;

/// A unified form field wrapper with label, error, and description.
///
/// Renders an optional label row (with required indicator), the main [child]
/// input, and either [description] or [error] text below.
///
/// When wrapped in a `Form` that has a [FormController], `FormField` becomes
/// the per-field orchestration entry: it owns a [FormKey], registers the
/// child's value + [validator] with the controller, and surfaces the
/// controller's validation result automatically (so the displayed error is
/// the live validation message). The child input (any component mixing in
/// `FormValueSupplier`) reports its value to this field via the inherited
/// [FormFieldHandleScope] — no per-field wiring needed by the caller.
///
/// Gap spacing flows through the nested [CoreGapStyle] slots on
/// [CoreFormFieldStyle] (`labelInputGapStyle`, `requiredIndicatorGapStyle`).
///
/// Example:
/// ```dart
/// final controller = FormController();
/// Form(
///   controller: controller,
///   children: [
///     FormField(
///       label: 'Email',
///       required: true,
///       validator: const RequiredValidator<String>(),
///       child: TextField(placeholder: Text('Enter email')),
///     ),
///   ],
/// )
/// ```
class FormField extends UiStatefulComponent
    implements CoreFormFieldContract<Component> {
  /// Creates a [FormField].
  const FormField({
    super.key,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.labelWidget,
    this.labelAction,
    this.child,
    this.error,
    this.description,
    this.counterText,
    this.required = false,
    this.enabled = true,
    this.size = CoreFormFieldStyle.defaultSize,
    this.validator,
    this.formKey,
    this.formFieldStyle,
    super.classes,
    super.css,
    super.id,
  });

  @override
  final Component? child;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final Component? labelWidget;

  @override
  final Component? labelAction;

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

  /// Validator applied to the child input's value. When the field is inside a
  /// `Form` with a [FormController], the validator runs on the configured
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
    Component? labelWidget,
    String? error,
    String? description,
    String? counterText,
    Component? labelAction,
    bool? required,
    bool? enabled,
    CoreComponentSize? size,
    Validator<dynamic>? validator,
    FormKey<dynamic>? formKey,
    CoreFormFieldStyle? formFieldStyle,
    String? classes,
    Styles? css,
    String? id,
    Component? child,
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
      classes: classes ?? this.classes,
      css: css ?? this.css,
      id: id ?? this.id,
      child: child ?? this.child,
    );
  }

  @override
  State<FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<FormField> implements CoreFormFieldHandle {
  late final String _scopeId;
  late FormKey<dynamic> _formKey;
  ValidationResult? _validity;
  FormController? _controller;
  Object? _lastValue;
  CouiLocalizations _localizations = DefaultCouiLocalizations.instance;

  @override
  void initState() {
    super.initState();
    _scopeId = '${kIsWeb ? 'web' : 'ssr'}-${_coFormFieldScopeCounter++}';
    // Not `const`: every field without its own key needs a distinct one, and
    // a canonical constant would hand the same key to all of them.
    // ignore: prefer_const_constructors
    _formKey = component.formKey ?? FormKey<Object?>(Object());
  }

  // Fires from the controller's (microtask-deferred) notification, so calling
  // setState here is safe — never during build.
  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final next = _controller?.getSyncError(_formKey);
    if (next != _validity) {
      setState(() => _validity = next);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = FormControllerScope.maybeOf(context);
    if (controller != _controller) {
      _controller?.removeListener(_handleControllerChanged);
      _controller = controller;
      _controller?.addListener(_handleControllerChanged);
      // Seed the initial validity directly — the build that follows
      // `didChangeDependencies` picks it up (no setState mid-build).
      _validity = _controller?.getSyncError(_formKey);
    }
    _localizations = CouiLocalizations.of(context);
  }

  @override
  void didUpdateComponent(covariant FormField oldComponent) {
    super.didUpdateComponent(oldComponent);
    final newKey = component.formKey;
    if (newKey != null && newKey != _formKey) {
      _formKey = newKey;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  FormKey<dynamic> get formKey => _formKey;

  @override
  FutureOr<ValidationResult?> reportNewFormValue<T>(T? value) {
    _lastValue = value;
    return _controller?.attach(
      CoUIWebValidationContext(
        localizations: _localizations,
        isActive: () => mounted,
      ),
      this,
      value,
      component.validator,
    );
  }

  @override
  FutureOr<ValidationResult?> revalidate() {
    return _controller?.attach(
      CoUIWebValidationContext(
        localizations: _localizations,
        isActive: () => mounted,
      ),
      this,
      _lastValue,
      component.validator,
      forceRevalidate: true,
    );
  }

  @override
  Component build(BuildContext context) {
    // An enclosing `Fieldset(enabled: false)` always wins over this
    // field's own `enabled: true` (HTML `<fieldset disabled>`
    // semantics) — `Fieldset` is the only publisher above a `FormField`
    // today, but any ambient `CoreFormFieldScope` combines the same way.
    final ambientScope = FormFieldScope.maybeOf(context);
    final effectiveEnabled =
        component.enabled && ambientScope?.disabled != true;

    final resolved = resolveFormField(
      context,
      enabled: effectiveEnabled,
      formFieldStyle: component.formFieldStyle,
    );

    final currentLabel = component.label;
    final currentLabelWidget = component.labelWidget;
    final currentChild = component.child;
    final currentDescription = component.description;
    final currentLabelAction = component.labelAction;
    final currentCounter = component.counterText;

    // Live validation message takes precedence over the manual `error` prop.
    final liveError = _validity is InvalidResult
        ? (_validity! as InvalidResult).message
        : null;
    final currentError = liveError ?? component.error;
    final childScope = CoreFormFieldScope(
      disabled: !effectiveEnabled,
      hasError: currentError != null,
    );

    final labelInputGap = Gap(gapStyle: resolved.labelInputGapStyle);

    final hasLabel = currentLabelWidget != null || currentLabel != null;

    // Ids so the group can point at its own parts. Nothing connected the
    // label, the description and the error to the input before this —
    // they were siblings in a div, which is what a sighted user reads as
    // one field and a screen reader reads as four unrelated things. A
    // submitted form's validation message in particular was announced by
    // nobody.
    //
    // Stated on the group rather than the input because the input is the
    // caller's own component: this cannot reach inside it to add an
    // attribute, and a `role="group"` that names and describes itself is
    // the pattern that does not require reaching.
    final labelId = 'co-field-label-$_scopeId';
    final describedById = currentError != null
        ? 'co-field-error-$_scopeId'
        : (currentDescription != null ? 'co-field-desc-$_scopeId' : null);

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        'role': 'group',
        // Only when this owns the label element. A caller-supplied
        // `labelWidget` has no id to point at, and pointing at one that
        // does not exist leaves the group unnamed while looking named.
        if (currentLabelWidget == null && currentLabel != null)
          'aria-labelledby': labelId,
        'aria-describedby': ?describedById,
        // Invalid and required are states of the field, not of its text.
        // Colour said both and said them to nobody else.
        if (currentError != null) 'aria-invalid': 'true',
        if (component.required) 'aria-required': 'true',
        if (!effectiveEnabled) 'aria-disabled': 'true',
        ...component.componentAttributes,
      },
      events: component.events,
      children: [
        // Label row — composed unified `FormLabel`: the label text +
        // required `*` chrome and their alignment are the FormLabel's
        // responsibility; FormField only raw-forwards its nested
        // `formLabelStyle` slot.
        // Pushed to the far ends when an action is present, with the gap
        // as the FLOOR on their separation rather than their usual
        // distance — `justify-between` gives them the row and the `Gap`
        // only shows on a field narrow enough that the two nearly meet.
        // The Flutter twin states the same thing with `spaceBetween`.
        //
        // Always a flex row, action or not: a plain block would hold the
        // inline `<label>` in a line box whose strut is the field's own body
        // line height (21px), so a 13px label with an 18.2px line would sit
        // in a 21px row and push the input 3px below where the Flutter twin
        // puts it. A flex item has no strut — the row is the label's own line.
        if (hasLabel)
          Component.element(
            tag: 'div',
            classes: currentLabelAction == null
                ? 'flex w-full flex-row items-center'
                : 'flex w-full flex-row items-center justify-between',
            children: [
              if (currentLabelWidget != null)
                currentLabelWidget
              else if (currentLabel != null)
                FormLabel(
                  label: Text(
                    currentLabel,
                    maxLines: component.labelMaxLines,
                    overflow: component.labelOverflow,
                  ),
                  isRequired: component.required,
                  size: component.size,
                  formLabelStyle: resolved.formLabelStyle,
                  id: labelId,
                ),
              if (currentLabelAction != null) ...[
                Gap(gapStyle: resolved.labelActionGapStyle),
                currentLabelAction,
              ],
            ],
          ),
        // Gap between label and child input.
        if (hasLabel) labelInputGap,
        // Child input — reaches this field's handle (value reporting +
        // validation) through the inherited [FormFieldHandleScope], and
        // this field's own disabled / error state through
        // [FormFieldScope].
        if (currentChild != null)
          FormFieldHandleScope(
            handle: this,
            child: FormFieldScope(scope: childScope, child: currentChild),
          ),
        // The footer — message (description OR error) on one end, the
        // counter on the other. The counter holds the row open on its
        // own: a length-capped field with nothing else to say still
        // shows `0 / 20`, and collapsing on "no message" would take it
        // with them. The Flutter twin makes the same call.
        if (currentDescription != null ||
            currentError != null ||
            currentCounter != null) ...[
          labelInputGap,
          Component.element(
            tag: 'div',
            classes: currentCounter == null
                ? null
                : 'flex w-full flex-row items-start justify-between',
            children: [
              // Description shows only when there is no error — the two
              // share this end of the row and the error outranks it.
              if (currentDescription != null && currentError == null)
                Component.element(
                  tag: 'p',
                  id: describedById,
                  classes: resolved.description.className,
                  styles: resolved.description.inlineStyles,
                  children: [Text(currentDescription)],
                )
              // Composed unified ValidatorHint: the severity icon +
              // message chrome are its responsibility; FormField
              // raw-forwards the nested validatorHintStyle slot.
              else if (currentError != null)
                ValidatorHint.error(
                  message: Text(currentError),
                  validatorHintStyle: resolved.validatorHintStyle,
                  id: describedById,
                )
              // A lone counter would otherwise sit at the START of the
              // row, where it reads as the helper line. The empty box
              // keeps `justify-between` pushing it to the end it belongs
              // to.
              else
                const Component.element(tag: 'span', children: []),
              if (currentCounter != null) ...[
                Gap(gapStyle: resolved.footerGapStyle),
                Component.element(
                  tag: 'span',
                  classes: resolved.counter.className,
                  styles: resolved.counter.inlineStyles,
                  children: [Text(currentCounter)],
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `FormField.withStyle` extension —
/// merges a [CoreFormFieldStyle] patch into [FormField.formFieldStyle] via
/// the existing [FormField.copyWith].
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
