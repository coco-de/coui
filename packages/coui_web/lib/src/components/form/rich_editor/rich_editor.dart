import 'dart:async';
import 'dart:typed_data';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/display/loading/loading.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_dom.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_markdown.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_selection_toolbar.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_toolbar.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/alert/alert.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart'
    show scheduleNextFrame;
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

int _coRichEditorScopeCounter = 0;

/// A WYSIWYG Markdown composer for posts and comments — a box that looks
/// like a `TextArea`, with a formatting toolbar at the top inside its border.
///
/// [RichEditor] implements [CoreRichEditorContract] for cross-platform API
/// parity with the Flutter implementation. The value in and out is
/// GitHub-flavoured Markdown ([initialValue], [onChanged], [onSubmit]); the
/// user sees and edits the formatted text.
///
/// The web editor keeps its document in the DOM (a `contenteditable`
/// surface), so it has no controller — [controller] and [focusNode] are
/// `Null`. The server renders the first paint from [initialValue]; the
/// browser takes the document over once the page hydrates.
///
/// The toolbar is a strip across the top of the box, so the box's border,
/// its focus ring and its tint wrap the strip and the text as one. A gap and
/// a line separate its groups of buttons. What the app puts in
/// [toolbarTrailing] sits at the strip's far end, and wraps onto a row of its
/// own below the buttons when they leave it no room. The rows that report an
/// image upload sit above the box and the character counter below it, outside
/// its border.
///
/// The toolbar starts with the block-type button: the caret's block (Text,
/// Heading 1 … 3) and a chevron, opening a menu of the four. The headings
/// keep their shortcuts (Mod+Alt+1 / 2 / 3), and `# `, `## ` and `### ` at a
/// line's start make the same headings. **Images**
/// need the app: with an [onImageUpload] and an [onImageDelete] the toolbar
/// gains an image button that opens the browser's file picker, uploads the
/// chosen file through the callback and puts the returned address in the
/// document as `![name](url)`, in a block of its own after the line the
/// caret was on; without both there is no button and the editor never
/// reaches for the network. [onImageDelete] is told when an image it
/// uploaded has been taken out of the document (see
/// [CoreRichEditorContract.onImageDelete]). The two come as a pair: an
/// [onImageUpload] with no [onImageDelete] asserts in debug builds, since
/// every image the user took out would stay on the server.
///
/// **Selection toolbar.** Selecting text, with the pointer or from the
/// keyboard, floats the same formatting buttons over the selection (without
/// the image button): centred above it, below when there is no room above,
/// and held inside the viewport. It follows the selection, and goes when the
/// selection collapses, on Escape, and when the editor loses the focus to
/// anything but the toolbar and its menu. Alt+F10 moves the focus from the
/// text into it. [showSelectionToolbar] turns it off; a disabled or
/// read-only editor never shows it.
///
/// Example:
/// ```dart
/// RichEditor(
///   placeholder: 'Write a comment…',
///   maxLength: 2000,
///   onChanged: (markdown) => draft = markdown,
///   onSubmit: (markdown) => post(markdown),
/// )
/// ```
///
/// surface:behind — the box is the composed `TextArea`'s, painted on the
/// wrapper that holds the toolbar and the editing surface.
///
/// surface:content — the box sits in the flow like a `TextArea`; the
/// tooltips and the link dialog it opens mount over content.
class RichEditor extends UiStatefulComponent
    implements CoreRichEditorContract<Component, Null, Null> {
  /// Creates a [RichEditor].
  const RichEditor({
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    // === Contract — Content ===
    this.initialValue,
    this.onChanged,
    this.onSubmit,
    this.placeholder,
    // === Contract — State ===
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    // === Contract — Toolbar ===
    this.showToolbar = CoreRichEditorContract.defaultShowToolbar,
    this.toolbarTrailing,
    this.toolbar = CoreRichEditorFormat.defaultToolbar,
    this.showSelectionToolbar =
        CoreRichEditorContract.defaultShowSelectionToolbar,
    this.onLinkRequest,
    // === Contract — Images ===
    this.onImageUpload,
    this.onImageDelete,
    this.maxImageBytes = CoreRichEditorContract.defaultMaxImageBytes,
    // === Style ===
    this.richEditorStyle,
    // === Controllers (Flutter only) ===
    this.controller,
    this.focusNode,
  }) : assert(
         onImageUpload == null || onImageDelete != null,
         'RichEditor: onImageUpload needs an onImageDelete — without it every '
         'image the user takes out stays on the server. Pass a delete that '
         'does nothing if the server cleans up on its own.',
       );

  @override
  final String? initialValue;

  @override
  final CoreValueChanged<String>? onChanged;

  @override
  final CoreValueChanged<String>? onSubmit;

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
  final Component? toolbarTrailing;

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

  /// Always null on the web — the document lives in the DOM.
  @override
  final Null controller;

  /// Always null on the web — focus is the browser's.
  @override
  final Null focusNode;

  @override
  State<RichEditor> createState() => _RichEditorState();
}

