import 'package:coui_core/src/adapter/coui_adapter.dart';
import 'package:coui_core/src/adapter/design_system_adapter.dart';
import 'package:coui_core/src/adapter/liquid_glass_adapter.dart';
import 'package:coui_core/src/adapter/m3e_adapter.dart';
import 'package:coui_core/src/theme/design_system.dart';

/// Maps each [DesignSystem] to its [DesignSystemAdapter].
///
/// The single source of truth for `designSystem → adapter` selection used
/// by the theme-resolution paths (Flutter `ThemeData.fromCore`, Web
/// `CssVariableGenerator`). The CoUI baseline adapter is a pass-through, so
/// resolving a `.coui` theme through it is visually identical to not
/// resolving at all.
extension DesignSystemAdapterSelector on DesignSystem {
  /// The adapter that resolves tokens for this design system.
  DesignSystemAdapter get adapter => switch (this) {
    .coui => const CouiAdapter(),
    .m3Expressive => const M3ExpressiveAdapter(),
    .liquidGlass => const LiquidGlassAdapter(),
  };
}
