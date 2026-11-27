import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/description_card/description_card_style.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;

/// Web row data alias — `CoreDescriptionRow<Component>`.
typedef DescriptionRow = CoreDescriptionRow<Component>;

enum _DescriptionCardSlot { rows }

/// 레이블-값 쌍을 동적으로 나열하는 메타데이터 카드 컴포넌트.
///
/// Flutter `DescriptionCard` 와 동일한 API/렌더링.
///
/// surface:behind — draws its own box rather than composing `Card`;
/// the page behind it shows through.
///
/// surface:content — draws its own box in the page flow, the same layer
/// `Card` sits on.
class DescriptionCard extends UiComponent
    implements CoreDescriptionCardContract<Component> {
  /// Creates a [DescriptionCard].
  const DescriptionCard({
    required this.rows,
    super.key,
    this.size = CoreDescriptionCardSize.md,
    this.layout = CoreDescriptionCardLayout.horizontal,
    this.variant = CoreDescriptionCardVariant.outlined,
    this.title,
    this.titleLeading,
    this.titleTrailing,
    this.showDivider = true,
    this.showRowDividers = true,
    this.bottomAction,
    this.showBottomActionDivider = true,
    this.alignment = CoreDescriptionCardAlignment.fixed,
    this.valueOverflow = CoreDescriptionCardOverflow.wrap,
    this.rowWeight = CoreDescriptionCardRowWeight.valueProminent,
    this.emptyValueBehavior = CoreDescriptionCardEmptyBehavior.hide,
    this.emptyPlaceholder = '-',
    this.onTap,
    this.enabled,
    this.descriptionCardStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<DescriptionRow> rows;

  @override
  final CoreDescriptionCardSize size;

  @override
  final CoreDescriptionCardLayout layout;

  @override
  final CoreDescriptionCardVariant variant;

  @override
  final String? title;

  @override
  final Component? titleLeading;

  @override
  final Component? titleTrailing;

  @override
  final bool showDivider;

  @override
  final bool showRowDividers;

  @override
  final Component? bottomAction;

  @override
  final bool showBottomActionDivider;

  @override
  final CoreDescriptionCardAlignment alignment;

  @override
  final CoreDescriptionCardOverflow valueOverflow;

  @override
  final CoreDescriptionCardRowWeight rowWeight;

  @override
  final CoreDescriptionCardEmptyBehavior emptyValueBehavior;

  @override
  final String emptyPlaceholder;

  @override
  final void Function()? onTap;

  @override
  final bool? enabled;

  @override
  final CoreDescriptionCardStyle? descriptionCardStyle;

  @override
  DescriptionCard copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    void Function()? onTap,
    bool? enabled,
    List<DescriptionRow>? rows,
    CoreDescriptionCardSize? size,
    CoreDescriptionCardLayout? layout,
    CoreDescriptionCardVariant? variant,
    String? title,
    Component? titleLeading,
    Component? titleTrailing,
    bool? showDivider,
    bool? showRowDividers,
    Component? bottomAction,
    bool? showBottomActionDivider,
    CoreDescriptionCardAlignment? alignment,
    CoreDescriptionCardOverflow? valueOverflow,
    CoreDescriptionCardRowWeight? rowWeight,
    CoreDescriptionCardEmptyBehavior? emptyValueBehavior,
    String? emptyPlaceholder,
    CoreDescriptionCardStyle? descriptionCardStyle,
  }) {
    return DescriptionCard(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      enabled: enabled ?? this.enabled,
      rows: rows ?? this.rows,
      size: size ?? this.size,
      layout: layout ?? this.layout,
      variant: variant ?? this.variant,
      title: title ?? this.title,
      titleLeading: titleLeading ?? this.titleLeading,
      titleTrailing: titleTrailing ?? this.titleTrailing,
      showDivider: showDivider ?? this.showDivider,
      showRowDividers: showRowDividers ?? this.showRowDividers,
      bottomAction: bottomAction ?? this.bottomAction,
      showBottomActionDivider:
          showBottomActionDivider ?? this.showBottomActionDivider,
      alignment: alignment ?? this.alignment,
      valueOverflow: valueOverflow ?? this.valueOverflow,
      rowWeight: rowWeight ?? this.rowWeight,
      emptyValueBehavior: emptyValueBehavior ?? this.emptyValueBehavior,
      emptyPlaceholder: emptyPlaceholder ?? this.emptyPlaceholder,
      descriptionCardStyle: descriptionCardStyle ?? this.descriptionCardStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveDescriptionCard(
      context,
      variant: variant,
      size: size,
      descriptionCardStyle: descriptionCardStyle,
    );
    final visibleRows = rows
        .where(
          (row) =>
              row.value != null ||
              row.valueWidget != null ||
              emptyValueBehavior != .hide,
        )
        .toList();

    final interactive = onTap != null;
    final hasTapTarget = onTap != null || rows.any((row) => row.onTap != null);
    final enabledNow = CoreDescriptionCardContract.effectiveEnabled(
      enabled: enabled,
      hasTapTarget: hasTapTarget,
    );
    final contentChrome =
        CoreDescriptionCardContract.dimsContent(
          enabled: enabled,
          hasTapTarget: hasTapTarget,
        )
        ? resolved.disabledContent
        : resolved.content;

    // Card content — title / rows / bottom-action, arranged in a flex
    // column with the inter-slot gaps below. Width comes from the
    // composed `OutlinedContainer` (a block-level child fills it by
    // default), so only the vertical arrangement lives here. A disabled card
    // dims this whole column — title, rows and the bottom action region —
    // and the box keeps its full strength.
    final content = Component.element(
      tag: 'div',
      classes: resolved.content.className,
      children: [
        if (title != null) ...[
          _buildTitle(resolved),
          Gap(gapStyle: resolved.titleContentGapStyle),
          if (showDivider) _buildDivider(resolved),
          Gap(gapStyle: resolved.titleContentGapStyle),
        ],
        Component.element(
          // Keep caller rows distinct from the optional title's div.
          key: const ValueKey(_DescriptionCardSlot.rows),
          tag: 'div',
          classes: resolved.rows.className,
          styles: resolved.rows.inlineStyles,
          children: [
            for (var i = 0; i < visibleRows.length; i += 1) ...[
              _buildRow(
                context,
                visibleRows[i],
                resolved,
                enabled: enabledNow,
              ),
              if (i < visibleRows.length - 1 && showRowDividers)
                _buildDivider(resolved),
            ],
          ],
        ),
      ],
    );

    final cardContent = Component.element(
      tag: 'div',
      classes: contentChrome.className,
      styles: contentChrome.inlineStyles,
      children: [
        content,
        if (bottomAction != null) ...[
          Gap(gapStyle: resolved.titleContentGapStyle),
          if (showBottomActionDivider) ...[
            _buildDivider(resolved),
            Gap(gapStyle: resolved.titleContentGapStyle),
          ],
          bottomAction!,
        ],
      ],
    );

    // #4362 — composes the shared `OutlinedContainer` surface primitive
    // instead of hand-drawing the card's fill / border / radius / shadow
    // / material, so the active preset reaches this card the same way it
    // reaches `Card`. When the card is tappable the composing `Clickable`
    // owns the caller chrome passthrough (id / classes / css /
    // attributes / events) and the surface keeps only its own resolved
    // [CoreOutlinedContainerStyle]; otherwise the surface carries the
    // passthrough itself (mirrors the previous `cardBody` split).
    Component card = OutlinedContainer(
      containerStyle: resolved.containerStyle,
      id: interactive ? null : id,
      classes: resolved.root.className,
      css: interactive ? null : css,
      attributes: interactive ? null : componentAttributes,
      eventHandlers: interactive ? null : eventHandlers,
      child: cardContent,
    );

    // Caller-supplied shadow override paints on top of the composed
    // surface's elevation (mirrors the Flutter `boxShadowOverride`
    // handling and `Card`'s identical pattern).
    final boxShadowOverride = resolved.boxShadowOverride;
    if (boxShadowOverride != null) {
      card = Component.element(
        tag: 'div',
        classes: boxShadowOverride.className,
        styles: boxShadowOverride.inlineStyles,
        children: [card],
      );
    }

    if (!interactive) return card;

    // Web twin of the Flutter card: the composing `Clickable` owns tap /
    // keyboard activation / cursor / focus ring; `role="button"` comes
    // from the Clickable root and caller chrome moves onto it (checkbox
    // pilot).
    return Clickable(
      onPressed: onTap,
      enabled: enabledNow,
      onClick: onClick,
      attributes: componentAttributes,
      classes: classes,
      css: css,
      eventHandlers: eventHandlers,
      id: id,
      onChange: onChange,
      onInput: onInput,
      onKeyDown: onKeyDown,
      onKeyUp: onKeyUp,
      onMouseEnter: onMouseEnter,
      onMouseLeave: onMouseLeave,
      clickableStyle: resolved.clickableStyle,
      child: card,
    );
  }

  Component _buildTitle(ResolvedDescriptionCard resolved) {
    return Component.element(
      tag: 'div',
      classes: resolved.title.className,
      styles: resolved.title.inlineStyles,
      children: [
        if (titleLeading != null) ...[
          IconTheme(
            data: IconThemeData.fromCoreIconStyle(
              resolved.titleLeadingIconStyle,
            ),
            child: titleLeading!,
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
        ],
        Component.element(
          tag: 'span',
          classes: resolved.titleText.className,
          styles: resolved.titleText.inlineStyles,
          children: [Text(title!)],
        ),
        if (titleTrailing != null) ...[
          Component.element(
            tag: 'div',
            classes: resolved.titleSpacer.className,
            children: const [],
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
          titleTrailing!,
        ],
      ],
    );
  }

  Component _buildDivider(ResolvedDescriptionCard resolved) {
    // Mirrors the Flutter `Divider(dividerStyle: …)` source-of-truth
    // tree (#1659) — the resolved divider colour flows through the
    // nested [CoreDividerStyle] slot and `Divider` self-resolves the
    // 1px horizontal line.
    return Divider(dividerStyle: resolved.dividerStyle);
  }

  Component _buildRow(
    BuildContext context,
    DescriptionRow row,
    ResolvedDescriptionCard resolved, {
    required bool enabled,
  }) {
    final isEmptyValue = row.value == null && row.valueWidget == null;
    final rowResolved = resolveDescriptionCardRow(
      context,
      row: row,
      size: size,
      layout: layout,
      valueOverflow: valueOverflow,
      rowWeight: rowWeight,
      isEmptyValue: isEmptyValue,
      descriptionCardStyle: descriptionCardStyle,
    );
    final displayValue = isEmptyValue ? emptyPlaceholder : (row.value ?? '');

    final labelComp = Component.element(
      tag: 'span',
      classes: rowResolved.label.className,
      styles: rowResolved.label.inlineStyles,
      children: [Text(row.label)],
    );

    final valueComp =
        row.valueWidget ??
        Component.element(
          tag: 'span',
          classes: rowResolved.value.className,
          styles: rowResolved.value.inlineStyles,
          children: [Text(displayValue)],
        );

    final children = <Component>[];
    if (layout == .vertical) {
      children.addAll([
        if (row.leading != null)
          Component.element(
            tag: 'div',
            classes: rowResolved.rowLeadingBlock.className,
            styles: rowResolved.rowLeadingBlock.inlineStyles,
            children: [
              row.leading!,
              Gap(gapStyle: rowResolved.rowLeadingGapStyle),
              labelComp,
            ],
          )
        else
          labelComp,
        Gap(gapStyle: rowResolved.labelValueGapStyle),
        valueComp,
        if (row.trailing != null) ...[
          Gap(gapStyle: rowResolved.iconLabelGapStyle),
          row.trailing!,
        ],
      ]);
    } else if (alignment == .spaceBetween) {
      children.addAll([
        if (row.leading != null) ...[
          row.leading!,
          Gap(gapStyle: rowResolved.iconLabelGapStyle),
        ],
        labelComp,
        Component.element(
          tag: 'div',
          classes: rowResolved.rowSpacer.className,
          children: const [],
        ),
        Gap(gapStyle: rowResolved.columnGapStyle),
        valueComp,
        if (row.trailing != null) ...[
          Gap(gapStyle: rowResolved.iconLabelGapStyle),
          row.trailing!,
        ],
      ]);
    } else {
      children.addAll([
        if (row.leading != null) ...[
          row.leading!,
          Gap(gapStyle: rowResolved.iconLabelGapStyle),
        ],
        labelComp,
        Gap(gapStyle: rowResolved.columnGapStyle),
        // Wrap the value (or custom valueWidget) so it stretches into
        // the row's remaining space. The `flex-1` wrapper carries the
        // same typography class as the value `<span>` so the inner
        // text shares the row's baseline.
        if (row.valueWidget != null)
          Component.element(
            tag: 'div',
            classes: rowResolved.rowValueExpand.className,
            children: [row.valueWidget!],
          )
        else
          Component.element(
            tag: 'div',
            classes: rowResolved.rowValueExpand.className,
            styles: rowResolved.rowValueExpand.inlineStyles,
            children: [Text(displayValue)],
          ),
        if (row.trailing != null) ...[
          Gap(gapStyle: rowResolved.iconLabelGapStyle),
          row.trailing!,
        ],
      ]);
    }

    final rowOnTap = row.onTap;
    final rowBody = Component.element(
      tag: 'div',
      classes: rowResolved.root.className,
      styles: rowResolved.root.inlineStyles,
      children: children,
    );

    if (rowOnTap == null) return rowBody;

    // Web twin of the Flutter row: the composing `Clickable` owns tap /
    // keyboard activation / cursor / focus ring; `role="button"` comes
    // from the Clickable root.
    return Clickable(
      onPressed: rowOnTap,
      enabled: enabled,
      clickableStyle: resolved.clickableStyle,
      child: rowBody,
    );
  }
}

/// Chain sugar mirroring the Flutter `DescriptionCard.withStyle`
/// extension — merges a [CoreDescriptionCardStyle] patch into
/// [DescriptionCard.descriptionCardStyle] via the existing
/// [DescriptionCard.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDescriptionCardStyle.merge` right-side-wins semantics).
///
/// `.outline` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension DescriptionCardStyleChain on DescriptionCard {
  /// Sets the content padding.
  DescriptionCard contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreDescriptionCardStyle(padding: value));

  /// Sets the border color.
  DescriptionCard borderColor(CoreColor value) =>
      withStyle(CoreDescriptionCardStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  DescriptionCard borderWidth(double value) =>
      withStyle(CoreDescriptionCardStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  DescriptionCard backgroundColor(CoreColor value) =>
      withStyle(CoreDescriptionCardStyle(backgroundColor: value));

  /// Returns a copy of this [DescriptionCard] with [patch] merged into
  /// [descriptionCardStyle] (patch fields win on conflict).
  DescriptionCard withStyle(CoreDescriptionCardStyle patch) => copyWith(
    descriptionCardStyle:
        (descriptionCardStyle ?? const CoreDescriptionCardStyle()).merge(
          patch,
        ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  DescriptionCard get radius0 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  DescriptionCard get radius2 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  DescriptionCard get radius4 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  DescriptionCard get radius6 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  DescriptionCard get radius8 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  DescriptionCard get radius10 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  DescriptionCard get radius12 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  DescriptionCard get radius14 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  DescriptionCard get radius16 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  DescriptionCard get radius20 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  DescriptionCard get radius24 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  DescriptionCard get radius28 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  DescriptionCard get radius32 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  DescriptionCard get radius36 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  DescriptionCard get radius40 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  DescriptionCard get radius48 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  DescriptionCard get radius56 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  DescriptionCard get radius64 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  DescriptionCard get radius9999 => withStyle(
    const CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  DescriptionCard get primary => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  DescriptionCard get secondary => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  DescriptionCard get tertiary => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  DescriptionCard get surface => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  DescriptionCard get surfaceContainer => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  DescriptionCard get error => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  DescriptionCard get success => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  DescriptionCard get warning => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  DescriptionCard get info => withStyle(
    const CoreDescriptionCardStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// Selects `variant: .outlined` using the component theme.
  DescriptionCard get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  DescriptionCard get transparent => withStyle(
    const CoreDescriptionCardStyle(backgroundColor: .transparent),
  );
}
