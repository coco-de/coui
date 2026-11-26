import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

/// Internal scope API shared between [SubfocusScope] and [Subfocus].
///
/// Distributed down the tree through `Data.inherit` so every
/// [Subfocus] item can attach itself, request subfocus and trigger
/// arrow-key traversal.
mixin SubfocusScopeApi {
  /// Registers [item] with the scope. Returns whether the item should
  /// start out focused (autofocus picked it as the first item).
  bool attach(SubfocusItemApi item);

  /// Unregisters [item] from the scope.
  void detach(SubfocusItemApi item);

  /// Makes [item] the currently subfocused item.
  bool requestFocus(SubfocusItemApi item);

  /// Clears subfocus if [item] currently holds it.
  bool unfocus(SubfocusItemApi item);

  /// Moves subfocus to the nearest item in [direction]. Returns
  /// whether a target was found.
  bool moveFocus(TraversalDirection direction);
}

/// Internal item API the scope uses to drive a [Subfocus] item.
mixin SubfocusItemApi {
  /// Render object of the item, used for spatial distance maths.
  RenderBox? itemRenderObject();

  /// Marks the item focused / unfocused. [showOutline] gates the
  /// focus ring: keyboard traversal shows it, pointer taps keep it
  /// hidden (mirrors the Web `:focus-visible` convention — the ring is
  /// keyboard-interaction feedback, not a tap highlight).
  void markFocused(bool focused, {bool showOutline = false});

  /// Scrolls the item into view inside any scrollable ancestor.
  void ensureVisible({ScrollPositionAlignmentPolicy alignmentPolicy});

  /// How many times this item has held subfocus — used by autofocus
  /// to restore the most-recently-used item.
  int get focusCount;
}

/// A unified subfocus scope.
///
/// Hosts a group of [Subfocus] items and manages arrow-key traversal
/// between them. Exactly one item holds subfocus at a time; the scope
/// routes navigation along [orientation] and keeps the focused item
/// visible inside scrollable ancestors.
///
/// ```dart
/// SubfocusScope(
///   autofocus: true,
///   child: Column(children: [
///     Subfocus(focusId: 'a', child: Text('A')),
///     Subfocus(focusId: 'b', child: Text('B')),
///   ]),
/// )
/// ```
class SubfocusScope extends StatefulWidget
    implements CoreSubfocusScopeContract<Widget> {
  /// Creates a [SubfocusScope].
  const SubfocusScope({
    required this.child,
    this.autofocus = false,
    this.orientation = CoreSubfocusOrientation.defaultOrientation,
    super.key,
  });

  @override
  final Widget child;

  @override
  final bool autofocus;

  @override
  final CoreSubfocusOrientation orientation;

  @override
  State<SubfocusScope> createState() => _SubfocusScopeState();
}

class _SubfocusScopeState extends State<SubfocusScope> with SubfocusScopeApi {
  var _items = <SubfocusItemApi>[];
  SubfocusItemApi? _current;
  bool _active = true;

  /// The scope's own focus node — arrow-key shortcuts only fire while
  /// the primary focus sits on (or under) the detector, and the
  /// gesture-only [Subfocus] items never take Flutter focus themselves,
  /// so a tap routes real keyboard focus here (mirrors the Web scope
  /// root's tabindex + click focus).
  final FocusNode _focusNode = FocusNode(debugLabel: 'SubfocusScope');

  RenderBox? _scopeRenderObject() {
    if (!mounted || !_active) return null;
    return context.findRenderObject() as RenderBox?;
  }

  void _setCurrent(bool? forward, SubfocusItemApi item) {
    if (!mounted || !_active) return;
    _current?.markFocused(false);
    item.markFocused(true, showOutline: true);
    item.ensureVisible(
      alignmentPolicy: forward == null
          ? .explicit
          : forward
          ? .keepVisibleAtEnd
          : .keepVisibleAtStart,
    );
    _current = item;
  }

