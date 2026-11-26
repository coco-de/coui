import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Makes the active density available to a subtree.
///
/// Named and shaped identically to the Web scope so an app reads the same
/// call on both platforms. Only the transport differs, and it differs the
/// way each framework already works: here a new density rebuilds the
/// subtree with a theme whose geometry carries it, while on the Web the
/// document gains an attribute ([kDensityAttribute]) that stylesheet rules
/// key off.
///
/// Components do not read this. It exists so an app can ask what is active
/// and switch it; the density reaches components by having already been
/// folded into the theme's geometry, which every conversion of a spacing,
/// an inset, a control row or a corner already takes.
class DensityScope extends InheritedWidget {
  /// Creates a scope publishing [density] to [child].
  const DensityScope({
    required this.density,
    required super.child,
    super.key,
  });

  /// The density in effect at [context], or the default when none is set.
  static CoreDensity of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DensityScope>()?.density ??
      .defaultDensity;

  /// The density in effect for this subtree.
  final CoreDensity density;

  @override
  bool updateShouldNotify(DensityScope oldWidget) =>
      density != oldWidget.density;
}
