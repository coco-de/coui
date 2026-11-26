import 'package:coui_core/src/component/contracts/selectable/selectable_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for selectable-text components.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreSelectableTextStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreSelectableTextStyle.defaultX)
///   → CoreSelectableTextTheme.style                  // 프로젝트 공통
///   → widget per-instance selectableTextStyle        // 인스턴스별
/// ```
@immutable
class CoreSelectableTextTheme {
  /// Creates a [CoreSelectableTextTheme].
  const CoreSelectableTextTheme({this.style});

  /// Project-wide composite style applied to every `SelectableText`.
  ///
  /// Resolved before any per-instance `widget.selectableTextStyle`.
  final CoreSelectableTextStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSelectableTextTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
