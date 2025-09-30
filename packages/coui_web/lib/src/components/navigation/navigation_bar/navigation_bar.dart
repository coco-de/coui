import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr/jaspr.dart';

/// A navigation bar component for site-wide navigation.
///
/// The NavigationBar component provides a horizontal navigation bar with
/// three sections (start, center, end) for organizing navigation elements.
/// It follows DaisyUI's navbar component patterns.
///
/// Features:
/// - Three-section layout (start, center, end)
/// - Flexible content positioning
/// - Mobile-responsive with optional hamburger menu
/// - Sticky positioning support
/// - Shadow and background customization
///
/// Example:
/// ```dart
/// NavigationBar(
///   start: [
///     Button([text('Menu')], style: [Button.ghost]),
///   ],
///   center: [
///     text('My App'),
///   ],
///   end: [
///     Button([text('Login')], style: [Button.ghost]),
///   ],
///   shadow: true,
/// )
/// ```
class NavigationBar extends UiComponent {
  /// Creates a NavigationBar component.
  ///
  /// - [start]: Components aligned to the start (left) of the navbar.
  /// - [center]: Components aligned to the center of the navbar.
  /// - [end]: Components aligned to the end (right) of the navbar.
  /// - [shadow]: Whether to show a shadow below the navbar.
  /// - [style]: List of [NavigationBarStyling] instances for styling.
  const NavigationBar({
    super.attributes,
    this.center,
    super.child,
    super.classes,
    super.css,
    this.end,
    super.id,
    super.key,
    this.shadow = false,
    this.start,
    List<NavigationBarStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// Components aligned to the start (left) of the navbar.
  final List<Component>? start;

  /// Components aligned to the center of the navbar.
  final List<Component>? center;

  /// Components aligned to the end (right) of the navbar.
  final List<Component>? end;

  /// Whether to show a shadow below the navbar.
  final bool shadow;

  // --- Static Style Modifiers ---

  /// Sticky positioning. `sticky top-0 z-30`.
  static const sticky = NavigationBarStyle('sticky top-0 z-30', type: StyleType.layout);

  @override
  String get baseClass => 'navbar bg-base-100';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('navigation');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();
    final sections = <Component>[];

    // Start section
    if (start != null && start!.isNotEmpty) {
      sections.add(
        Component.element(
          classes: 'navbar-start',
          tag: 'div',
          children: start!,
        ),
      );
    }

    // Center section
    if (center != null && center!.isNotEmpty) {
      sections.add(
        Component.element(
          classes: 'navbar-center',
          tag: 'div',
          children: center!,
        ),
      );
    }

    // End section
    if (end != null && end!.isNotEmpty) {
      sections.add(
        Component.element(
          classes: 'navbar-end',
          tag: 'div',
          children: end!,
        ),
      );
    }

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: sections,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add shadow if requested
    if (shadow) {
      stylesList.add('shadow-lg');
    }

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is NavigationBarStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  @override
  NavigationBar copyWith({
    Map<String, String>? attributes,
    List<Component>? center,
    Component? child,
    String? classes,
    Styles? css,
    List<Component>? end,
    String? id,
    Key? key,
    bool? shadow,
    List<Component>? start,
    List<NavigationBarStyling>? style,
    String? tag,
  }) {
    return NavigationBar(
      attributes: attributes ?? userProvidedAttributes,
      center: center ?? this.center,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      end: end ?? this.end,
      id: id ?? this.id,
      key: key ?? this.key,
      shadow: shadow ?? this.shadow,
      start: start ?? this.start,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<NavigationBarStyling>?
                ? currentStyle
                : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}