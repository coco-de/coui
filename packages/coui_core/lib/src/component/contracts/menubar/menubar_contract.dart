/// Platform-independent contract for menubar components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/menu/menu_contract.dart';
import 'package:coui_core/src/component/contracts/menubar/menubar_style.dart';
import 'package:meta/meta.dart';

/// Kind of a single entry inside a menubar dropdown panel.
enum CoreMenubarEntryKind {
  /// A selectable action row.
  action,

  /// A non-interactive horizontal divider.
  divider,
}

/// A single entry inside a menubar dropdown panel.
///
/// An entry is either a selectable [CoreMenubarEntry.action] (with an
/// optional keyboard-shortcut hint and enabled flag) or a
/// [CoreMenubarEntry.divider] separating groups of actions.
@immutable
class CoreMenubarEntry {
  /// Creates a selectable action entry.
  const CoreMenubarEntry.action({
    required this.label,
    this.shortcut,
    this.standardAction,
    this.enabled = true,
    this.onSelect,
  }) : kind = CoreMenubarEntryKind.action;

  /// Creates a non-interactive divider entry.
  const CoreMenubarEntry.divider()
    : kind = CoreMenubarEntryKind.divider,
      label = '',
      standardAction = null,
      shortcut = null,
      enabled = false,
      onSelect = null;

  /// Whether this entry is an action row or a divider.
  final CoreMenubarEntryKind kind;

  /// The text label of an action entry (empty for dividers).
  final String label;

  /// Optional keyboard-shortcut hint displayed trailing the label.
  final String? shortcut;

  /// Optional standard command icon shared with context and dropdown menus.
  final CoreMenuAction? standardAction;

  /// Whether an action entry is interactive. Disabled entries render
  /// muted and never invoke [onSelect].
  final bool enabled;

  /// Invoked when an enabled action entry is selected.
  final CoreVoidCallback? onSelect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenubarEntry &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          label == other.label &&
          shortcut == other.shortcut &&
          standardAction == other.standardAction &&
          enabled == other.enabled &&
          onSelect == other.onSelect;

  @override
  int get hashCode =>
      Object.hash(kind, label, shortcut, standardAction, enabled, onSelect);
}

/// A single top-level menu within a menubar.
///
/// Each menu shows its [label] in the horizontal bar and reveals its
/// [entries] as a dropdown panel when activated.
@immutable
class CoreMenubarMenu {
  /// Creates a [CoreMenubarMenu] with the given [label] and [entries].
  const CoreMenubarMenu({required this.label, this.entries = const []});

  /// The text label shown in the horizontal bar.
  final String label;

  /// The dropdown entries revealed when this menu is opened.
  final List<CoreMenubarEntry> entries;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreMenubarMenu || runtimeType != other.runtimeType) {
      return false;
    }
    if (label != other.label) return false;
    if (entries.length != other.entries.length) return false;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i] != other.entries[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(label, Object.hashAll(entries));
}

/// Contract for a menubar component.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters; the
/// menubar is data-driven through [CoreMenubarMenu] values rather than
/// widget slots.
///
/// Needs a container at least as wide as the trigger bar's intrinsic
/// width. Narrower containers are unsupported and fail differently per
/// platform — Flutter reports a row overflow, Web spills past the border
/// box without a signal. That divergence is intentionally left unresolved;
/// the width requirement is the contract.
abstract interface class CoreMenubarContract {
  /// The top-level menus displayed horizontally in the bar.
  List<CoreMenubarMenu> get menus;

  /// Whether the horizontal bar draws an outlined container.
  bool get border;

  /// Index of the open menu, or `null` when none is open.
  ///
  /// When non-null the component is controlled — the parent owns the
  /// open state. When `null` the menubar manages its own open state.
  /// Mirrors `NavigationMenu`'s controlled-open surface — both are
  /// multi-trigger bars, so open state is index-based (which menu),
  /// not a single binary controller.
  int? get activeIndex;

  /// Invoked when the open menu changes (open / close / switch).
  ///
  /// Receives the new open index, or `null` when the menubar closes.
  void Function(int?)? get onActiveIndexChanged;

  /// Per-instance menubar chrome / dimensional style.
  CoreMenubarStyle? get menubarStyle;
}
