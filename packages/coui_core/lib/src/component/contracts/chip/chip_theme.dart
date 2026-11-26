import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/contracts/chip/chip_variant.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_color.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for chip components.
///
/// Holds the project [style] applied to every `Chip` whose
/// widget-level `chipStyle` is null, plus two keyed override maps:
///
/// - [variantStyles] — keyed by [CoreChipVariant], looked up by the
///   widget's `variant` parameter (how an unselected chip is drawn).
/// - [colorStyles] — keyed by [CoreChipColor], looked up by the widget's
///   `chipColor` parameter (the colour a selected chip takes on).
///
/// 시각 chrome 은 전부 [style] / [variantStyles] / [colorStyles] 슬롯으로만
/// 흐른다 (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// Semantic identifiers (`chipColor` / `variant` / `size`) 는 **widget-only** —
/// Theme 이 override 하면 caller 의 `chipColor:` / `variant:` / `size:` 를
/// 짓밟고 Flutter 가 Web (이미 무시) 과 갈라지므로 Theme 에 두지 않는다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for chipColor
///   → CoreChipTheme.style                       // 프로젝트 공통
///   → CoreChipTheme.colorStyles[widget.chipColor]
///   → CoreChipTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance chipStyle
/// ```
@immutable
class CoreChipTheme {
  /// Creates a [CoreChipTheme].
  const CoreChipTheme({this.style, this.variantStyles, this.colorStyles});

  /// Project-level base style. `null` → no project override.
  ///
  /// Padding overrides flow through `style.padding`.
  final CoreChipStyle? style;

  /// Per-variant override styles. Looked up by the widget's `variant`
  /// parameter, merged on top of [style] and [colorStyles].
  final Map<CoreChipVariant, CoreChipStyle>? variantStyles;

  /// Per-colour override styles. Looked up by the widget's `chipColor`
  /// parameter, merged on top of [style].
  final Map<CoreChipColor, CoreChipStyle>? colorStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChipTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles) &&
          _mapEquals(colorStyles, other.colorStyles);

  @override
  int get hashCode =>
      Object.hash(style, _mapHash(variantStyles), _mapHash(colorStyles));

  /// Order-independent hash of the entries, so two maps [_mapEquals] calls
  /// equal hash alike — hashing the map object would use its identity.
  static int? _mapHash<K, V>(Map<K, V>? map) {
    if (map == null) return null;
    return Object.hashAllUnordered(
      map.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
