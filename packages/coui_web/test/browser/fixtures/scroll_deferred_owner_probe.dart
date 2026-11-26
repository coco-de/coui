import 'package:coui_web/coui_web.dart';

void Function(String generation)? scrollDeferredFirstFrame;
final _keys = <String, GlobalStateKey<State<ScrollableClient>>>{
  for (final name in ['A', 'B'])
    name: GlobalStateKey<State<ScrollableClient>>(),
};
final _childKeys = <String, GlobalStateKey<_ChildState>>{
  for (final name in ['A', 'B']) name: GlobalStateKey<_ChildState>(),
};
final _retained = <String, State<ScrollableClient>?>{};
final _samples = <String, List<Object?>>{};
final _events = <String>[];

Map<String, Object?> readScrollDeferredOwner() => {
  'currentMounted': {
    for (final e in _keys.entries) e.key: e.value.currentState?.mounted,
  },
  'retainedMounted': {
    for (final e in _retained.entries) e.key: e.value?.mounted,
  },
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
  'sameRetainedState': identical(_retained['A'], _retained['B']),
  'samples': _samples,
  'events': _events,
};

Component scrollDeferredOwnerProbe(String generation) => CoUIWeb(
  theme: .coui,
  enableThemeAnimation: false,
  child: _Host(generation: generation, key: ValueKey('host-$generation')),
);

class _Host extends StatefulComponent {
  const _Host({required this.generation, super.key});

  final String generation;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final Component _child;

  @override
  void initState() {
    super.initState();
    final name = component.generation;
    _child = _Child(name: name, key: _childKeys[name]);
    _events.add('host-mount-$name');
    context.binding.addPostFrameCallback(() {
      _retained[name] = _keys[name]!.currentState;
      _events.add('first-frame-$name');
      scrollDeferredFirstFrame?.call(name);
    });
  }

  @override
  void dispose() {
    _events.add('host-dispose-${component.generation}');
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final name = component.generation;
    return ScrollableClient(
      key: _keys[name],
      id: 'deferred-real-viewport',
      classes: 'viewport-caller',
      css: const Styles(
        raw: {
          'width': '240px',
          'height': '120px',
          'color': '#123456',
        },
      ),
      attributes: {'data-owner': name, 'aria-label': 'Caller viewport $name'},
      horizontalDetails: CoreScrollableDetails.horizontal(
        initialOffset: name == 'A' ? 15 : 45,
      ),
      verticalDetails: CoreScrollableDetails.vertical(
        initialOffset: name == 'A' ? 25 : 65,
      ),
      child: _child,
      builder: (context, offset, viewport, child) {
        (_samples[name] ??= []).add({
          'dx': offset.dx,
          'dy': offset.dy,
          'width': viewport.width,
          'height': viewport.height,
          'sameChild': identical(child, _child),
        });
        return div(
          [?child],
          styles: const Styles(
            raw: {
              'width': '720px',
              'height': '480px',
            },
          ),
        );
      },
    );
  }
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
    [Text('Scroll ${component.name} $_clicks')],
    id: 'scroll-child-${component.name}',
    onClick: () => setState(() => _clicks++),
  );
}
