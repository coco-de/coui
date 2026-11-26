import 'package:coui_flutter/coui_flutter.dart';
// The key-event types sit outside the barrel's curated re-export surface.
import 'package:flutter/services.dart'
    show KeyEvent, KeyRepeatEvent, KeyUpEvent, LogicalKeyboardKey;

/// Builder function for creating sortable items in Flutter.
///
/// Parameters:
/// - [context]: Build context.
/// - [index]: Item index.
/// - [dragHandle]: A pre-built drag handle widget that starts a drag.
/// - [removeButton]: A pre-built remove button widget (null if not removable).
typedef SortableItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      Widget dragHandle,
      Widget? removeButton,
    );

/// Unified cross-platform sortable list with token-based rendering.
///
/// Drag a handle to reorder items. Other items animate out of the way
/// in real time as the dragged item moves past them. Both platforms run
/// the same `coui_core` engine (collision detection + sortable math +
/// live displacement), so Flutter and Web reorder identically.
///
/// The handle is also the keyboard's way in: it takes focus, Space or
/// Enter picks the item up, the arrow keys (and Home / End) move it one
/// position at a time, Space or Enter drops it and Escape puts it back.
/// Every step is announced with the item's position, and a drop calls
/// [onReorder] with the same `(oldIndex, newIndex)` a pointer drag would.
///
/// Example:
/// ```dart
/// Sortable(
///   itemCount: items.length,
///   onReorder: (oldIndex, newIndex) {
///     setState(() {
///       final item = items.removeAt(oldIndex);
///       items.insert(newIndex, item);
///     });
///   },
///   itemBuilder: (context, index, dragHandle, removeButton) {
///     return Row(
///       children: [
///         dragHandle,
///         Expanded(child: Text(items[index])),
///         if (removeButton != null) removeButton,
///       ],
///     );
///   },
/// )
/// ```
///
/// surface:behind — each row paints its own box directly rather than
/// composing `OutlinedContainer`, so what shows through it is the page
/// it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class Sortable extends StatefulWidget
    implements
        CoreSortableContract<
          Widget,
          Widget Function(
            BuildContext context,
            int index,
            Widget dragHandle,
            Widget? removeButton,
          )
        > {
  /// Creates a [Sortable].
  const Sortable({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.axis = CoreSortableContract.defaultAxis,
    this.onReorder,
    this.onRemove,
    this.enabled = true,
    this.removable = false,
    this.sortableStyle,
  });

  @override
  final int itemCount;

  @override
  final CoreSortableAxis axis;

  @override
  final SortableItemBuilder itemBuilder;

  @override
  final CoreSortableReorderCallback? onReorder;

  @override
  final CoreSortableRemoveCallback? onRemove;

  @override
  final bool enabled;

  @override
  final bool removable;

  @override
  final CoreSortableStyle? sortableStyle;

  /// Returns a copy of this [Sortable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Sortable copyWith({
    Key? key,
    int? itemCount,
    SortableItemBuilder? itemBuilder,
    CoreSortableAxis? axis,
    CoreSortableReorderCallback? onReorder,
    CoreSortableRemoveCallback? onRemove,
    bool? enabled,
    bool? removable,
    CoreSortableStyle? sortableStyle,
  }) {
    return Sortable(
      key: key ?? this.key,
      itemCount: itemCount ?? this.itemCount,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      axis: axis ?? this.axis,
      onReorder: onReorder ?? this.onReorder,
      onRemove: onRemove ?? this.onRemove,
      enabled: enabled ?? this.enabled,
      removable: removable ?? this.removable,
      sortableStyle: sortableStyle ?? this.sortableStyle,
    );
  }

  @override
  State<Sortable> createState() => _SortableState();
}

class _SortableState extends State<Sortable> {
  int? _hoveredIndex;

