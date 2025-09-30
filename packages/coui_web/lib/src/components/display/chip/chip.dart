import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:jaspr/jaspr.dart';

/// Chip size variants.
enum ChipSize {
  /// Large chip size.
  lg,

  /// Medium chip size.
  md,

  /// Small chip size.
  sm,
}

/// A component for displaying compact interactive elements for tags and labels.
///
/// Chips combine button functionality with a compact form factor, ideal for
/// representing tags, categories, filters, or selected items.
/// Compatible with coui_flutter API.
///
/// Example:
/// ```dart
/// Chip(
///   label: 'Tag',
///   onClick: () => print('Chip clicked'),
/// )
/// ```
class Chip extends UiComponent {
  /// Creates a Chip component.
  ///
  /// - [label]: Text content of the chip.
  /// - [onClick]: Callback when chip is clicked.
  /// - [onDelete]: Callback when delete button is clicked (shows close button).
  /// - [size]: Size of the chip (sm, md, lg).
  /// - [outlined]: Whether to use outline style.
  /// - [style]: List of [ChipStyling] instances for styling.
  Chip({
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    required this.label,
    this.onDelete,
    void Function()? onClick,
    this.outlined = false,
    this.size,
    List<ChipStyling>? style,
    super.tag = _defaultTag,
  }) : _onClickCallback = onClick,
       _style = style,
       super(
         null,
         child: null,
         style: style,
       );

  /// Creates a primary chip.
  factory Chip.primary({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    required String label,
    void Function()? onDelete,
    void Function()? onClick,
    bool? outlined,
    ChipSize? size,
    List<ChipStyling>? style,
    String? tag,
  }) {
    return Chip(
      attributes: attributes,
      classes: classes,
      css: css,
      id: id,
      key: key,
      label: label,
      onDelete: onDelete,
      onClick: onClick,
      outlined: outlined ?? false,
      size: size,
      style: [
        if (style != null) ...style,
        _primaryStyle,
      ],
      tag: tag,
    );
  }

  /// Creates a secondary chip.
  factory Chip.secondary({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    required String label,
    void Function()? onDelete,
    void Function()? onClick,
    bool? outlined,
    ChipSize? size,
    List<ChipStyling>? style,
    String? tag,
  }) {
    return Chip(
      attributes: attributes,
      classes: classes,
      css: css,
      id: id,
      key: key,
      label: label,
      onDelete: onDelete,
      onClick: onClick,
      outlined: outlined ?? false,
      size: size,
      style: [
        if (style != null) ...style,
        _secondaryStyle,
      ],
      tag: tag,
    );
  }

  /// Creates an accent chip.
  factory Chip.accent({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    required String label,
    void Function()? onDelete,
    void Function()? onClick,
    bool? outlined,
    ChipSize? size,
    List<ChipStyling>? style,
    String? tag,
  }) {
    return Chip(
      attributes: attributes,
      classes: classes,
      css: css,
      id: id,
      key: key,
      label: label,
      onDelete: onDelete,
      onClick: onClick,
      outlined: outlined ?? false,
      size: size,
      style: [
        if (style != null) ...style,
        _accentStyle,
      ],
      tag: tag,
    );
  }

  /// Text label of the chip.
  final String label;

  /// Callback when chip is clicked (Flutter-compatible API).
  final void Function()? _onClickCallback;

  /// Callback when delete button is clicked (Flutter-compatible API).
  final void Function()? onDelete;

  /// Size of the chip.
  final ChipSize? size;

  /// Whether to use outline style.
  final bool outlined;

  /// Internal style list.
  final List<ChipStyling>? _style;

  // Static chip style modifiers
  static const _primaryStyle = ChipStyle(
    'badge-primary',
    type: StyleType.style,
  );
  static const _secondaryStyle = ChipStyle(
    'badge-secondary',
    type: StyleType.style,
  );
  static const _accentStyle = ChipStyle('badge-accent', type: StyleType.style);
  static const _outlineStyle = ChipStyle(
    'badge-outline',
    type: StyleType.style,
  );

  static const _defaultTag = 'div';
  static const _chipBaseClass = 'badge';
  static const _closeButtonClass = 'ml-2 cursor-pointer';

  @override
  String get baseClass => _chipBaseClass;

  @override
  Component build(BuildContext context) {
    final styles = _buildStyles();
    final sizeClass = _getSizeClass();

    final children = <Component>[
      Component.text(label),
    ];

    if (onDelete != null) {
      children.add(
        Component.element(
          attributes: {'aria-label': 'delete'},
          classes: _closeButtonClass,
          events: {'click': (_) => onDelete!()},
          tag: 'span',
          children: [Component.text('×')],
        ),
      );
    }

    final eventHandlers = _onClickCallback != null ? {'click': (_) => _onClickCallback!()} : null;

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}${sizeClass.isNotEmpty ? ' $sizeClass' : ''}',
      events: eventHandlers,
      id: id,
      styles: css,
      tag: tag,
      children: children,
    );
  }

  List<String> _buildStyles() {
    final stylesList = <String>[];

    if (_style != null) {
      for (final style in _style!) {
        stylesList.add(style.cssClass);
      }
    }

    if (outlined) {
      stylesList.add(_outlineStyle.cssClass);
    }

    return stylesList;
  }

  String _getSizeClass() {
    if (size == null) return '';

    switch (size!) {
      case ChipSize.sm:
        return 'badge-sm';

      case ChipSize.md:
        return 'badge-md';

      case ChipSize.lg:
        return 'badge-lg';
    }
  }

  @override
  Chip copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? label,
    void Function()? onDelete,
    void Function()? onClick,
    bool? outlined,
    ChipSize? size,
    List<ChipStyling>? style,
    String? tag,
  }) {
    return Chip(
      attributes: attributes ?? userProvidedAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      label: label ?? this.label,
      onDelete: onDelete ?? this.onDelete,
      onClick: onClick ?? _onClickCallback,
      outlined: outlined ?? this.outlined,
      size: size ?? this.size,
      style: style ?? _style,
      tag: tag ?? this.tag,
    );
  }
}
