import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/display/mockup_device/mockup_device_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// How far past its own box a half of the device is still drawn (logical
/// px). A half is cut at the hinge only; its buttons and its cast shadow lie
/// outside the body box and must survive the cut.
///
/// Not a design token: a clip bound, larger than anything the hardware
/// reaches.
const double _kCssHalfClipReach = 512;

/// How far past the hinge the left half's body is still drawn (logical px).
/// Each half's cut is anti-aliased, so two cuts on the same line let the
/// page through an opaque body as a hairline. The left half is painted over
/// the right one, and its body drawn this much further covers both soft
/// edges.
///
/// Not a design token: a rendering allowance, one pixel of the page.
const double _kCssHingeOverlap = 1;

/// Decimals kept in a length a transform states (`rem`): a hundred-thousandth
/// of a rem is far below a device pixel, and the style stays short.
///
/// Not a design token: a formatting bound.
const int _kCssLengthDigits = 5;

/// Decimals kept in an angle a transform states (`rad`).
///
/// Not a design token: a formatting bound.
const int _kCssAngleDigits = 6;

/// Decimals kept in the number a corner's radius is multiplied by where a
/// slab's edge ends: a hundred-thousandth of a corner is far below a device
/// pixel.
///
/// Not a design token: a formatting bound.
const int _kCssRatioDigits = 5;

/// A part of the device: laid at the stage's corner, where its transform
/// starts from. Structure only — no chrome.
const String _kPart =
    '${WebLayout.absolute} ${WebLayout.leftZero} ${WebLayout.topZero}';

/// What fills a slab's edge: as tall as the strip it lies in, from its top.
/// Which side it is pinned to is the pose's to say. Structure only.
const String _kEdgeFill =
    '${WebLayout.absolute} ${WebLayout.topZero} ${WebLayout.hFull}';

/// Keeps a subtree mounted and out of sight. `visibility` alone does not: a
/// descendant that states `visibility: visible` — a switcher does, for the
/// pane it shows — is painted through a hidden ancestor, while nothing is
/// painted through one with no opacity.
const String _kUnseen = '${WebLayout.invisible} opacity-0';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `MockupFoldable`.
///
/// DOM shape (back to front — every part is an absolute child of `root`, so
/// later siblings paint over earlier ones; the shape is the same at every
/// angle, and only styles and the copies' presence change):
///
/// ```text
/// root (<div>)                          // relative, the open body's box: the stage
///   ├─ live (<div>)                     // the open body, drawn as it is while flat;
///   │    │                              //   hidden and inert while bent, still mounted
///   │    └─ MockupDevice                // tablet on its side
///   │         └─ innerScreen …          // what its screen holds — see
///   │                                   //   [ResolvedMockupFoldableScreen]
///   ├─ rightHalf (<div>)                // the open body's box, turned
///   │    └─ rightHalfCut (<div>)        // that box, cut at the hinge
///   │         ├─ MockupDevice           // bent only: a second rendering of
///   │         │    └─ innerScreen …     //   the open body, the content built again
///   │         ├─ innerScrim (<div>)     // the inner screen going dark
///   │         └─ rightShade (<div>)     // a half turned from the viewer
///   ├─ rightEdge (<div>)                // the right slab's outer edge: a strip
///   │    │                              //   as wide as the slab is deep, clipping
///   │    └─ rightEdgeFill (<div>)       // the edge colour, cut at both ends by
///   │                                   //   the corners of the face behind it
///   ├─ leftHalf (<div>)                 // the other side of the hinge
///   │    └─ leftHalfCut (<div>)
///   │         ├─ MockupDevice
///   │         │    └─ innerScreen …
///   │         ├─ innerScrim (<div>)
///   │         └─ leftShade (<div>)
///   ├─ leftEdge (<div>)                 // the left slab's outer edge
///   │    └─ leftEdgeFill (<div>)
///   └─ cover (<div>)                    // the back of the left slab
///        ├─ MockupDevice                // phone
///        │    └─ coverScreen …
///        ├─ coverScrim (<div>)
///        └─ coverShade (<div>)
/// ```
///
/// The device draws no body of its own: the three bodies are `MockupDevice`s
/// given the nested [innerDeviceStyle] / [coverDeviceStyle] as they are. What
/// this resolver states is where each part stands at the angle shown, how
/// dark it is, and what the device adds to its two screens — the status
/// island ([innerScreen], [coverScreen]).
///
/// Each part is placed by a list of CSS transform functions in `rem` — the
/// steps `CoreMockupFoldPose` names — rather than by one `matrix3d`. The
/// bodies are sized in `rem`, so a matrix in px would come apart from them
/// at any root font size but 16px.
///
/// `mockup_foldable.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in the
/// widget body.
class ResolvedMockupFoldable implements WebResolvedChrome {
  /// Creates a [ResolvedMockupFoldable].
  const ResolvedMockupFoldable({
    required this.root,
    required this.live,
    required this.rightHalf,
    required this.rightHalfCut,
    required this.rightEdge,
    required this.rightEdgeFill,
    required this.leftHalf,
    required this.leftHalfCut,
    required this.leftEdge,
    required this.leftEdgeFill,
    required this.cover,
    required this.innerScrim,
    required this.rightShade,
    required this.leftShade,
    required this.coverScrim,
    required this.coverShade,
    required this.content,
    required this.innerScreen,
    required this.coverScreen,
    required this.innerDeviceStyle,
    required this.coverDeviceStyle,
    required this.runtime,
  });

