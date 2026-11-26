/// Shared SSR/hydration fixture for the real Iconify stroke regression.
library;

import 'package:coui_web/coui_web.dart';

/// The same component tree is server-rendered and hydrated in release mode.
Component iconStrokeProbe() => Theme.defaults(child: const _Probe());

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool _large = false;
  bool _replacement = false;
  bool _shown = true;
  int _clicks = 0;

  @override
  Component build(BuildContext context) => div([
    for (final size in [16.0, 20.0, 24.0, 28.0]) ...[
      Icon(
        LucideIcons.chevronDown,
        id: 'bundled-${size.toInt()}',
        iconStyle: CoreIconStyle(size: size),
      ),
      for (final mode in ['svg', 'mask', 'bg'])
        Icon(
          const IconName('lucide', 'a-arrow-down'),
          id: '$mode-${size.toInt()}',
          iconStyle: CoreIconStyle(size: size),
          attributes: {'mode': mode},
        ),
    ],
    const IconTheme(
      data: IconThemeData(size: 28, color: CoreColor(0xFF123456)),
      child: Icon(IconName('lucide', 'a-arrow-down'), id: 'ambient'),
    ),
    const IconTheme(
      data: IconThemeData(size: 28),
      child: Icon(
        IconName('lucide', 'a-arrow-down'),
        id: 'override',
        iconStyle: CoreIconStyle(size: 20),
      ),
    ),
    const Icon(
      IconName('lucide', 'custom-grid'),
      id: 'custom-grid',
      iconStyle: CoreIconStyle(size: 16),
    ),
    const Icon(IconName('test-control', 'outline'), id: 'outline'),
    const Icon(IconName('test-control', 'filled'), id: 'filled'),
    const Icon(IconName('test-control', 'multi'), id: 'multi'),
    Icon(
      const IconName('lucide', 'a-arrow-down'),
      id: 'customized',
      classes: 'caller-icon',
      attributes: const {
        'mode': 'mask',
        'rotate': '90deg',
        'flip': 'horizontal',
        'inline': 'true',
        'aria-label': 'Picture',
        'data-caller': 'retained',
      },
      eventHandlers: {
        'click': [(_) => setState(() => _clicks++)],
      },
    ),
    button(
      const [Text('Resize')],
      id: 'resize',
      onClick: () => setState(() => _large = !_large),
    ),
    button(
      const [Text('Replace')],
      id: 'replace',
      onClick: () => setState(() => _replacement = !_replacement),
    ),
    button(
      const [Text('Toggle')],
      id: 'toggle',
      onClick: () => setState(() => _shown = !_shown),
    ),
    if (_shown)
      Icon(
        IconName('lucide', _replacement ? 'image-off' : 'a-arrow-down'),
        id: 'dynamic',
        iconStyle: CoreIconStyle(size: _large ? 28 : 16),
      ),
    span([Text('$_clicks')], id: 'clicks'),
  ]);
}
