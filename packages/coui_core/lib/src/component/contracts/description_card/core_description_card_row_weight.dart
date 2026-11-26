/// Platform-independent label/value emphasis direction for
/// `DescriptionCard`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';

/// 행의 라벨/값 강조 방향.
enum CoreDescriptionCardRowWeight {
  /// 값을 진하게, 라벨을 흐리게.
  valueProminent,

  /// 라벨을 진하게, 값을 흐리게.
  labelProminent,
}

/// Per-`CoreDescriptionCardRowWeight` token-only [CoreColor] mapping
/// for the label / value slots.
///
/// Both Flutter and Web read this map (single source of truth):
/// - Flutter: `defaultLabelColor: scheme.resolve(role).toValue()`
///   (CoreColor → Flutter Color);
/// - Web: `text-${role}` Tailwind class via `CoreColor.toString()`
///   which returns the token name (e.g. `'on-surface'`).
typedef CoreDescriptionCardRowWeightColors = ({
  /// Token-only [CoreColor] for the label slot.
  CoreColor labelColor,

  /// Token-only [CoreColor] for the value slot.
  CoreColor valueColor,
});

/// Maps each [CoreDescriptionCardRowWeight] to the token-only
/// [CoreColor] used by the label / value slots — same data Flutter and
/// Web consume.
///
/// `valueProminent` → label is muted (`onSurfaceVariant`), value is
/// solid (`onSurface`); `labelProminent` swaps the two.
const Map<CoreDescriptionCardRowWeight, CoreDescriptionCardRowWeightColors>
kCoreDescriptionCardRowWeightColors = {
  CoreDescriptionCardRowWeight.valueProminent: (
    labelColor: CoreColor.token(CoreColors.onSurfaceVariant),
    valueColor: CoreColor.token(CoreColors.onSurface),
  ),
  CoreDescriptionCardRowWeight.labelProminent: (
    labelColor: CoreColor.token(CoreColors.onSurface),
    valueColor: CoreColor.token(CoreColors.onSurfaceVariant),
  ),
};
