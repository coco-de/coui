// A role's own font family on Web. The family cannot ride the role's
// Tailwind class, so it travels as a per-role variable read by a rule of its
// own — and only for a role that names one. The default scale names one on
// the code roles alone, which draw in mono.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  final roleFamilyVariable = RegExp('--coui-text-[a-z0-9-]+-family');

  const codeRoles = ['code-xs', 'code-sm', 'code-md'];

  test('the default stylesheet names the mono family on the code roles '
      'only', () {
    final css = ThemeConfig.defaults().cssVariables;
    expect(
      roleFamilyVariable.allMatches(css).map((match) => match[0]).toSet(),
      {for (final role in codeRoles) '--coui-text-$role-family'},
    );
    for (final role in codeRoles) {
      expect(
        css,
        contains('--coui-text-$role-family:var(--coui-font-family-mono);'),
      );
      expect(
        css,
        contains(
          ':where(.text-$role){font-family:var(--coui-text-$role-family)}',
        ),
      );
    }
    // The roles' leading rules share the `:where(.text-*)` selector, so the
    // family rules are counted by what they declare.
    final familyRule = RegExp(r':where\(\.text-[a-z0-9-]+\)\{font-family:');
    expect(familyRule.allMatches(css), hasLength(codeRoles.length));
  });

  test('the typography block defines rendering expressions beside '
      'the source variables and inherited leading', () {
    final block = ThemeConfig.typographyCssBlock(.coui);
    expect(
      block,
      startsWith(
        '@property --coui-text-scale '
        '{syntax:"<number>";inherits:false;initial-value:1}:root{',
      ),
    );
    for (final token in CoreTextStyles.values) {
      final role = token.name;
      expect(
        block,
        contains(
          ':where(.text-$role)'
          '{--coui-text-$role-rendered-line-height:round(nearest, '
          'calc(var(--coui-text-$role-line-height) * ',
        ),
      );
    }
    expect(block, contains('--coui-leading:1.5;'));
    expect(block, contains('--coui-leading:1.75;'));
  });

  group('a display face on the headings', () {
    final css = ThemeConfig.from(
      CouiColorPresets.source,
      typography: CoreTypography.coui.withFamily('Hahmlet'),
    ).cssVariables;

    test('reaches each heading role through its variable', () {
      expect(
        css,
        contains(
          '--coui-text-display-large-family:'
          '"Hahmlet", var(--coui-font-family-sans);',
        ),
      );
      expect(
        css,
        contains(
          ':where(.text-headline-small)'
          '{font-family:var(--coui-text-headline-small-family)}',
        ),
      );
    });

    test('leaves the other roles in the text face', () {
      expect(css, isNot(contains('--coui-text-body-medium-family')));
      expect(
        css,
        isNot(contains(':where(.text-body-medium){font-family')),
      );
    });

    test('leaves the code roles in mono', () {
      expect(
        css,
        contains('--coui-text-code-sm-family:var(--coui-font-family-mono);'),
      );
    });
  });
}
