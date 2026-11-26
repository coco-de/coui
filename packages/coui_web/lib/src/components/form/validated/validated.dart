import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/form/validated/validated_style.dart';
import 'package:coui_web/src/components/form/validated/validation_state_scope.dart';
import 'package:coui_web/src/components/form/validator_hint/validator_hint.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A unified validation wrapper for form fields for CoUI Web.
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
/// Mirrors Flutter `Validated` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Validated(
///   state: CoreValidationState.invalid,
///   message: Text('This field is required.'),
///   child: TextField(placeholder: Text('Enter value')),
/// )
/// ```
class Validated extends UiComponent
    implements CoreValidatedContract<Component> {
  /// Creates a [Validated].
  const Validated({
    this.state = CoreValidationState.defaultState,
    this.message,
    this.child,
    this.validatedStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final CoreValidationState state;

  @override
  final Component? message;

  @override
  final CoreValidatedStyle? validatedStyle;
  @override
  Component build(BuildContext context) {
    final resolved = resolveValidated(
      context,
      validatedStyle: validatedStyle,
    );
    final currentChild = child;
    final currentMessage = message;

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
      children: [
        if (currentChild != null)
          // Propagate the validation state to the wrapped field via the
          // ambient scope — the field applies its own error variant
          // (border + focus ring switch to the error tone), so one ring
          // changes colour instead of a second ring stacking on top.
          ValidationStateScope(state: state, child: currentChild),
        if (currentMessage != null && state != .pending) ...[
          Gap(gapStyle: resolved.fieldMessageGapStyle),
          // Composed unified ValidatorHint — severity icon + message
          // chrome; the type follows the validation state.
          ValidatorHint(
            message: currentMessage,
            type: state == .invalid ? .error : .success,
            validatorHintStyle: resolved.validatorHintStyle,
          ),
        ],
      ],
    );
  }

  @override
  Validated copyWith({
    CoreValidationState? state,
    Component? message,
    Component? child,
    CoreValidatedStyle? validatedStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Validated(
      key: key ?? this.key,
      state: state ?? this.state,
      message: message ?? this.message,
      validatedStyle: validatedStyle ?? this.validatedStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `Validated.withStyle` extension —
/// merges a [CoreValidatedStyle] patch into [Validated.validatedStyle]
/// via the existing [Validated.copyWith].
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