  void _findFirstFocus() {
    if (!mounted || !_active) return;
    // Restore the most-recently-used item first.
    (SubfocusItemApi, int)? mostUsed;
    for (final item in _items) {
      if (item.focusCount > 0 && item.focusCount > (mostUsed?.$2 ?? 0)) {
        mostUsed = (item, item.focusCount);
      }
    }
    if (mostUsed != null) {
      _setCurrent(null, mostUsed.$1);
      return;
    }
    // Otherwise pick the item nearest the top-left (top-right in RTL).
    final parentBox = _scopeRenderObject();
    if (parentBox == null) return;
    final direction = Directionality.of(context);
    final anchor = direction == .ltr
        ? Offset.zero
        : Offset(parentBox.size.width, 0);
    (SubfocusItemApi, double)? nearest;
    for (final item in _items) {
      final box = item.itemRenderObject();
      if (box == null) continue;
      final offset = box.localToGlobal(.zero);
      final distance = (offset - anchor).distance;
      if (nearest == null || distance < nearest.$2) {
        nearest = (item, distance);
      }
    }
    if (nearest != null) _setCurrent(null, nearest.$1);
  }

  bool _handleArrow(TraversalDirection direction) {
    final allowed = switch (widget.orientation) {
      .vertical => direction == .up || direction == .down,
      .horizontal => direction == .left || direction == .right,
      .both => true,
    };
    if (!allowed) return false;
    return moveFocus(direction);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  bool attach(SubfocusItemApi item) {
    _items = [..._items, item];
    if (widget.autofocus) {
      _current ??= item;
    }
    return _current == item;
  }

  @override
  void detach(SubfocusItemApi item) {
    _items = _items.where((it) => it != item).toList();
    if (_current == item) {
      _current = null;
      if (widget.autofocus) _findFirstFocus();
    }
  }

  @override
  bool requestFocus(SubfocusItemApi item) {
    if (!mounted || !_active) return false;
    // Pull real keyboard focus onto the scope so the arrow-key
    // shortcuts fire for subsequent traversal.
    _focusNode.requestFocus();
    _current?.markFocused(false);
    _current = item;
    // Tap focus — no ring (Web `:focus-visible` mirror); subsequent
    // arrow traversal via `_setCurrent` shows it.
    item.markFocused(true);
    return true;
  }

  @override
  bool unfocus(SubfocusItemApi item) {
    if (_current != item) return false;
    _current?.markFocused(false);
    _current = null;
    return true;
  }

  @override
  bool moveFocus(TraversalDirection direction) {
    if (!mounted || !_active) return false;
    final current = _current;
    if (current == null) {
      _findFirstFocus();
      return _current != null;
    }
    final currentBox = current.itemRenderObject();
    final parentBox = _scopeRenderObject();
    if (currentBox == null || parentBox == null) return false;
    final currentOffset = currentBox.localToGlobal(
      .zero,
      ancestor: parentBox,
    );

    final (horizontal, forward) = switch (direction) {
      .down => (false, true),
      .up => (false, false),
      .right => (true, true),
      .left => (true, false),
    };

    (SubfocusItemApi, double)? nearest;
    for (final item in _items) {
      if (item == current) continue;
      final box = item.itemRenderObject();
      if (box == null) continue;
      final offset = box.localToGlobal(.zero, ancestor: parentBox);
      final delta = horizontal
          ? (forward
                ? offset.dx - currentOffset.dx
                : currentOffset.dx - offset.dx)
          : (forward
                ? offset.dy - currentOffset.dy
                : currentOffset.dy - offset.dy);
      if (delta <= 0) continue;
      if (nearest == null || delta < nearest.$2) {
        nearest = (item, delta);
      }
    }
    if (nearest != null) {
      _setCurrent(forward, nearest.$1);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Web twin: role="group".
    return Semantics(
      container: true,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        shortcuts: const {
          SingleActivator(.arrowUp): _ArrowIntent(.up),
          SingleActivator(.arrowDown): _ArrowIntent(.down),
          SingleActivator(.arrowLeft): _ArrowIntent(.left),
          SingleActivator(.arrowRight): _ArrowIntent(.right),
        },
        actions: {
          _ArrowIntent: CallbackAction<_ArrowIntent>(
            onInvoke: (intent) => _handleArrow(intent.direction),
          ),
        },
        child: Data<SubfocusScopeApi>.inherit(
          data: this,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Intent emitted by an arrow-key activation inside a [SubfocusScope].
class _ArrowIntent extends Intent {
  const _ArrowIntent(this.direction);

  final TraversalDirection direction;
}

/// A unified focusable subfocus item.
///
/// Makes its [child] focusable inside a [SubfocusScope]. While the
/// item holds subfocus it draws a focus ring (via `FocusOutline`)
/// whose corner radius comes from [subfocusStyle].
///
/// ```dart
/// Subfocus(
///   focusId: 'menu-item-1',
///   child: Text('Menu item 1'),
/// )
/// ```
class Subfocus extends StatefulWidget implements CoreSubfocusContract<Widget> {
  /// Creates a [Subfocus].
  const Subfocus({
    required this.child,
    required this.focusId,
    this.enabled = true,
    this.subfocusStyle,
    super.key,
  });

  @override
  final Widget child;

  @override
  final String focusId;

  @override
  final bool enabled;

  @override
  final CoreSubfocusStyle? subfocusStyle;

  /// Returns a copy of this [Subfocus] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Subfocus copyWith({
    Key? key,
    String? focusId,
    bool? enabled,
    CoreSubfocusStyle? subfocusStyle,
    Widget? child,
  }) {
    return Subfocus(
      key: key ?? this.key,
      focusId: focusId ?? this.focusId,
      enabled: enabled ?? this.enabled,
      subfocusStyle: subfocusStyle ?? this.subfocusStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Subfocus> createState() => _SubfocusState();
}

/// Chain sugar for merging a [CoreSubfocusStyle] patch into
/// [Subfocus.subfocusStyle] without hand-reconstructing every field.
/// Mirrors the Web `Subfocus.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSubfocusStyle.merge` right-side-wins semantics).
extension SubfocusStyleChain on Subfocus {
  /// Returns a copy of this [Subfocus] with [patch] merged into
  /// [subfocusStyle] (patch fields win on conflict).
  Subfocus withStyle(CoreSubfocusStyle patch) => copyWith(
    subfocusStyle: (subfocusStyle ?? const CoreSubfocusStyle()).merge(patch),
  );
}

class _SubfocusState extends State<Subfocus> with SubfocusItemApi {
  SubfocusScopeApi? _scope;
  bool _focused = false;
  bool _showOutline = false;
  bool _active = true;
  int _focusCount = 0;

  @override
  int get focusCount => _focusCount;

  bool get _isFocused => _focused && widget.enabled;

  bool get _isOutlineVisible => _isFocused && _showOutline;

  void _handleTap() {
    if (!widget.enabled) return;
    final result = _scope?.requestFocus(this);
    assert(result != null || _scope == null, 'subfocus scope detached');
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newScope = Data.maybeOf<SubfocusScopeApi>(context);
    if (newScope != _scope) {
      _focusCount = 0;
      _scope?.detach(this);
      _scope = newScope;
      if (widget.enabled) {
        _focused = _scope?.attach(this) ?? false;
      }
    }
  }

  @override
  void didUpdateWidget(covariant Subfocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _focused = _scope?.attach(this) ?? false;
      } else {
        _focused = false;
        _scope?.detach(this);
      }
    }
  }

  @override
  void dispose() {
    _scope?.detach(this);
    super.dispose();
  }

  @override
  RenderBox? itemRenderObject() {
    if (!mounted || !_active) return null;
    return context.findRenderObject() as RenderBox?;
  }

  @override
  void markFocused(bool focused, {bool showOutline = false}) {
    if (!mounted || !_active) return;
    setState(() {
      if (focused) _focusCount += 1;
      _focused = focused;
      _showOutline = focused && showOutline;
    });
  }

  @override
  void ensureVisible({
    ScrollPositionAlignmentPolicy alignmentPolicy = .explicit,
  }) {
    if (!mounted || !_active) return;
    unawaited(
      Scrollable.ensureVisible(context, alignmentPolicy: alignmentPolicy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSubfocus(
      context,
      subfocusStyle: widget.subfocusStyle,
    );

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: .opaque,
        child: FocusOutline(
          focused: _isOutlineVisible,
          focusOutlineStyle: resolved.focusOutlineStyle,
          child: widget.child,
        ),
      ),
    );
  }
}
