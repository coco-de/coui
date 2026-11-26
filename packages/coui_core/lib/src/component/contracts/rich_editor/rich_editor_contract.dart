/// Platform-independent contract for the rich text editor.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/rich_editor/rich_editor_format.dart';
import 'package:coui_core/src/component/contracts/rich_editor/rich_editor_image.dart';
import 'package:coui_core/src/component/contracts/rich_editor/rich_editor_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';

/// Asks the user for a link target; [current] is the link being edited
/// (null for a new one).
///
/// Completes with the new target, with `''` to remove the link, or with
/// null when the user cancelled.
typedef CoreRichEditorLinkRequest = Future<String?> Function(String? current);

/// Contract for a WYSIWYG Markdown editor — a post or comment composer.
///
/// The value is **Markdown**: what the editor is given and what it reports
/// is GitHub-flavoured Markdown text, while what the user sees and edits is
/// the formatted result (bold looks bold, a list is a list). A toolbar at the
/// top of the box — inside its border, so the focus ring and the error
/// outline wrap both — applies the [toolbar] formats, each with the shortcut
/// [CoreRichEditorFormat.shortcut] names, shown in the button's tooltip.
///
/// While typing, Markdown is formatted as it is recognised: `**bold**`,
/// `*italic*`, `~~strike~~`, `` `code` `` and `[text](url)` inline, and a
/// line starting with `# `, `## `, `### `, `- `, `1. `, `[] ` or `> ` turns
/// into a heading, list, task or quote.
///
/// Selecting text brings up a second toolbar over the selection
/// ([showSelectionToolbar]), with the same buttons.
///
/// **Images.** The editor draws an image where the Markdown has a line of
/// its own `![alt](url)`. It can also add one — the toolbar's image button
/// opens the platform's file picker — but only when the app says where the
/// file goes *and* how it comes off again: with an [onImageUpload] and an
/// [onImageDelete] the button appears, without both it does not and the
/// editor never reaches for the network. The app owns the server side
/// completely: [onImageUpload] stores the file and returns its URL, and
/// [onImageDelete] removes it again. The two come as a pair because an
/// upload alone would leave every image the user takes out on the server
/// for good.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Ctrl] — the editing controller (Flutter `RichEditorController?`,
///   Web `Null` — the web editor keeps its document in the DOM).
/// - [Focus] — focus node type (Flutter `FocusNode?`, Web `Null`).
abstract interface class CoreRichEditorContract<W, Ctrl, Focus> {
  // === Behaviour defaults (single source for both platforms) ===

  /// Default for showing the formatting toolbar.
  static const bool defaultShowToolbar = true;

  /// Default for showing the toolbar that floats over a selection.
  static const bool defaultShowSelectionToolbar = true;

  /// The share of [maxLength] at which the character counter appears.
  static const double counterThreshold = 0.8;

  /// How long a selection grown from the keyboard (Shift+Arrow) has to hold
  /// still before the toolbar over it shows. A key held down changes the
  /// selection on every repeat; showing the toolbar on each would flicker
  /// it, so it waits for the selection to settle. A selection dragged out
  /// with the pointer waits for the pointer to come up instead.
  static const Duration selectionToolbarKeyboardDelay = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// How many units of [CoreRichEditorFormat.selectionToolbarFoldOrder] the
  /// toolbar over a selection folds into its "more" menu so that it fits
  /// [available] without wrapping: the fewest that make the block-type menu
  /// ([pinnedWidth]), the units left and — once anything is folded — the
  /// "more" button ([moreWidth]) fit side by side. [unitWidths] are the
  /// units' widths in fold order, each with the gap or line that leads it.
  /// Every unit folds when even that does not fit; nothing folds into a
  /// width that is not finite.
  static int selectionToolbarFoldSteps({
    required double available,
    required double pinnedWidth,
    required double moreWidth,
    required List<double> unitWidths,
  }) {
    if (!available.isFinite) return 0;
    var width = pinnedWidth + unitWidths.fold<double>(0, (a, b) => a + b);
    if (width <= available) return 0;
    width += moreWidth;
    for (var steps = 1; steps <= unitWidths.length; steps++) {
      width -= unitWidths[steps - 1];
      if (width <= available) return steps;
    }

    return unitWidths.length;
  }

