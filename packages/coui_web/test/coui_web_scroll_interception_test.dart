import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

CoUIWeb _app({bool? enableScrollInterception}) => .new(
  theme: .coui,
  enableScrollInterception: enableScrollInterception ?? true,
  child: div([]),
);

void main() {
  group('CoUIWeb.enableScrollInterception', () {
    test('defaults to true (Flutter CoUIApp parity), settable to false', () {
      expect(_app().enableScrollInterception, isTrue);
      expect(
        _app(enableScrollInterception: false).enableScrollInterception,
        isFalse,
      );
    });

    testComponents('mounts the CoUI ScrollViewInterceptor when enabled', (
      tester,
    ) async {
      tester.pumpComponent(_app());
      expect(find.byType(ScrollViewInterceptor), findsOneComponent);
    });

    testComponents('omits the ScrollViewInterceptor when disabled', (
      tester,
    ) async {
      // The browser's native middle-click autoscroll is suppressed at the
      // document level instead (`initState`, browser-only — no DOM under
      // jaspr_test); the CoUI engine is not mounted.
      tester.pumpComponent(_app(enableScrollInterception: false));
      expect(find.byType(ScrollViewInterceptor), findsNothing);
    });
  });
}
