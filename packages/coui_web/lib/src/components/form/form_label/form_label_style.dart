import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ── ResolvedFormLabel ──────────────────────────────

/// Resolver output for `FormLabel` (Web).
///
/// DOM shape:
///
/// ```text
/// root (<label>)                    // label container
///   ├─ caller label component       // optional caller-provided label
///   └─ required (<span>)            // optional `*` indicator
/// ```
///
/// Every chrome / typography override has had the nested-merge chain
/// applied plus the `CoreFormLabelStyle.defaultX` static const fallback:
///
/// ```text
/// CoreFormLabelStyle.defaultX            // design system default
///   → theme.coreComponentTheme.formLabel.style
///   → component.formLabelStyle
/// ```
class ResolvedFormLabel implements WebResolvedChrome {
  /// Creates a [ResolvedFormLabel].
  const ResolvedFormLabel({
    required this.root,
    required this.required,
  });

  /// Paint-ready chrome for the outermost `<label>` container —
  /// composed `inline-flex flex-row items-center` layout className with
  /// the resolved typography token (`text-{labelMedium}` / `text-{labelLarge}`
  /// by size, on-surface-variant colour class) plus any explicit per-instance
  /// typography / colour overlay emitted inline.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the required-indicator `<span>` — empty
  /// className, inline CSS bundle carrying the resolved
  /// `margin-inline-start` (gap from the label) plus the required colour.
  /// Always non-null; the call site skips rendering this element when
  /// `isRequired` is `false` or a caller-supplied `requiredIndicator`
  /// overrides it.
  final WebElementChrome required;
}

// ── resolveFormLabel (single entry point) ───────────

/// Resolves [ResolvedFormLabel] for the given [context].
ResolvedFormLabel resolveFormLabel(
  BuildContext context, {
  required CoreComponentSize size,
  bool enabled = true,
  CoreFormLabelStyle? formLabelStyle,
}) {
  final formLabelTheme = context.theme.coreComponentTheme?.formLabel;

  // Stage 1 RESOLVE — theme.style → component.formLabelStyle.
  final merged = resolveStyleChain(const CoreFormLabelStyle(), [
    formLabelTheme?.style,
    formLabelStyle,
  ]);

  // Stage 1 RESOLVE — nested `CoreGapStyle` slot (merge default +
  // override), then extract `size` for the inline `margin-inline-start`
  // value that separates the label and the required-indicator `<span>`.
  final requiredIndicatorGapStyle = CoreFormLabelStyle
      .defaultRequiredIndicatorGapStyle
      .merge(merged.requiredIndicatorGapStyle);
  final requiredGapCss = spaceCss(requiredIndicatorGapStyle.size!);

  // The size-keyed default (role + colour) is the EMIT baseline instead
  // of the flat `defaultLabelStyle` — `xs`/`sm`/`md` settle on the 13px
  // rung, `lg`/`xl`/`xl2` on the 14px rung
  // (`CoreFormLabelStyle.defaultsBySize`). `enabled` forces the colour
  // half of both the baseline and any per-instance override to
  // `disabledColor` — the size-derived role still applies underneath,
  // and a per-instance colour override cannot silently win over the
  // disabled state (same "select between resolved values" shape as any
  // other per-state VALUE, not a runtime DETECTION branch — Web's CSS
  // pseudo-classes have no "disabled" concept for a plain `<span>`
  // anyway, so this has to be a build-time select).
  final sizeLabelStyle = CoreFormLabelStyle.defaultsBySize[size]!.labelStyle!;
  final disabledColor =
      merged.disabledColor ?? CoreFormLabelStyle.defaultDisabledColor;
  final labelStyleBase = enabled
      ? sizeLabelStyle
      : sizeLabelStyle.copyWith(color: disabledColor);
  final labelStyleOverride = enabled
      ? merged.labelStyle
      : merged.labelStyle?.copyWith(color: disabledColor);

  // Stage 2 EMIT (theme-free) — typography role + colour through the
  // single `emitTypography` entry point (role class + explicit overlay
  // inline); required colour through `emitColor`.
  final labelTypography = emitTypography(labelStyleOverride, labelStyleBase);
  final requiredColor = enabled
      ? emitColor(
          merged.requiredColor,
          CoreFormLabelStyle.defaultRequiredColor,
          .text,
        )
      : emitColor(null, disabledColor, .text);

  // ─── Local builders ───────────────────────────────────

  /// Composes the form-label `<label>` Tailwind className — layout +
  /// the resolved typography role / colour class.
  String buildRootClassName() => [
    WebLayout.inlineFlex,
    WebLayout.flexRow,
    WebLayout.itemsCenter,
    labelTypography.className,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the form-label `<label>` inline CSS — explicit typography
  /// overlay (font-size / font-weight / …) when the caller layered one
  /// on top of the role. Returns `null` when nothing needs inlining.
  Styles? buildRootInlineStyles() {
    final raw = labelTypography.inline;
    if (raw == null || raw.isEmpty) return null;
    return Styles(raw: raw);
  }

  /// Composes the required-indicator `<span>` inline CSS — inline-start margin
  /// governed by the resolved gap, colour from the resolved required
  /// colour.
  Styles buildRequiredInlineStyles() => .new(
    raw: {
      'margin-inline-start': requiredGapCss,
      ...?requiredColor.inline,
    },
  );

  /// Composes the required-indicator `<span>` className — the resolved
  /// required colour class when it is token-bound.
  String buildRequiredClassName() => requiredColor.className;

  return ResolvedFormLabel(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    required: WebElementChrome(
      className: buildRequiredClassName(),
      inlineStyles: buildRequiredInlineStyles(),
    ),
  );
}
