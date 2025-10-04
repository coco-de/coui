/// Color scheme for web themes.
library;

import 'brightness.dart';

/// Base color scheme.
class ColorScheme {
  /// Creates a color scheme.
  const ColorScheme({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.error,
    required this.onError,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.outline,
  });

  /// Brightness mode.
  final Brightness brightness;

  /// Primary color.
  final String primary;

  /// Color on primary.
  final String onPrimary;

  /// Secondary color.
  final String secondary;

  /// Color on secondary.
  final String onSecondary;

  /// Error color.
  final String error;

  /// Color on error.
  final String onError;

  /// Background color.
  final String background;

  /// Color on background.
  final String onBackground;

  /// Surface color.
  final String surface;

  /// Color on surface.
  final String onSurface;

  /// Outline color.
  final String outline;

  /// Default light color scheme.
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: '#3b82f6',
    onPrimary: '#ffffff',
    secondary: '#8b5cf6',
    onSecondary: '#ffffff',
    error: '#ef4444',
    onError: '#ffffff',
    background: '#ffffff',
    onBackground: '#18181b',
    surface: '#ffffff',
    onSurface: '#18181b',
    outline: '#d4d4d8',
  );

  /// Default dark color scheme.
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: '#60a5fa',
    onPrimary: '#1e3a8a',
    secondary: '#a78bfa',
    onSecondary: '#4c1d95',
    error: '#f87171',
    onError: '#7f1d1d',
    background: '#09090b',
    onBackground: '#fafafa',
    surface: '#18181b',
    onSurface: '#fafafa',
    outline: '#52525b',
  );

  /// Converts to CSS variables.
  Map<String, String> toCssVariables() {
    return {
      '--color-primary': primary,
      '--color-on-primary': onPrimary,
      '--color-secondary': secondary,
      '--color-on-secondary': onSecondary,
      '--color-error': error,
      '--color-on-error': onError,
      '--color-background': background,
      '--color-on-background': onBackground,
      '--color-surface': surface,
      '--color-on-surface': onSurface,
      '--color-outline': outline,
    };
  }

  /// Converts to DaisyUI theme.
  Map<String, String> toDaisyUITheme() {
    return {
      'primary': primary,
      'primary-content': onPrimary,
      'secondary': secondary,
      'secondary-content': onSecondary,
      'error': error,
      'error-content': onError,
      'base-100': surface,
      'base-content': onSurface,
    };
  }
}
