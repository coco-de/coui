/// The decorative "something behind the glass" backdrop painted into
/// `.preview-pane` when `liquidGlass` is the active surface style — **single
/// source**.
///
/// Pure data: no jaspr, no Flutter (`chain_permutations.dart` precedent).
/// Before this file the pattern lived only as a CSS string literal in
/// `site_head.dart`, so the Flutter preview harness had no way to draw it —
/// its own opaque `CoUIApp.background` (kept opaque on purpose, see
/// `preview_app.dart`'s doc comment) hid it completely. `site_head.dart`
/// (CSS emit) and `docs_site`'s `GlassPreviewBackdropPainter` (Flutter emit)
/// each read these same values and build their own platform's paint
/// primitives — the Core→platform-emit split this codebase already uses for
/// every `CoreXxxStyle` (`core/style-contract.md`), applied to a docs-only
/// decoration.
///
/// # Why "coarse" is a feature, not a shortcut
///
/// The two renderers do not resolve percentages, gradient angles, or layer
/// blending identically, so the two panes were never going to be
/// pixel-identical — that was never this backdrop's job
/// (`glass_preview_backdrop_test.dart` measured it and calls it "coarse on
/// purpose"). Its job is only to give the glass material *something with a
/// hard edge to bend and some fine structure to blur*; both platforms clear
/// that bar with the same numbers, which is what the test asserts on this
/// file's constants directly.
library;

/// One hard-edged grid axis — Web emits it as a `repeating-linear-gradient`,
/// Flutter paints it as evenly-spaced solid bands.
class GlassGridLine {
  const GlassGridLine({
    required this.colorArgb,
    required this.lineWidth,
    required this.spacing,
  });

  /// 0xAARRGGBB.
  final int colorArgb;

  /// Logical px width of the drawn line before the gap starts.
  final int lineWidth;

  /// Logical px period of one line+gap repeat.
  final int spacing;
}

/// The single diagonal band crossing the pane — the one layer whose bent
/// edge lets refraction be judged at all (a smooth wash bends into another
/// smooth wash).
class GlassBand {
  const GlassBand({
    required this.angleDeg,
    required this.colorArgb,
    required this.startPercent,
    required this.endPercent,
  });

  /// CSS `linear-gradient` angle convention: 0deg points up, increases
  /// clockwise.
  final int angleDeg;
  final int colorArgb;

  /// Where along the gradient axis the band starts/ends, 0..100.
  final int startPercent;
  final int endPercent;
}

/// One soft colour wash, positioned as a percentage of the pane's box —
/// coverage filler, deliberately quieter than the grid/band (see this
/// file's top doc comment).
class GlassWash {
  const GlassWash({
    required this.centerXPercent,
    required this.centerYPercent,
    required this.colorArgb,
    required this.radiusPercent,
  });

  /// 0 = left/top edge, 100 = right/bottom edge.
  final int centerXPercent;
  final int centerYPercent;
  final int colorArgb;

  /// How far the wash fades out, as a percentage of the gradient's own
  /// sizing. CSS's default sizing keyword (`farthest-corner`) and Flutter's
  /// `RadialGradient.radius` (fraction of the shorter side) do not agree
  /// pixel-for-pixel — acceptable per this file's "coarse on purpose" doc.
  final int radiusPercent;
}

/// A full backdrop recipe: one hard grid (both axes), one diagonal band,
/// three washes, and the opaque fill beneath all of it.
class GlassPreviewBackdrop {
  const GlassPreviewBackdrop({
    required this.horizontalGrid,
    required this.verticalGrid,
    required this.band,
    required this.washes,
    required this.baseColorArgb,
  });

  /// CSS 0deg — bands constant along X, repeating along Y.
  final GlassGridLine horizontalGrid;

  /// CSS 90deg — bands constant along Y, repeating along X.
  final GlassGridLine verticalGrid;

  final GlassBand band;

  /// Front-to-back paint order (matches CSS's `background` layer order:
  /// earlier entries sit on top).
  final List<GlassWash> washes;

  /// The opaque fallback fill beneath every layer above (CSS
  /// `var(--color-surface, <this>)`, Flutter's outermost solid fill) —
  /// never transparent, so neither renderer's output depends on compositing
  /// against whatever sits behind the pane.
  final int baseColorArgb;
}

/// Light-theme recipe. Values match the frame `glass_preview_backdrop_test`
/// measured refraction/frost against — changing them moves that baseline.
const GlassPreviewBackdrop kGlassPreviewBackdropLight = GlassPreviewBackdrop(
  horizontalGrid: GlassGridLine(
    colorArgb: 0x2E0F172A,
    lineWidth: 4,
    spacing: 26,
  ),
  verticalGrid: GlassGridLine(
    colorArgb: 0x2E0F172A,
    lineWidth: 4,
    spacing: 26,
  ),
  band: GlassBand(
    angleDeg: 126,
    colorArgb: 0xA61D4ED8,
    startPercent: 30,
    endPercent: 41,
  ),
  washes: [
    GlassWash(
      centerXPercent: 18,
      centerYPercent: 22,
      colorArgb: 0x557C3AED,
      radiusPercent: 42,
    ),
    GlassWash(
      centerXPercent: 82,
      centerYPercent: 30,
      colorArgb: 0x550891B2,
      radiusPercent: 45,
    ),
    GlassWash(
      centerXPercent: 45,
      centerYPercent: 88,
      colorArgb: 0x55E11789,
      radiusPercent: 40,
    ),
  ],
  baseColorArgb: 0xFFFFFFFF,
);

/// Dark-theme recipe — same structure, brighter/cooler washes to read
/// against a dark base.
const GlassPreviewBackdrop kGlassPreviewBackdropDark = GlassPreviewBackdrop(
  horizontalGrid: GlassGridLine(
    colorArgb: 0x24E2E8F0,
    lineWidth: 4,
    spacing: 26,
  ),
  verticalGrid: GlassGridLine(
    colorArgb: 0x24E2E8F0,
    lineWidth: 4,
    spacing: 26,
  ),
  band: GlassBand(
    angleDeg: 126,
    colorArgb: 0x8C60A5FA,
    startPercent: 30,
    endPercent: 41,
  ),
  washes: [
    GlassWash(
      centerXPercent: 18,
      centerYPercent: 22,
      colorArgb: 0x44A78BFA,
      radiusPercent: 42,
    ),
    GlassWash(
      centerXPercent: 82,
      centerYPercent: 30,
      colorArgb: 0x4422D3EE,
      radiusPercent: 45,
    ),
    GlassWash(
      centerXPercent: 45,
      centerYPercent: 88,
      colorArgb: 0x44F472B6,
      radiusPercent: 40,
    ),
  ],
  baseColorArgb: 0xFF1E293B,
);
