import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing badge widget appearance across different styles.
///
/// This class defines the visual properties that can be applied to various
/// badge types including [PrimaryBadge], [SecondaryBadge], [OutlineBadge],
/// and [DestructiveBadge]. Each badge style can have its own button styling
/// configuration to provide consistent appearance across the application.
class BadgeTheme {
  /// Creates a [BadgeTheme].
  const BadgeTheme({
    this.destructiveStyle,
    this.outlineStyle,
    this.primaryStyle,
    this.secondaryStyle,
  });

  /// Style for [PrimaryBadge].
  final AbstractButtonStyle? primaryStyle;

  /// Style for [SecondaryBadge].
  final AbstractButtonStyle? secondaryStyle;

  /// Style for [OutlineBadge].
  final AbstractButtonStyle? outlineStyle;

  /// Style for [DestructiveBadge].
  final AbstractButtonStyle? destructiveStyle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BadgeTheme &&
        other.primaryStyle == primaryStyle &&
        other.secondaryStyle == secondaryStyle &&
        other.outlineStyle == outlineStyle &&
        other.destructiveStyle == destructiveStyle;
  }

  @override
  int get hashCode =>
      Object.hash(primaryStyle, secondaryStyle, outlineStyle, destructiveStyle);
}

/// A primary style badge widget for highlighting important information or status.
///
/// [PrimaryBadge] displays content in a prominent badge format using the primary
/// color scheme. It's designed for high-importance status indicators, labels,
/// and interactive elements that need to draw attention. The badge supports
/// leading and trailing widgets for icons or additional content.
///
/// Key features:
/// - Primary color styling with emphasis and contrast
/// - Optional tap handling for interactive badges
/// - Support for leading and trailing widgets (icons, counters, etc.)
/// - Customizable button styling through theme integration
/// - Compact size optimized for badge display
/// - Consistent visual hierarchy with other badge variants
///
/// The badge uses button-like styling but in a compact form factor suitable
/// for status displays, labels, and small interactive elements. It integrates
/// with the theme system to maintain visual consistency.
///
/// Common use cases:
/// - Status indicators (active, new, featured)
/// - Notification counts and alerts
/// - Category labels and tags
/// - Interactive filter chips
/// - Achievement or ranking displays
///
/// Example:
/// ```dart
/// PrimaryBadge(
///   child: Text('NEW'),
///   leading: Icon(Icons.star, size: 16),
///   onPressed: () => _showNewItems(),
/// );
///
/// // Non-interactive status badge
/// PrimaryBadge(
///   child: Text('5'),
///   trailing: Icon(Icons.notifications, size: 14),
/// );
/// ```
class PrimaryBadge extends StatelessWidget {
  const PrimaryBadge({
    required this.child,
    super.key,
    this.leading,
    this.onPressed,
    this.style,
    this.trailing,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  final AbstractButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<BadgeTheme>(context);
    final baseStyle =
        style ??
        compTheme?.primaryStyle ??
        const ButtonStyle.primary(
          density: ButtonDensity.dense,
          size: ButtonSize.small,
        ).copyWith(
          textStyle: (context, states, value) {
            return value.copyWith(fontWeight: FontWeight.w500);
          },
        );

    return ExcludeFocus(
      child: Button(
        enabled: true,
        leading: leading,
        onPressed: onPressed,
        style: baseStyle,
        trailing: trailing,
        child: child,
      ),
    );
  }
}

class SecondaryBadge extends StatelessWidget {
  const SecondaryBadge({
    required this.child,
    super.key,
    this.leading,
    this.onPressed,
    this.style,
    this.trailing,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  final AbstractButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<BadgeTheme>(context);
    final baseStyle =
        style ??
        compTheme?.secondaryStyle ??
        const ButtonStyle.secondary(
          density: ButtonDensity.dense,
          size: ButtonSize.small,
        ).copyWith(
          textStyle: (context, states, value) {
            return value.copyWith(fontWeight: FontWeight.w500);
          },
        );

    return ExcludeFocus(
      child: Button(
        enabled: true,
        leading: leading,
        onPressed: onPressed,
        style: baseStyle,
        trailing: trailing,
        child: child,
      ),
    );
  }
}

class OutlineBadge extends StatelessWidget {
  const OutlineBadge({
    required this.child,
    super.key,
    this.leading,
    this.onPressed,
    this.style,
    this.trailing,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  final AbstractButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<BadgeTheme>(context);
    final baseStyle =
        style ??
        compTheme?.outlineStyle ??
        const ButtonStyle.outline(
          density: ButtonDensity.dense,
          size: ButtonSize.small,
        ).copyWith(
          textStyle: (context, states, value) {
            return value.copyWith(fontWeight: FontWeight.w500);
          },
        );

    return ExcludeFocus(
      child: Button(
        enabled: true,
        leading: leading,
        onPressed: onPressed,
        style: baseStyle,
        trailing: trailing,
        child: child,
      ),
    );
  }
}

class DestructiveBadge extends StatelessWidget {
  const DestructiveBadge({
    required this.child,
    super.key,
    this.leading,
    this.onPressed,
    this.style,
    this.trailing,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  final AbstractButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<BadgeTheme>(context);
    final baseStyle =
        style ??
        compTheme?.destructiveStyle ??
        const ButtonStyle.destructive(
          density: ButtonDensity.dense,
          size: ButtonSize.small,
        ).copyWith(
          textStyle: (context, states, value) {
            return value.copyWith(fontWeight: FontWeight.w500);
          },
        );

    return ExcludeFocus(
      child: Button(
        enabled: true,
        leading: leading,
        onPressed: onPressed,
        style: baseStyle,
        trailing: trailing,
        child: child,
      ),
    );
  }
}
