import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/debug_warn.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform chip for CoUI Web with token-based rendering.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [chipStyle] (a [CoreChipStyle]). The
/// semantic enums (`chipColor` / `variant` / `emphasis` / `size` /
/// `shape` / `selected` / `enabled`) and behaviour fields stay flat on the
/// component.
///
/// ```text
/// design system default for chip (size row → shape row)
///   → CoreChipTheme.style
///   → CoreChipTheme.colorStyles[chipColor]
///   → CoreChipTheme.variantStyles[variant]
///   → parent component slot override
///   → component.chipStyle
/// ```
///
/// Example:
/// ```dart
/// Chip(
///   label: 'Flutter',
///   chipColor: CoreChipColor.primary,
///   selected: true,
///   onTap: () => toggle(),
/// )
/// ```
///
/// surface:content — an in-flow chip: what shows through it (when it
/// carries no fill) is whatever it is laid on, not a parent panel.
class Chip extends UiComponent implements CoreChipContract<Component> {
  /// Creates a [Chip].
  ///
  /// Chip took only `key` and `id`, so a caller could not attach a CSS
  /// class, an inline style, an `aria-label`, or a `data-*` hook to it —
  /// no styling seam, no scroll/analytics hooks, no accessible name on a
  /// decorative chip. The only way out was to wrap it and target
  /// `.wrapper > div`, which couples the caller to this component's
  /// internal DOM shape. Card / Button / Divider have carried the full
  /// set all along; this brings Chip in line.
  Chip({
    super.key,
    this.prefixLabel,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.child,
    this.chipColor = CoreChipColor.defaultColor,
    this.variant = CoreChipVariant.defaultVariant,
    this.emphasis = CoreChipEmphasis.defaultEmphasis,
    this.selected = false,
    this.enabled = true,
    this.size = CoreChipSize.defaultSize,
    this.shape = CoreChipShape.defaultShape,
    this.leading,
    this.trailing,
    this.onTap,
    this.onRemove,
    this.seedColor,
    this.maxLength,
    this.chipStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final bool selected;

  @override
  final bool enabled;

  @override
  final CoreVoidCallback? onTap;

  @override
  final CoreVoidCallback? onRemove;

  @override
  final String? prefixLabel;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final CoreChipColor chipColor;

  @override
  final CoreChipVariant variant;

  @override
  final CoreChipEmphasis emphasis;

  @override
  final CoreChipSize size;

  /// The outline — [CoreChipShape.rounded] (the size row's corner, the
  /// default) or [CoreChipShape.pill] (half-circle ends on every size). A
  /// `chipStyle.borderRadius` wins over both.
  @override
  final CoreChipShape shape;

  @override
  final CoreColor? seedColor;

  @override
  final int? maxLength;

  /// Per-instance composite style. See [CoreChipStyle] for the merge
  /// chain.
  @override
  final CoreChipStyle? chipStyle;

  @override
  Chip copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? prefixLabel,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    Component? child,
    CoreChipColor? chipColor,
    CoreChipVariant? variant,
    CoreChipEmphasis? emphasis,
    bool? selected,
    bool? enabled,
    CoreChipSize? size,
    CoreChipShape? shape,
    Component? leading,
    Component? trailing,
    CoreVoidCallback? onTap,
    CoreVoidCallback? onRemove,
    CoreColor? seedColor,
    int? maxLength,
    CoreChipStyle? chipStyle,
  }) {
    return Chip(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      prefixLabel: prefixLabel ?? this.prefixLabel,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      chipColor: chipColor ?? this.chipColor,
      variant: variant ?? this.variant,
      emphasis: emphasis ?? this.emphasis,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      onRemove: onRemove ?? this.onRemove,
      seedColor: seedColor ?? this.seedColor,
      maxLength: maxLength ?? this.maxLength,
      chipStyle: chipStyle ?? this.chipStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    if (!enabled) {
      attributes.add('aria-disabled', 'true');
    }
  }

  @override
  Component build(BuildContext context) {
    // `filled` + `low` still renders; it is a poor pair, not an illegal one,
    // so debug builds report it rather than throw. Absent from release.
    assert(() {
      if (variant == .filled &&
          emphasis == .low &&
          (selected || onTap != null)) {
        debugWarn(CoreChipContract.filledLowEmphasisReport);
      }
      return true;
    }(), 'debug-only report; never fails');

    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 옵션 B — `WebResolvedChrome` contract). `co_*` reads the
    // paint-ready strings directly without invoking any builder helpers.
    final resolved = resolveChip(
      context,
      chipColor: chipColor,
      variant: variant,
      emphasis: emphasis,
      size: size,
      selected: selected,
      enabled: enabled,
      shape: shape,
      seedColor: seedColor,
      chipStyle: chipStyle,
      labelMaxLines: labelMaxLines,
      labelOverflow: labelOverflow,
    );
    // The state layer is a blend, so — like NavigationBar/TextField — it
    // rides scoped rules rather than a preset utility class. Re-walks the
    // same merge chain `resolveChip` just did; empty on `!enabled` (a
    // disabled chip's rest chrome IS its disabled chrome, nothing to
    // wash toward).
    final stateLayerRules = resolveChipRules(
      context,
      chipColor: chipColor,
      variant: variant,
      size: size,
      selected: selected,
      emphasis: emphasis,
      enabled: enabled,
      shape: shape,
      seedColor: seedColor,
      chipStyle: chipStyle,
    );

    // Build label — truncate at `maxLength` for ellipsis behaviour.
    final String? displayLabel;
    if (label != null && maxLength != null && label!.length > maxLength!) {
      displayLabel = '${label!.substring(0, maxLength)}...';
    } else {
      displayLabel = label;
    }

    // Build close button via the unified Button (variant: ghost) so
    // hover / focus / disabled states are handled by the design-system
    // component instead of a hand-rolled <button>. The nested
    // closeButtonStyle + closeIconStyle slots flow into the child
    // widgets directly — no theme reads here.
    final Component? closeBtn;
    if (onRemove != null && enabled) {
      final l10n = CouiLocalizations.of(context);
      // Named, because the glyph carries no text of its own — see the
      // Flutter twin. Read at build time so it follows the active locale.
      closeBtn = Button(
        onPressed: onRemove,
        variant: .ghost,
        size: .sm,
        buttonStyle: resolved.closeButtonStyle,
        // The reach floor rides the close button only when the chip
        // itself carries none. A tappable chip's `Clickable` already
        // holds the one marker, and a second full-bleed one here would
        // sit inside the chip's own hit area (#3705). A display-only chip
        // — every chip a `ChipInput` renders — has no `Clickable` and so
        // no marker at all, yet its remove button is still a pointer
        // target that `ChipInput` overrides down to 16.
        classes: onTap == null ? kWebTouchTargetMarker : null,
        attributes: {
          'aria-label': l10n.chipRemoveLabel(
            CoreChipContract.accessibleName(
              prefixLabel: prefixLabel,
              label: label,
            ),
          ),
        },
        child: Icon(
          LucideIcons.x,
          iconStyle: resolved.closeIconStyle,
        ),
      );
    } else {
      closeBtn = null;
    }

    // Single nested `CoreGapStyle` slot — rendered as an explicit
    // `Gap` between every adjacent sibling pair inside the chip, so
    // the per-side horizontal spacing flows through the nested slot
    // (matching the Flutter widget). `Gap` runs its own resolve /
    // scaling step.
    final gap = Gap(gapStyle: resolved.iconLabelGapStyle);

    // Both `null` leaves the clamp to the resolver's `truncate` utility —
    // the shape this component has always drawn. Once the caller states
    // either half, the other half falls back to the same contract default
    // the Flutter twin reads, so `labelOverflow: .clip` alone still clamps
    // to one line on both platforms.
    final clampStated = labelMaxLines != null || labelOverflow != null;
    final labelComponent =
        child ??
        (displayLabel != null
            ? span(
                [
                  Text(
                    displayLabel,
                    maxLines: clampStated
                        ? labelMaxLines ?? CoreChipContract.defaultLabelMaxLines
                        : null,
                    overflow: clampStated
                        ? labelOverflow ?? CoreChipContract.defaultLabelOverflow
                        : null,
                  ),
                ],
                classes: resolved.label.className,
                styles: resolved.label.inlineStyles,
              )
            : null);

    final interactive = onTap != null;

    // Sibling layout — mirrors the Flutter widget exactly:
    //   if leading: [leading, gap]
    //   if prefixLabel: [prefixLabel, (gap if labelComponent)]
    //   if labelComponent: [labelComponent]
    //   if trailing: [gap, trailing]
    //   if closeBtn: [gap, closeBtn]
    final children = <Component>[
      // `<style>` is `display: none` — never joins the pill's flex row.
      // Only the interactive branch below wears the scope class the
      // selectors inside target, so a display-only chip renders this
      // (harmlessly) inert.
      if (interactive && stateLayerRules.css.isNotEmpty)
        Component.element(
          tag: 'style',
          children: [RawText(stateLayerRules.css)],
        ),
      if (leading != null) ...[
        span(
          [
            // Nearest `IconTheme` so the size row's leading glyph size
            // outranks the app-root ambient one — the wrapper span's CSS
            // reaches an `Icon` only through inheritance, which the Dart
            // channel silently outranks (mirrors the Flutter twin's
            // `IconTheme` around the leading slot). Emits no DOM.
            IconTheme(
              data: IconThemeData.fromCoreIconStyle(resolved.leadingIconStyle),
              child: leading!,
            ),
          ],
          classes: resolved.leading.className,
        ),
        gap,
      ],
      // The key holds its width and its single line; the label is the half
      // that truncates. Separated by the same gap as the icons.
      if (prefixLabel != null) ...[
        span(
          [Text(prefixLabel!)],
          classes: resolved.prefixLabel.className,
          styles: resolved.prefixLabel.inlineStyles,
        ),
        if (labelComponent != null) gap,
      ],
      ?labelComponent,
      if (trailing != null) ...[
        gap,
        span(
          [
            // The trailing slot takes the same nearest `IconTheme`.
            IconTheme(
              data: IconThemeData.fromCoreIconStyle(
                resolved.trailingIconStyle,
              ),
              child: trailing!,
            ),
          ],
          classes: resolved.trailing.className,
        ),
      ],
      if (closeBtn != null) ...[
        gap,
        span(
          [closeBtn],
          classes: resolved.closeButton.className,
        ),
      ],
    ];

    // Display-only chip (`onTap == null`, e.g. inside a chip input) —
    // plain container, no role="button" / tabindex pollution. Identity
    // attributes (id / aria-disabled) stay on the chip root; when the
    // chip is tappable they move to the composing Clickable root below
    // instead (checkbox pilot passthrough pattern).
    final chipBody = Component.element(
      tag: 'div',
      id: interactive ? null : id,
      // `kChipBodyMarker` unconditionally — inert without the scoped
      // rules above, and only the interactive branch below ever pairs
      // it with a scope class + `<style>` block. Keeping it stable
      // rather than gating avoids two shapes of this element.
      classes: [
        resolved.root.className,
        kChipBodyMarker,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: interactive ? null : componentAttributes,
      events: interactive ? null : events,
      children: children,
    );

    if (!interactive) {
      return chipBody;
    }

    // Web twin of the Flutter chip: the composed Clickable owns tap /
    // keyboard activation / cursor / focus ring / press feedback. The
    // chip paints its own disabled tokens, so the nested clickableStyle
    // slot keeps the Clickable's generic disabled fade off.
    return Clickable(
      onPressed: enabled ? onTap : null,
      attributes: componentAttributes,
      // Every size row is at least 28 tall, above the 24 pointer
      // minimum, so the marker's floor widens nothing on the default
      // rows. It reaches a chip narrower than 24 (a one-character `sm`
      // label) or one whose caller states a lower `minHeight`. The
      // marker rides the `Clickable` rather than the chip body because
      // only this branch is tappable — a display-only chip that carried
      // it would capture pointers around itself and do nothing with them,
      // which is worse than being small.
      //
      // The state-layer scope class rides here too, not on `chipBody` —
      // `:hover` / `:focus-visible` / `:active` land on the actually
      // focusable/pressable element, which IS this Clickable root, not
      // the plain nested `<div>` `chipBody` renders as. The scoped rules
      // reach `chipBody` with a `>` child combinator (`.scope:hover >
      // .co-chip-body{...}`).
      classes: [
        kWebTouchTargetMarker,
        if (stateLayerRules.scopeClass.isNotEmpty) stateLayerRules.scopeClass,
      ].join(' '),
      id: id,
      enabled: enabled,
      clickableStyle: resolved.clickableStyle,
      child: chipBody,
    );
  }
}

/// Chain sugar mirroring the Flutter `Chip.withStyle` extension —
/// merges a [CoreChipStyle] patch into [Chip.chipStyle] via the
/// existing [Chip.copyWith]. Composition slots (`child` / `leading` /
/// `trailing`) keep using the `Text(...).bodyMedium...` chain directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChipStyle.merge` right-side-wins semantics).
///
/// `.primary`, `.outline` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension ChipStyleChain on Chip {
  /// Sets the content padding.
  Chip contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreChipStyle(padding: value));

  /// Sets the border color.
  Chip borderColor(CoreColor value) =>
      withStyle(CoreChipStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Chip borderWidth(double value) =>
      withStyle(CoreChipStyle(borderWidth: value));

  /// Sets the content foreground color.
  Chip foregroundColor(CoreColor value) =>
      withStyle(CoreChipStyle(foregroundColor: value));

  /// Sets the background paint and preserves the other style fields.
  Chip backgroundColor(CoreColor value) =>
      withStyle(CoreChipStyle(backgroundColor: value));

  /// Returns a copy of this [Chip] with [patch] merged into
  /// [chipStyle] (patch fields win on conflict).
  Chip withStyle(CoreChipStyle patch) =>
      copyWith(chipStyle: (chipStyle ?? const CoreChipStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Chip get radius0 =>
      withStyle(const CoreChipStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Chip get radius2 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Chip get radius4 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Chip get radius6 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Chip get radius8 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Chip get radius10 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Chip get radius12 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Chip get radius14 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Chip get radius16 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Chip get radius20 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Chip get radius24 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Chip get radius28 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Chip get radius32 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Chip get radius36 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Chip get radius40 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Chip get radius48 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Chip get radius56 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Chip get radius64 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Chip get radius9999 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// Selects `chipColor: .primary` using the component theme.
  Chip get primary => copyWith(chipColor: .primary);

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ///
  /// A background-colour token for this one instance — not a
  /// [CoreChipColor] value (that enum has `neutral` and `primary`).
  Chip get secondary => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.secondary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ///
  /// A background-colour token for this one instance — not a
  /// [CoreChipColor] value (that enum has `neutral` and `primary`).
  Chip get tertiary => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Chip get surface => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Chip get surfaceContainer => withStyle(
    const CoreChipStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Chip get error => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Chip get success => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Chip get warning => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Chip get info => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// Selects `variant: .outlined` using the component theme.
  Chip get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  Chip get transparent =>
      withStyle(const CoreChipStyle(backgroundColor: .transparent));
}
