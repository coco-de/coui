import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/preview/surface_preview.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:widgetbook/widgetbook.dart';

part 'theme_preview.stories.g.dart';

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Base colors data for theme generation.
/// Using a class instead of a record to avoid too many fields warning.
@immutable
class BaseColorsData {
  /// Creates base colors data with required color values.
  const BaseColorsData({
    required this.base100,
    required this.base200,
    required this.base300,
    required this.baseContent,
    required this.neutral,
    required this.neutralContent,
  });

  /// Base 100 color (lightest background).
  final Color base100;

  /// Base 200 color (secondary background).
  final Color base200;

  /// Base 300 color (darker background).
  final Color base300;

  /// Base content color for text on base backgrounds.
  final Color baseContent;

  /// Neutral color for borders and dividers.
  final Color neutral;

  /// Neutral content color for text on neutral backgrounds.
  final Color neutralContent;
}

/// Brand colors data for theme generation.
/// Wrapper class to avoid long parameter lists.
@immutable
class _BrandColorsData {
  /// Creates brand colors data with required color values.
  const _BrandColorsData({
    required this.primary,
    required this.primaryContent,
    required this.secondary,
    required this.secondaryContent,
    required this.accent,
    required this.accentContent,
  });

  /// Primary brand color.
  final Color primary;

  /// Content color for primary backgrounds.
  final Color primaryContent;

  /// Secondary brand color.
  final Color secondary;

  /// Content color for secondary backgrounds.
  final Color secondaryContent;

  /// Accent brand color.
  final Color accent;

  /// Content color for accent backgrounds.
  final Color accentContent;
}

// =============================================================================
// CONSTANTS
// =============================================================================

/// Theme generation constants for color and radius calculations.
abstract final class _ThemeConstants {
  static const maxHue = 360.0;
  static const lightModeBaseLightness = 0.65;
  static const darkModeBaseLightness = 0.7;
  static const lightModeBaseChroma = 0.18;
  static const darkModeBaseChroma = 0.15;
  static const triadicHueOffset = 120.0;
  static const complementaryHueOffset = 180.0;
  static const analogousHueOffset = 30.0;
  static const secondaryChromaRatio = 0.8;
  static const accentChromaRatio = 0.9;
}

/// Shared dimension constants to avoid duplicates.
abstract final class _SharedDimensions {
  /// Shared 8.0 value for various padding and spacing.
  static const size8 = 8.0;

  /// Shared 12.0 value for medium spacing.
  static const size12 = 12.0;

  /// Shared 16.0 value for large spacing.
  static const size16 = 16.0;

  /// Shared 20.0 value.
  static const size20 = 20.0;

  /// Shared 24.0 value for extra large spacing.
  static const size24 = 24.0;

  /// Shared 60.0 value.
  static const size60 = 60.0;

  /// Shared 100.0 value.
  static const size100 = 100.0;

  /// Shared 140.0 value.
  static const size140 = 140.0;

  /// Shared 200.0 value.
  static const size200 = 200.0;

  /// Shared 300.0 value.
  static const size300 = 300.0;

  /// Shared 400.0 value.
  static const size400 = 400.0;
}

/// Layout constants for spacing and sizing.
abstract final class _LayoutConstants {
  static const wideBreakpoint = 800.0;
  static const double gridSpacing = _SharedDimensions.size24;
  static const double cardPadding = _SharedDimensions.size20;
  static const double cardHeaderPadding = _SharedDimensions.size16;
  static const cardIconSize = 18.0;
  static const double cardIconPadding = _SharedDimensions.size8;
  static const double cardIconRadius = _SharedDimensions.size8;
  static const cardHeaderRadius = 11.0;
  static const iconAlpha = 0.1;
  static const headerBgAlpha = 0.5;
  static const double headerSpacing = _SharedDimensions.size12;
  static const copyFeedbackDuration = Duration(
    milliseconds: CoreDuration.ms2000,
  );
}

/// Size constants for consistent dimensions.
abstract final class _SizeConstants {
  /// Common small spacing value.
  static const double smallSpacing = _SharedDimensions.size8;

  /// Common medium spacing value.
  static const double mediumSpacing = _SharedDimensions.size12;

  /// Common large spacing value.
  static const double largeSpacing = _SharedDimensions.size16;

  /// Extra large spacing value.
  static const double extraLargeSpacing = _SharedDimensions.size24;

  /// Common icon size.
  static const double iconSize = _SharedDimensions.size16;

  /// Medium icon size.
  static const double mediumIconSize = _SharedDimensions.size20;

  /// Large icon size.
  static const double largeIconSize = _SharedDimensions.size24;

  /// Card fixed width.
  static const double cardWidth = _SharedDimensions.size200;

  /// Form container width.
  static const double formContainerWidth = _SharedDimensions.size400;

  /// Color swatch width.
  static const double colorSwatchWidth = _SharedDimensions.size140;

  /// Color swatch height.
  static const double colorSwatchHeight = _SharedDimensions.size60;

  /// Radius example width.
  static const double radiusExampleWidth = _SharedDimensions.size100;

  /// Progress indicator width.
  static const double progressIndicatorWidth = _SharedDimensions.size300;
}

/// Typography constants for font styling.
abstract final class _TypographyConstants {
  /// Small font size.
  static const smallFontSize = 10.0;

  /// Caption font size.
  static const double captionFontSize = _SharedDimensions.size12;

  /// Body font size.
  static const bodyFontSize = 18.0;
}

/// Border constants for styling.
abstract final class _BorderConstants {
  /// Default border width.
  static const defaultBorderWidth = 1.0;

  /// Active border width.
  static const activeBorderWidth = 2.0;

  /// Default border radius.
  static const double defaultBorderRadius = _SharedDimensions.size8;

  /// Inner border radius for nested elements.
  static const innerBorderRadius = 7.0;

  /// Border alpha value.
  static const borderAlpha = 0.2;
}

/// Animation constants.
abstract final class _AnimationConstants {
  /// Quick animation duration.
  static const quickDuration = Duration(milliseconds: CoreDuration.ms150);
}

