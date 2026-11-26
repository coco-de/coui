import 'package:coui_core/src/component/contracts/scroll_area/scroll_area_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ScrollArea`.
///
/// All chrome / dimensional defaults live as `static const` fields on
/// [CoreScrollAreaStyle] (Phase 6f). This theme exposes only the
/// project-level `style` slot — flat chrome fields are forbidden.
///
/// ### Resolve chain.
///
/// ```text
/// CoreScrollAreaStyle.defaultX             ← static const default
///   → CoreComponentTheme.scrollArea.style  ← project-level override
///   → widget.scrollAreaStyle               ← per-instance override
/// ```
@immutable
class CoreScrollAreaTheme {
  /// Creates a [CoreScrollAreaTheme].
  const CoreScrollAreaTheme({this.style});

  /// Project-wide composite style applied to every `ScrollArea`.
  ///
  /// Resolved before any per-instance `widget.scrollAreaStyle`. Uses
  /// canonical [CoreScrollAreaStyle] fields; platform widgets convert
  /// to `Color` / CSS at the resolver boundary.
  final CoreScrollAreaStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreScrollAreaTheme) return false;
    return other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
