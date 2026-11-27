import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _kBackground = ValueKey('background-control');
const ValueKey<String> _kTrigger = ValueKey('dropdown-trigger');

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  for (final closeBeforeFirstOverlayBuild in [false, true]) {
    testWidgets(
      closeBeforeFirstOverlayBuild
          ? 'show then close before first overlay frame removes the panel'
          : 'mounted panel close removes the panel and permits reopening',
      (tester) async {
        final controller = PopoverController();
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        });
        var backgroundActivations = 0;
        var triggerActivations = 0;
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData.fromCore(CoreThemePresets.light),
            home: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button(
                    key: _kBackground,
                    onPressed: () => backgroundActivations++,
                    child: const Text('Background control'),
                  ),
                  const SizedBox(height: 24),
                  DropdownMenu(
                    controller: controller,
                    trigger: Button(
                      key: _kTrigger,
                      onPressed: () => triggerActivations++,
                      child: const Text('Open menu'),
                    ),
                    items: const [CoreMenuItem.action('Profile')],
                  ),
                ],
              ),
            ),
          ),
        );
        await _settle(tester);
        expect(controller.isOpen, isFalse);
        expect(find.text('Profile'), findsNothing);

        // Both calls below are public controller operations. In the early
        // close case no pump, await, trigger callback, or input occurs
        // between show and close.
        controller.show();
        expect(controller.isOpen, isTrue);
        if (!closeBeforeFirstOverlayBuild) {
          await _settle(tester);
          expect(find.text('Profile'), findsOneWidget);
        }
        controller.close();
        await _settle(tester);
        final closedControllerIsOpen = controller.isOpen;
        final mountedProfileCount = find.text('Profile').evaluate().length;
        // A real pointer must reach an ordinary background control after
        // dismissal; checking only the controller would miss a stale barrier.
        await tester.tap(find.byKey(_kBackground));
        await _settle(tester);
        final backgroundCallbacksAfterClose = backgroundActivations;
        expect(
          {
            'controllerIsOpenAfterClose': closedControllerIsOpen,
            'mountedProfileCountAfterClose': mountedProfileCount,
            'backgroundPointerCallbacksAfterClose':
                backgroundCallbacksAfterClose,
            'triggerCallbacksBeforeNextOpen': triggerActivations,
            'frameworkException': tester.takeException(),
          },
          {
            'controllerIsOpenAfterClose': false,
            'mountedProfileCountAfterClose': 0,
            'backgroundPointerCallbacksAfterClose': 1,
            'triggerCallbacksBeforeNextOpen': 0,
            'frameworkException': null,
          },
        );

        // The same mounted trigger remains usable after the early close.
        await tester.tap(find.byKey(_kTrigger));
        await _settle(tester);
        expect(triggerActivations, 1);
        expect(controller.isOpen, isTrue);
        expect(find.text('Profile'), findsOneWidget);
        controller.close();
        await _settle(tester);
        expect(controller.isOpen, isFalse);
        expect(find.text('Profile'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('repeated early closes release the modal barrier', (
    tester,
  ) async {
    final controller = PopoverController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
    var backgroundActivations = 0;
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                key: _kBackground,
                onPressed: () => backgroundActivations++,
                child: const Text('Background control'),
              ),
              DropdownMenu(
                controller: controller,
                trigger: Button(
                  key: _kTrigger,
                  onPressed: () {},
                  child: const Text('Open menu'),
                ),
                items: const [CoreMenuItem.action('Profile')],
              ),
            ],
          ),
        ),
      ),
    );
    await _settle(tester);
    for (var cycle = 1; cycle <= 3; cycle++) {
      controller
        ..show()
        ..close();
      await _settle(tester);
      expect(controller.isOpen, isFalse);
      expect(find.text('Profile'), findsNothing);
      await tester.tap(find.byKey(_kBackground));
      await _settle(tester);
      expect(backgroundActivations, cycle);
    }
    await tester.tap(find.byKey(_kTrigger));
    await _settle(tester);
    expect(controller.isOpen, isTrue);
    expect(find.text('Profile'), findsOneWidget);
    controller.close();
    await _settle(tester);
    expect(find.text('Profile'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early close followed by host unmount releases the overlay', (
    tester,
  ) async {
    final controller = PopoverController();
    final hostVisible = ValueNotifier(true);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      hostVisible.dispose();
    });
    var backgroundActivations = 0;
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                key: _kBackground,
                onPressed: () => backgroundActivations++,
                child: const Text('Background control'),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: hostVisible,
                builder: (_, visible, _) => visible
                    ? DropdownMenu(
                        controller: controller,
                        trigger: Button(
                          onPressed: () {},
                          child: const Text('Open menu'),
                        ),
                        items: const [CoreMenuItem.action('Profile')],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
    await _settle(tester);
    controller
      ..show()
      ..close();
    hostVisible.value = false;
    await _settle(tester);
    expect(find.text('Open menu'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    await tester.tap(find.byKey(_kBackground));
    await _settle(tester);
    expect(backgroundActivations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public Popover early close permits the next open', (
    tester,
  ) async {
    final controller = PopoverController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: Popover(
            controller: controller,
            trigger: Button(onPressed: () {}, child: const Text('Trigger')),
            content: const Text('Public popover content'),
          ),
        ),
      ),
    );
    await _settle(tester);
    controller
      ..show()
      ..close();
    await _settle(tester);
    expect(controller.isOpen, isFalse);
    expect(find.text('Public popover content'), findsNothing);
    controller.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.isOpen, isTrue);
    expect(find.text('Public popover content'), findsOneWidget);
    controller.close();
    await _settle(tester);
    expect(controller.isOpen, isFalse);
    expect(find.text('Public popover content'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
