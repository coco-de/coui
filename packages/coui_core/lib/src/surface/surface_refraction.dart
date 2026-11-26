import 'dart:math' as math;

import 'package:coui_core/src/surface/surface_dissolve.dart';
import 'package:meta/meta.dart';

/// The top of the 0–100 range a design tool's glass sliders run on.
///
/// Named rather than inlined because three conversions read it and a
/// fourth will, and a scale that disagrees with itself in one place is a
/// value that arrives wrong from exactly one control.
const double _kFigmaScale = 100;

/// The law the rim band bends light by.
///
/// Both laws read the same band (`CoreSurfaceRefraction.bezel`), the same
/// dial (`strength`), the same index and the same bevel, and both pull the
/// backdrop inward by the same unit (`travelPerBand` band widths at full
/// strength). They differ only in how a point's travel follows from where it
/// sits in the band, so one request can be read under either and switching
/// the law moves the shape of the bend, not the places it happens.
///
/// Not the `lens`. That term is the dome across the whole face and is
/// independent of the law: it magnifies the interior the band leaves flat.
///
/// Declaration order is part of the contract with the Flutter shader, which
/// receives the law as a number — new members append.
enum CoreRefractionModel {
  /// The bevel's normal against Snell's law: a ray straight into the screen
  /// is bent by the index, and the sample moves by the screen-space part of
  /// where it went, faded out at the band's inner boundary.
  ///
  /// The travel scales with `1 / index` and falls off from the rim as the
  /// product of the normal's lateral share and the fade.
  snell,

  /// The small-angle (thin-prism) law: a thin wedge deviates a ray by
  /// `(index - 1)` times its slope, whatever the angle the ray meets it at,
  /// and the slope is taken as the square of the normal's lateral share —
  /// `1 - h²` at a point `h` of the way in from the rim to the band's inner
  /// boundary.
  ///
  /// Three things follow, and each is the reason to pick it:
  ///
  /// * **An index of 1 bends nothing.** The travel is proportional to
  ///   `index - 1`, so the dial that reaches vacuum reaches no bend.
  /// * **The travel reaches zero at the inner boundary on its own.** There is
  ///   no separate fade, so the interior joins the band without the kink a
  ///   fade multiplied onto a square-root profile leaves.
  /// * **The travel is a parabola in the inset**, so the fold the band shows
  ///   — a mirrored, compressed copy of the interior near the rim —
  ///   compresses at a constant rate across the band instead of steepening
  ///   toward grazing incidence.
  ///
  /// Squaring the slope (rather than taking the lateral share itself) is a
  /// look decision: the unsquared slope is a plateau with a visible edge at
  /// the inner boundary. The index scales this law as `index - 1` and the
  /// other as `1 / index`, so a request moved from one law to the other is
  /// re-judged at its `strength`.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** the unit of this law's
  /// travel is the one the other law uses (`travelPerBand` band widths at full
  /// strength) times `index - 1`, and it is not normalised so that the two
  /// laws agree at the rim. Normalising would keep a request's rim strength
  /// when the law is switched, at the price of the `index - 1` dependence the
  /// law is chosen for. Which of the two a product wants is a look decision,
  /// and the law a request states by default stays the other one.
  paraxial,
}

