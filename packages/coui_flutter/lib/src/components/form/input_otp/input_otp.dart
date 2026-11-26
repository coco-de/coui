import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';

/// Chromeless, fully-transparent style for the hidden OTP buffer: the visual
/// N-cell row renders the digits on top, so the backing unified [TextField]
/// suppresses its own chrome (transparent border/bg, zero padding) and paints
/// its text/caret invisibly (transparent value style + hidden cursor).
const _kHiddenBufferStyle = CoreTextFieldStyle(
  backgroundColor: .transparent,
  borderColor: .transparent,
  focusBorderColor: .transparent,
  // Hover too: the field's own hover border is `on-surface`, and a
  // zero-width border still paints a hairline — the cells draw the step.
  hoverBorderColor: .transparent,
  borderWidth: 0,
  padding: .zero,
  textAlign: .center,
  // The buffer spans the whole cell row — without this the TextField's
  // own focus ring (border ring + its gap band) draws a full-width ring
  // around the cells on focus (the visual cells carry their own per-cell
  // FocusOutline instead).
  focusOutlineStyle: CoreFocusOutlineStyle(
    borderColor: .transparent,
    borderWidth: 0,
    offsetColor: .transparent,
  ),
  valueStyle: CoreTextStyle(color: .transparent),
  // Selection belongs to the hidden buffer; each visible cell owns its focus.
  selectionColor: .transparent,
);

// ---------------------------------------------------------------------------
// Private constants
// ---------------------------------------------------------------------------
//
// Dimensional chrome defaults (cell size, spacing, separator padding,
// obscured dot size, border radius, border width) live in
// `CoreInputOtpStyle.defaultX` — the single cross-platform source of truth.
//
// Behaviour defaults (`length`, `separatorInterval`) stay flat on the widget
// because they are *behaviour* (count / interval), not chrome — Style
// slot is reserved for visual chrome. Their values live on
// `CoreInputOtpContract` so the Web twin and the Figma builder read the same
// ones.

/// Unified cross-platform OTP input with token-based rendering.
///
/// Renders a row of single-character input cells with automatic
/// focus advancement, backspace navigation, separator support, and
/// platform OTP autofill (iOS `UITextContentType.oneTimeCode`,
/// Android SMS Retriever).
///
/// When the final cell is filled (i.e. [onCompleted] fires), the input
/// automatically releases focus so the soft keyboard is dismissed.
///
/// **Architecture**: A single [TextField] backs the input so that the
/// platform keyboard / autofill flow stays attached to one input
/// connection — switching focus between N separate `TextField`s used
/// to dismiss/recreate the iOS keyboard on every keystroke and broke
/// SMS autofill. The visual N-cell row is rendered on top with
/// [IgnorePointer], reading from the shared controller.
///
/// Resolve priority: widget parameter > CoreInputOtpTheme > defaults.
///
/// Example:
/// ```dart
/// InputOtp(
///   length: 6,
///   onCompleted: (code) => handleVerify(String.fromCharCodes(code.nonNulls)),
/// )
/// ```
///
/// [size] picks the cell box, corner, digit role and dot together —
/// `CoreInputOtpSize.lg` for a screen whose one job is entering the code.
///
/// surface:content — each cell draws its own box (composes
/// `OutlinedContainer` rather than being drawn inside a parent panel),
/// on the page rather than floating over it.
class InputOtp extends StatefulWidget
    implements
        CoreInputOtpContract<OTPCodepointList>,
        CoreInputOtpCellEditingContract {
  /// Creates a [InputOtp].
  const InputOtp({
    super.key,
    this.length = CoreInputOtpContract.defaultLength,
    this.obscured = false,
    this.enabled = true,
    this.autofocus = false,
    this.allowCellEditing = false,
    this.separatorInterval = CoreInputOtpContract.defaultSeparatorInterval,
    this.onChanged,
    this.onCompleted,
    this.initialValue,
    this.errorText,
    this.size = CoreInputOtpSize.defaultSize,
    this.inputOtpStyle,
  });

  @override
  final int length;

  @override
  final bool obscured;

  @override
  final bool enabled;

  @override
  final bool autofocus;

  @override
  final bool allowCellEditing;

  @override
  final int separatorInterval;

  @override
  final ValueChanged<OTPCodepointList>? onChanged;

  @override
  final ValueChanged<OTPCodepointList>? onCompleted;

  @override
  final OTPCodepointList? initialValue;

  @override
  final String? errorText;

  @override
  final CoreInputOtpSize size;

  @override
  final CoreInputOtpStyle? inputOtpStyle;

  /// Returns a copy of this [InputOtp] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  InputOtp copyWith({
    Key? key,
    ValueChanged<OTPCodepointList>? onChanged,
    OTPCodepointList? initialValue,
    int? length,
    bool? obscured,
    bool? enabled,
    bool? autofocus,
    bool? allowCellEditing,
    int? separatorInterval,
    ValueChanged<OTPCodepointList>? onCompleted,
    String? errorText,
    CoreInputOtpSize? size,
    CoreInputOtpStyle? inputOtpStyle,
  }) {
    return InputOtp(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      length: length ?? this.length,
      obscured: obscured ?? this.obscured,
      enabled: enabled ?? this.enabled,
      autofocus: autofocus ?? this.autofocus,
      allowCellEditing: allowCellEditing ?? this.allowCellEditing,
      separatorInterval: separatorInterval ?? this.separatorInterval,
      onCompleted: onCompleted ?? this.onCompleted,
      errorText: errorText ?? this.errorText,
      size: size ?? this.size,
      inputOtpStyle: inputOtpStyle ?? this.inputOtpStyle,
    );
  }

  @override
  State<InputOtp> createState() => _InputOtpState();
}

