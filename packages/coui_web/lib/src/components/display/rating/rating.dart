// ignore_for_file: avoid-using-non-ascii-symbols

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for rating change.
typedef RatingCallback = void Function(int rating);

/// A rating component (star rating).
///
/// Example:
/// ```dart
/// Rating(
///   value: 4,
///   max: 5,
///   onChanged: (rating) => print('Rating: $rating'),
/// )
/// ```
class Rating extends UiComponent {
  /// Creates a Rating component.
  const Rating({
    super.key,
    this.value = 0,
    this.max = _defaultMaxRating,
    this.readonly = false,
    this.onChanged,
    this.size = RatingSize.md,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Current rating value.
  final int value;

  /// Maximum rating.
  final int max;

  /// Whether rating is readonly.
  final bool readonly;

  /// Change callback.
  final RatingCallback? onChanged;

  /// Size of rating stars.
  final RatingSize size;

  /// Filled star icon character code (U+2605 - ★).
  static const _kFilledStarCode = 0x2605;

  /// Empty star icon character code (U+2606 - ☆).
  static const _kEmptyStarCode = 0x2606;

  static const _defaultMaxRating = 5;

  static const _divValue = 'div';

  /// Filled star icon character.
  static String get _kFilledStar => String.fromCharCode(_kFilledStarCode);

  /// Empty star icon character.
  static String get _kEmptyStar => String.fromCharCode(_kEmptyStarCode);

  @override
  Rating copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    int? value,
    int? max,
    bool? readonly,
    RatingCallback? onChanged,
    RatingSize? size,
    Key? key,
  }) {
    return Rating(
      key: key ?? this.key,
      value: value ?? this.value,
      max: max ?? this.max,
      readonly: readonly ?? this.readonly,
      onChanged: onChanged ?? this.onChanged,
      size: size ?? this.size,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final stars = <Component>[];

    for (int i = 1; i <= max; i += 1) {
      stars.add(_buildStar(i));
    }

    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'img',
        'aria-label': '$value out of $max stars',
      },
      events: this.events,
      children: stars,
    );
  }

  @override
  String get baseClass => 'flex items-center gap-1';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  Component _buildStar(int index) {
    final isFilled = index <= value;
    final sizeClass = _getSizeClass();

    return button(
      classes:
          '$sizeClass transition-colors ${isFilled ? 'text-yellow-400' : 'text-muted'} ${readonly ? 'cursor-default' : 'cursor-pointer hover:text-yellow-400'}',
      attributes: {
        'type': 'button',
        if (readonly) 'disabled': '',
        'aria-label': '$index stars',
      },
      events: _buildStarEvents(index),
      child: text(isFilled ? _kFilledStar : _kEmptyStar),
    );
  }

  String _getSizeClass() {
    return switch (size) {
      RatingSize.sm => 'text-sm',
      RatingSize.md => 'text-xl',
      RatingSize.lg => 'text-2xl',
    };
  }

  Map<String, List<dynamic>> _buildStarEvents(int rating) {
    return readonly || onChanged == null
        ? {}
        : {
            'click': [
              (event) => onChanged(rating),
            ],
          };
  }
}

/// Rating size options.
enum RatingSize {
  /// Small size.
  sm,

  /// Medium size.
  md,

  /// Large size.
  lg,
}
