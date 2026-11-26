// Adapted from Wonky Work's `wonky_rich_editor` (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

import 'dart:async';
import 'dart:math' show max;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/rich_editor_reactions.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_document.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_selection_toolbar.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_toolbar.dart';
import 'package:coui_flutter/src/util/input_focus_ring.dart';
import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart' as se;

/// A WYSIWYG Markdown editor — the composer of a post or a comment.
///
/// The value is GitHub-flavoured **Markdown** ([initialValue], [onChanged],
/// [RichEditorController.markdown]); what the user sees and edits is the
/// formatted text. The box is a `TextArea`'s, and a toolbar at the top of it —
/// inside its border, so the focus ring and the outline wrap both — opens
/// with the block-type button (the caret's block — Text, Heading 1 … 3 — and
/// a chevron, which opens a menu of the four) and holds one plain `Button`
/// per other [toolbar] format, each with a `Tooltip` naming it and its
/// shortcut in `Kbd` key caps; the button of a format that is on at the caret
/// stays filled. A line under the toolbar and one between its groups
/// separate them; [toolbarTrailing] puts an app's own control at its right
/// end.
///
/// - **Shortcuts** — Mod is ⌘ on Apple platforms and Ctrl elsewhere:
///   Mod+B / I / E (code), Mod+Shift+X (strikethrough), Mod+K (link),
///   Mod+Alt+1 / 2 / 3 (headings), Mod+Shift+8 / 7 / 9 (bulleted, numbered,
///   checklist), Mod+Shift+. (quote), Tab / Shift+Tab (list levels;
///   elsewhere they move the focus), Mod+Z / Mod+Shift+Z (the editor's own
///   undo), Mod+C / Mod+X (the selection as Markdown), Mod+V (Markdown is
///   formatted; Mod+Shift+V pastes plain text), Mod+Enter ([onSubmit]). AltGr
///   (Ctrl+Alt on Windows, Level-3 shift on Linux) is never a shortcut: it
///   types the characters it is for.
/// - **Autoformat while typing**: `**bold**`, `*italic*`, `~~strike~~`,
///   `` `code` ``, `[text](url)`; a line starting with `# `, `## `, `### `,
///   `- `, `1. `, `[] ` or `> ` becomes a heading, list, task or quote;
///   `---` then Enter a rule. Markdown the editor cannot show (tables, HTML,
///   fenced code, an image among other text) stays as a literal block and is
///   written back unchanged.
/// - **Images** — a line of its own `![alt](url)` is drawn as an image.
///   With [onImageUpload] and [onImageDelete] the toolbar gets an image
///   button: it opens the platform's file picker, [onImageUpload] stores the
///   file on the app's server and returns its URL, and the image goes in
///   below the caret. A row above the box reports the upload while it runs
///   and when it fails. [onImageDelete] removes a file again once the user
///   has taken its image out (see `CoreRichEditorContract.onImageDelete` for
///   exactly when). The two come as a pair: without both there is no image
///   button, and an [onImageUpload] with no [onImageDelete] asserts in debug
///   builds, since every image the user took out would stay on the server.
///   Dropping a file onto the editor and pasting a picture from the
///   clipboard are not supported here (the web editor takes neither
///   either).
/// - **Selection toolbar** — selecting text, with the pointer or from the
///   keyboard, floats the same formatting buttons over the selection
///   (without the image button): centred above it, below when there is no
///   room above, and held inside the screen. It follows the selection, and
///   goes when the selection collapses, on Escape, and when the editor
///   loses the focus to anything but the toolbar and its menu. Alt+F10
///   moves the focus from the text into it. [showSelectionToolbar] turns it
///   off; a disabled or read-only editor never shows it.
/// - The area grows from `minHeight` to `maxHeight` ([richEditorStyle])
///   and then scrolls; with [maxLength] a counter appears near the limit.
///
/// ```dart
/// RichEditor(
///   placeholder: 'What happened?',
///   onChanged: (markdown) => draft = markdown,
///   onSubmit: (markdown) => post(markdown),
///   // Optional, as a pair: the image button appears when the app can store
///   // the file and take it off the server again.
///   onImageUpload: (file) => api.uploadImage(file.name, file.bytes),
///   onImageDelete: (url) => api.deleteImage(url),
/// )
/// ```
///
/// surface:content — the box sits in the flow like a `TextArea`; the
/// tooltips and the link dialog it opens mount over content.
class RichEditor extends StatefulWidget
    implements
        CoreRichEditorContract<Widget, RichEditorController?, FocusNode?> {
  /// Creates a [RichEditor].
  const RichEditor({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.onChanged,
    this.onSubmit,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.showToolbar = CoreRichEditorContract.defaultShowToolbar,
    this.toolbarTrailing,
    this.toolbar = CoreRichEditorFormat.defaultToolbar,
    this.showSelectionToolbar =
        CoreRichEditorContract.defaultShowSelectionToolbar,
    this.onLinkRequest,
    this.onImageUpload,
    this.onImageDelete,
    this.maxImageBytes = CoreRichEditorContract.defaultMaxImageBytes,
    this.richEditorStyle,
  }) : assert(
         onImageUpload == null || onImageDelete != null,
         'RichEditor: onImageUpload needs an onImageDelete — without it every '
         'image the user takes out stays on the server. Pass a delete that '
         'does nothing if the server cleans up on its own.',
       );

  @override
  final RichEditorController? controller;

  @override
  final FocusNode? focusNode;

  @override
  final String? initialValue;

  @override
  final ValueChanged<String>? onChanged;

  @override
  final ValueChanged<String>? onSubmit;

  @override
  final String? placeholder;

  @override
  final bool enabled;

  @override
  final bool readOnly;

  @override
  final bool autofocus;

  @override
  final int? maxLength;

  @override
  final bool showToolbar;

  @override
  final Widget? toolbarTrailing;

  @override
  final List<List<CoreRichEditorFormat>> toolbar;

  @override
  final bool showSelectionToolbar;

  @override
  final CoreRichEditorLinkRequest? onLinkRequest;

  @override
  final CoreRichEditorImageUpload? onImageUpload;

  @override
  final CoreRichEditorImageDelete? onImageDelete;

  @override
  final int? maxImageBytes;

  @override
  final CoreRichEditorStyle? richEditorStyle;

  @override
  State<RichEditor> createState() => RichEditorState();
}

