/// Theme slot for `StepItem`.
library;

import 'package:coui_core/src/component/contracts/step_item/step_item_style.dart';
import 'package:coui_core/src/component/contracts/steps/step_status.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for step rows.
///
/// Holds the project [style] applied to every `StepItem`, plus
/// [statusStyles] — keyed by [CoreStepStatus], looked up by the row's
/// `status` — so a project can recolour one status (a failed step in its
/// own red) without restating the others. The same shape as
/// `CoreBadgeTheme.toneStyles`: the component has no variant enum, and its
/// colour axis is the status.
///
/// The status itself is **widget-only** — a theme that picked it would
/// overwrite what the caller reports.
///
/// ```text
/// CoreStepItemStyle.default* + defaultsByStatus[status]
///   → CoreStepItemTheme.style                       // 프로젝트 공통
///   → CoreStepItemTheme.statusStyles[status]
///   → widget.stepItemStyle
/// ```
@immutable
class CoreStepItemTheme {
  /// Creates a [CoreStepItemTheme].
  const CoreStepItemTheme({this.style, this.statusStyles});

  /// Chrome applied to every step row in the project.
  final CoreStepItemStyle? style;

  /// Per-status override styles. Looked up by the row's `status`, merged on
  /// top of [style].
  final Map<CoreStepStatus, CoreStepItemStyle>? statusStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepItemTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(statusStyles, other.statusStyles);

  @override
  int get hashCode => Object.hash(style, _mapHash(statusStyles));

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
