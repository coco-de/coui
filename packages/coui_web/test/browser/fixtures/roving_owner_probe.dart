import 'package:coui_web/coui_web.dart';

// The same configuration is deliberately mounted twice (Tabs is const).
// A component
// configuration is not the owner of an interactive collection's focus targets.
final rovingOwnerEvents = <String>[];
void Function()? rovingOwnerOnEvent;

void _handleTabChanged(int index) {
  rovingOwnerEvents.add('tab:$index');
  rovingOwnerOnEvent?.call();
}

void _handleToggleChanged(String value) {
  rovingOwnerEvents.add('toggle:$value');
  rovingOwnerOnEvent?.call();
}

const _kTabs = <CoreTabItem<Component>>[
  CoreTabItem(label: 'Alpha'),
  CoreTabItem(label: 'Beta'),
  CoreTabItem(label: 'Gamma'),
];
const _kToggles = <CoreToggleGroupItem<String, Component>>[
  CoreToggleGroupItem(value: 'alpha', label: 'Alpha'),
  CoreToggleGroupItem(value: 'beta', label: 'Beta'),
  CoreToggleGroupItem(value: 'gamma', label: 'Gamma'),
];
const _kSharedTabs = Tabs(
  tabs: _kTabs,
  selectedIndex: 0,
  onChanged: _handleTabChanged,
  swipeable: false,
);
// ToggleGroup declares const, but its existing List.length assert cannot
// be evaluated in a const invocation. Reuse one runtime configuration instead.
final _sharedToggle = ToggleGroup<String>(
  items: _kToggles,
  value: 'alpha',
  onChanged: _handleToggleChanged,
);

Component _group(String name, Component child) => div(
  [child],
  attributes: {'data-roving-case': name},
);

Component rovingOwnerProbe() => Theme.defaults(child: const _Probe());

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int _revision = 0;
  int _mount = 0;

  @override
  Component build(BuildContext context) => div([
    button(
      const [Text('Rebuild')],
      id: 'rebuild',
      onClick: () => setState(() => _revision++),
    ),
    button(
      const [Text('Remount')],
      id: 'remount',
      onClick: () => setState(() => _mount++),
    ),
    div(
      const [],
      id: 'revision',
      attributes: {'data-revision': '$_revision', 'data-mount': '$_mount'},
    ),
    _group('tabs-shared-a', _kSharedTabs),
    _group('tabs-shared-b', _kSharedTabs),
    _group(
      'tabs-explicit-a',
      const Tabs(
        id: 'caller-tabs-a',
        tabs: _kTabs,
        selectedIndex: 0,
        onChanged: _handleTabChanged,
        swipeable: false,
      ),
    ),
    _group(
      'tabs-explicit-b',
      const Tabs(
        id: 'caller-tabs-b',
        tabs: _kTabs,
        selectedIndex: 0,
        onChanged: _handleTabChanged,
        swipeable: false,
      ),
    ),
    _group('toggle-shared-a', _sharedToggle),
    _group('toggle-shared-b', _sharedToggle),
    _group(
      'toggle-explicit-a',
      ToggleGroup<String>(
        id: 'caller-toggle-a',
        items: _kToggles,
        value: 'alpha',
        onChanged: _handleToggleChanged,
      ),
    ),
    _group(
      'toggle-explicit-b',
      ToggleGroup<String>(
        id: 'caller-toggle-b',
        items: _kToggles,
        value: 'alpha',
        onChanged: _handleToggleChanged,
      ),
    ),
    _group(
      'tabs-lifecycle',
      Tabs(
        key: ValueKey('tabs-$_mount'),
        tabs: _kTabs,
        selectedIndex: _revision % 2,
        onChanged: _handleTabChanged,
        swipeable: false,
      ),
    ),
    _group(
      'toggle-lifecycle',
      ToggleGroup<String>(
        key: ValueKey('toggle-$_mount'),
        items: _kToggles,
        value: _revision.isEven ? 'alpha' : 'beta',
        onChanged: _handleToggleChanged,
      ),
    ),
  ]);
}