/// The state of a [RichEditor] — [focus] it, or open its link dialog
/// ([editLink]).
class RichEditorState extends State<RichEditor> {
  RichEditorController? _ownController;
  FocusNode? _ownFocus;
  final _scroll = ScrollController();
  final GlobalKey<State<StatefulWidget>> _layoutKey = GlobalKey();

  /// The editing area — the part of the document that is in view.
  final GlobalKey _bodyKey = GlobalKey();

  /// Has the focus while anything in the box does — the text or a button of
  /// the toolbar at its top.
  final _fieldFocus = FocusNode(
    debugLabel: 'RichEditor field',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// The shared overlay engine the toolbar over a selection is mounted and
  /// placed by.
  static const PopoverOverlayHandler _overlay = PopoverOverlayHandler();

  /// Where the toolbar over a selection sits before collision handling:
  /// centred above the selection.
  static const CorePopoverPlacement _selectionToolbarPlacement = .top;

  /// The scope the buttons of the toolbar over a selection take focus in.
  final _selectionToolbarScope = FocusScopeNode(
    debugLabel: 'RichEditorSelectionToolbar',
  );

  /// The toolbar over the selection while it is showing.
  PopoverEntryHandle<void>? _selectionToolbar;

  /// The selection's box the toolbar was last placed against, in global
  /// coordinates.
  Rect? _selectionToolbarAnchor;

  /// The room the toolbar was last held to, in the overlay's coordinates.
  EdgeInsetsGeometry? _selectionToolbarMargin;

  /// A selection is being grown from the keyboard (Shift+Arrow) and has not
  /// held still for [CoreRichEditorContract.selectionToolbarKeyboardDelay]
  /// yet; the toolbar waits, so a key held down does not flicker it.
  bool _keyboardSelecting = false;
  Timer? _keyboardSelectionSettle;

  /// The selection Escape closed the toolbar on; it stays closed until the
  /// selection is another one.
  se.DocumentSelection? _dismissedSelection;

  /// A pointer is down in the editing area — a selection is being dragged
  /// out, and the toolbar waits for the pointer to come up.
  bool _pointerDown = false;

  /// A menu of this editor's toolbars is open: it holds the focus, and that
  /// is not the editor losing it.
  bool _menuOpen = false;

  bool _toolbarSyncScheduled = false;
  bool _hovered = false;
  String? _lastReported;

  /// The uploads under way or failed, and which uploaded images may still be
  /// deleted from the server — the state both platforms share.
  late final CoreRichEditorImages _images;

  /// [RichEditorController.replacements] as last seen: a change means the
  /// content was replaced from outside, which is not the user removing it.
  int _replacements = 0;

  /// [RichEditorController.embedCount] as last seen.
  int _embeds = 0;

  /// The controller in use — the widget's, or one of the editor's own.
  RichEditorController get controller =>
      widget.controller ??
      (_ownController ??= RichEditorController(
        markdown: widget.initialValue ?? '',
      ));

  /// Tells a focus a pointer press caused from one that arrived by keyboard
  /// — see [_showsFocusRing].
  final _focusRing = InputFocusRing();

  /// The focus node in use.
  FocusNode get focusNode =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'RichEditor'));

  bool get _editable => widget.enabled && !widget.readOnly;

  static bool get _apple => richEditorIsApple;

  @override
  void initState() {
    super.initState();
    _images = CoreRichEditorImages(
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _configure();
    _replacements = controller.replacements;
    _embeds = controller.embedCount;
    _images.sync(controller.imageUrls);
    controller.addListener(_onChange);
    _lastReported = controller.markdown;
    focusNode.addListener(_onFocus);
    _focusRing.adopt(focusNode);
    _fieldFocus.addListener(_scheduleSelectionToolbarSync);
    _selectionToolbarScope.addListener(_scheduleSelectionToolbarSync);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !focusNode.hasFocus) focus();
      });
    }
  }

  @override
  void didUpdateWidget(RichEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onChange);
      controller.addListener(_onChange);
      _lastReported = controller.markdown;
      _documentStyle = null;
      // Another document: what was uploaded into the old one is not this
      // one's to delete.
      _images.reset();
      _replacements = controller.replacements;
      _embeds = controller.embedCount;
      _images.sync(controller.imageUrls);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      focusNode.addListener(_onFocus);
      _focusRing.adopt(focusNode);
    }
    _configure();
    // The open toolbar is mounted in the app's overlay, outside this
    // subtree: what it reads from the widget reaches it when it is told to
    // build again.
    _selectionToolbar?.markNeedsBuild();
    _scheduleSelectionToolbarSync();
  }

  void _configure() {
    controller
      ..readOnly = !_editable
      ..maxLength = widget.maxLength;
    _images
      ..upload = widget.onImageUpload
      ..delete = widget.onImageDelete
      ..maxBytes = widget.maxImageBytes;
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    controller.removeListener(_onChange);
    focusNode.removeListener(_onFocus);
    _selectionToolbar?.dismissImmediately();
    _selectionToolbar = null;
    _keyboardSelectionSettle?.cancel();
    _fieldFocus.dispose();
    _selectionToolbarScope.dispose();
    // Reports the images removed and still waiting to the app.
    _images.dispose();
    _ownController?.dispose();
    _ownFocus?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (controller.replacements != _replacements) {
      _replacements = controller.replacements;
      _images.reset();
    }
    _images.sync(controller.imageUrls);
    final embeds = controller.embedCount;
    if (embeds != _embeds) {
      _embeds = embeds;
      // An image or rule gone or back is a block whose id may now stand for
      // another kind of component (Backspace over an image leaves an empty
      // paragraph under the same id). The selection layer reads the layout
      // in the same frame, and when only it and the document are dirty it is
      // built first and asks the old component about the new kind's position.
      // Rebuilding from here updates the document first.
      if (mounted) setState(() {});
    }
    _scheduleSelectionToolbarSync();
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final markdown = controller.markdown;
    if (markdown == _lastReported) return;
    _lastReported = markdown;
    onChanged(markdown);
  }

  void _onFocus() {
    // Decide the outer ring once, when focus arrives.
    _focusRing.focusChanged(focusNode);
    if (mounted) setState(() {});
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (mounted && focusNode.hasFocus) setState(() {});
  }

  /// Focuses the editor (the caret at the end when there was none).
  void focus() {
    if (!widget.enabled) return;
    focusNode.requestFocus();
    if (controller.selection == null) controller.moveCaretToEnd();
  }

  // -------------------------------------------------- selection toolbar

  /// Whether the toolbar over the selection should be showing: the editor
  /// takes input, a run of text is selected and no longer being dragged out,
  /// Escape has not closed the toolbar on this selection, and the focus is in
  /// the editor, in the toolbar or in a block-type menu of either.
  bool get _wantsSelectionToolbar =>
      CoreRichEditorContract.showsSelectionToolbar(
        showSelectionToolbar: widget.showSelectionToolbar,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        hasSelectedText: controller.hasSelectedText,
        selecting: _pointerDown || _keyboardSelecting,
        dismissed:
            _dismissedSelection != null &&
            controller.selection == _dismissedSelection,
        focused:
            _fieldFocus.hasFocus ||
            _selectionToolbarScope.hasFocus ||
            _menuOpen,
      );

  /// Looks at the selection again once the frame is out — the selection's
  /// box is only known after layout — and asks for that frame.
  void _scheduleSelectionToolbarSync() {
    if (!mounted) return;
    _armSelectionToolbarSync();
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Runs [_syncSelectionToolbar] after the next frame, whenever that is.
  void _armSelectionToolbarSync() {
    if (_toolbarSyncScheduled) return;
    _toolbarSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toolbarSyncScheduled = false;
      if (mounted) _syncSelectionToolbar();
    });
  }

  /// Opens, moves or closes the toolbar over the selection to match the
  /// editor as it is now.
  void _syncSelectionToolbar() {
    final dismissed = _dismissedSelection;
    if (dismissed != null && controller.selection != dismissed) {
      _dismissedSelection = null;
    }
    final wanted = _wantsSelectionToolbar;
    final anchor = wanted ? _selectionAnchor() : null;
    final open = _selectionToolbar;
    if (anchor == null) {
      if (open != null) {
        _selectionToolbar = null;
        _selectionToolbarAnchor = null;
        _selectionToolbarMargin = null;
        open.close();
      }
    } else if (open == null) {
      _openSelectionToolbar(anchor);
    } else {
      final margin = _selectionToolbarRoom();
      if (anchor != _selectionToolbarAnchor ||
          margin != _selectionToolbarMargin) {
        _selectionToolbarAnchor = anchor;
        _selectionToolbarMargin = margin;
        open.moveAnchorTo(anchor, margin: margin);
      }
    }
    // While a selection wants the toolbar its box is measured again after
    // every frame that happens — a scroll of the text or the page, a resize,
    // a reflow all move it, and each of them draws a frame. No frame is
    // asked for: an editor at rest measures nothing.
    if (wanted) _armSelectionToolbarSync();
  }

  /// The part of the selection that is in view, in global coordinates, or
  /// null when none of it is (the text was scrolled away from it) or the
  /// document is not laid out yet.
  Rect? _selectionAnchor() {
    final selection = controller.selection;
    final Object? layout = _layoutKey.currentState;
    final bodyBox = _bodyKey.currentContext?.findRenderObject();
    if (selection == null ||
        layout is! se.DocumentLayout ||
        bodyBox is! RenderBox ||
        !bodyBox.attached) {
      return null;
    }
    final local = layout.getRectForSelection(
      selection.base,
      selection.extent,
    );
    if (local == null) return null;
    // The document's own coordinates to the screen's — the layout knows how
    // it is scrolled.
    final selected = Rect.fromPoints(
      layout.getGlobalOffsetFromDocumentOffset(local.topLeft),
      layout.getGlobalOffsetFromDocumentOffset(local.bottomRight),
    );
    final viewport = Rect.fromPoints(
      bodyBox.localToGlobal(Offset.zero),
      bodyBox.localToGlobal(bodyBox.size.bottomRight(Offset.zero)),
    );
    if (!selected.overlaps(viewport)) return null;

    return selected.intersect(viewport);
  }

  /// The room the toolbar over the selection is held to — the margin the
  /// engine keeps it inside of, in the overlay's coordinates. It is the
  /// popover's own distance from the screen's edges, except at the top while
  /// the toolbar in the box shows: there the room ends where the editing
  /// area begins, so a selection on the first line gets the toolbar below it
  /// rather than over the toolbar in the box. (A panel the toolbar's height
  /// and offset do not fit above the selection within that room flips below
  /// — the engine's collision rule, read against this margin.) Null leaves
  /// the engine its default.
  EdgeInsetsGeometry? _selectionToolbarRoom() {
    final margin = resolvePopover(context).viewportMargin;
    if (!widget.showToolbar) return margin;
    final body = _bodyKey.currentContext?.findRenderObject();
    if (body is! RenderBox || !body.attached) return margin;
    final overlayBox =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    final top = body.localToGlobal(Offset.zero, ancestor: overlayBox).dy;

    return margin.copyWith(top: top > margin.top ? top : margin.top);
  }

  void _openSelectionToolbar(Rect anchor) {
    final resolved = resolveRichEditor(
      context,
      richEditorStyle: widget.richEditorStyle,
      enabled: widget.enabled,
    );
    // The enter and exit motion is the panel `Popup`'s own.
    final panel = resolvePopup(
      context,
      popupStyle: resolved.selectionToolbarPanelStyle,
    );
    final margin = _selectionToolbarRoom();
    final entry = _overlay.show<void>(
      alignment: _selectionToolbarPlacement.toPopoverAlignment(),
      builder: _buildSelectionToolbar,
      context: context,
      anchorAlignment: _selectionToolbarPlacement.toAnchorAlignment(),
      anchorRect: anchor,
      // The editor opens and closes it: a press outside it — on the text, on
      // its own menu — is not its end, and it never takes the focus from
      // the text by itself.
      consumeOutsideTaps: false,
      dismissBackdropFocus: false,
      dismissDuration: panel.closeAnimationDuration,
      dismissOnTapOutside: false,
      // Moved by [_syncSelectionToolbar]; the anchor is no render box for
      // the engine's ticker to follow.
      follow: false,
      margin: margin,
      modal: false,
      offset: _selectionToolbarPlacement.toPopoverOffset(
        resolved.selectionToolbarOffset,
      ),
      // One tap region with the box: a press on the toolbar is not a press
      // outside the editor.
      regionGroupId: _tapGroup,
      showDuration: panel.openAnimationDuration,
    );
    _selectionToolbar = entry;
    _selectionToolbarAnchor = anchor;
    _selectionToolbarMargin = margin;
    unawaited(
      entry.future.whenComplete(() {
        if (!identical(_selectionToolbar, entry)) return;
        _selectionToolbar = null;
        _selectionToolbarAnchor = null;
        _selectionToolbarMargin = null;
      }),
    );
  }

  Widget _buildSelectionToolbar(BuildContext overlayContext) {
    // Resolved under the overlay's context, which carries the themes of the
    // place the editor is in — a light ↔ dark switch reaches the open panel.
    final resolved = resolveRichEditor(
      overlayContext,
      richEditorStyle: widget.richEditorStyle,
      enabled: widget.enabled,
    );
    // The panel is mounted in the app's overlay, which reads from the app's
    // root: an editor whose text runs the other way keeps its own direction
    // on its toolbar, as the toolbar in its box has it.
    final direction = Directionality.of(context);
    // The engine offers the panel the overlay's width and holds it inside
    // the margin afterwards; the bar folds its buttons to the room between
    // the margins, less the panel's inset and line, so the panel never
    // overflows them. The panel shrink-wraps the bar, so the bar is told
    // the room rather than reading it from its constraints.
    final margin = _selectionToolbarMargin;
    final sideRoom = margin is EdgeInsets ? margin.horizontal : 0.0;
    final panel = resolvePopup(
      overlayContext,
      popupStyle: resolved.selectionToolbarPanelStyle,
    );
    final panelChrome = panel.padding.horizontal + 2 * panel.borderWidth;
    return Directionality(
      textDirection: direction,
      child: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) => RichEditorSelectionToolbar(
            resolved: resolved,
            apple: _apple,
            isOn: _isOn,
            canApply: _canApply,
            onApply: _handleApply,
            availableWidth: constraints.maxWidth.isFinite
                ? max(0, constraints.maxWidth - sideRoom - panelChrome)
                : null,
            focusScopeNode: _selectionToolbarScope,
            onDismiss: _handleDismissSelectionToolbar,
            onMenuOpenChanged: _handleMenu,
          ),
        ),
      ),
    );
  }

  /// Escape: the toolbar goes and stays away until the selection changes,
  /// and the focus is back in the text.
  void _handleDismissSelectionToolbar() {
    _dismissedSelection = controller.selection;
    if (!focusNode.hasFocus) focus();
    _scheduleSelectionToolbarSync();
  }

  /// Alt+F10: the focus moves from the text to the toolbar's first button.
  void _focusSelectionToolbar() {
    final scope = _selectionToolbarScope;
    final scopeContext = scope.context;
    if (scopeContext == null) return;
    final first = FocusTraversalGroup.maybeOf(
      scopeContext,
    )?.findFirstFocus(scope, ignoreCurrentFocus: true);
    (first ?? scope).requestFocus();
  }

  /// A menu of the editor's toolbars — a block-type menu, the "more" menu of
  /// the toolbar over the selection — opened or closed. The menu holds the
  /// focus while it is open; one that closes without a pick hands it back to
  /// the text, so the toolbar over the selection stays.
  void _handleMenu(bool open) {
    _menuOpen = open;
    if (!open && _selectionToolbar != null && !focusNode.hasFocus) focus();
    _scheduleSelectionToolbarSync();
  }

  void _handleBodyPointer({required bool down}) {
    if (_pointerDown == down) return;
    _pointerDown = down;
    _scheduleSelectionToolbarSync();
  }

  /// A key that grows the selection was pressed: the toolbar waits for the
  /// selection to hold still before it shows — a key held down repeats, and
  /// a toolbar that came up on every repeat would flicker.
  void _handleKeyboardSelection() {
    _keyboardSelectionSettle?.cancel();
    _keyboardSelectionSettle = Timer(
      CoreRichEditorContract.selectionToolbarKeyboardDelay,
      () {
        _keyboardSelectionSettle = null;
        if (!mounted || !_keyboardSelecting) return;
        _keyboardSelecting = false;
        _scheduleSelectionToolbarSync();
      },
    );
    if (_keyboardSelecting) return;
    _keyboardSelecting = true;
    _scheduleSelectionToolbarSync();
  }

  /// Whether [key] with Shift held grows the selection.
  static bool _growsSelection(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.home ||
      key == LogicalKeyboardKey.end ||
      key == LogicalKeyboardKey.pageUp ||
      key == LogicalKeyboardKey.pageDown;

  // ------------------------------------------------------------ actions

  void _handleApply(CoreRichEditorFormat format) {
    // A press before the editor was ever focused acts at the end of the
    // text, where focusing puts the caret.
    if (controller.selection == null) focus();
    if (!_canApply(format)) return;
    switch (format) {
      case CoreRichEditorFormat.link:
        unawaited(editLink());
        return;
      case CoreRichEditorFormat.image:
        unawaited(_requestImage());
        return;
      case CoreRichEditorFormat.blockType:
        // The menu reports the heading a row toggles, never itself.
        return;
      case CoreRichEditorFormat.bold:
      case CoreRichEditorFormat.italic:
      case CoreRichEditorFormat.strikethrough:
      case CoreRichEditorFormat.code:
      case CoreRichEditorFormat.heading1:
      case CoreRichEditorFormat.heading2:
      case CoreRichEditorFormat.heading3:
      case CoreRichEditorFormat.bulletedList:
      case CoreRichEditorFormat.numberedList:
      case CoreRichEditorFormat.taskList:
      case CoreRichEditorFormat.quote:
        richEditorFormatToggle(controller, format);
    }
    focus();
  }

  bool _isOn(CoreRichEditorFormat format) =>
      richEditorFormatIsOn(controller, format);

  bool _canApply(CoreRichEditorFormat format) {
    if (!_editable) return false;
    // The image button works while the app can store the file and take it
    // off its server again.
    if (format == CoreRichEditorFormat.image) {
      return _images.enabled;
    }
    return richEditorFormatCanApply(controller, format);
  }

  /// Whether the image button has work to do: the editor takes input, and the
  /// app gave an [RichEditor.onImageUpload] with the
  /// [RichEditor.onImageDelete] that goes with it.
  ///
  /// What a [RichEditorToolbar] outside the editor asks before it shows its
  /// image button.
  bool get canInsertImage => _editable && _images.enabled;

  /// Picks an image, uploads it through [RichEditor.onImageUpload] and puts it
  /// below the caret as it is now — what the image button does. Nothing
  /// happens while [canInsertImage] is false.
  Future<void> insertImage() => _requestImage();

  /// Asks for a link and applies it to the selection (Mod+K, the link
  /// button).
  Future<void> editLink() async {
    if (!_editable || !controller.canLink) return;
    final current = controller.link;
    final selection = controller.selection;
    final request = widget.onLinkRequest;
    final result = request != null
        ? await request(current)
        : await _defaultLinkDialog(current);
    if (!mounted) return;
    if (result != null && selection != null) {
      controller.editor.execute([
        se.ChangeSelectionRequest(
          selection,
          se.SelectionChangeType.placeCaret,
          se.SelectionReason.userInteraction,
        ),
      ]);
      controller.setLink(result.isEmpty ? null : result);
    }
    focus();
  }

  Future<String?> _defaultLinkDialog(String? current) => showDialog<String>(
    context: context,
    builder: (context) => _LinkDialog(current: current),
  );

  /// Picks an image, uploads it through [RichEditor.onImageUpload] and puts
  /// it below the caret as it was when the button was pressed (the image
  /// button).
  Future<void> _requestImage() async {
    if (!_editable || !_images.enabled) return;
    // The anchor is taken, and the picker opened, before anything is
    // awaited: the web's picker opens only inside the click that asked for
    // it, and the caret may move while the file is on its way.
    final anchor = controller.selection?.extent.nodeId;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: CoreRichEditorImage.extensions,
    );
    if (!mounted || picked == null) return;
    final mimeType = CoreRichEditorImage.mimeTypeOf(picked.name);
    // The size is read from the pick result where the platform has it; it
    // costs a read of the file only where it does not.
    final int size;
    try {
      size = picked.lengthSync() ?? await picked.length();
    } on Object {
      if (mounted) {
        _images.reject(picked.name, CoreRichEditorImageIssue.uploadFailed);
      }
      return;
    }
    if (!mounted) return;
    final issue = mimeType == null
        ? CoreRichEditorImageIssue.notAllowed
        : CoreRichEditorImage.check(
            name: picked.name,
            mimeType: mimeType,
            size: size,
            maxBytes: widget.maxImageBytes,
          );
    // Judged before the file is read: a refused file is never in memory.
    if (mimeType == null || issue != null) {
      _images.reject(picked.name, issue ?? CoreRichEditorImageIssue.notAllowed);
      return;
    }
    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } on Object {
      if (mounted) {
        _images.reject(picked.name, CoreRichEditorImageIssue.uploadFailed);
      }
      return;
    }
    if (!mounted) return;
    final url = await _images.submit(
      CoreRichEditorImageFile(
        name: picked.name,
        mimeType: mimeType,
        bytes: bytes,
      ),
    );
    if (!mounted || url == null) return;
    controller.insertImage(
      url: url,
      alt: CoreRichEditorImage.altTextFor(picked.name),
      afterNodeId: anchor,
    );
    focus();
  }

  /// Copies the selection as Markdown ([cut] also deletes it, unless the
  /// editor is read-only).
  Future<void> _copy({bool cut = false}) async {
    final markdown = controller.selectedMarkdown;
    if (markdown == null) return;
    if (cut && _editable) controller.deleteSelection();
    await Clipboard.setData(ClipboardData(text: markdown));
  }

  Future<void> _paste({bool plain = false}) async {
    if (!_editable) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted || text == null || text.isEmpty) return;
    controller.paste(text, plain: plain);
  }

  // ----------------------------------------------------------- keyboard

  se.ExecutionInstruction _keys({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return se.ExecutionInstruction.continueExecution;
    }
    final keyboard = HardwareKeyboard.instance;
    final mod = _apple ? keyboard.isMetaPressed : keyboard.isControlPressed;
    final shift = keyboard.isShiftPressed;
    final alt = keyboard.isAltPressed;
    final key = keyEvent.logicalKey;
    se.ExecutionInstruction run(void Function() action) {
      action();
      return se.ExecutionInstruction.haltExecution;
    }

    // The toolbar over the selection: Escape closes it, Alt+F10 moves the
    // focus into it. Without it both keys are the page's.
    if (_selectionToolbar != null) {
      if (key == LogicalKeyboardKey.escape) {
        return run(_handleDismissSelectionToolbar);
      }
      if (key == LogicalKeyboardKey.f10 && alt && !mod && !shift) {
        return run(_focusSelectionToolbar);
      }
    }
    // Shift+Arrow grows the selection: the toolbar over it waits for the
    // selection to hold still. The key itself is super_editor's.
    if (shift && !alt && _growsSelection(key)) _handleKeyboardSelection();

    if (mod) {
      // AltGr is Ctrl+Alt on Windows and the Level-3 shift on Linux: on many
      // layouts it types characters (² ³ { [ …) and must reach the text.
      final altGr =
          !_apple &&
          (keyboard.logicalKeysPressed.contains(LogicalKeyboardKey.altRight) ||
              keyboard.logicalKeysPressed.contains(
                LogicalKeyboardKey.altGraph,
              ));
      // With Alt held the logical key is not the key cap (Option+1 types
      // ¡), so the physical key names it.
      final label = alt ? _physicalLabel(keyEvent.physicalKey) : _keyLabel(key);
      final format = altGr || label == null
          ? null
          : CoreRichEditorFormat.forKey(label, shift: shift, alt: alt);
      if (format != null) {
        if (!_editable) return se.ExecutionInstruction.haltExecution;
        return run(() => _handleApply(format));
      }
      if (alt) return se.ExecutionInstruction.continueExecution;
      switch (key) {
        case LogicalKeyboardKey.keyZ:
          return run(shift ? controller.redo : controller.undo);
        case LogicalKeyboardKey.keyY when !_apple:
          return run(controller.redo);
        case LogicalKeyboardKey.keyC when !shift:
          return run(() => unawaited(_copy()));
        case LogicalKeyboardKey.keyX when !shift:
          return run(() => unawaited(_copy(cut: true)));
        case LogicalKeyboardKey.keyV:
          return run(() => unawaited(_paste(plain: shift)));
        case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
          final submit = widget.onSubmit;
          if (submit == null) return se.ExecutionInstruction.continueExecution;
          return run(() => submit(controller.markdown));
      }
      return se.ExecutionInstruction.continueExecution;
    }
    if (key == LogicalKeyboardKey.tab && !mod && !alt) {
      if (_inCode()) {
        if (!shift && _editable) {
          controller.editor.execute([
            const se.InsertPlainTextAtCaretRequest('  '),
          ]);
        }
        return se.ExecutionInstruction.haltExecution;
      }
      if (_editable && controller.indentItems(outdent: shift)) {
        return se.ExecutionInstruction.haltExecution;
      }
      // Elsewhere Tab leaves the editor, like any other input.
      if (shift) {
        focusNode.previousFocus();
      } else {
        focusNode.nextFocus();
      }
      return se.ExecutionInstruction.haltExecution;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        !mod &&
        !shift &&
        !alt &&
        _editable &&
        _ruleOnEnter()) {
      return se.ExecutionInstruction.haltExecution;
    }
    return se.ExecutionInstruction.continueExecution;
  }

  /// The unshifted character of [key] as the shortcut table writes it.
  static String _keyLabel(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.period => '.',
    LogicalKeyboardKey.digit7 => '7',
    LogicalKeyboardKey.digit8 => '8',
    LogicalKeyboardKey.digit9 => '9',
    _ => key.keyLabel,
  };

  /// The key cap of [key] as the shortcut table writes it, read from the
  /// physical key — the one thing Alt does not change — or null for a key the
  /// table has no Alt shortcut on (digits and the period).
  static String? _physicalLabel(PhysicalKeyboardKey key) => switch (key) {
    PhysicalKeyboardKey.digit0 => '0',
    PhysicalKeyboardKey.digit1 => '1',
    PhysicalKeyboardKey.digit2 => '2',
    PhysicalKeyboardKey.digit3 => '3',
    PhysicalKeyboardKey.digit4 => '4',
    PhysicalKeyboardKey.digit5 => '5',
    PhysicalKeyboardKey.digit6 => '6',
    PhysicalKeyboardKey.digit7 => '7',
    PhysicalKeyboardKey.digit8 => '8',
    PhysicalKeyboardKey.digit9 => '9',
    PhysicalKeyboardKey.period => '.',
    _ => null,
  };

  bool _inCode() {
    final s = controller.selection;
    if (s == null) return false;
    return isCodeLike(controller.document.getNodeById(s.extent.nodeId));
  }

  /// `---` + Enter makes a rule.
  bool _ruleOnEnter() {
    final s = controller.selection;
    if (s == null || !s.isCollapsed) return false;
    final node = controller.document.getNodeById(s.extent.nodeId);
    final p = s.extent.nodePosition;
    if (!isPlainParagraph(node) || p is! se.TextNodePosition) return false;
    final text = (node! as se.ParagraphNode).text.toPlainText();
    if (p.offset != text.length) return false;
    if (!controller.features.rules ||
        !RegExp(r'^(---|\*\*\*|___)$').hasMatch(text)) {
      return false;
    }
    final start = se.DocumentPosition(
      nodeId: node.id,
      nodePosition: const se.TextNodePosition(offset: 0),
    );
    controller.editor.execute([
      se.DeleteContentRequest(
        documentRange: se.DocumentRange(start: start, end: s.extent),
      ),
      se.InsertNodeAtIndexRequest(
        nodeIndex: controller.document.getNodeIndexById(node.id),
        newNode: se.HorizontalRuleNode(id: se.Editor.createNodeId()),
      ),
      se.ChangeSelectionRequest(
        se.DocumentSelection.collapsed(position: start),
        se.SelectionChangeType.placeCaret,
        se.SelectionReason.userInteraction,
      ),
    ]);
    return true;
  }

  /// super_editor's own bindings that the editor replaces (styles,
  /// clipboard, indents) or leaves to the page (Esc). Its undo and redo
  /// never run: [_keys] comes first and handles Mod+Z.
  static final _removedActions = <se.SuperEditorKeyboardAction>{
    se.cmdBToToggleBold,
    se.cmdIToToggleItalics,
    se.pasteWhenCmdVIsPressed,
    se.copyWhenCmdCIsPressed,
    se.cutWhenCmdXIsPressed,
    se.tabToIndentParagraph,
    se.shiftTabToUnIndentParagraph,
    se.backspaceToUnIndentParagraph,
    se.enterToUnIndentParagraph,
    se.tabToIndentTask,
    se.shiftTabToUnIndentTask,
    se.collapseSelectionWhenEscIsPressed,
  };

  static final List<se.SuperEditorKeyboardAction> _imeActions = [
    for (final a in se.defaultImeKeyboardActions)
      if (!_removedActions.contains(a)) a,
  ];

  // -------------------------------------------------------------- build

  bool get _showsFocusRing => _focusRing.shows(focusNode);

  Set<WidgetState> get _states => {
    if (!widget.enabled) WidgetState.disabled,
    if (focusNode.hasFocus) WidgetState.focused,
    if (_hovered) WidgetState.hovered,
  };

  @override
  Widget build(BuildContext context) {
    final resolved = resolveRichEditor(
      context,
      richEditorStyle: widget.richEditorStyle,
      enabled: widget.enabled,
    );
    final area = resolveTextArea(
      context,
      hasError: false,
      size: CoreComponentSize.md,
      enabled: widget.enabled,
      textAreaStyle: resolved.textAreaStyle,
    );
    final states = _states;
    final base = DefaultTextStyle.of(
      context,
    ).style.merge(area.valueTextStyle.resolve(states));

    final decoration = area.decoration.resolve(states);
    final active = area.activeDecoration.resolve(states);

    final body = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.forbidden,
      child: Semantics(
        textField: true,
        multiline: true,
        readOnly: !_editable,
        enabled: widget.enabled,
        label: widget.placeholder,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          // A press below the text (inside the box) focuses it too — at
          // once: keys typed before the IME connection opens are lost on
          // the web. The toolbar is not part of it: a press there is the
          // toolbar's (or the app's trailing control's).
          onPointerDown: (_) {
            // A press on the body is what focuses the editor: a focus it
            // causes is a pointer's, and draws no outer ring.
            _focusRing.pointerDown();
            _handleBodyPointer(down: true);
          },
          onPointerUp: (_) {
            if (!mounted) return;
            if (!focusNode.hasFocus) focus();
            _handleBodyPointer(down: false);
          },
          onPointerCancel: (_) => _handleBodyPointer(down: false),
          child: ConstrainedBox(
            key: _bodyKey,
            constraints: BoxConstraints(
              minHeight: resolved.minHeight,
              maxHeight: resolved.maxHeight,
            ),
            child: _editor(
              RichEditorDocumentStyle(
                resolved: resolved,
                base: base,
                placeholder: area.placeholderTextStyle,
                padding: area.padding,
              ),
              selectionColor: area.selectionColor,
              caretColor: area.cursorColor,
              caretWidth: area.cursorWidth,
            ),
          ),
        ),
      ),
    );

    // Without a toolbar the box is a `TextArea`'s, drawn as it always was:
    // fill and border together under the editing area, the active boundary
    // laid over it so the text does not move when the editor takes focus.
    final box = widget.showToolbar
        ? _boxWithToolbar(context, resolved, decoration, active, body)
        : Container(
            decoration: decoration,
            foregroundDecoration: active,
            child: body,
          );

    final field = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusOutline(
        focused: _showsFocusRing,
        focusOutlineStyle: area.focusOutlineStyle,
        // Knows when the focus is anywhere in the box; it takes none itself
        // and says nothing to assistive technology.
        child: Focus(
          focusNode: _fieldFocus,
          includeSemantics: false,
          child: box,
        ),
      ),
    );

    final max = widget.maxLength;
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) {
        if (focusNode.hasFocus) focusNode.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_images.pending.isNotEmpty) ...[
            _uploadRows(context, resolved),
            Gap(gapStyle: resolved.toolbarGapStyle),
          ],
          field,
          if (max != null)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final length = controller.length;
                if (!CoreRichEditorContract.showsCounter(length, max)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(
                    top:
                        Theme.of(context).geometry.space(CoreSpace.space4) *
                        Theme.of(context).scaling,
                  ),
                  child: Text(
                    CoreRichEditorContract.counterLabel(length, max),
                    textAlign: TextAlign.end,
                    style: length >= max
                        ? area.errorTextStyle
                        : area.counterTextStyle,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// The box and its toolbar as one region for [TapRegion.onTapOutside].
  String get _tapGroup => 'RichEditor#${identityHashCode(this)}';

  RichEditorDocumentStyle? _documentStyle;
  String? _documentHint;
  late se.Stylesheet _stylesheet;
  late List<se.ComponentBuilder> _builders;

  Widget _editor(
    RichEditorDocumentStyle style, {
    required Color selectionColor,
    required Color caretColor,
    required double caretWidth,
  }) {
    // A new stylesheet restyles the whole document: only on chrome changes.
    final previous = _documentStyle;
    if (previous == null ||
        previous.base != style.base ||
        previous.placeholder != style.placeholder ||
        previous.padding != style.padding ||
        !identical(previous.resolved, style.resolved) &&
            !_sameDocumentChrome(previous.resolved, style.resolved) ||
        widget.placeholder != _documentHint) {
      _documentStyle = style;
      _documentHint = widget.placeholder;
      _stylesheet = style.stylesheet();
      _builders = style.componentBuilders(
        controller.editor,
        hint: widget.placeholder,
      );
    }
    // Its own scroll view: super_editor scrolls the nearest vertical
    // Scrollable, which must not be the dialog's or the page's.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        controller: _scroll,
        shrinkWrap: true,
        slivers: [
          se.SuperEditor(
            editor: controller.editor,
            focusNode: focusNode,
            documentLayoutKey: _layoutKey,
            inputSource: se.TextInputSource.ime,
            // Several editors can be on screen (a dialog over a page).
            inputRole: _tapGroup,
            tapRegionGroupId: _tapGroup,
            gestureMode: se.DocumentGestureMode.mouse,
            selectionPolicies: const se.SuperEditorSelectionPolicies(
              clearSelectionWhenEditorLosesFocus: false,
              clearSelectionWhenImeConnectionCloses: false,
            ),
            stylesheet: _stylesheet,
            componentBuilders: _builders,
            selectionStyle: se.SelectionStyles(selectionColor: selectionColor),
            // The selection outlives the focus (the toolbar acts on it), so
            // the caret layer is only there while the editor is focused and
            // editable. An empty layer takes its slot: super_editor never
            // unmounts layers dropped from the end of the list.
            documentOverlayBuilders: [
              if (focusNode.hasFocus && _editable)
                se.DefaultCaretOverlayBuilder(
                  caretStyle: se.CaretStyle(
                    width: caretWidth,
                    color: caretColor,
                  ),
                )
              else
                const se.FunctionalSuperEditorLayerBuilder(_noCaret),
            ],
            keyboardActions: [_keys, ..._imeActions],
            // Links don't open while editing.
            contentTapDelegateFactories: const [],
          ),
        ],
      ),
    );
  }

  static bool _sameDocumentChrome(ResolvedRichEditor a, ResolvedRichEditor b) =>
      a.blockSpacing == b.blockSpacing &&
      a.linkColor == b.linkColor &&
      a.codeTextStyle == b.codeTextStyle &&
      a.codeBackgroundColor == b.codeBackgroundColor &&
      a.codePadding == b.codePadding &&
      a.quoteBarColor == b.quoteBarColor &&
      a.quoteBarWidth == b.quoteBarWidth &&
      a.quoteSpacing == b.quoteSpacing &&
      a.quoteTextColor == b.quoteTextColor &&
      a.ruleColor == b.ruleColor &&
      a.completedTaskColor == b.completedTaskColor &&
      a.heading1TextStyle == b.heading1TextStyle &&
      a.heading2TextStyle == b.heading2TextStyle &&
      a.heading3TextStyle == b.heading3TextStyle &&
      a.imageBorderRadius == b.imageBorderRadius &&
      a.imageMaxHeight == b.imageMaxHeight &&
      a.imageBackgroundColor == b.imageBackgroundColor;

  // ------------------------------------------------------- upload rows

  /// The uploads under way and the failed ones, one `Alert` strip each, above
  /// the box: what is happening to the image the user picked.
  Widget _uploadRows(BuildContext context, ResolvedRichEditor resolved) {
    final localizations = CoUILocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: resolved.toolbarItemSpacing,
      children: [
        for (final pending in _images.pending)
          if (pending.uploading)
            Alert(
              key: ValueKey<String>('richEditor.imageRow.${pending.id}'),
              layout: CoreAlertLayout.inline,
              leading: const Loading(),
              title:
                  '${localizations.richEditorImageUploading} · ${pending.name}',
              alertStyle: resolved.uploadAlertStyle,
            )
          else
            Alert.destructive(
              key: ValueKey<String>('richEditor.imageRow.${pending.id}'),
              layout: CoreAlertLayout.inline,
              title:
                  '${_issueLabel(pending.issue!, localizations)}'
                  ' · ${pending.name}',
              onDismiss: () => _images.dismiss(pending.id),
              alertStyle: resolved.uploadAlertStyle,
            ),
      ],
    );
  }

  static String _issueLabel(
    CoreRichEditorImageIssue issue,
    CoUILocalizations localizations,
  ) => switch (issue) {
    CoreRichEditorImageIssue.notAllowed =>
      localizations.richEditorImageNotAllowed,
    CoreRichEditorImageIssue.tooLarge => localizations.richEditorImageTooLarge,
    CoreRichEditorImageIssue.uploadFailed =>
      localizations.richEditorImageUploadFailed,
  };

  // ------------------------------------------------------------ toolbar

  /// The box when it holds the toolbar: a strip at the top, a line under it and
  /// the editing area below, inside one border.
  ///
  /// The border — and the active boundary over it — is drawn over both parts,
  /// above the fill and what it holds, not under them: the strip's own fill
  /// then meets the rounded corners beneath the line instead of over it. The
  /// content is inset by the border's width, so the box measures what a
  /// `TextArea` does.
  Widget _boxWithToolbar(
    BuildContext context,
    ResolvedRichEditor resolved,
    BoxDecoration decoration,
    BoxDecoration? active,
    Widget body,
  ) {
    final borderInsets =
        decoration.border?.dimensions.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final fill = BoxDecoration(
      color: decoration.color,
      image: decoration.image,
      borderRadius: decoration.borderRadius,
      boxShadow: decoration.boxShadow,
      gradient: decoration.gradient,
      backgroundBlendMode: decoration.backgroundBlendMode,
      shape: decoration.shape,
    );
    final edge = BoxDecoration(
      border: decoration.border,
      borderRadius: decoration.borderRadius,
      shape: decoration.shape,
    );
    final edged = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: edge,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: fill,
        padding: borderInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only the toolbar and the counter follow every keystroke.
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _toolbar(context, resolved),
            ),
            Divider(dividerStyle: resolved.toolbarDividerStyle),
            body,
          ],
        ),
      ),
    );
    return active == null
        ? edged
        : DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: active,
            child: edged,
          );
  }

  Widget _toolbar(BuildContext context, ResolvedRichEditor resolved) {
    // The strip at the top of the box: the toolbar's own fill and inset
    // around the buttons (and the app's trailing control). The image button
    // is there only while the app can store the file and delete it again; a
    // group left empty by that leaves no gap.
    return ColoredBox(
      color: resolved.toolbarBackgroundColor,
      child: Padding(
        padding: resolved.toolbarPadding,
        child: RichEditorToolbarBar(
          groups: CoreRichEditorFormat.visibleToolbar(
            widget.toolbar,
            images: _images.enabled,
          ),
          resolved: resolved,
          apple: _apple,
          isOn: _isOn,
          canApply: _canApply,
          onApply: _handleApply,
          trailing: widget.toolbarTrailing,
          groupDividers: true,
          onMenuOpenChanged: _handleMenu,
        ),
      ),
    );
  }
}

