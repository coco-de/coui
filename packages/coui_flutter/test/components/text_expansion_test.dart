import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

String _long(String text) => CorePseudoLocale.expand(text);

/// A locale whose chrome strings came out longer than English.
///
/// Extends the shipped default rather than the interface, which the
/// locale rule forbids for a *shipped* locale — the compiler has to
/// force a real translation to answer every member. This one wants the
/// opposite: it takes the English string and stretches it, so inheriting
/// is the point, and it never reaches the registry or `supportedLocales`.
class _ExpandedLocalizations extends DefaultCoUILocalizations {
  const _ExpandedLocalizations();

  @override
  String getAbbreviatedWeekday(int weekday) =>
      _long(super.getAbbreviatedWeekday(weekday));

  @override
  String getAbbreviatedMonth(int month) =>
      _long(super.getAbbreviatedMonth(month));
}

class _ExpandedLocalizationsDelegate
    extends LocalizationsDelegate<CoUILocalizations> {
  const _ExpandedLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CoUILocalizations> load(Locale locale) =>
      SynchronousFuture(const _ExpandedLocalizations());

  @override
  bool shouldReload(_ExpandedLocalizationsDelegate old) => false;
}

/// Every rendered string that is cut off without the component having
/// said that it would be.
///
/// Two halves, and both are needed. A box narrower than the text's own
/// intrinsic width is cutting it off — read intrinsic width rather than
/// laid-out width, because the laid-out width is whatever the box
/// permitted and so looks correct no matter how much was lost. Then
/// discount the ones that declared an overflow behaviour: a cell that
/// ellipsizes is not fitting either, but it said so, and a grid cell
/// holding an arbitrary locale string cannot promise to fit.
///
/// What is left is the case with no answer at all — the default clip,
/// which severs a glyph mid-stroke and reports nothing.
List<String> _silentlyCutOff(WidgetTester tester) {
  final cut = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final text = widget.data;
    if (text == null || text.isEmpty) continue;
    final declared = widget.overflow;
    if (declared != null && declared != TextOverflow.clip) continue;
    final box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    if (box.getMaxIntrinsicWidth(double.infinity) > box.size.width + 0.5) {
      cut.add(text);
    }
  }

  return cut;
}

/// Renders [child] in a box the width of a phone and reports whether
/// anything overflowed.
///
/// Overflow is a thrown `FlutterError` in a test, so this is a real
/// gate rather than a screenshot someone has to look at. The width is
/// fixed on purpose: a layout that only holds its text because the test
/// gave it the whole desktop has not been asked the question.
Future<Object?> _overflow(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 360, child: child)),
    ),
  );
  await tester.pumpAndSettle();

  return tester.takeException();
}

