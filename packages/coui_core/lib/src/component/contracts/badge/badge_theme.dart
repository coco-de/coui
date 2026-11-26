import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';
import 'package:coui_core/src/component/contracts/badge/badge_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for badge components.
///
/// Holds the project [style] applied to every `Badge` whose
/// widget-level `badgeStyle` is null, plus two keyed override maps:
///
/// - [toneStyles] — keyed by [CoreBadgeTone], looked up by the widget's
///   `tone` parameter (what the colour means).
/// - [variantStyles] — keyed by [CoreBadgeVariant], looked up by the
///   widget's `variant` parameter (how loud it is).
///
/// 시각 chrome 은 전부 [style] / [toneStyles] / [variantStyles] 슬롯으로만
/// 흐른다 (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만" —
/// 색 축이 따로 있는 컴포넌트는 그 축의 표가 하나 더 붙는다, `CoreChipTheme`
/// 과 같은 모양). Semantic identifiers (`tone` / `variant` / `form` / `size`)
/// 는 **widget-only** — Theme 이 override 하면 caller 의 값을 짓밟으므로
/// Theme 에 두지 않는다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for size × form × tone × variant
///   → CoreBadgeTheme.style                       // 프로젝트 공통
///   → CoreBadgeTheme.toneStyles[widget.tone]
///   → CoreBadgeTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance badgeStyle
/// ```
@immutable
class CoreBadgeTheme {
  /// Creates a [CoreBadgeTheme].
  const CoreBadgeTheme({this.style, this.toneStyles, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreBadgeStyle? style;

  /// Per-tone override styles. Looked up by the widget's `tone`
  /// parameter, merged on top of [style].
  final Map<CoreBadgeTone, CoreBadgeStyle>? toneStyles;

  /// Per-variant override styles. Looked up by the widget's `variant`
  /// parameter, merged on top of [style] and [toneStyles].
  final Map<CoreBadgeVariant, CoreBadgeStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBadgeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(toneStyles, other.toneStyles) &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode =>
      Object.hash(style, _mapHash(toneStyles), _mapHash(variantStyles));

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
