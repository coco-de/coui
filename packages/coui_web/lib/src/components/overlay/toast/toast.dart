// ignore_for_file: avoid-using-non-ascii-symbols

import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for toast dismiss.
typedef ToastDismissCallback = void Function();

/// A toast notification component.
///
/// Example:
/// ```dart
/// Toast(
///   title: 'Success',
///   description: 'Your changes have been saved.',
///   onDismiss: () => print('Dismissed'),
/// )
/// ```
class Toast extends UiComponent {
  /// Creates a Toast component.
  ///
  /// Parameters:
  /// - [title]: Toast title
  /// - [description]: Toast description
  /// - [variant]: Toast variant (default or destructive)
  /// - [onDismiss]: Callback when toast is dismissed
  Toast({
    super.key,
    required this.title,
    this.description,
    ToastVariant variant = ToastVariant.default_,
    this.onDismiss,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : _variant = variant,
       super(
         null,
         style: [
           ToastVariantStyle(variant: variant),
         ],
       );

  /// Toast title.
  final String title;

  /// Toast description.
  final String? description;

  /// Callback when toast is dismissed.
  final ToastDismissCallback? onDismiss;

  /// Close icon character code (multiplication sign U+00D7).
  static const _kCloseIconCode = 0x00D7;

  /// Internal variant reference.
  final ToastVariant _variant;

  static const _divValue = 'div';

  /// Close icon character (multiplication sign).
  static String get _kCloseIcon => String.fromCharCode(_kCloseIconCode);

  @override
  Toast copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    ToastVariant? variant,
    ToastDismissCallback? onDismiss,
    String? title,
    String? description,
    Key? key,
  }) {
    return Toast(
      children: children ?? this.children,
      child: child ?? this.child,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      variant: variant ?? _variant,
      onDismiss: onDismiss ?? this.onDismiss,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'status',
        'aria-live': 'polite',
      },
      events: this.events,
      children: [
        // Content
        div(
          children: [
            // Title
            div(
              child: text(title),
              classes: 'text-sm font-semibold',
            ),
            // Description
            if (description != null)
              div(
                child: text(description),
                classes: 'text-sm opacity-90',
              ),
          ],
          classes: 'grid gap-1',
        ),
        // Close button
        if (onDismiss != null)
          Component.element(
            child: text(_kCloseIcon),
            tag: 'button',
            classes:
                'absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity hover:text-foreground focus:opacity-100 focus:outline-none focus:ring-2 group-hover:opacity-100',
            attributes: {
              'type': 'button',
              'aria-label': 'Close',
            },
            events: {
              'click': (event) => onDismiss(),
            },
          ),
      ],
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
