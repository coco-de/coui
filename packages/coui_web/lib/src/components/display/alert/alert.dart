import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/display/alert/alert_style.dart';
import 'package:jaspr/jaspr.dart';

/// An alert component for displaying important messages.
///
/// Follows shadcn-ui design patterns with Tailwind CSS styling.
///
/// Example:
/// ```dart
/// Alert(
///   children: [
///     AlertTitle(titleChild: text('Heads up!')),
///     AlertDescription(descriptionChild: text('You can add components to your app using the cli.')),
///   ],
/// )
/// ```
class Alert extends UiComponent {
  /// Creates an Alert component.
  ///
  /// Parameters:
  /// - [children]: Child components to display in the alert
  /// - [child]: Single child component (alternative to children)
  /// - [variant]: Alert variant (default or destructive)
  Alert(
    List<Component> list, {
    List<Component>? children,
    Component? child,
    super.key,
    AlertVariant? variant,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : _variant = variant ?? AlertVariant.defaultVariant,
       super(
         children,
         child: child,
         style: [
           AlertVariantStyle(variant: variant ?? AlertVariant.defaultVariant),
         ],
       );

  /// Creates a destructive alert.
  Alert.destructive({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : _variant = AlertVariant.destructive,
       super(
         children,
         child: child,
         style: [
           AlertVariantStyle(variant: AlertVariant.destructive),
         ],
       );

  /// Internal variant reference.
  final AlertVariant _variant;

  static const _divValue = 'div';

  @override
  Alert copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    AlertVariant? variant,
    Key? key,
  }) {
    return Alert(
      children: children ?? this.children,
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
  Component build(BuildContext context) {
    return Component.element(
      child: child,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => '';

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

/// Alert title component.
class AlertTitle extends UiComponent {
  /// Creates an AlertTitle component.
  const AlertTitle({
    required Component this.titleChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _h5Value,
  }) : super(null);

  /// Content of the title.
  final Component titleChild;

  static const _h5Value = 'h5';

  static const _baseClasses = 'mb-1 font-medium leading-none tracking-tight';

  @override
  AlertTitle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? titleChild,
    Key? key,
  }) {
    return AlertTitle(
      titleChild: titleChild ?? this.titleChild,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: titleChild,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Alert description component.
class AlertDescription extends UiComponent {
  /// Creates an AlertDescription component.
  const AlertDescription({
    required Component this.descriptionChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Content of the description.
  final Component descriptionChild;

  static const _divValue = 'div';

  static const _baseClasses = 'text-sm [&_p]:leading-relaxed';

  @override
  AlertDescription copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? descriptionChild,
    Key? key,
  }) {
    return AlertDescription(
      descriptionChild: descriptionChild ?? this.descriptionChild,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: descriptionChild,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
