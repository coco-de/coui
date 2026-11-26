import 'package:jaspr/jaspr.dart';

/// Ambient cap a host installs around the `Menu` of a panel that is held to
/// the room the viewport leaves it.
///
/// The positioner measures the panel and reports the height it is capped to;
/// the host (`DropdownMenu`, `ContextMenu`, `Menubar`) keeps that beside the
/// panel's origin and wraps the `Menu` it composes in this scope. The `Menu`
/// then holds its own box to the cap and scrolls its rows inside it
/// (`resolveOverlayFit*`): the panel keeps the box chrome it was drawn with
/// and only the list moves. A `Menu` outside any scope is laid out as it
/// always was.
///
/// Only the panel's own vertical `Menu` reads it — the Web counterpart of the
/// private scroll scope the Flutter `Menu` sets for its `Popup`.
class MenuFitScope extends InheritedComponent {
  /// Creates a [MenuFitScope] exposing [maxHeight] to [child].
  const MenuFitScope({
    required this.maxHeight,
    required super.child,
    super.key,
  });

  /// The height the positioner capped the panel to, or `null` while the panel
  /// fits.
  final double? maxHeight;

  /// Returns the cap of the nearest scope above [context], or `null` when
  /// there is none or its panel fits.
  static double? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<MenuFitScope>()
        ?.maxHeight;
  }

  @override
  bool updateShouldNotify(MenuFitScope oldComponent) {
    return maxHeight != oldComponent.maxHeight;
  }
}
