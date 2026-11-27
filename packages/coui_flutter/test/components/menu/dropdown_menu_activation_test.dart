import 'dart:async' show Completer;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/semantics.dart'
    show SemanticsAction, SemanticsNode, SemanticsRole;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _kTriggerLabel = ValueKey('dropdown-trigger-label');

class _Fixture {
  _Fixture({
    this.dropdown = true,
    this.interactive = true,
    this.showFromTrigger = false,
  });

  final bool dropdown;
  final bool interactive;
  final bool showFromTrigger;
  final before = FocusNode();
  final triggerFocus = FocusNode();
  final controller = PopoverController();
  int triggerActivations = 0;
  int itemSelections = 0;

  void _activated() {
    triggerActivations++;
    if (showFromTrigger) controller.show();
  }

  Future<void> mount(WidgetTester tester) async {
    final trigger = interactive
        ? Button(
            focusNode: triggerFocus,
            onPressed: _activated,
            child: const Text('Open menu', key: _kTriggerLabel),
          )
        : const Text('Open menu', key: _kTriggerLabel);
    final target = dropdown
        ? DropdownMenu(
            controller: controller,
            trigger: trigger,
            items: [
              CoreMenuItem.action(
                'Profile',
                onPressed: () => itemSelections++,
              ),
            ],
          )
        : trigger;
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: Focus(
                    focusNode: before,
                    child: const Text('Before menu'),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: target,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsNothing);
    expect(controller.isOpen, isFalse);
  }

  Future<void> tabToTrigger(WidgetTester tester) async {
    before.requestFocus();
    await tester.pumpAndSettle();
    expect(before.hasPrimaryFocus, isTrue);
    expect(triggerFocus.hasFocus, isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
    await tester.pumpAndSettle();
    expect(before.hasFocus, isFalse);
    expect(triggerFocus.hasPrimaryFocus, isTrue);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
    before.dispose();
    triggerFocus.dispose();
  }
}

Future<void> _withFixture(
  WidgetTester tester,
  Future<void> Function(_Fixture fixture) run, {
  bool dropdown = true,
  bool interactive = true,
  bool showFromTrigger = false,
  bool semantics = false,
}) async {
  final handle = semantics ? tester.ensureSemantics() : null;
  final fixture = _Fixture(
    dropdown: dropdown,
    interactive: interactive,
    showFromTrigger: showFromTrigger,
  );
  try {
    await fixture.mount(tester);
    await run(fixture);
  } finally {
    try {
      await fixture.dispose(tester);
    } finally {
      handle?.dispose();
    }
  }
}

SemanticsNode _triggerNode(WidgetTester tester) {
  final node = tester.getSemantics(find.byKey(_kTriggerLabel));
  for (
    SemanticsNode? current = node;
    current != null;
    current = current.parent
  ) {
    final data = current.getSemanticsData();
    if (data.flagsCollection.isButton && data.label.contains('Open menu')) {
      return current;
    }
  }
  throw TestFailure('No rendered Button semantics identifies the trigger.');
}

Future<void> _activateSemantics(WidgetTester tester) async {
  final node = _triggerNode(tester);
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  expect(node.owner, isNotNull);
  node.owner!.performAction(node.id, SemanticsAction.tap);
  await tester.pumpAndSettle();
}

void _expectOpen(_Fixture fixture) {
  expect(fixture.controller.isOpen, isTrue);
  expect(find.text('Profile'), findsOneWidget);
}

void main() {
  _scopeTimingRegressions();
  _portableSemanticsRegressions();
  _compositionRegressions();
  group('DropdownMenu public activation', () {
    testWidgets('host Tab and Enter reach the actual Button callback', (
      tester,
    ) async {
      await _withFixture(tester, (fixture) async {
        await fixture.tabToTrigger(tester);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
        await tester.pumpAndSettle();
        expect(fixture.triggerActivations, 1);
        expect(find.text('Profile'), findsNothing);
      }, dropdown: false);
    });

    testWidgets('host semantics dispatch reaches the actual Button callback', (
      tester,
    ) async {
      await _withFixture(
        tester,
        (fixture) async {
          await _activateSemantics(tester);
          expect(fixture.triggerActivations, 1);
        },
        dropdown: false,
        semantics: true,
      );
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      testWidgets('${key.keyLabel} opens from the Tab-focused Button trigger', (
        tester,
      ) async {
        await _withFixture(tester, (fixture) async {
          await fixture.tabToTrigger(tester);
          expect(await tester.sendKeyEvent(key), isTrue);
          await tester.pumpAndSettle();
          expect(fixture.triggerActivations, 1);
          _expectOpen(fixture);
        });
      });
    }

    testWidgets('semantics activation opens the Button trigger once', (
      tester,
    ) async {
      await _withFixture(tester, (fixture) async {
        await _activateSemantics(tester);
        expect(fixture.triggerActivations, 1);
        _expectOpen(fixture);
      }, semantics: true);
    });

    testWidgets('the declared plain trigger button has an opening action', (
      tester,
    ) async {
      await _withFixture(
        tester,
        (fixture) async {
          await _activateSemantics(tester);
          _expectOpen(fixture);
          expect(fixture.triggerActivations, 0);
        },
        interactive: false,
        semantics: true,
      );
    });

    testWidgets('pointer tap opens once and selection closes normally', (
      tester,
    ) async {
      await _withFixture(tester, (fixture) async {
        await tester.tap(find.byKey(_kTriggerLabel));
        await tester.pumpAndSettle();
        expect(fixture.triggerActivations, 1);
        _expectOpen(fixture);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(fixture.itemSelections, 1);
        expect(fixture.triggerActivations, 1);
        expect(fixture.controller.isOpen, isFalse);
        expect(find.text('Profile'), findsNothing);
      });
    });

    testWidgets('secondary pointer keeps the menu closed', (tester) async {
      await _withFixture(tester, (fixture) async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_kTriggerLabel)),
          kind: .mouse,
          buttons: kSecondaryButton,
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(fixture.triggerActivations, 0);
        expect(fixture.controller.isOpen, isFalse);
        expect(find.text('Profile'), findsNothing);
      });
    });

    testWidgets('documented controller.show trigger does not double toggle', (
      tester,
    ) async {
      await _withFixture(tester, (fixture) async {
        await fixture.tabToTrigger(tester);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
        await tester.pumpAndSettle();
        expect(fixture.triggerActivations, 1);
        _expectOpen(fixture);
        fixture.controller.close();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(_kTriggerLabel));
        await tester.pumpAndSettle();
        expect(fixture.triggerActivations, 2);
        _expectOpen(fixture);
      }, showFromTrigger: true);
    });
  });
}