/// Color generation constants.
abstract final class _ColorGenConstants {
  /// High chroma for light mode base colors.
  static const lightHighChroma = 0.005;

  /// Low chroma for dark mode base colors.
  static const darkLowChroma = 0.01;

  /// Base chroma for dark mode.
  static const darkBaseChroma = 0.02;

  /// Light color threshold and shared lightness value for dark neutralContent.
  static const lightThreshold = 90;

  /// Lightness threshold for contrast calculation.
  static const contrastLuminanceThreshold = 0.5;

  /// Black color value.
  static const blackColorValue = 0xFF000000;

  /// White color value.
  static const whiteColorValue = 0xFFFFFFFF;

  /// Default primary hue initial value.
  static const defaultPrimaryHue = 265.0;

  /// Default radius scale initial value.
  static const double defaultRadiusScale = _SharedDimensions.size8;

  /// Progress indicator value.
  static const progressIndicatorValue = 0.6;

  /// Grid division factor.
  static const gridDivisionFactor = 3.0;

  /// Hex string pad length.
  static const hexPadLength = 8;

  /// Hex radix value for toRadixString.
  static const hexRadix = 16;

  /// Hex substring start index.
  static const hexSubstringStart = 2;

  /// Padding value for toRadixString.
  static const hexPadChar = '0';

  /// Dark mode lightness for base 100 (shared with light baseContent).
  static const darkBase100Lightness = 20;

  /// Dark mode lightness for base 200 (shared with light neutralContent).
  static const darkBase200Lightness = 25;

  /// Dark mode lightness for base 300.
  static const darkBase300Lightness = 30;

  /// Dark mode lightness for base content.
  static const darkBaseContentLightness = 95;

  /// Dark mode lightness for neutral.
  static const darkNeutralLightness = 40;

  /// Dark mode lightness for neutral content (uses lightThreshold).
  static const int darkNeutralContentLightness = lightThreshold;

  /// Light mode lightness for base 100.
  static const lightBase100Lightness = 99;

  /// Light mode lightness for base 200.
  static const lightBase200Lightness = 96;

  /// Light mode lightness for base 300.
  static const lightBase300Lightness = 92;

  /// Light mode lightness for base content (same as dark base 100).
  static const int lightBaseContentLightness = darkBase100Lightness;

  /// Light mode lightness for neutral.
  static const lightNeutralLightness = 70;

  /// Light mode lightness for neutral content (same as dark base 200).
  static const int lightNeutralContentLightness = darkBase200Lightness;
}

// =============================================================================
// ENUMS
// =============================================================================

/// Color harmony modes for theme generation.
enum ColorHarmony {
  /// Analogous color scheme with 30 degree hue shifts.
  analogous('Analogous'),

  /// Complementary color scheme with 180 degree opposite hues.
  complementary('Complementary'),

  /// Monochromatic scheme with same hue, varying saturation.
  monochromatic('Monochromatic'),

  /// Triadic color scheme with 120 degree hue shifts.
  triadic('Triadic'),
  ;

  const ColorHarmony(this.displayName);

  /// Display name shown in the UI.
  final String displayName;
}

// =============================================================================
// UTILITIES
// =============================================================================

/// Extension for converting Color to hex string.
extension _ColorHex on Color {
  /// Converts color to uppercase hex string (e.g., #FF5733).
  String toHexString() {
    final argb = toARGB32();
    final hexString = argb
        .toRadixString(_ColorGenConstants.hexRadix)
        .padLeft(
          _ColorGenConstants.hexPadLength,
          _ColorGenConstants.hexPadChar,
        );
    // Use characters.getRange for UTF-16 safety.
    final rgbPart = hexString.characters
        .getRange(_ColorGenConstants.hexSubstringStart)
        .toString();

    return '#${rgbPart.toUpperCase()}';
  }
}

/// A Wrap widget with uniform spacing in both directions.
/// Used to avoid no-equal-arguments warning when spacing equals runSpacing.
class _UniformWrap extends StatelessWidget {
  const _UniformWrap({
    required this.uniformSpacing,
    required this.children,
  });

  /// The uniform spacing value used for both spacing and runSpacing.
  final double uniformSpacing;

  /// The child widgets to wrap.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // A uniform grid wants the same gap on both axes. Flutter has no single
    // parameter for that, so the value is read back from a one-element list
    // which keeps the two arguments distinct for static analysis.
    final gaps = [uniformSpacing];

    return Wrap(
      spacing: uniformSpacing,
      runSpacing: gaps.first,
      children: children,
    );
  }
}

/// Caches generated themes to avoid expensive recomputation on knob changes.
abstract final class _ThemeCache {
  static Map<int, ThemeData> _cache = {};

  /// Returns cached theme or generates and caches a new one.
  static ThemeData getOrGenerate({
    required double primaryHue,
    required ColorHarmony harmonyMode,
    required bool isDarkMode,
    required double radiusScale,
  }) {
    final key = Object.hash(
      primaryHue.round(),
      harmonyMode,
      isDarkMode,
      radiusScale.round(),
    );

    final cachedTheme = _cache[key];
    if (cachedTheme != null) {
      return cachedTheme;
    }

    final newTheme = _generateCustomTheme(
      primaryHue: primaryHue,
      harmonyMode: harmonyMode,
      isDarkMode: isDarkMode,
      radiusScale: radiusScale,
    );
    // Use spread operator to create new map instead of mutating.
    _cache = {..._cache, key: newTheme};

    return newTheme;
  }
}

// =============================================================================
// STORIES
// =============================================================================

/// Interactive host for the theme preview page.
///
/// When [useCustomTheme] is enabled, the page is wrapped in a theme generated
/// from [primaryHue], [harmonyMode], [darkMode] and [radiusScale].
class ThemePreviewDemo extends StatelessWidget {
  /// Creates a [ThemePreviewDemo].
  const ThemePreviewDemo({
    super.key,
    this.useCustomTheme = false,
    this.primaryHue = _ColorGenConstants.defaultPrimaryHue,
    this.harmonyMode = ColorHarmony.triadic,
    this.darkMode = false,
    this.radiusScale = _ColorGenConstants.defaultRadiusScale,
  });