  /// Default for [maxImageBytes].
  static const int defaultMaxImageBytes = CoreRichEditorImage.defaultMaxBytes;

  /// Link schemes the editor accepts; anything else is refused rather than
  /// stored, so a `javascript:` target never reaches the document.
  static const List<String> safeLinkSchemes = ['http', 'https', 'mailto'];

  /// Normalises a typed link target: trims it, adds `https://` to a bare
  /// domain, and returns null for an empty or unsafe target (see
  /// [safeLinkSchemes]).
  static String? normalizeLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final hasScheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(trimmed);
    final target = hasScheme
        ? trimmed
        : trimmed.contains('@') && !trimmed.contains('/')
        ? 'mailto:$trimmed'
        : 'https://$trimmed';
    final uri = Uri.tryParse(target);
    if (uri == null || !safeLinkSchemes.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    if (uri.scheme != 'mailto' && uri.host.isEmpty) return null;
    return target;
  }

  /// The accessible name of the toolbar's block-type button: what the
  /// button picks ([title], the localized "Block type") and the block the
  /// caret is in ([current], the localized "Text" / "Heading 2") — the
  /// visible label alone would read as a button called "Text".
  static String blockTypeButtonLabel(String title, String current) =>
      '$title: $current';

  /// Whether the toolbar over the selection shows — the one rule both
  /// platforms ask.
  ///
  /// It shows while the editor wants it ([showSelectionToolbar]) and takes
  /// input ([enabled], not [readOnly]), a run of text is selected
  /// ([hasSelectedText]) and no longer being dragged out ([selecting] is the
  /// pointer still down), Escape has not closed it on this selection
  /// ([dismissed]), and the focus is the editor's ([focused]: in the text, in
  /// the toolbar itself or in a block-type menu of either toolbar).
  static bool showsSelectionToolbar({
    required bool showSelectionToolbar,
    required bool enabled,
    required bool readOnly,
    required bool hasSelectedText,
    required bool selecting,
    required bool dismissed,
    required bool focused,
  }) =>
      showSelectionToolbar &&
      enabled &&
      !readOnly &&
      hasSelectedText &&
      !selecting &&
      !dismissed &&
      focused;

  /// The character counter text (`120 / 500`) — Latin digits on every
  /// locale, like every counter in the kit.
  static String counterLabel(int length, int maxLength) =>
      '$length / $maxLength';

  /// Whether the counter shows at [length] of [maxLength].
  static bool showsCounter(int length, int? maxLength) =>
      maxLength != null && length >= maxLength * counterThreshold;

  // === Content ===

  /// The Markdown the editor starts with (uncontrolled mode). Ignored when
  /// a [controller] is given — the controller holds the text then.
  String? get initialValue;

  /// Called with the editor's Markdown after every change.
  CoreValueChanged<String>? get onChanged;

  /// Called on Mod+Enter (⌘↩ / Ctrl+Enter) with the editor's Markdown.
  /// Null leaves the shortcut unbound.
  CoreValueChanged<String>? get onSubmit;

  /// Shown in the empty editor.
  String? get placeholder;

  // === State ===

  /// Whether the editor takes input. A disabled editor is greyed out and
  /// its toolbar is off.
  bool get enabled;

  /// Whether the text can be selected and copied but not changed.
  bool get readOnly;

  /// Whether the editor takes focus when it first appears.
  bool get autofocus;

  /// The most characters of Markdown the editor accepts; a counter appears
  /// from [counterThreshold] of it. Null for no limit.
  int? get maxLength;

  // === Toolbar ===

  /// Whether the formatting toolbar shows. The shortcuts work either way.
  /// Without it the box is the `TextArea`'s.
  bool get showToolbar;

  /// What sits at the right end of the toolbar — an app's own control for
  /// the editor, such as a "Show changes" checkbox. When the toolbar has no
  /// room for it beside the buttons it wraps onto a row of its own below
  /// them, at the start. Null leaves the slot out; it also goes with
  /// [showToolbar].
  W? get toolbarTrailing;