  /// The stage: `relative`, the open body's box at every angle.
  @override
  final WebElementChrome root;

  /// The open body drawn as it is. Shown while the inner screen is flat;
  /// hidden (and inert in the component) while it is bent.
  final WebElementChrome live;

  /// The open body as the right slab holds it at the angle shown: the whole
  /// body's box, turned. Not displayed while flat.
  final WebElementChrome rightHalf;

  /// What of [rightHalf] is shown: its box again, cut at the hinge.
  ///
  /// The cut is this child's and not the turned element's own. A browser
  /// applies a clip stated on an element it turns in 3D to a picture of that
  /// element taken at one device pixel per px, so on a dense screen the half
  /// would be drawn soft; a clip on a child is drawn into the half's own
  /// picture, at the screen's density.
  final WebElementChrome rightHalfCut;

  /// The right slab's outer edge: the strip the pose places, as wide as the
  /// slab is deep. It draws nothing of its own and clips what it holds.
  final WebElementChrome rightEdge;

  /// What fills [rightEdge]: the edge colour in a box that reaches as far
  /// towards the face as its corners take, rounded where the device's
  /// outline is by the corners of the face behind it
  /// (`CoreMockupFoldEdgeCut`). The strip shows what of it lies inside.
  final WebElementChrome rightEdgeFill;

  /// The open body as the left slab holds it at the angle shown. Not
  /// displayed while flat or once it has turned its back.
  final WebElementChrome leftHalf;

  /// What of [leftHalf] is shown, as [rightHalfCut]: the other side of the
  /// hinge.
  final WebElementChrome leftHalfCut;

  /// The left slab's outer edge, as [rightEdge].
  final WebElementChrome leftEdge;

  /// What fills [leftEdge], as [rightEdgeFill]. Its outline is the inner
  /// face's while the cover faces the viewer, and the cover's otherwise.
  final WebElementChrome leftEdgeFill;

  /// The back of the left slab, where the cover body is drawn. Not displayed
  /// until it faces the viewer.
  final WebElementChrome cover;

  /// The dark laid over the inner screen as it goes off — the same box in
  /// both halves.
  final WebElementChrome innerScrim;

  /// The shade over the right half of the open body.
  final WebElementChrome rightShade;

  /// The shade over the left half of the open body.
  final WebElementChrome leftShade;

  /// The dark laid over the cover screen while it is off.
  final WebElementChrome coverScrim;

  /// The shade over the cover.
  final WebElementChrome coverShade;

  /// What holds the content on a screen. It draws no box
  /// (`display: contents`), so the screen lays the content out as if the
  /// holder were not there; it is there so that a screen which gives the
  /// content up is left with an empty holder rather than another component
  /// in the content's place.
  final WebElementChrome content;

  /// What the inner screen holds, in every rendering of the open body: the
  /// room its content is laid out in and its status island.
  final ResolvedMockupFoldableScreen innerScreen;

  /// What the cover screen holds, as [innerScreen]; its island starts with
  /// the camera.
  final ResolvedMockupFoldableScreen coverScreen;

  /// Nested [CoreMockupDeviceStyle] handed as it is to the `MockupDevice`
  /// that draws the open body, which fills in the rest.
  final CoreMockupDeviceStyle innerDeviceStyle;

  /// Nested [CoreMockupDeviceStyle] handed as it is to the `MockupDevice`
  /// that draws the cover, which fills in the rest.
  final CoreMockupDeviceStyle coverDeviceStyle;

