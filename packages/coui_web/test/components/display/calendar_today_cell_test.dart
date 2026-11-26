// The today cell is a ghost cell marked by a line: the Web resolver forwards
// the calendar's `todayBorder*` to the cell `Button` (the Flutter resolver
// reads the same fields).

import 'package:coui_web/coui_web.dart';
// Resolver-level assertion — the style file is not on the barrel.
import 'package:coui_web/src/components/display/calendar/calendar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

CoreButtonStyle _today(ComponentTester tester, [CoreCalendarStyle? style]) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveCalendar(context, calendarStyle: style).dateCellTodayStyle;
}

void main() {
  group('Calendar today cell', () {
    testComponents('is outlined by the calendar defaults', (tester) async {
      final today = _today(tester);
      expect(today.borderColor, CoreCalendarStyle.defaultTodayBorderColor);
      expect(today.borderWidth, CoreCalendarStyle.defaultTodayBorderWidth);
    });

    testComponents('takes the border a caller states', (tester) async {
      final today = _today(
        tester,
        const CoreCalendarStyle(
          todayBorderColor: CoreColor.token(CoreColors.primary),
          todayBorderWidth: 2,
        ),
      );
      expect(today.borderColor, const CoreColor.token(CoreColors.primary));
      expect(today.borderWidth, 2);
    });
  });

  // #5881 — the date labels' role, weight and colour, read off the DOM the
  // calendar renders (the Flutter twin reads the painted spans).
  group('Calendar #5881 labels', () {
    // The DOM ancestors of day [day]'s text, nearest first.
    List<DomComponent> ancestors(String day) => [
      for (final tag in const ['span', 'button', 'div'])
        ...find
            .ancestor(of: find.text(day).first, matching: find.tag(tag))
            .evaluate()
            .map((e) => e.component)
            .whereType<DomComponent>(),
    ];

    // The nearest ancestor of [day] whose classes carry the bodySmall role
    // — the element that paints the label.
    DomComponent labelOf(String day) => ancestors(
      day,
    ).firstWhere((c) => (c.classes ?? '').contains('text-body-small'));

    testComponents('today labels SemiBold in primary', (tester) async {
      final today = _today(tester).labelStyle!;
      expect(today.token, CoreTextStyles.bodySmall);
      expect(today.fontWeight, CoreFontWeight.semiBold);
      expect(today.color, const CoreColor.token(CoreColors.primary));
    });

    testComponents('today renders SemiBold in primary', (tester) async {
      final now = DateTime.now();
      pumpWithTheme(
        tester,
        Calendar(initialView: CoreCalendarView(now.year, now.month)),
      );
      // A neighbouring month can draw the same number; today's is the one
      // marked.
      final labels = [
        for (final occurrence in find.text('${now.day}').evaluate())
          for (final tag in const ['span', 'button', 'div'])
            ...find
                .ancestor(
                  of: find.byElementPredicate((e) => e == occurrence),
                  matching: find.tag(tag),
                )
                .evaluate()
                .map((e) => e.component)
                .whereType<DomComponent>()
                .where(
                  (c) => (c.classes ?? '').contains('text-body-small'),
                )
                .take(1),
      ];
      expect(
        labels.any(
          (c) =>
              (c.classes ?? '').contains('text-primary') &&
              c.styles?.properties['font-weight'] == '600',
        ),
        isTrue,
      );
    });

    testComponents('a selected date renders Medium in onPrimary', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          value: CoreCalendarValue.single(DateTime(2024, 3, 15)),
          initialView: const CoreCalendarView(2024, 3),
        ),
      );
      final label = labelOf('15');
      expect(label.classes, contains('text-on-primary'));
      expect(label.styles?.properties['font-weight'], '500');
      // A plain date states no weight over the role.
      expect(labelOf('16').styles?.properties['font-weight'], isNull);
    });

    testComponents('range endpoints render Medium onPrimary over the band', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar.range(
          value: CoreCalendarValue.range(
            DateTime(2024, 3, 12),
            DateTime(2024, 3, 14),
          ),
          initialView: const CoreCalendarView(2024, 3),
        ),
      );
      for (final day in ['12', '14']) {
        final pill = labelOf(day);
        expect(pill.classes, contains('text-on-primary'));
        expect(pill.classes, contains('bg-primary'));
        expect(pill.styles?.properties['font-weight'], '500');
      }
      // The inner date keeps the cell role at its default weight.
      final inner = labelOf('13');
      expect(inner.classes, contains('bg-primary-container'));
      expect(inner.styles?.properties['font-weight'], isNull);
    });

    testComponents('the month title takes labelMedium', (tester) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((c) => context = c));
      final title = resolveCalendar(context).headerButtonStyle.labelStyle;
      expect(title?.token, CoreTextStyles.labelMedium);
    });
  });
}
