// Tests for CssVariableGenerator.typographyVars (#2624 — Web typography
// theme wiring). Verifies the per-role CSS variables match the M3 default
// scale and that a project-supplied CoreTypography flows through.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The table the Flutter line metrics test and the Chrome probe read too.
const String _kLineBoxVectorsPath = 'test/fixtures/line_box_vectors.json';

void main() {
  group('CssVariableGenerator.typographyVars — default scale', () {
    final vars = CssVariableGenerator.typographyVars(.coui);

    // The 22 and the 3 are LITERALS on purpose, and the count was briefly not
    // one. Counting `CoreTextStyles.values.length * 4` reads far better and
    // checks nothing: the generator loops over that same list, so numerator
    // and denominator move together and a role dropped from it passes.
    // Verified by dropping one — green either way.
    //
    // A literal is an independent second source. It fails on the next role
    // added or removed, which is exactly when a human should look at whether
    // the emit side kept up.
    test('emits 5 properties for each of the 22 roles, plus 3 families', () {
      const roles = CoreTextStyles.values;
      expect(roles, hasLength(22));
      expect(vars.length, equals(22 * 5 + 3));
      for (final role in roles) {
        final isCode = role.name.startsWith('code-');
        expect(
          vars.keys.where((k) => k.startsWith('--coui-text-${role.name}-')),
          hasLength(isCode ? 6 : 5),
          reason: '${role.name} is missing one of its properties',
        );
      }
    });

    test('preserves the public line-box type flags for every role', () {
      for (final role in CoreTextStyles.values) {
        expect(
          vars['--coui-text-${role.name}-line-box'],
          role.name.startsWith('code-') ? '1' : '0',
          reason: role.name,
        );
      }
    });

    test(
      'body-medium matches the default scale (14px / 1.5 / 400 / -0.01em)',
      () {
        expect(vars['--coui-text-body-medium-size'], equals('0.875rem'));
        expect(vars['--coui-text-body-medium-line-height'], equals('1.5'));
        expect(vars['--coui-text-body-medium-weight'], equals('400'));
        expect(vars['--coui-text-body-medium-tracking'], equals('-0.01em'));
      },
    );

    test(
      'display-large matches the default scale (52px / 1.4 / 700 / -0.02em)',
      () {
        expect(vars['--coui-text-display-large-size'], equals('3.25rem'));
        expect(vars['--coui-text-display-large-line-height'], equals('1.4'));
        expect(vars['--coui-text-display-large-weight'], equals('700'));
        expect(vars['--coui-text-display-large-tracking'], equals('-0.02em'));
      },
    );

    test('headline-large weight is bold (700), one step above title (600)', () {
      expect(vars['--coui-text-headline-large-weight'], equals('700'));
      expect(vars['--coui-text-title-large-weight'], equals('600'));
    });

    // The code roles share one 21px line box. It is written as a rem length
    // into the same line-height variable — a length, not a multiplier, so
    // 11 · 12 · 13px code all land on one line, and rem so the box follows
    // browser text scaling as Flutter's `height = px / fontSize` follows the
    // text scaler.
    test('code-sm is 12px mono on a 21px (1.3125rem) line, no tracking', () {
      expect(vars['--coui-text-code-sm-size'], equals('0.75rem'));
      expect(vars['--coui-text-code-sm-line-height'], equals('1.3125rem'));
      expect(vars['--coui-text-code-sm-weight'], equals('400'));
      expect(vars['--coui-text-code-sm-tracking'], equals('0.0em'));
      expect(
        vars['--coui-text-code-sm-family'],
        equals('var(--coui-font-family-mono)'),
      );
      for (final role in ['code-xs', 'code-md']) {
        expect(vars['--coui-text-$role-line-height'], equals('1.3125rem'));
      }
    });
  });

  group('CssVariableGenerator.typographyVars — project override', () {
    test('a custom bodyMedium composition flows into the vars', () {
      final custom = CoreTypography.coui.copyWith(
        bodyMedium: const CoreTextStyle(
          fontSize: CoreFontSize.s18,
          lineHeight: CoreLineHeight.h140,
          fontWeight: CoreFontWeight.medium,
          letterSpacing: CoreLetterSpacing.tight,
        ),
      );
      final vars = CssVariableGenerator.typographyVars(custom);

      expect(vars['--coui-text-body-medium-size'], equals('1.125rem')); // 18/16
      expect(vars['--coui-text-body-medium-weight'], equals('500'));
      expect(vars['--coui-text-body-medium-line-height'], equals('1.4'));
      expect(vars['--coui-text-body-medium-tracking'], equals('-0.025em'));

      // Untouched roles keep the default. `label-small` is the weight witness
      // BECAUSE the override sets a weight — if a per-role override ever leaked
      // sideways, a neighbouring role's weight is where it would show.
      expect(vars['--coui-text-title-medium-size'], equals('1.125rem'));
      expect(vars['--coui-text-label-small-weight'], equals('500'));
    });
  });

  group('CssVariableGenerator.generate', () {
    test('includes the per-role typography vars alongside colours', () {
      final vars = CssVariableGenerator.generate(CoreThemePresets.light);
      expect(vars.containsKey('--coui-text-body-medium-size'), isTrue);
      expect(vars.containsKey('--coui-primary'), isTrue);
    });

    test('is the runtime vars and the typography vars', () {
      final theme = CoreThemePresets.light;
      expect(CssVariableGenerator.generate(theme), {
        ...CssVariableGenerator.runtimeVars(theme),
        ...CssVariableGenerator.typographyVars(theme.typography),
      });
    });
  });

  // Flutter's engine lays every line out at a whole pixel. The Web emits the
  // box a multiplier draws, rounded the same way, so text stacks to the same
  // height on both. The table is the one the Flutter line metrics test and
  // the Chrome probe read; here it is held to the role values it was written
  // against, so a role that changes its size or leading fails here first.
  group('line box', () {
    final vectors =
        jsonDecode(File(_kLineBoxVectorsPath).readAsStringSync())
            as Map<String, dynamic>;
    final roles = (vectors['roles'] as List).cast<Map<String, dynamic>>();

    test('the table lists every role of the default scale once', () {
      expect(
        roles.map((row) => row['role']),
        unorderedEquals(CoreTextStyles.values.map((token) => token.name)),
      );
    });

    test('each row states the size and leading of its role', () {
      for (final row in roles) {
        final style = CoreTextStyles.values
            .firstWhere((token) => token.name == row['role'])
            .read(.coui);
        expect(
          style.fontSize,
          (row['fontSize'] as num).toDouble(),
          reason: '${row['role']} size',
        );
        expect(
          style.lineHeight,
          (row['lineHeight'] as num?)?.toDouble(),
          reason: '${row['role']} multiplier',
        );
        expect(
          style.lineHeightPx,
          (row['lineHeightPx'] as num?)?.toDouble(),
          reason: '${row['role']} fixed box',
        );
      }
    });

    // The variable is what an element reads to hand a multiplier down —
    // the app root does — so it stays the multiplier. The box is drawn by
    // the role's class, at the element's own size.
    test('a multiplier role keeps its multiplier in the variable', () {
      final vars = CssVariableGenerator.typographyVars(.coui);
      for (final row in roles.where((row) => row['lineHeight'] != null)) {
        expect(
          vars['--coui-text-${row['role']}-line-height'],
          '${row['lineHeight']}',
          reason: '${row['role']}',
        );
      }
    });

    test('the box is the product rounded to the nearest pixel', () {
      expect(
        CssVariableGenerator.lineHeightCss(1.4),
        'round(nearest, calc(1.4 * 1em), 1px)',
      );
      expect(
        CssVariableGenerator.roundToPixelCss('1.3125rem'),
        'round(nearest, 1.3125rem, 1px)',
      );
      expect(
        CssVariableGenerator.inheritedLineHeightCss(),
        'round(nearest, calc(var(--coui-leading) * 1em), 1px)',
      );
    });
  });

  // The runtime path writes inline on `<html>`, which beats every rule in the
  // stylesheet. A role variable written there would pin the page's type to
  // that one value over every rule that restates it — a surface style raising
  // a weight, for one.
  group('CssVariableGenerator.runtimeVars', () {
    final vars = CssVariableGenerator.runtimeVars(CoreThemePresets.light);

    test('writes no typography variable', () {
      expect(vars.keys.where((key) => key.startsWith('--coui-text-')), isEmpty);
    });

    test('writes colour and corners', () {
      expect(vars.containsKey('--coui-primary'), isTrue);
      expect(vars.containsKey('--coui-radius-8'), isTrue);
    });
  });
}
