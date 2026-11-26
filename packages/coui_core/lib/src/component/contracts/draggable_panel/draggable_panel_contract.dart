/// Platform-independent contract for unified `DraggablePanel` components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/draggable_panel/core_draggable_panel_controller.dart';
import 'package:coui_core/src/component/contracts/draggable_panel/core_draggable_panel_dock_type.dart';
import 'package:coui_core/src/component/contracts/draggable_panel/draggable_panel_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';

/// Contract for a unified floating, draggable, edge-docking panel.
///
/// `DraggablePanel` wraps a full-screen [child] subtree and overlays a
/// draggable [handle] button that snaps to the nearest viewport edge; tapping
/// the handle toggles an expandable [panel] surface (caller-provided content).
/// Generic over the platform widget type `W` (Flutter `Widget` / Web
/// `Component`) — the only type parameter, per the phantom-generic-free
/// convention.
abstract interface class CoreDraggablePanelContract<W> {
  /// The subtree the panel floats over (typically the whole screen/app body).
  W? get child;

  /// The expandable panel surface content, shown when the handle is open.
  W? get panel;

  /// Custom collapsed handle content. When null a default drag glyph is drawn.
  W? get handle;

  /// How the collapsed handle docks against the nearest viewport edge —
  /// fully inside it, or resting past it until the panel opens (see
  /// [CoreDraggablePanelDockType]).
  CoreDraggablePanelDockType get dockType;

  /// Whether the handle can be dragged. When false the panel stays put.
  bool get enabled;

  /// Whether tapping outside an open panel closes it.
  bool get closeOnTapOutside;

  /// Distance (logical px) the docked handle keeps from the viewport edge.
  double get dockOffset;

  /// Optional external controller for programmatic position / open control.
  CoreDraggablePanelController? get controller;

  /// Called whenever the handle position settles, with its (x, y) in logical
  /// pixels — useful for persistence.
  void Function(double x, double y)? get onPositionChanged;

  /// Called whenever the panel open state changes.
  CoreValueChanged<bool>? get onOpenChanged;

  /// Per-instance chrome style (single entry point — no flat chrome props).
  CoreDraggablePanelStyle? get draggablePanelStyle;

  /// Default dock-edge offset shared by Flutter and Web.
  static const double defaultDockOffset = CoreSpace.space8;

  /// Default for [enabled] — the handle is draggable by default.
  static const bool defaultEnabled = true;

  /// Default for [closeOnTapOutside] — an open panel closes on outside tap.
  static const bool defaultCloseOnTapOutside = true;

  /// Pointer movement, in logical pixels, before the handle starts dragging.
  ///
  /// Not a design token — a platform gesture threshold (Flutter's
  /// `kTouchSlop`) shared by both platforms so the handle disambiguates tap
  /// from drag identically. A non-zero distance also keeps touch drags on
  /// the engine's immediate recogniser: the handle is a dedicated drag
  /// affordance, so it must move on a plain touch drag rather than waiting
  /// out the long-press delay that list items use to coexist with scrolling.
  static const double defaultDragActivationDistance = 18;
}
