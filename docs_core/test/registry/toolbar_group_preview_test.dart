import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/toolbar_group/toolbar_group_default_example.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toolbar preview fits its pane and its actions update zoom', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(320, kDocsPreviewConstraints['toolbar-group']!.minHeight);
    addTearDown(tester.view.reset);
    expect(kDocsWideComponents, contains('toolbar-group'));
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: const ToolbarGroupDefaultExample(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('배율: 100%'), findsOneWidget);
    await tester.tap(find.text('확대'));
    await tester.pumpAndSettle();
    expect(find.text('배율: 110%'), findsOneWidget);
    await tester.tap(find.text('축소'));
    await tester.pumpAndSettle();
    expect(find.text('배율: 100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
