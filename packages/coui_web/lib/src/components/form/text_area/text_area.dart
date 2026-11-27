import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/form/form_label/form_label.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
// `observeElementResize` is hidden here so the general DOM utility above
// stays the one this component uses — the overlay module's copy exists for
// the positioning engine, which measures anchors rather than fields.
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart'
    hide observeElementResize;
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

int _coTextAreaScopeCounter = 0;

/// Unified cross-platform multi-line text area for CoUI Web.
///
/// [TextArea] implements [CoreTextAreaContract] for cross-platform
/// API parity with the Flutter implementation.
///
/// Internally a [StatefulComponent] so the wrapper can track keyboard
/// focus on the underlying `<textarea>` (`:focus-visible`) and forward
/// it to [FocusOutline] — the same model the Flutter implementation
/// uses.
///
/// Example:
/// ```dart
/// TextArea(
///   placeholder: 'Type your message here.',
///   rows: 4,
///   onChanged: (value) => print(value),
/// )
/// ```
///
/// surface:behind — the area's box paints on a wrapper `<div>` around the
/// native `<textarea>` (the footer frame, once there is a footer) rather
/// than composing `OutlinedContainer`, so what shows through it is
/// the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class TextArea extends UiStatefulComponent
    implements
        CoreTextAreaContract<
          Component,
          Null,
          Null,
          void Function(),
          List<CoreInputFormatter>
        > {
  /// Creates a [TextArea].
  const TextArea({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
    this.autocorrect,
    this.size = CoreComponentSize.md,
    this.variant = CoreTextAreaVariant.defaultTextAreaVariant,
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
    this.obscureText = false,
    this.obscuringCharacter = CoreTextAreaContract.defaultObscuringCharacter,
    // === Contract — Cursor ===
    this.showCursor,
    // === Contract — Keyboard ===
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    // === Contract — Input formatting ===
    this.inputFormatters,
    // === Contract — Callbacks ===
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    // === Contract — Prefix/Suffix ===
    this.prefix,
    this.suffix,
    // === Contract — Footer ===
    this.footer,
    // === Style (chrome / dimensional / cursor / nested slot) ===
    this.textAreaStyle,
    // === Contract — Resize ===
    this.expandableHeight = false,
    this.expandableWidth = false,
    this.onHeightChanged,
    this.onWidthChanged,
    // === Web extended ===
    this.cols,
  });

  // === Contract fields ===

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

  /// Whether the text is masked.
  ///
  /// Rendered with `-webkit-text-security`, the browser's only surface for
  /// obscuring a multi-line control. An obscured area also opts out of the
  /// browser's text services (see `_buildTextareaAttributes`) so its
  /// contents reach no spell checker and no keyboard dictionary.
  @override
  final bool obscureText;

  /// Mask character. The web draws one of three shapes rather than an
  /// arbitrary glyph, so this picks the nearest — see
  /// `CoreTextAreaContract.obscuringCharacter`.
  @override
  final String obscuringCharacter;

  /// When `false`, hides the text caret (parity with Flutter
  /// `EditableText.showCursor: false`). `null` / `true` shows the caret.
  @override
  final bool? showCursor;

  /// HTML `inputmode` attribute value — picks the on-screen keyboard.
  @override
  final String? keyboardType;

  /// HTML `enterkeyhint` attribute value.
  @override
  final String? textInputAction;

  /// HTML `autocapitalize` attribute value.
  @override
  final String? textCapitalization;

  /// Formatters applied to the text as it changes (parity with Flutter
  /// `TextArea.inputFormatters`). Web binds [CoreInputFormatter]; the
  /// param name matches Flutter, the binding type differs (generic).
  @override
  final List<CoreInputFormatter>? inputFormatters;

  /// Called when editing completes — the `change` event, which a
  /// `<textarea>` fires on commit (blur). Enter inserts a newline here, so
  /// unlike the single-line field there is no key to key on.
  @override
  final CoreVoidCallback? onEditingComplete;

  /// Called when the text area is tapped (HTML `click` event).
  @override
  final CoreVoidCallback? onTap;

  /// Called on a pointer-down outside the area (parity with Flutter
  /// `TextArea.onTapOutside`). Wired via a document `pointerdown`
  /// listener scoped to the area's root id.
  @override
  final void Function()? onTapOutside;

  /// Called with the area's new height in CSS pixels while
  /// [expandableHeight] is set — driven by a `ResizeObserver` on the
  /// `<textarea>`, whose native grip performs the drag.
  @override
  final CoreValueChanged<double>? onHeightChanged;

  /// Called with the area's new width in CSS pixels while
  /// [expandableWidth] is set.
  @override
  final CoreValueChanged<double>? onWidthChanged;

  @override
  final Component? prefix;

  @override
  final Component? suffix;

  @override
  final Component? footer;

  /// Per-instance style covering chrome (border, background) plus
  /// dimensional (paddings), cursor, and nested label / placeholder /
  /// value / description / error / leading / trailing icon styles.
  @override
  final CoreTextAreaStyle? textAreaStyle;

  @override
  final bool expandableHeight;

  @override
  final bool expandableWidth;

  // === Flutter-only contract fields ===

  @override
  Null get controller => null;

  @override
  Null get focusNode => null;

  // `autocorrect`, `autocapitalize` and `spellcheck` are emitted as
  // `<textarea>` attributes — see `_buildTextareaAttributes`, which also
  // gates all three on the obscured state. The remaining interaction
  // policy fields (input-method suggestions, interactive selection, IME
  // personalised-learning, stylus handwriting, cursor-opacity animation)
  // have no per-`<textarea>` switch; the browser's native behaviour
  // applies and the getters below only state a value.
  @override
  final bool? autocorrect;

  /// Always null — the web states spell check as an element attribute,
  /// not a configuration object.
  ///
  /// This is not an unimplemented slot. `spellcheck` is emitted on the
  /// `<textarea>` (off while obscured), which is the same capability
  /// through the platform's own vocabulary. A plain area states nothing
  /// and keeps the browser's default: a comment box is spell-checked on
  /// purpose.
  @override
  Object? get spellCheckConfiguration => null;

  /// Always null — the browser draws its own selection loupe on touch.
  @override
  Object? get magnifierConfiguration => null;

  /// Input-method suggestions, as the Flutter twin computes them.
  ///
  /// Nothing on the web reads this (a `<textarea>` has no per-element
  /// switch), but the two platforms must not *state* different values for
  /// the same field — Flutter's effective value is `false` while obscured.
  @override
  bool get enableSuggestions {
    // An obscured area hands its text to no keyboard dictionary.
    if (obscureText) return false;
    return CoreTextAreaContract.defaultEnableSuggestions;
  }

  @override
  bool get enableInteractiveSelection =>
      CoreTextAreaContract.defaultEnableInteractiveSelection;

  /// IME personalised learning, as the Flutter twin computes it — see
  /// [enableSuggestions] for why an obscured area reports it off.
  @override
  bool get enableIMEPersonalizedLearning {
    if (obscureText) return false;
    return CoreTextAreaContract.defaultEnableIMEPersonalizedLearning;
  }

  @override
  bool get stylusHandwritingEnabled =>
      CoreTextAreaContract.defaultStylusHandwritingEnabled;

  @override
  bool get cursorOpacityAnimates =>
      CoreTextAreaContract.defaultCursorOpacityAnimates;

  // === Web extended ===

  /// Number of visible text columns (HTML `cols` attribute).
  final int? cols;

  // === Internal constants ===

  static const _kTextarea = 'textarea';
  static const _kPlaceholderAttr = 'placeholder';
  static const _kDisabledAttr = 'disabled';
  static const _kReadonlyAttr = 'readonly';
  static const _kRowsAttr = 'rows';
  static const _kColsAttr = 'cols';
  static const _kNameAttr = 'name';
  static const _kMaxlengthAttr = 'maxlength';
  static const _kAutocorrectAttr = 'autocorrect';
  static const _kOffValue = 'off';
  static const _kNoneValue = 'none';
  static const _kRequiredAttr = 'required';
  static const _kAutofocusAttr = 'autofocus';
  static const _kEmptyValue = '';
  static const String _kRelative = WebLayout.relative;

  /// Returns a copy of this [TextArea] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TextArea copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    String? placeholder,
    String? initialValue,
    CoreValueChanged<String>? onChanged,
    CoreValueChanged<String>? onSubmitted,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    bool? selectAllOnFocus,
    CoreEdgeInsets? scrollPadding,
    bool? autocorrect,
    CoreComponentSize? size,
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
    bool? obscureText,
    String? obscuringCharacter,
    bool? showCursor,
    String? keyboardType,
    String? textInputAction,
    String? textCapitalization,
    List<CoreInputFormatter>? inputFormatters,
    CoreVoidCallback? onEditingComplete,
    CoreVoidCallback? onTap,
    void Function()? onTapOutside,
    CoreValueChanged<double>? onHeightChanged,
    CoreValueChanged<double>? onWidthChanged,
    Component? prefix,
    Component? suffix,
    Component? footer,
    CoreTextAreaStyle? textAreaStyle,
    bool? expandableHeight,
    bool? expandableWidth,
    int? cols,
  }) {
    return TextArea(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      placeholder: placeholder ?? this.placeholder,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      autofocus: autofocus ?? this.autofocus,
      selectAllOnFocus: selectAllOnFocus ?? this.selectAllOnFocus,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      autocorrect: autocorrect ?? this.autocorrect,
      size: size ?? this.size,
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
      obscureText: obscureText ?? this.obscureText,
      obscuringCharacter: obscuringCharacter ?? this.obscuringCharacter,
      showCursor: showCursor ?? this.showCursor,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      footer: footer ?? this.footer,
      textAreaStyle: textAreaStyle ?? this.textAreaStyle,
      expandableHeight: expandableHeight ?? this.expandableHeight,
      expandableWidth: expandableWidth ?? this.expandableWidth,
      onHeightChanged: onHeightChanged ?? this.onHeightChanged,
      onWidthChanged: onWidthChanged ?? this.onWidthChanged,
      cols: cols ?? this.cols,
    );
  }

  @override
  State<TextArea> createState() => _TextAreaState();
}

