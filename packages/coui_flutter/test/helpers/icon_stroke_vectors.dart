import 'dart:convert';
import 'dart:io';

/// The vector table coui_core owns — same relative-path pattern as the clock
/// format vectors. Core, Flutter and Web tests all read this one file, so a
/// fix that lands on one platform fails on the others.
const String kIconStrokeVectorsPath =
    '../coui_core/test/fixtures/icon_stroke_vectors.json';

/// The unit count of the viewBox every row is stated for (Lucide glyphs).
const double kIconStrokeViewBox = 24;

/// One row of the shared table: the stroke an icon of [tokenSize] draws.
class IconStrokeVector {
  /// Creates a row.
  const IconStrokeVector({
    required this.tokenSize,
    required this.renderedWidth,
    required this.svgString,
  });

  /// The icon size before the theme scaling.
  final double tokenSize;

  /// The stroke the screen shows at scaling 1, in token px.
  final double renderedWidth;

  /// The `stroke-width` attribute written into the SVG for a 24-unit viewBox.
  final String svgString;
}

/// Reads every row of the shared table.
List<IconStrokeVector> loadIconStrokeVectors() {
  final doc =
      jsonDecode(File(kIconStrokeVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  if (doc['viewBox'] != kIconStrokeViewBox) {
    throw StateError('The vectors are stated for a 24-unit viewBox.');
  }

  return [
    for (final c in (doc['cases']! as List).cast<Map<String, Object?>>())
      IconStrokeVector(
        tokenSize: (c['tokenSize']! as num).toDouble(),
        renderedWidth: (c['renderedWidth']! as num).toDouble(),
        svgString: c['svgString']! as String,
      ),
  ];
}
