import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/dashed_overlay.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// ResolvedFileInput
// ═══════════════════════════════════════════════════

/// Resolver output for Web `FileInput`.
///
/// DOM shape:
///
/// ```text
/// Clickable (role="button", clickableStyle)  // owns tap / keyboard / cursor / focus ring
///   └─ root (<div>)                          // drop-zone visual box
///        ├─ hiddenInput (<input type="file">)  // sr-only native picker
///        ├─ iconBox (<div>)                    // circular box
///        │    └─ uploadIcon (<svg>)            // upload glyph
///        ├─ contentGroup (<div>)               // text block → buttons
///        │    ├─ textBlock (<div>)             // title → hint
///        │    │    ├─ labelText (<span>)       // primary label
///        │    │    └─ hintText (<span>)        // optional hint
///        │    └─ buttonsRow (<div>)            // browse (+ optional folder)
///        └─ selectedFiles (<div>)              // optional selected list
///             └─ fileItem (<div>)              // per-file row
///                  ├─ fileIcon (<svg>)         // file glyph
///                  ├─ fileName (<span>)        // file name
///                  └─ save Button (plain)*     // when allowSave + data
/// ```
///
/// Single struct that the widget reads — the nested-merge chain
/// (`theme.fileInput.style` → `widget.fileInputStyle`) applied once. The
/// `enabled` flag travels with the resolver so every state-dependent
/// element slot (drop-zone borders, content tint, hover border) ships
/// pre-composed.
class ResolvedFileInput implements WebResolvedChrome {
  /// Creates a [ResolvedFileInput].
  const ResolvedFileInput({
    required this.root,
    required this.dashOverlay,
    required this.dashRect,
    required this.hiddenInput,
    required this.iconBox,
    required this.contentGroup,
    required this.textBlock,
    required this.labelText,
    required this.buttonsRow,
    required this.hintText,
    required this.selectedFiles,
    required this.fileItem,
    required this.fileIcon,
    required this.fileName,
    required this.saveButtonStyle,
    required this.iconStyle,
    required this.fileIconStyle,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the drop-zone visual box `<div>` nested
  /// inside the composing `Clickable` — composed Tailwind className
  /// (`coui-file-input flex flex-col items-center justify-center` +
  /// the default preset spacing / radius / dashed border classes plus
  /// the state-dependent border / background / hover-border classes for
  /// the current `enabled` / `isDragOver` combination — cursor and focus
  /// ring are owned by the `Clickable`) and inline-CSS bundle carrying
  /// the per-instance border-width / radius / padding / item-spacing /
  /// background-colour / border-colour overrides.
  @override
  final WebElementChrome root;

  /// Dashed-border `<svg>` overlay — absolutely fills the drop zone and
  /// strokes with `currentColor` so the root's state / hover text-colour
  /// classes recolour the dashes (deterministic across browsers, unlike
  /// CSS `border-dashed`).
  final WebElementChrome dashOverlay;

  /// The overlay's `<rect>` — geometry (half-stroke inset), stroke
  /// width, dash pattern (none while a file is dragged over the zone — the
  /// edge turns solid) and corner radius, all as CSS properties.
  final WebElementChrome dashRect;

  /// Paint-ready chrome for the hidden native `<input type="file">` —
  /// `sr-only` className keeps the picker accessible to keyboard /
  /// screen-readers but visually hidden. No inline CSS.
  final WebElementChrome hiddenInput;

  /// Paint-ready chrome for the circular icon box `<div>` — fixed size,
  /// fill colour (the drag-over tone while a file is dragged over an
  /// enabled zone), corner radius, flex centring. Hosts the upload glyph.
  final WebElementChrome iconBox;

  /// Paint-ready chrome for the `<div>` that stacks the text block and the
  /// button row — flex column, centred, the resolved `actionSpacing` as its
  /// `gap` (Flutter twin: the inner `Column(spacing: actionSpacing)`).
  final WebElementChrome contentGroup;

  /// Paint-ready chrome for the `<div>` that stacks the label and the hint
  /// — flex column, centred, the resolved `textSpacing` as its `gap`.
  final WebElementChrome textBlock;

  /// Paint-ready chrome for the primary label `<span>` — composed
  /// Tailwind className (`text-{bodySmall}` + content colour) plus the
  /// optional [CoreTextStyle] override inline CSS bundle.
  final WebElementChrome labelText;

  /// Paint-ready chrome for the button row `<div>` that holds the browse
  /// button (and the folder button when `allowDirectory` is on) — flex
  /// row, centred, with the resolved `itemSpacing` as its `gap`, matching
  /// the Flutter twin's `Row(spacing: resolved.itemSpacing)`.
  final WebElementChrome buttonsRow;

  /// Paint-ready chrome for the optional hint `<span>` — composed
  /// Tailwind className (`text-{labelMedium}` + dimmed content colour)
  /// plus the optional [CoreTextStyle] override inline CSS bundle.
  final WebElementChrome hintText;

  /// Paint-ready chrome for the optional selected-files `<div>` list
  /// container — `flex flex-col items-center` layout className.
  final WebElementChrome selectedFiles;

  /// Paint-ready chrome for each selected-file row `<div>` —
  /// composed Tailwind className (`flex items-center`) plus inline CSS
  /// carrying the resolved `fileItemSpacing` as both `gap` and
  /// `margin-bottom`.
  final WebElementChrome fileItem;

  /// Paint-ready chrome for the per-file `<svg>` icon — composed
  /// Tailwind colour class (dimmed on-surface-variant) so the SVG's
  /// `currentColor` is tinted via color-level alpha.
  final WebElementChrome fileIcon;

  /// Paint-ready chrome for the per-file `<span>` name — composed
  /// Tailwind className (`text-{labelMedium}` + dimmed content
  /// colour + `truncate`).
  final WebElementChrome fileName;

  /// Nested [CoreButtonStyle] slot for the per-file save affordance's
  /// composed `Button` — `CoreFileInputStyle.defaultSaveButtonStyle` merged
  /// with the per-instance override, raw-forwarded to `Button(buttonStyle:)`.
  final CoreButtonStyle saveButtonStyle;

  /// Nested [CoreIconStyle] slot for the upload glyph — the resolver
  /// absorbs the design-system default
  /// ([CoreFileInputStyle.defaultIconStyle]) so this is non-null and
  /// carries a concrete `size`. `co_file_input.dart` reads
  /// `iconStyle.size` for the SVG `width` / `height` attributes and the
  /// optional colour override flows through the upload icon's inline CSS.
  final CoreIconStyle iconStyle;

  /// Nested [CoreIconStyle] slot for the per-file row glyph — the
  /// resolver absorbs the design-system default
  /// ([CoreFileInputStyle.defaultFileIconStyle]) so this is non-null
  /// and carries a concrete `size`. `co_file_input.dart` reads
  /// `fileIconStyle.size` for the per-file SVG `width` / `height`
  /// attributes; the colour flows through [fileIcon]'s className.
  final CoreIconStyle fileIconStyle;

  /// Nested [CoreClickableStyle] slot for the composed drop-zone
  /// `Clickable` — `CoreFileInputStyle.defaultClickableStyle` merged
  /// with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `FileInput`.
///
/// Non-empty only when the idle-hover border cannot ride a Tailwind
/// `hover:` class: a RAW colour (no design token to name) or a per-instance
/// `borderColor` that ships inline on the root (an inline `color` outranks
/// any class, so the hover step has to out-shout it). `file_input.dart`
/// renders it as a `<style>` child of the drop zone; the default path ships
/// no `<style>` at all.
class ResolvedFileInputRules {
  /// Creates a [ResolvedFileInputRules].
  const ResolvedFileInputRules({required this.css});

  /// The scoped hover rule for the drop zone, or empty.
  final String css;
}

// ═══════════════════════════════════════════════════
// Idle-hover border — one decision, read by the chrome and the rules
// ═══════════════════════════════════════════════════

/// Scope id used when the caller names none. The widget always passes its
/// own per-instance id; only a direct resolver call falls back to this.
const _kDefaultScopeId = 'coui-file-input';

/// The class the drop-zone root carries so a scoped hover rule can find it
/// — per instance, since several drop zones can sit on one page.
String _zoneScopeClass(String scopeId) => '$scopeId-zone';

/// Idle-hover border of the drop zone — the edge colour while the pointer
/// is over the zone and no file is being dragged over it. Callers gate this
/// on `enabled && !isDragOver`; a real drag keeps its `primary` edge and a
/// disabled zone takes neither.
///
/// The dashes stroke with `currentColor`, so the colour lands on the root's
/// `color` ([ColorTarget.text]). Token → `hover:text-*` class, raw → scoped
/// rule. A per-instance `borderColor` ships INLINE as `color` on the root,
/// which beats every class and every selector-based rule, so that path
/// states its rule `!important` instead.
PseudoEmit _emitIdleHoverBorder(CoreFileInputStyle merged, String scopeId) {
  final scopeSelector = '.${_zoneScopeClass(scopeId)}';
  if (merged.borderColor != null) {
    final hover =
        merged.hoverBorderColor ?? CoreFileInputStyle.defaultHoverBorderColor;
    return (
      className: '',
      rule:
          '${WebPseudo.hover.selector(scopeSelector)}'
          '{color: ${hover.toValue()} !important;}',
    );
  }
  return emitPseudoColor(
    merged.hoverBorderColor,
    CoreFileInputStyle.defaultHoverBorderColor,
    .text,
    pseudo: .hover,
    scopeSelector: scopeSelector,
  );
}

/// Resolves [ResolvedFileInputRules] — the hover rule a class cannot carry.
/// Walks the same merge chain and the same gate as [resolveFileInput], so
/// the class the chrome drops and the rule emitted here are one decision.
ResolvedFileInputRules resolveFileInputRules(
  BuildContext context, {
  required bool enabled,
  required bool isDragOver,
  String scopeId = _kDefaultScopeId,
  CoreFileInputStyle? fileInputStyle,
}) {
  if (!enabled || isDragOver) return const ResolvedFileInputRules(css: '');

  final csTheme = context.theme.coreComponentTheme?.fileInput;
  final merged = resolveStyleChain(const CoreFileInputStyle(), [
    csTheme?.style,
    fileInputStyle,
  ]);

  return ResolvedFileInputRules(
    css: _emitIdleHoverBorder(merged, scopeId).rule,
  );
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFileInput] for the given [context].
///
/// ```text
/// design system default (CoreFileInputStyle.default*)
///   → CoreFileInputTheme.style
///   → widget.fileInputStyle
/// ```
///
/// [enabled] and [isDragOver] travel with the pre-computed root chrome
/// so the state-dependent border / background / hover / cursor classes
/// can be composed up-front by the resolver. The widget still
/// recomputes the resolver when these state flags flip, so reruns are
/// cheap and avoid leaking state details into widget build().
ResolvedFileInput resolveFileInput(
  BuildContext context, {
  required bool enabled,
  required bool isDragOver,
  String scopeId = _kDefaultScopeId,
  CoreFileInputStyle? fileInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.fileInput;

  final merged = resolveStyleChain(const CoreFileInputStyle(), [
    csTheme?.style,
    fileInputStyle,
  ]);

  // Radius / padding / item-spacing are **always** emitted inline (no
  // `rounded-*` / `p-*` / `gap-*` Tailwind class, no class-drop branch)
  // so the override path and the default path share one CSS surface —
  // the resolved chrome reflects `merged.X` directly (Epic #1603 single
  // inline signature gate).
  final borderRadius =
      (merged.borderRadius ?? CoreFileInputStyle.defaultBorderRadius).toValue();
  final padding = (merged.padding ?? CoreFileInputStyle.defaultPadding)
      .toValue();
  final itemSpacing = spaceCss(
    merged.itemSpacing ?? CoreFileInputStyle.defaultItemSpacing,
  );
  final textSpacing = spaceCss(
    merged.textSpacing ?? CoreFileInputStyle.defaultTextSpacing,
  );
  final actionSpacing = spaceCss(
    merged.actionSpacing ?? CoreFileInputStyle.defaultActionSpacing,
  );
  final iconBoxSize =
      merged.iconBoxSize ?? CoreFileInputStyle.defaultIconBoxSize;
  final borderWidth = merged.borderWidth;
  // Dash pattern — Core slot with the shared CoreDashedBorder baseline
  // default; rendered by the SVG `stroke-dasharray` overlay so the
  // pattern is deterministic across browsers (CSS `border-dashed`
  // leaves it to the engine) and user-tunable, mirroring the Flutter
  // dash painter.
  final dashLength = merged.dashLength ?? CoreFileInputStyle.defaultDashLength;
  final dashSpacing =
      merged.dashSpacing ?? CoreFileInputStyle.defaultDashSpacing;
  final strokeWidth = borderWidth ?? CoreFileInputStyle.defaultBorderWidth;
  // SVG `rect` expresses a single uniform corner radius (`rx`) — the
  // 4-corner CSS shorthand is invalid there, so take the canonical
  // top-left scalar (the drop-zone radius is uniform by design).
  final dashRectRadius =
      (merged.borderRadius ?? CoreFileInputStyle.defaultBorderRadius).topLeft;
  // A disabled zone paints the opaque `disabledContainer` fill / the
  // `disabledOutline` edge from their token classes: a per-instance idle
  // background / border override belongs to the enabled states and must not
  // ship inline over the disabled tokens (inline outranks the class).
  final backgroundColor = enabled ? merged.backgroundColor : null;
  final borderColor = enabled ? merged.borderColor : null;
  // surface:content — the drop zone draws its own box on the root
  // `<div>` rather than composing `OutlinedContainer`. Idle states no
  // fill of its own by design (the dashed border alone reads as a drop
  // zone); drag-active always states one — mirrors [buildRootClassName]'s
  // `backgroundClass` branch so the marker tracks exactly which fill (if
  // any) is actually painted this render.
  final containerFillCore =
      backgroundColor ??
      (enabled && isDragOver
          ? CoreFileInputStyle.defaultDragActiveBackgroundColor
          : null);
  // Promoted chrome — `fileItemSpacing` / `transitionDuration` now
  // carry contract override slots, so resolve them as
  // `merged.X ?? default` (Epic #1603 chaining gate — 1:1:1:1 ③칸).
  final fileItemSpacing =
      merged.fileItemSpacing ?? CoreFileInputStyle.defaultFileItemSpacing;
  final transitionDurationMs =
      (merged.transitionDuration ??
              CoreFileInputStyle.defaultTransitionDuration)
          .inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
  final transitionDurationCss = durationMsCss(transitionDurationMs);
  final transitionEasingCss = CoreEasing.move.toVarCss();
  // Nested icon slot — absorb the design-system default (size) and the
  // subtle-tone colour base so the composed `Icon` renders both through
  // its own resolver; the per-instance `iconStyle` override wins per
  // sub-field.
  // Disabled always wears the `disabledContent` tone (the per-instance
  // glyph colour belongs to the enabled states, like the Flutter twin).
  final iconStyle =
      CoreIconStyle(
            color: enabled && isDragOver
                ? merged.dragActiveIconColor ??
                      CoreFileInputStyle.defaultDragActiveIconColor
                : merged.subtleIconColor ??
                      CoreFileInputStyle.defaultSubtleIconColor,
          )
          .merge(CoreFileInputStyle.defaultIconStyle)
          .merge(merged.iconStyle)
          .merge(
            enabled
                ? null
                : CoreIconStyle(
                    color:
                        merged.disabledContentColor ??
                        CoreFileInputStyle.defaultDisabledContentColor,
                  ),
          );
  // Nested file-icon slot — same absorb-default pattern, used by the
  // per-file row glyph.
  final fileIconStyle = CoreFileInputStyle.defaultFileIconStyle.merge(
    merged.fileIconStyle,
  );
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreFileInputStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // Nested save-affordance button slot — the design-system default always
  // applies (the affordance is the input's own), so the override merges on
  // top rather than replacing it.
  final saveButtonStyle = CoreFileInputStyle.defaultSaveButtonStyle.merge(
    merged.saveButtonStyle,
  );

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value (token → class,
  // raw override → inline). No `cs.<token>` interpolation and no
  // `scheme.resolve` (a no-op on Web). State-dependent border /
  // background tones pass `null` as the override so they emit the
  // design-system default token class; the per-instance border /
  // background override drops the class and ships inline (card model).
  final borderColorEmit = emitColor(
    null,
    CoreFileInputStyle.defaultBorderColor,
    .text,
  );
  final disabledBorderEmit = emitColor(
    merged.disabledBorderColor,
    CoreFileInputStyle.defaultDisabledBorderColor,
    .text,
  );
  final dragOverBorderEmit = emitColor(
    merged.dragOverBorderColor,
    CoreFileInputStyle.defaultDragOverBorderColor,
    .text,
  );
  final iconBoxColorEmit = emitColor(
    !enabled
        ? merged.disabledIconBoxColor
        : isDragOver
        ? merged.dragActiveIconBoxColor
        : merged.iconBoxColor,
    !enabled
        ? CoreFileInputStyle.defaultDisabledIconBoxColor
        : isDragOver
        ? CoreFileInputStyle.defaultDragActiveIconBoxColor
        : CoreFileInputStyle.defaultIconBoxColor,
    .background,
  );
  final disabledBackgroundEmit = emitColor(
    merged.disabledBackgroundColor,
    CoreFileInputStyle.defaultDisabledBackgroundColor,
    .background,
  );
  final iconBoxRadiusEmit = emitRadius(
    merged.iconBoxBorderRadius,
    CoreFileInputStyle.defaultIconBoxBorderRadius,
  );
  final dragActiveBackgroundEmit = emitColor(
    merged.dragActiveBackgroundColor,
    CoreFileInputStyle.defaultDragActiveBackgroundColor,
    .background,
  );
  // Per-instance background / border overrides → inline CSS (token
  // overrides also resolve to a `var(--coui-X)` inline string).
  final backgroundColorInline = backgroundColor?.toValue();
  final borderColorInline = borderColor?.toValue();

  // Per-state content tones (label / hint / file name) — token classes.
  final labelEnabledEmit = emitColor(
    merged.contentColor,
    CoreFileInputStyle.defaultContentColor,
    .text,
  );
  final labelDisabledEmit = emitColor(
    merged.disabledContentColor,
    CoreFileInputStyle.defaultDisabledContentColor,
    .text,
  );
  final hintEnabledEmit = emitColor(
    merged.hintColor,
    CoreFileInputStyle.defaultHintColor,
    .text,
  );
  final fileIconEnabledEmit = emitColor(
    merged.fileIconColor,
    CoreFileInputStyle.defaultFileIconColor,
    .text,
  );
  final fileNameEnabledEmit = emitColor(
    merged.fileNameColor,
    CoreFileInputStyle.defaultFileNameColor,
    .text,
  );

  // Typography roles — `text-{role}` classes; the per-instance overlay
  // (if any) ships inline alongside the role class.
  final labelTypographyEmit = emitTypography(
    merged.labelTextStyle,
    CoreFileInputStyle.defaultLabelTextStyle,
  );
  final hintTypographyEmit = emitTypography(
    merged.hintTextStyle,
    CoreFileInputStyle.defaultHintTextStyle,
  );
  final fileTypographyEmit = emitTypography(
    merged.fileTextStyle,
    CoreFileInputStyle.defaultFileTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the drop-zone visual box `<div>` Tailwind className —
  /// `coui-file-input flex flex-col items-center justify-center` stack
  /// plus the dashed-border base and the state-dependent border /
  /// background / hover colour classes. Cursor and focus ring are owned
  /// by the composing `Clickable`.
  ///
  /// Radius / padding / item-spacing are **not** emitted here — they
  /// always ship inline through [buildRootInlineStyles] (single inline
  /// signature).
  /// Border / background colour follow the card model: the default
  /// state colour class is dropped only when the matching per-instance
  /// override (`borderColor` / `backgroundColor`) ships inline.
  String buildRootClassName() {
    // Border colour state — drop the default state class when a
    // per-instance `borderColor` override ships inline. Each state's
    // class comes from the emit family (token default → class).
    String resolveBorderColorClass() {
      if (borderColor != null) return '';
      if (!enabled) return disabledBorderEmit.className;
      if (isDragOver) return dragOverBorderEmit.className;
      return borderColorEmit.className;
    }

    final borderColorClass = resolveBorderColorClass();

    final backgroundClass = !enabled
        ? disabledBackgroundEmit.className
        : backgroundColor == null && isDragOver
        ? dragActiveBackgroundEmit.className
        : '';

    // Hover pseudo-state (inline CSS cannot express `:hover`) — the idle
    // step to the hover border, `disabled > drag-over > hover > idle`: a
    // disabled zone has none and a real drag keeps its `primary` edge, so
    // neither states it. Hover never tints the fill — only a drag does.
    // A token rides a `hover:` class; anything else rides the scoped rule
    // `resolveFileInputRules` emits, found through the zone's scope class.
    final hoverEmit = enabled && !isDragOver
        ? _emitIdleHoverBorder(merged, scopeId)
        : (className: '', rule: '');
    final hasHoverRule = hoverEmit.rule.isNotEmpty;

    return [
      'coui-file-input',
      WebLayout.relative,
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      // Clickable receives the caller's width. Its visual drop zone must
      // fill that allocation while retaining its intrinsic size otherwise.
      WebLayout.grow,
      WebLayout.minWZero,
      borderColorClass,
      backgroundClass,
      hoverEmit.className,
      if (hasHoverRule) _zoneScopeClass(scopeId),
      // Marks this as a component surface only while a fill is actually
      // painted this render — idle states none by design, so a material
      // handed to it would stack a backdrop pass behind nothing.
      if (containerFillCore != null && !containerFillCore.isTransparent)
        ...webSurfaceMarkerFor(.content),
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the file-input `<div role="button">` inline CSS — radius /
  /// padding / item-spacing are always inlined (single signature;
  /// default and override share this one surface), plus the
  /// colour-crossfade transition and the per-instance border-width /
  /// background / border-colour overrides.
  Styles buildRootInlineStyles() {
    final raw = {
      // Always-inline chrome (default or override on the same surface).
      'border-radius': borderRadius,
      'padding': padding,
      'gap': itemSpacing,
      // Colour crossfade — emitted inline so the duration follows the
      // resolved `transitionDurationMs` (token default or override),
      // mirroring the Flutter `AnimatedContainer` (card model).
      'transition':
          'color $transitionDurationCss $transitionEasingCss, '
          'background-color $transitionDurationCss $transitionEasingCss',
    };
    if (backgroundColorInline != null) {
      raw['background-color'] = backgroundColorInline;
    }
    // The marker's other half — a preset restates this fill at a lower
    // alpha and cannot know which token the drop zone chose.
    if (containerFillCore != null && !containerFillCore.isTransparent) {
      raw.addAll(surfaceFillVar(containerFillCore));
    }
    if (borderColorInline != null) {
      // Border-colour override rides the root's `color` — the dash
      // overlay strokes with `currentColor`. The drag state class is
      // already dropped when an override is present; the hover step
      // states its scoped rule `!important` (see `_emitIdleHoverBorder`),
      // so this inline value cannot shadow it.
      raw['color'] = borderColorInline;
    }
    // Raw disabled overrides (token overrides ride the class above) have
    // no class to stand on, so they ship inline — enabled states never
    // reach this branch.
    if (!enabled) {
      raw
        ..addAll(disabledBackgroundEmit.inline ?? const {})
        ..addAll(disabledBorderEmit.inline ?? const {});
    }
    return Styles(raw: raw);
  }

  /// Composes the primary label `<span>` Tailwind className —
  /// `text-{bodySmall}` plus content colour (full opacity when enabled,
  /// dimmed when disabled).
  String buildLabelTextClassName() {
    final contentColorClass = enabled
        ? labelEnabledEmit.className
        : labelDisabledEmit.className;
    return [
      labelTypographyEmit.className,
      contentColorClass,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the primary label `<span>` inline CSS — applied only
  /// when a [CoreTextStyle] override is supplied (role overlay).
  Styles? buildLabelTextInlineStyles() {
    final raw = labelTypographyEmit.inline;
    return raw == null ? null : Styles(raw: raw);
  }

  /// Composes the optional hint `<span>` Tailwind className —
  /// `text-{labelMedium}` plus a dimmer content colour
  /// (60% enabled / 40% disabled).
  String buildHintTextClassName() {
    final hintColorClass = enabled
        ? hintEnabledEmit.className
        : labelDisabledEmit.className;
    return [
      hintTypographyEmit.className,
      hintColorClass,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the optional hint `<span>` inline CSS — applied only
  /// when a [CoreTextStyle] override is supplied (role overlay).
  Styles? buildHintTextInlineStyles() {
    final raw = hintTypographyEmit.inline;
    return raw == null ? null : Styles(raw: raw);
  }

  /// Composes the icon box `<div>` className — flex centring, never
  /// shrinks, fill + radius classes (token) or inline (override).
  String buildIconBoxClassName() => [
    WebLayout.flexCenter,
    WebLayout.shrinkZero,
    iconBoxColorEmit.className,
    iconBoxRadiusEmit.className,
  ].where((c) => c.isNotEmpty).join(' ');

  Styles buildIconBoxInlineStyles() => Styles(
    raw: {
      'width': '${iconBoxSize / kRemDivisor}rem',
      'height': '${iconBoxSize / kRemDivisor}rem',
      ...?iconBoxColorEmit.inline,
      ...?iconBoxRadiusEmit.inline,
    },
  );

  /// Composes the button row `<div>` Tailwind className — flex row,
  /// centred.
  String buildButtonsRowClassName() => WebLayout.flexItemsCenter;

  /// Composes the button row `<div>` inline CSS — the resolved
  /// `itemSpacing` (token default or override) as its `gap`, the same
  /// value the Flutter twin puts on `Row.spacing`.
  Styles buildButtonsRowInlineStyles() => .new(
    raw: {'gap': itemSpacing},
  );

  /// Composes the selected-files list `<div>` Tailwind className —
  /// `flex flex-col items-center` vertical stack.
  String buildSelectedFilesClassName() => WebLayout.flexColItemsCenter;

  /// Composes the per-file row `<div>` Tailwind className — flex row.
  /// The gap + bottom margin ship inline (single signature) so the
  /// resolved `fileItemSpacing` (token default or override) drives both.
  String buildFileItemClassName() => WebLayout.flexItemsCenter;

  /// Composes the per-file row `<div>` inline CSS — gap + bottom margin
  /// from the resolved `fileItemSpacing` (default or override on one
  /// surface).
  Styles buildFileItemInlineStyles() => .new(
    raw: {
      'gap': spaceCss(fileItemSpacing),
      'margin-bottom': spaceCss(fileItemSpacing),
    },
  );

  /// Composes the per-file icon `<svg>` Tailwind className — dimmed
  /// content colour mirroring the hint colour so the disabled state is
  /// expressed via a single token.
  String buildFileIconClassName() {
    return enabled
        ? fileIconEnabledEmit.className
        : labelDisabledEmit.className;
  }

  /// Composes the per-file name `<span>` Tailwind className —
  /// `text-{labelMedium}` + slightly stronger content colour for the
  /// file name plus `truncate` for overflow.
  String buildFileNameClassName() {
    final fileNameColorClass = enabled
        ? fileNameEnabledEmit.className
        : labelDisabledEmit.className;
    return [
      fileTypographyEmit.className,
      fileNameColorClass,
      WebLayout.truncate,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  return ResolvedFileInput(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    dashOverlay: WebElementChrome(
      className: dashedOverlaySvgClassName(),
      inlineStyles: dashedOverlaySvgStyles(),
    ),
    dashRect: WebElementChrome(
      className: '',
      inlineStyles: dashedOverlayRectStyles(
        // Deliberately NOT `strokeWidthCss(strokeWidth)` — unlike
        // OutlinedContainer/Frame/Button, FileInput's Flutter twin never
        // runs this field through `theme.geometry.stroke` (no `* scaling`
        // either), so it isn't stroke-axis-bound on either platform today.
        // Passing a literal here keeps Web behaviourally identical to
        // Flutter; routing it through the CSS variable would make Web
        // respond to `strokeFloor` presets while Flutter still would not,
        // trading today's consistent-bypass for a new one-way divergence.
        strokeWidth: '${strokeWidth / kRemDivisor}rem',
        dashLength: dashLength,
        dashGap: dashSpacing,
        radius: dashRectRadius,
        // A file over the zone turns the dashes solid — "you can drop here"
        // said by shape as well as by the `primary` colour. Colour and
        // width stay as they are (mirrors the Flutter dash painter).
        solid: enabled && isDragOver,
      ),
    ),
    hiddenInput: const WebElementChrome(className: WebLayout.srOnly),
    iconBox: WebElementChrome(
      className: buildIconBoxClassName(),
      inlineStyles: buildIconBoxInlineStyles(),
    ),
    contentGroup: WebElementChrome(
      className: WebLayout.flexColItemsCenter,
      inlineStyles: Styles(raw: {'gap': actionSpacing}),
    ),
    textBlock: WebElementChrome(
      className: WebLayout.flexColItemsCenter,
      inlineStyles: Styles(raw: {'gap': textSpacing}),
    ),
    labelText: WebElementChrome(
      className: buildLabelTextClassName(),
      inlineStyles: buildLabelTextInlineStyles(),
    ),
    buttonsRow: WebElementChrome(
      className: buildButtonsRowClassName(),
      inlineStyles: buildButtonsRowInlineStyles(),
    ),
    hintText: WebElementChrome(
      className: buildHintTextClassName(),
      inlineStyles: buildHintTextInlineStyles(),
    ),
    selectedFiles: WebElementChrome(
      className: buildSelectedFilesClassName(),
    ),
    fileItem: WebElementChrome(
      className: buildFileItemClassName(),
      inlineStyles: buildFileItemInlineStyles(),
    ),
    fileIcon: WebElementChrome(className: buildFileIconClassName()),
    fileName: WebElementChrome(className: buildFileNameClassName()),
    saveButtonStyle: saveButtonStyle,
    iconStyle: iconStyle,
    fileIconStyle: fileIconStyle,
    clickableStyle: clickableStyle,
  );
}
