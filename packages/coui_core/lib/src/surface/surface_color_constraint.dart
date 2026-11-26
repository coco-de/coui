import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

/// How far a gamut-fitted colour may drift in lightness before the fit
/// rejects that chroma.
///
/// Round-tripping through 8-bit channels never lands exactly, so the test
/// has to allow something; this is small enough to be invisible and large
/// enough not to reject every value over rounding noise.
const double _kGamutFitLightnessTolerance = 0.002;

/// Bisection steps when fitting a chroma into the gamut. Twenty halvings
/// take any starting chroma below one part in a million — far past what an
/// 8-bit channel can show.
const int _kGamutFitSteps = 20;

/// How a surface preset bends an app's palette without replacing it.
///
/// Some presets are partly a colour statement — one wants vivid accents,
/// another wants pastels, a third needs component surfaces to match the page
/// exactly. The naive way to express that is to ship a palette per preset,
/// but then an app that brought its own brand colours loses them the moment
/// it turns a preset on, and "our button is the wrong blue" becomes the
/// preset's fault.
///
/// So a preset states a *constraint* and the palette is derived from whatever
/// the app authored. Hue — the part that carries brand identity — is never
/// touched; only chroma and lightness, the parts that carry the preset's
/// character, move. An app's blue stays that blue and becomes a vivid or
/// pastel version of itself.
///
/// Chroma is scaled in OKLch rather than HSL because the same multiplier in
/// HSL shifts perceived lightness differently per hue, which would make one
/// brand colour wash out while another darkens.

@immutable
class CoreSurfaceColorConstraint {
  /// Creates a constraint. The default is identity — it changes nothing,
  /// which is what a preset that makes no colour statement declares.
  const CoreSurfaceColorConstraint({
    this.accentChromaScale = 1,
    this.accentLightnessShift = 0,
    this.outlineEmphasis = 0,
    this.surfaceMatchesStage = false,
    this.stageTintChroma = 0,
  }) : assert(
         outlineEmphasis >= 0 && outlineEmphasis <= 1,
         'outlineEmphasis is a fraction of the way to the foreground.',
       ),
       assert(
         stageTintChroma >= 0,
         'Chroma is a distance from grey; negative has no meaning.',
       );

  /// Multiplies the chroma of the accent roles.
  ///
  /// Above 1 pushes toward vivid, below 1 toward pastel. Applies only to
  /// accent roles — surfaces and foregrounds are load-bearing for legibility
  /// and are settled by the contrast audit, not by preset character.
  final double accentChromaScale;

  /// Shifts the lightness of the accent roles, in OKLch L units.
  final double accentLightnessShift;

  /// How far the component boundary is pushed toward the foreground.
  ///
  /// 0 leaves the authored outline alone; 1 lands it on the foreground's
  /// lightness — near-black on a light page, near-white on a dark one —
  /// while keeping the app's own hue and chroma.
  ///
  /// Chroma is kept as far as the destination lightness can hold it. Near
  /// black and near white sRGB has little room for colour, and asking for
  /// more than fits does not fail — each channel clamps on its own, which
  /// turns the hue and drags the lightness off the target. So the chroma is
  /// fitted to the gamut at the new lightness (the same fit the page tint
  /// uses): hue and lightness land where stated, and only a tint the
  /// destination cannot show is given up.
  ///
  /// It is a *fraction toward a target* rather than a shift or a colour
  /// because neither of those survives both modes. A literal near-black
  /// border is invisible on a dark page, where the surface is already
  /// black; a negative lightness shift has the same problem. Naming the
  /// destination instead lets one declaration mean "as far from the page
  /// as the text is" in either mode.
  ///
  /// Applies to both boundary tones. The subtler one carries the border of
  /// the shared outlined-box primitive and is the only boundary token 13
  /// components reference, so a style that moved only the stronger tone
  /// would darken some borders and leave others pale — the hybrid screen
  /// this axis exists to avoid.
  ///
  /// Note this puts the subtler tone outside the premise that exempts it
  /// from the contrast audit: it is exempt as a decorative hairline, and a
  /// style that turns it into a heavy boundary has made it something else.
  /// A preset using this owes the audit a registered scheme.
  final double outlineEmphasis;

