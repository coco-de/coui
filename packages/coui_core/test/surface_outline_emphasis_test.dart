import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

const _heavy = CoreSurfaceColorConstraint(outlineEmphasis: 1);

void main() {
  // The same promises for both mappings that ship: a brand palette read
  // through the standard mapping, and CoUI's own source.
  _outlineEmphasisSuite(
    'standard mapping on a brand palette',
    kBrandFixtureSource,
  );
  _outlineEmphasisSuite('CoUI', CouiColorPresets.source);

  const heavy = _heavy;

  group('identity and equality', () {
    test('zero emphasis is identity and costs nothing', () {
      const none = CoreSurfaceColorConstraint();
      final authored = CouiColorPresets.source.light();
      expect(none.isIdentity, isTrue);
      expect(none.apply(authored), same(authored));
    });

    test('an emphasis makes the constraint non-identity', () {
      // Load-bearing: the contrast guard uses this to decide which presets
      // owe it a registered scheme, and the Web emitter uses it to decide
      // whether to write a rule at all.
      expect(heavy.isIdentity, isFalse);
    });

    test('it is inside value equality', () {
      expect(heavy, isNot(equals(const CoreSurfaceColorConstraint())));
      expect(
        heavy.hashCode,
        isNot(equals(const CoreSurfaceColorConstraint().hashCode)),
      );
    });

    test('copyWith carries it', () {
      expect(
        const CoreSurfaceColorConstraint().copyWith(outlineEmphasis: 1),
        equals(heavy),
      );
    });
  });
}

void _outlineEmphasisSuite(String name, CoreSchemeSource source) {
  const heavy = _heavy;
  CoreColorScheme base(CoreBrightness b) =>
      b == CoreBrightness.light ? source.light() : source.dark();

  group('$name: a boundary statement reaches both boundary tones', () {
    test('the stronger tone moves', () {
      final before = base(.light).outline!;
      final after = heavy.apply(base(.light)).outline!;
      expect(after, isNot(equals(before)));
    });

    test('the subtler tone moves too', () {
      // The shared outlined-box primitive defaults its border to this tone,
      // and 13 components reference only it. Moving one and not the other
      // darkens some borders and leaves others pale.
      final before = base(.light).outlineVariant!;
      final after = heavy.apply(base(.light)).outlineVariant!;
      expect(after, isNot(equals(before)));
    });

    test('nothing else is disturbed', () {
      final before = base(.light);
      final after = heavy.apply(before);
      expect(after.onSurface, equals(before.onSurface));
      expect(after.surface, equals(before.surface));
      expect(after.primary, equals(before.primary));
    });
  });

  group('$name: one declaration serves both modes', () {
    test('light goes dark and dark goes light', () {
      // This is why the field names a destination rather than carrying a
      // colour or a shift: an absolute near-black is invisible on a dark
      // page, where the surface is already near-black.
      final light = heavy.apply(base(.light)).outline!;
      final dark = heavy.apply(base(.dark)).outline!;

      expect(CoreContrast.relativeLuminance(light), lessThan(0.1));
      expect(CoreContrast.relativeLuminance(dark), greaterThan(0.8));
    });

    test('the boundary becomes far more legible in both', () {
      for (final mode in CoreBrightness.values) {
        final authored = base(mode);
        final styled = heavy.apply(authored);
        final surface = authored.surface!;

        expect(
          CoreContrast.ratio(styled.outline!, surface),
          greaterThan(CoreContrast.ratio(authored.outline!, surface)),
          reason: '$mode boundary did not improve',
        );
        expect(
          CoreContrast.ratio(styled.outline!, surface),
          greaterThanOrEqualTo(3),
          reason: '$mode boundary is under the 3:1 floor for a control edge',
        );
      }
    });
  });

  group('$name: the app keeps its own tint', () {
    test('chroma survives the push as far as the destination holds it', () {
      // The push moves lightness only. Chroma coming through intact is what
      // makes this a derivation of the app's colour rather than a swap for
      // a literal — as far as sRGB has room for it at the new lightness.
      // Near white there is little: CoUI's dark outline (neutral/500,
      // c ≈ 0.021) pushed to its near-white foreground cannot keep all of
      // it (≈ 0.016 fits). Clamping channels there instead turns the hue
      // and pulls the lightness off the destination, so the lightness is
      // the checkable claim in that case and the chroma only has to shrink,
      // not vanish.
      for (final mode in CoreBrightness.values) {
        final authored = base(mode);
        final before = CoreColorConversion.colorToOKLch(authored.outline!);
        final target = CoreColorConversion.colorToOKLch(authored.onSurface!).l;
        final after = CoreColorConversion.colorToOKLch(
          heavy.apply(authored).outline!,
        );
        expect(
          after.l,
          closeTo(target, 0.002),
          reason: '$mode left the destination lightness',
        );

        // Whether the authored chroma survives a trip at the destination
        // lightness is a property of sRGB, asked of the conversion itself.
        final asked = CoreColorConversion.colorToOKLch(
          CoreColorConversion.oklchToColor(
            target,
            before.c,
            before.h,
            before.a,
          ),
        );
        if ((asked.l - target).abs() <= 0.002) {
          expect(after.c, closeTo(before.c, 0.001), reason: '$mode');
        } else {
          expect(after.c, lessThan(before.c), reason: '$mode');
          expect(after.c, greaterThan(0), reason: '$mode lost the whole tint');
        }
      }
    });

    test("the palette's blue tint is still there at both ends", () {
      // Hue is deliberately not asserted tightly: the outline neutrals sit
      // at low chroma (~0.004 on the brand palette, ~0.02 on CoUI's), where
      // 8-bit rounding swings the recovered angle by several degrees
      // without changing the colour perceptibly.
      // The tint itself is the checkable claim — a literal black or white
      // would be exactly neutral and would lose it.
      for (final mode in CoreBrightness.values) {
        final c = heavy.apply(base(mode)).outline!;
        expect(
          c.blue,
          greaterThan(c.red),
          reason: '$mode lost the neutral hue and went flat grey',
        );
      }
    });
  });

  group('$name: partial emphasis is partial', () {
    test('half lands between the two ends', () {
      const half = CoreSurfaceColorConstraint(outlineEmphasis: 0.5);
      final authored = base(.light).outline!;
      final full = heavy.apply(base(.light)).outline!;
      final mid = half.apply(base(.light)).outline!;

      expect(
        CoreContrast.relativeLuminance(mid),
        lessThan(CoreContrast.relativeLuminance(authored)),
      );
      expect(
        CoreContrast.relativeLuminance(mid),
        greaterThan(CoreContrast.relativeLuminance(full)),
      );
    });

    test('a fraction outside the range is rejected', () {
      expect(
        () => CoreSurfaceColorConstraint(outlineEmphasis: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
