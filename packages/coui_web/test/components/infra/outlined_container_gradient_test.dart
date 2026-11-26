import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

const _gradient = CoreGradient(
  type: CoreGradientType.linear,
  colors: [CoreColor(0xFFC3C4C6), CoreColor(0xFF7D7F82)],
  stops: [0, 1],
  begin: CoreAlignment.topCenter,
  end: CoreAlignment.bottomCenter,
);

void main() {
  group('OutlinedContainer — a gradient fill', () {
    testComponents('is painted as an inline background-image', (tester) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(
          backgroundGradient: _gradient,
        ),
      );
      final p = r.root.inlineStyles!.properties;
      expect(
        p['background-image'],
        'linear-gradient(180deg, rgb(195, 196, 198) 0%, '
        'rgb(125, 127, 130) 100%)',
      );
      // Spanning the border box, as the fill of the Flutter twin does.
      expect(p['background-origin'], 'border-box');
    });

    testComponents('replaces the surface colour: class XOR inline', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final solid = resolveOutlinedContainer(context: context);
      // The default fill is a token → a `bg-*` class.
      expect(solid.root.className, contains('bg-surface'));

      final gradient = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          backgroundGradient: _gradient,
        ),
      );
      expect(gradient.root.className, isNot(contains('bg-')));
      expect(
        gradient.root.inlineStyles!.properties.containsKey('background-color'),
        isFalse,
      );

      // A stated raw colour (an inline fill) is dropped just the same.
      final raw = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          backgroundColor: CoreColor(0xFF112233),
          backgroundGradient: _gradient,
        ),
      );
      expect(
        raw.root.inlineStyles!.properties.containsKey('background-color'),
        isFalse,
      );
      expect(
        raw.root.inlineStyles!.properties['background-image'],
        isNotNull,
      );
    });

    testComponents('leaves border, radius and shadow alone', (tester) async {
      final context = _themedContext(tester);
      const base = CoreOutlinedContainerStyle(
        borderColor: CoreColor(0xFF646568),
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        boxShadow: CoreShadow.xl,
      );
      final without = resolveOutlinedContainer(
        context: context,
        containerStyle: base,
      ).root.inlineStyles!.properties;
      final withGradient = resolveOutlinedContainer(
        context: context,
        containerStyle: base.merge(
          const CoreOutlinedContainerStyle(backgroundGradient: _gradient),
        ),
      ).root.inlineStyles!.properties;
      for (final key in [
        'border-width',
        'border-color',
        'border-radius',
        'box-shadow',
        'overflow',
      ]) {
        expect(withGradient[key], without[key], reason: key);
      }
    });

    testComponents("surfaceOpacity scales every stop's alpha", (tester) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(
          surfaceOpacity: 0.5,
          backgroundGradient: CoreGradient(
            type: CoreGradientType.linear,
            colors: [
              CoreColor(0xFFFFFFFF),
              CoreColor(0x80FFFFFF),
              CoreColor.token(CoreColors.surface),
            ],
            stops: [0, 0.5, 1],
            begin: CoreAlignment.topCenter,
            end: CoreAlignment.bottomCenter,
          ),
        ),
      );
      expect(
        r.root.inlineStyles!.properties['background-image'],
        'linear-gradient(180deg, rgba(255, 255, 255, 0.50) 0%, '
        'rgba(255, 255, 255, 0.25) 50%, '
        'rgb(var(--coui-surface) / 50%) 100%)',
      );
    });

    testComponents('publishes no single fill for a preset to restate', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final solid = resolveOutlinedContainer(
        context: context,
      ).root.inlineStyles!.properties;
      expect(solid.containsKey(kWebSurfaceFillVar), isTrue);

      final gradient = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          backgroundGradient: _gradient,
        ),
      ).root.inlineStyles!.properties;
      expect(gradient.containsKey(kWebSurfaceFillVar), isFalse);
    });

    testComponents('null changes nothing for any other surface', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final plain = resolveOutlinedContainer(context: context);
      final p = plain.root.inlineStyles!.properties;
      expect(p.containsKey('background-image'), isFalse);
      expect(p.containsKey('background-origin'), isFalse);
      expect(plain.root.className, contains('bg-surface'));
    });
  });

  group('OutlinedContainer — a raw border colour is a border', () {
    testComponents('an opaque raw colour keeps its width', (tester) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(
          borderColor: CoreColor(0xFF646568),
        ),
      );
      // A raw colour carries no token, which is not the same as being
      // transparent: the rim of a hardware part is opaque and must be drawn.
      expect(
        r.root.inlineStyles!.properties['border-width'],
        isNot(strokeWidthCss(0)),
      );
      expect(
        r.root.inlineStyles!.properties['border-color'],
        'rgb(100, 101, 104)',
      );
    });

    testComponents('a fully transparent colour still collapses it', (
      tester,
    ) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(
          borderColor: CoreColor.transparent,
        ),
      );
      expect(
        r.root.inlineStyles!.properties['border-width'],
        strokeWidthCss(0),
      );
    });
  });

  group('OutlinedContainer — a fixed-slot body', () {
    // A body that must not follow the mode: a top-to-bottom gradient whose
    // stops are fixed slots, a fixed-slot rim, and a fixed-slot solid
    // underneath that the gradient replaces.
    const frame = CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.onPrimaryFixedVariant),
      backgroundGradient: CoreGradient(
        type: CoreGradientType.linear,
        colors: [
          CoreColor.token(CoreColors.primaryFixedDim),
          CoreColor.token(CoreColors.onPrimaryFixedVariant),
          CoreColor.token(CoreColors.onPrimaryFixedVariant),
          CoreColor.token(CoreColors.primaryFixedDim),
        ],
        stops: [0, 0.1, 0.9, 1],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      ),
      borderColor: CoreColor.token(CoreColors.onPrimaryFixedVariant),
    );

    testComponents('token stops stay variable references, in order', (
      tester,
    ) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: frame,
      );
      final p = r.root.inlineStyles!.properties;
      // A slot name, not a resolved colour: the browser settles it, so the
      // body is the same under every theme the slot is the same under.
      expect(
        p['background-image'],
        'linear-gradient(180deg, '
        'rgb(var(--coui-primary-fixed-dim)) 0%, '
        'rgb(var(--coui-on-primary-fixed-variant)) 10%, '
        'rgb(var(--coui-on-primary-fixed-variant)) 90%, '
        'rgb(var(--coui-primary-fixed-dim)) 100%)',
      );
      expect(p['background-origin'], 'border-box');
    });

    testComponents('the gradient replaces the token solid under it', (
      tester,
    ) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: frame,
      );
      final p = r.root.inlineStyles!.properties;
      // Class XOR inline: neither the solid's class nor an inline colour is
      // left under a gradient whose stops could be translucent.
      expect(r.root.className, isNot(contains('bg-')));
      expect(p.containsKey('background-color'), isFalse);
      // A gradient is not one fill a surface style could restate.
      expect(p.containsKey(kWebSurfaceFillVar), isFalse);
    });

    testComponents('the rim is a token border class, opaque and drawn', (
      tester,
    ) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: frame,
      );
      final p = r.root.inlineStyles!.properties;
      expect(
        r.root.className.split(' '),
        contains('border-on-primary-fixed-variant'),
      );
      expect(p.containsKey('border-color'), isFalse);
      // A slot is not transparent, so the stroke keeps its width.
      expect(p['border-width'], isNot(strokeWidthCss(0)));
    });

    testComponents("surfaceOpacity scales a token stop's alpha, not its slot", (
      tester,
    ) async {
      final r = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: frame.merge(
          const CoreOutlinedContainerStyle(surfaceOpacity: 0.5),
        ),
      );
      expect(
        r.root.inlineStyles!.properties['background-image'],
        startsWith(
          'linear-gradient(180deg, '
          'rgb(var(--coui-primary-fixed-dim) / 50%) 0%, '
          'rgb(var(--coui-on-primary-fixed-variant) / 50%) 10%, ',
        ),
      );
    });
  });

  group('OutlinedContainer widget', () {
    testComponents('renders the gradient with no child', (tester) async {
      pumpWithTheme(
        tester,
        const OutlinedContainer(
          containerStyle: CoreOutlinedContainerStyle(
            backgroundGradient: _gradient,
          ),
        ),
      );
      final box =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent &&
                        (c.styles?.properties.containsKey('background-image') ??
                            false),
                  )
                  .evaluate()
                  .single
                  .component
              as DomComponent;
      expect(box.styles!.properties['background-origin'], 'border-box');
    });
  });
}
