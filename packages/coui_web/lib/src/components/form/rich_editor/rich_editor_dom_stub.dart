// Inert `RichEditor` DOM bridge for SSR / VM builds — every call is a no-op
// and every query reports an empty, unfocused editor. The signatures mirror
// `rich_editor_dom_web.dart` exactly.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_file.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_markdown.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';

/// A decoded key press on the editing surface.
typedef RichEditorKey = ({
  /// The unshifted key of a Mod shortcut (`B`, `8`, `.`, `1`), else null —
  /// always null while AltGr is held, which types characters on layouts
  /// that have it.
  String? shortcutKey,

  /// Whether Shift was held.
  bool shift,

  /// Whether Alt (Option on Apple platforms) was held.
  bool alt,

  /// Whether the platform modifier (⌘ / Ctrl) was held.
  bool mod,

  /// Whether the key was Enter.
  bool enter,

  /// Whether the key was Escape — it closes the toolbar over the selection.
  bool escape,

  /// Whether the press was Alt+F10 — it moves the focus into the toolbar
  /// over the selection.
  bool toolbarFocus,

  /// Whether the press grows the selection — Shift with an arrow, Home,
  /// End, PageUp or PageDown — so the toolbar over it waits for the
  /// selection to hold still.
  bool selects,
});

/// What the toolbar over a selection measures to fold its buttons: the
/// widths of its units in fold order, the width of what never folds, the
/// width of the "more" button with its separator, and how much wider the
/// panel is than the bar (its inset and line).
typedef RichEditorFoldMeasure = ({
  List<double> units,
  double pinned,
  double more,
  double chrome,
});

/// Whether the browser runs on an Apple platform (⌘ rather than Ctrl).
bool richEditorIsApple() => false;

/// Replaces the surface's document with [html].
void richEditorSeed(String id, String html) {}

/// Reads the surface's document.
List<RichEditorNode> richEditorRead(String id) => const [];

/// Moves focus to the surface.
void richEditorFocus(String id) {}

/// Calls [onChange] whenever the selection moves inside the surface; returns
/// the disposer.
void Function() richEditorListenSelection(
  String id,
  void Function() onChange,
) => () {};

/// The box of the selected text that is in view — never any without a DOM.
OverlayRect? richEditorSelectionRect(String id) => null;

/// Where the editing surface begins, from the top of the viewport.
double? richEditorSurfaceTop(String id) => null;

/// Measures the units of the toolbar over a selection, for folding.
RichEditorFoldMeasure? richEditorMeasureFold(String panelId) => null;

/// The room the toolbar over a selection may take: the viewport's width.
double richEditorViewportWidth() => double.infinity;

/// Names the selected run of text — never any without a DOM.
String? richEditorSelectionSignature(String id) => null;

/// Whether the focus is in one of the elements [ids] name.
bool richEditorHasFocusIn(List<String> ids) => false;

/// Moves the focus to the first button in the element [id] names.
bool richEditorFocusFirstButton(String id) => false;

/// Runs [run] once the surface can be edited — at once, without a DOM.
void richEditorWhenInteractive(String id, void Function() run) => run();

/// The direction the surface's text runs in.
String? richEditorDirectionOf(String id) => null;

/// Listens for a pointer released, a scroll and a resize; returns the
/// disposer.
void Function() richEditorListenViewport(
  void Function({required bool pointer}) onChange,
) => () {};

/// The formats on at the caret.
Set<CoreRichEditorFormat> richEditorActiveFormats(String id) => const {};

/// Remembers the surface's selection (a toolbar press or a dialog takes
/// focus away from it).
void richEditorSaveSelection(String id) {}

/// Focuses the surface and puts the remembered selection back.
void richEditorRestoreSelection(String id) {}

/// Toggles [format] at the selection — every format but the link.
void richEditorApply(String id, CoreRichEditorFormat format) {}

/// The target of the link at the caret, or null.
String? richEditorLinkAtCaret(String id) => null;

/// Links the selection to [href], or unlinks it when [href] is null.
void richEditorSetLink(String id, String? href) {}

/// Decodes a `keydown` event.
RichEditorKey richEditorKeyOf(Object event, {required bool apple}) => (
  shortcutKey: null,
  shift: false,
  alt: false,
  mod: false,
  enter: false,
  escape: false,
  toolbarFocus: false,
  selects: false,
);

/// Cancels the browser's default action for [event].
void richEditorPreventDefault(Object event) {}

/// Handles Enter where the editor, not the browser, decides: a `---` line
/// becomes a rule, and Enter on an empty list item or quote line leaves
/// it. Returns whether
/// it did either (the caller then cancels the browser's Enter).
bool richEditorEnterRule(String id) => false;

/// Formats Markdown typed into the surface (`**x**`, `# `, `- ` …) after an
/// `input` event; returns whether it changed the document.
bool richEditorAutoformat(String id, Object event) => false;

/// Opens the browser's file picker for [accept] (MIME types and
/// `.extensions`) and completes with the chosen file, or null when the user
/// cancels. Must be called inside the click that asked for it: browsers
/// open the picker only for a user gesture.
Future<RichEditorPickedFile?> richEditorPickImage({
  required List<String> accept,
}) async => null;

/// Keeps a file dragged onto the surface out of it. Left alone, the browser
/// would put its own `<img>` there — a `blob:` or `file:` address the value
/// cannot keep, shown in the editor but missing from the Markdown. Images come
/// in through the button. Text and other drags are untouched. Returns whether
/// the drag carried files.
bool richEditorBlockFileDrop(Object event) => false;

/// Selects the image a click landed on, so it shows as selected and one
/// Backspace or Delete removes it — a browser would only put the caret beside
/// it. Returns whether the click was on an image.
bool richEditorSelectImage(Object event) => false;

/// Remembers where the caret is — a live clone of the surface's selection —
/// and returns the id an image is inserted at later with
/// [richEditorInsertImage], or null when there is no surface.
String? richEditorMarkAnchor(String id) => null;

/// Forgets the anchor [anchor] — the image it was kept for was not added.
void richEditorDropAnchor(String anchor) {}

/// Inserts the image [src] as a block of its own after the top-level block
/// that holds the anchor [anchor] (or in place of it when that block is an
/// empty paragraph), with an empty paragraph after it to continue on, and
/// puts the caret there. Returns whether it did.
bool richEditorInsertImage(String id, String anchor, String src, String alt) =>
    false;

/// Whether a `beforeinput` [event] adds text.
bool richEditorInsertsText(Object event) => false;

/// Pastes the clipboard as plain text, cut to [limit] characters when one
/// is given.
void richEditorPastePlainText(Object event, {int? limit}) {}
