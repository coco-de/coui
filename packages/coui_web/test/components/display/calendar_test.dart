import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kWeekdayColumnCount = 7;

List<DomComponent> _divsWithRole(ComponentTester tester, String role) => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .where((c) => c.attributes?['role'] == role)
    .toList();

// The outermost `<div>` in document order is the widget's own root — its
// role/aria-label are assembled inline in `build()` (not via
// `configureAttributes`), so they live on the rendered element rather than
// on `Calendar.componentAttributes` (which only echoes what a caller
// passed in).
DomComponent _rootDiv(ComponentTester tester) =>
    find.tag('div').evaluate().first.component as DomComponent;

void main() {
  testComponents('navigation buttons have localized accessible names', (
    tester,
  ) async {
    pumpWithTheme(tester, const Calendar());
    final names = find
        .tag('button')
        .evaluate()
        .map((e) => (e.component as DomComponent).attributes?['aria-label'])
        .whereType<String>();
    expect(names, containsAll(['Previous period', 'Next period']));
  });

  group('Calendar', () {
    testComponents('root carries no role — application removed', (
      tester,
    ) async {
      pumpWithTheme(tester, const Calendar());

      expect(_rootDiv(tester).attributes?.containsKey('role'), isFalse);
    });

    testComponents('root keeps its accessible label', (tester) async {
      pumpWithTheme(tester, const Calendar());

      expect(_rootDiv(tester).attributes?['aria-label'], isNotNull);
    });

    testComponents('date grid carries role="grid"', (tester) async {
      pumpWithTheme(tester, const Calendar());

      expect(_divsWithRole(tester, 'grid'), isNotEmpty);
    });

    testComponents('date grid rows carry role="row"', (tester) async {
      pumpWithTheme(tester, const Calendar());

      // One row for the weekday header, several more for the visible weeks.
      expect(_divsWithRole(tester, 'row').length, greaterThan(1));
    });

    testComponents('weekday header cells carry role="columnheader"', (
      tester,
    ) async {
      pumpWithTheme(tester, const Calendar());

      expect(
        _divsWithRole(tester, 'columnheader'),
        hasLength(_kWeekdayColumnCount),
      );
    });

    testComponents(
      'each day cell is wrapped by a role="gridcell" group with '
      'display:contents',
      (tester) async {
        pumpWithTheme(tester, const Calendar());

        final gridCells = _divsWithRole(tester, 'gridcell');
        expect(gridCells, isNotEmpty);
        for (final cell in gridCells) {
          expect(cell.styles?.properties['display'], contains('contents'));
        }
      },
    );
  });

  group('Calendar range band', () {
    // The inner range cells sit on the `primaryContainer` band, so their
    // text takes the foreground that pairs with that fill. A light
    // foreground (`onSecondary`) on the light band read as no text at all.
    testComponents(
      'should_paint_inner_range_text_in_the_band_foreground',
      (tester) async {
        pumpWithTheme(
          tester,
          Calendar.range(
            value: CoreCalendarValue.range(
              DateTime(2024, 3, 10),
              DateTime(2024, 3, 20),
            ),
            initialView: const CoreCalendarView(2024, 3),
          ),
        );

        final bandCells = find
            .tag('div')
            .evaluate()
            .map((e) => e.component)
            .whereType<DomComponent>()
            .where(
              (c) =>
                  (c.classes ?? '').split(' ').contains('bg-primary-container'),
            )
            .toList();

        expect(bandCells, isNotEmpty);
        final inner = bandCells.where(
          (c) => (c.classes ?? '').split(' ').contains('select-none'),
        );
        expect(inner, isNotEmpty);
        for (final cell in inner) {
          final classes = (cell.classes ?? '').split(' ');
          expect(classes, contains('text-on-primary-container'));
          expect(classes, isNot(contains('text-on-secondary')));
        }
      },
    );
  });

  group('Calendar controlled value', () {
    // `value` is a controlled field on the shared contract. Seeding it
    // once at mount left the calendar rendering whatever the user last
    // clicked, ignoring every externally-driven change — a form reset, a
    // "Today" shortcut, a programmatic clear, the host picker's value
    // moving while the panel is open. The Flutter twin has always
    // followed the caller.
    //
    // A second `pumpComponent` mounts a fresh root, which seeds itself
    // from the new value and would pass without the update path ever
    // running, so the value has to change from a parent's `setState`.
    testComponents('follows a parent-driven change', (tester) async {
      late _ValueHostState host;
      pumpWithTheme(
        tester,
        _ValueHost(
          onState: (state) => host = state,
          builder: (value) => Calendar(
            value: value,
            initialView: const CoreCalendarView(2024, 3),
          ),
        ),
      );
      expect(_isDaySelected(tester, '15'), isTrue);

      host.setValue(CoreCalendarValue.single(DateTime(2024, 3, 20)));
      await tester.pump();

      expect(_isDaySelected(tester, '20'), isTrue);
      expect(_isDaySelected(tester, '15'), isFalse);
    });

    testComponents('follows a parent-driven clear', (tester) async {
      late _ValueHostState host;
      pumpWithTheme(
        tester,
        _ValueHost(
          onState: (state) => host = state,
          builder: (value) => Calendar(
            value: value,
            initialView: const CoreCalendarView(2024, 3),
          ),
        ),
      );

      host.setValue(null);
      await tester.pump();

      expect(_isDaySelected(tester, '15'), isFalse);
    });
  });
  group('Calendar markers', () {
    CoreCalendarMarker? markerFor(DateTime date) => switch (date) {
      DateTime(year: 2024, month: 3, day: 10) => const CoreCalendarMarker(),
      DateTime(year: 2024, month: 3, day: 15) => const CoreCalendarMarker(
        count: 2,
        semanticsLabel: '2 vaccinations due',
      ),
      DateTime(year: 2024, month: 3, day: 20) => const CoreCalendarMarker(
        count: 7,
      ),
      _ => null,
    };

    testComponents('should_draw_no_marker_when_builder_is_null', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Calendar(initialView: CoreCalendarView(2024, 3)),
      );

      expect(_markerRows(tester), isEmpty);
    });

    testComponents('should_draw_one_dot_per_item_up_to_the_cap', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          initialView: const CoreCalendarView(2024, 3),
          markerBuilder: markerFor,
        ),
      );

      final rows = _markerRows(tester);
      expect(rows, hasLength(3));
      expect(_dotCount(tester, '10'), 1);
      expect(_dotCount(tester, '15'), 2);
      expect(_dotCount(tester, '20'), CoreCalendarStyle.defaultMarkerMaxCount);
    });

    testComponents('should_honour_a_style_override_of_the_cap', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          initialView: const CoreCalendarView(2024, 3),
          markerBuilder: markerFor,
          calendarStyle: const CoreCalendarStyle(markerMaxCount: 5),
        ),
      );

      expect(_dotCount(tester, '20'), 5);
    });

    testComponents('should_put_the_marker_label_inside_the_day_button', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          initialView: const CoreCalendarView(2024, 3),
          markerBuilder: markerFor,
        ),
      );

      // The caller's label and, without one, the localized full count both
      // ride a visually hidden span inside the button, so they join its
      // accessible name.
      for (final label in ['2 vaccinations due', '7 items', '1 item']) {
        final spanClasses = find
            .ancestor(of: find.text(label), matching: find.tag('span'))
            .evaluate()
            .map((e) => (e.component as DomComponent).classes ?? '');
        expect(spanClasses, contains(contains('sr-only')));
        expect(
          find.ancestor(of: find.text(label), matching: find.tag('button')),
          findsOneComponent,
        );
      }
    });

    testComponents('should_keep_the_dots_out_of_the_pointer_path', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          initialView: const CoreCalendarView(2024, 3),
          markerBuilder: markerFor,
        ),
      );

      for (final row in _markerRows(tester)) {
        expect(row.classes, contains('pointer-events-none'));
      }
    });

    testComponents(
      'should_paint_the_selection_fill_dot_colour_across_a_range',
      (tester) async {
        pumpWithTheme(
          tester,
          Calendar.range(
            value: CoreCalendarValue.range(
              DateTime(2024, 3, 10),
              DateTime(2024, 3, 20),
            ),
            initialView: const CoreCalendarView(2024, 3),
            markerBuilder: markerFor,
          ),
        );

        // Endpoints are hand-drawn range cells; the label span still lands
        // inside them, and their dots take the selected fill.
        expect(_dotClasses(tester, '10'), contains('bg-on-primary'));
        expect(_dotClasses(tester, '20'), contains('bg-on-primary'));
        // Inside the range the band's foreground, not the default fill.
        expect(_dotClasses(tester, '15'), contains('bg-on-primary-container'));
      },
    );

    testComponents('should_prefer_the_marker_colour_off_selection', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Calendar(
          initialView: const CoreCalendarView(2024, 3),
          value: CoreCalendarValue.single(DateTime(2024, 3, 15)),
          markerBuilder: (date) =>
              date.month == 3 && (date.day == 15 || date.day == 11)
              ? const CoreCalendarMarker(
                  color: CoreColor.token(CoreColors.error),
                )
              : null,
        ),
      );

      expect(_dotClasses(tester, '11'), contains('bg-error'));
      expect(_dotClasses(tester, '15'), contains('bg-on-primary'));
    });
  });
}

