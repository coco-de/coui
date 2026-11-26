import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The class names rendered on the root `<span>`.
Set<String> _classes(ComponentTester tester) {
  final element = find.tag('span').evaluate().first.component as DomComponent;
  return (element.classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();
}

void main() {
  group('the caret colour emitted to the browser', () {
    for (final coreTheme in [CoreThemePresets.light, CoreThemePresets.dark]) {
      testComponents('is primary in ${coreTheme.brightness}', (tester) async {
        tester.pumpComponent(
          Theme(
            data: ThemeData.fromCore(coreTheme),
            child: const SelectableText('T'),
          ),
        );
        final element =
            find.tag('span').evaluate().first.component as DomComponent;
        expect(
          element.styles?.properties['caret-color'],
          'rgb(var(--coui-primary))',
        );
        expect(_classes(tester), contains('selection:bg-primary-container'));
      });
    }

    for (final instanceOverride in [false, true]) {
      testComponents('theme colour supports an instance override '
          '($instanceOverride)', (tester) async {
        tester.pumpComponent(
          Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                selectableText: CoreSelectableTextTheme(
                  style: CoreSelectableTextStyle(
                    cursorColor: CoreColor.token(CoreColors.tertiary),
                  ),
                ),
              ),
            ),
            child: SelectableText(
              'T',
              selectableTextStyle: instanceOverride
                  ? const CoreSelectableTextStyle(
                      cursorColor: CoreColor.token(CoreColors.error),
                    )
                  : null,
            ),
          ),
        );
        final element =
            find.tag('span').evaluate().first.component as DomComponent;
        expect(
          element.styles?.properties['caret-color'],
          instanceOverride
              ? 'rgb(var(--coui-error))'
              : 'rgb(var(--coui-tertiary))',
        );
      });
    }
  });

  // Flutter's selectable text lays its glyphs out the cursor width plus the
  // framework's caret gap wider than the words, whether a caret shows or
  // not (`RenderEditable`). The Web span reserves the same room after the
  // text so the two boxes are as wide.
  group('the caret room after the text', () {
    String? reserved(ComponentTester tester) =>
        (find.tag('span').evaluate().first.component as DomComponent)
            .styles
            ?.properties['padding-inline-end'];

    testComponents('is the default cursor width plus the caret gap', (
      tester,
    ) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.fromCore(CoreThemePresets.light),
          child: const SelectableText('T'),
        ),
      );
      // 2 + 1 = 3px, as rem — the Flutter twin's 3px.
      expect(reserved(tester), '0.1875rem');
    });

    testComponents('follows a cursorWidth override', (tester) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.fromCore(CoreThemePresets.light),
          child: const SelectableText(
            'T',
            selectableTextStyle: CoreSelectableTextStyle(cursorWidth: 4),
          ),
        ),
      );
      expect(reserved(tester), '0.3125rem');
    });
  });

  group('the selection tint a SelectableText paints', () {
    // `::selection` cannot be written inline, so the tint rides a
    // `selection:bg-*` pseudo-element class. These read the class list the
    // browser actually receives.
    testComponents('is primary-container by default', (tester) async {
      pumpWithTheme(tester, const SelectableText('T'));
      final selection = _classes(
        tester,
      ).where((c) => c.startsWith('selection:bg-'));

      // The whole class, so neither the old `primary` tint nor an alpha
      // suffix (`/20`) can pass: the band is the container tone as stated.
      expect(selection, {'selection:bg-primary-container'});
    });

    testComponents('follows a selectionColor override', (tester) async {
      pumpWithTheme(
        tester,
        const SelectableText(
          'T',
          selectableTextStyle: CoreSelectableTextStyle(
            selectionColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );
      final selection = _classes(
        tester,
      ).where((c) => c.startsWith('selection:bg-'));

      expect(selection, {'selection:bg-tertiary'});
    });

    testComponents('keeps the alpha the caller states', (tester) async {
      // Nothing multiplies it: a 25% colour is a 25% class, the same value
      // the Flutter twin paints.
      pumpWithTheme(
        tester,
        const SelectableText(
          'T',
          selectableTextStyle: CoreSelectableTextStyle(
            selectionColor: CoreColor.token(
              CoreColors.primary,
              opacity: CoreOpacity.opacity25,
            ),
          ),
        ),
      );
      final selection = _classes(
        tester,
      ).where((c) => c.startsWith('selection:bg-'));

      expect(selection, {'selection:bg-primary/25'});
    });

    testComponents('leaves the glyph colour to the text style', (tester) async {
      // Selecting changes the band, not the text: the root states the body
      // role in `on-surface`, and no `selection:text-*` class rewrites it.
      pumpWithTheme(tester, const SelectableText('T'));
      final classes = _classes(tester);

      expect(classes, contains('text-body-medium'));
      expect(classes, contains('text-on-surface'));
      expect(classes.where((c) => c.startsWith('selection:text-')), isEmpty);
    });
  });
}
