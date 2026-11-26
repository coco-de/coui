import 'package:coui_flutter/coui_flutter.dart';

/// Announces "loading" once for an area whose content has not arrived.
///
/// Wrap the skeletons standing in for one area. The region is a single
/// polite live region carrying [semanticLabel] (or the locale's loading
/// label); the skeletons inside read [LoadingRegionScope] and drop their
/// own announcement, and the area itself is excluded from the semantics
/// tree while the region speaks for it.
///
/// Draws nothing — layout is exactly the [child]'s.
///
/// Example:
/// ```dart
/// LoadingRegion(
///   semanticLabel: 'Loading orders',
///   child: Column(
///     spacing: CoreSpace.space8,
///     children: [for (var i = 0; i < 5; i++) Skeleton(height: 20)],
///   ),
/// )
/// ```
class LoadingRegion extends StatelessWidget
    implements CoreLoadingRegionContract<Widget> {
  /// Creates a [LoadingRegion].
  const LoadingRegion({required this.child, super.key, this.semanticLabel});

  @override
  final String? semanticLabel;

  @override
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // An enclosing region already speaks for this area and already
    // excludes it, so a nested one adds nothing but a second announcement.
    if (LoadingRegionScope.existsAbove(context)) return child;

    return CoUISemantics(
      role: .status,
      // Read at render time: a default parameter value cannot reach the
      // active locale.
      label: semanticLabel ?? CoUILocalizations.of(context).loadingLabel,
      // Keeps the label on its own node — merged into an enclosing card it
      // would be read as part of that card, not announced.
      container: true,
      child: LoadingRegionScope(child: ExcludeSemantics(child: child)),
    );
  }
}

/// Tells the skeletons below that an enclosing [LoadingRegion] announces
/// for them.
///
/// Named and shaped like the Web counterpart so the two platforms read the
/// same. It is a plain inherited widget, so it stops at an overlay
/// boundary: a skeleton in a dialog opened from inside the region is not
/// under the region's exclusion and announces itself.
///
/// Not exported from the package — wrapping a subtree in the scope alone
/// would silence its skeletons with nothing announcing in their place.
class LoadingRegionScope extends InheritedWidget {
  /// Creates a scope declaring a region announces for [child].
  const LoadingRegionScope({required super.child, super.key});

  /// Whether an enclosing [LoadingRegion] already announces this area.
  static bool existsAbove(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoadingRegionScope>() != null;

  @override
  bool updateShouldNotify(LoadingRegionScope oldWidget) => false;
}
