import 'package:meta/meta.dart';

/// The document attribute a Web page carries while an adaptive-quality tier
/// is in effect.
///
/// Lives here for the reason `kSurfaceStyleAttribute` does: the stylesheet
/// that writes rules for it, the root that sets it and the refraction host
/// that watches it must agree on one string, and a second spelling anywhere
/// is a silent no-op rather than an error.
const String kQualityAttribute = 'data-coui-quality';

/// Something a surface's material can be asked to go without.
///
/// The members are the things the material draws that cost the display
/// something every frame, in the terms the two platforms share. A tier never
/// adds one: it only names the ones a surface leaves out.
enum CoreQualityEffect {
  /// The bend at a surface's rim — the refraction program on Flutter, the
  /// displacement filter on the Web.
  refraction,

  /// The backdrop pass and everything that rides it: the blur, the chroma
  /// lift, the dimming, the frost and the body shade, and the translucent
  /// fill that only means something over a blurred backdrop.
  ///
  /// A surface that goes without it is exactly the reduce-transparency
  /// fallback (`CoreSurfaceToken.withoutTransparency`): an opaque fill, with
  /// the edge band kept.
  backdropPass,
}

/// How much of the material a surface draws — one rung of the ladder.
///
/// A theme axis: one choice that moves every surface at once. It is read
/// where a recipe becomes a material (`applySurfaceStyle` on Flutter, the
/// stylesheet and the refraction host on the Web) and never by a component.
/// Which rung an app is on is decided by the app (`forced`, `initialQuality`)
/// or by the governor (`CoreQualityGovernor`) from measured frame times; the
/// order of the rungs and what each one leaves out is [CoreQualityLadder]'s,
/// as data, so a rung is added by adding an entry there.
enum CoreQualityTier {
  /// Everything the style states.
  full,

  /// The style's material without the bend at its rim: translucent fill,
  /// blur, chroma lift, dimming and the edge band all stay.
  noRefraction,

  /// No backdrop pass at all: an opaque fill with the edge band kept — the
  /// reduce-transparency fallback.
  solid;

  /// The tier of an app that states none.
  static const CoreQualityTier defaultTier = full;
}

/// One rung of a [CoreQualityLadder]: a tier, and what it stops drawing on
/// top of what the rungs above it already stopped.
@immutable
class CoreQualityStep {
  /// Creates a rung.
  const CoreQualityStep(this.tier, {this.drops = const {}});

  /// The tier this rung is.
  final CoreQualityTier tier;

  /// What this rung leaves out that the rung above it still drew.
  ///
  /// Stated as the difference rather than as the whole set, so a rung
  /// inserted in the middle cannot leave a later rung drawing something an
  /// earlier one stopped: the set a tier withholds is the union down to it.
  final Set<CoreQualityEffect> drops;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQualityStep &&
          tier == other.tier &&
          drops.length == other.drops.length &&
          drops.containsAll(other.drops);

  @override
  int get hashCode => Object.hash(tier, Object.hashAllUnordered(drops));

  @override
  String toString() => 'CoreQualityStep($tier, drops: $drops)';
}

/// The tiers in order, from the most the material can draw to the least,
/// and what each one leaves out.
///
/// ## The order is data
///
/// A seat never compares tiers; it asks the ladder what a tier withholds.
/// Putting another rung in front of an existing one — a cheaper frost before
/// the bend goes, say — is one new [CoreQualityStep] in the list and one new
/// [CoreQualityEffect] it drops, and nothing that reads the ladder changes.
///
/// **Designer-judgement value (디자이너 판단 값):** the order. The bend goes
/// first because it is the only effect that needs a program of its own — a
/// fragment shader on Flutter, a per-element displacement map on the Web —
/// and because dropping it keeps the part of the material that reads as the
/// style (the blur and the translucent fill). How much each rung saves is a
/// measurement (`tool/frame_timing`) and differs by platform: in Chrome the
/// bend is most of the cost of a page of glass, so the first step recovers
/// nearly all of it; on an Apple M3 Max in Flutter profile mode the bend is
/// up to a tenth of a glass scene's raster time (a fifth for five cards laid
/// over one another) and the backdrop pass a fifth to a third, so the first
/// step is the cheaper loss and the second the larger saving. The
/// alternative order (the backdrop pass first, which leaves a bent but opaque
/// surface) is not expressible as a look, since a bend needs a backdrop to
/// bend.
@immutable
class CoreQualityLadder {
  /// Creates a ladder from [steps], the first of which draws everything.
  const CoreQualityLadder(this.steps);

