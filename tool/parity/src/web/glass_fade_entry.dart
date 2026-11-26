/// Client fixture for the glass fade runtime probe: a dialog and a popover the
/// page opens and closes on demand, on a page where the refraction runtime is
/// running, so a real Chrome can read what the runtime does to a panel that is
/// still fading in.
///
/// A panel only exists after a click on a hydrated page, which a server render
/// cannot show — hence a client entry, compiled and loaded by
/// `glass_fade_runtime_probe_test.dart`.
///
///   · `open-dialog` / `close-dialog` — buttons the probe clicks from script
///     (the dialog's scrim covers the page, so a pointer could not reach
///     them);
///   · `dialog-body` — content in the dialog's panel;
///   · `p-trigger` — the popover's trigger, and `p-panel` the content in its
///     panel;
///   · `plain-surface` — a glass surface that never fades, the surface the
///     runtime always handled.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _App()));

class _App extends StatefulComponent {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  bool _open = false;

  void _set({required bool open}) => setState(() => _open = open);

  @override
  Component build(BuildContext context) => div([
    button(
      const [Text('open')],
      id: 'open-dialog',
      events: {'click': (_) => _set(open: true)},
    ),
    button(
      const [Text('close')],
      id: 'close-dialog',
      events: {'click': (_) => _set(open: false)},
    ),
    const div(
      [Text('plain')],
      id: 'plain-surface',
      classes: 'coui-surface coui-surface-content',
      styles: Styles(
        raw: {
          'width': '200px',
          'height': '80px',
          '--coui-surface-rgb': 'var(--coui-surface-bright)',
        },
      ),
    ),
    const Popover(
      trigger: button([Text('p')], id: 'p-trigger'),
      content: div(
        [Text('Ag')],
        id: 'p-panel',
        styles: Styles(raw: {'width': '240px', 'height': '120px'}),
      ),
    ),
    Dialog(
      open: _open,
      onClose: () => _set(open: false),
      content: const div(
        [Text('Ag')],
        id: 'dialog-body',
        styles: Styles(raw: {'width': '240px', 'height': '120px'}),
      ),
    ),
  ]);
}
