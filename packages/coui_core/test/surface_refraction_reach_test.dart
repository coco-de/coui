// Tripwire: how far into the surface a refracted read lands, against the
// surface's own footprint.
//
// A rim sample is displaced **inward** (`displacementAt` is negative) by an
// amount that is a multiple of the band, and the band is a fraction of the
// shorter side — so the reach is a fraction of the shorter side too, whatever
// the size. That is why a small chip cannot overshoot where a large panel does
// not, and it is also why nothing structural stops a request from reaching
// past the far edge: `CoreSurfaceRefraction` bounds each of its dials
// separately, and the bounds multiply. At the constructor's own limits
// (bezel .5, strength 1, dispersion 1) the read lands 2.5 shorter sides deep.
//
// Past the far edge the two renderers stop agreeing. The Flutter shader
// clamps the read to the whole backdrop texture, so it samples outside the
// glass; the Web displacement map reads outside its filter region. Neither is
// the picture the model describes, and the two differ from each other. The
// shipped values keep a margin — the tightest lands at about 0.87 of the
// shorter side — but the Figma-style constructor makes it one slider move
// away: Refraction 80 -> 100 puts the red channel past the edge.
//
// What this does and does not decide. It does **not** cap the bend at run
// time: how a request that exceeds the footprint should render (clamp it,
// scale it, leave it to the author) is a design call, and any cap would have
// to be mirrored in the shader and the Web map. It only makes sure that
// moving a shipped value across the line is a deliberate act with a failing
// test attached, and that the number it moves from is written down.
//
// The landing is computed here from the public `displacementAt`,
// `dispersionUnit` and `lensDisplacement`, along the axis a rim pixel is
// nearest — the axis on which the reach is greatest, because a diagonal
// normal spends part of its travel along the other axis. It is measured from
// the **same** edge the sample was displaced from, in units of the shorter
// side, so 1 is the far edge.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The shorter side, as the unit every landing is measured in.
const double _short = 1;

/// How finely the band is walked. The deepest landing is at the rim for any
/// value this kit ships, but the walk does not assume it.
const int _steps = 1024;

/// The deepest any of the three colour channels reads, from the same edge,
/// in shorter sides.
///
/// The channels are the shader's and the Web filter's: red travels
/// `1 + spread` times the shared bend, green exactly it, blue `1 - spread`,
/// with `spread = dispersionUnit x dispersion`. The dome then pulls the read
/// toward the centre by `lens` of its distance from it, so it is applied to
/// the bent position, as the shader does.
double _deepestLanding(CoreSurfaceRefraction refraction) {
  final band = refraction.bezel * _short;
  final spread = CoreSurfaceRefraction.dispersionUnit * refraction.dispersion;
  final channels = [1 + spread, 1.0, 1 - spread];

  var deepest = 0.0;
  for (var step = 0; step <= _steps; step++) {
    final inset = band * step / _steps;
    final bend = refraction.displacementAt(insetPx: inset, bandPx: band).abs();
    for (final channel in channels) {
      final bent = inset + (bend * channel);
      final landed = bent + refraction.lensDisplacement(bent - (_short / 2));
      if (landed > deepest) deepest = landed;
    }
  }

  return deepest;
}

const String _kWhyItMatters =
    'The read lands past the far edge of the shortest surface that carries '
    'this request. Flutter then samples outside the glass (the shader clamps '
    'to the whole backdrop) and the Web map reads outside its filter region, '
    'so the two platforms stop drawing the same picture. Lower the value, or '
    'decide how an over-reaching request should render and mirror that in '
    'the shader and the Web map.';

