/// Client fixture for the typography tier probe: a popover and a context
/// menu opened inside a [TypographyTierScope], so a real Chrome can read
/// what each panel draws once it has been portalled out of the scope.
///
/// A panel only exists after a click on a hydrated page, which a server
/// render cannot show — hence a client entry, compiled and loaded by
/// `typography_tier_probe_test.dart`. The context menu also needs the
/// browser's own `contextmenu` event, which no VM test can build. Every
/// heading carries a role class and an id that ends in the role, so the
/// probe reads them like its server pages.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

/// The roles each group of headings draws.
const List<String> _kRoles = ['display-large', 'headline-small'];

/// One heading per role, ids prefixed with [prefix].
Component _roles(String prefix) => div([
  for (final role in _kRoles)
    div(const [Text('Ag')], id: '$prefix-$role', classes: 'text-$role'),
]);

void main() => client.runApp(
  CoUIWeb(
    theme: .coui,
    child: div([
      // The page's own tier — what the viewport gives it.
      _roles('free'),
      TypographyTierScope(
        tier: .desktop,
        child: Popover(
          trigger: div([
            const button([Text('Open')], id: 'probe-trigger'),
            _roles('trigger'),
          ]),
          content: _roles('panel'),
        ),
      ),
      TypographyTierScope(
        tier: .desktop,
        child: ContextMenu(
          // A label row's leading slot takes any component — the headings
          // the probe reads in the menu panel.
          items: [CoreMenuItem.label('Roles', leading: _roles('context'))],
          child: const div([Text('Right-click')], id: 'probe-context'),
        ),
      ),
    ]),
  ),
);
