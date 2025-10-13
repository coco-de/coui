import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// An avatar component for displaying user profile images or initials.
///
/// Example:
/// ```dart
/// Avatar(src: 'https://example.com/avatar.jpg')
/// Avatar(fallback: 'JD') // Shows initials
/// ```
class Avatar extends UiComponent {
  /// Creates an Avatar component.
  ///
  /// Parameters:
  /// - [src]: Image source URL
  /// - [fallback]: Fallback text (e.g., initials)
  /// - [alt]: Alt text for the image
  const Avatar({
    super.key,
    this.src,
    this.fallback,
    this.alt,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Image source URL.
  final String? src;

  /// Fallback text (e.g., initials).
  final String? fallback;

  /// Alt text for the image.
  final String? alt;

  static const _divValue = 'div';

  @override
  Avatar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? src,
    String? fallback,
    String? alt,
    Key? key,
  }) {
    return Avatar(
      key: key ?? this.key,
      src: src ?? this.src,
      alt: alt ?? this.alt,
      fallback: fallback ?? this.fallback,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass =>
      'relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full';

  @override
  Component build(BuildContext context) {
    final currentSrc = src;
    final currentFallback = fallback;

    Component content;
    if (currentSrc != null) {
      content = Component.element(
        tag: 'img',
        classes: 'aspect-square h-full w-full',
        attributes: {
          'src': currentSrc,
          if (alt != null) 'alt': alt!,
        },
      );
    } else if (currentFallback != null) {
      content = div(
        classes:
            'flex h-full w-full items-center justify-center rounded-full bg-muted',
        child: text(currentFallback),
      );
    } else {
      content = div(
        classes:
            'flex h-full w-full items-center justify-center rounded-full bg-muted',
      );
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      child: content,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
