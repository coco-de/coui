import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/component/contracts/tag/tag_emphasis.dart';
import 'package:coui_core/src/component/contracts/tag/tag_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for tag components.
///
/// Holds the project [style] applied to every `Tag`, plus two keyed
/// override maps:
///
/// - [colorStyles] — keyed by [CoreCategoryColor], looked up by the
///   widget's `color` parameter (which hue it wears).
/// - [emphasisStyles] — keyed by [CoreTagEmphasis], looked up by the
///   widget's `emphasis` parameter (how loud it is).
///
/// 시각 chrome 은 전부 [style] / [colorStyles] / [emphasisStyles] 슬롯으로만
/// 흐른다 — 축마다 표가 하나씩 붙는 `CoreBadgeTheme` 과 같은 모양이다.
/// 강조 축은 이 컴포넌트의 variant 에 해당하며, 그 축 이름으로 표 이름을
/// 짓는다. Semantic identifiers (`color` / `emphasis` / `size`) 는
/// **widget-only** — Theme 이 override 하면 caller 의 값을 짓밟으므로 Theme
/// 에 두지 않는다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for size × emphasis × hue
///   → CoreTagTheme.style                        // 프로젝트 공통
///   → CoreTagTheme.colorStyles[widget.color]
///   → CoreTagTheme.emphasisStyles[widget.emphasis]
///   → widget per-instance tagStyle
/// ```
@immutable
class CoreTagTheme {
  /// Creates a [CoreTagTheme].
  const CoreTagTheme({this.style, this.colorStyles, this.emphasisStyles});

  /// Project-level base style. `null` → no project override.
  final CoreTagStyle? style;

  /// Per-hue override styles. Looked up by the widget's `color` parameter,
  /// merged on top of [style].
  final Map<CoreCategoryColor, CoreTagStyle>? colorStyles;

  /// Per-emphasis override styles. Looked up by the widget's `emphasis`
  /// parameter, merged on top of [style] and [colorStyles].
  final Map<CoreTagEmphasis, CoreTagStyle>? emphasisStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTagTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(colorStyles, other.colorStyles) &&
          _mapEquals(emphasisStyles, other.emphasisStyles);

  @override
  int get hashCode =>
      Object.hash(style, _mapHash(colorStyles), _mapHash(emphasisStyles));

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
