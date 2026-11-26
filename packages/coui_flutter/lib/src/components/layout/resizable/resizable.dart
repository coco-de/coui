import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

/// Quarter turn (90°) used to orient the drag dots along a vertical divider.
const _kHandleQuarterTurn = math.pi / 2;

/// Ratio → percent conversion factor. Not a design token — pure math for
/// the numbers a screen reader announces for a focused divider, in the
/// same percent-of-container convention as the Web twin. The percentage
/// reaches the user two ways: as the spoken sentence in `value` /
/// `increasedValue` / `decreasedValue` (Web: `aria-valuetext`), and as the
/// bare numeric bounds in `minValue` / `maxValue` (Web: `aria-valuemin` /
/// `aria-valuemax`).
const _kRatioToPercent = 100;

/// Unified resizable component.
///
/// Displays multiple panes with draggable dividers.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [resizableStyle] slot. Behavioural fields (`panes`,
/// `direction`, `onResize`, `showDragHandle`) stay flat on the widget.
///
/// Layout: panes fill the container with no reserved divider gutter — the
/// thin divider line and (when [showDragHandle]) the grab handle are drawn
/// as `Stack` overlays positioned over the pane boundary. This keeps the
/// content area maximal (only the hairline line sits over the seam) while
/// the grab handle floats above the content for comfortable touch dragging
/// without stealing layout width.
///
/// Example:
/// ```dart
/// Resizable(
///   direction: CoreResizableDirection.horizontal,
///   panes: [
///     CoreResizablePaneData(
///       content: Container(color: Colors.red),
///       initialSize: 0.3,
///     ),
///     CoreResizablePaneData(
///       content: Container(color: Colors.blue),
///       initialSize: 0.7,
///     ),
///   ],
/// )
/// ```
class Resizable extends StatefulWidget
    implements CoreResizableContract<Widget> {
  /// Creates a [Resizable].
  const Resizable({
    required this.panes,
    this.direction = CoreResizableDirection.horizontal,
    this.onResize,
    this.showDragHandle = CoreResizableContract.defaultShowDragHandle,
    this.optionalDivider = CoreResizableContract.defaultOptionalDivider,
    this.resizableStyle,
    super.key,
  });

  @override
  final List<CoreResizablePaneData<Widget>> panes;

  @override
  final CoreResizableDirection direction;

  @override
  final void Function(List<double> sizes)? onResize;

  /// Whether to render a larger, centered grab handle floating over the
  /// divider.
  ///
  /// The thin divider line is hard to grab on touch platforms (iOS /
  /// Android). When `true`, a pill-shaped grab handle with drag dots is
  /// drawn as an overlay centered on the seam — it floats above the
  /// content ([CoreResizableStyle] `handleHitExtent` wide hit area) without
  /// consuming layout width, so the panes keep their full size. Defaults to
  /// `false` (the plain thin divider whose own hit area carries the drag on
  /// pointer platforms).
  @override
  final bool showDragHandle;

  /// Whether the divider stays invisible until hovered, focused or dragged.
  ///
  /// The hit area is unchanged while hidden, so the seam is still grabbable.
  @override
  final bool optionalDivider;

  @override
  final CoreResizableStyle? resizableStyle;

  /// Returns a copy of this [Resizable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Resizable copyWith({
    Key? key,
    List<CoreResizablePaneData<Widget>>? panes,
    CoreResizableDirection? direction,
    void Function(List<double> sizes)? onResize,
    bool? showDragHandle,
    bool? optionalDivider,
    CoreResizableStyle? resizableStyle,
  }) {
    return Resizable(
      key: key ?? this.key,
      panes: panes ?? this.panes,
      direction: direction ?? this.direction,
      onResize: onResize ?? this.onResize,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      optionalDivider: optionalDivider ?? this.optionalDivider,
      resizableStyle: resizableStyle ?? this.resizableStyle,
    );
  }

  @override
  State<Resizable> createState() => _ResizableState();
}

class _ResizableState extends State<Resizable> {
  /// Pane sizes and the bounds they satisfy, resolved from
  /// [Resizable.panes] rather than copied out of it — the declared ratios
  /// are intent, and the invariants that make an announced position land
  /// inside its announced range only hold after
  /// [CoreResizableLayout.resolve] has fitted them. Shared with the Web
  /// twin so a fix here cannot land on one platform only.
  late CoreResizableLayout _layout;

