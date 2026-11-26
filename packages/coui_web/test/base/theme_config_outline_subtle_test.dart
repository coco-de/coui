// `outline-subtle` as the Web reads it — the slot at the stylesheet, the
// Tailwind palette and the two blocks that restate colour on top of `:root`
// (high contrast, and a surface style that bends the outline).
//
// A slot that only exists on the scheme looks finished from the authoring
// side and changes nothing a page can use; this reads it where a page would.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

String _rgb(CoreColor c) => '${c.red} ${c.green} ${c.blue}';

/// The light high-contrast block's selector (see the high-contrast test).
const _lightSelector = ':root:root:where(:not([data-theme="dark"]))';

/// The dark high-contrast block's selector.
const _darkSelector = ':root:root[data-theme="dark"]';

void main() {
  const source = CouiColorPresets.source;
  final config = ThemeConfig.defaults();
  final css = config.cssVariables;

  RegExp block(String selector) => RegExp(
    '@media \\(prefers-contrast:more\\)\\{${RegExp.escape(selector)}\\{(.*?)\\}\\}',
    dotAll: true,
  );

  group('the Tailwind palette', () {
    test('has an outline-subtle colour that reads the variable', () {
      expect(
        config.tailwindConfig,
        contains('"outline-subtle":"rgb(var(--coui-outline-subtle))"'),
      );
    });
  });

  group(':root', () {
    test('defines the variable from the light mapping', () {
      final light = source.light().resolved(.light);

      // The `:root` block is the generator's pretty-printed form
      // (`--coui-x: R G B;`); the media-query blocks below are compact.
      expect(
        css,
        matches(
          RegExp(
            r'--coui-outline-subtle:\s*'
            '${_rgb(light.outlineSubtle)};',
          ),
        ),
      );
    });
  });

  group('high contrast restates it', () {
    test('the light block carries the raised line, not the page value', () {
      final raised = source.highContrastLight().resolved(.light);
      final normal = source.light().resolved(.light);
      final body = block(_lightSelector).firstMatch(css)!.group(1)!;

      expect(
        body,
        contains('--coui-outline-subtle:${_rgb(raised.outlineSubtle)};'),
      );
      expect(_rgb(raised.outlineSubtle), isNot(_rgb(normal.outlineSubtle)));
    });

    test('the dark block carries the raised line, not the page value', () {
      final raised = source.highContrastDark().resolved(.dark);
      final normal = source.dark().resolved(.dark);
      final body = block(_darkSelector).firstMatch(css)!.group(1)!;

      expect(
        body,
        contains('--coui-outline-subtle:${_rgb(raised.outlineSubtle)};'),
      );
      expect(_rgb(raised.outlineSubtle), isNot(_rgb(normal.outlineSubtle)));
    });
  });

  group('a surface style that bends outlines bends this one too', () {
    // The same statement that heavies `outline` and `outlineVariant`: a
    // preset whose look is "every boundary is drawn" does not leave the
    // floating-panel line as the one faint hairline.
    test('the style block restates it when the emphasis moves it', () {
      const bent = CoreSurfaceColorConstraint(outlineEmphasis: 1);
      final rule = config.surfaceStyleBlock(.neoBrutalism, bent);

      expect(rule, contains('--coui-outline-subtle:'));
    });

    test('and says nothing about it when the emphasis is zero', () {
      final rule = config.surfaceStyleBlock(
        .neoBrutalism,
        const CoreSurfaceColorConstraint(),
      );

      expect(rule, isNot(contains('--coui-outline-subtle:')));
    });
  });
}
