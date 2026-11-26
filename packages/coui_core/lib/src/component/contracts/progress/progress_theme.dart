import 'package:coui_core/src/component/contracts/progress/progress_style.dart';
import 'package:coui_core/src/component/contracts/progress/progress_tone.dart';
import 'package:meta/meta.dart';

/// Linear progress component theme overrides.
///
/// Holds the project [style] applied to every `Progress` whose
/// widget-level `progressStyle` is null, plus [toneStyles] — keyed by
/// [CoreProgressTone], looked up by the widget's `tone` parameter — see
/// [CoreProgressStyle] for the merge chain. 시각 chrome 은 전부 [style] /
/// [toneStyles] 슬롯으로만 흐른다 (style-contract.md "CoreXxxTheme — style +
/// variantStyles 슬롯만" — linear progress has no variants; its colour axis
/// gets its own table, the shape `CoreBadgeTheme` has). The semantic `tone`
/// itself is widget-only — a Theme that overrode it would overwrite the
/// caller's value.
///
/// Radial progress overrides live in `CoreRadialProgressTheme`
/// (`radialProgress` slot) — a distinct component with its own
/// [CoreRadialProgressStyle], so it gets its own single-[style] theme.
///
/// ### Resolve chain.
///
/// ```text
/// CoreProgressStyle.defaultX / defaultsByTone[tone] (static const)
///   → CoreProgressTheme.style                      // 프로젝트 공통
///   → CoreProgressTheme.toneStyles[widget.tone]
///   → parent component slot override
///   → widget.progressStyle                         // 인스턴스별
/// ```
@immutable
class CoreProgressTheme {
  /// Creates a [CoreProgressTheme].
  const CoreProgressTheme({this.style, this.toneStyles});

  /// Project-wide linear progress composite style.
  ///
  /// Resolved before any per-instance `widget.progressStyle`.
  final CoreProgressStyle? style;

  /// Per-tone override styles. Looked up by the widget's `tone`
  /// parameter, merged on top of [style].
  final Map<CoreProgressTone, CoreProgressStyle>? toneStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreProgressTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(toneStyles, other.toneStyles);

  @override
  int get hashCode => Object.hash(style, _mapHash(toneStyles));

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
