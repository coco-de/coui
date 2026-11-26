import 'package:coui_core/src/component/contracts/swap/swap_style.dart';
import 'package:meta/meta.dart';

/// Swap component theme overrides.
///
/// Per Epic #1302 chrome / animation overrides flow through the
/// single [style] field — see [CoreSwapStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreSwapTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance swapStyle
/// ```
@immutable
class CoreSwapTheme {
  /// Creates a [CoreSwapTheme].
  const CoreSwapTheme({this.style});

  /// Project-wide composite style applied to every `Swap`.
  ///
  /// Resolved before any per-instance `widget.swapStyle`.
  final CoreSwapStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreSwapTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
