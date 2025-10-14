import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/display/badge/badge_style.dart';
import 'package:jaspr/jaspr.dart';

/// A badge component for displaying labels, tags, or status indicators.
///
/// Follows shadcn-ui design patterns with Tailwind CSS styling.
///
/// Example:
/// ```dart
/// Badge.primary(child: text('New'))
/// ```
class Badge extends UiComponent {
  /// Creates a Badge component.
  ///
  /// Parameters:
  /// - [child]: Content to display in the badge
  /// - [variant]: Badge variant (primary, secondary, destructive, outline)
  Badge({
    required Component this.child,
    super.key,
    BadgeVariant? variant,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : _variant = variant ?? BadgeVariant.defaultVariant,
       super(
         null,
         style: [
           BadgeVariantStyle(variant: variant ?? BadgeVariant.defaultVariant),
         ],
       );

  /// Creates a primary badge.
  Badge.primary({
    required Component this.child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : _variant = BadgeVariant.primary,
       super(
         null,
         style: [
           BadgeVariantStyle(variant: BadgeVariant.primary),
         ],
       );

  /// Creates a secondary badge.
  Badge.secondary({
    required Component this.child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : _variant = BadgeVariant.secondary,
       super(
         null,
         style: [
           BadgeVariantStyle(variant: BadgeVariant.secondary),
         ],
       );

  /// Creates a destructive badge.
  Badge.destructive({
    required Component this.child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : _variant = BadgeVariant.destructive,
       super(
         null,
         style: [
           BadgeVariantStyle(variant: BadgeVariant.destructive),
         ],
       );

  /// Creates an outline badge.
  Badge.outline({
    required Component this.child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : _variant = BadgeVariant.outline,
       super(
         null,
         style: [
           BadgeVariantStyle(variant: BadgeVariant.outline),
         ],
       );

  /// Content of the badge.
  final Component child;

  /// Internal variant reference.
  final BadgeVariant _variant;

  static const _spanValue = 'span';

  @override
  Badge copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    BadgeVariant? variant,
    Key? key,
  }) {
    return Badge(
      child: child ?? this.child,
      key: key ?? this.key,
      variant: variant ?? _variant,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass => '';

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: child,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
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

    // Add user classes
    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
