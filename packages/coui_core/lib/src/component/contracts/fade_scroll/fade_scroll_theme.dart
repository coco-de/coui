import 'package:coui_core/src/component/contracts/fade_scroll/fade_scroll_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `FadeScroll`.
///
/// All chrome / dimensional defaults live as `static const` fields on
/// [CoreFadeScrollStyle] (Phase 6f). This theme exposes only the
/// project-level `style` slot — flat chrome fields were removed.
///
/// ### Resolve chain.
///
/// ```text
/// CoreFadeScrollStyle.defaultX             ← static const default
///   → CoreComponentTheme.fadeScroll.style  ← project-level override
///   → widget.fadeScrollStyle               ← per-instance override
/// ```
@immutable
class CoreFadeScrollTheme {
  /// Creates a [CoreFadeScrollTheme].
  const CoreFadeScrollTheme({this.style});

  /// Project-wide composite style applied to every `FadeScroll`.
  ///
  /// Resolved before any per-instance `widget.fadeScrollStyle`. Uses
  /// canonical [CoreFadeScrollStyle] fields; platform widgets convert
  /// to `Color` / CSS at the resolver boundary.
  final CoreFadeScrollStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreFadeScrollTheme) return false;
    return other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
