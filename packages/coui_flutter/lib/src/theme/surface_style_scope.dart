import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Makes the active surface style available to a subtree.
///
/// Named and shaped identically to the Web scope so an app reads the same
/// call on both platforms. Only the transport differs, and it differs the
/// way each framework already works: here a new style rebuilds the subtree
/// with a theme resolved for it, while on the Web the document gains an
/// attribute that stylesheet rules key off.
///
/// Components do not read this. It exists so an app can ask what is active
/// and switch it; the style reaches components by having already been
/// applied where the palette resolves.
class SurfaceStyleScope extends InheritedWidget {
  /// Creates a scope publishing [surfaceStyle] to [child].
  const SurfaceStyleScope({
    required this.surfaceStyle,
    required super.child,
    super.key,
  });

  /// The style in effect at [context], or the default when none is set.
  static CoreSurfaceStyleId of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SurfaceStyleScope>()
          ?.surfaceStyle ??
      .defaultId;

  /// The style in effect for this subtree.
  final CoreSurfaceStyleId surfaceStyle;

  @override
  bool updateShouldNotify(SurfaceStyleScope oldWidget) =>
      surfaceStyle != oldWidget.surfaceStyle;
}
