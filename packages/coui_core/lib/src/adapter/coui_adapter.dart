import 'package:coui_core/coui_core.dart' show CoreSemanticMapping;
import 'package:coui_core/src/adapter/design_system_adapter.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/color/semantic_mapping.dart'
    show CoreSemanticMapping;
import 'package:coui_core/src/theme/brightness.dart';

/// CoUI design system adapter.
///
/// CoUI is the baseline — M3 Semantic tokens are expected to be
/// present (set by [CoreSemanticMapping]). This adapter passes
/// the scheme through as-is.
class CouiAdapter extends DesignSystemAdapter {
  /// Creates a [CouiAdapter] — the baseline pass-through adapter.
  const CouiAdapter();

  @override
  ResolvedColorScheme resolveColorScheme(
    CoreColorScheme scheme,
    CoreBrightness brightness,
  ) {
    return scheme.resolved(brightness);
  }
}