  /// One [FocusNode] per divider (`panes.length - 1`) — the keyboard
  /// entry point WCAG 2.1.1 requires. Whichever overlay currently owns
  /// the pointer drag for a divider (the line when [Resizable.
  /// showDragHandle] is `false`, the pill handle when it is `true`) also
  /// owns this node, via [_buildInteractiveDivider].
  late List<FocusNode> _dividerFocusNodes;

  /// Index of the divider currently hovered, if any.
  int? _hoveredDivider;

  /// Index of the divider currently keyboard-focused, if any. Tracked
  /// separately from [_hoveredDivider] — merging them into one "active"
  /// flag would let a mouse leaving the divider clear a highlight that
  /// keyboard focus still owns.
  int? _focusedDivider;

  /// Index of the divider currently being dragged, if any.
  ///
  /// A third state rather than a reuse of [_hoveredDivider], because a
  /// drag outlives hover in two ordinary ways: the divider pins at its
  /// bound while the pointer keeps travelling, and a touch pointer never
  /// hovers at all. Riding hover alone makes the thing under the user's
  /// finger disappear mid-gesture — which is what `optionalDivider`
  /// shipped doing.
  int? _draggingDivider;

  @override
  void initState() {
    super.initState();
    _layout = CoreResizableLayout.resolve(widget.panes);
    // Grown from empty by the same path that grows it later, so every
    // divider focus node in this widget's life is created in one place and
    // released in one place.
    _dividerFocusNodes = const [];
    _syncDividerFocusNodes();
  }

  @override
  void didUpdateWidget(covariant Resizable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (CoreResizableLayout.declaresSameGeometry(
      oldWidget.panes,
      widget.panes,
    )) {
      return;
    }
    // A pane list that declares different ratios or bounds is a different
    // layout, and the sizes resolved against the old one no longer satisfy
    // it — leaving them is how the announced range goes back to excluding
    // the announced position after the first frame.
    _layout = CoreResizableLayout.resolve(widget.panes);
    _syncDividerFocusNodes();
  }