/// The toolbar icon of [format].
IconName richEditorFormatIcon(CoreRichEditorFormat format) => switch (format) {
  CoreRichEditorFormat.bold => LucideIcons.bold,
  CoreRichEditorFormat.italic => LucideIcons.italic,
  CoreRichEditorFormat.strikethrough => LucideIcons.strikethrough,
  CoreRichEditorFormat.code => LucideIcons.code,
  CoreRichEditorFormat.link => LucideIcons.link,
  CoreRichEditorFormat.bulletedList => LucideIcons.list,
  CoreRichEditorFormat.numberedList => LucideIcons.listOrdered,
  CoreRichEditorFormat.taskList => LucideIcons.listTodo,
  CoreRichEditorFormat.quote => LucideIcons.quote,
  CoreRichEditorFormat.heading1 => LucideIcons.heading1,
  CoreRichEditorFormat.heading2 => LucideIcons.heading2,
  CoreRichEditorFormat.heading3 => LucideIcons.heading3,
  CoreRichEditorFormat.image => LucideIcons.image,
  // The block-type button is drawn as its label and this chevron.
  CoreRichEditorFormat.blockType => LucideIcons.chevronDown,
};

/// The localized name of [format].
String richEditorFormatLabel(
  CoreRichEditorFormat format,
  CoUILocalizations localizations,
) => switch (format) {
  CoreRichEditorFormat.bold => localizations.richEditorBold,
  CoreRichEditorFormat.italic => localizations.richEditorItalic,
  CoreRichEditorFormat.strikethrough => localizations.richEditorStrikethrough,
  CoreRichEditorFormat.code => localizations.richEditorCode,
  CoreRichEditorFormat.link => localizations.richEditorLink,
  CoreRichEditorFormat.bulletedList => localizations.richEditorBulletedList,
  CoreRichEditorFormat.numberedList => localizations.richEditorNumberedList,
  CoreRichEditorFormat.taskList => localizations.richEditorTaskList,
  CoreRichEditorFormat.quote => localizations.richEditorQuote,
  CoreRichEditorFormat.heading1 => localizations.richEditorHeading1,
  CoreRichEditorFormat.heading2 => localizations.richEditorHeading2,
  CoreRichEditorFormat.heading3 => localizations.richEditorHeading3,
  CoreRichEditorFormat.image => localizations.richEditorImage,
  // What the block-type button picks; its visible label is the block.
  CoreRichEditorFormat.blockType => localizations.richEditorBlockType,
};

