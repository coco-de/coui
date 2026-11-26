import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

/// Renders [child] in [brightness], whatever the theme around it.
///
/// The subtree takes the app's colours for that brightness — its palette, its
/// high-contrast set when the preference is on, the surface style's colour
/// bends — that brightness's shadow strength, its surface materials' fill
/// share and dimming, and the share of the frost and the strength of the body
/// shade an app turned on. Everything else stays the surrounding theme's:
/// component themes, typography, density, scaling, the surface style's
/// geometry and the rest of its material.
///
/// Named and shaped identically to the Web scope so an app reads the same call
/// on both platforms. Only the transport differs: here the subtree gets a
/// theme with the other brightness's colours, while on the Web the wrapper
/// carries `data-theme`, whose scoped rules restate the colour variables for
/// everything inside it.
///
/// The colours come from [AppBrightnessThemes], which `CoUIApp` publishes.
/// Outside one (a test harness, a hand-built root) a brightness the
/// surrounding theme already has keeps its colours, and the other one reads
/// CoUI's own preset for it, unfolded — no surface style bends it, and the
/// content material keeps the surroundings' numbers. A root that folds its
/// own theme publishes the pair itself to avoid that.
///
/// A panel the subtree opens — a popover, menu, tooltip, hover card or
/// dialog — captures the theme of the place it opened from, so it renders in
/// this brightness too; the Web panels state the scope again around
/// themselves to match. A drawer does not: its route builds its panel under
/// the navigator it is pushed on without capturing the opener's theme, so
/// the panel renders in the brightness around that navigator.
///
/// ```dart
/// // A light app previewed in a dark editor.
/// BrightnessScope(brightness: CoreBrightness.light, child: preview)
/// ```
class BrightnessScope extends StatelessWidget {
  /// Creates a scope rendering [child] in [brightness].
  const BrightnessScope({
    required this.brightness,
    required this.child,
    super.key,
  });

  /// The brightness [child] renders in.
  final CoreBrightness brightness;

  /// The subtree that renders in [brightness].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final around = Theme.of(context);
    final published = AppBrightnessThemes.maybeOf(context, brightness);
    final colorScheme =
        published?.colorScheme ??
        (around.coreBrightness == brightness
            ? around.colorScheme
            : ThemeData.fromCore(switch (brightness) {
                .light => CoreThemePresets.light,
                .dark => CoreThemePresets.dark,
              }).colorScheme);
    final theme = around.copyWith(
      colorScheme: () => colorScheme,
      // The shadow strength rides the geometry's brightness — a light
      // subtree under a dark page draws light-strength casts.
      geometry: () => around.geometry.copyWith(brightness: brightness),
      // The content material's fill share and dimming are numbers the fold
      // resolved for one brightness, so they come from the theme folded
      // for this one. The functional and nested materials keep their light
      // and dark pair and resolve it against the theme's brightness as
      // they paint, so they follow the swapped scheme on their own.
      // `copyWith` cannot clear the fill share, and needs not: both themes
      // were folded with the same style, so one states a material exactly
      // when the other does.
      surfaceOpacity: switch (published?.surfaceOpacity) {
        null => null,
        final opacity => () => opacity,
      },
      surfaceBackdropBrightness: published == null
          ? null
          : () => published.surfaceBackdropBrightness,
      // The cloud's share and the shade's strength are folded per brightness
      // too, so a dark scope in a light page draws the dark ones. The getter
      // returns null where the published theme states none, which is how a
      // brightness whose palette draws no shade clears the surrounding one.
      surfaceFrost: published == null ? null : () => published.surfaceFrost,
      surfaceBodyShade: published == null
          ? null
          : () => published.surfaceBodyShade,
    );
    // Text and icons inherit their colour from the root's defaults, which
    // were resolved in the surrounding brightness; restated here so a bare
    // `Text` inside reads this brightness's `onSurface` — the same restart the
    // Web scope makes with `color`.
    final onSurface = theme.colorScheme.onSurface.toValue();

    return Theme(
      data: theme,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: onSurface),
          child: child,
        ),
      ),
    );
  }
}

/// The app's theme in each brightness — published by `CoUIApp` so a
/// [BrightnessScope] renders what the app would render in that brightness.
///
/// Both are chosen and folded the way the active theme is: the high-contrast
/// set when the preference is on, the surface style, the density, the scaling.
/// A theme counts for the brightness it is, not the slot it was passed in —
/// an app may pass a single theme of either brightness and switch it itself.
/// A brightness the app gives no theme for is CoUI's preset for it, folded the
/// same way.
class AppBrightnessThemes extends InheritedWidget {
  /// Creates the published pair.
  const AppBrightnessThemes({
    required this.light,
    required this.dark,
    required super.child,
    super.key,
  });

  /// The app's theme in [brightness] at [context], or `null` when nothing
  /// above publishes one.
  static ThemeData? maybeOf(BuildContext context, CoreBrightness brightness) {
    final themes = context
        .dependOnInheritedWidgetOfExactType<AppBrightnessThemes>();
    if (themes == null) return null;

    return switch (brightness) {
      .light => themes.light,
      .dark => themes.dark,
    };
  }

  /// The app's light theme.
  final ThemeData light;

  /// The app's dark theme.
  final ThemeData dark;

  @override
  bool updateShouldNotify(AppBrightnessThemes oldWidget) =>
      light != oldWidget.light || dark != oldWidget.dark;
}
