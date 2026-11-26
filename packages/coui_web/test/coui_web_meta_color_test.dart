import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

CoUIWeb _app({String? color}) => .new(
  theme: .coui,
  color: color,
  child: div([]),
);

void main() {
  group('CoUIWeb.color', () {
    test('defaults to null, settable (Flutter CoUIApp.color parity)', () {
      expect(_app().color, isNull);
      expect(_app(color: '#3366ff').color, equals('#3366ff'));
    });

    testComponents('renders without throwing when color is set', (
      tester,
    ) async {
      // The `<meta name="theme-color">` sync is a browser-only DOM side
      // effect (stubbed under jaspr_test); this guards the initState /
      // render path stays intact when `color` is supplied.
      tester.pumpComponent(_app(color: '#3366ff'));
      expect(find.tag('div'), findsComponents);
    });
  });
}