/// Light bending as it passes through a surface's edge — what a real pane
/// of glass does to whatever is behind it near its rim.
///
/// ## The statement is size-independent; only the drawing is not
///
/// What this type holds is a fraction of the shorter side, so one
/// declaration reads the same on a chip and on a full-width panel. That is
/// the property that lets it sit on the style axis beside the thickness,
/// the run fraction and the blur radius — a material states its refraction
/// once and every surface made of it bends.
///
/// The displacement itself is still per-element: it is computed from that
/// element's own rounded rectangle and rebuilt when the rectangle changes.
/// But the renderer does that, not the author — a Web surface gets its map
/// from the document-level host that watches the surface marker, and a
/// Flutter one from the surface primitive it is already composed of.
/// Neither asks the component to measure itself, which is what "components
/// do not read the axis" exists to prevent.
///
/// A caller may still state one directly on a surface that wants to differ.
/// The axis is what it falls back to, and that fallback is the reason the
/// shipped glass bends at all: measured, nothing in the kit passed a
/// refraction to anything, so the material had every term except the one it
/// is named for.
///
/// ## It is a request, not a guarantee
///
/// Whether refraction can be drawn at all is a property of the engine, not
/// of this value. Where it cannot, the surface keeps the rest of its
/// material — translucency, blur, chroma, edge band — and simply does not
/// bend anything. Losing the whole material because one layer is
/// unavailable would be a worse answer than the layer's absence.
@immutable
class CoreSurfaceRefraction {
  /// Creates a refraction request.
  const CoreSurfaceRefraction({
    required this.bezel,
    this.strength = defaultStrength,
    this.refractiveIndex = defaultRefractiveIndex,
    this.dispersion = 0,
    this.lens = 0,
    this.fallbackBlurAdd = 0,
    this.model = CoreRefractionModel.snell,
  }) : assert(
         lens >= 0 && lens <= maxLens,
         'The lens is the fraction of its distance from the centre a sample '
         'moves inward — a magnification. Negative would shrink, which is a '
         'concave pane, and past half the face folds over itself.',
       ),
       assert(
         strength >= 0 && strength <= 1,
         'The strength is a dial, not a length — how much of the bend the '
         'index and the band already describe actually gets applied.',
       ),
       assert(
         refractiveIndex >= 1,
         'Below 1 a ray would bend away from the normal on entry, which is '
         'not glass; 1 is vacuum and bends nothing.',
       ),
       assert(
         dispersion >= 0 && dispersion <= 1,
         'Dispersion is the spread between the channels as a fraction of '
         'the bend they share.',
       ),
       assert(
         bezel > minBezel && bezel <= maxBezel,
         'The bezel is the band the bending happens in, measured against '
         'the shorter side. At zero there is no band and nothing bends; '
         'past half the two sides meet in the middle and the surface has '
         'no flat interior left to be seen through.',
       ),
       assert(
         fallbackBlurAdd >= 0,
         'The correction exists because a fallback looks less like glass '
         'than the refracted original, so it can only add.',
       );

  /// Creates a request from the numbers a glass panel in a design tool
  /// shows, so a value read off a design lands here unconverted.
  ///
  /// The three dials are all 0–100 there and normalised quantities here,
  /// which is exactly the kind of conversion that gets done differently by
  /// each person who does it. One place, once.
  ///
  /// `depth` is capped at 50 rather than 100 because past half the shorter
  /// side the two bands meet and the surface has no flat interior left to
  /// be seen through — the geometry runs out before the slider does.
  ///
  /// `lens` is not on that panel. It is stated here in this kit's own unit
  /// (a fraction, see [lens]) so a recipe written in the panel's numbers can
  /// still say it, and it defaults to nothing so a request that only names
  /// what the panel shows gets exactly what the panel shows.
  const CoreSurfaceRefraction.figma({
    required double refraction,
    required double depth,
    double dispersion = 0,
    double refractiveIndex = defaultRefractiveIndex,
    double lens = 0,
    double fallbackBlurAdd = 0,
    CoreRefractionModel model = CoreRefractionModel.snell,
  }) : this(
         bezel: depth / _kFigmaScale,
         strength: refraction / _kFigmaScale,
         refractiveIndex: refractiveIndex,
         dispersion: dispersion / _kFigmaScale,
         lens: lens,
         fallbackBlurAdd: fallbackBlurAdd,
         model: model,
       );

  /// How much of the surface's edge the bending occupies, as a fraction of
  /// the shorter side.
  ///
  /// Stated as a fraction rather than a length so one value reads the same
  /// on a small chip and a full-width panel. The bending itself still has
  /// to be recomputed per element — this is what stays constant across
  /// those recomputations.
  ///
  /// This is the band's **width**, and it is not the same knob as how far
  /// anything moves inside it. Welding the two — which both renderers did
  /// before, in two different ways — meant widening the band also
  /// strengthened the bend, and on one platform only.
  final double bezel;

  /// How much of the bend the geometry describes is actually applied, 0 to 1.
  ///
  /// Separate from [refractiveIndex] because the two saturate differently.
  /// Snell's law flattens out quickly — past about 2 the ray is already
  /// bent as far as it goes and raising the index changes almost nothing —
  /// so an index used as the magnitude dial has a narrow usable range and a
  /// dead one beyond it. This scales the travel distance instead, which
  /// stays linear across its whole range.
  final double strength;