class _RichEditorState extends State<RichEditor> {
  /// Stable per-instance id of the editing surface — the bridge finds the
  /// element by it, and the document rules are scoped to it.
  late final String _surfaceId;

  /// The surface's markup at first paint (server-rendered).
  late final String _initialHtml;

  /// The editor's current Markdown.
  String _value = '';

  /// The formats on at the caret — the toolbar's held-down buttons.
  Set<CoreRichEditorFormat> _active = const {};

  /// Whether shortcuts read ⌘ (Apple) rather than Ctrl. Known only in the
  /// browser; the server renders the Ctrl spelling.
  bool _apple = false;

  /// Keyboard focus on the surface, forwarded to `FocusOutline`.
  bool _focused = false;
  final _focusModality = CoreInputFocusModality();

  bool _isMounted = false;
  void Function()? _disposeSelection;

  /// The uploads under way or failed, and which uploaded images may be
  /// deleted from the server — the state both editors share.
  late final CoreRichEditorImages _images;

  // The editor's own link dialog (when no `onLinkRequest` is given).
  bool _linkDialogOpen = false;
  String _linkDraft = '';
  String? _linkCurrent;
  String? _linkError;

  /// Opens and closes the block-type menu.
  final _blockTypeMenu = PopoverController();

  // ─── The toolbar over a selection ──────────────────────────────────

  /// The id of the floating toolbar's positioning wrapper — what the
  /// positioner measures and places.
  late final String _selectionToolbarId;

  /// Opens and closes the block-type menu of the toolbar over a selection.
  final _selectionBlockTypeMenu = PopoverController();

  /// Opens and closes the "more" menu of the toolbar over a selection — the
  /// buttons it folded for want of room.
  final _selectionMoreMenu = PopoverController();

  /// How many units of the fold order the toolbar over the selection has
  /// folded — measured against the room the engine leaves it each time the
  /// panel is placed.
  int _selectionFoldSteps = 0;

  /// The fold changed on the last measure and the panel is about to be
  /// drawn again: the position the engine computed for the old width is not
  /// applied, the next placement's is.
  bool _selectionFoldStale = false;

  /// A selection is being grown from the keyboard (Shift+Arrow) and has not
  /// held still for `CoreRichEditorContract.selectionToolbarKeyboardDelay`
  /// yet; the toolbar waits, so a key held down does not flicker it.
  bool _keyboardSelecting = false;
  Timer? _keyboardSelectionSettle;

  /// Whether the toolbar over the selection is in the DOM. Stays true
  /// through its exit animation, until [_selectionToolbarExit] unmounts it.
  bool _selectionToolbarOpen = false;

  /// Whether the toolbar is playing its exit before it is unmounted.
  bool _selectionToolbarClosing = false;
  Timer? _selectionToolbarExit;

  /// The flip/shift-resolved origin of the toolbar, fed back from
  /// [_selectionToolbarPositioner]. Null until it has been placed.
  double? _selectionToolbarLeft;
  double? _selectionToolbarTop;

  /// The shared positioning engine, anchored to the selected text's box.
  OverlayPositioner? _selectionToolbarPositioner;

  OverlayController? _overlayController;
  int? _overlayToken;

  /// A pointer is down on the surface — a selection is being dragged out,
  /// and the toolbar waits for the pointer to come up.
  bool _pointerDown = false;

  /// The selection Escape closed the toolbar on; it stays closed until the
  /// selection is another one.
  String? _dismissedSelection;

  /// A menu of this editor's toolbars is open, or closed and still fading
  /// out: it holds the focus — and the page inert — and that is not the
  /// editor losing it.
  bool _menuHeld = false;

  /// The direction the surface's text runs in, carried onto the toolbar.
  String? _direction;

  void Function()? _disposeViewport;