  /// How much of the accent's hue the page background carries, as OKLch
  /// chroma.
  ///
  /// Zero leaves the page alone. Above it the page takes the accent's *hue*
  /// at this chroma while keeping its own lightness — a near-white page
  /// becomes a barely-tinted one of the app's own colour, which is what
  /// gives a styled screen its cast without repainting anything on it.
  ///
  /// Lightness is deliberately fixed. Contrast is a function of relative
  /// luminance, so moving lightness would move every foreground pair on the
  /// page at once and the audit would have two free parameters (hue and
  /// lightness) to sweep instead of one. Holding it leaves only the
  /// luminance wobble chroma itself introduces, which is small enough to
  /// bound — and the bound is what `CoreSurfaceTuning` states.
  ///
  /// Only the page. Container tones stay where the palette put them:
  /// a card, an input and a popover are told apart *by* those tones, and
  /// tinting them along with the page collapses that separation into one
  /// wash. It is the opposite statement from [surfaceMatchesStage], which
  /// deliberately flattens them.
  ///
  /// Effectively dark-only by intent — the default light page is too close
  /// to white to hold a visible tint (see `CoreSurfaceTuning.stageTintChroma`).
  final double stageTintChroma;

  /// Whether component surfaces must equal the page background.
  ///
  /// A preset whose components are bounded by shadow alone needs the surface
  /// and the page to be the same colour — that identity *is* the look. It is
  /// stated here rather than baked into a palette so the derivation can take
  /// the app's own background.
  final bool surfaceMatchesStage;

  /// Whether this constraint leaves the palette untouched.
  ///
  /// Load-bearing beyond convenience: a preset that bends colour is a
  /// different palette wearing the same token names, so the contrast audit
  /// can no longer cover it by auditing the base palette. The guard reads
  /// this to decide which presets owe it a registered scheme.
  bool get isIdentity =>
      accentChromaScale == 1 &&
      accentLightnessShift == 0 &&
      outlineEmphasis == 0 &&
      stageTintChroma == 0 &&
      !surfaceMatchesStage;

  /// Applies this constraint to an authored scheme.
  ///
  /// Returns [authored] unchanged when [isIdentity], so a preset that makes
  /// no colour statement costs nothing and cannot perturb a palette by
  /// rounding.
  CoreColorScheme apply(CoreColorScheme authored) {
    if (isIdentity) return authored;

    CoreColor? bend(CoreColor? color) {
      if (color == null) return null;
      final lch = CoreColorConversion.colorToOKLch(color);
      return CoreColorConversion.oklchToColor(
        (lch.l + accentLightnessShift).clamp(0.0, 1.0),
        lch.c * accentChromaScale,
        lch.h,
        lch.a,
      );
    }

    final authoredSurface = authored.surface;
    final foreground = authored.onSurface;

    // The page takes the accent's hue at the stated chroma, keeping its own
    // lightness. Derived from the app's own accent rather than named as a
    // colour, so a brand palette tints toward itself.
    CoreColor? tinted() {
      // A palette that states no page colour has nothing to tint — the
      // identity case, not a failure.
      if (stageTintChroma == 0 || authoredSurface == null) return null;
      final page = CoreColorConversion.colorToOKLch(authoredSurface);
      final hue = CoreColorConversion.colorToOKLch(authored.primary).h;

      return CoreColorConversion.oklchToColor(
        page.l,
        _inGamutChroma(page.l, hue, page.a, stageTintChroma),
        hue,
        page.a,
      );
    }

    final stage = tinted();
    // Containers that flatten onto the page follow the *tinted* page, not
    // the authored one — otherwise turning both statements on at once
    // leaves the two colours the flattening exists to make identical
    // visibly different.
    final surface = stage ?? authoredSurface;

    // Null keeps the authored value: `copyWith` treats null as "unchanged",
    // so a style that says nothing about boundaries costs nothing here.
    CoreColor? emphasise(CoreColor? color) {
      if (outlineEmphasis == 0 || color == null || foreground == null) {
        return null;
      }
      final from = CoreColorConversion.colorToOKLch(color);
      final to = CoreColorConversion.colorToOKLch(foreground);
      final lightness = from.l + (to.l - from.l) * outlineEmphasis;

      return CoreColorConversion.oklchToColor(
        lightness,
        _inGamutChroma(lightness, from.h, from.a, from.c),
        from.h,
        from.a,
      );
    }

    return authored.copyWith(
      surface: stage,
      // A shadow-bounded preset needs component surfaces to equal the page.
      // Only the tones a component actually paints on are collapsed; the
      // highest tone stays distinct so anything that differentiates by
      // background tone alone does not vanish outright.
      surfaceContainerLow: surfaceMatchesStage ? surface : null,
      surfaceContainer: surfaceMatchesStage ? surface : null,
      surfaceContainerHigh: surfaceMatchesStage ? surface : null,
      primary: bend(authored.primary),
      secondary: bend(authored.secondary),
      tertiary: bend(authored.tertiary),
      outline: emphasise(authored.outline),
      outlineVariant: emphasise(authored.outlineVariant),
      outlineSubtle: emphasise(authored.outlineSubtle),
    );
  }

