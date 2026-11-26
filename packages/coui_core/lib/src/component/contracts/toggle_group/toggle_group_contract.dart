/// Platform-independent contract for the unified `ToggleGroup`.
library;

import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_item.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_style.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a grouped toggle — a track holding mutually exclusive
/// segments, the chosen one raised off the track.
///
/// `ToggleGroup` is a **controlled** component: the parent owns the chosen
/// value via [value] and reacts through [onChanged]. It is the shared
/// shape behind a filter's segments, a time picker's AM / PM and a colour
/// picker's mode tabs.
///
/// Every chrome / dimensional override flows through the single
/// [toggleGroupStyle] field — see [CoreToggleGroupStyle] for the merge
/// chain. Behaviour fields (`items` / `value` / `onChanged` / `enabled`)
/// stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
///   Carried into each [CoreToggleGroupItem.icon] slot.
/// - [T] — the value type carried by each item.
abstract interface class CoreToggleGroupContract<W, T> {
  /// Default [size] — `md` (32 segment, 40 track).
  static const CoreComponentSize defaultSize = CoreComponentSize.md;

  /// Default [direction] — `horizontal`.
  static const CoreAxis defaultDirection = CoreAxis.horizontal;

  /// The size step: `md` (segment 32, track 40) or `sm` (segment 26, track
  /// 32). Other values read as `md`. A floating panel's toggles (a time
  /// picker's AM / PM, a colour picker's mode tabs) use `sm`.
  CoreComponentSize get size;

  /// The axis the segments are laid along: `horizontal` (a row) or
  /// `vertical` (a column — AM above PM). The spacing between segments and
  /// the track inset are the same on both axes; a vertical group's segments
  /// share the track's width (each segment stretches to the widest one, or
  /// to the parent's width with [fillWidth]) and centre their content.
  /// Defaults to [defaultDirection].
  CoreAxis get direction;

  /// The options, in display order. Each may carry an optional
  /// [CoreToggleGroupItem.icon] of type [W] and hide its label via
  /// [CoreToggleGroupItem.showLabel].
  List<CoreToggleGroupItem<T, W>> get items;

  /// The currently chosen value; `null` chooses nothing.
  T? get value;

  /// Called with the value of the segment the user picked. `null` makes
  /// the group inert (see [enabled]).
  void Function(T)? get onChanged;

  /// Whether the group accepts input. `null` → whether [onChanged] is
  /// set.
  bool? get enabled;

  /// Whether the track fills the width its parent offers and the
  /// segments share it equally (each segment's content centred), instead
  /// of hugging its content. A panel's mode tabs turn this on so the
  /// track lines up with the full-width fields below it.
  bool get fillWidth;

  /// Optional content painted inside the track after the last segment
  /// (a hairline and a reset button, say). The track's segment spacing
  /// applies between the last segment and this slot; the slot is not a
  /// segment and takes no part in the chosen state.
  W? get trailing;

  /// Per-instance chrome / dimensional / slot style.
  ///
  /// ```text
  /// design system default
  ///   → CoreToggleGroupTheme.style
  ///   → widget.toggleGroupStyle
  /// ```
  CoreToggleGroupStyle? get toggleGroupStyle;
}
