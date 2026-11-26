import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// The geometry block a style emits, or `''` when it emits none.
String _block(CoreSurfaceStyleId id) {
  final recipe = CoreSurfaceRecipe.of(id);

  return ThemeConfig.defaults().surfaceStyleGeometryBlock(
    id,
    recipe.geometry,
    typography: recipe.typography,
  );
}

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveXxx` directly, the same way `text_area_style_test.dart`
/// does — the rim mechanism is a compile-time string reference
/// (`kSurfaceRimVar`), not a claymorphism-conditioned value, so no active
/// style needs to be set up to see whether a resolver emits it.
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

void main() {
  group('a style that states a rim draws one', () {
    test('claymorphism emits the highlight tint in its shadow steps', () {
      // Declared-but-undrawn is this axis's recurring failure, and it is
      // invisible: the recipe reads complete, the value has an equality
      // entry, and nothing on screen changes. Reading the emitted CSS is
      // the only thing that separates the two.
      final css = _block(.claymorphism);

      // Its own variable, not smeared across every shadow step: the
      // step scale is elevation MAGNITUDE and spans controls, while a
      // rim is a surface MATERIAL. Panels opt in by naming it.
      expect(css, contains('--coui-surface-rim'));
      expect(css, contains('--coui-surface-highlight'));
    });

    test('the rim is not appended to the shadow steps', () {
      // The regression this replaces: appending it to all eight steps
      // put a 55%-alpha inset glow on a 12px toggle knob, whose fill is
      // `onSurface` while the rim is derived from `surface`.
      final css = _block(.claymorphism);
      final steps = css.split(';').where((d) => d.startsWith('--shadow-'));

      expect(steps, isNotEmpty, reason: 'clay still bends the cast blur');
      expect(
        steps.every((d) => !d.contains('--coui-surface-highlight')),
        isTrue,
        reason:
            'a shadow step carries the rim, so every lifted control '
            'gets one whether or not it is a surface',
      );
    });

    test('the no-rim default is a renderable layer, not an empty value', () {
      // Measured in a browser: with the variable undefined, a panel
      // whose declaration names it lost its cast shadow entirely —
      // `box-shadow` computed to `none`. An invalid custom property
      // takes the whole declaration with it, so the no-rim case has to
      // be a real layer rather than an empty string.
      final declared = RegExp(
        '--coui-surface-rim:([^;]+);',
      ).firstMatch(ThemeConfig.defaults().cssVariables);

      expect(declared, isNotNull, reason: 'the base stylesheet omits it');
      expect(declared!.group(1)!.trim(), isNotEmpty);
      expect(
        declared.group(1),
        contains('transparent'),
        reason: 'the default rim paints something',
      );
    });

    test('a panel names the variable rather than baking a rim', () {
      // The opt-in. A panel that stopped naming it would silently drop
      // the rim on Web while Flutter kept drawing one.
      expect(kSurfaceRimVar, 'var(--coui-surface-rim)');
    });

    test('a style with no rim emits no rim variable', () {
      // The tint is a statement, not a default. A style that says
      // nothing about a rim must not acquire one.
      for (final id in CoreSurfaceStyleId.values) {
        if (CoreSurfaceRecipe.of(id).geometry.highlightRim.isNotEmpty) {
          continue;
        }
        expect(
          _block(id),
          isNot(contains('--coui-surface-rim')),
          reason: '${id.name} states no rim but emits one',
        );
      }
    });
  });

  group('the variable the rim points at is always defined', () {
    test('both stylesheets declare it', () {
      // An undefined custom property does not degrade to "no rim" — it
      // invalidates the whole `box-shadow` declaration, taking the cast
      // shadow with it. That is why the palette derives one when a
      // palette states none.
      final config = ThemeConfig.defaults();

      expect(config.cssVariables, contains('--coui-surface-highlight'));
    });
  });

  // Every `.coui-surface`-marked component reads the rim on the shadow
  // stack it states (#3463, #5434); the `.coui-surface` marker set and
  // the rim-reading set are not two separate lists to keep in sync. A
  // surface that states no stack takes only the contributed cast
  // (`--coui-control-shadow`), and the rim does not ride a cast the
  // surface did not state — Flutter's `resolveSurfaceRim` lights the rim
  // only on a stack the surface states, so a rim on a flat Web surface is
  // a rim only one platform draws.
  //
  // `scaffold` / `dock` / `navigation_bar` / `tooltip` are marked but
  // carry no `box-shadow` on either platform (full-bleed structural
  // chrome, not an elevated box) — there is no shadow property to append
  // a rim layer to, so they are not covered here, not an oversight.
  group('every marked surface reads the rim on the stack it states', () {
    testComponents('OutlinedContainer — elevation-preset path', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(elevation: .medium),
      );

      expect(
        resolved.root.inlineStyles?.properties['box-shadow'],
        contains(kSurfaceRimVar),
      );
    });

    testComponents('OutlinedContainer — a flat container states no stack '
        'and takes no rim', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveOutlinedContainer(context: context);

      expect(
        resolved.root.inlineStyles?.properties['box-shadow'],
        kControlShadowVar,
        reason: 'the contributed cast alone — the rim rides a stated stack',
      );
    });

    testComponents('OutlinedContainer — explicit-shadow-stack path', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const explicit = [
        (
          offsetX: 0.0,
          offsetY: 2.0,
          blurRadius: 4.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      final resolved = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          boxShadow: explicit,
        ),
      );

      expect(
        resolved.root.inlineStyles?.properties['box-shadow'],
        contains(kSurfaceRimVar),
      );
    });

    testComponents('Card — explicit-shadow-stack path', (tester) async {
      final context = _themedContext(tester);
      const explicit = [
        (
          offsetX: 0.0,
          offsetY: 4.0,
          blurRadius: 8.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      final resolved = resolveCard(
        context,
        variant: .defaultVariant,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(boxShadow: explicit),
      );

      expect(
        resolved.root.inlineStyles?.properties['box-shadow'],
        contains(kSurfaceRimVar),
      );
    });

    testComponents('Dialog — panel', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveDialog(context);

      expect(
        resolved.panel.inlineStyles?.properties['box-shadow'],
        contains(kSurfaceRimVar),
      );
    });
  });
}
