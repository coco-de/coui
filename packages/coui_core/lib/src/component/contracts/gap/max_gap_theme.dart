/// Theme data for `MaxGap` customisation.
library;

import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `MaxGap`.
///
/// Shares the `CoreGapStyle` shape with `CoreGapTheme` — the
/// flexible-fit semantics live in the widget (Flutter wraps in
/// `Flexible`, Web emits `flex-grow: 1` / `flex-shrink: 1` plus a
/// `max-width` / `max-height` cap), so the style slot needs no extra
/// fields.
@immutable
class CoreMaxGapTheme {
  /// Creates a [CoreMaxGapTheme].
  const CoreMaxGapTheme({this.style});

  /// Per-theme default max-gap style (folded into the resolver chain
  /// before the per-instance `widget.gapStyle`).
  final CoreGapStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreMaxGapTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