/// Chain sugar mirroring the Flutter `TextArea.withStyle` extension —
/// merges a [CoreTextAreaStyle] patch into [TextArea.textAreaStyle] via
/// the existing [TextArea.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextAreaStyle.merge` right-side-wins semantics).
///
/// `.error` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension TextAreaStyleChain on TextArea {
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
      borderRadius: CoreBorderRadius.zero,
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

class _TextAreaState extends State<TextArea> {
  /// Tracks `:focus-visible` on the underlying `<textarea>` to drive
  /// [FocusOutline]. Mirrors the Flutter widget's `_focusNode.hasFocus`
  /// + highlight-mode logic.
  bool _focused = false;

  // Set by a pointer press on the field and read by the `focus` that the
  // press causes (#5747): a text input matches `:focus-visible` however it
  // was focused, so the browser's own rule would ring a clicked field. The
  // outer ring is a keyboard signal — a pointer focus shows on the `primary`
  // active boundary alone, the way the Flutter twin reads
  // `FocusHighlightMode`.
  final _focusModality = CoreInputFocusModality();

  /// Stable per-instance id for the `<textarea>`. Carried by the element
  /// only when something needs to find it — a scoped `::selection` rule or
  /// a `ResizeObserver` — so the default path stays id-less.
  late final String _elementId;

