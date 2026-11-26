// A finger that opened a ContextMenu with a long press may keep moving and
// choose a row by lifting over it - opt-in, `glideToSelect`. What the two seats
// must agree on is not the gesture recogniser's output but a handful of
// judgements (when a movement is a glide, which row is under the finger, what
// a release does), and they live in one Core state machine that the shared
// table (`context_menu_glide_vectors.json`) pins. This file replays every
// trace of that table on a real ContextMenu as pointer events - the framework's
// long-press recogniser opens the menu, and the glide follows the same pointer
// on the pointer router - in left-to-right and right-to-left text, and reads
// what a person would see: which row is lit, whether the menu is open, which
// row's handler ran and which haptic the platform was asked for.
//
// The preview (`preview`) is placed around the menu by one Core rule, pinned by
// `context_menu_preview_vectors.json`; the scenarios of that table are replayed
// here on real menus.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/menu/menu_item/menu_glide.dart';
import 'package:coui_flutter/src/util/haptics.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey, SystemChannels;
import 'package:flutter_test/flutter_test.dart';

const String _kGlideVectorsPath =
    '../coui_core/test/fixtures/context_menu_glide_vectors.json';
const String _kPreviewVectorsPath =
    '../coui_core/test/fixtures/context_menu_preview_vectors.json';

const String _kSelectionClick = 'HapticFeedbackType.selectionClick';

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

/// Records the haptics the platform was asked for while a test runs.
class _Haptics {
  _Haptics(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          requests.add(call.arguments! as String);
        }

        return null;
      },
    );
  }

  final WidgetTester tester;
  final List<String> requests = [];

  int get ticks => requests.where((r) => r == _kSelectionClick).length;

  void dispose() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

