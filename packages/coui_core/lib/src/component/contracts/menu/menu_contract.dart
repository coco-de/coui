/// Platform-independent contract for the unified static menu panel.
library;

import 'package:coui_core/src/component/contracts/menu/menu_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_size.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_tone.dart';
import 'package:coui_core/src/icon/icon_name.dart';
import 'package:coui_core/src/icon/lucide_icons.dart';

/// The kind of a [CoreMenuItem].
///
/// Each kind drives a distinct render path inside `Menu`.
enum CoreMenuItemKind {
  /// A non-interactive section heading / label entry.
  label,

  /// An interactive action entry (optionally a submenu trigger).
  action,

  /// A checkable toggle entry.
  checkbox,

  /// A single-choice (radio) entry.
  radio,

  /// A horizontal / vertical visual separator.
  divider,

  /// An empty spacer entry of a fixed size.
  gap,
}

/// The glyph a selected [CoreMenuItemKind.radio] entry draws in its mark
/// column.
///
/// What the entry *is* — one choice of a mutually exclusive group — is its
/// kind and does not change with this; only the picture does. [dot] is the
/// radio button's own mark. [check] is the convention of a menu whose rows
/// are choices of one setting (the platform menus draw a check there), where
/// a dot reads as a list of radio buttons.
enum CoreMenuRadioMark {
  /// A dot in a ring.
  dot(LucideIcons.circleDot),

  /// A check.
  check(LucideIcons.check);

  const CoreMenuRadioMark(this.icon);

  /// The mark a radio entry draws unless it says otherwise.
  static const CoreMenuRadioMark defaultMark = dot;

  /// The glyph drawn on the selected entry.
  final IconName icon;
}

/// Standard menu commands, with shared familiar icons on both renderers.
/// Labels remain caller-localized and callbacks remain caller-owned.
enum CoreMenuAction {
  /// Cut the selection.
  cut(LucideIcons.scissors),

  /// Copy the selection.
  copy(LucideIcons.copy),

  /// Paste clipboard content.
  paste(LucideIcons.clipboardPaste),

  /// Undo the latest edit.
  undo(LucideIcons.undo2),

  /// Redo the latest undone edit.
  redo(LucideIcons.redo2),

  /// Share the current content.
  share(LucideIcons.share),

  /// Rename the current item.
  rename(LucideIcons.pencil),

  /// Delete the current item.
  delete(LucideIcons.trash2);

  const CoreMenuAction(this.icon);

  /// Default icon, used only when the entry has no explicit leading widget.
  final IconName icon;
}

/// Data for a single entry inside a `Menu` panel.
///
/// `CoreMenuItem` is a tagged record — the [kind] field selects which
/// render path `Menu` uses. Construct entries through the named
/// factory constructors rather than the primitive constructor:
///
/// * [CoreMenuItem.label] — non-interactive heading (optionally with
///   leading / trailing slots).
/// * [CoreMenuItem.action] — interactive entry; supplying [submenu]
///   turns it into an inline nested menu trigger.
/// * [CoreMenuItem.checkbox] — checkable toggle entry.
/// * [CoreMenuItem.radio] — single-choice entry.
/// * [CoreMenuItem.divider] — visual separator.
/// * [CoreMenuItem.gap] — fixed-size spacer.
///
/// The generic [W] is the platform widget type (`Widget` on Flutter,
/// `Component` on Web) used by the [leading] / [trailing] slots and by
/// nested [submenu] entries.
class CoreMenuItem<W> {
  const CoreMenuItem._({
    required this.kind,
    this.label = '',
    this.description,
    this.tone = CoreMenuItemTone.defaultTone,
    this.leading,
    this.standardAction,
    this.trailing,
    this.shortcut,
    this.submenu,
    this.onPressed,
    this.onChanged,
    this.href,
    this.active = false,
    this.checked = false,
    this.selected = false,
    this.radioMark = CoreMenuRadioMark.defaultMark,
    this.disabled = false,
    this.gapSize = 0,
  });

  /// Creates a non-interactive section heading entry.
  const CoreMenuItem.label(String label, {W? leading, W? trailing})
    : this._(
        kind: .label,
        label: label,
        leading: leading,
        trailing: trailing,
      );

  /// Creates an interactive action entry.
  ///
  /// When [submenu] is non-null and non-empty the entry renders as an
  /// inline nested menu trigger (a chevron is appended automatically).
  const CoreMenuItem.action(
    String label, {
    String? description,
    CoreMenuItemTone tone = CoreMenuItemTone.defaultTone,
    W? leading,
    CoreMenuAction? standardAction,
    W? trailing,
    String? shortcut,
    void Function()? onPressed,
    String? href,
    List<CoreMenuItem<W>>? submenu,
    bool active = false,
    bool disabled = false,
  }) : this._(
         onPressed: onPressed,
         kind: .action,
         label: label,
         description: description,
         tone: tone,
         leading: leading,
         standardAction: standardAction,
         trailing: trailing,
         shortcut: shortcut,
         submenu: submenu,
         href: href,
         active: active,
         disabled: disabled,
       );

  /// Creates a checkable toggle entry.
  ///
  /// [onChanged] receives the next checked state when activated.
  const CoreMenuItem.checkbox(
    String label, {
    String? description,
    CoreMenuItemTone tone = CoreMenuItemTone.defaultTone,
    W? trailing,
    void Function(bool)? onChanged,
    bool checked = false,
    bool disabled = false,
  }) : this._(
         onChanged: onChanged,
         kind: .checkbox,
         label: label,
         description: description,
         tone: tone,
         trailing: trailing,
         checked: checked,
         disabled: disabled,
       );

