import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart' hide Icon, FormField;
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 900, child: child)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

Iterable<SemanticsProperties> _properties(WidgetTester tester, Finder of) =>
    tester
        .widgetList<Semantics>(
          find.descendant(of: of, matching: find.byType(Semantics)),
        )
        .map((w) => w.properties);

void main() {
  group('a two-month range calendar is named', () {
    testWidgets('the range layout carries the label too', (tester) async {
      // The range layout returned before the wrapper that names the
      // component, so a range calendar reached a screen reader as an
      // unnamed pile of buttons. The comment above the wrapper claimed
      // parity with the Web twin, which labels both layouts.
      await _pump(
        tester,
        Calendar(
          selectionMode: CoreCalendarSelectionMode.range,
          onChanged: (_) {},
        ),
      );

      expect(
        _properties(
          tester,
          find.byType(Calendar),
        ).map((p) => p.label).whereType<String>(),
        isNotEmpty,
      );
    });
  });

  group('a decorative card is not a disabled button', () {
    testWidgets('a card with no onPressed announces no button', (
      tester,
    ) async {
      // Wrapping it in a `Button` regardless made it announce as a
      // *disabled* button — a decorative image card read out as
      // something the user could have used but was not allowed to, which
      // is worse than saying nothing.
      await _pump(
        tester,
        const CardImage(image: SizedBox.shrink(), title: Text('Cover')),
      );

      expect(find.byType(Button), findsNothing);
    });

    testWidgets('and a pressable one still is a button', (tester) async {
      await _pump(
        tester,
        CardImage(
          onPressed: () {},
          image: const SizedBox.shrink(),
          title: const Text('Cover'),
        ),
      );

      expect(find.byType(Button), findsWidgets);
    });
  });

  group('carousel navigation stays in the semantics tree', () {
    testWidgets('the buttons are readable while not hovered', (tester) async {
      // `AnimatedOpacity` drops a fully transparent subtree out of the
      // semantics tree by default, so the labelled buttons existed for a
      // screen reader only while a pointer rested on the carousel — on a
      // touch device, never. They stayed hit-testable throughout, so the
      // comment claiming they were "readable by screen readers" was half
      // right, and the wrong half was the half nobody could see.
      //
      // Asserted against the rendered semantics rather than the widget's
      // flag: the exclusion happens at render time, so inspecting the
      // widget tree would show the `Semantics` node either way and prove
      // nothing.
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        const Carousel(
          transition: CoreCarouselTransition.sliding(),
          items: [Text('One'), Text('Two')],
        ),
      );

      expect(
        find.bySemanticsLabel(
          DefaultCoUILocalizations.instance.carouselPreviousSlide,
        ),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('a form field is one thing, not four', () {
    testWidgets('the group carries its label and its description', (
      tester,
    ) async {
      // Label, input, description and error were siblings in a column
      // with nothing joining them: what a sighted user reads as one
      // field, a screen reader read as unrelated fragments.
      await _pump(
        tester,
        const FormField(
          label: 'Delivery address',
          description: 'Street and number',
          child: SizedBox.shrink(),
        ),
      );

      final grouped = _properties(tester, find.byType(FormField)).where(
        (p) => p.label == 'Delivery address',
      );

      expect(grouped, isNotEmpty);
      expect(grouped.first.hint, 'Street and number');
    });

    testWidgets('and the error replaces the description once it appears', (
      tester,
    ) async {
      await _pump(
        tester,
        const FormField(
          label: 'Delivery address',
          description: 'Street and number',
          error: 'Required',
          child: SizedBox.shrink(),
        ),
      );

      final grouped = _properties(tester, find.byType(FormField)).where(
        (p) => p.label == 'Delivery address',
      );

      expect(grouped.first.hint, 'Required');
    });

    testWidgets('a disabled field says it is disabled', (tester) async {
      // Disabling only blocked the pointer, so a disabled field
      // announced as an ordinary one that silently did nothing.
      await _pump(
        tester,
        const FormField(
          label: 'Delivery address',
          enabled: false,
          child: SizedBox.shrink(),
        ),
      );

      final grouped = _properties(tester, find.byType(FormField)).where(
        (p) => p.label == 'Delivery address',
      );

      expect(grouped.first.enabled, isFalse);
    });
  });

  group('a comparison split reports where it is', () {
    testWidgets('an interactive diff is a slider with a value', (
      tester,
    ) async {
      // The arrow keys moved the split and nothing announced that it had
      // moved, or where it landed. The control existed only for people
      // who could see it.
      await _pump(
        tester,
        const Diff(before: Text('A'), after: Text('B')),
      );

      final slider = _properties(
        tester,
        find.byType(Diff),
      ).where((p) => p.slider ?? false);

      expect(slider, isNotEmpty);
      expect(slider.first.value, isNotNull);
    });

    testWidgets('and a static one is not', (tester) async {
      // A slider that never moves is a promise of a control that is not
      // there.
      await _pump(
        tester,
        const Diff(
          interactive: false,
          before: Text('A'),
          after: Text('B'),
        ),
      );

      expect(
        _properties(tester, find.byType(Diff)).any((p) => p.slider ?? false),
        isFalse,
      );
    });
  });
}
