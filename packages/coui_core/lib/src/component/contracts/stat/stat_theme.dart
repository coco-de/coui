import 'package:coui_core/src/component/contracts/stat/stat_style.dart';
import 'package:coui_core/src/component/contracts/stat/stat_variant.dart';
import 'package:meta/meta.dart';

/// Stat component theme overrides.
///
/// Controls default appearance for the `Stat` display component.
///
/// All fields are optional — when null, the component uses
/// [CoreStatStyle.defaultsByVariant] / `CoreStatStyle.defaultX`.
@immutable
class CoreStatTheme {
  /// Creates a [CoreStatTheme].
  const CoreStatTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `Stat`.
  ///
  /// Resolved before any per-instance `widget.statStyle`.
  final CoreStatStyle? style;

  /// Per-variant override styles (`filled` / `outlined`), applied after
  /// [style] so a project can retune one variant's chrome without the
  /// other.
  final Map<CoreStatVariant, CoreStatStyle>? variantStyles;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CoreStatTheme &&
            other.style == style &&
            _mapEquals(other.variantStyles, variantStyles);
  }

  @override
  int get hashCode => Object.hash(style, variantStyles);
}

bool _mapEquals(
  Map<CoreStatVariant, CoreStatStyle>? a,
  Map<CoreStatVariant, CoreStatStyle>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
