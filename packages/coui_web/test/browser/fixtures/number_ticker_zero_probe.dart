import 'package:coui_web/coui_web.dart';

// A caller-authored duration outside the token scale exercises interpolation.
const _kLongDuration = Duration(milliseconds: 800);

Map<String, Object?> Function()? readNumberTickerZero;
void Function(String phase)? numberTickerZeroFrame;

Component numberTickerZeroProbe() => CoUIWeb(
  theme: ThemeData.coui.copyWith(
    coreComponentTheme: const CoreComponentTheme(
      numberTicker: CoreNumberTickerTheme(
        style: CoreNumberTickerStyle(duration: Duration.zero),
      ),
    ),
  ),
  enableThemeAnimation: false,
  child: const _Probe(),
);

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _values = <String, List<num>>{};
  final _curves = <String, List<double>>{};
  final _keys = <String, GlobalStateKey<State<NumberTicker>>>{};
  final _childKey = GlobalStateKey<_ChildState>();
  late final Component _child;
  int _value = 100;
  bool _liveZero = false;
  int _clicks = 0;

  Map<String, Object?> _read() => {
    'values': _values,
    'curves': _curves,
    'stateTokens': {
      for (final e in _keys.entries)
        e.key: e.value.currentState == null
            ? null
            : identityHashCode(e.value.currentState),
    },
    'childToken': _childKey.currentState == null
        ? null
        : identityHashCode(_childKey.currentState),
    'clicks': _clicks,
    'value': _value,
    'liveZero': _liveZero,
  };

  @override
  void initState() {
    super.initState();
    _child = _Child(key: _childKey);
    readNumberTickerZero = _read;
    context.binding.addPostFrameCallback(() {
      numberTickerZeroFrame?.call('initial');
    });
  }

  void _change(String phase, void Function() update) {
    setState(update);
    context.binding.addPostFrameCallback(() {
      numberTickerZeroFrame?.call(phase);
    });
  }

  Component _ticker(
    String name, {
    Duration? duration,
    bool formatted = false,
    bool chained = false,
    bool constantCurve = false,
  }) {
    final style = duration == null
        ? null
        : CoreNumberTickerStyle(duration: duration);
    final key = _keys.putIfAbsent(
      name,
      GlobalStateKey<State<NumberTicker>>.new,
    );
    double curve(double t) {
      (_curves[name] ??= []).add(t);
      return constantCurve ? 0.25 : t;
    }

    NumberTicker ticker;
    if (formatted) {
      ticker = NumberTicker(
        key: key,
        id: name,
        value: _value,
        initialValue: 0,
        numberTickerStyle: style,
        curve: curve,
        formatter: (value) {
          (_values[name] ??= []).add(value);
          return 'v=${value.toStringAsFixed(3)}';
        },
        css: const Styles(raw: {'color': '#123456', 'letter-spacing': '2px'}),
        classes: 'zero-caller',
        attributes: const {'role': 'status', 'aria-label': 'Public total'},
        onClick: (_) => _clicks++,
      );
    } else {
      ticker = NumberTicker.builder(
        key: key,
        value: _value,
        initialValue: 0,
        numberTickerStyle: style,
        curve: curve,
        child: name == 'zero-builder' ? _child : null,
        builder: (context, value, child) {
          (_values[name] ??= []).add(value);
          return span(
            [Text(value.toStringAsFixed(3)), ?child],
            id: name,
            attributes: {'data-value': '$value'},
          );
        },
      );
    }
    return chained
        ? ticker.withStyle(const CoreNumberTickerStyle(duration: Duration.zero))
        : ticker;
  }

  @override
  Component build(BuildContext context) => div([
    button(
      const [Text('update')],
      id: 'zero-update',
      onClick: () => _change('update', () => _value = 200),
    ),
    button(
      const [Text('retarget')],
      id: 'zero-retarget',
      onClick: () => _change('retarget', () => _value = 300),
    ),
    button(
      const [Text('zero existing target')],
      id: 'zero-live',
      onClick: () => _change('live-zero', () => _liveZero = true),
    ),
    _ticker('zero-formatted', duration: Duration.zero, formatted: true),
    _ticker('zero-builder', duration: Duration.zero, constantCurve: true),
    _ticker('zero-theme'),
    _ticker(
      'zero-chain',
      duration: _kLongDuration,
      chained: true,
    ),
    _ticker(
      'positive-150',
      duration: const Duration(milliseconds: CoreDuration.fast),
    ),
    _ticker('positive-800', duration: _kLongDuration),
    _ticker('positive-subms', duration: const Duration(microseconds: 500)),
    _ticker(
      'live-instance',
      duration: _liveZero ? Duration.zero : _kLongDuration,
    ),
    Theme(
      data: ThemeData.coui.copyWith(
        coreComponentTheme: CoreComponentTheme(
          numberTicker: CoreNumberTickerTheme(
            style: CoreNumberTickerStyle(
              duration: _liveZero ? Duration.zero : _kLongDuration,
            ),
          ),
        ),
      ),
      child: _ticker('live-theme'),
    ),
  ]);
}

class _Child extends StatefulComponent {
  const _Child({super.key});

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  int _clicks = 0;

  @override
  Component build(BuildContext context) => button(
    [Text('Child $_clicks')],
    id: 'zero-child',
    onClick: () => setState(() => _clicks++),
  );
}
