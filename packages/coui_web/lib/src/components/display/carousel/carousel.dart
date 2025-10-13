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
  static const _percentageMultiplier = 100;

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

  static const _divValue = 'div';

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
      styles: css,
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
          events: _buildPrevEvents(),
          child: text('\u2039'),
        ),
        button(
          classes:
              'absolute right-4 top-1/2 -translate-y-1/2 rounded-full bg-background/80 p-2 shadow-md hover:bg-background',
          attributes: {
            'type': 'button',
            'aria-label': 'Next slide',
          },
          events: _buildNextEvents(),
          child: text('\u203A'),
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
              events: _buildIndicatorEvents(index),
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

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _buildPrevEvents() {
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

  Map<String, List<dynamic>> _buildNextEvents() {
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

  Map<String, List<dynamic>> _buildIndicatorEvents(int index) {
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
