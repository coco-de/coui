/// Whether a piece of evidence can be opened right now — and, when it
/// cannot, on what terms.
library;

/// The stroke pattern a [CoreDisclosureKind] is drawn with.
///
/// This is the **shape** half of a kind's identity, and the half that
/// survives a colour-blind reader and a black-and-white printout. It is
/// deliberately not a style slot: see [CoreDisclosureKind.stroke].
///
/// Maps to:
/// - Web: CSS `border-style` (`solid` / `dashed`) via the Tailwind
///   `border-solid` / `border-dashed` utility.
/// - Flutter (future twin): a solid `Border` vs. a dash-painted one.
enum CoreDisclosureStroke {
  /// An unbroken outline. Reads as "this is settled".
  solid,

  /// A broken outline. Reads as "this is withheld" — the gaps in the
  /// stroke are the point, so the state is legible without colour.
  dashed,
}

/// What a consumer-facing site is claiming about one piece of evidence.
///
/// The three kinds answer one question — *can I open this right now?* —
/// and each answers it differently:
///
/// | kind         | can open now | outline        | dot |
/// |--------------|--------------|----------------|-----|
/// | [open]       | yes          | solid          | no  |
/// | [commitment] | no, later    | solid          | yes |
/// | [private]    | no, ever     | dashed         | no  |
///
/// ### Why [stroke] and [hasMarker] live on the enum
///
/// They are the component's WCAG 1.4.1 guarantee (색 이외의 수단으로도
/// 구분), so they must not be reachable from a style slot. If a project
/// theme could set all three kinds to `solid` with no marker, the three
/// states would collapse into colour alone the moment a reader is
/// colour-blind or prints the page — and the 실사 담당자 who prints the
/// evidence pack to PDF does exactly that. A kind therefore *carries*
/// its shape; `CoreDisclosureBadgeStyle` can retune colour, padding,
/// radius and typography, but it has no field that can erase the
/// distinction.
enum CoreDisclosureKind {
  /// Openable right now — the site has a live link to the evidence.
  open(stroke: CoreDisclosureStroke.solid, hasMarker: false),

  /// Not openable yet, but promised: the evidence is handed over at
  /// contract signing / kickoff. Solid outline (the promise is firm)
  /// plus a marker dot (it has not landed yet).
  commitment(stroke: CoreDisclosureStroke.solid, hasMarker: true),

  /// Not openable, and not going to be. A reason always accompanies it
  /// in the label text — a bare "비공개" with no cause reads as evasion.
  private(stroke: CoreDisclosureStroke.dashed, hasMarker: false);

  const CoreDisclosureKind({required this.stroke, required this.hasMarker});

  /// The outline pattern this kind is drawn with. Fixed per kind — see
  /// the class doc for why this is not a style slot.
  final CoreDisclosureStroke stroke;

  /// Whether this kind renders the deferral marker (a small dot before
  /// the label). Fixed per kind, for the same reason as [stroke]: it is
  /// the second non-colour signal that separates [commitment] from
  /// [open], which share a solid outline.
  final bool hasMarker;
}
