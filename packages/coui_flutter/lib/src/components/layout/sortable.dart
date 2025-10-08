import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// A draggable widget that supports drag-and-drop reordering with directional drop zones.
///
/// The Sortable widget enables drag-and-drop interactions with support for four directional
/// drop zones (top, left, right, bottom). It provides customizable callbacks for handling
/// drop events, visual feedback during dragging, and placeholder widgets for smooth
/// reordering animations.
///
/// Features:
/// - Four directional drop zones with individual accept/reject logic
/// - Customizable ghost and placeholder widgets during drag operations
/// - Automatic scroll support when wrapped in ScrollableSortableLayer
/// - Visual feedback with animated placeholders and fallback widgets
/// - Robust drag session management with proper cleanup
///
/// The widget must be wrapped in a [SortableLayer] to function properly. Use
/// [ScrollableSortableLayer] for automatic scrolling during drag operations.
///
/// Example:
/// ```dart
/// SortableLayer(
///   child: Column(
///     children: [
///       Sortable<String>(
///         data: SortableData('Item 1'),
///         onAcceptTop: (data) => reorderAbove(data.data),
///         onAcceptBottom: (data) => reorderBelow(data.data),
///         child: Card(child: Text('Item 1')),
///       ),
///       Sortable<String>(
///         data: SortableData('Item 2'),
///         onAcceptTop: (data) => reorderAbove(data.data),
///         onAcceptBottom: (data) => reorderBelow(data.data),
///         child: Card(child: Text('Item 2')),
///       ),
///     ],
///   ),
/// )
/// ```
class Sortable<T> extends StatefulWidget {
  /// Creates a [Sortable] widget with drag-and-drop functionality.
  ///
  /// Configures a widget that can be dragged and accepts drops from other
  /// sortable items. The widget supports directional drop zones and provides
  /// extensive customization for drag interactions and visual feedback.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [data] (SortableData<T>, required): Data associated with this sortable item
  /// - [child] (Widget, required): The main widget to make sortable
  /// - [enabled] (bool, default: true): Whether drag interactions are enabled
  /// - [canAcceptTop] (Predicate<SortableData<T>>?, optional): Validation for top drops
  /// - [canAcceptLeft] (Predicate<SortableData<T>>?, optional): Validation for left drops
  /// - [canAcceptRight] (Predicate<SortableData<T>>?, optional): Validation for right drops
  /// - [canAcceptBottom] (Predicate<SortableData<T>>?, optional): Validation for bottom drops
  /// - [onAcceptTop] (ValueChanged<SortableData<T>>?, optional): Handler for top drops
  /// - [onAcceptLeft] (ValueChanged<SortableData<T>>?, optional): Handler for left drops
  /// - [onAcceptRight] (ValueChanged<SortableData<T>>?, optional): Handler for right drops
  /// - [onAcceptBottom] (ValueChanged<SortableData<T>>?, optional): Handler for bottom drops
  /// - [placeholder] (Widget?, default: SizedBox()): Widget shown in drop zones
  /// - [ghost] (Widget?, optional): Widget displayed while dragging
  /// - [fallback] (Widget?, optional): Widget shown at original position during drag
  /// - [candidateFallback] (Widget?, optional): Widget shown when item is drop candidate
  /// - [onDragStart] (VoidCallback?, optional): Called when drag starts
  /// - [onDragEnd] (VoidCallback?, optional): Called when drag ends successfully
  /// - [onDragCancel] (VoidCallback?, optional): Called when drag is cancelled
  /// - [behavior] (HitTestBehavior, default: HitTestBehavior.deferToChild): Hit test behavior
  /// - [onDropFailed] (VoidCallback?, optional): Called when drop fails
  ///
  /// Example:
  /// ```dart
  /// Sortable<String>(
  ///   data: SortableData('item_1'),
  ///   onAcceptTop: (data) => moveAbove(data.data),
  ///   onAcceptBottom: (data) => moveBelow(data.data),
  ///   placeholder: Container(height: 2, color: Colors.blue),
  ///   child: ListTile(title: Text('Draggable Item')),
  /// )
  /// ```
  const Sortable({
    this.behavior = HitTestBehavior.deferToChild,
    this.canAcceptBottom,
    this.canAcceptLeft,
    this.canAcceptRight,
    this.canAcceptTop,
    this.candidateFallback,
    required this.child,
    required this.data,
    this.enabled = true,
    this.fallback,
    this.ghost,
    super.key,
    this.onAcceptBottom,
    this.onAcceptLeft,
    this.onAcceptRight,
    this.onAcceptTop,
    this.onDragCancel,
    this.onDragEnd,
    this.onDragStart,
    this.onDropFailed,
    this.placeholder = const SizedBox(),
  });

  /// Predicate to determine if data can be accepted when dropped above this widget.
  ///
  /// Type: `Predicate<SortableData<T>>?`. If null, drops from the top are not accepted.
  /// Called before [onAcceptTop] to validate the drop operation.
  final Predicate<SortableData<T>>? canAcceptTop;

  /// Predicate to determine if data can be accepted when dropped to the left of this widget.
  ///
  /// Type: `Predicate<SortableData<T>>?`. If null, drops from the left are not accepted.
  /// Called before [onAcceptLeft] to validate the drop operation.
  final Predicate<SortableData<T>>? canAcceptLeft;

  /// Predicate to determine if data can be accepted when dropped to the right of this widget.
  ///
  /// Type: `Predicate<SortableData<T>>?`. If null, drops from the right are not accepted.
  /// Called before [onAcceptRight] to validate the drop operation.
  final Predicate<SortableData<T>>? canAcceptRight;

  /// Predicate to determine if data can be accepted when dropped below this widget.
  ///
  /// Type: `Predicate<SortableData<T>>?`. If null, drops from the bottom are not accepted.
  /// Called before [onAcceptBottom] to validate the drop operation.
  final Predicate<SortableData<T>>? canAcceptBottom;

  /// Callback invoked when data is successfully dropped above this widget.
  ///
  /// Type: `ValueChanged<SortableData<T>>?`. The callback receives the dropped
  /// data and should handle the reordering logic. Only called after [canAcceptTop]
  /// validation passes.
  final ValueChanged<SortableData<T>>? onAcceptTop;

  /// Callback invoked when data is successfully dropped to the left of this widget.
  ///
  /// Type: `ValueChanged<SortableData<T>>?`. The callback receives the dropped
  /// data and should handle the reordering logic. Only called after [canAcceptLeft]
  /// validation passes.
  final ValueChanged<SortableData<T>>? onAcceptLeft;

