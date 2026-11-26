import 'dart:convert';

import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:coui_core/src/theme/core_theme_data.dart';
import 'package:coui_core/src/theme/design_system.dart';

/// JSON serialization utilities for design tokens (Figma roundtrip support).
class TokenSerialization {
  const TokenSerialization._();

  /// Serialize [CoreThemeData] to a JSON string.
  static String toJson(CoreThemeData theme) {
    return jsonEncode(theme.toJson());
  }

  /// Deserialize [CoreThemeData] from a JSON string.
  static CoreThemeData fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    final brightness = map['brightness'] == 'dark'
        ? CoreBrightness.dark
        : CoreBrightness.light;

    final designSystemName = map['designSystem'] as String? ?? 'couiWeb';
    final designSystem = DesignSystem.values.firstWhere(
      (ds) => ds.name == designSystemName,
      orElse: () => DesignSystem.coui,
    );

    final colorsMap = map['colors'] as Map<String, dynamic>? ?? {};
    final colorScheme = CoreColorScheme.fromMap(colorsMap);

    return CoreThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      designSystem: designSystem,
      textScaling: (map['textScaling'] as num?)?.toDouble() ?? 1.0,
      sizeScaling: (map['sizeScaling'] as num?)?.toDouble() ?? 1.0,
      radiusScaling: (map['radiusScaling'] as num?)?.toDouble() ?? 1.0,
      // Absent means "not stated", which has to read as the platform
      // default rather than as silence — a theme exported before this
      // key existed described an app that still made a sound.
      tapSoundEnabled: map['tapSoundEnabled'] as bool? ?? true,
    );
  }

  /// Serialize only the color tokens to a flat hex map (for Figma Variables).
  static Map<String, String> toFigmaVariables(CoreThemeData theme) {
    return theme.colorScheme.toMap();
  }

  /// Serialize to CoUI theme format.
  static Map<String, String> toCouiTheme(CoreThemeData theme) {
    return theme.colorScheme.toMap();
  }
}
