// The status indicator slots (`error-icon` … `info-icon`) as the Web reads
// them — the Tailwind palette, `:root`, and the two high-contrast blocks.
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

const _kFamilies = ['error', 'success', 'warning', 'info'];

CoreColor _icon(ResolvedColorScheme s, String family) => switch (family) {
  'error' => s.errorIcon,
  'success' => s.successIcon,
  'warning' => s.warningIcon,
  _ => s.infoIcon,
};

void main() {
  const source = CouiColorPresets.source;
  final config = ThemeConfig.defaults();
  final css = config.cssVariables;

  RegExp block(String selector) => RegExp(
    '@media \\(prefers-contrast:more\\)\\{${RegExp.escape(selector)}\\{(.*?)\\}\\}',
    dotAll: true,
  );

  test(
    'the Tailwind palette has a colour per slot that reads its variable',
    () {
      for (final family in _kFamilies) {
        expect(
          config.tailwindConfig,
          contains('"$family-icon":"rgb(var(--coui-$family-icon))"'),
        );
      }
    },
  );

  test(':root defines each variable from the light mapping', () {
    final light = source.light().resolved(.light);
    for (final family in _kFamilies) {
      expect(
        css,
        matches(
          RegExp('--coui-$family-icon:\\s*${_rgb(_icon(light, family))};'),
        ),
        reason: family,
      );
    }
  });

  group('high contrast restates them on the raised step', () {
    for (final (name, selector, raised, normal) in [
      (
        'light',
        _lightSelector,
        source.highContrastLight().resolved(.light),
        source.light().resolved(.light),
      ),
      (
        'dark',
        _darkSelector,
        source.highContrastDark().resolved(.dark),
        source.dark().resolved(.dark),
      ),
    ]) {
      test(name, () {
        final body = block(selector).firstMatch(css)!.group(1)!;
        for (final family in _kFamilies) {
          final value = _rgb(_icon(raised, family));
          expect(value, isNot(_rgb(_icon(normal, family))), reason: family);
          expect(
            body,
            contains('--coui-$family-icon:$value;'),
            reason: family,
          );
        }
      });
    }
  });
}