  /// The most chroma this lightness and hue can actually hold, up to
  /// [wanted].
  ///
  /// Asking for more colour than sRGB has at a given lightness does not
  /// fail — the conversion clamps each channel independently, and a clamped
  /// channel moves *lightness* (and hue) as well as chroma. A near-white
  /// page asked for a deep tint therefore comes back both duller and darker
  /// than requested, which quietly breaks the one property the contrast
  /// sweep relies on: that these statements hold lightness fixed.
  ///
  /// So the request is fitted to the gamut instead of being clamped by it.
  /// Bisection rather than an analytic boundary because the conversion is
  /// the authority on what is representable, and asking it directly cannot
  /// disagree with it.
  ///
  /// The consequence is worth stating plainly: how much tint a colour can
  /// take depends on how light it is. A near-white page takes very little
  /// whatever [stageTintChroma] says, and an outline pushed to near-white
  /// keeps only the part of its tint that near-white can show.
  double _inGamutChroma(
    double lightness,
    double hue,
    double alpha,
    double wanted,
  ) {
    bool holds(double chroma) {
      final back = CoreColorConversion.colorToOKLch(
        CoreColorConversion.oklchToColor(lightness, chroma, hue, alpha),
      );

      return (back.l - lightness).abs() <= _kGamutFitLightnessTolerance;
    }

    if (holds(wanted)) return wanted;

    var low = 0.0;
    var high = wanted;
    for (var i = 0; i < _kGamutFitSteps; i++) {
      final mid = (low + high) / 2;
      if (holds(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return low;
  }

  /// Creates a copy with modified values.
  CoreSurfaceColorConstraint copyWith({
    double? accentChromaScale,
    double? accentLightnessShift,
    double? outlineEmphasis,
    bool? surfaceMatchesStage,
    double? stageTintChroma,
  }) {
    return CoreSurfaceColorConstraint(
      accentChromaScale: accentChromaScale ?? this.accentChromaScale,
      accentLightnessShift: accentLightnessShift ?? this.accentLightnessShift,
      outlineEmphasis: outlineEmphasis ?? this.outlineEmphasis,
      surfaceMatchesStage: surfaceMatchesStage ?? this.surfaceMatchesStage,
      stageTintChroma: stageTintChroma ?? this.stageTintChroma,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceColorConstraint &&
          accentChromaScale == other.accentChromaScale &&
          accentLightnessShift == other.accentLightnessShift &&
          outlineEmphasis == other.outlineEmphasis &&
          stageTintChroma == other.stageTintChroma &&
          surfaceMatchesStage == other.surfaceMatchesStage;

  @override
  int get hashCode => Object.hash(
    accentChromaScale,
    accentLightnessShift,
    outlineEmphasis,
    stageTintChroma,
    surfaceMatchesStage,
  );
}