  bool get _editable => component.enabled && !component.readOnly;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _images = CoreRichEditorImages(onChanged: _handleImagesChanged);
    _configureImages();
    _surfaceId =
        'co-rich-editor-${kIsWeb ? 'web' : 'ssr'}-'
        '${_coRichEditorScopeCounter++}';
    _selectionToolbarId = '$_surfaceId-selection-toolbar';
    _blockTypeMenu.addListener(_handleMenuChanged);
    _selectionBlockTypeMenu.addListener(_handleMenuChanged);
    _selectionMoreMenu.addListener(_handleMenuChanged);
    final nodes = parseRichEditorMarkdown(component.initialValue ?? '');
    _initialHtml = renderRichEditorHtml(nodes);
    // The value is the editor's own reading of the document, so it is the
    // same Markdown the first edit reports from.
    _value = serializeRichEditorMarkdown(nodes);
    // The document is the browser's from the first client frame on: the
    // surface renders no children there, and its markup is seeded once.
    if (kIsWeb) scheduleNextFrame(_attach);
  }

  void _attach() {
    if (!_isMounted) return;
    richEditorSeed(_surfaceId, _initialHtml);
    _disposeSelection = richEditorListenSelection(_surfaceId, _handleSelection);
    _disposeViewport = richEditorListenViewport(_handleViewport);
    final apple = richEditorIsApple();
    if (apple != _apple) setState(() => _apple = apple);
    if (component.autofocus && _editable) richEditorFocus(_surfaceId);
  }

  @override
  void didUpdateComponent(RichEditor oldComponent) {
    super.didUpdateComponent(oldComponent);
    _configureImages();
    // An editor switched off, or told to show no toolbar over a selection,
    // closes the one that is open.
    if (_selectionToolbarOpen) _scheduleSelectionToolbarSync();
  }

  @override
  void dispose() {
    _isMounted = false;
    _disposeSelection?.call();
    _disposeViewport?.call();
    _images.dispose();
    _selectionToolbarExit?.cancel();
    _keyboardSelectionSettle?.cancel();
    _selectionToolbarPositioner?.dispose();
    _selectionToolbarPositioner = null;
    _unmountSelectionToolbar();
    _blockTypeMenu
      ..removeListener(_handleMenuChanged)
      ..dispose();
    _selectionBlockTypeMenu
      ..removeListener(_handleMenuChanged)
      ..dispose();
    _selectionMoreMenu
      ..removeListener(_handleMenuChanged)
      ..dispose();
    super.dispose();
  }

  void _configureImages() {
    _images
      ..upload = component.onImageUpload
      ..delete = component.onImageDelete
      ..maxBytes = component.maxImageBytes;
  }

  void _handleImagesChanged() {
    if (_isMounted) setState(() {});
  }

  // ─── Document changes ──────────────────────────────────────────────

  void _handleSelection() {
    richEditorSaveSelection(_surfaceId);
    _syncActive();
    _syncSelectionToolbar();
  }

  // ─── The toolbar over a selection ──────────────────────────────────

  /// Looks at the selection and the focus again once the browser has
  /// settled them — a blur reports before the element that takes the focus
  /// has it.
  void _scheduleSelectionToolbarSync() => scheduleNextFrame(() {
    if (_isMounted) _syncSelectionToolbar();
  });

  /// Opens, moves or closes the toolbar over the selection to match the
  /// editor as it is now.
  void _syncSelectionToolbar() {
    if (!_isMounted) return;
    final dismissed = _dismissedSelection;
    if (dismissed != null &&
        richEditorSelectionSignature(_surfaceId) != dismissed) {
      _dismissedSelection = null;
    }
    final menuOpen = _menuHeld;
    final wanted = CoreRichEditorContract.showsSelectionToolbar(
      showSelectionToolbar: component.showSelectionToolbar,
      enabled: component.enabled,
      readOnly: component.readOnly,
      // The selected text that is in view: scrolled out of the surface, it
      // has nothing for the toolbar to sit over.
      hasSelectedText: richEditorSelectionRect(_surfaceId) != null,
      selecting: _pointerDown || _keyboardSelecting,
      dismissed: _dismissedSelection != null,
      focused:
          menuOpen || richEditorHasFocusIn([_surfaceId, _selectionToolbarId]),
    );
    final showing = _selectionToolbarOpen && !_selectionToolbarClosing;
    if (!wanted) {
      if (showing) _closeSelectionToolbar();
      return;
    }
    if (!showing) {
      _openSelectionToolbar();
      // The engine is one positioner at a time: placing the toolbar again
      // under its own open menu would close the menu.
    } else if (!menuOpen) {
      _placeSelectionToolbar();
    }
  }

  void _openSelectionToolbar() {
    _selectionToolbarExit?.cancel();
    _selectionToolbarExit = null;
    setState(() {
      _selectionToolbarOpen = true;
      _selectionToolbarClosing = false;
      _direction = richEditorDirectionOf(_surfaceId);
    });
    // Next frame: the panel is in the DOM (still hidden — unplaced), and the
    // positioner can measure it.
    scheduleNextFrame(() {
      if (!_isMounted || !_selectionToolbarOpen || _selectionToolbarClosing) {
        return;
      }
      _placeSelectionToolbar();
    });
  }

  /// Places the toolbar against the selected text as it is now: centred
  /// above it, below when there is no room, held inside the viewport — all
  /// of it the shared engine's. The engine also places it again when the
  /// page scrolls.
  void _placeSelectionToolbar() {
    final existing = _selectionToolbarPositioner;
    if (existing != null) {
      // Another overlay that opened since — a tooltip of one of the buttons
      // — took the engine's one slot and closed this positioner: open it
      // again.
      if (existing.isOpen) {
        existing.update();
      } else {
        existing.open();
      }
      return;
    }
    final config = resolveRichEditorSelectionToolbarConfig(
      context,
      richEditorStyle: component.richEditorStyle,
    );
    _selectionToolbarPositioner = OverlayPositioner(
      triggerId: _surfaceId,
      popoverId: _selectionToolbarId,
      placement: config.placement,
      gap: config.gap,
      viewportPadding: config.viewportPadding,
      // The editor opens and closes it.
      closeOnOutsideClick: false,
      closeOnEsc: false,
      closeOnScroll: false,
      measureAnchor: () => richEditorSelectionRect(_surfaceId),
      // While the toolbar in the box shows, the room above the selection
      // ends where the editing surface begins: a selection on the first
      // line gets the toolbar below it rather than over the toolbar in the
      // box.
      measureTopInset: component.showToolbar
          ? () => richEditorSurfaceTop(_surfaceId) ?? 0
          : null,
      onPanelMeasured: (_) => _measureSelectionToolbarFold(config),
      onPosition: (left, top, _) {
        if (!_isMounted) return;
        // Measured at a width about to change: placed again next frame.
        if (_selectionFoldStale) return;
        if (left == _selectionToolbarLeft && top == _selectionToolbarTop) {
          return;
        }
        setState(() {
          _selectionToolbarLeft = left;
          _selectionToolbarTop = top;
        });
      },
    )..open();
  }

  /// Folds the toolbar's buttons to the room the engine leaves the panel —
  /// the viewport less its padding — from the units' measured widths, by
  /// the one rule both platforms read. A fold that changed is drawn and
  /// placed again next frame.
  void _measureSelectionToolbarFold(
    ({
      CorePopoverPlacement placement,
      double gap,
      CoreEdgeInsets viewportPadding,
      Duration closeDuration,
    })
    config,
  ) {
    if (!_isMounted) return;
    final measure = richEditorMeasureFold(_selectionToolbarId);
    if (measure == null) return;
    final padding = config.viewportPadding;
    final steps = CoreRichEditorContract.selectionToolbarFoldSteps(
      available:
          richEditorViewportWidth() -
          padding.left -
          padding.right -
          measure.chrome,
      pinnedWidth: measure.pinned,
      moreWidth: measure.more,
      unitWidths: measure.units,
    );
    if (steps == _selectionFoldSteps) {
      _selectionFoldStale = false;
      return;
    }
    _selectionFoldStale = true;
    setState(() => _selectionFoldSteps = steps);
    scheduleNextFrame(() {
      if (!_isMounted) return;
      _selectionFoldStale = false;
      _selectionToolbarPositioner?.update();
    });
  }

  void _closeSelectionToolbar() {
    if (!_selectionToolbarOpen || _selectionToolbarClosing) return;
    final positioner = _selectionToolbarPositioner;
    _selectionToolbarPositioner = null;
    positioner?.dispose();
    final closeDuration = resolveRichEditorSelectionToolbarConfig(
      context,
      richEditorStyle: component.richEditorStyle,
    ).closeDuration;
    // Re-render with the exit animation while still mounted, then unmount.
    setState(() => _selectionToolbarClosing = true);
    _selectionToolbarExit?.cancel();
    _selectionToolbarExit = Timer(closeDuration, () {
      _selectionToolbarExit = null;
      if (!_isMounted) return;
      setState(() {
        _selectionToolbarOpen = false;
        _selectionToolbarClosing = false;
        _selectionToolbarLeft = null;
        _selectionToolbarTop = null;
        _selectionFoldSteps = 0;
        _selectionFoldStale = false;
      });
      _unmountSelectionToolbar();
    });
  }

  void _unmountSelectionToolbar() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) controller.unmount(token);
    _overlayController = null;
    _overlayToken = null;
  }

  void _scheduleSelectionToolbarPortal(
    OverlayController controller,
    Component? entry,
  ) {
    // Deferred: mounting notifies the host, which must not rebuild while
    // this build is under way.
    unawaited(
      Future<void>.microtask(() {
        if (!_isMounted) return;
        if (entry == null) {
          if (_overlayController != null) _unmountSelectionToolbar();
          return;
        }
        if (_overlayController != controller) {
          _unmountSelectionToolbar();
          _overlayController = controller;
        }
        final token = _overlayToken;
        if (token == null) {
          _overlayToken = controller.mount(layer: .popover, panel: entry);
        } else {
          controller.update(token, entry);
        }
      }),
    );
  }

  /// The focus left a button of the toolbar over the selection: looked at
  /// once the browser has moved it — to the text, to a menu, or away.
  void _handleSelectionToolbarFocusOut() => _scheduleSelectionToolbarSync();

  /// Escape: the toolbar goes and stays away until the selection changes,
  /// and the focus is back in the text with the selection as it was.
  void _handleDismissSelectionToolbar() {
    _dismissedSelection = richEditorSelectionSignature(_surfaceId);
    if (!richEditorHasFocusIn([_surfaceId])) {
      richEditorRestoreSelection(_surfaceId);
    }
    _syncSelectionToolbar();
  }

  /// A menu of the editor's toolbars — a block-type menu, the "more" menu
  /// of the toolbar over the selection — opened or closed. The menu holds
  /// the focus while it is open; one that closes without a pick hands it
  /// back to the text, so the toolbar over the selection stays.
  void _handleMenuChanged() {
    if (_blockTypeMenu.isOpen ||
        _selectionBlockTypeMenu.isOpen ||
        _selectionMoreMenu.isOpen) {
      _menuHeld = true;
      return;
    }
    // Closed, but the page is inert until the menu has faded out: the focus
    // can go back to the text only then.
    richEditorWhenInteractive(_surfaceId, () {
      if (!_isMounted) return;
      _menuHeld = false;
      if (_selectionToolbarOpen &&
          !_selectionToolbarClosing &&
          !richEditorHasFocusIn([_surfaceId])) {
        richEditorRestoreSelection(_surfaceId);
      }
      _scheduleSelectionToolbarSync();
    });
  }

  /// A pointer came up somewhere, or the page moved under the selection.
  void _handleViewport({required bool pointer}) {
    if (pointer) {
      if (!_pointerDown) return;
      _pointerDown = false;
    } else if (!_selectionToolbarOpen &&
        richEditorSelectionSignature(_surfaceId) == null) {
      // Nothing is selected: the move changes nothing for the toolbar. With
      // a selection, a toolbar that went when its text scrolled out of view
      // comes back once the text does.
      return;
    }
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
        if (!_isMounted || !_keyboardSelecting) return;
        _keyboardSelecting = false;
        _syncSelectionToolbar();
      },
    );
    if (_keyboardSelecting) return;
    _keyboardSelecting = true;
    _syncSelectionToolbar();
  }

  Component _buildSelectionToolbar(ResolvedRichEditor resolved) =>
      RichEditorSelectionToolbar(
        panelId: _selectionToolbarId,
        chrome: resolveRichEditorSelectionToolbar(
          context,
          closing: _selectionToolbarClosing,
          left: _selectionToolbarLeft,
          top: _selectionToolbarTop,
          richEditorStyle: component.richEditorStyle,
        ),
        resolved: resolved,
        active: _active,
        enabled: _editable,
        apple: _apple,
        surfaceId: _surfaceId,
        onFormat: _handleFormat,
        blockTypeMenu: _selectionBlockTypeMenu,
        moreMenu: _selectionMoreMenu,
        foldSteps: _selectionFoldSteps,
        direction: _direction,
        onDismiss: _handleDismissSelectionToolbar,
        onFocusOut: _handleSelectionToolbarFocusOut,
      );

  void _syncActive() {
    final active = richEditorActiveFormats(_surfaceId);
    if (!_sameFormats(active, _active)) setState(() => _active = active);
  }

  static bool _sameFormats(
    Set<CoreRichEditorFormat> a,
    Set<CoreRichEditorFormat> b,
  ) => a.length == b.length && a.containsAll(b);

  /// Reads the document back after an edit and reports the new Markdown.
  void _afterEdit() {
    final nodes = richEditorRead(_surfaceId);
    _images.sync(richEditorImageUrls(nodes));
    final markdown = serializeRichEditorMarkdown(nodes);
    _syncActive();
    if (markdown == _value) return;
    setState(() => _value = markdown);
    component.onChanged?.call(markdown);
  }

  void _handleFormat(CoreRichEditorFormat format) {
    if (!_editable) return;
    // At once for a button press. A row of the block-type menu is picked
    // while the menu — a modal overlay — still holds the page inert: the
    // surface would refuse the focus and the edit, so it waits for the menu
    // to go.
    richEditorWhenInteractive(_surfaceId, () {
      if (!_isMounted || !_editable) return;
      richEditorRestoreSelection(_surfaceId);
      if (format == .link) {
        unawaited(_requestLink());
        return;
      }
      if (format == .image) {
        unawaited(_requestImage());
        return;
      }
      richEditorApply(_surfaceId, format);
      _afterEdit();
    });
  }

  // ─── Images ────────────────────────────────────────────────────────

  /// What the file picker lists: the accepted types and their extensions
  /// (some systems know a file by one and not the other).
  static final List<String> _imageAccept = [
    ...CoreRichEditorImage.mimeTypes,
    for (final extension in CoreRichEditorImage.extensions) '.$extension',
  ];

  /// Opens the file picker, uploads the chosen image through
  /// [RichEditor.onImageUpload] and puts it in the document where the caret
  /// was when the button was pressed.
  Future<void> _requestImage() async {
    if (!_images.enabled || !_editable) return;
    // Both calls come before the first `await`: a browser opens its file
    // picker only inside the click that asked for it.
    final anchor = richEditorMarkAnchor(_surfaceId);
    final picked = richEditorPickImage(accept: _imageAccept);

    void forgetAnchor() {
      if (anchor != null) richEditorDropAnchor(anchor);
    }

    final file = await picked;
    if (!_isMounted || file == null) {
      forgetAnchor();
      return;
    }
    // Refused before its bytes are read: a file too big or of the wrong
    // type never reaches memory.
    final issue = CoreRichEditorImage.check(
      name: file.name,
      mimeType: file.mimeType,
      size: file.size,
      maxBytes: component.maxImageBytes,
    );
    final mimeType = file.mimeType.isEmpty
        ? CoreRichEditorImage.mimeTypeOf(file.name)
        : file.mimeType;
    if (issue != null || mimeType == null) {
      forgetAnchor();
      _images.reject(file.name, issue ?? CoreRichEditorImageIssue.notAllowed);
      return;
    }
    final Uint8List bytes;
    try {
      bytes = await file.readBytes();
    } on Object {
      forgetAnchor();
      if (_isMounted) {
        _images.reject(file.name, CoreRichEditorImageIssue.uploadFailed);
      }
      return;
    }
    final url = await _images.submit(
      CoreRichEditorImageFile(
        name: file.name,
        mimeType: mimeType,
        bytes: bytes,
      ),
    );
    if (!_isMounted || url == null) {
      forgetAnchor();
      return;
    }
    // An editor that was switched off while the file travelled takes no
    // image; the sync below hands the upload back for deletion.
    if (_editable && anchor != null) {
      richEditorInsertImage(
        _surfaceId,
        anchor,
        url,
        CoreRichEditorImage.altTextFor(file.name),
      );
    } else {
      forgetAnchor();
    }
    _afterEdit();
  }

  // ─── Links ─────────────────────────────────────────────────────────

  Future<void> _requestLink() async {
    richEditorSaveSelection(_surfaceId);
    final current = richEditorLinkAtCaret(_surfaceId);
    final request = component.onLinkRequest;
    if (request == null) {
      setState(() {
        _linkDialogOpen = true;
        _linkDraft = current ?? '';
        _linkCurrent = current;
        _linkError = null;
      });
      return;
    }
    final result = await request(current);
    if (!_isMounted || result == null) return;
    if (result.trim().isEmpty) {
      _commitLink(null);
      return;
    }
    final href = CoreRichEditorContract.normalizeLink(result);
    if (href != null) _commitLink(href);
  }

  /// Links the remembered selection to [href]; null removes the link.
  void _commitLink(String? href) {
    richEditorRestoreSelection(_surfaceId);
    richEditorSetLink(_surfaceId, href);
    _afterEdit();
  }

  void _handleConfirmLinkDialog() {
    final draft = _linkDraft.trim();
    if (draft.isEmpty) {
      _handleCloseLinkDialog();
      if (_linkCurrent != null) _commitLink(null);
      return;
    }
    final href = CoreRichEditorContract.normalizeLink(draft);
    if (href == null) {
      setState(
        () => _linkError = CouiLocalizations.of(context).richEditorLinkInvalid,
      );
      return;
    }
    _handleCloseLinkDialog();
    _commitLink(href);
  }

  void _handleRemoveLinkFromDialog() {
    _handleCloseLinkDialog();
    _commitLink(null);
  }

  void _handleCloseLinkDialog() {
    if (!_linkDialogOpen) return;
    setState(() => _linkDialogOpen = false);
    richEditorRestoreSelection(_surfaceId);
  }

  // ─── Surface events ────────────────────────────────────────────────

  void _onKeyDown(Object event) {
    final key = richEditorKeyOf(event, apple: _apple);
    // The toolbar over the selection: Escape closes it, Alt+F10 moves the
    // focus into it. Without it both keys are the page's.
    if (_selectionToolbarOpen && !_selectionToolbarClosing) {
      if (key.escape) {
        richEditorPreventDefault(event);
        _handleDismissSelectionToolbar();
        return;
      }
      if (key.toolbarFocus) {
        richEditorPreventDefault(event);
        richEditorFocusFirstButton(_selectionToolbarId);
        return;
      }
    }
    // Shift+Arrow grows the selection: the toolbar over it waits for the
    // selection to hold still. The key itself is the browser's.
    if (key.selects) _handleKeyboardSelection();
    if (key.mod && key.enter) {
      final onSubmit = component.onSubmit;
      if (onSubmit == null) return;
      richEditorPreventDefault(event);
      onSubmit(_value);
      return;
    }
    if (key.enter && !key.mod && !key.shift) {
      if (richEditorEnterRule(_surfaceId)) {
        richEditorPreventDefault(event);
        _afterEdit();
      }
      return;
    }
    final shortcutKey = key.shortcutKey;
    if (shortcutKey == null) return;
    final format = CoreRichEditorFormat.forKey(
      shortcutKey,
      shift: key.shift,
      alt: key.alt,
    );
    if (format == null) return;
    richEditorPreventDefault(event);
    _handleFormat(format);
  }

  void _onBeforeInput(Object event) {
    final maxLength = component.maxLength;
    if (maxLength == null || !richEditorInsertsText(event)) return;
    if (_value.length >= maxLength) richEditorPreventDefault(event);
  }

  void _onPaste(Object event) {
    final maxLength = component.maxLength;
    richEditorPastePlainText(
      event,
      limit: maxLength == null ? null : maxLength - _value.length,
    );
  }

  void _onInput(Object event) {
    richEditorAutoformat(_surfaceId, event);
    _afterEdit();
  }

  /// Pressing the toolbar — the whole strip, its trailing slot too — or a row
  /// above the box, must not take focus from the surface. A press that does
  /// blurs it, the blur re-renders the editor between the mouse going down
  /// and coming up, and the icon under the pointer is a new node by then: the
  /// browser drops the click. Keeping focus (and the selection) in the
  /// surface also leaves the caret where the user had it. Keyboard
  /// activation does not press, so it is untouched.
  static final Map<String, EventCallback> _keepSurfaceFocus = {
    'mousedown': richEditorPreventDefault,
  };

  Map<String, EventCallback> _buildSurfaceEvents() => {
    if (_editable) ...{
      'keydown': _onKeyDown,
      'beforeinput': _onBeforeInput,
      'input': _onInput,
      'paste': _onPaste,
      // A dropped file would bring the browser's own <img> into the surface.
      'dragover': richEditorBlockFileDrop,
      'drop': richEditorBlockFileDrop,
      // A task's checkbox toggles on click, which fires no `input`; a
      // click on an image selects it, so it shows as selected.
      'click': (event) {
        richEditorSelectImage(event);
        _afterEdit();
      },
    },
    // Mirror W3C `:focus-visible`: ring on iff focus arrived via keyboard,
    // the TextArea's model.
    'focus': EventHandlers.createElementTargetEventHandler((_, target) {
      final visible = _focusModality.focus(
        platformShowsRing: target.matches(':focus-visible'),
      );
      _setFocused(visible);
    }),
    'blur': (_) {
      _focusModality.blur();
      richEditorSaveSelection(_surfaceId);
      _setFocused(false);
      // The focus may have gone to the toolbar over the selection, or left
      // the editor: looked at once the browser has moved it.
      _scheduleSelectionToolbarSync();
    },
    'pointerdown': (_) {
      _focusModality.pointerDown();
      // A drag that selects is under way until the pointer comes up.
      _pointerDown = true;
      if (_selectionToolbarOpen) _syncSelectionToolbar();
    },
  };

  /// Re-renders only when the ring changes. Focus that arrives by mouse
  /// shows no ring, and the blur that follows it changes nothing, so neither
  /// may re-render: a re-render replaces the icons under the pointer, and a
  /// click that began with such a blur (a host page moving focus on a press,
  /// as an embedded Flutter view does) would be dropped by the browser.
  void _setFocused(bool value) {
    if (value != _focused) setState(() => _focused = value);
  }

  Map<String, String> _buildSurfaceAttributes(String imageUnavailable) {
    final placeholder = component.placeholder;
    return {
      'contenteditable': _editable ? 'true' : 'false',
      'role': 'textbox',
      'aria-multiline': 'true',
      // What a tooltip on an image that cannot be loaded says (the bridge
      // reads it when the load fails).
      'data-unavailable-label': imageUnavailable,
      if (!component.enabled) 'aria-disabled': 'true',
      if (component.readOnly) 'aria-readonly': 'true',
      // Read-only text can still be selected and copied, so it keeps its
      // tab stop.
      if (component.readOnly && component.enabled) 'tabindex': '0',
      if (placeholder != null) ...{
        'aria-placeholder': placeholder,
        'data-placeholder': placeholder,
        if (_value.isEmpty) 'data-empty': '',
      },
    };
  }

  // ─── Toolbar ───────────────────────────────────────────────────────

  /// The strip at the top of the box: the buttons, and what the app put at
  /// its far end. It wraps that onto a row of its own below the buttons when
  /// they leave it no room.
  Component _buildToolbar(ResolvedRichEditor resolved, CouiLocalizations l10n) {
    final groups = CoreRichEditorFormat.visibleToolbar(
      component.toolbar,
      images: _images.enabled,
    );
    final trailing = component.toolbarTrailing;
    return div(
      [
        RichEditorToolbarBar(
          groups: groups,
          resolved: resolved,
          active: _active,
          enabled: _editable,
          apple: _apple,
          surfaceId: _surfaceId,
          onFormat: _handleFormat,
          blockTypeMenu: _blockTypeMenu,
        ),
        if (trailing != null)
          div(
            [trailing],
            classes: resolved.toolbarTrailing.className,
            styles: resolved.toolbarTrailing.inlineStyles,
          ),
      ],
      classes: resolved.toolbar.className,
      styles: resolved.toolbar.inlineStyles,
      events: _keepSurfaceFocus,
      attributes: {
        'role': 'toolbar',
        'aria-label': l10n.richEditorToolbar,
        'aria-controls': _surfaceId,
      },
    );
  }

  static String _issueMessage(
    CouiLocalizations l10n,
    CoreRichEditorImageIssue issue,
  ) => switch (issue) {
    .notAllowed => l10n.richEditorImageNotAllowed,
    .tooLarge => l10n.richEditorImageTooLarge,
    .uploadFailed => l10n.richEditorImageUploadFailed,
  };

  /// Removes the failed row [id]. The row that was dismissed may hold the
  /// keyboard's focus, which would then fall to the page: it goes back to
  /// the editor, with the caret where the user left it.
  void _handleDismissImage(int id) {
    _images.dismiss(id);
    if (_editable) richEditorRestoreSelection(_surfaceId);
  }

  /// One row above the box per upload under way or failed.
  Component _buildPendingImages(
    ResolvedRichEditor resolved,
    CouiLocalizations l10n,
  ) => div(
    [
      for (final entry in _images.pending)
        if (entry.issue case final issue?)
          Alert.destructive(
            key: ValueKey<int>(entry.id),
            layout: CoreAlertLayout.inline,
            title: '${_issueMessage(l10n, issue)} · ${entry.name}',
            onDismiss: () => _handleDismissImage(entry.id),
            alertStyle: resolved.uploadAlertStyle,
          )
        else
          Alert(
            key: ValueKey<int>(entry.id),
            layout: CoreAlertLayout.inline,
            leading: const Loading(componentSize: CoreComponentSize.xs),
            title: '${l10n.richEditorImageUploading} · ${entry.name}',
            alertStyle: resolved.uploadAlertStyle,
          ),
    ],
    classes: resolved.pendingImages.className,
    styles: resolved.pendingImages.inlineStyles,
    events: _keepSurfaceFocus,
  );

  Component _buildLinkDialog(CouiLocalizations l10n) => Dialog(
    onClose: _handleCloseLinkDialog,
    title: Text(l10n.richEditorLink),
    content: TextField(
      label: l10n.richEditorLinkUrl,
      initialValue: _linkDraft,
      errorText: _linkError,
      autofocus: true,
      onChanged: (value) {
        _linkDraft = value;
        if (_linkError != null) setState(() => _linkError = null);
      },
      onSubmitted: (_) => _handleConfirmLinkDialog(),
    ),
    actions: [
      if (_linkCurrent != null)
        Button(
          variant: .ghost,
          onPressed: _handleRemoveLinkFromDialog,
          child: Text(l10n.richEditorLinkRemove),
        ),
      Button(
        variant: .outline,
        onPressed: _handleCloseLinkDialog,
        child: Text(l10n.buttonCancel),
      ),
      Button(onPressed: _handleConfirmLinkDialog, child: Text(l10n.buttonOk)),
    ],
  );

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    final l10n = CouiLocalizations.of(context);
    final maxLength = component.maxLength;
    final length = _value.length;
    final showsCounter = CoreRichEditorContract.showsCounter(length, maxLength);

    final resolved = resolveRichEditor(
      context,
      enabled: component.enabled,
      counterAtLimit: maxLength != null && length >= maxLength,
      // Only the server paints the document into the surface (below).
      serverRendered: !kIsWeb,
      richEditorStyle: component.richEditorStyle,
    );
    final rules = resolveRichEditorRules(
      context,
      scopeId: _surfaceId,
      richEditorStyle: component.richEditorStyle,
    );

    final surface = Component.element(
      tag: 'div',
      id: _surfaceId,
      classes: resolved.surface.className,
      styles: resolved.surface.inlineStyles,
      attributes: _buildSurfaceAttributes(l10n.richEditorImageUnavailable),
      events: _buildSurfaceEvents(),
      // The server paints the document; in the browser the surface's
      // children are the user's, so the component renders none and never
      // diffs them away. The markup is the codec's own, every text escaped.
      children: [if (!kIsWeb) RawText(_initialHtml)],
    );

    // The box: one border, one fill and one focus tint around the strip, the
    // line under it and the surface. Without a toolbar it holds the surface
    // alone, which is the `TextArea`'s box.
    final box = Component.element(
      tag: 'div',
      classes: resolved.box.className,
      styles: resolved.box.inlineStyles,
      children: [
        if (component.showToolbar) ...[
          _buildToolbar(resolved, l10n),
          Divider(dividerStyle: resolved.toolbarDividerStyle),
        ],
        surface,
      ],
    );

    // The toolbar over the selection is mounted on the page's overlay layer
    // — out of the box's clip — and inline where there is no host.
    final selectionToolbar = _selectionToolbarOpen
        ? _buildSelectionToolbar(resolved)
        : null;
    final portal = OverlayPortal.maybeOf(context);
    if (portal != null) {
      _scheduleSelectionToolbarPortal(
        portal.controller,
        portal.capture(context, selectionToolbar),
      );
    } else if (_overlayController != null) {
      _unmountSelectionToolbar();
    }

    return div(
      [
        Component.element(tag: 'style', children: [RawText(rules.css)]),
        if (_images.pending.isNotEmpty) ...[
          _buildPendingImages(resolved, l10n),
          Gap(gapStyle: resolved.toolbarGapStyle),
        ],
        FocusOutline(
          focused: _focused,
          focusOutlineStyle: resolved.focusOutlineStyle,
          child: box,
        ),
        if (showsCounter) ...[
          Gap(gapStyle: resolved.counterGapStyle),
          div(
            [
              span(
                [Text(CoreRichEditorContract.counterLabel(length, maxLength!))],
                classes: resolved.counter.className,
                styles: resolved.counter.inlineStyles,
              ),
            ],
            classes: resolved.counterRow.className,
            styles: resolved.counterRow.inlineStyles,
          ),
        ],
        if (_linkDialogOpen) _buildLinkDialog(l10n),
        if (portal == null) ?selectionToolbar,
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
