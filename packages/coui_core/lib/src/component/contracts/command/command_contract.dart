/// Cross-platform contract for `Command`.
library;

import 'package:coui_core/src/component/contracts/command/command_item.dart';
import 'package:coui_core/src/component/contracts/command/command_presentation.dart';
import 'package:coui_core/src/component/contracts/command/command_size.dart';
import 'package:coui_core/src/component/contracts/command/command_style.dart';
import 'package:coui_core/src/component/contracts/command/command_variant.dart';

/// Shared surface for the Flutter and Web `Command` palettes.
///
/// Chrome flows through the single [commandStyle] slot; everything here is
/// semantic (which shape, which size), data (groups, scopes, query) or
/// behaviour (callbacks).
abstract interface class CoreCommandContract<W> {
  /// Whether the keyboard-hint footer renders, by presentation, when the
  /// caller leaves `showFooter` unset. A dialog has the room and the
  /// pointer-less user who needs the hints; an inline palette sits in a
  /// page that already explains itself; a fullscreen one gives the space to
  /// the soft keyboard.
  static bool defaultShowFooterFor(CoreCommandPresentation presentation) =>
      presentation == CoreCommandPresentation.dialog;

  /// Whether Arrow Up on the first item wraps to the last (and vice versa).
  /// Off by default — the list edges stop, the way a native listbox does.
  static const bool defaultLoopNavigation = false;

  /// Visual variant. There is one member today.
  CoreCommandVariant get variant;

  /// The shape — inline · dialog · fullscreen. See
  /// [CoreCommandPresentation] for what each decides and what it leaves to
  /// the caller.
  CoreCommandPresentation get presentation;

  /// Density ladder — row height, search field height, icon and type
  /// steps. `sm` for an inline desktop panel, `md` for a dialog, `lg` for a
  /// fullscreen (touch) palette, where the drawn row height is the hit
  /// target.
  CoreCommandSize get size;

  /// Grouped items. Filtered by [query] and [scope].
  List<CoreCommandGroup<W>> get groups;

  /// Scope chips rendered under the search field. Empty means no chip row.
  /// An "All" chip is added automatically when this is non-empty; the
  /// caller supplies only real scopes.
  List<CoreCommandScope> get scopes;

  /// The selected scope's [CoreCommandScope.value], or `null` for all.
  /// Groups whose [CoreCommandGroup.scope] is `null` are shown in every
  /// scope; the rest only in theirs.
  String? get scope;

  /// Search-field placeholder. `null` → the active locale's default.
  String? get placeholder;

  /// Current search text (controlled).
  String get query;

  /// Empty-state title. `null` → the active locale's default.
  String? get emptyLabel;

  /// Empty-state description. `null` → the active locale's default, which
  /// names the two ways out (another word, a wider scope).
  String? get emptyDescription;

  /// Optional empty-state icon, forwarded to the composed `EmptyState`.
  W? get emptyIcon;

  /// Optional empty-state action (a `Button(variant: .plain)` by
  /// convention), forwarded to the composed `EmptyState`.
  W? get emptyAction;

  /// Whether the search field takes focus on mount.
  bool get autofocus;

  /// Whether the keyboard-hint footer renders. `null` → [defaultShowFooterFor]
  /// the presentation.
  bool? get showFooter;

  /// Whether arrow navigation wraps at the list edges.
  bool get loopNavigation;

  /// Called on every keystroke in the search field.
  void Function(String)? get onQueryChanged;

  /// Called with the selected scope's value, or `null` for all — from a
  /// chip tap or Arrow Left / Right.
  void Function(String?)? get onScopeChanged;

  /// Called with the chosen item's [CoreCommandItem.value].
  void Function(String)? get onSelect;

  /// Called on Escape, and from the fullscreen back affordance. The host
  /// (a `Dialog`, a route) closes itself here; an inline palette leaves it
  /// unset.
  void Function()? get onDismiss;

  /// Single chrome entry point.
  CoreCommandStyle? get commandStyle;
}