  @override
  void dispose() {
    for (final node in _dividerFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Number of dividers — one per seam between panes.
  int get _dividerCount =>
      widget.panes.length > 1 ? widget.panes.length - 1 : 0;

  /// Grows or shrinks the per-divider focus nodes to match the current pane
  /// count, disposing the ones that no longer have a seam.
  ///
  /// A pane list that gains a pane gains a divider, and indexing the old
  /// list for it throws — so a component that renders a variable number of
  /// panes has no keyboard path at all past the first change without this.
  void _syncDividerFocusNodes() {
    final needed = _dividerCount;
    if (needed == _dividerFocusNodes.length) return;

    if (needed < _dividerFocusNodes.length) {
      for (final node in _dividerFocusNodes.skip(needed)) {
        node.dispose();
      }
      _dividerFocusNodes = _dividerFocusNodes.take(needed).toList();
    } else {
      _dividerFocusNodes = [
        ..._dividerFocusNodes,
        for (int i = _dividerFocusNodes.length; i < needed; i++)
          FocusNode(debugLabel: 'ResizableDivider'),
      ];
    }

    // Highlight state is an index into the list that just changed length.
    final focused = _focusedDivider;
    if (focused != null && focused >= needed) _focusedDivider = null;
    final hovered = _hoveredDivider;
    if (hovered != null && hovered >= needed) _hoveredDivider = null;
    final dragging = _draggingDivider;
    if (dragging != null && dragging >= needed) _draggingDivider = null;
  }

  void _handleHoverChanged(int dividerIndex, {required bool hovered}) {
    setState(() => _hoveredDivider = hovered ? dividerIndex : null);
  }

  void _handleDragStart(int dividerIndex) {
    setState(() => _draggingDivider = dividerIndex);
  }

  void _handleDragStop() {
    if (_draggingDivider == null) return;
    setState(() => _draggingDivider = null);
  }

  void _handleFocusHighlightChanged(
    int dividerIndex, {
    required bool focused,
  }) {
    setState(() => _focusedDivider = focused ? dividerIndex : null);
  }

  /// Applies a flex-ratio delta to the pane pair straddling [dividerIndex],
  /// clamped to that divider's reachable range. Shared by pointer drag
  /// ([_handleDrag], which first converts a pixel delta to this same
  /// dimensionless ratio) and keyboard resize ([_handleKeyboardResize],
  /// which already deals in ratios).
  ///
  /// The range and the clamp both come from [CoreResizableLayout], so the
  /// bounds a drag enforces are the same object a screen reader reads out —
  /// and a step that would overshoot pins the divider at its bound instead
  /// of being dropped, which is what a drag past the limit should do.
  void _applyDeltaRatio(int dividerIndex, double deltaRatio) {
    final moved = _layout.moveDivider(dividerIndex, deltaRatio);
    if (moved == null) return;

    setState(() => _layout = moved);
    widget.onResize?.call(List.of(_layout.sizes));
  }

  void _handleDrag(int dividerIndex, double deltaPx, double containerSize) {
    if (containerSize <= 0) return;
    // Convert pixel delta to flex ratio delta.
    // Unit: px / px = ratio (dimensionless).
    final deltaRatio = deltaPx / containerSize;
    _applyDeltaRatio(dividerIndex, deltaRatio);
  }

  /// WCAG 2.1.1 keyboard path — arrow-key resize by one
  /// `CoreResizableContract.defaultKeyboardStepFraction` per press,
  /// reusing the same ratio-delta application as pointer drag.
  void _handleKeyboardResize(int dividerIndex, double deltaRatio) =>
      _applyDeltaRatio(dividerIndex, deltaRatio);

  /// Wraps [child] with the keyboard / focus / Semantics machinery that
  /// makes a divider an ARIA-APG "window splitter" (WCAG 2.1.1). [child]
  /// already carries the pointer-drag `GestureDetector`; this only adds
  /// the keyboard path alongside it, mirroring `Slider`'s
  /// `FocusableActionDetector` + `Shortcuts`/`Actions` pattern (`#3454`)
  /// rather than `DragItem`'s `role="application"` — a splitter is a
  /// self-contained ARIA *widget* role (like `slider`), not a subtree
  /// that needs the browser's virtual cursor suppressed entirely to
  /// forward arrow keys, which is what `application` is for.
  Widget _buildInteractiveDivider({
    required int dividerIndex,
    required bool isHorizontal,
    required Widget child,
  }) {
    final range = _layout.dividerRange(dividerIndex);
    const step = CoreResizableContract.defaultKeyboardStepFraction;

    void adjust(double direction) =>
        _handleKeyboardResize(dividerIndex, direction * step);

    final localizations = CoUILocalizations.of(context);

    // No clamp: the position announced is the position laid out. Clamping
    // here would read out a number the panes are not drawn at, and the
    // sizes reaching this point already sit inside `range` — the layout
    // resolves them there rather than papering over it at the announce
    // site.
    int percentOf(double ratio) => (ratio * _kRatioToPercent).round();

    String spokenAt(double ratio) =>
        localizations.resizableDividerPositionLabel(percentOf(ratio));

    /// Where one step in [direction] would actually land — the same clamp
    /// [_applyDeltaRatio] applies, so the preview cannot promise a position
    /// the divider will not take.
    String spokenAfter(double direction) => spokenAt(
      math.min(range.max, math.max(range.min, range.now + direction * step)),
    );

    return Semantics(
      // Flutter has no ARIA `separator` role — `slider:` is the nearest
      // idiom (see `CoreSemanticRole.separator`), which is why the Web
      // twin's `role="separator"` and this flag both resolve through the
      // same Core seat.
      slider: true,
      // A splitter that reports only a number is announced as a value
      // with no subject — the Web twin's `aria-label` says what the
      // control is, and this is that same name. Both platforms read it
      // at render time from the active locale rather than baking in
      // English.
      label: localizations.resizableDividerLabel,
      value: spokenAt(range.now),
      increasedValue: spokenAfter(1),
      decreasedValue: spokenAfter(-1),
      // Bounds stay numeric. Flutter's web engine writes `minValue` /
      // `maxValue` straight into `aria-valuemin` / `aria-valuemax` and
      // parses them as numbers, so these two pair with the Web twin's
      // numeric attributes — it is `value` / `increasedValue` /
      // `decreasedValue` that pair with `aria-valuetext`. `Diff`, the
      // sibling component with the same locale-member shape, splits them
      // the same way.
      minValue: '${percentOf(range.min)}',
      maxValue: '${percentOf(range.max)}',
      // Lets VoiceOver/TalkBack "adjustable" swipe gestures resize the
      // panes too — the same delta path arrow keys use.
      onIncrease: () => adjust(1),
      onDecrease: () => adjust(-1),
      child: FocusableActionDetector(
        focusNode: _dividerFocusNodes[dividerIndex],
        shortcuts: isHorizontal
            ? const {
                SingleActivator(.arrowRight): _ResizableDeltaIntent(1),
                SingleActivator(.arrowLeft): _ResizableDeltaIntent(-1),
              }
            : const {
                SingleActivator(.arrowDown): _ResizableDeltaIntent(1),
                SingleActivator(.arrowUp): _ResizableDeltaIntent(-1),
              },
        actions: {
          _ResizableDeltaIntent: CallbackAction<_ResizableDeltaIntent>(
            onInvoke: (intent) {
              adjust(intent.direction);
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) =>
            _handleFocusHighlightChanged(dividerIndex, focused: v),
        child: child,
      ),
    );
  }

  List<Widget> _buildPanes(List<int> flexes) {
    return [
      for (int i = 0; i < widget.panes.length; i++)
        Expanded(
          flex: flexes[i] <= 0 ? 1 : flexes[i],
          child: widget.panes[i].content,
        ),
    ];
  }

  /// Thin divider line overlaid on the seam. On pointer platforms (no grab
  /// handle) the line owns the drag hit area; when a handle is shown the
  /// line is purely the hairline indicator and the handle carries the drag.
  Widget _buildDividerLine({
    required int dividerIndex,
    required double seam,
    required bool isHorizontal,
    required double containerSize,
    required ResolvedResizable resolved,
  }) {
    // Three looks, picked from the divider's runtime state: dragged (heavier
    // `primary` line), hovered (`outline`), and the rest — a focused divider
    // keeps the resting line and gets the shared focus ring instead. An
    // `optionalDivider` has no resting line, so keyboard focus reveals it
    // the way hover does.
    final dragging = _draggingDivider == dividerIndex;
    final hovered = _hoveredDivider == dividerIndex;
    final focused = _focusedDivider == dividerIndex;
    final color = dragging
        ? resolved.dividerDraggingColor
        : hovered || (focused && widget.optionalDivider)
        ? resolved.dividerHoverColor
        : resolved.dividerColor;
    final thickness = dragging
        ? resolved.dividerDraggingThickness
        : resolved.dividerThickness;
    final line = FocusOutline(
      focused: focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: AnimatedContainer(
        color: color,
        width: isHorizontal ? thickness : .infinity,
        height: !isHorizontal ? thickness : .infinity,
        duration: resolved.transitionDuration,
        curve: resolved.curve,
      ),
    );

    // Handle mode: the line is a non-interactive hairline; the floating
    // handle owns hover + drag.
    if (widget.showDragHandle) {
      return Position(
        top: !isHorizontal ? seam - thickness / 2 : 0,
        right: isHorizontal ? null : 0,
        bottom: !isHorizontal ? null : 0,
        left: isHorizontal ? seam - thickness / 2 : 0,
        width: isHorizontal ? thickness : null,
        height: !isHorizontal ? thickness : null,
        child: IgnorePointer(child: line),
      );
    }

    // Pointer mode: the line carries an enlarged invisible grab area
    // ([dividerHitExtent]) with hover + drag, plus (below) the keyboard
    // path that makes it reachable without one.
    final hit = resolved.dividerHitExtent;
    return Position(
      top: !isHorizontal ? seam - hit / 2 : 0,
      right: isHorizontal ? null : 0,
      bottom: !isHorizontal ? null : 0,
      left: isHorizontal ? seam - hit / 2 : 0,
      width: isHorizontal ? hit : null,
      height: !isHorizontal ? hit : null,
      child: _buildInteractiveDivider(
        dividerIndex: dividerIndex,
        isHorizontal: isHorizontal,
        child: MouseRegion(
          onEnter: (_) => _handleHoverChanged(dividerIndex, hovered: true),
          onExit: (_) => _handleHoverChanged(dividerIndex, hovered: false),
          cursor: isHorizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: GestureDetector(
            // Start/end/cancel are wired alongside update so the reveal
            // covers the whole gesture. Cancel matters as much as end: a
            // drag the arena takes away would otherwise leave the divider
            // stuck visible with nothing holding it.
            onVerticalDragStart: !isHorizontal
                ? (_) => _handleDragStart(dividerIndex)
                : null,
            onVerticalDragEnd: !isHorizontal ? (_) => _handleDragStop() : null,
            onVerticalDragCancel: !isHorizontal ? _handleDragStop : null,
            onVerticalDragUpdate: !isHorizontal
                ? (d) => _handleDrag(dividerIndex, d.delta.dy, containerSize)
                : null,
            onHorizontalDragStart: isHorizontal
                ? (_) => _handleDragStart(dividerIndex)
                : null,
            onHorizontalDragEnd: isHorizontal ? (_) => _handleDragStop() : null,
            onHorizontalDragCancel: isHorizontal ? _handleDragStop : null,
            onHorizontalDragUpdate: isHorizontal
                ? (d) => _handleDrag(dividerIndex, d.delta.dx, containerSize)
                : null,
            behavior: .translucent,
            child: Center(child: line),
          ),
        ),
      ),
    );
  }

  /// Pill-shaped grab handle floating over the seam (touch platforms). It is
  /// [handleHitExtent] wide across the divider axis so it is comfortable to
  /// grab, and overflows the hairline onto the adjacent content without
  /// consuming layout width.
  Widget _buildHandle({
    required int dividerIndex,
    required double seam,
    required bool isHorizontal,
    required bool isActive,
    required double containerSize,
    required ResolvedResizable resolved,
  }) {
    final hit = resolved.handleHitExtent;
    final dots = Icon(
      LucideIcons.gripVertical,
      iconStyle: CoreIconStyle(
        size: resolved.handleIconSize,
        color: CoreColor(resolved.handleIconColor.toARGB32()),
      ),
    );
    final pill = AnimatedContainer(
      alignment: .center,
      decoration: BoxDecoration(
        color: isActive
            ? (_draggingDivider == dividerIndex
                  ? resolved.dividerDraggingColor
                  : resolved.dividerHoverColor)
            : resolved.handleColor,
        borderRadius: resolved.handleBorderRadius,
      ),
      width: isHorizontal ? resolved.handleBreadth : resolved.handleLength,
      height: isHorizontal ? resolved.handleLength : resolved.handleBreadth,
      duration: resolved.transitionDuration,
      curve: resolved.curve,
      // A vertical divider (horizontal split) needs the dots turned upright.
      child: isHorizontal
          ? Transform.rotate(angle: _kHandleQuarterTurn, child: dots)
          : dots,
    );

    return Position(
      top: !isHorizontal ? seam - hit / 2 : 0,
      right: isHorizontal ? null : 0,
      bottom: !isHorizontal ? null : 0,
      left: isHorizontal ? seam - hit / 2 : 0,
      width: isHorizontal ? hit : null,
      height: !isHorizontal ? hit : null,
      child: _buildInteractiveDivider(
        dividerIndex: dividerIndex,
        isHorizontal: isHorizontal,
        child: MouseRegion(
          onEnter: (_) => _handleHoverChanged(dividerIndex, hovered: true),
          onExit: (_) => _handleHoverChanged(dividerIndex, hovered: false),
          cursor: isHorizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: GestureDetector(
            // Start/end/cancel are wired alongside update so the reveal
            // covers the whole gesture. Cancel matters as much as end: a
            // drag the arena takes away would otherwise leave the divider
            // stuck visible with nothing holding it.
            onVerticalDragStart: !isHorizontal
                ? (_) => _handleDragStart(dividerIndex)
                : null,
            onVerticalDragEnd: !isHorizontal ? (_) => _handleDragStop() : null,
            onVerticalDragCancel: !isHorizontal ? _handleDragStop : null,
            onVerticalDragUpdate: !isHorizontal
                ? (d) => _handleDrag(dividerIndex, d.delta.dy, containerSize)
                : null,
            onHorizontalDragStart: isHorizontal
                ? (_) => _handleDragStart(dividerIndex)
                : null,
            onHorizontalDragEnd: isHorizontal ? (_) => _handleDragStop() : null,
            onHorizontalDragCancel: isHorizontal ? _handleDragStop : null,
            onHorizontalDragUpdate: isHorizontal
                ? (d) => _handleDrag(dividerIndex, d.delta.dx, containerSize)
                : null,
            behavior: .translucent,
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveResizable(
      context,
      optionalDivider: widget.optionalDivider,
      resizableStyle: widget.resizableStyle,
    );
    final isHorizontal = widget.direction == .horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = isHorizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        // Panes fill the container by flex — no divider gutter reserved, so
        // the content area stays maximal. The seam positions are derived
        // from the same integer flex ratios Flutter lays the panes out
        // with, so the overlaid line / handle land exactly on the boundary.
        final flexes = [
          for (final size in _layout.sizes)
            (size * resolved.flexPrecision).round(),
        ];
        final totalFlex = flexes.fold<int>(0, (sum, f) => sum + f);

        // A single `Flex` with a variable `direction` (mirrors
        // `ResponsiveRowColumn`) — NOT `isHorizontal ? Row(...) : Column(...)`.
        // `Row`/`Column` are distinct `Flex` subclasses, so branching between
        // them changes the child's `runtimeType` on every direction flip.
        // `Widget.canUpdate` then returns false, Flutter unmounts the old
        // element and mounts a fresh one, and every descendant State (focus
        // nodes, controllers, BLoCs) in `_buildPanes(flexes)` is destroyed
        // and recreated. Consumers that flip `direction` in response to a
        // live layout change — e.g. a split panel whose orientation depends
        // on `MediaQuery.viewInsets` while the keyboard opens — lose input
        // focus mid-animation as a result. A single `Flex` instance keeps
        // the element identity stable across the flip, so descendant State
        // survives.
        final paneRow = Flex(
          direction: isHorizontal ? .horizontal : .vertical,
          children: _buildPanes(flexes),
        );

        // Single pane (or zero) — no dividers to overlay.
        if (widget.panes.length < 2 || totalFlex <= 0 || containerSize <= 0) {
          return paneRow;
        }

        final overlays = <Widget>[Position.fill(child: paneRow)];
        var cumulativeFlex = 0;
        for (int i = 0; i < widget.panes.length - 1; i++) {
          cumulativeFlex += flexes[i];
          final seam = containerSize * cumulativeFlex / totalFlex;
          final isActive =
              _hoveredDivider == i ||
              _focusedDivider == i ||
              _draggingDivider == i;

          overlays.add(
            _buildDividerLine(
              dividerIndex: i,
              seam: seam,
              isHorizontal: isHorizontal,
              containerSize: containerSize,
              resolved: resolved,
            ),
          );
          if (widget.showDragHandle) {
            overlays.add(
              _buildHandle(
                dividerIndex: i,
                seam: seam,
                isHorizontal: isHorizontal,
                isActive: isActive,
                containerSize: containerSize,
                resolved: resolved,
              ),
            );
          }
        }

        // Clip.none keeps the floating handle visible where it overflows the
        // hairline seam onto the adjacent panes.
        return Stacks(clipBehavior: .none, children: overlays);
      },
    );
  }
}

/// Arrow-key resize intent for a divider — `direction` is `+1` (grows the
/// left/top pane) or `-1` (shrinks it), multiplied by
/// `CoreResizableContract.defaultKeyboardStepFraction` in the action that
/// handles it. Mirrors `Slider`'s `_SliderDeltaIntent`.
class _ResizableDeltaIntent extends Intent {
  const _ResizableDeltaIntent(this.direction);
  final double direction;
}

/// Chain sugar for merging a [CoreResizableStyle] patch into
/// [Resizable.resizableStyle] without hand-reconstructing every field.
/// Mirrors the Web `Resizable.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResizableStyle.merge` right-side-wins semantics).
extension ResizableStyleChain on Resizable {
  /// Returns a copy of this [Resizable] with [patch] merged into
  /// [resizableStyle] (patch fields win on conflict).
  Resizable withStyle(CoreResizableStyle patch) => copyWith(
    resizableStyle: (resizableStyle ?? const CoreResizableStyle()).merge(
      patch,
    ),
  );
}
