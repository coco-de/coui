/// What a control's cast does when the control is engaged.
///
/// A *cast* is the shadow a surface style throws — under a style that
/// states no cast vocabulary this whole axis is a no-op, because there is
/// nothing to move and nothing to hide.
///
/// **Engage is not a single input.** The reference design this axis is
/// drawn from is a web-only library and states the behaviour on `:hover`
/// alone. Ported literally that breaks on touch: `:hover` there is not
/// absent but *emulated* — it turns on at a tap and stays on until the
/// next tap elsewhere, so the control would sit in its engaged shape
/// indefinitely. So engage resolves per device capability: **hover where
/// a pointer exists, press where one does not.** Each platform reaches
/// that the way its own runtime already expresses it, and neither may
/// drop the press path — it is the only path touch has.
///
/// This enum says *when the cast changes*, never what it is worth. The
/// offset, colour and thickness stay with the surface style, which is
/// what lets one control opt into a different motion without restating
/// the material.
///
/// It also does not decide whether a cast exists at all. A cast is the
/// shadow of a *filled box*: a control with no fill has no box to throw
/// one, so it reads as [noShadow] whatever it asks for here. The two
/// answer different questions — this one is "what do I want", the fill is "is
/// there a box to draw".
enum CoreCastMotion {
  /// Casts at rest; engaging hides the cast and the control travels into
  /// the space it just vacated. The reference calls this `default`.
  ///
  /// The pair is the point — the hide and the travel are one statement,
  /// and splitting them across two clocks reads as two events rather than
  /// one control being pressed.
  defaultMotion,

  /// Never casts, and so never travels. The reference calls this
  /// `noShadow`.
  ///
  /// Distinct from a [defaultMotion] control that happens to have no
  /// fill: this is a control saying it wants no cast, rather than one
  /// that would take the style's cast if it had a box for it.
  noShadow,

  /// Casts nothing at rest; engaging grows the cast and the control
  /// travels the *other* way — the mirror of [defaultMotion], not a
  /// second flavour of it. The reference calls this `reverse`.
  ///
  /// Only reaches the cast a *style* injects. A control handed a shadow
  /// of its own (`Fab`'s elevation) already casts at rest, so "no cast
  /// at rest" is already false there — reverse has nothing to invert,
  /// and the control keeps [defaultMotion]'s hide-and-travel regardless
  /// of what this value asks for. The same precedence that lets a
  /// stated shadow outrank [noShadow].
  reverse,
}
