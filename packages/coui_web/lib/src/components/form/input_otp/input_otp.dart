import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/typography_tier_scope.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/input_otp/input_otp_scale_measurer.dart';
import 'package:coui_web/src/components/form/input_otp/input_otp_style.dart';
import 'package:coui_web/src/components/form/validator_hint/validator_hint.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

// ---------------------------------------------------------------------------
// Private constants
// ---------------------------------------------------------------------------
//
// Behaviour defaults (`length`, `separatorInterval`) stay flat on the
// widget because they are *behaviour* (count / interval), not chrome —
// `CoreInputOtpStyle` is reserved for visual chrome. Their values live on
// `CoreInputOtpContract` so the Flutter twin and the Figma builder read the
// same ones.

/// Matches every non-digit character — the single client-side input
/// policy, mirroring Flutter's
/// `FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))`.
final _kNonDigit = RegExp('[^0-9]');

/// Unified cross-platform OTP input for CoUI Web.
///
/// **Architecture (Flutter parity)**: a single hidden `<input>` backs the
/// whole row so the platform keyboard / autofill / WebOTP connection
/// stays attached to one input element — switching real DOM focus
/// between `length` separate `<input>`s made SMS autofill unreliable
/// (most browsers' OTP autofill / suggestion UI targets exactly one text
/// field) and doubled as an accessibility anti-pattern (tabbing through
/// `length` single-character fields). The visual N-cell row is rendered
/// on top as plain decorative `<div>`s, `pointer-events-none` so clicks
/// fall through to the hidden input — the direct Web analogue of
/// Flutter's `Stack([TextField, IgnorePointer(visualRow)])`.
///
/// Renders a row of single-character cells with automatic focus
/// advancement (native browser text editing on the single hidden field —
/// no custom keydown/paste interception needed, matching Flutter, which
/// has none either), separator support, and WebOTP-based SMS autofill
/// (`requestWebOtp`) where the browser implements it — a pure
/// progressive enhancement that degrades to manual typing / paste
/// elsewhere.
///
/// When the final cell is filled (i.e. [onCompleted] fires), the input
/// automatically releases focus so the mobile keyboard is dismissed.
///
/// [size] picks the [CoreInputOtpStyle.defaultsBySize] rung — the cell box,
/// its corner, the digit / separator role and the obscured dot.
/// Chrome / dimensional overrides flow through the single
/// [inputOtpStyle] slot ([CoreInputOtpStyle]); [resolveInputOtp]
/// (in `input_otp_style.dart`) is the single entry point that merges
/// the size row, `CoreInputOtpTheme.style` and the per-instance style.
///
/// Internally a [StatefulComponent] so the wrapper can track the current
/// value + which cell is the active (focused) one, forwarding the active
/// cell to [FocusOutline] — the same model the Flutter implementation
/// uses (`_focusNode.hasFocus` + `_activeIndex`).
///
/// Example:
/// ```dart
/// InputOtp(
///   length: 6,
///   onCompleted: (value) => print('OTP: $value'),
/// )
/// ```
class InputOtp extends UiStatefulComponent
    implements CoreInputOtpContract<String>, CoreInputOtpCellEditingContract {
  /// Creates a [InputOtp].
  const InputOtp({
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
    this.enabled = true,
    this.autofocus = false,
    this.allowCellEditing = false,
    this.length = CoreInputOtpContract.defaultLength,
    this.obscured = false,
    this.onChanged,
    this.onCompleted,
    this.separatorInterval = CoreInputOtpContract.defaultSeparatorInterval,
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
  final CoreValueChanged<String>? onChanged;

  @override
  final CoreValueChanged<String>? onCompleted;

  @override
  final String? initialValue;

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
    UiMouseEventHandler? onClick,
    CoreValueChanged<String>? onChanged,
    String? initialValue,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    bool? enabled,
    bool? autofocus,
    bool? allowCellEditing,
    int? length,
    bool? obscured,
    CoreValueChanged<String>? onCompleted,
    int? separatorInterval,
    String? errorText,
    CoreInputOtpSize? size,
    CoreInputOtpStyle? inputOtpStyle,
  }) {
    return InputOtp(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
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
      enabled: enabled ?? this.enabled,
      autofocus: autofocus ?? this.autofocus,
      allowCellEditing: allowCellEditing ?? this.allowCellEditing,
      length: length ?? this.length,
      obscured: obscured ?? this.obscured,
      onCompleted: onCompleted ?? this.onCompleted,
      separatorInterval: separatorInterval ?? this.separatorInterval,
      errorText: errorText ?? this.errorText,
      size: size ?? this.size,
      inputOtpStyle: inputOtpStyle ?? this.inputOtpStyle,
    );
  }

  @override
  State<InputOtp> createState() => _InputOtpState();
}

