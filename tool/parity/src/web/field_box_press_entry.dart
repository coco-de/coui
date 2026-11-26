/// Client fixture for the framed-field box press probe.
///
/// A Select, a field with a glyph beside its input, a field with a clear
/// button, and a disabled one — on one page, so the probe can judge in a real
/// browser what a VM cannot: which pixels of a framed field answer a press,
/// that a control inside the box keeps its own click, that nothing fires
/// twice, and what the press does to focus and to the box's wash.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int _prefixedTaps = 0;
  int _clearableTaps = 0;
  int _disabledTaps = 0;

  @override
  Component build(BuildContext context) => div(
    [
      div(
        [
          const Select<String>(
            items: [
              CoreSelectItem(value: 'apple', label: 'Apple'),
              CoreSelectItem(value: 'banana', label: 'Banana'),
            ],
            placeholder: 'Pick a fruit',
          ),
        ],
        id: 'w-select',
      ),
      div(
        [
          TextField(
            prefix: const Text('@'),
            onTap: () => setState(() => _prefixedTaps++),
          ),
        ],
        id: 'w-prefixed',
      ),
      div(
        [
          TextField(
            initialValue: 'abc',
            features: [CoreInputFeature.clear()],
            onTap: () => setState(() => _clearableTaps++),
          ),
        ],
        id: 'w-clearable',
      ),
      div(
        [
          TextField(
            prefix: const Text('@'),
            enabled: false,
            onTap: () => setState(() => _disabledTaps++),
          ),
        ],
        id: 'w-disabled',
      ),
      p([Text('$_prefixedTaps')], id: 'taps-prefixed'),
      p([Text('$_clearableTaps')], id: 'taps-clearable'),
      p([Text('$_disabledTaps')], id: 'taps-disabled'),
    ],
    styles: Styles(
      raw: const {
        'width': '360px',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '16px',
        'padding': '16px',
      },
    ),
  );
}
