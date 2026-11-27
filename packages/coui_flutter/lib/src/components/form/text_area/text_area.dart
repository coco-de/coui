import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/util/input_focus_ring.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show TextMagnifier;
import 'package:flutter/services.dart';

/// Unified cross-platform multi-line text area with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, the semantic enums (`variant`, `size`)
/// stay as widget parameters. All chrome / dimensional / cursor /
/// nested-slot overrides flow through the single [textAreaStyle]
/// (a [CoreTextFieldStyle] — `TextArea` reuses the same Style class
/// because chrome is identical to `TextField`).
///
/// Supports resizable dimensions via [expandableHeight] and [expandableWidth],
/// and integrates with [CoreTextAreaTheme] for project-level style overrides.
///
/// Example:
/// ```dart
/// TextArea(
///   placeholder: 'Enter your message...',
///   onChanged: handleChanged,
///   expandableHeight: true,
///   textAreaStyle: CoreTextAreaStyle(borderRadius: 8),
/// )
/// ```
///
/// surface:behind — the area's box paints directly on the framed body
/// (native `<textarea>` on Web, a `Container` here) rather than composing
/// `OutlinedContainer`, so what shows through it is the page it is laid
/// on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class TextArea extends StatefulWidget
    implements
        CoreTextAreaContract<
          Widget,
          TextEditingController?,
          FocusNode?,
          TapRegionCallback,
          List<TextInputFormatter>
        > {
  /// Creates a [TextArea].
  TextArea({
    super.key,
    // === Contract — Content ===
    this.placeholder,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    // === Contract — State ===
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.selectAllOnFocus = CoreTextAreaContract.defaultSelectAllOnFocus,
    this.scrollPadding = CoreTextAreaContract.defaultScrollPadding,
    this.size = CoreComponentSize.md,
    this.variant = CoreTextAreaVariant.defaultTextAreaVariant,
    // === Style (chrome / dimensional / cursor / nested slot) ===
    this.textAreaStyle,
    // === Contract — Validation/Meta ===
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.required = false,
    this.name,
    // === Contract — Text behavior ===
    this.maxLength,
    this.showCounter = CoreTextAreaContract.defaultShowCounter,
    this.rows,
    // === Contract — Prefix/Suffix ===
    this.prefix,
    this.suffix,
    // === Contract — Footer ===
    this.footer,
    // === Contract — Resize ===
    this.expandableHeight = false,
    this.expandableWidth = false,
    // === Contract — Controllers ===
    this.controller,
    this.focusNode,
    // === Contract — Text behaviour ===
    this.obscureText = false,
    this.obscuringCharacter = CoreTextAreaContract.defaultObscuringCharacter,
    // === Flutter extended fields ===
    this.autocorrect,
    this.enableSuggestions = CoreTextAreaContract.defaultEnableSuggestions,
    this.spellCheckConfiguration,
    bool? enableInteractiveSelection,
    this.enableIMEPersonalizedLearning =
        CoreTextAreaContract.defaultEnableIMEPersonalizedLearning,
    this.stylusHandwritingEnabled =
        CoreTextAreaContract.defaultStylusHandwritingEnabled,
    // === Resize callbacks ===
    this.onHeightChanged,
    this.onWidthChanged,
    // === Cursor (interaction toggles) ===
    this.showCursor,
    this.cursorOpacityAnimates =
        CoreTextAreaContract.defaultCursorOpacityAnimates,
    // === Layout ===
    this.textDirection,
    // === Keyboard ===
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance,
    // === Input formatting ===
    this.maxLengthEnforcement,
    this.inputFormatters,
    // === Callbacks ===
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    // === Scrolling ===
    this.scrollController,
    this.scrollPhysics,
    // === Selection ===
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.dragStartBehavior = DragStartBehavior.start,
    // === Autofill ===
    this.autofillHints,
    // === Clip & Restoration ===
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    // === Advanced ===
    this.contextMenuBuilder,
    this.magnifierConfiguration,
    this.undoController,
  }) : enableInteractiveSelection =
           enableInteractiveSelection ?? (!readOnly || !obscureText);

  // ---------------------------------------------------------------------------
  // Contract fields
  // ---------------------------------------------------------------------------

  @override
  final String? placeholder;

  @override
  final String? initialValue;

  @override
  final CoreValueChanged<String>? onChanged;

  @override
  final CoreValueChanged<String>? onSubmitted;

  @override
  final bool enabled;

  @override
  final bool readOnly;

  @override
  final bool autofocus;

  @override
  final bool selectAllOnFocus;

  @override
  final CoreEdgeInsets scrollPadding;

  @override
  final CoreComponentSize size;

  @override
  final CoreTextAreaVariant variant;

  @override
  final CoreTextAreaStyle? textAreaStyle;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final String? errorText;

  @override
  final bool required;

  @override
  final String? name;

  @override
  final int? maxLength;

  @override
  final bool showCounter;

  @override
  final int? rows;

  @override
  final Widget? prefix;

  @override
  final Widget? suffix;

  @override
  final Widget? footer;

  @override
  final bool expandableHeight;

  @override
  final bool expandableWidth;

  @override
  final TextEditingController? controller;

  @override
  final FocusNode? focusNode;

  // ---------------------------------------------------------------------------
  // Flutter extended fields
  // ---------------------------------------------------------------------------

  @override
  final bool obscureText;

  @override
  final String obscuringCharacter;

  @override
  final bool? autocorrect;

  /// Whether to show input suggestions.
  final bool enableSuggestions;

  @override
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Whether interactive selection is enabled.
  final bool enableInteractiveSelection;

  /// Whether to enable IME personalized learning.
  final bool enableIMEPersonalizedLearning;

  /// Whether stylus handwriting is enabled.
  final bool stylusHandwritingEnabled;

  @override
  final ValueChanged<double>? onHeightChanged;

  @override
  final ValueChanged<double>? onWidthChanged;

  @override
  final bool? showCursor;

  /// Whether cursor opacity animates on blink.
  final bool cursorOpacityAnimates;

  /// Text direction (LTR/RTL).
  final TextDirection? textDirection;

  @override
  final TextInputType? keyboardType;

  @override
  final TextInputAction? textInputAction;

  @override
  final TextCapitalization textCapitalization;

  /// Keyboard appearance (light/dark).
  final Brightness? keyboardAppearance;

  /// Maximum length enforcement strategy.
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  final List<TextInputFormatter>? inputFormatters;

  @override
  final VoidCallback? onEditingComplete;

  @override
  final VoidCallback? onTap;

  @override
  final TapRegionCallback? onTapOutside;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Scroll physics.
  final ScrollPhysics? scrollPhysics;

  /// Selection controls.
  final TextSelectionControls? selectionControls;

  /// Selection highlight height style.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// Selection highlight width style.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// Drag start behavior.
  final DragStartBehavior dragStartBehavior;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Content clipping behavior.
  final Clip clipBehavior;

  /// Restoration ID for state restoration.
  final String? restorationId;

  /// Builder for custom context menus.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// The loupe shown while dragging a selection on touch.
  ///
  /// Null picks the platform's own magnifier — the iOS loupe on iOS, the
  /// Android magnifier on Android, none elsewhere — the same default
  /// `TextField` uses. Pass `TextMagnifierConfiguration.disabled` to turn
  /// it off.
  @override
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controller for undo/redo operations.
  final UndoHistoryController? undoController;

  /// Returns a copy of this [TextArea] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TextArea copyWith({
    Key? key,
    VoidCallback? onTap,
    CoreValueChanged<String>? onChanged,
    String? initialValue,
    String? placeholder,
    CoreValueChanged<String>? onSubmitted,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    bool? selectAllOnFocus,
    CoreEdgeInsets? scrollPadding,
    CoreComponentSize? size,
    CoreTextAreaStyle? textAreaStyle,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    bool? required,
    String? name,
    int? maxLength,
    bool? showCounter,
    CoreTextAreaVariant? variant,
    int? rows,
    Widget? prefix,
    Widget? suffix,
    Widget? footer,
    bool? expandableHeight,
    bool? expandableWidth,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool? obscureText,
    String? obscuringCharacter,
    bool? autocorrect,
    bool? enableSuggestions,
    SpellCheckConfiguration? spellCheckConfiguration,
    bool? enableInteractiveSelection,
    bool? enableIMEPersonalizedLearning,
    bool? stylusHandwritingEnabled,
    ValueChanged<double>? onHeightChanged,
    ValueChanged<double>? onWidthChanged,
    bool? showCursor,
    bool? cursorOpacityAnimates,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    Brightness? keyboardAppearance,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onEditingComplete,
    TapRegionCallback? onTapOutside,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    TextSelectionControls? selectionControls,
    ui.BoxHeightStyle? selectionHeightStyle,
    ui.BoxWidthStyle? selectionWidthStyle,
    DragStartBehavior? dragStartBehavior,
    Iterable<String>? autofillHints,
    Clip? clipBehavior,
    String? restorationId,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    TextMagnifierConfiguration? magnifierConfiguration,
    UndoHistoryController? undoController,
  }) {
    return TextArea(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      placeholder: placeholder ?? this.placeholder,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      autofocus: autofocus ?? this.autofocus,
      selectAllOnFocus: selectAllOnFocus ?? this.selectAllOnFocus,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      size: size ?? this.size,
      textAreaStyle: textAreaStyle ?? this.textAreaStyle,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      required: required ?? this.required,
      name: name ?? this.name,
      maxLength: maxLength ?? this.maxLength,
      showCounter: showCounter ?? this.showCounter,
      variant: variant ?? this.variant,
      rows: rows ?? this.rows,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      footer: footer ?? this.footer,
      expandableHeight: expandableHeight ?? this.expandableHeight,
      expandableWidth: expandableWidth ?? this.expandableWidth,
      controller: controller ?? this.controller,
      focusNode: focusNode ?? this.focusNode,
      obscureText: obscureText ?? this.obscureText,
      obscuringCharacter: obscuringCharacter ?? this.obscuringCharacter,
      autocorrect: autocorrect ?? this.autocorrect,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      spellCheckConfiguration:
          spellCheckConfiguration ?? this.spellCheckConfiguration,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
      enableIMEPersonalizedLearning:
          enableIMEPersonalizedLearning ?? this.enableIMEPersonalizedLearning,
      stylusHandwritingEnabled:
          stylusHandwritingEnabled ?? this.stylusHandwritingEnabled,
      onHeightChanged: onHeightChanged ?? this.onHeightChanged,
      onWidthChanged: onWidthChanged ?? this.onWidthChanged,
      showCursor: showCursor ?? this.showCursor,
      cursorOpacityAnimates:
          cursorOpacityAnimates ?? this.cursorOpacityAnimates,
      textDirection: textDirection ?? this.textDirection,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      maxLengthEnforcement: maxLengthEnforcement ?? this.maxLengthEnforcement,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      scrollController: scrollController ?? this.scrollController,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      selectionControls: selectionControls ?? this.selectionControls,
      selectionHeightStyle: selectionHeightStyle ?? this.selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle ?? this.selectionWidthStyle,
      dragStartBehavior: dragStartBehavior ?? this.dragStartBehavior,
      autofillHints: autofillHints ?? this.autofillHints,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      restorationId: restorationId ?? this.restorationId,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      magnifierConfiguration:
          magnifierConfiguration ?? this.magnifierConfiguration,
      undoController: undoController ?? this.undoController,
    );
  }

  @override
  State<TextArea> createState() => _TextAreaState();
}

