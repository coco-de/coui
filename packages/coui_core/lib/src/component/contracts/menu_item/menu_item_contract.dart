/// Cross-platform contract for `MenuItem`.
library;

import 'package:coui_core/src/component/contracts/menu_item/menu_item_size.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_tone.dart';

/// One interactive row of a menu — the surface `Menu`, `DropdownMenu`,
/// `ContextMenu`, `Menubar` and `Select` all place, drawn once here so the
/// five agree.
///
/// Anatomy, start to end: `[ mark ] [ leading ] [ label / description ]
/// [ shortcut | chevron ] [ trailing ]`. The mark is the toggle glyph a
/// checkbox / radio row shows; the chevron replaces the shortcut when the
/// row opens a submenu — the two never share the trailing seat.
///
/// Drawn as `Clickable` + `Text` + `Icon` + `Gap`, not as a `Button`: a
/// menu row's accessibility contract is different in kind (one tab stop
/// for the whole menu with roving focus, `menuitem*` roles derived from
/// what the row is, focusable-but-inert when disabled), and a button's
/// chrome cannot carry it (§6-3 (a)).
///
/// Chrome flows through the single [menuItemStyle] slot; everything here
/// is semantic (which size, which tone), composition (the slots) or
/// behaviour (the callback and the flags).
abstract interface class CoreMenuItemContract<W> {
  /// Density — 32 / 36 / 48. The menu passes its own value to every row.
  CoreMenuItemSize get size;

  /// Ordinary or destructive. Foreground only.
  CoreMenuItemTone get tone;

  /// The row's text. A composition slot so the caller can hand a `Text`
  /// chain; the resolver supplies the role (`labelLarge` / `labelXl`).
  W get label;

  /// A second, quieter line under [label]. When present the row grows past
  /// its minimum height and the two lines top-align (Primer / Fluent model).
  W? get description;

  /// Keyboard shortcut hint at the end of the row. Hidden when
  /// [hasSubmenu] — the chevron takes that seat.
  W? get shortcut;

  /// The toggle glyph — a check for a checkbox row, a dot for a radio row.
  /// `null` on a plain action row.
  W? get leading;

  /// Trailing affordance after the shortcut / chevron.
  W? get trailing;

  /// The mark glyph a checkbox / radio row draws when it is on. `null`
  /// leaves the mark column empty; see [reserveMark] for whether the
  /// column keeps its width.
  W? get mark;

  /// Whether the mark column keeps its width while [mark] is `null`, so
  /// the labels of a toggle group stay aligned when only some rows are on.
  bool get reserveMark;

  /// Whether the row opens a submenu — draws the chevron in place of the
  /// shortcut and, on Web, states `aria-haspopup`.
  bool get hasSubmenu;

  /// Whether the row is drawn as chosen (an active action, a checked
  /// checkbox, a selected radio) — the selected fill and foreground.
  bool get selected;

  /// Whether the row can be activated. `null` derives it from [onPressed]
  /// (the kit-wide `enabled ?? (onPressed != null)` rule). A disabled row
  /// is still focusable (WAI-ARIA APG) — inert, not invisible to the
  /// keyboard.
  bool? get enabled;

  /// Activation.
  void Function()? get onPressed;

  /// Single chrome slot — see [CoreMenuItemStyle].
  CoreMenuItemStyle? get menuItemStyle;
}