  /// The index of refraction, which sets the *angle* light bends through.
  ///
  /// 1 is vacuum and bends nothing. Window glass sits near 1.5, and the
  /// useful range runs to roughly 2 before Snell's law saturates.
  final double refractiveIndex;

  /// How far the colour channels separate, as a fraction of their shared
  /// bend. Zero draws all three at the same place.
  ///
  /// Real glass bends short wavelengths more than long ones, which is why a
  /// thick edge fringes. The channels are displaced by slightly different
  /// amounts rather than tinted, so the fringe appears only where there is
  /// something to fringe — a hard boundary crossing the rim — and the flat
  /// interior stays neutral.
  final double dispersion;

  /// How much the whole face magnifies what shows through it, as the
  /// fraction of its distance from the centre a sample moves inward. Zero
  /// leaves the interior optically flat.
  ///
  /// ## What this is that the band is not
  ///
  /// The band ([bezel]) is the rim: the surface tilts over at its edge and
  /// the bend lives there, fading to nothing at the band's inner boundary.
  /// The reference this material is modelled on does one more thing — the
  /// face itself is a shallow dome, so everything behind it reads a little
  /// larger, and a line crossing under the panel bows across the whole
  /// width rather than only at the rim. That is a lens, and no amount of
  /// band can produce it because the band is defined to leave the
  /// interior alone.
  ///
  /// Stated as a fraction rather than a length for the same reason the
  /// band is: one value reads the same on a chip and on a full-width
  /// panel. A sample at distance *r* from the centre reads from `r × (1 −
  /// lens)` — see [lensDisplacement] — which is a uniform magnification of
  /// `1 / (1 − lens)`.
  ///
  /// Outside the design tool's vocabulary, on purpose: the panel this
  /// request is otherwise read off has no such dial, so this one is a
  /// decision this kit makes for itself and records here.
  final double lens;

  /// Extra blur radius for surfaces that asked for refraction and could not
  /// have it.
  ///
  /// Refraction adds apparent blur at the edge, so a fallback without a
  /// correction reads as slightly flatter than the refracted original.
  ///
  /// The default is no correction, deliberately. Baking a hidden constant
  /// here would make "a surface that never asked for refraction" and "a
  /// surface that asked and did not get it" differ for a reason neither the
  /// caller nor the reader can see. Whoever wants the two to match states
  /// by how much.
  final double fallbackBlurAdd;

  /// The law the rim band bends light by — see [CoreRefractionModel].
  ///
  /// The default is the law the band has always been drawn with, so a
  /// request that states none renders as it did. The dome ([lens]) is not
  /// affected by it.
  final CoreRefractionModel model;

  /// The dial position a request uses when it states none.
  ///
  /// Full, because a caller that named a band and an index has already said
  /// it wants the bend those describe. A quieter default would mean every
  /// such caller states two values and gets a third, smaller one.
  static const double defaultStrength = 1;

  /// Window glass, which is what this material is meant to read as.
  static const double defaultRefractiveIndex = 1.5;

  /// Converts the [strength] dial into the distance a fully-bent sample
  /// travels, as a multiple of the band width.
  ///
  /// A dial of 1 moves a sample at the very edge by five band widths along
  /// the refracted ray's screen-space part — which is far less than five
  /// band widths on screen, because that part is a fraction of a unit
  /// vector and shrinks to nothing as the surface flattens.
  ///
  /// Lives here rather than in either renderer because it is the one number
  /// that decides whether the two platforms bend by the same amount, and
  /// the two got it wrong in opposite directions when each owned its own:
  /// one scaled with the band and the other did not, so widening the band
  /// moved one platform and left the other still.
  static const double travelPerBand = 5;

  /// Below this there is no band for the bending to happen in.
  static const double minBezel = 0;

  /// The most a lens may magnify — past this the face folds over itself.
  static const double maxLens = 0.5;

  /// How far apart the outer colour channels sit at full [dispersion], as
  /// a fraction of the bend they share.
  ///
  /// Half rather than the whole bend: at one the red pass would travel
  /// twice as far as green and the blue pass not at all, which is not a
  /// fringe but three separate images. Both renderers multiply their
  /// channel passes by `1 ± dispersionUnit × dispersion`; the number lives
  /// here because when each held its own the two fringed by different
  /// amounts for the same stated value.
  static const double dispersionUnit = 0.5;

  /// Above this the two sides meet before either reaches the interior.
  static const double maxBezel = 0.5;

