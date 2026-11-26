import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter_test/flutter_test.dart';

/// Every mounted [ModalRoute] barrier's semantics label — collected across
/// both concrete widgets [ModalRoute.buildModalBarrier] can choose
/// (`ModalBarrier` when the barrier is fully transparent, `AnimatedModalBarrier`
/// otherwise) since a test app can have more than one barrier mounted (e.g.
/// an implicit root-route placeholder alongside the drawer's own).
Iterable<String> _barrierSemanticsLabels(WidgetTester tester) => tester
    .allWidgets
    .map(
      (w) => switch (w) {
        ModalBarrier(:final semanticsLabel) ||
        AnimatedModalBarrier(:final semanticsLabel) => semanticsLabel,
        _ => null,
      },
    )
    .whereType();

/// The `Resizable` split under test — the left pane's share of the
/// container, which is what its divider announces.
const _kLeftPaneFraction = 0.3;
const _kRightPaneFraction = 0.7;

/// Ratio → percent, mirroring the component's own conversion so the
/// expected sentences are derived the same way the announced ones are
/// rather than transcribed by hand.
const _kPercentScale = 100;

const _kKeyboardStep = CoreResizableContract.defaultKeyboardStepFraction;

const _kResizableTestSize = 200.0;

int _percent(double ratio) => (ratio * _kPercentScale).round();

/// Frames to pump, 50 ms apiece, while the picker's panel mounts — a bound
/// so a panel that never opens fails the assertion instead of hanging.
const _kPopoverMountFrames = 20;