// =============================================================================
// State
// =============================================================================

class _TextAreaState extends State<TextArea>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _hovered = false;

  /// Tells a focus a pointer press caused from one that arrived by keyboard
  /// — see [_showsFocusRing].
  final _focusRing = InputFocusRing();

  // User-overridden dimensions from drag interaction. `null` defers to
  // the resolver's `initialHeight` / `initialWidth` defaults at build time.
  double? _height;
  double? _width;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => defaultTargetPlatform == .iOS;

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

  /// Full text-selection gesture stack (tap / double-tap / drag-select /
  /// touch long-press with handles, toolbar and magnifier), the same one
  /// `TextField` builds. A plain tap detector gave the area focus and
  /// nothing else, so on a touch device its text could not be selected.
  late final TextSelectionGestureDetectorBuilder _selectionGestureBuilder;

  /// Whether the draggable selection handles show — toggled by
  /// [_handleSelectionChanged] off what caused the change.
  bool _showSelectionHandles = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  // The outer focus ring is a keyboard signal (#5747): a pointer or touch
  // focus already shows on the `primary` active boundary, so the ring joins
  // only while focus moves by keyboard — the `:focus-visible` the Web twin
  // reads.
  //
  // `highlightMode` is the platform's half of that judgment, and it cannot
  // be the whole of it: a mouse never moves it off `traditional` on a
  // desktop, so a click would ring. Whether a press caused the focus is
  // decided by [CoreInputFocusModality], the class the Web twin reads, once
  // when focus arrives — a keystroke after a click must not turn it on.
  void _handleHighlightMode(FocusHighlightMode mode) {
    if (mounted && _focusNode.hasFocus) setState(() {});
  }

  bool get _showsFocusRing => _focusRing.shows(_focusNode);

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_handleHighlightMode);
    _selectionGestureBuilder = _TextAreaSelectionGestureBuilder(state: this);
    _initController();
    _initFocusNode();
  }

  // ---------------------------------------------------------------------------
  // Init helpers
  // ---------------------------------------------------------------------------

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_handleFocusChanged);
    _focusRing.adopt(_focusNode);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _handleFocusChanged() {
    // Decide the outer ring once, when focus arrives.
    _focusRing.focusChanged(_focusNode);
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        if (_effectiveSelectAllOnFocus) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      });
    }
    setState(() {
      /* Rebuild to reflect focus state. */
    });
  }

  /// Opens an editing session on the area that already holds focus.
  ///
  /// The engine ends the session when the on-screen keyboard is dismissed
  /// while the framework still believes the area is focused, so asking
  /// for focus again would change nothing — the keyboard is what has to
  /// be asked for.
  void _requestKeyboard() => editableTextKey.currentState?.requestKeyboard();

  /// Handles for a touch / long-press selection, never for a keyboard one
  /// — the same rule `TextField` follows.
  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final willShow = _shouldShowSelectionHandles(cause);
    if (willShow != _showSelectionHandles) {
      setState(() => _showSelectionHandles = willShow);
    }
  }

  /// Wraps the input surface with the selection gesture stack. A
  /// disabled area skips it, so a tap places no caret and selects nothing.
  Widget _wrapWithSelectionGestures(Widget child) {
    if (!widget.enabled) return child;
    // The press is noted on the region that grants focus, so a press the
    // area answers with focus is read as the cause of it (see
    // [_showsFocusRing]). Translucent: it only watches.
    return Listener(
      behavior: .translucent,
      onPointerDown: (_) => _focusRing.pointerDown(),
      child: _selectionGestureBuilder.buildGestureDetector(
        behavior: .translucent,
        child: child,
      ),
    );
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (!_selectionGestureBuilder.shouldShowSelectionToolbar) return false;
    if (!widget.enabled) return false;
    if (cause == .keyboard) return false;
    if (widget.readOnly && _controller.selection.isCollapsed) return false;
    if (cause == .longPress) return true;
    return _controller.text.isNotEmpty;
  }

  // Input-policy booleans flow straight from the per-instance widget
  // flags (constructor-defaulted to the contract's `static const`
  // single-source defaults). They are project-wide behaviour, not
  // chrome, so they no longer route through `CoreTextAreaTheme` (which is
  // `{style, variantStyles}` only) — the widget reads its own flag.
  bool get _effectiveSelectAllOnFocus => widget.selectAllOnFocus;

  // An obscured area routes its text nowhere the platform can keep it.
  // Autocorrect and suggestions hand it to the keyboard's dictionary and
  // spell check ships it to a platform service, and none of the three
  // changes what is drawn — so the leak is invisible from the outside.
  //
  // Null is forwarded as null when not obscured, which is where Flutter
  // infers autocorrect from the autofill hints.
  bool? get _effectiveAutocorrect =>
      widget.obscureText ? false : widget.autocorrect;

  bool get _effectiveEnableSuggestions =>
      !widget.obscureText && widget.enableSuggestions;

  // Masking wins over a stated capitalisation, as it does on the Web twin.
  TextCapitalization get _effectiveTextCapitalization =>
      widget.obscureText ? TextCapitalization.none : widget.textCapitalization;

  SpellCheckConfiguration get _effectiveSpellCheckConfiguration =>
      widget.obscureText
      ? const .disabled()
      : (widget.spellCheckConfiguration ?? const .disabled());

  bool get _effectiveEnableInteractiveSelection =>
      widget.enableInteractiveSelection;

  bool get _effectiveEnableIMEPersonalizedLearning =>
      !widget.obscureText && widget.enableIMEPersonalizedLearning;

  bool get _effectiveStylusHandwritingEnabled =>
      widget.stylusHandwritingEnabled;

  bool get _effectiveCursorOpacityAnimates => widget.cursorOpacityAnimates;

  void _handleTextChanged(String value) {
    widget.onChanged?.call(value);
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted?.call(value);
  }

  @override
  void didUpdateWidget(TextArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode
          ..removeListener(_handleFocusChanged)
          ..dispose();
        _ownsFocusNode = false;
      }
      _initFocusNode();
    }

    // Reset the user-drag override when the textAreaStyle changes — the
    // new style's `initialHeight` / `initialWidth` should be respected.
    if (widget.textAreaStyle != oldWidget.textAreaStyle) {
      _height = null;
      _width = null;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_handleHighlightMode);
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Resolve helpers
  // ---------------------------------------------------------------------------

  Set<WidgetState> get _states => {
    if (!widget.enabled) WidgetState.disabled,
    if (_focusNode.hasFocus) WidgetState.focused,
    if (_hovered) WidgetState.hovered,
  };

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement(
        defaultTargetPlatform,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = _states;

    // --- Style resolution ---------------------------------------------------

    final resolved = resolveTextArea(
      context,
      hasError: widget.errorText != null,
      size: widget.size,
      enabled: widget.enabled,
      variant: widget.variant,
      scrollPadding: widget.scrollPadding,
      textAreaStyle: widget.textAreaStyle,
    );

    final tokenDecoration = resolved.decoration.resolve(states);
    final activeDecoration = resolved.activeDecoration.resolve(states);
    final effectivePadding = resolved.padding;

    // Text style: inherit the ambient DefaultTextStyle, then apply the
    // resolved per-state value style (which already carries the size
    // rung's body typography + normal-weight base).
    final tokenValueTs = resolved.valueTextStyle.resolve(states);
    final defaultTextStyle = DefaultTextStyle.of(
      context,
    ).style.merge(tokenValueTs);

    final placeholderTs = resolved.placeholderTextStyle;
    final cursorColor = resolved.cursorColor;

    final selectionColor = resolved.selectionColor;

    final keyboardAppearance = widget.keyboardAppearance ?? theme.brightness;

    // --- Input formatters ---------------------------------------------------

    final formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(
          widget.maxLength,
          maxLengthEnforcement: _effectiveMaxLengthEnforcement,
        ),
    ];

    // --- Selection controls -------------------------------------------------

    final textSelectionControls =
        widget.selectionControls ?? cupertinoDesktopTextSelectionHandleControls;

    // --- EditableText -------------------------------------------------------

    final editable = RepaintBoundary(
      // `EditableText` builds its own `Focus` with semantics left out, so
      // the node that carries `isTextField` states no enabled state and
      // offers no focus action of its own. A web engine reads the missing
      // enabled state as a disabled control, and a disabled control never
      // receives the focus event that starts an editing session — the area
      // draws, announces itself, and takes no typing.
      //
      // Wrapped at the innermost point deliberately: `RenderEditable` is
      // no semantics boundary here, so this annotation merges into that
      // same node instead of describing the surrounding row.
      child: Semantics(
        enabled: widget.enabled,
        // Assistive technology, and the web engine's semantics editing
        // strategy, reach the area through this action rather than through
        // a pointer event. An area that publishes no handler for it cannot
        // be entered by that route at all.
        //
        // A caller-supplied node may refuse focus; the area is still asked
        // for the keyboard so the two branches cover every reachable state
        // rather than asserting one of them away.
        onFocus: widget.enabled
            ? () {
                if (_focusNode.canRequestFocus && !_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                } else if (!widget.readOnly) {
                  _requestKeyboard();
                }
              }
            : null,
        child: EditableText(
          key: editableTextKey,
          onChanged: _handleTextChanged,
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly || !widget.enabled,
          obscuringCharacter: widget.obscuringCharacter,
          obscureText: widget.obscureText,
          autocorrect: _effectiveAutocorrect,
          enableSuggestions: _effectiveEnableSuggestions,
          style: defaultTextStyle,
          cursorColor: cursorColor,
          backgroundCursorColor: resolved.backgroundCursorColor,
          textAlign: resolved.textAlign,
          textDirection: widget.textDirection,
          // Two height policies, mirroring HTML `<textarea rows>`:
          // - rows specified → exactly that many visible lines; extra
          //   input scrolls inside the field
          //   (`minLines == maxLines == rows`, `expands: false`).
          // - rows omitted → fill the outer `SizedBox(_height)`
          //   (`expands: true`, both lines null per EditableText's
          //   assertion).
          maxLines: widget.rows,
          minLines: widget.rows,
          expands: widget.rows == null,
          autofocus: widget.autofocus,
          showCursor: widget.showCursor,
          showSelectionHandles: _showSelectionHandles,
          selectionColor: _focusNode.hasFocus ? selectionColor : null,
          selectionControls: _effectiveEnableInteractiveSelection
              ? textSelectionControls
              : null,
          keyboardType: widget.keyboardType ?? .multiline,
          textInputAction: widget.textInputAction,
          textCapitalization: _effectiveTextCapitalization,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: _handleSubmitted,
          onSelectionChanged: _handleSelectionChanged,
          onTapOutside: widget.onTapOutside,
          inputFormatters: formatters,
          rendererIgnoresPointer: true,
          cursorWidth: resolved.cursorWidth,
          cursorRadius: resolved.cursorRadius,
          cursorOpacityAnimates: _effectiveCursorOpacityAnimates,
          paintCursorAboveText: true,
          selectionHeightStyle: widget.selectionHeightStyle,
          selectionWidthStyle: widget.selectionWidthStyle,
          scrollPadding: resolved.scrollPadding,
          keyboardAppearance: keyboardAppearance,
          dragStartBehavior: widget.dragStartBehavior,
          enableInteractiveSelection: _effectiveEnableInteractiveSelection,
          scrollController: widget.scrollController,
          scrollPhysics: widget.scrollPhysics,
          autofillHints: widget.autofillHints,
          clipBehavior: widget.clipBehavior,
          restorationId: widget.restorationId,
          stylusHandwritingEnabled: _effectiveStylusHandwritingEnabled,
          enableIMEPersonalizedLearning:
              _effectiveEnableIMEPersonalizedLearning,
          contextMenuBuilder: widget.contextMenuBuilder,
          magnifierConfiguration:
              widget.magnifierConfiguration ??
              TextMagnifier.adaptiveMagnifierConfiguration,
          spellCheckConfiguration: _effectiveSpellCheckConfiguration,
          undoController: widget.undoController,
        ),
      ),
    );

    // --- Placeholder + EditableText stack -----------------------------------

    final leadingIconTheme = resolved.leadingIconTheme.resolve(states);
    final trailingIconTheme = resolved.trailingIconTheme.resolve(states);

    final innerContent = ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, text, child) {
        final hasText = text.text.isNotEmpty;
        final placeholderText = widget.placeholder;
        final placeholderWidget = placeholderText == null
            ? null
            : Visibility(
                visible: !hasText,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: SizedBox(
                  width: .infinity,
                  child: DefaultTextStyle(
                    style: defaultTextStyle.merge(placeholderTs),
                    textAlign: resolved.textAlign,
                    child: Text(placeholderText),
                  ),
                ),
              );

        final inputStack = Expanded(
          child: Stacks(
            alignment: .topStart,
            textDirection: widget.textDirection == null
                ? null
                : (widget.textDirection == .ltr
                      ? CoreTextDirection.ltr
                      : CoreTextDirection.rtl),
            children: [
              ?placeholderWidget,
              child!,
            ],
          ),
        );

        return Row(
          crossAxisAlignment: .start,
          spacing: resolved.rowSpacing,
          children: [
            if (widget.prefix != null)
              IconTheme.merge(
                data: leadingIconTheme,
                child: widget.prefix!,
              ),
            inputStack,
            if (widget.suffix != null)
              IconTheme.merge(
                data: trailingIconTheme,
                child: widget.suffix!,
              ),
          ],
        );
      },
      child: editable,
    );

    // --- Resize drag handle -------------------------------------------------

    final effectiveWidth = _width ?? resolved.initialWidth;
    final effectiveHeight = _height ?? resolved.initialHeight;

    // Without a footer the handle takes the box's own corner. With one it
    // takes the text row's corner instead: the box's corner is where the
    // footer's trailing action sits, and the handle would paint over it and
    // contend for its drags. The text row's corner is also where the web's
    // native grip sits — on the `<textarea>`, above the footer. Either way
    // it resizes the whole box, so a measured height includes the footer.
    final dragHandle = widget.expandableHeight || widget.expandableWidth
        ? Position(
            right: resolved.dragHandleOffset,
            bottom: resolved.dragHandleOffset,
            width: resolved.dragHandleSize,
            height: resolved.dragHandleSize,
            child: MouseRegion(
              cursor: widget.expandableWidth
                  ? widget.expandableHeight
                        ? SystemMouseCursors.resizeDownRight
                        : SystemMouseCursors.resizeLeftRight
                  : widget.expandableHeight
                  ? SystemMouseCursors.resizeUpDown
                  : SystemMouseCursors.basic,
              hitTestBehavior: .translucent,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final maxHeight = resolved.maxHeight;
                  final maxWidth = resolved.maxWidth;
                  if (widget.expandableHeight && effectiveHeight.isFinite) {
                    setState(() {
                      final next = (effectiveHeight + details.delta.dy).clamp(
                        resolved.minHeight,
                        maxHeight,
                      );
                      _height = next;
                      widget.onHeightChanged?.call(next);
                    });
                  }
                  if (widget.expandableWidth && effectiveWidth.isFinite) {
                    setState(() {
                      final next = (effectiveWidth + details.delta.dx).clamp(
                        resolved.minWidth,
                        maxWidth,
                      );
                      _width = next;
                      widget.onWidthChanged?.call(next);
                    });
                  }
                },
                behavior: .translucent,
                child: Padding(
                  padding: resolved.dragHandlePadding,
                  child: CustomPaint(
                    painter: _TextAreaDragHandlePainter(
                      resolved.dragHandleColor,
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;

    // --- Footer -------------------------------------------------------------

    // With a footer only the text row is the editing surface: the selection
    // gestures and the I-beam wrap that row rather than the box, so a tap on
    // the footer reaches the footer's own content and neither places a caret
    // nor focuses the area, and hovering it keeps its own cursor — the web's
    // footer sits outside the `<textarea>` and behaves the same. Without a
    // footer the whole box carries both, so a tap on its padding focuses the
    // area too.
    final footer = widget.footer;
    final Widget boxContent;
    if (footer == null) {
      boxContent = innerContent;
    } else {
      Widget textRow = MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.text : MouseCursor.defer,
        child: _wrapWithSelectionGestures(
          // The vertical alignment the box applies to the bare row applies
          // here to the text inside the share the footer leaves — the web
          // aligns the text inside its `<textarea>` the same way.
          Align(
            alignment: Alignment(-1, resolved.textAlignVertical.y),
            widthFactor: 1,
            heightFactor: 1,
            child: innerContent,
          ),
        ),
      );
      if (dragHandle != null) {
        textRow = Stacks(
          fit: .passthrough,
          clipBehavior: .none,
          children: [textRow, dragHandle],
        );
      }
      boxContent = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          // A box of fixed height (no `rows`) gives the text row what the
          // footer leaves; with `rows` the row keeps its lines and the box
          // grows to hold both.
          if (widget.rows == null) Expanded(child: textRow) else textRow,
          Gap(gapStyle: resolved.footerGapStyle),
          // Part of the field for `onTapOutside`: tapping a footer action is
          // not tapping away from the area, which is also how the web's
          // containment test reads it (the root holds the footer).
          TextFieldTapRegion(child: footer),
        ],
      );
    }

    // --- Container with decoration + focus outline --------------------------

    // `SurfaceBlur` sits inside the ring rather than around it — the ring
    // frames the same box either way, so wrapping here does not move it. A
    // no-op when the area paints no fill (transparent override) or the
    // active style states no material.
    final box = SurfaceBlur(
      borderRadius: tokenDecoration.borderRadius,
      surfaceBlur: resolved.surfaceBlur,
      surfaceSaturation: resolved.surfaceSaturation,
      surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
      surfaceSheen: resolved.surfaceSheen,
      refraction: Theme.of(context).surfaceRefraction,
      child: Container(
        decoration: tokenDecoration,
        // The active boundary (focus / error) is laid over the box rather
        // than added to the layout border, so the text does not move — nor
        // the box grow — when the area takes focus.
        foregroundDecoration: activeDecoration,
        child: Align(
          alignment: Alignment(
            -1,
            resolved.textAlignVertical.y,
          ),
          widthFactor: 1,
          heightFactor: 1,
          child: Padding(
            padding: effectivePadding,
            child: boxContent,
          ),
        ),
      ),
    );

    // The box's own cursor — with a footer it states none, so the text row's
    // I-beam stays on the text and the footer keeps its content's cursor.
    final boxCursor = !widget.enabled
        ? SystemMouseCursors.forbidden
        : (footer == null ? SystemMouseCursors.text : MouseCursor.defer);

    Widget field = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: boxCursor,
      child: FocusOutline(
        focused: _showsFocusRing,
        focusOutlineStyle: resolved.focusOutlineStyle,
        child: footer == null ? _wrapWithSelectionGestures(box) : box,
      ),
    );

    // --- Wrap in SizedBox with drag handle for resize -----------------------

    field = SizedBox(
      width: effectiveWidth,
      height: widget.rows == null ? effectiveHeight : null,
      child: Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: [
          if (widget.rows != null) field else Position.fill(child: field),
          if (footer == null) ?dragHandle,
        ],
      ),
    );

    // --- Label / Description / Error wrapping -------------------------------

    if (widget.label != null ||
        widget.description != null ||
        widget.errorText != null ||
        widget.showCounter) {
      // The helper line: the description or the error, and — when asked —
      // the character count at its end (#5747). The count follows the text
      // live, so it listens to the controller.
      final Widget? helperText = widget.errorText != null
          ? Text(widget.errorText!, style: resolved.errorTextStyle)
          : widget.description != null
          ? Text(widget.description!, style: resolved.descriptionTextStyle)
          : null;
      final Widget? helperRow = widget.showCounter
          ? Row(
              crossAxisAlignment: .start,
              children: [
                Expanded(child: helperText ?? const SizedBox.shrink()),
                Gap(gapStyle: resolved.counterGapStyle),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => Text(
                    CoreTextAreaContract.counterLabel(
                      value.text,
                      maxLength: widget.maxLength,
                    ),
                    style: resolved.counterTextStyle,
                  ),
                ),
              ],
            )
          : helperText;

      field = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          if (widget.label != null) ...[
            // A bare `Text`, and `size` / `enabled` handed down — the way
            // the `TextField` twin composes this same child. Wrapping the
            // words in a `DefaultTextStyle` of this component's own making
            // overrode the role `FormLabel` resolves from its per-size
            // ladder, so every rung rendered the label at one size.
            FormLabel(
              label: Text(
                widget.label!,
                maxLines: widget.labelMaxLines,
                overflow: widget.labelOverflow?.toValue(),
              ),
              isRequired: widget.required,
              size: widget.size,
              enabled: widget.enabled,
              formLabelStyle: resolved.labelFormLabelStyle,
            ),
            Gap(gapStyle: resolved.labelGapStyle),
          ],
          field,
          if (helperRow != null) ...[
            Gap(gapStyle: resolved.descriptionGapStyle),
            helperRow,
          ],
        ],
      );
    }

    return field;
  }
}

