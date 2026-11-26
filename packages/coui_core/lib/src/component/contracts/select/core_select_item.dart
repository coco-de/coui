/// A single selectable item for select / dropdown components.
library;

/// A single selectable item within a select component.
///
/// Represents one option in the dropdown with a typed value, display label,
/// optional custom widget rendering, and optional disabled state.
///
/// The [label] is always required as it serves a dual purpose:
/// 1. The text shown on the trigger when this item is selected.
/// 2. The fallback rendering inside the popup when [child] is null.
///
/// When [child] is provided, the popup row renders [child] instead of the
/// plain [label] text. This enables rich option rows (icon + title + price,
/// avatar + name, etc.) while keeping the trigger text simple.
///
/// The [child] type is erased to [Object] so this contract stays
/// platform-agnostic; Flutter implementations cast to `Widget` and Web
/// implementations cast to `Component`.
///
/// Naming follows the cross-platform contract convention:
/// `Core{X}Item` for data classes that travel through both `coui_flutter`
/// and `coui_web`.
class CoreSelectItem<T> {
  /// Creates a [CoreSelectItem] with the given [value], [label],
  /// optional [child] widget for popup rendering, and optional
  /// [enabled] flag.
  const CoreSelectItem({
    required this.value,
    required this.label,
    this.child,
    this.enabled = true,
  });

  /// The underlying value of this item.
  final T value;

  /// The text label displayed for this item.
  ///
  /// Used both for the trigger (when this item is selected) and as a
  /// fallback rendering inside the popup when [child] is null.
  final String label;

  /// Optional custom widget rendered inside the popup option row.
  ///
  /// Type-erased to [Object] so this contract stays platform-agnostic.
  /// Flutter implementations expect a `Widget`; Web implementations
  /// expect a `Component`. When null, the popup renders a plain text
  /// row using [label].
  final Object? child;

  /// Whether this item is enabled and can be selected.
  final bool enabled;
}
