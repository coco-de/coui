import 'package:coui_web/coui_web.dart';

void Function()? colorPickerSupportFirstFrame;
Map<String, int?> Function()? _readStateTokens;

Map<String, int?> colorPickerSupportStateTokens() =>
    _readStateTokens?.call() ?? const {};

Component colorPickerSupportProbe() =>
    CoUIWeb(theme: .coui, child: const _Probe());

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final Map<String, GlobalStateKey<State<ColorPicker>>> _keys = {
    for (final id in [
      'inline-null',
      'inline-true',
      'inline-false',
      'dynamic',
      'popover',
    ])
      id: GlobalStateKey<State<ColorPicker>>(),
  };
  final _values = <String, String>{};
  final _commits = <String, int>{};
  bool? _dynamicEnable = true;
  bool _dynamicEnabled = true;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _readStateTokens = () => {
      for (final entry in _keys.entries)
        entry.key: entry.value.currentState == null
            ? null
            : identityHashCode(entry.value.currentState),
    };
    // Registered before the child pickers: observe the initial finalized DOM
    // before their capability callbacks can schedule a subsequent update.
    context.binding.addPostFrameCallback(() {
      if (mounted) colorPickerSupportFirstFrame?.call();
    });
  }

  void _setEnable(bool? next) => setState(() {
    _dynamicEnable = next;
    _revision++;
  });

  Component _case(String id, bool? enable, {bool popover = false}) => div(
    [
      ColorPicker(
        key: _keys[id],
        color: _values[id] ?? '#6750A4',
        promptMode: popover ? .popover : .inline,
        showHexInput: popover,
        enableEyeDropper: enable,
        enabled: id == 'dynamic' ? _dynamicEnabled : null,
        onChanged: (value) => setState(() {
          _values[id] = value;
          _commits[id] = (_commits[id] ?? 0) + 1;
        }),
      ),
    ],
    attributes: {
      'data-picker-case': id,
      'data-value': _values[id] ?? '#6750A4',
      'data-commits': '${_commits[id] ?? 0}',
    },
  );

  @override
  Component build(BuildContext context) => div(
    [
      for (final entry in <String, bool?>{
        'null': null,
        'true': true,
        'false': false,
      }.entries)
        button(
          [Text('enable ${entry.key}')],
          attributes: {'data-enable': entry.key, 'type': 'button'},
          // Keep a focused picker input focused while the host changes only
          // this public property; the click still uses the real DOM handler.
          events: {
            'mousedown': (event) => event.preventDefault(),
            'click': (_) => _setEnable(entry.value),
          },
        ),
      button(
        const [Text('toggle enabled')],
        attributes: const {'data-toggle-enabled': '', 'type': 'button'},
        events: {
          'mousedown': (event) => event.preventDefault(),
          'click': (_) => setState(() {
            _dynamicEnabled = !_dynamicEnabled;
            _revision++;
          }),
        },
      ),
      _case('inline-null', null),
      _case('inline-true', true),
      _case('inline-false', false),
      _case('dynamic', _dynamicEnable),
      _case('popover', null, popover: true),
    ],
    attributes: {'data-picker-probe': '', 'data-revision': '$_revision'},
  );
}
