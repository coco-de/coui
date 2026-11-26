// A role's own font family — how a product sets its headings in a display
// face. The default scale names a family only on the code roles (mono), so
// nothing here may change what the rest of the default renders; the face
// only reaches a role that was given one.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTypography.withFamily', () {
    const face = 'Hahmlet';
    final scale = CoreTypography.coui.withFamily(face);

    // The three code roles are written out rather than matched by prefix —
    // a second source, so a role that gains or loses mono fails here.
    const codeRoles = {'code-xs', 'code-sm', 'code-md'};

    test('the default scale names a family on the code roles only', () {
      for (final token in CoreTextStyles.values) {
        expect(
          token.read(CoreTypography.coui).fontFamily,
          codeRoles.contains(token.name) ? CoreFontFamily.mono : isNull,
          reason: token.name,
        );
      }
    });

    test('sets the face on display and headline roles, and only there', () {
      // Six heading roles, written out rather than read back from
      // `headingRoles` — a second source, so a role dropped from that list
      // fails here instead of moving both sides together.
      const headings = {
        'display-large',
        'display-medium',
        'display-small',
        'headline-large',
        'headline-medium',
        'headline-small',
      };
      for (final token in CoreTextStyles.values) {
        expect(
          token.read(scale).fontFamily,
          headings.contains(token.name)
              ? face
              : codeRoles.contains(token.name)
              ? CoreFontFamily.mono
              : isNull,
          reason: token.name,
        );
      }
    });

    test('keeps the rest of every role', () {
      for (final token in CoreTextStyles.values) {
        final before = token.read(CoreTypography.coui);
        final after = token.read(scale);
        expect(after.fontSize, before.fontSize, reason: token.name);
        expect(after.fontWeight, before.fontWeight, reason: token.name);
        expect(after.lineHeight, before.lineHeight, reason: token.name);
        expect(after.lineHeightPx, before.lineHeightPx, reason: token.name);
        expect(after.letterSpacing, before.letterSpacing, reason: token.name);
      }
    });

    test('a caller can name the roles', () {
      final titles = CoreTypography.coui.withFamily(
        face,
        roles: const [CoreTextStyles.titleLarge],
      );
      expect(titles.titleLarge.fontFamily, face);
      expect(titles.displayLarge.fontFamily, isNull);
    });

    test('the face survives text scaling', () {
      expect(scale.scale(1.5).displayLarge.fontFamily, face);
    });
  });

  group('CssVariableGenerator.typographyVars — role family', () {
    Iterable<String> familyKeys(Map<String, String> vars) =>
        vars.keys.where((key) => key.endsWith('-family'));

    test('the default scale emits a family variable for the code roles '
        'only, reading the mono stack', () {
      final vars = CssVariableGenerator.typographyVars(.coui);
      expect(familyKeys(vars), {
        '--coui-text-code-xs-family',
        '--coui-text-code-sm-family',
        '--coui-text-code-md-family',
      });
      for (final key in familyKeys(vars)) {
        expect(vars[key], 'var(--coui-font-family-mono)', reason: key);
      }
    });

    test('a display face reaches each heading role, falling back to the '
        'text face', () {
      final vars = CssVariableGenerator.typographyVars(
        CoreTypography.coui.withFamily('Hahmlet'),
      );
      expect(familyKeys(vars), hasLength(6 + 3));
      expect(
        vars['--coui-text-display-large-family'],
        '"Hahmlet", var(--coui-font-family-sans)',
      );
      expect(vars['--coui-text-body-medium-family'], isNull);
    });

    test('the text and mono faces read their own stacks', () {
      expect(
        CssVariableGenerator.typographyVars(
          CoreTypography.coui.withFamily(CoreFontFamily.sans),
        )['--coui-text-display-large-family'],
        'var(--coui-font-family-sans)',
      );
      expect(
        CssVariableGenerator.typographyVars(
          CoreTypography.coui.withFamily(CoreFontFamily.mono),
        )['--coui-text-display-large-family'],
        'var(--coui-font-family-mono)',
      );
    });

    test('a quote in the name cannot close the CSS string', () {
      expect(
        CssVariableGenerator.typographyVars(
          CoreTypography.coui.withFamily('Ham"let'),
        )['--coui-text-display-large-family'],
        '"Hamlet", var(--coui-font-family-sans)',
      );
    });
  });
}
