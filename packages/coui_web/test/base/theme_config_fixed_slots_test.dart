// The fixed slots keep one colour in every mode.
//
// `scrim`, `primary-fixed-dim`, `on-primary-fixed`, `on-primary-fixed-variant`
// and `secondary-fixed` are the slots a surface stands on when switching the
// page between light, dark and high contrast must leave it alone. On this
// platform that claim is a claim about the stylesheet: a class names a slot,
// the browser reads `--coui-<slot>`, and the slot is mode-invariant exactly
// when no rule that applies in a mode writes that variable to a different
// value.
//
// Three rules can write a slot — the dark palette (attribute and media-query
// forms), the high-contrast overrides, and a surface style's palette delta —
// and each is checked here against the light value, for both kinds of colour
// source a product can ship (the CoUI look and a chromatic brand's).
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../helpers/brand_fixture.dart';

/// The slot name (the CSS variable without `--coui-`) for each colour.
const _kFixedSlots = [
  'primary-fixed-dim',
  'on-primary-fixed',
  'on-primary-fixed-variant',
  'secondary-fixed',
  'scrim',
];

/// `R G B` of [slot] as [css] declares it, or `null` when it does not.
///
/// The name is followed by `:` so `secondary-fixed` does not read
/// `secondary-fixed-dim`; the first declaration wins, which for the full
/// light block is the semantic one (the primitive ramps use other names).
String? _declared(String css, String slot) => RegExp(
  '--coui-${RegExp.escape(slot)}:\\s*(\\d+ \\d+ \\d+)',
).firstMatch(css)?.group(1);

String _rgb(CoreColor c) => '${c.red} ${c.green} ${c.blue}';

Map<String, CoreColor> _slots(ResolvedColorScheme s) => {
  'primary-fixed-dim': s.primaryFixedDim,
  'on-primary-fixed': s.onPrimaryFixed,
  'on-primary-fixed-variant': s.onPrimaryFixedVariant,
  'secondary-fixed': s.secondaryFixed,
  'scrim': s.scrim,
};

void main() {
  final sources = <String, (ThemeConfig, CoreSchemeSource)>{
    'CoUI': (ThemeConfig.defaults(), CouiColorPresets.source),
    'brand, standard mapping': (
      ThemeConfig(kBrandFixturePalette),
      CoreSemanticMappingSet.standard.bind(kBrandFixturePalette),
    ),
  };

  for (final MapEntry(key: label, value: (config, source)) in sources.entries) {
    group('fixed slots do not follow the mode — $label', () {
      final lightCss = config.cssVariables;

      test('every slot is declared in the light block', () {
        for (final slot in _kFixedSlots) {
          expect(_declared(lightCss, slot), isNotNull, reason: slot);
        }
      });

      test('the dark palette declares each slot at its light value', () {
        // Both forms a document can carry dark in: the attribute and the
        // media-query one. A slot missing from a form would be inherited from
        // `:root`, which is also the light value — so absent is not wrong,
        // but a different value is.
        for (final (form, css) in [
          ('data-theme="dark"', config.darkVariableBlock),
          ('prefers-color-scheme: dark', config.darkAutoVariableBlock),
        ]) {
          for (final slot in _kFixedSlots) {
            final dark = _declared(css, slot);
            expect(
              dark ?? _declared(lightCss, slot),
              _declared(lightCss, slot),
              reason: '$slot under $form',
            );
          }
        }
      });

      test('the dark palette does declare them, so the claim is read', () {
        // Guards the guard above: if the dark block stopped carrying these
        // slots the previous test would pass on `?? light` alone.
        for (final slot in _kFixedSlots) {
          expect(
            _declared(config.darkVariableBlock, slot),
            isNotNull,
            reason: slot,
          );
        }
      });

      test('the high-contrast block never rewrites one', () {
        // Every high-contrast block — the root's two and the brightness
        // scopes' — and nothing after them: the scopes restate the whole
        // light palette, fixed slots included, at the same values.
        final highContrast = _contrastBlocksIn(lightCss);
        expect(highContrast, isNotEmpty, reason: 'no high-contrast block');
        // Not rewritten, so under `prefers-contrast: more` the browser reads
        // the `:root` value — the same one the light and dark palettes carry.
        expect(highContrast, contains('--coui-outline:'));
        for (final slot in _kFixedSlots) {
          expect(
            highContrast,
            isNot(contains('--coui-$slot:')),
            reason: slot,
          );
        }
      });

      test('the high-contrast mapping Flutter reads agrees with that', () {
        final lightScheme = _slots(source.light().resolved(.light));
        final darkScheme = _slots(source.dark().resolved(.dark));
        final hcLight = _slots(source.highContrastLight().resolved(.light));
        final hcDark = _slots(source.highContrastDark().resolved(.dark));

        for (final slot in _kFixedSlots) {
          final value = _rgb(lightScheme[slot]!);
          expect(_declared(lightCss, slot), value, reason: 'css $slot');
          expect(_rgb(darkScheme[slot]!), value, reason: 'dark $slot');
          expect(_rgb(hcLight[slot]!), value, reason: 'hc light $slot');
          expect(_rgb(hcDark[slot]!), value, reason: 'hc dark $slot');
        }
      });

      test('no surface style rewrites one', () {
        final styles = config.surfaceStyleVariableBlocks;
        expect(styles, isNotEmpty);
        for (final slot in _kFixedSlots) {
          expect(styles, isNot(contains('--coui-$slot:')), reason: slot);
        }
      });
    });
  }

  group('a slot that follows the mode is the contrast the guard needs', () {
    test('surface differs between light and dark', () {
      // If every slot matched across modes these tests could not fail; this
      // one shows the comparison is capable of seeing a difference.
      final config = ThemeConfig.defaults();
      expect(
        _declared(config.cssVariables, 'surface'),
        isNot(_declared(config.darkVariableBlock, 'surface')),
      );
    });
  });
}

/// The bodies of every `prefers-contrast: more` block in [css], joined.
String _contrastBlocksIn(String css) {
  const opening = '@media (prefers-contrast:more){';
  final bodies = StringBuffer();
  var from = css.indexOf(opening);
  while (from >= 0) {
    // Brace-matched, so a block ends where its own `}` closes it.
    var depth = 1;
    var i = from + opening.length;
    final start = i;
    for (; i < css.length && depth > 0; i++) {
      if (css[i] == '{') depth++;
      if (css[i] == '}') depth--;
    }
    bodies.write(css.substring(start, i - 1));
    from = css.indexOf(opening, i);
  }

  return bodies.toString();
}
