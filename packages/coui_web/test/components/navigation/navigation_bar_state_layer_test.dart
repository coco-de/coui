import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart and chip_style.dart are not re-exported by the
// barrel (the resolvers are internal chrome) — import them directly for
// resolver-level assertions.
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The NavigationBar's own state-layer ramp, read back where it lands.
///
/// `CoreNavigationBarStyle.defaultStateLayer` is 3 / 8 / 8 — the subtle
/// tier's hover and focus, and a pressed wash that stops at 8 % so the
/// unselected label keeps 4.5 : 1 over it in dark. Web states the wash as a
/// `color-mix()` weight in scoped rules, so the percentage in the emitted
/// CSS is what is read here, not the Core constant: a resolver that stopped
/// reading the field — or kept reading `CoreStateLayer.subtle` — fails.
///
/// The second group is the other half of the claim: the shared subtle ramp
/// is still 12 % pressed for the component that reads it.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// `color-mix(in srgb, <ink> N%, <base>)` weight per pseudo-class, in the
/// order the rules are written.
Map<String, int> _weights(String css) {
  final rule = RegExp(
    r':(hover|focus-visible|active)(?:>\.[\w-]+)?\{background-color:'
    r'color-mix\(in srgb, rgb\(var\(--coui-[\w-]+\)\) (\d+)%,',
  );
  return {
    for (final m in rule.allMatches(css)) m.group(1)!: int.parse(m.group(2)!),
  };
}

String _barRules(BuildContext context, {CoreNavigationBarStyle? style}) =>
    resolveNavigationBarRules(
      context,
      mode: CoreNavigationBarMode.bar,
      variant: CoreNavigationBarVariant.defaultVariant,
      // The ramp is the `fill` indicator's; the bar's own default (`color`)
      // lays no wash on hover or focus.
      indicator: CoreNavigationSelectionIndicator.fill,
      navigationBarStyle: style,
    ).css;

ResolvedChipRules _chipRules(BuildContext context, {CoreChipStyle? style}) =>
    resolveChipRules(
      context,
      variant: CoreChipVariant.outlined,
      chipColor: CoreChipColor.defaultColor,
      size: CoreChipSize.defaultSize,
      selected: false,
      emphasis: CoreChipEmphasis.defaultEmphasis,
      enabled: true,
      chipStyle: style,
    );

void main() {
  group('NavigationBar emits its own 3 / 8 / 8 ramp', () {
    testComponents('hover 3 %, focus 8 %, pressed 8 %', (tester) async {
      final context = _themedContext(tester);

      expect(_weights(_barRules(context)), {
        'hover': 3,
        'focus-visible': 8,
        'active': 8,
      });
    });

    testComponents("pressed is NOT the subtle tier's 12 %", (tester) async {
      final context = _themedContext(tester);

      expect(
        _weights(_barRules(context))['active'],
        isNot(12),
        reason: 'pressed fell back to the shared subtle ramp',
      );
    });

    testComponents('focus and pressed wash alike, hover is lighter', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final weights = _weights(_barRules(context));

      expect(weights['focus-visible'], weights['active']);
      expect(weights['hover'], lessThan(weights['focus-visible']!));
    });

    testComponents('the instance slot still wins over the default', (
      tester,
    ) async {
      final context = _themedContext(tester);

      // The field is the live source: handing the subtle ramp back through
      // it restores the 12 % pressed wash, which only holds if the resolver
      // reads `merged.stateLayer` and not a number of its own.
      expect(
        _weights(
          _barRules(
            context,
            style: const CoreNavigationBarStyle(
              stateLayer: CoreStateLayer.subtle,
            ),
          ),
        ),
        {'hover': 3, 'focus-visible': 8, 'active': 12},
      );
    });

    testComponents('the rules scope names the weights they carry', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final css = _barRules(context);
      const chrome = CoreNavigationBarVariant.defaultVariant;
      // The bar's face: its mode cell's, else the variant's.
      final base =
          CoreNavigationBarStyle
              .defaultsByMode[CoreNavigationBarMode.bar]!
              .backgroundColor ??
          CoreNavigationBarStyle.defaultsByVariant[chrome]!.backgroundColor;

      String scopeFor(CoreStateLayer layer) =>
          navigationBarStateLayerScopeClass(
            ink: CoreNavigationBarStyle.defaultStateLayerColor,
            base: base,
            layer: layer,
          );

      // Content-addressed off the weights: the default's class is on the
      // rules, and the subtle ramp's class is not — so a bar that rendered
      // the old 12 % would be wearing a class these rules never select.
      expect(
        css,
        contains(scopeFor(CoreNavigationBarStyle.defaultStateLayer)),
      );
      expect(css, isNot(contains(scopeFor(CoreStateLayer.subtle))));
    });
  });

  group('the shared subtle ramp is still 12 % pressed', () {
    testComponents("Chip's default is 3 / 8 / 12", (tester) async {
      final context = _themedContext(tester);

      final defaults = _chipRules(context);
      const expectedLayer = CoreStateLayer.subtle;
      expect(
        [expectedLayer.hover, expectedLayer.focus, expectedLayer.pressed],
        [.03, .08, .12],
      );
      // Pin the public slot independently of its CSS serialization. The
      // browser regression checks which computed pseudo-state uses each
      // weight, including the transparent resting face.
      expect(
        defaults.css,
        _chipRules(
          context,
          style: const CoreChipStyle(
            stateLayer: expectedLayer,
          ),
        ).css,
      );
      expect(
        defaults.css,
        isNot(
          _chipRules(
            context,
            style: const CoreChipStyle(
              stateLayer: CoreStateLayer(hover: .03, focus: .08, pressed: .08),
            ),
          ).css,
        ),
        reason: 'the instance ramp must be consumed, not silently ignored',
      );
    });

    testComponents('and equals an explicit subtle, byte for byte', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        _chipRules(context).css,
        _chipRules(
          context,
          style: const CoreChipStyle(stateLayer: CoreStateLayer.subtle),
        ).css,
      );
    });
  });
}
