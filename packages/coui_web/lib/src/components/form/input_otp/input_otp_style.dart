import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `InputOtp`.
///
/// Each cell composes `OutlinedContainer`, which marks it as a content
/// surface and publishes its fill — the cells take the material through
/// that primitive, so nothing here restates the marker.
///
/// DOM shape (Flutter parity — a single hidden `<input>` owns the
/// keyboard / autofill connection, the visual cell row is purely
/// decorative and pointer-events-disabled so clicks fall through to the
/// hidden input, exactly mirroring Flutter's `Stack([TextField,
/// IgnorePointer(visualRow)])`):
///
/// ```text
/// root (<div role="group" class="group/input-otp">, position: relative)
///   ├─ <style>                                              // co_input_otp renders only for a raw hover override
///   ├─ hiddenInput (<input>, absolute inset-0, invisible)  // real focus / typing / autofill target
///   └─ visualRow (<div>, pointer-events-none)
///        ├─ cell / cellFocused / cellFocusSibling (<div>)  // repeated `length` times
///        │    └─ value (<span>), obscuredDot (<div>)        // a filled cell: whichever applies
///        │       or caret (<div>)                           // the active empty cell
///        └─ separator (<span>)                              // co_input_otp renders only when separatorInterval > 0
///             └─ separatorBar (<div>)
///   └─ errorText (<div>)                                     // co_input_otp renders only when errorText != null
///        └─ ValidatorHint.error                              // errorValidatorHintStyle
/// ```
///
/// `input_otp.dart` forwards [cellContainerStyle] or
/// [cellFocusedContainerStyle] to `OutlinedContainer` and selects the
/// corresponding composed slot for alignment and group-hover classes.
/// The earlier [cell], [cellFocused] and [cellFocusSibling] outputs stay
/// available to existing resolver consumers.
///
/// Hover belongs to the named group on [root] because the visual row is
/// pointer-transparent. Only [cellComposed] carries the hover hook; focused
/// cells and their siblings keep their own state while focus is held.
/// The focus-ring style is forwarded separately to `FocusOutline`.
class ResolvedInputOtp implements WebResolvedChrome {
  /// Creates a [ResolvedInputOtp].
  const ResolvedInputOtp({
    required this.root,
    required this.hiddenInput,
    required this.visualRow,
    required this.cell,
    required this.cellFocused,
    required this.cellFocusSibling,
    required this.value,
    required this.obscuredDot,
    required this.separator,
    required this.errorText,
    required this.cellFocusOutlineStyle,
    required this.caret,
    required this.separatorBar,
    required this.errorValidatorHintStyle,
    this.cellContainerStyle = const CoreOutlinedContainerStyle(),
    this.cellFocusedContainerStyle = const CoreOutlinedContainerStyle(),
    this.cellFilledContainerStyle = const CoreOutlinedContainerStyle(),
    this.cellFocusedFilledContainerStyle = const CoreOutlinedContainerStyle(),
    this.cellComposed = const WebElementChrome(className: ''),
    this.cellFocusedComposed = const WebElementChrome(className: ''),
    this.cellFocusSiblingComposed = const WebElementChrome(className: ''),
  });

  /// Paint-ready chrome for the outermost `<div role="group">` row —
  /// `relative` (containing block for [hiddenInput]) + composed
  /// `inline-flex` + per-instance gap + disabled-state opacity + the
  /// named hover group `group/input-otp` the cells' hover step reads.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the single hidden `<input>` that owns the
  /// keyboard / autofill connection — absolutely positioned to cover
  /// the whole row, fully transparent (Flutter parity: chromeless +
  /// transparent text + hidden caret).
  final WebElementChrome hiddenInput;

  /// Paint-ready chrome for the decorative visual-cell row wrapper —
  /// `pointer-events-none` so clicks fall through to [hiddenInput].
  final WebElementChrome visualRow;

  /// The pre-composition idle-cell chrome, retained for resolver consumers.
  /// The widget now forwards [cellContainerStyle] to `OutlinedContainer`
  /// and uses [cellComposed] for alignment and hover instead.
  final WebElementChrome cell;

