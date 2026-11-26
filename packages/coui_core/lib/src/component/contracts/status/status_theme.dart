import 'package:coui_core/src/component/contracts/status/status_style.dart';
import 'package:meta/meta.dart';

/// Status component theme overrides.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreStatusStyle] for the merge
/// chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreStatusTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance statusStyle
/// ```
@immutable
class CoreStatusTheme {
  /// Creates a [CoreStatusTheme].
  const CoreStatusTheme({this.style});

  /// Project-wide composite style applied to every `Status`.
  ///
  /// Resolved before any per-instance `widget.statusStyle`.
  final CoreStatusStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreStatusTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
