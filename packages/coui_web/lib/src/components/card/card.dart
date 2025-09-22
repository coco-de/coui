import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart' show UiMouseEventHandler;
import 'package:coui_web/src/base/utilities/alignment.dart';
import 'package:coui_web/src/components/card/card_style.dart';
import 'package:coui_web/src/elements/figure.dart';
import 'package:jaspr/jaspr.dart';

/// A content container, often used to display information in a structured layout.
/// It typically renders as an HTML `<div>` element with the 'card' base class.
/// The `modifiers` list accepts instances of [CardStyling] (the interface),
/// which includes specific card styles and general utility classes.
class Card extends UiComponent {
  /// Creates a Card component.
  ///
  /// - [children] or [child]: The content, typically [CardBody], [Figure], [CardActions].
  /// - [tag]: The HTML tag, defaults to 'div'.
  /// - [style]: A list of [CardStyling] (the interface) instances.
  /// - [ariaLabel], [ariaLabelledBy]: For accessibility.
  /// - Other parameters from [UiComponent].
  const Card(
    super.children, {
    this.ariaLabel,
    this.ariaLabelledBy,
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.onClick,
    List<CardStyling>? style,
    super.tag = 'div',
  }) : super(style: style);

  final String? ariaLabel;

  final String? ariaLabelledBy; // --- Static Card Modifiers ---

  // Style Modifiers
  /// Adds a solid border to the card. `card-border`.
  static const border = CardStyle('card-border', type: StyleType.style);

  /// Adds a dashed border to the card. `card-dash` (New in DaisyUI 5).
  static const dash = CardStyle('card-dash', type: StyleType.style);

  /// Styles the card for full-width image display, where the image becomes
  /// the background. `image-full`.
  static const imageFull = CardStyle('image-full', type: StyleType.style);

  // Modifier
  /// Styles the card for a side-by-side layout, typically image on one side,
  /// body on the other. `card-side`.
  static const side = CardStyle('card-side', type: StyleType.layout);

  // Size Modifiers (padding and overall look)
  /// Extra small card size/padding. `card-xs` (New in DaisyUI 5).
  static const xs = CardStyle('card-xs', type: StyleType.sizing);

  /// Small card size/padding. `card-sm`.
  static const sm = CardStyle('card-sm', type: StyleType.sizing);

  /// Medium card size/padding (default). `card-md`.
  static const md = CardStyle('card-md', type: StyleType.sizing);

  /// Large card size/padding. `card-lg`.
  static const lg = CardStyle('card-lg', type: StyleType.sizing);

  /// Extra large card size/padding. `card-xl` (New in DaisyUI 5).
  static const xl = CardStyle(
    'card-xl',
    type: StyleType.sizing,
  ); // HTML attribute constants
  static const _ariaLabelAttribute = 'label';

  static const _ariaLabelledByAttribute = 'labelledby';

  @override
  String get baseClass => 'card';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    final ariaLabelValue = ariaLabel;
    if (ariaLabelValue != null) {
      attributes.addAria(_ariaLabelAttribute, ariaLabelValue);
    }
    final ariaLabelledByValue = ariaLabelledBy;
    if (ariaLabelledByValue != null) {
      attributes.addAria(_ariaLabelledByAttribute, ariaLabelledByValue);
    }
    // Role "group" or "region" could be applicable depending on context,
    // but not applied by default.
  }

  @override
  Card copyWith({
    String? ariaLabel,
    String? ariaLabelledBy,
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    List<CardStyling>? style,
    String? tag,
  }) {
    return Card(
      children,
      key: key ?? this.key,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      ariaLabelledBy: ariaLabelledBy ?? this.ariaLabelledBy,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      onClick: onClick ?? this.onClick,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<CardStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }

  // 'glass' was previously a CardStyleModifier. In DaisyUI 5, 'glass' is a general utility
  // that can be applied to any element, including cards. It should be used as a general Effect.
  // Example: Card([...], styles: [Effects.glass])
}

/// The main content area of a [Card].
/// Typically renders as an HTML `<div>` element with the 'card-body' class.
class CardBody extends UiComponent {
  /// Creates a CardBody component.
  ///
  /// styles can include general utilities like `Spacing` or `Typography`.
  const CardBody(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.style,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'card-body';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
  }

  @override
  CardBody copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Styling>? style,
    String? tag,
  }) {
    return CardBody(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: style ?? this.style,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}

/// The title section of a [Card].
/// Typically renders as an HTML `<h2>` element with the 'card-title' class.
class CardTitle extends UiComponent {
  /// Creates a CardTitle component.
  /// Its `id` can be used by the parent [Card]'s `aria-labelledby` attribute.
  /// modifiers can include general utilities like `Typography`.
  const CardTitle(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.style,
    super.tag = 'h2',
  });

  @override
  String get baseClass => 'card-title';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
  }

  @override
  CardTitle copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Styling>? style,
    String? tag,
  }) {
    return CardTitle(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: style ?? this.style,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}

/// A container for action elements (like buttons) within a [Card].
/// Typically renders as an HTML `<div>` element with the 'card-actions' class.
class CardActions extends UiComponent {
  /// Creates a CardActions component.
  /// [style] can include general utilities like `Layout` for alignment.
  const CardActions(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.style,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'card-actions';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
  }

  @override
  CardActions copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Styling>? style,
    String? tag,
  }) {
    return CardActions(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: style ?? this.style,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}

/// Configuration object for creating basic cards.
class BasicCardConfig {
  const BasicCardConfig({
    this.actions,
    this.cardClasses = 'w-96 bg-base-100 shadow-sm',
    this.cardId,
    this.cardStyles,
    required this.content,
    this.figureStyles,
    this.imageAlt,
    this.imageUrl,
    this.key,
    this.titleId,
    required this.titleText,
  });
  final List<Component>? actions;
  final String cardClasses;
  final String? cardId;
  final List<CardStyling>? cardStyles;
  final List<Component> content;
  final List<Styling>? figureStyles;
  final String? imageAlt;
  final String? imageUrl;
  final Key? key;
  final String? titleId;

  final String titleText;
}

/// Helper methods for creating common card patterns.
abstract final class CardHelper {
  static const _defaultImageAlt = 'Card image';

  /// Creates a basic card with title, content, and optional actions.
  static Card createBasicCard(BasicCardConfig config) {
    // Extract config properties for better readability
    final actions = config.actions;
    final cardClasses = config.cardClasses;
    final cardId = config.cardId;
    final cardStyles = config.cardStyles;
    final content = config.content;
    final titleText = config.titleText;
    final titleId = config.titleId;
    final key = config.key;
    final cardChildren = <Component>[];

    // Handle optional image
    final imageUrl = config.imageUrl;
    if (imageUrl != null) {
      final imageAlt = config.imageAlt;
      final figureStyles = config.figureStyles;

      cardChildren.add(
        Figure(
          [img(alt: imageAlt ?? _defaultImageAlt, src: imageUrl)],
          style: figureStyles,
        ),
      );
    }

    final bodyChildren = <Component>[
      CardTitle([Component.text(titleText)], id: titleId),
      ...content,
    ];
    if (actions != null && actions.isNotEmpty) {
      bodyChildren.add(
        CardActions(
          actions,
          style: const [Alignment.justifyEnd],
        ), // Default to justify-end for actions
      );
    }
    cardChildren.add(CardBody(bodyChildren));

    return Card(
      cardChildren,
      key: key,
      ariaLabelledBy: titleId,
      classes: cardClasses,
      id: cardId,
      style: cardStyles,
    );
  }

  // Other helpers can be added if needed, e.g., for specific complex card layouts.
}