  /// What the component reads besides chrome — the two bodies' widths, which
  /// screen carries the content, what that content is told about the fold,
  /// and how the fold moves. Held in the separate
  /// [ResolvedMockupFoldableRuntime] holder so this chrome bundle carries
  /// only paint-ready element slots.
  final ResolvedMockupFoldableRuntime runtime;
}

/// Paint-ready chrome for what one screen of a `MockupFoldable` holds.
///
/// DOM shape (the child of that screen's `MockupDevice`, the same in every
/// rendering of it):
///
/// ```text
/// root (<div>)                     // the room the content is laid out in:
///   │                              //   the screen, less the island's column
///   ├─ content (<div>)             // box-less; holds the content while this
///   │                              //   screen carries it
///   └─ island (<div>)              // over the whole screen, not in the way of
///        │                         //   a pointer, hidden from assistive tech
///        ├─ camera (<div>)         // cover only: a round hole
///        ├─ clock (<span>)         // the sample time, centred in its line
///        └─ indicator (<div>)      // the status indicator's box
///             ├─ ring (<svg>)      // the ring and the glyph inside it
///             └─ dots (<svg>)      // the four dots that close the ring
/// ```
///
/// The island is the operating system's, like a `MockupDevice`'s status bar,
/// so its parts are that component's item chrome
/// ([ResolvedMockupDeviceStatusItem]): one element each, with what it holds
/// and the parts drawn inside it. Where each stands is
/// `CoreMockupFoldableLayout.islandOf` — the rule the Flutter resolver reads.
class ResolvedMockupFoldableScreen implements WebResolvedChrome {
  /// Creates a [ResolvedMockupFoldableScreen].
  const ResolvedMockupFoldableScreen({
    required this.root,
    this.island,
    this.islandItems = const [],
  });

  /// The room the content is laid out in: as tall as the screen's safe
  /// area, and short of its right edge by the island's column.
  @override
  final WebElementChrome root;

  /// The island's layer, over the whole screen. `null` when nothing of the
  /// island shows on this screen — whether it does is the shared layout's
  /// rule, not a flag the component reads — and then [root] keeps the whole
  /// width.
  final WebElementChrome? island;

  /// The island's parts, top to bottom: the camera, the clock, the status
  /// indicator — the ones that show.
  final List<ResolvedMockupDeviceStatusItem> islandItems;
}

/// Client-side runtime config for `MockupFoldable`. Fed to the component's
/// own build and to the clock that moves the fold — never to an element.
class ResolvedMockupFoldableRuntime {
  /// Creates a [ResolvedMockupFoldableRuntime].
  const ResolvedMockupFoldableRuntime({
    required this.width,
    required this.coverWidth,
    required this.activeScreen,
    required this.isFlat,
    required this.foldLayout,
    required this.islandStyle,
    required this.duration,
    required this.curve,
  });

  /// Width of the open body (logical px) — the `width` its `MockupDevice`
  /// is given.
  final double width;

  /// Width of the cover (logical px) — the `width` its `MockupDevice` is
  /// given.
  final double coverWidth;

  /// The screen that carries the content at the angle shown.
  final CoreMockupFoldScreen activeScreen;

  /// Whether the inner screen lies in one plane, so the open body is drawn
  /// as it is rather than as a copy per half.
  final bool isFlat;

  /// What the content reads from `FoldScope` at the angle shown.
  final CoreFoldLayout foldLayout;

  /// What both islands are drawn from, as one value: the island fields of
  /// the style, settled. Chrome does not compare — an inline style is a new
  /// object every time it is resolved — so this is what the component
  /// compares to tell whether the bodies it built still stand.
  final CoreMockupFoldableStyle islandStyle;

  /// How long a move to a new angle takes, before the reduced-motion
  /// setting is applied.
  final Duration duration;

  /// The easing of that move.
  final CoreCubicBezier curve;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupFoldable] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreMockupFoldableStyle.defaultX)
