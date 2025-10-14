// ignore_for_file: avoid-using-non-ascii-symbols, prefer-correct-handler-name

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for carousel index change.
typedef CarouselIndexCallback = void Function(int index);

/// A carousel component for displaying rotating content.
///
/// Example:
/// ```dart
/// Carousel(
///   items: [
///     div(child: text('Slide 1')),
///     div(child: text('Slide 2')),
///     div(child: text('Slide 3')),
///   ],
/// )
/// ```
class Carousel extends UiComponent {
  /// Creates a Carousel component.
  ///
  /// Parameters:
  /// - [items]: Carousel items
  /// - [currentIndex]: Currently displayed index
  /// - [onIndexChanged]: Callback when index changes
  /// - [autoPlay]: Whether to auto-play
  const Carousel({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onIndexChanged,
    this.autoPlay = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Carousel items.
  final List<Component> items;

  /// Currently displayed index.
  final int currentIndex;

  /// Callback when index changes.
  final CarouselIndexCallback? onIndexChanged;

  /// Whether to auto-play.
  final bool autoPlay;

  static const _percentageMultiplier = 100;

  /// Previous slide icon character code (U+2039 - ‹).
  static const _kPrevIconCode = 0x2039;

  /// Next slide icon character code (U+203A - ›).
  static const _kNextIconCode = 0x203A;

  static const _divValue = 'div';

  /// Previous slide icon character.
  static String get _kPrevIcon => String.fromCharCode(_kPrevIconCode);

  /// Next slide icon character.
  static String get _kNextIcon => String.fromCharCode(_kNextIconCode);

  @override
  Carousel copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? items,
    int? currentIndex,
    CarouselIndexCallback? onIndexChanged,
    bool? autoPlay,
    Key? key,
  }) {
    return Carousel(
      key: key ?? this.key,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      onIndexChanged: onIndexChanged ?? this.onIndexChanged,
      autoPlay: autoPlay ?? this.autoPlay,
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
      attributes: {
        ...this.componentAttributes,
        'role': 'region',
        'aria-label': 'Carousel',
      },
      events: this.events,
      children: [
        // Carousel items
        div(
          classes: 'flex transition-transform duration-300',
          styles: {
            'transform':
                'translateX(-${currentIndex * _percentageMultiplier}%)',
          },
          children: items
              .map(
                (item) => div(
                  classes: 'min-w-full',
                  child: item,
                ),
              )
              .toList(),
        ),
        // Navigation buttons
        button(
          classes:
              'absolute left-4 top-1/2 -translate-y-1/2 rounded-full bg-background/80 p-2 shadow-md hover:bg-background',
          attributes: {
            'type': 'button',
            'aria-label': 'Previous slide',
          },
          events: _handlePrev(),
          child: text(_kPrevIcon),
        ),
        button(
          classes:
              'absolute right-4 top-1/2 -translate-y-1/2 rounded-full bg-background/80 p-2 shadow-md hover:bg-background',
          attributes: {
            'type': 'button',
            'aria-label': 'Next slide',
          },
          events: _handleNext(),
          child: text(_kNextIcon),
        ),
        // Indicators
        div(
          classes: 'absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2',
          children: List.generate(
            items.length,
            (index) => button(
              classes:
                  'h-2 w-2 rounded-full transition-colors ${index == currentIndex ? 'bg-primary' : 'bg-muted'}',
              attributes: {
                'type': 'button',
                'aria-label': 'Go to slide ${index + 1}',
              },
              events: _handleIndicator(index),
            ),
          ),
        ),
      ],
    );
  }

  @override
  String get baseClass => 'relative overflow-hidden rounded-lg';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _handlePrev() {
    final callback = onIndexChanged;

    return callback == null
        ? {}
        : {
            'click': [
              (event) {
                final newIndex = currentIndex > 0
                    ? currentIndex - 1
                    : items.length - 1;
                callback(newIndex);
              },
            ],
          };
  }

  Map<String, List<dynamic>> _handleNext() {
    final callback = onIndexChanged;

    return callback == null
        ? {}
        : {
            'click': [
              (event) {
                final newIndex = currentIndex < items.length - 1
                    ? currentIndex + 1
                    : 0;
                callback(newIndex);
              },
            ],
          };
  }

  Map<String, List<dynamic>> _handleIndicator(int index) {
    final callback = onIndexChanged;

    return callback == null
        ? {}
        : {
            'click': [
              (event) => callback(index),
            ],
          };
  }
}