  /// Callback invoked when data is successfully dropped to the right of this widget.
  ///
  /// Type: `ValueChanged<SortableData<T>>?`. The callback receives the dropped
  /// data and should handle the reordering logic. Only called after [canAcceptRight]
  /// validation passes.
  final ValueChanged<SortableData<T>>? onAcceptRight;

  /// Callback invoked when data is successfully dropped below this widget.
  ///
  /// Type: `ValueChanged<SortableData<T>>?`. The callback receives the dropped
  /// data and should handle the reordering logic. Only called after [canAcceptBottom]
  /// validation passes.
  final ValueChanged<SortableData<T>>? onAcceptBottom;

  /// Callback invoked when a drag operation starts on this widget.
  ///
  /// Type: `VoidCallback?`. Called immediately when the user begins dragging
  /// this sortable item. Useful for providing haptic feedback or updating UI state.
  final VoidCallback? onDragStart;

  /// Callback invoked when a drag operation ends successfully.
  ///
  /// Type: `VoidCallback?`. Called when the drag completes with a successful drop.
  /// This is called before the appropriate accept callback.
  final VoidCallback? onDragEnd;

  /// Callback invoked when a drag operation is cancelled.
  ///
  /// Type: `VoidCallback?`. Called when the drag is cancelled without a successful
  /// drop, such as when the user releases outside valid drop zones.
  final VoidCallback? onDragCancel;

  /// The main child widget that will be made sortable.
  ///
  /// Type: `Widget`. This widget is displayed normally and becomes draggable
  /// when drag interactions are initiated.
  final Widget child;

  /// The data associated with this sortable item.
  ///
  /// Type: `SortableData<T>`. Contains the actual data being sorted and provides
  /// identity for the drag-and-drop operations.
  final SortableData<T> data;

  /// Widget displayed in drop zones when this item is being dragged over them.
  ///
  /// Type: `Widget?`. If null, uses [SizedBox.shrink]. This creates visual
  /// space in potential drop locations, providing clear feedback about where
  /// the item will be placed if dropped.
  final Widget? placeholder;

  /// Widget displayed while dragging instead of the original child.
  ///
  /// Type: `Widget?`. If null, uses [child]. Typically a semi-transparent
  /// or styled version of the child to provide visual feedback during dragging.
  final Widget? ghost;

  /// Widget displayed in place of the child while it's being dragged.
  ///
  /// Type: `Widget?`. If null, the original child becomes invisible but maintains
  /// its space. Used to show an alternative representation at the original location.
  final Widget? fallback;

  /// Widget displayed when the item is a candidate for dropping.
  ///
  /// Type: `Widget?`. Shows alternative styling when the dragged item hovers
  /// over this sortable as a potential drop target.
  final Widget? candidateFallback;

  /// Whether drag interactions are enabled for this sortable.
  ///
  /// Type: `bool`, default: `true`. When false, the widget cannot be dragged
  /// and will not respond to drag gestures.
  final bool enabled;

  /// How hit-testing behaves for drag gesture recognition.
  ///
  /// Type: `HitTestBehavior`, default: `HitTestBehavior.deferToChild`.
  /// Controls how the gesture detector participates in hit testing.
  final HitTestBehavior behavior;

  /// Callback invoked when a drop operation fails.
  ///
  /// Type: `VoidCallback?`. Called when the user drops outside of any valid
  /// drop zones or when drop validation fails.
  final VoidCallback? onDropFailed;

  @override
  State<Sortable<T>> createState() => _SortableState<T>();
}

class _SortableDraggingSession<T> {
  _SortableDraggingSession({
    required this.data,
    required this.ghost,
    required this.layer,
    required this.layerRenderBox,
    required this.lock,
    required this.maxOffset,
    required this.minOffset,
    required Offset offset,
    required this.placeholder,
    required this.size,
    required this.target,
    required this.transform,
  }) : offset = ValueNotifier(offset);
  final key = GlobalKey();
  final Matrix4 transform;
  final Size size;
  final Widget ghost;
  final Widget placeholder;
  final SortableData<T> data;
  final ValueNotifier<Offset> offset;
  final _SortableLayerState layer;
  final RenderBox layerRenderBox;
  final Offset minOffset;
  final Offset maxOffset;
  final bool lock;
  final _SortableState<T> target;
}

enum _SortableDropLocation {
  bottom,
  left,
  right,
  top,
}

_SortableDropLocation? _getPosition(
  Offset position,
  Size size, {
  bool acceptBottom = false,
  bool acceptLeft = false,
  bool acceptRight = false,
  bool acceptTop = false,
}) {
  final dx = position.dx;
  final dy = position.dy;
  final width = size.width;
  final height = size.height;
  if (acceptTop && !acceptBottom) {
    return _SortableDropLocation.top;
  } else if (acceptBottom && !acceptTop) {
    return _SortableDropLocation.bottom;
  } else if (acceptLeft && !acceptRight) {
    return _SortableDropLocation.left;
  } else if (acceptRight && !acceptLeft) {
    return _SortableDropLocation.right;
  }
  if (acceptTop && dy <= height / 2) {
    return _SortableDropLocation.top;
  }
  if (acceptLeft && dx <= width / 2) {
    return _SortableDropLocation.left;
  }
  if (acceptRight && dx >= width / 2) {
    return _SortableDropLocation.right;
  }

  return acceptBottom && dy >= height / 2 ? _SortableDropLocation.bottom : null;
}

/// A fallback drop zone for sortable items when dropped outside specific sortable widgets.
///
/// SortableDropFallback provides a catch-all drop zone that can accept sortable
/// items when they're dropped outside of any specific sortable widget drop zones.
/// This is useful for implementing deletion zones, creation areas, or general
/// drop handling areas.
///
/// The widget wraps its child with an invisible hit test layer that can detect
/// and accept dropped sortable items based on configurable acceptance criteria.
///
/// Example:
/// ```dart
/// SortableDropFallback<String>(
///   canAccept: (data) => data.data.startsWith('temp_'),
///   onAccept: (data) => deleteItem(data.data),
///   child: Container(
///     height: 100,
///     child: Center(child: Text('Drop here to delete')),
///   ),
/// )
/// ```
class SortableDropFallback<T> extends StatefulWidget {
  /// Creates a [SortableDropFallback] drop zone.
  ///
  /// Configures a fallback drop zone that can accept sortable items dropped
  /// outside of specific sortable widget drop zones.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [child] (Widget, required): The widget that defines the drop zone area
  /// - [onAccept] (ValueChanged<SortableData<T>>?, optional): Handler for accepted drops
  /// - [canAccept] (Predicate<SortableData<T>>?, optional): Validation for drops
  ///
  /// Example:
  /// ```dart
  /// SortableDropFallback<String>(
  ///   canAccept: (data) => data.data.contains('removable'),
  ///   onAccept: (data) => removeFromList(data.data),
  ///   child: Icon(Icons.delete, size: 48),
  /// )
  /// ```
  const SortableDropFallback({
    this.canAccept,
    required this.child,
    super.key,
    this.onAccept,
  });

