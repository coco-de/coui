/// Client fixture for the Diff pointer-focus probe.
///
/// A button ahead of a Diff, on one page, so the probe can read in a real
/// browser what a VM cannot: whether the focus ring a mouse press gives the
/// comparison is the keyboard ring or none. The button is there to put the
/// page in keyboard modality (Tab onto it) before the press — a script
/// `focus()` after keyboard input is matched by `:focus-visible`.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatelessComponent {
  const _Probe();

  @override
  Component build(BuildContext context) => const div(
    [
      Component.element(
        tag: 'button',
        id: 'ahead',
        children: [Text('Ahead of the comparison')],
      ),
      Diff(
        ariaLabel: 'Pointer focus probe',
        before: _Scene(color: '#c9ccd1'),
        after: _Scene(color: '#2f7fd8'),
      ),
    ],
    styles: Styles(raw: {'width': '480px', 'padding': '16px'}),
  );
}

class _Scene extends StatelessComponent {
  const _Scene({required this.color});

  final String color;

  @override
  Component build(BuildContext context) => div(
    const [],
    styles: Styles(
      raw: {'width': '100%', 'height': '100%', 'background-color': color},
    ),
  );
}
