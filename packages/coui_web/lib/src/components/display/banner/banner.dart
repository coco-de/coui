// ignore_for_file: avoid-using-non-ascii-symbols

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

  /// Close icon character code (U+00D7 - ×).
  static const _kCloseIconCode = 0x00D7;

  /// Info icon character code (U+2139 - ℹ).
  static const _kInfoIconCode = 0x2139;

  /// Warning icon character code (U+26A0 - ⚠).
  static const _kWarningIconCode = 0x26A0;

  /// Error icon character code (U+2716 - ✖).
  static const _kErrorIconCode = 0x2716;

  /// Success icon character code (U+2713 - ✓).
  static const _kSuccessIconCode = 0x2713;

  static const _divValue = 'div';

  /// Close icon character.
  static String get _kCloseIcon => String.fromCharCode(_kCloseIconCode);

  /// Info icon character.
  static String get _kInfoIcon => String.fromCharCode(_kInfoIconCode);

  /// Warning icon character.
  static String get _kWarningIcon => String.fromCharCode(_kWarningIconCode);

  /// Error icon character.
  static String get _kErrorIcon => String.fromCharCode(_kErrorIconCode);

  /// Success icon character.
  static String get _kSuccessIcon => String.fromCharCode(_kSuccessIconCode);

  @override
  String get baseClass => 'flex items-center gap-4 p-4 border-l-4';

  @override
  Component build(BuildContext context) {
    final currentAction = action;
    final currentOnDismiss = onDismiss;

    return div(
      children: [
        // Icon
        div(
          child: text(_variantIcon),
          classes: 'text-2xl',
        ),
        // Message
        div(
          child: text(message),
          classes: 'flex-1 text-sm font-medium',
        ),
        // Action
        currentAction,
        // Dismiss button
        currentOnDismiss == null
            ? null
            : button(
                child: text(_kCloseIcon),
                classes:
                    'rounded-full p-1 hover:bg-black/10 dark:hover:bg-white/10',
                attributes: {
                  'type': 'button',
                  'aria-label': 'Dismiss',
                },
                events: {
                  'click': (event) => currentOnDismiss(),
                },
              ),
      ].nonNulls.toList(),
      id: id,
      classes: '${_buildClasses()} $_variantClasses',
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'banner',
      },
      events: this.events,
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

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  String get _variantClasses {
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

  String get _variantIcon {
    return switch (variant) {
      BannerVariant.info => _kInfoIcon,
      BannerVariant.warning => _kWarningIcon,
      BannerVariant.error => _kErrorIcon,
      BannerVariant.success => _kSuccessIcon,
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
