import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Widget _host(Widget child, GlobalKey<NavigatorState> navigator) => buildTestApp(
  Navigator(
    key: navigator,
    onGenerateRoute: (settings) => PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, _, _) => child,
    ),
  ),
);

bool? _expanded(WidgetTester tester, Key swiper) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byKey(swiper), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .expanded;

void main() {
  for (final dismissByRoute in [false, true]) {
    testWidgets(
      'Swiper rendered Semantics tracks real open/close without parent callback/$dismissByRoute',
      (tester) async {
        final swiper = GlobalKey();
        final navigator = GlobalKey<NavigatorState>();
        const child = SizedBox(width: 300, height: 160);
        const overlay = Text('swiper route content');
        coui.Swiper input({bool open = false}) => coui.Swiper(
          key: swiper,
          open: open,
          overlayContent: overlay,
          child: child,
        );
        final first = input();
        final current = ValueNotifier<Widget>(first);
        addTearDown(current.dispose);
        await tester.pumpWidget(
          _host(
            ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, value, _) => value,
            ),
            navigator,
          ),
        );
        await tester.pumpAndSettle();
        expect(first.onOpenChanged, isNull);
        expect(_expanded(tester, swiper), false);
        current.value = input(open: true);
        await tester.pumpAndSettle();
        expect(find.text('swiper route content'), findsOneWidget);
        expect(_expanded(tester, swiper), true);
        if (dismissByRoute) {
          navigator.currentState!.pop();
        } else {
          current.value = input();
        }
        await tester.pumpAndSettle();
        expect(find.text('swiper route content'), findsNothing);
        expect(_expanded(tester, swiper), false);
        if (dismissByRoute) {
          expect((current.value as coui.Swiper).open, true);
        }
      },
    );
  }
}