  /// Id for the frame `<div>` of an area with a footer — the box whose
  /// size a resize reports once a footer shares the box with the
  /// `<textarea>`. Carried only while a resize callback is wired.
  String get _frameId => '$_elementId-frame';

  /// The element whose border box a resize reports: the box. That is the
  /// `<textarea>` alone, or the frame once a footer joins it.
  String get _boxId => component.footer != null ? _frameId : _elementId;

  /// Root id used by the outside-pointer listener's containment test. The
  /// caller's id wins when supplied, so passthrough is preserved.
  ///
  /// The root rather than the `<textarea>` is the container: a tap on the
  /// label or the helper text is inside the field's region, which is what
  /// Flutter's `TapRegion` treats it as.
  late final String _rootId;

  /// Whether an outside-pointer callback is wired (drives whether the root
  /// is forced to carry [_rootId] — keeps default-path markup unchanged).
  late final bool _needsRootScope;

  /// Whether a resize callback is wired on an axis the user can drag.
  ///
  /// Both halves are required: a `ResizeObserver` on a non-resizable axis
  /// reports reflows, and Flutter's callbacks fire only from the drag
  /// handle. Observing anyway would make the same callback mean different
  /// things on the two platforms.
  late final bool _observesResize;

  /// Disposer for the document `pointerdown` listener (`onTapOutside`).
  void Function()? _disposeTapOutside;