///   → theme.coreComponentTheme.mockupFoldable.style
///   → widget.mockupFoldableStyle
/// ```
///
/// The semantic [widgetWidth] is a widget prop — it threads through here
/// already resolved (the widget supplies the design-system fallback on the
/// widget edge) and the theme cannot override it. [foldAngle] is the angle
/// shown now: while the device moves it is the angle of the frame being
/// drawn, not the one the caller asked for. [showCamera] and [showStatus]
/// are the caller's flags: what of the status island each screen shows.
///
/// Every derived size comes from [CoreMockupFoldableLayout.compute] and every
/// placement from [CoreMockupFoldPose] — the rules the Flutter resolver
/// reads; this resolver only settles the inputs and writes the outputs.
ResolvedMockupFoldable resolveMockupFoldable(
  BuildContext context, {
  required double widgetWidth,
  required double foldAngle,
  required bool showCamera,
  required bool showStatus,
  CoreMockupFoldableStyle? mockupFoldableStyle,
}) {
  final foldableTheme = context.theme.coreComponentTheme?.mockupFoldable;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreMockupFoldableStyle(), [
    foldableTheme?.style,
    mockupFoldableStyle,
  ]);

  // ─── Stage 1 RESOLVE (Flutter = Web) ──────────────────
  final thickness =
      merged.thickness ?? CoreMockupFoldableStyle.defaultThickness;
  final perspective =
      merged.perspective ?? CoreMockupFoldableStyle.defaultPerspective;
  final shadeOpacity =
      merged.shadeOpacity ?? CoreMockupFoldableStyle.defaultShadeOpacity;
  final duration = merged.duration ?? CoreMockupFoldableStyle.defaultDuration;
  final curve = merged.curve ?? CoreMockupFoldableStyle.defaultCurve;
  final screenOffColor =
      merged.screenOffColor ?? CoreMockupFoldableStyle.defaultScreenOffColor;
  final shadeColor =
      merged.shadeColor ?? CoreMockupFoldableStyle.defaultShadeColor;
  final islandWidth =
      merged.islandWidth ?? CoreMockupFoldableStyle.defaultIslandWidth;
  final islandOffset =
      merged.islandOffset ?? CoreMockupFoldableStyle.defaultIslandOffset;
  final islandCameraSize =
      merged.islandCameraSize ??
      CoreMockupFoldableStyle.defaultIslandCameraSize;
  final islandCameraColor =
      merged.islandCameraColor ??
      CoreMockupFoldableStyle.defaultIslandCameraColor;
  final islandTextStyle = CoreMockupFoldableStyle.defaultIslandTextStyle.merge(
    merged.islandTextStyle,
  );
  final islandIconColor =
      merged.islandIconColor ?? CoreMockupFoldableStyle.defaultIslandIconColor;
  final islandDotColor =
      merged.islandDotColor ?? CoreMockupFoldableStyle.defaultIslandDotColor;
  final innerDeviceStyle = CoreMockupFoldableStyle.defaultInnerDeviceStyle
      .merge(merged.innerDeviceStyle);
  final coverDeviceStyle = CoreMockupFoldableStyle.defaultCoverDeviceStyle
      .merge(merged.coverDeviceStyle);
  final layout = CoreMockupFoldableLayout.compute(
    width: widgetWidth,
    innerDeviceStyle: innerDeviceStyle,
    coverDeviceStyle: coverDeviceStyle,
    thickness: thickness,
    perspective: perspective,
    islandWidth: islandWidth,
    islandOffset: islandOffset,
    islandCameraSize: islandCameraSize,
  );
  final pose = layout.poseAt(foldAngle);
  // The radii the two faces were handed, read back from the styles they are
  // drawn with — the shade follows the body it lies on.
  final innerBorderRadius = layout.innerDeviceStyle.borderRadius;
  final coverBorderRadius = layout.coverDeviceStyle.borderRadius;
  // How each slab's outer edge ends is the shared rule's, read with the
  // corners the two faces are stated with — a corner here is as far across
  // as it is down. It is read only for an edge the pose draws: one turned
  // away has no outline in view to be cut by.
  CoreMockupFoldCorner cornerOf(double? radius) =>
      (x: radius ?? 0, y: radius ?? 0);
  final rightEdgeCut = pose.edgeRight.visible
      ? pose.rightEdgeCut(
          top: cornerOf(innerBorderRadius?.topRight),
          bottom: cornerOf(innerBorderRadius?.bottomRight),
        )
      : null;
  final leftEdgeCut = pose.edgeLeft.visible
      ? pose.leftEdgeCut(
          innerTop: cornerOf(innerBorderRadius?.topLeft),
          innerBottom: cornerOf(innerBorderRadius?.bottomLeft),
          coverTop: cornerOf(coverBorderRadius?.topRight),
          coverBottom: cornerOf(coverBorderRadius?.bottomRight),
        )
      : null;
  // The shade on a part: the share Core gives for how far the part is turned
  // from the viewer, of the strength the style states. It rides the shade's
  // own colour, as how far a screen has gone dark rides the dark's — each is
  // a layer that holds nothing else to dim, and Flutter fades the colour too.
  final rightShadeFill = shadeColor.scaleAlpha(
    pose.innerRight.shade * shadeOpacity,
  );
  final leftShadeFill = shadeColor.scaleAlpha(
    pose.innerLeft.shade * shadeOpacity,
  );
  final coverShadeFill = shadeColor.scaleAlpha(pose.cover.shade * shadeOpacity);
  final innerScrimFill = screenOffColor.scaleAlpha(pose.innerScreenDim);
  final coverScrimFill = screenOffColor.scaleAlpha(pose.coverScreenDim);

  // ─── Stage 2 EMIT (theme-free — class XOR inline) ─────
  final edgeEmit = emitColor(
    merged.edgeColor,
    CoreMockupFoldableStyle.defaultEdgeColor,
    .background,
  );
  final cameraEmit = emitColor(
    merged.islandCameraColor,
    CoreMockupFoldableStyle.defaultIslandCameraColor,
    .background,
  );
  // The indicator's two drawings are filled with `currentColor`, so each
  // colour is a text colour on its `<svg>`.
  final iconEmit = emitColor(
    merged.islandIconColor,
    CoreMockupFoldableStyle.defaultIslandIconColor,
    .text,
  );
  final dotEmit = emitColor(
    merged.islandDotColor,
    CoreMockupFoldableStyle.defaultIslandDotColor,
    .text,
  );

  // ─── Local builders ───────────────────────────────────

  /// Logical px → `rem` (root-font reactive, like every other inline
  /// dimension on this platform).
  String rem(double px) => '${px / kRemDivisor}rem';

  /// A number as short as it reads the same: fixed [digits], trailing zeros
  /// and a bare minus sign dropped.
  String trimmed(double value, int digits) {
    final text = value.toStringAsFixed(digits);
    final short = text.contains('.')
        ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : text;

    return short == '-0' ? '0' : short;
  }

  /// A length inside a transform, in `rem`.
  String span(double px) =>
      '${trimmed(px / kRemDivisor, _kCssLengthDigits)}rem';

  /// An angle inside a transform, in radians.
  String turnOf(double radians) => '${trimmed(radians, _kCssAngleDigits)}rad';

  /// Joins class fragments, dropping the empty ones.
  String joinClasses(Iterable<String> fragments) =>
      fragments.where((c) => c.isNotEmpty).join(' ');

  // The steps every part is placed by, from the stage inwards — the ones
  // `CoreMockupFoldPose` names, written as CSS transform functions. The
  // camera looks at the middle of the open body, so its `perspective()` is
  // wrapped in the move there and back.
  final hingeX = layout.hingeX;
  final centerX = layout.width / 2;
  final centerY = layout.height / 2;
  final placed = <String>[
    'translateX(${span(pose.slide)})',
    'translate(${span(centerX)}, ${span(centerY)})',
    'perspective(${span(pose.distance)})',
    'translate(${span(-centerX)}, ${span(-centerY)})',
    'translateZ(${span(pose.depth)})',
    'translateX(${span(hingeX)})',
    'rotateY(${turnOf(pose.yaw)})',
    'translateX(${span(-hingeX)})',
  ];
  // The left slab's parts are turned about the hinge first.
  final folded = <String>[
    ...placed,
    'translateX(${span(hingeX)})',
    'rotateY(${turnOf(pose.turn)})',
    'translateX(${span(-hingeX)})',
  ];
  // Then each part that is not the screen's own plane is stood in its own:
  // the right slab's outer edge at the body's right, running back; the left
  // slab's at its left, from its back to its screen; and the cover on the
  // back of the left slab, turned over so that it reads the right way round
  // once the slab has folded onto the right half.
  final rightEdgeSteps = <String>[
    ...placed,
    'translateX(${span(layout.width)})',
    'rotateY(90deg)',
  ];
  final leftEdgeSteps = <String>[
    ...folded,
    'translateZ(${span(-layout.thickness)})',
    'rotateY(-90deg)',
  ];
  final coverSteps = <String>[
    ...folded,
    'translate3d(${span(hingeX)}, 0, ${span(-layout.thickness)})',
    'rotateY(180deg)',
  ];

  /// The inline placement of one part: its box at the stage's corner and the
  /// transform that stands it where the pose says.
  Map<String, String> placement(
    List<String> steps, {
    required double width,
    required double height,
  }) => {
    'width': rem(width),
    'height': rem(height),
    'transform-origin': '0 0',
    'transform': steps.join(' '),
  };

  /// One layer laid over a body: a box in the part's own frame, filled with
  /// [fill]. The fill is inline: its alpha is of this angle, and no class
  /// stands for that. It takes no pointer, so what lies under it does.
  WebElementChrome overlay(
    CoreMockupDeviceRect box,
    CoreBorderRadius? borderRadius,
    CoreColor fill,
  ) => WebElementChrome(
    className: joinClasses([WebLayout.absolute, WebLayout.pointerEventsNone]),
    inlineStyles: Styles(
      raw: {
        'left': rem(box.left),
        'top': rem(box.top),
        'width': rem(box.width),
        'height': rem(box.height),
        'border-radius': ?borderRadius?.toValue(),
        'background-color': fill.toValue(),
      },
    ),
  );

  /// One half of the open body as its slab holds it: the whole body's box
  /// under the slab's transform.
  WebElementChrome half(CoreMockupFoldPart part, List<String> steps) =>
      WebElementChrome(
        className: joinClasses([
          _kPart,
          if (pose.isFlat || !part.visible) WebLayout.hidden,
        ]),
        inlineStyles: Styles(
          raw: placement(steps, width: layout.width, height: layout.height),
        ),
      );

  /// What of a half is shown: the half's box, cut at the hinge. The cut is
  /// in the half's own frame, before its transform, so it stays on the hinge
  /// at every angle.
  WebElementChrome halfCut({required bool leftSide}) {
    const reach = _kCssHalfClipReach;
    final lap = hingeX + _kCssHingeOverlap;
    final bottom = layout.height;
    // The right half starts on the hinge. The left half ends on it too,
    // except across the body itself, where it laps over the right half:
    // the body is opaque, so the lap hides both soft edges, while the cast
    // shadow around it is not, and drawn twice it would show as a line.
    final outline = <(double, double)>[
      (-reach, -reach),
      (hingeX, -reach),
      (hingeX, 0),
      (lap, 0),
      (lap, bottom),
      (hingeX, bottom),
      (hingeX, bottom + reach),
      (-reach, bottom + reach),
    ];
    final corners = [for (final (x, y) in outline) '${rem(x)} ${rem(y)}'];
    final outward = rem(-reach);
    final cut = leftSide
        ? 'polygon(${corners.join(', ')})'
        // inset(top right bottom left), each measured in from its own side.
        : 'inset($outward $outward $outward ${rem(hingeX)})';

    return WebElementChrome(
      className: WebLayout.absoluteFull,
      inlineStyles: Styles(raw: {'clip-path': cut}),
    );
  }

  /// A slab's outer edge: a strip as wide as the slab is deep, which shows
  /// what of its fill lies inside it.
  WebElementChrome edge(CoreMockupFoldPart part, List<String> steps) =>
      WebElementChrome(
        className: joinClasses([
          _kPart,
          WebLayout.overflowHidden,
          if (!part.visible) WebLayout.hidden,
        ]),
        inlineStyles: Styles(
          raw: placement(
            steps,
            width: layout.thickness,
            height: layout.height,
          ),
        ),
      );

  /// One end of an edge's outline side, as CSS reads an elliptical corner:
  /// how far it reaches across the strip, and how far down. `null` where the
  /// end is square.
  ///
  /// Down is the face's own corner, written as the reference the face itself
  /// is drawn with, and across is that reference times how many of it the
  /// pose draws the corner across. So a surface style or a density that
  /// re-points the radius scale — which no rebuild follows — moves the cut
  /// with the corner it is the cut of, and squares it where it squares the
  /// corner.
  ({String across, String down})? edgeEnd(CoreMockupFoldCorner end) {
    if (end.x <= 0 || end.y <= 0) return null;
    final down = radiusCss(end.y);

    return (
      across: 'calc($down * ${trimmed(end.x / end.y, _kCssRatioDigits)})',
      down: down,
    );
  }

  /// What fills a slab's edge: the edge colour in the strip's box widened to
  /// its widest corner, away from the side the device's outline is on, and
  /// rounded on that side by those corners. With no [cut] — the edge is not
  /// drawn — it is the strip's own box.
  WebElementChrome edgeFill(CoreMockupFoldEdgeCut? cut) {
    final outlineAtEnd = cut?.outlineAtEnd ?? false;
    final top = cut == null ? null : edgeEnd(cut.top);
    final bottom = cut == null ? null : edgeEnd(cut.bottom);
    final strip = rem(layout.thickness);
    // A corner wider than its box is shrunk by the browser, both ways at
    // once; the box is made as wide as the corner instead.
    final reaches = {strip, ?top?.across, ?bottom?.across};
    final side = outlineAtEnd ? 'right' : 'left';

    return WebElementChrome(
      className: joinClasses([
        _kEdgeFill,
        if (outlineAtEnd) WebLayout.rightZero else WebLayout.leftZero,
        edgeEmit.className,
      ]),
      inlineStyles: Styles(
        raw: {
          'width': reaches.length == 1 ? strip : 'max(${reaches.join(', ')})',
          if (top != null)
            'border-top-$side-radius': '${top.across} ${top.down}',
          if (bottom != null)
            'border-bottom-$side-radius': '${bottom.across} ${bottom.down}',
          ...?edgeEmit.inline,
        },
      ),
    );
  }

  /// The four inline offsets of a box laid in a screen.
  Map<String, String> boxStyles(CoreMockupDeviceRect box) => {
    'left': rem(box.left),
    'top': rem(box.top),
    'width': rem(box.width),
    'height': rem(box.height),
  };

  /// One of the status indicator's drawings: the glyph's own box as the
  /// `viewBox`, stretched over the indicator's, in [colour].
  ResolvedMockupDeviceStatusItem drawing(CoreVectorGlyph glyph, Emit colour) =>
      ResolvedMockupDeviceStatusItem(
        root: WebElementChrome(
          className: joinClasses([
            WebLayout.absoluteFull,
            WebLayout.hFull,
            WebLayout.wFull,
            colour.className,
          ]),
          inlineStyles: switch (colour.inline) {
            null => null,
            final inline => Styles(raw: inline),
          },
        ),
        content: .glyph(
          path: glyph.path,
          viewBox: '0 0 ${glyph.width} ${glyph.height}',
          fillRule: switch (glyph.fillRule) {
            .evenOdd => 'evenodd',
            .nonZero => 'nonzero',
          },
        ),
      );

  /// What one screen holds: the room its content is laid out in, and its
  /// status island. Where the island's parts stand is the shared layout's
  /// (`CoreMockupFoldableLayout.islandOf`); this only writes them out.
  ResolvedMockupFoldableScreen screenOf(CoreMockupFoldScreen screen) {
    final island = layout.islandOf(
      screen,
      showCamera: showCamera,
      showStatus: showStatus,
    );
    // The screen's whole safe area, whatever it holds: the content reads a
    // height from it as it did from the screen itself.
    if (island == null) {
      return const ResolvedMockupFoldableScreen(
        root: WebElementChrome(className: WebLayout.hFull),
      );
    }
    final camera = island.camera;
    final clock = island.clock;
    final indicator = island.indicator;
    // The clock is the role's own text at the scale the screen draws its
    // system lengths at, as a `MockupDevice`'s status text is.
    final clockEmit = emitScaledTypography(
      merged.islandTextStyle,
      CoreMockupFoldableStyle.defaultIslandTextStyle,
      factor: island.scale,
    );

    return ResolvedMockupFoldableScreen(
      root: WebElementChrome(
        className: WebLayout.hFull,
        inlineStyles: Styles(
          raw: {
            'box-sizing': 'border-box',
            // The island's column, kept clear — pinned: it is the picture's
            // geometry, like the device's own safe area, not spacing.
            'padding-right': pinnedLengthCss(island.column.width),
          },
        ),
      ),
      // Over the whole screen, so every part is placed in the screen's own
      // frame. A picture of an operating system: it takes no pointer.
      island: WebElementChrome(
        className: joinClasses([
          WebLayout.absoluteFull,
          WebLayout.pointerEventsNone,
        ]),
      ),
      islandItems: [
        if (camera != null)
          ResolvedMockupDeviceStatusItem(
            root: WebElementChrome(
              className: joinClasses([
                WebLayout.absolute,
                cameraEmit.className,
              ]),
              inlineStyles: Styles(
                raw: {
                  ...boxStyles(camera),
                  // Half the box: a circle. Derived, never stated.
                  'border-radius': rem(camera.width / 2),
                  ...?cameraEmit.inline,
                },
              ),
            ),
            content: const .none(),
          ),
        if (clock != null)
          ResolvedMockupDeviceStatusItem(
            root: WebElementChrome(
              // One line, centred in its box and never cut: words wider
              // than the column run over both sides alike.
              className: joinClasses([
                WebLayout.absolute,
                WebLayout.flexCenter,
                WebLayout.whitespaceNowrap,
                clockEmit.className,
              ]),
              inlineStyles: Styles(
                raw: {...boxStyles(clock), ...?clockEmit.inline},
              ),
            ),
            content: const .text(CoreMockupFoldableStyle.sampleTime),
          ),
        if (indicator != null)
          ResolvedMockupDeviceStatusItem(
            root: WebElementChrome(
              className: WebLayout.absolute,
              inlineStyles: Styles(raw: boxStyles(indicator)),
            ),
            content: const .none(),
            // Two drawings in one box, one over the other: each is one
            // colour.
            parts: [
              drawing(CoreMockupFoldableStyle.islandRingGlyph, iconEmit),
              drawing(CoreMockupFoldableStyle.islandDotsGlyph, dotEmit),
            ],
          ),
      ],
    );
  }

  final bodyBox = (
    left: 0.0,
    top: 0.0,
    width: layout.width,
    height: layout.height,
  );
  final coverBox = (
    left: 0.0,
    top: 0.0,
    width: layout.coverWidth,
    height: layout.height,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  final root = WebElementChrome(
    className: joinClasses([WebLayout.relative, WebLayout.inlineFlex]),
    inlineStyles: Styles(
      raw: {'width': rem(layout.width), 'height': rem(layout.height)},
    ),
  );
  final live = WebElementChrome(
    className: joinClasses([
      _kPart,
      // Hidden, not removed: the content it holds keeps its state.
      if (!pose.isFlat) _kUnseen,
    ]),
  );
  final rightHalf = half(pose.innerRight, placed);
  final rightHalfCut = halfCut(leftSide: false);
  final rightEdge = edge(pose.edgeRight, rightEdgeSteps);
  final rightEdgeFill = edgeFill(rightEdgeCut);
  final leftHalf = half(pose.innerLeft, folded);
  final leftHalfCut = halfCut(leftSide: true);
  final leftEdge = edge(pose.edgeLeft, leftEdgeSteps);
  final leftEdgeFill = edgeFill(leftEdgeCut);
  final cover = WebElementChrome(
    className: joinClasses([
      _kPart,
      if (!pose.cover.visible) WebLayout.hidden,
    ]),
    inlineStyles: Styles(
      raw: placement(
        coverSteps,
        width: layout.coverWidth,
        height: layout.height,
      ),
    ),
  );
  final innerScrim = overlay(
    layout.innerScreen,
    layout.innerScreenBorderRadius,
    innerScrimFill,
  );
  final rightShade = overlay(bodyBox, innerBorderRadius, rightShadeFill);
  final leftShade = overlay(bodyBox, innerBorderRadius, leftShadeFill);
  final coverScrim = overlay(
    layout.coverScreen,
    layout.coverScreenBorderRadius,
    coverScrimFill,
  );
  final coverShade = overlay(coverBox, coverBorderRadius, coverShadeFill);
  const content = WebElementChrome(className: WebLayout.contents);
  final innerScreen = screenOf(CoreMockupFoldScreen.inner);
  final coverScreen = screenOf(CoreMockupFoldScreen.cover);
  final runtime = ResolvedMockupFoldableRuntime(
    width: layout.width,
    coverWidth: layout.coverWidth,
    activeScreen: pose.activeScreen,
    isFlat: pose.isFlat,
    foldLayout: layout.foldLayoutAt(foldAngle),
    islandStyle: CoreMockupFoldableStyle(
      islandWidth: islandWidth,
      islandOffset: islandOffset,
      islandCameraSize: islandCameraSize,
      islandCameraColor: islandCameraColor,
      islandTextStyle: islandTextStyle,
      islandIconColor: islandIconColor,
      islandDotColor: islandDotColor,
    ),
    duration: duration,
    curve: curve,
  );

  return ResolvedMockupFoldable(
    root: root,
    live: live,
    rightHalf: rightHalf,
    rightHalfCut: rightHalfCut,
    rightEdge: rightEdge,
    rightEdgeFill: rightEdgeFill,
    leftHalf: leftHalf,
    leftHalfCut: leftHalfCut,
    leftEdge: leftEdge,
    leftEdgeFill: leftEdgeFill,
    cover: cover,
    innerScrim: innerScrim,
    rightShade: rightShade,
    leftShade: leftShade,
    coverScrim: coverScrim,
    coverShade: coverShade,
    content: content,
    innerScreen: innerScreen,
    coverScreen: coverScreen,
    innerDeviceStyle: layout.innerDeviceStyle,
    coverDeviceStyle: layout.coverDeviceStyle,
    runtime: runtime,
  );
}