  /// Pre-composition focused-cell chrome, retained for resolver consumers.
  /// The widget uses [cellFocusedContainerStyle] for its focused cell.
  final WebElementChrome cellFocused;

  /// Pre-composition focus-sibling chrome, retained for resolver consumers.
  /// The widget uses [cellFocusSiblingComposed] for this state.
  final WebElementChrome cellFocusSibling;

  /// Paint-ready chrome for the digit text node rendered inside a
  /// filled, non-obscured cell.
  final WebElementChrome value;

  /// Paint-ready chrome for the obscured-value dot rendered inside a
  /// filled, obscured cell in place of the digit.
  final WebElementChrome obscuredDot;

  /// Paint-ready chrome for the caret `<div>` drawn in the active empty
  /// cell — its size and corner inline, its colour a token class (inline
  /// for a raw override).
  final WebElementChrome caret;

  /// Paint-ready chrome for the OTP separator `<span>` — `input_otp.dart`
  /// renders this between cells at `separatorInterval` boundaries (only
  /// when `separatorInterval > 0`). The horizontal padding lives inline.
  final WebElementChrome separator;

  /// Paint-ready chrome for the separator bar `<div>` inside [separator] —
  /// its length, thickness and corner inline, its colour a token class.
  final WebElementChrome separatorBar;

  /// Paint-ready chrome for the wrapper of the error line rendered below
  /// the cell row — the padding above it. `input_otp.dart` renders this
  /// only when `component.errorText != null`.
  final WebElementChrome errorText;

  /// Nested [CoreValidatorHintStyle] slot forwarded raw to the composed
  /// `ValidatorHint.error` inside [errorText] — see
  /// `CoreInputOtpStyle.resolveErrorValidatorHintStyle`.
  final CoreValidatorHintStyle errorValidatorHintStyle;

  /// Nested [CoreFocusOutlineStyle] slot — forwarded to
  /// `FocusOutline(focusOutlineStyle: …)` so the focus ring corner
  /// radius tracks the cell's actual shape (after the merge chain), and
  /// its ring colour switches to the `error` token in the error variant.
  final CoreFocusOutlineStyle cellFocusOutlineStyle;

  /// Style forwarded to the composed container for a resting cell.
  final CoreOutlinedContainerStyle cellContainerStyle;

  /// Style forwarded to the composed container for a focused cell.
  final CoreOutlinedContainerStyle cellFocusedContainerStyle;

  /// Style forwarded to the composed container for a resting cell that
  /// holds a character.
  final CoreOutlinedContainerStyle cellFilledContainerStyle;

  /// Style forwarded to the composed container for the active cell while
  /// it holds a character.
  final CoreOutlinedContainerStyle cellFocusedFilledContainerStyle;

  /// Alignment and hover hooks; the container paints the cell chrome.
  final WebElementChrome cellComposed;

  /// Alignment for the focused container.
  final WebElementChrome cellFocusedComposed;

  /// Alignment for a focus-sibling container.
  final WebElementChrome cellFocusSiblingComposed;
}

/// Scoped CSS text for the `<style>` block in `InputOtp`.
///
/// Non-empty only when the hover border is a RAW colour (no design token,
/// so no Tailwind class can carry it). `input_otp.dart` renders it as a
/// `<style>` child of the root; the default path ships no `<style>` at all.
class ResolvedInputOtpRules {
  /// Creates a [ResolvedInputOtpRules].
  const ResolvedInputOtpRules({required this.css});

  /// The scoped hover rule for the resting cells, or empty.
  final String css;
}

// ═══════════════════════════════════════════════════
// Hover step — one decision, read by the chrome and the rules resolver
// ═══════════════════════════════════════════════════

/// The named Tailwind group on the root that hands the hidden input's
/// `:hover` to the decorative cells (see [ResolvedInputOtp]).
const _kHoverGroup = 'input-otp';

/// Scope id used when the caller names none. The widget always passes its
/// own per-instance id; only a direct resolver call falls back to this.
const _kDefaultScopeId = 'co-input-otp';

