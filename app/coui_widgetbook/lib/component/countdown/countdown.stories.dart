import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'countdown.stories.g.dart';

// Countdown widgetbook constants.
const _kDefaultValue = 42;
const _kTimerStartValue = 10;
const _kTimerTickInterval = Duration(seconds: 1);

/// Demo host for [Countdown] stories.
///
/// Renders a static [Countdown] by default; with [timerDriven] the
/// value ticks down every second from [value] to zero and a restart
/// button re-arms the timer, showing the roll animation.
class CountdownDemo extends StatefulWidget {
  /// Creates a [CountdownDemo].
  const CountdownDemo({
    super.key,
    this.value = _kDefaultValue,
    this.timerDriven = false,
  });

  /// Displayed value (the timer start value when [timerDriven]).
  final int value;

  /// Whether the value ticks down once per second.
  final bool timerDriven;

  @override
  State<CountdownDemo> createState() => _CountdownDemoState();
}

class _CountdownDemoState extends State<CountdownDemo> {
  // deferred init must read widget.
  late int _value = widget.value;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.timerDriven) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_kTimerTickInterval, handleTick);
  }

  @override
  void didUpdateWidget(CountdownDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.timerDriven != widget.timerDriven) {
      _value = widget.value;
      _timer?.cancel();
      if (widget.timerDriven) {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void handleTick(Timer timer) {
    setState(() {
      if (_value > 0) {
        _value -= 1;
      } else {
        timer.cancel();
      }
    });
  }

  void handleRestart() {
    setState(() => _value = widget.value);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        Countdown(value: _value),
        if (widget.timerDriven)
          Button(
            onPressed: handleRestart,
            child: const Text('Restart'),
          ),
      ],
    );
  }
}

/// Navigation metadata for the Countdown component.
const kComponentMeta = ComponentMeta(name: 'Countdown', path: 'display');

/// Story metadata for [CountdownDemo].
const kMeta = Meta(CountdownDemo.new);

/// Static countdown value with an editable knob.
final $Default = _Story();

/// Timer-driven countdown that ticks to zero with a restart button.
final $Timer = _Story(
  args: _Args(
    value: IntArg(_kTimerStartValue),
    timerDriven: BoolArg(true),
  ),
);
