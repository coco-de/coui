import 'dart:convert';

import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:coui_core/src/theme/core_theme_data.dart';

/// Parses CoUI theme JSON into [CoreThemeData].
///
/// Supports the CoUI theme format where colors are defined as
/// OKLch strings or hex values.
class ThemeParser {
  const ThemeParser._();

  /// Parse a CoUI theme JSON string into [CoreThemeData].
  static CoreThemeData parse(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return fromMap(map);
  }

  /// Parse a CoUI theme map into [CoreThemeData].
  static CoreThemeData fromMap(Map<String, dynamic> map) {
    final colorScheme = CoreColorScheme.fromMap(map);
    final brightnessStr = map['brightness'] as String?;
    final brightness = brightnessStr == 'dark'
        ? CoreBrightness.dark
        : CoreBrightness.light;

    return CoreThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      designSystem: .coui,
    );
  }

  /// Parse multiple named themes from a CoUI config.
  ///
  /// Expects format: `{ "light": { ...colors }, "dark": { ...colors } }`.
  static Map<String, CoreThemeData> parseMultiple(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final result = <String, CoreThemeData>{};

    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = fromMap(entry.value as Map<String, dynamic>);
      }
    }

    return result;
  }
}
