// ignore_for_file: avoid-using-non-ascii-symbols

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A stat/metric display component.
///
/// Example:
/// ```dart
/// Stat(
///   label: 'Total Revenue',
///   value: '\$45,231',
///   change: '+20.1%',
///   changeType: StatChangeType.positive,
/// )
/// ```
class Stat extends UiComponent {
  /// Creates a Stat component.
  const Stat({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.changeType,
    this.icon,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Stat label.
  final String label;

  /// Stat value.
  final String value;

  /// Change indicator.
  final String? change;

  /// Change type (positive/negative/neutral).
  final StatChangeType? changeType;

  /// Optional icon.
  final Component? icon;

  /// Upward arrow icon character code (U+2191 - ↑).
  static const _kUpArrowCode = 0x2191;

  /// Downward arrow icon character code (U+2193 - ↓).
  static const _kDownArrowCode = 0x2193;

  /// Right arrow icon character code (U+2192 - →).
  static const _kRightArrowCode = 0x2192;

  static const _divValue = 'div';

  /// Upward arrow icon character.
  static String get _kUpArrow => String.fromCharCode(_kUpArrowCode);

  /// Downward arrow icon character.
  static String get _kDownArrow => String.fromCharCode(_kDownArrowCode);

  /// Right arrow icon character.
  static String get _kRightArrow => String.fromCharCode(_kRightArrowCode);

  @override
  Stat copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? label,
    String? value,
    String? change,
    StatChangeType? changeType,
    Component? icon,
    Key? key,
  }) {
    return Stat(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      change: change ?? this.change,
      changeType: changeType ?? this.changeType,
      icon: icon ?? this.icon,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      children: [
        // Label and icon
        div(
          children: [
            p(
              child: text(label),
              classes: 'text-sm font-medium text-muted-foreground',
            ),
            ?icon,
          ],
          classes: 'flex items-center justify-between',
        ),
        // Value
        div(
          child: text(value),
          classes: 'text-2xl font-bold',
        ),
        // Change indicator
        if (change != null && changeType != null)
          div(
            children: [
              span(child: text(_getChangeIcon)),
              span(child: text(change)),
            ],
            classes: 'flex items-center gap-1 text-xs ${_getChangeColor}',
          ),
      ],
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => 'rounded-lg border p-6 space-y-2';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  String get _getChangeColor {
    final type = changeType;
    if (type == null) return '';

    return switch (type) {
      StatChangeType.positive => 'text-green-600',
      StatChangeType.negative => 'text-red-600',
      StatChangeType.neutral => 'text-muted-foreground',
    };
  }

  String get _getChangeIcon {
    final type = changeType;
    if (type == null) return '';

    return switch (type) {
      StatChangeType.positive => _kUpArrow,
      StatChangeType.negative => _kDownArrow,
      StatChangeType.neutral => _kRightArrow,
    };
  }
}

/// Change type for stat.
enum StatChangeType {
  /// Positive change.
  positive,

  /// Negative change.
  negative,

  /// Neutral/no significant change.
  neutral,
}
