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

  static const _divValue = 'div';

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
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Label and icon
        div(
          classes: 'flex items-center justify-between',
          children: [
            p(
              classes: 'text-sm font-medium text-muted-foreground',
              child: text(label),
            ),
            if (icon != null) icon!,
          ],
        ),
        // Value
        div(
          classes: 'text-2xl font-bold',
          child: text(value),
        ),
        // Change indicator
        if (change != null && changeType != null)
          div(
            classes: 'flex items-center gap-1 text-xs ${_getChangeColor()}',
            children: [
              span(child: text(_getChangeIcon())),
              span(child: text(change!)),
            ],
          ),
      ],
    );
  }

  @override
  String get baseClass => 'rounded-lg border p-6 space-y-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  String _getChangeColor() {
    return switch (changeType!) {
      StatChangeType.positive => 'text-green-600',
      StatChangeType.negative => 'text-red-600',
      StatChangeType.neutral => 'text-muted-foreground',
    };
  }

  String _getChangeIcon() {
    return switch (changeType!) {
      StatChangeType.positive => '↑',
      StatChangeType.negative => '↓',
      StatChangeType.neutral => '→',
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
