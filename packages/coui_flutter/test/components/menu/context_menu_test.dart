import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart'
    show DeviceGestureSettings, kLongPressTimeout, kSecondaryButton, kTouchSlop;
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

/// The vector table shared with the Core test and the Web press-tracker test:
/// what a touch has to do to open the menu, replayed here as real pointer
/// events so the framework's long-press recognizer has to answer it.
const String _kLongPressVectorsPath =
    '../coui_core/test/fixtures/context_menu_long_press_vectors.json';

void main() {
  group('ContextMenu widget', () {
    material.Widget buildApp(
      material.Widget child, {
      ThemeData theme = const ThemeData(),
    }) => material.MaterialApp(
      home: Theme(
        data: theme,
        child: material.Scaffold(body: material.Center(child: child)),
      ),
    );

    // The open panel follows the trigger via a perpetual ticker
    // (`follow: true`, like every other menu), so `pumpAndSettle` would
    // never settle. Pump a couple of fixed frames covering the open/close
    // transition instead.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Regression: the panel was positioned via `Position(top:, left:)`,
    // which lays the child out under UNBOUNDED width, so the `expanded` menu
    // rows threw a BoxConstraints "infinite width" assertion on open. It is
    // now wrapped in `IntrinsicWidth`.
    testWidgets('opens on right-click without a layout exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            items: [
              CoreMenuItem.action('Copy', onPressed: () {}),
              CoreMenuItem.action('Paste', onPressed: () {}),
            ],
            child: const material.Text('Right-click me'),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Copy'), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Right-click me')),
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('re-right-clicking an open menu toggles it closed', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            items: [
              CoreMenuItem.action('Copy', onPressed: () {}),
              CoreMenuItem.action('Paste', onPressed: () {}),
            ],
            child: const material.Text('Right-click me'),
          ),
        ),
      );
      await settle(tester);

      final target = tester.getCenter(find.text('Right-click me'));

      // Right-click to open.
      final open = await tester.startGesture(target, buttons: kSecondaryButton);
      await open.up();
      await settle(tester);
      expect(
        find.text('Copy'),
        findsOneWidget,
        reason: 'opened on right-click',
      );

      // Right-click again — must toggle closed instead of being ignored.
      final close = await tester.startGesture(
        target,
        buttons: kSecondaryButton,
      );
      await close.up();
      await settle(tester);
      expect(
        find.text('Copy'),
        findsNothing,
        reason: 're-right-clicking must close the open menu',
      );
    });

    // The panel is mounted in the app's overlay, outside the host's own
    // subtree, so a host that rebuilds with new items has to reach it
    // explicitly. Web hosts re-sync the portalled panel on every build; this
    // is the Flutter half of that statement.
    testWidgets('swapping the items re-renders the open panel', (tester) async {
      final items = ValueNotifier<List<CoreMenuItem<Widget>>>([
        CoreMenuItem.action('Copy', onPressed: () {}),
        CoreMenuItem.action('Paste', onPressed: () {}),
      ]);
      addTearDown(items.dispose);

      await tester.pumpWidget(
        buildApp(
          ValueListenableBuilder<List<CoreMenuItem<Widget>>>(
            valueListenable: items,
            builder: (_, value, _) => ContextMenu(
              items: value,
              child: const material.Text('Right-click me'),
            ),
          ),
        ),
      );
      await settle(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Right-click me')),
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await settle(tester);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      items.value = [
        CoreMenuItem.action('Cut', onPressed: () {}),
        CoreMenuItem.action('Paste', onPressed: () {}),
      ];
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
    });

    testWidgets('controller.show opens at the child anchor, close closes', (
      tester,
    ) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            controller: controller,
            items: [
              CoreMenuItem.action('Copy', onPressed: () {}),
            ],
            child: const material.Text('Anchor'),
          ),
        ),
      );
      await settle(tester);

      expect(controller.isOpen, isFalse);
      expect(find.text('Copy'), findsNothing);

      controller.show();
      await settle(tester);

      expect(controller.isOpen, isTrue);
      expect(find.text('Copy'), findsOneWidget);

      controller.close();
      await settle(tester);

      expect(controller.isOpen, isFalse);
      expect(find.text('Copy'), findsNothing);
    });

    // A touch held on the region opens the menu where it went down. Which
    // touches count — how long, how far it may drift, what ends it — is the
    // shared table's: the Core test pins the table to the constants, the Web
    // replays it on its own tracker, and the framework's recognizer has to
    // answer it here.
    group('long press', () {
      final doc =
          jsonDecode(File(_kLongPressVectorsPath).readAsStringSync())
              as Map<String, Object?>;
      final drift = (doc['drift']! as List).cast<Map<String, Object?>>();
      final presses = (doc['presses']! as List).cast<Map<String, Object?>>();

      const regionKey = ValueKey('region');

      // Big enough that every press in the table, drifts included, starts
      // inside it, and nothing in it handles a touch of its own.
      material.Widget region({
        bool enabled = true,
        PopoverController? controller,
      }) => ContextMenu(
        enabled: enabled,
        controller: controller,
        items: [
          CoreMenuItem.action('Copy', onPressed: () {}),
          CoreMenuItem.action('Paste', onPressed: () {}),
        ],
        child: const SizedBox(key: regionKey, width: 320, height: 200),
      );

      ThemeData themeOn(TargetPlatform platform) =>
          ThemeData(platform: platform);

      Offset regionTopLeft(WidgetTester tester) =>
          tester.getTopLeft(find.byKey(regionKey));

      Offset at(WidgetTester tester, num x, num y) =>
          regionTopLeft(tester) + Offset(x.toDouble(), y.toDouble());

      // Replays [events] as pointer events, advancing the clock between
      // them, and then to [until].
      Future<void> replay(
        WidgetTester tester,
        List<Map<String, Object?>> events,
        int until,
      ) async {
        TestGesture? gesture;
        var now = 0;
        for (final event in events) {
          final time = event['at']! as int;
          if (time > now) {
            await tester.pump(Duration(milliseconds: time - now));
            now = time;
          }
          switch (event['kind']) {
            case 'down':
              gesture = await tester.startGesture(
                at(tester, event['x']! as num, event['y']! as num),
              );
            case 'move':
              await gesture!.moveTo(
                at(tester, event['x']! as num, event['y']! as num),
              );
            case 'up':
              await gesture!.up();
            case 'cancel':
              await gesture!.cancel();
            default:
              fail('the table gave Flutter an event it cannot replay: $event');
          }
        }
        if (until > now) await tester.pump(Duration(milliseconds: until - now));
        // Let the panel mount and play its entrance.
        await settle(tester);
      }

      test("the table is the framework's own numbers, stated once", () {
        // Flutter's long press has always been 500 ms and 18 px; the Core
        // constants are those numbers, so the Flutter trigger is unchanged and
        // the Web one is held to the same.
        expect(
          CoreContextMenuContract.defaultLongPressDuration,
          kLongPressTimeout,
        );
        expect(CoreContextMenuContract.defaultLongPressSlop, kTouchSlop);
      });

      for (final press in presses) {
        final platforms = (press['platforms'] as List?)?.cast<String>();
        if (platforms != null && !platforms.contains('flutter')) continue;

        testWidgets(press['name']! as String, (tester) async {
          await tester.pumpWidget(
            buildApp(region(), theme: themeOn(.android)),
          );
          await settle(tester);
          expect(find.text('Copy'), findsNothing);

          await replay(
            tester,
            (press['events']! as List).cast<Map<String, Object?>>(),
            press['until']! as int,
          );

          expect(tester.takeException(), isNull);
          final opens = press['opens'] as Map<String, Object?>?;
          if (opens == null) {
            expect(find.text('Copy'), findsNothing);
          } else {
            expect(find.text('Copy'), findsOneWidget);
            // Where the touch went down — not where it drifted to.
            final panel = tester.getTopLeft(find.byType(Popup).first);
            final expected = at(
              tester,
              opens['x']! as num,
              opens['y']! as num,
            );
            expect(panel.dx, closeTo(expected.dx, 0.5));
            expect(panel.dy, closeTo(expected.dy, 0.5));
          }
        });
      }

      for (final vector in drift) {
        testWidgets('drift: ${vector['name']}', (tester) async {
          await tester.pumpWidget(
            buildApp(region(), theme: themeOn(.android)),
          );
          await settle(tester);
          final origin = (vector['origin']! as List).cast<num>();
          final point = (vector['point']! as List).cast<num>();

          await replay(
            tester,
            [
              {'at': 0, 'kind': 'down', 'x': origin[0], 'y': origin[1]},
              {'at': 100, 'kind': 'move', 'x': point[0], 'y': point[1]},
            ],
            700,
          );

          // The recognizer answers the way the Core predicate does.
          expect(
            find.text('Copy'),
            vector['exceeds']! as bool ? findsNothing : findsOneWidget,
          );
        });
      }

      testWidgets(
        'the slop is the Core number, not what the device reports',
        (tester) async {
          // A device that reports a tighter touch slop than 18 (8 here) must
          // not tighten the press: a 15 px drift is inside the 18 the Web is
          // held to, so it opens here too.
          await tester.pumpWidget(
            material.MediaQuery(
              data: const MediaQueryData(
                gestureSettings: DeviceGestureSettings(touchSlop: 8),
              ),
              child: buildApp(region(), theme: themeOn(.android)),
            ),
          );
          await settle(tester);

          await replay(
            tester,
            [
              {'at': 0, 'kind': 'down', 'x': 60, 'y': 50},
              {'at': 100, 'kind': 'move', 'x': 75, 'y': 50},
            ],
            700,
          );

          expect(find.text('Copy'), findsOneWidget);
        },
      );

      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.android,
        TargetPlatform.fuchsia,
      ]) {
        testWidgets('a held touch opens it on $platform', (tester) async {
          await tester.pumpWidget(buildApp(region(), theme: themeOn(platform)));
          await settle(tester);

          await replay(
            tester,
            [
              {'at': 0, 'kind': 'down', 'x': 60, 'y': 50},
            ],
            600,
          );

          expect(find.text('Copy'), findsOneWidget);
        });
      }

      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        testWidgets('a held touch opens nothing on $platform', (tester) async {
          // The desktop platforms open it from the right button and the
          // keyboard; no long-press recognizer is attached to claim a
          // press-and-hold meant for the content.
          await tester.pumpWidget(buildApp(region(), theme: themeOn(platform)));
          await settle(tester);

          await replay(
            tester,
            [
              {'at': 0, 'kind': 'down', 'x': 60, 'y': 50},
            ],
            1200,
          );

          expect(find.text('Copy'), findsNothing);
        });
      }

      testWidgets('a disabled menu ignores a held touch', (tester) async {
        await tester.pumpWidget(
          buildApp(region(enabled: false), theme: themeOn(.android)),
        );
        await settle(tester);

        await replay(
          tester,
          [
            {'at': 0, 'kind': 'down', 'x': 60, 'y': 50},
          ],
          900,
        );

        expect(find.text('Copy'), findsNothing);
      });

      testWidgets('holding again on the open menu toggles it closed', (
        tester,
      ) async {
        await tester.pumpWidget(buildApp(region(), theme: themeOn(.android)));
        await settle(tester);
        final hold = [
          {'at': 0, 'kind': 'down', 'x': 60, 'y': 50},
          {'at': 700, 'kind': 'up'},
        ];

        await replay(tester, hold, 700);
        expect(find.text('Copy'), findsOneWidget, reason: 'opened');

        await replay(tester, hold, 700);
        expect(
          find.text('Copy'),
          findsNothing,
          reason: 'the re-trigger closes',
        );
      });

      testWidgets(
        "a screen reader's long-press action opens it at the region's middle",
        (tester) async {
          // The detector's semantics read the long-press recognizer, so the
          // action a screen reader offers on the region has to reach this
          // trigger — it carries the region's centre, since there is no touch.
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              buildApp(region(), theme: themeOn(.android)),
            );
            await settle(tester);

            tester.semantics.longPress(
              find.semantics.byAction(SemanticsAction.longPress),
            );
            await settle(tester);

            expect(find.text('Copy'), findsOneWidget);
            final panel = tester.getTopLeft(find.byType(Popup).first);
            final centre = tester.getCenter(find.byKey(regionKey));
            expect(panel.dx, closeTo(centre.dx, 0.5));
            expect(panel.dy, closeTo(centre.dy, 0.5));
          } finally {
            semantics.dispose();
          }
        },
      );
    });

    // The menu key and Shift+F10 reach the menu from whichever widget inside
    // the region has focus — no tab stop of its own — and open it at that
    // widget, since the keyboard has no pointer to anchor to.
    group('keyboard', () {
      const targetKey = ValueKey('focus-target');

      // The focusable widget sits in a corner of the region, so the widget's
      // centre and the region's differ and the test says which one it is.
      material.Widget focusable(
        FocusNode focus, {
        bool enabled = true,
        PopoverController? controller,
      }) => ContextMenu(
        enabled: enabled,
        controller: controller,
        items: [
          CoreMenuItem.action('Copy', onPressed: () {}),
          CoreMenuItem.action('Paste', onPressed: () {}),
        ],
        child: SizedBox(
          width: 320,
          height: 200,
          child: Align(
            alignment: .topLeft,
            child: Focus(
              focusNode: focus,
              child: const SizedBox(key: targetKey, width: 80, height: 40),
            ),
          ),
        ),
      );

      Future<FocusNode> pumpFocused(
        WidgetTester tester, {
        bool enabled = true,
      }) async {
        final focus = FocusNode(debugLabel: 'target');
        addTearDown(focus.dispose);
        await tester.pumpWidget(buildApp(focusable(focus, enabled: enabled)));
        focus.requestFocus();
        await settle(tester);
        expect(focus.hasPrimaryFocus, isTrue, reason: 'the test needs focus');

        return focus;
      }

      void expectAnchoredAtTarget(WidgetTester tester) {
        final panel = tester.getTopLeft(find.byType(Popup).first);
        final centre = tester.getCenter(find.byKey(targetKey));
        expect(panel.dx, closeTo(centre.dx, 0.5));
        expect(panel.dy, closeTo(centre.dy, 0.5));
      }

      testWidgets(
        'the context-menu key opens it at the centre of the focused widget',
        (tester) async {
          await pumpFocused(tester);
          expect(find.text('Copy'), findsNothing);

          await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
          await settle(tester);

          expect(tester.takeException(), isNull);
          expect(find.text('Copy'), findsOneWidget);
          expectAnchoredAtTarget(tester);
          // The widget's centre, not the region's.
          expect(
            tester.getTopLeft(find.byType(Popup).first).dx,
            lessThan(tester.getCenter(find.byType(ContextMenu)).dx),
          );
        },
      );

      testWidgets('Shift+F10 opens it the same way', (tester) async {
        await pumpFocused(tester);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await settle(tester);

        expect(find.text('Copy'), findsOneWidget);
        expectAnchoredAtTarget(tester);
      });

      testWidgets('F10 alone and Shift+Enter open nothing', (tester) async {
        await pumpFocused(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await settle(tester);
        expect(find.text('Copy'), findsNothing, reason: 'F10 alone');

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await settle(tester);
        expect(find.text('Copy'), findsNothing, reason: 'Shift+Enter');
      });

      testWidgets('a disabled menu ignores both keys', (tester) async {
        await pumpFocused(tester, enabled: false);

        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await settle(tester);

        expect(find.text('Copy'), findsNothing);
      });

      testWidgets('a disabled menu leaves the keys to whatever is above it', (
        tester,
      ) async {
        // A menu that is switched off must not eat the key: an app may bind
        // it, and a disabled control that swallowed it would take that away.
        final seen = <LogicalKeyboardKey>[];
        final focus = FocusNode(debugLabel: 'target');
        addTearDown(focus.dispose);
        material.Widget app({required bool enabled}) => buildApp(
          Focus(
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent) seen.add(event.logicalKey);

              return KeyEventResult.ignored;
            },
            child: focusable(focus, enabled: enabled),
          ),
        );

        await tester.pumpWidget(app(enabled: true));
        focus.requestFocus();
        await settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);
        expect(seen, isEmpty, reason: 'an enabled menu takes the key');

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        seen.clear();

        await tester.pumpWidget(app(enabled: false));
        focus.requestFocus();
        await settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);
        expect(seen, [LogicalKeyboardKey.contextMenu]);
        expect(find.text('Copy'), findsNothing);
      });

      testWidgets('the keys do nothing while focus is outside the region', (
        tester,
      ) async {
        final inside = FocusNode(debugLabel: 'inside');
        final outside = FocusNode(debugLabel: 'outside');
        addTearDown(inside.dispose);
        addTearDown(outside.dispose);
        await tester.pumpWidget(
          buildApp(
            Column(
              mainAxisSize: .min,
              children: [
                focusable(inside),
                Focus(
                  focusNode: outside,
                  child: const SizedBox(width: 80, height: 40),
                ),
              ],
            ),
          ),
        );
        outside.requestFocus();
        await settle(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);

        expect(find.text('Copy'), findsNothing);
      });

      testWidgets('the key closes an open menu again (re-trigger toggles)', (
        tester,
      ) async {
        final focus = await pumpFocused(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);
        expect(find.text('Copy'), findsOneWidget);
        // Opening hands focus to the panel, so the key does not reach the
        // region again by itself. With focus back on the widget (an app that
        // keeps it there), the same key is a second trigger and closes the
        // menu, as a second right-click does.
        expect(focus.hasPrimaryFocus, isFalse);
        focus.requestFocus();
        await settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);

        expect(find.text('Copy'), findsNothing);
      });

      testWidgets('Escape closes it and focus goes back to the widget', (
        tester,
      ) async {
        final focus = await pumpFocused(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);
        expect(find.text('Copy'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);

        expect(find.text('Copy'), findsNothing);
        // The keyboard user is where they were, not at the top of the page.
        expect(focus.hasPrimaryFocus, isTrue);
      });

      testWidgets('a held key opens it once and does not flicker it shut', (
        tester,
      ) async {
        final focus = await pumpFocused(tester);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);
        expect(find.text('Copy'), findsOneWidget);
        focus.requestFocus();
        await settle(tester);
        // The OS repeats a held key; a repeat is not another press. Each one
        // is looked at on its own — two repeats that toggled would end where
        // they began, and a test that only looked at the end would not see it.
        for (var repeat = 1; repeat <= 3; repeat++) {
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.contextMenu);
          await settle(tester);
          expect(
            find.text('Copy'),
            findsOneWidget,
            reason: 'repeat $repeat must not close it',
          );
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
        await settle(tester);

        expect(find.text('Copy'), findsOneWidget);
      });

      testWidgets('it adds no tab stop of its own', (tester) async {
        final focus = FocusNode(debugLabel: 'only stop');
        addTearDown(focus.dispose);
        await tester.pumpWidget(buildApp(focusable(focus)));
        await settle(tester);

        // One focusable in the tree: Tab goes to it and then wraps back to it
        // — a second stop belonging to the menu would take a turn in between.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focus.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focus.hasPrimaryFocus, isTrue);
      });
    });
  });
}