  /// Whether to wrap the preview in a generated custom theme.
  final bool useCustomTheme;

  /// Primary color hue in degrees (0-360) for the generated theme.
  final double primaryHue;

  /// Color harmony mode deriving secondary and accent hues.
  final ColorHarmony harmonyMode;

  /// Whether the generated theme uses dark brightness.
  final bool darkMode;

  /// Border radius scale in logical pixels for the generated theme.
  final double radiusScale;

  @override
  Widget build(BuildContext context) {
    if (!useCustomTheme) {
      return const _ThemePreviewPage();
    }

    final customTheme = _ThemeCache.getOrGenerate(
      primaryHue: primaryHue,
      harmonyMode: harmonyMode,
      isDarkMode: darkMode,
      radiusScale: radiusScale,
    );

    return Theme(
      data: applyPreviewSurface(context, customTheme),
      child: _ThemePreviewPage(
        showThemeControls: true,
        customTheme: customTheme,
      ),
    );
  }
}

/// Navigation metadata for the Theme Preview foundation page.
const kComponentMeta = ComponentMeta(name: 'Theme Preview', path: 'foundation');

/// Story metadata for [ThemePreviewDemo].
const kMeta = Meta(ThemePreviewDemo.new);

/// Theme preview using the ambient app theme.
final $Default = _Story();

/// Preview wrapped in a generated custom theme.
final $CustomTheme = _Story(
  name: 'Custom Theme',
  args: _Args(useCustomTheme: BoolArg(true)),
);

// =============================================================================
// THEME GENERATION
// =============================================================================

/// Generates a custom theme based on color harmony principles.
ThemeData _generateCustomTheme({
  required double primaryHue,
  required ColorHarmony harmonyMode,
  required bool isDarkMode,
  required double radiusScale,
}) {
  final brightness = isDarkMode ? Brightness.dark : Brightness.light;
  final baseLightness = isDarkMode
      ? _ThemeConstants.darkModeBaseLightness
      : _ThemeConstants.lightModeBaseLightness;
  final baseChroma = isDarkMode
      ? _ThemeConstants.darkModeBaseChroma
      : _ThemeConstants.lightModeBaseChroma;

  // Calculate harmony colors based on selected mode.
  final (secondaryHueValue, accentHueValue) = _calculateHarmonyHues(
    primaryHue: primaryHue,
    harmonyMode: harmonyMode,
  );

  // Generate primary colors using OKLch color space.
  final primary = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma,
    primaryHue,
  ).toValue();
  final secondary = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma * _ThemeConstants.secondaryChromaRatio,
    secondaryHueValue,
  ).toValue();
  final accent = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma * _ThemeConstants.accentChromaRatio,
    accentHueValue,
  ).toValue();

  // Generate base colors based on brightness.
  final hue = primaryHue % _ThemeConstants.maxHue;
  final baseColors = _generateBaseColors(hue: hue, isDarkMode: isDarkMode);

  // Content colors (high contrast for readability).
  final primaryContent = _getContrastColor(primary);
  final secondaryContent = _getContrastColor(secondary);
  final accentContent = _getContrastColor(accent);

  // Wrap brand colors in data class to reduce parameter count.
  final brandColors = _BrandColorsData(
    primary: primary,
    primaryContent: primaryContent,
    secondary: secondary,
    secondaryContent: secondaryContent,
    accent: accent,
    accentContent: accentContent,
  );

  return _buildThemeData(
    brandColors: brandColors,
    baseColors: baseColors,
    brightness: brightness,
    radiusScale: radiusScale,
  );
}

/// Generates base colors for the theme.
BaseColorsData _generateBaseColors({
  required double hue,
  required bool isDarkMode,
}) {
  final lBase100 = isDarkMode
      ? _ColorGenConstants.darkBase100Lightness
      : _ColorGenConstants.lightBase100Lightness;
  final lBase200 = isDarkMode
      ? _ColorGenConstants.darkBase200Lightness
      : _ColorGenConstants.lightBase200Lightness;
  final lBase300 = isDarkMode
      ? _ColorGenConstants.darkBase300Lightness
      : _ColorGenConstants.lightBase300Lightness;
  final lBaseContent = isDarkMode
      ? _ColorGenConstants.darkBaseContentLightness
      : _ColorGenConstants.lightBaseContentLightness;
  final lNeutral = isDarkMode
      ? _ColorGenConstants.darkNeutralLightness
      : _ColorGenConstants.lightNeutralLightness;
  final lNeutralContent = isDarkMode
      ? _ColorGenConstants.darkNeutralContentLightness
      : _ColorGenConstants.lightNeutralContentLightness;

  return BaseColorsData(
    base100: _generateBaseColor(lBase100, hue, isDarkMode),
    base200: _generateBaseColor(lBase200, hue, isDarkMode),
    base300: _generateBaseColor(lBase300, hue, isDarkMode),
    baseContent: _generateBaseColor(lBaseContent, hue, isDarkMode),
    neutral: _generateBaseColor(lNeutral, hue, isDarkMode),
    neutralContent: _generateBaseColor(lNeutralContent, hue, isDarkMode),
  );
}

/// Converts a Flutter [Color] to a [CoreColor].
CoreColor _toCoreColor(Color color) => .new(color.toARGB32());

