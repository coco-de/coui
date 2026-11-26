import 'package:coui_web/coui_web.dart';

void Function()? numberTickerLifetimeFirstFrame;
Map<String, Object?> Function()? readNumberTickerLifetime;

Component numberTickerLifetimeProbe({bool withInitialValues = true}) => CoUIWeb(
  theme: .coui,
  enableThemeAnimation: false,
  child: _Probe(withInitialValues: withInitialValues),
);

class _Probe extends StatefulComponent {
  const _Probe({required this.withInitialValues});

  final bool withInitialValues;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final Map<String, GlobalStateKey<State<NumberTicker>>> _keys = {
    for (final name in ['plain', 'builder', 'same', 'no-initial'])
      name: GlobalStateKey<State<NumberTicker>>(),
  };
  final _childKey = GlobalStateKey<_ChildState>();
  final _retained = <String, State<NumberTicker>?>{};
  final _builderValues = <num>[];
  final _childIdentities = <bool>[];
  late final Component _child;
  int _value = 100;
  int _rootClicks = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _child = _Child(key: _childKey);
    readNumberTickerLifetime = () => {
      'mounted': {
        for (final entry in _keys.entries)
          entry.key: entry.value.currentState?.mounted,
      },
      'retainedMounted': {
        for (final entry in _retained.entries) entry.key: entry.value?.mounted,
      },
      'stateTokens': {
        for (final entry in _keys.entries)
          entry.key: entry.value.currentState == null
              ? null
              : identityHashCode(entry.value.currentState),
      },
      'builderValues': _builderValues,
      'childIdentities': _childIdentities,
      'childToken': _childKey.currentState == null
          ? null
          : identityHashCode(_childKey.currentState),
      'rootClicks': _rootClicks,
      'hostDisposed': _disposed,
    };
    // A public host may unmount its application as soon as its first tree
    // is finalized, before a child's deferred initial animation starts.
    context.binding.addPostFrameCallback(() {
      for (final entry in _keys.entries) {
        _retained[entry.key] = entry.value.currentState;
      }
      numberTickerLifetimeFirstFrame?.call();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Component build(BuildContext context) => div([
    button(
      const [Text('change value')],
      id: 'ticker-change',
      onClick: () => setState(() => _value += 100),
    ),
    NumberTicker(
      key: _keys['plain'],
      id: 'ticker-plain',
      value: _value,
      initialValue: component.withInitialValues ? 0 : null,
      formatter: (value) => 'v=${value.toStringAsFixed(1)}',
      classes: 'ticker-caller',
      css: const Styles(raw: {'color': '#123456', 'letter-spacing': '2px'}),
      attributes: const {'role': 'status', 'aria-label': 'Formatted total'},
      onClick: (_) => _rootClicks++,
    ),
    NumberTicker.builder(
      key: _keys['builder'],
      value: _value,
      initialValue: component.withInitialValues ? 0 : null,
      numberTickerStyle: const CoreNumberTickerStyle(
        duration: Duration(milliseconds: CoreDuration.fast),
      ),
      curve: (t) => t,
      child: _child,
      builder: (context, value, child) {
        _builderValues.add(value);
        _childIdentities.add(identical(child, _child));
        // The existing builder owns its complete DOM, including this root.
        return span(
          [Text(value.toStringAsFixed(2)), ?child],
          id: 'ticker-builder',
          attributes: {'data-builder-value': '$value'},
        );
      },
    ),
    NumberTicker(
      key: _keys['same'],
      id: 'ticker-same',
      value: 42,
      initialValue: component.withInitialValues ? 42 : null,
    ),
    NumberTicker(key: _keys['no-initial'], id: 'ticker-no-initial', value: 42),
  ]);
}

class _Child extends StatefulComponent {
  const _Child({super.key});

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  int _count = 0;

  @override
  Component build(BuildContext context) => button(
    [Text('Child $_count')],
    id: 'ticker-child',
    onClick: () => setState(() => _count++),
  );
}
