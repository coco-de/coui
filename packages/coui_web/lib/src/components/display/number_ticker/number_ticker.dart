import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/number_ticker/number_ticker_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Animation frame interval in milliseconds (~60fps).
const _kFrameIntervalMs = 16;

/// Ease-in-out midpoint.
const _kEaseMidpoint = 0.5;

/// Default ease-in-out curve function.
double _easeInOut(double t) {
  return t < _kEaseMidpoint ? 2 * t * t : 1 - (-2 * t + 2) * (-2 * t + 2) / 2;
}

/// Builder callback for custom number display.
typedef WebNumberTickerBuilder =
    Component Function(
      BuildContext context,
      num value,
      Component? child,
    );

/// Unified cross-platform number ticker for CoUI Web.
///
/// Displays a numeric value with animated interpolation
/// when the value changes. Supports custom formatting.
///
/// Per Epic #1302 chrome / dimensional / text-style overrides flow
/// through the single [numberTickerStyle] slot. Behavioural fields
/// (`value`, `initialValue`, `formatter`, `builder`, `curve`) stay
/// flat on the widget.
class NumberTicker extends UiStatefulComponent
    implements CoreNumberTickerContract {
  /// Creates a [NumberTicker] with formatted text display.
  const NumberTicker({
    required this.value,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.initialValue,
    this.formatter,
    this.curve,
    this.numberTickerStyle,
  }) : builder = null,
       child = null;

  /// Creates a [NumberTicker] with a custom builder.
  const NumberTicker.builder({
    required this.value,
    required this.builder,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
  final WebNumberTickerBuilder? builder;

  /// Optional child passed to builder for optimization.
  final Component? child;

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
  /// mutually exclusive with [formatter] (mirrors the Flutter
  /// `NumberTicker.copyWith`); when this instance already carries a
  /// [builder] the copy stays a `NumberTicker.builder`.
  NumberTicker copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    num? initialValue,
    num? value,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreNumberTickerFormatter? formatter,
    double Function(double t)? curve,
    CoreNumberTickerStyle? numberTickerStyle,
  }) {
    final currentBuilder = builder;
    if (currentBuilder != null) {
      return NumberTicker.builder(
        key: key ?? this.key,
        onClick: onClick ?? this.onClick,
        initialValue: initialValue ?? this.initialValue,
        value: value ?? this.value,
        attributes: attributes ?? userAttributes,
        classes: classes ?? this.classes,
        css: css ?? this.css,
        eventHandlers: eventHandlers ?? this.eventHandlers,
        id: id ?? this.id,
        onChange: onChange ?? this.onChange,
        onInput: onInput ?? this.onInput,
        onKeyDown: onKeyDown ?? this.onKeyDown,
        onKeyUp: onKeyUp ?? this.onKeyUp,
        onMouseEnter: onMouseEnter ?? this.onMouseEnter,
        onMouseLeave: onMouseLeave ?? this.onMouseLeave,
        curve: curve ?? this.curve,
        numberTickerStyle: numberTickerStyle ?? this.numberTickerStyle,
        builder: currentBuilder,
        child: child,
      );
    }
    return NumberTicker(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      initialValue: initialValue ?? this.initialValue,
      value: value ?? this.value,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      formatter: formatter ?? this.formatter,
      curve: curve ?? this.curve,
      numberTickerStyle: numberTickerStyle ?? this.numberTickerStyle,
    );
  }

  @override
  State<NumberTicker> createState() => _NumberTickerState();
}

/// Chain sugar mirroring the Flutter `NumberTicker.withStyle` extension
/// — merges a [CoreNumberTickerStyle] patch into
/// [NumberTicker.numberTickerStyle] via the existing
/// [NumberTicker.copyWith].
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

class _NumberTickerState extends State<NumberTicker> {
  double _displayValue = 0;
  double _startValue = 0;
  double _targetValue = 0;
  Timer? _timer;
  int _elapsed = 0;

  bool get _hasAnimationWork =>
      _timer != null || _displayValue != component.value.toDouble();

  @override
  void initState() {
    super.initState();
    final initial = component.initialValue;
    if (initial != null) {
      _displayValue = initial.toDouble();
      _targetValue = component.value.toDouble();
      if (kIsWeb) {
        unawaited(
          Future.microtask(() {
            if (!mounted) return;
            _startAnimation(_displayValue, _targetValue);
          }),
        );
      }
    } else {
      _displayValue = component.value.toDouble();
      _targetValue = _displayValue;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited duration is available before the first SSR/client build and
    // whenever its theme changes. A zero duration has no intermediate value.
    if (_hasAnimationWork && _resolveDuration(context) == Duration.zero) {
      _finishAnimation(component.value.toDouble());
    }
  }

  ResolvedNumberTicker _resolve(BuildContext context) {
    return resolveNumberTicker(
      context,
      numberTickerStyle: component.numberTickerStyle,
    );
  }

  Duration _resolveDuration(BuildContext context) {
    return resolveNumberTickerDuration(
      context,
      numberTickerStyle: component.numberTickerStyle,
    );
  }

  void _finishAnimation(double value) {
    _timer?.cancel();
    _timer = null;
    _startValue = value;
    _targetValue = value;
    _displayValue = value;
    _elapsed = 0;
  }

  void _startAnimation(double from, double to) {
    final duration = _resolveDuration(context);
    if (duration == Duration.zero) {
      setState(() => _finishAnimation(to));
      return;
    }

    _timer?.cancel();
    _startValue = from;
    _targetValue = to;
    _elapsed = 0;

    final totalMs = duration.inMilliseconds;
    final easingFn = component.curve ?? _easeInOut;

    _timer = Timer.periodic(
      const Duration(milliseconds: _kFrameIntervalMs),
      (_) {
        _elapsed += _kFrameIntervalMs;
        final progress = (_elapsed / totalMs).clamp(0.0, 1.0);
        final eased = easingFn(progress);

        setState(() {
          _displayValue = _startValue + (_targetValue - _startValue) * eased;
        });

        if (progress >= 1.0) {
          _timer?.cancel();
          _timer = null;
        }
      },
    );
  }

  @override
  void didUpdateComponent(covariant NumberTicker oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.value != component.value) {
      _startAnimation(
        _displayValue,
        component.value.toDouble(),
      );
    } else if (_hasAnimationWork &&
        _resolveDuration(context) == Duration.zero) {
      _finishAnimation(component.value.toDouble());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Builder mode — delegate to user.
    if (component.builder != null) {
      return component.builder!(context, _displayValue, component.child);
    }

    final resolved = _resolve(context);
    final displayText = component.formatter != null
        ? component.formatter!(_displayValue)
        : _displayValue.toStringAsFixed(
            _targetValue == _targetValue.roundToDouble() ? 0 : 2,
          );

    return span(
      [Text(displayText)],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
