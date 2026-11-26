import 'dart:async';
import 'dart:convert';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client;

void main() {
  final config = jsonDecode(Uri.decodeComponent(Uri.base.fragment)) as Map;
  client.runApp(
    Component.fragment([
      Style(styles: docsContentTheme().styles),
      if (config['controller'] == true)
        CoUIWeb(theme: .coui, child: const _ControllerProbe())
      else
        _Probe(
          CoreSwiperPosition.values.byName(config['side'] as String),
          CoreSwiperVariant.values.byName(config['variant'] as String),
        ),
    ]),
  );
}

class _ControllerProbe extends StatefulComponent {
  const _ControllerProbe();

  @override
  State<_ControllerProbe> createState() => _ControllerProbeState();
}

class _ControllerProbeState extends State<_ControllerProbe> {
  final _controller = DrawerScrubController();
  int _completed = 0;

  void _command(String command) {
    switch (command) {
      case 'open-controller':
        _controller.update(0);
        unawaited(
          openDrawer<void>(
            context: context,
            side: .left,
            scrubController: _controller,
            builder: (_) => const Drawer(
              content: Text('One reusable public controller'),
              drawerStyle: CoreDrawerStyle(panelWidth: 320),
            ),
          ).then((_) {
            if (mounted) setState(() => _completed++);
          }),
        );
      case 'quarter':
        _controller.update(.25);
      case 'three-quarters':
        _controller.update(.75);
      case 'settle-open':
        _controller.settle(open: true);
      case 'settle-close':
        _controller.settle(open: false);
    }
    setState(() {});
  }

  @override
  Component build(BuildContext context) => div([
    for (final command in [
      'open-controller',
      'quarter',
      'three-quarters',
      'settle-open',
      'settle-close',
    ])
      Component.element(
        tag: 'button',
        attributes: {'data-command': command},
        events: {'click': (_) => _command(command)},
      ),
    div(
      const [],
      id: 'controller-stats',
      attributes: {
        'data-completed': '$_completed',
        'data-progress': '${_controller.progress}',
      },
    ),
    const div([], id: 'child-button'),
  ]);
}

class _Probe extends StatefulComponent {
  const _Probe(this.side, this.variant);
  final CoreSwiperPosition side;
  final CoreSwiperVariant variant;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool _enabled = true;
  bool _present = true;
  bool _open = false;
  int _opens = 0;
  int _closes = 0;
  int _clicks = 0;
  CoreSwiperPosition? _side;

  void _command(String command) => setState(() {
    switch (command) {
      case 'disable':
        _enabled = false;
      case 'enable':
        _enabled = true;
      case 'remove':
        _present = false;
      case 'restore':
        _present = true;
      case 'open':
        _open = true;
      case 'close':
        _open = false;
      case 'rotate':
        _side = .right;
      case 'left':
        _side = .left;
    }
  });

  @override
  Component build(BuildContext context) => div(
    [
      div([
        for (final command in [
          'disable',
          'enable',
          'remove',
          'restore',
          'open',
          'close',
          'rotate',
          'left',
        ])
          Component.element(
            tag: 'button',
            attributes: {'data-command': command},
            events: {'click': (_) => _command(command)},
          ),
      ], styles: const Styles(raw: {'display': 'none'})),
      div(
        const [],
        id: 'stats',
        attributes: {
          'data-opens': '$_opens',
          'data-closes': '$_closes',
          'data-clicks': '$_clicks',
        },
      ),
      CoUIWeb(
        theme: .coui,
        child: _present
            ? Swiper(
                enabled: _enabled,
                open: _open,
                position: _side ?? component.side,
                variant: component.variant,
                onOpenChanged: (open) => setState(() {
                  _open = open;
                  if (open) {
                    _opens++;
                  } else {
                    _closes++;
                  }
                }),
                swiperStyle: const CoreSwiperStyle(
                  drawerStyle: CoreDrawerStyle(panelWidth: 320),
                ),
                overlayContent: div([
                  Button(
                    id: 'close',
                    onPressed: () => setState(() => _open = false),
                    child: const Text('Close'),
                  ),
                  Button(
                    id: 'panel-focus',
                    onPressed: () {},
                    child: const Text('Focus'),
                  ),
                ], styles: const Styles(raw: {'height': '240px'})),
                child: div(
                  [
                    Button(
                      id: 'child-button',
                      onPressed: () => setState(() => _clicks++),
                      child: const Text('Ordinary click'),
                    ),
                  ],
                  styles: const Styles(
                    raw: {
                      'width': '800px',
                      'height': '500px',
                      'background': 'var(--color-surface)',
                    },
                  ),
                ),
              )
            : const Text('Removed'),
      ),
    ],
    id: 'fixture',
  );
}
