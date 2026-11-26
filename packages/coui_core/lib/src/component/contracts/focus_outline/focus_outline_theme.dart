import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:meta/meta.dart';

/// Focus outline component theme overrides.
///
/// Provides per-component style defaults for focus ring rendering
/// that can be set at the project level and read by FocusOutline
/// via the inherited theme.
///
/// All numeric values are pre-scaling; the component applies
/// `theme.scaling` internally if needed.
///
/// Per Epic #1302 chrome flows through the single [style] field —
/// see [CoreFocusOutlineStyle] for the merge chain. Animation timing
/// (`duration`) lives on [CoreFocusOutlineStyle.duration] since
/// Epic #1370 Phase 4 — the legacy flat field was removed.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreFocusOutlineTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance focusOutlineStyle
/// ```
@immutable
class CoreFocusOutlineTheme {
  /// Creates a [CoreFocusOutlineTheme].
  const CoreFocusOutlineTheme({this.style});

  /// Project-wide composite style applied to every `FocusOutline`.
  ///
  /// Resolved before any per-instance `widget.focusOutlineStyle`.
  final CoreFocusOutlineStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreFocusOutlineTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
