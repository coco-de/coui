import 'dart:math' as math;

/// How a glass surface's material gives way while the surface fades in or
/// out.
///
/// ## Why a fade needs this at all
///
/// A surface that fades is two things at once. Its **fill and its content**
/// are paint: they fade the way anything fades, each by the progress itself.
/// Its **backdrop pass** — the blur, the chroma lift, the dimming, the frost,
/// the bend at the rim — is not paint. It is a statement about what is behind
/// the surface, and an opacity layer cannot fade a statement: a backdrop
/// filter inside a layer that is saved at less than full alpha reads only what
/// was painted into that layer, which is nothing, so the pass is lost in the
/// first frame of the fade and the surface goes on as a plain translucent
/// plate over a page that has turned sharp.
///
/// So the pass is not put under an opacity at all. It stays where it is and
/// every term it states is scaled by [share] of the progress, which takes the
/// glass from the page's own picture (nothing blurred, nothing bent) to its
/// full material as it arrives, and back as it leaves. Each term moves on its
/// own scale, but none of them waits for another to finish: a pass that stayed
/// fully blurred until the alpha reached zero would pop to sharp in the last
/// frame, which is the same fault from the other side.
///
/// ## Which terms follow what
///
/// * The **fill, the border, the content, the edge light, the rim and the
///   shadow** follow the progress itself — what an opacity does.
/// * The **blur sigma, the frost share, the body shade, the bend's strength and
///   the lens** go from nothing to their stated value with [share] of the
///   progress.
/// * The **chroma lift and the backdrop dimming** go from the identity (`1`) to
///   their stated value with [share] of the progress.
///
/// `CoreSurfaceBackdropPass.dissolvedAt` states that rule over a whole pass.
///
/// The geometry of the bend — the band's width, the index, the dispersion as a
/// fraction of the bend it rides — is not scaled: it states where and at what
/// angle, and the strength it rides already goes to nothing.
///
/// At a progress of 1 every function here returns its input unchanged, so a
/// surface at rest draws what it states.
abstract final class CoreSurfaceDissolve {
  /// How fast the backdrop terms give way relative to the fill and the
  /// content: [share] is the progress raised to this power.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** the curve of the
  /// material against the progress. At `1` the material moves in step with the
  /// fill — half the progress is half the blur, half the chroma lift, half the
  /// bend, beside half the fill. Above `1` the glass loses its character
  /// before it loses its fill (it reads as a plate that is going), and below
  /// `1` it keeps its frost longer than its fill (it reads as glass that is
  /// going). The shipped value is the one that adds no opinion of its own: the
  /// fill and the content already fade linearly, and a material that moved on
  /// a different clock would be a second animation riding the first.
  ///
  /// Nothing derives it. It has to stay positive; a value of zero would leave
  /// the material at full strength until the last frame.
  static const double materialExponent = 1;

  /// The share of a surface's backdrop material that is drawn at [progress]:
  /// `0` at nothing, exactly `1` at rest, and continuous and increasing in
  /// between.
  static double share(double progress) {
    if (progress >= 1) return 1;
    if (progress <= 0) return 0;

    return math.pow(progress, materialExponent).toDouble();
  }

  /// [value] at [progress], for a term whose nothing is zero: a blur sigma, a
  /// bend strength, a frost share, a body shade.
  ///
  /// Returns [value] itself at a progress of 1, so a surface at rest compares
  /// equal to the surface that states the value.
  static double scaled(double value, double progress) =>
      progress >= 1 ? value : value * share(progress);

  /// [value] at [progress], for a term whose nothing is [identity]: a chroma
  /// lift (`1` leaves the colours as they are) or a backdrop dimming (`1`
  /// leaves the brightness as it is).
  ///
  /// Returns [value] itself at a progress of 1, for the reason [scaled] does.
  static double towardIdentity(
    double value,
    double progress, {
    double identity = 1,
  }) =>
      progress >= 1 ? value : identity + ((value - identity) * share(progress));
}