// =============================================================================
// Drag handle painter
// =============================================================================

/// [TextSelectionGestureDetectorBuilder] for `TextArea` — the same stack
/// `TextField` uses. It only routes the user's tap through the widget's
/// `onTap`; the base builder already focuses the area on tap. A read-only
/// area keeps its old contract of not reporting taps.
class _TextAreaSelectionGestureBuilder
    extends TextSelectionGestureDetectorBuilder {
  _TextAreaSelectionGestureBuilder({required _TextAreaState state})
    : _state = state,
      super(delegate: state);

  final _TextAreaState _state;

  @override
  void onUserTap() {
    if (_state.widget.readOnly) return;
    _state.widget.onTap?.call();
  }
}

class _TextAreaDragHandlePainter extends CustomPainter {
  const _TextAreaDragHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = .round;
    final start = Offset(size.width, 0);
    final end = Offset(0, size.height);
    final start2 = Offset(size.width, size.height / 2);
    final end2 = Offset(size.width / 2, size.height);
    canvas.drawLine(start, end, paint);
    canvas.drawLine(start2, end2, paint);
  }

  @override
  bool shouldRepaint(covariant _TextAreaDragHandlePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// Chain sugar for merging a [CoreTextAreaStyle] patch into
/// [TextArea.textAreaStyle] without hand-reconstructing every field.
/// Mirrors the Web `TextArea.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextAreaStyle.merge` right-side-wins semantics).
///
/// `.error` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension TextAreaStyleChain on TextArea {
  /// Sets the content padding.
  TextArea contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreTextAreaStyle(padding: value));

  /// Sets the border color.
  TextArea borderColor(CoreColor value) =>
      withStyle(CoreTextAreaStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  TextArea borderWidth(double value) =>
      withStyle(CoreTextAreaStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  TextArea backgroundColor(CoreColor value) =>
      withStyle(CoreTextAreaStyle(backgroundColor: value));

  /// Returns a copy of this [TextArea] with [patch] merged into
  /// [textAreaStyle] (patch fields win on conflict).
  TextArea withStyle(CoreTextAreaStyle patch) => copyWith(
    textAreaStyle: (textAreaStyle ?? const CoreTextAreaStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  TextArea get radius0 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  TextArea get radius2 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  TextArea get radius4 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  TextArea get radius6 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  TextArea get radius8 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  TextArea get radius10 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  TextArea get radius12 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  TextArea get radius14 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  TextArea get radius16 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  TextArea get radius20 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  TextArea get radius24 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  TextArea get radius28 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  TextArea get radius32 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  TextArea get radius36 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  TextArea get radius40 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  TextArea get radius48 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  TextArea get radius56 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  TextArea get radius64 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  TextArea get radius9999 => withStyle(
    const CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  TextArea get primary => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  TextArea get secondary => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  TextArea get tertiary => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  TextArea get surface => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  TextArea get surfaceContainer => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// Selects `variant: .error` using the component theme.
  TextArea get error => copyWith(variant: .error);

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  TextArea get success => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  TextArea get warning => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  TextArea get info => withStyle(
    const CoreTextAreaStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  TextArea get outline => withStyle(
    const CoreTextAreaStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  TextArea get transparent => withStyle(
    const CoreTextAreaStyle(backgroundColor: .transparent),
  );
}