class _InputOtpState extends State<InputOtp>
    with FormValueSupplier<OTPCodepointList, InputOtp> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late List<int?> _values;
  late List<GlobalKey> _cellKeys;
  Offset? _tapPosition;
  bool _completedDispatched = false;

  /// Whether the pointer is over the control. The control is one hit
  /// target (a single hidden `TextField` spans the whole cell row), so
  /// hover is a fact about the control, not about one cell — the same
  /// granularity as focus and `enabled`.
  bool _hovered = false;

  OTPCodepointList get _currentValue => List<int?>.unmodifiable(_values);

  static bool _listEquals(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _allocateResources();
    formValue = _currentValue;
  }

  void _allocateResources() {
    _cellKeys = List.generate(widget.length, (_) => GlobalKey());
    _values = List.generate(widget.length, (i) {
      final iv = widget.initialValue;
      return iv != null && i < iv.length ? iv[i] : null;
    });
    final initialText = _values
        .takeWhile((v) => v != null)
        .map((v) => String.fromCharCode(v!))
        .join();
    _controller = TextEditingController(text: initialText);
    _controller.addListener(_handleTextChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
    _completedDispatched = initialText.length == widget.length;
  }

  void _disposeResources() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
  }

  void _handleFocusChanged() {
    // Rebuild so the active-cell highlight (focus ring) follows focus.
    if (mounted) setState(() {});
    // Whenever the hidden field gains focus (tap, tab, or programmatic),
    // pin the caret to the end of the entered digits — regardless of
    // which visual cell the tap physically landed on. The invisible
    // buffer's own glyph layout has no relationship to the overlay cell
    // grid, so leaving the platform's default tap-to-caret placement in
    // charge would land the cursor at an arbitrary, meaningless offset.
    // Typing/backspacing naturally keep the caret at the end afterwards
    // (append / trim-from-end), so this one reset is all that's needed.
    if (_focusNode.hasFocus && !widget.allowCellEditing) _moveCursorToEnd();
  }

  /// Forces the hidden buffer's caret to the end of the current text —
  /// Web parity: `target.setSelectionRange(end, end)` in the `focus` /
  /// `click` handlers.
  void _moveCursorToEnd() {
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  /// Re-tap while already focused doesn't re-run [_handleFocusChanged]
  /// (focus didn't change), so `TextField.onTap` covers that case; the
  /// focus listener covers the initial tap-to-focus / tab-focus case.
  void handleTap() {
    if (!widget.allowCellEditing || _tapPosition == null) {
      _moveCursorToEnd();
      return;
    }
    final tap = _tapPosition!;
    _tapPosition = null;
    var nearest = 0;
    var distance = double.infinity;
    for (var i = 0; i < _cellKeys.length; i++) {
      final box = _cellKeys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final candidate = (center.dx - tap.dx).abs();
      if (candidate < distance) {
        distance = candidate;
        nearest = i;
      }
    }
    final length = _controller.text.length;
    _controller.selection = nearest < length
        ? TextSelection(baseOffset: nearest, extentOffset: nearest + 1)
        : TextSelection.collapsed(offset: length);
  }

  void _handleTextChanged() {
    final text = _controller.text;
    final newValues = List.generate(widget.length, (i) {
      if (i >= text.length) return null;
      return text.codeUnitAt(i);
    });

    final changed = !_listEquals(newValues, _values);
    if (changed) {
      setState(() {
        _values = newValues;
      });
      final val = _currentValue;
      widget.onChanged?.call(val);
      formValue = val;

      final isComplete = val.every((cp) => cp != null);
      if (isComplete && !_completedDispatched) {
        _completedDispatched = true;
        // 인증 코드 입력이 완료되면 키보드를 자동으로 내린다 (포커스 해제).
        _focusNode.unfocus();
        widget.onCompleted?.call(val);
      } else if (!isComplete) {
        _completedDispatched = false;
      }
    } else if (mounted) {
      // Selection moved (e.g. cursor only) — repaint so the active-cell
      // highlight tracks the caret.
      setState(() {});
    }
  }

  Widget _buildSeparator(ResolvedInputOtp resolved) {
    // A painted bar, not a glyph — `Container` with the resolver's
    // paint-ready size, colour and corner (Web parity: a `<div>` bar).
    return Padding(
      padding: resolved.separatorPadding,
      child: Container(
        width: resolved.separatorWidth,
        height: resolved.separatorThickness,
        decoration: BoxDecoration(
          color: resolved.separatorColor,
          borderRadius: resolved.separatorBorderRadius,
        ),
      ),
    );
  }

  void _handleHoverChanged(bool hovered) {
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  Widget _buildCell(
    BuildContext context,
    int index,
    double cellSize,
    double cellHeight,
    ResolvedInputOtp resolved,
  ) {
    final isActive = _focusNode.hasFocus && index == _activeIndex;
    final filled = _values[index] != null;
    // `disabled > error > focus > hover > rest`, each in its fill state's
    // look — the resolver baked every arm's chrome (the error rung rides
    // inside every style); this only picks. A disabled control has no
    // hover step, and a control that holds focus keeps its focus chrome
    // instead of stepping, so hover never reaches the cells beside the
    // active one either.
    final hovered = _hovered && widget.enabled && !_focusNode.hasFocus;
    final containerStyle = switch ((isActive, hovered, filled)) {
      (true, _, true) => resolved.focusedFilledCellContainerStyle,
      (true, _, false) => resolved.focusedCellContainerStyle,
      (false, true, true) => resolved.hoveredFilledCellContainerStyle,
      (false, true, false) => resolved.hoveredCellContainerStyle,
      (false, false, true) => resolved.filledCellContainerStyle,
      (false, false, false) => resolved.unfocusedCellContainerStyle,
    };

    return SizedBox(
      width: cellSize,
      height: cellHeight,
      child: Stacks(
        children: [
          Position.fill(
            // Focus-ring colour / width come from `FocusOutline`'s own
            // design-system defaults (`primary` @ `ringOpacity`, `ringWidth`)
            // unless the field is in its error variant, in which case the
            // resolver already folded the `error` token into
            // `resolved.cellFocusOutlineStyle.borderColor` — Web parity:
            // that side forwards the same nested slot to its own
            // `FocusOutline`.
            child: FocusOutline(
              focused: isActive,
              focusOutlineStyle: resolved.cellFocusOutlineStyle,
              // The cell box itself is a composed `OutlinedContainer` —
              // it owns the fill / border / radius AnimatedContainer
              // lerp, geometry conversion, and cast injection (replaces
              // the manual cast-injection helper this resolver used to
              // call), plus the `surface:content` material reach a
              // preset can now apply. `role` is left at its own default
              // (`.content`).
              child: OutlinedContainer(containerStyle: containerStyle),
            ),
          ),
          if (filled)
            Position.fill(
              child: Center(
                child: _buildValueWidget(index, resolved),
              ),
            ),
          // The caret: the active cell is the next empty slot, so it marks
          // where the next character lands. The hidden buffer's own cursor
          // stays off (`showCursor: false`) — this is the one the user sees.
          if (isActive && !filled)
            Position.fill(
              child: Center(
                child: Container(
                  width: resolved.caretWidth,
                  height: resolved.caretHeight,
                  decoration: BoxDecoration(
                    color: resolved.caretColor,
                    borderRadius: resolved.caretBorderRadius,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(
    int index,
    ResolvedInputOtp resolved,
  ) {
    final value = _values[index];
    if (value == null) return const SizedBox();

    if (widget.obscured) {
      return Container(
        decoration: BoxDecoration(
          color: resolved.obscuredDotColor,
          shape: .circle,
        ),
        width: resolved.obscuredDotSize,
        height: resolved.obscuredDotSize,
      );
    }

    return Text(String.fromCharCode(value), style: resolved.valueTextStyle);
  }

  /// Index of the cell that should display the focus ring while the field
  /// has focus. Tracks the current text length (i.e. the next slot to
  /// receive input), but never falls outside `[0, length - 1]`.
  int get _activeIndex {
    final len = _controller.text.length;
    if (widget.allowCellEditing && _controller.selection.isValid) {
      return _controller.selection.start.clamp(0, widget.length - 1);
    }
    if (len >= widget.length) return widget.length - 1;
    return len;
  }

  @override
  void didUpdateWidget(covariant InputOtp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      _disposeResources();
      _allocateResources();
      formValue = _currentValue;
    }
  }

  @override
  void didReplaceFormValue(OTPCodepointList value) {
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  // The digits fill a cell whose size is the step's at every viewport width,
  // so the field states the tier its box was drawn for — the desktop one —
  // rather than let a narrow viewport shrink a headline digit inside an
  // unchanged cell. The Web twin states the same scope around each digit;
  // only the digit's role moves with the tier, so wrapping the whole field
  // (as Avatar does) reaches the same glyphs.
  @override
  Widget build(BuildContext context) => TypographyTierScope(
    tier: .desktop,
    child: Builder(builder: _buildField),
  );

  Widget _buildField(BuildContext context) {
    final resolved = resolveInputOtp(
      context,
      size: widget.size,
      hasError: widget.errorText != null,
      inputOtpStyle: widget.inputOtpStyle,
    );

    // Effective sizing (resolver already applies scaling).
    final effectiveCellSize = resolved.cellSize;
    final effectiveCellHeight = resolved.cellHeight;
    final effectiveHeight = resolved.height;
    final cellSpacing = resolved.cellSpacing;

    // Each visual element (cell or separator) sits at the top level of the
    // `Row` so `Row.spacing` distributes a uniform gap between every
    // sibling — no manual `Gap` interleave required. The separator
    // counts as a visual child and gets the same `cellSpacing` on both
    // sides automatically.
    final cells = <Widget>[];
    for (var i = 0; i < widget.length; i += 1) {
      if (widget.separatorInterval > 0 &&
          i > 0 &&
          i % widget.separatorInterval == 0) {
        cells.add(_buildSeparator(resolved));
      }
      cells.add(
        KeyedSubtree(
          key: _cellKeys[i],
          child: _buildCell(
            context,
            i,
            effectiveCellSize,
            effectiveCellHeight,
            resolved,
          ),
        ),
      );
    }

    // 가용 폭이 셀 합계보다 좁으면(예: 좁은 컨테이너에 인라인 배치) 비율을
    // 줄여 맞춘다. 충분히 넓으면 원본 크기를 유지하고 좌측 정렬한다.
    // 시각 셀만 스케일하므로 키보드/autofill 을 소유한 hiddenInput 은 영향 없음.
    final visualRow = SizedBox(
      height: effectiveHeight,
      child: FittedBox(
        fit: .scaleDown,
        alignment: .centerLeft,
        child: Row(
          mainAxisSize: .min,
          spacing: cellSpacing,
          children: cells,
        ),
      ),
    );

    // Underlying single TextField that owns the keyboard / autofill.
    //
    // Visually invisible (transparent text + cursor + zero decoration), yet
    // still takes pointer events so tapping any cell focuses the field and
    // raises the keyboard. The visual row above is wrapped in
    // [IgnorePointer] so taps fall through to the TextField.
    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final hiddenInput = Data<FormFieldHandle>.boundary(
      child: TextField(
        onTap: handleTap,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        // Visual stealth: chromeless + transparent text + hidden cursor, all
        // via the unified Style slot (the visual cells above render the
        // digits).
        textFieldStyle: _kHiddenBufferStyle,
        maxLength: widget.length,
        autocorrect: false,
        enableSuggestions: false,
        controller: _controller,
        focusNode: _focusNode,
        showCursor: false,
        keyboardType: .number,
        maxLengthEnforcement: .enforced,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9]')),
          LengthLimitingTextInputFormatter(widget.length),
        ],
        // SMS autofill: maps to UITextContentType.oneTimeCode on iOS and
        // SMS Retriever on Android.
        autofillHints: const [AutofillHints.oneTimeCode],
        // The editable's LINE BOX must fill the cell-row height, not sit
        // as a centred ~22px text line: on Flutter web the autofill
        // bridge `<input>` mirrors the EditableText rect, and password
        // managers anchor their inline icon to that rect — the short
        // strip put the 1Password icon in a different spot than the Web
        // twin's full-row-height hidden input. A forced strut stretches
        // the (invisible) line to the row height so both platforms expose
        // an identical hidden-input geometry.
        strutStyle: StrutStyle(
          fontSize: effectiveHeight,
          height: 1,
          forceStrutHeight: true,
        ),
      ),
    );

    // The visual row is the stack's NON-positioned child so the whole
    // component hugs the cell row's width — Web-root `inline-flex
    // w-fit` parity. With both children `Position.fill` the stack
    // expanded to every width the parent offered, and the left-aligned
    // FittedBox pinned the cells to the left of that stretched box
    // (visible as the component sitting left while the Web twin stayed
    // centred at some preview widths).
    final stack = SizedBox(
      height: effectiveHeight,
      child: Stacks(
        children: [
          // Pointer/keyboard owner — the only TextField in the tree,
          // filling exactly the hugged cell-row area.
          Position.fill(
            child: Listener(
              onPointerDown: widget.allowCellEditing
                  ? (event) => _tapPosition = event.position
                  : null,
              child: hiddenInput,
            ),
          ),
          // Visual cells — pointer events fall through to the TextField.
          IgnorePointer(child: visualRow),
        ],
      ),
    );

    // Apply disabled opacity for visual parity with Web.
    final content = widget.enabled
        ? stack
        : Opacity(opacity: CoreOpacity.opacity50, child: stack);

    // Hover is detected on the whole control — the one hit target the
    // hidden `TextField` provides — and the cells read it. The Web twin
    // reads the same fact from `:hover` on its root.
    final hoverContent = MouseRegion(
      onEnter: (_) => _handleHoverChanged(true),
      onExit: (_) => _handleHoverChanged(false),
      child: content,
    );

    // Group semantics — Web parity: `role="group"
    // aria-label="One-time password input"` on the root.
    final semanticContent = Semantics(
      container: true,
      label: CoUILocalizations.of(context).inputOtpLabel,
      child: hoverContent,
    );

    // Error line — Web parity: rendered below the cell row only when
    // `widget.errorText != null`. A composed `ValidatorHint.error` — the
    // `circle-alert` glyph, the `error` accent and the live-region
    // announcement are the hint's, not redrawn here.
    if (widget.errorText == null) return semanticContent;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        semanticContent,
        Padding(
          padding: resolved.errorTextPadding,
          child: ValidatorHint.error(
            message: Text(widget.errorText!),
            validatorHintStyle: resolved.errorValidatorHintStyle,
          ),
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreInputOtpStyle] patch into
/// [InputOtp.inputOtpStyle] without hand-reconstructing every field.
/// Mirrors the Web `InputOtp.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreInputOtpStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreInputOtpStyle.borderRadius] and `.primary` sets
/// [CoreInputOtpStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// InputOtp(length: 6).radius4.primary
/// ```
extension InputOtpStyleChain on InputOtp {
  /// Returns a copy of this [InputOtp] with [patch] merged into
  /// [inputOtpStyle] (patch fields win on conflict).
  InputOtp withStyle(CoreInputOtpStyle patch) => copyWith(
    inputOtpStyle: (inputOtpStyle ?? const CoreInputOtpStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  InputOtp get radius0 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  InputOtp get radius2 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  InputOtp get radius4 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  InputOtp get radius6 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  InputOtp get radius8 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  InputOtp get radius10 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  InputOtp get radius12 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  InputOtp get radius14 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  InputOtp get radius16 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  InputOtp get radius20 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  InputOtp get radius24 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  InputOtp get radius28 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  InputOtp get radius32 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  InputOtp get radius36 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  InputOtp get radius40 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  InputOtp get radius48 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  InputOtp get radius56 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  InputOtp get radius64 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  InputOtp get radius9999 => withStyle(
    const CoreInputOtpStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  InputOtp get primary => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  InputOtp get secondary => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  InputOtp get tertiary => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  InputOtp get surface => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  InputOtp get surfaceContainer => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  InputOtp get error => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  InputOtp get success => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  InputOtp get warning => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  InputOtp get info => withStyle(
    const CoreInputOtpStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  InputOtp get outline => withStyle(
    const CoreInputOtpStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  InputOtp get transparent => withStyle(
    const CoreInputOtpStyle(backgroundColor: .transparent),
  );
}

/// Nullable Unicode code points backing the visual OTP cells.
typedef OTPCodepointList = List<int?>;