/// The class the resting cells carry so a raw-colour hover rule can find
/// them — per instance, since several fields can sit on one page.
String _cellScopeClass(String scopeId) => '$scopeId-cell';

/// Hover border of a resting cell: caller override wins, else the
/// variant's own hover step (the error variant restates `error`, so an
/// invalid control does not soften to `onSurface` under the pointer), else
/// the design-system hover tone. Token → `group-hover/input-otp:border-*`
/// class, raw → scoped rule.
PseudoEmit _emitCellHoverBorder(
  CoreInputOtpStyle merged,
  CoreInputOtpStyle variantStyle,
  String scopeId,
) => emitGroupHoverColor(
  merged.hoverBorderColor,
  variantStyle.hoverBorderColor ?? CoreInputOtpStyle.defaultHoverBorderColor,
  .border,
  group: _kHoverGroup,
  scopeSelector: '.${_cellScopeClass(scopeId)}',
);

/// Resolves [ResolvedInputOtpRules] — the hover rule a raw-colour override
/// cannot carry as a class. Walks the same merge chain as [resolveInputOtp]
/// — the same [size] row at its head — so the class the chrome drops and
/// the rule emitted here are one decision.
ResolvedInputOtpRules resolveInputOtpRules(
  BuildContext context, {
  required bool enabled,
  bool hasError = false,
  String scopeId = _kDefaultScopeId,
  CoreInputOtpSize size = CoreInputOtpSize.defaultSize,
  CoreInputOtpStyle? inputOtpStyle,
}) {
  // A disabled control has no hover step to restate.
  if (!enabled) return const ResolvedInputOtpRules(css: '');

  final csTheme = context.theme.coreComponentTheme?.inputOtp;
  final variant = hasError
      ? CoreInputOtpVariant.error
      : CoreInputOtpVariant.defaultVariant;
  final variantStyle = CoreInputOtpStyle.defaultsByVariant[variant]!;
  final merged = resolveStyleChain(
    CoreInputOtpStyle.chainHeadFor(size, variant),
    [csTheme?.style, csTheme?.variantStyles?[variant], inputOtpStyle],
  );

  return ResolvedInputOtpRules(
    css: _emitCellHoverBorder(merged, variantStyle, scopeId).rule,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedInputOtp] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → CoreInputOtpStyle.defaultsBySize[size]           ┐ chain head
///   → CoreInputOtpStyle.defaultsByVariant[variant]     ┘ (`chainHeadFor`)
///   → theme.coreComponentTheme.inputOtp.style
///   → theme.coreComponentTheme.inputOtp.variantStyles[variant]
///   → widget.inputOtpStyle
/// ```
///
/// The [size] row with the variant row over it is the head of the merge
/// chain, so a theme `style` or the widget's `inputOtpStyle` still wins
/// over both, and `lg`'s own cell colours never erase the error variant's
/// `error` borders (the variant carries no dimension and no text role, so
/// the two rows meet on the border colours alone).
ResolvedInputOtp resolveInputOtp(
  BuildContext context, {
  required bool enabled,
  bool hasError = false,
  String scopeId = _kDefaultScopeId,
  CoreInputOtpSize size = CoreInputOtpSize.defaultSize,
  CoreInputOtpStyle? inputOtpStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.inputOtp;

  // `hasError` is a build-time semantic flag (not an interaction state),
  // so Map dispatch through `defaultsByVariant` is the correct resolver
  // pattern — never a scattered `if (hasError)` per field.
  final variant = hasError
      ? CoreInputOtpVariant.error
      : CoreInputOtpVariant.defaultVariant;
  final variantStyle = CoreInputOtpStyle.defaultsByVariant[variant]!;

  // ─── Merge chain ──────────────────────────────────────
  // The size row with the variant row over it heads the chain — `md` is
  // the empty style, so at the default size every field falls through to
  // the variant's colours and then its `default*` constant.
  final callerLayers = [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    inputOtpStyle,
  ];
  final merged = resolveStyleChain(
    CoreInputOtpStyle.chainHeadFor(size, variant),
    callerLayers,
  );

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly). Every `(merged.X ?? CoreInputOtpStyle.defaultX)` chains
  // the per-instance override — and the size row under it — over the
  // design-system default. Dimensional chrome (cell size / border width /
  // border radius / separator padding) is always emitted inline (single
  // inline signature) on the same path at every size — the cell box takes
  // no density step at `lg` any more than at `md`; colour /
  // typography tokens stay Tailwind classes and drop to inline only when
  // overridden.
  final cellSpacing =
      merged.cellSpacing ?? CoreInputOtpStyle.defaultCellSpacing;
  // Chains the Core default like every sibling in this block. Leaving
  // it un-chained meant the Web root never emitted a height at all, so
  // `CoreInputOtpStyle.defaultHeight` reached Flutter and not Web — the
  // Web row happened to measure the same by content, which is what kept
  // the gap invisible while the shared default was the one thing not
  // being shared.
  final cellSize = merged.cellSize ?? CoreInputOtpStyle.defaultCellSize;
  final cellHeight =
      merged.cellHeight ??
      merged.cellSize ??
      CoreInputOtpStyle.defaultCellHeight;
  // The row is never shorter than its cells — the Flutter resolver takes
  // the same larger of the two, so a tall cell neither overflows the row
  // here nor shrinks under the row's scale-down fit there.
  final height = math.max(
    merged.height ?? CoreInputOtpStyle.defaultHeight,
    cellHeight,
  );
  final borderWidth =
      merged.borderWidth ?? CoreInputOtpStyle.defaultBorderWidth;
  final borderRadius =
      merged.borderRadius ?? CoreInputOtpStyle.defaultBorderRadius;
  final separatorPadding =
      merged.separatorPadding ?? CoreInputOtpStyle.defaultSeparatorPadding;
  final errorTextPadding =
      merged.errorTextPadding ?? CoreInputOtpStyle.defaultErrorTextPadding;
  final obscuredDotSize =
      merged.obscuredDotSize ?? CoreInputOtpStyle.defaultObscuredDotSize;
  // Transition duration — caller override wins, else design-system
  // default. The existing CSS adapter retains token remapping and
  // arbitrary durations on each cell's inline chrome.
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreInputOtpStyle.defaultTransitionDuration)
          .inMilliseconds;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound values
  // (design-system defaults AND token overrides) emit Tailwind classes so
  // they stay dark-mode reactive; raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no `cs.<token>` hardcodes — the
  // design-system defaults route through the Core named statics.
  //
  // Idle colours fold in the variant chrome (`variantStyle.X` — the
  // `error` token when `hasError`) as the effective default *before* the
  // terminal static default, per the resolver-pattern's variant fallback
  // chain.
  final effectiveBackgroundColor =
      merged.backgroundColor ?? CoreInputOtpStyle.defaultBackgroundColor;
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreInputOtpStyle.defaultBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    variantStyle.borderColor ?? CoreInputOtpStyle.defaultBorderColor,
    .border,
  );
  // Focused-cell colours — caller override wins, else variant chrome,
  // else the idle colour. Routed through the same emit family as the idle
  // colours so a token focus override stays dark-mode reactive. The focus
  // background's terminal is the named `defaultFocusBackgroundColor`,
  // which is `defaultBackgroundColor` under its own name: focus is
  // signalled by the border, so the fill follows the idle cell.
  final effectiveBorderColor =
      merged.borderColor ??
      variantStyle.borderColor ??
      CoreInputOtpStyle.defaultBorderColor;
  final effectiveFocusBackgroundColor =
      merged.focusBackgroundColor ??
      merged.backgroundColor ??
      CoreInputOtpStyle.defaultFocusBackgroundColor;
  // A cell that holds a character takes its own pair. The active cell keeps
  // the fill of its state and takes a stated focus edge (caller, else
  // variant chrome), else the neutral `outline` — never `primary`.
  final effectiveFilledBackgroundColor =
      merged.filledBackgroundColor ??
      CoreInputOtpStyle.defaultFilledBackgroundColor;
  final effectiveFilledBorderColor =
      merged.filledBorderColor ??
      variantStyle.filledBorderColor ??
      CoreInputOtpStyle.defaultFilledBorderColor;
  final effectiveFocusBorderColor =
      merged.focusBorderColor ??
      variantStyle.focusBorderColor ??
      CoreInputOtpStyle.defaultFocusBorderColor;
  final focusBackgroundEmit = emitColor(
    merged.focusBackgroundColor ?? merged.backgroundColor,
    CoreInputOtpStyle.defaultFocusBackgroundColor,
    .background,
  );
  final focusBorderEmit = emitColor(
    merged.focusBorderColor ?? variantStyle.focusBorderColor,
    CoreInputOtpStyle.defaultFocusBorderColor,
    .border,
  );
  // Hover step of a resting cell — a disabled control has none, so the
  // chrome states it only when `enabled`. A token rides the
  // `group-hover/input-otp:` class on [cell]; a raw colour has no class, so
  // the cell carries a per-instance scope class and `resolveInputOtpRules`
  // supplies the rule. Either way hover sits on [cell] alone — not on
  // [cellFocused] (focus outranks it) and not on [cellFocusSibling] (a
  // focused control does not step).
  final hoverEmit = enabled
      ? _emitCellHoverBorder(merged, variantStyle, scopeId)
      : (className: '', rule: '');
  final hasHoverRule = hoverEmit.rule.isNotEmpty;

  // Cell value typography — `emitTypography` merges the design-system
  // default (`titleMedium` role + `onSurface` colour) with the merged
  // overlay — the size row's role and any theme / per-instance override
  // above it — emitting a `text-{role}` (+ colour token) class for the role
  // and inline fragments for scalar / raw overlays.
  final valueEmit = emitTypography(
    merged.textStyle,
    CoreInputOtpStyle.defaultTextStyle,
  );
  // Caret — the active empty cell's insertion mark. Colour: caller, else
  // the variant's (`error`), else `primary`.
  final caretEmit = emitColor(
    merged.caretColor,
    variantStyle.caretColor ?? CoreInputOtpStyle.defaultCaretColor,
    .background,
  );
  final caretWidth = merged.caretWidth ?? CoreInputOtpStyle.defaultCaretWidth;
  final caretHeight =
      merged.caretHeight ?? CoreInputOtpStyle.defaultCaretHeight;
  final caretBorderRadius =
      merged.caretBorderRadius ?? CoreInputOtpStyle.defaultCaretBorderRadius;
  // Separator bar.
  final separatorBarEmit = emitColor(
    merged.separatorColor,
    CoreInputOtpStyle.defaultSeparatorColor,
    .background,
  );
  final separatorWidth =
      merged.separatorWidth ?? CoreInputOtpStyle.defaultSeparatorWidth;
  final separatorThickness =
      merged.separatorThickness ?? CoreInputOtpStyle.defaultSeparatorThickness;
  final separatorBorderRadius =
      merged.separatorBorderRadius ??
      CoreInputOtpStyle.defaultSeparatorBorderRadius;
  // Error line — the composed `ValidatorHint.error` resolves its own
  // accent, glyph and message role; one Core helper, shared with Flutter.
  final errorValidatorHintStyle = merged.resolveErrorValidatorHintStyle();
  // Obscured-dot colour — the value-glyph foreground (`onSurface`) via
  // the Core named default (`defaultTextStyle.color`), theme-free
  // `.toValue()` (token → `var(--coui-X)`). Mirrors Flutter's
  // `scheme.resolve(CoreInputOtpStyle.defaultTextStyle.color!).toValue()`.
  final obscuredDotColorValue = CoreInputOtpStyle.defaultTextStyle.color!
      .toValue();

  // Cell focus outline — design-system default radius is the cell's own
  // resolved radius so the ring tracks the cell shape. The ring colour is
  // the focus border a caller or the variant states (theme / widget
  // override → variant chrome, unresolved) rather than a separate
  // `hasError` ternary, so a project overriding the error variant's
  // `focusBorderColor` via `CoreInputOtpTheme.variantStyles` recolours
  // the ring consistently with the cell border instead of leaving it
  // hardcoded to the global `error` token. The size row is left out on
  // purpose: a size states no ring colour, so the ring keeps
  // `FocusOutline`'s default on every size. The surrounding `FocusOutline`
  // widget folds in theme / per-instance overrides through its own merge
  // chain.
  final ringColorStyle = resolveStyleChain(variantStyle, callerLayers);
  final cellFocusOutlineStyle = CoreFocusOutlineStyle(
    borderRadius: borderRadius,
    borderColor: ringColorStyle.focusBorderColor,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the OTP group container Tailwind className. `relative` is
  /// the containing block for the absolutely-positioned hidden input;
  /// `inline-flex w-fit` matches Flutter's
  /// `SizedBox(child: Row(mainAxisSize: MainAxisSize.min))` — the OTP
  /// group shrinks to its content width instead of stretching, while
  /// `max-w-full` clamps it at the parent width (Flutter's "a RenderBox
  /// can never exceed its parent's max-width constraint") so the
  /// down-scale measurer reads the real available width off the group
  /// instead of the group growing past narrow parents. The cell-to-cell
  /// gap rides on the Tailwind `gap-${cellSpacing.tailwindSpace}`
  /// utility (Flutter parity: `Row(spacing: …)`).
  String buildRootClassName() {
    return '${WebLayout.relative} ${WebLayout.inlineFlex} ${WebLayout.wFit} '
        '${WebLayout.maxWFull} ${WebLayout.itemsCenter} '
        'group/$_kHoverGroup gap-${cellSpacing.tailwindSpace}';
  }

  /// Composes the OTP group container inline CSS — carries the
  /// per-instance row height plus the disabled-state opacity (matching
  /// Flutter `Opacity(opacity: 0.5)`). The cell-to-cell gap lives on
  /// the Tailwind class (see [buildRootClassName]).
  Styles buildRootInlineStyles() {
    final raw = <String, String>{'height': '${height / kRemDivisor}rem'};
    if (!enabled) {
      raw['opacity'] = '${CoreOpacity.opacity50}';
    }
    return Styles(raw: raw);
  }

  /// Builds the hidden `<input>` Tailwind classes — invisible
  /// (`opacity-0`), absolutely covers the whole row so a tap/click
  /// anywhere focuses it (Flutter parity: the single `TextField` under
  /// an `IgnorePointer`-wrapped visual row).
  String buildHiddenInputClassName() {
    // CSS sentinel: reset native input padding, not a spacing token.
    return '${WebLayout.absoluteFull} ${WebLayout.wFull} ${WebLayout.hFull} '
        'opacity-0 border-none outline-none bg-transparent p-0 '
        'text-transparent caret-transparent cursor-text '
        'disabled:cursor-not-allowed';
  }

  /// Builds the decorative visual-row wrapper Tailwind classes —
  /// `pointer-events-none` so clicks fall through to the hidden input.
  String buildVisualRowClassName() {
    return '${WebLayout.pointerEventsNone} ${WebLayout.flexItemsCenter} '
        'gap-${cellSpacing.tailwindSpace}';
  }

  /// Builds the shared (state-independent) OTP cell `<div>` Tailwind
  /// classes — layout / typography-role / transition only; background
  /// and border colour are layered on top by [buildCellClassName] /
  /// [buildCellFocusedClassName] since they differ between idle and
  /// active state.
  String buildCellBaseClassName() {
    // The cast rides the cell base, so every cell state carries it.
    return '${WebLayout.flexCenter} border transition-all '
        '$kControlShadowRestMarker';
  }

  /// Builds the shared (state-independent) OTP cell `<div>` inline CSS —
  /// dimensional chrome only (always inline: single inline signature).
  Map<String, String> buildCellBaseInlineStyles() {
    return {
      'transition-duration': durationMsCss(transitionDurationMs),
      'height': '${cellHeight / kRemDivisor}rem',
      'width': '${cellSize / kRemDivisor}rem',
      'border-width': strokeWidthCss(borderWidth),
      // Border radius — `toValue()` emits `var(--coui-radius-N)` for
      // token values, raw px for arbitrary overrides.
      'border-radius': borderRadius.toValue(),
    };
  }

  /// Builds the idle-state OTP cell `<div>` Tailwind classes — shared
  /// base chrome plus the idle background / border colour classes and, for
  /// an enabled control, the hover step (the token class, or the scope
  /// class a raw hover rule targets).
  String buildCellClassName() {
    return <String>[
      buildCellBaseClassName(),
      backgroundEmit.className,
      borderEmit.className,
      hoverEmit.className,
      if (hasHoverRule) _cellScopeClass(scopeId),
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Builds the OTP cell `<div>` Tailwind classes for a cell beside the
  /// active one while the control holds focus — the idle chrome without
  /// its hover step.
  String buildCellFocusSiblingClassName() {
    return <String>[
      buildCellBaseClassName(),
      backgroundEmit.className,
      borderEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Builds the idle-state OTP cell `<div>` inline CSS — shared
  /// dimensional chrome plus idle-colour emit-family fragments (token
  /// values stay on classes and contribute nothing here).
  Styles buildCellInlineStyles() {
    return Styles(
      raw: {
        ...buildCellBaseInlineStyles(),
        ...?backgroundEmit.inline,
        ...?borderEmit.inline,
      },
    );
  }

  /// Builds the active (focused) OTP cell `<div>` Tailwind classes —
  /// shared base chrome plus the focus / error-variant background /
  /// border colour classes.
  String buildCellFocusedClassName() {
    return <String>[
      buildCellBaseClassName(),
      focusBackgroundEmit.className,
      focusBorderEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Builds the active (focused) OTP cell `<div>` inline CSS — shared
  /// dimensional chrome plus focus-colour emit-family fragments.
  Styles buildCellFocusedInlineStyles() {
    return Styles(
      raw: {
        ...buildCellBaseInlineStyles(),
        ...?focusBackgroundEmit.inline,
        ...?focusBorderEmit.inline,
      },
    );
  }

  /// Builds the digit text node Tailwind classes — the value typography
  /// role default flows through the Tailwind class; only a per-instance
  /// override flows inline (see [buildValueInlineStyles]).
  String buildValueClassName() => valueEmit.className;

  /// Builds the digit text node inline CSS — scalar / raw typography
  /// overlays only (the token role + colour stay on the className).
  Styles buildValueInlineStyles() => .new(raw: {...?valueEmit.inline});

  /// Builds the obscured-value dot inline CSS — size + fill colour plus the
  /// circular `border-radius: 50%` that renders the square box as a perfect
  /// circle (structural shape, mirroring Flutter's `BoxShape.circle`). The
  /// size-independent `50%` is the canonical inline CSS circle used across
  /// coui_web (radio_group / stepper / steps), not a `rounded-full` Tailwind
  /// class (RULE F). The fill colour is theme-free `.toValue()`, dark-mode
  /// reactive since the value glyph foreground token is resolved above.
  Styles buildObscuredDotInlineStyles() {
    return Styles(
      raw: {
        'width': '${obscuredDotSize / kRemDivisor}rem',
        'height': '${obscuredDotSize / kRemDivisor}rem',
        'border-radius': '50%',
        'background-color': obscuredDotColorValue,
      },
    );
  }

  /// Builds the caret inline CSS — size and corner (always inline: single
  /// inline signature) plus a raw colour override.
  Styles buildCaretInlineStyles() {
    return Styles(
      raw: {
        'width': '${caretWidth / kRemDivisor}rem',
        'height': '${caretHeight / kRemDivisor}rem',
        'border-radius': caretBorderRadius.toValue(),
        ...?caretEmit.inline,
      },
    );
  }

  /// Builds the OTP separator wrapper Tailwind classes — it centres the
  /// bar; the horizontal padding is inline.
  String buildSeparatorClassName() => WebLayout.flexItemsCenter;

  /// Builds the OTP separator wrapper inline CSS — the horizontal padding
  /// around the bar (always inline: single inline signature).
  Styles buildSeparatorInlineStyles() {
    return Styles(raw: {'padding': separatorPadding.toValue()});
  }

  /// Builds the separator bar inline CSS — length, thickness and corner
  /// plus a raw colour override.
  Styles buildSeparatorBarInlineStyles() {
    return Styles(
      raw: {
        'width': '${separatorWidth / kRemDivisor}rem',
        'height': '${separatorThickness / kRemDivisor}rem',
        'border-radius': separatorBorderRadius.toValue(),
        ...?separatorBarEmit.inline,
      },
    );
  }

  /// Builds the error line wrapper inline CSS — the full 4-side padding
  /// above the composed hint (always inline; per the "Web 4-side adapter
  /// enforced" rule, a single-axis extraction like `padding-top` would
  /// silently drop a left/right/bottom override).
  Styles buildErrorTextInlineStyles() {
    return Styles(raw: {'padding': errorTextPadding.toValue()});
  }

  /// The composed container's style for one (fill state × focus) arm —
  /// the colours differ, the box does not.
  CoreOutlinedContainerStyle cellStyle(CoreColor fill, CoreColor border) =>
      CoreOutlinedContainerStyle(
        backgroundColor: fill,
        borderColor: border,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        preserveTransparentBorder: true,
        width: cellSize,
        height: cellHeight,
        // OTP retains its transition-all timing on its own cell chrome.
        duration: Duration.zero,
      );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedInputOtp(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    hiddenInput: WebElementChrome(className: buildHiddenInputClassName()),
    visualRow: WebElementChrome(className: buildVisualRowClassName()),
    cell: WebElementChrome(
      className: buildCellClassName(),
      inlineStyles: buildCellInlineStyles(),
    ),
    cellFocused: WebElementChrome(
      className: buildCellFocusedClassName(),
      inlineStyles: buildCellFocusedInlineStyles(),
    ),
    cellFocusSibling: WebElementChrome(
      className: buildCellFocusSiblingClassName(),
      inlineStyles: buildCellInlineStyles(),
    ),
    value: WebElementChrome(
      className: buildValueClassName(),
      inlineStyles: buildValueInlineStyles(),
    ),
    obscuredDot: WebElementChrome(
      className: '',
      inlineStyles: buildObscuredDotInlineStyles(),
    ),
    caret: WebElementChrome(
      className: caretEmit.className,
      inlineStyles: buildCaretInlineStyles(),
    ),
    separator: WebElementChrome(
      className: buildSeparatorClassName(),
      inlineStyles: buildSeparatorInlineStyles(),
    ),
    separatorBar: WebElementChrome(
      className: separatorBarEmit.className,
      inlineStyles: buildSeparatorBarInlineStyles(),
    ),
    errorText: WebElementChrome(
      className: '',
      inlineStyles: buildErrorTextInlineStyles(),
    ),
    errorValidatorHintStyle: errorValidatorHintStyle,
    cellFocusOutlineStyle: cellFocusOutlineStyle,
    cellContainerStyle: cellStyle(
      effectiveBackgroundColor,
      effectiveBorderColor,
    ),
    cellFocusedContainerStyle: cellStyle(
      effectiveFocusBackgroundColor,
      effectiveFocusBorderColor,
    ),
    cellFilledContainerStyle: cellStyle(
      effectiveFilledBackgroundColor,
      effectiveFilledBorderColor,
    ),
    cellFocusedFilledContainerStyle: cellStyle(
      merged.focusBackgroundColor ?? effectiveFilledBackgroundColor,
      effectiveFocusBorderColor,
    ),
    cellComposed: WebElementChrome(
      className: <String>[
        WebLayout.flexCenter,
        'transition-all',
        hoverEmit.className,
        if (hasHoverRule) _cellScopeClass(scopeId),
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {'transition-duration': durationMsCss(transitionDurationMs)},
      ),
    ),
    cellFocusedComposed: WebElementChrome(
      className: '${WebLayout.flexCenter} transition-all',
      inlineStyles: Styles(
        raw: {'transition-duration': durationMsCss(transitionDurationMs)},
      ),
    ),
    cellFocusSiblingComposed: WebElementChrome(
      className: '${WebLayout.flexCenter} transition-all',
      inlineStyles: Styles(
        raw: {'transition-duration': durationMsCss(transitionDurationMs)},
      ),
    ),
  );
}
