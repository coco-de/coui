import 'package:meta/meta.dart';

/// A single selectable option within a `Filter` container.
///
/// Each item carries a unique [value] of type [T], an accessible [label],
/// an optional caller-supplied [icon] widget of type [W], and a
/// [showLabel] toggle. Items are platform-neutral data — both Flutter and
/// Web `Filter` consume the same `CoreFilterItem<T, W>` list; only the
/// widget slot type differs (Flutter `Widget`, Web `Component`).
///
/// Segment shapes:
///
/// - **label-only** — `icon == null` (the default).
/// - **icon + label** — `icon != null && showLabel`.
/// - **icon-only** — `icon != null && !showLabel`; the segment collapses
///   to its fixed height as a square (`CoreFilterStyle.itemPadding` +
///   icon size + `itemPadding`) and [label] remains the accessible name.
@immutable
class CoreFilterItem<T, W> {
  /// Creates a [CoreFilterItem].
  const CoreFilterItem({
    required this.value,
    required this.label,
    this.icon,
    this.showLabel = true,
  });

  /// The unique value this filter item represents.
  final T value;

  /// The text label of the filter item. Always the accessible name of the
  /// segment (Flutter `Semantics` / Web `aria-label`), even when
  /// [showLabel] is false and the label is not painted.
  final String label;

  /// Optional caller-supplied icon rendered before the label. The
  /// per-state colour and size come from
  /// `CoreFilterStyle.iconStyle` / `selectedIconStyle` and reach this
  /// widget through the platform's ambient icon theme.
  final W? icon;

  /// Whether the label is painted. Defaults to `true`. With `false` and a
  /// non-null [icon] the segment renders icon-only; [label] still names
  /// the segment for assistive technology.
  final bool showLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFilterItem<T, W> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          icon == other.icon &&
          showLabel == other.showLabel;

  @override
  int get hashCode => Object.hash(value, label, icon, showLabel);
}
