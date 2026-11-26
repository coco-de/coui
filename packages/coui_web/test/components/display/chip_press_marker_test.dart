import 'package:coui_web/coui_web.dart';
// chip_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The chip's press affordance and its chrome clock are one contract.
///
/// `kControlShadowPressMarker`'s rule states this element's *only*
/// `transition`, covering both the press pair (transform / box-shadow on
/// a 50ms clock) and the chrome group. An inline `transition` here would
/// outrank that rule and silently drop the press half — the pill would
/// jump into its shadow instead of travelling, with nothing failing to
/// say so. So carrying the marker and stating no `transition` have to
/// hold together, and that pair is what this pins.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));

  return context;
}

void main() {
  group('a chip presses the way a control does', () {
    testComponents('it carries the press marker', (tester) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );

      expect(
        resolved.root.className.split(' '),
        contains(kControlShadowPressMarker),
        reason:
            'without it the pill has no press affordance at all, and '
            'the Flutter twin travels while this one sits still',
      );
    });

    testComponents('it states no transition of its own', (tester) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );
      final raw = resolved.root.inlineStyles?.properties ?? const {};

      expect(
        raw.keys,
        isNot(contains('transition')),
        reason:
            'an inline transition outranks the marker rule and drops '
            'the press half of its shorthand',
      );
      // The other half of the same trade: the clock the dropped inline
      // declaration used to carry has to still reach the shared rule, or
      // the chrome transition is gone instead of the press one.
      expect(raw.keys, contains(kControlChromeDurationVar));
    });

    testComponents('its rest shadow is reachable as the press fallback', (
      tester,
    ) async {
      // Under a style that publishes no press shadow the `:active` rule
      // falls back to this variable. Absent, the fallback chain resolves
      // to nothing and the box-shadow drops on press under styles that
      // never asked for a press effect.
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );
      final raw = resolved.root.inlineStyles?.properties ?? const {};

      expect(raw['--coui-button-rest-shadow'], kControlShadowVar);
    });
    testComponents('a disabled chip takes no press marker', (tester) async {
      // `:active` is a browser state, not a handler — it fires on whatever
      // the pointer presses. A native `<button disabled>` is exempt because
      // the browser suppresses it; this pill is a `<div>`, so only leaving
      // the marker off keeps a disabled chip from squashing under the
      // cursor while its Flutter twin, gated on the same flag, sits still.
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: false,
      );

      expect(
        resolved.root.className.split(' '),
        isNot(contains(kControlShadowPressMarker)),
      );
    });

    testComponents('a disabled chip states its own transition instead', (
      tester,
    ) async {
      // The coupled half. Dropping the marker also drops the rule that
      // owned this element's only `transition`, so without stating one
      // here a disabled chip would lose its chrome fade entirely — it can
      // still change (a caller flipping `selected`).
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: false,
      );
      final raw = resolved.root.inlineStyles?.properties ?? const {};

      expect(raw.keys, contains('transition'));
      // And it must not publish the clock the shared rule reads, or both
      // would be speaking about the same shorthand.
      expect(raw.keys, isNot(contains(kControlChromeDurationVar)));
    });
  });
}