  /// Whether an ambient [Overlay] exists to lift the dragged row into.
  ///
  /// [DragOverlay] no-ops when there is none, so this decides between
  /// emptying the row's slot and keeping the in-tree lift: getting it wrong
  /// in the absent case would make the dragged row disappear outright.
  bool get _liftsToOverlay => Overlay.maybeOf(context) != null;

  /// True while the engine runs a drag session — hover recolour is
  /// suppressed so displaced rows sliding under the pointer do not flash
  /// their hover tint mid-drag.
  bool _dragging = false;

  /// True for the commit frame: the reorder just landed, so displaced rows
  /// snap (rather than animate) back to zero while the list re-renders in
  /// its new order — otherwise the reset transform and the content swap
  /// would double-animate. Mirrors the Web twin's commit-frame transition
  /// suppression.
  bool _committing = false;

  /// The engine runtime — owned here so the hover gate can watch drag
  /// lifecycle transitions and the list can read live reorder maths.
  /// A single-axis list locks that axis in the engine rather than each
  /// render site dropping the sideways component by hand. A grid locks
  /// nothing — both axes carry meaning there.
  late final DragScopeController _dragController = DragScopeController(
    modifiers: switch (widget.axis) {
      .vertical => [
        CoreDragModifiers.restrictToVerticalAxis,
      ],
      .horizontal => [
        CoreDragModifiers.restrictToHorizontalAxis,
      ],
      .grid => const [],
    },
  );

  /// The reorder the live drag would commit, recomputed per engine tick.
  CoreSortableResolution _resolution = .none;

  /// The keyboard reorder — drives the same engine as the pointer, one
  /// position per key.
  final CoreSortableKeyboard _keyboard = CoreSortableKeyboard();

  /// One focus node per position, so the handle that keeps focus across a
  /// move is the one at the position the item landed on.
  List<FocusNode> _handleFocusNodes = const [];

  /// The handle that holds keyboard focus, for its focus ring.
  int? _focusedHandleIndex;

  @override
  void initState() {
    super.initState();
    _dragController
      ..describeAnnouncement = handleDescribeAnnouncement
      ..addListener(handleEngineUpdate);
    _syncPerPosition();
  }

