import 'package:coui_flutter/coui_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Theme configuration for skeleton loading effects.
///
/// Provides styling properties for skeleton loading animations including pulse
/// timing, colors, and animation behavior. These properties integrate with the
/// coui design system and work with the underlying Skeletonizer package.
///
/// The theme enables consistent skeleton styling across the application while
/// allowing for customization of animation characteristics and visual appearance.
class SkeletonTheme {
  /// Creates a [SkeletonTheme].
  ///
  /// All parameters are optional and can be null to use intelligent defaults
  /// that integrate with the current theme's color scheme and design system.
  ///
  /// Example:
  /// ```dart
  /// const SkeletonTheme(
  ///   duration: Duration(milliseconds: 800),
  ///   fromColor: Colors.grey.withOpacity(0.1),
  ///   toColor: Colors.grey.withOpacity(0.2),
  ///   enableSwitchAnimation: true,
  /// );
  /// ```
  const SkeletonTheme({
    this.duration,
    this.enableSwitchAnimation,
    this.fromColor,
    this.toColor,
  });

  /// The duration of one complete pulse animation cycle.
  ///
  /// Type: `Duration?`. If null, defaults to 1 second for a natural breathing
  /// effect. Controls the speed of the fade in/out pulse animation.
  final Duration? duration;

  /// The starting color of the pulse animation.
  ///
  /// Type: `Color?`. If null, uses primary color with 5% opacity from theme.
  /// Represents the lightest state of the skeleton shimmer effect.
  final Color? fromColor;

  /// The ending color of the pulse animation.
  ///
  /// Type: `Color?`. If null, uses primary color with 10% opacity from theme.
  /// Represents the darkest state of the skeleton shimmer effect.
  final Color? toColor;

  /// Whether to enable smooth transitions when switching between skeleton states.
  ///
  /// Type: `bool?`. If null, defaults to true. When enabled, provides smooth
  /// fade transitions when toggling skeleton visibility on/off.
  final bool? enableSwitchAnimation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SkeletonTheme &&
        other.duration == duration &&
        other.fromColor == fromColor &&
        other.toColor == toColor &&
        other.enableSwitchAnimation == enableSwitchAnimation;
  }

  @override
  int get hashCode =>
      Object.hash(duration, fromColor, toColor, enableSwitchAnimation);
}

/// A configuration layer that provides Skeletonizer setup with theme integration.
///
/// CoUISkeletonizerConfigLayer acts as a bridge between the coui theme system
/// and the underlying Skeletonizer package, ensuring skeleton loading effects
/// are consistent with the overall design system. This widget wraps content
/// with properly configured skeleton animation settings.
///
/// The component automatically resolves theme values from [SkeletonTheme] and
/// applies appropriate defaults based on the current theme's color scheme and
/// scaling factors. It creates a [SkeletonizerConfig] with [PulseEffect] for
/// smooth, accessible loading animations.
///
/// This is typically used internally by skeleton extension methods and should
/// rarely be instantiated directly by application code.
///
/// Example:
/// ```dart
/// CoUISkeletonizerConfigLayer(
///   theme: Theme.of(context),
///   child: YourContentWidget(),
/// );
/// ```
class CoUISkeletonizerConfigLayer extends StatelessWidget {
  /// Creates a [CoUISkeletonizerConfigLayer].
  ///
  /// The [theme] and [child] parameters are required for proper skeleton
  /// configuration and content wrapping. Override parameters allow for
  /// fine-tuned control of skeleton appearance at the layer level.
  ///
  /// Parameters:
  /// - [theme] (ThemeData, required): Theme for skeleton configuration calculation
  /// - [child] (Widget, required): Content to wrap with skeleton configuration
  /// - [duration] (Duration?, optional): Pulse animation duration override
  /// - [fromColor] (Color?, optional): Pulse start color override
  /// - [toColor] (Color?, optional): Pulse end color override
  /// - [enableSwitchAnimation] (bool?, optional): Switch animation behavior override
  ///
  /// Example:
  /// ```dart
  /// CoUISkeletonizerConfigLayer(
  ///   theme: Theme.of(context),
  ///   duration: Duration(milliseconds: 1200),
  ///   child: MyContentWidget(),
  /// );
  /// ```
  const CoUISkeletonizerConfigLayer({
    required this.child,
    this.duration,
    this.enableSwitchAnimation,
    this.fromColor,
    super.key,
    required this.theme,
    this.toColor,
  });

  /// The theme data used for skeleton configuration.
  ///
  /// Type: `ThemeData`, required. Provides color scheme, scaling factors,
  /// and other design system values for skeleton appearance calculation.
  final ThemeData theme;

  /// The child widget to wrap with skeleton configuration.
  ///
  /// Type: `Widget`, required. The content that will have skeleton
  /// configuration available through the widget tree.
  final Widget child;

