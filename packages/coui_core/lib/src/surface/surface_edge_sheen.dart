import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/surface/surface_edge_bevel.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// Light running *along* a surface's edges — a lighter touch across the
/// horizontal runs, a heavier one down the vertical, fading out at every
/// corner.
///
/// This is what a translucent panel does that an opaque one does not: its
/// edge is a thickness, not a line, so light entering it travels the run
/// and dies at the corners where the two runs meet at an angle.
///
/// ## The two runs differ in weight, not in polarity
///
/// One run is not lit while the other is shaded. Both step away from the
/// surface in whichever direction that surface leaves room, and what
/// distinguishes them is how far.
///
/// The reason is that a surface near either end of the scale has room on
/// one side only. A light theme's surface is very nearly white, so a
/// brighter run has nowhere to go; a dark theme's is very nearly black,
/// and a darker one has nowhere to go either. Colours fixed at those ends
/// therefore produce a run that is invisible in one mode — and since the
/// invisible one would be the horizontal pair in light and the vertical
/// pair in dark, the band would appear to turn a quarter circle when the
/// theme changed.
///
/// So a colour for either run has to be stated relative to the surface.
/// Both then hold their relationship in both modes, and the disagreement
/// that defines this treatment survives the theme.
///
/// ## Not the same thing as `highlightRim`
///
/// Both are called a rim in English and they are different mechanisms, so
/// naming them apart is load-bearing — a later reader who merges them
/// loses one of the two looks:
///
/// | | mechanism | direction |
/// |---|---|---|
/// | `highlightRim` (clay) | inset box-shadow | uniform on all edges |
/// | this (glass) | gradient band at the border | horizontal ≠ vertical |
///
/// An inset shadow cannot express this: it is uniform by construction, and
/// the whole signature here is that the top and bottom runs disagree with
/// the left and right ones. A gradient band cannot express clay's soft
/// interior glow either. Neither subsumes the other.
///
/// ## The band is size-independent on purpose
///
/// Every value is either a thickness or a fraction of a run, so one
/// declaration serves an element of any size. That is what lets this live
/// in the theme axis at all: an edge treatment stated in absolute lengths
/// would mean something different on a chip than on a panel, and a style
/// axis has no element to measure against when it is written.
@immutable
class CoreSurfaceEdgeSheen {
  /// Creates an edge sheen.
  const CoreSurfaceEdgeSheen({
    required this.width,
    required this.lightColor,
    required this.darkColor,
    this.fade = defaultFade,
    this.bevel,
  });

  /// Thickness of the band, in logical pixels.
  ///
  /// Sub-pixel values are meaningful here and are not a mistake: the band
  /// reads as a boundary of the material rather than as a drawn border,
  /// and a full pixel at a high device ratio reads as the latter.
  final double width;

  /// The colour of the horizontal runs — the top and bottom edges.
  ///
  /// The lighter-weight of the two: it sits nearer the surface than
  /// [darkColor] does, in both modes.
  final CoreColor lightColor;

  /// The colour of the vertical runs — the left and right edges.
  ///
  /// The heavier of the two. Matching [lightColor]'s weight would read as
  /// a uniform outline, which is the look this treatment exists to be
  /// distinguishable from.
  final CoreColor darkColor;

  /// How far along each run the streak takes to reach full strength,
  /// as a fraction of that run's length, measured from the corner.
  ///
  /// Smaller means a longer streak. Above `0.5` the two ends of a run
  /// would overlap before either reaches full strength, so the streak
  /// never reaches its stated colour — the value is clamped by consumers
  /// rather than asserted, because a theme is data and data arrives from
  /// places an assertion cannot reach.
  final double fade;

