import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final variant in ['vertical', 'passive']) {
    testWidgets('$variant indicator fits its preview and retains its behavior', (
      tester,
    ) async {
      final stage = docsPreviewConstraintsFor('dot-indicator', variant);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(320, stage.maxHeight);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.previewLight),
          debugShowCheckedModeBanner: false,
          disableBrowserContextMenu: false,
          enableThemeAnimation: false,
          scaling: const AdaptiveScaling(),
          home: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kDocsPreviewContentInset),
              child: kFlutterPreviewRegistry['dot-indicator']!(variant),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final indicator = tester.widget<DotIndicator>(find.byType(DotIndicator));
      expect(indicator.length, 3);
      expect(indicator.direction, variant == 'vertical' ? CoreAxis.vertical : CoreAxis.horizontal);
      expect(indicator.onChanged, variant == 'vertical' ? isNotNull : isNull);
      if (variant == 'vertical') {
        final dots = find.descendant(
          of: find.byType(DotIndicator),
          matching: find.byType(Clickable),
        );
        await tester.tap(dots.first);
        await tester.pumpAndSettle();
        expect(tester.widget<DotIndicator>(find.byType(DotIndicator)).index, 0);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
