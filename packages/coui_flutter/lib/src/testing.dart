import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;

/// Wraps a widget in a lightweight CoUI widget tree for widget testing.
///
/// Unlike [CoUIApp], this provides only the essential layers
/// (Theme, Directionality, MediaQuery, Material, Overlay)
/// without [CoUILayer], [ToastLayer], or [OverlayManagerLayer].
///
/// This avoids `pumpAndSettle()` timeout issues caused by always-present
/// animation controllers in the full CoUI widget tree.
///
/// ```dart
/// // In test hooks.dart
/// class TestApp extends StatelessWidget {
///   const TestApp({required this.child, super.key});
///   final Widget child;
///
///   @override
///   Widget build(BuildContext context) {
///     return buildCoUITestApp(
///       theme: AppTheme.light,
///       child: Scaffold(body: child),
///     );
///   }
/// }
/// ```
/// [textDirection] is what makes a right-to-left claim checkable. It was
/// pinned to left-to-right with no way to override, so no widget test
/// could ask a component to lay itself out the other way — which meant
/// any statement about mirroring was unfalsifiable.
Widget buildCoUITestApp({
  required Widget child,
  ThemeData? theme,
  TextDirection textDirection = .ltr,
}) {
  final effectiveTheme = theme ?? const ThemeData();

  return Theme(
    data: effectiveTheme,
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: material.Material(
          child: material.Overlay(
            initialEntries: [
              material.OverlayEntry(
                builder: (_) => child,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
