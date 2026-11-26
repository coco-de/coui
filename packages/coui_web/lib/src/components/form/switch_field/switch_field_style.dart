library;

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

/// Paint-ready chrome for Web `SwitchField`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)
///   ├─ textColumn (<div>)
///   │    ├─ label (<label>)
///   │    ├─ Gap (labelDescriptionGapStyle)  // co_switch_field renders only when description != null
///   │    └─ description (<p>)
///   ├─ Gap (labelToggleGapStyle)
///   └─ Toggle(size, toggleStyle)            // size forwarded as semantic param, track colours via nested slot
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots ([root] / [textColumn] / [label] /
///   [description]) the widget drops straight into
///   `Component.element(classes: ..., styles: ...)`.
/// * Cat 2 — nested style slots:
///     * [toggleStyle] passed to the child `Toggle(toggleStyle: …)` —
///       carries the resolved active / inactive track colours (kept as
///       [CoreColor] so `Toggle` runs its own `.toValue()` step).
///     * [labelToggleGapStyle] / [labelDescriptionGapStyle] passed to
///       the `Gap(gapStyle: …)` siblings — `Gap` runs its own
///       resolve / scaling step (mirrors the Flutter widget).
///
/// The toggle's semantic [CoreComponentSize] is NOT carried here — it is
/// a `Toggle(size:)` widget param (behavioural identifier, not paint
/// chrome of this component's own elements), so the widget reads it from
/// the merge chain via [resolveSwitchFieldSize] (the number_ticker
/// separate-resolver pattern).
class ResolvedSwitchField implements WebResolvedChrome {
  /// Creates a [ResolvedSwitchField].
  const ResolvedSwitchField({
    required this.clickableStyle,
    required this.root,
    required this.textColumn,
    required this.label,
    required this.description,
    required this.toggleStyle,
    required this.labelToggleGapStyle,
    required this.labelDescriptionGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the label + description column `<div>`.
  final WebElementChrome textColumn;

  /// Paint-ready chrome for the label `<label>` element.
  final WebElementChrome label;

  /// Paint-ready chrome for the description `<p>` element — always
  /// non-null; `co_switch_field` decides whether to render the element.
  final WebElementChrome description;

  /// Nested [CoreToggleStyle] slot — forwarded straight to
  /// `Toggle(toggleStyle: …)`. Carries the resolved active / inactive
  /// track colours as [CoreColor] so the child runs its own
  /// `.toValue()` step.
  final CoreToggleStyle toggleStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreSwitchFieldStyle.defaultClickableStyle`,
  /// which keeps the Clickable's generic disabled fade off because the
  /// field paints its own disabled tokens) merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreGapStyle] slot — forwarded to the `Gap(gapStyle: …)`
  /// sibling sitting between the text column and the `Toggle`. `Gap`
  /// runs its own resolve / scaling step (mirrors the Flutter widget).
  final CoreGapStyle labelToggleGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded to the `Gap(gapStyle: …)`
  /// sibling sitting between the label and description inside the text
  /// column. Only rendered by the widget when `description != null`.
  final CoreGapStyle labelDescriptionGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwitchField] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.switchField.style
///   → widget.switchFieldStyle
/// ```
///
/// [enabled] picks between the enabled and disabled typography slot
/// pairs and drives the cursor between `pointer` and `not-allowed`.
ResolvedSwitchField resolveSwitchField(
  BuildContext context, {
  required bool enabled,
  CoreSwitchFieldStyle? switchFieldStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.switchField;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSwitchFieldStyle(), [
    csTheme?.style,
    switchFieldStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward the resulting slot straight
  // to `Gap(gapStyle: …)` in the widget. `Gap` runs its own
  // resolve / scaling step, so the resolver carries no inline `gap` /
  // `row-gap` CSS (mirrors the Flutter resolver + the breadcrumb /
  // basic Web exemplars).
  final labelToggleGapStyle = CoreSwitchFieldStyle.defaultLabelToggleGapStyle
      .merge(merged.labelToggleGapStyle);
  final labelDescriptionGapStyle = CoreSwitchFieldStyle
      .defaultLabelDescriptionGapStyle
      .merge(
        merged.labelDescriptionGapStyle,
      );
  final activeColor =
      merged.activeColor ?? CoreSwitchFieldStyle.defaultActiveColor;
  final inactiveColor =
      merged.inactiveColor ?? CoreSwitchFieldStyle.defaultInactiveColor;
  final minHeight = merged.minHeight ?? CoreSwitchFieldStyle.defaultMinHeight;

  // Typography slot selection — enabled / disabled default + caller
  // override. `emitTypography` is the single canonical path: it composes
  // `fallbackDefault.merge(value)`, then emits the typography role on a
  // `text-{role}` class (+ token colour class — dark-mode reactive) and
  // any explicit scalar overlay (`font-weight` etc.) inline. No
  // hand-rolled `text-${...token!.name}` / `font-${...}` / colour class.
  final labelDefault = enabled
      ? CoreSwitchFieldStyle.defaultLabelTextStyle
      : CoreSwitchFieldStyle.defaultDisabledLabelTextStyle;
  final labelOverride = enabled
      ? merged.labelTextStyle
      : merged.disabledLabelTextStyle;
  final descriptionDefault = enabled
      ? CoreSwitchFieldStyle.defaultDescriptionTextStyle
      : CoreSwitchFieldStyle.defaultDisabledDescriptionTextStyle;
  final descriptionOverride = enabled
      ? merged.descriptionTextStyle
      : merged.disabledDescriptionTextStyle;

  final labelEmit = emitTypography(labelOverride, labelDefault);
  final descriptionEmit = emitTypography(
    descriptionOverride,
    descriptionDefault,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root row inline CSS — a `min-height` floor when one
  /// is stated (the whole row is the press area; `items-center` centres
  /// the content in it). Nothing at the default, so the row renders as
  /// it always has.
  Styles? buildRootInlineStyles() => minHeight > 0
      ? Styles(raw: {'min-height': '${minHeight / kRemDivisor}rem'})
      : null;

  /// Composes the label `<label>` Tailwind className — typography role +
  /// colour class from [labelEmit]. Cursor is owned by the composing
  /// `Clickable` root and inherits down.
  String buildLabelClassName() => labelEmit.className;

  /// Composes the label `<label>` inline-CSS bundle — the explicit
  /// scalar / raw-colour overlay [emitTypography] emits inline alongside
  /// the role class.
  Styles? buildLabelInlineStyles() {
    final raw = labelEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the description `<p>` Tailwind className — typography role +
  /// colour class from [descriptionEmit].
  String buildDescriptionClassName() => descriptionEmit.className;

  /// Composes the description `<p>` inline-CSS bundle — same shape as
  /// [buildLabelInlineStyles].
  Styles? buildDescriptionInlineStyles() {
    final raw = descriptionEmit.inline;
    return raw == null || raw.isEmpty ? null : Styles(raw: raw);
  }

  // Nested toggle slot — the resolved active / inactive track colours
  // folded into a `CoreToggleStyle` that `co_switch_field` forwards
  // straight to `Toggle(toggleStyle: …)`. The widget never builds a
  // `CoreToggleStyle` itself (옵션 B Cat 2 nested-slot pattern).
  final toggleStyle = CoreToggleStyle(
    trackActiveColor: activeColor,
    trackInactiveColor: inactiveColor,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  // Root is the content row inside the composing `Clickable` (which
  // owns cursor / press-shrink / focus ring for the whole field, like
  // the Flutter twin's `Clickable(child: Row(…))`). `w-full` keeps the
  // row spanning the field width inside the inline-flex Clickable.
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreSwitchFieldStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  return ResolvedSwitchField(
    clickableStyle: clickableStyle,
    root: WebElementChrome(
      className: '${WebLayout.flexBetween} ${WebLayout.wFull}',
      inlineStyles: buildRootInlineStyles(),
    ),
    // `flex-1 min-w-0` — the text column absorbs the free width and
    // shrinks below its content (Flutter `Expanded` mirror) so a long
    // label/description wraps instead of pushing the toggle out.
    textColumn: const WebElementChrome(
      className:
          '${WebLayout.flex} ${WebLayout.flexCol}'
          ' ${WebLayout.flex1} ${WebLayout.minWZero}',
    ),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    toggleStyle: toggleStyle,
    labelToggleGapStyle: labelToggleGapStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
  );
}

/// Resolves the merged toggle [CoreComponentSize] for `SwitchField` —
/// forwarded to the child `Toggle(size: …)` semantic widget param.
///
/// Walks the same merge chain as [resolveSwitchField] (design-system
/// default → `CoreSwitchFieldTheme.style.size` →
/// `widget.switchFieldStyle.size`). Kept as a separate `resolveCo*` entry
/// point so [ResolvedSwitchField] stays purely paint-ready chrome
/// (Epic #1603 옵션 B 최종 — no scalar metadata on `ResolvedCo*`; the
/// number_ticker separate-resolver pattern).
CoreComponentSize resolveSwitchFieldSize(
  BuildContext context, {
  CoreSwitchFieldStyle? switchFieldStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.switchField;
  final merged = resolveStyleChain(const CoreSwitchFieldStyle(), [
    csTheme?.style,
    switchFieldStyle,
  ]);
  return merged.size ?? CoreSwitchFieldStyle.defaultSize;
}
