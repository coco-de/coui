import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart'
    show DragStartBehavior, PointerDeviceKind, kPrimaryMouseButton;

/// Percent is the unit the split position is announced in — a bare
/// 0..1 ratio is not a sentence anyone speaks.
const int _kDiffPercentScale = 100;

/// Before/after split-view comparison viewer (daisyUI `Diff` pattern).
///
/// Renders [before] under [after] inside a fixed-aspect frame and
/// reveals [after] on the right of a draggable resizer. Equivalent
/// to the Web `Diff` — same parameters, same rendering.
///
/// The split is a thin raised line with a round handle on it. The handle
/// is what to grab: a [CoreDiffStyle.handleHitSize]-wide strip around it
/// takes the pointer, a click or tap anywhere else on the frame moves the
/// split there, and on touch only that strip drags — a finger on the rest
/// of the frame keeps scrolling the page. [beforeLabel] / [afterLabel]
/// name the two sides with a chip in the top corners.
///
/// Chrome and dimensional / initial layout overrides flow through the
/// single [diffStyle] slot (`aspectRatio`, `initialPosition`,
/// `borderRadius`, …). Behaviour fields (`before`, `after`,
/// `onPositionChanged`, `interactive`, `ariaLabel`, the two labels) stay
/// flat on the widget.
///
/// ```dart
/// Diff(
///   before: Image.network('before.jpg'),
///   after: Image.network('after.jpg'),
///   beforeLabel: Text('Before'),
///   afterLabel: Text('After'),
///   ariaLabel: 'Before / after comparison',
/// )
/// ```
class Diff extends StatefulWidget implements CoreDiffContract<Widget> {
  /// Creates a [Diff].
  const Diff({
    required this.before,
    required this.after,
    super.key,
    this.beforeLabel,
    this.afterLabel,
    this.onPositionChanged,
    this.interactive = true,
    this.ariaLabel,
    this.diffStyle,
  });

  @override
  final Widget before;

  @override
  final Widget after;

  @override
  final Widget? beforeLabel;

  @override
  final Widget? afterLabel;

  @override
  final void Function(double position)? onPositionChanged;

  @override
  final bool interactive;

  @override
  final String? ariaLabel;

  @override
  final CoreDiffStyle? diffStyle;

  /// Returns a copy of this [Diff] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Diff copyWith({
    Key? key,
    Widget? before,
    Widget? after,
    Widget? beforeLabel,
    Widget? afterLabel,
    void Function(double position)? onPositionChanged,
    bool? interactive,
    String? ariaLabel,
    CoreDiffStyle? diffStyle,
  }) {
    return Diff(
      key: key ?? this.key,
      before: before ?? this.before,
      after: after ?? this.after,
      beforeLabel: beforeLabel ?? this.beforeLabel,
      afterLabel: afterLabel ?? this.afterLabel,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
      interactive: interactive ?? this.interactive,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      diffStyle: diffStyle ?? this.diffStyle,
    );
  }

  @override
  State<Diff> createState() => _DiffState();
}

/// Which keyboard step an arrow / page key moves by.
enum _DiffStep { arrow, page }

/// Arrow / Page key intent — `sign` is `-1` toward the "before" side and
/// `1` toward the "after" side.
class _DiffMoveIntent extends Intent {
  const _DiffMoveIntent(this.step, this.sign);

  final _DiffStep step;
  final int sign;
}

/// Home / End intent — jumps the split to an end of the frame.
class _DiffJumpIntent extends Intent {
  const _DiffJumpIntent(this.target);

  final double target;
}

class _DiffState extends State<Diff> {
  double? _position;

  /// A pointer is holding the split — the handle is pressed.
  bool _dragging = false;

  /// The pointer is over the handle's strip.
  bool _handleHovered = false;

  /// How far the pointer was from the handle's centre when it took hold
  /// (px). Grabbing the disc off-centre keeps the split where it is
  /// instead of snapping the line under the pointer.
  double _grabOffset = 0;

  bool _focused = false;

  /// Whether the current focus arrived from a pointer rather than the
  /// keyboard — the ring is for keyboard focus only (`:focus-visible`
  /// parity with the Web twin), while a click still takes focus so the
  /// keys work right after it. Same arrangement as `Slider`.
  bool _pointerFocus = false;

