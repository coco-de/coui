/// Cross-platform contract for `CommandSearch`.
library;

import 'package:coui_core/src/component/contracts/command/command_size.dart';
import 'package:coui_core/src/component/contracts/command_search/command_search_style.dart';

/// The trigger that opens a command palette — a search-shaped button an app
/// bar or a sidebar places, which calls [onPressed] when it is activated.
///
/// It looks like a search field and is not one. Typing happens in the
/// `Command` the app opens from [onPressed] (usually its dialog
/// presentation); the trigger itself takes no text, so it is announced as a
/// **button** and takes one tab stop. A read-only `TextField` bent into this
/// shape would announce a textbox that refuses input and put the caret
/// somewhere the user cannot type. Listening for the shortcut it shows
/// (`⌘K`) is the app's job — the trigger only draws the hint.
///
/// Anatomy, start to end: `[ leading ] [ hint ] [ shortcut ]`, one
/// [CoreCommandSearchStyle.contentGapStyle] between each seat. The hint takes
/// the remaining width and truncates; the width itself is the parent's —
/// there is no width token.
///
/// Chrome flows through the single [commandSearchStyle] slot; everything
/// here is semantic (which size), content (the hint, the slots) or
/// behaviour (the callback and the flag).
abstract interface class CoreCommandSearchContract<W> {
  /// Density — 32 / 40 / 48, the same three rungs a `Command` palette
  /// draws, so a trigger and the palette it opens can share one size.
  CoreCommandSize get size;

  /// The hint the trigger shows. `null` → the active locale's command
  /// search placeholder, the same text the opened palette's search field
  /// shows.
  String? get hint;

  /// The glyph before the hint. `null` → a search glyph, sized and tinted
  /// by the trigger. A caller's glyph takes the trigger's size and ink
  /// through the ambient icon theme.
  W? get leading;

  /// The shortcut hint at the end — a `Kbd` by convention (`⌘K`). The app
  /// listens for the keys; this slot only shows them.
  W? get shortcut;

  /// Whether the trigger can be activated. `null` derives it from
  /// [onPressed] (the kit-wide `enabled ?? (onPressed != null)` rule). A
  /// disabled trigger leaves the tab order, like any disabled button.
  bool? get enabled;

  /// Activation — the app opens its `Command` here.
  void Function()? get onPressed;

  /// Single chrome slot — see [CoreCommandSearchStyle].
  CoreCommandSearchStyle? get commandSearchStyle;
}
