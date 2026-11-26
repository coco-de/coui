import 'dart:async';

import 'package:coui_web/coui_web.dart';

Map<String, Object?> Function()? readRefreshDeferredOwner;

Component refreshDeferredOwnerProbe() => CoUIWeb(
  theme: .coui,
  enableThemeAnimation: false,
  child: const _Host(),
);

class _Host extends StatefulComponent {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _key = GlobalStateKey<RefreshTriggerState>();
  final _childKey = GlobalStateKey<_ChildState>();
  final _pending = [Completer<void>(), Completer<void>()];
  final _error = StateError('caller-refresh-error');
  final _results = <String, Object?>{};
  final _invocationMounted = <bool>[];
  final _callbackMounted = <bool?>[];
  RefreshTriggerState? _retained;
  bool _visible = true;
  int _callbackCount = 0;

  @override
  void initState() {
    super.initState();
    readRefreshDeferredOwner = () => {
      'callbackCount': _callbackCount,
      'callbackMounted': _callbackMounted,
      'invocationMounted': _invocationMounted,
      'results': _results,
      'currentMounted': _key.currentState?.mounted,
      'retainedMounted': _retained?.mounted,
      'stateToken': _key.currentState == null
          ? null
          : identityHashCode(_key.currentState),
      'childToken': _childKey.currentState == null
          ? null
          : identityHashCode(_childKey.currentState),
      'visible': _visible,
    };
  }

  Future<void> _handleRefresh() {
    _callbackMounted.add(_retained?.mounted);
    return _pending[_callbackCount++].future;
  }

  void _start(int count) {
    final state = _key.currentState!;
    _retained = state;
    for (var i = 0; i < count; i++) {
      final name = i == 0 ? 'first' : 'second';
      _invocationMounted.add(state.mounted);
      _results[name] = {'status': 'pending'};
      unawaited(
        state.refresh().then<void>(
          (_) => _results[name] = {'status': 'done'},
          onError: (Object error, StackTrace stack) {
            _results[name] = {
              'status': 'error',
              'error': '$error',
              'isOwnedError': identical(error, _error),
            };
          },
        ),
      );
    }
  }

  @override
  Component build(BuildContext context) => div([
    button(
      const [Text('Start two')],
      id: 'refresh-start-two',
      onClick: () => _start(2),
    ),
    button(
      const [Text('Start one')],
      id: 'refresh-start-one',
      onClick: () => _start(1),
    ),
    button(
      const [Text('Remove trigger')],
      id: 'refresh-remove',
      onClick: () => setState(() => _visible = false),
    ),
    button(
      const [Text('Complete first')],
      id: 'refresh-complete-first',
      onClick: () => _pending[0].complete(),
    ),
    button(
      const [Text('Complete second')],
      id: 'refresh-complete-second',
      onClick: () => _pending[1].complete(),
    ),
    button(
      const [Text('Fail first')],
      id: 'refresh-fail-first',
      onClick: () => _pending[0].completeError(_error),
    ),
    if (_visible)
      RefreshTrigger(
        key: _key,
        id: 'refresh-real-root',
        classes: 'refresh-caller',
        css: const Styles(
          raw: {
            'width': '260px',
            'height': '160px',
            'color': '#123456',
          },
        ),
        attributes: const {'aria-label': 'Caller refresh region'},
        onRefresh: _handleRefresh,
        child: _Child(key: _childKey),
      )
    else
      const Text('Trigger removed'),
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
    [Text('Refresh child $_clicks')],
    id: 'refresh-real-child',
    onClick: () => setState(() => _clicks++),
  );
}
