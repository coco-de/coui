/// Client fixture for the brightness scope panel probe: on a light page,
/// popovers and a context menu opened inside a dark `BrightnessScope`, so a
/// real Chrome can read what each panel draws once it has been portalled out
/// of the scope.
///
/// A panel only exists after a click on a hydrated page, which a server
/// render cannot show — hence a client entry, compiled and loaded by
/// `brightness_scope_panel_probe_test.dart`. The context menu also needs the
/// browser's own `contextmenu` event, which no VM test can build.
///
/// Every panel holds one element the probe reads by id:
///
///   · `scoped-panel` — a popover opened inside the dark scope, mounted on
///     the app's host, outside the scope;
///   · `plain-panel` — the same popover with no scope, in the page's light;
///   · `hosted-panel` — the same popover opened inside a dark scope that
///     also holds its own host, so its panel renders inside the scope with
///     no restating at all — the dark panel the first one has to match;
///   · `context-panel` — a context menu opened inside the dark scope.
///
/// `scope-text` is plain content inside the dark scope and `page-text` is
/// plain content on the page — the variables each brightness gives.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

/// A popover whose trigger is a button with id `$name-trigger` and whose
/// panel holds an element with id `$name-panel`.
Component _popover(String name) => Popover(
  trigger: button([Text(name)], id: '$name-trigger'),
  content: div(const [Text('Ag')], id: '$name-panel'),
);

void main() => client.runApp(
  CoUIWeb(
    theme: .coui,
    child: div([
      const div([Text('page')], id: 'page-text'),
      BrightnessScope(
        brightness: .dark,
        child: div([
          const div([Text('scope')], id: 'scope-text'),
          _popover('scoped'),
          const ContextMenu(
            // A label row's leading slot takes any component — the element
            // the probe reads in the menu panel.
            items: [
              CoreMenuItem.label(
                'Ag',
                leading: div([Text('Ag')], id: 'context-panel'),
              ),
            ],
            child: div([Text('Right-click')], id: 'probe-context'),
          ),
        ]),
      ),
      _popover('plain'),
      BrightnessScope(
        brightness: .dark,
        child: OverlayHost(child: _popover('hosted')),
      ),
    ]),
  ),
);
