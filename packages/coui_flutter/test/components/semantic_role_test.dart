import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the semantics node the given finder produces.
SemanticsData _dataOf(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

/// A labelled semantics node needs a text direction, so every case
/// here is mounted under one.
Widget _mount(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

/// `Frame` reads the theme, so its cases mount a real app.
Widget _app(Widget child) =>
    CoUIApp(theme: ThemeData.fromCore(CoreThemePresets.light), home: child);

void main() {
  group('a role Flutter cannot safely express never reaches the tree', () {
    test('every non-mapped role resolves to no native role', () {
      // The declared support state and the switch are two independent
      // statements. This is the one place they are compared — a value
      // moved to `mapped` without a role, or given a role while still
      // marked deferred, fails here rather than in a consumer's debug
      // build.
      for (final role in CoreSemanticRole.values) {
        final resolved = role.toValue();

        if (role.support == CoreSemanticRoleSupport.mapped) {
          expect(
            resolved.role,
            isNotNull,
            reason: '${role.name} claims a native role but produced none',
          );
        } else {
          expect(
            resolved.role,
            isNull,
            reason:
                '${role.name} is ${role.support.name} — emitting a '
                'native role here is what crashes debug builds',
          );
        }
      }
    });

    testWidgets('a deferred role does not raise in a semantics test', (
      tester,
    ) async {
      // Flutter registers no debug check for `SemanticsRole.tooltip`,
      // and the missing-check assert runs inside
      // `SemanticsNode._addToUpdate` — reached by every test that turns
      // semantics on. Mapping this role naively takes the whole suite
      // down, which is why it is deferred.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.tooltip,
            label: 'more info',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('a stated role reaches the semantics tree', () {
    testWidgets('navigation arrives as a native SemanticsRole', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.navigation,
            label: 'primary',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(
        _dataOf(tester, find.byType(CoUISemantics)).role,
        SemanticsRole.navigation,
      );
      handle.dispose();
    });

    testWidgets('a flagged role arrives as its flag', (tester) async {
      // `button` has no Flutter role — the flag *is* the idiom, not a
      // consolation prize, so this must be as real as the case above.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.button,
            label: 'save',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final data = _dataOf(tester, find.byType(CoUISemantics));

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.role, SemanticsRole.none);
      handle.dispose();
    });

    testWidgets('an alert arrives as a live region, not a role', (
      tester,
    ) async {
      // Flutter asserts a node is not both `alert` and a live region.
      // Web states both; of the two, only the live region is announced
      // on Flutter today.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.alert,
            label: 'saved',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final data = _dataOf(tester, find.byType(CoUISemantics));

      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(data.role, SemanticsRole.none);
      handle.dispose();
    });
  });

  group('a precondition this widget can see is honoured', () {
    testWidgets('a region without a label drops the role instead of '
        'crashing', (tester) async {
      // The SDK check rejects an unlabelled region. A role that fails
      // its own precondition tells a screen reader nothing, so dropping
      // it costs nothing — and the alternative is an assert inside the
      // consumer's build.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.region,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        _dataOf(tester, find.byType(CoUISemantics)).role,
        SemanticsRole.none,
      );
      handle.dispose();
    });

    testWidgets('the same region with a label keeps the role', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _mount(
          const CoUISemantics(
            role: CoreSemanticRole.region,
            label: 'filters',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(
        _dataOf(tester, find.byType(CoUISemantics)).role,
        SemanticsRole.region,
      );
      handle.dispose();
    });
  });

  group('Frame carries the role through', () {
    testWidgets('Frame(a11y: role) reaches SemanticsData.role', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          const Frame(
            a11y: CoreFrameA11y(
              role: CoreSemanticRole.navigation,
              label: 'primary',
            ),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(
        _dataOf(tester, find.byType(CoUISemantics)).role,
        SemanticsRole.navigation,
      );
      handle.dispose();
    });

    testWidgets('a tappable Frame with a stated role keeps that role', (
      tester,
    ) async {
      // The string comparison this replaces turned every tappable frame
      // into a button, discarding whatever role it stated.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          Frame(
            a11y: const CoreFrameA11y(
              role: CoreSemanticRole.navigation,
              label: 'primary',
            ),
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final data = _dataOf(tester, find.byType(CoUISemantics));

      expect(data.role, SemanticsRole.navigation);
      expect(data.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a tappable Frame that states no role is still a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          Frame(
            a11y: const CoreFrameA11y(label: 'open'),
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(
        _dataOf(tester, find.byType(CoUISemantics)).flagsCollection.isButton,
        isTrue,
      );
      handle.dispose();
    });
  });
}