  /// The toolbar's buttons, in groups — a gap and a line separate the groups.
  /// Formats left out have no button, but keep their shortcut. The image
  /// button shows only when both [onImageUpload] and [onImageDelete] are
  /// given ([CoreRichEditorFormat.visibleToolbar]).
  List<List<CoreRichEditorFormat>> get toolbar;

  /// Whether a formatting toolbar floats over the selection
  /// (`RichEditorSelectionToolbar`) while a run of text is selected — by a
  /// drag or from the keyboard.
  ///
  /// It holds [CoreRichEditorFormat.selectionToolbar]: the block-type menu
  /// and the buttons of the toolbar in the box, without the image button.
  /// It sits centred over the selection,
  /// [CoreRichEditorStyle.selectionToolbarOffset] above it — below when
  /// there is no room above, and moved inwards at the edges of the screen.
  /// With the toolbar in the box showing ([showToolbar]) the room above is
  /// the editing area's, not the screen's: a selection on the first line
  /// gets the toolbar below it rather than over the toolbar in the box. It
  /// never wraps — too narrow for its buttons, it folds them into a "more"
  /// menu ([CoreRichEditorFormat.selectionToolbarFoldOrder]). It waits for a
  /// drag to end, and for a selection grown from the keyboard to hold still
  /// ([selectionToolbarKeyboardDelay]), and goes when the selection
  /// collapses, on Escape, and when the editor loses the focus to anything
  /// but the toolbar. Alt+F10 moves the focus from the text into it; Escape
  /// brings it back, to the selection as it was. An editor that is disabled
  /// or read-only never shows it. It does not depend on [showToolbar].
  bool get showSelectionToolbar;

  /// Asks for a link target when the link button or Mod+K is used. Null
  /// opens the editor's own small dialog.
  CoreRichEditorLinkRequest? get onLinkRequest;

  // === Images ===

  /// Uploads an image the user picked and completes with the URL it can be
  /// shown from. **The image button only shows when this and [onImageDelete]
  /// are both given** — an upload alone would leave every image the user
  /// takes out on the server for good, so a widget built with this and no
  /// delete asserts in debug builds.
  ///
  /// While it runs a row above the box names the file; when it throws, or
  /// returns an address the editor refuses (see
  /// [CoreRichEditorImage.normalizeSource]), the row says the upload failed
  /// and offers to dismiss it. A file that is not a PNG, JPEG, GIF or WebP,
  /// or is over [maxImageBytes], is refused before this is called.
  CoreRichEditorImageUpload? get onImageUpload;

  /// Deletes an image from the app's server once the user has taken it out
  /// of the document. It is the other half of [onImageUpload]: without it
  /// the editor takes no images. An app that cleans up on its own — a
  /// server job that drops files no saved post refers to — passes a delete
  /// that does nothing.
  ///
  /// It is called with a URL [onImageUpload] returned — **never with one
  /// that was already in the Markdown** the editor started with, since
  /// whether that edit is saved is not the editor's to know — and only
  /// after the image has been out of the document for
  /// [CoreRichEditorImage.deleteDelay], so an undo, or a cut and paste that
  /// moves the image, does not lose the file. It is also called for the
  /// images removed and still waiting when the editor goes away, for a file
  /// whose upload finished after that, and at once for a file whose address
  /// the editor refused to show (the server stored it all the same, and no
  /// document will ever hold it). Setting the content from outside
  /// (`controller.markdown = …`) is not a removal: those images are not
  /// reported.
  ///
  /// The call is not awaited and its errors are not caught: they reach the
  /// app's own error handling.
  CoreRichEditorImageDelete? get onImageDelete;

  /// The largest image, in bytes, the editor reads and uploads; null for no
  /// limit.
  int? get maxImageBytes;

  // === Style ===

  /// Per-instance chrome, merged over `CoreRichEditorTheme.style` and the
  /// design-system defaults.
  CoreRichEditorStyle? get richEditorStyle;

  // === Controllers (Flutter only) ===

  /// Holds the document; read and set its Markdown through it.
  Ctrl get controller;

  /// Focus node for keyboard focus management.
  Focus get focusNode;
}