class _ProbeIntent extends Intent {
  const _ProbeIntent();
}

class _ResultAction extends Action<_ProbeIntent> {
  _ResultAction(this.result);

  final Object result;
  bool enabled = true;
  int invocations = 0;

  @override
  bool isEnabled(_ProbeIntent intent) => enabled;

  @override
  Object? invoke(_ProbeIntent intent) {
    invocations++;
    return result;
  }
}

class _RecordingDispatcher extends ActionDispatcher {
  final routes = <String>[];

  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    routes.add('direct');
    return super.invokeAction(action, intent, context);
  }

  @override
  (bool, Object?) invokeActionIfEnabled(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    routes.add('enabled');
    return super.invokeActionIfEnabled(action, intent, context);
  }
}

Future<void> _withCustomMenu(
  WidgetTester tester, {
  required Widget trigger,
  required Future<void> Function(PopoverController controller) run,
  ActionDispatcher? dispatcher,
  List<CoreMenuItem<Widget>>? items,
  bool semantics = false,
  bool blockUserActions = false,
}) async {
  final handle = semantics ? tester.ensureSemantics() : null;
  final controller = PopoverController();
  try {
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: Actions(
            dispatcher: dispatcher,
            actions: const {},
            child: Semantics(
              blockUserActions: blockUserActions,
              child: DropdownMenu(
                controller: controller,
                trigger: trigger,
                items: items ?? const [CoreMenuItem.action('Profile')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(controller.isOpen, isFalse);
    await run(controller);
  } finally {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
    } finally {
      handle?.dispose();
    }
  }
}

void _compositionRegressions() {
  group('DropdownMenu scoped activation composition', () {
    testWidgets('keyboard delegates once to the caller dispatcher', (
      tester,
    ) async {
      final focus = FocusNode();
      final dispatcher = _RecordingDispatcher();
      var calls = 0;
      try {
        await _withCustomMenu(
          tester,
          dispatcher: dispatcher,
          trigger: Button(
            focusNode: focus,
            onPressed: () => calls++,
            child: const Text('Open menu', key: _kTriggerLabel),
          ),
          run: (controller) async {
            focus.requestFocus();
            await tester.pumpAndSettle();
            expect(focus.hasPrimaryFocus, isTrue);
            expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
            await tester.pumpAndSettle();
            expect(calls, 1);
            expect(dispatcher.routes, ['enabled']);
            expect(controller.isOpen, isTrue);
          },
        );
      } finally {
        focus.dispose();
      }
    });

    testWidgets('other intents keep delegate results and enabled decisions', (
      tester,
    ) async {
      final focus = FocusNode();
      final dispatcher = _RecordingDispatcher();
      final result = Object();
      final action = _ResultAction(result);
      late BuildContext actionContext;
      try {
        await _withCustomMenu(
          tester,
          dispatcher: dispatcher,
          trigger: Shortcuts(
            shortcuts: const {SingleActivator(.f2): _ProbeIntent()},
            child: Actions(
              actions: {_ProbeIntent: action},
              child: Builder(
                builder: (context) {
                  actionContext = context;
                  return Button(
                    focusNode: focus,
                    onPressed: () {},
                    child: const Text('Open menu', key: _kTriggerLabel),
                  );
                },
              ),
            ),
          ),
          run: (controller) async {
            expect(
              Actions.invoke(actionContext, const _ProbeIntent()),
              same(result),
            );
            expect(action.invocations, 1);
            expect(dispatcher.routes, ['direct']);
            expect(controller.isOpen, isFalse);
            action.enabled = false;
            final declined = Actions.of(actionContext).invokeActionIfEnabled(
              action,
              const _ProbeIntent(),
              actionContext,
            );
            expect(declined.$1, isFalse);
            expect(declined.$2, isNull);
            expect(action.invocations, 1);
            expect(controller.isOpen, isFalse);
            action.enabled = true;
            focus.requestFocus();
            await tester.pumpAndSettle();
            expect(await tester.sendKeyEvent(LogicalKeyboardKey.f2), isTrue);
            await tester.pumpAndSettle();
            expect(action.invocations, 2);
            expect(dispatcher.routes, ['direct', 'enabled', 'enabled']);
            expect(controller.isOpen, isFalse);
          },
        );
      } finally {
        focus.dispose();
      }
    });

    testWidgets('merged public semantics keeps callback labels and actions', (
      tester,
    ) async {
      var taps = 0;
      var longPresses = 0;
      await _withCustomMenu(
        tester,
        semantics: true,
        trigger: Semantics(
          label: 'Caller label',
          value: 'Caller value',
          hint: 'Caller hint',
          child: GestureDetector(
            onTap: () => taps++,
            onLongPress: () => longPresses++,
            child: const Text('Open menu', key: _kTriggerLabel),
          ),
        ),
        run: (controller) async {
          final before = _triggerNode(tester).getSemanticsData();
          expect(before.label, contains('Caller label'));
          expect(before.label, contains('Open menu'));
          expect(before.value, 'Caller value');
          expect(before.hint, 'Caller hint');
          expect(before.hasAction(SemanticsAction.tap), isTrue);
          expect(before.hasAction(SemanticsAction.longPress), isTrue);
          await _activateSemantics(tester);
          expect(taps, 1);
          expect(longPresses, 0);
          expect(controller.isOpen, isTrue);
          controller.close();
          await tester.pumpAndSettle();
          final node = _triggerNode(tester);
          final after = node.getSemanticsData();
          expect(after.label, before.label);
          expect(after.value, before.value);
          expect(after.hint, before.hint);
          expect(after.flagsCollection, before.flagsCollection);
          expect(after.hasAction(SemanticsAction.longPress), isTrue);
          node.owner!.performAction(node.id, SemanticsAction.longPress);
          await tester.pumpAndSettle();
          expect(longPresses, 1);
          expect(taps, 1);
          expect(controller.isOpen, isFalse);
          await _activateSemantics(tester);
          expect(taps, 2);
          expect(controller.isOpen, isTrue);
        },
      );
    });

    testWidgets('a disabled trigger gains no semantic opening action', (
      tester,
    ) async {
      var calls = 0;
      await _withCustomMenu(
        tester,
        semantics: true,
        trigger: Button(
          enabled: false,
          onPressed: () => calls++,
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        run: (controller) async {
          final node = _triggerNode(tester);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
          node.owner!.performAction(node.id, SemanticsAction.tap);
          await tester.pumpAndSettle();
          expect(calls, 0);
          expect(controller.isOpen, isFalse);
        },
      );
    });

    testWidgets('ancestor blocking keeps all trigger user actions blocked', (
      tester,
    ) async {
      var calls = 0;
      await _withCustomMenu(
        tester,
        semantics: true,
        blockUserActions: true,
        trigger: Button(
          onPressed: () => calls++,
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        run: (controller) async {
          final node = _triggerNode(tester);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
          node.owner!.performAction(node.id, SemanticsAction.tap);
          await tester.pumpAndSettle();
          expect(calls, 0);
          expect(controller.isOpen, isFalse);
        },
      );
    });

    testWidgets('Escape restores trigger focus and keyboard selection closes', (
      tester,
    ) async {
      await _withFixture(tester, (fixture) async {
        await fixture.tabToTrigger(tester);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
        await tester.pumpAndSettle();
        _expectOpen(fixture);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
        await tester.pumpAndSettle();
        expect(fixture.controller.isOpen, isFalse);
        expect(fixture.triggerFocus.hasPrimaryFocus, isTrue);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
        await tester.pumpAndSettle();
        _expectOpen(fixture);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
        await tester.pumpAndSettle();
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
        await tester.pumpAndSettle();
        expect(fixture.itemSelections, 1);
        expect(fixture.triggerActivations, 2);
        expect(fixture.controller.isOpen, isFalse);
        expect(find.text('Profile'), findsNothing);
      });
    });

    testWidgets('portaled nested rows preserve their callbacks and Escape', (
      tester,
    ) async {
      var triggerCalls = 0;
      var nestedCalls = 0;
      await _withCustomMenu(
        tester,
        semantics: true,
        trigger: Button(
          onPressed: () => triggerCalls++,
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        items: [
          CoreMenuItem.action(
            'More',
            submenu: [
              CoreMenuItem.action(
                'Nested item',
                onPressed: () => nestedCalls++,
              ),
            ],
          ),
        ],
        run: (controller) async {
          await _activateSemantics(tester);
          expect(triggerCalls, 1);
          expect(controller.isOpen, isTrue);
          final nested = _menuItemActionNode(tester, 'Nested item');
          expect(
            nested.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          nested.owner!.performAction(nested.id, SemanticsAction.tap);
          await tester.pumpAndSettle();
          expect(nestedCalls, 1);
          expect(triggerCalls, 1);
          // Inline nested Menu currently has no host onActivate callback.
          expect(controller.isOpen, isTrue);
          expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
          await tester.pumpAndSettle();
          expect(controller.isOpen, isFalse);
        },
      );
    });

    testWidgets('controller.show also stays idempotent for semantics', (
      tester,
    ) async {
      await _withFixture(
        tester,
        (fixture) async {
          await _activateSemantics(tester);
          expect(fixture.triggerActivations, 1);
          _expectOpen(fixture);
          fixture.controller.close();
          await tester.pumpAndSettle();
          await _activateSemantics(tester);
          expect(fixture.triggerActivations, 2);
          _expectOpen(fixture);
        },
        showFromTrigger: true,
        semantics: true,
      );
    });

    testWidgets('separate child semantic boundaries keep their own action', (
      tester,
    ) async {
      var calls = 0;
      await _withCustomMenu(
        tester,
        semantics: true,
        trigger: Semantics(
          container: true,
          button: true,
          onTap: () => calls++,
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        run: (controller) async {
          await _activateSemantics(tester);
          expect(calls, 1);
          expect(controller.isOpen, isFalse);
        },
      );
    });
  });
}

SemanticsNode _menuItemActionNode(WidgetTester tester, String label) {
  SemanticsNode? row = tester.getSemantics(find.text(label));
  while (row != null && row.getSemanticsData().role != SemanticsRole.menuItem) {
    row = row.parent;
  }
  expect(
    row,
    isNotNull,
    reason: 'Find the actual declared menu-item boundary.',
  );
  final matches = <SemanticsNode>[];
  void collect(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
      matches.add(node);
    }
    node.visitChildren((child) {
      collect(child);
      return true;
    });
  }

  collect(row!);
  expect(matches, hasLength(1), reason: 'Exactly one actual row tap action.');
  return matches.single;
}

void _scopeTimingRegressions() {
  group('DropdownMenu scoped callback timing', () {
    testWidgets('pointer caller close after mount is not reopened', (
      tester,
    ) async {
      late PopoverController controller;
      late Completer<void> callerReady;
      late Future<void> closing;
      var calls = 0;
      await _withCustomMenu(
        tester,
        trigger: Button(
          onPressed: () {
            calls++;
            callerReady = Completer<void>();
            closing = callerReady.future.then((_) => controller.close());
          },
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        run: (current) async {
          controller = current;
          for (var count = 1; count <= 2; count++) {
            await tester.tap(find.byKey(_kTriggerLabel));
            expect(calls, count);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 16));
            expect(find.text('Profile'), findsOneWidget);
            expect(controller.isOpen, isTrue);
            callerReady.complete();
            await closing;
            await tester.pumpAndSettle();
            expect(calls, count);
            expect(controller.isOpen, isFalse);
            expect(find.text('Profile'), findsNothing);
          }
        },
      );
    });

    testWidgets('timed double tap keeps deferred close and callback counts', (
      tester,
    ) async {
      late PopoverController controller;
      late Completer<void> callerReady;
      late Future<void> pending;
      var singles = 0;
      var doubles = 0;
      void closeAfterCallerWork() {
        callerReady = Completer<void>();
        pending = callerReady.future.then((_) => controller.close());
      }

      await _withCustomMenu(
        tester,
        trigger: Clickable(
          onPressed: () {
            singles++;
            closeAfterCallerWork();
          },
          onDoubleTap: () {
            doubles++;
            closeAfterCallerWork();
          },
          child: const Text('Open menu', key: _kTriggerLabel),
        ),
        run: (current) async {
          controller = current;
          final first = await tester.createGesture();
          await first.down(
            tester.getCenter(find.byKey(_kTriggerLabel)),
            timeStamp: const Duration(seconds: 1),
          );
          await first.up(timeStamp: const Duration(milliseconds: 1020));
          expect(singles, 1);
          expect(doubles, 0);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(find.text('Profile'), findsOneWidget);
          callerReady.complete();
          await pending;
          await tester.pumpAndSettle();
          expect(controller.isOpen, isFalse);
          expect(find.text('Profile'), findsNothing);
          final second = await tester.createGesture();
          await second.down(
            tester.getCenter(find.byKey(_kTriggerLabel)),
            timeStamp: const Duration(milliseconds: 1080),
          );
          await second.up(timeStamp: const Duration(milliseconds: 1100));
          expect(singles, 1);
          expect(doubles, 1);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(find.text('Profile'), findsOneWidget);
          callerReady.complete();
          await pending;
          await tester.pumpAndSettle();
          expect(singles, 1);
          expect(doubles, 1);
          expect(controller.isOpen, isFalse);
          expect(find.text('Profile'), findsNothing);
        },
      );
    });
  });
}

void _portableSemanticsRegressions() {
  testWidgets('normal trigger preserves parent and child semantic actions', (
    tester,
  ) async {
    await _withFixture(tester, (fixture) async {
      final child = _triggerNode(tester);
      final childData = child.getSemanticsData();
      final parent = child.parent;
      expect(parent, isNotNull);
      final parentData = parent!.getSemanticsData();
      expect(childData.label, 'Open menu');
      expect(childData.flagsCollection.isButton, isTrue);
      expect(childData.hasAction(SemanticsAction.tap), isTrue);
      expect(parentData.label, isEmpty);
      expect(parentData.flagsCollection.isButton, isTrue);
      expect(parentData.hasAction(SemanticsAction.tap), isFalse);
      await _activateSemantics(tester);
      expect(fixture.triggerActivations, 1);
      _expectOpen(fixture);
      fixture.controller.close();
      await tester.pumpAndSettle();
      final restored = _triggerNode(tester);
      final restoredData = restored.getSemanticsData();
      expect(restoredData.label, childData.label);
      expect(restoredData.flagsCollection, childData.flagsCollection);
      expect(restoredData.actions, childData.actions);
      expect(restored.parent, isNotNull);
      final restoredParent = restored.parent!.getSemanticsData();
      expect(restoredParent.label, parentData.label);
      expect(restoredParent.flagsCollection, parentData.flagsCollection);
      expect(restoredParent.actions, parentData.actions);
      expect(fixture.controller.isOpen, isFalse);
    }, semantics: true);
  });
}
