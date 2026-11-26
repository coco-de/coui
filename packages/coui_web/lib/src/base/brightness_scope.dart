import 'package:coui_core/coui_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Renders [child] in [brightness], whatever the page around it.
///
/// The subtree takes the app's colours for that brightness — its palette,
/// high contrast when the preference is on, the surface style's colour
/// bends — that brightness's shadow strength, and its surface materials'
/// fill share and dimming. Everything else stays the page's.
///
/// Named and shaped identically to the Flutter scope so an app reads the
/// same call on both platforms. Only the transport differs: Flutter gives
/// the subtree a theme with the other brightness's colours, and here a
/// wrapper carries `data-theme`, whose scoped rules
/// (`ThemeConfig.brightnessScopeBlock`) restate the colour variables for
/// everything inside it.
///
/// The wrapper draws no box (`display: contents`): it neither lays out nor
/// paints, so wrapping a positioned element keeps that element's containing
/// block. Custom properties and `color` still inherit through it — that is
/// what carries the scope.
///
/// A panel the subtree opens is portalled to the overlay host, outside the
/// wrapper. The popovers, menus, tooltips, hover cards and dialogs that
/// portal it state the scope again around the panel
/// (`OverlayPortal.capture`), so the panel renders in this brightness too —
/// as on Flutter, where those panels capture the theme of the place they
/// opened from. A drawer does not: it renders in the brightness around the
/// host it mounts on, as the Flutter drawer route builds its panel without
/// capturing the theme of the place it was opened.
///
/// ```dart
/// // A light app previewed in a dark editor.
/// BrightnessScope(brightness: CoreBrightness.light, child: preview)
/// ```
class BrightnessScope extends StatelessComponent {
  /// Creates a scope rendering [child] in [brightness].
  const BrightnessScope({
    required this.brightness,
    required this.child,
    super.key,
  });

  /// The brightness [child] renders in.
  final CoreBrightness brightness;

  /// The subtree that renders in [brightness].
  final Component child;

  @override
  Component build(BuildContext context) => _BrightnessScopePin(
    brightness: brightness,
    child: div(
      [child],
      styles: const Styles(raw: {'display': 'contents'}),
      attributes: {'data-theme': brightness.name},
    ),
  );
}

/// The brightness of the nearest [BrightnessScope] above [context] when that
/// scope sits below [boundary] — `null` when no scope is above [context], or
/// when the nearest one is above [boundary] too.
///
/// The DOM carries the brightness to the elements inside the wrapper; this
/// carries it to what the subtree renders under [boundary] instead — a panel
/// it portals to the overlay host (`OverlayPortal.capture`). A scope above
/// [boundary] still reaches what renders there, so only a scope between the
/// two is left behind.
///
/// The answer turns on where the scope sits, never on its brightness: a
/// caller that wraps on it keeps its wrapper while the brightness changes,
/// and only the tree's shape adds or drops it.
CoreBrightness? brightnessBetween(BuildContext context, Element boundary) {
  final scope = context
      .getElementForInheritedComponentOfExactType<_BrightnessScopePin>();
  // Both are ancestors of [context], so the deeper one is the nearer.
  if (scope == null || scope.depth <= boundary.depth) return null;

  return (context.dependOnInheritedElement(scope) as _BrightnessScopePin)
      .brightness;
}

/// A [BrightnessScope]'s brightness, for the components below it.
class _BrightnessScopePin extends InheritedComponent {
  const _BrightnessScopePin({required this.brightness, required super.child});

  final CoreBrightness brightness;

  @override
  bool updateShouldNotify(covariant _BrightnessScopePin oldComponent) =>
      brightness != oldComponent.brightness;
}
