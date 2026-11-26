/// Client fixture using shipped components, for cross-platform interaction probes.
library;

import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiProbeConfigure')
external set _configure(JSFunction value);
@JS('couiProbeEvents')
external set _events(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int selected = 0;
  int rail = 0;
  int tab = 0;
  bool accept = true;
  bool enabled = true;
  bool visible = true;
  bool toggle = false;
  bool labels = true;
  double width = 480;
  CoreSurfaceStyleId? local;
  final events = <String>[];

  @override
  void initState() {
    super.initState();
    _events = (() => events.join(',')).toJS;
    _configure = ((String operation, String value) {
      if (operation == 'material') {
        SurfaceStyleScope.setSurfaceStyle(
          CoreSurfaceStyleId.values.byName(value),
        );
        return;
      }
      setState(() {
        switch (operation) {
          case 'selected':
            selected = int.parse(value);
          case 'tab':
            tab = int.parse(value);
          case 'accept':
            accept = value == 'true';
          case 'enabled':
            enabled = value == 'true';
          case 'visible':
            visible = value == 'true';
          case 'local':
            local = value == 'ambient'
                ? null
                : CoreSurfaceStyleId.values.byName(value);
          case 'labels':
            labels = value == 'true';
          case 'width':
            width = double.parse(value);
          case 'clear':
            events.clear();
        }
      });
    }).toJS;
  }

  @override
  Component build(BuildContext context) => div(
    [
      if (visible)
        NavigationBar(
          id: 'probe-nav',
          labelMode: labels ? .all : .none,
          selectedIndex: selected,
          onSelected: enabled
              ? (i) {
                  events.add('nav:$i');
                  if (accept) setState(() => selected = i);
                }
              : null,
          navigationBarStyle: CoreNavigationBarStyle(surfaceStyle: local),
          items: const [
            CoreNavigationBarItem.destination(label: 'Home'),
            CoreNavigationBarItem.destination(
              label: 'Disabled',
              enabled: false,
            ),
            CoreNavigationBarItem.destination(label: 'Search'),
            CoreNavigationBarItem.destination(label: 'Profile'),
          ],
        ),
      Tabs(
        id: 'probe-tabs',
        selectedIndex: tab,
        swipeable: true,
        onChanged: (i) {
          events.add('tab:$i');
          setState(() => tab = i);
        },
        tabs: const [
          CoreTabItem(label: 'First'),
          CoreTabItem(label: 'Disabled', enabled: false),
          CoreTabItem(label: 'Last'),
        ],
      ),
      Toggle(
        id: 'probe-toggle',
        value: toggle,
        label: 'Toggle',
        onChanged: (value) => setState(() => toggle = value),
      ),
      Slider(
        id: 'probe-slider',
        value: 20,
        enabled: enabled,
        onChanged: enabled ? (v) => events.add('slider:${v.round()}') : null,
        onChangeStart: (v) => events.add('start:${v.round()}'),
        onChangeEnd: (v) => events.add('end:${v.round()}'),
      ),
      AppBar(
        id: 'probe-appbar',
        title: const Text('Transparent toolbar'),
        appBarStyle: const CoreAppBarStyle(backgroundColor: .transparent),
      ),
      Popover(
        id: 'probe-popover',
        trigger: const Text('Open popover'),
        content: const Text('Glass content'),
        popoverStyle: CorePopoverStyle(
          panelStyle: CorePopupStyle(
            surfaceStyle: local,
            borderRadius: .all(24),
          ),
        ),
      ),
      // Last, so nothing above it moves. A rail hugs its column in a row —
      // the way an app shell places it — rather than stretching to the grid.
      div(
        [
          NavigationBar(
            id: 'probe-rail',
            mode: .rail,
            selectedIndex: rail,
            onSelected: (index) {
              events.add('rail:$index');
              setState(() => rail = index);
            },
            navigationBarStyle: CoreNavigationBarStyle(surfaceStyle: local),
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.search),
                label: 'Search',
              ),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.bell),
                label: 'Alerts',
              ),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.user),
                label: 'Profile',
              ),
            ],
          ),
        ],
        styles: const Styles(raw: {'display': 'flex'}),
      ),
      // A column of page actions, as it stands beside the rail in a side
      // strip. Hugs its content the same way.
      div(
        [
          ToolbarGroup(
            ariaLabel: 'Page actions',
            direction: .vertical,
            popupStyle: CorePopupStyle(surfaceStyle: local),
            children: [
              Button(
                variant: .ghost,
                shape: .square,
                onPressed: () => events.add('action:back'),
                attributes: const {'aria-label': 'Back'},
                child: const Icon(LucideIcons.house),
              ),
              Button(
                variant: .ghost,
                shape: .square,
                onPressed: () => events.add('action:share'),
                attributes: const {'aria-label': 'Share'},
                child: const Icon(LucideIcons.search),
              ),
            ],
          ),
        ],
        id: 'probe-actions',
        styles: const Styles(raw: {'display': 'flex'}),
      ),
    ],
    styles: Styles(
      raw: {
        'width': '${width}px',
        'margin': '48px',
        'display': 'grid',
        'gap': '48px',
      },
    ),
  );
}
