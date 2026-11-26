import 'package:coui_core/src/adapter/design_system_adapter.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Liquid Glass design system adapter.
///
/// Holds no colour derivation — the translucency this design system is
/// named for is stated by the surface style recipe, not by a colour slot.
class LiquidGlassAdapter extends DesignSystemAdapter {
  /// Creates a [LiquidGlassAdapter].
  const LiquidGlassAdapter();

  /// Passes the scheme through unchanged.
  ///
  /// The translucency this design system is named for is stated by the
  /// surface token's own opacity and blur radius, and reaches both
  /// platforms from the surface style recipe. Nothing about it is a colour
  /// slot, so there is no per-scheme derivation for this adapter to do.
  @override
  ResolvedColorScheme resolveColorScheme(
    CoreColorScheme scheme,
    CoreBrightness brightness,
  ) => scheme.resolved(brightness);
}