  /// The ladder every seat uses.
  static const CoreQualityLadder standard = CoreQualityLadder([
    CoreQualityStep(CoreQualityTier.full),
    CoreQualityStep(
      CoreQualityTier.noRefraction,
      drops: {CoreQualityEffect.refraction},
    ),
    CoreQualityStep(
      CoreQualityTier.solid,
      drops: {CoreQualityEffect.backdropPass},
    ),
  ]);

  /// What a reduce-transparency preference removes. The tier it forces is the
  /// first one that leaves all of these out.
  ///
  /// The bend goes with the pass: a surface with nothing showing through it
  /// has nothing to bend, and the renderer would mount no program for it.
  static const Set<CoreQualityEffect> reducedTransparencyWithholds = {
    CoreQualityEffect.refraction,
    CoreQualityEffect.backdropPass,
  };

  /// The rungs, top first.
  final List<CoreQualityStep> steps;

  /// How many rungs there are.
  int get length => steps.length;

  /// The tier that draws everything.
  CoreQualityTier get top => steps.first.tier;

  /// The tiers, top first.
  List<CoreQualityTier> get tiers => [for (final step in steps) step.tier];

  /// Where [tier] sits, or -1 when this ladder has no such rung.
  int indexOf(CoreQualityTier tier) {
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].tier == tier) return i;
    }

    return -1;
  }

  /// Everything [tier] leaves out: the union of what every rung down to it
  /// drops. The top rung withholds nothing; a tier this ladder has no rung
  /// for withholds nothing either.
  Set<CoreQualityEffect> withheldAt(CoreQualityTier tier) {
    final index = indexOf(tier);
    if (index < 0) return const {};

    return {
      for (var i = 0; i <= index; i++) ...steps[i].drops,
    };
  }

  /// Whether a surface at [tier] goes without [effect].
  bool withholds(CoreQualityTier tier, CoreQualityEffect effect) =>
      withheldAt(tier).contains(effect);

  /// The first tier that leaves out every one of [effects], or null when no
  /// rung does.
  CoreQualityTier? firstWithholding(Set<CoreQualityEffect> effects) {
    for (final step in steps) {
      if (withheldAt(step.tier).containsAll(effects)) return step.tier;
    }

    return null;
  }

  /// [tier], or the tier a reduce-transparency preference forces when it is
  /// on — the one place that preference becomes a rung, so the accessibility
  /// setting is the lowest tier regardless of what the app or the governor
  /// chose.
  ///
  /// A ladder with no rung that leaves out what the preference removes keeps
  /// [tier]; the seat's own accessibility handling still removes it.
  CoreQualityTier effective(
    CoreQualityTier tier, {
    required bool reduceTransparency,
  }) {
    if (!reduceTransparency) return tier;

    return firstWithholding(reducedTransparencyWithholds) ?? tier;
  }

  /// The tiers a governor may step between when the surfaces can draw
  /// [drawable].
  ///
  /// The top rung always, and every later rung that stops drawing something
  /// in [drawable]. A rung whose drops are all things this engine does not
  /// draw anyway (the bend, on an engine without shader filters) would cost
  /// the governor a window and a cooldown to change nothing on screen, so it
  /// is not a step.
  List<CoreQualityTier> reachable(Set<CoreQualityEffect> drawable) => [
    steps.first.tier,
    for (var i = 1; i < steps.length; i++)
      if (steps[i].drops.any(drawable.contains)) steps[i].tier,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQualityLadder &&
          steps.length == other.steps.length &&
          [
            for (var i = 0; i < steps.length; i++) steps[i] == other.steps[i],
          ].every((same) => same);

  @override
  int get hashCode => Object.hashAll(steps);

  @override
  String toString() => 'CoreQualityLadder(${tiers.map((t) => t.name)})';
}