void main() {
  final glideDoc =
      jsonDecode(File(_kGlideVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final previewDoc =
      jsonDecode(File(_kPreviewVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final traces = _list(glideDoc['traces']);
  final menus = glideDoc['menus']! as Map<String, Object?>;

  const regionKey = ValueKey('region');

  material.Widget buildApp(material.Widget child, {bool rtl = false}) =>
      material.MaterialApp(
        builder: rtl
            ? (context, app) =>
                  Directionality(textDirection: TextDirection.rtl, child: app!)
            : null,
        home: Theme(
          data: const ThemeData(),
          child: material.Scaffold(body: material.Center(child: child)),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// A ContextMenu over a region that every trace's pointer can start in,
  /// whose rows and recorders come from the table's [menu].
  ({
    material.Widget app,
    List<String> labels,
    List<int> activated,
  })
  contextMenuOf(
    Map<String, Object?> menu, {
    required bool glide,
    required bool haptics,
    required bool rtl,
    material.Widget? preview,
    PopoverController? controller,
  }) {
    final activated = <int>[];
    final labels = <String>[];
    final items = <CoreMenuItem<Widget>>[];
    for (final item in _list(menu['items'])) {
      final kind = item['kind']! as String;
      if (kind == 'divider') {
        items.add(const CoreMenuItem.divider());
        continue;
      }
      final index = labels.length;
      final label = item['label']! as String;
      labels.add(label);
      final disabled = item['disabled'] == true;
      items.add(
        kind == 'checkbox'
            ? CoreMenuItem.checkbox(
                label,
                disabled: disabled,
                onChanged: (_) => activated.add(index),
              )
            : CoreMenuItem.action(
                label,
                disabled: disabled,
                onPressed: () => activated.add(index),
              ),
      );
    }

    return (
      app: buildApp(
        ContextMenu(
          items: items,
          glideToSelect: glide,
          haptics: haptics,
          preview: preview,
          controller: controller,
          child: const SizedBox(key: regionKey, width: 320, height: 200),
        ),
        rtl: rtl,
      ),
      labels: labels,
      activated: activated,
    );
  }

  /// The wash a row paints for its state layer, or `null` when it paints none.
  Color? washOf(WidgetTester tester, String label) {
    final washes = find.descendant(
      of: find.widgetWithText(MenuItem, label),
      matching: find.descendant(
        of: find.byType(Position),
        matching: find.byType(DecoratedBox),
      ),
    );
    for (final element in washes.evaluate()) {
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        return decoration.color;
      }
    }

    return null;
  }

  /// Which of the menu's interactive rows are lit.
  List<int> litRows(WidgetTester tester, List<String> labels) => [
    for (var i = 0; i < labels.length; i++)
      if (find.widgetWithText(MenuItem, labels[i]).evaluate().isNotEmpty &&
          washOf(tester, labels[i]) != null)
        i,
  ];

  group('glide-to-select, every trace of the shared table', () {
    for (final rtl in [false, true]) {
      for (final trace in traces) {
        final platforms = (trace['platforms'] as List?)?.cast<String>();
        if (platforms != null && !platforms.contains('flutter')) continue;

        testWidgets('${trace['name']}${rtl ? ' (right-to-left)' : ''}', (
          tester,
        ) async {
          final haptics = _Haptics(tester);
          addTearDown(haptics.dispose);
          final glide = trace['glide'] != false;
          final menu =
              menus[(trace['menu'] as String?) ?? 'basic']!
                  as Map<String, Object?>;
          final built = contextMenuOf(
            menu,
            glide: glide,
            haptics: trace['haptics'] == true,
            rtl: rtl,
          );
          await tester.pumpWidget(built.app);
          await settle(tester);

          final events = _list(trace['events']);
          final regionTopLeft = tester.getTopLeft(find.byKey(regionKey));
          final down = events.first;
          final origin =
              regionTopLeft +
              Offset(
                (down['x']! as num).toDouble(),
                (down['y']! as num).toDouble(),
              );
          late TestGesture gesture;
          var position = origin;
          var now = 0;
          var opened = false;

          /// Moves the clock to [target] ms after the down, letting the hold
          /// fire and the menu mount on the way.
          Future<void> advanceTo(int target) async {
            if (!opened && target >= 500) {
              await tester.pump(Duration(milliseconds: 500 - now));
              now = 500;
              opened = true;
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 200));
              now += 200;
            }
            if (target > now) {
              await tester.pump(Duration(milliseconds: target - now));
              now = target;
            }
          }

          Offset resolve(Map<String, Object?> to) {
            if (to['same'] == true) return position;
            if (to.containsKey('offset')) {
              final offset = (to['offset']! as List).cast<num>();

              return origin +
                  Offset(offset[0].toDouble(), offset[1].toDouble());
            }
            Rect rowRect(int i) =>
                tester.getRect(find.widgetWithText(MenuItem, built.labels[i]));
            if (to.containsKey('row')) {
              final rect = rowRect((to['row']! as num).toInt());
              final at = (to['at']! as List).cast<num>();

              return rect.topLeft +
                  Offset(rect.width * at[0], rect.height * at[1]);
            }
            final panel = tester.getRect(find.byType(Menu));
            if (to.containsKey('between')) {
              final pair = (to['between']! as List).cast<num>();
              final upper = rowRect(pair[0].toInt());
              final lower = rowRect(pair[1].toInt());

              return Offset(panel.center.dx, (upper.bottom + lower.top) / 2);
            }
            final by = (to['by']! as num).toDouble();

            return switch (to['outside']) {
              'below' => Offset(panel.center.dx, panel.bottom + by),
              'above' => Offset(panel.center.dx, panel.top - by),
              'left' => Offset(panel.left - by, panel.center.dy),
              'right' => Offset(panel.right + by, panel.center.dy),
              final side => throw StateError('unknown side $side'),
            };
          }

          gesture = await tester.startGesture(origin);
          for (final event in events.skip(1)) {
            final kind = event['kind']! as String;
            final at = event['at']! as int;
            await advanceTo(at);
            final to = event['to'] as Map<String, Object?>?;
            switch (kind) {
              case 'move':
                position = resolve(to!);
                await gesture.moveTo(position);
              case 'scroll':
                final target = tester.element(
                  find.widgetWithText(
                    MenuItem,
                    built.labels[(to!['firstRow']! as num).toInt()],
                  ),
                );
                await Scrollable.ensureVisible(target);
              case 'up':
                await gesture.up();
              case 'cancel':
                await gesture.cancel();
              default:
                fail('the table gave Flutter an event it cannot replay: $kind');
            }
            await tester.pump();
            if (kind == 'up' || kind == 'cancel') await settle(tester);

            final expected = event['expect'] as Map<String, Object?>?;
            if (expected == null) continue;
            final where = 'after $kind at $at ms';
            expect(tester.takeException(), isNull, reason: where);
            if (expected.containsKey('highlight')) {
              final lit = litRows(tester, built.labels);
              final want = expected['highlight'] as int?;
              expect(
                lit,
                want == null ? isEmpty : [want],
                reason: '$where: which row is lit',
              );
            }
            if (expected.containsKey('cues')) {
              expect(
                haptics.ticks,
                expected['cues'],
                reason: '$where: haptic ticks',
              );
            }
            if (expected.containsKey('open')) {
              expect(
                find.byType(Menu).evaluate().isNotEmpty,
                expected['open'],
                reason: '$where: whether the menu is open',
              );
            }
            if (expected.containsKey('activated')) {
              expect(
                built.activated,
                (expected['activated']! as List).cast<int>(),
                reason: '$where: which rows were activated',
              );
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('what is on the screen while a finger glides', () {
    Future<({List<String> labels, TestGesture finger})> openAndGlide(
      WidgetTester tester, {
      required String row,
      bool glide = true,
    }) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: glide,
        haptics: false,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, row)),
      );
      await tester.pump();

      return (labels: built.labels, finger: finger);
    }

    testWidgets('the lit row wears exactly the pressed look', (tester) async {
      final glided = await openAndGlide(tester, row: 'Cut');
      final lit = washOf(tester, 'Cut');
      expect(lit, isNotNull, reason: 'a lit row paints a wash');
      await glided.finger.up();
      await settle(tester);
      expect(find.byType(Menu), findsNothing, reason: 'choosing closed it');

      // The reference: the same row in a plain menu, held down by a finger.
      await tester.pumpWidget(
        buildApp(
          Menu(
            items: [CoreMenuItem.action('Cut', onPressed: () {})],
          ),
        ),
      );
      await tester.pump();
      final press = await tester.startGesture(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final pressed = washOf(tester, 'Cut');
      await press.up();
      await tester.pumpAndSettle();

      expect(pressed, isNotNull);
      expect(lit, pressed);
    });

    testWidgets('a row the finger leaves goes back to rest', (tester) async {
      final glided = await openAndGlide(tester, row: 'Cut');
      expect(litRows(tester, glided.labels), [2]);

      await glided.finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Copy')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(litRows(tester, glided.labels), [0]);
      expect(washOf(tester, 'Cut'), isNull);
    });

    testWidgets('the panel has a glide scope only when the glide is on', (
      tester,
    ) async {
      await openAndGlide(tester, row: 'Cut');
      expect(find.byType(MenuGlideScope), findsOneWidget);

      await tester.pumpWidget(const material.SizedBox());
      await tester.pumpAndSettle();
      await openAndGlide(tester, row: 'Cut', glide: false);
      expect(find.byType(MenuGlideScope), findsNothing);
    });
  });

  group('the mouse and the keyboard are unchanged', () {
    testWidgets('a right-click opens the menu and starts no glide', (
      tester,
    ) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: true,
        rtl: false,
      );
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);
      await tester.pumpWidget(built.app);
      await settle(tester);

      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final mouse = await tester.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await tester.pump(const Duration(milliseconds: 700));
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget);

      // The button is still down; the pointer travels onto a row and lifts.
      // A mouse has no finger to glide with: nothing is chosen.
      await mouse.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await tester.pump();
      await mouse.up();
      await settle(tester);

      expect(built.activated, isEmpty);
      expect(find.byType(Menu), findsOneWidget, reason: 'it stays open');
      expect(haptics.ticks, 0);
    });

    testWidgets('a menu opened by controller starts no glide', (tester) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);
      final activated = <int>[];
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            controller: controller,
            glideToSelect: true,
            items: [
              CoreMenuItem.action('Cut', onPressed: () => activated.add(0)),
            ],
            child: const SizedBox(key: regionKey, width: 320, height: 200),
          ),
        ),
      );
      controller.show();
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget);

      final stray = await tester.startGesture(const Offset(5, 5));
      await stray.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await stray.up();
      await settle(tester);
      expect(activated, isEmpty, reason: 'no finger of the menu is gliding');
    });

    testWidgets('the keyboard opens a gliding menu without a glide', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final activated = <int>[];
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            glideToSelect: true,
            items: [
              CoreMenuItem.action('Cut', onPressed: () => activated.add(0)),
            ],
            child: Focus(
              focusNode: focus,
              child: const SizedBox(width: 320, height: 200),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(MenuGlideScope), findsOneWidget);
      expect(activated, isEmpty);
    });
  });

  group('a glide ends when the menu does', () {
    testWidgets('Escape mid-glide, then lifting, chooses nothing', (
      tester,
    ) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: true,
        rtl: false,
      );
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await tester.pump();
      expect(haptics.ticks, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.byType(Menu), findsNothing);

      await finger.up();
      await settle(tester);
      expect(built.activated, isEmpty);
      expect(haptics.ticks, 1, reason: 'no activation tick for a closed menu');
      expect(tester.takeException(), isNull);
    });

    // The invariant is only observable while the panel is still on the screen:
    // once the exit has played the rows are gone and nothing can be chosen
    // whatever the glide thinks. So the lift here comes a fraction of the exit
    // after the menu began to close — the rows are still mounted and still
    // measurable under the finger.
    final closers =
        <String, Future<void> Function(WidgetTester, PopoverController)>{
          'Escape': (tester, _) async {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          },
          'controller.close()': (_, controller) async => controller.close(),
        };
    for (final closer in closers.entries) {
      testWidgets(
        'lifting over a row of a menu that is still leaving chooses nothing '
        '(${closer.key})',
        (tester) async {
          final controller = PopoverController();
          addTearDown(controller.dispose);
          final built = contextMenuOf(
            menus['basic']! as Map<String, Object?>,
            glide: true,
            haptics: true,
            rtl: false,
            controller: controller,
          );
          final haptics = _Haptics(tester);
          addTearDown(haptics.dispose);
          await tester.pumpWidget(built.app);
          await settle(tester);
          final origin =
              tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
          final finger = await tester.startGesture(origin);
          await tester.pump(const Duration(milliseconds: 600));
          await settle(tester);
          await finger.moveTo(
            tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
          );
          await tester.pump();
          expect(haptics.ticks, 1, reason: 'the premise: the row is entered');
          expect(
            litRows(tester, built.labels),
            isNotEmpty,
            reason: 'the premise: a row is lit under the finger',
          );

          await closer.value(tester, controller);
          await tester.pump(const Duration(milliseconds: 20));
          expect(
            find.widgetWithText(MenuItem, 'Cut'),
            findsOneWidget,
            reason: 'the premise: the panel is still on the screen, leaving',
          );
          expect(
            litRows(tester, built.labels),
            isEmpty,
            reason: 'a menu that began to close lights no row',
          );

          await finger.up();
          await tester.pump(const Duration(milliseconds: 20));
          expect(
            built.activated,
            isEmpty,
            reason: 'no row of a closing menu is activated',
          );
          expect(
            haptics.ticks,
            1,
            reason: 'no activation tick for a closing menu',
          );
          expect(tester.takeException(), isNull);

          await settle(tester);
          expect(find.byType(Menu), findsNothing);
          expect(built.activated, isEmpty);
        },
      );
    }

    testWidgets('holding again on the open menu closes it and glides nowhere', (
      tester,
    ) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: false,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);

      final first = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await first.up();
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget, reason: 'opened, lifted: open');

      final second = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      expect(find.byType(Menu), findsNothing, reason: 'the second hold closes');
      await second.moveTo(origin + const Offset(100, 100));
      await second.up();
      await settle(tester);
      expect(built.activated, isEmpty);
    });

    testWidgets('a second glide after the first works', (tester) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: false,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);

      for (final label in ['Cut', 'Delete']) {
        final finger = await tester.startGesture(origin);
        await tester.pump(const Duration(milliseconds: 600));
        await settle(tester);
        await finger.moveTo(
          tester.getCenter(find.widgetWithText(MenuItem, label)),
        );
        await tester.pump();
        await finger.up();
        await settle(tester);
      }
      expect(built.activated, [2, 4]);
    });

    testWidgets('switching the glide off while a finger is down stops it', (
      tester,
    ) async {
      final glide = ValueNotifier<bool>(true);
      addTearDown(glide.dispose);
      final activated = <int>[];
      await tester.pumpWidget(
        buildApp(
          ValueListenableBuilder<bool>(
            valueListenable: glide,
            builder: (_, on, _) => ContextMenu(
              glideToSelect: on,
              items: [
                CoreMenuItem.action('Cut', onPressed: () => activated.add(0)),
              ],
              child: const SizedBox(key: regionKey, width: 320, height: 200),
            ),
          ),
        ),
      );
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);

      glide.value = false;
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await finger.up();
      await settle(tester);

      expect(activated, isEmpty);
      expect(find.byType(MenuGlideScope), findsNothing);
    });

    testWidgets('disabling the menu while a finger glides stops the glide', (
      tester,
    ) async {
      final enabled = ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);
      final activated = <int>[];
      await tester.pumpWidget(
        buildApp(
          ValueListenableBuilder<bool>(
            valueListenable: enabled,
            builder: (_, on, _) => ContextMenu(
              enabled: on,
              glideToSelect: true,
              items: [
                CoreMenuItem.action('Cut', onPressed: () => activated.add(0)),
              ],
              child: const SizedBox(key: regionKey, width: 320, height: 200),
            ),
          ),
        ),
      );
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget, reason: 'the premise: open');

      enabled.value = false;
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await finger.up();
      await settle(tester);

      expect(activated, isEmpty);
    });

    testWidgets('opening again while the first panel is still leaving raises '
        'nothing', (tester) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: false,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      Future<void> rightClick() async {
        final click = await tester.startGesture(
          origin,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await click.up();
      }

      await rightClick();
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 20));
      // The first panel is mid-exit when the second one opens beside it.
      await rightClick();
      await tester.pump();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Menu), findsOneWidget, reason: 'only the new panel');
      await tester.tap(find.widgetWithText(MenuItem, 'Cut'));
      await settle(tester);
      expect(built.activated, [2]);
    });
  });

  group('a lit row and the host going away or changing', () {
    testWidgets('switching the glide off while a row is lit dims it, '
        'without a build error', (tester) async {
      final glide = ValueNotifier<bool>(true);
      addTearDown(glide.dispose);
      await tester.pumpWidget(
        buildApp(
          ValueListenableBuilder<bool>(
            valueListenable: glide,
            builder: (_, on, _) => ContextMenu(
              glideToSelect: on,
              items: [
                CoreMenuItem.action('Cut', onPressed: () {}),
                CoreMenuItem.action('Paste', onPressed: () {}),
              ],
              child: const SizedBox(key: regionKey, width: 320, height: 200),
            ),
          ),
        ),
      );
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Paste')),
      );
      await tester.pump();
      expect(washOf(tester, 'Paste'), isNotNull, reason: 'the premise: lit');

      glide.value = false;
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(washOf(tester, 'Paste'), isNull, reason: 'dimmed');
    });

    testWidgets('taking the host away while a row is lit raises nothing', (
      tester,
    ) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: false,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Cut')),
      );
      await tester.pump();
      expect(washOf(tester, 'Cut'), isNotNull, reason: 'the premise: lit');

      await tester.pumpWidget(const material.SizedBox());
      await settle(tester);
      await finger.up();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(built.activated, isEmpty);
    });
  });

  group('a scrolling host', () {
    material.Widget scrollingApp(
      ScrollController controller,
      List<int> activated,
    ) => buildApp(
      ListView(
        controller: controller,
        children: [
          for (var i = 0; i < 12; i++)
            ContextMenu(
              glideToSelect: true,
              items: [
                CoreMenuItem.action(
                  'Open $i',
                  onPressed: () => activated.add(i * 10),
                ),
                CoreMenuItem.action(
                  'Share $i',
                  onPressed: () => activated.add(i * 10 + 1),
                ),
              ],
              child: SizedBox(
                key: ValueKey('region$i'),
                height: 100,
                child: material.Text('Row $i'),
              ),
            ),
        ],
      ),
    );

    testWidgets('the finger that opened the menu glides and the list stays '
        'where it was', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final activated = <int>[];
      await tester.pumpWidget(scrollingApp(controller, activated));
      await settle(tester);

      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('region2'))),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      expect(find.byType(Menu), findsOneWidget);
      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Share 2')),
      );
      await tester.pump();
      await finger.up();
      await settle(tester);

      expect(activated, [21]);
      expect(
        controller.offset,
        0,
        reason: 'the list did not follow the finger',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a drag that starts before the hold is up scrolls the list '
        'and opens nothing', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(scrollingApp(controller, <int>[]));
      await settle(tester);

      await tester.drag(
        find.byKey(const ValueKey('region2')),
        const Offset(0, -150),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(Menu), findsNothing);
      expect(controller.offset, greaterThan(0));
    });
  });

  group('selection haptics', () {
    testWidgets('playHapticCue asks the platform for one selection click', (
      tester,
    ) async {
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);

      playHapticCue(CoreHapticCue.selectionTick);
      await tester.pump();

      expect(haptics.requests, [_kSelectionClick]);
    });

    testWidgets('haptics without a glide ask for nothing, on open or on tap', (
      tester,
    ) async {
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: false,
        haptics: true,
        rtl: false,
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await finger.up();
      await tester.tap(find.widgetWithText(MenuItem, 'Cut'));
      await settle(tester);

      expect(built.activated, [2]);
      expect(haptics.requests, isEmpty);
    });
  });

  group('the preview', () {
    final scenarios = _list(previewDoc['scenarios']);
    final gap = (previewDoc['gap']! as num).toDouble();
    const previewKey = ValueKey('preview');
    // The room the menu keeps from the window's edges, and the room the
    // preview keeps with it.
    const margin = 8.0;

    // The region keeps the menu's margin (and a little more) from every edge
    // of the window. The engine anchors the panel at the pointer on top of the
    // region's top-left corner and decides whether to flip it by where *that
    // corner* is: a region that fills the window would flip the panel to
    // somewhere the pointer is not, and the scenarios would measure the
    // engine's flip rather than the preview.
    material.Widget previewedApp({
      required Size content,
      required bool rtl,
      int rows = 3,
      material.Widget? preview,
    }) => buildApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: ContextMenu(
          items: [
            for (var i = 0; i < rows; i++)
              CoreMenuItem.action('Item $i', onPressed: () {}),
          ],
          preview:
              preview ??
              SizedBox(
                key: previewKey,
                width: content.width,
                height: content.height,
              ),
          child: const SizedBox.expand(key: regionKey),
        ),
      ),
      rtl: rtl,
    );

    Future<void> openAt(WidgetTester tester, Offset pointer) async {
      final click = await tester.startGesture(
        pointer,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await settle(tester);
      await tester.pump();
    }

    void sizeWindow(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    /// The box the rule places: the floating panel drawn around the preview.
    Rect popupAround(WidgetTester tester) => tester.getRect(
      find.ancestor(of: find.byKey(previewKey), matching: find.byType(Popup)),
    );

    /// What the panel adds around the preview. The table speaks of the box
    /// that is placed, so a preview is sized to make that box the table's.
    Future<Size> chromeOf(WidgetTester tester, {required bool rtl}) async {
      // Wider than the panel's own minimum width, so that only its padding is
      // measured.
      const probe = Size(160, 100);
      await tester.pumpWidget(previewedApp(content: probe, rtl: rtl));
      await settle(tester);
      await openAt(tester, const Offset(40, 40));
      final box = popupAround(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.byType(Menu), findsNothing, reason: 'the probe is closed');

      return Size(box.width - probe.width, box.height - probe.height);
    }

    for (final scenario in scenarios) {
      testWidgets(scenario['name']! as String, (tester) async {
        final window = (scenario['viewport']! as List).cast<num>();
        sizeWindow(tester, Size(window[0].toDouble(), window[1].toDouble()));
        final rtl = scenario['direction'] == 'rtl';
        final preview = (scenario['preview']! as List).cast<num>();
        final chrome = await chromeOf(tester, rtl: rtl);
        await tester.pumpWidget(
          previewedApp(
            rows: (scenario['rows']! as num).toInt(),
            content: Size(
              preview[0] - chrome.width,
              preview[1] - chrome.height,
            ),
            rtl: rtl,
          ),
        );
        await settle(tester);

        final pointer = (scenario['pointer']! as List).cast<num>();
        await openAt(
          tester,
          Offset(pointer[0].toDouble(), pointer[1].toDouble()),
        );

        final menu = tester.getRect(find.byType(Menu));
        final placed = popupAround(tester);
        expect(placed.width, closeTo(preview[0], 0.01), reason: 'whole');
        expect(placed.height, closeTo(preview[1], 0.01), reason: 'whole');

        switch (scenario['physical']) {
          case 'above':
            expect(menu.top - placed.bottom, closeTo(gap, 0.01));
          case 'below':
            expect(placed.top - menu.bottom, closeTo(gap, 0.01));
          case 'left':
            expect(menu.left - placed.right, closeTo(gap, 0.01));
          case 'right':
            expect(placed.left - menu.right, closeTo(gap, 0.01));
          case final side:
            fail('the table names a side Flutter cannot read: $side');
        }
        expect(placed.overlaps(menu), isFalse, reason: 'never over the menu');
        final room = Rect.fromLTRB(
          margin,
          margin,
          window[0] - margin,
          window[1] - margin,
        );
        expect(placed.left, greaterThanOrEqualTo(room.left - 0.01));
        expect(placed.top, greaterThanOrEqualTo(room.top - 0.01));
        expect(placed.right, lessThanOrEqualTo(room.right + 0.01));
        expect(placed.bottom, lessThanOrEqualTo(room.bottom + 0.01));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the Core rule decides, whatever the menu measured', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      final chrome = await chromeOf(tester, rtl: false);
      await tester.pumpWidget(
        previewedApp(
          content: Size(200 - chrome.width, 120 - chrome.height),
          rtl: false,
        ),
      );
      await settle(tester);
      await openAt(tester, const Offset(100, 600));

      final menu = tester.getRect(find.byType(Menu));
      final expected = CoreContextMenuPreview.place(
        menu: CoreMenuBox(
          left: menu.left,
          top: menu.top,
          right: menu.right,
          bottom: menu.bottom,
        ),
        previewWidth: 200,
        previewHeight: 120,
        viewport: const CoreMenuBox(
          left: margin,
          top: margin,
          right: 390 - margin,
          bottom: 844 - margin,
        ),
      );
      final placed = popupAround(tester);
      expect(placed.left, closeTo(expected.box.left, 0.01));
      expect(placed.top, closeTo(expected.box.top, 0.01));
      expect(placed.right, closeTo(expected.box.right, 0.01));
      expect(placed.bottom, closeTo(expected.box.bottom, 0.01));
    });

    testWidgets('a status bar takes room from the rule: no longer above', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      tester.view.padding = const FakeViewPadding(top: 40);
      final chrome = await chromeOf(tester, rtl: false);
      await tester.pumpWidget(
        previewedApp(
          content: Size(200 - chrome.width, 120 - chrome.height),
          rtl: false,
        ),
      );
      await settle(tester);
      // 134 px between the pointer and the window's edge fits 120 + the gap
      // until the status bar's 40 px is taken off the room above.
      await openAt(tester, const Offset(100, 150));

      final menu = tester.getRect(find.byType(Menu));
      final placed = popupAround(tester);
      expect(
        placed.top,
        closeTo(menu.bottom + gap, 0.01),
        reason: 'below: the room above ends under the status bar',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the keyboard takes room from the rule: it goes beside', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      final chrome = await chromeOf(tester, rtl: false);
      await tester.pumpWidget(
        previewedApp(
          content: Size(200 - chrome.width, 120 - chrome.height),
          rtl: false,
        ),
      );
      await settle(tester);
      // Below the menu there is room for the preview until the keyboard's
      // 600 px is taken off the bottom of the window.
      await openAt(tester, const Offset(100, 40));

      final menu = tester.getRect(find.byType(Menu));
      final placed = popupAround(tester);
      expect(
        placed.right,
        lessThanOrEqualTo(menu.left),
        reason: 'beside the menu: below it the keyboard has the room',
      );
      expect(placed.overlaps(menu), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a preview no side holds is held to the room it has', (
      tester,
    ) async {
      sizeWindow(tester, const Size(300, 300));
      final chrome = await chromeOf(tester, rtl: false);
      await tester.pumpWidget(
        previewedApp(
          content: Size(250 - chrome.width, 250 - chrome.height),
          rtl: false,
        ),
      );
      await settle(tester);
      await openAt(tester, const Offset(20, 20));

      final menu = tester.getRect(find.byType(Menu));
      final placed = popupAround(tester);
      expect(placed.top, closeTo(menu.bottom + gap, 0.01), reason: 'below');
      expect(placed.bottom, closeTo(300 - margin, 0.01), reason: 'to the room');
      expect(placed.height, lessThan(250));
      expect(placed.overlaps(menu), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a preview with no room beside the menu is not drawn', (
      tester,
    ) async {
      sizeWindow(tester, const Size(160, 130));
      await tester.pumpWidget(
        previewedApp(content: const Size(40, 30), rtl: false),
      );
      await settle(tester);
      // The menu takes what the window leaves; nothing is left on any side.
      await openAt(tester, const Offset(16, 16));

      final placement = tester.renderObject(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_PreviewPlacement',
        ),
      );
      expect(placement, paintsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no preview, no second layer: the default is unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            items: [CoreMenuItem.action('Cut', onPressed: () {})],
            child: const SizedBox(key: regionKey, width: 320, height: 200),
          ),
        ),
      );
      await settle(tester);
      await openAt(tester, tester.getCenter(find.byKey(regionKey)));

      expect(find.byType(Menu), findsOneWidget);
      expect(find.byType(Popup), findsOneWidget, reason: 'only the menu panel');
    });

    testWidgets('the preview is read by assistive technology, as plain '
        'content', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        sizeWindow(tester, const Size(390, 844));
        await tester.pumpWidget(
          previewedApp(
            content: const Size(200, 120),
            rtl: false,
            preview: const SizedBox(
              key: previewKey,
              width: 200,
              height: 120,
              child: material.Text('Quarterly report.pdf'),
            ),
          ),
        );
        await settle(tester);
        await openAt(tester, const Offset(100, 600));
        await settle(tester);

        expect(find.bySemanticsLabel('Quarterly report.pdf'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a tap on the preview is a tap outside the menu', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      final chrome = await chromeOf(tester, rtl: false);
      await tester.pumpWidget(
        previewedApp(
          content: Size(200 - chrome.width, 120 - chrome.height),
          rtl: false,
        ),
      );
      await settle(tester);
      await openAt(tester, const Offset(100, 600));
      expect(find.byKey(previewKey), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.byKey(previewKey)));
      await settle(tester);

      expect(find.byType(Menu), findsNothing);
      expect(find.byKey(previewKey), findsNothing, reason: 'it goes with it');
    });

    testWidgets('the preview waits for the menu to be placed, then shows', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      await tester.pumpWidget(
        previewedApp(content: const Size(200, 120), rtl: false),
      );
      await settle(tester);
      final click = await tester.startGesture(
        const Offset(100, 600),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      // The menu is built on this frame; the engine tells the preview where it
      // landed after it.
      await tester.pump();

      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(previewKey),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(), 0, reason: 'not before the menu has a place');

      await settle(tester);
      expect(opacity(), 1, reason: 'then the whole preview');
    });

    testWidgets(
      'a host that rebuilds with a new preview updates the open one',
      (
        tester,
      ) async {
        sizeWindow(tester, const Size(390, 844));
        final preview = ValueNotifier<String>('First');
        addTearDown(preview.dispose);
        await tester.pumpWidget(
          buildApp(
            Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<String>(
                valueListenable: preview,
                builder: (_, text, _) => ContextMenu(
                  items: [CoreMenuItem.action('Cut', onPressed: () {})],
                  preview: SizedBox(
                    width: 160,
                    height: 60,
                    child: material.Text(text),
                  ),
                  child: const SizedBox.expand(key: regionKey),
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        await openAt(tester, const Offset(100, 600));
        expect(find.text('First'), findsOneWidget);

        preview.value = 'Second';
        await settle(tester);
        expect(find.text('Second'), findsOneWidget);
        expect(find.text('First'), findsNothing);
      },
    );

    testWidgets('the preview fades out with the menu, then goes', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      await tester.pumpWidget(
        previewedApp(content: const Size(200, 120), rtl: false),
      );
      await settle(tester);
      await openAt(tester, const Offset(100, 600));
      // The fade-in starts on the frame after the menu has a place.
      await settle(tester);

      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(previewKey),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(), 1, reason: 'the premise: fully shown');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byKey(previewKey), findsOneWidget, reason: 'still fading');
      expect(opacity(), lessThan(1), reason: 'on its way out');
      expect(opacity(), greaterThan(0));

      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(previewKey), findsNothing);
    });

    testWidgets('the preview follows the menu out: gone with it', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      await tester.pumpWidget(
        previewedApp(content: const Size(200, 120), rtl: false),
      );
      await settle(tester);
      await openAt(tester, const Offset(100, 600));
      expect(find.byKey(previewKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);

      expect(find.byType(Menu), findsNothing);
      expect(find.byKey(previewKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing the host with the menu open removes the preview', (
      tester,
    ) async {
      sizeWindow(tester, const Size(390, 844));
      await tester.pumpWidget(
        previewedApp(content: const Size(200, 120), rtl: false),
      );
      await settle(tester);
      await openAt(tester, const Offset(100, 600));
      expect(find.byKey(previewKey), findsOneWidget);

      await tester.pumpWidget(const material.SizedBox());
      await settle(tester);

      expect(find.byKey(previewKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a glide goes over the preview to the rows: it ignores the '
        'pointer', (tester) async {
      final built = contextMenuOf(
        menus['basic']! as Map<String, Object?>,
        glide: true,
        haptics: false,
        rtl: false,
        preview: const SizedBox(key: previewKey, width: 120, height: 60),
      );
      await tester.pumpWidget(built.app);
      await settle(tester);
      final origin =
          tester.getTopLeft(find.byKey(regionKey)) + const Offset(60, 50);
      final finger = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      expect(find.byKey(previewKey), findsOneWidget);

      await finger.moveTo(
        tester.getCenter(find.widgetWithText(MenuItem, 'Delete')),
      );
      await tester.pump();
      await finger.up();
      await settle(tester);

      expect(built.activated, [4]);
      expect(find.byKey(previewKey), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
