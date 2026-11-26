/// Platform-independent contract for unified number ticker components.
///
/// Defines the interface that all NumberTicker implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/number_ticker/number_ticker_style.dart';

/// Callback to format a number for display.
typedef CoreNumberTickerFormatter = String Function(num number);

/// Contract for a unified number ticker component.
///
/// Displays a numeric value with transition animation
/// when the value changes. Supports custom formatting.
///
/// Per Epic #1302 chrome / dimensional / text-style overrides flow
/// through the single [numberTickerStyle] field — see
/// [CoreNumberTickerStyle] for the merge chain.
abstract interface class CoreNumberTickerContract {
  /// The target numeric value to animate to and display.
  num get value;

  /// Starting value for initial mount animation.
  num? get initialValue;

  /// Custom formatter for number display.
  CoreNumberTickerFormatter? get formatter;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreNumberTickerTheme.style
  ///   → parent component slot override
  ///   → widget.numberTickerStyle
  /// ```
  CoreNumberTickerStyle? get numberTickerStyle;
}
