import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('transparent app bar leaves glass on its toolbar capsules', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const AppBar(
        appBarStyle: CoreAppBarStyle(
          surfaceStyle: .liquidGlass,
          backgroundColor: .transparent,
        ),
        title: Text('Title'),
        trailing: [
          ToolbarGroup(
            ariaLabel: 'Actions',
            popupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
            children: [Text('Action')],
          ),
        ],
      ),
    );
    expect(find.byType(SurfaceBlur), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ToolbarGroup),
        matching: find.byType(SurfaceBlur),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final local in [
    CoreSurfaceStyleId.liquidGlass,
    CoreSurfaceStyleId.defaultStyle,
  ]) {
    testWidgets('popover morph follows local material $local', (tester) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);
      await pumpTestApp(
        tester,
        Popover(
          controller: controller,
          trigger: const SizedBox(width: 100, height: 40),
          content: const SizedBox(width: 220, height: 140),
          popoverStyle: CorePopoverStyle(
            panelStyle: CorePopupStyle(
              surfaceStyle: local,
              borderRadius: const CoreBorderRadius.all(CoreRadius.radius24),
            ),
          ),
        ),
        surfaceStyle: local == .liquidGlass ? .defaultStyle : .liquidGlass,
      );
      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      if (local == .liquidGlass) {
        final clip = tester.widget<LiquidMorphClip>(
          find.byType(LiquidMorphClip),
        );
        expect(clip.panel.radius, 24);
      } else {
        expect(find.byType(LiquidMorphClip), findsNothing);
      }
      controller.close();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('popover uses its independently authored close duration', (
    tester,
  ) async {
    final controller = PopoverController();
    addTearDown(controller.dispose);
    await pumpTestApp(
      tester,
      Popover(
        controller: controller,
        trigger: const SizedBox(width: 100, height: 40),
        content: const Text('Floating content'),
        popoverStyle: const CorePopoverStyle(
          openAnimationDuration: Duration(milliseconds: 300),
          closeAnimationDuration: Duration(milliseconds: 80),
          panelStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
        ),
      ),
    );
    controller.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    controller.close();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Floating content'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modal chrome honors reduced motion for custom durations', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const ModalContainer(
        filled: true,
        duration: Duration(milliseconds: 400),
        child: Text('Modal content'),
      ),
      surfaceStyle: .liquidGlass,
      disableAnimations: true,
    );
    final chrome = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ModalContainer),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(chrome.duration, Duration.zero);
    expect(find.byType(SurfaceBlur), findsOneWidget);
  });
}
