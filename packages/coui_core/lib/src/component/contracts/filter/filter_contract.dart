/// Platform-independent contract for unified filter components.
///
/// Defines the interface that all Filter implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/filter/filter_item.dart';
import 'package:coui_core/src/component/contracts/filter/filter_style.dart';
import 'package:coui_core/src/component/contracts/filter/filter_variant.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_contract.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified filter component.
///
/// `Filter` is a **controlled** segmented filter control: the parent
/// owns the selected value via [groupValue] and reacts through
/// [onValueChanged]. An optional reset button clears the selection via
/// [onReset].
///
/// Per Epic #1302 every chrome / dimensional override flows through the
/// single [filterStyle] field — see [CoreFilterStyle] for the merge
/// chain. Behaviour fields (`variant` / `groupValue` / `items` /
/// `onValueChanged` / `onReset` / `showResetButton` / `enabled` /
/// `fillWidth`) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
///   Carried into each [CoreFilterItem.icon] slot.
/// - [T] — the value type carried by each filter item.
/// - [Cb] — callback type (Flutter `VoidCallback`, Web
///   `CoreVoidCallback`).
abstract interface class CoreFilterContract<W, T, Cb> {
  /// Default [size] — `md`, the composed `ToggleGroup`'s own default.
  static const CoreComponentSize defaultSize =
      CoreToggleGroupContract.defaultSize;

  /// The visual variant of the filter.
  CoreFilterVariant get variant;

  /// The size step, handed to the composed `ToggleGroup` as is: `md` (a
  /// 40 track, 32 segments and reset button) or `sm` (a 32 track, 26
  /// segments and reset button height). Other values read as `md`. There
  /// is no Filter-own size enum — the segments are the group's.
  CoreComponentSize get size;

  /// The currently selected value in the filter group.
  T? get groupValue;

  /// The list of filter options to display. Each item may carry an
  /// optional [CoreFilterItem.icon] of type [W] and hide its label via
  /// [CoreFilterItem.showLabel].
  List<CoreFilterItem<T, W>> get items;

  /// Callback invoked when a filter item is selected.
  void Function(T) get onValueChanged;

  /// Callback invoked when the reset button is pressed.
  Cb? get onReset;

  /// Whether to show a reset (clear) button after the items, parted from
  /// them by a hairline.
  bool get showResetButton;

  /// Whether the filter accepts input. `null` → enabled. A disabled filter
  /// paints the flat disabled look of its segments (disabled track and ink,
  /// no raised face shadow) and ignores the reset button.
  bool? get enabled;

  /// Whether the track fills the width its parent offers and the segments
  /// share it equally (each segment's content centred), instead of hugging
  /// its content. Handed to the composed `ToggleGroup` as is
  /// ([CoreToggleGroupContract.fillWidth]): only the segments stretch — the
  /// hairline and the reset button keep their own width at the end of the
  /// track. A filter bar that spans a phone-width column turns this on so
  /// the track lines up with the full-width content around it. The parent
  /// must offer a bounded width.
  bool get fillWidth;

  /// Per-instance filter chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFilterTheme.style
  ///   → CoreFilterTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.filterStyle
  /// ```
  CoreFilterStyle? get filterStyle;
}
