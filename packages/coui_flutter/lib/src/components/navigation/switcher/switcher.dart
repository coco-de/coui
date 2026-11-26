import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// A unified swipeable container that transitions between child views.
///
/// `Switcher` shows one of [items] at a time and animates a smooth
/// slide / fade transition along [direction] whenever [index] changes.
/// When [gestureEnabled] is set the user can drag to scrub between
/// adjacent views; releasing snaps to the nearest view and reports the
/// new index through [onIndexChanged].
///
/// `Switcher` is the unified replacement for the legacy Flutter
/// `Switcher` and Web `Switcher` — same parameter names, same
/// semantics, full visual / interaction parity.
///
/// Mirrors Web `Switcher` 1:1 — same parameter names, same semantics.
/// Transition chrome enters through the single [switcherStyle] slot, and
/// [CoreSwitcherStyle.curve] carries the easing as a Core token, which is
/// what the Web twin can emit too.
///
/// ```dart
/// Switcher(
///   index: _index,
///   direction: CoreSwitcherDirection.left,
///   onIndexChanged: (i) => setState(() => _index = i),
///   items: const [
///     Text('Page 1'),
///     Text('Page 2'),
///     Text('Page 3'),
///   ],
/// )
/// ```
class Switcher extends StatefulWidget implements CoreSwitcherContract<Widget> {
  /// Creates a [Switcher].
  const Switcher({
    required this.items,
    this.index = 0,
    this.direction = CoreSwitcherDirection.defaultDirection,
    this.gestureEnabled = true,
    this.onIndexChanged,
    this.switcherStyle,
    super.key,
  });

  @override
  final int index;

  @override
  final List<Widget> items;

  @override
  final CoreSwitcherDirection direction;

  @override
  final bool gestureEnabled;

  @override
  final void Function(int)? onIndexChanged;

  @override
  final CoreSwitcherStyle? switcherStyle;

  /// Returns a copy of this [Switcher] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Switcher copyWith({
    Key? key,
    List<Widget>? items,
    int? index,
    CoreSwitcherDirection? direction,
    bool? gestureEnabled,
    void Function(int)? onIndexChanged,
    CoreSwitcherStyle? switcherStyle,
  }) {
    return Switcher(
      key: key ?? this.key,
      items: items ?? this.items,
      index: index ?? this.index,
      direction: direction ?? this.direction,
      gestureEnabled: gestureEnabled ?? this.gestureEnabled,
      onIndexChanged: onIndexChanged ?? this.onIndexChanged,
      switcherStyle: switcherStyle ?? this.switcherStyle,
    );
  }

  @override
  State<Switcher> createState() => _SwitcherState();
}

/// Chain sugar for merging a [CoreSwitcherStyle] patch into
/// [Switcher.switcherStyle] without hand-reconstructing every field.
/// Mirrors the Web `Switcher.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwitcherStyle.merge` right-side-wins semantics).
extension SwitcherStyleChain on Switcher {
  /// Returns a copy of this [Switcher] with [patch] merged into
  /// [switcherStyle] (patch fields win on conflict).
  Switcher withStyle(CoreSwitcherStyle patch) => copyWith(
    switcherStyle: (switcherStyle ?? const CoreSwitcherStyle()).merge(patch),
  );
}

