import 'package:coui_flutter/coui_flutter.dart' hide Skeleton;
import 'package:skeletonizer/skeletonizer.dart';

// Skeleton component animation constants.
const _kSkeletonDurationSeconds = 1;

/// Skeleton loading effect theme configuration.
///
/// Provides styling properties for skeleton loading animations including
/// pulse timing, colors, and animation behavior. These properties integrate
/// with the CoUI design system and work with the Skeletonizer package.
///
/// The theme enables consistent skeleton styling across the application
/// while allowing customization of animation characteristics and visual
/// appearance.
@Deprecated(
  'Style placeholders through CoreSkeletonStyle / CoreSkeletonTheme '
  '(since 0.156) — SkeletonTheme configures the skeletonizer effect behind '
  'asSkeleton, which is deprecated, and nothing in CoUI reads it.',
)
@immutable
class SkeletonTheme {
  /// Creates a [SkeletonTheme].
  ///
  /// All parameters are optional and may be null to use intelligent defaults
  /// that integrate with the current theme's color scheme and design system.
  ///
  /// Example:
  /// ```dart
  /// const SkeletonTheme(
  ///   duration: Duration(milliseconds: 800),
  ///   fromColor: Colors.grey.withOpacity(0.1),
  ///   toColor: Colors.grey.withOpacity(0.2),
  ///   enableSwitchAnimation: true,.
  /// );
  /// ```
  @Deprecated(
    'Style placeholders through CoreSkeletonStyle / CoreSkeletonTheme '
    '(since 0.156) — SkeletonTheme configures the skeletonizer effect behind '
    'asSkeleton, which is deprecated, and nothing in CoUI reads it.',
  )
  const SkeletonTheme({
    this.duration,
    this.enableSwitchAnimation,
    this.fromColor,
    this.toColor,
  });

  /// Duration of one complete pulse animation cycle.
  ///
  /// Type: `Duration?`. If null, defaults to 1 second for a natural
  /// breathing effect. Controls the speed of the fade in/out pulse animation.
  final Duration? duration;

  /// Starting color of the pulse animation.
  ///
  /// Type: `Color?`. If null, uses a default color from the theme at 5%
  /// opacity. Represents the lightest state of the skeleton shimmer effect.
  final Color? fromColor;

  /// Ending color of the pulse animation.
  ///
  /// Type: `Color?`. If null, uses a default color from the theme at 10%
  /// opacity. Represents the darkest state of the skeleton shimmer effect.
  final Color? toColor;

  /// Whether to enable smooth transitions when toggling skeleton state.
  ///
  /// Type: `bool?`. If null, defaults to true. When enabled, provides smooth
  /// fade transitions when turning skeleton visibility on and off.
  final bool? enableSwitchAnimation;

  /// Returns a copy with the given fields replaced.
  SkeletonTheme copyWith({
    ValueGetter<Duration?>? duration,
    ValueGetter<bool?>? enableSwitchAnimation,
    ValueGetter<Color?>? fromColor,
    ValueGetter<Color?>? toColor,
  }) {
    return SkeletonTheme(
      duration: duration == null ? this.duration : duration(),
      enableSwitchAnimation: enableSwitchAnimation == null
          ? this.enableSwitchAnimation
          : enableSwitchAnimation(),
      fromColor: fromColor == null ? this.fromColor : fromColor(),
      toColor: toColor == null ? this.toColor : toColor(),
    );
  }

