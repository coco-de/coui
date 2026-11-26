import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/form/sortable/sortable_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/drag_item/drag_item.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Builder function for creating sortable items in Web.
///
/// Parameters:
/// - [index]: Item index.
/// - [dragHandle]: A pre-built drag handle component.
/// - [removeButton]: A pre-built remove button component (null if not removable).
typedef SortableItemBuilder =
    Component Function(
      int index,
      Component dragHandle,
      Component? removeButton,
    );

/// Counter for generating unique root IDs.
int _coSortableIdCounter = 0;

/// How long the commit-frame transition suppression holds before the
/// reorder transitions come back. Not a design token — a technical
/// two-frame bound so the browser paints the reset transforms before
/// transitions re-enable.
const _kTransitionRestoreDelay = Duration(milliseconds: 50);

/// Unified cross-platform sortable list with token-based rendering (Web).
///
/// Drag the handle to reorder items. Both platforms run the same
/// `coui_core` engine (collision detection + sortable math + live
/// displacement): the grabbed row itself follows the pointer (lifted —
/// scale + elevation shadow) while the other rows slide out of the way in
/// real time (`transform: translateY(...)` + `transition`), and the
/// reorder commits on release.
///
/// The handle is also the keyboard's way in: it takes focus, Space or
/// Enter picks the item up, the arrow keys (and Home / End) move it one
/// position at a time, Space or Enter drops it and Escape puts it back.
/// Every step is announced with the item's position, and a drop calls
/// [onReorder] with the same `(oldIndex, newIndex)` a pointer drag would.
///
/// Chrome / dimensional overrides flow through the single
/// [sortableStyle] slot ([CoreSortableStyle]); [resolveSortable]
/// (in `sortable_style.dart`) is the single entry point that merges
/// `CoreSortableTheme.style` with the per-instance style.
///
/// Example:
/// ```dart
/// Sortable(
///   itemCount: items.length,
///   onReorder: (oldIndex, newIndex) => reorderItems(oldIndex, newIndex),
///   itemBuilder: (index, dragHandle, removeButton) => div(
///     [
///       dragHandle,
///       span([text('Item $index')]),
///       if (removeButton != null) removeButton,
///     ],
///     classes: 'flex items-center gap-\${CoreSpace.scale.space8}',
///   ),
/// )
/// ```
///
/// surface:behind — each row paints its own box directly on its own
/// `<div role="listitem">` rather than composing `OutlinedContainer`, so
/// what shows through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class Sortable extends UiStatefulComponent
    implements
        CoreSortableContract<
          Component,
          Component Function(
            int index,
            Component dragHandle,
            Component? removeButton,
          )
        > {
  /// Creates a [Sortable].
  const Sortable({
    required this.itemCount,
    required this.itemBuilder,
    this.axis = CoreSortableContract.defaultAxis,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
  Sortable copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    int? itemCount,
    SortableItemBuilder? itemBuilder,
    CoreSortableAxis? axis,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreSortableReorderCallback? onReorder,
    CoreSortableRemoveCallback? onRemove,
    bool? enabled,
    bool? removable,
    CoreSortableStyle? sortableStyle,
  }) {
    return Sortable(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      itemCount: itemCount ?? this.itemCount,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      axis: axis ?? this.axis,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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
  static const _kDivTag = 'div';
  static const _kSpanTag = 'span';
  static const _kDataIndexAttr = 'data-index';
  static const _kRoleAttr = 'role';
  static const _kListItemRole = 'listitem';
  static const _kListRole = 'list';
  static const _kHandleAttr = 'data-sortable-handle';

  /// `role="application"` is what lets a screen reader in browse mode pass
  /// Space, Enter and the arrow keys through to the handle. As a plain
  /// button, a reader would turn Space into a click and keep the arrows
  /// for its own virtual cursor, and the keyboard path would silently
  /// never run.
  static const _kHandleRole = 'application';

  /// True while the engine runs a drag session (dragging or dropping) —
  /// rows drop their pointer events (stale-hover suppression) and the
  /// root keeps the grabbing cursor alive.
  bool _dragging = false;

  /// True for the single commit frame after a reorder — the reorder swaps
  /// row contents in place, so every row's transition is suppressed while
  /// the stale transforms clear (otherwise the list visibly animates a
  /// second time).
  bool _committing = false;

  /// Commit-frame restore timer.
  Timer? _restoreTimer;
  late final String _scopeId;

  /// The engine runtime — owned here so the session gate can watch drag
  /// lifecycle transitions and the list can read live reorder maths.
  /// A single-axis list locks that axis in the engine rather than each
  /// render site dropping the sideways component by hand. A grid locks
  /// nothing — both axes carry meaning there.
  late final DragScopeController _dragController = DragScopeController(
    modifiers: switch (component.axis) {
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

  /// The source row's transform as of the last render — the second render
  /// input the rebuild gate has to watch (see [handleEngineUpdate]).
  CoreDragOffset _dragTransform = .zero;

  /// Disposer for the engine subscription.
  void Function()? _unsubscribe;

  /// The keyboard reorder — drives the same engine as the pointer, one
  /// position per key.
  final CoreSortableKeyboard _keyboard = CoreSortableKeyboard();

  /// The handle whose focus is keyboard-visible, for its focus ring.
  int? _focusedHandleIndex;

  /// Root element id — a caller-supplied id wins (passthrough); else the
  /// generated scope id.
  String get _effectiveScopeId => component.id ?? _scopeId;

  @override
  void initState() {
    super.initState();
    _scopeId = 'co-sortable-${_coSortableIdCounter++}';
    _unsubscribe = _dragController.addListener(handleEngineUpdate);
    _dragController.describeAnnouncement = handleDescribeAnnouncement;
  }

  /// The reorder [session] currently describes.
  CoreSortableResolution _resolveFor(CoreDragSession session) =>
      CoreSortable.resolve(
        activeId: session.activeId,
        itemIds: _itemIds,
        itemRects: _dragController.registry.itemRects,
        transform: session.transform,
        axis: component.axis,
      );

  /// Builds a drag handle component from the resolver-owned handle slot.
  ///
  /// The handle — not the row — is the drag source: [DragHandle]
  /// registers it as the only activation surface (the same contract as
  /// the Flutter twin's handle wrapper). Row content
  /// stays selectable and a grab anywhere else on the row does nothing.
  ///
  /// The grip glyph renders via [Icon] (`<iconify-icon>` lucide
  /// `grip-vertical`); with no per-instance icon colour it inherits the
  /// handle `<span>`'s `currentColor`.
  ///
  /// A reorderable handle is also the keyboard's way in — focusable, named
  /// after its item and position, and ringed while keyboard focus is on it.
  Component _buildDragHandle(int index, ResolvedSortable resolved) {
    final grip = Icon(
      LucideIcons.gripVertical,
      iconStyle: resolved.iconStyle,
    );
    if (!_canReorder) {
      return Component.element(
        tag: _kSpanTag,
        classes: resolved.handle.className,
        styles: resolved.handle.inlineStyles,
        children: [grip],
      );
    }

    final l10n = CouiLocalizations.of(context);
    final handle = Component.element(
      tag: _kSpanTag,
      classes: resolved.handle.className,
      styles: resolved.handle.inlineStyles,
      attributes: {
        _kHandleAttr: _handleKey(index),
        _kRoleAttr: _kHandleRole,
        'tabindex': '0',
        'aria-label': l10n.sortableHandleLabel(
          CoreSortableKeyboard.positionOf(index),
          component.itemCount,
        ),
        'aria-description': l10n.sortableHandleHint,
      },
      events: {
        'keydown': EventHandlers.createKeyboardEventHandler(
          (event) => handleHandleKeyDown(index, event),
        ),
        'focus': EventHandlers.createElementTargetEventHandler(
          (_, target) => handleHandleFocus(
            index,
            visible: target.matches(':focus-visible'),
          ),
        ),
        'blur': (_) => handleHandleBlur(index),
      },
      children: [grip],
    );

    return DragHandle(
      child: FocusOutline(
        focused: _focusedHandleIndex == index,
        focusOutlineStyle: resolved.handleFocusOutlineStyle,
        classes: resolved.handleRing.className,
        child: handle,
      ),
    );
  }

  /// The value that finds the handle at [index] again after a reorder.
  String _handleKey(int index) => '$_effectiveScopeId:$index';

  /// The key a keyboard reorder understands, or `null` for any other key.
  static CoreSortableKey? _sortableKeyOf(String key) => switch (key) {
    ' ' || 'Enter' => .activate,
    'Escape' => .cancel,
    'ArrowUp' => .up,
    'ArrowDown' => .down,
    'ArrowLeft' => .left,
    'ArrowRight' => .right,
    'Home' => .first,
    'End' => .last,
    _ => null,
  };

  /// Routes a key pressed on the handle at [index] into the keyboard
  /// reorder, and speaks a move the engine has no transition for.
  void handleHandleKeyDown(int index, web.KeyboardEvent event) {
    final key = _sortableKeyOf(event.key);
    if (key == null) return;
    // A held Space would pick up and drop on alternate repeats.
    if (key == .activate && event.repeat) {
      event.preventDefault();

      return;
    }

    final result = _keyboard.handleKey(
      key,
      index: index,
      runtime: _dragController.runtime,
      itemIds: _itemIds,
      axis: component.axis,
    );
    if (!result.handled) return;

    event.preventDefault();
    final announcement = result.announcement;
    if (announcement != null) {
      _dragController.announce(_sentenceFor(announcement));
    }
  }

  /// Rings the handle only for keyboard focus — a pointer grab focuses it
  /// too, and a ring flashing on every drag would read as a glitch.
  void handleHandleFocus(int index, {required bool visible}) {
    if (!mounted) return;
    setState(() => _focusedHandleIndex = visible ? index : null);
  }

  /// Drops the ring, and abandons a keyboard move whose handle lost focus —
  /// the item cannot stay carried by a key the user is no longer pressing
  /// into this list.
  void handleHandleBlur(int index) {
    if (!mounted) return;
    if (_keyboard.isActive && _keyboard.fromIndex == index) {
      _dragController.runtime.cancel(reason: .dismissed);
    }
    if (_focusedHandleIndex != index) return;
    setState(() => _focusedHandleIndex = null);
  }

  /// The fuller sentence for an engine transition during a keyboard move.
  String? handleDescribeAnnouncement(CoreDragAnnouncement announcement) {
    if (!mounted) return null;
    final described = _keyboard.describe(announcement);

    return described == null ? null : _sentenceFor(described);
  }

  String _sentenceFor(CoreSortableAnnouncement announcement) {
    final l10n = CouiLocalizations.of(context);
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

  /// Builds a remove button for the item at [index].
  ///
  /// The unified `Button(variant: .plain, size: .sm, shape: .square)`: the
  /// `plain` variant owns the quiet idle content and the hover, `square`
  /// the equal sides, and `resolved.removeButtonStyle` (raw-forward)
  /// supplies the 32-px side / corner / foreground. The glyph is an
  /// `Icon` child (size from the slot's `leadingIconStyle`; colour null so
  /// it inherits the button foreground).
  Component _buildRemoveButton(int index, ResolvedSortable resolved) {
    final currentOnRemove = component.onRemove;

    return Button(
      onPressed: currentOnRemove == null ? null : () => currentOnRemove(index),
      variant: .plain,
      size: .sm,
      shape: .square,
      buttonStyle: resolved.removeButtonStyle,
      attributes: {
        // The glyph is an icon alone, so the accessible name would be empty.
        // An explicit label gives it the localized string.
        'aria-label': CouiLocalizations.of(context).dismissLabel,
        if (currentOnRemove != null) _kDataIndexAttr: index.toString(),
      },
      child: Icon(
        LucideIcons.x,
        iconStyle: resolved.removeButtonStyle.leadingIconStyle,
      ),
    );
  }

  /// Wraps a row as an engine sortable item: the active row follows the
  /// drag transform under the lifted chrome, sibling rows slide along
  /// their engine-computed displacement, and all motion emission stays
  /// resolver-owned ([composeSortableItem]).
  Component _buildEngineItem(
    int index,
    Component itemContent,
    ResolvedSortable resolved, {
    required double proxyScale,
    required double proxyElevation,
    required Map<String, EventCallback> itemEvents,
  }) {
    final id = CoreDragId('$index');
    final isDragSource = _dragController.activeId == id;
    final displacement = _resolution.displacements[id] ?? .zero;
    final itemChrome = composeSortableItem(
      resolved,
      shiftPx: displacement.y,
      isDragSource: isDragSource,
      suppressTransition: (isDragSource && _dragging) || _committing,
      sessionActive: _dragging || _committing,
      dragOffsetY: isDragSource ? _dragController.transformOf(id).y : 0,
      proxyScale: proxyScale,
      proxyElevation: proxyElevation,
      shiftXPx: displacement.x,
      dragOffsetX: isDragSource ? _dragController.transformOf(id).x : 0,
    );

    return DragItem(
      id: id,
      // The handle owns the keyboard path — one position per key, with the
      // position announced — so the row is not a second, pixel-stepping tab
      // stop in front of it.
      keyboardDraggable: false,
      onDragEnd: handleDragEnd,
      onDragCancel: handleDragCancel,
      child: Component.element(
        tag: _kDivTag,
        classes: itemChrome.className,
        styles: itemChrome.inlineStyles,
        attributes: {
          _kDataIndexAttr: index.toString(),
          _kRoleAttr: _kListItemRole,
        },
        events: itemEvents.isEmpty ? null : itemEvents,
        children: [itemContent],
      ),
    );
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _unsubscribe?.call();
    _dragController
      ..describeAnnouncement = null
      ..dispose();
    super.dispose();
  }

  /// Recomputes the live reorder on every engine tick.
  ///
  /// Resolving landing index and sibling displacement in one call is what
  /// keeps the preview honest: the row the user sees open up is the slot
  /// the drop commits to, because both read the same resolution.
  ///
  /// The gate has to watch the live transform as well, because the source
  /// row's rendered position reads it directly
  /// (`_dragController.transformOf`) at build time — the resolution is not
  /// the only render input. Watching the resolution alone froze the row
  /// exactly where the resolution stops varying: `CoreSortable.resolve`
  /// returns the **constant** `.none` for the whole home-slot dead zone
  /// (`toIndex == fromIndex`), so a grab that hovered its own slot skipped
  /// every rebuild there and the row sat still under a moving pointer,
  /// then snapped a slot's worth the moment it crossed out. Measured on
  /// the docs list: frozen for 48 px of travel, then one 48 px jump.
  ///
  /// Outside that zone the displacements vary with the transform, so the
  /// old gate happened to pass on every tick — which is why the freeze
  /// showed up only over the item's own slot and read as the drag being
  /// choppy rather than as a stuck frame.
  void handleEngineUpdate() {
    final session = _dragController.session;
    final dragging = session != null;
    final resolution = session == null
        ? CoreSortableResolution.none
        : _resolveFor(session);
    final transform = session == null
        ? CoreDragOffset.zero
        : _dragController.transformOf(session.activeId);

    if (dragging == _dragging &&
        resolution == _resolution &&
        transform == _dragTransform) {
      return;
    }

    setState(() {
      _dragging = dragging;
      _resolution = resolution;
      _dragTransform = transform;
    });
  }

  List<CoreDragId> get _itemIds => [
    for (var i = 0; i < component.itemCount; i++) CoreDragId('$i'),
  ];

  /// Commits the reorder the drag previewed — the parent applies the new
  /// order while every row's transition is suppressed for the commit frame,
  /// so the content swap lands motionless (the rows already sit at their
  /// target slots visually).
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
      focusElementBySelector(
        '[$_kHandleAttr="${_handleKey(resolution.toIndex)}"]',
      );
    }

    setState(() {
      _committing = true;
      _resolution = .none;
    });
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_kTransitionRestoreDelay, () {
      _restoreTimer = null;
      if (!mounted) return;
      setState(() => _committing = false);
    });
    component.onReorder?.call(resolution.fromIndex, resolution.toIndex);
  }

  /// Whether items can be reordered — mirrors the Flutter twin's
  /// `enabled && onReorder != null` gate.
  bool get _canReorder => component.enabled && component.onReorder != null;

  @override
  Component build(BuildContext context) {
    final resolved = resolveSortable(
      context,
      enabled: component.enabled,
      axis: component.axis,
      sortableStyle: component.sortableStyle,
    );
    final runtime = resolveSortableRuntime(
      context,
      sortableStyle: component.sortableStyle,
    );
    final showsRemove = component.removable && component.onRemove != null;

    final items = <Component>[];

    final hoverOverride = runtime.hoverColor;

    for (var i = 0; i < component.itemCount; i++) {
      final dragHandle = _buildDragHandle(i, resolved);
      final removeButton = showsRemove ? _buildRemoveButton(i, resolved) : null;

      final itemContent = component.itemBuilder(i, dragHandle, removeButton);

      final itemEvents = <String, EventCallback>{
        if (component.enabled && hoverOverride != null)
          'mouseenter': EventHandlers.createMouseCurrentTargetEventHandler((
            _,
            currentTarget,
          ) {
            currentTarget.style.backgroundColor = hoverOverride;
          }),
        if (component.enabled && hoverOverride != null)
          'mouseleave': EventHandlers.createMouseCurrentTargetEventHandler((
            _,
            currentTarget,
          ) {
            currentTarget.style.backgroundColor = '';
          }),
      };

      if (_canReorder) {
        items.add(
          _buildEngineItem(
            i,
            itemContent,
            resolved,
            proxyScale: runtime.proxyScale,
            proxyElevation: runtime.proxyElevation,
            itemEvents: itemEvents,
          ),
        );
      } else {
        final itemChrome = composeSortableItem(
          resolved,
          shiftPx: 0,
          isDragSource: false,
          suppressTransition: false,
          sessionActive: false,
          dragOffsetY: 0,
          proxyScale: runtime.proxyScale,
          proxyElevation: runtime.proxyElevation,
        );
        items.add(
          Component.element(
            tag: _kDivTag,
            classes: itemChrome.className,
            styles: itemChrome.inlineStyles,
            attributes: {
              _kDataIndexAttr: i.toString(),
              _kRoleAttr: _kListItemRole,
            },
            events: itemEvents.isEmpty ? null : itemEvents,
            children: [itemContent],
          ),
        );
      }
    }

    final sessionRootStyles = _dragging
        ? const Styles(raw: {'cursor': 'grabbing'})
        : null;
    final rootStyles = component.css != null || sessionRootStyles != null
        ? Styles.combine([
            ?resolved.root.inlineStyles,
            ?sessionRootStyles,
            ?component.css,
          ])
        : resolved.root.inlineStyles;

    final rootAttributes = {
      ...component.componentAttributes,
      _kRoleAttr: _kListRole,
    };

    final rootEvents = component.events;

    final root = Component.element(
      tag: _kDivTag,
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: rootStyles,
      attributes: rootAttributes,
      events: rootEvents.isEmpty ? null : rootEvents,
      children: items,
    );

    // The scope wraps the list and adopts it as the measurement origin,
    // rather than sitting inside it — the same shape the Flutter twin has.
    // Rows have to stay *direct* children of this element: it carries the
    // flex `gap`, and `gap` only separates children it owns, so a scope box
    // in between would leave the rows touching.
    return _canReorder
        ? DragScope(
            controller: _dragController,
            originElementId: _effectiveScopeId,
            child: root,
          )
        : root;
  }
}

/// Chain sugar mirroring the Flutter `Sortable.withStyle` extension —
/// merges a [CoreSortableStyle] patch into [Sortable.sortableStyle] via
/// the existing [Sortable.copyWith].
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
