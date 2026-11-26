import 'package:coui_core/src/component/contracts/label/label_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for label components.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreLabelStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreLabelTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance labelStyle
/// ```
@immutable
class CoreLabelTheme {
  /// Creates a [CoreLabelTheme].
  const CoreLabelTheme({this.style});

  /// Project-wide composite style applied to every `Label`.
  ///
  /// Resolved before any per-instance `widget.labelStyle`.
  final CoreLabelStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLabelTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