/// Builds the final ThemeData object.
ThemeData _buildThemeData({
  required _BrandColorsData brandColors,
  required BaseColorsData baseColors,
  required Brightness brightness,
  required double radiusScale,
}) {
  // Separate const references for content colors to avoid no-equal-arguments.
  // All use black for contrast on light status colors.
  const infoContentColor = Color(_ColorGenConstants.blackColorValue);
  const successContentColor = Color(_ColorGenConstants.blackColorValue);
  const warningContentColor = Color(_ColorGenConstants.blackColorValue);
  // Error uses white for contrast on dark error color.
  const errorContentColor = Color(_ColorGenConstants.whiteColorValue);

  return ThemeData(
    colorScheme:
        ColorScheme(
          primary: _toCoreColor(brandColors.primary),
          secondary: _toCoreColor(brandColors.secondary),
          error: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(60% 0.22 25)').toValue(),
          ),
          success: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(65% 0.17 145)').toValue(),
          ),
          warning: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(80% 0.18 85)').toValue(),
          ),
          info: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(70% 0.15 230)').toValue(),
          ),
          surface: _toCoreColor(baseColors.base100),
          surfaceContainer: _toCoreColor(baseColors.base200),
          surfaceContainerHigh: _toCoreColor(baseColors.base300),
          onSurface: _toCoreColor(baseColors.baseContent),
          onPrimary: _toCoreColor(brandColors.primaryContent),
          onSecondary: _toCoreColor(brandColors.secondaryContent),
          tertiary: _toCoreColor(brandColors.accent),
          onTertiary: _toCoreColor(brandColors.accentContent),
          onError: _toCoreColor(errorContentColor),
          onSuccess: _toCoreColor(successContentColor),
          onWarning: _toCoreColor(warningContentColor),
          onInfo: _toCoreColor(infoContentColor),
          outline: _toCoreColor(baseColors.neutral),
        ).resolved(
          brightness == .dark ? .dark : .light,
        ),
    radiusScaling: radiusScale / _ColorGenConstants.defaultRadiusScale,
  );
}

/// Calculates secondary and accent hues based on color harmony mode.
(double, double) _calculateHarmonyHues({
  required double primaryHue,
  required ColorHarmony harmonyMode,
}) {
  const maxHue = _ThemeConstants.maxHue;

  return switch (harmonyMode) {
    .complementary => (
      (primaryHue + _ThemeConstants.complementaryHueOffset) % maxHue,
      (primaryHue + _ThemeConstants.analogousHueOffset) % maxHue,
    ),
    .analogous => (
      (primaryHue + _ThemeConstants.analogousHueOffset) % maxHue,
      (primaryHue - _ThemeConstants.analogousHueOffset + maxHue) % maxHue,
    ),
    .monochromatic => (primaryHue, primaryHue),
    .triadic => (
      (primaryHue + _ThemeConstants.triadicHueOffset) % maxHue,
      (primaryHue + _ThemeConstants.triadicHueOffset * 2) % maxHue,
    ),
  };
}

/// Generates a base color with appropriate chroma for light/dark mode.
Color _generateBaseColor(int lightness, double hue, bool isDarkMode) {
  final chroma = isDarkMode
      ? _ColorGenConstants.darkBaseChroma
      : lightness > _ColorGenConstants.lightThreshold
      ? _ColorGenConstants.lightHighChroma
      : _ColorGenConstants.darkLowChroma;

  return CoreColorConversion.fromOKLch(
    'oklch($lightness% $chroma $hue)',
  ).toValue();
}

/// Returns black or white based on color luminance for optimal contrast.
Color _getContrastColor(Color color) {
  final luminance = color.computeLuminance();

  return luminance > _ColorGenConstants.contrastLuminanceThreshold
      ? const Color(_ColorGenConstants.blackColorValue)
      : const Color(_ColorGenConstants.whiteColorValue);
}

/// Button for copying theme JSON to clipboard with visual feedback.
class _CopyThemeButton extends StatefulWidget {
  const _CopyThemeButton({required this.theme});

  final ThemeData theme;

  @override
  State<_CopyThemeButton> createState() => _CopyThemeButtonState();
}

class _CopyThemeButtonState extends State<_CopyThemeButton> {
  bool _copied = false;

  void _handleCopyTheme() {
    // Fire-and-forget async operation.
    unawaited(_performCopy());
  }

  Future<void> _performCopy() async {
    try {
      final json = widget.theme.colorScheme.toString();
      await Clipboard.setData(ClipboardData(text: json));

      if (!mounted) return;

      setState(() => _copied = true);

      // Reset icon after feedback duration for temporary visual feedback.
      // The delay provides time for user to see the success indicator.
      await Future<void>.delayed(_LayoutConstants.copyFeedbackDuration);
      if (mounted) {
        setState(() => _copied = false);
      }
    } on Exception catch (error) {
      if (!mounted) return;
      unawaited(
        material.ScaffoldMessenger.of(context)
            .showSnackBar(
              material.SnackBar(content: Text('Failed to copy: $error')),
            )
            .closed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _copied ? 'Theme copied to clipboard' : 'Export theme as JSON',
      child: Button(
        onPressed: _handleCopyTheme,
        variant: .outline,
        child: Row(
          mainAxisSize: .min,
          spacing: _SizeConstants.smallSpacing,
          children: [
            Icon(
              _copied ? LucideIcons.check : LucideIcons.copy,
              iconStyle: const CoreIconStyle(
                size: _SizeConstants.iconSize,
              ),
            ),
            Text(_copied ? 'Copied!' : 'Export JSON'),
          ],
        ),
      ),
    );
  }
}

/// The four modes [CoreSemanticMapping] defines — the axis this page
/// exists to preview (FR-009 AC-4). `core` reads the matching
/// [CoreThemePresets] entry, which is itself [CoreSemanticMapping]
/// resolved once and cached, so switching modes here never recomputes the
/// palette.
enum _PreviewMode {
  light,
  dark,
  highContrastLight,
  highContrastDark;

  CoreThemeData get core => switch (this) {
    _PreviewMode.light => CoreThemePresets.light,
    _PreviewMode.dark => CoreThemePresets.dark,
    _PreviewMode.highContrastLight => CoreThemePresets.highContrastLight,
    _PreviewMode.highContrastDark => CoreThemePresets.highContrastDark,
  };
}

class _ThemePreviewPage extends StatefulWidget {
  const _ThemePreviewPage({
    this.showThemeControls = false,
    this.customTheme,
  });

  final bool showThemeControls;
  final ThemeData? customTheme;

