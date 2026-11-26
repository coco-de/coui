/// A small filled vector drawing, stated once for every platform.
library;

import 'package:meta/meta.dart';

/// How the sub-paths of a [CoreVectorGlyph] fill where they overlap.
///
/// A fact about the drawing, not a style: an outline ring is a big shape with
/// a hole cut in it, and only the fill rule says which of the two shapes is
/// the hole.
enum CoreVectorFillRule {
  /// A point is inside when a ray from it crosses the outline an odd number of
  /// times — nested sub-paths cut holes.
  evenOdd,

  /// A point is inside when the outline winds around it at all — nested
  /// sub-paths of the same direction add up.
  nonZero,
}

/// A filled vector drawing in its own coordinate box.
///
/// Platform-neutral: the box is `width × height` units with its origin at the
/// top-left, and [path] is drawn in those units. A platform places the box in
/// a rectangle and scales the path by `rect.width / width` and
/// `rect.height / height` — never by anything the glyph states itself, so the
/// drawing has no size of its own beyond its proportions.
///
/// Maps to:
/// - Flutter: a `Path` parsed from [path], filled by the active fill rule.
/// - Web: an inline `<svg viewBox="0 0 width height"><path d=… fill-rule=…/>`.
/// - Figma: a vector node whose `vectorPaths` carry [path] and the winding
///   rule.
///
/// The colour is not part of the glyph — it belongs to the style that draws
/// it.
@immutable
class CoreVectorGlyph {
  /// Creates a [CoreVectorGlyph].
  const CoreVectorGlyph({
    required this.path,
    required this.width,
    required this.height,
    required this.fillRule,
  });

  /// The outline, in SVG path syntax restricted to the four commands the
  /// drawing needs: absolute `M x y`, `L x y`, `C x1 y1 x2 y2 x y` and `Z`,
  /// every number separated by one space.
  ///
  /// The restriction is the contract. A platform needs a parser for these four
  /// commands and nothing else, and the same string is accepted unchanged by
  /// an SVG `<path d>` and by Figma's `vectorPaths`.
  final String path;

  /// Width of the coordinate box [path] is drawn in.
  final double width;

  /// Height of the coordinate box [path] is drawn in.
  final double height;

  /// How overlapping sub-paths fill.
  final CoreVectorFillRule fillRule;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreVectorGlyph &&
          path == other.path &&
          width == other.width &&
          height == other.height &&
          fillRule == other.fillRule;

  @override
  int get hashCode => Object.hash(path, width, height, fillRule);
}
