/// Theme provider for CoUI web components.
///
/// Wraps the component tree to provide [ThemeData] access via
/// [BuildContext], mirroring Flutter's `Theme.of(context)` pattern.
///
/// ```dart
/// // App root
/// CoUIWeb(
///   theme: ThemeData.coui,
///   child: myApp,
/// )
///
/// // In components
/// final theme = Theme.of(context);
/// 'bg-${theme.colorScheme.surface ?? 'surface'}'
/// ```
library;

import 'package:jaspr/jaspr.dart';

import 'theme_data.dart';

// Re-export the BuildContext extension so legacy `import
// 'package:coui_web/src/theme/coui_theme.dart'` callers keep working —
// the actual definition lives in `theme_context.dart`.
export 'theme_context.dart';

/// Provides [ThemeData] to descendant components via [InheritedComponent].
///
/// Pure metadata — emits no DOM of its own. Mirrors Flutter's `Theme`
/// `InheritedWidget` exactly. The project's base typography is applied
/// separately by [CoUIWeb] (the Web equivalent of Flutter's `UiApp`)
/// via a `<div class="text-body-medium text-on-surface font-sans">`
/// wrapper, matching Flutter's `DefaultTextStyle.merge` setup inside
/// `UiApp`.
class Theme extends InheritedComponent {
  /// Creates a theme provider.
  const Theme({
    required this.data,
    required super.child,
    super.key,
  });

  /// Creates a theme with default CoUI settings.
  Theme.defaults({
    required Component child,
    Key? key,
  }) : this(
         key: key,
         data: .coui,
         child: child,
       );

  /// The theme data.
  final ThemeData data;

  /// Retrieves the nearest [Theme] data from the given [BuildContext].
  ///
  /// Returns `null` if no [Theme] is found.
  static ThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<Theme>()?.data;
  }

  /// Retrieves the nearest [Theme] data from the given [BuildContext].
  ///
  /// Throws if no [Theme] is found.
  static ThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(
      data != null,
      'No Theme found in context. '
      'Wrap your app with CoUIWeb or Theme.',
    );
    return data!;
  }

  @override
  bool updateShouldNotify(covariant Theme oldComponent) {
    return data != oldComponent.data;
  }
}

// `extension ThemeContext on BuildContext` lives in
// `theme_context.dart` — kept separate so it can be expanded with
// shorthand getters (`context.colorScheme`, `context.typography`, …)
// without touching the [Theme] InheritedComponent above.
