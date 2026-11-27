import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/util/input_focus_ring.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show TextMagnifier;
import 'package:flutter/services.dart';

/// The gap `RenderEditable` keeps between the text and the caret
/// (`_kCaretGap` in `package:flutter/rendering/editable.dart`, private
/// there). Not a design token — the framework's own layout constant, mirrored
/// so a centred value can be balanced against the margin the editable
/// reserves.
const double _kEditableCaretGap = 1;

/// Default maximum number of visible text lines for `TextField`.
/// Single-line is the canonical text-field shape; multi-line input is
/// Unified cross-platform text field with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, the semantic enums (`variant`, `size`)
/// stay as widget parameters because they identify the input
/// instance. All chrome / dimensional / cursor / nested-slot
/// overrides flow through the single [textFieldStyle] (a
/// [CoreTextFieldStyle]) so the nested-merge chain works uniformly:
///
/// ```text
/// design system default for variant
///   → CoreTextFieldTheme.style
///   → CoreTextFieldTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.textFieldStyle
/// ```
///
/// The `variant` is auto-determined: when [errorText] is non-null,
/// the error variant is used; otherwise the default variant is used.
///
/// Inside a `FormField` the field takes part in the form: it mixes in
/// [FormValueSupplier], so it reports its text to the enclosing field's
/// [FormFieldHandle] on mount (the initial text) and on every change
/// (typing, the controller, a controlled [value], the clear affordance), and
/// the form controller validates it. Blank text is reported as `null` —
/// [CoreTextFieldContract.formValueOf]. A validator that answers with a
/// `ReplaceResult` rewrites the text (`onChanged` fires with it). The
/// report does not depend on [enabled] or [readOnly]: a field that cannot be
/// edited still has a value. A field outside a `FormField` reports to
/// nothing, and so does one inside an overlay opened from a `FormField`
/// (a dialog, a popover) — the field's scope stops at the overlay boundary.
/// A composite that embeds a `TextField` as an implementation detail walls
/// it off with `Data<FormFieldHandle>.boundary`, so the composite's own
/// value is the only one the enclosing field sees.
///
/// Example:
/// ```dart
/// TextField(
///   placeholder: Text('Enter text...'),
///   onChanged: handleChanged,
///   textFieldStyle: CoreTextFieldStyle(
///     borderRadius: CoreBorderRadius.all(8),
///     padding: CoreEdgeInsets.symmetric(horizontal: 16),
///   ),
/// )
/// ```
///
/// surface:behind — the field's box paints directly on the framed body
/// (native `<input>` on Web, a `Container` here) rather than composing
/// `OutlinedContainer`, so what shows through it is the page it is laid
/// on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class TextField extends StatefulWidget
    implements
        CoreTextFieldContract<
          Widget,
          FocusNode,
          WidgetStatesController,
          TextEditingController,
          TapRegionCallback,
          TapRegionUpCallback,
          List<TextInputFormatter>
        > {
  /// Creates a [TextField].
  // ignore: prefer_const_constructors_in_immutables
  TextField({
    super.key,
    // === Content ===
    this.placeholder,
    this.initialValue,
    this.value,
    this.onChanged,
    this.onCaretChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.size = CoreComponentSize.md,
    this.variant,
    // === Style (chrome / dimensional / cursor / nested slot) ===
    this.textFieldStyle,
    // === Validation ===
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.required = false,
    // === Text behavior ===
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.maxLength,
    // === HTML-semantic type + validation (absorbed from `Input`) ===
    this.type = CoreInputType.defaultType,
    this.minLength,
    this.pattern,
    this.min,
    this.max,
    this.title,
    this.maxLines = CoreTextFieldContract.defaultMaxLines,
    this.minLines,
    this.expands = false,
    this.autocorrect,
    this.selectAllOnFocus = false,
    this.scrollPadding = CoreTextFieldContract.defaultScrollPadding,
    this.enableSuggestions = true,
    bool? enableInteractiveSelection,
    this.enableIMEPersonalizedLearning = true,
    this.stylusHandwritingEnabled =
        EditableText.defaultStylusHandwritingEnabled,
    // === Prefix/Suffix ===
    this.prefix,
    this.suffix,
    // === Form ===
    this.name,
    this.hintText,
    // === Controller ===
    this.controller,
    // === Focus & State ===
    this.focusNode,
    this.statesController,
    // === Cursor (interaction toggles) ===
    this.showCursor,
    this.cursorOpacityAnimates = true,
    // === Layout (behaviour, not chrome) ===
    this.textDirection,
    // === Keyboard ===
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance,
    // === Input formatting ===
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.submitFormatters = const [],
    // === Callbacks ===
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    this.onTapUpOutside,
    // === Scrolling ===
    this.scrollController,
    this.scrollPhysics,
    // === Selection ===
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.dragStartBehavior = DragStartBehavior.start,
    // === Autofill ===
    this.autofillHints = const [],
    // === Accessibility ===
    this.clearButtonSemanticLabel,
    // === Clip & Restoration ===
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    // === Advanced platform configuration ===
    this.contentInsertionConfiguration,
    this.contextMenuBuilder,
    this.magnifierConfiguration,
    this.spellCheckConfiguration,
    this.undoController,
    this.strutStyle,
    // === Feature system (clear / password-toggle affordances) ===
    this.features = const [],
    this.skipInputFeatureFocusTraversal =
        CoreTextFieldContract.defaultSkipInputFeatureFocusTraversal,
    this.groupId = EditableText,
  }) : enableInteractiveSelection =
           enableInteractiveSelection ?? (!readOnly || !obscureText);

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  @override
  final Widget? placeholder;

  @override
  final String? initialValue;

  @override
  final String? value;

  @override
  final ValueChanged<String>? onChanged;

  /// Reports the caret offset each time the text changes.
  ///
  /// The same capability [controller] already exposes through
  /// `TextEditingController.selection`, surfaced as a plain callback so
  /// the Web twin — which has no controller — can offer it under the same
  /// name. A composing parent that must know *where* an edit landed (to
  /// complete the word under the caret rather than the whole field) can
  /// read either.
  ///
  /// Fires immediately before [onChanged], so a listener that keeps both
  /// sees a caret that matches the value it is handed.
  final ValueChanged<int>? onCaretChanged;

  @override
  final ValueChanged<String>? onSubmitted;

  @override
  final bool enabled;

  @override
  final bool readOnly;

  @override
  final bool autofocus;

  @override
  final CoreComponentSize size;

  @override
  final CoreTextFieldVariant? variant;

  // ---------------------------------------------------------------------------
  // Style (chrome / dimensional / cursor / nested slot)
  // ---------------------------------------------------------------------------

  @override
  final CoreTextFieldStyle? textFieldStyle;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Text behavior
  // ---------------------------------------------------------------------------

  /// Initial obscured seed only — later changes are ignored. See
  /// [CoreTextFieldContract.obscureText].
  @override
  final bool obscureText;

  @override
  final String obscuringCharacter;

  @override
  final int? maxLength;

  // ---------------------------------------------------------------------------
  // HTML-semantic type + validation (absorbed from `Input`)
  // ---------------------------------------------------------------------------

  @override
  final CoreInputType type;

  @override
  final int? minLength;

  @override
  final String? pattern;

  @override
  final num? min;

  @override
  final num? max;

  @override
  final String? title;

  @override
  final int? maxLines;

  @override
  final int? minLines;

  @override
  final bool expands;

  @override
  final bool? autocorrect;

  @override
  final bool selectAllOnFocus;

  @override
  final CoreEdgeInsets scrollPadding;

  @override
  final bool enableSuggestions;

  @override
  final bool enableInteractiveSelection;

  @override
  final bool enableIMEPersonalizedLearning;

  @override
  final bool stylusHandwritingEnabled;

  // ---------------------------------------------------------------------------
  // Prefix / Suffix
  // ---------------------------------------------------------------------------

  @override
  final Widget? prefix;

  @override
  final Widget? suffix;

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  @override
  final String? name;

  @override
  final String? hintText;

  // ---------------------------------------------------------------------------
  // Controller
  // ---------------------------------------------------------------------------

  @override
  final TextEditingController? controller;

  // ---------------------------------------------------------------------------
  // Focus & State
  // ---------------------------------------------------------------------------

  @override
  final FocusNode? focusNode;

  /// Receives the interaction states this field owns — disabled, focused,
  /// hovered and error — as they change, so a caller can react to them
  /// (Material `TextField` parity). The field only writes those four; any
  /// other state the caller puts on the controller is left alone.
  @override
  final WidgetStatesController? statesController;

  // ---------------------------------------------------------------------------
  // Cursor (interaction toggles only — chrome cursor* lives in textFieldStyle)
  // ---------------------------------------------------------------------------

  @override
  final bool? showCursor;

  @override
  final bool cursorOpacityAnimates;

  // ---------------------------------------------------------------------------
  // Layout (behaviour, not chrome)
  // ---------------------------------------------------------------------------

  @override
  final TextDirection? textDirection;

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------

  @override
  final TextInputType? keyboardType;

  @override
  final TextInputAction? textInputAction;

  @override
  final TextCapitalization textCapitalization;

  @override
  final Brightness? keyboardAppearance;

  // ---------------------------------------------------------------------------
  // Input formatting
  // ---------------------------------------------------------------------------

  @override
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  final List<TextInputFormatter>? inputFormatters;

  @override
  final List<TextInputFormatter>? submitFormatters;

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  @override
  final VoidCallback? onEditingComplete;

  @override
  final GestureTapCallback? onTap;

  @override
  final TapRegionCallback? onTapOutside;

  /// Called for a pointer-up outside the field — the up-event twin of
  /// [onTapOutside]. Passed straight to `EditableText`, which tracks the
  /// region that pointer went down in.
  @override
  final TapRegionUpCallback? onTapUpOutside;

  // ---------------------------------------------------------------------------
  // Scrolling
  // ---------------------------------------------------------------------------

  @override
  final ScrollController? scrollController;

  @override
  final ScrollPhysics? scrollPhysics;

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  @override
  final TextSelectionControls? selectionControls;

  @override
  final ui.BoxHeightStyle selectionHeightStyle;

  @override
  final ui.BoxWidthStyle selectionWidthStyle;

  @override
  final DragStartBehavior dragStartBehavior;

  // ---------------------------------------------------------------------------
  // Autofill
  // ---------------------------------------------------------------------------

  @override
  final Iterable<String>? autofillHints;

  // ---------------------------------------------------------------------------
  // Accessibility
  // ---------------------------------------------------------------------------

  @override
  final String? clearButtonSemanticLabel;

  // ---------------------------------------------------------------------------
  // Clip & Restoration
  // ---------------------------------------------------------------------------

  @override
  final Clip clipBehavior;

  @override
  final String? restorationId;

  // ---------------------------------------------------------------------------
  // Advanced platform configuration
  // ---------------------------------------------------------------------------

  @override
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  @override
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// The loupe shown while dragging a selection on touch.
  ///
  /// Null picks the platform's own magnifier — the iOS loupe on iOS, the
  /// Android magnifier on Android, none elsewhere — the same default
  /// Material `TextField` uses. Pass `TextMagnifierConfiguration.disabled`
  /// to turn it off.
  @override
  final TextMagnifierConfiguration? magnifierConfiguration;

  @override
  final SpellCheckConfiguration? spellCheckConfiguration;

  @override
  final UndoHistoryController? undoController;

  /// Strut style for the editable text's vertical line-height layout.
  ///
  /// When omitted (`null`), `EditableText` derives an implicit strut
  /// from the resolved value [TextStyle] with `forceStrutHeight: true`,
  /// which can render a visibly different line spacing than a sibling
  /// `Text` widget given the same `TextStyle`. Pass
  /// `StrutStyle.disabled` to match a sibling `Text` widget's line
  /// spacing exactly.
  @override
  final StrutStyle? strutStyle;

  // ---------------------------------------------------------------------------
  // Feature system — built-in affordances (clear / password toggle) rendered
  // as leading / trailing icon buttons. Cross-platform parity with Web via
  // the platform-neutral [CoreInputFeature] model.
  // ---------------------------------------------------------------------------

  @override
  final List<CoreInputFeature> features;

  @override
  final bool skipInputFeatureFocusTraversal;

  @override
  final Object groupId;

  /// Returns a copy of this [TextField] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TextField copyWith({
    Key? key,
    GestureTapCallback? onTap,
    ValueChanged<String>? onChanged,
    ValueChanged<int>? onCaretChanged,
    String? initialValue,
    Widget? placeholder,
    String? value,
    ValueChanged<String>? onSubmitted,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    CoreComponentSize? size,
    CoreTextFieldVariant? variant,
    CoreTextFieldStyle? textFieldStyle,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    bool? required,
    bool? obscureText,
    String? obscuringCharacter,
    int? maxLength,
    CoreInputType? type,
    int? minLength,
    String? pattern,
    num? min,
    num? max,
    String? title,
    int? maxLines,
    int? minLines,
    bool? expands,
    bool? autocorrect,
    bool? selectAllOnFocus,
    CoreEdgeInsets? scrollPadding,
    bool? enableSuggestions,
    bool? enableInteractiveSelection,
    bool? enableIMEPersonalizedLearning,
    bool? stylusHandwritingEnabled,
    Widget? prefix,
    Widget? suffix,
    String? name,
    String? hintText,
    TextEditingController? controller,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    bool? showCursor,
    bool? cursorOpacityAnimates,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    Brightness? keyboardAppearance,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    List<TextInputFormatter>? submitFormatters,
    VoidCallback? onEditingComplete,
    TapRegionCallback? onTapOutside,
    TapRegionUpCallback? onTapUpOutside,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    TextSelectionControls? selectionControls,
    ui.BoxHeightStyle? selectionHeightStyle,
    ui.BoxWidthStyle? selectionWidthStyle,
    DragStartBehavior? dragStartBehavior,
    Iterable<String>? autofillHints,
    String? clearButtonSemanticLabel,
    Clip? clipBehavior,
    String? restorationId,
    ContentInsertionConfiguration? contentInsertionConfiguration,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    TextMagnifierConfiguration? magnifierConfiguration,
    SpellCheckConfiguration? spellCheckConfiguration,
    UndoHistoryController? undoController,
    StrutStyle? strutStyle,
    List<CoreInputFeature>? features,
    bool? skipInputFeatureFocusTraversal,
    Object? groupId,
  }) {
    return TextField(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
      onCaretChanged: onCaretChanged ?? this.onCaretChanged,
      initialValue: initialValue ?? this.initialValue,
      placeholder: placeholder ?? this.placeholder,
      value: value ?? this.value,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      autofocus: autofocus ?? this.autofocus,
      size: size ?? this.size,
      variant: variant ?? this.variant,
      textFieldStyle: textFieldStyle ?? this.textFieldStyle,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      required: required ?? this.required,
      obscureText: obscureText ?? this.obscureText,
      obscuringCharacter: obscuringCharacter ?? this.obscuringCharacter,
      maxLength: maxLength ?? this.maxLength,
      type: type ?? this.type,
      minLength: minLength ?? this.minLength,
      pattern: pattern ?? this.pattern,
      min: min ?? this.min,
      max: max ?? this.max,
      title: title ?? this.title,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      expands: expands ?? this.expands,
      autocorrect: autocorrect ?? this.autocorrect,
      selectAllOnFocus: selectAllOnFocus ?? this.selectAllOnFocus,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
      enableIMEPersonalizedLearning:
          enableIMEPersonalizedLearning ?? this.enableIMEPersonalizedLearning,
      stylusHandwritingEnabled:
          stylusHandwritingEnabled ?? this.stylusHandwritingEnabled,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      name: name ?? this.name,
      hintText: hintText ?? this.hintText,
      controller: controller ?? this.controller,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
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
      submitFormatters: submitFormatters ?? this.submitFormatters,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      onTapUpOutside: onTapUpOutside ?? this.onTapUpOutside,
      scrollController: scrollController ?? this.scrollController,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      selectionControls: selectionControls ?? this.selectionControls,
      selectionHeightStyle: selectionHeightStyle ?? this.selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle ?? this.selectionWidthStyle,
      dragStartBehavior: dragStartBehavior ?? this.dragStartBehavior,
      autofillHints: autofillHints ?? this.autofillHints,
      clearButtonSemanticLabel:
          clearButtonSemanticLabel ?? this.clearButtonSemanticLabel,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      restorationId: restorationId ?? this.restorationId,
      contentInsertionConfiguration:
          contentInsertionConfiguration ?? this.contentInsertionConfiguration,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      magnifierConfiguration:
          magnifierConfiguration ?? this.magnifierConfiguration,
      spellCheckConfiguration:
          spellCheckConfiguration ?? this.spellCheckConfiguration,
      undoController: undoController ?? this.undoController,
      strutStyle: strutStyle ?? this.strutStyle,
      features: features ?? this.features,
      skipInputFeatureFocusTraversal:
          skipInputFeatureFocusTraversal ?? this.skipInputFeatureFocusTraversal,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  State<TextField> createState() => _TextFieldState();
}

/// Combines the resolver's `height` / `minHeight` / `maxHeight` (each
/// paint-ready and already `* scaling`, `resolveTextField` in
/// `text_field_style.dart`) into a single height-only [BoxConstraints].
/// Width is left unconstrained — the parent still decides it.
///
/// Mirrors the Web resolver's independent conditional CSS declarations
/// (`height` / `min-height` / `max-height`) via the same
/// `used height = clamp(height, min-height, max-height)` rule the browser
/// applies when all three are stated together — a caller `minHeight`
/// still clamps a fixed `height` (`CoreTextFieldStyle.boxMinHeight` keeps
/// it; only the size row's floor steps aside for a fixed height).
/// `height == null` (the default) degenerates to a `[minHeight, maxHeight]`
/// range — the floor
/// is the size row's control height (`CoreTextFieldStyle.boxMinHeight`),
/// and the content grows the box past it when it is taller.
BoxConstraints _textFieldHeightConstraints({
  required double? height,
  required double? minHeight,
  required double? maxHeight,
}) {
  if (height == null) {
    return BoxConstraints(
      minHeight: minHeight ?? 0.0,
      maxHeight: maxHeight ?? double.infinity,
    );
  }
  var clamped = height;
  if (minHeight != null && clamped < minHeight) clamped = minHeight;
  if (maxHeight != null && clamped > maxHeight) clamped = maxHeight;
  return BoxConstraints.tightFor(height: clamped);
}

// =============================================================================
// State
// =============================================================================

class _TextFieldState extends State<TextField>
    with FormValueSupplier<String, TextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  /// One owned node per declared [TextField.features] entry, carrying
  /// [TextField.skipInputFeatureFocusTraversal] as `skipTraversal`.
  ///
  /// Kept in sync by [_syncFeatureFocusNodes]; disposed with the state.
  final List<FocusNode> _featureFocusNodes = [];

  /// Runtime obscured state — seeded from [TextField.obscureText] and
  /// flipped by a [CoreInputFeature.passwordToggle].
  late bool _obscured;

  /// Whether the field is hovered (drives `hovered`-visibility features).
  bool _hovered = false;

  /// Whether a pointer is held down on the field — the `pressed` state the
  /// style's state layer reads (a composing parent such as Select states a
  /// pressed-only wash through it). Web's `:active`.
  bool _pressed = false;

  /// Tells a focus a pointer press caused from one that arrived by keyboard
  /// — see [_showsFocusRing].
  final _focusRing = InputFocusRing();

  /// Whether the current text sits outside [TextField.min] / [TextField.max].
  ///
  /// Tracked rather than recomputed in `build` because it gates the error
  /// chrome, which is resolved above the value builder — the listener
  /// re-renders only when the boundary is actually crossed, the same
  /// shape the Web side uses for its own re-render.
  bool _rangeViolated = false;

  /// Whether selection handles are currently shown — toggled by
  /// [_handleSelectionChanged] based on the change cause (mirrors Material
  /// so handles appear on long-press / mobile selection but not on
  /// keyboard-driven selection).
  bool _showSelectionHandles = false;

  /// The disabled / error constraint an enclosing `FormField` or
  /// `Fieldset` publishes to this input — null when the field stands
  /// alone.
  ///
  /// Captured in [didChangeDependencies] rather than read at each use
  /// site: gesture callbacks ([_shouldShowSelectionHandles]) consult the
  /// enabled state outside `build`, where registering an inherited
  /// dependency is not allowed.
  CoreFormFieldScope? _formFieldScope;

  /// [TextField.enabled] folded with the ambient [CoreFormFieldScope] —
  /// AND: a wrapper that is disabled (an enclosing `Fieldset(enabled:
  /// false)`, a `FormField(enabled: false)`) always wins over this
  /// field's own `enabled: true`. Without a scope this is exactly
  /// `widget.enabled`.
  bool get _effectiveEnabled =>
      widget.enabled && _formFieldScope?.disabled != true;

  /// Full text-selection gesture stack (tap / double-tap / triple-tap /
  /// drag-select / mobile long-press + handles + toolbar + magnifier),
  /// platform-aware — the same infrastructure Material's `TextField` uses.
  /// Raw `EditableText` provides none of this on its own.
  late final TextSelectionGestureDetectorBuilder _selectionGestureBuilder;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => defaultTargetPlatform == .iOS;

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

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
    // `type: password` (absorbed from `Input`) seeds the obscured state
    // just like the explicit `obscureText` flag.
    _obscured = widget.obscureText || widget.type == .password;
    _selectionGestureBuilder = _CoTextFieldSelectionGestureBuilder(state: this);
    _initController();
    _initFocusNode();
    _syncFeatureFocusNodes();
    _rangeViolated = _computeRangeViolation();
    // The text the field starts with. Cached here and reported once the
    // enclosing `FormField` is found (`didChangeDependencies`), so the form
    // sees the initial text at mount rather than `null`.
    formValue = CoreTextFieldContract.formValueOf(_controller.text);
  }

  /// Whether the controller's text currently violates [TextField.min] /
  /// [TextField.max], per the shared [CoreTextFieldContract.isRangeViolation]
  /// rule both platforms read.
  bool _computeRangeViolation() => CoreTextFieldContract.isRangeViolation(
    _controller.text,
    min: widget.min,
    max: widget.max,
  );

  /// Re-renders only when the range verdict flips.
  ///
  /// The value builder already redraws the text itself on every keystroke;
  /// this exists because the error chrome is resolved above it, and it
  /// stays quiet while the verdict holds.
  void _handleRangeCheck() {
    final violated = _computeRangeViolation();
    if (violated == _rangeViolated) return;
    setState(() => _rangeViolated = violated);
  }

  /// Reports the controller's text to the enclosing `FormField`.
  ///
  /// Fires on selection-only notifications too; the `formValue` setter
  /// drops a value equal to the last one it reported, so those cost
  /// nothing.
  void _handleFormValueChanged() {
    formValue = CoreTextFieldContract.formValueOf(_controller.text);
  }

  /// Grows / shrinks [_featureFocusNodes] to one node per declared feature
  /// and (re)applies [TextField.skipInputFeatureFocusTraversal] to each.
  ///
  /// Nodes are keyed by index into `widget.features` — the *declared* list,
  /// not the visible subset — so a feature that hides and reappears keeps
  /// its node instead of inheriting a sibling's.
  void _syncFeatureFocusNodes() {
    final skipTraversal = widget.skipInputFeatureFocusTraversal;
    final count = widget.features.length;

    while (_featureFocusNodes.length > count) {
      _featureFocusNodes.removeLast().dispose();
    }
    while (_featureFocusNodes.length < count) {
      _featureFocusNodes.add(FocusNode(skipTraversal: skipTraversal));
    }
    for (final node in _featureFocusNodes) {
      node.skipTraversal = skipTraversal;
    }
  }

  // ---------------------------------------------------------------------------
  // Init helpers
  // ---------------------------------------------------------------------------

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      // A controlled value, when supplied, seeds the owned controller —
      // otherwise the uncontrolled initialValue does.
      _controller = TextEditingController(
        text: widget.value ?? widget.initialValue,
      );
      _ownsController = true;
    }
    // Watches the range verdict, not the text — see [_handleRangeCheck].
    // Attached to whichever controller is in play, including a caller's.
    //
    // The form value rides the controller too rather than `onChanged`:
    // the controller is where every edit lands — typing, a controlled
    // `value`, the clear affordance, submit formatters, the caller's own
    // `controller.text = …` — and `onChanged` hears only the first.
    _controller
      ..addListener(_handleRangeCheck)
      ..addListener(_handleFormValueChanged);
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
    // `selectAllOnFocus` mirrors the Web `select()` behaviour; otherwise
    // leave the selection alone — EditableText already places the caret at
    // the tap position (parity with the browser `<input>` click). Forcing
    // `collapsed(text.length)` here snapped the caret to the end on every
    // focus, making mid-text taps impossible to honour.
    if (_focusNode.hasFocus && widget.selectAllOnFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
    setState(() {
      /* Rebuild to reflect focus state. */
    });
  }

  /// Opens an editing session on the field that already holds focus.
  ///
  /// The engine ends the session when the on-screen keyboard is dismissed
  /// while the framework still believes the field is focused, so asking
  /// for focus again would change nothing — the keyboard is what has to
  /// be asked for.
  void _requestKeyboard() => editableTextKey.currentState?.requestKeyboard();

  void _handleTextChanged(String value) {
    // Ahead of `onChanged` so a listener holding both ends up with a caret
    // that belongs to the value it is about to receive — same ordering the
    // Web twin uses.
    widget.onCaretChanged?.call(_controller.selection.baseOffset);
    widget.onChanged?.call(value);
  }

  /// Wraps the input surface with the platform-aware selection gesture
  /// stack when interactive. A disabled field skips the wrapper entirely
  /// so taps place no caret and select nothing.
  Widget _wrapWithSelectionGestures(Widget child) {
    if (!_effectiveEnabled) return child;
    // The press is noted on the region that grants focus, so a press the
    // field answers with focus is read as the cause of it (see
    // [_showsFocusRing]). Translucent: it only watches.
    return Listener(
      behavior: .translucent,
      onPointerDown: (_) {
        _focusRing.pointerDown();
        setState(() => _pressed = true);
      },
      // The up and the cancel are delivered to the region the press began
      // in, wherever the pointer is released.
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: _selectionGestureBuilder.buildGestureDetector(
        behavior: .translucent,
        child: child,
      ),
    );
  }

  /// Toggles selection-handle visibility off the change [cause] (mirrors
  /// Material): handles for long-press / (non-collapsed) pointer
  /// selection, never for keyboard-driven changes.
  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final willShow = _shouldShowSelectionHandles(cause);
    if (willShow != _showSelectionHandles) {
      setState(() => _showSelectionHandles = willShow);
    }
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (!_selectionGestureBuilder.shouldShowSelectionToolbar) return false;
    if (!_effectiveEnabled) return false;
    // Keyboard-driven selection (arrow keys / shortcuts) never shows the
    // draggable handles — only pointer / long-press gestures do.
    if (cause == .keyboard) return false;
    if (widget.readOnly && _controller.selection.isCollapsed) return false;
    // Long-press (mobile word select) always shows handles; other pointer
    // gestures show them once there is text to grab. Stylus handwriting
    // falls through to the has-text check.
    if (cause == .longPress) return true;
    return _controller.text.isNotEmpty;
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted?.call(value);
    _formatSubmit();
  }

  void _formatSubmit() {
    final formatters = widget.submitFormatters;
    if (formatters == null || formatters.isEmpty) return;
    var value = _controller.value;
    for (final formatter in formatters) {
      value = formatter.formatEditUpdate(value, value);
    }
    _controller.value = value;
  }

  // ---------------------------------------------------------------------------
  // Input features (clear / password toggle)
  // ---------------------------------------------------------------------------

  bool _isFeatureVisible(CoreInputFeature feature, {required bool hasText}) {
    return switch (feature.visibility) {
      .always => true,
      .textNotEmpty => hasText,
      .textEmpty => !hasText,
      .focused => _focusNode.hasFocus,
      .hovered => _hovered,
    };
  }

  /// Builds one affordance button for [feature] — a `Button.plain`
  /// carrying the resolved [buttonStyle] (nested `featureButtonStyle`
  /// slot, raw-forwarded — same chrome path the Web affordance uses).
  /// Its icon inherits [iconTheme] (the resolved leading / trailing icon
  /// chrome — same chrome the Web affordance reuses).
  ///
  /// [index] indexes `widget.features`, selecting the owned focus node that
  /// carries [TextField.skipInputFeatureFocusTraversal] — the Tab-order
  /// counterpart of the Web affordance's `tabindex="-1"`.
  Widget _buildFeatureButton(
    CoreInputFeature feature,
    int index,
    IconThemeData iconTheme,
    CoreButtonStyle buttonStyle,
  ) {
    return Semantics(
      button: true,
      label: _featureLabel(feature),
      child: Button(
        onPressed: () => _handleFeatureTap(feature),
        variant: .plain,
        focusNode: _featureFocusNodes[index],
        buttonStyle: buttonStyle,
        child: IconTheme.merge(
          data: iconTheme,
          child: Icon(_featureIcon(feature)),
        ),
      ),
    );
  }

  void _handleFeatureTap(CoreInputFeature feature) {
    switch (feature.kind) {
      case .passwordToggle:
        setState(() => _obscured = !_obscured);
      case .clear:
        _controller.clear();
        widget.onChanged?.call('');
    }
  }

  IconName _featureIcon(CoreInputFeature feature) {
    return switch (feature.kind) {
      .passwordToggle =>
        _obscured
            ? (feature.icon ?? LucideIcons.eyeOff)
            : (feature.iconShown ?? LucideIcons.eye),
      .clear => feature.icon ?? LucideIcons.x,
    };
  }

  String? _featureLabel(CoreInputFeature feature) {
    return switch (feature.kind) {
      .clear => feature.semanticLabel ?? widget.clearButtonSemanticLabel,
      .passwordToggle => feature.semanticLabel,
    };
  }

  /// Reports only while inside the `FormField`'s own subtree.
  ///
  /// The field's [FormFieldHandle] travels as a `Data`, and a dialog or
  /// popover opened from within the field carries a copy of it — so a text
  /// box in that overlay (a search box, an "add tag" prompt) would report
  /// its text as the field's value. [FormFieldScope] is not a `Data` and is
  /// not copied, which makes it the tell: present means this input is the
  /// field's own, absent means it is somewhere the field only opened.
  @override
  bool get reportsToFormField => FormFieldScope.maybeOf(context) != null;

  /// A validator answered with a `ReplaceResult`: the field adopts the text.
  ///
  /// Writes through the controller, so the change reaches every listener
  /// the same as typing does (the form's own report included — the
  /// replacement is validated in its turn), and then tells the caller with
  /// `onChanged` / `onCaretChanged`, so a controlled `value` follows.
  ///
  /// The caret stays where the reader left it, held inside the new text.
  /// `controller.text = …` would drop it to an invalid position, which
  /// leaves a focused field with no caret until it is tapped.
  @override
  void didReplaceFormValue(String value) {
    if (value == _controller.text) return;
    final caret = _controller.selection.extentOffset;
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: caret < 0 || caret > value.length ? value.length : caret,
      ),
    );
    _handleTextChanged(value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formFieldScope = FormFieldScope.maybeOf(context);
  }

  String _obscureTextReseedMessage(TextField old) =>
      'TextField.obscureText changed from ${old.obscureText} to '
      '${widget.obscureText}, but it is only read when the field mounts — '
      'the change is ignored. Add CoreInputFeature.passwordToggle() to '
      '`features` for a show/hide control, or give the field a new `key` '
      'to restart from a different seed.';

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // `obscureText` seeds `_obscured` once; the field owns it afterwards
    // (a `passwordToggle` flips it). A caller flipping the prop instead —
    // the Material habit — would be silently ignored, so debug builds say
    // so. Reported rather than asserted: a throw here would replace the
    // whole subtree with an error. With a toggle feature present the field
    // already has its own control and the prop is not the caller's lever.
    assert(() {
      if (widget.obscureText != oldWidget.obscureText &&
          !widget.features.any((feature) => feature.kind == .passwordToggle)) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(_obscureTextReseedMessage(oldWidget)),
            library: 'coui_flutter',
            context: ErrorDescription('while updating a TextField'),
          ),
        );
      }
      return true;
    }(), 'debug-only report; never fails');

    // A press does not outlive the field's ability to take one: the up
    // would never arrive once the listener is gone.
    if (_pressed && !_effectiveEnabled) _pressed = false;

    // Controller.
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
        _ownsController = false;
      } else {
        // A caller's controller outlives this widget, so both listeners
        // have to come back off it — `dispose` above already covers the
        // owned case.
        _controller
          ..removeListener(_handleRangeCheck)
          ..removeListener(_handleFormValueChanged);
      }
      _initController();
      _handleRangeCheck();
      // The new controller may hold different text; the form is owed the
      // new answer even though nothing was typed.
      _handleFormValueChanged();
    }

    // FocusNode.
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode
          ..removeListener(_handleFocusChanged)
          ..dispose();
        _ownsFocusNode = false;
      }
      _initFocusNode();
    }

    // Feature focus nodes: both the feature count and the traversal flag
    // are live — `skipTraversal` is a mutable property, so a flag flip
    // reaches the existing nodes without rebuilding them.
    if (widget.features.length != oldWidget.features.length ||
        widget.skipInputFeatureFocusTraversal !=
            oldWidget.skipInputFeatureFocusTraversal) {
      _syncFeatureFocusNodes();
    }

    // Moving the bounds can flip the verdict on text that never changed.
    if (widget.min != oldWidget.min || widget.max != oldWidget.max) {
      _handleRangeCheck();
    }

    // Controlled `value`: the parent owns the text, so push external
    // changes into the controller (mirroring the HTML `<input value>`
    // model the legacy `Input` provided).
    final nextValue = widget.value;
    if (nextValue != null &&
        nextValue != oldWidget.value &&
        nextValue != _controller.text) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_handleHighlightMode);
    _focusNode.removeListener(_handleFocusChanged);
    _controller
      ..removeListener(_handleRangeCheck)
      ..removeListener(_handleFormValueChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    for (final node in _featureFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Behaviour flags
  // ---------------------------------------------------------------------------
  //
  // Input-policy booleans read straight off the widget — their
  // constructor defaults source `CoreTextFieldContract.defaultXxx`
  // (project-wide single source). No `coreComponentTheme` read here:
  // chrome flows through `resolveTextField`, and behaviour policy is a
  // widget concern, not a Theme `{style, variantStyles}` slot.

  Set<WidgetState> get _states => {
    if (!_effectiveEnabled) WidgetState.disabled,
    if (_focusNode.hasFocus) WidgetState.focused,
    // `_hovered` used to drive feature visibility alone, and the
    // `MouseRegion` that sets it was wired only when some feature asked
    // for it — so on a plain field the flag was permanently false. The
    // state layer reads it too now, which is why that wiring became
    // unconditional below.
    if (_hovered) WidgetState.hovered,
    // Pointer events reach the field only while it is enabled, and a field
    // disabled mid-press is cleared in `didUpdateWidget`.
    if (_pressed) WidgetState.pressed,
  };

  /// The states this field writes to [TextField.statesController].
  static const Set<WidgetState> _publishedStates = {
    WidgetState.disabled,
    WidgetState.focused,
    WidgetState.hovered,
    WidgetState.error,
  };

  /// Mirrors [states] onto [TextField.statesController].
  ///
  /// Written after the frame: the controller's listeners are the caller's,
  /// and one that rebuilds would otherwise be marking widgets dirty in the
  /// middle of this build. `update` notifies only on an actual change, so
  /// a rebuild that moves no state costs the listeners nothing.
  void _publishStates(Set<WidgetState> states) {
    final controller = widget.statesController;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.statesController != controller) return;
      for (final state in _publishedStates) {
        controller.update(state, states.contains(state));
      }
    });
  }

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement(
        defaultTargetPlatform,
      );

  /// Keyboard derived from the HTML-semantic [TextField.type] (absorbed
  /// from `Input`). An explicit [TextField.keyboardType] always wins.
  TextInputType get _effectiveKeyboardType =>
      widget.keyboardType ??
      switch (widget.type) {
        .text || .search => .text,
        .password => .visiblePassword,
        .email => .emailAddress,
        .number => .number,
        .tel => .phone,
        .url => .url,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = _states;

    // --- Style resolution ---------------------------------------------------

    // Ambient validation state — a wrapping `Validated` propagates its
    // state so the field's own error variant (border + focus ring)
    // switches to the error tone without a second stacked ring.
    final ambientValidation = Data.maybeOf<CoreValidationState>(context);
    // `_rangeViolated` is the Flutter half of what `<input min max>`
    // gets from the browser for free — same verdict, same error tone.
    //
    // A wrapping `FormField(error: ...)` folds in with OR — its error
    // puts this field's chrome into the error tone even when the field
    // was not separately told an `errorText`. The message itself stays
    // the wrapper's to show; only the tone reaches here.
    final hasError =
        widget.errorText != null ||
        ambientValidation == .invalid ||
        _rangeViolated ||
        (_formFieldScope?.hasError ?? false);
    _publishStates({...states, if (hasError) WidgetState.error});
    final resolved = resolveTextField(
      context,
      hasError: hasError,
      enabled: _effectiveEnabled,
      size: widget.size,
      variant: widget.variant,
      // `maxLines: null` grows with its text, `expands` fills its parent:
      // neither is held on one row.
      singleLine: widget.maxLines == 1 && !widget.expands,
      scrollPadding: widget.scrollPadding,
      textFieldStyle: widget.textFieldStyle,
      // A hosting `Join` squares the corners docking against a
      // neighbour (composition semantic, build-time).
      joinItemData: Data.maybeOf(context),
    );

    final tokenDecoration = resolved.decoration.resolve(states);
    final activeDecoration = resolved.activeDecoration.resolve(states);

    final tokenPadding = resolved.padding;

    // Text style: inherit the ambient DefaultTextStyle, then apply the
    // resolved per-state value style (which already carries the size
    // rung's body role at its own line height + normal-weight base).
    final tokenValueTs = resolved.valueTextStyle.resolve(states);
    final defaultTextStyle = DefaultTextStyle.of(
      context,
    ).style.merge(tokenValueTs);

    final placeholderTs = resolved.placeholderTextStyle;

    final cursorColor = resolved.cursorColor;

    final selectionColor = resolved.selectionColor;

    final keyboardAppearance = widget.keyboardAppearance ?? theme.brightness;

    // An obscured field never spell-checks, whatever the caller stated.
    // Spell check ships the field's text to a platform service, so a
    // caller that passes a configuration and obscures the same field
    // sends the password there — and the field renders identically
    // either way, so nothing shows that it happened.
    //
    // The gate is `_obscured`, not `widget.obscureText`: `type: .password`
    // obscures too, and the reveal toggle flips this at runtime. A field
    // the user just re-hid has to stop spell-checking from that moment.
    final spellCheckConfiguration = _obscured
        ? const SpellCheckConfiguration.disabled()
        : (widget.spellCheckConfiguration ??
              const SpellCheckConfiguration.disabled());

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

    // `RenderEditable` reserves the caret's margin — its 1px gap plus
    // `cursorWidth` — on the trailing edge, so centred text is measured
    // against `width - margin` and lands `margin / 2` left of the true
    // middle. Reserving the same margin on the leading edge when centring
    // rebalances the glyphs onto the real centre — parity with the
    // browser `<input>`, which reserves nothing.
    final centerCaretBalance = resolved.textAlign == .center
        ? EdgeInsets.only(left: _kEditableCaretGap + resolved.cursorWidth)
        : EdgeInsets.zero;

    final editable = RepaintBoundary(
      child: Padding(
        padding: centerCaretBalance,
        // `EditableText` builds its own `Focus` with semantics left out,
        // so the node that carries `isTextField` states no enabled state
        // and offers no focus action of its own. A web engine reads the
        // missing enabled state as a disabled input, and a disabled input
        // never receives the focus event that starts an editing session —
        // the field draws, announces itself, and takes no typing.
        //
        // Wrapped at the innermost point deliberately. `RenderEditable` is
        // no semantics boundary here, so this annotation merges into that
        // same node; lifted above the row it would merge with a sibling
        // affordance and describe the wrong thing while still reading as
        // wired.
        child: Semantics(
          enabled: _effectiveEnabled,
          // Assistive technology, and the web engine's semantics editing
          // strategy, reach the field through this action rather than
          // through a pointer event. A field that publishes no handler for
          // it cannot be entered by that route at all.
          //
          // A caller-supplied node may refuse focus; the field is still
          // asked for the keyboard so the two branches cover every
          // reachable state rather than asserting one of them away.
          onFocus: _effectiveEnabled
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
            readOnly: widget.readOnly || !_effectiveEnabled,
            obscuringCharacter: widget.obscuringCharacter,
            obscureText: _obscured,
            // Null reaches `EditableText` as null on purpose — that is where
            // it reads the autofill hints and turns autocorrect off for a
            // username or password field. Passing a non-null value here is
            // what stopped that inference from ever running.
            autocorrect: _obscured ? false : widget.autocorrect,
            // Suggestions are the keyboard's own store, which is why this is
            // a separate flag from autocorrect: turning autocorrect off does
            // not stop the field's text being kept for prediction.
            enableSuggestions: !_obscured && widget.enableSuggestions,
            style: defaultTextStyle,
            strutStyle: widget.strutStyle,
            cursorColor: cursorColor,
            backgroundCursorColor: resolved.backgroundCursorColor,
            textAlign: resolved.textAlign,
            textDirection: widget.textDirection,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            expands: widget.expands,
            autofocus: widget.autofocus,
            showCursor: widget.showCursor,
            showSelectionHandles: _showSelectionHandles,
            selectionColor: _focusNode.hasFocus ? selectionColor : null,
            selectionControls: widget.enableInteractiveSelection
                ? textSelectionControls
                : null,
            keyboardType: _effectiveKeyboardType,
            textInputAction: widget.textInputAction,
            // An obscured field is a password: capitalising its first letter
            // is not what was typed. The Web twin forces `autocapitalize`
            // off for the same reason, and the contract says masking wins.
            textCapitalization: _obscured
                ? TextCapitalization.none
                : widget.textCapitalization,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: _handleSubmitted,
            onSelectionChanged: _handleSelectionChanged,
            groupId: widget.groupId,
            onTapOutside: widget.onTapOutside,
            onTapUpOutside: widget.onTapUpOutside,
            inputFormatters: formatters,
            rendererIgnoresPointer: true,
            cursorWidth: resolved.cursorWidth,
            cursorHeight: resolved.cursorHeight,
            cursorRadius: resolved.cursorRadius,
            cursorOpacityAnimates: widget.cursorOpacityAnimates,
            paintCursorAboveText: true,
            selectionHeightStyle: widget.selectionHeightStyle,
            selectionWidthStyle: widget.selectionWidthStyle,
            scrollPadding: resolved.scrollPadding,
            keyboardAppearance: keyboardAppearance,
            dragStartBehavior: widget.dragStartBehavior,
            enableInteractiveSelection: widget.enableInteractiveSelection,
            scrollController: widget.scrollController,
            scrollPhysics: widget.scrollPhysics,
            autofillHints: widget.autofillHints,
            clipBehavior: widget.clipBehavior,
            restorationId: widget.restorationId,
            stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
            // The same leak with a longer memory: personalised learning adds
            // what is typed to the keyboard's user dictionary, so a password
            // typed once can be suggested later in another app's field.
            enableIMEPersonalizedLearning:
                !_obscured && widget.enableIMEPersonalizedLearning,
            contentInsertionConfiguration: widget.contentInsertionConfiguration,
            contextMenuBuilder: widget.contextMenuBuilder,
            spellCheckConfiguration: spellCheckConfiguration,
            magnifierConfiguration:
                widget.magnifierConfiguration ??
                TextMagnifier.adaptiveMagnifierConfiguration,
            undoController: widget.undoController,
          ),
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
        // Widget slot wins; the String `hintText` is the cross-platform
        // twin of Web's `placeholder` attribute — without this fallback
        // it was a declared-but-unrendered parameter and every
        // `hintText:` caller (PhoneInput, Command search, …) showed no
        // placeholder at all.
        final placeholderContent =
            widget.placeholder ??
            (widget.hintText == null
                ? null
                : Text(widget.hintText!, softWrap: widget.maxLines != 1));
        final placeholderWidget = placeholderContent == null
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
                    maxLines: widget.maxLines,
                    child: placeholderContent,
                  ),
                ),
              );

        final inputStack = Expanded(
          child: Stacks(
            alignment: .centerStart,
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

        // Built-in affordances visible at this text / focus / hover state,
        // split by side. The `ValueListenableBuilder` already rebuilds on
        // text change; `_handleFocusChanged` setState covers focus.
        // Indexed against the *declared* list so each affordance keeps the
        // focus node that carries `skipInputFeatureFocusTraversal`, even as
        // visibility filtering changes which ones render.
        final visibleFeatures = widget.features.indexed.where(
          (entry) => _isFeatureVisible(entry.$2, hasText: hasText),
        );
        final leadingFeatures = visibleFeatures.where(
          (entry) => entry.$2.position == .leading,
        );
        final trailingFeatures = visibleFeatures.where(
          (entry) => entry.$2.position == .trailing,
        );

        return Row(
          crossAxisAlignment: resolved.crossAxisAlignment,
          spacing: resolved.rowSpacing,
          children: [
            // An affix is `W?` — a glyph OR words (a unit, a count, a
            // timer). The icon theme sizes and tints a glyph; the text
            // style is what words wear, and it was missing, so a `Text`
            // suffix took the page's ambient style instead of the field's.
            if (widget.prefix != null)
              DefaultTextStyle.merge(
                style: resolved.affixTextStyle,
                child: IconTheme.merge(
                  data: leadingIconTheme,
                  child: widget.prefix!,
                ),
              ),
            for (final (index, feature) in leadingFeatures)
              _buildFeatureButton(
                feature,
                index,
                leadingIconTheme,
                resolved.featureButtonStyle,
              ),
            inputStack,
            for (final (index, feature) in trailingFeatures)
              _buildFeatureButton(
                feature,
                index,
                trailingIconTheme,
                resolved.featureButtonStyle,
              ),
            if (widget.suffix != null)
              DefaultTextStyle.merge(
                style: resolved.affixTextStyle,
                child: IconTheme.merge(
                  data: trailingIconTheme,
                  child: widget.suffix!,
                ),
              ),
          ],
        );
      },
      child: editable,
    );

    // --- Container with decoration + focus outline --------------------------

    // Unconditional now. These callbacks used to be installed only when a
    // feature asked to appear on hover, which left `_hovered` stuck at
    // false on every plain field — fine while nothing but feature
    // visibility read it, wrong the moment the fill does.
    Widget field = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: _effectiveEnabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.forbidden,
      child: FocusOutline(
        focused: _showsFocusRing,
        focusOutlineStyle: resolved.focusOutlineStyle,
        child: _wrapWithSelectionGestures(
          // `SurfaceBlur` sits inside the ring rather than around it —
          // the ring frames the same box either way, so wrapping here
          // does not move it. A no-op when the field paints no fill
          // (transparent override) or the active style states no
          // material.
          SurfaceBlur(
            borderRadius: tokenDecoration.borderRadius,
            surfaceBlur: resolved.surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: ConstrainedBox(
              constraints: _textFieldHeightConstraints(
                height: resolved.height,
                minHeight: resolved.minHeight,
                maxHeight: resolved.maxHeight,
              ),
              child: Container(
                decoration: tokenDecoration,
                // The active boundary (focus / error) is laid over the box
                // rather than added to the layout border, so the content does
                // not move when the field takes focus.
                foregroundDecoration: activeDecoration,
                child: Align(
                  alignment: Alignment(
                    -1,
                    resolved.textAlignVertical.y,
                  ),
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Padding(
                    padding: tokenPadding,
                    child: innerContent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // --- Label / Description / Error wrapping -------------------------------

    if (widget.label != null ||
        widget.description != null ||
        widget.errorText != null) {
      field = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          if (widget.label != null)
            Padding(
              padding: resolved.labelPadding,
              child: FormLabel(
                label: Text(
                  widget.label!,
                  maxLines: widget.labelMaxLines,
                  overflow: widget.labelOverflow?.toValue(),
                ),
                isRequired: widget.required,
                size: widget.size,
                enabled: _effectiveEnabled,
                formLabelStyle: resolved.labelFormLabelStyle,
              ),
            ),
          field,
          if (widget.description != null && widget.errorText == null)
            Padding(
              padding: resolved.descriptionPadding,
              child: Text(
                widget.description!,
                style: resolved.descriptionTextStyle,
              ),
            ),
          if (widget.errorText != null)
            Padding(
              padding: resolved.descriptionPadding,
              child: Text(
                widget.errorText!,
                style: resolved.errorTextStyle,
              ),
            ),
        ],
      );
    }

    return field;
  }
}

/// [TextSelectionGestureDetectorBuilder] subclass for `TextField`.
///
/// The base builder already wires the full platform-aware selection stack
/// (single / double / triple tap, drag-select, iOS force-press, mobile
/// long-press with handles + toolbar + magnifier). This subclass only
/// routes the user's tap through the widget's `onTap` callback (Material
/// does the same via `onUserTap`), so callers keep their tap handler
/// without re-implementing any selection behaviour.
class _CoTextFieldSelectionGestureBuilder
    extends TextSelectionGestureDetectorBuilder {
  _CoTextFieldSelectionGestureBuilder({required _TextFieldState state})
    : _state = state,
      super(delegate: state);

  final _TextFieldState _state;

  @override
  void onUserTap() => _state.widget.onTap?.call();
}

/// Chain sugar for merging a [CoreTextFieldStyle] patch into
/// [TextField.textFieldStyle] without hand-reconstructing every field.
/// Mirrors the Web `TextField.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextFieldStyle.merge` right-side-wins semantics).
///
/// `.error` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension TextFieldStyleChain on TextField {
  /// Sets the background paint and preserves the other style fields.
  TextField backgroundColor(CoreColor value) =>
      withStyle(CoreTextFieldStyle(backgroundColor: value));

  /// Returns a copy of this [TextField] with [patch] merged into
  /// [textFieldStyle] (patch fields win on conflict).
  TextField withStyle(CoreTextFieldStyle patch) => copyWith(
    textFieldStyle: (textFieldStyle ?? const CoreTextFieldStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  TextField get radius0 => withStyle(
    const CoreTextFieldStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  TextField get radius2 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  TextField get radius4 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  TextField get radius6 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  TextField get radius8 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  TextField get radius10 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  TextField get radius12 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  TextField get radius14 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  TextField get radius16 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  TextField get radius20 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  TextField get radius24 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  TextField get radius28 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  TextField get radius32 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  TextField get radius36 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  TextField get radius40 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  TextField get radius48 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  TextField get radius56 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  TextField get radius64 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  TextField get radius9999 => withStyle(
    const CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  TextField get primary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  TextField get secondary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  TextField get tertiary => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  TextField get surface => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  TextField get surfaceContainer => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// Selects `variant: .error` using the component theme.
  TextField get error => copyWith(variant: .error);

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  TextField get success => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  TextField get warning => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  TextField get info => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  TextField get outline => withStyle(
    const CoreTextFieldStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  TextField get transparent => withStyle(
    const CoreTextFieldStyle(backgroundColor: .transparent),
  );
}
