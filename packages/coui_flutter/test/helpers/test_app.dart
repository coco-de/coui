import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget in a minimal CoUI widget tree for testing.
///
/// Provides Theme, Directionality, MediaQuery, and Material so that CoUI
/// widgets can render properly. A per-component [CoreComponentTheme] is
/// injected through `ThemeData.coreComponentTheme` (the unified single entry
/// point — the old `ComponentTheme(data:)` provider is gone).
///
/// [surfaceStyle] and [density] are folded into the theme through the
/// **same** `applySurfaceStyle` the app itself uses — a harness that
/// reimplemented that fold would become a second source for preset
/// resolution and could answer differently from `CoUIApp`.
///
/// [textDirection] is a parameter rather than a pinned `ltr` because a
/// harness that fixes direction makes any claim about mirroring
/// unfalsifiable — there would be no way to show a component wrong.
Widget buildTestApp(
  Widget child, {
  ThemeData? theme,
  CoreComponentTheme? componentTheme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreDensity density = .defaultDensity,
  TextDirection textDirection = .ltr,
  bool highContrast = false,
  bool disableAnimations = false,
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
        // app ever renders. `disableAnimations` is the ambient
        // reduced-motion preference `resolveMotionDuration` reads —
        // defaulted off so every existing call site keeps its current
        // (animating) behaviour unchanged.
        data: MediaQueryData(
          highContrast: highContrast,
          disableAnimations: disableAnimations,
        ),
        child: SurfaceStyleScope(
          surfaceStyle: surfaceStyle,
          child: DensityScope(
            density: density,
            child: material.Material(
              child: material.Overlay(
                initialEntries: [
                  material.OverlayEntry(
                    builder: (_) => Center(child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pumps a CoUI widget wrapped in the test app shell.
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  CoreComponentTheme? componentTheme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreDensity density = .defaultDensity,
  TextDirection textDirection = .ltr,
  bool highContrast = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      child,
      theme: theme,
      componentTheme: componentTheme,
      surfaceStyle: surfaceStyle,
      density: density,
      textDirection: textDirection,
      highContrast: highContrast,
      disableAnimations: disableAnimations,
    ),
  );
}
