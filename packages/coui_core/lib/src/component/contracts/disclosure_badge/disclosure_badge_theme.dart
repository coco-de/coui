/// Theme overrides for the disclosure badge component.
library;

import 'package:coui_core/src/component/contracts/disclosure_badge/core_disclosure_kind.dart';
import 'package:coui_core/src/component/contracts/disclosure_badge/disclosure_badge_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for `DisclosureBadge`.
///
/// All chrome flows through the composite [style] / [kindStyles] slots —
/// no flat chrome fields, and no semantic identifier (`kind` is a widget
/// parameter; a theme that could override it would let a project
/// silently restate every "비공개" as "공개").
///
/// ### Resolve chain.
///
/// ```text
/// design system default for kind
///   → CoreDisclosureBadgeTheme.style              // 프로젝트 공통
///   → CoreDisclosureBadgeTheme.kindStyles[kind]
///   → widget.disclosureBadgeStyle                 // 인스턴스별
/// ```
///
/// Note what a theme still cannot reach: the stroke pattern and the
/// marker dot live on [CoreDisclosureKind], so no project theme can
/// collapse the three kinds into colour alone.
@immutable
class CoreDisclosureBadgeTheme {
  /// Creates a [CoreDisclosureBadgeTheme].
  const CoreDisclosureBadgeTheme({this.style, this.kindStyles});

  /// Project-wide composite style applied to every `DisclosureBadge`.
  final CoreDisclosureBadgeStyle? style;

  /// Per-kind override styles. Looked up by the widget's `kind`
  /// parameter and merged on top of [style].
  final Map<CoreDisclosureKind, CoreDisclosureBadgeStyle>? kindStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDisclosureBadgeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(kindStyles, other.kindStyles);

  @override
  int get hashCode => Object.hash(style, kindStyles);

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