class _SwitcherState extends State<Switcher> {
  late double _index;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _index = widget.index.toDouble();
  }

  void _handleDragSettled() {
    setState(() {
      _dragging = false;
      _index = _index.roundToDouble();
    });
    widget.onIndexChanged?.call(_index.toInt());
  }

  Widget _buildDraggable(BuildContext context, Widget child) {
    if (!widget.gestureEnabled) return child;

    return GestureDetector(
      onPanStart: (details) {
        _dragging = true;
      },
      onPanUpdate: (details) {
        if (!_dragging) return;
        final currentSize = context.size;
        if (currentSize == null) return;
        final double delta;
        switch (widget.direction) {
          case .up:
            delta = -details.delta.dy / currentSize.height;
          case .down:
            delta = details.delta.dy / currentSize.height;
          case .left:
            delta = -details.delta.dx / currentSize.width;
          case .right:
            delta = details.delta.dx / currentSize.width;
        }
        setState(() {
          _index = (_index + delta)
              .clamp(0, widget.items.length - 1)
              .toDouble();
        });
      },
      onPanEnd: (details) => _handleDragSettled(),
      onPanCancel: _handleDragSettled,
      behavior: .translucent,
      child: child,
    );
  }

  @override
  void didUpdateWidget(covariant Switcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _index = widget.index.toDouble();
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSwitcher(
      context,
      switcherStyle: widget.switcherStyle,
    );
    final axisDirection = coSwitcherAxisDirection(widget.direction);

    // Web twin: role="group" on the switcher track.
    return Semantics(
      container: true,
      child: _buildDraggable(
        context,
        AnimatedValueBuilder(
          value: _index,
          duration: _dragging ? .zero : resolved.duration,
          curve: resolved.curve,
          builder: (context, value, child) {
            final sourceChild = value.floor();
            final targetChild = value.ceil();
            final relativeProgress = value - sourceChild;

            // Clip to the viewport so the sliding source/target children
            // reveal and hide at the edges — mirroring the Web root's
            // `overflow: hidden` so the transition reads as a slide, not a
            // cross-fade of two overlapping children.
            return ClipRect(
              child: _SwitcherTransition(
                direction: axisDirection,
                progress: relativeProgress,
                children: [
                  if (1 - relativeProgress == 0)
                    const SizedBox.shrink()
                  else
                    Opacity(
                      key: ValueKey(sourceChild),
                      opacity: 1 - relativeProgress,
                      child: widget.items[sourceChild],
                    ),
                  if (relativeProgress == 0)
                    const SizedBox.shrink()
                  else
                    Opacity(
                      key: ValueKey(targetChild),
                      opacity: relativeProgress,
                      child: widget.items[targetChild],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Internal multi-child transition that lerps the size and offset of
/// two stacked views as the [progress] sweeps from 0 to 1.
class _SwitcherTransition extends MultiChildRenderObjectWidget {
  const _SwitcherTransition({
    required super.children,
    required this.direction,
    required this.progress,
  });

  final double progress;
  final AxisDirection direction;

  @override
  _RenderSwitcherTransition createRenderObject(BuildContext context) {
    return _RenderSwitcherTransition()
      ..progress = progress
      ..direction = direction;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSwitcherTransition renderObject,
  ) {
    if (renderObject.progress != progress ||
        renderObject.direction != direction) {
      renderObject
        ..progress = progress
        ..direction = direction
        ..markNeedsLayout();
    }
  }
}

class _SwitcherParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSwitcherTransition extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SwitcherParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SwitcherParentData> {
  double progress = 0;
  AxisDirection direction = .down;

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parent != this) {
      child.parentData = _SwitcherParentData();
    }
  }

  @override
  void performLayout() {
    final first = firstChild;
    if (first == null || childAfter(first) == null) {
      size = .zero;
      return;
    }
    final oldChild = first;
    final newChild = childAfter(oldChild)!;

    oldChild.layout(constraints, parentUsesSize: true);
    newChild.layout(constraints, parentUsesSize: true);
    final oldSize = oldChild.size;
    final newSize = newChild.size;

    final oldData = oldChild.parentData! as _SwitcherParentData;
    final newData = newChild.parentData! as _SwitcherParentData;

    final lerpedSize = Size.lerp(oldSize, newSize, progress)!;

    switch (direction) {
      case .down:
      case .up:
        final oldSlideOffset = direction == .down
            ? Offset.lerp(.zero, Offset(0, newSize.height), progress)!
            : Offset.lerp(.zero, Offset(0, -oldSize.height), progress)!;
        final newSlideOffset = direction == .down
            ? Offset.lerp(Offset(0, -newSize.height), .zero, progress)!
            : Offset.lerp(Offset(0, oldSize.height), .zero, progress)!;

        final oldCenteringDx = (lerpedSize.width - oldSize.width) / 2;
        final newCenteringDx = (lerpedSize.width - newSize.width) / 2;

        oldData.offset = oldSlideOffset + Offset(oldCenteringDx, 0);
        newData.offset = newSlideOffset + Offset(newCenteringDx, 0);
      case .left:
      case .right:
        final oldSlideOffset = direction == .right
            ? Offset.lerp(.zero, Offset(newSize.width, 0), progress)!
            : Offset.lerp(.zero, Offset(-oldSize.width, 0), progress)!;
        final newSlideOffset = direction == .right
            ? Offset.lerp(Offset(-newSize.width, 0), .zero, progress)!
            : Offset.lerp(Offset(oldSize.width, 0), .zero, progress)!;

        final oldCenteringDy = (lerpedSize.height - oldSize.height) / 2;
        final newCenteringDy = (lerpedSize.height - newSize.height) / 2;

        oldData.offset = oldSlideOffset + Offset(0, oldCenteringDy);
        newData.offset = newSlideOffset + Offset(0, newCenteringDy);
    }
    size = constraints.constrain(lerpedSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
