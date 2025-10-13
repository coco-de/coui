import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for banner dismiss.
typedef BannerDismissCallback = void Function();

/// A banner component for prominent messages.
///
/// Example:
/// ```dart
/// Banner(
///   message: 'Important announcement',
///   variant: BannerVariant.info,
///   onDismiss: () => print('Dismissed'),
/// )
/// ```
class Banner extends UiComponent {
  /// Creates a Banner component.
  ///
  /// Parameters:
  /// - [message]: Banner message
  /// - [variant]: Banner variant (info, warning, error, success)
  /// - [action]: Optional action button
  /// - [onDismiss]: Optional dismiss callback
  const Banner({
    super.key,
    required this.message,
    this.variant = BannerVariant.info,
    this.action,
    this.onDismiss,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Banner message.
  final String message;

  /// Banner variant.
  final BannerVariant variant;

  /// Optional action component.
  final Component? action;

  /// Optional dismiss callback.
  final BannerDismissCallback? onDismiss;

  static const _divValue = 'div';

  @override
  String get baseClass => 'flex items-center gap-4 p-4 border-l-4';

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      classes: '${_buildClasses()} ${_getVariantClasses()}',
      styles: css,
      attributes: {
        ...this.componentAttributes,
        'role': 'banner',
      },
      events: this.events,
      children: [
        // Icon
        div(
          classes: 'text-2xl',
          child: text(_getVariantIcon()),
        ),
        // Message
        div(
          classes: 'flex-1 text-sm font-medium',
          child: text(message),
        ),
        // Action
        if (action != null) action!,
        // Dismiss button
        if (onDismiss != null)
          button(
            classes:
                'rounded-full p-1 hover:bg-black/10 dark:hover:bg-white/10',
            attributes: {
              'type': 'button',
              'aria-label': 'Dismiss',
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
  Banner copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? message,
    BannerVariant? variant,
    Component? action,
    BannerDismissCallback? onDismiss,
    Key? key,
  }) {
    return Banner(
      key: key ?? this.key,
      message: message ?? this.message,
      variant: variant ?? this.variant,
      action: action ?? this.action,
      onDismiss: onDismiss ?? this.onDismiss,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  String _getVariantClasses() {
    return switch (variant) {
      BannerVariant.info =>
        'bg-blue-50 border-blue-500 text-blue-900 dark:bg-blue-950 dark:text-blue-100',
      BannerVariant.warning =>
        'bg-yellow-50 border-yellow-500 text-yellow-900 dark:bg-yellow-950 dark:text-yellow-100',
      BannerVariant.error =>
        'bg-red-50 border-red-500 text-red-900 dark:bg-red-950 dark:text-red-100',
      BannerVariant.success =>
        'bg-green-50 border-green-500 text-green-900 dark:bg-green-950 dark:text-green-100',
    };
  }

  String _getVariantIcon() {
    return switch (variant) {
      BannerVariant.info => 'ℹ',
      BannerVariant.warning => '⚠',
      BannerVariant.error => '✖',
      BannerVariant.success => '✓',
    };
  }
}

/// Banner variant options.
enum BannerVariant {
  /// Info banner (blue).
  info,

  /// Warning banner (yellow).
  warning,

  /// Error banner (red).
  error,

  /// Success banner (green).
  success,
}