void main() {
  group('every shipped refraction reads from inside its own footprint', () {
    test('each style preset that bends', () {
      final presets = {
        for (final entry in CoreSurfaceRecipe.presets.entries)
          if (entry.value.refraction != null)
            entry.key: entry.value.refraction!,
      };

      expect(
        presets.keys,
        contains(CoreSurfaceStyleId.liquidGlass),
        reason:
            'the guard has nothing to look at if the glass preset stops '
            'stating a refraction',
      );
      for (final MapEntry(:key, :value) in presets.entries) {
        expect(
          _deepestLanding(value),
          lessThanOrEqualTo(1.0),
          reason: '${key.name}: $_kWhyItMatters',
        );
      }
    });

    test('the navigation bar glass, resting and selection', () {
      for (final (name, refraction) in [
        ('resting', CoreNavigationBarStyle.glassRestingRefraction),
        ('selection', CoreNavigationBarStyle.glassSelectionRefraction),
      ]) {
        expect(
          _deepestLanding(refraction),
          lessThanOrEqualTo(1.0),
          reason: 'navigation $name: $_kWhyItMatters',
        );
      }
    });
  });

  group('and the margin they keep is written down', () {
    // Pinned, not just bounded: a shipped value that creeps toward the line
    // still passes `<= 1`, and the first anyone hears of it is the change
    // that finally crosses it. Tolerance is wide enough for the sampling and
    // narrow enough that a tenth of a dial notch moves it.
    const tolerance = 0.01;

    test('the glass preset lands about 0.87 deep', () {
      final glass = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).refraction!;

      expect(_deepestLanding(glass), closeTo(0.868, tolerance));
    });

    test('the navigation lens lands about 0.17 deep', () {
      expect(
        _deepestLanding(CoreNavigationBarStyle.glassSelectionRefraction),
        closeTo(0.166, tolerance),
      );
    });

    test('the resting navigation pane lands about 0.12 deep', () {
      expect(
        _deepestLanding(CoreNavigationBarStyle.glassRestingRefraction),
        closeTo(0.120, tolerance),
      );
    });

    test('and the rim is where the glass preset reaches deepest', () {
      // The closed form at the rim, independent of the walk above: the bend
      // there is `travelPerBand x strength x bezel / index`, the red channel
      // takes `1 + spread` of it, and the dome pulls the result toward the
      // centre. If the sampled number and this ever disagree, the walk is
      // wrong, not the preset.
      final glass = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).refraction!;
      final rimBend =
          CoreSurfaceRefraction.travelPerBand *
          glass.strength *
          glass.bezel /
          glass.refractiveIndex;
      final red =
          rimBend *
          (1 + CoreSurfaceRefraction.dispersionUnit * glass.dispersion);
      final lensed = red + glass.lensDisplacement(red - (_short / 2));

      expect(_deepestLanding(glass), closeTo(lensed, 1e-3));
    });
  });

  group('the guard can fail', () {
    // Without these the assertions above could pass for a function that
    // never exceeds 1. Each value is one slider move from a shipped one.
    test('Refraction 80 -> 100 on the glass preset crosses the edge', () {
      const slidUp = CoreSurfaceRefraction.figma(
        refraction: 100,
        depth: 27,
        dispersion: 50,
        lens: .08,
      );

      expect(_deepestLanding(slidUp), greaterThan(1.0));
      expect(_deepestLanding(slidUp), closeTo(1.075, 0.01));
    });

    test('Dispersion 50 -> 100 on the glass preset crosses the edge', () {
      const fringed = CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 27,
        dispersion: 100,
        lens: .08,
      );

      expect(_deepestLanding(fringed), greaterThan(1.0));
    });

    test('the constructor is legal well beyond the footprint', () {
      // Every dial inside its own bound, the product far outside the
      // surface: why this is a tripwire and not an assertion in the
      // constructor.
      const limits = CoreSurfaceRefraction(
        bezel: CoreSurfaceRefraction.maxBezel,
        dispersion: 1,
      );

      expect(_deepestLanding(limits), greaterThan(2.0));
    });

    test('a quieter value than the shipped one stays inside', () {
      const quieter = CoreSurfaceRefraction.figma(
        refraction: 60,
        depth: 27,
        dispersion: 50,
        lens: .08,
      );

      expect(
        _deepestLanding(quieter),
        lessThan(
          _deepestLanding(
            CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass).refraction!,
          ),
        ),
      );
    });
  });
}