  /// Disposer for the `<textarea>` `ResizeObserver`.
  void Function()? _disposeResizeObserver;

  /// Last observed size in CSS pixels. Null until the observer's first
  /// report, which states the element's current size rather than a change
  /// — Flutter does not call back on mount, so neither does this.
  double? _lastHeight;
  double? _lastWidth;

  bool _isMounted = false;

  /// Last committed text — fed to [CoreInputFormatter.format] as the
  /// `oldValue`, so a filtering formatter can reject an edit by returning
  /// the previous value.
  String _lastValue = '';

  /// The obscured state. A `<textarea>` has no reveal toggle, so this is
  /// the constructor flag — but it is read through one name so every text
  /// service is gated on the same thing.
  bool get _obscured => component.obscureText;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _lastValue = component.initialValue ?? TextArea._kEmptyValue;
    // Scoped rules, observation and outside-click ownership share this
    // State's identity; caller keys are only unique within their parent.
    _elementId =
        'co-text-area-${kIsWeb ? 'web' : 'ssr'}-${_coTextAreaScopeCounter++}';
    _rootId = component.id ?? '$_elementId-root';
    _needsRootScope = component.onTapOutside != null;
    _observesResize =
        (component.expandableHeight && component.onHeightChanged != null) ||
        (component.expandableWidth && component.onWidthChanged != null);

    if (_needsRootScope) {
      _disposeTapOutside = registerDocumentOutsidePointerListener(
        // Read through `component` rather than the mount-time closure: a
        // rebuild hands over a fresh callback, and the fresh one is the
        // one that captured the caller's current state.
        () {
          if (_isMounted) component.onTapOutside?.call();
        },
        containerIds: () => [_rootId],
        eventType: 'pointerdown',
      );
    }

