import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/loading/loading_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles;

/// A component that shows an animation to indicate that something is loading.
///
/// It renders an empty `<span>` element with the necessary CSS classes for the
/// animation. The color of the loading indicator is controlled by standard text
/// color utilities (e.g., `TextUtil.primary`).
///
/// Example Usage:
/// ```dart
/// Loading(
///   style: [
///     Loading.spinner,
///     Loading.lg,
///     TextUtil.primary, // Color is applied via text utilities
///   ],
/// )
/// ```
class Loading extends UiComponent {
  /// Creates a Loading component.
  ///
  /// - [style]: A list of [LoadingStyling] instances to control the animation
  ///   type (e.g., `Loading.spinner`) and size (e.g., `Loading.lg`).
  ///   Color should be applied using a text utility like `TextUtil.primary`.
  /// - [ariaLabel]: An accessible name for the loading indicator. Defaults to "loading".
  ///   It's recommended to provide a more descriptive label if possible (e.g., "Loading results...").
  /// - [tag]: The HTML tag for the root element, defaults to 'span'.
  /// - Other parameters are inherited from [UiComponent].
  const Loading({
    this.ariaLabel,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    List<LoadingStyling>? style,
    super.tag = 'span',
  }) : super(null, style: style);

  // Loading elements have no children.

  /// An accessible label for the loading indicator, announced by screen readers.
  final String? ariaLabel;

  // --- Static Style Modifiers ---

  // Animation Styles
  /// Spinner animation. `loading-spinner`.
  static const spinner = LoadingStyle(
    'loading-spinner',
    type: StyleType.style,
  );

  /// Dots animation. `loading-dots`.
  static const dots = LoadingStyle('loading-dots', type: StyleType.style);

  /// Ring animation. `loading-ring`.
  static const ring = LoadingStyle('loading-ring', type: StyleType.style);

  /// Ball animation. `loading-ball`.
  static const ball = LoadingStyle('loading-ball', type: StyleType.style);

  /// Bars animation. `loading-bars`.
  static const bars = LoadingStyle('loading-bars', type: StyleType.style);

  /// Infinity animation. `loading-infinity`.
  static const infinity = LoadingStyle(
    'loading-infinity',
    type: StyleType.style,
  );

  // Sizes
  /// Extra-small size. `loading-xs`.
  static const xs = LoadingStyle('loading-xs', type: StyleType.sizing);

  /// Small size. `loading-sm`.
  static const sm = LoadingStyle('loading-sm', type: StyleType.sizing);

  /// Medium size (default). `loading-md`.
  static const md = LoadingStyle('loading-md', type: StyleType.sizing);

  /// Large size. `loading-lg`.
  static const lg = LoadingStyle('loading-lg', type: StyleType.sizing);

  /// Extra-large size. `loading-xl`.
  static const xl = LoadingStyle(
    'loading-xl',
    type: StyleType.sizing,
  ); // HTML attribute constants
  static const _roleAttribute = 'role';
  static const _statusRole = 'status';
  static const _ariaLabel = 'label';

  static const _loadingValue = 'loading';

  @override
  String get baseClass => _loadingValue;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // The 'status' role indicates that the content is a live region
    // providing advisory information about the status of a request.
    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_statusRole);
    }
    // Provide a default accessible name, which can be overridden by the user.
    attributes.addAria(_ariaLabel, ariaLabel ?? _loadingValue);
  }

  @override
  Loading copyWith({
    String? ariaLabel,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<LoadingStyling>? style,
    String? tag,
  }) {
    final currentStyle = this.style;
    final loadingStyle = currentStyle is List<LoadingStyling>?
        ? currentStyle
        : null;

    return Loading(
      key: key ?? this.key,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: style ?? loadingStyle,
      tag: tag ?? this.tag,
    );
  }
}
