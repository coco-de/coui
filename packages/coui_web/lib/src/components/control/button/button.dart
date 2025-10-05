import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/types.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles, span;

/// Defines the valid HTML `type` attributes for a button element.
enum ButtonHtmlType {
  /// The button has no default behavior and does nothing when pressed by default.
  button('button'),

  /// The button resets all the controls to their initial values.
  reset('reset'),

  /// The button submits the form data to the server.
  submit('submit');

  const ButtonHtmlType(this.value);

  final String value;

  @override
  String toString() => value;
}

/// Button size variants matching coui_flutter API.
enum ButtonSize {
  /// Large button size.
  lg,

  /// Medium button size.
  md,

  /// Small button size.
  sm,

  /// Extra large button size.
  xl,

  /// Extra small button size.
  xs,
}

/// Button shape variants matching coui_flutter API.
enum ButtonShape {
  /// Circle button shape.
  circle,

  /// Rectangle button shape.
  rectangle,

  /// Square button shape.
  square,
}

/// Button density variants matching coui_flutter API.
enum ButtonDensity {
  /// Comfortable button density.
  comfortable,

  /// Compact button density.
  compact,

  /// Dense button density.
  dense,

  /// Normal button density.
  normal,
}

/// A clickable button component with coui_flutter-compatible API.
///
/// This component provides the same API surface as coui_flutter's Button,
/// but renders to HTML using DaisyUI classes for web applications.
class Button extends UiComponent {
  /// Creates a Button component with full customization.
  ///
  /// Parameters match coui_flutter's Button API:
  /// - [child]: Main content of the button (required)
  /// - [onPressed]: Primary action callback
  /// - [enabled]: Whether button responds to interactions (defaults to true)
  /// - [leading]: Widget displayed before the main content
  /// - [trailing]: Widget displayed after the main content
  /// - [size]: Button size (xs, sm, md, lg, xl)
  /// - [shape]: Button shape (rectangle, square, circle)
  /// - [density]: Button density (normal, comfortable, dense, compact)
  /// - [style]: Visual styling configuration (primary, secondary, outline, etc.)
  /// - [disableTransition]: Whether to disable state animations
  /// - [onHover]: Hover state change callback (mouseenter/mouseleave)
  /// - [onFocus]: Focus state change callback (focus/blur)
  /// - [wide]: Whether button should be wide
  /// - [block]: Whether button should be full width
  Button({
    required this.child,
    super.key,
    this.onPressed, // void Function()?
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    List<ButtonStyling>? style,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = style,
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: style,
       );

  /// Creates a primary button with prominent styling for main actions.
  Button.primary({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.primaryStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.primaryStyle],
       );

  /// Creates a secondary button with subtle styling.
  Button.secondary({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.secondaryStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.secondaryStyle],
       );

  /// Creates an outline button with bordered styling.
  Button.outline({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.outlineStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.outlineStyle],
       );

  /// Creates a ghost button with transparent background.
  Button.ghost({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.ghostStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.ghostStyle],
       );

  /// Creates a link button that looks like a hyperlink.
  Button.link({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.linkStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.linkStyle],
       );

  /// Creates a text button with minimal styling.
  Button.text({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [
         Button.ghostStyle,
       ], // DaisyUI doesn't have text variant, use ghost.
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.ghostStyle],
       );

  /// Creates a destructive button for dangerous actions.
  Button.destructive({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.density,
    this.htmlType,
    this.role,
    this.disableTransition = false,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _style = const [Button.errorStyle],
       super(
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: const [Button.errorStyle],
       );

  /// Main content of the button.
  final Component child;

  /// Primary action callback (Flutter-compatible API).
  final VoidCallback? onPressed;

  /// Whether button responds to interactions.
  final bool enabled;

  /// Widget displayed before the main content.
  final Component? leading;

  /// Widget displayed after the main content.
  final Component? trailing;

  /// Button size.
  final ButtonSize? size;

  /// Button shape.
  final ButtonShape? shape;

  /// Button density.
  final ButtonDensity? density;

  /// The HTML 'type' attribute for the button.
  final ButtonHtmlType? htmlType;

  /// The ARIA role for the component.
  final String? role;

  /// Whether to disable state animations.
  final bool disableTransition;

  /// Hover state change callback.
  final void Function(bool)? onHover;

  /// Focus state change callback.
  final void Function(bool)? onFocus;

  /// Whether button should be wide.
  final bool wide;

  /// Whether button should be full width.
  final bool block;

  // --- Static Button Style Modifiers ---.

  /// Primary button style. `btn-primary`.
  static const primaryStyle = ButtonStyle('btn-primary', type: StyleType.style);

  /// Secondary button style. `btn-secondary`.
  static const secondaryStyle = ButtonStyle(
    'btn-secondary',
    type: StyleType.style,
  );

  /// Accent button style. `btn-accent`.
  static const accentStyle = ButtonStyle('btn-accent', type: StyleType.style);

  /// Neutral button style. `btn-neutral`.
  static const neutralStyle = ButtonStyle('btn-neutral', type: StyleType.style);

  /// Info button style. `btn-info`.
  static const infoStyle = ButtonStyle('btn-info', type: StyleType.style);

  /// Success button style. `btn-success`.
  static const successStyle = ButtonStyle('btn-success', type: StyleType.style);

  /// Warning button style. `btn-warning`.
  static const warningStyle = ButtonStyle('btn-warning', type: StyleType.style);

  /// Error button style. `btn-error`.
  static const errorStyle = ButtonStyle('btn-error', type: StyleType.style);

  /// Outline button style. `btn-outline`.
  static const outlineStyle = ButtonStyle('btn-outline', type: StyleType.style);

  /// Dash button style. `btn-dash`.
  static const dashStyle = ButtonStyle('btn-dash', type: StyleType.style);

  /// Soft button style. `btn-soft`.
  static const softStyle = ButtonStyle('btn-soft', type: StyleType.style);

  /// Ghost button style. `btn-ghost`.
  static const ghostStyle = ButtonStyle('btn-ghost', type: StyleType.style);

  /// Link button style. `btn-link`.
  static const linkStyle = ButtonStyle('btn-link', type: StyleType.style);

  /// Active button state. `btn-active`.
  static const activeStyle = ButtonStyle('btn-active', type: StyleType.state);

  /// Disabled button state. `btn-disabled`.
  static const disabledStyle = ButtonStyle(
    'btn-disabled',
    type: StyleType.state,
  );

  // Size modifiers
  /// Extra small button size. `btn-xs`.
  static const xsStyle = ButtonStyle('btn-xs', type: StyleType.sizing);

  /// Small button size. `btn-sm`.
  static const smStyle = ButtonStyle('btn-sm', type: StyleType.sizing);

  /// Medium button size. `btn-md`.
  static const mdStyle = ButtonStyle('btn-md', type: StyleType.sizing);

  /// Large button size. `btn-lg`.
  static const lgStyle = ButtonStyle('btn-lg', type: StyleType.sizing);

  /// Extra large button size. `btn-xl`.
  static const xlStyle = ButtonStyle('btn-xl', type: StyleType.sizing);

  // Shape modifiers
  /// Wide button style. `btn-wide`.
  static const wideStyle = ButtonStyle('btn-wide', type: StyleType.additional);

  /// Block level button style. `btn-block`.
  static const blockStyle = ButtonStyle(
    'btn-block',
    type: StyleType.additional,
  );

  /// Square button shape. `btn-square`.
  static const squareStyle = ButtonStyle('btn-square', type: StyleType.form);

  /// Circle button shape. `btn-circle`.
  static const circleStyle = ButtonStyle('btn-circle', type: StyleType.form);

  /// Internal style list.
  final List<ButtonStyling>? _style;

  static const _buttonValue = 'button';
  static const _typeAttribute = 'type';
  static const _disabledValue = 'disabled';
  static const _tabindexAttribute = 'tabindex';
  static const _emptyValue = '';
  static const _tabindexDisabled = '-1';
  static const _trueValue = 'true';
  // ignore: unused_field - Used for aria attributes in future implementations
  static const _falseValue = 'false';
  static const _buttonBaseClass = 'btn';

  @override
  String get baseClass => _buttonBaseClass;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set the HTML 'type' attribute
    if (tag == _buttonValue) {
      attributes.add(_typeAttribute, (htmlType ?? ButtonHtmlType.button).value);
    }

    // Set the ARIA 'role' attribute
    final currentRole = role;
    if (currentRole != null) {
      attributes.addRole(currentRole);
    } else if (tag != _buttonValue) {
      attributes.addRole(_buttonValue);
    }

    // Handle disabled state
    if (!enabled) {
      attributes
        ..add(_disabledValue, _emptyValue)
        ..add(_tabindexAttribute, _tabindexDisabled)
        ..addAria(_disabledValue, _trueValue);
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
    UiMouseEventHandler? onPressed,
    bool? enabled,
    Component? leading,
    Component? trailing,
    ButtonSize? size,
    ButtonShape? shape,
    ButtonDensity? density,
    String? role,
    List<ButtonStyling>? style,
    String? tag,
    bool? disableTransition,
    void Function(bool)? onHover,
    void Function(bool)? onFocus,
    bool? wide,
    bool? block,
  }) {
    return Button(
      key: key ?? this.key,
      child: child ?? this.child,
      onPressed: onPressed ?? onClick ?? this.onPressed,
      enabled: enabled ?? this.enabled,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      density: density ?? this.density,
      style: style ?? _style,
      htmlType: htmlType ?? this.htmlType,
      role: role ?? this.role,
      disableTransition: disableTransition ?? this.disableTransition,
      onHover: onHover ?? this.onHover,
      onFocus: onFocus ?? this.onFocus,
      wide: wide ?? this.wide,
      block: block ?? this.block,
      attributes: attributes ?? userProvidedAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  // ignore: unused_element - Reserved for dynamic styling system
  List<ButtonStyling> get _buildStyles {
    final currentStyle = _style;
    final currentSize = size;
    final currentShape = shape;

    return [
      ...?currentStyle,
      if (!enabled) disabledStyle,
      if (currentSize != null) _getSizeStyle(currentSize),
      if (currentShape != null) _getShapeStyle(currentShape),
      if (wide) wideStyle,
      if (block) blockStyle,
    ];
  }

  static ButtonStyle _getSizeStyle(ButtonSize size) => switch (size) {
        ButtonSize.xs => xsStyle,
        ButtonSize.sm => smStyle,
        ButtonSize.md => mdStyle,
        ButtonSize.lg => lgStyle,
        ButtonSize.xl => xlStyle,
      };

  static ButtonStyle _getShapeStyle(ButtonShape shape) => switch (shape) {
        ButtonShape.rectangle => mdStyle, // Default shape, no specific class
        ButtonShape.square => squareStyle,
        ButtonShape.circle => circleStyle,
      };

  // ignore: unused_element - Reserved for icon button layout system
  Component get _contentWithLeadingTrailing {
    final currentLeading = leading;
    final currentTrailing = trailing;

    if (currentLeading == null && currentTrailing == null) {
      // ignore: match-getter-setter-field-names - Returns child when no leading/trailing
      return child;
    }

    // Build content with leading and trailing
    final content = [
      ?currentLeading,
      child,
      ?currentTrailing,
    ];

    return span(children: content);
  }
}