  /// The wall that gives the edge a near side and a far side, drawn in the
  /// palette's surface highlight. Null for an edge that is only a band.
  ///
  /// The band above says *where* the surface ends. This says the edge has
  /// a near side and a far side — which is the whole difference between a
  /// pane and a blurred rectangle, and it cannot be had by widening the
  /// band. Measured: doubling `width` changed almost nothing, because the
  /// run colours are stated relative to the surface and a thicker line of
  /// a nearly-surface colour is still a line. A specular wall needs a
  /// colour *brighter than the surface in both modes*, which is exactly
  /// the slot the highlight token holds — white in light, a light grey in
  /// dark, so the wall never inverts.
  ///
  /// ## Why these are not `CoreSurfaceGeometryConstraint.highlightRim`
  ///
  /// Same mechanism, and both platforms already draw inset layers. What
  /// differs is when they are owed. A rim decorates a surface that casts
  /// — its resolver returns nothing for an empty shadow stack, on purpose,
  /// so that a style cannot turn a flat surface into a raised one. That
  /// gate is right for a rim and wrong here: a pane of glass has an edge
  /// whether or not it is lifted off the page, and the surface this was
  /// built for casts no shadow at all. Routing the wall through the rim
  /// would have made it appear on dialogs and vanish on cards, which is
  /// the same value reading as a bug.
  ///
  /// So the wall is part of the material's edge and lands wherever the
  /// band lands, and the two treatments stay distinguishable in the way
  /// the section above describes.
  final CoreSurfaceEdgeBevel? bevel;

  /// The fade this axis uses when a recipe states none.
  static const double defaultFade = 0.18;

  /// The shortest streak the shape can express — a run that reaches full
  /// strength immediately at each end.
  static const double minFade = 0;

  /// The longest. Above this the two ends of a run would overlap before
  /// either reached full strength, so the streak never reaches its
  /// stated colour and the extra value means nothing.
  static const double maxFade = 0.5;

  /// `fade` clamped to the range in which the streak is expressible.
  ///
  /// Single source for the clamp so the two platforms cannot disagree
  /// about what an out-of-range theme means.
  double get effectiveFade => fade.clamp(minFade, maxFade);

  /// Whether the light on this edge is stated per mode — the wall's angle
  /// is the only term of the sheen that is.
  bool get statesByMode => bevel?.statesByMode ?? false;

  /// This sheen as it is lit in [brightness]: the wall collapsed to the
  /// angle that mode draws it at.
  ///
  /// Returns this very instance when nothing is stated per mode, so a seat
  /// that collapses every sheen it hands out allocates nothing for the
  /// styles that never ask. The band's own colours are tokens and resolve
  /// per mode where they are painted; they are not part of this.
  CoreSurfaceEdgeSheen atBrightness(CoreBrightness brightness) {
    final wall = bevel;
    if (wall == null || !wall.statesByMode) return this;

    return CoreSurfaceEdgeSheen(
      width: width,
      lightColor: lightColor,
      darkColor: darkColor,
      fade: fade,
      bevel: wall.atBrightness(brightness),
    );
  }

  /// Creates a copy with modified values.
  CoreSurfaceEdgeSheen copyWith({
    double? width,
    CoreColor? lightColor,
    CoreColor? darkColor,
    double? fade,
    CoreSurfaceEdgeBevel? bevel,
  }) => .new(
    width: width ?? this.width,
    lightColor: lightColor ?? this.lightColor,
    darkColor: darkColor ?? this.darkColor,
    fade: fade ?? this.fade,
    bevel: bevel ?? this.bevel,
  );

  /// Serializes this sheen to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'width': width,
    'lightColor': lightColor.toString(),
    'darkColor': darkColor.toString(),
    'fade': fade,
    'bevel': bevel?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceEdgeSheen &&
          width == other.width &&
          lightColor == other.lightColor &&
          darkColor == other.darkColor &&
          fade == other.fade &&
          bevel == other.bevel;

  @override
  int get hashCode => Object.hash(width, lightColor, darkColor, fade, bevel);

  @override
  String toString() =>
      'CoreSurfaceEdgeSheen(width: $width, fade: $fade, '
      'bevel: $bevel)';
}
