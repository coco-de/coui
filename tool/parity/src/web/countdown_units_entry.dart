/// Exercises the documented caller composition through real client rebuilds.
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/previews/examples/web/countdown/countdown_units_example.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int days = 100;

  @override
  Component build(BuildContext context) => div([
    div([CountdownUnitsExample(days: days)], id: 'units'),
    for (final value in [101, 100, 99, 98, 365, 400])
      button(
        [Text('$value')],
        id: 'days-$value',
        onClick: () => setState(() => days = value),
      ),
  ]);
}
