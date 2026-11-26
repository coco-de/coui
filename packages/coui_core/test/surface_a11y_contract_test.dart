import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const presets = <String, CoreSurfaceA11yContract>{
    'default': CoreSurfaceA11yContract.defaultSurface,
    'neo-brutalism': CoreSurfaceA11yContract.neoBrutalism,
    'liquid glass': CoreSurfaceA11yContract.liquidGlass,
    'neumorphism': CoreSurfaceA11yContract.neumorphism,
    'claymorphism': CoreSurfaceA11yContract.claymorphism,
  };

  group('every preset answers the contract', () {
    test('all four presets plus the baseline are declared', () {
      expect(presets, hasLength(5));
    });

    test('the baseline defers to the global ring', () {
      // Nothing about an opaque, stroke-bounded surface breaks the global
      // ring, so the baseline states no override and the resolver falls
      // through to `CoreFocusOutlineStyle`'s own defaults.
      expect(
        CoreSurfaceA11yContract.defaultSurface.focusOutlineStyle,
        equals(const CoreFocusOutlineStyle()),
      );
    });

    presets.forEach((name, contract) {
      if (name == 'default') return;
      test('$name states its ring width rather than inheriting it', () {
        // The global ring is 2px over an opaque offset. Each preset changes
        // what sits under that ring, so it has to say out loud whether 2px
        // still reads — even when the answer is "yes, unchanged".
        expect(contract.focusOutlineStyle.borderWidth, isNotNull);
      });
    });
  });

  group('shadow-only boundaries owe a forced-colours fallback', () {
    test('neumorphism declares one', () {
      // Forced colours replaces colours but creates no geometry, so a
      // boundary made of shadow simply vanishes there.
      expect(
        CoreSurfaceA11yContract.neumorphism.boundaryMechanism,
        equals(CoreSurfaceBoundaryMechanism.shadow),
      );
      expect(
        CoreSurfaceA11yContract.neumorphism.forcedColorsBoundary,
        isNotNull,
      );
    });

    test('declaring shadow without a fallback is rejected', () {
      // A declaration with no drawing path would be inert — present enough
      // to pass review, absent when it matters.
      expect(
        () => CoreSurfaceA11yContract(
          focusOutlineStyle: const CoreFocusOutlineStyle(),
          boundaryMechanism: CoreSurfaceBoundaryMechanism.shadow,
          disabledSignal: CoreSurfaceDisabledSignal.colorTokens,
          usesTransparency: false,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stroke boundaries need no fallback', () {
      for (final entry in presets.entries) {
        if (entry.value.boundaryMechanism ==
            CoreSurfaceBoundaryMechanism.stroke) {
          expect(
            entry.value.forcedColorsBoundary,
            isNull,
            reason: '${entry.key} already survives forced colours.',
          );
        }
      }
    });
  });

  group('the two presets that break assumptions say so', () {
    test('glass drops the opaque ring offset', () {
      // An opaque band (the one a component states when its background is
      // unknown) over a translucent surface paints a solid halo and defeats
      // the material, so glass states a transparent offset outright.
      expect(
        CoreSurfaceA11yContract.liquidGlass.focusOutlineStyle.offsetColor,
        equals(CoreColor.transparent),
      );
    });

    test('glass is the only preset reporting transparency', () {
      final translucent = presets.entries
          .where((e) => e.value.usesTransparency)
          .map((e) => e.key)
          .toList();
      expect(translucent, equals(['liquid glass']));
    });

    test('neo-brutalism out-weighs its own border', () {
      // A 2px ring beside a 4px black border reads as part of the border.
      expect(
        CoreSurfaceA11yContract.neoBrutalism.focusOutlineStyle.borderWidth,
        greaterThan(CoreStrokeWidth.stroke4),
      );
    });

    test('presets whose surface competes with the page flatten instead', () {
      // Neumorphism paints the page colour and glass is see-through, so a
      // recoloured foreground alone is competing with whatever is behind.
      for (final name in ['liquid glass', 'neumorphism']) {
        expect(
          presets[name]!.disabledSignal,
          equals(CoreSurfaceDisabledSignal.flattenedSurface),
          reason: '$name cannot rely on colour alone for disabled.',
        );
      }
    });
  });

  group('value equality', () {
    test('two identical contracts compare equal', () {
      expect(
        CoreSurfaceA11yContract.defaultSurface,
        equals(CoreSurfaceA11yContract.defaultSurface),
      );
    });

    test('presets are distinguishable from one another', () {
      final seen = presets.values.toSet();
      expect(seen, hasLength(presets.length));
    });
  });
}
