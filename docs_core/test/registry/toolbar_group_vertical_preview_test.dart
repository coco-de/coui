import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/toolbar_group/toolbar_group_vertical_example.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vertical toolbar preview fits its pane, stands its actions in a column and updates zoom', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(320, docsPreviewConstraintsFor('toolbar-group', 'vertical').minHeight);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: const Center(child: ToolbarGroupVerticalExample()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('배율: 100%'), findsOneWidget);

    // One capsule 48 across, a 48 seat per action, one above the other.
    final buttons = find.byType(Button);
    expect(tester.getSize(find.byType(Popup)), const Size(48, 96));
    expect(tester.getTopLeft(buttons.last) - tester.getTopLeft(buttons.first), const Offset(0, 48));

    await tester.tap(find.bySemanticsLabel('확대'));
    await tester.pumpAndSettle();
    expect(find.text('배율: 110%'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('축소'));
    await tester.pumpAndSettle();
    expect(find.text('배율: 100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