  /// Callback invoked when a sortable item is dropped on this fallback zone.
  ///
  /// Type: `ValueChanged<SortableData<T>>?`. Receives the dropped item's data
  /// and should handle the drop operation. Only called if [canAccept] validation
  /// passes or is null.
  final ValueChanged<SortableData<T>>? onAccept;

  /// Predicate to determine if dropped data can be accepted by this fallback zone.
  ///
  /// Type: `Predicate<SortableData<T>>?`. If null, all sortable items are accepted.
  /// Return true to accept the drop, false to reject it.
  final Predicate<SortableData<T>>? canAccept;

  /// The child widget that defines the drop zone area.
  ///
  /// Type: `Widget`. This widget's bounds determine the area where drops can
  /// be detected. The child is rendered normally with an invisible overlay
  /// for drop detection.
  final Widget child;

  @override
  State<SortableDropFallback<T>> createState() =>
      _SortableDropFallbackState<T>();
}

class _SortableDropFallbackState<T> extends State<SortableDropFallback<T>> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: MetaData(
            behavior: HitTestBehavior.translucent,
            metaData: this,
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _DroppingTarget<T> {
  const _DroppingTarget({
    required this.candidate,
    required this.location,
    required this.source,
  });

  final _SortableState<T> source;
  final ValueNotifier<_SortableDraggingSession<T>?> candidate;

  final _SortableDropLocation location;

  void dispose(_SortableDraggingSession<T> target) {
    if (candidate.value == target) {
      candidate.value = null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _DroppingTarget<T> &&
        other.source == source &&
        other.candidate == candidate &&
        other.location == location;
  }

  @override
  String toString() => '_DroppingTarget($source, $location)';

  @override
  int get hashCode => Object.hash(source, candidate, location);
}

class _DropTransform {
  _DropTransform({
    required this.child,
    required this.from,
    required this.state,
    required this.to,
  });
  final Matrix4 from;
  final Matrix4 to;
  final Widget child;

  final _SortableState state;

  Duration? start;

  final progress = ValueNotifier<double>(0);
}

class _SortableState<T> extends State<Sortable<T>>
    with AutomaticKeepAliveClientMixin {
  static Widget _buildAnimatedSize({
    AlignmentGeometry alignment = Alignment.center,
    Widget? child,
    required Duration duration,
    bool hasCandidate = false,
  }) {
    return !hasCandidate
        ? child!
        : AnimatedSize(
            alignment: alignment,
            duration: duration,
            child: child,
          );
  }

  final topCandidate = ValueNotifier<_SortableDraggingSession<T>?>(null);
  final leftCandidate = ValueNotifier<_SortableDraggingSession<T>?>(null);
  final rightCandidate = ValueNotifier<_SortableDraggingSession<T>?>(null);

  final bottomCandidate = ValueNotifier<_SortableDraggingSession<T>?>(null);
  final _currentTarget = ValueNotifier<_DroppingTarget<T>?>(null);
  final _currentFallback = ValueNotifier<_SortableDropFallbackState<T>?>(null);
  final _hasClaimedDrop = ValueNotifier<bool>(false);

  final _hasDraggedOff = ValueNotifier<bool>(false);

  final _key = GlobalKey();

  final _gestureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final layer = Data.maybeFind<_SortableLayerState>(context);
    if (layer != null) {
      final data = widget.data;
      if (layer._canClaimDrop(this, data)) {
        _hasClaimedDrop.value = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            layer._claimDrop(this, data);
          }
        });
      }
    }
  }

  (_SortableState<T>, Offset)? _findState(
    Offset globalPosition,
    _SortableLayerState target,
  ) {
    final result = BoxHitTestResult();
    final renderBox = target.context.findRenderObject()! as RenderBox;
    renderBox.hitTest(result, position: globalPosition);
    for (final entry in result.path) {
      if (entry.target is RenderMetaData) {
        final metaData = entry.target as RenderMetaData;
        if (metaData.metaData is _SortableState<T> &&
            metaData.metaData != this) {
          return (
            metaData.metaData as _SortableState<T>,
            (entry as BoxHitTestEntry).localPosition,
          );
        }
      }
    }

    return null;
  }

  _SortableDropFallbackState<T>? _findFallbackState(
    Offset globalPosition,
    _SortableLayerState target,
  ) {
    final result = BoxHitTestResult();
    final renderBox = target.context.findRenderObject()! as RenderBox;
    renderBox.hitTest(result, position: globalPosition);
    for (final entry in result.path) {
      if (entry.target is RenderMetaData) {
        final metaData = entry.target as RenderMetaData;
        if (metaData.metaData is _SortableDropFallbackState<T> &&
            metaData.metaData != this) {
          return metaData.metaData as _SortableDropFallbackState<T>;
        }
      }
    }

    return null;
  }

  void _onDragStart(DragStartDetails details) {
    if (_hasClaimedDrop.value) {
      return;
    }
    _hasDraggedOff.value = false;
    final layer = Data.maybeFind<_SortableLayerState>(context);
    assert(layer != null, 'Sortable must be a descendant of SortableLayer');
    final renderBox = context.findRenderObject()! as RenderBox;
    final layerRenderBox = layer!.context.findRenderObject()! as RenderBox;
    final transform = renderBox.getTransformTo(layerRenderBox);
    final size = renderBox.size;
    final minOffset = MatrixUtils.transformPoint(transform, Offset.zero);
    final maxOffset = MatrixUtils.transformPoint(
      transform,
      Offset(size.width, size.height),
    );
    final ghost = widget.ghost ?? widget.child;
    final candidateFallback = widget.candidateFallback;
    _session = _SortableDraggingSession(
      data: widget.data,
      ghost: ListenableBuilder(
        builder: (context, child) {
          return _currentTarget.value != null
              ? candidateFallback ?? widget.child
              : ghost;
        },
        listenable: _currentTarget,
      ),
      layer: layer,
      layerRenderBox: layerRenderBox,
      lock: layer.widget.lock,
      maxOffset: maxOffset,
      minOffset: minOffset,
      offset: Offset.zero,
      placeholder: widget.placeholder ?? widget.child,
      size: size,
      target: this,
      transform: transform,
    );
    layer.pushDraggingSession(_session!);
    widget.onDragStart?.call();
    setState(() {
      _dragging = true;
    });
    _scrollableLayer?._startDrag(details.globalPosition, this);
  }

  ValueNotifier<_SortableDraggingSession<T>?> _getByLocation(
    _SortableDropLocation location,
  ) {
    switch (location) {
      case _SortableDropLocation.top:
        return topCandidate;

      case _SortableDropLocation.left:
        return leftCandidate;

      case _SortableDropLocation.right:
        return rightCandidate;

      case _SortableDropLocation.bottom:
        return bottomCandidate;
    }
  }

  void _handleDrag(Offset delta) {
    final minOffset = _session!.minOffset;
    final maxOffset = _session!.maxOffset;
    if (_session != null) {
      final sessionRenderBox =
          _session!.layer.context.findRenderObject()! as RenderBox;
      final size = sessionRenderBox.size;
      if (_session!.lock) {
        final minX = -minOffset.dx;
        final maxX = size.width - maxOffset.dx;
        final minY = -minOffset.dy;
        final maxY = size.height - maxOffset.dy;
        _session!.offset.value = Offset(
          (_session!.offset.value.dx + delta.dx).clamp(
            min(minX, maxX),
            max(minX, maxX),
          ),
          (_session!.offset.value.dy + delta.dy).clamp(
            min(minY, maxY),
            max(minY, maxY),
          ),
        );
      } else {
        _session!.offset.value += delta;
      }
      final globalPosition =
          _session!.offset.value +
          minOffset +
          Offset(
            (maxOffset.dx - minOffset.dx) / 2,
            (maxOffset.dy - minOffset.dy) / 2,
          );
      final target = _findState(globalPosition, _session!.layer);
      if (target == null) {
        final fallback = _findFallbackState(globalPosition, _session!.layer);
        _currentFallback.value = fallback;
        if (_currentTarget.value != null && fallback == null) {
          _currentTarget.value!.dispose(_session!);
          _currentTarget.value = null;
        }
      } else {
        _hasDraggedOff.value = true;
        _currentFallback.value = null;
        if (_currentTarget.value != null) {
          _currentTarget.value!.dispose(_session!);
        }
        final targetRenderBox =
            target.$1.context.findRenderObject()! as RenderBox;
        final size = targetRenderBox.size;
        final location = _getPosition(
          target.$2,
          size,
          acceptBottom: widget.onAcceptBottom != null,
          acceptLeft: widget.onAcceptLeft != null,
          acceptRight: widget.onAcceptRight != null,
          acceptTop: widget.onAcceptTop != null,
        );
        if (location != null) {
          final candidate = target.$1._getByLocation(location);

          candidate.value = _session;
          _currentTarget.value = _DroppingTarget(
            candidate: candidate,
            location: location,
            source: target.$1,
          );
        }
      }
    }
  }

  ValueChanged<SortableData<T>>? _getCallback(_SortableDropLocation location) {
    switch (location) {
      case _SortableDropLocation.top:
        return widget.onAcceptTop;

      case _SortableDropLocation.left:
        return widget.onAcceptLeft;

      case _SortableDropLocation.right:
        return widget.onAcceptRight;

      case _SortableDropLocation.bottom:
        return widget.onAcceptBottom;
    }
  }

  Predicate<SortableData<T>>? _getPredicate(_SortableDropLocation location) {
    switch (location) {
      case _SortableDropLocation.top:
        return widget.canAcceptTop;

      case _SortableDropLocation.left:
        return widget.canAcceptLeft;

      case _SortableDropLocation.right:
        return widget.canAcceptRight;

      case _SortableDropLocation.bottom:
        return widget.canAcceptBottom;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_hasClaimedDrop.value) {
      return;
    }
    _handleDrag(details.delta);
    _scrollableLayer?._updateDrag(details.globalPosition, this);
  }

  void _onDragEnd(DragEndDetails details) {
    widget.onDragEnd?.call();
    if (_session != null) {
      if (_currentTarget.value != null) {
        _currentTarget.value!.dispose(_session!);
        final target = _currentTarget.value!.source;
        final location = _currentTarget.value!.location;
        final predicate = target._getPredicate(location);
        final sortData = _session!.data;
        if (predicate == null || predicate(sortData)) {
          final callback = target._getCallback(location);
          if (callback != null) {
            callback(sortData);
          }
        }
        _session!.layer.removeDraggingSession(_session!);
        _currentTarget.value = null;
      } else if (_hasDraggedOff.value) {
        final target = _currentFallback.value;
        if (target != null) {
          final sortData = _session!.data;
          if (target.widget.canAccept == null ||
              target.widget.canAccept!(sortData)) {
            target.widget.onAccept?.call(sortData);
          }
        }
        _session!.layer.removeDraggingSession(_session!);
        if (target == null) {
          _session!.layer._claimDrop(this, _session!.data, true);
        }
      } else {
        /// Basically the same as drag cancel, because the drag has not been dragged off of itself.
        _session!.layer.removeDraggingSession(_session!);
        widget.onDropFailed?.call();
        _session!.layer._claimDrop(this, _session!.data, true);
      }
      _claimUnchanged = true;
      _session = null;
    }
    setState(() {
      _dragging = false;
    });
    _scrollableLayer?._endDrag(this);
  }

  void _onDragCancel() {
    if (_session != null) {
      if (_currentTarget.value != null) {
        _currentTarget.value!.dispose(_session!);
        _currentTarget.value = null;
      }
      _session!.layer.removeDraggingSession(_session!);
      _session!.layer._claimDrop(this, _session!.data, true);
      _session = null;
    }
    setState(() {
      _dragging = false;
    });
    widget.onDragCancel?.call();
    _scrollableLayer?._endDrag(this);
  }

  bool _dragging = false;

  bool _claimUnchanged = false;

  _SortableDraggingSession<T>? _session;

  _ScrollableSortableLayerState? _scrollableLayer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollableLayer = Data.maybeOf<_ScrollableSortableLayerState>(context);
  }

  @override
  void didUpdateWidget(covariant Sortable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled && !widget.enabled && _dragging) {
      _onDragCancel();
    }
    if (widget.data != oldWidget.data || _claimUnchanged) {
      _claimUnchanged = false;
      final layer = Data.maybeFind<_SortableLayerState>(context);
      if (layer != null && layer._canClaimDrop(this, widget.data)) {
        _hasClaimedDrop.value = true;
        final data = widget.data;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            layer._claimDrop(this, data);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (_dragging) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollableLayer?._endDrag(this);
        _session!.layer.removeDraggingSession(_session!);
        _currentTarget.value = null;
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final layer = Data.of<_SortableLayerState>(context);

    return MetaData(
      behavior: HitTestBehavior.translucent,
      metaData: this,

      /// Must define the generic type to avoid type inference _SortableState<T>.
      child: Data<_SortableState>.inherit(
        data: this,
        child: ListenableBuilder(
          builder: (context, child) {
            final hasCandidate = layer._sessions.value.isNotEmpty;
            final container = GestureDetector(
              key: _gestureKey,
              behavior: widget.behavior,
              onPanCancel: widget.enabled ? _onDragCancel : null,
              onPanEnd: widget.enabled ? _onDragEnd : null,
              onPanStart: widget.enabled ? _onDragStart : null,
              onPanUpdate: widget.enabled ? _onDragUpdate : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AbsorbPointer(
                    child: _buildAnimatedSize(
                      alignment: Alignment.centerRight,
                      duration: kDefaultDuration,
                      hasCandidate: hasCandidate,
                      child: ListenableBuilder(
                        builder: (context, child) {
                          return leftCandidate.value != null
                              ? SizedBox.fromSize(
                                  size: leftCandidate.value!.size,
                                  child: leftCandidate.value!.placeholder,
                                )
                              : const SizedBox.shrink();
                        },
                        listenable: leftCandidate,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AbsorbPointer(
                          child: _buildAnimatedSize(
                            alignment: Alignment.bottomCenter,
                            duration: kDefaultDuration,
                            hasCandidate: hasCandidate,
                            child: ListenableBuilder(
                              builder: (context, child) {
                                return topCandidate.value != null
                                    ? SizedBox.fromSize(
                                        size: topCandidate.value!.size,
                                        child: topCandidate.value!.placeholder,
                                      )
                                    : const SizedBox.shrink();
                              },
                              listenable: topCandidate,
                            ),
                          ),
                        ),
                        Flexible(
                          child: _dragging
                              ? widget.fallback ??
                                    ListenableBuilder(
                                      builder: (context, child) {
                                        return (_hasDraggedOff.value
                                            ? AbsorbPointer(
                                                child: Visibility(
                                                  maintainState: true,
                                                  visible: false,
                                                  child: KeyedSubtree(
                                                    key: _key,
                                                    child: widget.child,
                                                  ),
                                                ),
                                              )
                                            : AbsorbPointer(
                                                child: Visibility(
                                                  maintainAnimation: true,
                                                  maintainSize: true,
                                                  maintainState: true,
                                                  visible: false,
                                                  child: KeyedSubtree(
                                                    key: _key,
                                                    child: widget.child,
                                                  ),
                                                ),
                                              ));
                                      },
                                      listenable: _hasDraggedOff,
                                    )
                              : ListenableBuilder(
                                  builder: (context, child) {
                                    return IgnorePointer(
                                      ignoring:
                                          hasCandidate || _hasClaimedDrop.value,
                                      child: Visibility(
                                        maintainAnimation: true,
                                        maintainSize: true,
                                        maintainState: true,
                                        visible: !_hasClaimedDrop.value,
                                        child: KeyedSubtree(
                                          key: _key,
                                          child: widget.child,
                                        ),
                                      ),
                                    );
                                  },
                                  listenable: _hasClaimedDrop,
                                ),
                        ),
                        AbsorbPointer(
                          child: _buildAnimatedSize(
                            alignment: Alignment.topCenter,
                            duration: kDefaultDuration,
                            hasCandidate: hasCandidate,
                            child: ListenableBuilder(
                              builder: (context, child) {
                                return bottomCandidate.value != null
                                    ? SizedBox.fromSize(
                                        size: bottomCandidate.value!.size,
                                        child:
                                            bottomCandidate.value!.placeholder,
                                      )
                                    : const SizedBox.shrink();
                              },
                              listenable: bottomCandidate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AbsorbPointer(
                    child: _buildAnimatedSize(
                      alignment: Alignment.centerLeft,
                      duration: kDefaultDuration,
                      hasCandidate: hasCandidate,
                      child: ListenableBuilder(
                        builder: (context, child) {
                          return rightCandidate.value != null
                              ? SizedBox.fromSize(
                                  size: rightCandidate.value!.size,
                                  child: rightCandidate.value!.placeholder,
                                )
                              : const SizedBox.shrink();
                        },
                        listenable: rightCandidate,
                      ),
                    ),
                  ),
                ],
              ),
            );

            return !hasCandidate
                ? container
                : AnimatedSize(duration: kDefaultDuration, child: container);
          },
          listenable: layer._sessions,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => _dragging;
}

/// A dedicated drag handle for initiating sortable drag operations.
///
/// SortableDragHandle provides a specific area within a sortable widget that
/// can be used to initiate drag operations. This is useful when you want to
/// restrict drag initiation to a specific handle area rather than the entire
/// sortable widget.
///
/// The handle automatically detects its parent Sortable widget and delegates
/// drag operations to it. It provides visual feedback with appropriate mouse
/// cursors and can be enabled/disabled independently.
///
/// Features:
/// - Dedicated drag initiation area within sortable widgets
/// - Automatic mouse cursor management (grab/grabbing states)
/// - Independent enable/disable control
/// - Automatic cleanup and lifecycle management
///
/// Example:
/// ```dart
/// Sortable<String>(
///   data: SortableData('item'),
///   child: Row(
///     children: [
///       SortableDragHandle(
///         child: Icon(Icons.drag_handle),
///       ),
///       Expanded(child: Text('Drag me by the handle')),
///     ],
///   ),
/// )
/// ```
class SortableDragHandle extends StatefulWidget {
  /// Creates a [SortableDragHandle] for initiating drag operations.
  ///
  /// Configures a dedicated drag handle that can initiate drag operations for
  /// its parent sortable widget. The handle provides visual feedback and can
  /// be independently enabled or disabled.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [child] (Widget, required): The widget that serves as the drag handle
  /// - [enabled] (bool, default: true): Whether drag operations are enabled
  /// - [behavior] (HitTestBehavior?, optional): Hit test behavior for gestures
  /// - [cursor] (MouseCursor?, optional): Mouse cursor when hovering
  ///
  /// Example:
  /// ```dart
  /// SortableDragHandle(
  ///   enabled: isDragEnabled,
  ///   cursor: SystemMouseCursors.move,
  ///   child: Container(
  ///     padding: EdgeInsets.all(8),
  ///     child: Icon(Icons.drag_indicator),
  ///   ),
  /// )
  /// ```
  const SortableDragHandle({
    this.behavior,
    required this.child,
    this.cursor,
    this.enabled = true,
    super.key,
  });

  /// The child widget that serves as the drag handle.
  ///
  /// Type: `Widget`. This widget defines the visual appearance of the drag handle
  /// and responds to drag gestures. Commonly an icon like Icons.drag_handle.
  final Widget child;

  /// Whether the drag handle is enabled for drag operations.
  ///
  /// Type: `bool`, default: `true`. When false, the handle will not respond to
  /// drag gestures and shows the default cursor instead of grab cursors.
  final bool enabled;

  /// How hit-testing behaves for this drag handle.
  ///
  /// Type: `HitTestBehavior?`. Controls how the gesture detector and mouse region
  /// participate in hit testing. If null, uses default behavior.
  final HitTestBehavior? behavior;

  /// The mouse cursor displayed when hovering over the drag handle.
  ///
  /// Type: `MouseCursor?`. If null, uses SystemMouseCursors.grab when enabled,
  /// or MouseCursor.defer when disabled. Changes to SystemMouseCursors.grabbing
  /// during active drag operations.
  final MouseCursor? cursor;

  @override
  State<SortableDragHandle> createState() => _SortableDragHandleState();
}

class _SortableDragHandleState extends State<SortableDragHandle>
    with AutomaticKeepAliveClientMixin {
  _SortableState? _state;

  bool _dragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = Data.maybeOf<_SortableState>(context);
  }

  @override
  bool get wantKeepAlive {
    return _dragging;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MouseRegion(
      cursor: widget.enabled
          ? (widget.cursor ?? SystemMouseCursors.grab)
          : MouseCursor.defer,
      hitTestBehavior: widget.behavior,
      child: GestureDetector(
        behavior: widget.behavior,
        onPanCancel: widget.enabled && _state != null
            ? () {
                _state!._onDragCancel();
                _dragging = false;
              }
            : null,
        onPanEnd: widget.enabled && _state != null
            ? (details) {
                _state!._onDragEnd(details);
                _dragging = false;
              }
            : null,
        onPanStart: widget.enabled && _state != null
            ? (details) {
                _dragging = true;
                _state!._onDragStart(details);
              }
            : null,
        onPanUpdate: widget.enabled && _state != null
            ? _state!._onDragUpdate
            : null,
        child: widget.child,
      ),
    );
  }
}

/// Immutable data wrapper for sortable items in drag-and-drop operations.
///
/// SortableData wraps the actual data being sorted and provides identity for
/// drag-and-drop operations. Each sortable item must have associated data that
/// uniquely identifies it within the sorting context.
///
/// The class is immutable and uses reference equality for comparison, ensuring
/// that each sortable item maintains its identity throughout drag operations.
/// This is crucial for proper drop validation and handling.
///
/// Type parameter [T] represents the type of data being sorted, which can be
/// any type including primitive types, custom objects, or complex data structures.
///
/// Example:
/// ```dart
/// // Simple string data
/// SortableData<String>('item_1')
///
/// // Complex object data
/// SortableData<TodoItem>(TodoItem(id: 1, title: 'Task 1'))
///
/// // Map data
/// SortableData<Map<String, dynamic>>({'id': 1, 'name': 'Item'})
/// ```
@immutable
class SortableData<T> {
  /// Creates a [SortableData] wrapper for the given data.
  ///
  /// Wraps the provided data in an immutable container that can be used with
  /// sortable widgets for drag-and-drop operations.
  ///
  /// Parameters:
  /// - [data] (T, required): The data to wrap for sorting operations
  ///
  /// Example:
  /// ```dart
  /// // Wrapping different data types
  /// SortableData('text_item')
  /// SortableData(42)
  /// SortableData(MyCustomObject(id: 1))
  /// ```
  const SortableData(this.data);

  /// The actual data being wrapped for sorting operations.
  ///
  /// Type: `T`. This is the data that will be passed to drop handlers and
  /// validation predicates. Can be any type that represents the sortable item.
  final T data;

  @override
  @nonVirtual
  bool operator ==(Object other) => super == other;

  @override
  String toString() => 'SortableData($data)';

  @override
  @nonVirtual
  int get hashCode => super.hashCode;
}

/// A layer widget that manages drag-and-drop sessions for sortable widgets.
///
/// SortableLayer is a required wrapper that coordinates drag-and-drop operations
/// between multiple sortable widgets. It provides the infrastructure for managing
/// drag sessions, rendering ghost elements during dragging, and handling drop
/// animations.
///
/// The layer maintains the drag state and provides a rendering context for ghost
/// widgets that follow the cursor during drag operations. It also manages drop
/// animations and cleanup when drag operations complete.
///
/// Features:
/// - Centralized drag session management across multiple sortable widgets
/// - Ghost widget rendering with cursor following during drag operations
/// - Configurable drop animations with custom duration and curves
/// - Boundary locking to constrain drag operations within the layer bounds
/// - Automatic cleanup and state management for drag sessions
///
/// All sortable widgets must be descendants of a SortableLayer to function properly.
/// The layer should be placed at a level that encompasses all related sortable widgets.
///
/// Example:
/// ```dart
/// SortableLayer(
///   lock: true, // Constrain dragging within bounds
///   dropDuration: Duration(milliseconds: 300),
///   dropCurve: Curves.easeOut,
///   child: Column(
///     children: [
///       Sortable(...),
///       Sortable(...),
///       Sortable(...),
///     ],
///   ),
/// )
/// ```
class SortableLayer extends StatefulWidget {
  /// Creates a [SortableLayer] to manage drag-and-drop operations.
  ///
  /// Configures the layer that coordinates drag sessions between sortable widgets
  /// and provides the rendering context for drag operations.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [child] (Widget, required): The widget tree containing sortable widgets
  /// - [lock] (bool, default: false): Whether to constrain dragging within bounds
  /// - [clipBehavior] (Clip?, optional): How to clip the layer content
  /// - [dropDuration] (Duration?, optional): Duration for drop animations
  /// - [dropCurve] (Curve?, optional): Curve for drop animation easing
  ///
  /// Example:
  /// ```dart
  /// SortableLayer(
  ///   lock: true,
  ///   dropDuration: Duration(milliseconds: 250),
  ///   dropCurve: Curves.easeInOutCubic,
  ///   child: ListView(
  ///     children: sortableItems.map((item) => Sortable(...)).toList(),
  ///   ),
  /// )
  /// ```
  const SortableLayer({
    required this.child,
    this.clipBehavior,
    this.dropCurve,
    this.dropDuration,
    super.key,
    this.lock = false,
  });

  /// Ensures a pending drop operation is completed and dismisses it.
  ///
  /// Finds the sortable layer in the widget tree and ensures that any pending
  /// drop operation for the specified data is completed and dismissed. This is
  /// useful for programmatically finalizing drop operations.
  ///
  /// Parameters:
  /// - [context] (BuildContext): The build context to find the layer from
  /// - [data] (Object): The data associated with the drop operation to dismiss
  ///
  /// Example:
  /// ```dart
  /// // After programmatic reordering
  /// SortableLayer.ensureAndDismissDrop(context, sortableData);
  /// ```
  static void ensureAndDismissDrop(BuildContext context, Object data) {
    final layer = Data.of<_SortableLayerState>(context);
    layer.ensureAndDismissDrop(data);
  }

  /// The child widget tree containing sortable widgets.
  ///
  /// Type: `Widget`. All sortable widgets must be descendants of this child
  /// tree to function properly with the layer.
  final Widget child;

  /// Whether to lock dragging within the layer's bounds.
  ///
  /// Type: `bool`, default: `false`. When true, dragged items cannot be moved
  /// outside the layer's visual bounds, providing spatial constraints.
  final bool lock;

  /// The clipping behavior for the layer.
  ///
  /// Type: `Clip?`. Controls how content is clipped. If null, uses Clip.hardEdge
  /// when [lock] is true, otherwise Clip.none.
  final Clip? clipBehavior;

  /// Duration for drop animations when drag operations complete.
  ///
  /// Type: `Duration?`. If null, uses the default duration. Set to Duration.zero
  /// to disable drop animations entirely.
  final Duration? dropDuration;

  /// Animation curve for drop transitions.
  ///
  /// Type: `Curve?`. If null, uses Curves.easeInOut. Controls the easing
  /// behavior of items animating to their final drop position.
  final Curve? dropCurve;

  @override
  State<SortableLayer> createState() => _SortableLayerState();
}

class _PendingDropTransform {
  const _PendingDropTransform({
    required this.child,
    required this.data,
    required this.from,
  });
  final Matrix4 from;
  final Widget child;

  final SortableData data;
}

class _SortableLayerState extends State<SortableLayer>
    with SingleTickerProviderStateMixin {
  static Matrix4 _tweenMatrix(Matrix4 from, double progress, Matrix4 to) {
    return Matrix4Tween(begin: from, end: to).transform(progress);
  }

  final _sessions = MutableNotifier<List<_SortableDraggingSession>>([]);

  final _activeDrops = MutableNotifier<List<_DropTransform>>([]);

  final _pendingDrop = ValueNotifier<_PendingDropTransform?>(null);

  Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void ensureAndDismissDrop(Object data) {
    if (_pendingDrop.value != null && data == _pendingDrop.value!.data) {
      _pendingDrop.value = null;
    }
  }

  void dismissDrop() {
    _pendingDrop.value = null;
  }

  bool _canClaimDrop(_SortableState item, Object? data) {
    return _pendingDrop.value != null && data == _pendingDrop.value!.data;
  }

  _DropTransform? _claimDrop(
    _SortableState item,
    SortableData data, [
    bool force = false,
  ]) {
    if (_pendingDrop.value != null &&
        (force || data == _pendingDrop.value!.data)) {
      final layerRenderBox = context.findRenderObject()! as RenderBox;
      final itemRenderBox = item.context.findRenderObject()! as RenderBox;
      final dropTransform = _DropTransform(
        from: _pendingDrop.value!.from,
        state: item,
        to: itemRenderBox.getTransformTo(layerRenderBox),
        child: _pendingDrop.value!.child,
      );
      _activeDrops.mutate((value) {
        value.add(dropTransform);
      });
      item._hasClaimedDrop.value = true;
      _pendingDrop.value = null;
      if (!_ticker.isActive) {
        _ticker.start();
      }

      return dropTransform;
    }

    return null;
  }

  void _tick(Duration elapsed) {
    final toRemove = <_DropTransform>[];
    for (final drop in _activeDrops.value) {
      drop.start ??= elapsed;
      double progress =
          ((elapsed - drop.start!).inMilliseconds /
                  (widget.dropDuration ?? kDefaultDuration).inMilliseconds)
              .clamp(0, 1).toDouble();
      progress = (widget.dropCurve ?? Curves.easeInOut).transform(progress.toDouble());
      if (progress >= 1 || !drop.state.mounted) {
        drop.state._hasClaimedDrop.value = false;
        toRemove.add(drop);
      } else {
        drop.progress.value = progress;
      }
    }
    _activeDrops.mutate((value) {
      value.removeWhere(toRemove.contains);
    });
    if (_activeDrops.value.isEmpty) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void pushDraggingSession(_SortableDraggingSession session) {
    _sessions.mutate((value) {
      value.add(session);
    });
  }

  void removeDraggingSession(_SortableDraggingSession session) {
    if (!mounted) {
      return;
    }
    if (_sessions.value.contains(session)) {
      _sessions.mutate((value) {
        value.remove(session);
      });
      if (widget.dropDuration != Duration.zero) {
        final ghostRenderBox =
            session.key.currentContext?.findRenderObject() as RenderBox?;
        if (ghostRenderBox != null) {
          final layerRenderBox = context.findRenderObject()! as RenderBox;
          _pendingDrop.value = _PendingDropTransform(
            data: session.data,
            from: ghostRenderBox.getTransformTo(layerRenderBox),
            child: SizedBox.fromSize(
              size: session.size,
              child: session.ghost,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MetaData(
      behavior: HitTestBehavior.translucent,
      metaData: this,
      child: Data.inherit(
        data: this,
        child: Stack(
          clipBehavior:
              widget.clipBehavior ?? (widget.lock ? Clip.hardEdge : Clip.none),
          fit: StackFit.passthrough,
          children: [
            widget.child,
            ListenableBuilder(
              builder: (context, child) {
                return Positioned.fill(
                  child: MouseRegion(
                    cursor: _sessions.value.isNotEmpty
                        ? SystemMouseCursors.grabbing
                        : MouseCursor.defer,
                    hitTestBehavior: HitTestBehavior.translucent,
                    opaque: false,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final session in _sessions.value)
                          ListenableBuilder(
                            builder: (context, child) {
                              return Positioned(
                                left: session.offset.value.dx,
                                top: session.offset.value.dy,
                                child: IgnorePointer(
                                  child: Transform(
                                    transform: session.transform,
                                    child: SizedBox.fromSize(
                                      key: session.key,
                                      size: session.size,
                                      child: session.ghost,
                                    ),
                                  ),
                                ),
                              );
                            },
                            listenable: session.offset,
                          ),
                      ],
                    ),
                  ),
                );
              },
              listenable: _sessions,
            ),
            ListenableBuilder(
              builder: (context, child) {
                return Positioned.fill(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final drop in _activeDrops.value)
                        ListenableBuilder(
                          builder: (context, child) {
                            return IgnorePointer(
                              child: Transform(
                                transform: _tweenMatrix(
                                  drop.from,
                                  drop.progress.value,
                                  drop.to,
                                ),
                                child: drop.child,
                              ),
                            );
                          },
                          listenable: drop.progress,
                        ),
                      child!,
                    ],
                  ),
                );
              },
              listenable: _activeDrops,
              child: ListenableBuilder(
                builder: (context, child) {
                  return _pendingDrop.value != null
                      ? IgnorePointer(
                          child: Transform(
                            transform: _pendingDrop.value!.from,
                            child: _pendingDrop.value!.child,
                          ),
                        )
                      : const SizedBox();
                },
                listenable: _pendingDrop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sortable layer that provides automatic scrolling during drag operations.
///
/// ScrollableSortableLayer extends the basic sortable functionality with automatic
/// scrolling when dragged items approach the edges of scrollable areas. This provides
/// a smooth user experience when dragging items in long lists or grids that extend
/// beyond the visible area.
///
/// The layer monitors drag positions and automatically scrolls the associated
/// scroll controller when the drag position comes within the configured threshold
/// of the scroll area edges. Scrolling speed is proportional to proximity to edges.
///
/// Features:
/// - Automatic scrolling when dragging near scroll area edges
/// - Configurable scroll threshold distance from edges
/// - Proportional scrolling speed based on proximity
/// - Optional overscroll support for scrolling beyond normal bounds
/// - Integrated with standard Flutter ScrollController
///
/// This layer should wrap scrollable widgets like ListView, GridView, or CustomScrollView
/// that contain sortable items. The scroll controller must be provided to enable
/// automatic scrolling functionality.
///
/// Example:
/// ```dart
/// ScrollController scrollController = ScrollController();
///
/// ScrollableSortableLayer(
///   controller: scrollController,
///   scrollThreshold: 80.0,
///   child: ListView.builder(
///     controller: scrollController,
///     itemBuilder: (context, index) => Sortable(...),
///   ),
/// )
/// ```
class ScrollableSortableLayer extends StatefulWidget {
  /// Creates a [ScrollableSortableLayer] with automatic scrolling support.
  ///
  /// Configures a sortable layer that provides automatic scrolling when dragged
  /// items approach the edges of the scrollable area.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [child] (Widget, required): The scrollable widget containing sortable items
  /// - [controller] (ScrollController, required): The scroll controller to manage
  /// - [scrollThreshold] (double, default: 50.0): Distance from edges for scroll trigger
  /// - [overscroll] (bool, default: false): Whether to allow overscroll behavior
  ///
  /// Example:
  /// ```dart
  /// final controller = ScrollController();
  ///
  /// ScrollableSortableLayer(
  ///   controller: controller,
  ///   scrollThreshold: 60.0,
  ///   overscroll: true,
  ///   child: ListView.builder(
  ///     controller: controller,
  ///     itemCount: items.length,
  ///     itemBuilder: (context, index) => Sortable<Item>(
  ///       data: SortableData(items[index]),
  ///       child: ItemWidget(items[index]),
  ///     ),
  ///   ),
  /// )
  /// ```
  const ScrollableSortableLayer({
    required this.child,
    required this.controller,
    super.key,
    this.scrollThreshold = 50,
  });

  /// The child widget containing sortable items within a scrollable area.
  ///
  /// Type: `Widget`. Typically a scrollable widget like ListView or GridView
  /// that contains sortable items and uses the same controller.
  final Widget child;

  /// The scroll controller that manages the scrollable area.
  ///
  /// Type: `ScrollController`. Must be the same controller used by the scrollable
  /// widget in the child tree. This allows the layer to control scrolling during
  /// drag operations.
  final ScrollController controller;

  /// Distance from scroll area edges that triggers automatic scrolling.
  ///
  /// Type: `double`, default: `50.0`. When a dragged item comes within this
  /// distance of the top or bottom edge (for vertical scrolling), automatic
  /// scrolling begins. Larger values provide earlier scroll activation.
  final double scrollThreshold;

  @override
  State<ScrollableSortableLayer> createState() =>
      _ScrollableSortableLayerState();
}

class _ScrollableSortableLayerState extends State<ScrollableSortableLayer>
    with SingleTickerProviderStateMixin {
  Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_scroll);
  }

  void _scroll(Duration elapsed) {
    Offset? position = _globalPosition;
    if (position != null && _lastElapsed != null) {
      final renderBox = context.findRenderObject()! as RenderBox;
      position = renderBox.globalToLocal(position);
      final delta = elapsed.inMicroseconds - _lastElapsed!.inMicroseconds;
      double scrollDelta = 0;
      final pos = widget.controller.position.axisDirection == AxisDirection.down
          ? position.dy
          : position.dx;
      final size =
          widget.controller.position.axisDirection == AxisDirection.down
          ? renderBox.size.height
          : renderBox.size.width;
      if (pos < widget.scrollThreshold) {
        scrollDelta = -delta / 10000;
      } else if (pos > size - widget.scrollThreshold) {
        scrollDelta = delta / 10000;
      }
      for (final pos in widget.controller.positions) {
        pos.pointerScroll(scrollDelta);
      }
      _attached?._handleDrag(Offset.zero);
    }
    _lastElapsed = elapsed;
  }

  void _startDrag(Offset globalPosition, _SortableState state) {
    if (_attached != null && _attached!.context.mounted) {
      return;
    }
    _attached = state;
    _globalPosition = globalPosition;
    if (!ticker.isActive) {
      ticker.start();
    }
  }

  void _updateDrag(Offset globalPosition, _SortableState state) {
    if (state != _attached) {
      return;
    }
    _globalPosition = globalPosition;
  }

  void _endDrag(_SortableState state) {
    if (state != _attached) {
      return;
    }
    if (ticker.isActive) {
      ticker.stop();
    }
    _globalPosition = null;
    _attached = null;
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  _SortableState? _attached;

  Offset? _globalPosition;

  Duration? _lastElapsed;

  @override
  Widget build(BuildContext context) {
    return Data.inherit(data: this, child: widget.child);
  }
}
