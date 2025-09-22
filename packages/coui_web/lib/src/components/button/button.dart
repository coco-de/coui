import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/button/button_style.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles;

/// Defines the valid HTML `type` attributes for a button element.
enum ButtonHtmlType {
  /// The button has no default behavior and does nothing when pressed by default.
  /// It can have client-side scripts listen to the element's events.
  /// This is the default if the `tag` is `<button>` and no `htmlType` is provided.
  button('button'),

  /// The button resets all the controls to their initial values.
  reset('reset'),

  /// The button submits the form data to the server. This is the default if the
  /// attribute is not specified for buttons associated with a `<form>`,
  /// or if the attribute is an empty or invalid value.
  submit('submit');

  const ButtonHtmlType(this.value);

  final String value;

  @override
  String toString() => value;
}

/// A clickable button component, used for actions in forms, dialogs, and more.
///
/// It can be rendered using different HTML tags (defaulting to `<button>`) and
/// styled with a variety of modifiers for color, size, shape, and state.
class Button extends UiComponent {
  /// Creates a Button component.
  ///
  /// - [children] or [child]: The content of the button (e.g., text, an icon).
  /// - [tag]: The HTML tag to use for the button, defaults to 'button'.
  /// - [htmlType]: The HTML 'type' attribute (e.g., submit, reset, button).
  ///   Relevant if `tag` is 'button'.
  /// - [role]: The ARIA role. Defaults to 'button' if `tag` is not '<button>' or
  ///   if a more specific button-like role (e.g., 'menuitem') is not provided.
  /// - [style]: A list of [ButtonStyling] (the interface) instances.
  /// - Other parameters are inherited from [UiComponent].
  const Button(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    this.htmlType,
    super.id,
    super.key,
    super.onClick,
    this.role,
    List<ButtonStyling>? style,
    super.tag = _buttonValue,
  }) : super(style: style);

  /// The HTML 'type' attribute for the button.
  /// If the [tag] is 'button' and [htmlType] is null, it defaults to `ButtonHtmlType.button`.
  final ButtonHtmlType? htmlType;

  /// The ARIA role for the component.
  final String? role;

  // --- Static Button Modifiers ---.

  /// Neutral button style. `btn-neutral`.
  static const neutral = ButtonStyle('btn-neutral', type: StyleType.style);

  /// Primary button style. `btn-primary`.
  static const primary = ButtonStyle('btn-primary', type: StyleType.style);

  /// Secondary button style. `btn-secondary`.
  static const secondary = ButtonStyle(
    'btn-secondary',
    type: StyleType.style,
  );

  /// Accent button style. `btn-accent`.
  static const accent = ButtonStyle('btn-accent', type: StyleType.style);

  /// Info button style. `btn-info`.
  static const info = ButtonStyle('btn-info', type: StyleType.style);

  /// Success button style. `btn-success`.
  static const success = ButtonStyle('btn-success', type: StyleType.style);

  /// Warning button style. `btn-warning`.
  static const warning = ButtonStyle('btn-warning', type: StyleType.style);

  /// Error button style. `btn-error`.
  static const error = ButtonStyle('btn-error', type: StyleType.style);

  // Styles
  /// Outline button style. `btn-outline`.
  static const outline = ButtonStyle(
    'btn-outline',
    type: StyleType.style,
  ); // Was .border

  /// Dash button style. `btn-dash` (New in DaisyUI 5).
  static const dash = ButtonStyle('btn-dash', type: StyleType.style);

  /// Soft button style. `btn-soft` (New in DaisyUI 5).
  static const soft = ButtonStyle('btn-soft', type: StyleType.style);

  /// Ghost button style (transparent background). `btn-ghost`.
  static const ghost = ButtonStyle('btn-ghost', type: StyleType.style);

  /// Link button style (looks like a hyperlink). `btn-link`.
  static const link = ButtonStyle('btn-link', type: StyleType.style);

  // Behavior modifiers
  /// Active button state (appears pressed). `btn-active`.
  static const active = ButtonStyle('btn-active', type: StyleType.state);

  /// Disabled button state (styles the button as disabled). `btn-disabled`
  /// The HTML 'disabled' attribute and ARIA attributes will also be managed by `configureAttributes`.
  static const disabled = ButtonStyle('btn-disabled', type: StyleType.state);

  // Size modifiers
  /// Extra small button size. `btn-xs`.
  static const xs = ButtonStyle('btn-xs', type: StyleType.sizing);

  /// Small button size. `btn-sm`.
  static const sm = ButtonStyle('btn-sm', type: StyleType.sizing);

  /// Medium button size (default). `btn-md`.
  static const md = ButtonStyle('btn-md', type: StyleType.sizing);

  /// Large button size. `btn-lg`.
  static const lg = ButtonStyle('btn-lg', type: StyleType.sizing);

  /// Extra large button size. `btn-xl` (New in DaisyUI 5).
  static const xl = ButtonStyle('btn-xl', type: StyleType.sizing);

  // General modifiers
  /// Wide button style (takes more horizontal space). `btn-wide`.
  static const wide = ButtonStyle('btn-wide', type: StyleType.additional);

  /// Block level button style (takes full width of its parent). `btn-block`.
  static const block = ButtonStyle('btn-block', type: StyleType.additional);

  /// Square button shape. `btn-square`.
  static const square = ButtonStyle('btn-square', type: StyleType.form);

  /// Circle button shape. `btn-circle`.
  static const circle = ButtonStyle(
    'btn-circle',
    type: StyleType.form,
  ); // HTML attribute constants
  static const _typeAttribute = 'type';
  static const _buttonValue = 'button';
  static const _inputTag = 'input';
  static const _disabledValue = 'disabled';
  static const _tabindexAttribute = 'tabindex';
  static const _emptyValue = '';
  static const _tabindexDisabled = '-1';
  static const _trueValue = 'true';
  static const _falseValue = 'false';

  static const _buttonBaseClass = 'btn';

  @override
  String get baseClass => _buttonBaseClass;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // 1. Set the HTML 'type' attribute
    if (tag == _buttonValue) {
      attributes.add(_typeAttribute, (htmlType ?? ButtonHtmlType.button).value);
    } else {
      final htmlTypeValue = htmlType;
      if (htmlTypeValue != null) {
        // Allow type for other tags if specified, though less common for
        // non-button tags.
        attributes.add(_typeAttribute, htmlTypeValue.value);
      }
    }

    // 2. Set the ARIA 'role' attribute
    final roleValue = role;
    if (roleValue != null) {
      attributes.addRole(roleValue);
    } else if (tag != _buttonValue && tag != _inputTag) {
      // Inputs have implicit roles
      // Add role="button" if it's an anchor or div styled as a button
      attributes.addRole(_buttonValue);
    }

    // 3. Handle disabled state:
    //    - If user provides 'disabled' in attributes, it takes precedence.
    //    - If `ButtonStyleModifier.disabled` is present, set HTML 'disabled' attribute
    //      and ARIA attributes for class-based disabling.
    final isDisabledByAttribute = userProvidedAttributes.containsKey(
      _disabledValue,
    );
    final isDisabledByStyle =
        style?.any(
          (styling) =>
              styling is ButtonStyling &&
              styling.cssClass == Button.disabled.cssClass,
        ) ??
        false;

    if (isDisabledByStyle && !isDisabledByAttribute) {
      attributes
        ..add(_disabledValue, _emptyValue)
        ..add(_tabindexAttribute, _tabindexDisabled)
        ..addAria(_disabledValue, _trueValue);
    } else if (isDisabledByAttribute) {
      // If native 'disabled' attribute is set by user, ARIA roles might not be
      // strictly necessary as browsers handle it, but adding them doesn't hurt.
      if (userProvidedAttributes[_disabledValue] != _falseValue) {
        // Ensure it's not explicitly false
        attributes.addAria(_disabledValue, _trueValue);
      }
    }
  }

  @override
  Button copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    ButtonHtmlType? htmlType,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    String? role,
    List<ButtonStyling>? style,
    String? tag,
  }) {
    final currentStyle = this.style;
    final buttonStyle = currentStyle is List<ButtonStyling>?
        ? currentStyle
        : null;

    return Button(
      children, // or this.child
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      htmlType: htmlType ?? this.htmlType,
      id: id ?? this.id,
      onClick: onClick ?? this.onClick,
      role: role ?? this.role,
      style: style ?? buttonStyle,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}