/// Every marker dot row in the grid — the only `aria-hidden` divs the
/// calendar renders.
List<DomComponent> _markerRows(ComponentTester tester) => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .where((c) => c.attributes?['aria-hidden'] == 'true')
    .toList();

/// The marker wrapper (`relative inline-flex`) around day-of-month [day].
Finder _markerRoot(String day) => find
    .ancestor(of: find.text(day), matching: find.tag('div'))
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .where((c) => c.classes == 'relative inline-flex')
    .map((c) => find.byComponent(c))
    .first;

/// The dots drawn for day-of-month [day].
List<DomComponent> _dots(ComponentTester tester, String day) {
  final row = find
      .descendant(of: _markerRoot(day), matching: find.tag('div'))
      .evaluate()
      .map((e) => e.component)
      .whereType<DomComponent>()
      .firstWhere((c) => c.attributes?['aria-hidden'] == 'true');
  return find
      .descendant(of: find.byComponent(row), matching: find.tag('div'))
      .evaluate()
      .map((e) => e.component as DomComponent)
      .toList();
}

int _dotCount(ComponentTester tester, String day) => _dots(tester, day).length;

String _dotClasses(ComponentTester tester, String day) =>
    _dots(tester, day).first.classes ?? '';

/// Whether the grid cell for day-of-month [day] renders as selected.
/// A selected day is the only one whose button carries the primary
/// variant's background class.
bool _isDaySelected(ComponentTester tester, String day) {
  final cell =
      find
              .ancestor(of: find.text(day), matching: find.tag('button'))
              .first
              .evaluate()
              .single
              .component
          as DomComponent;

  return cell.classes?.contains('bg-primary') ?? false;
}

/// Rebuilds its child in place so the child reaches `didUpdateComponent`.
class _ValueHost extends StatefulComponent {
  const _ValueHost({required this.builder, required this.onState});

  final Component Function(CoreCalendarValue? value) builder;
  final void Function(_ValueHostState state) onState;

  @override
  State<_ValueHost> createState() => _ValueHostState();
}

class _ValueHostState extends State<_ValueHost> {
  CoreCalendarValue? value = CoreCalendarValue.single(DateTime(2024, 3, 15));

  void setValue(CoreCalendarValue? next) => setState(() => value = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(value);
  }
}