  @override
  void didUpdateWidget(Sortable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) _syncPerPosition();
  }

  /// Grows or shrinks the per-position focus nodes to the current item
  /// count, keeping the ones that still have a row.
  void _syncPerPosition() {
    final count = widget.itemCount;
    for (var i = count; i < _handleFocusNodes.length; i++) {
      _handleFocusNodes[i].dispose();
    }
    _handleFocusNodes = [
      for (var i = 0; i < count; i++)
        if (i < _handleFocusNodes.length)
          _handleFocusNodes[i]
        else
          FocusNode(debugLabel: 'Sortable handle $i'),
    ];
    if ((_focusedHandleIndex ?? 0) >= count) _focusedHandleIndex = null;
  }

  /// Whether the list reorders at all — the same gate the engine path uses.
  bool get _canReorder => widget.enabled && widget.onReorder != null;

  /// The reorder [session] currently describes.
  CoreSortableResolution _resolveFor(CoreDragSession session) =>
      CoreSortable.resolve(
        activeId: session.activeId,
        itemIds: _itemIds,
        itemRects: _dragController.registry.itemRects,
        transform: session.transform,
        axis: widget.axis,
      );

  /// Wraps the user-provided item content with the background / border chrome,
  /// plus hover tint + drag handle.
  ///
  /// [interactive] is false for the floating copy a drag lifts into the
  /// overlay: it draws the same handle but must not claim the handle's
  /// focus node, which the row still in the list owns.
  Widget _buildItemShell(
    BuildContext context,
    int index,
    ResolvedSortable resolved, {
    bool interactive = true,
  }) {
    final dragHandle = _buildDragHandle(
      index,
      resolved,
      interactive: interactive && _canReorder,
    );

    final removeButton = widget.removable && widget.onRemove != null
        ? _buildRemoveButton(index, resolved)
        : null;

    final content = widget.itemBuilder(
      context,
      index,
      dragHandle,
      removeButton,
    );

    final borderRadius = resolved.itemBorderRadius;

    // State select — a disabled list wears the dedicated disabled fill and
    // border; an enabled one hovers to the hover fill.
    final isHovered = _hoveredIndex == index && widget.enabled && !_dragging;
    final effectiveBg = !widget.enabled
        ? resolved.disabledItemBackgroundColor
        : isHovered
        ? resolved.itemHoverColor
        : resolved.itemBackgroundColor;
    final effectiveBorderColor = widget.enabled
        ? resolved.itemBorderColor
        : resolved.disabledItemBorderColor;

    return MouseRegion(
      onEnter: widget.enabled
          ? (_) {
              if (!_dragging) setState(() => _hoveredIndex = index);
            }
          : null,
      onExit: widget.enabled
          ? (_) => setState(() => _hoveredIndex = null)
          : null,
      // `SurfaceBlur` sits inside the hover target rather than around it
      // — a no-op when the item paints no fill (transparent override) or
      // the active style states no material.
      child: SurfaceBlur(
        borderRadius: borderRadius,
        surfaceBlur: resolved.surfaceBlur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        refraction: Theme.of(context).surfaceRefraction,
        child: AnimatedContainer(
          padding: resolved.itemPadding,
          // The row is a floor, not a fixed height, and its content sits on
          // the cross-axis centre of it (the Web twin's `items-center`).
          constraints: BoxConstraints(minHeight: resolved.itemMinHeight),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: borderRadius,
            border: Border.all(
              color: effectiveBorderColor,
              width: resolved.itemBorderWidth,
            ),
          ),
          duration: resolved.animationDuration,
          curve: resolved.curve,
          child: DefaultTextStyle.merge(
            style: widget.enabled
                ? resolved.itemTextStyle
                : resolved.disabledItemTextStyle,
            child: content,
          ),
        ),
      ),
    );
  }

  /// Decorates the lifted (active) row with a subtle scale + shadow, ramped
  /// in over the drag-start curve.
  Widget _buildActiveProxy(Widget child, ResolvedSortable resolved) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: resolved.animationDuration,
      curve: CoreEasing.enter.toValue(),
      builder: (context, t, _) {
        final scale = 1.0 + (resolved.proxyScale - 1.0) * t;
        // Drag-proxy lift: a CoUI BoxShadow drop (no Material elevation) sized
        // by `proxyElevation`, mirroring the Web `composeSortableItem`
        // `box-shadow: 0 {e}rem {e*2}rem rgba(0,0,0, opacity20)`.
        final elevation = resolved.proxyElevation * t;
        final shadows = [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, CoreOpacity.opacity20),
            offset: Offset(0, elevation),
            blurRadius: elevation * 2,
          ),
        ];
        // The style's rim on the lifted row, inside the scale so it rides
        // the lift with the row. Not ramped with the cast: the Web twin
        // puts both on the drag source in a single frame, and the rim is
        // the material of the row rather than part of the lift.
        final scaled = Transform.scale(
          scale: scale,
          child: InsetShadow(
            shadows: resolved.proxyInsetShadow,
            radius: resolved.itemBorderRadius,
            child: child,
          ),
        );
        // The lifted item's own fill can only turn translucent under a
        // style that actually folds `surfaceOpacity` into it (glass) —
        // every non-glass preset leaves [ResolvedSortable.surfaceOpacity]
        // null, and an opaque-in-every-state fill cannot tell
        // `BoxDecoration.boxShadow` apart from `InjectedCast` (its own
        // doc comment says so). So the shadow only moves off the
        // decoration and onto `InjectedCast` (which knocks the box out of
        // the shadow the way CSS does —
        // `core/theme-axis-composition.md` — "그림자는 두 플랫폼이 다른
        // 곳에 칠한다") when translucency is actually possible.
        if (resolved.surfaceOpacity == null) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: resolved.itemBorderRadius,
              boxShadow: shadows,
            ),
            child: scaled,
          );
        }
        return InjectedCast(
          shadows: shadows,
          borderRadius: resolved.itemBorderRadius,
          child: scaled,
        );
      },
    );
  }

  Widget _buildDragHandle(
    int index,
    ResolvedSortable resolved, {
    required bool interactive,
  }) {
    final grip = _buildGrip(resolved);
    if (!interactive) return grip;

    // The pointer grabs through `DragHandle`; the keyboard reaches the
    // same drag through this focus node. Naming the handle is what makes
    // it a control a screen reader can find — an icon alone reads as
    // nothing — and the hint says how to operate it.
    final l10n = CoUILocalizations.of(context);

    // A node of its own: without the boundary the name would merge into
    // the row and be read as part of the item's text, and the focus the
    // keyboard lands on would have no name of its own.
    return DragHandle(
      child: Semantics(
        container: true,
        label: l10n.sortableHandleLabel(
          CoreSortableKeyboard.positionOf(index),
          widget.itemCount,
        ),
        hint: l10n.sortableHandleHint,
        child: Focus(
          focusNode: _handleFocusNodes[index],
          onKeyEvent: (_, event) => handleHandleKey(index, event),
          onFocusChange: (focused) =>
              handleHandleFocusChange(index, focused: focused),
          child: FocusOutline(
            focused: _focusedHandleIndex == index,
            focusOutlineStyle: resolved.handleFocusOutlineStyle,
            child: grip,
          ),
        ),
      ),
    );
  }

  Widget _buildGrip(ResolvedSortable resolved) {
    // The handle is a drag affordance (wrapped by DragHandle so the
    // engine only activates drags from it), not a hover-recolour target —
    // only the cursor changes. The per-state icon style (enabled vs
    // 50%-dimmed) is resolved upstream, so the widget selects a
    // `CoreIconStyle` and never computes a raw `Color`.
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.grab
          : SystemMouseCursors.basic,
      child: Padding(
        padding: resolved.handlePadding,
        child: Icon(
          LucideIcons.gripVertical,
          iconStyle: widget.enabled
              ? resolved.handleIconStyle
              : resolved.handleDisabledIconStyle,
        ),
      ),
    );
  }

  Widget _buildRemoveButton(int index, ResolvedSortable resolved) {
    // Icon-only, and the button is built here rather than by the caller —
    // `itemBuilder` receives it already assembled, so a consumer has no place
    // to attach a name. Without this it reads as an unnamed "button".
    //
    // The unified `Button(variant: .plain, size: .sm, shape: .square)`: the
    // `plain` variant owns the quiet idle content and the hover, `square`
    // the equal sides, and `resolved.removeButtonStyle` (raw-forward)
    // supplies the 32-px side / corner / foreground. The glyph is an `Icon`
    // child (size from the slot's `leadingIconStyle`; colour null so it
    // inherits the button's foreground).
    return Semantics(
      button: true,
      label: CoUILocalizations.of(context).dismissLabel,
      child: Button(
        onPressed: () => widget.onRemove?.call(index),
        variant: .plain,
        size: .sm,
        shape: .square,
        buttonStyle: widget.enabled
            ? resolved.removeButtonStyle
            : resolved.disabledRemoveButtonStyle,
        child: Icon(
          LucideIcons.x,
          iconStyle: resolved.removeButtonStyle.leadingIconStyle,
        ),
      ),
    );
  }

  /// Wraps a shell as an engine sortable item: the active row follows the
  /// drag transform (main axis only) under the lifted-proxy chrome, and
  /// sibling rows animate along their engine-computed displacement.
  Widget _buildEngineItem(
    BuildContext context,
    int index,
    ResolvedSortable resolved,
  ) {
    final id = CoreDragId('$index');
    final shell = _buildItemShell(context, index, resolved);
    final displacement = _resolution.displacements[id] ?? .zero;
    final isActive = _dragController.activeId == id;

    // A `Column` paints its children in order, so a row dragged *downwards*
    // is drawn before — and therefore under — every sibling it passes.
    // Lifting the copy into the ambient `Overlay` takes it out of that
    // ordering entirely; the slot it left keeps its size so nothing below
    // it shifts, and stays invisible so the row is not drawn twice.
    final content = isActive && _liftsToOverlay
        ? Opacity(opacity: 0, child: shell)
        // Without an `Overlay` the copy has nowhere to go, and `DragOverlay`
        // fails quiet — emptying the slot would make the dragged row vanish.
        // Keep the in-tree lift instead: still occluded going down, but
        // present.
        : isActive
        ? Transform.translate(
            offset: Offset(
              _dragController.transformOf(id).x,
              _dragController.transformOf(id).y,
            ),
            child: _buildActiveProxy(shell, resolved),
          )
        : AnimatedContainer(
            transform: Matrix4.translationValues(
              displacement.x,
              displacement.y,
              0,
            ),
            curve: CoreEasing.move.toValue(),
            duration: _committing ? .zero : resolved.animationDuration,
            child: shell,
          );

    // `DragItem` stays the outermost node so lifting a row never changes
    // the tree *above* it: a wrapper swapped in mid-drag would remount the
    // item, and its `dispose` would cancel the very session it is running.
    return DragItem(
      id: id,
      // The handle owns the keyboard path — one position per key, with the
      // position announced — so the row is not a second, pixel-stepping tab
      // stop in front of it.
      keyboardDraggable: false,
      onDragEnd: handleDragEnd,
      onDragCancel: handleDragCancel,
      child: content,
    );
  }

  /// Binds the overlay copy to a context taken from inside the scope.
  ///
  /// The context the overlay hands its builder sits above both the measured
  /// row geometry and the theme, so it can answer neither; this closes over
  /// the one the [Builder] provides instead.
  Widget Function(BuildContext) handleScopedOverlayBuild(
    ResolvedSortable resolved,
  ) =>
      (scopeContext) => DragOverlay(
        // The overlay's own context is the wrong end of the tree; reaching the
        // scoped one is the entire purpose of this indirection.
        builder: (_, session) =>
            _buildOverlayRow(scopeContext, session, resolved),
      );

  /// The floating copy of the row being dragged.
  ///
  /// Rendered inside the ambient [Overlay], where constraints are unbounded
  /// — so the width the row had in the list is restated here, otherwise a
  /// row that fills its container would size to its content. That width
  /// comes from the geometry the engine already measured; reading it off
  /// the laid-out list would mean asking a render object for its size
  /// mid-build, which is not allowed.
  Widget _buildOverlayRow(
    BuildContext context,
    CoreDragSession session,
    ResolvedSortable resolved,
  ) {
    final index = int.tryParse(session.activeId.value);
    final rect = DragScope.maybeOf(
      context,
    )?.registry.itemRects[session.activeId];
    if (index == null || index >= widget.itemCount || rect == null) {
      return const SizedBox.shrink();
    }

    // The `Overlay` sits above whatever installed the theme, so the copy
    // would build without one and the row's own `Icon` would assert. Rebind
    // from inside the list: the copy has to resolve the same tokens as the
    // row it stands in for, including after a live theme switch.
    return Theme(
      data: Theme.of(context),
      child: SizedBox(
        width: rect.width,
        child: _buildActiveProxy(
          _buildItemShell(context, index, resolved, interactive: false),
          resolved,
        ),
      ),
    );
  }

  /// Arranges [children] along the configured axis.
  ///
  /// The vertical stack hugs its content down the main axis but *fills*
  /// the cross axis — `stretch` is what makes every row span the parent
  /// width, mirroring the `w-full` the Web twin emits on both its list
  /// container and its `.vertical` rows. That width is load-bearing
  /// rather than decorative: a row is the drop target, so a
  /// content-width row would tie the hit area to the label it happens to
  /// hold and leave rows of differing widths in what should read as one
  /// reorder lane.
  ///
  /// `.horizontal` (`Row`) and `.grid` (`Wrap`) do not stretch their
  /// children — each item keeps its own content width, matching the Web
  /// twin's rows on those axes (see `buildItemClassName` in
  /// `sortable_style.dart`). An item on those axes is one of several
  /// sharing the main axis, not the only thing occupying it, so there is
  /// no "container width" for it to fill.
  Widget _layout(ResolvedSortable resolved, List<Widget> children) =>
      switch (widget.axis) {
        .vertical => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: resolved.itemSpacing,
          children: children,
        ),
        .horizontal => Row(
          mainAxisSize: .min,
          spacing: resolved.itemSpacing,
          children: children,
        ),
        .grid => Wrap(
          spacing: resolved.itemSpacing,
          runSpacing: resolved.itemSpacing,
          children: children,
        ),
      };

  @override
  void dispose() {
    _dragController
      ..describeAnnouncement = null
      ..removeListener(handleEngineUpdate)
      ..dispose();
    for (final node in _handleFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// The key a keyboard reorder understands, or `null` for any other key.
  static CoreSortableKey? _sortableKeyOf(LogicalKeyboardKey key) =>
      switch (key) {
        .space || .enter || .numpadEnter => .activate,
        .escape => .cancel,
        .arrowUp => .up,
        .arrowDown => .down,
        .arrowLeft => .left,
        .arrowRight => .right,
        .home => .first,
        .end => .last,
        _ => null,
      };

  /// Routes a key pressed on the handle at [index] into the keyboard
  /// reorder, and speaks a move the engine has no transition for.
  KeyEventResult handleHandleKey(int index, KeyEvent event) {
    if (event is KeyUpEvent) return .ignored;
    final key = _sortableKeyOf(event.logicalKey);
    if (key == null) return .ignored;
    // A held Space would pick up and drop on alternate repeats.
    if (key == .activate && event is KeyRepeatEvent) return .handled;

    final result = _keyboard.handleKey(
      key,
      index: index,
      runtime: _dragController.runtime,
      itemIds: _itemIds,
      axis: widget.axis,
    );
    final announcement = result.announcement;
    if (announcement != null) {
      _dragController.announce(_sentenceFor(announcement));
    }

    return result.handled ? .handled : .ignored;
  }

  /// Tracks the focused handle for its ring, and abandons a keyboard move
  /// whose handle lost focus — the item cannot stay carried by a key the
  /// user is no longer pressing into this list.
  void handleHandleFocusChange(int index, {required bool focused}) {
    if (!mounted) return;
    if (!focused && _keyboard.isActive && _keyboard.fromIndex == index) {
      _dragController.runtime.cancel(reason: .dismissed);
    }
    setState(() {
      if (focused) {
        _focusedHandleIndex = index;
      } else if (_focusedHandleIndex == index) {
        _focusedHandleIndex = null;
      }
    });
  }

  /// The fuller sentence for an engine transition during a keyboard move.
  String? handleDescribeAnnouncement(CoreDragAnnouncement announcement) {
    if (!mounted) return null;
    final described = _keyboard.describe(announcement);

    return described == null ? null : _sentenceFor(described);
  }

  String _sentenceFor(CoreSortableAnnouncement announcement) {
    final l10n = CoUILocalizations.of(context);
    final position = announcement.position;
    final count = announcement.count;

    return switch (announcement.kind) {
      .pickedUp => l10n.sortableAnnouncePickedUp(position, count),
      .moved => l10n.sortableAnnounceMoved(position, count),
      .dropped => l10n.sortableAnnounceDropped(position, count),
      .cancelled => l10n.sortableAnnounceCancelled(position, count),
    };
  }

  /// Forgets a keyboard move the engine ended without a key from here —
  /// the item was removed, or focus left the handle.
  void handleDragCancel(CoreDragCancelEvent event) => _keyboard.release();

  /// Recomputes the live reorder on every engine tick.
  ///
  /// Resolving landing index and sibling displacement in one call is what
  /// keeps the preview honest: the row the user sees open up is the slot
  /// the drop commits to, because both read the same resolution.
  void handleEngineUpdate() {
    final session = _dragController.session;
    final dragging = session != null;
    final resolution = session == null
        ? CoreSortableResolution.none
        : _resolveFor(session);

    if (dragging == _dragging && resolution == _resolution) return;

    final started = dragging != _dragging;
    setState(() {
      _dragging = dragging;
      _resolution = resolution;
      // A row under the cursor when the drag begins is no longer "hovered"
      // — the pointer now belongs to the drag, not to that row.
      if (started) _hoveredIndex = null;
    });
  }

  List<CoreDragId> get _itemIds => [
    for (var i = 0; i < widget.itemCount; i++) CoreDragId('$i'),
  ];

  /// Commits the reorder the drag previewed, if it moved anything.
  void handleDragEnd(CoreDragEndEvent event) {
    // Resolve from the session the drop ended with rather than the cached
    // preview: the engine goes idle before it reports the end, which has
    // already cleared that cache. Same function over the same rects and
    // transform, so the commit still matches what the preview showed.
    final resolution = _resolveFor(event.session);
    if (!resolution.moves) return;

    // The rows are positional, so after the parent reorders its data the
    // item the keyboard carried sits under the handle at its new position.
    // Focus follows it there, or the next arrow would move a different item.
    if (event.session.inputKind == .keyboard) {
      final landed = resolution.toIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || landed >= _handleFocusNodes.length) return;
        _handleFocusNodes[landed].requestFocus();
      });
    }

    setState(() {
      _committing = true;
      _hoveredIndex = null;
      _resolution = .none;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _committing = false);
    });
    widget.onReorder?.call(resolution.fromIndex, resolution.toIndex);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSortable(
      context,
      sortableStyle: widget.sortableStyle,
    );

    if (!widget.enabled || widget.onReorder == null) {
      // Non-interactive path: plain layout with native spacing.
      return _layout(resolved, [
        for (int i = 0; i < widget.itemCount; i++)
          _buildItemShell(context, i, resolved),
      ]);
    }

    return DragScope(
      controller: _dragController,
      // `DragOverlay` draws nothing inline (it returns a shrunk box and
      // paints through the ambient `Overlay`), so it cannot be a child of
      // the layout itself — `spacing` would open a gap around it. The
      // stack passes its constraints straight through, leaving the row
      // width contract the layout depends on intact.
      child: Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: [
          _layout(resolved, [
            for (int i = 0; i < widget.itemCount; i++)
              _buildEngineItem(context, i, resolved),
          ]),
          // The copy is built from a context *inside* the scope: that is
          // where the measured row geometry and the theme live. The one the
          // overlay hands back sits above both, so it answers neither.
          Builder(
            builder: handleScopedOverlayBuild(resolved),
          ),
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSortableStyle] patch into
/// [Sortable.sortableStyle] without hand-reconstructing every field.
/// Mirrors the Web `Sortable.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSortableStyle.merge` right-side-wins semantics).
extension SortableStyleChain on Sortable {
  /// Returns a copy of this [Sortable] with [patch] merged into
  /// [sortableStyle] (patch fields win on conflict).
  Sortable withStyle(CoreSortableStyle patch) => copyWith(
    sortableStyle: (sortableStyle ?? const CoreSortableStyle()).merge(patch),
  );
}