Future<void> _pump(WidgetTester tester, Widget home, {Locale? locale}) async {
  await tester.pumpWidget(
    CoUIApp(
      home: home,
      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('ko')],
      theme: ThemeData.fromCore(CoreThemePresets.light),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Measured before this changed: the panel's control buttons already read
  // `CoUILocalizations.of(context)` for minimize/maximize/close, but the
  // outer `Semantics(label: 'window')` was a hardcoded English literal —
  // switching locale never touched it.
  group('WindowPanel accessible name comes from the active locale', () {
    testWidgets('English default', (tester) async {
      await _pump(tester, const WindowPanel(child: SizedBox()));

      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((w) => w.properties.label);
      expect(labels, contains('Window'));
    });

    testWidgets('Korean', (tester) async {
      await _pump(
        tester,
        const WindowPanel(child: SizedBox()),
        locale: const Locale('ko'),
      );

      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((w) => w.properties.label);
      expect(labels, contains('창'));
    });
  });

  // Measured before this changed: `DialogRoute.barrierLabel` (the sibling
  // overlay route) already resolved through `CoUILocalizations`, but
  // `_DrawerRoute.barrierLabel` returned a hardcoded `'Dismiss'` — a screen
  // reader announced the drawer's dismiss barrier in English regardless of
  // the app's locale.
  group(
    'opening a Drawer names its dismiss barrier from the active locale',
    () {
      late BuildContext homeContext;
      Widget openerHome() => Builder(
        builder: (context) {
          homeContext = context;
          return const SizedBox();
        },
      );

      testWidgets('English default', (tester) async {
        await _pump(tester, openerHome());
        unawaited(
          openDrawer(
            context: homeContext,
            side: .bottom,
            transformBackdrop: false,
            builder: (context) => const Drawer(content: SizedBox()),
          ),
        );
        await tester.pumpAndSettle();

        expect(_barrierSemanticsLabels(tester), contains('Dismiss'));
      });

      testWidgets('Korean', (tester) async {
        await _pump(tester, openerHome(), locale: const Locale('ko'));
        unawaited(
          openDrawer(
            context: homeContext,
            side: .bottom,
            transformBackdrop: false,
            builder: (context) => const Drawer(content: SizedBox()),
          ),
        );
        await tester.pumpAndSettle();

        expect(_barrierSemanticsLabels(tester), contains('닫기'));
      });
    },
  );

  // Measured before this changed: Web's dot indicator already named its
  // group (`dotIndicatorLabel`) and each dot (`dotIndicatorGoToItem`) —
  // Flutter had zero `Semantics` at all. Worse than a hardcoded label: a
  // carousel position with no accessible name and no way to jump to a
  // slide via assistive tech, on either locale.
  group('DotIndicator names come from the active locale', () {
    testWidgets('English default', (tester) async {
      await _pump(
        tester,
        DotIndicator(index: 0, length: 3, onChanged: (_) {}),
      );

      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((w) => w.properties.label);
      expect(labels, containsAll(['Page navigation', 'Go to item 1']));
    });

    testWidgets('Korean', (tester) async {
      await _pump(
        tester,
        DotIndicator(index: 0, length: 3, onChanged: (_) {}),
        locale: const Locale('ko'),
      );

      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((w) => w.properties.label);
      expect(labels, containsAll(['페이지 탐색', '1번 항목으로 이동']));
    });
  });

  // Measured before this changed: the divider's `Semantics` carried
  // `value: '30%'` — a bare number with no subject — and no `label` at
  // all. A reader announced "30 percent" of nothing, in English,
  // whatever the app locale was. The Web twin had the same gap in
  // `aria-valuetext`, so neither platform could be used as the
  // reference for the other.
  group('Resizable divider name and spoken value come from the locale', () {
    const english = DefaultCoUILocalizations.instance;
    const korean = KoCoUILocalizations.instance;

    /// The divider's own `Semantics` — the only slider in this subtree.
    SemanticsProperties dividerProperties(WidgetTester tester) => tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((w) => w.properties)
        .singleWhere((p) => p.slider ?? false);

    Widget sizedResizable() => const SizedBox(
      width: _kResizableTestSize,
      height: _kResizableTestSize,
      child: Resizable(
        panes: [
          CoreResizablePaneData(
            content: SizedBox(),
            initialSize: _kLeftPaneFraction,
          ),
          CoreResizablePaneData(
            content: SizedBox(),
            initialSize: _kRightPaneFraction,
          ),
        ],
      ),
    );

    testWidgets('English default', (tester) async {
      await _pump(tester, sizedResizable());

      final props = dividerProperties(tester);
      expect(props.label, english.resizableDividerLabel);
      expect(
        props.value,
        english.resizableDividerPositionLabel(_percent(_kLeftPaneFraction)),
      );
    });

    testWidgets('Korean', (tester) async {
      await _pump(tester, sizedResizable(), locale: const Locale('ko'));

      final props = dividerProperties(tester);
      expect(props.label, korean.resizableDividerLabel);
      expect(
        props.value,
        korean.resizableDividerPositionLabel(_percent(_kLeftPaneFraction)),
      );
    });

    testWidgets(
      'the whole value axis moves with the locale, not just the current '
      'value',
      (tester) async {
        await _pump(tester, sizedResizable(), locale: const Locale('ko'));

        // `increasedValue`/`decreasedValue` are what a reader speaks
        // *before* the swipe commits, and `minValue`/`maxValue` bound
        // the range it reports. In Flutter these are all `String?` —
        // the analog of the Web twin's `aria-valuetext`, not of its
        // numeric `aria-valuenow`. Leaving any of them formatted by
        // hand would announce one sentence in Korean and the next in
        // English on the same control.
        final props = dividerProperties(tester);
        expect(
          props.increasedValue,
          korean.resizableDividerPositionLabel(
            _percent(_kLeftPaneFraction + _kKeyboardStep),
          ),
        );
        expect(
          props.decreasedValue,
          korean.resizableDividerPositionLabel(
            _percent(_kLeftPaneFraction - _kKeyboardStep),
          ),
        );
        // `minValue`/`maxValue` are the exception: Flutter's web engine
        // writes them straight into `aria-valuemin`/`aria-valuemax` and
        // parses them as numbers, so they stay bare — a translated
        // sentence there is the same mistake as translating
        // `aria-valuenow`. Neither pane constrains this divider, so the
        // reachable range is the whole container.
        expect(props.minValue, '${_percent(0)}');
        expect(props.maxValue, '${_percent(1)}');
      },
    );

    // Not a `testWidgets` — it pumps nothing. Every assertion above
    // reads its expected value from the same localizations the component
    // reads, which makes them blind to two things the strings themselves
    // could get wrong. This closes both.
    test('the strings are translated, and each carries its number', () {
      // (1) `ko` really differs from English. If it silently served the
      // English values — the exact failure mode `Default*` inheritance
      // produces — every assertion above would still pass.
      final percent = _percent(_kLeftPaneFraction);
      expect(
        korean.resizableDividerLabel,
        isNot(english.resizableDividerLabel),
      );
      expect(
        korean.resizableDividerPositionLabel(percent),
        isNot(english.resizableDividerPositionLabel(percent)),
      );

      // (2) Each sentence actually carries the number it describes —
      // for **both** locales. A formatter that dropped `$percent`
      // ("Divider position") would otherwise sail through, which is the
      // bug this whole change exists to fix, on the locale most users
      // are on.
      expect(
        english.resizableDividerPositionLabel(percent),
        contains('$percent'),
      );
      expect(
        korean.resizableDividerPositionLabel(percent),
        contains('$percent'),
      );
    });
  });

  // Measured before this changed: the Web picker panel carried
  // `role="dialog"` and the locale's `timePickerPopoverLabel`; the Flutter
  // panel had neither, so a screen reader entered it with no name — in any
  // locale. The label is the locale's string, never a literal.
  group('TimePicker popover accessible name comes from the locale', () {
    const english = DefaultCoUILocalizations.instance;
    const korean = KoCoUILocalizations.instance;

    Future<void> openPicker(
      WidgetTester tester,
      String label, {
      Locale? locale,
    }) async {
      await _pump(
        tester,
        const Center(child: TimePicker(value: '10:00', use24HourFormat: false)),
        locale: locale,
      );
      await tester.tap(find.byType(TimePicker));
      // Frame by frame: the panel is not in the semantics tree after one
      // large pump.
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.bySemanticsLabel(label).evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('English default', (tester) async {
      await openPicker(tester, english.timePickerPopoverLabel);

      expect(
        find.bySemanticsLabel(english.timePickerPopoverLabel),
        findsOneWidget,
      );
    });

    testWidgets('Korean', (tester) async {
      await openPicker(
        tester,
        korean.timePickerPopoverLabel,
        locale: const Locale('ko'),
      );

      expect(
        find.bySemanticsLabel(korean.timePickerPopoverLabel),
        findsOneWidget,
      );
      // The English string is not announced in a Korean app.
      expect(
        find.bySemanticsLabel(english.timePickerPopoverLabel),
        findsNothing,
      );
    });

    // Not a `testWidgets` — it pumps nothing. The two tests above read their
    // expected value from the same localizations the component reads, so a
    // `ko` that silently served the English value would still pass them.
    test('the two locales really differ', () {
      expect(
        korean.timePickerPopoverLabel,
        isNot(english.timePickerPopoverLabel),
      );
    });
  });
}
