import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

String? get _value =>
    (find.tag('input').evaluate().single.component as DomComponent)
        .attributes?['value'];

void main() {
  testComponents('initialValue seeds once across parent rebuilds', (
    tester,
  ) async {
    late _HostState host;
    pumpWithTheme(tester, _Host(onState: (value) => host = value));
    expect(_value, 'first');
    host.update('second');
    await tester.pump();
    expect(_value, 'first');
  });

  testComponents('plain uncontrolled field listens without a callback', (
    tester,
  ) async {
    pumpWithTheme(tester, const TextField());
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.events?.containsKey('input'), isTrue);
  });

  testComponents('controlled value still follows its parent', (tester) async {
    late _HostState host;
    pumpWithTheme(
      tester,
      _Host(controlled: true, onState: (value) => host = value),
    );
    expect(_value, 'first');
    host.update('second');
    await tester.pump();
    expect(_value, 'second');
    host.update('');
    await tester.pump();
    expect(_value, '');
    expect(find.tag('button'), findsNothing);
  });
}

class _Host extends StatefulComponent {
  const _Host({required this.onState, this.controlled = false});
  final void Function(_HostState) onState;
  final bool controlled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = 'first';

  void update(String next) => setState(() => value = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return TextField(
      initialValue: component.controlled ? null : value,
      value: component.controlled ? value : null,
      features: const [CoreInputFeature.clear()],
    );
  }
}
