import 'package:coui_core/src/component/contracts/join/join_style.dart';
import 'package:meta/meta.dart';

/// Join component theme overrides.
///
/// Controls default appearance for joined-strip groupings of children.
///
/// All fields flow through [style] — no legacy flat fields
/// (introduced fresh per Epic #1302 원칙 7).
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreJoinTheme.style                            // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance joinStyle
/// ```
@immutable
class CoreJoinTheme {
  /// Creates a [CoreJoinTheme].
  const CoreJoinTheme({this.style});

  /// Project-wide composite style applied to every `Join`.
  ///
  /// Resolved before any per-instance `widget.joinStyle`.
  final CoreJoinStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreJoinTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
