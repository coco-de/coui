import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:jaspr/jaspr.dart';

/// HTML button type attributes.
enum ButtonHtmlType {
  /// The button has no default behavior.
  button('button'),

  /// The button resets form controls.
  reset('reset'),

  /// The button submits form data.
  submit('submit');

  const ButtonHtmlType(this.value);

  final String value;

  @override
  String toString() => value;
}

/// Button size variants matching coui_flutter API.
enum CoButtonSize {
  /// Extra small button size.
  xs,

  /// Small button size.
  sm,

  /// Medium button size (default).
  md,

  /// Large button size.
  lg,

  /// Extra large button size.
  xl,
}

/// Button shape variants.
enum ButtonShape {
  /// Rectangle button shape (default).
  rectangle,

  /// Square button shape.
  square,

  /// Circle button shape.
  circle,
}

/// A clickable button component following shadcn-ui design patterns.
///
/// This component provides a Flutter-compatible API surface but renders
/// to HTML using Tailwind CSS utility classes for web applications.
///
/// Example:
/// ```dart
/// Button.primary(
///   child: text('Click me'),
///   onPressed: () => print('Clicked!'),
/// )
/// ```
class Button extends UiComponent {
  /// Creates a Button component with customization options.
  ///
  /// Parameters:
  /// - [child]: Main content of the button (required)
  /// - [onPressed]: Primary action callback
  /// - [enabled]: Whether button responds to interactions (defaults to true)
  /// - [leading]: Component displayed before the main content
  /// - [trailing]: Component displayed after the main content
  /// - [size]: Button size (xs, sm, md, lg, xl)
  /// - [shape]: Button shape (rectangle, square, circle)
  /// - [variant]: Button variant (primary, secondary, etc.)
  /// - [htmlType]: The HTML 'type' attribute
  /// - [role]: The ARIA role
  /// - [wide]: Whether button should be wide
  /// - [block]: Whether button should be full width
  Button({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    ButtonVariant? variant,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = variant ?? ButtonVariant.defaultVariant,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: variant == null
             ? null
             : [
                 ButtonVariantStyle(
                   variant: variant,
                   size: _mapSize(size),
                 ),
               ],
       );

  /// Creates a primary button.
  Button.primary({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.primary,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.primary,
             size: _mapSize(size),
           ),
         ],
       );

  /// Creates a secondary button.
  Button.secondary({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.secondary,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.secondary,
             size: _mapSize(size),
           ),
         ],
       );

  /// Creates an outline button.
  Button.outline({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.outline,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.outline,
             size: _mapSize(size),
           ),
         ],
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
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.ghost,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.ghost,
             size: _mapSize(size),
           ),
         ],
       );

  /// Creates a link button styled as hyperlink.
  Button.link({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.link,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.link,
             size: _mapSize(size),
           ),
         ],
       );

  /// Creates a text button (alias for ghost).
  Button.text({
    required this.child,
    super.key,
    this.onPressed,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.size,
    this.shape,
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.ghost,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.ghost,
             size: _mapSize(size),
           ),
         ],
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
    this.htmlType,
    this.role,
    this.onHover,
    this.onFocus,
    this.wide = false,
    this.block = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : _variant = ButtonVariant.destructive,
       super(
         null,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (e) => onHover(true),
         onMouseLeave: onHover == null ? null : (e) => onHover(false),
         style: [
           ButtonVariantStyle(
             variant: ButtonVariant.destructive,
             size: _mapSize(size),
           ),
         ],
       );

  /// Main content of the button.
  final Component child;

  /// Primary action callback.
  final VoidCallback? onPressed;

  /// Whether button responds to interactions.
  final bool enabled;

  /// Component displayed before the main content.
  final Component? leading;

  /// Component displayed after the main content.
  final Component? trailing;

  /// Button size.
  final CoButtonSize? size;

  /// Button shape.
  final ButtonShape? shape;

  /// The HTML 'type' attribute for the button.
  final ButtonHtmlType? htmlType;

  /// The ARIA role for the component.
  final String? role;

  /// Hover state change callback.
  final void Function(bool)? onHover;

  /// Focus state change callback.
  final void Function(bool)? onFocus;

  /// Whether button should be wide.
  final bool wide;

  /// Whether button should be full width.
  final bool block;

  /// Internal variant reference.
  final ButtonVariant _variant;

  static const _buttonValue = 'button';

  static const _typeAttribute = 'type';
  static const _disabledAttribute = 'disabled';
  static const _tabindexAttribute = 'tabindex';
  static const _emptyValue = '';
  static const _tabindexDisabled = '-1';
  static const _trueValue = 'true';

  @override
  Button copyWith({
    bool? block,
    bool? disabled,
    bool? enabled,
    bool? loading,
    bool? wide,
    ButtonShape? shape,
    ButtonVariant? variant,
    CoButtonSize? size,
    Component? child,
    Component? leading,
    Component? trailing,
    Key? key,
    Map<String, String>? attributes,
    String? classes,
    String? htmlType,
    String? id,
    String? role,
    String? tag,
    Styles? css,
    void Function(bool)? onFocus,
    void Function(bool)? onHover,
    VoidCallback? onPressed,
  }) {
    return Button(
      disabled: disabled ?? this.enabled,
      loading: loading ?? false,
      child: child ?? this.child,
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      enabled: enabled ?? this.enabled,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      variant: variant ?? this._variant,
      htmlType: htmlType ?? this.htmlType,
      role: role ?? this.role,
      onHover: onHover ?? this.onHover,
      onFocus: onFocus ?? this.onFocus,
      wide: wide ?? this.wide,
      block: block ?? this.block,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

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
        ..add(_disabledAttribute, _emptyValue)
        ..add(_tabindexAttribute, _tabindexDisabled)
        ..addAria(_disabledAttribute, _trueValue);
    }
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: _content,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => '';

  static ButtonSize? _mapSize(CoButtonSize? size) {
    if (size == null) return null;

    return switch (size) {
      CoButtonSize.xs => ButtonSize.xs,
      CoButtonSize.sm => ButtonSize.sm,
      CoButtonSize.md => ButtonSize.md,
      CoButtonSize.lg => ButtonSize.lg,
      CoButtonSize.xl => ButtonSize.xl,
    };
  }

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        classList.add(s.cssClass);
      }
    }

    // Add shape classes
    final currentShape = shape;
    if (currentShape != null) {
      classList.add(_getShapeClass(currentShape));
    }

    // Add wide/block classes
    if (wide) {
      classList.add('w-48');
    }
    if (block) {
      classList.add('w-full');
    }

    // Add user classes
    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  Component get _content {
    final currentLeading = leading;
    final currentTrailing = trailing;

    if (currentLeading == null && currentTrailing == null) {
      return child;
    }

    // Build content with leading and trailing
    final content = [
      currentLeading,
      child,
      currentTrailing,
    ].nonNulls.toList();

    return span(
      children: content,
      classes: 'flex items-center gap-2',
    );
  }

  static String _getShapeClass(ButtonShape shape) => switch (shape) {
    ButtonShape.rectangle => '',
    ButtonShape.square => 'aspect-square p-0',
    ButtonShape.circle => 'rounded-full aspect-square p-0',
  };
}
