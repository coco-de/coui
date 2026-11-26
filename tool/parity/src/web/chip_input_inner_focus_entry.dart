/// Client fixture for the ChipInput inner-focus probe.
///
/// One ChipInput on a page, so the probe can read in a real browser what a VM
/// cannot: that focusing the inline input draws no border around it while the
/// frame's own ring still shows.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatelessComponent {
  const _Probe();

  @override
  Component build(BuildContext context) => div(
    [
      ChipInput(
        chips: const ['Flutter', 'Dart'],
        placeholder: 'Add a tag...',
        onChanged: (_) {},
      ),
    ],
    styles: Styles(
      raw: const {'width': '360px', 'padding': '16px'},
    ),
  );
}
