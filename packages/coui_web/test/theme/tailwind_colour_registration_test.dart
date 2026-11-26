// Every colour slot that generates a CSS variable must also be a Tailwind
// colour — otherwise the class that names it paints nothing.
//
// The two halves live apart and neither knows about the other.
// `PrimitiveCssGenerator` walks the scheme and emits `--coui-{slot}` for
// each entry in its own map; the Tailwind `colors:{…}` block in
// `ThemeConfig` is a hand-written string. Adding a slot updates the first
// automatically and the second not at all.
//
// What that failure looks like is the problem: the variable is present in
// the document, the class is present on the element, the markup reads
// exactly as intended — and the browser has no rule for that class, so the
// paint is simply absent. Nothing throws, no test that inspects emitted
// class names notices, and a screenshot only shows it if someone knows
// which pixel to doubt.
//
// It has already happened once. `error-strong` was added for the
// destructive button's pressed state, reached the resolver, reached the
// markup as `bg-error-strong`, and generated no CSS at all, because
// nobody added the matching entry here.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:test/test.dart';

/// Every SEMANTIC colour slot, by the name its CSS variable uses.
///
/// From the generator that writes the variables, not from the scheme's own
/// `toMap()`: that map is a serialisation vocabulary and leaves out the
/// `-fixed` family, which has variables and is named by classes, so only the
/// generator's list carries every slot a class can name. The CSS block also
/// carries the primitive ramps (`--coui-primary-600` and friends); those
/// come from a different generator method and are deliberately not Tailwind
/// colours — a ramp step is what a semantic slot points AT, not something a
/// component names.
Set<String> _semanticColourSlots() => PrimitiveCssGenerator.semanticVarsFor(
  CouiColorPresets.source,
  .light,
).keys.map((name) => name.substring('--coui-'.length)).toSet();

/// Every colour name the Tailwind config declares.
Set<String> _registeredColourNames() {
  final config = ThemeConfig.defaults().tailwindConfig;
  return RegExp(
    r'"?([a-z0-9-]+)"?\s*:\s*"rgb\(var\(--coui-([a-z0-9-]+)\)\)"',
  ).allMatches(config).map((m) => m.group(2)!).toSet();
}

void main() {
  group('a generated colour variable is a usable Tailwind colour', () {
    test('every emitted slot is registered', () {
      final generated = _semanticColourSlots();
      final registered = _registeredColourNames();

      expect(
        generated,
        isNotEmpty,
        reason:
            'the extraction found nothing — the regex has gone stale, '
            'which would make this test pass by measuring an empty set',
      );

      // Ratchet, not a clean sweep. One slot is unregistered today and
      // this test is not the place to decide whether it should be — but a
      // NEW one is always a mistake, and that is what this catches.
      const known = {'surface-highlight'};

      final unregistered = generated.difference(registered);
      expect(
        unregistered.difference(known),
        isEmpty,
        reason:
            'these slots emit a --coui-* variable but are not Tailwind '
            'colours, so any bg-/text-/ring-/border- class naming them '
            'produces no CSS: '
            '${unregistered.difference(known).toList()..sort()}',
      );
      expect(
        known.difference(unregistered),
        isEmpty,
        reason:
            'a slot on the known list is registered now — take it off the '
            'list so the list keeps shrinking rather than going stale',
      );
    });

    test('the fixed slots in particular', () {
      // The `-fixed` family and `scrim` resolve to one colour in all four
      // modes, for a surface that must look the same in each. A class that
      // names one (`bg-scrim`, `border-on-primary-fixed-variant`) needs an
      // entry here, or it paints nothing — the fill is absent, and the
      // border falls back to the text colour.
      expect(
        _registeredColourNames(),
        containsAll(const [
          'scrim',
          'primary-fixed-dim',
          'on-primary-fixed',
          'on-primary-fixed-variant',
          'secondary-fixed',
        ]),
      );
    });

    test('the focus ring in particular', () {
      // Called out on its own because the ring is the one colour whose
      // absence is hardest to notice: a missing focus indicator looks like
      // a control that simply is not focused, and keyboard users are the
      // people who would find out.
      expect(_registeredColourNames(), contains('focus-ring'));
    });
  });
}
