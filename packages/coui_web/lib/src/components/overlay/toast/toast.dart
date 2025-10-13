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

  /// Internal variant reference.
  final ToastVariant _variant;

  static const _divValue = 'div';

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
      children: children ?? this.children,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...this.componentAttributes,
        'role': 'status',
        'aria-live': 'polite',
      },
      events: this.events,
      children: [
        // Content
        div(
          classes: 'grid gap-1',
          children: [
            // Title
            div(
              classes: 'text-sm font-semibold',
              child: text(title),
            ),
            // Description
            if (description != null)
              div(
                classes: 'text-sm opacity-90',
                child: text(description!),
              ),
          ],
        ),
        // Close button
        if (onDismiss != null)
          Component.element(
            tag: 'button',
            classes:
                'absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity hover:text-foreground focus:opacity-100 focus:outline-none focus:ring-2 group-hover:opacity-100',
            attributes: {
              'type': 'button',
              'aria-label': 'Close',
            },
            events: {
              'click': (event) => onDismiss!(),
            },
            child: text('\u00D7'),
          ),
      ],
    );
  }

  @override
  String get baseClass => '';

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    if (style != null) {
      for (final s in style!) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
