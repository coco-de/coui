import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/layout/card/card_style.dart';
import 'package:jaspr/jaspr.dart';

/// A card container component following shadcn-ui design patterns.
///
/// Cards are surfaces that display content and actions on a single topic.
///
/// Example:
/// ```dart
/// Card(
///   children: [
///     CardHeader(child: text('Card Title')),
///     CardContent(child: text('Card content goes here')),
///     CardFooter(child: Button.primary(child: text('Action'))),
///   ],
/// )
/// ```
class Card extends UiComponent {
  /// Creates a Card component.
  ///
  /// Parameters:
  /// - [children]: Child components to display in the card
  /// - [child]: Single child component (alternative to children)
  /// - [variant]: Card variant (default or hoverable)
  Card({
    List<Component>? children,
    Component? child,
    super.key,
    CardVariant? variant,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : _variant = variant ?? CardVariant.defaultVariant,
       super(
         children,
         child: child,
         style: [
           CardVariantStyle(variant: variant ?? CardVariant.defaultVariant),
         ],
       );

  /// Creates a hoverable card with hover effects.
  Card.hoverable({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : _variant = CardVariant.hoverable,
       super(
         children,
         child: child,
         style: [
           CardVariantStyle(variant: CardVariant.hoverable),
         ],
       );

  /// Internal variant reference.
  final CardVariant _variant;

  static const _divValue = 'div';

  @override
  Card copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    CardVariant? variant,
    Key? key,
  }) {
    return Card(
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

/// Card header component.
class CardHeader extends UiComponent {
  /// Creates a CardHeader component.
  CardHeader({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  static const _divValue = 'div';

  static const _baseClasses = 'flex flex-col space-y-1.5 p-6';

  @override
  CardHeader copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    List<Component>? children,
    Key? key,
  }) {
    return CardHeader(
      children: children ?? this.children,
      child: child ?? this.child,
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

/// Card title component.
class CardTitle extends UiComponent {
  /// Creates a CardTitle component.
  const CardTitle({
    required Component this.titleChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _h3Value,
  }) : super(null);

  /// Content of the title.
  final Component titleChild;

  static const _h3Value = 'h3';

  static const _baseClasses =
      'text-2xl font-semibold leading-none tracking-tight';

  @override
  CardTitle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? titleChild,
    Key? key,
  }) {
    return CardTitle(
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

/// Card description component.
class CardDescription extends UiComponent {
  /// Creates a CardDescription component.
  const CardDescription({
    required Component this.descriptionChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _pValue,
  }) : super(null);

  /// Content of the description.
  final Component descriptionChild;

  static const _pValue = 'p';

  static const _baseClasses = 'text-sm text-muted-foreground';

  @override
  CardDescription copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? descriptionChild,
    Key? key,
  }) {
    return CardDescription(
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

/// Card content component.
class CardContent extends UiComponent {
  /// Creates a CardContent component.
  CardContent({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  static const _divValue = 'div';

  static const _baseClasses = 'p-6 pt-0';

  @override
  CardContent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    List<Component>? children,
    Key? key,
  }) {
    return CardContent(
      children: children ?? this.children,
      child: child ?? this.child,
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

/// Card footer component.
class CardFooter extends UiComponent {
  /// Creates a CardFooter component.
  CardFooter({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  static const _divValue = 'div';

  static const _baseClasses = 'flex items-center p-6 pt-0';

  @override
  CardFooter copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    List<Component>? children,
    Key? key,
  }) {
    return CardFooter(
      children: children ?? this.children,
      child: child ?? this.child,
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
