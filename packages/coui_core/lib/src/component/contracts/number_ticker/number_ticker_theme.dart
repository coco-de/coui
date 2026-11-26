import 'package:coui_core/src/component/contracts/number_ticker/number_ticker_style.dart';
import 'package:meta/meta.dart';

/// Number ticker component theme overrides.
///
/// Per Epic #1302 chrome / dimensional / text style overrides flow
/// through the single [style] field — see [CoreNumberTickerStyle]
/// for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreNumberTickerTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance numberTickerStyle
/// ```
@immutable
class CoreNumberTickerTheme {
  /// Creates a [CoreNumberTickerTheme].
  const CoreNumberTickerTheme({this.style});

  /// Project-wide composite style applied to every `NumberTicker`.
  ///
  /// Resolved before any per-instance `widget.numberTickerStyle`.
  final CoreNumberTickerStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreNumberTickerTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