    // The observer needs the element in the document, so it attaches after
    // the first client render. No-op on the server (stub `scheduleNextFrame`).
    if (_observesResize) scheduleNextFrame(_attachResizeObserver);
  }

  void _attachResizeObserver() {
    if (!_isMounted) return;
    // The observer is the trigger; the reported size is read separately —
    // see [_handleResize] for why its content-box numbers are not the ones
    // the callbacks carry. The trigger is the `<textarea>` even when a
    // footer makes the frame the box: the native grip moves the
    // `<textarea>`, while a change in the footer's own content grows the
    // frame and leaves the `<textarea>` as it was — so a footer that gains a
    // row of attachments is not reported as a resize.
    _disposeResizeObserver = observeElementResize(
      _elementId,
      (_, _) => _handleResize(),
    );
  }

  @override
  void didUpdateComponent(TextArea oldComponent) {
    super.didUpdateComponent(oldComponent);
    // A footer or an affix arriving or leaving moves the `<textarea>` to a
    // new place in the tree, and so to a new element; the observer stays on
    // the old one and the callbacks go quiet. Re-attach to the new element
    // after it renders. The first report after that states its size again
    // rather than a resize, as on mount.
    if (!_observesResize) return;
    bool affixedOf(TextArea area) => area.prefix != null || area.suffix != null;
    final moved =
        (oldComponent.footer == null) != (component.footer == null) ||
        affixedOf(oldComponent) != affixedOf(component);
    if (!moved) return;
    _disposeResizeObserver?.call();
    _disposeResizeObserver = null;
    _lastHeight = null;
    _lastWidth = null;
    scheduleNextFrame(_attachResizeObserver);
  }

  /// Reports a user resize on the axes the caller made draggable.
  ///
  /// The size is the box's **border box** — the `<textarea>`'s, or the
  /// frame's once a footer shares the box, footer included — which is the
  /// quantity the Flutter twin reports (its `SizedBox` wraps the field's own
  /// border and padding, and the footer inside them) and the quantity the
  /// caller can feed straight back into `CoreTextAreaStyle.initialHeight`.
  /// `ResizeObserver` hands out the *content* box instead, and with the
  /// global `box-sizing: border-box` that is smaller by the padding and
  /// border — a value which, round tripped through `initialHeight`, would
  /// shrink the field on every resize on one platform only.
  void _handleResize() {
    if (!_isMounted) return;
    final element = web.document.getElementById(_boxId);
    if (element == null) return;
    final rect = element.getBoundingClientRect();
    final height = rect.height;
    final width = rect.width;
    final previousHeight = _lastHeight;
    final previousWidth = _lastWidth;
    _lastHeight = height;
    _lastWidth = width;
    // The first report states the element's current size, not a resize.
    if (previousHeight == null || previousWidth == null) return;
    if (component.expandableHeight && height != previousHeight) {
      component.onHeightChanged?.call(height);
    }
    if (component.expandableWidth && width != previousWidth) {
      component.onWidthChanged?.call(width);
    }
  }

  /// Runs [formatters] in order against the element's current value,
  /// feeding [_lastValue] as the previous text, writes the result back
  /// when it changed, and returns the committed text.
  String _runFormatters(
    List<CoreInputFormatter> formatters,
    web.HTMLTextAreaElement target,
  ) {
    var value = target.value;
    for (final formatter in formatters) {
      value = formatter.format(_lastValue, value);
    }
    if (value != target.value) {
      target.value = value;
    }
    return value;
  }

  Map<String, String> _buildTextareaAttributes() {
    final attrs = <String, String>{};

    final currentPlaceholder = component.placeholder;
    if (currentPlaceholder != null) {
      attrs[TextArea._kPlaceholderAttr] = currentPlaceholder;
    }

    if (!component.enabled) {
      attrs[TextArea._kDisabledAttr] = TextArea._kEmptyValue;
    }

    if (component.readOnly) {
      attrs[TextArea._kReadonlyAttr] = TextArea._kEmptyValue;
    }

    if (component.required) {
      attrs[TextArea._kRequiredAttr] = TextArea._kEmptyValue;
    }

    if (component.autofocus) {
      attrs[TextArea._kAutofocusAttr] = TextArea._kEmptyValue;
    }

    final currentRows = component.rows;
    if (currentRows != null) {
      attrs[TextArea._kRowsAttr] = currentRows.toString();
    }

    final currentCols = component.cols;
    if (currentCols != null) {
      attrs[TextArea._kColsAttr] = currentCols.toString();
    }

    final currentName = component.name;
    if (currentName != null) {
      attrs[TextArea._kNameAttr] = currentName;
    }

    final currentMaxLength = component.maxLength;
    if (currentMaxLength != null) {
      attrs[TextArea._kMaxlengthAttr] = currentMaxLength.toString();
    }

    // An obscured area opts out of every text service the browser would
    // otherwise apply. Left alone these default to *on* for an editable
    // element, so the platform needing the explicit statement is this one
    // — Flutter's equivalents default to off, and a kit whose masked field
    // is quiet on one platform and spell-checked on the other has a leak
    // on exactly one side.
    //
    // `spellcheck` is the one that leaves the machine: the browser may
    // send the value to a remote checker. `autocorrect` and
    // `autocapitalize` feed the on-screen keyboard's dictionary, which is
    // the same leak with a longer memory.
    if (_obscured) {
      attrs['spellcheck'] = 'false';
    }

    // Null means "let the platform decide", which on the web is the
    // browser's own default — so only a stated `false`, or the obscured
    // state, emits anything.
    if (_obscured || component.autocorrect == false) {
      attrs[TextArea._kAutocorrectAttr] = TextArea._kOffValue;
    }

    final currentKeyboardType = component.keyboardType;
    if (currentKeyboardType != null) {
      attrs['inputmode'] = currentKeyboardType;
    }

    final currentTextInputAction = component.textInputAction;
    if (currentTextInputAction != null) {
      attrs['enterkeyhint'] = currentTextInputAction;
    }

    // An obscured area capitalises nothing — that is the keyboard's
    // dictionary again, and it wins over a stated value rather than being
    // written after it.
    final currentTextCapitalization = _obscured
        ? TextArea._kNoneValue
        : component.textCapitalization;
    if (currentTextCapitalization != null) {
      attrs['autocapitalize'] = currentTextCapitalization;
    }

    return attrs;
  }

  Map<String, EventCallback> _buildTextareaEvents() {
    final currentOnChanged = component.onChanged;
    final currentOnSubmitted = component.onSubmitted;
    final currentOnTap = component.onTap;
    final currentOnEditingComplete = component.onEditingComplete;
    final formatters =
        component.inputFormatters ?? const <CoreInputFormatter>[];
    final hasInputFormatters = formatters.isNotEmpty;

    return {
      if (currentOnChanged != null ||
          hasInputFormatters ||
          component.showCounter)
        'input': EventHandlers.createTextAreaTargetEventHandler((_, target) {
          final value = hasInputFormatters
              ? _runFormatters(formatters, target)
              : target.value;
          // The character count follows the text live (#5747).
          if (component.showCounter) {
            setState(() => _lastValue = value);
          } else {
            _lastValue = value;
          }
          currentOnChanged?.call(value);
        }),
      // `change` fires once the edit is committed, which for a
      // `<textarea>` means blur — Enter inserts a newline here. Both
      // callbacks land on it, in the order `EditableText` uses:
      // editing-complete first, then the submitted value.
      if (currentOnSubmitted != null || currentOnEditingComplete != null)
        'change': EventHandlers.createTextAreaTargetEventHandler((_, target) {
          currentOnEditingComplete?.call();
          currentOnSubmitted?.call(target.value);
        }),
      if (currentOnTap != null) 'click': (_) => currentOnTap(),
      // Mirror W3C `:focus-visible`: ring on iff focus arrived via
      // keyboard. Forward to the surrounding [FocusOutline]. Also
      // honour `selectAllOnFocus` for cross-platform parity with the
      // Flutter implementation. Resolves with the usual
      // widget > theme > default precedence.
      //
      // Typed handler via `EventHandlers.createTextAreaTargetEventHandler`:
      // dart2js release minifies dynamic getter dispatches (e.g.
      // `event.target` → `event.gdE`) into mangled names that
      // compile-graph changes can desync, leaving the ring stuck in its
      // unfocused state in production. Routing the cast through the
      // helper keeps the call site mangling-resilient.
      'focus': EventHandlers.createTextAreaTargetEventHandler((_, target) {
        // `selectAllOnFocus` is project-wide behaviour sourced from the
        // per-instance widget flag (contract-defaulted), not from
        // `CoreTextAreaTheme` (now `{style, variantStyles}` only).
        if (component.selectAllOnFocus) {
          selectInputText(target);
        }
        final isVisible = _focusModality.focus(
          platformShowsRing: target.matches(':focus-visible'),
        );
        setState(() => _focused = isVisible);
      }),
      'blur': (_) {
        _focusModality.blur();
        setState(() => _focused = false);
      },
      'pointerdown': (_) => _focusModality.pointerDown(),
    };
  }

  @override
  void dispose() {
    _isMounted = false;
    _disposeTapOutside?.call();
    _disposeResizeObserver?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final currentLabel = component.label;
    final currentDescription = component.description;
    final currentError = component.errorText;
    final currentPrefix = component.prefix;
    final currentSuffix = component.suffix;
    final currentFooter = component.footer;

    final effectiveSize = component.size;

    // Single entry point — resolves the nested-merge chain
    // (theme.style → theme.errorStyle → widget.textAreaStyle) plus
    // token conversion in `text_area_style.dart`.
    final resolved = resolveTextArea(
      context,
      size: effectiveSize,
      expandableHeight: component.expandableHeight,
      expandableWidth: component.expandableWidth,
      hasError: currentError != null,
      obscureText: component.obscureText,
      obscuringCharacter: component.obscuringCharacter,
      hasFooter: currentFooter != null,
      enabled: component.enabled,
      variant: component.variant,
      showCursor: component.showCursor,
      scrollPadding: component.scrollPadding,
      textAreaStyle: component.textAreaStyle,
    );

    // Scoped `::selection` rule for the per-instance scope id. The
    // `::selection` pseudo-element has no inline-CSS surface, so a raw
    // (token-less) `selectionColor` override is painted via a
    // `#scopeId::selection{…}` rule instead of a Tailwind class.
    final rules = resolveTextAreaRules(
      context,
      scopeId: _elementId,
      hasError: currentError != null,
      enabled: component.enabled,
      textAreaStyle: component.textAreaStyle,
    );
    final hasScopedRules = rules.css.isNotEmpty;

    // The `<textarea>` carries its id only when something looks the
    // element up — the scoped rule's selector, or the `ResizeObserver`
    // behind `onHeightChanged` / `onWidthChanged`. Default-path markup
    // stays id-less (the root `<div>` owns `component.id`).
    final textareaElement = Component.element(
      tag: TextArea._kTextarea,
      id: hasScopedRules || _observesResize ? _elementId : null,
      classes: resolved.textarea.className,
      styles: resolved.textarea.inlineStyles,
      attributes: _buildTextareaAttributes(),
      events: _buildTextareaEvents(),
      children: [
        if (component.initialValue != null)
          Component.text(component.initialValue!),
      ],
    );

    Component affixSlot(Component affix) => span(
      [affix],
      classes: resolved.affixSlot.className,
      styles: resolved.affixSlot.inlineStyles,
    );

    // Decorative resize-handle affordance, mirroring the Flutter painted
    // handle. The native CSS `resize` grip drives the drag underneath
    // (`pointer-events: none` on the indicator).
    final expandable = component.expandableHeight || component.expandableWidth;
    final resizeHandle = div(
      const [],
      classes: resolved.resizeHandle.className,
      styles: resolved.resizeHandle.inlineStyles,
    );

    final Component handledBody;
    if (currentFooter == null) {
      // The box is always this wrapper, never the bare `<textarea>`: a
      // native `<textarea>` is a replaced element and cannot carry the
      // box's pseudo-element layers (a glass surface's edge band).
      final framedBody = div(
        [
          if (currentPrefix != null) affixSlot(currentPrefix),
          textareaElement,
          if (currentSuffix != null) affixSlot(currentSuffix),
        ],
        classes: resolved.affixWrapper.className,
        styles: resolved.affixWrapper.inlineStyles,
      );

      // The handle overlays the field's bottom-right corner — wrapped in a
      // `position: relative` container so the absolutely-positioned handle
      // anchors to the field.
      handledBody = expandable
          ? div([framedBody, resizeHandle], classes: TextArea._kRelative)
          : framedBody;
    } else {
      // A footer shares the box with the text, so the frame is the box: the
      // text row (with the handle on its own corner, where the native grip
      // sits — not the box's, where the footer's trailing action sits), the
      // gap, and the footer, which stays outside the `<textarea>` and so
      // outside the editing surface. The frame carries its id while a
      // resize callback is wired, so a resize reports the whole box.
      handledBody = div(
        [
          div(
            [
              if (currentPrefix != null) affixSlot(currentPrefix),
              textareaElement,
              if (currentSuffix != null) affixSlot(currentSuffix),
              if (expandable) resizeHandle,
            ],
            classes: resolved.textRow.className,
            styles: resolved.textRow.inlineStyles,
          ),
          Gap(gapStyle: resolved.footerGapStyle),
          div(
            [currentFooter],
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          ),
        ],
        id: _observesResize ? _frameId : null,
        classes: resolved.frame.className,
        styles: resolved.frame.inlineStyles,
      );
    }

    // Forward the resolved focus-outline slot straight to FocusOutline
    // (옵션 B nested-slot path) — the resolver folded the per-instance
    // `focusOutlineStyle` override onto the text-area radius default, so
    // a caller override (radius / colour / width) reaches the ring while
    // the unset colour defers to FocusOutline's reactive primary ring.
    final ringedBody = FocusOutline(
      focused: _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: handledBody,
    );

    final hasHelperText = currentDescription != null || currentError != null;
    // The description or the error — the line a counter, when asked, ends
    // (#5747).
    final helperLine = currentError != null
        ? p(
            [Text(currentError)],
            classes: resolved.error.className,
            styles: resolved.error.inlineStyles,
          )
        : currentDescription != null
        ? p(
            [Text(currentDescription)],
            classes: resolved.description.className,
            styles: resolved.description.inlineStyles,
          )
        : null;

    return div(
      [
        // `<style>` is `display: none`, so it never affects the flex-col
        // layout. Present only when a raw `selectionColor` override needs
        // the scoped `#scopeId::selection` rule.
        if (hasScopedRules)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        if (currentLabel != null) ...[
          // A composed `FormLabel`, the way the `TextField` twin and the
          // Flutter twin both compose it — not a hand-rolled `<label>`
          // with its own asterisk. The raw element that stood here stated
          // its own typography and so rendered one size on every rung,
          // while `FormLabel` resolves the role from its per-size ladder;
          // the asterisk it drew was also an unlabelled `*` a reader
          // announced after the words.
          FormLabel(
            label: Text(
              currentLabel,
              maxLines: component.labelMaxLines,
              overflow: component.labelOverflow,
            ),
            isRequired: component.required,
            size: component.size,
            enabled: component.enabled,
            formLabelStyle: resolved.formLabelStyle,
            classes: resolved.labelHost.className,
          ),
          Gap(gapStyle: resolved.labelGapStyle),
        ],
        ringedBody,
        if (hasHelperText || component.showCounter)
          Gap(gapStyle: resolved.descriptionGapStyle),
        if (component.showCounter)
          div(
            [
              ?helperLine,
              Gap(gapStyle: resolved.counterGapStyle),
              span(
                [
                  Text(
                    CoreTextAreaContract.counterLabel(
                      _lastValue,
                      maxLength: component.maxLength,
                    ),
                  ),
                ],
                classes: resolved.counter.className,
                styles: resolved.counter.inlineStyles,
              ),
            ],
            classes: resolved.helperRow.className,
          )
        else
          ?helperLine,
      ],
      // Forced to the generated id only when the outside-pointer listener
      // needs a containment target; otherwise the caller's id passes
      // through untouched.
      id: _needsRootScope ? _rootId : component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