  /// How far a sample at [insetPx] inside the edge is displaced, along the
  /// outward normal, in pixels — negative because the bend pulls inward.
  ///
  /// This is the whole optical model in one place, and it is here rather
  /// than in either renderer because the two are supposed to produce the
  /// same picture. When each owned its own copy they disagreed on all three
  /// terms that matter — the direction, the falloff and the magnitude —
  /// and nothing in either suite could see it, because neither suite had
  /// anything to compare against.
  ///
  /// The Web renderer calls this directly, per pixel, to bake its map. The
  /// Flutter one cannot — it runs on the GPU and the same arithmetic is
  /// written out in GLSL — so the shader mirrors these five lines and a
  /// test evaluates both against the same inputs.
  ///
  /// The model: the flat interior faces the viewer and the surface tilts
  /// over as it approaches the rim, so the normal is lifted into three
  /// dimensions with the band as its ramp. A ray coming straight at the
  /// screen is bent by Snell's law against that normal, and the sample
  /// moves by the screen-space part of where it went. `zone` fades the
  /// travel to nothing at the band's inner boundary, so the interior is
  /// left optically flat rather than uniformly shifted.
  ///
  /// That is [CoreRefractionModel.snell]. Under [model] `paraxial` the same
  /// bevel is read through the thin-prism law instead — see
  /// [CoreRefractionModel.paraxial]; the two share the band, the dial and
  /// the sign, and both return nothing outside the band.
  double displacementAt({required double insetPx, required double bandPx}) {
    if (bandPx <= 0) return 0;
    if (model == CoreRefractionModel.paraxial) {
      return _paraxialDisplacementAt(insetPx: insetPx, bandPx: bandPx);
    }

    final h = (insetPx / bandPx).clamp(0.0, 1.0);
    // The surface stands on end at the rim and lies flat by the band's
    // inner edge — a quarter circle, not a straight ramp, because a real
    // bevel is round and a linear one bends most where it should bend
    // least.
    final bulge = math.sqrt(math.max(0, 1 - (h * h)));
    final normalLength = math.sqrt((bulge * bulge) + (h * h));
    if (normalLength == 0) return 0;

    final nx = bulge / normalLength;
    final nz = h / normalLength;

    // refract(I, N, eta) with I straight into the screen, written out:
    // `dot(N, I)` is `-nz`, so the tangential part survives as `-nx`.
    final eta = 1 / math.max(refractiveIndex, 1);
    final k = 1 - (eta * eta * (1 - (nz * nz)));
    if (k < 0) return 0;

    final tangential = -eta * nx;
    final zone = 1 - (insetPx / bandPx).clamp(0.0, 1.0);

    return tangential * bandPx * strength * travelPerBand * zone;
  }

  /// [displacementAt] under [CoreRefractionModel.paraxial].
  ///
  /// The thin-prism law, with the same bevel the other law reads: the
  /// normal's lateral share at a point `h` of the way in is
  /// `sqrt(1 - h²)`, the slope is its square, and the deviation is
  /// `(index - 1)` times that. The travel unit (`bandPx * strength *
  /// travelPerBand`) is shared, so the dial means the same thing under
  /// either law.
  ///
  /// The Flutter shader mirrors these lines (`paraxialDisplacementAt`), and
  /// the parity test pins its transcription and the shared vector table
  /// against this.
  double _paraxialDisplacementAt({
    required double insetPx,
    required double bandPx,
  }) {
    final h = (insetPx / bandPx).clamp(0.0, 1.0);
    final slope = 1 - (h * h);
    final deviation = math.max(refractiveIndex, 1) - 1;

    return -deviation * slope * bandPx * strength * travelPerBand;
  }

  /// How far a sample [fromCentrePx] from the centre along one axis is
  /// displaced along that axis by the lens, in pixels — negative because
  /// the dome pulls every sample toward the centre.
  ///
  /// Per axis, so a renderer applies it to *x* and *y* separately and the
  /// result is a uniform scale about the centre with no seam. An earlier
  /// shape of this idea rode the edge normal and the distance to the
  /// nearest edge, and it had a seam: on a rectangle the nearest edge
  /// flips across the diagonal, and with it the reach the dome was
  /// measured against.
  ///
  /// The Web map calls this per pixel. The Flutter shader mirrors the one
  /// line in GLSL, and the parity test pins both.
  double lensDisplacement(double fromCentrePx) => -lens * fromCentrePx;

