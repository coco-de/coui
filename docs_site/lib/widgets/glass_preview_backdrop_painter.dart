// depend_on_referenced_packages — `flutter` reaches this package only
// transitively (via `coui_flutter`/`jaspr_flutter_embed`), the same reason
// every other Flutter-importing file here (`preview_app.dart` included)
// carries this ignore.
// ignore_for_file: depend_on_referenced_packages
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:docs_core/shared/glass_preview_backdrop.dart';
import 'package:flutter/widgets.dart';

/// Paints the same [GlassPreviewBackdrop] recipe `site_head.dart` emits as
/// CSS (`docs_core`'s single source, `shared/glass_preview_backdrop.dart`),
/// as a full-bleed Flutter layer.
///
/// Always fully opaque, by construction — never relies on canvas
/// transparency. `PreviewApp` forces `CoUIApp.background` opaque for every
/// surface style (`#4446`: a genuinely transparent scene shows CanvasKit's
/// black clear colour instead of the host page, and 34 docs "chain gallery"
/// pages hit that whenever their colour axis rotates to `.transparent`).
/// This layer paints its own opaque base fill first, so the liquidGlass demo
/// backdrop reaches the Flutter pane without ever depending on the canvas
/// showing anything through it.
class GlassPreviewBackdropLayer extends StatelessWidget {
  const GlassPreviewBackdropLayer({required this.recipe, super.key});

  final GlassPreviewBackdrop recipe;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GlassPreviewBackdropPainter(recipe), child: const SizedBox.expand());
}

/// Percent (0..100) → unit fraction (0..1), for gradient stops and radii.
const double kPercentScale = 100;

/// Degrees → radians conversion (a half turn is 180deg / pi radians).
const double kDegreesPerHalfTurn = 180;

class _GlassPreviewBackdropPainter extends CustomPainter {
  const _GlassPreviewBackdropPainter(this.recipe);

  final GlassPreviewBackdrop recipe;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Opaque base first — everything above only ever adds colour on top of
    // it, so the canvas is never asked to show anything through itself.
    canvas.drawRect(rect, Paint()..color = Color(recipe.baseColorArgb));

    // Reversed: `recipe.washes` is front-to-back (CSS layer-list order,
    // earlier = on top), canvas painting is back-to-front.
    for (final wash in recipe.washes.reversed) {
      canvas.drawRect(rect, _washPaint(wash, rect));
    }

    canvas.drawRect(rect, _bandPaint(recipe.band, rect));
    _paintGrid(canvas, size, recipe.verticalGrid, horizontal: false);
    // Horizontal grid painted last so it sits on top, matching the CSS
    // layer order (`site_head.dart`'s `_glassBackdropCss` lists it first).
    _paintGrid(canvas, size, recipe.horizontalGrid, horizontal: true);
  }

  /// CSS `radial-gradient(circle at X% Y%, colour, transparent R%)` with no
  /// explicit size keyword sizes itself to `farthest-corner`: `R%` is a
  /// percentage of the distance from the center to whichever of the box's
  /// four corners is furthest away — a distance that depends on the box's
  /// aspect ratio and grows without bound as a box gets taller or wider.
  ///
  /// `RadialGradient.radius` (a fraction of the box's *shortest* side) does
  /// not track that: for a box far taller than it is wide — this preview's
  /// normal shape, see `preview_app.dart`'s doc comment on why — it reads
  /// as a wash that shrunk to a fraction of the width while the CSS pane's
  /// wash grew with the height, which is what made the Flutter pane's
  /// washes read as barely-there next to Web's vivid ones even though both
  /// used the same [GlassWash.radiusPercent]. Computed in true pixels
  /// instead, the same way [_bandPaint] computes the band's true angle.
  Paint _washPaint(GlassWash wash, Rect rect) {
    final center = Offset(
      rect.left + rect.width * wash.centerXPercent / kPercentScale,
      rect.top + rect.height * wash.centerYPercent / kPercentScale,
    );
    final farthestCorner = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].map((corner) => (corner - center).distance).reduce(math.max);
    final radius = farthestCorner * wash.radiusPercent / kPercentScale;

    return Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        Color(wash.colorArgb),
        const Color(0x00000000),
      ]);
  }

  /// CSS `linear-gradient` angle convention (0deg = to top, clockwise),
  /// converted to a true pixel line through [rect] — not a [LinearGradient]
  /// (its `begin`/`end` are box-relative [Alignment] fractions, which bakes
  /// in a dependency on the box's aspect ratio that CSS angles do not
  /// have). The Flutter pane is padded out to `ViewConstraints.maxHeight`
  /// while the CSS pane sizes to its content, so the two panes routinely
  /// disagree about aspect ratio — an `Alignment`-based band read as a
  /// visibly different angle (and, past a certain aspect skew, as a
  /// disconnected shape) between them even though both used the same
  /// [GlassBand.angleDeg].
  Paint _bandPaint(GlassBand band, Rect rect) {
    final radians = band.angleDeg * math.pi / kDegreesPerHalfTurn;
    final direction = Offset(math.sin(radians), -math.cos(radians));
    // The CSS gradient-line length: the box's own diagonal projected onto
    // `direction`, so the line's ends land on the box's far corners exactly
    // as a CSS `linear-gradient` computes them (spec's "simple case"
    // algorithm), regardless of `rect`'s aspect ratio.
    final lineLength = rect.height * direction.dy.abs() + rect.width * direction.dx.abs();
    final half = direction * (lineLength / 2);
    final from = rect.center - half;
    final to = rect.center + half;

    final color = Color(band.colorArgb);
    final start = band.startPercent / kPercentScale;
    final end = band.endPercent / kPercentScale;

    return Paint()
      ..shader = ui.Gradient.linear(
        from,
        to,
        [
          const Color(0x00000000),
          const Color(0x00000000),
          color,
          color,
          const Color(0x00000000),
          const Color(0x00000000),
        ],
        // Repeated stop positions (start/start, end/end) is how a hard
        // edge is expressed — the same technique the CSS side uses.
        [0, start, start, end, end, 1],
      );
  }

  void _paintGrid(Canvas canvas, Size size, GlassGridLine line, {required bool horizontal}) {
    final paint = Paint()..color = Color(line.colorArgb);
    final lineWidth = line.lineWidth.toDouble();
    final extent = horizontal ? size.height : size.width;
    for (var position = 0.0; position < extent; position += line.spacing) {
      canvas.drawRect(
        horizontal
            ? Rect.fromLTWH(0, position, size.width, lineWidth)
            : Rect.fromLTWH(position, 0, lineWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlassPreviewBackdropPainter oldDelegate) => oldDelegate.recipe != recipe;
}
