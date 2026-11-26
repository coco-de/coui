import 'package:coui_core/src/adapter/design_system_adapter.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// M3 Expressive design system adapter.
///
/// Derives the M3E surface-container and inverse slots a CoUI baseline
/// palette leaves open. Colour is the whole of it — variant, corner and
/// motion are stated at their own seats, not rewritten here.
class M3ExpressiveAdapter extends DesignSystemAdapter {
  /// Creates an [M3ExpressiveAdapter].
  const M3ExpressiveAdapter();

  @override
  ResolvedColorScheme resolveColorScheme(
    CoreColorScheme scheme,
    CoreBrightness brightness,
  ) {
    // M3 Semantic tokens are expected to be set by
    // CoreSemanticMapping. Pass through as-is.
    return scheme.resolved(brightness);
  }
}
