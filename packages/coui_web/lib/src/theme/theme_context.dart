/// `BuildContext` extensions for one-liner theme access.
///
/// Mirrors `coui_flutter`'s `theme_context.dart` so component code is
/// identical across platforms:
///
/// ```dart
/// Component build(BuildContext context) {
///   final cs = context.colorScheme;            // CoreColorScheme
///   final ts = context.typography;             // CoreTypography
///   return Text('Hi').bodyMedium.onSurface;
/// }
/// ```
///
/// `context.theme` is the long form (gives `ThemeData`); `colorScheme`
/// / `typography` are convenience shortcuts to the same fields.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/theme_data.dart';
import 'package:jaspr/jaspr.dart';

/// CoUI `BuildContext` extensions.
extension ThemeContext on BuildContext {
  /// The nearest [ThemeData] from [Theme].
  ThemeData get theme => Theme.of(this);

  /// Shortcut for `theme.colorScheme` — the CoUI semantic colour scheme.
  CoreColorScheme get colorScheme => theme.colorScheme;

  /// Shortcut for `theme.typography` — the canonical [CoreTypography]
  /// scale (mirrors Flutter's `context.typography`).
  CoreTypography get typography => theme.typography;
}