/// Chain sugar mirroring the Flutter `InputOtp.withStyle` extension —
/// merges a [CoreInputOtpStyle] patch into [InputOtp.inputOtpStyle] via
/// the existing [InputOtp.copyWith].
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

/// Monotonic id source for the per-instance hidden `<input>` element id.
int _coInputOtpIdCounter = 0;

class _InputOtpState extends State<InputOtp>
    with FormValueSupplier<String, InputOtp> {
  /// Stable element id for the hidden `<input>` — used by [setInputValue]
  /// to write a programmatically-obtained value (WebOTP autofill) into
  /// the real DOM node so a subsequent manual edit continues from it
  /// instead of stale DOM state.
  late final String _inputId = 'co-input-otp-${_coInputOtpIdCounter++}-input';

  /// Stable element id for the visual cell row — the down-scale
  /// measurer's transform target (Flutter `FittedBox(scaleDown)` mirror).
  late final String _rowId = '$_inputId-row';

  /// Fits the visual row into narrow containers by scaling it down
  /// proportionally — the web twin of Flutter's `FittedBox(fit:
  /// scaleDown, alignment: centerLeft)`. No-op during SSR (stub).
  InputOtpScaleMeasurer? _scaleMeasurer;

  /// Current OTP buffer — single source of truth for rendering the
  /// visual cells (Flutter parity: `_values`). Mirrors the hidden
  /// input's real DOM `value`.
  late String _value;

  /// Value supplied to the hidden input by the virtual DOM. Keep this in
  /// sync with [_value]: a rerender must not restore the initial value after
  /// the user edits the field. The input handler restores the native selection
  /// after a value patch so middle-cell editing keeps its caret.
  String? _domInitialValue;

  /// Whether the hidden input currently has keyboard focus — drives the
  /// active-cell `FocusOutline` + cell/cellFocused chrome choice.
  bool _focused = false;
  int? _selectionStart;

  /// Whether the OTP has reached its full length since it was last
  /// incomplete. Gates the one-shot focus release on completion so that
  /// editing an already-complete code does not keep dismissing the
  /// keyboard.
  bool _completedDispatched = false;

  /// Aborts a pending WebOTP request — called once the value is
  /// otherwise filled and from [dispose], so a stale callback never
  /// lands on an unmounted / already-complete widget.
  void Function()? _abortWebOtp;

  /// Index of the cell that should display the focus ring while the
  /// hidden input has focus. Tracks the current value length (i.e. the
  /// next slot to receive input), but never falls outside
  /// `[0, length - 1]` — mirrors Flutter's `_activeIndex` getter.
  int get _activeIndex {
    final len = _value.length;
    if (component.allowCellEditing && _selectionStart != null) {
      return _selectionStart!.clamp(0, component.length - 1);
    }
    if (len >= component.length) return component.length - 1;
    return len;
  }

  @override
  void initState() {
    super.initState();
    final seed = component.initialValue ?? '';
    // Bound to `length` up front — mirrors Flutter's `_allocateResources`
    // (`List.generate(widget.length, ...)`), which only ever reads
    // `iv[index]` for `index < widget.length`. Without this, a caller
    // passing an over-long `initialValue` would leave `_value` (and the
    // hidden `<input>`'s seeded DOM value below) permanently longer than
    // the visible cell count, silently blocking further typed edits
    // until enough backspaces drop the total back under `length`.
    _value = seed.length > component.length
        ? seed.substring(0, component.length)
        : seed;
    _domInitialValue = _value.isEmpty ? null : _value;
    _completedDispatched = _value.length == component.length;
    formValue = _value;
    // Progressive enhancement — a browser without WebOTP support (or a
    // user who declines the SMS permission prompt) just falls back to
    // manual entry / paste. Skipped when the field starts disabled or
    // already complete: there is nothing useful for WebOTP to fill in
    // either case, and requesting anyway would hold a live
    // `navigator.credentials.get()` listener for the widget's entire
    // mount lifetime with no path to ever abort it (the one-shot abort
    // in `_commitValue` only fires on the false→true completion edge).
    _abortWebOtp = component.enabled && !_completedDispatched
        ? requestWebOtp(_handleWebOtpCode)
        : null;
  }

  /// Attaches the row down-scale measurer once the row is in the DOM.
  /// Idempotent — `attach` no-ops after the first successful resolve.
  void _ensureScaleMeasurer() {
    if (!kIsWeb) return;
    (_scaleMeasurer ??= InputOtpScaleMeasurer(rowId: _rowId)).attach();
  }

  String _filterDigits(String raw) {
    final digits = raw.replaceAll(_kNonDigit, '');
    return digits.length > component.length
        ? digits.substring(0, component.length)
        : digits;
  }

  void _handleWebOtpCode(String code) {
    // `component.enabled` is re-checked here (not just at request time
    // in `initState`) since a disabled field should never accept a
    // value through any path — typed, pasted, or autofilled.
    if (!mounted || !component.enabled) return;
    final filtered = _filterDigits(code);
    if (filtered.isEmpty || filtered == _value) return;
    setInputValue(_inputId, filtered);
    _commitValue(filtered);
  }

  /// Applies [next] as the new OTP value — updates Dart state, fires
  /// [InputOtp.onChanged] / [InputOtp.onCompleted], and releases focus on
  /// first completion. Single funnel for every value-changing path
  /// (typing, native paste, WebOTP autofill) so the completion / focus-
  /// release logic lives in exactly one place. Callers own writing the
  /// value into the real DOM `<input>` themselves (the native `input`
  /// handler already has `target`; the WebOTP callback uses
  /// [setInputValue]).
  void _commitValue(String next) {
    if (next == _value) return;
    setState(() {
      _value = next;
      _domInitialValue = next;
    });
    formValue = next;
    component.onChanged?.call(next);

    final isComplete = next.length == component.length;
    // `onCompleted` fires only on the false→true completion edge — Web
    // parity with Flutter's `_handleTextChanged`
    // (`if (isComplete && !_completedDispatched)`). Firing it whenever
    // `next` merely *stays* at full length (e.g. the user edits the
    // last digit of an already-complete code) would re-invoke a
    // caller's verify-code submission for every such edit.
    if (isComplete && !_completedDispatched) {
      _completedDispatched = true;
      _abortWebOtp?.call();
      _releaseFocusAfterCompletion();
      component.onCompleted?.call(next);
    } else if (!isComplete) {
      _completedDispatched = false;
    }
  }

  Map<String, EventCallback> _buildHiddenInputEvents() {
    return {
      // Single funnel for typing *and* paste — pasting into a real
      // `<input>` fires a native `input` event afterwards, so no
      // separate `paste` handler is needed (unlike the old per-cell
      // architecture, which had to distribute pasted text manually).
      //
      // Typed `web.Event` signature: dart2js release minifies dynamic
      // getter dispatches into mangled names (e.g. `event.target` →
      // `event.gdE`) that compile-graph changes can desync, leaving
      // the ring stuck in its unfocused state in production. Static
      // typing via `EventHandlers` keeps the call site
      // mangling-resilient.
      'input': EventHandlers.createInputTargetEventHandler((_, target) {
        final filtered = _filterDigits(target.value);
        final selectionStart = target.selectionStart;
        final selectionEnd = target.selectionEnd;
        if (filtered != target.value) target.value = filtered;
        _commitValue(filtered);
        if (target.value != filtered) target.value = filtered;
        if (selectionStart != null && selectionEnd != null) {
          try {
            target.setSelectionRange(
              selectionStart.clamp(0, filtered.length),
              selectionEnd.clamp(0, filtered.length),
            );
          } on Object {
            // The value remains usable on platforms without selection APIs.
          }
        }
        if (component.allowCellEditing) _trackSelection(target);
      }),
      // Mirror W3C `:focus-visible`: ring on iff focus arrived via
      // keyboard (browsers also treat a mouse/touch focus on a text
      // input as focus-visible, matching Flutter's unconditional
      // `_focusNode.hasFocus`).
      'focus': EventHandlers.createInputTargetEventHandler((_, target) {
        final isVisible = target.matches(':focus-visible');
        setState(() => _focused = isVisible);
        _moveCaretToEnd(target);
        if (component.allowCellEditing) _trackSelection(target);
      }),
      'blur': (_) => setState(() => _focused = false),
      // Re-click while already focused doesn't re-fire `focus` (focus
      // didn't change), so this covers that case; the `focus` handler
      // above covers the initial tap-to-focus / tab-focus case.
      'click': component.allowCellEditing
          ? EventHandlers.createMouseEventHandler((event) {
              final target = event.target as web.HTMLInputElement?;
              if (target == null) return;
              if (event.detail > 0) {
                _selectCell(event, target);
              } else {
                _moveCaretToEnd(target);
              }
              _trackSelection(target);
            })
          : EventHandlers.createInputTargetEventHandler(
              (_, target) => _moveCaretToEnd(target),
            ),
      if (component.allowCellEditing) ...{
        'keyup': EventHandlers.createInputTargetEventHandler(
          (_, target) => _trackSelection(target),
        ),
        'select': EventHandlers.createInputTargetEventHandler(
          (_, target) => _trackSelection(target),
        ),
      },
    };
  }

  void _trackSelection(web.HTMLInputElement target) {
    final next = target.selectionStart ?? target.value.length;
    if (_selectionStart != next) setState(() => _selectionStart = next);
  }

  void _selectCell(web.MouseEvent event, web.HTMLInputElement target) {
    final row = web.document.getElementById(_rowId);
    final cells = row?.querySelectorAll('[data-otp-cell]');
    if (cells == null || cells.length == 0) {
      _moveCaretToEnd(target);
      return;
    }
    var nearest = 0;
    var distance = double.infinity;
    for (var i = 0; i < cells.length; i++) {
      final cell = cells.item(i)! as web.Element;
      final rect = cell.getBoundingClientRect();
      final candidate = (rect.left + rect.width / 2 - event.clientX).abs();
      if (candidate < distance) {
        distance = candidate;
        nearest = i;
      }
    }
    final length = target.value.length;
    final start = nearest.clamp(0, length);
    try {
      target.setSelectionRange(start, start < length ? start + 1 : start);
    } on Object {
      _moveCaretToEnd(target);
    }
  }

  /// Forces the hidden buffer's caret to the end of the current text —
  /// regardless of which visual cell the click physically landed on.
  /// The invisible buffer's own glyph layout has no relationship to the
  /// overlay cell grid, so the browser's default click-to-caret
  /// placement would land the cursor at an arbitrary, meaningless
  /// offset. Typing/backspacing naturally keep the caret at the end
  /// afterwards (append / trim-from-end), so this one reset per
  /// click/focus is all that's needed. Flutter parity:
  /// `_controller.selection = TextSelection.collapsed(offset: …)` in
  /// `onTap` / the focus listener.
  void _moveCaretToEnd(web.HTMLInputElement target) {
    final end = target.value.length;
    try {
      target.setSelectionRange(end, end);
    } on Object catch (_) {
      // setSelectionRange may not be supported on all browsers — ignore.
    }
  }

  /// 인증 코드 입력이 완료되면 포커스를 해제해 모바일 키보드를 내린다.
  void _releaseFocusAfterCompletion() {
    blurActiveElement();
  }

  Component _buildSeparator(ResolvedInputOtp resolved) {
    // A painted bar, not a glyph (Flutter parity: a `Container` bar).
    return span(
      [
        div(
          const [],
          classes: resolved.separatorBar.className,
          styles: resolved.separatorBar.inlineStyles,
        ),
      ],
      classes: resolved.separator.className,
      styles: resolved.separator.inlineStyles,
      attributes: const {'aria-hidden': 'true'},
    );
  }

  Component _buildCell(int index, ResolvedInputOtp resolved) {
    final isActive = _focused && index == _activeIndex;
    // `disabled > error > focus > hover > rest` — the active cell takes its
    // focus chrome, and every other cell of a focused control takes the
    // resting chrome WITHOUT the hover step. Only a control nobody has
    // focused gives its cells the hover-reactive chrome; the pointer
    // itself is read by CSS (`:hover` on the root group), not here.
    final chrome = isActive
        ? resolved.cellFocusedComposed
        : _focused
        ? resolved.cellFocusSiblingComposed
        : resolved.cellComposed;
    final filled = index < _value.length;
    // The cell's look follows its fill state; the active cell keeps it
    // (focus is the caret and the ring).
    final containerStyle = switch ((isActive, filled)) {
      (true, true) => resolved.cellFocusedFilledContainerStyle,
      (true, false) => resolved.cellFocusedContainerStyle,
      (false, true) => resolved.cellFilledContainerStyle,
      (false, false) => resolved.cellContainerStyle,
    };

    return FocusOutline(
      focused: isActive,
      focusOutlineStyle: resolved.cellFocusOutlineStyle,
      child: OutlinedContainer(
        containerStyle: containerStyle,
        classes: chrome.className,
        css: chrome.inlineStyles,
        attributes: {
          'aria-hidden': 'true',
          if (component.allowCellEditing) 'data-otp-cell': '$index',
        },
        child: filled
            ? _buildValue(index, resolved)
            // The caret marks the active empty cell — where the next
            // character lands. The hidden input's own caret stays
            // transparent; this is the one the user sees.
            : isActive
            ? div(
                const [],
                classes: resolved.caret.className,
                styles: resolved.caret.inlineStyles,
              )
            : null,
      ),
    );
  }

  Component _buildValue(int index, ResolvedInputOtp resolved) {
    if (component.obscured) {
      return div(
        const [],
        classes: resolved.obscuredDot.className,
        styles: resolved.obscuredDot.inlineStyles,
      );
    }
    // The digit fills a cell whose size is the step's at every viewport
    // width, so it states the tier its box was drawn for (Flutter parity).
    // The scope is a box-less wrapper inside the cell, around the digit
    // alone, so no sibling selector on the row sees it.
    return TypographyTierScope(
      tier: .desktop,
      child: span(
        [Text(_value[index])],
        classes: resolved.value.className,
        styles: resolved.value.inlineStyles,
      ),
    );
  }

  @override
  void didReplaceFormValue(String value) {
    // The hidden `<input>` is uncontrolled (DOM holds the typed code), so
    // an async validator's normalised value is forwarded to the caller
    // via [onChanged] rather than written back into the field.
    component.onChanged?.call(value);
  }

  @override
  void dispose() {
    _scaleMeasurer?.dispose();
    _scaleMeasurer = null;
    _abortWebOtp?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveInputOtp(
      context,
      enabled: component.enabled,
      hasError: component.errorText != null,
      scopeId: _inputId,
      size: component.size,
      inputOtpStyle: component.inputOtpStyle,
    );
    final rules = resolveInputOtpRules(
      context,
      enabled: component.enabled,
      hasError: component.errorText != null,
      scopeId: _inputId,
      size: component.size,
      inputOtpStyle: component.inputOtpStyle,
    );

    final cells = <Component>[];
    for (var i = 0; i < component.length; i += 1) {
      if (component.separatorInterval > 0 &&
          i > 0 &&
          i % component.separatorInterval == 0) {
        cells.add(_buildSeparator(resolved));
      }
      cells.add(_buildCell(i, resolved));
    }

    final visualRow = div(
      cells,
      id: _rowId,
      classes: resolved.visualRow.className,
      styles: resolved.visualRow.inlineStyles,
    );
    if (kIsWeb) {
      scheduleMicrotask(() {
        if (mounted) _ensureScaleMeasurer();
      });
    }

    // Real focus / typing / autofill owner — the only `<input>` in the
    // tree. Fully invisible (opacity 0), absolutely positioned to cover
    // the whole row so a tap/click anywhere focuses it natively; no
    // click handler needed. `type="text"` (not `password`) even when
    // `obscured` — the field itself is always invisible, so a password
    // type would only risk triggering unrelated browser
    // password-manager heuristics on an invisible node.
    //
    // Keep the attribute current as Jaspr can reapply it on rerender. The
    // input handler preserves the selection when that update changes it.
    final hiddenInput = Component.element(
      tag: 'input',
      id: _inputId,
      classes: resolved.hiddenInput.className,
      styles: resolved.hiddenInput.inlineStyles,
      attributes: {
        'type': 'text',
        'inputmode': 'numeric',
        'pattern': '[0-9]*',
        'maxlength': '${component.length}',
        // SMS autofill: the browser's OTP suggestion UI / WebOTP API
        // both key off this attribute.
        'autocomplete': 'one-time-code',
        'aria-label': CouiLocalizations.of(context).inputOtpLabel,
        'value': ?_domInitialValue,
        if (component.autofocus) 'autofocus': '',
        if (!component.enabled) 'disabled': '',
      },
      events: component.enabled ? _buildHiddenInputEvents() : const {},
    );

    final group = div(
      [
        // `<style>` is `display: none`, so it creates no flex item and never
        // picks up the row gap. Present only for a raw-colour hover
        // override; the default path's markup is unchanged.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        hiddenInput,
        visualRow,
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': 'group',
        'aria-label': CouiLocalizations.of(context).inputOtpLabel,
      },
      events: component.events,
    );

    // Error line — rendered below the cell row only when
    // `component.errorText != null` (Flutter parity). Plain block-level
    // `<div>`s already stack vertically, so no extra layout wrapper class is
    // needed.
    if (component.errorText == null) return group;
    return div([
      group,
      div(
        [
          // A composed `ValidatorHint.error` — the `circle-alert` glyph, the
          // `error` accent and the announcement role are the hint's.
          ValidatorHint.error(
            message: Text(component.errorText!),
            validatorHintStyle: resolved.errorValidatorHintStyle,
          ),
        ],
        classes: resolved.errorText.className,
        styles: resolved.errorText.inlineStyles,
      ),
    ]);
  }
}