  final FocusNode _focusNode = FocusNode(debugLabel: 'Diff');
  final GlobalKey _frameKey = GlobalKey();

  bool get _showFocusOutline => _focused && !_pointerFocus;

  void _setPosition(double next) {
    final clamped = next.clamp(0.0, 1.0);
    if (clamped == _position) return;
    setState(() => _position = clamped);
    widget.onPositionChanged?.call(clamped);
  }

  void _focusFromPointer() {
    setState(() {
      _pointerFocus = true;
      _focused = false;
    });
    _focusNode.requestFocus();
  }

  /// Promotes pointer-originated focus to keyboard focus once a key
  /// arrives, which is when the ring becomes meaningful.
  void _promotePointerFocus() {
    if (!_pointerFocus) return;
    setState(() {
      _pointerFocus = false;
      _focused = _focusNode.hasFocus;
    });
  }

  void _moveBy(double delta, ResolvedDiff resolved) {
    if (!widget.interactive) return;
    _promotePointerFocus();
    _setPosition((_position ?? resolved.initialPosition) + delta);
  }

  void _jumpTo(double target) {
    if (!widget.interactive) return;
    _promotePointerFocus();
    _setPosition(target);
  }

  /// The frame's box — the coordinate space the split lives in.
  RenderBox? get _frameBox {
    final box = _frameKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Maps a global pointer position to an x inside the frame (px).
  double? _frameX(Offset global) => _frameBox?.globalToLocal(global).dx;

  /// A pointer takes hold at [global]. Inside the handle's strip the split
  /// stays put and the pointer keeps its distance from the centre; outside
  /// it the split goes to the pointer.
  void _beginDrag(Offset global, ResolvedDiff resolved) {
    final box = _frameBox;
    final x = _frameX(global);
    if (box == null || x == null || box.size.width <= 0) return;
    final width = box.size.width;
    final centre = (_position ?? resolved.initialPosition) * width;
    final inStrip = (x - centre).abs() <= resolved.handleHitSize / 2;
    _focusFromPointer();
    setState(() {
      _dragging = true;
      _grabOffset = inStrip ? x - centre : 0;
    });
    if (!inStrip) _setPosition(x / width);
  }

  void _dragTo(Offset global) {
    final box = _frameBox;
    final x = _frameX(global);
    if (box == null || x == null || box.size.width <= 0) return;
    _setPosition((x - _grabOffset) / box.size.width);
  }

  void _handleEndDrag() {
    if (!_dragging) return;
    setState(() {
      _dragging = false;
      _grabOffset = 0;
    });
  }

  @override
  void didUpdateWidget(covariant Diff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.interactive) {
      _dragging = false;
      _handleHovered = false;
      _focused = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The label chip — a `Badge` around the caller's content.
  Widget _label(Widget content, ResolvedDiff resolved) {
    return IgnorePointer(
      child: Badge(
        size: .sm,
        badgeStyle: resolved.labelBadgeStyle,
        child: content,
      ),
    );
  }

  /// The round handle on the split, with its focus ring.
  Widget _handle(ResolvedDiff resolved) {
    final shadow = _dragging
        ? resolved.handlePressedShadow
        : _handleHovered
        ? resolved.handleHoverShadow
        : resolved.handleShadow;
    return AnimatedScale(
      scale: _dragging ? resolved.handlePressedScale : 1,
      duration: resolved.handleTransitionDuration,
      curve: CoreEasing.move.toValue(),
      child: FocusOutline(
        focused: _showFocusOutline,
        focusOutlineStyle: resolved.focusOutlineStyle,
        child: AnimatedContainer(
          duration: resolved.handleTransitionDuration,
          curve: CoreEasing.move.toValue(),
          width: resolved.handleSize,
          height: resolved.handleSize,
          decoration: BoxDecoration(
            color: resolved.handleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: resolved.handleBorderColor,
              width: resolved.handleBorderWidth,
            ),
            boxShadow: shadow,
          ),
          child: Center(
            // The glyph says "this moves sideways" to the eye only. Left in,
            // it becomes an image node of its own that takes the focus action
            // off the slider, so a reader lands on a picture, not the control.
            child: ExcludeSemantics(
              child: Icon(
                LucideIcons.chevronsLeftRight,
                iconStyle: resolved.handleIconStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDiff(context, diffStyle: widget.diffStyle);

    final effectivePosition = _position ?? resolved.initialPosition;
    final interactive = widget.interactive;

    Widget frame = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final positionPx = width * effectivePosition;

        Widget stage = Stacks(
          key: _frameKey,
          // The handle and its ring may reach past the frame at the ends.
          clipBehavior: .none,
          children: [
            // Content, line, labels and edge — clipped to the frame's
            // rounded shape.
            Position.fill(
              child: ClipRRect(
                borderRadius: resolved.borderRadius,
                child: Stacks(
                  children: [
                    // After (full background).
                    Position.fill(child: widget.after),
                    // Before (clipped to position).
                    Position.fill(
                      child: ClipRect(
                        clipper: _SplitClipper(position: effectivePosition),
                        child: widget.before,
                      ),
                    ),
                    // Split line.
                    Position(
                      top: 0,
                      bottom: 0,
                      left: positionPx - resolved.resizerWidth / 2,
                      width: resolved.resizerWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: resolved.resizerColor,
                          boxShadow: resolved.resizerShadow,
                        ),
                      ),
                    ),
                    if (widget.beforeLabel != null)
                      Position(
                        top: resolved.labelInset.top,
                        left: resolved.labelInset.left,
                        child: _label(widget.beforeLabel!, resolved),
                      ),
                    if (widget.afterLabel != null)
                      Position(
                        top: resolved.labelInset.top,
                        right: resolved.labelInset.right,
                        child: _label(widget.afterLabel!, resolved),
                      ),
                    // Frame edge — drawn inside, over the content.
                    if (resolved.borderWidth > 0)
                      Position.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: resolved.borderRadius,
                              border: Border.all(
                                color: resolved.borderColor,
                                width: resolved.borderWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Handle strip — the only part a touch can drag.
            if (interactive)
              Position(
                top: 0,
                bottom: 0,
                left: positionPx - resolved.handleHitSize / 2,
                width: resolved.handleHitSize,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  onEnter: (_) => setState(() => _handleHovered = true),
                  onExit: (_) => setState(() => _handleHovered = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    dragStartBehavior: DragStartBehavior.down,
                    onHorizontalDragStart: (details) {
                      // A mouse already took hold on the way down.
                      if (_dragging) return;
                      _beginDrag(details.globalPosition, resolved);
                    },
                    onHorizontalDragUpdate: (details) =>
                        _dragTo(details.globalPosition),
                    onHorizontalDragEnd: (_) => _handleEndDrag(),
                    onHorizontalDragCancel: _handleEndDrag,
                    child: Center(child: _handle(resolved)),
                  ),
                ),
              ),
          ],
        );

        if (interactive) {
          // A tap (touch / stylus) anywhere moves the split there; the
          // mouse is handled below, from the press, so it can drag.
          stage = GestureDetector(
            // The comparison is one slider to assistive technology — a
            // tap or a scroll action on its internals would be a second,
            // meaningless control.
            excludeFromSemantics: true,
            onTapUp: (details) {
              if (details.kind == PointerDeviceKind.mouse) return;
              final box = _frameBox;
              final x = _frameX(details.globalPosition);
              if (box == null || x == null || box.size.width <= 0) return;
              _focusFromPointer();
              _setPosition(x / box.size.width);
            },
            // A listener, not a drag recognizer: it takes no part in the
            // gesture arena, so a vertical scroll is never held up by it.
            child: Listener(
              onPointerDown: (event) {
                if (event.kind != PointerDeviceKind.mouse ||
                    event.buttons != kPrimaryMouseButton) {
                  return;
                }
                _beginDrag(event.position, resolved);
              },
              onPointerMove: (event) {
                if (_dragging && event.kind == PointerDeviceKind.mouse) {
                  _dragTo(event.position);
                }
              },
              onPointerUp: (event) {
                if (event.kind == PointerDeviceKind.mouse) _handleEndDrag();
              },
              onPointerCancel: (event) {
                if (event.kind == PointerDeviceKind.mouse) _handleEndDrag();
              },
              child: stage,
            ),
          );
        }
        return stage;
      },
    );

    if (resolved.aspectRatio > 0) {
      final content = frame;
      frame = LayoutBuilder(
        builder: (context, constraints) {
          final aspected = AspectRatio(
            aspectRatio: resolved.aspectRatio,
            child: content,
          );
          // Fill the available width so the height derives from the width
          // (matching Web's `width:100%` + `aspect-ratio`). Without this an
          // unbounded-width / height-bounded context lets `AspectRatio`
          // collapse the frame to fit the ambient height instead of the
          // full width.
          return constraints.hasBoundedWidth
              ? SizedBox(width: constraints.maxWidth, child: aspected)
              : aspected;
        },
      );
    }

    // An interactive comparison is a value on a range, not a container:
    // the arrow keys move the split and nothing announced that it had
    // moved, or where it was. A reader heard a label and then silence,
    // so the control existed only for people who could see it.
    //
    // Non-interactive stays a plain container — there is no value to
    // report when the split cannot move, and a slider that never moves
    // is a promise of a control that is not there.
    final percent = (effectivePosition * _kDiffPercentScale).round();

    return CoUISemantics(
      role: interactive ? .slider : null,
      label: widget.ariaLabel,
      value: interactive
          ? CoUILocalizations.of(context).diffPositionLabel(percent)
          : null,
      minValue: interactive ? '0' : null,
      maxValue: interactive ? '$_kDiffPercentScale' : null,
      container: true,
      child: FocusableActionDetector(
        enabled: interactive,
        focusNode: _focusNode,
        shortcuts: const {
          SingleActivator(.arrowLeft): _DiffMoveIntent(.arrow, -1),
          SingleActivator(.arrowRight): _DiffMoveIntent(.arrow, 1),
          SingleActivator(.pageDown): _DiffMoveIntent(.page, -1),
          SingleActivator(.pageUp): _DiffMoveIntent(.page, 1),
          SingleActivator(.home): _DiffJumpIntent(0),
          SingleActivator(.end): _DiffJumpIntent(1),
        },
        actions: {
          _DiffMoveIntent: CallbackAction<_DiffMoveIntent>(
            onInvoke: (intent) {
              final step = intent.step == .arrow
                  ? resolved.keyboardStep
                  : resolved.keyboardPageStep;
              _moveBy(intent.sign * step, resolved);
              return null;
            },
          ),
          _DiffJumpIntent: CallbackAction<_DiffJumpIntent>(
            onInvoke: (intent) {
              _jumpTo(intent.target);
              return null;
            },
          ),
        },
        onShowFocusHighlight: (visible) => setState(() {
          _focused = visible;
          // Losing focus ends the pointer-originated episode, so the next
          // Tab into the comparison shows the ring again.
          if (!visible) _pointerFocus = false;
        }),
        child: frame,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreDiffStyle] patch into
/// [Diff.diffStyle] without hand-reconstructing every field. Mirrors
/// the Web `Diff.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDiffStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreDiffStyle.borderRadius]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Diff(before: ..., after: ...).radius4
/// ```
extension DiffStyleChain on Diff {
  /// Returns a copy of this [Diff] with [patch] merged into
  /// [diffStyle] (patch fields win on conflict).
  Diff withStyle(CoreDiffStyle patch) =>
      copyWith(diffStyle: (diffStyle ?? const CoreDiffStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Diff get radius0 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Diff get radius2 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Diff get radius4 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Diff get radius6 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Diff get radius8 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Diff get radius10 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Diff get radius12 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Diff get radius14 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Diff get radius16 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Diff get radius20 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Diff get radius24 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Diff get radius28 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Diff get radius32 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Diff get radius36 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Diff get radius40 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Diff get radius48 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Diff get radius56 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Diff get radius64 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Diff get radius9999 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}

/// Clips the painted child to the left `position` fraction of the
/// available width, leaving the rest transparent. Used to reveal the
/// `before` slot only on the left side of the resizer.
class _SplitClipper extends CustomClipper<Rect> {
  const _SplitClipper({required this.position});

  final double position;

  @override
  Rect getClip(Size size) =>
      .fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) =>
      oldClipper.position != position;
}
