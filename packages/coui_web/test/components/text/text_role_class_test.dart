import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Arbitrary factor for the calc() textScaler assertion — not a token.
const _kTestScaler = 1.5;

/// The single `<span>` a bare `Text` chain renders.
DomComponent _span(ComponentTester tester) =>
    find.byType(DomComponent).evaluate().single.component as DomComponent;

void main() {
  // Regression for #4449: `neoBrutalism`'s typography `weightFloor` only
  // reached Flutter. `_withCoreTextStyle` baked fontSize/fontWeight/
  // lineHeight/letterSpacing from the static `CoreTypography.coui` into
  // inline CSS + a `font-{weightScale}` class that references a
  // surface-style-agnostic global variable — never the per-role
  // `text-{role}` class that `[data-coui-style="neoBrutalism"]` actually
  // overrides. These tests pin the emitted DOM shape so that mechanism
  // can't silently regress back to baked literals.
  group('a semantic Text chain emits the role as a single class (#4449)', () {
    testComponents('.bodyMedium carries text-body-medium', (tester) async {
      pumpWithTheme(tester, const Text('Hi').bodyMedium);

      final classes = (_span(tester).classes ?? '').split(' ');
      expect(classes, contains('text-body-medium'));
    });

    testComponents(
      'role text carries no font-{weight} primitive class — weight comes '
      'from the role CSS variable, not a baked class',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi').titleLarge);

        final classes = (_span(tester).classes ?? '').split(' ');
        expect(classes.any((c) => c.startsWith('font-')), isFalse);
      },
    );

    testComponents(
      'no inline font-size/line-height/letter-spacing is baked — the role '
      'class carries them via CSS variables',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi').labelSmall);

        final styles = _span(tester).styles?.properties ?? const {};
        expect(styles.containsKey('font-size'), isFalse);
        expect(styles.containsKey('line-height'), isFalse);
        expect(styles.containsKey('letter-spacing'), isFalse);
      },
    );

    testComponents(
      'a primitive chained after the role overrides only that property, '
      'inline, while the role class (and its other properties) stay',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi').bodyMedium.s14);

        final span = _span(tester);
        final classes = (span.classes ?? '').split(' ');
        expect(classes, contains('text-body-medium'));
        final styles = span.styles?.properties ?? const {};
        expect(styles['font-size'], '${CoreFontSize.s14 / kRemDivisor}rem');
      },
    );

    testComponents(
      "textScaler with a role scales the role's own CSS variable via "
      'calc(), staying reactive instead of assuming a fixed base size',
      (tester) async {
        pumpWithTheme(
          tester,
          const Text('Hi', textScaler: _kTestScaler).bodyMedium,
        );

        final span = _span(tester);
        final classes = (span.classes ?? '').split(' ');
        expect(classes, contains('text-body-medium'));
        final styles = span.styles?.properties ?? const {};
        expect(
          styles['font-size'],
          'calc(var(--coui-text-body-medium-size) * $_kTestScaler)',
        );
      },
    );

    testComponents(
      'textScaler with no role scales the inherited size, not an assumed '
      'base size',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi', textScaler: _kTestScaler));

        final styles = _span(tester).styles?.properties ?? const {};
        // `1em` in `font-size` is the parent's computed size — whatever
        // role the ancestor painted, as Flutter's `DefaultTextStyle` does.
        expect(styles['font-size'], 'calc(1em * $_kTestScaler)');
      },
    );
  });

  group('the new role chains emit only their role class', () {
    for (final (name, chain) in <(String, Text Function(Text))>[
      ('body-xs', (text) => text.bodyXs),
      ('label-xs', (text) => text.labelXs),
      ('code-xs', (text) => text.codeXs),
      ('code-sm', (text) => text.codeSm),
      ('code-md', (text) => text.codeMd),
    ]) {
      testComponents('text-$name', (tester) async {
        pumpWithTheme(tester, chain(const Text('Hi')));

        final span = _span(tester);
        final classes = (span.classes ?? '').split(' ');
        expect(classes, contains('text-$name'));
        // The code roles' face rides the `:where(.text-code-*)` rule, not a
        // `font-*` class — so an explicit `.sans` after it still wins.
        expect(classes.any((c) => c.startsWith('font-')), isFalse);
        final styles = span.styles?.properties ?? const {};
        expect(styles.containsKey('font-size'), isFalse);
        expect(styles.containsKey('line-height'), isFalse);
        expect(styles.containsKey('font-family'), isFalse);
      });
    }
  });

  group('the new primitive chains', () {
    for (final (name, chain, size) in <(String, Text Function(Text), double)>[
      ('s11', (text) => text.s11, CoreFontSize.s11),
      ('s13', (text) => text.s13, CoreFontSize.s13),
      ('s15', (text) => text.s15, CoreFontSize.s15),
    ]) {
      testComponents('.$name sets the size in rem', (tester) async {
        pumpWithTheme(tester, chain(const Text('Hi')));

        final styles = _span(tester).styles?.properties ?? const {};
        expect(styles['font-size'], '${size / kRemDivisor}rem');
      });
    }

    testComponents('.h150 sets the leading multiplier', (tester) async {
      pumpWithTheme(tester, const Text('Hi').h150);

      // The box it makes at the span's own size, on a whole pixel, and the
      // multiplier itself for the text inside.
      final styles = _span(tester).styles?.properties ?? const {};
      expect(
        styles['line-height'],
        CssVariableGenerator.lineHeightCss(CoreLineHeight.h150),
      );
      expect(
        styles[CssVariableGenerator.leadingVar],
        '${CoreLineHeight.h150}',
      );
    });
  });
}
