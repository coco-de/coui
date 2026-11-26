// #3665 — the opaque page-background color a Flutter capture composites
// against, mirroring `docs_core/lib/site_head.dart`'s `docsContentTheme()`:
//
//   background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950)
//
// — the color the Web offline harness's `jaspr_content` reset paints
// behind every captured component's page (`jaspr_content`'s `ThemeColors`
// define these as `oklch(...)`; the constants below are the sRGB values a
// browser actually renders that OKLCH to — confirmed empirically against
// a real Web capture's own corner pixel: `(248, 250, 252, 255)`, exactly
// Tailwind's well-known slate-50 hex).
//
// Why this matters: `RenderRepaintBoundary.toImage()` captures *with* an
// alpha channel. The four corner regions of a rounded component's own
// bounding box (outside its border-radius) are TRANSPARENT (alpha 0) in a
// bare Flutter capture — nothing painted there. A browser screenshot has
// no such concept; the same region in a Web capture shows the page's own
// opaque background bleeding through (alpha 255). Comparing an alpha-0
// corner against an opaque one is a fixed pixel-diff floor on *every*
// rounded component's capture (confirmed: ~2%, unrelated to any real
// rendering difference) — wrapping the capture target in
// `ColoredBox(pageBackgroundFor(dark: …))` composites Flutter's capture
// over the same opaque color Web's corners already show, so both sides'
// corners agree.
//
// This decision (opaque, not transparent) is deliberate, not incidental:
// a translucent surface (liquid-glass, 70% alpha) composited against an
// opaque page background produces the same visual result a real screen
// does; captured against transparency, Web's `backdrop-filter` has
// nothing behind it to blur and becomes a no-op — transparent capture
// would silently break every translucent-surface component's parity
// signal, not just move a corner-pixel baseline.
import 'package:flutter/painting.dart' show Color;

/// Mirrors `docsContentTheme()`'s light-mode page background
/// (`ThemeColors.slate.$50`, Tailwind slate-50).
const Color kParityPageBackgroundLight = Color(0xFFF8FAFC);

/// Mirrors `docsContentTheme()`'s dark-mode page background
/// (`ThemeColors.zinc.$950`, Tailwind zinc-950).
const Color kParityPageBackgroundDark = Color(0xFF09090B);

/// The page-background color a Flutter capture should composite against
/// for [dark] — the single call site every `test/parity/*_test.dart`
/// capture wraps its `RepaintBoundary` child with
/// (`ColoredBox(color: parityPageBackground(dark: …))`).
Color parityPageBackground({required bool dark}) =>
    dark ? kParityPageBackgroundDark : kParityPageBackgroundLight;
