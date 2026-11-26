import 'package:coui_core/src/drag/core_drag_diagnostics.dart';
import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';

/// Registered drag participants and their measured geometry.
///
/// Measurement is the platform adapter's job — only it knows how to read a
/// render object or a DOM box — so the registry stores what the adapter
/// feeds it and never measures anything itself.
///
/// Rects are cached rather than re-read per move: a drag emits pointer
/// events far faster than layout changes, and re-measuring every sibling on
/// every move is what makes hand-rolled drag code janky. Adapters call
/// [invalidateDropZone] when layout actually changes.
class CoreDragRegistry {
  /// Creates a registry.
  ///
  /// [diagnostics] is where duplicate registrations are reported; the
  /// default says nothing.
  CoreDragRegistry({
    CoreDragDiagnosticsConfig diagnostics = .silent,
  }) : _diagnostics = diagnostics;

  final CoreDragDiagnosticsConfig _diagnostics;

  /// The area a drag is expected to stay within, once an adapter has
  /// measured one.
  ///
  /// Null until measured — a bound nobody supplied must not be invented,
  /// or constraints would pin items to a rectangle that isn't there.
  CoreDragRect? containerRect;
  Map<CoreDragId, Object?> _items = const {};
  Map<CoreDragId, Object?> _dropZones = const {};
  Map<CoreDragId, Object> _itemOwners = const {};
  Map<CoreDragId, Object> _dropZoneOwners = const {};
  Map<CoreDragId, CoreDragRect> _itemRects = const {};
  Map<CoreDragId, CoreDragRect> _dropZoneRects = const {};

  /// Registered draggable ids.
  Iterable<CoreDragId> get itemIds => _items.keys;

  /// Registered drop zone ids.
  Iterable<CoreDragId> get dropZoneIds => _dropZones.keys;

  /// Measured draggable rects, by id.
  Map<CoreDragId, CoreDragRect> get itemRects => .unmodifiable(_itemRects);

  /// Measured drop zone rects, by id.
  Map<CoreDragId, CoreDragRect> get dropZoneRects =>
      .unmodifiable(_dropZoneRects);

  /// Whether [id] is a registered draggable.
  bool hasItem(CoreDragId id) => _items.containsKey(id);

  /// Whether [id] is a registered drop zone.
  bool hasDropZone(CoreDragId id) => _dropZones.containsKey(id);

  /// The application data registered with draggable [id].
  Object? itemData(CoreDragId id) => _items[id];

  /// The application data registered with drop zone [id].
  Object? dropZoneData(CoreDragId id) => _dropZones[id];

  /// Registers (or re-registers) a draggable.
  ///
  /// [owner] is the registering widget's state. It is what makes a
  /// duplicate detectable: a re-registration by the *same* owner is an
  /// ordinary rebuild, while a different owner arriving on top of a live
  /// registration means two widgets believe they hold one id — the later
  /// one silently wins, and drags of the earlier one resolve to the wrong
  /// item. Reported through [CoreDragDiagnosticsConfig].
  void registerItem(CoreDragId id, {Object? data, Object? owner}) {
    _report(_duplicateWarning(_itemOwners[id], owner, id, 'item'));
    _items = {..._items, id: data};
    if (owner != null) _itemOwners = {..._itemOwners, id: owner};
  }

  /// Registers (or re-registers) a drop zone. [owner] as in [registerItem].
  void registerDropZone(CoreDragId id, {Object? data, Object? owner}) {
    _report(_duplicateWarning(_dropZoneOwners[id], owner, id, 'zone'));
    _dropZones = {..._dropZones, id: data};
    if (owner != null) _dropZoneOwners = {..._dropZoneOwners, id: owner};
  }

  /// Removes a draggable and its measurement.
  void unregisterItem(CoreDragId id) {
    _items = _without(_items, id);
    _itemRects = _without(_itemRects, id);
    _itemOwners = _without(_itemOwners, id);
  }

  /// Removes a drop zone and its measurement.
  void unregisterDropZone(CoreDragId id) {
    _dropZones = _without(_dropZones, id);
    _dropZoneRects = _without(_dropZoneRects, id);
    _dropZoneOwners = _without(_dropZoneOwners, id);
  }

  /// Reports [warning], if there is one.
  void _report(String? warning) {
    if (warning == null) return;

    _diagnostics.warn(warning);
  }

  /// The sentence for a registration that displaced another owner's, or
  /// null when there is nothing to report.
  ///
  /// An owner that never unregistered is the whole signal: re-registration
  /// by the same owner is a rebuild, and the first registration has no
  /// predecessor.
  String? _duplicateWarning(
    Object? currentOwner,
    Object? nextOwner,
    CoreDragId id,
    String kind,
  ) {
    if (nextOwner == null) return null;
    if (currentOwner == null || identical(currentOwner, nextOwner)) return null;

    return 'CoreDragRegistry: two owners registered the $kind id "$id" — '
        'the later registration wins, so drags that resolve through it now '
        'reach the second widget. Give each participant a distinct '
        'CoreDragId.';
  }

  /// Stores the adapter-measured rect of draggable [id].
  void measureItem(CoreDragId id, CoreDragRect rect) =>
      _itemRects = {..._itemRects, id: rect};

  /// Stores the adapter-measured rect of drop zone [id].
  void measureDropZone(CoreDragId id, CoreDragRect rect) =>
      _dropZoneRects = {..._dropZoneRects, id: rect};

  /// Drops the cached rect of draggable [id] (layout changed).
  void invalidateItem(CoreDragId id) => _itemRects = _without(_itemRects, id);

  /// Drops the cached rect of drop zone [id] (layout changed).
  void invalidateDropZone(CoreDragId id) =>
      _dropZoneRects = _without(_dropZoneRects, id);

  /// Drops every cached rect, keeping registrations.
  void invalidateAll() {
    containerRect = null;
    _itemRects = const {};
    _dropZoneRects = const {};
  }

  /// Removes every registration and measurement.
  void clear() {
    containerRect = null;
    _items = const {};
    _dropZones = const {};
    _itemOwners = const {};
    _dropZoneOwners = const {};
    _itemRects = const {};
    _dropZoneRects = const {};
  }

  /// Returns a copy of [source] without [key] — the registry replaces its
  /// collections instead of mutating them in place.
  static Map<K, V> _without<K, V>(Map<K, V> source, K key) => {
    for (final entry in source.entries)
      if (entry.key != key) entry.key: entry.value,
  };
}
