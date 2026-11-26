import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart';

void _handleToggleChanged(bool value) {}
void _handleChipTapped() {}
const _kRawBase = CoreColor(0xff334455);
const _kAlphaBase = CoreColor(0x80334455);
const _kRawInk = CoreColor(0x8012a43c);
const _kShared = Toggle(
  value: true,
  onChanged: _handleToggleChanged,
  toggleStyle: CoreToggleStyle(trackActiveColor: _kRawBase),
);

Component _row(String id, Component child) => div(
  [child],
  attributes: {'data-runtime-paint': id},
  styles: const Styles(
    raw: {'padding': '20px', 'width': '600px', 'background-color': '#eeeeee'},
  ),
);

Component selectedBaseRuntimeProbe() => Component.fragment([
  Style(styles: docsContentTheme().styles),
  CoUIWeb(theme: ThemeData.coui, child: const _Probe()),
]);

class _Probe extends StatefulComponent {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool _owned = false;
  bool _value = true;
  bool _themeOwned = false;
  int _revision = 0;
  int _mount = 0;

  @override
  Component build(BuildContext context) {
    final variant =
        CoreToggleStyle.defaultsByVariant[CoreToggleVariant.defaultVariant]!;
    final sameBase = CoreToggleStyle(
      trackActiveColor: variant.activeTrack,
      trackInactiveColor: variant.inactiveTrack,
    );
    final inherited = ThemeData.coui.copyWith(
      coreComponentTheme: CoreComponentTheme(
        toggle: CoreToggleTheme(style: _themeOwned ? sameBase : null),
      ),
    );
    return div([
      button(
        const [Text('Mode')],
        id: 'runtime-mode',
        onClick: () => setState(() => _owned = !_owned),
      ),
      button(
        const [Text('Value')],
        id: 'runtime-value',
        onClick: () => setState(() => _value = !_value),
      ),
      button(
        const [Text('Inherited')],
        id: 'runtime-theme',
        onClick: () => setState(() => _themeOwned = !_themeOwned),
      ),
      button(
        const [Text('Rebuild')],
        id: 'runtime-rebuild',
        onClick: () => setState(() => _revision++),
      ),
      button(
        const [Text('Remount')],
        id: 'runtime-remount',
        onClick: () => setState(() => _mount++),
      ),
      div(
        const [],
        id: 'runtime-status',
        attributes: {
          'data-owned': '$_owned',
          'data-value': '$_value',
          'data-theme-owned': '$_themeOwned',
          'data-revision': '$_revision',
          'data-mount': '$_mount',
        },
      ),
      _row(
        'default-peer',
        Toggle(value: _value, onChanged: _handleToggleChanged),
      ),
      _row(
        'dynamic',
        Toggle(
          key: ValueKey('dynamic-$_mount'),
          value: _value,
          onChanged: _handleToggleChanged,
          toggleStyle: _owned ? sameBase : null,
        ),
      ),
      _row(
        'inherited',
        Theme(
          data: inherited,
          child: Toggle(value: _value, onChanged: _handleToggleChanged),
        ),
      ),
      _row('reused-a', _kShared),
      _row('reused-b', _kShared),
      _row(
        'active-outer-raw-inner',
        Chip(
          id: 'outer-active-raw',
          onTap: _handleChipTapped,
          selected: true,
          chipStyle: const CoreChipStyle(
            backgroundColor: _kRawBase,
            foregroundColor: _kRawInk,
          ),
          child: Chip(
            id: 'inner-passive-raw',
            label: 'Passive raw',
            chipStyle: const CoreChipStyle(backgroundColor: _kAlphaBase),
          ),
        ),
      ),
      _row(
        'active-outer-clear-inner',
        Chip(
          id: 'outer-active-clear',
          onTap: _handleChipTapped,
          selected: true,
          chipStyle: const CoreChipStyle(
            backgroundColor: _kRawBase,
            foregroundColor: _kRawInk,
          ),
          child: Chip(id: 'inner-passive-clear', label: 'Passive clear'),
        ),
      ),
      _row(
        'passive-outer-active-inner',
        Chip(
          id: 'outer-passive',
          chipStyle: const CoreChipStyle(backgroundColor: _kRawBase),
          child: Chip(
            id: 'inner-active',
            label: 'Active inner',
            onTap: _handleChipTapped,
            chipStyle: const CoreChipStyle(
              backgroundColor: _kAlphaBase,
              foregroundColor: _kRawInk,
            ),
          ),
        ),
      ),
    ]);
  }
}
