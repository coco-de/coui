import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/form/validator_hint/validator_hint_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A unified validation-hint message for form fields for CoUI Web.
///
/// `ValidatorHint` displays a validation message (error / warning /
/// info / success) below a form input, with a leading severity icon.
/// It is the unified replacement for the legacy Web and Flutter
/// `ValidatorHint` — same parameter names, same semantics, full visual
/// parity.
///
/// When [visible] is `false` the component renders nothing. The [type]
/// drives the per-type accent colour (applied to both the icon and the
/// message) and the default leading icon.
///
/// Every chrome / typography override flows through the single
/// [validatorHintStyle] field — see [CoreValidatorHintStyle] for the
/// merge chain.
///
/// Mirrors Flutter `ValidatorHint` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// ValidatorHint(message: Text('This field is required'))
/// ValidatorHint.success(message: Text('Looks good'))
/// ```
class ValidatorHint extends UiComponent
    implements CoreValidatorHintContract<Component> {
  /// Creates a [ValidatorHint].
  const ValidatorHint({
    this.message,
    this.type = CoreValidatorHintType.defaultType,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'p');

  /// Creates an error-type [ValidatorHint].
  const ValidatorHint.error({
    this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : type = CoreValidatorHintType.error,
       super(tag: 'p');

  /// Creates a warning-type [ValidatorHint].
  const ValidatorHint.warning({
    this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : type = CoreValidatorHintType.warning,
       super(tag: 'p');

  /// Creates an info-type [ValidatorHint].
  const ValidatorHint.info({
    this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : type = CoreValidatorHintType.info,
       super(tag: 'p');

  /// Creates a success-type [ValidatorHint].
  const ValidatorHint.success({
    this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : type = CoreValidatorHintType.success,
       super(tag: 'p');

  /// Creates a neutral-type [ValidatorHint] — a line with no severity,
  /// such as a checklist rule not yet met.
  const ValidatorHint.neutral({
    this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : type = CoreValidatorHintType.neutral,
       super(tag: 'p');

  @override
  final Component? message;

  @override
  final CoreValidatorHintType type;

  @override
  final bool visible;

  @override
  final Component? icon;

  @override
  final CoreValidatorHintStyle? validatorHintStyle;

  /// Announces the hint when it appears — `alert` for an error, `status`
  /// for the other reported tones, nothing for a neutral rule. Without it
  /// an error that appeared after submit reached a screen reader only if
  /// focus happened to move onto it; `aria-describedby` links the message
  /// to the field but announces nothing. Caller attributes still win.
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    final role = type.toSemanticRole();
    if (role != null) attributes.addRole(role.ariaRole);
  }

  @override
  Component build(BuildContext context) {
    if (!visible) {
      return const Component.fragment([]);
    }

    final resolved = resolveValidatorHint(
      context,
      type: type,
      validatorHintStyle: validatorHintStyle,
    );

    final defaultIcon = Icon(
      coValidatorHintDefaultIcon(type),
      iconStyle: resolved.iconStyle,
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: componentAttributes,
      events: events,
      children: [
        Component.element(
          tag: 'span',
          classes: resolved.icon.className,
          styles: resolved.icon.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
          children: [icon ?? defaultIcon],
        ),
        ?message,
      ],
    );
  }

  @override
  ValidatorHint copyWith({
    Component? message,
    CoreValidatorHintType? type,
    bool? visible,
    Component? icon,
    CoreValidatorHintStyle? validatorHintStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return ValidatorHint(
      key: key ?? this.key,
      message: message ?? this.message,
      type: type ?? this.type,
      visible: visible ?? this.visible,
      icon: icon ?? this.icon,
      validatorHintStyle: validatorHintStyle ?? this.validatorHintStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the Flutter `ValidatorHint.withStyle` extension
/// — merges a [CoreValidatorHintStyle] patch into
/// [ValidatorHint.validatorHintStyle] via the existing
/// [ValidatorHint.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreValidatorHintStyle.merge` right-side-wins semantics).
extension ValidatorHintStyleChain on ValidatorHint {
  /// Returns a copy of this [ValidatorHint] with [patch] merged into
  /// [validatorHintStyle] (patch fields win on conflict).
  ValidatorHint withStyle(CoreValidatorHintStyle patch) => copyWith(
    validatorHintStyle: (validatorHintStyle ?? const CoreValidatorHintStyle())
        .merge(patch),
  );
}
