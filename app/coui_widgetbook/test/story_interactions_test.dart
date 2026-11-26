import 'package:coui_flutter/coui_flutter.dart' as co;
import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/components.g.dart';
import 'package:coui_widgetbook/widgetbook_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart' as wb;

void main() {
  testWidgets('dark previews paint a dark surface behind their content', (
    tester,
  ) async {
    await _mountStory(tester, 'navigation/TabPane/Default', dark: true);
    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('widgetbook-preview-surface')),
    );
    expect(
      surface.color,
      co.ThemeData.fromCore(
        co.CoreThemePresets.dark,
      ).colorScheme.surface.toValue(),
    );
  });
  for (final sample in [
    (
      path: 'overlay/AlertDialog/Default',
      open: 'Show Confirmation',
      title: 'Confirm Action',
      close: 'Confirm',
    ),
    (
      path: 'overlay/AlertDialog/Destructive',
      open: 'Show Confirmation',
      title: 'Confirm Action',
      close: 'Delete',
    ),
    (
      path: 'overlay/Dialog/With Actions',
      open: 'Show Confirmation',
      title: 'Confirm Action',
      close: 'Cancel',
    ),
    (
      path: 'overlay/Dialog/With Icon',
      open: 'Show Warning',
      title: 'Warning',
      close: 'Dismiss',
    ),
    (
      path: 'overlay/Dialog/Stretch',
      open: 'Show Mobile Confirm',
      title: 'Connection lost',
      close: 'Cancel',
    ),
  ]) {
    testWidgets('${sample.path} opens and closes on the root navigator', (
      tester,
    ) async {
      await _mountStory(tester, sample.path);
      expect(find.text(sample.title), findsNothing);
      await tester.tap(find.text(sample.open));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(sample.title), findsOneWidget);
      await tester.tap(find.text(sample.close));
      await tester.pumpAndSettle();
      expect(find.text(sample.title), findsNothing);
      expect(find.text(sample.open), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Dialog/Stretch splits the actions row between its two actions', (
    tester,
  ) async {
    await _mountStory(tester, 'overlay/Dialog/Stretch');
    await tester.tap(find.text('Show Mobile Confirm'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<co.Dialog>(find.byType(co.Dialog));
    expect(
      dialog.dialogStyle?.actionsLayout,
      co.CoreDialogActionsLayout.stretch,
    );
    final cancel = tester.getRect(find.widgetWithText(co.Button, 'Cancel'));
    final confirm = tester.getRect(find.widgetWithText(co.Button, 'Confirm'));
    expect(cancel.width, confirm.width);
    expect(cancel.top, confirm.top);
    expect(cancel.right, lessThan(confirm.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('FadeScroll owns exactly one scrolling position', (tester) async {
    await _mountStory(tester, 'layout/FadeScroll/Default');
    final fade = tester.widget<co.FadeScroll>(find.byType(co.FadeScroll));
    expect(fade.controller!.positions, hasLength(1));
    expect(fade.controller!.offset, 0);
    await tester.drag(find.byType(co.FadeScroll), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(fade.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scaffold converts its percentage knob to a progress fraction', (
    tester,
  ) async {
    await _mountStory(tester, 'layout/Scaffold/Loading');
    final progress = tester.widget<co.Progress>(find.byType(co.Progress));
    expect(progress.value, 0.65);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom Collapsible trigger expands and collapses', (
    tester,
  ) async {
    await _mountStory(tester, 'layout/Collapsible/Custom Trigger');
    final collapsedHeight = tester.getSize(find.byType(co.Collapsible)).height;
    await tester.tap(find.text('FAQ: What is Collapsible?'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(co.Collapsible)).height,
      greaterThan(collapsedHeight),
    );
    await tester.tap(find.text('FAQ: What is Collapsible?'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(co.Collapsible)).height, collapsedHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TabPane drag feedback renders and reorders without losing selection',
    (tester) async {
      await _mountStory(tester, 'navigation/TabPane/Reorderable');
      final initial = tester.widget<co.TabPane>(find.byType(co.TabPane));
      final first = initial.tabs.first;
      final last = initial.tabs.last;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(first.label)),
      );
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text(last.label)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      final reordered = tester.widget<co.TabPane>(find.byType(co.TabPane));
      expect(reordered.tabs, isNot(orderedEquals(initial.tabs)));
      expect(reordered.tabs[reordered.selectedIndex], same(first));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DatePicker opens the calendar and accepts a date', (
    tester,
  ) async {
    await _mountStory(tester, 'form/DatePicker/Default');
    final trigger = find.byType(co.DatePicker);
    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(co.Calendar), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The demo intentionally disables future dates; day 1 is always enabled.
    await tester.tap(find.text('1').first);
    await tester.pump();
    expect(tester.widget<co.DatePicker>(trigger).value?.day, 1);
    await tester.pump(
      const Duration(
        milliseconds: co.CoreDatePickerStyle.defaultPopoverDismissDelayMs,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(co.Calendar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mountStory(
  WidgetTester tester,
  String path, {
  bool dark = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final _ = LocaleSettings.setLocaleRawSync('ko');
  final story = components
      .expand((component) => component.stories)
      .singleWhere((story) => story.path == path);
  final config = createWidgetbookConfig();
  final themeAddon = config.addons!
      .whereType<wb.ThemeAddon<co.ThemeData>>()
      .single;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => story.buildWithConfig(
          context,
          config,
          modes: dark
              ? [
                  wb.ThemeMode<co.ThemeData>(
                    'Dark',
                    themeAddon.themes['Dark']!,
                    themeAddon.builder,
                  ),
                ]
              : null,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}
