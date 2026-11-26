/// What kind of surface a component draws — the one thing a component
/// says about its own material.
///
/// ## Why the component states this and the axis does not infer it
///
/// A surface style has to give a floating panel a different material than
/// a card: nested translucency multiplies, and a menu over a glass page
/// reads as fog unless it is more definite than what it covers. Apple
/// states the same split as two variants — `regular` adjusts the
/// luminosity of what is behind it, `clear` stays out of the way.
///
/// The tempting shape is for the axis to hold the split: a list of which
/// components float. That list is wrong the day someone adds a component
/// and does not find it, and the failure is silent — the new surface
/// simply gets the other material and nobody is told. The axis rule this
/// kit already follows says so directly:
///
/// > 축이 컴포넌트 목록을 들고 있지 않는다 — 목록은 새 컴포넌트가
/// > 추가될 때 조용히 낡는다.
///
/// So the split lives where the surface is declared. A component already
/// marks itself as a surface; it now says *which kind*, one word, at that
/// same place. Someone building a new surface decides it there, with the
/// component in front of them, instead of a stranger deciding it later in
/// a table.
///
/// ## This is not a per-component theme bundle
///
/// Two roles, ~140 components. What the recipe authors is two materials,
/// and every component points at one of them — the authoring surface does
/// not grow with the component count, which is the thing that makes
/// per-preset bundles unmaintainable.
///
/// ## How to decide
///
/// Not by how important the component feels. By whether **the code has
/// evidence that it floats** — an overlay portal, an overlay layer, a
/// popup route, an anchored popover, or sticky/fixed docking. If none of
/// that is there, it sits in the content layer whatever it is called.
///
/// That test is not academic: it has already overturned two guesses. A
/// segmented tab bar was read as floating until the check found zero
/// sticky/fixed/portal evidence — and the same survey had classified an
/// identical rail as content. Shipping the guess would have given a tab
/// bar *inside the page flow* an overlay material, so the page would have
/// shown through it. A command palette was overturned the same way: the
/// marker cited as evidence turned out to be a shadow opt-in that 23
/// unrelated files also carry.
enum CoreSurfaceRole {
  /// Floats above the content layer — overlays, navigation, toolbars,
  /// menus.
  ///
  /// Evidence, not vibes: an overlay portal, an overlay layer, a popup
  /// route, an anchored popover, or sticky/fixed docking.
  functional,

  /// A face in the content layer — cards, tables, body panels, controls.
  ///
  /// The default reading. A surface with no evidence that it floats is
  /// this one, because being wrong in this direction costs a material
  /// that is slightly too plain, while being wrong in the other gives a
  /// component in the page flow a material designed to sit over it.
  content;

  /// The role a surface gets when it does not say.
  ///
  /// Content rather than functional for the reason above: the failure it
  /// produces is the recoverable one.
  static const CoreSurfaceRole defaultRole = content;
}
