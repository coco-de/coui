import 'package:coui_web/coui_web.dart';

Map<String, int?> Function()? readColorPickerDisabledStates;

Component colorPickerDisabledProbe() => const _Probe();

class _Probe extends StatefulComponent {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final Map<String, GlobalStateKey<State<ColorPicker>>> _keys = {
    for (final id in ['disabled', 'live', 'popover'])
      id: GlobalStateKey<State<ColorPicker>>(),
  };
  final _colors = <String, String>{};
  final _commits = <String, int>{};
  bool _enabled = true;
  bool _showLive = true;
  int _revision = 0;
  CoreColorPickerMode _mode = .rgb;

  @override
  void initState() {
    super.initState();
    readColorPickerDisabledStates = () => {
      for (final entry in _keys.entries)
        entry.key: entry.value.currentState == null
            ? null
            : identityHashCode(entry.value.currentState),
    };
  }

  Component _control(String id, void Function() action) => button(
    [Text(id)],
    id: id,
    attributes: const {'type': 'button'},
    events: {
      'click': (_) => setState(() {
        action();
        _revision++;
      }),
    },
  );

  Component _case(String id) => div(
    [
      button(const [Text('before')], id: 'before-$id'),
      ColorPicker(
        key: _keys[id],
        id: 'picker-$id',
        color: _colors[id] ?? '#6750A4',
        enabled: id == 'live' && _enabled,
        promptMode: id == 'popover' ? .popover : .inline,
        showHexInput: true,
        showAlpha: true,
        pickerMode: id == 'disabled' ? _mode : null,
        onChanged: (value) => setState(() {
          _colors[id] = value;
          _commits[id] = (_commits[id] ?? 0) + 1;
        }),
      ),
      button(const [Text('after')], id: 'after-$id'),
    ],
    attributes: {
      'data-disabled-case': id,
      'data-value': _colors[id] ?? '#6750A4',
      'data-commits': '${_commits[id] ?? 0}',
    },
  );

  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: .coui,
    enableThemeAnimation: false,
    initialRecentColors: const [CoreColor(0xffff0000)],
    child: div(
      [
        _control('disable-live', () => _enabled = false),
        _control('enable-live', () => _enabled = true),
        _control('external-color', () => _colors['disabled'] = '#0000FF'),
        _control('external-mode', () => _mode = .hsv),
        const _HistoryUpdate(),
        _control('remove-live', () => _showLive = false),
        _case('disabled'),
        if (_showLive) _case('live'),
        _case('popover'),
      ],
      attributes: {
        'data-disabled-probe': '',
        'data-revision': '$_revision',
        'data-total-commits':
            '${_commits.values.fold<int>(0, (sum, count) => sum + count)}',
      },
    ),
  );
}

class _HistoryUpdate extends StatelessComponent {
  const _HistoryUpdate();

  @override
  Component build(BuildContext context) => button(
    const [Text('external-history')],
    id: 'external-history',
    onClick: () => RecentColorsScope.maybeOf(context)!.setHistory(
      const [CoreColor(0xff00ff00)],
    ),
  );
}
