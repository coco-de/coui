/// Client fixture for the navigation bar that follows scrolling content
/// (`NavigationBar.compact`): a scaffold in a scrollport of its own, on a
/// page that scrolls too.
library;

import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
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
  CoreNavigationCompact compact = .onScroll;
  final events = <String>[];

  @override
  void initState() {
    super.initState();
    _events = (() => events.join(',')).toJS;
    _configure = ((String operation, String value) {
      setState(() {
        switch (operation) {
          case 'selected':
            selected = int.parse(value);
          case 'compact':
            compact = CoreNavigationCompact.values.byName(value);
          case 'clear':
            events.clear();
        }
      });
    }).toJS;
  }

  @override
  Component build(BuildContext context) => div(
    [
      // The scrollport the scaffold scrolls in: the bar sticks to its
      // bottom, and the content moves under it.
      div(
        [
          Scaffold(
            floatingFooter: true,
            footers: [
              NavigationBar(
                id: 'probe-nav',
                selectedIndex: selected,
                compact: compact,
                onSelected: (index) {
                  events.add('nav:$index');
                  setState(() => selected = index);
                },
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
            child: const div(
              [
                // A strip that scrolls sideways inside the content.
                div(
                  [
                    div(
                      [],
                      styles: Styles(
                        raw: {'width': '1600px', 'height': '80px'},
                      ),
                    ),
                  ],
                  id: 'probe-strip',
                  styles: Styles(
                    raw: {'overflow-x': 'auto', 'width': '100%'},
                  ),
                ),
                div(
                  [],
                  styles: Styles(raw: {'height': '2400px'}),
                ),
              ],
            ),
          ),
        ],
        id: 'probe-viewport',
        styles: const Styles(
          raw: {
            'width': '400px',
            'height': '480px',
            'overflow-y': 'auto',
            'position': 'relative',
          },
        ),
      ),
      // The same bar with no compact form — a compact size of 1 — and so no
      // fold around its captions: what the bar above has to rest as.
      div(
        [
          NavigationBar(
            id: 'probe-plain',
            selectedIndex: selected,
            onSelected: (_) {},
            navigationBarStyle: const CoreNavigationBarStyle(compactScale: 1),
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
        styles: const Styles(raw: {'width': '400px'}),
      ),
      // Room for the page itself to scroll, further out than the content.
      const div([], styles: Styles(raw: {'height': '1600px'})),
    ],
    styles: const Styles(raw: {'margin': '48px'}),
  );
}
