library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DatePicker` / `DateRangePicker`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // flex-col wrapper
///   ├─ label (<div>)                        // co_date_picker renders only when label != null
///   ├─ Gap (labelBottomGapStyle)          // co_date_picker renders only when label != null
///   ├─ triggerSurface                       // Popover | <div> (dialog mode)
///   │    ├─ trigger (read-only TextField)  //   chrome = triggerStyle
///   │    └─ dialogContentWrap (<div>)       //   dialog mode only — calendar centering wrapper
///   ├─ Gap (descriptionTopGapStyle)       // co_date_picker renders only when description or error present
///   ├─ description (<div>)                  // co_date_picker renders only when description != null && errorText == null
///   └─ error (<div>)                        // co_date_picker renders only when errorText != null
/// ```
///
/// All chrome slot fields are non-null — `co_date_picker` decides
/// whether to render each optional element based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots forwarded to child unified
///   widgets ([popoverStyle] → `Popover.popoverStyle`,
///   [dialogStyle] → `Dialog.dialogStyle`,
///   [calendarStyle] → `Calendar.calendarStyle`,
///   [triggerStyle] → the trigger `TextField.textFieldStyle`,
///   [labelBottomGapStyle] / [descriptionTopGapStyle] →
///   `Gap.gapStyle`).
///
/// No scalar metadata is exposed — semantic identifiers (`mode`) and
/// behaviour fields stay on the widget prop.
class ResolvedDatePicker implements WebResolvedChrome {
  /// Creates a [ResolvedDatePicker].
  const ResolvedDatePicker({
    required this.root,
    required this.label,
    required this.triggerStyle,
    required this.trailingIconStyle,
    required this.dialogContentWrap,
    required this.description,
    required this.error,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.calendarStyle,
    required this.labelBottomGapStyle,
    required this.descriptionTopGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` grid wrapper that
  /// stacks the label / trigger / description-or-error rows.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the label `<div>` — `co_date_picker` skips
  /// this element when `label == null`.
  final WebElementChrome label;

  /// The trigger field's chrome — [CoreDatePickerStyle.defaultTriggerStyle]
  /// with the error edge, the value / placeholder colours and the value role
  /// folded in, then the per-instance `triggerStyle` on top. A disabled
  /// picker leaves the two text colours out so the field's own disabled tone
  /// applies. Forwarded raw to the composed read-only `TextField`, which
  /// resolves it. Mirrors the Flutter resolver 1:1.
  final CoreTextFieldStyle triggerStyle;

  /// Paint-ready trailing (calendar) icon style — the trigger's
  /// `trailingIconStyle` override chained onto the 16-px design-system
  /// default. The widget reads this straight; the single and range
  /// triggers pick their own glyph (`calendar` / `calendarRange`).
  final CoreIconStyle trailingIconStyle;

  /// Paint-ready chrome for the inner `<div>` that centres the calendar
  /// inside the dialog content — `flex justify-center` so the calendar's
  /// natural width stays centred in the dialog's stretch area.
  final WebElementChrome dialogContentWrap;

  /// Paint-ready chrome for the description `<div>` — `co_date_picker`
  /// skips this element when `description == null` or when an error is
  /// shown instead.
  final WebElementChrome description;

  /// Paint-ready chrome for the error `<div>` — `co_date_picker` skips
  /// this element when `errorText == null`.
  final WebElementChrome error;

  /// Nested [CorePopoverStyle] for the popover-mode picker — forwarded
  /// to `Popover(popoverStyle: …)`. `null` when the caller did not
  /// supply a popover override.
  final CorePopoverStyle? popoverStyle;

  /// Nested [CoreDialogStyle] for the dialog-mode picker — forwarded
  /// to `Dialog(dialogStyle: …)`. `null` when the caller did not
  /// supply a dialog override.
  final CoreDialogStyle? dialogStyle;

  /// Nested [CoreCalendarStyle] applied to the inline calendar grid —
  /// forwarded to `Calendar(calendarStyle: …)`. `null` when the
  /// caller did not supply a calendar override.
  final CoreCalendarStyle? calendarStyle;

  /// Resolved nested [CoreGapStyle] slot for the vertical gap between
  /// the label row and the trigger row — the design-system default
  /// merged with `merged.labelBottomGapStyle`. Forwarded straight to
  /// `Gap(gapStyle: …)` so the receiving `Gap` owns its own scaling.
  final CoreGapStyle labelBottomGapStyle;

  /// Resolved nested [CoreGapStyle] slot for the vertical gap between
  /// the trigger row and the description / error text row — the
  /// design-system default merged with `merged.descriptionTopGapStyle`.
  /// Forwarded straight to `Gap(gapStyle: …)` so the receiving `Gap`
  /// owns its own scaling.
  final CoreGapStyle descriptionTopGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDatePicker] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default for date picker
///   → theme.coreComponentTheme.datePicker.style
///   → widget.datePickerStyle (or widget.dateRangePickerStyle)
/// ```
ResolvedDatePicker resolveDatePicker(
  BuildContext context, {
  CoreDatePickerStyle? datePickerStyle,
  bool enabled = true,
}) {
  final datePickerTheme = context.theme.coreComponentTheme?.datePicker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDatePickerStyle(), [
    datePickerTheme?.style,
    datePickerStyle,
  ]);

  // Field-trigger convention default (`triggerSizing: .expand`) with the
  // per-instance override merged on top — single Core source instead of
  // widget-side `copyWith`.
  final popoverStyle = CoreDatePickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // Nested child-component slots — the picker's (empty) partial with the
  // per-instance override merged on top, forwarded raw so `Dialog` /
  // `Calendar` fill their own defaults (no field-by-field reach).
  final dialogStyle = CoreDatePickerStyle.defaultDialogStyle.merge(
    merged.dialogStyle,
  );
  final calendarStyle = CoreDatePickerStyle.defaultCalendarStyle.merge(
    merged.calendarStyle,
  );

  // ─── Resolved chrome values ───────────────────────────
  // Per-instance text-style overrides for the label / description /
  // error rows. Each captured value drives inline-CSS emission on the
  // matching chrome slot below; the Tailwind className carries the
  // design-system baseline.
  final labelStyleOverride = merged.labelStyle;
  final descriptionStyleOverride = merged.descriptionStyle;
  final errorStyleOverride = merged.errorStyle;

  // Stage2 EMIT (theme-free) — `emitTypography(override, default)` resolves
  // `default.merge(override)`, emitting the design-system role class
  // (`text-{role}`) plus any explicit scalar / raw-colour overlay inline
  // in one decision (no hand-rolled `.token!.name` class, matching the
  // Flutter resolver's per-row merge 1:1).
  final labelEmit = emitTypography(
    labelStyleOverride,
    CoreDatePickerStyle.defaultLabelStyle,
  );
  final descriptionEmit = emitTypography(
    descriptionStyleOverride,
    CoreDatePickerStyle.defaultDescriptionStyle,
  );
  final errorEmit = emitTypography(
    errorStyleOverride,
    CoreDatePickerStyle.defaultErrorStyle,
  );

  // Row text colours — `(merged.X ?? default)` so the flat override
  // wins, else the design-system default token (1:1:1:1 with the
  // contract slot + the Flutter resolver). The token class is emitted
  // by default and suppressed in favour of an inline `color` rule when
  // either the flat colour override or the nested text-style `.color`
  // override is present (card model — colour token class drop + inline
  // override). Web emits token names theme-free — `.toValue()` yields
  // `rgb(var(--coui-X))`, resolved at runtime by the browser, so no
  // `scheme.resolve` (a no-op on Web).
  final contentColor =
      merged.contentColor ?? CoreDatePickerStyle.defaultContentColor;
  // A disabled picker paints its description `disabledDescriptionColor`, the
  // way it paints its error text — the Flutter resolver 1:1.
  final descriptionColorOverride = enabled
      ? merged.descriptionColor
      : merged.disabledDescriptionColor;
  final descriptionColor =
      descriptionColorOverride ??
      (enabled
          ? CoreDatePickerStyle.defaultDescriptionColor
          : CoreDatePickerStyle.defaultDisabledDescriptionColor);
  // A disabled picker paints its error text `disabledErrorColor` (disabled
  // outranks the error) — the Flutter resolver 1:1.
  final errorColorOverride = enabled
      ? merged.errorColor
      : merged.disabledErrorColor;
  final errorColor =
      errorColorOverride ??
      (enabled
          ? CoreDatePickerStyle.defaultErrorColor
          : CoreDatePickerStyle.defaultDisabledErrorColor);
  // Nested `CoreGapStyle` slots — merge the design-system defaults with
  // the per-instance overrides and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step. Mirrors the Flutter
  // resolver which forwards each slot to its `Gap` sibling.
  final labelBottomGapStyle = CoreDatePickerStyle.defaultLabelBottomGapStyle
      .merge(merged.labelBottomGapStyle);
  final descriptionTopGapStyle = CoreDatePickerStyle
      .defaultDescriptionTopGapStyle
      .merge(merged.descriptionTopGapStyle);

  // The trigger is a read-only `TextField` (the TimePicker / Select input
  // look): its box, edge and Regular 14 value are the field's own `md` row,
  // and one Core function folds the picker's own decisions (the error edge,
  // the value / placeholder colours, an explicit value role) under the
  // per-instance `triggerStyle`. A disabled picker leaves the two text
  // colours out so the field's disabled tone applies. Mirrors the Flutter
  // resolver 1:1.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;

  // The paint-ready trailing-icon style (trigger override chained onto the
  // 16-px default). A disabled picker leaves the glyph untinted: the trigger
  // field's own disabled foreground applies to it the way it does to the
  // value text.
  final trailingIconRung =
      merged.trailingIconStyle ?? CoreDatePickerStyle.defaultTrailingIconStyle;
  final trailingIconStyle = enabled
      ? trailingIconRung
      : trailingIconRung.withoutColor;

  // ─── Local builders ───────────────────────────────────

  /// Composes the picker root `<div>` Tailwind className.
  /// `flex flex-col w-full` stacks the label / trigger /
  /// description-or-error rows; the inter-row gaps are inserted as
  /// `Gap` siblings (see [labelBottomGapStyle] /
  /// [descriptionTopGapStyle]). No `overflow-hidden` (would clip the
  /// popover when it wasn't portaled), no `relative` (Popover portals
  /// to the overlay host so positioning isn't local).
  String buildRootClassName() => WebLayout.flexColFull;

  /// Composes the label `<div>` Tailwind className — [labelEmit] supplies
  /// the design-system label typography role class; the flat content
  /// colour token class is dropped when a flat `merged.contentColor` or
  /// nested `merged.labelStyle.color` override is present so the inline
  /// rule in [buildLabelInlineStyles] wins.
  String buildLabelClassName() {
    final hasColorOverride =
        merged.contentColor != null || labelStyleOverride?.color != null;
    return <String>[
      labelEmit.className,
      if (!hasColorOverride) 'text-${contentColor.tailwindColor}',
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the label `<div>` inline-CSS bundle — the [labelEmit]
  /// overlay (explicit font / weight / nested `labelStyle.color`) plus
  /// the resolved flat `contentColor` (only when it is overridden and the
  /// nested `labelStyle.color` is unset, so the nested colour wins).
  Styles? buildLabelInlineStyles() {
    final raw = <String, String>{...?labelEmit.inline};
    if (merged.contentColor != null && labelStyleOverride?.color == null) {
      raw['color'] = contentColor.toValue();
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the dialog content wrapper Tailwind className. Calendar
  /// root is `inline-flex` so in the dialog content stretch area it would
  /// align left at its natural width — `flex justify-center` keeps it
  /// centred.
  String buildDialogContentWrapClassName() => WebLayout.flexJustifyCenter;

  /// Composes the description `<div>` Tailwind className — [descriptionEmit]
  /// supplies the design-system helper typography role class; the flat
  /// description colour token class is dropped when a flat
  /// `merged.descriptionColor` (`merged.disabledDescriptionColor` while
  /// disabled) or nested `merged.descriptionStyle.color` override is present.
  String buildDescriptionClassName() {
    final hasColorOverride =
        descriptionColorOverride != null ||
        descriptionStyleOverride?.color != null;
    return <String>[
      descriptionEmit.className,
      if (!hasColorOverride) 'text-${descriptionColor.tailwindColor}',
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the description `<div>` inline-CSS bundle — the
  /// [descriptionEmit] overlay (explicit font / weight / nested
  /// `descriptionStyle.color`) plus the resolved flat `descriptionColor`
  /// (only when it is overridden and the nested colour is unset).
  Styles? buildDescriptionInlineStyles() {
    final raw = <String, String>{...?descriptionEmit.inline};
    if (descriptionColorOverride != null &&
        descriptionStyleOverride?.color == null) {
      raw['color'] = descriptionColor.toValue();
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the error `<div>` Tailwind className — [errorEmit] supplies
  /// the design-system helper typography role class; the flat error
  /// colour token class is dropped when a flat `merged.errorColor` or
  /// nested `merged.errorStyle.color` override is present.
  String buildErrorClassName() {
    final hasColorOverride =
        errorColorOverride != null || errorStyleOverride?.color != null;
    return <String>[
      errorEmit.className,
      if (!hasColorOverride) 'text-${errorColor.tailwindColor}',
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the error `<div>` inline-CSS bundle — the [errorEmit]
  /// overlay (explicit font / weight / nested `errorStyle.color`) plus
  /// the resolved flat `errorColor` (only when it is overridden and the
  /// nested colour is unset).
  Styles? buildErrorInlineStyles() {
    final raw = <String, String>{...?errorEmit.inline};
    if (errorColorOverride != null && errorStyleOverride?.color == null) {
      raw['color'] = errorColor.toValue();
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDatePicker(
    root: WebElementChrome(
      className: buildRootClassName(),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
    triggerStyle: triggerStyle,
    trailingIconStyle: trailingIconStyle,
    dialogContentWrap: WebElementChrome(
      className: buildDialogContentWrapClassName(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    error: WebElementChrome(
      className: buildErrorClassName(),
      inlineStyles: buildErrorInlineStyles(),
    ),
    popoverStyle: popoverStyle,
    dialogStyle: dialogStyle,
    calendarStyle: calendarStyle,
    labelBottomGapStyle: labelBottomGapStyle,
    descriptionTopGapStyle: descriptionTopGapStyle,
  );
}