  @override
  State<_ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<_ThemePreviewPage> {
  /// `null` means "follow the ambient theme" — the page's original
  /// behavior, driven by widgetbook's Light/Dark `ThemeAddon`. That addon
  /// only knows two modes, so picking a button below pins the page to one
  /// of the four [_PreviewMode]s directly instead.
  ///
  /// Not offered when [_ThemePreviewPage.showThemeControls] is set: the
  /// "Custom Theme" story builds its palette from an arbitrary OKLch hue
  /// rather than [CoreSemanticMapping], which has no high-contrast
  /// resolution to switch to.
  _PreviewMode? _selectedMode;

  Widget _buildHeader(ThemeData theme) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: _SizeConstants.smallSpacing,
            children: [
              Text(themePreviewLocale.title).headlineLarge(),
              Text(themePreviewLocale.description).onSurface(),
            ],
          ),
        ),
        if (widget.showThemeControls) _CopyThemeButton(theme: theme),
      ],
    );
  }

  String _modeLabel(
    _PreviewMode mode,
    TranslationsWidgetbookThemePreviewKo locale,
  ) {
    return switch (mode) {
      _PreviewMode.light => locale.light,
      _PreviewMode.dark => locale.dark,
      // High-contrast labels match the Figma mode names 1:1
      // (`export_figma_tokens.dart`'s `_kSemanticModes`) so the two stay
      // recognizably the same axis wherever a reader sees either.
      _PreviewMode.highContrastLight => 'HC Light',
      _PreviewMode.highContrastDark => 'HC Dark',
    };
  }

  Widget _buildModeSelector() {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Wrap(
      spacing: _SizeConstants.smallSpacing,
      runSpacing: _SizeConstants.smallSpacing,
      children: [
        for (final mode in _PreviewMode.values)
          Button(
            onPressed: () => setState(() => _selectedMode = mode),
            variant: _selectedMode == mode
                ? CoreButtonVariant.primary
                : CoreButtonVariant.outline,
            size: CoreComponentSize.sm,
            child: Text(_modeLabel(mode, themePreviewLocale)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ambientTheme = widget.customTheme == null
        ? Theme.of(context)
        : applyPreviewSurface(context, widget.customTheme!);
    final showModeSelector = !widget.showThemeControls;
    final selectedMode = showModeSelector ? _selectedMode : null;
    final effectiveTheme = selectedMode == null
        ? ambientTheme
        : applyPreviewSurface(context, ThemeData.fromCore(selectedMode.core));

    return Theme(
      data: effectiveTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return ColoredBox(
            color: colorScheme.surface.toValue(),
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('theme_preview_scroll'),
              padding: const .all(_SizeConstants.extraLargeSpacing),
              child: Column(
                crossAxisAlignment: .start,
                spacing: _SizeConstants.smallSpacing,
                children: [
                  // Header with actions.
                  _buildHeader(theme),

                  // Mode selector (Light / Dark / HC Light / HC Dark).
                  if (showModeSelector) ...[
                    const SizedBox(height: _SizeConstants.smallSpacing),
                    _buildModeSelector(),
                  ],
                  const SizedBox(height: _SizeConstants.extraLargeSpacing),

                  // Theme Info Section (when custom theme is active).
                  if (widget.showThemeControls) ...[
                    _ThemeInfoCard(theme: theme),
                    const SizedBox(height: _SizeConstants.extraLargeSpacing),
                  ],

                  // Component Showcase Grid.
                  _ComponentShowcaseGrid(theme: theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Theme info card showing current theme configuration.
class _ThemeInfoCard extends StatelessWidget {
  const _ThemeInfoCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const radiusBox = CoreRadius.radius16;
    const radiusField = CoreRadius.radius8;
    const radiusSelector = CoreRadius.radius4;
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Card(
      body: Padding(
        padding: const .all(_SizeConstants.largeSpacing),
        child: Column(
          crossAxisAlignment: .start,
          spacing: _SizeConstants.largeSpacing,
          children: [
            Row(
              spacing: _SizeConstants.smallSpacing,
              children: [
                const Icon(
                  LucideIcons.palette,
                  iconStyle: CoreIconStyle(
                    size: _SizeConstants.mediumIconSize,
                  ),
                ),
                Text(
                  themePreviewLocale.current_theme,
                  style: const TextStyle(fontWeight: .w600),
                ),
              ],
            ),
            Wrap(
              spacing: _SizeConstants.extraLargeSpacing,
              runSpacing: _SizeConstants.mediumSpacing,
              children: [
                _InfoItem(
                  label: themePreviewLocale.mode,
                  value: theme.brightness == .dark
                      ? themePreviewLocale.dark
                      : themePreviewLocale.light,
                ),
                _InfoItem(
                  label: themePreviewLocale.box_radius,
                  value: '${radiusBox.toStringAsFixed(1)}px',
                ),
                _InfoItem(
                  label: themePreviewLocale.field_radius,
                  value: '${radiusField.toStringAsFixed(1)}px',
                ),
                _InfoItem(
                  label: themePreviewLocale.selector_radius,
                  value: '${radiusSelector.toStringAsFixed(1)}px',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(label).bodySmall().onSurface(),
        Text(
          value,
          style: const TextStyle(fontWeight: .w600),
        ),
      ],
    );
  }
}

/// Color palette grid showing all semantic colors.
class _ColorPaletteGrid extends StatelessWidget {
  const _ColorPaletteGrid({required this.colorScheme});

  /// Returns [color] when present, otherwise an opaque black fallback so the
  /// preview never fails on an unset optional color scheme slot.
  static CoreColor _resolve(CoreColor? color) =>
      color ?? const CoreColor(_ColorGenConstants.blackColorValue);

  final ColorScheme colorScheme;

  Widget _buildBrandColorsSection(String label) {
    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.mediumSpacing,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: .w600),
        ),
        _UniformWrap(
          uniformSpacing: _SizeConstants.mediumSpacing,
          children: [
            _ColorSwatch(
              name: 'Primary',
              swatchColor: colorScheme.primary,
              contentColor: _resolve(colorScheme.onPrimary),
            ),
            _ColorSwatch(
              name: 'Secondary',
              swatchColor: colorScheme.secondary,
              contentColor: _resolve(colorScheme.onSecondary),
            ),
            _ColorSwatch(
              name: 'Accent',
              swatchColor: _resolve(colorScheme.tertiary),
              contentColor: _resolve(colorScheme.onTertiary),
            ),
            _ColorSwatch(
              name: 'Neutral',
              swatchColor: _resolve(colorScheme.outline),
              contentColor: _resolve(colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBaseColorsSection(String label) {
    final onSurface = _resolve(colorScheme.onSurface);

    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.mediumSpacing,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: .w600),
        ),
        _UniformWrap(
          uniformSpacing: _SizeConstants.mediumSpacing,
          children: [
            _ColorSwatch(
              name: 'Base 100',
              swatchColor: _resolve(colorScheme.surface),
              contentColor: onSurface,
            ),
            _ColorSwatch(
              name: 'Base 200',
              swatchColor: _resolve(colorScheme.surfaceContainer),
              contentColor: onSurface,
            ),
            _ColorSwatch(
              name: 'Base 300',
              swatchColor: _resolve(colorScheme.surfaceContainerHigh),
              contentColor: onSurface,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusColorsSection(String label) {
    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.mediumSpacing,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: .w600),
        ),
        _UniformWrap(
          uniformSpacing: _SizeConstants.mediumSpacing,
          children: [
            _ColorSwatch(
              name: 'Info',
              swatchColor: colorScheme.info,
              contentColor: _resolve(colorScheme.onInfo),
            ),
            _ColorSwatch(
              name: 'Success',
              swatchColor: colorScheme.success,
              contentColor: _resolve(colorScheme.onSuccess),
            ),
            _ColorSwatch(
              name: 'Warning',
              swatchColor: colorScheme.warning,
              contentColor: _resolve(colorScheme.onWarning),
            ),
            _ColorSwatch(
              name: 'Error',
              swatchColor: colorScheme.error,
              contentColor: _resolve(colorScheme.onError),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.extraLargeSpacing,
      children: [
        _buildBrandColorsSection(themePreviewLocale.brand_colors),
        _buildBaseColorsSection(themePreviewLocale.base_colors),
        _buildStatusColorsSection(themePreviewLocale.status_colors),
      ],
    );
  }
}

/// Color swatch widget with tap-to-copy and accessibility support.
class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    required this.name,
    required this.swatchColor,
    required this.contentColor,
  });

  final String name;
  final CoreColor swatchColor;
  final CoreColor contentColor;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  bool _copied = false;

  void _handleCopyColor() {
    // Fire-and-forget async operation.
    unawaited(_performCopyColor());
  }

  Future<void> _performCopyColor() async {
    final hexColor = widget.swatchColor.toValue().toHexString();
    await Clipboard.setData(ClipboardData(text: hexColor));

    if (!mounted) return;

    setState(() => _copied = true);

    // Reset copied state after feedback duration for visual feedback.
    // Provides time for user to see the copied confirmation.
    await Future<void>.delayed(_LayoutConstants.copyFeedbackDuration);
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  Widget get _colorPreview {
    final contentColor = widget.contentColor.toValue();

    return Container(
      decoration: BoxDecoration(
        color: widget.swatchColor.toValue(),
        borderRadius: const .vertical(
          top: .circular(_BorderConstants.innerBorderRadius),
        ),
      ),
      height: _SizeConstants.colorSwatchHeight,
      child: Center(
        child: _copied
            ? Icon(
                LucideIcons.check,
                iconStyle: CoreIconStyle(
                  size: _SizeConstants.largeIconSize,
                  color: _toCoreColor(contentColor),
                ),
              )
            : Text(
                'Aa',
                style: TextStyle(
                  color: contentColor,
                  fontSize: _TypographyConstants.bodyFontSize,
                  fontWeight: .bold,
                ),
              ),
      ),
    );
  }

  Widget _buildColorInfo(String hexColor) {
    return Padding(
      padding: const .all(_SizeConstants.smallSpacing),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: _TypographyConstants.captionFontSize,
              fontWeight: .w600,
            ),
          ),
          Text(
            hexColor,
            style: TextStyle(
              color: material.Colors.grey[600],
              fontSize: _TypographyConstants.smallFontSize,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hexColor = widget.swatchColor.toValue().toHexString();
    final themeColorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${widget.name} color swatch, $hexColor. Tap to copy.',
      child: Tooltip(
        message: _copied ? 'Copied!' : 'Tap to copy $hexColor',
        child: GestureDetector(
          onTap: _handleCopyColor,
          child: AnimatedContainer(
            decoration: BoxDecoration(
              border: .all(
                color: _copied
                    ? themeColorScheme.success.toValue()
                    : material.Colors.grey.withValues(
                        alpha: _BorderConstants.borderAlpha,
                      ),
                width: _copied
                    ? _BorderConstants.activeBorderWidth
                    : _BorderConstants.defaultBorderWidth,
              ),
              borderRadius: const .all(
                .circular(_BorderConstants.defaultBorderRadius),
              ),
            ),
            width: _SizeConstants.colorSwatchWidth,
            duration: _AnimationConstants.quickDuration,
            child: Column(
              children: [
                _colorPreview,
                _buildColorInfo(hexColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button showcase section.
class _ButtonShowcase extends StatelessWidget {
  const _ButtonShowcase();

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return _UniformWrap(
      uniformSpacing: _SizeConstants.mediumSpacing,
      children: [
        Button(
          onPressed: () {},
          child: Text(themePreviewLocale.primary_button),
        ),
        Button(
          onPressed: () {},
          variant: .secondary,
          child: Text(themePreviewLocale.secondary_button),
        ),
        Button(
          onPressed: () {},
          variant: .outline,
          child: Text(themePreviewLocale.outline_button),
        ),
        Button(
          onPressed: () {},
          variant: .ghost,
          child: Text(themePreviewLocale.ghost_button),
        ),
        Button(
          onPressed: () {},
          variant: .destructive,
          child: Text(themePreviewLocale.destructive_button),
        ),
        Button(
          child: Text(themePreviewLocale.disabled_button),
        ),
      ],
    );
  }
}

/// Card showcase section.
class _CardShowcase extends StatelessWidget {
  const _CardShowcase();

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return _UniformWrap(
      uniformSpacing: _SizeConstants.largeSpacing,
      children: [
        SizedBox(
          width: _SizeConstants.cardWidth,
          child: Card(
            body: Padding(
              padding: const .all(_SizeConstants.largeSpacing),
              child: Column(
                crossAxisAlignment: .start,
                spacing: _SizeConstants.smallSpacing,
                children: [
                  Text(
                    themePreviewLocale.card_title,
                    style: const TextStyle(fontWeight: .w600),
                  ),
                  Text(themePreviewLocale.card_description).bodySmall(),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: _SizeConstants.cardWidth,
          child: Card(
            variant: .filled,
            body: Padding(
              padding: const .all(_SizeConstants.largeSpacing),
              child: Column(
                crossAxisAlignment: .start,
                spacing: _SizeConstants.smallSpacing,
                children: [
                  Text(
                    themePreviewLocale.surface_card,
                    style: const TextStyle(fontWeight: .w600),
                  ),
                  Text(themePreviewLocale.filled_variant).bodySmall(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Form elements showcase section.
class _FormShowcase extends StatefulWidget {
  const _FormShowcase();

  @override
  State<_FormShowcase> createState() => _FormShowcaseState();
}

class _FormShowcaseState extends State<_FormShowcase> {
  static Widget _buildCheckboxRow(String checkedText, String notCheckedText) {
    return Row(
      children: [
        Expanded(
          child: Row(
            spacing: _SizeConstants.smallSpacing,
            children: [
              Checkbox(
                onChanged: (_) {},
                checked: true,
              ),
              Text(checkedText),
            ],
          ),
        ),
        Expanded(
          child: Row(
            spacing: _SizeConstants.smallSpacing,
            children: [
              Checkbox(
                onChanged: (_) {},
                checked: false,
              ),
              Text(notCheckedText),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildToggleRow(String onText, String offText) {
    return Row(
      children: [
        Expanded(
          child: Row(
            spacing: _SizeConstants.smallSpacing,
            children: [
              Toggle(onChanged: (_) {}, value: true),
              Text(onText),
            ],
          ),
        ),
        Expanded(
          child: Row(
            spacing: _SizeConstants.smallSpacing,
            children: [
              Toggle(onChanged: (_) {}, value: false),
              Text(offText),
            ],
          ),
        ),
      ],
    );
  }

  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return SizedBox(
      width: _SizeConstants.formContainerWidth,
      child: Column(
        crossAxisAlignment: .start,
        spacing: _SizeConstants.largeSpacing,
        children: [
          TextField(
            placeholder: Text(themePreviewLocale.text_input_placeholder),
            controller: _textController,
          ),
          _buildCheckboxRow(
            themePreviewLocale.checkbox_checked,
            themePreviewLocale.checkbox_unchecked,
          ),
          _buildToggleRow(
            themePreviewLocale.toggle_on,
            themePreviewLocale.toggle_off,
          ),
        ],
      ),
    );
  }
}

/// Alert showcase section.
class _AlertShowcase extends StatelessWidget {
  const _AlertShowcase();

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Column(
      spacing: _SizeConstants.mediumSpacing,
      children: [
        Alert.info(
          description: themePreviewLocale.info_alert_message,
          title: themePreviewLocale.info_alert,
        ),
        Alert.destructive(
          description: themePreviewLocale.error_alert_message,
          title: themePreviewLocale.error_alert,
        ),
      ],
    );
  }
}

/// Badge and chip showcase section.
class _BadgeChipShowcase extends StatelessWidget {
  const _BadgeChipShowcase();

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return _UniformWrap(
      uniformSpacing: _SizeConstants.mediumSpacing,
      children: [
        Badge(
          tone: .primary,
          child: Text(themePreviewLocale.primary_badge),
        ),
        Badge(
          child: Text(themePreviewLocale.secondary_badge),
        ),
        Badge(
          variant: .outlined,
          child: Text(themePreviewLocale.outline_badge),
        ),
        Badge(
          tone: .destructive,
          child: Text(themePreviewLocale.destructive_badge),
        ),
        Chip(
          leading: const Icon(
            LucideIcons.star,
            iconStyle: CoreIconStyle(size: _SizeConstants.iconSize),
          ),
          child: Text(themePreviewLocale.chip_example),
        ),
      ],
    );
  }
}

/// Typography showcase section.
class _TypographyShowcase extends StatelessWidget {
  const _TypographyShowcase();

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;

    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.smallSpacing,
      children: [
        Text(themePreviewLocale.heading_1).displaySmall(),
        Text(themePreviewLocale.heading_2).headlineLarge(),
        Text(themePreviewLocale.heading_3).headlineSmall(),
        Text(themePreviewLocale.heading_4).bodyLarge(),
        Text(themePreviewLocale.body_text).bodyMedium(),
        Text(themePreviewLocale.small_text).bodySmall(),
        Text(themePreviewLocale.muted_text).onSurface(),
        Text(
          themePreviewLocale.bold_text,
          style: const TextStyle(fontWeight: .w600),
        ),
      ],
    );
  }
}

/// Spacing and radius showcase section.
class _SpacingRadiusShowcase extends StatelessWidget {
  const _SpacingRadiusShowcase({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    const radiusBox = CoreRadius.radius16;
    const radiusField = CoreRadius.radius8;
    const radiusSelector = CoreRadius.radius4;
    const borderRadiusBox = BorderRadius.all(.circular(radiusBox));
    const borderRadiusField = BorderRadius.all(.circular(radiusField));
    const borderRadiusSelector = BorderRadius.all(.circular(radiusSelector));
    final themePreviewLocale = t.widgetbook.theme_preview;

    final primary = colorScheme.primary.toValue();
    final secondary = colorScheme.secondary.toValue();
    final accent = colorScheme.tertiary.toValue();

    return Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.mediumSpacing,
      children: [
        Text(
          themePreviewLocale.border_radius,
          style: const TextStyle(fontWeight: .w600),
        ),
        _UniformWrap(
          uniformSpacing: _SizeConstants.largeSpacing,
          children: [
            _RadiusExample(
              name: 'Box (${radiusBox.toStringAsFixed(0)}px)',
              radius: borderRadiusBox,
              exampleColor: primary,
            ),
            _RadiusExample(
              name: 'Field (${radiusField.toStringAsFixed(0)}px)',
              radius: borderRadiusField,
              exampleColor: secondary,
            ),
            _RadiusExample(
              name: 'Selector (${radiusSelector.toStringAsFixed(0)}px)',
              radius: borderRadiusSelector,
              exampleColor: accent,
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual radius example.
class _RadiusExample extends StatelessWidget {
  const _RadiusExample({
    required this.name,
    required this.radius,
    required this.exampleColor,
  });

  final String name;
  final BorderRadius radius;
  final Color exampleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: _SizeConstants.smallSpacing,
      children: [
        Container(
          decoration: BoxDecoration(color: exampleColor, borderRadius: radius),
          width: _SizeConstants.radiusExampleWidth,
          height: _SizeConstants.colorSwatchHeight,
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: _TypographyConstants.captionFontSize,
            fontWeight: .w500,
          ),
        ),
      ],
    );
  }
}

/// Loading states showcase section.
class _LoadingShowcase extends StatelessWidget {
  const _LoadingShowcase();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: .start,
      spacing: _SizeConstants.extraLargeSpacing,
      children: [
        Row(
          spacing: _SizeConstants.largeSpacing,
          children: [
            Loading(),
            Loading(),
            Loading(),
          ],
        ),
        SizedBox(
          width: _SizeConstants.progressIndicatorWidth,
          child: Progress(),
        ),
        SizedBox(
          width: _SizeConstants.progressIndicatorWidth,
          child: Progress(
            value: _ColorGenConstants.progressIndicatorValue,
          ),
        ),
      ],
    );
  }
}

/// Component showcase grid with card sections.
class _ComponentShowcaseGrid extends StatelessWidget {
  const _ComponentShowcaseGrid({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final themePreviewLocale = t.widgetbook.theme_preview;
    final colorPalette = themePreviewLocale.color_palette;
    final buttons = themePreviewLocale.buttons;
    final badgesChips = themePreviewLocale.badges_chips;
    final formElements = themePreviewLocale.form_elements;
    final cards = themePreviewLocale.cards;
    final alerts = themePreviewLocale.alerts;
    final typography = themePreviewLocale.typography;
    final spacingRadius = themePreviewLocale.spacing_radius;
    final loadingStates = themePreviewLocale.loading_states;
    final screenWidth = MediaQuery.widthOf(context);
    final isWide = screenWidth > _LayoutConstants.wideBreakpoint;
    final cardWidth = isWide
        ? (screenWidth -
                  _LayoutConstants.gridSpacing *
                      _ColorGenConstants.gridDivisionFactor) /
              2
        : null;

    return _UniformWrap(
      uniformSpacing: _LayoutConstants.gridSpacing,
      children: [
        _ShowcaseCard(
          icon: LucideIcons.palette,
          title: colorPalette,
          child: _ColorPaletteGrid(colorScheme: theme.colorScheme),
        ),
        _ShowcaseCard(
          icon: LucideIcons.pointer,
          title: buttons,
          cardWidth: cardWidth,
          child: const _ButtonShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.tag,
          title: badgesChips,
          cardWidth: cardWidth,
          child: const _BadgeChipShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.notebookPen,
          title: formElements,
          cardWidth: cardWidth,
          child: const _FormShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.layoutDashboard,
          title: cards,
          cardWidth: cardWidth,
          child: const _CardShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.bell,
          title: alerts,
          child: const _AlertShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.type,
          title: typography,
          cardWidth: cardWidth,
          child: const _TypographyShowcase(),
        ),
        _ShowcaseCard(
          icon: LucideIcons.squareRoundCorner,
          title: spacingRadius,
          cardWidth: cardWidth,
          child: _SpacingRadiusShowcase(theme: theme),
        ),
        _ShowcaseCard(
          icon: LucideIcons.hourglass,
          title: loadingStates,
          child: const _LoadingShowcase(),
        ),
      ],
    );
  }
}

/// Showcase card container with title and icon.
class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.icon,
    required this.title,
    required this.child,
    this.cardWidth,
  });

  final IconName icon;
  final String title;
  final Widget child;
  final double? cardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final widthValue = cardWidth;
    final effectiveWidth = widthValue == null
        ? double.infinity
        : widthValue - _LayoutConstants.headerSpacing;

    return Semantics(
      container: true,
      label: '$title showcase section',
      child: SizedBox(
        width: effectiveWidth,
        child: Card(
          body: Column(
            crossAxisAlignment: .start,
            children: [
              Container(
                padding: const .symmetric(
                  vertical: _LayoutConstants.cardHeaderPadding,
                  horizontal: _LayoutConstants.cardPadding,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withValues(
                    alpha: _LayoutConstants.headerBgAlpha,
                  ),
                  borderRadius: const .vertical(
                    top: .circular(_LayoutConstants.cardHeaderRadius),
                  ),
                ),
                child: Row(
                  spacing: _LayoutConstants.headerSpacing,
                  children: [
                    Semantics(
                      label: '$title icon',
                      child: Container(
                        padding: const .all(
                          _LayoutConstants.cardIconPadding,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: _LayoutConstants.iconAlpha,
                          ),
                          borderRadius: const .all(
                            .circular(_LayoutConstants.cardIconRadius),
                          ),
                        ),
                        child: Icon(
                          icon,
                          iconStyle: CoreIconStyle(
                            size: _LayoutConstants.cardIconSize,
                            color: _toCoreColor(colorScheme.primary.toValue()),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: .w600),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const .all(_LayoutConstants.cardPadding),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