  /// Merges this theme with [other], preferring this theme's values.
  SkeletonTheme mergeWith(SkeletonTheme? other) {
    if (other == null) return this;
    return SkeletonTheme(
      duration: duration ?? other.duration,
      enableSwitchAnimation:
          enableSwitchAnimation ?? other.enableSwitchAnimation,
      fromColor: fromColor ?? other.fromColor,
      toColor: toColor ?? other.toColor,
    );
  }

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

/// Configuration layer providing Skeletonizer settings with theme integration.
///
/// CoUISkeletonizerConfigLayer acts as a bridge between the CoUI theme system
/// and the Skeletonizer package, ensuring skeleton loading effects are
/// consistent with the overall design system. This widget wraps content with
/// properly configured skeleton animation settings.
///
/// The component automatically resolves theme values from [SkeletonTheme] and
/// applies appropriate defaults based on the current theme's color scheme and
/// scaling factor, creating a [SkeletonizerConfig] with [PulseEffect] for
/// smooth, accessible loading animations.
///
/// This is typically used internally by the skeleton extension method and
/// is rarely instantiated directly in application code.
///
/// Example:
/// ```dart
/// CoUISkeletonizerConfigLayer(
///   theme: Theme.of(context),
///   child: YourContentWidget(),.
/// );
/// ```
@Deprecated(
  'Goes with asSkeleton, which is deprecated (since 0.156) — placeholders '
  'are Skeleton and an area is announced once by LoadingRegion. CoUIApp '
  'keeps installing this layer until asSkeleton is removed.',
)
class CoUISkeletonizerConfigLayer extends StatelessWidget {
  /// Creates a [CoUISkeletonizerConfigLayer].
  ///
  /// The [theme] and [child] parameters are required for proper skeleton
  /// configuration and content wrapping. Override parameters allow fine-grained
  /// control of skeleton appearance at the layer level.
  ///
  /// Parameters:
  /// - [theme] (ThemeData, required): Theme for skeleton configuration
  ///   calculation.
  /// - [child] (Widget, required): Content to wrap with skeleton settings.
  /// - [duration] (Duration?, optional): Pulse animation duration override.
  /// - [fromColor] (Color?, optional): Pulse start color override.
  /// - [toColor] (Color?, optional): Pulse end color override.
  /// - [enableSwitchAnimation] (bool?, optional): Transition animation
  ///   behavior override.
  ///
  /// Example:
  /// ```dart
  /// CoUISkeletonizerConfigLayer(
  ///   theme: Theme.of(context),
  ///   duration: Duration(milliseconds: 1200),
  ///   child: MyContentWidget(),.
  /// );
  /// ```
  @Deprecated(
    'Goes with asSkeleton, which is deprecated (since 0.156) — placeholders '
    'are Skeleton and an area is announced once by LoadingRegion. CoUIApp '
    'keeps installing this layer until asSkeleton is removed.',
  )
  const CoUISkeletonizerConfigLayer({
    required this.child,
    required this.theme,
    this.duration,
    this.enableSwitchAnimation,
    this.fromColor,
    super.key,
    this.toColor,
  });

  /// Theme data used for skeleton configuration.
  ///
  /// Type: `ThemeData`, required. Provides color scheme, scaling factor, and
  /// other design system values for skeleton appearance calculations.
  final ThemeData theme;

  /// Child widget to wrap with skeleton configuration.
  ///
  /// Type: `Widget`, required. Content that will have skeleton configuration
  /// available through the widget tree.
  final Widget child;

  /// Override duration for the pulse animation cycle.
  ///
  /// Type: `Duration?`. When provided, overrides theme and default duration
  /// values for this specific configuration layer.
  final Duration? duration;

  /// Override start color for the pulse animation.
  ///
  /// Type: `Color?`. When provided, overrides theme and default color values
  /// for the lightest pulse state.
  final Color? fromColor;

  /// Override end color for the pulse animation.
  ///
  /// Type: `Color?`. When provided, overrides theme and default color values
  /// for the darkest pulse state.
  final Color? toColor;

  /// Override for transition animation behavior.
  ///
  /// Type: `bool?`. When provided, overrides theme and default animation
  /// behavior when toggling skeleton visibility.
  final bool? enableSwitchAnimation;

