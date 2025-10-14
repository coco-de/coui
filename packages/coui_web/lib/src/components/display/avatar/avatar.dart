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
      fallback: fallback ?? this.fallback,
      alt: alt ?? this.alt,
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
      final attrs = {'src': currentSrc};
      final currentAlt = alt;
      if (currentAlt != null) {
        attrs['alt'] = currentAlt;
      }

      content = Component.element(
        tag: 'img',
        classes: 'aspect-square h-full w-full',
        attributes: attrs,
      );
    } else if (currentFallback != null) {
      content = div(
        child: text(currentFallback),
        classes:
            'flex h-full w-full items-center justify-center rounded-full bg-muted',
      );
    } else {
      content = div(
        classes:
            'flex h-full w-full items-center justify-center rounded-full bg-muted',
      );
    }

    return Component.element(
      child: content,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
