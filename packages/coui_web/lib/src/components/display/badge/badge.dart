import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/badge/badge_style.dart';
import 'package:jaspr/jaspr.dart';

/// A small visual indicator or label, often used for counts, statuses, or categories.
/// It typically renders as an HTML `<span>` with the 'badge' base class.
class Badge extends UiComponent {
  /// Creates a Badge component.
  ///
  /// - [children] or [child]: The content to display within the badge (e.g., text, an icon).
  /// - [tag]: The HTML tag for the root element, defaults to 'span'.
  /// - [style]: A list of [BadgeStyling].
  /// - [ariaLabel]: An optional accessible name for the badge.
  /// - Other parameters are inherited from [UiComponent].
  const Badge(
    super.children, {
    this.ariaLabel,
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    List<BadgeStyling>? style,
    super.tag = 'span',
  }) : super(style: style);

  /// An optional string to use as an `aria-label` for the badge.
  final String? ariaLabel; // --- Static Badge Styles ---

  // Styles
  /// Outline style badge. `badge-outline`.
  static const outline = BadgeStyle('badge-outline', type: StyleType.border);

  /// Dash outline style badge. `badge-dash` (New in DaisyUI 5).
  static const dash = BadgeStyle('badge-dash', type: StyleType.border);

  /// Soft style badge. `badge-soft` (New in DaisyUI 5).
  static const soft = BadgeStyle('badge-soft', type: StyleType.style);

  /// Ghost style badge (semi-transparent). `badge-ghost`.
  static const ghost = BadgeStyle('badge-ghost', type: StyleType.style);

  // Color styles
  /// Neutral color badge. `badge-neutral`.
  static const neutral = BadgeStyle('badge-neutral', type: StyleType.style);

  /// Primary color badge. `badge-primary`.
  static const primary = BadgeStyle('badge-primary', type: StyleType.style);

  /// Secondary color badge. `badge-secondary`.
  static const secondary = BadgeStyle(
    'badge-secondary',
    type: StyleType.style,
  );

  /// Accent color badge. `badge-accent`.
  static const accent = BadgeStyle('badge-accent', type: StyleType.style);

  /// Informational status color badge. `badge-info`.
  static const info = BadgeStyle('badge-info', type: StyleType.style);

  /// Success status color badge. `badge-success`.
  static const success = BadgeStyle('badge-success', type: StyleType.style);

  /// Warning status color badge. `badge-warning`.
  static const warning = BadgeStyle('badge-warning', type: StyleType.style);

  /// Error status color badge. `badge-error`.
  static const error = BadgeStyle('badge-error', type: StyleType.style);

  // Size styles
  /// Extra-small size badge. `badge-xs`.
  static const xs = BadgeStyle('badge-xs', type: StyleType.sizing);

  /// Small size badge. `badge-sm`.
  static const sm = BadgeStyle('badge-sm', type: StyleType.sizing);

  /// Medium size badge (often the default). `badge-md`.
  static const md = BadgeStyle('badge-md', type: StyleType.sizing);

  /// Large size badge. `badge-lg`.
  static const lg = BadgeStyle('badge-lg', type: StyleType.sizing);

  /// Extra-large size badge. `badge-xl` (New in DaisyUI 5).
  static const xl = BadgeStyle('badge-xl', type: StyleType.sizing);

  // HTML attribute constants
  static const _ariaLabelAttribute = 'label';

  @override
  String get baseClass => 'badge';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    final ariaLabelValue = ariaLabel;
    if (ariaLabelValue != null) {
      attributes.addAria(_ariaLabelAttribute, ariaLabelValue);
    }
    // Consider role="status" if the badge content updates dynamically to convey status changes.
    // This is context-dependent and might be better applied by the user.
  }

  @override
  Badge copyWith({
    String? ariaLabel,
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<BadgeStyling>? style,
    String? tag,
  }) {
    return Badge(
      children,
      key: key ?? this.key,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: style ?? this.style?.whereType<BadgeStyling>().toList(),
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}

/// Configuration for creating icon badges.
class IconBadgeConfig {
  const IconBadgeConfig({
    this.ariaLabel,
    this.classes,
    required this.icon,
    this.key,
    this.styles,
    required this.text,
  });
  final String? ariaLabel;
  final String? classes;
  final Component icon;
  final Key? key;
  final List<BadgeStyling>? styles;

  final String text;
}

/// Configuration for creating notification badges.
class NotificationBadgeConfig {
  const NotificationBadgeConfig({
    this.ariaLabel,
    this.classes,
    required this.count,
    this.key,
    this.styles,
  });
  final String? ariaLabel;
  final String? classes;
  final String count;
  final Key? key;

  final List<BadgeStyling>? styles;
}

/// Helper methods for creating common badge patterns.
abstract final class BadgeHelper {
  static const _notificationCountPrefix = 'Notification count: ';

  /// Creates a badge with an icon and text.
  static Badge createIconBadge(IconBadgeConfig config) {
    final icon = config.icon;
    final text = config.text;
    final key = config.key;
    final ariaLabel = config.ariaLabel;
    final classes = config.classes;
    final styles = config.styles;

    return Badge(
      [icon, Component.text(text)],
      key: key,
      ariaLabel: ariaLabel,
      classes: classes,
      style: styles,
    );
  }

  /// Creates a notification badge, typically displaying a count.
  static Badge createNotificationBadge(NotificationBadgeConfig config) {
    final count = config.count;
    final key = config.key;
    final ariaLabel = config.ariaLabel;
    final classes = config.classes;
    final styles = config.styles;

    return Badge(
      [Component.text(count)],
      key: key,
      ariaLabel: ariaLabel ?? _getDefaultCountLabel(count),
      classes: classes,
      style: styles,
    );
  }

  /// Creates an empty status badge, often used as a colored dot.
  /// An `ariaLabel` is highly recommended for accessibility if the badge's meaning isn't clear from context.
  static Badge createStatusBadge({
    String? ariaLabel,
    String? classes,
    Key? key,
    List<BadgeStyling>? styles,
  }) {
    return Badge(
      const [],
      key: key,
      ariaLabel: ariaLabel,
      classes: classes,
      style: styles,
    );
  }

  static String _getDefaultCountLabel(String count) {
    return '$_notificationCountPrefix$count';
  }
}
