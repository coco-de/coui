import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Abstract adapter interface for design-system-specific behavior.
///
/// Each design system (CoUI Web, M3E, Liquid Glass) implements this to
/// derive the colour slots a scheme leaves null.
abstract class DesignSystemAdapter {
  /// Const default constructor for subclasses.
  const DesignSystemAdapter();

  /// Fills in nullable tokens by deriving from existing required tokens.
  ///
  /// For example, M3E `surfaceContainer` can be derived from CoUI
  /// `base100`/`base200`/`base300` via interpolation.
  ResolvedColorScheme resolveColorScheme(
    CoreColorScheme scheme,
    CoreBrightness brightness,
  );
}
