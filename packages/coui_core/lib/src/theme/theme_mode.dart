/// Theme mode for CoUI applications — controls whether the light or
/// dark `ThemeData` resolves at runtime.
///
/// Mirrors Flutter SDK's `ThemeMode` enum but lives in `coui_core` so
/// the same token drives both the Flutter (`CoUIApp.themeMode`) and
/// Web (`CoUIWeb.themeMode`) entry points without depending on
/// `package:flutter/material.dart`.
///
/// `system` follows the host OS / browser preference — Web reads
/// `prefers-color-scheme` media query, Flutter reads
/// `MediaQuery.platformBrightnessOf(context)`.
library;

/// How an app picks between its light and dark themes.
enum CoreThemeMode {
  /// Force dark theme regardless of OS preference.
  dark,

  /// Force light theme regardless of OS preference.
  light,

  /// Track the host platform / browser preference.
  system,
}
