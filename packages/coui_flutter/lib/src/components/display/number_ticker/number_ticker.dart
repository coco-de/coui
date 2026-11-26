import 'package:coui_flutter/coui_flutter.dart';

/// Default formatter that shows integer representation.
String _defaultFormatter(num n) => n.toStringAsFixed(0);

/// Wraps a `double Function(double)` as a Flutter [Curve].
class _FnCurve extends Curve {
  const _FnCurve(this._fn);
  final double Function(double t) _fn;

  @override
  double transformInternal(double t) => _fn(t);
}

/// Unified cross-platform number ticker with token-based rendering.
///
/// Displays a numeric value with a smooth animation transition
/// when the value changes. Supports custom formatting for
/// currency, percentages, etc.
///
/// Per Epic #1302 chrome / dimensional / text-style overrides flow
/// through the single [numberTickerStyle] slot. Behavioural fields
/// (`value`, `initialValue`, `formatter`, `builder`, `curve`) stay
/// flat on the widget.
///
/// Example:
/// ```dart
/// NumberTicker(
///   value: 1234,
///   formatter: (n) => '\$${n.toStringAsFixed(2)}',
///   numberTickerStyle: CoreNumberTickerStyle(
///     duration: Duration(milliseconds: 600),
///     textStyle: CoreTextStyle(fontSize: 32),
///   ),
/// )
/// ```
class NumberTicker extends StatelessWidget implements CoreNumberTickerContract {
  /// Creates a [NumberTicker] with a formatted text display.
  const NumberTicker({
    required this.value,
    super.key,
    this.formatter,
    this.initialValue,
    this.curve,
    this.numberTickerStyle,
  }) : builder = null,
       child = null;

  /// Creates a [NumberTicker] with a custom builder.
  const NumberTicker.builder({
    required this.value,
    required this.builder,
    super.key,
    this.child,
    this.initialValue,
    this.curve,
    this.numberTickerStyle,
  }) : formatter = null;

  @override
  final num value;

  @override
  final num? initialValue;

  @override
  final CoreNumberTickerFormatter? formatter;

  /// Custom builder for complete display control.
  final NumberTickerBuilder? builder;

  /// Optional child passed to builder for optimization.
  final Widget? child;

  /// Custom easing curve function. Takes progress 0.0-1.0, returns eased value.
  /// Default is ease-in-out.
  final double Function(double t)? curve;

  @override
  final CoreNumberTickerStyle? numberTickerStyle;

  /// Returns a copy of this [NumberTicker] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  ///
  /// [builder] and [child] are not overridable here — they are
  /// mutually exclusive with [formatter] (mirrors the Web
  /// `NumberTicker.copyWith`); when this instance already carries a
  /// [builder] the copy stays a `NumberTicker.builder`.
  NumberTicker copyWith({
    Key? key,
    num? initialValue,
    num? value,
    CoreNumberTickerFormatter? formatter,
    double Function(double t)? curve,
    CoreNumberTickerStyle? numberTickerStyle,
  }) {
    final currentBuilder = builder;
    if (currentBuilder != null) {
      return NumberTicker.builder(
        key: key ?? this.key,
        initialValue: initialValue ?? this.initialValue,
        value: value ?? this.value,
        curve: curve ?? this.curve,
        numberTickerStyle: numberTickerStyle ?? this.numberTickerStyle,
        builder: currentBuilder,
        child: child,
      );
    }
    return NumberTicker(
      key: key ?? this.key,
      initialValue: initialValue ?? this.initialValue,
      value: value ?? this.value,
      formatter: formatter ?? this.formatter,
      curve: curve ?? this.curve,
      numberTickerStyle: numberTickerStyle ?? this.numberTickerStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveNumberTicker(
      context,
      numberTickerStyle: numberTickerStyle,
    );
    final effectiveCurve = curve != null
        ? _FnCurve(curve!)
        : CoreEasing.move.toValue();

    if (builder != null) {
      return AnimatedValueBuilder(
        initialValue: initialValue?.toDouble(),
        value: value.toDouble(),
        duration: resolved.duration,
        curve: effectiveCurve,
        builder: (context, animValue, child) {
          return builder!(context, animValue, child);
        },
        child: child,
      );
    }

    final effectiveFormatter = formatter ?? _defaultFormatter;

    return AnimatedValueBuilder(
      initialValue: initialValue?.toDouble(),
      value: value.toDouble(),
      duration: resolved.duration,
      curve: effectiveCurve,
      builder: (context, animValue, child) {
        return Text(effectiveFormatter(animValue), style: resolved.textStyle);
      },
    );
  }
}

/// Chain sugar for merging a [CoreNumberTickerStyle] patch into
/// [NumberTicker.numberTickerStyle] without hand-reconstructing every
/// field. Mirrors the Web `NumberTicker.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNumberTickerStyle.merge` right-side-wins semantics).
extension NumberTickerStyleChain on NumberTicker {
  /// Returns a copy of this [NumberTicker] with [patch] merged into
  /// [numberTickerStyle] (patch fields win on conflict).
  NumberTicker withStyle(CoreNumberTickerStyle patch) => copyWith(
    numberTickerStyle: (numberTickerStyle ?? const CoreNumberTickerStyle())
        .merge(patch),
  );
}

/// 애니메이션되는 숫자 값을 기반으로 위젯을 빌드하는 콜백.
///
/// [NumberTicker.builder]에서 애니메이션되는 숫자의 커스텀 표현을 구성하는 데
/// 사용됩니다. [number] 매개변수는 현재 보간된 숫자 값을 포함하고,.
/// [child]는 최적화를 위한 선택적 위젯입니다.

typedef NumberTickerBuilder =
    Widget Function(BuildContext context, num number, Widget? child);
