import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/select/select_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles;

/// A dropdown select component, rendering an HTML `<select>` element.
///
/// Its children should be a list of Jaspr `option()` components.
/// Compatible with coui_flutter API.
class Select extends UiComponent {
  /// Creates a Select component.
  ///
  /// - children: A list of `option()` components to populate the dropdown.
  /// - name: The name of the select element, used for form submission.
  /// - disabled: If true, the select dropdown will be disabled.
  /// - style: A list of [SelectStyling] instances for styling.
  /// - onChanged: Callback when the selected value changes (Flutter-compatible API).
  /// - Other parameters are inherited from [UiComponent].
  Select(
    super.children, {
    super.attributes,
    super.classes,
    super.css,
    super.id,
    this.isDisabled = false,
    super.key,
    this.name,
    void Function(String)? onChanged,
    List<SelectStyling>? style,
    super.tag = 'select',
  }) : super(
          // Convert Flutter-style onChanged to web onChange event
          onChange: onChanged,
          style: style,
        );

  final String? name;

  final bool isDisabled; // --- Static Style Modifiers ---

  /// Adds a border to the select. `select-bordered`.
  static const bordered = SelectStyle(
    'select-bordered',
    type: StyleType.border,
  );

  /// Ghost style (transparent background). `select-ghost`.
  static const ghost = SelectStyle('select-ghost', type: StyleType.style);

  // Colors
  /// Neutral color. `select-neutral`.
  static const neutral = SelectStyle('select-neutral', type: StyleType.style);

  /// Primary color. `select-primary`.
  static const primary = SelectStyle('select-primary', type: StyleType.style);

  /// Secondary color. `select-secondary`.
  static const secondary = SelectStyle(
    'select-secondary',
    type: StyleType.style,
  );

  /// Accent color. `select-accent`.
  static const accent = SelectStyle('select-accent', type: StyleType.style);

  /// Info color. `select-info`.
  static const info = SelectStyle('select-info', type: StyleType.style);

  /// Success color. `select-success`.
  static const success = SelectStyle('select-success', type: StyleType.style);

  /// Warning color. `select-warning`.
  static const warning = SelectStyle('select-warning', type: StyleType.style);

  /// Error color. `select-error`.
  static const error = SelectStyle('select-error', type: StyleType.style);

  // Sizes
  /// Extra-small size. `select-xs`.
  static const xs = SelectStyle('select-xs', type: StyleType.sizing);

  /// Small size. `select-sm`.
  static const sm = SelectStyle('select-sm', type: StyleType.sizing);

  /// Medium size (default). `select-md`.
  static const md = SelectStyle('select-md', type: StyleType.sizing);

  /// Large size. `select-lg`.
  static const lg = SelectStyle('select-lg', type: StyleType.sizing);

  /// Extra-large size. `select-xl`.
  static const xl = SelectStyle('select-xl', type: StyleType.sizing);

  static const _attrName = 'name';

  static const _attrDisabled = 'disabled';

  static const _empty = '';

  @override
  String get baseClass => 'select';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    final selectedName = name;
    if (selectedName != null) {
      attributes.add(_attrName, selectedName);
    }
    if (isDisabled) {
      attributes.add(_attrDisabled, _empty);
    }
  }

  @override
  Select copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    bool? isDisabled,
    Key? key,
    String? name,
    void Function(String)? onChanged,
    List<SelectStyling>? style,
    String? tag,
  }) {
    final currentStyle = this.style;
    final typedStyle = currentStyle == null
        ? null
        : List<SelectStyling>.from(currentStyle);

    return Select(
      children,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      isDisabled: isDisabled ?? this.isDisabled,
      key: key ?? this.key,
      name: name ?? this.name,
      onChanged: onChanged,
      style: style ?? typedStyle,
      tag: tag ?? this.tag,
    );
  }
}