  /// Override duration for the pulse animation cycle.
  ///
  /// Type: `Duration?`. If provided, overrides theme and default duration
  /// values for this specific configuration layer.
  final Duration? duration;

  /// Override starting color for the pulse animation.
  ///
  /// Type: `Color?`. If provided, overrides theme and default color
  /// values for the lightest pulse state.
  final Color? fromColor;

  /// Override ending color for the pulse animation.
  ///
  /// Type: `Color?`. If provided, overrides theme and default color
  /// values for the darkest pulse state.
  final Color? toColor;

  /// Override switch animation behavior.
  ///
  /// Type: `bool?`. If provided, overrides theme and default animation
  /// behavior when toggling skeleton visibility.
  final bool? enableSwitchAnimation;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<SkeletonTheme>(context);
    final durationValue = styleValue(
      widgetValue: duration,
      themeValue: compTheme?.duration,
      defaultValue: const Duration(seconds: 1),
    );
    final fromValue = styleValue(
      widgetValue: fromColor,
      themeValue: compTheme?.fromColor,
      defaultValue: theme.colorScheme.primary.scaleAlpha(0.05),
    );
    final toValue = styleValue(
      widgetValue: toColor,
      themeValue: compTheme?.toColor,
      defaultValue: theme.colorScheme.primary.scaleAlpha(0.1),
    );
    final enableSwitchAnimationValue = styleValue(
      widgetValue: enableSwitchAnimation,
      themeValue: compTheme?.enableSwitchAnimation,
      defaultValue: true,
    );

    return SkeletonizerConfig(
      data: SkeletonizerConfigData(
        effect: PulseEffect(
          from: fromValue,
          to: toValue,
          duration: durationValue,
        ),
        enableSwitchAnimation: enableSwitchAnimationValue,
      ),
      child: child,
    );
  }
}

/// Extension methods for adding skeleton loading effects to any widget.
///
/// SkeletonExtension provides convenient methods to transform regular widgets
/// into skeleton loading states with proper animation and theming integration.
/// These methods work with the underlying Skeletonizer package while ensuring
/// consistency with the coui design system.
///
/// The extension handles common use cases including content loading, image
/// placeholders, form field loading, and complex layout skeletonization.
/// Different skeleton modes (sliver, leaf, unite, replace) provide flexibility
/// for various UI patterns and performance requirements.
///
/// Methods automatically detect certain widget types (Avatar, Image) and apply
/// appropriate skeleton handling to avoid common rendering issues.
extension SkeletonExtension on Widget {
  /// Converts the widget to a skeleton with advanced configuration options.
  ///
  /// Provides comprehensive skeleton transformation with multiple modes and
  /// automatic handling of problematic widget types. Supports [AsyncSnapshot]
  /// integration for automatic skeleton state management based on data loading.
  ///
  /// Special handling:
  /// - Avatar and Image widgets use [Skeleton.leaf] to avoid rendering issues
  /// - [snapshot] parameter automatically enables/disables based on data state
  /// - Various skeleton modes (leaf, unite, replace) for different use cases
  ///
  /// Parameters:
  /// - [enabled] (bool, default: true): Whether skeleton effect is active
  /// - [leaf] (bool, default: false): Use leaf mode for simple widgets
  /// - [replacement] (Widget?, optional): Custom replacement widget in replace mode
  /// - [unite] (bool, default: false): Use unite mode for complex layouts
  /// - [snapshot] (AsyncSnapshot?, optional): Auto-enable based on data loading state
  ///
  /// Returns:
  /// A skeleton-wrapped widget with appropriate configuration for the specified mode.
  ///
  /// Example:
  /// ```dart
  /// FutureBuilder<String>(
  ///   future: loadData(),
  ///   builder: (context, snapshot) => Text(snapshot.data ?? 'Loading...').asSkeleton(
  ///     snapshot: snapshot,
  ///   ),
  /// );
  /// ```
  Widget asSkeleton({
    bool enabled = true,
    bool leaf = false,
    Widget? replacement,
    AsyncSnapshot<dynamic>? snapshot,
    bool unite = false,
  }) {
    if (snapshot != null) {
      enabled = !snapshot.hasData;
    }
    if (this is Avatar || this is Image) {
      // https://github.com/Milad-Akarie/skeletonizer/issues/17
      return Skeleton.leaf(enabled: enabled, child: this);
    }
    if (unite) {
      return Skeleton.unite(unite: enabled, child: this);
    }
    if (replacement != null) {
      return Skeleton.replace(replace: enabled, child: replacement);
    }

    return leaf
        ? Skeleton.leaf(enabled: enabled, child: this)
        : Skeletonizer(enabled: enabled, child: this);
  }
}