  /// The largest magnitude [lensDisplacement] can return on a face whose
  /// corner sits [cornerPx] from the centre.
  ///
  /// The Web map stores each channel as a ratio of this, the same way the
  /// band's map stores a ratio of [peakDisplacement].
  double lensPeak({required double cornerPx}) => lens * cornerPx;

  /// The largest magnitude [displacementAt] can return for [bandPx].
  ///
  /// The Web renderer needs it because its map stores a ratio: a channel
  /// holds the displacement divided by this, and the filter multiplies it
  /// back. Computed by sampling rather than solved, because the product of
  /// the ramp and the zone fade has no closed-form peak worth deriving and
  /// a wrong one clips the map.
  double peakDisplacement({required double bandPx}) {
    if (bandPx <= 0) return 0;

    var peak = 0.0;
    const steps = 256;
    for (var i = 0; i <= steps; i++) {
      final at = displacementAt(
        insetPx: bandPx * i / steps,
        bandPx: bandPx,
      ).abs();
      if (at > peak) peak = at;
    }

    return peak;
  }

  /// Creates a copy with modified values.
  CoreSurfaceRefraction copyWith({
    double? bezel,
    double? strength,
    double? refractiveIndex,
    double? dispersion,
    double? lens,
    double? fallbackBlurAdd,
    CoreRefractionModel? model,
  }) => .new(
    bezel: bezel ?? this.bezel,
    strength: strength ?? this.strength,
    refractiveIndex: refractiveIndex ?? this.refractiveIndex,
    dispersion: dispersion ?? this.dispersion,
    lens: lens ?? this.lens,
    fallbackBlurAdd: fallbackBlurAdd ?? this.fallbackBlurAdd,
    model: model ?? this.model,
  );

  /// This request as it is drawn while its surface is [progress] of the way
  /// in or out of view: the two terms that say *how far* a sample moves —
  /// [strength] at the rim and [lens] across the face — go from nothing to
  /// their stated value with [CoreSurfaceDissolve.share] of the progress.
  ///
  /// The terms that say *where* and *at what angle* are kept: the band's
  /// [bezel], the [refractiveIndex] and the [model]. [dispersion] is a
  /// fraction of the bend it rides, so it goes with the bend and is not
  /// scaled twice.
  ///
  /// Both distances have to go, not only the rim's. The dome is independent
  /// of the band, so a request that dissolved only its strength would leave
  /// every sample inside the face still pulled toward the centre by the lens
  /// while the rest of the surface was nearly gone — a shifted copy of the
  /// page under a surface that is hardly there.
  ///
  /// Returns this very instance at a progress of 1.
  CoreSurfaceRefraction dissolvedAt(double progress) => progress >= 1
      ? this
      : copyWith(
          strength: CoreSurfaceDissolve.scaled(strength, progress),
          lens: CoreSurfaceDissolve.scaled(lens, progress),
        );

  /// Serializes this request to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'bezel': bezel,
    'strength': strength,
    'refractiveIndex': refractiveIndex,
    'dispersion': dispersion,
    'lens': lens,
    'fallbackBlurAdd': fallbackBlurAdd,
    if (model != CoreRefractionModel.snell) 'model': model.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceRefraction &&
          bezel == other.bezel &&
          strength == other.strength &&
          refractiveIndex == other.refractiveIndex &&
          dispersion == other.dispersion &&
          lens == other.lens &&
          fallbackBlurAdd == other.fallbackBlurAdd &&
          model == other.model;

  // Every field, and the reason is sharper here than the usual one. On the
  // Web side this value is part of the key a generated displacement map is
  // cached under: a field left out of the comparison makes two different
  // requests look identical, the cache answers with the map it already has,
  // and the surface bends by the wrong amount with nothing in the output to
  // say why. The model is the field this bites hardest — two requests that
  // differ in nothing else draw different maps.
  @override
  int get hashCode => Object.hash(
    bezel,
    strength,
    refractiveIndex,
    dispersion,
    lens,
    fallbackBlurAdd,
    model,
  );

  @override
  String toString() =>
      'CoreSurfaceRefraction(bezel: $bezel, strength: $strength, '
      'index: $refractiveIndex, dispersion: $dispersion, lens: $lens, '
      'fallbackBlurAdd: $fallbackBlurAdd, model: ${model.name})';
}
