import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/icon/icon_style.dart';
import 'package:jaspr/jaspr.dart';

// Utilities for typography/sizing can be imported where needed.

/// A component for displaying icons, typically from an icon font like Material Symbols.
///
/// It renders an HTML `<span>` element with appropriate classes for the icon font
/// and the specified icon name as its text content.
/// Styling (size, color, fill, weight) can be applied via [IconStyling]s or
/// general utility classes.
class Icon extends UiComponent {
  /// Creates an Icon component.
  ///
  /// - [name]: The name of the icon to display (e.g., "home", "settings" for Material Symbols).
  /// - [tag]: The HTML tag for the root element, defaults to 'span'.
  /// - [ariaLabel]: An accessible name for the icon, especially if it's used without visible text.
  ///   If null and [ariaHidden] is false, the icon [name] might be used by assistive tech,
  ///   which may not be ideal.
  /// - [ariaHidden]: If true, hides the icon from assistive technologies. Set to true
  ///   if the icon is purely decorative or if its meaning is conveyed by adjacent text.
  /// - [style]: A list of [IconStyling] (the interface) instances.
  /// - Other parameters are inherited from [UiComponent].
  Icon(
    this.name, {
    this.ariaHidden,
    this.ariaLabel,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    List<IconStyling>? style,
    super.tag = 'span',
  }) : super(
         // The icon name is the direct text child of the span
         [Component.text(name)],
         style: style,
       );

  // Base class for Material Symbols

  /// The name or identifier of the icon (e.g., "search", "settings").
  final String name;

  /// An accessible label for the icon. If provided, `aria-hidden` should typically be `false` or null.
  final String? ariaLabel;

  /// If true, the icon will be hidden from assistive technologies (`aria-hidden="true"`).
  /// Useful for decorative icons or when an adjacent text label exists.
  final bool? ariaHidden;

  // --- Static Icon Modifiers (Type: IconModifier interface, Instantiating: IconStyleModifier) ---
  // These would correspond to specific Material Symbols CSS styling classes or font variation settings
  // if they are controlled by classes rather than font-variation-settings CSS.

  /// Applies a "filled" style to the icon (if supported by the icon set).
  /// For Material Symbols, this is often controlled by `font-variation-settings: 'FILL' 1;`
  /// or by using a "Filled" variant of the font/icon name.
  /// If DaisyUI/Tailwind provide a utility class for this, we use it.
  /// Assuming a class like `.icon-fill` or similar.
  static const fill = IconStyle('filled', type: StyleType.style);

  // Material Symbols weights are typically 100-700.
  // These can be controlled by `font-variation-settings: 'wght' <value>;`
  // If there are utility classes like `font-weight-thin`, `font-weight-bold` from Typography,
  // those should be preferred. These are examples if specific icon classes existed.
  // For Material Symbols, it's often direct CSS or `font-variation-settings`.
  // If `coui_web` aims to abstract `font-variation-settings` via classes, they'd be defined here.

  /// Thin stroke weight for the icon.
  static const weightThin = IconStyle('weight-200', type: StyleType.style);

  /// Regular stroke weight for the icon.
  static const weightRegular = IconStyle(
    'weight-400',
    type: StyleType.style,
  );

  /// Bold stroke weight for the icon.
  static const weightBold = IconStyle(
    'weight-700',
    type: StyleType.style,
  ); // HTML attribute constants
  static const _ariaHiddenAttribute = 'hidden';
  static const _ariaLabelAttribute = 'label';

  static const _trueValue = 'true';

  @override
  String get baseClass => 'material-symbols-rounded';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    if (ariaHidden ?? false) {
      attributes.addAria(_ariaHiddenAttribute, _trueValue);
      // If hidden, an aria-label is usually not needed or might even be confusing.
      // However, we don't remove a user-provided ariaLabel if ariaHidden is also true.
    } else {
      final ariaLabelValue = ariaLabel;
      if (ariaLabelValue != null && ariaLabelValue.isNotEmpty) {
        attributes.addAria(_ariaLabelAttribute, ariaLabelValue);
      }
    }
    // If neither ariaHidden=true nor ariaLabel is provided, the icon's text may be read by screen readers.
  }

  @override
  Icon copyWith({
    bool? ariaHidden,
    String? ariaLabel,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<IconStyling>? style,
    String? tag,
  }) {
    return Icon(
      name,
      key: key ?? this.key,
      ariaHidden: ariaHidden ?? this.ariaHidden,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<IconStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }

  // Sizes: DaisyUI/Tailwind text size utilities are typically used for font icons.
  // e.g., Text(modifiers: [Typography.textLg], [Icon(...)]) or Icon(..., modifiers: [Typography.textLg])
  // If you want dedicated Icon.sizeSm, Icon.sizeMd, etc., they would map to text size classes.
  // Your original example had text-xs, text-sm, etc. These should come from Typography utility.

  // Color: Similarly, text color utilities from Typography/Colors should be used.
  // e.g., Icon(..., modifiers: [Colors.textPrimary])
  // Your original example had text-primary etc.
}