  @override
  Widget build(BuildContext context) {
    final durationValue =
        duration ?? const Duration(seconds: _kSkeletonDurationSeconds);
    final fromValue =
        fromColor ??
        theme.colorScheme.primary.scaleAlpha(CoreOpacity.opacity5).toValue();
    final toValue =
        toColor ??
        theme.colorScheme.primary.scaleAlpha(CoreOpacity.opacity10).toValue();
    final enableSwitchAnimationValue = enableSwitchAnimation ?? true;

    return SkeletonizerConfig(
      data: SkeletonizerConfigData(
        effect: PulseEffect(
          from: fromValue,
          to: toValue,
          duration: durationValue,
        ),
        enableSwitchAnimation: enableSwitchAnimationValue,
        // A fresh (non-static) transitionBuilder closure each build works
        // around the upstream AnimatedSwitcher duplicate-key crash on rapid
        // `enabled` toggle (flutter#121336 / skeletonizer#50): the default
        // static `AnimatedSwitcher.defaultTransitionBuilder` accumulates
        // same-keyed outgoing entries in its Stack. The fade is visually
        // identical to the default transition.
        switchAnimationConfig: SwitchAnimationConfig(
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: child,
    );
  }
}

/// Extension method for adding skeleton loading effects to any widget.
///
/// SkeletonExtension provides convenient methods for transforming normal
/// widgets into skeleton loading states with proper animation and theme
/// integration. These methods work with the Skeletonizer package while
/// ensuring consistency with the CoUI design system.
///
/// The extension handles common use cases including content loading, image
/// placeholders, form field loading, and complex layout skeletonization.
/// Different skeleton modes (sliver, leaf, unite, replace) provide flexibility
/// for various UI patterns and performance requirements.
///
/// Methods automatically detect specific widget types (Avatar, Image) and
/// apply appropriate skeleton handling to avoid common rendering issues.
@Deprecated(
  'Use Skeleton for each placeholder and wrap the area in LoadingRegion '
  '(since 0.156) — asSkeleton paints the widget tree through the skeletonizer '
  'package: its colours and pulse are not CoUI tokens, it has no Web '
  'counterpart, and it announces nothing.',
)
extension SkeletonExtension on Widget {
  /// Transforms a widget into a skeleton with advanced configuration options.
  ///
  /// Provides comprehensive skeleton transformation with multiple modes and
  /// automatic handling of problematic widget types. Supports [AsyncSnapshot]
  /// integration for automatic skeleton state management based on data loading.
  ///
  /// Special handling:
  /// - Avatar and Image widgets use [Skeleton.leaf] to avoid rendering issues.
  /// - The [snapshot] parameter automatically enables/disables based on data
  ///   state.
  /// - Various skeleton modes (leaf, unite, replace) for different use cases.
  ///
  /// Parameters:
  /// - [enabled] (bool, default: true): Whether the skeleton effect is enabled.
  /// - [leaf] (bool, default: false): Use leaf mode for simple widgets.
  /// - [replacement] (Widget?, optional): Custom replacement widget for
  ///   replace mode.
  /// - [unite] (bool, default: false): Use unite mode for complex layouts.
  /// - [snapshot] (AsyncSnapshot?, optional): Auto-enable based on data
  ///   loading state.
  ///
  /// Returns:
  /// A skeleton-wrapped widget with appropriate configuration for the
  /// specified mode.
  ///
  /// Example:
  /// ```dart
  /// FutureBuilder<String>(
  ///   future: loadData(),
  ///   builder: (context, snapshot) => Text(snapshot.data ?? 'Loading...')
  ///       .asSkeleton(snapshot: snapshot),
  /// );
  /// ```
  @Deprecated(
    'Use Skeleton for each placeholder and wrap the area in LoadingRegion '
    '(since 0.156) — asSkeleton paints the widget tree through the '
    'skeletonizer package: its colours and pulse are not CoUI tokens, it has '
    'no Web counterpart, and it announces nothing.',
  )
  Widget asSkeleton({
    bool enabled = true,
    bool leaf = false,
    Widget? replacement,
    AsyncSnapshot<dynamic>? snapshot,
    bool unite = false,
  }) {
    final effectiveEnabled = snapshot != null ? !snapshot.hasData : enabled;
    if (this is Avatar || this is Image) {
      // https://github.com/Milad-Akarie/skeletonizer/issues/17
      return Skeleton.leaf(enabled: effectiveEnabled, child: this);
    }
    if (unite) {
      return Skeleton.unite(unite: effectiveEnabled, child: this);
    }
    if (replacement != null) {
      return Skeleton.replace(replace: effectiveEnabled, child: replacement);
    }

    return leaf
        ? Skeleton.leaf(enabled: effectiveEnabled, child: this)
        : Skeletonizer(enabled: effectiveEnabled, child: this);
  }
}