void main() {
  group('a label that grew in translation still fits', () {
    // Korean, the only non-default locale, runs about half the length
    // of its English source — so every layout here has only ever been
    // shown text that shrank. These are the same components with text
    // that grew instead.
    final cases = <String, Widget Function()>{
      'Button': () => Button(
        onPressed: () {},
        child: Text(_long('Save changes')),
      ),
      'Badge': () => Badge(child: Text(_long('In review'))),
      'Chip': () => Chip(child: Text(_long('Marketing'))),
      // The expansion goes on `title`, the slot every other case here
      // uses: the component's own primary label. It used to be
      // `description` because that was the only slot Alert had; `title`
      // is now the required one and `description` the optional second
      // line, so measuring the description would be measuring the slot
      // most Alerts do not fill. Mirrors the Web twin of this file.
      'Alert': () => Alert(title: _long('Could not load orders')),
      'Card': () => Card(
        header: Text(_long('Monthly summary')),
        body: Text(_long('Revenue by channel')),
      ),
      'EmptyState': () => EmptyState(
        title: Text(_long('No orders yet')),
        description: Text(_long('Orders will appear here once placed')),
      ),
      'Select': () => Select<String>(
        value: 'a',
        placeholder: _long('Choose a warehouse'),
        items: [
          CoreSelectItem(value: 'a', label: _long('Central warehouse')),
        ],
      ),
      'TextField': () => TextField(
        label: _long('Delivery address'),
        placeholder: Text(_long('Street and number')),
      ),
      'Accordion': () => Accordion(
        items: [
          AccordionItem(
            title: _long('Shipping and returns'),
            content: Text(_long('Ships within two business days')),
          ),
        ],
      ),
    };

    cases.forEach((name, build) {
      testWidgets(name, (tester) async {
        expect(
          await _overflow(tester, build()),
          isNull,
          reason: '$name overflowed once its text grew 35%',
        );
      });
    });
  });

  group('the layouts that do not survive it', () {
    // Listed, not skipped. Asserting that these *do* overflow means the
    // day one is fixed this test goes red and says so — a skip would
    // stay quiet forever and the fix would never be noticed.
    testWidgets('a tab bar pushes past its container', (tester) async {
      // Both platforms lay the bar out as a single non-wrapping,
      // non-scrolling row (Flutter `Row`, Web `inline-flex` with no
      // `flex-wrap` and no `overflow-x-auto`), so long labels have
      // nowhere to go. Flutter throws; the Web silently spills.
      //
      // Not fixed here because the fix is a design decision — scroll,
      // wrap, or truncate — and whichever is chosen has to be chosen
      // for both platforms at once.
      expect(
        await _overflow(
          tester,
          Tabs.labels(
            selectedIndex: 0,
            labels: [_long('Overview'), _long('Settings')],
          ),
        ),
        isNotNull,
        reason: 'the tab bar now fits — move this to the passing set',
      );
    });
  });

  group('a cell with a hard width still holds its text', () {
    // Why this group exists separately: an exception is not the only way
    // a layout fails, and it is not how the worst ones fail. A cell with
    // a fixed width and a fixed height clips its text and throws
    // nothing — the label is simply cut off and the widget test is
    // green. The gate here is geometry, not exceptions: if the text
    // wants more width than the box gives it, it is being clipped.
    //
    // The calendar is where this bites. Its weekday cells are a fixed
    // square holding a string that comes from the locale, so the
    // component cannot know how long that string will be — and a grid
    // cell cannot promise to fit one. What it can do is say what
    // happens when it does not, which is what this asks for.
    // The view is pinned, and to September on purpose. Left to
    // `DateTime.now()` this asked its question of whatever month the
    // suite happened to run in, so it was a different test every day and
    // the hardest one only eleven months out of twelve — `September` is
    // the longest English month name at nine letters. It found the
    // undeclared overflow on the header the first morning it was
    // September and had been green through the ten months before that.
    //
    // A test whose subject changes with the calendar reports "passed"
    // for a case it never ran. Pinning costs the other eleven months,
    // which were the ones proving nothing.
    testWidgets('the calendar weekday header', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          localizationsDelegates: const [_ExpandedLocalizationsDelegate()],
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: const Align(
            child: SizedBox(
              width: 360,
              child: Calendar(initialView: CoreCalendarView(2026, 9)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_silentlyCutOff(tester), isEmpty);
    });
  });

  group('the expansion itself is honest', () {
    test('it grows the string', () {
      final expanded = CorePseudoLocale.expand('Save');

      expect(expanded.length, greaterThan('Save'.length));
    });

    test('it marks both ends so clipping is visible', () {
      // Without the markers a clipped string is indistinguishable from
      // a short one, which is the whole reason a reviewer can trust
      // what they are looking at.
      final expanded = CorePseudoLocale.expand('Save');

      expect(expanded.startsWith(CorePseudoLocale.startMarker), isTrue);
      expect(expanded.endsWith(CorePseudoLocale.endMarker), isTrue);
      expect(CorePseudoLocale.isComplete(expanded), isTrue);
      expect(
        CorePseudoLocale.isComplete(
          expanded.substring(0, expanded.length - 3),
        ),
        isFalse,
      );
    });

    test('it leaves an empty string empty', () {
      // A component that renders nothing should not start rendering
      // brackets because the harness ran.
      expect(CorePseudoLocale.expand(''), isEmpty);
    });

    test('it keeps the text readable', () {
      // Accented look-alikes, not mojibake: a reviewer has to be able
      // to tell which control they are looking at. A string that stayed
      // plain ASCII is one the component hardcoded instead of pulling
      // from the locale.
      expect(CorePseudoLocale.expand('Save'), contains('Šáṽé'));
    });
  });
}
