import 'package:coui_web/src/base/base_style.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart' show UiMouseEventHandler;
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:jaspr/jaspr.dart';

/// A generic container component, typically rendering as an HTML `<div>`.
///
/// It serves as a versatile building block for layout and grouping content.
/// Styling and layout are primarily controlled by applying general utility classes
/// (instances of styling classes) through its `styles` property.
///
/// Use the [Container.responsive] factory for a convenient way to apply
/// different modifiers at various breakpoints.
class Container extends UiComponent {
  /// Creates a generic Container component.
  ///
  /// - [children] or [child]: The content to be placed within the container.
  /// - [tag]: The HTML tag for the container element, defaults to 'div'.
  /// - [style]: A list of general styling instances for styling
  ///   and layout (e.g., Spacing, Sizing, Flex, Background).
  /// - Other parameters are inherited from [UiComponent].
  const Container(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    // If the container itself needs to be clickable
    super.key,
    super.onClick,
    super.style,
    super.tag = 'div',
  });

  // Container itself has no specific DaisyUI base class.

  static const _noBaseClass = '';

  @override
  String get baseClass => _noBaseClass;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // A generic container typically doesn't require specific ARIA roles by default.
    // Roles like 'region', 'main', 'complementary', 'form', etc., should be
    // applied by the user via the `attributes` prop or by more specialized
    // components that might extend or use Container.
    // For example, if used as a main content area:
    // Container([...], attributes: {'role': 'main', 'aria-label': 'Main content'})
  }

  @override
  Container copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    List<Styling>? style,
    String? tag,
  }) {
    return Container(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      onClick: onClick ?? this.onClick,
      style: style ?? this.style,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }

  // ignore: unused_element - Reserved for responsive breakpoint system
  static Container _createResponsiveContainer(
    ResponsiveContainerConfig config,
  ) {
    final attributes = config.attributes;
    final child = config.child;
    final children = config.children;
    final classes = config.classes;
    final css = config.css;
    final desktop = config.desktop;
    final id = config.id;
    final key = config.key;
    final mobile = config.mobile;
    final tablet = config.tablet;
    final tag = config.tag;
    final responsiveStyles = <Styling>[];

    if (mobile != null) {
      responsiveStyles.addAll(mobile);
    }

    if (tablet != null) {
      responsiveStyles.addAll(
        tablet.map(
          (utility) => Container._applyBreakpoint(
            breakpoint: Breakpoint.md,
            utility: utility,
          ),
        ),
      );
    }

    if (desktop != null) {
      responsiveStyles.addAll(
        desktop.map(
          (utility) => Container._applyBreakpoint(
            breakpoint: Breakpoint.lg,
            utility: utility,
          ),
        ),
      );
    }

    return Container(
      children ?? (child == null ? null : [child]),
      key: key,
      attributes: attributes,
      classes: classes,
      css: css,
      id: id,
      style: responsiveStyles.isNotEmpty ? responsiveStyles : null,
      tag: tag,
    );
  }

  // Helper to safely apply breakpoints.
  static Styling _applyBreakpoint({
    required PrefixModifier breakpoint,
    required Styling utility,
  }) {
    // If it's not a BaseStyle, it cannot have breakpoints applied via .at().
    // Non-BaseStyle utilities are returned unchanged.
    return utility is BaseStyle
        ? utility.at(breakpoint)
        : utility; // Return the utility as is.
  }
}

/// Configuration for creating responsive containers.
class ResponsiveContainerConfig {
  const ResponsiveContainerConfig({
    this.attributes,
    this.child,
    this.children,
    this.classes,
    this.css,
    this.desktop,
    this.id,
    this.key,
    this.mobile,
    this.tablet,
    this.tag = 'div',
  });

  final Map<String, String>? attributes;
  final Component? child;
  final List<Component>? children;
  final String? classes;
  final Styles? css;
  final List<Styling>? desktop;
  final String? id;
  final Key? key;
  final List<Styling>? mobile;
  final List<Styling>? tablet;
  final String tag;
}
