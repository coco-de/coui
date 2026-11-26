import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Date test constants.
const _kStartYear = 2024;
const _kStartMonth = 1;
const _kStartDay = 1;
const _kEndYear = 2024;
const _kEndMonth = 12;
const _kEndDay = 31;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
  localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
);

/// A harness whose [Theme] sits *above* the navigator, so a route pushed
/// by `showDialog` (which targets the root navigator) still finds it.
/// The plain `home:`-nested harness above cannot reach dialog content.
Widget _buildRootThemedApp(Widget child) => material.MaterialApp(
  builder: (context, navigatorChild) =>
      Theme(data: const ThemeData(), child: navigatorChild ?? const SizedBox()),
  home: child,
  localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
);

void main() {
  group('DateTimeRange', () {
    group('constructor', () {
      test('creates with start and end dates', () {
        final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range = DateTimeRange(start, end);

        expect(range.start, equals(start));
        expect(range.end, equals(end));
      });
    });

    group('copyWith', () {
      test('returns DateTimeRange instance from copyWith', () {
        final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range = DateTimeRange(start, end);

        expect(range.copyWith(), isA<DateTimeRange>());
      });

      test('copyWith with explicit start preserves type', () {
        final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range = DateTimeRange(start, end);
        final newStart = DateTime(_kStartYear, 6, 1);
        final copied = range.copyWith(start: () => newStart);

        expect(copied, isA<DateTimeRange>());
      });
    });

    group('equality', () {
      test('two identical ranges are equal', () {
        final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range1 = DateTimeRange(start, end);
        final range2 = DateTimeRange(start, end);

        expect(range1, equals(range2));
      });

      test('different start makes ranges unequal', () {
        final start1 = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final start2 = DateTime(_kStartYear, 6, 1);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range1 = DateTimeRange(start1, end);
        final range2 = DateTimeRange(start2, end);

        expect(range1, isNot(equals(range2)));
      });
    });

    group('hashCode', () {
      test('identical ranges have same hashCode', () {
        final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
        final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
        final range1 = DateTimeRange(start, end);
        final range2 = DateTimeRange(start, end);

        expect(range1.hashCode, equals(range2.hashCode));
      });
    });

    test('toString returns descriptive string', () {
      final start = DateTime(_kStartYear, _kStartMonth, _kStartDay);
      final end = DateTime(_kEndYear, _kEndMonth, _kEndDay);
      final range = DateTimeRange(start, end);

      expect(range.toString(), contains('DateTimeRange'));
    });
  });

  group('DatePickerController', () {
    test('creates with null initial value', () {
      final controller = DatePickerController(null);

      expect(controller.value, isNull);
    });

    test('creates with initial DateTime value', () {
      final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);
      final controller = DatePickerController(date);

      expect(controller.value, equals(date));
    });

    test('updates value and notifies listeners', () {
      final controller = DatePickerController(null);
      var notified = false;
      void handleNotify() => notified = true;
      controller.addListener(handleNotify);

      controller.value = DateTime(_kStartYear, _kStartMonth, _kStartDay);

      expect(notified, isTrue);
      controller.dispose();
    });
  });

  group('DatePicker widget', () {
    testWidgets('renders with key parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DatePicker(
            key: Key('date_picker'),
            value: null,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('date_picker')), findsOneWidget);
    });

    testWidgets('renders with null value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DatePicker(value: null),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(DatePicker), findsOneWidget);
    });

    testWidgets('renders with a date value', (tester) async {
      final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);

      await tester.pumpWidget(
        _buildApp(
          DatePicker(value: date),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(DatePicker), findsOneWidget);
    });

    testWidgets('renders with placeholder', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DatePicker(
            placeholder: 'Pick a date',
            value: null,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Pick a date'), findsOneWidget);
    });

    testWidgets('renders disabled state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DatePicker(
            enabled: false,
            value: null,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(DatePicker), findsOneWidget);
    });
  });

  group('the disabled value colour belongs to the trigger field', () {
    // The trigger is a read-only `TextField`, which already states its own
    // disabled foreground. The picker's `contentColor` is an enabled value
    // colour: painted for an enabled picker — in error too, since an error
    // changes the trigger's edge and ring and leaves the text alone — and
    // left out for disabled so the field's own answer shows through. "No
    // value" (placeholder colour) is a different state and is not a
    // stand-in for disabled.
    final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);
    // `error` rather than `primary`: in the default palette `primary` is
    // the same near-black as `onSurface`, and the enabled assertion must be
    // able to tell the two apart.
    const contentColor = CoreColor.token(CoreColors.error);
    const styled = CoreDatePickerStyle(contentColor: contentColor);
    // For the error-state test: `contentColor` above is deliberately the
    // same `error` token the error edge uses, so it cannot tell "the
    // picker painted its override" apart from "the text was turned
    // `error`". This second override is a colour the error look never is.
    const distinctFromError = CoreColor.token(CoreColors.primary);
    const styledDistinct = CoreDatePickerStyle(contentColor: distinctFromError);
    // The default placeholder (`placeholder`) and a disabled label
    // (`disabledContent`) resolve to the same neutral in light, so the
    // "not the placeholder" claim needs a placeholder that is its own
    // colour to be able to fail.
    const distinctPlaceholder = CoreColor.token(CoreColors.tertiary);
    const styledDistinctPlaceholder = CoreDatePickerStyle(
      contentColor: contentColor,
      placeholderColor: distinctPlaceholder,
    );
    // `enabled` is derived from the callback when not stated
    // (`enabled ?? onChanged != null`), so "enabled" means "has one".
    void onChanged(DateTime? _) {}

    // What actually paints: the editable's own text style colour.
    Color paintedValueColor(WidgetTester tester) => tester
        .widget<material.EditableText>(
          find.descendant(
            of: find.byType(TextField),
            matching: find.byType(material.EditableText),
          ),
        )
        .style
        .color!;

    Color resolve(WidgetTester tester, CoreColor token) {
      final context = tester.element(find.byType(DatePicker));
      return Theme.of(context).colorScheme.resolve(token).toValue();
    }

    testWidgets('enabled paints contentColor', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DatePicker(
            onChanged: onChanged,
            value: date,
            datePickerStyle: styled,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final painted = paintedValueColor(tester);
      expect(painted, resolve(tester, contentColor));
      expect(
        painted,
        isNot(resolve(tester, const CoreColor.token(CoreColors.onSurface))),
      );
    });

    testWidgets(
      'disabled paints the field disabled tone — not contentColor, '
      'not placeholderColor',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            DatePicker(
              onChanged: onChanged,
              value: date,
              enabled: false,
              datePickerStyle: styledDistinctPlaceholder,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final painted = paintedValueColor(tester);
        expect(painted, isNot(resolve(tester, contentColor)));
        expect(painted, isNot(resolve(tester, distinctPlaceholder)));
      },
    );

    testWidgets(
      'error (enabled) paints contentColor like any enabled picker — the '
      'text is not turned error',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            DatePicker(
              onChanged: onChanged,
              value: date,
              errorText: 'Pick a valid date',
              datePickerStyle: styledDistinct,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final painted = paintedValueColor(tester);
        expect(painted, resolve(tester, distinctFromError));
        expect(painted, isNot(resolve(tester, contentColor)));
      },
    );

    testWidgets('the resolver folds the colour into the field, enabled only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          DatePicker(
            onChanged: onChanged,
            value: date,
            datePickerStyle: styled,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final context = tester.element(find.byType(DatePicker));
      final enabled = resolveDatePicker(context, datePickerStyle: styled);
      final disabled = resolveDatePicker(
        context,
        datePickerStyle: styled,
        enabled: false,
      );
      expect(enabled.triggerStyle.valueStyle?.color, contentColor);
      // Disabled leaves the colours out so the field's disabled tone applies.
      expect(disabled.triggerStyle.valueStyle, isNull);
      expect(disabled.triggerStyle.placeholderStyle, isNull);
      expect(disabled.customValueTextStyle.color, isNull);
      expect(enabled.customValueTextStyle.color, resolve(tester, contentColor));
    });
  });

  group('DatePicker with placeholder', () {
    testWidgets('renders with string placeholder', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DatePicker(
            onChanged: (_) {},
            placeholder: 'Select date',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(DatePicker), findsOneWidget);
      expect(find.text('Select date'), findsOneWidget);
    });

    testWidgets('renders with popover mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DatePicker(
            onChanged: (_) {},
            placeholder: 'Pick a date',
            mode: .popover,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(DatePicker), findsOneWidget);
    });
  });

  group('ControlledDatePicker widget', () {
    testWidgets('renders with key parameter', (tester) async {
      final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);

      await tester.pumpWidget(
        _buildApp(
          ControlledDatePicker(
            key: const Key('controlled_date'),
            initialValue: date,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('controlled_date')), findsOneWidget);
    });

    testWidgets('renders with controller that has a date value', (
      tester,
    ) async {
      final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);
      final controller = DatePickerController(date);

      await tester.pumpWidget(
        _buildApp(
          ControlledDatePicker(controller: controller),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ControlledDatePicker), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders with initialValue', (tester) async {
      final date = DateTime(_kStartYear, _kStartMonth, _kStartDay);

      await tester.pumpWidget(
        _buildApp(
          ControlledDatePicker(initialValue: date),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ControlledDatePicker), findsOneWidget);
    });
  });

  group('firstDayOfWeek reaches the calendar the picker opens', () {
    // The pickers own no calendar of their own: each builds a `Calendar` in
    // a popover or a dialog and hands it the props it was given. A week
    // start declared on the picker and not handed on would leave the
    // calendar on Sunday while the field claimed otherwise.
    //
    // Both surfaces are checked because they are separate construction
    // sites: the popover content and the dialog content are built by
    // different methods.
    Future<void> openPopover(WidgetTester tester, Finder trigger) async {
      await tester.tap(trigger);
      // The panel mounts through a post-frame callback; pump until the
      // calendar exists so a short frame budget cannot read as a failure of
      // the thing under test.
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(Calendar).evaluate().isNotEmpty) break;
      }
    }

    int weekStartOf(WidgetTester tester) =>
        tester.widget<Calendar>(find.byType(Calendar).first).firstDayOfWeek;

    testWidgets('DatePicker in a dialog', (tester) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          DatePicker(
            firstDayOfWeek: DateTime.monday,
            mode: CorePromptMode.dialog,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DatePicker));
      await tester.pumpAndSettle();

      expect(weekStartOf(tester), DateTime.monday);
    });

    testWidgets('DatePicker in a popover', (tester) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          material.Scaffold(
            body: material.Center(
              child: DatePicker(
                firstDayOfWeek: DateTime.saturday,
                mode: CorePromptMode.popover,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await openPopover(tester, find.byType(DatePicker));

      expect(weekStartOf(tester), DateTime.saturday);
    });

    testWidgets('DateRangePicker in a dialog', (tester) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          DateRangePicker(
            value: null,
            firstDayOfWeek: DateTime.monday,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();

      expect(weekStartOf(tester), DateTime.monday);
    });

    testWidgets('DateRangePicker in a popover', (tester) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          material.Scaffold(
            body: material.Center(
              child: DateRangePicker(
                value: null,
                firstDayOfWeek: DateTime.saturday,
                mode: CorePromptMode.popover,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await openPopover(tester, find.byType(DateRangePicker));

      expect(weekStartOf(tester), DateTime.saturday);
    });

    testWidgets('ControlledDatePicker', (tester) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          material.Scaffold(
            body: material.Center(
              child: ControlledDatePicker(
                firstDayOfWeek: DateTime.monday,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await openPopover(tester, find.byType(DatePicker));

      expect(weekStartOf(tester), DateTime.monday);
    });

    testWidgets('a picker that states none opens a Sunday-first calendar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRootThemedApp(
          DatePicker(mode: CorePromptMode.dialog, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DatePicker));
      await tester.pumpAndSettle();

      expect(weekStartOf(tester), DateTime.sunday);
    });

    test('a week start outside Monday..Sunday is rejected', () {
      expect(
        () => DatePicker(firstDayOfWeek: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DateRangePicker(value: null, firstDayOfWeek: 8),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith carries and replaces the week start', () {
      const picker = DatePicker(firstDayOfWeek: DateTime.monday);

      expect(picker.copyWith().firstDayOfWeek, DateTime.monday);
      expect(
        picker.copyWith(firstDayOfWeek: DateTime.friday).firstDayOfWeek,
        DateTime.friday,
      );
    });
  });

  group('DatePicker dialog outcome', () {
    // Backing out of the prompt is not a choice, but it used to be
    // reported as one. `Navigator.pop()` with no result and
    // `Navigator.pop(null)` are the same value, so Cancel — and a
    // barrier tap, and a system back — arrived at the caller as
    // `onChanged(null)` and wiped the committed date.
    //
    // The clear path has to survive that fix, which is why the outcome
    // is wrapped rather than null-guarded: tapping the selected day
    // deselects it, so Save-with-nothing-selected is a real clear.
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byType(DatePicker));
      await tester.pumpAndSettle();
    }

    testWidgets('Cancel leaves the committed date alone', (tester) async {
      final calls = <DateTime?>[];
      await tester.pumpWidget(
        _buildRootThemedApp(
          DatePicker(
            value: DateTime(_kStartYear, _kStartMonth, _kStartDay),
            mode: CorePromptMode.dialog,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.tap(
        find.text(DefaultCoUILocalizations.instance.buttonCancel),
      );
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('dismissing the barrier leaves the committed date alone', (
      tester,
    ) async {
      final calls = <DateTime?>[];
      await tester.pumpWidget(
        _buildRootThemedApp(
          DatePicker(
            value: DateTime(_kStartYear, _kStartMonth, _kStartDay),
            mode: CorePromptMode.dialog,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('Save still reports, including a deliberate clear', (
      tester,
    ) async {
      final calls = <DateTime?>[];
      await tester.pumpWidget(
        _buildRootThemedApp(
          DatePicker(
            mode: CorePromptMode.dialog,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Nothing was ever selected, so Save commits "no date" — which the
      // caller must hear, and which is indistinguishable from Cancel if
      // the outcome travels as a bare null.
      await tester.tap(find.text(DefaultCoUILocalizations.instance.buttonSave));
      await tester.pumpAndSettle();

      expect(calls, equals(<DateTime?>[null]));
    });
  });

  group('DateRangePicker dialog outcome', () {
    // The range picker defaults to `dialog` mode, so it carried the same
    // defect without any caller opting in.
    testWidgets('Cancel leaves the committed range alone', (tester) async {
      final calls = <DateTimeRange?>[];
      await tester.pumpWidget(
        _buildRootThemedApp(
          DateRangePicker(
            value: DateTimeRange(
              DateTime(_kStartYear, _kStartMonth, _kStartDay),
              DateTime(_kEndYear, _kEndMonth, _kEndDay),
            ),
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(DefaultCoUILocalizations.instance.buttonCancel),
      );
      await tester.pumpAndSettle();

      // The two-month range calendar fits the 640 dialog panel, so opening
      // and cancelling reports nothing.
      expect(tester.takeException(), isNull);
      expect(calls, isEmpty);
    });
  });
  group('the trigger wears the shared input look', () {
    // The trigger is a read-only `TextField` at its `md` rung: height 40,
    // corner 10 (the row's 0.25), an `outlineVariant` edge, filling the width
    // its parent gives it. The picker adds only the error edge — `error`
    // while invalid; the focus edge is the field's own `primary`.
    Future<void> pumpIn(WidgetTester tester, Widget picker) async {
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: material.Alignment.topCenter,
            child: material.SizedBox(width: 320, child: picker),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is 40 tall with a 10 corner and an outlineVariant edge', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15)),
      );

      expect(tester.getSize(find.byType(TextField)).height, 40);
      final decorated = tester.widgetList<material.DecoratedBox>(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(material.DecoratedBox),
        ),
      );
      final scheme = Theme.of(
        tester.element(find.byType(DatePicker)),
      ).colorScheme;
      final variant = scheme
          .resolve(const CoreColor.token(CoreColors.outlineVariant))
          .toValue();
      final edges = decorated
          .map((d) => d.decoration)
          .whereType<material.BoxDecoration>()
          .where((d) => d.border != null)
          .toList();
      expect(edges, isNotEmpty);
      expect(
        edges.any(
          (d) =>
              d.borderRadius == material.BorderRadius.circular(10) &&
              (d.border! as material.Border).top.color == variant,
        ),
        isTrue,
      );
    });

    testWidgets('fills the width its parent gives it — single and range', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15)),
      );
      expect(tester.getSize(find.byType(TextField)).width, 320);

      // An empty picker fills too — it does not hug the placeholder.
      await pumpIn(tester, DatePicker(onChanged: (_) {}));
      expect(tester.getSize(find.byType(TextField)).width, 320);

      await pumpIn(
        tester,
        DateRangePicker(
          value: DateTimeRange(DateTime(2024, 3, 15), DateTime(2024, 3, 20)),
          onChanged: (_) {},
        ),
      );
      expect(tester.getSize(find.byType(TextField)).width, 320);
    });

    testWidgets('the value is a Regular 14 — not the Button label role', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15)),
      );

      final style = tester
          .widget<material.EditableText>(
            find.descendant(
              of: find.byType(TextField),
              matching: find.byType(material.EditableText),
            ),
          )
          .style;
      expect(style.fontSize, 14);
      expect(style.fontWeight, material.FontWeight.w400);
    });

    testWidgets('the calendar glyph sits in the suffix seat at 16', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15)),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.suffix, isA<Icon>());
      expect((field.suffix! as Icon).iconStyle?.size, CoreIconSize.size16);
    });

    testWidgets('focus edge is primary, error is error', (tester) async {
      await tester.pumpWidget(
        _buildApp(DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15))),
      );
      final context = tester.element(find.byType(DatePicker));
      final resolved = resolveDatePicker(context);
      const primary = CoreColor.token(CoreColors.primary);
      const error = CoreColor.token(CoreColors.error);

      // The focus edge is the trigger field's own row; the picker states
      // none of it.
      final field = resolveTextField(
        context,
        hasError: false,
        enabled: true,
        size: CoreComponentSize.md,
        textFieldStyle: resolved.triggerStyle,
      );
      expect(field.focusOutlineStyle.borderColor, primary);
      final inError = resolveTextField(
        context,
        hasError: true,
        enabled: true,
        size: CoreComponentSize.md,
        textFieldStyle: resolved.triggerStyle,
      );
      expect(inError.focusOutlineStyle.borderColor, error);
      expect(resolved.triggerStyle.errorBorderColor, error);
    });

    testWidgets('a range builder widget takes the field placeholder seat', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DateRangePicker(
          value: DateTimeRange(DateTime(2024, 3, 15), DateTime(2024, 3, 20)),
          onChanged: (_) {},
          builder: (context, range) => const Text('custom range'),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      // A widget cannot be the field's text value, so the value stays empty
      // and the widget is shown in the placeholder seat.
      expect(field.value, '');
      expect(find.text('custom range'), findsOneWidget);
      expect(find.text('2024-03-15 - 2024-03-20'), findsNothing);
    });

    testWidgets('a custom placeholderWidget replaces the placeholder text', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(
          onChanged: (_) {},
          placeholderWidget: const Text('pick one'),
        ),
      );

      expect(find.text('pick one'), findsOneWidget);
    });

    testWidgets('tapping the field opens the popover calendar', (
      tester,
    ) async {
      await pumpIn(
        tester,
        DatePicker(onChanged: (_) {}, value: DateTime(2024, 3, 15)),
      );
      expect(find.byType(Calendar), findsNothing);

      await tester.tap(find.byType(TextField));
      // Not `pumpAndSettle`: the focused field keeps a ring animating.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Calendar), findsOneWidget);
    });
  });
}
