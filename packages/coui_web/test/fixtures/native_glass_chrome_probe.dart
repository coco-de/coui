/// Release-browser probe for structural material switching and scroll edges.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client;
import 'package:web/web.dart' as web;

void main() {
  final config = ThemeConfig.defaults();
  web.document.head!
    ..appendChild(
      web.HTMLStyleElement()
        ..textContent =
            '${config.cssVariables}${config.darkVariableBlock}${config.surfaceStyleVariableBlocks}${config.densityVariableBlocks}',
    )
    ..appendChild(web.HTMLScriptElement()..textContent = config.tailwindConfig);
  client.Jaspr.initializeApp();
  client.runApp(const _Probe());
}

class _Probe extends StatefulComponent {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int _clicks = 0;
  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: ThemeData.coui,
    enableThemeAnimation: false,
    child: div([
      Scaffold(
        floatingHeader: true,
        headers: [
          AppBar(
            id: 'probe-appbar',
            centerTitle: true,
            title: const Text('Dashboard'),
            leading: [
              Button(
                variant: .ghost,
                size: .sm,
                shape: .square,
                attributes: const {'aria-label': 'Back'},
                onPressed: () {},
                child: const Icon(LucideIcons.menu),
              ),
            ],
            trailing: [
              Button(
                variant: .ghost,
                size: .sm,
                shape: .square,
                attributes: const {'aria-label': 'Search'},
                onPressed: () => setState(() => _clicks++),
                child: const Icon(LucideIcons.search),
              ),
              DropdownMenu(
                trigger: Button(
                  variant: .ghost,
                  size: .sm,
                  shape: .square,
                  onPressed: () {},
                  child: const Icon(LucideIcons.ellipsis),
                ),
                items: [
                  CoreMenuItem.action('Save collection', onPressed: () {}),
                ],
              ),
            ],
          ),
        ],
        child: div([
          Text('Clicks: $_clicks'),
          for (var i = 0; i < 24; i++)
            div(
              [Text('Collection ${i + 1}')],
              styles: Styles(
                raw: {
                  'height': '140px',
                  'margin': '12px 16px',
                  'border-radius': '20px',
                  'padding': '24px',
                  'color': 'white',
                  'background': [
                    '#1798ff',
                    '#ff9623',
                    '#c63ee9',
                    '#34c76a',
                  ][i % 4],
                },
              ),
            ),
        ]),
      ),
    ], styles: const Styles(raw: {'width': '480px', 'margin': '0 auto'})),
  );
}