  /// Creates a single-choice (radio) entry.
  ///
  /// [onChanged] is invoked with `true` when the entry is activated.
  /// [shortcut] is the same muted hint an action row shows at its end, and
  /// [radioMark] picks the glyph the selected entry draws.
  const CoreMenuItem.radio(
    String label, {
    String? description,
    CoreMenuItemTone tone = CoreMenuItemTone.defaultTone,
    W? trailing,
    String? shortcut,
    void Function(bool)? onChanged,
    bool selected = false,
    CoreMenuRadioMark radioMark = CoreMenuRadioMark.defaultMark,
    bool disabled = false,
  }) : this._(
         onChanged: onChanged,
         kind: .radio,
         label: label,
         description: description,
         tone: tone,
         trailing: trailing,
         shortcut: shortcut,
         selected: selected,
         radioMark: radioMark,
         disabled: disabled,
       );

  /// Creates a visual separator entry.
  const CoreMenuItem.divider() : this._(kind: .divider);

  /// Creates a fixed-size spacer entry.
  const CoreMenuItem.gap(double size) : this._(kind: .gap, gapSize: size);

  /// Selects the render path for this entry.
  final CoreMenuItemKind kind;

  /// The text label rendered for this entry. Empty for
  /// [CoreMenuItemKind.divider] / [CoreMenuItemKind.gap].
  final String label;

  /// A second, quieter line under [label] — only on interactive entries.
  /// A row that carries one grows past the size ladder's minimum height.
  final String? description;

  /// Ordinary or destructive. Foreground only — the label and glyphs read
  /// in the error colour; the hover / pressed wash is the same as any
  /// other row. Because colour is the only cue, a critical entry goes
  /// last in its group, usually behind a divider.
  final CoreMenuItemTone tone;

  /// Optional leading slot (icon, indicator) shown before [label].
  final W? leading;

  /// Optional standard command identity; never inferred from translated text.
  final CoreMenuAction? standardAction;

  /// Optional trailing slot (icon, shortcut hint) shown after [label].
  final W? trailing;

  /// Optional keyboard-shortcut hint text rendered muted + end-aligned
  /// after [label] (before [trailing]). Only meaningful for an
  /// [CoreMenuItemKind.action] or [CoreMenuItemKind.radio] entry; the row
  /// styles it via
  /// `CoreMenuItemStyle.shortcutTextStyle`.
  final String? shortcut;

  /// Nested entries rendered as an inline submenu under this entry.
  ///
  /// Only meaningful for [CoreMenuItemKind.action].
  final List<CoreMenuItem<W>>? submenu;

  /// Callback invoked when an [CoreMenuItemKind.action] entry is
  /// activated. Ignored when [disabled].
  final void Function()? onPressed;

  /// Callback invoked when a [CoreMenuItemKind.checkbox] /
  /// [CoreMenuItemKind.radio] entry is activated.
  ///
  /// Receives the next state — `!checked` for checkbox, `true` for
  /// radio. The positional `bool` matches `ValueChanged<bool>`.
  final void Function(bool)? onChanged;

  /// Optional link target for an [CoreMenuItemKind.action] entry.
  final String? href;

  /// Whether an action entry is rendered with active (highlighted)
  /// styling.
  final bool active;

  /// Whether a checkbox entry is currently checked.
  final bool checked;

  /// Whether a radio entry is currently selected.
  final bool selected;

  /// The glyph a selected radio entry draws. Only meaningful for
  /// [CoreMenuItemKind.radio].
  final CoreMenuRadioMark radioMark;

  /// Whether the entry is rendered disabled and non-interactive.
  final bool disabled;

  /// Spacer height (vertical) / width (horizontal) in logical pixels.
  ///
  /// Only meaningful for [CoreMenuItemKind.gap].
  final double gapSize;

  /// Whether this entry reserves a leading-icon column.
  ///
  /// `Menu` aligns every interactive row to a shared leading column
  /// when any entry in the panel has a leading slot.
  bool get hasLeading =>
      leading != null ||
      standardAction != null ||
      kind == .checkbox ||
      kind == .radio;
}

/// Contract for a unified static menu panel component.
///
/// `Menu` renders a vertical (or horizontal) list of rich menu
/// entries inside a bordered panel. It is the cross-platform
/// unification of the legacy Web `Menu` family (`<ul>` / `<details>`
/// based) and the rich item model of the Flutter `MenuButton` family.
abstract interface class CoreMenuContract<W> {
  /// The entries rendered inside the menu panel.
  List<CoreMenuItem<W>> get items;

  /// Whether the menu lays out its items vertically.
  ///
  /// When `false`, items are arranged horizontally.
  bool get vertical;

  /// Row density — 32 / 36 / 48. One value for the whole panel: the menu
  /// hands it to every `MenuItem` it composes, so a single menu never
  /// mixes heights (`CoreMenuItemSize.defaultSize` = `sm`, 32).
  CoreMenuItemSize get size;

  /// Accessible name announced for the menu container.
  String? get ariaLabel;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreMenuStyle.defaultX (design-system default)
  ///   → CoreMenuTheme.style
  ///   → widget.menuStyle
  /// ```
  CoreMenuStyle? get menuStyle;

  /// Invoked when an **action** entry is activated (its `onPressed`
  /// fires), letting an overlay host (`DropdownMenu` / `ContextMenu` /
  /// `Menubar`) dismiss itself on select without each host re-rolling its
  /// own row renderer. Fired close-first — before the item's own
  /// `onPressed` — mirroring the hosts' existing "close then act" order.
  ///
  /// Toggle entries (checkbox / radio) and submenu parents do **not**
  /// fire it: toggling keeps the menu open (Radix convention) and a
  /// submenu parent expands rather than dismisses. A standalone `Menu`
  /// leaves this null.
  void Function()? get onActivate;
}
