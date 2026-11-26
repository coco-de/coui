// Tests for CoreTypography.copyWith (#2624 — typography role override).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTypography.copyWith', () {
    test('overrides only the given role, others unchanged', () {
      const custom = CoreTextStyle(
        fontSize: CoreFontSize.s18,
        fontWeight: CoreFontWeight.regular,
        lineHeight: CoreLineHeight.h160,
      );
      final result = CoreTypography.coui.copyWith(bodyMedium: custom);

      expect(result.bodyMedium, equals(custom));
      expect(result.titleMedium, equals(CoreTypography.coui.titleMedium));
      expect(result.labelSmall, equals(CoreTypography.coui.labelSmall));
      expect(result.displayLarge, equals(CoreTypography.coui.displayLarge));
    });

    test('no-arg copyWith returns an equal scale', () {
      final result = CoreTypography.coui.copyWith();
      expect(result.bodyMedium, equals(CoreTypography.coui.bodyMedium));
      expect(result.headlineLarge, equals(CoreTypography.coui.headlineLarge));
    });

    test('overriding multiple roles applies each independently', () {
      const body = CoreTextStyle(fontSize: CoreFontSize.s18);
      const label = CoreTextStyle(fontSize: CoreFontSize.s12);
      final result = CoreTypography.coui.copyWith(
        bodyMedium: body,
        labelLarge: label,
      );

      expect(result.bodyMedium, equals(body));
      expect(result.labelLarge, equals(label));
      expect(result.bodyLarge, equals(CoreTypography.coui.bodyLarge));
    });
  });

  // ─── Role weights ──────────────────────────────────────────────────────────
  //
  // Two invariants a component can rely on without naming a number: a
  // control's label is heavier than the prose beside it, and every role in a
  // group carries one weight. Pinned here rather than left to the scale
  // literal because the value was previously spelled in widgets, one
  // component at a time, and what that produced was a `Button` lighter than
  // the checkbox next to it — with nothing failing.
  group('CoreTypography.coui role weights', () {
    const scale = CoreTypography.coui;

    // The six role groups, every member listed. The Figma exporter writes ONE
    // `font-weight/<group>` variable per group from a single representative
    // role and binds every text style in the group to it — so a group whose
    // members disagree would have its variable and some of its text styles
    // telling two different weights.
    final groups = <String, List<CoreTextStyle>>{
      'display': [scale.displayLarge, scale.displayMedium, scale.displaySmall],
      'headline': [
        scale.headlineLarge,
        scale.headlineMedium,
        scale.headlineSmall,
      ],
      'title': [scale.titleLarge, scale.titleMedium, scale.titleSmall],
      'body': [
        scale.bodyLarge,
        scale.bodyMedium,
        scale.bodySmall,
        scale.bodyXs,
      ],
      'label': [
        scale.labelXl2,
        scale.labelXl,
        scale.labelLarge,
        scale.labelMedium,
        scale.labelSmall,
        scale.labelXs,
      ],
      'code': [scale.codeXs, scale.codeSm, scale.codeMd],
    };

    test('every label role is heavier than every body role', () {
      for (final label in groups['label']!) {
        for (final body in groups['body']!) {
          expect(
            label.fontWeight,
            greaterThan(body.fontWeight!),
            reason: 'a label names something you act on; body is read',
          );
        }
      }
    });

    test('every role in a group agrees on weight', () {
      for (final entry in groups.entries) {
        final weights = {for (final style in entry.value) style.fontWeight};
        expect(
          weights,
          hasLength(1),
          reason: '${entry.key} roles disagree on weight: $weights',
        );
      }
    });

    test('each group carries its authored weight', () {
      int weightOf(String group) => groups[group]!.first.fontWeight!;

      expect(weightOf('display'), CoreFontWeight.bold);
      expect(weightOf('headline'), CoreFontWeight.bold);
      expect(weightOf('title'), CoreFontWeight.semiBold);
      expect(weightOf('body'), CoreFontWeight.regular);
      expect(weightOf('label'), CoreFontWeight.medium);
      expect(weightOf('code'), CoreFontWeight.regular);
    });

    // Display and headline share one weight; title is one step lighter
    // (600) so a title set inside a heading's reach does not read as heavy
    // as the heading. All three stay above body.
    test('display and headline share one weight, title one step lighter', () {
      expect(
        {scale.displaySmall.fontWeight, scale.headlineSmall.fontWeight},
        hasLength(1),
      );
      expect(scale.titleLarge.fontWeight, CoreFontWeight.semiBold);
      expect(
        scale.titleLarge.fontWeight,
        lessThan(scale.headlineSmall.fontWeight!),
      );
      expect(
        scale.titleSmall.fontWeight,
        greaterThan(scale.bodyLarge.fontWeight!),
      );
    });
  });

  // ─── The whole table ───────────────────────────────────────────────────────
  //
  // Every role's size · weight · line · tracking, written out as numbers so
  // a change to any one of them is a change to this table and shows up in
  // review as one. Line is the multiplier, or a pixel box for the code roles.
  group('CoreTypography.coui values', () {
    const scale = CoreTypography.coui;
    // (role, size, weight, line multiplier, line px, tracking em)
    final table =
        <(String, CoreTextStyle, double, int, double?, double?, double)>[
          ('display-large', scale.displayLarge, 52, 700, 1.4, null, -0.02),
          ('display-medium', scale.displayMedium, 48, 700, 1.4, null, -0.02),
          ('display-small', scale.displaySmall, 44, 700, 1.4, null, -0.02),
          ('headline-large', scale.headlineLarge, 32, 700, 1.4, null, -0.02),
          ('headline-medium', scale.headlineMedium, 28, 700, 1.4, null, -0.02),
          ('headline-small', scale.headlineSmall, 24, 700, 1.4, null, -0.02),
          ('title-large', scale.titleLarge, 20, 600, 1.4, null, -0.02),
          ('title-medium', scale.titleMedium, 18, 600, 1.4, null, -0.01),
          ('title-small', scale.titleSmall, 16, 600, 1.4, null, -0.01),
          ('body-large', scale.bodyLarge, 15, 400, 1.5, null, -0.01),
          ('body-medium', scale.bodyMedium, 14, 400, 1.5, null, -0.01),
          ('body-small', scale.bodySmall, 13, 400, 1.5, null, -0.01),
          ('body-xs', scale.bodyXs, 12, 400, 1.5, null, -0.01),
          ('label-xl2', scale.labelXl2, 16, 500, 1.4, null, -0.01),
          ('label-xl', scale.labelXl, 15, 500, 1.4, null, -0.01),
          ('label-large', scale.labelLarge, 14, 500, 1.4, null, -0.01),
          ('label-medium', scale.labelMedium, 13, 500, 1.4, null, -0.01),
          ('label-small', scale.labelSmall, 12, 500, 1.4, null, -0.01),
          ('label-xs', scale.labelXs, 11, 500, 1.4, null, -0.01),
          ('code-xs', scale.codeXs, 11, 400, null, 21, 0),
          ('code-sm', scale.codeSm, 12, 400, null, 21, 0),
          ('code-md', scale.codeMd, 13, 400, null, 21, 0),
        ];

    test('lists every role once, in token order', () {
      expect(
        [for (final row in table) row.$1],
        [for (final token in CoreTextStyles.values) token.name],
      );
    });

    for (final (name, style, size, weight, line, linePx, tracking) in table) {
      test('$name is $size / $weight / ${linePx ?? line} / $tracking', () {
        expect(style.fontSize, size);
        expect(style.fontWeight, weight);
        expect(style.lineHeight, line);
        expect(style.lineHeightPx, linePx);
        expect(style.letterSpacing, tracking);
      });
    }

    // Tracking is two steps: 20px and above, and below. A role that crosses
    // the line moves a whole step, which is the point — there is no third
    // rung for an 18px title to sit on.
    test('tracking is −2% from 20px, −1% below, 0 for mono', () {
      for (final token in CoreTextStyles.values) {
        final style = token.read(scale);
        final expected = style.fontFamily == CoreFontFamily.mono
            ? CoreLetterSpacing.normal
            : style.fontSize! >= 20
            ? CoreLetterSpacing.tight20
            : CoreLetterSpacing.tight10;
        expect(style.letterSpacing, expected, reason: token.name);
      }
    });

    test('only the code roles name a family, and it is mono', () {
      for (final token in CoreTextStyles.values) {
        final style = token.read(scale);
        final isCode = token.name.startsWith('code-');
        expect(
          style.fontFamily,
          isCode ? CoreFontFamily.mono : isNull,
          reason: token.name,
        );
      }
    });

    // The three code sizes share one line box, so an editor's 12px line
    // numbers and its 13px code land on the same lines.
    test('the code roles share one 21px line box', () {
      expect(
        {scale.codeXs.lineHeightPx, scale.codeSm.lineHeightPx},
        {CoreLineBox.px21},
      );
      expect(scale.codeMd.lineHeightPx, CoreLineBox.px21);
    });
  });

  group('CoreTypography.scale', () {
    test('scales the code line box with the glyphs, not the multipliers', () {
      final scaled = CoreTypography.coui.scale(1.25);
      expect(scaled.codeSm.fontSize, 15);
      expect(scaled.codeSm.lineHeightPx, 26.25);
      expect(scaled.bodyMedium.fontSize, 17.5);
      expect(scaled.bodyMedium.lineHeight, 1.5);
    });

    test('map, scale, copyWith, withFamily and atTier cover every role', () {
      const marker = CoreTextStyle(fontSize: 99);
      final mapped = CoreTypography.coui.map((_) => marker);
      for (final token in CoreTextStyles.values) {
        expect(token.read(mapped), marker, reason: 'map: ${token.name}');
        expect(
          token.read(CoreTypography.coui.scale(2)).fontSize,
          token.read(CoreTypography.coui).fontSize! * 2,
          reason: 'scale: ${token.name}',
        );
        expect(
          token.read(CoreTypography.coui.copyWith()),
          token.read(CoreTypography.coui),
          reason: 'copyWith: ${token.name}',
        );
        expect(
          token
              .read(CoreTypography.coui.withFamily('X', roles: [token]))
              .fontFamily,
          'X',
          reason: 'withFamily: ${token.name}',
        );
        // The tier reaches every heading role and no other.
        expect(
          token.read(CoreTypography.coui.atTier(.mobile)).fontSize !=
              token.read(CoreTypography.coui).fontSize,
          CoreTypography.headingRoles.contains(token),
          reason: 'atTier: ${token.name}',
        );
      }
    });
  });

  // ─── The previous table ────────────────────────────────────────────────────
  //
  // `couiV1` is the revert an app reaches for while it migrates, so it has to
  // be the old numbers — not "close to" them.
  group('CoreTypography.couiV1', () {
    const v1 = CoreTypography.couiV1;

    test('is the pre-v2 table', () {
      expect(v1.bodyLarge.fontSize, 18);
      expect(v1.bodyMedium.fontSize, 16);
      expect(v1.bodySmall.fontSize, 14);
      expect(v1.bodyMedium.lineHeight, 1.6);
      expect(v1.labelXl2.fontSize, 18);
      expect(v1.labelXl.fontSize, 16);
      expect(v1.labelLarge.fontSize, 14);
      expect(v1.labelMedium.fontSize, 12);
      expect(v1.labelSmall.fontSize, 10);
      expect(v1.labelSmall.lineHeight, 1.2);
      expect(v1.headlineLarge.fontWeight, CoreFontWeight.semiBold);
      expect(v1.displayLarge.letterSpacing, CoreLetterSpacing.tight);
      expect(v1.titleMedium.letterSpacing, CoreLetterSpacing.tight15);
    });

    test('maps each new role to the old role a component read there', () {
      expect(v1.bodyXs, v1.bodySmall);
      expect(v1.labelXs, v1.labelSmall);
      for (final code in [v1.codeXs, v1.codeSm, v1.codeMd]) {
        expect(code.fontSize, v1.bodySmall.fontSize);
        expect(code.lineHeight, v1.bodySmall.lineHeight);
        expect(code.fontFamily, CoreFontFamily.mono);
      }
    });
  });
}
