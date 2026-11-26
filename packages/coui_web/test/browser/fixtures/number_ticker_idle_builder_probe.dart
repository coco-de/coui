import 'package:coui_web/coui_web.dart';

Map<String, Object?> Function()? readNumberTickerIdleBuilder;
void Function()? numberTickerIdleBuilderFirstFrame;

// A custom builder owns its DOM; an idle value needs no theme lookup.
Component numberTickerIdleBuilderProbe() => const _IdleProbe();

class _IdleProbe extends StatefulComponent {
  const _IdleProbe();

  @override
  State<_IdleProbe> createState() => _IdleProbeState();
}

class _IdleProbeState extends State<_IdleProbe> {
  final Map<String, GlobalStateKey<State<NumberTicker>>> _keys = {
    for (final name in ['plain', 'zero'])
      name: GlobalStateKey<State<NumberTicker>>(),
  };
  final Map<String, GlobalStateKey<_ChildState>> _childKeys = {
    for (final name in ['plain', 'zero']) name: GlobalStateKey<_ChildState>(),
  };
  final _values = <String, List<num>>{};
  late final Map<String, Component> _children;
  int _refreshes = 0;

  @override
  void initState() {
    super.initState();
    _children = {
      for (final name in ['plain', 'zero'])
        name: _Child(name: name, key: _childKeys[name]),
    };
    readNumberTickerIdleBuilder = () => {
      'values': _values,
      'refreshes': _refreshes,
      'stateTokens': {
        for (final e in _keys.entries)
          e.key: e.value.currentState == null
              ? null
              : identityHashCode(e.value.currentState),
      },
      'childTokens': {
        for (final e in _childKeys.entries)
          e.key: e.value.currentState == null
              ? null
              : identityHashCode(e.value.currentState),
      },
    };
    context.binding.addPostFrameCallback(() {
      numberTickerIdleBuilderFirstFrame?.call();
    });
  }

  @override
  Component build(BuildContext context) => div([
    button(
      const [
        Text('same target parent refresh'),
      ],
      id: 'idle-parent-refresh',
      onClick: () => setState(() => _refreshes++),
    ),
    for (final name in ['plain', 'zero'])
      NumberTicker.builder(
        key: _keys[name],
        value: 100,
        numberTickerStyle: name == 'zero'
            ? const CoreNumberTickerStyle(duration: Duration.zero)
            : null,
        child: _children[name],
        builder: (context, value, child) {
          (_values[name] ??= []).add(value);
          return span(
            [
              Text('idle:$value'),
              ?child,
            ],
            id: 'idle-$name',
            attributes: {'data-value': '$value'},
          );
        },
      ),
  ]);
}

class _Child extends StatefulComponent {
  const _Child({required this.name, super.key});

  final String name;

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  int _clicks = 0;

  @override
  Component build(BuildContext context) => button(
    [
      Text('Child $_clicks'),
    ],
    id: 'idle-child-${component.name}',
    onClick: () => setState(() => _clicks++),
  );
}
