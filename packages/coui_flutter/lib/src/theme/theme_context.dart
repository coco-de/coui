/// `BuildContext` extensions for one-liner theme access.
///
/// Mirrors `coui_web`'s `theme_context.dart` so component code is
/// identical across platforms:
///
/// ```dart
/// Widget build(BuildContext context) {
///   final cs = context.colorScheme;            // ResolvedColorScheme
///   final ts = context.typography;             // Typography
///   return Text('Hi', style: ts.bodyMedium.copyWith(color: cs.onSurface.toValue()));
/// }
/// ```
///
/// `context.theme` is the long form (gives `ThemeData`); `colorScheme`
/// / `typography` are convenience shortcuts to the same fields.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// CoUI `BuildContext` extensions.
extension ThemeContext on BuildContext {
  /// The nearest [ThemeData] from [Theme].
  ThemeData get theme => Theme.of(this);

  /// Shortcut for `theme.colorScheme` — the fully-resolved CoUI semantic
  /// colour scheme (every M3 slot non-null; read `.onSurface.toValue()`).
  ResolvedColorScheme get colorScheme => theme.colorScheme;

  /// Shortcut for `theme.typography` — the CoUI typography token scale.
  CoreTypography get typography => theme.typography;
}
