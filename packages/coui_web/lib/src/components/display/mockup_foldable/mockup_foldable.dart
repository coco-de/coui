import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/display/mockup_device/mockup_device.dart';
import 'package:coui_web/src/components/display/mockup_device/mockup_device_style.dart';
import 'package:coui_web/src/components/display/mockup_foldable/mockup_foldable_motion.dart';
import 'package:coui_web/src/components/display/mockup_foldable/mockup_foldable_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform folding-device mockup for CoUI Web.
///
/// A device that folds down its middle, around the caller's screen content.
/// Open, the content is on the inner screen, which spans both halves; shut,
/// it is on the cover screen on the back of the half that folds over. How far
/// the device is folded is the one value [foldAngle], and what is drawn at it
/// — which screen is lit, where each half stands, what the content reads from
/// `FoldScope` — follows from the rules in `CoreMockupFold`, the ones the
/// Flutter twin reads. Uses [CoreMockupFoldableContract] from `coui_core` for
/// a consistent cross-platform API.
///
/// It draws no body of its own: both faces are [MockupDevice]s, styled
/// through the nested slots of the single [mockupFoldableStyle]. What it adds
/// to them is the status island — where a slab phone has a status bar across
/// the top of its screen, this device keeps a column at the screen's right
/// edge: the cover's camera at its top ([showCamera]), the clock and the
/// status indicator under it ([showStatus]). The content is laid out clear of
/// that column. The layout knob ([width]) stays flat on the widget, and the
/// component keeps that box at every angle.
///
/// A change of [foldAngle] moves the device to the new angle over the
/// style's `duration`, from wherever it is. The move is stepped frame by
/// frame in the browser. It is a jump when the duration is zero, when the
/// reader asked for reduced motion (which makes a jump of any transition,
/// the default duration among them), and on the server, which draws the
/// angle it was given. A caller that steps the angle itself — a slider —
/// states a zero duration, or the device trails every step.
///
/// While the inner screen is bent — at any angle short of flat — its two
/// halves stand in different planes, and one element cannot be drawn in two.
/// Each half is then a second rendering of the open body with [child] built
/// again, taken out of focus, pointer and assistive technology, while the
/// first stays mounted and hidden so what it holds keeps its state. A copy
/// is a build of its own: it shows what [child] is given, not what a
/// stateful [child] has come to hold since.
///
/// Example:
/// ```dart
/// MockupFoldable(
///   foldAngle: CoreMockupFold.halfOpen,
///   child: div([img(src: '/images/wallpaper.jpg')]),
/// )
/// ```
class MockupFoldable extends UiStatefulComponent
    implements CoreMockupFoldableContract<Component> {
  /// Creates a [MockupFoldable].
  const MockupFoldable({
    required this.child,
    this.foldAngle = CoreMockupFoldableContract.defaultFoldAngle,
    this.width,
    this.showCamera = CoreMockupFoldableContract.defaultShowCamera,
    this.showStatus = CoreMockupFoldableContract.defaultShowStatus,
    this.showGestureBar = CoreMockupFoldableContract.defaultShowGestureBar,
    this.screenBrightness,
    this.mockupFoldableStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    super.key,
  });

  @override
  final Component child;

  @override
  final double foldAngle;

  @override
  final double? width;

  @override
  final bool showCamera;

  @override
  final bool showStatus;

  @override
  final bool showGestureBar;

  @override
  final CoreBrightness? screenBrightness;

  @override
  final CoreMockupFoldableStyle? mockupFoldableStyle;

  /// Returns a copy of this [MockupFoldable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MockupFoldable copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? child,
    double? foldAngle,
    double? width,
    bool? showCamera,
    bool? showStatus,
    bool? showGestureBar,
    CoreBrightness? screenBrightness,
    CoreMockupFoldableStyle? mockupFoldableStyle,
  }) {
    return MockupFoldable(
      key: key ?? this.key,
      foldAngle: foldAngle ?? this.foldAngle,
      width: width ?? this.width,
      showCamera: showCamera ?? this.showCamera,
      showStatus: showStatus ?? this.showStatus,
      showGestureBar: showGestureBar ?? this.showGestureBar,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      mockupFoldableStyle: mockupFoldableStyle ?? this.mockupFoldableStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  State<MockupFoldable> createState() => _MockupFoldableState();
}

/// What a face is built from. While none of it changes — every frame of a
/// move, bar the ones that cross a rule — the faces are the same components
/// as the frame before, and a frame only rewrites the styles around them.
typedef _FaceInputs = ({
  Component child,
  bool showCamera,
  bool showStatus,
  bool showGestureBar,
  CoreMockupFoldableStyle islandStyle,
  CoreBrightness? screenBrightness,
  CoreMockupDeviceStyle innerDeviceStyle,
  CoreMockupDeviceStyle coverDeviceStyle,
  double width,
  double coverWidth,
  CoreMockupFoldScreen activeScreen,
  CoreFoldLayout foldLayout,
  CoreTextDirection direction,
  WebElementChrome holder,
});

/// The three bodies: the open body that holds the content while the inner
/// screen carries it, the open body drawn again for a half, and the cover.
typedef _Faces = ({Component live, Component copy, Component cover});

class _MockupFoldableState extends State<MockupFoldable> {
  /// Keeps the content one subtree as it moves between the inner screen and
  /// the cover, so what it holds is not built anew when the screen changes.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'MockupFoldable content');

  late final MockupFoldMotion _motion;
  _FaceInputs? _faceInputs;
  _Faces? _faces;

  @override
  void initState() {
    super.initState();
    _motion = MockupFoldMotion(
      angle: component.foldAngle,
      now: mockupFoldClock,
      requestFrame: requestMockupFoldFrame,
      onFrame: _handleFrame,
    );
  }

  @override
  void didUpdateComponent(MockupFoldable oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Rebuilt for something other than the angle: a move under way goes on.
    if (CoreMockupFold.clampAngle(component.foldAngle) == _motion.target) {
      return;
    }
    final runtime = _resolve(context).runtime;
    _motion.moveTo(
      component.foldAngle,
      // A host without frames would never arrive, so it does not set out.
      // The fold is a transition, so reduced motion makes it a jump.
      duration: kMockupFoldHasFrames
          ? CoreReducedMotion.resolve(
              runtime.duration,
              reduce: prefersReducedMotion,
            )
          : Duration.zero,
      curve: runtime.curve,
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  /// The move came to a frame: draw the angle it is at.
  void _handleFrame() {
    if (!mounted) return;
    setState(() {});
  }

  ResolvedMockupFoldable _resolve(BuildContext context) =>
      resolveMockupFoldable(
        context,
        // Semantic layout knob — the widget supplies the design-system
        // `CoreMockupFoldableStyle.defaultWidth` fallback so the resolver
        // consumes an already resolved value (the theme cannot override
        // `width`). Single source of truth shared with the Flutter resolver.
        widgetWidth: component.width ?? CoreMockupFoldableStyle.defaultWidth,
        foldAngle: _motion.angle,
        showCamera: component.showCamera,
        showStatus: component.showStatus,
        mockupFoldableStyle: component.mockupFoldableStyle,
      );

  /// The faces for [inputs]: the ones of the frame before while nothing they
  /// are built from has changed. [inner] and [cover] are what the two screens
  /// hold, drawn from those same inputs — read only when the faces are built
  /// anew.
  _Faces _facesFor(
    _FaceInputs inputs, {
    required ResolvedMockupFoldableScreen inner,
    required ResolvedMockupFoldableScreen cover,
  }) {
    final kept = _faces;
    if (kept != null && _faceInputs == inputs) return kept;
    final onInner = inputs.activeScreen == CoreMockupFoldScreen.inner;

    /// [content] told what the screen it is on reads of the fold.
    Component onScreen(Component content, {Key? key}) => FoldLayoutScope(
      key: key,
      layout: inputs.foldLayout,
      direction: inputs.direction,
      child: content,
    );

    /// One of the two bodies around [content]: which device it is and how
    /// it is held is the shared layout's statement
    /// (`CoreMockupFoldableLayout`), the one the Flutter twin reads.
    ///
    /// Neither draws a camera or a status bar of its own: what this device
    /// shows of them is its island, which stands on the screen with the
    /// content.
    Component body(
      Component content, {
      required CoreMockupDevice device,
      required CoreMockupOrientation orientation,
      required double width,
      required CoreMockupDeviceStyle deviceStyle,
    }) => MockupDevice(
      device: device,
      orientation: orientation,
      width: width,
      showCamera: false,
      showStatusBar: false,
      showGestureBar: inputs.showGestureBar,
      screenBrightness: inputs.screenBrightness,
      mockupDeviceStyle: deviceStyle,
      child: content,
    );

    /// The open body around [content].
    Component innerBody(Component content) => body(
      content,
      device: CoreMockupFoldableLayout.innerDevice,
      orientation: CoreMockupFoldableLayout.innerOrientation,
      width: inputs.width,
      deviceStyle: inputs.innerDeviceStyle,
    );

    /// What a screen holds: [content], or nothing.
    ///
    /// A screen that gives the content up keeps an empty holder — the device
    /// never puts another component where the content was. The content is
    /// one subtree moved between screens by a `GlobalKey`, and once Jaspr has
    /// moved a subtree it goes on treating it as updatable by any component:
    /// replaced in place it is handed a component of another type, removed
    /// from a list it is let go of as it should be.
    Component held(Component? content) => div(
      [?content],
      classes: inputs.holder.className,
      styles: inputs.holder.inlineStyles,
    );

    /// What a screen holds: [content] — or nothing — in the room the island
    /// leaves it, and the island over it. A screen keeps its island whether
    /// or not it carries the content.
    Component onto(ResolvedMockupFoldableScreen screen, Component? content) =>
        div(
          [
            held(content),
            if (screen.island case final island?)
              div(
                [for (final item in screen.islandItems) _islandItem(item)],
                classes: island.className,
                styles: island.inlineStyles,
                // A picture of an operating system, not content.
                attributes: _kPicture,
              ),
          ],
          classes: screen.root.className,
          styles: screen.root.inlineStyles,
        );

    // One subtree, on whichever screen carries it.
    final content = onScreen(inputs.child, key: _contentKey);
    final faces = (
      live: innerBody(onto(inner, onInner ? content : null)),
      // The same content built again, not moved: it carries no key.
      copy: innerBody(onto(inner, onInner ? onScreen(inputs.child) : null)),
      cover: body(
        onto(cover, onInner ? null : content),
        device: CoreMockupFoldableLayout.coverDevice,
        orientation: CoreMockupFoldableLayout.coverOrientation,
        width: inputs.coverWidth,
        deviceStyle: inputs.coverDeviceStyle,
      ),
    );
    _faceInputs = inputs;
    _faces = faces;

    return faces;
  }

  @override
  Component build(BuildContext context) {
    final resolved = _resolve(context);
    final runtime = resolved.runtime;
    final faces = _facesFor(
      (
        child: component.child,
        showCamera: component.showCamera,
        showStatus: component.showStatus,
        showGestureBar: component.showGestureBar,
        islandStyle: runtime.islandStyle,
        screenBrightness: component.screenBrightness,
        innerDeviceStyle: resolved.innerDeviceStyle,
        coverDeviceStyle: resolved.coverDeviceStyle,
        width: runtime.width,
        coverWidth: runtime.coverWidth,
        activeScreen: runtime.activeScreen,
        foldLayout: runtime.foldLayout,
        // The content keeps reading in the direction the page reads in.
        direction:
            context
                .dependOnInheritedComponentOfExactType<FoldLayoutScope>()
                ?.direction ??
            CoreTextDirection.ltr,
        holder: resolved.content,
      ),
      inner: resolved.innerScreen,
      cover: resolved.coverScreen,
    );
    final bent = !runtime.isFlat;

    /// A half of the inner screen: the turned box, and in it the box that
    /// cuts it at the hinge. While the screen is bent the cut holds the open
    /// body drawn again, the dark of a screen going off, and the shade of a
    /// half turned from the viewer; while flat it holds nothing — the open
    /// body is drawn as it is.
    Component half(
      WebElementChrome turned,
      WebElementChrome cut,
      WebElementChrome shade,
    ) => div(
      [
        div(
          bent
              ? [faces.copy, _part(resolved.innerScrim), _part(shade)]
              : const [],
          classes: cut.className,
          styles: cut.inlineStyles,
        ),
      ],
      classes: turned.className,
      styles: turned.inlineStyles,
      attributes: _kCopy,
    );

    return div(
      [
        // Back to front: every part is absolute in the root, so DOM order is
        // paint order. That order holds at every angle — the only parts that
        // ever overlap are the cover and what lies under it.
        div(
          [faces.live],
          classes: resolved.live.className,
          styles: resolved.live.inlineStyles,
          // Hidden but mounted while bent: out of focus and out of reach.
          attributes: bent ? _kInert : null,
        ),
        half(resolved.rightHalf, resolved.rightHalfCut, resolved.rightShade),
        _edge(resolved.rightEdge, resolved.rightEdgeFill),
        half(resolved.leftHalf, resolved.leftHalfCut, resolved.leftShade),
        _edge(resolved.leftEdge, resolved.leftEdgeFill),
        div(
          [faces.cover, _part(resolved.coverScrim), _part(resolved.coverShade)],
          classes: resolved.cover.className,
          styles: resolved.cover.inlineStyles,
        ),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }

  /// One flat part — an empty `<div>` wearing its slot chrome.
  static Component _part(WebElementChrome chrome) =>
      div(const [], classes: chrome.className, styles: chrome.inlineStyles);

  /// A slab's outer edge: its strip, and in it the fill the strip cuts.
  static Component _edge(WebElementChrome strip, WebElementChrome fill) => div(
    [_part(fill)],
    classes: strip.className,
    styles: strip.inlineStyles,
  );

  /// One part of the island: its text, its drawing, or the box its parts
  /// draw in — the three things a `MockupDevice` status bar item is, and
  /// drawn as that component draws them.
  static Component _islandItem(ResolvedMockupDeviceStatusItem item) {
    final content = item.content;
    final text = content.text;
    if (text != null) {
      return Component.element(
        tag: 'span',
        classes: item.root.className,
        styles: item.root.inlineStyles,
        // The span carries the role's typography and colour; `Text` sets
        // neither of its own, so it inherits them.
        children: [Text(text)],
      );
    }
    if (content.path case final path?) {
      return Component.element(
        tag: 'svg',
        classes: item.root.className,
        styles: item.root.inlineStyles,
        attributes: {'viewBox': content.viewBox!, ..._kPicture},
        children: [
          Component.element(
            tag: 'path',
            attributes: {
              'd': path,
              'fill': 'currentColor',
              'fill-rule': content.fillRule!,
            },
          ),
        ],
      );
    }

    return div(
      [for (final part in item.parts) _islandItem(part)],
      classes: item.root.className,
      styles: item.root.inlineStyles,
    );
  }
}

/// What takes a subtree out of focus, pointer and the accessibility tree.
const Map<String, String> _kInert = {'inert': ''};

/// A half holds a second rendering of what the hidden open body already
/// holds: a picture, to nobody's hand and read to nobody twice.
const Map<String, String> _kCopy = {'inert': '', 'aria-hidden': 'true'};

/// What keeps a drawing of the device's own from assistive technology: the
/// island is a picture of an operating system, as a `MockupDevice`'s status
/// bar is.
const Map<String, String> _kPicture = {'aria-hidden': 'true'};

/// Chain sugar mirroring the Flutter `MockupFoldable.withStyle` extension —
/// merges a [CoreMockupFoldableStyle] patch into
/// [MockupFoldable.mockupFoldableStyle] via the existing
/// [MockupFoldable.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMockupFoldableStyle.merge` right-side-wins semantics).
extension MockupFoldableStyleChain on MockupFoldable {
  /// Returns a copy of this [MockupFoldable] with [patch] merged into
  /// [mockupFoldableStyle] (patch fields win on conflict).
  MockupFoldable withStyle(CoreMockupFoldableStyle patch) => copyWith(
    mockupFoldableStyle:
        (mockupFoldableStyle ?? const CoreMockupFoldableStyle()).merge(patch),
  );
}
