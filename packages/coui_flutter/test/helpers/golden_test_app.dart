import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;

/// Wraps a widget in a minimal CoUI widget tree for golden tests.
///
/// Unlike [buildTestApp], this avoids [material.Overlay] which
/// causes infinite constraint issues in Alchemist golden scenarios.
/// A per-component [CoreComponentTheme] is injected through
/// `ThemeData.coreComponentTheme` (the old `ComponentTheme` provider is gone).
///
/// [surfaceStyle] and [density] are folded into the theme through the
/// **same** `applySurfaceStyle` the app itself uses — a harness that
/// reimplemented that fold would become a second source for preset
/// resolution and could answer differently from `CoUIApp`.
///
/// [textDirection] is a parameter rather than a pinned `ltr` because a
/// harness that fixes direction makes any claim about mirroring
/// unfalsifiable — there would be no way to show a component wrong.
Widget buildGoldenTestApp(
  Widget child, {
  ThemeData? theme,
  CoreComponentTheme? componentTheme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreDensity density = .defaultDensity,
  TextDirection textDirection = .ltr,
  bool highContrast = false,
}) {
  final baseTheme = theme ?? const ThemeData();
  final withComponentTheme = componentTheme == null
      ? baseTheme
      : baseTheme.copyWith(coreComponentTheme: () => componentTheme);
  final effectiveTheme = applySurfaceStyle(
    withComponentTheme,
    surfaceStyle: surfaceStyle,
    highContrast: highContrast,
    density: density,
  );

  return Theme(
    data: effectiveTheme,
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        // The flag travels with the fold: a tree whose theme was folded for
        // high contrast while `MediaQuery` says otherwise is a tree no real
        // app ever renders.
        data: MediaQueryData(highContrast: highContrast),
        child: SurfaceStyleScope(
          surfaceStyle: surfaceStyle,
          child: DensityScope(
            density: density,
            child: material.Material(
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}
