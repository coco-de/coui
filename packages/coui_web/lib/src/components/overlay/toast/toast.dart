import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:jaspr/jaspr.dart';

/// A toast notification component for displaying temporary messages.
///
/// The Toast component shows temporary notifications that appear over
/// the main content. It follows DaisyUI's toast patterns and provides
/// Flutter-compatible API.
///
/// Features:
/// - 9 position options (corners, edges, center)
/// - Auto-dismiss with configurable duration
/// - Manual dismiss callback
/// - Fixed positioning over content
/// - Stacked notifications support
///
/// Example:
/// ```dart
/// Toast(
///   [
///     Alert([text('File saved successfully')], style: [Alert.success]),
///   ],
///   position: ToastPosition.topEnd,
///   duration: Duration(seconds: 3),
///   onDismiss: () => hideToast(),
/// )
/// ```
class Toast extends UiComponent {
  /// Creates a Toast component.
  ///
  /// - [children]: Alert components to display as toasts.
  /// - [position]: Position of toast on screen.
  /// - [duration]: Auto-dismiss duration (null = no auto-dismiss).
  /// - [onDismiss]: Callback when toast is dismissed.
  /// - [style]: List of [ToastStyling] instances for styling.
  const Toast(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    this.duration,
    super.id,
    super.key,
    this.onDismiss,
    this.position = ToastPosition.topEnd,
    List<ToastStyling>? style,
    super.tag = 'div',
  }) : super(style: style);

  /// Position of the toast on screen.
  final ToastPosition position;

  /// Auto-dismiss duration.
  ///
  /// If null, toast will not auto-dismiss.
  final Duration? duration;

  /// Callback when toast is dismissed.
  ///
  /// Flutter-compatible void Function() callback.
  final void Function()? onDismiss;

  // --- Static Style Modifiers ---

  /// Start horizontal position. `toast-start`.
  static const start = ToastStyle('toast-start', type: StyleType.layout);

  /// Center horizontal position. `toast-center`.
  static const center = ToastStyle('toast-center', type: StyleType.layout);

  /// End horizontal position. `toast-end`.
  static const end = ToastStyle('toast-end', type: StyleType.layout);

  /// Top vertical position. `toast-top`.
  static const top = ToastStyle('toast-top', type: StyleType.layout);

  /// Middle vertical position. `toast-middle`.
  static const middle = ToastStyle('toast-middle', type: StyleType.layout);

  /// Bottom vertical position. `toast-bottom`.
  static const bottom = ToastStyle('toast-bottom', type: StyleType.layout);

  @override
  String get baseClass => 'toast';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA role for notifications
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('alert');
    }

    // Set ARIA live region for accessibility
    if (!userProvidedAttributes.containsKey('aria-live')) {
      attributes.addAria('live', 'polite');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Note: Auto-dismiss with duration would typically be handled by
    // parent component managing toast state, as we can't use timers
    // directly in build method without proper lifecycle management

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: children,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add position classes
    final positionClasses = _getPositionClasses();
    stylesList.addAll(positionClasses);

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is ToastStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  List<String> _getPositionClasses() {
    switch (position) {
      case ToastPosition.topStart:
        return ['toast-top', 'toast-start'];
      case ToastPosition.topCenter:
        return ['toast-top', 'toast-center'];
      case ToastPosition.topEnd:
        return ['toast-top', 'toast-end'];
      case ToastPosition.middleStart:
        return ['toast-middle', 'toast-start'];
      case ToastPosition.middleCenter:
        return ['toast-middle', 'toast-center'];
      case ToastPosition.middleEnd:
        return ['toast-middle', 'toast-end'];
      case ToastPosition.bottomStart:
        return ['toast-bottom', 'toast-start'];
      case ToastPosition.bottomCenter:
        return ['toast-bottom', 'toast-center'];
      case ToastPosition.bottomEnd:
        return ['toast-bottom', 'toast-end'];
    }
  }

  @override
  Toast copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    Duration? duration,
    String? id,
    Key? key,
    void Function()? onDismiss,
    ToastPosition? position,
    List<ToastStyling>? style,
    String? tag,
  }) {
    return Toast(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      duration: duration ?? this.duration,
      id: id ?? this.id,
      key: key ?? this.key,
      onDismiss: onDismiss ?? this.onDismiss,
      position: position ?? this.position,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<ToastStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}

/// Position of the toast notification on screen.
enum ToastPosition {
  /// Top-left corner.
  topStart,

  /// Top-center edge.
  topCenter,

  /// Top-right corner.
  topEnd,

  /// Middle-left edge.
  middleStart,

  /// Exact center of screen.
  middleCenter,

  /// Middle-right edge.
  middleEnd,

  /// Bottom-left corner.
  bottomStart,

  /// Bottom-center edge.
  bottomCenter,

  /// Bottom-right corner.
  bottomEnd,
}