/// The editor's own link dialog: a URL field, remove (when editing a link)
/// and OK.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.current});

  final String? current;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _url = TextEditingController(text: widget.current ?? '');
  bool _invalid = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _handleApply() {
    final target = CoreRichEditorContract.normalizeLink(_url.text);
    if (target == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    return Dialog(
      key: const ValueKey<String>('richEditor.linkDialog'),
      title: Text(localizations.richEditorLink),
      content: TextField(
        key: const ValueKey<String>('richEditor.linkDialog.url'),
        controller: _url,
        label: localizations.richEditorLinkUrl,
        placeholder: const Text('https://'),
        autofocus: true,
        errorText: _invalid ? localizations.richEditorLinkInvalid : null,
        onSubmitted: (_) => _handleApply(),
      ),
      actions: [
        if (widget.current != null)
          Button(
            key: const ValueKey<String>('richEditor.linkDialog.remove'),
            variant: CoreButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(localizations.richEditorLinkRemove),
          ),
        Button(
          key: const ValueKey<String>('richEditor.linkDialog.cancel'),
          variant: CoreButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.buttonCancel),
        ),
        Button(
          key: const ValueKey<String>('richEditor.linkDialog.ok'),
          onPressed: _handleApply,
          child: Text(localizations.buttonOk),
        ),
      ],
    );
  }
}

/// The caret's layer in an editor without focus.
se.ContentLayerWidget _noCaret(
  BuildContext context,
  se.SuperEditorContext _,
) => const se.EmptyContentLayer();
