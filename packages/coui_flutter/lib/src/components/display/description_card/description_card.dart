import 'package:coui_flutter/coui_flutter.dart';

/// Flutter row data alias — `CoreDescriptionRow<Widget>`.
typedef DescriptionRow = CoreDescriptionRow<Widget>;

/// 레이블-값 쌍을 동적으로 나열하는 메타데이터 카드 컴포넌트.
///
/// Web `DescriptionCard` 와 동일한 API/렌더링.
///
/// ```dart
/// DescriptionCard(
///   title: '주문 상세',
///   variant: CoreDescriptionCardVariant.outlined,
///   rows: [
///     DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
///     DescriptionRow(label: '결제금액', value: '₩369,000', isEmphasized: true),
///   ],
///   descriptionCardStyle: CoreDescriptionCardStyle(
///     padding: EdgeInsets.all(24),
///   ),
/// )
/// ```
///
/// surface:behind — draws its own box rather than composing `Card`, so what
/// shows through it is the page it is laid on.
///
/// surface:content — draws its own box in the page flow, the same layer
/// `Card` sits on.
class DescriptionCard extends StatelessWidget
    implements CoreDescriptionCardContract<Widget> {
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
  });

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
  final Widget? titleLeading;

  @override
  final Widget? titleTrailing;

  @override
  final bool showDivider;

  @override
  final bool showRowDividers;

  @override
  final Widget? bottomAction;

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

  /// Returns a copy of this [DescriptionCard] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  DescriptionCard copyWith({
    Key? key,
    void Function()? onTap,
    bool? enabled,
    List<DescriptionRow>? rows,
    CoreDescriptionCardSize? size,
    CoreDescriptionCardLayout? layout,
    CoreDescriptionCardVariant? variant,
    String? title,
    Widget? titleLeading,
    Widget? titleTrailing,
    bool? showDivider,
    bool? showRowDividers,
    Widget? bottomAction,
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
    );
  }

  Widget _buildTitleSection({
    required ResolvedDescriptionCard resolved,
    required TextStyle titleStyle,
  }) {
    return Row(
      children: [
        if (titleLeading != null) ...[
          IconTheme.merge(
            data: resolved.titleLeadingIconTheme,
            child: titleLeading!,
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
        ],
        Expanded(
          child: Text(
            title!,
            style: titleStyle,
            overflow: .ellipsis,
          ),
        ),
        if (titleTrailing != null) ...[
          Gap(gapStyle: resolved.iconLabelGapStyle),
          titleTrailing!,
        ],
      ],
    );
  }

  Widget _buildRows({
    required ResolvedDescriptionCard resolved,
    required TextStyle labelValueStyle,
    required Color labelWeightColor,
    required Color valueWeightColor,
    required CoreColor? dividerColorOverride,
    required CoreTextStyle? labelTextStyle,
    required CoreTextStyle? valueTextStyle,
    required CoreTextStyle? emphasizedLabelTextStyle,
    required CoreTextStyle? emphasizedValueTextStyle,
    required CoreColorScheme scheme,
    required bool interactive,
  }) {
    final visibleRows = rows
        .where(
          (row) =>
              row.value != null ||
              row.valueWidget != null ||
              emptyValueBehavior != .hide,
        )
        .toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: resolved.rowSpacing,
      children: [
        for (var i = 0; i < visibleRows.length; i += 1) ...[
          _buildSingleRow(
            row: visibleRows[i],
            resolved: resolved,
            labelValueStyle: labelValueStyle,
            labelWeightColor: labelWeightColor,
            valueWeightColor: valueWeightColor,
            labelTextStyle: labelTextStyle,
            valueTextStyle: valueTextStyle,
            emphasizedLabelTextStyle: emphasizedLabelTextStyle,
            emphasizedValueTextStyle: emphasizedValueTextStyle,
            scheme: scheme,
            interactive: interactive,
          ),
          if (showRowDividers && i < visibleRows.length - 1)
            Divider(
              dividerStyle: CoreDividerStyle(color: dividerColorOverride),
            ),
        ],
      ],
    );
  }

  Widget _buildSingleRow({
    required DescriptionRow row,
    required ResolvedDescriptionCard resolved,
    required TextStyle labelValueStyle,
    required Color labelWeightColor,
    required Color valueWeightColor,
    required CoreTextStyle? labelTextStyle,
    required CoreTextStyle? valueTextStyle,
    required CoreTextStyle? emphasizedLabelTextStyle,
    required CoreTextStyle? emphasizedValueTextStyle,
    required CoreColorScheme scheme,
    required bool interactive,
  }) {
    final isNull = row.value == null && row.valueWidget == null;

    // Layered slot resolve:
    //   typography base
    //     ← default label/value text slot (resolved style)
    //     ← emphasised label/value text slot (when row.isEmphasized)
    //     ← per-row labelTextStyle / valueTextStyle override
    //
    // `isEmphasized: true` 만으로도 기본 bold 효과를 자동 적용한다.
    // emphasised slot 은 사용자가 색상/굵기를 커스터마이징할 때 쓰는 옵션.
    final baseLabelStyle = labelValueStyle.copyWith(color: labelWeightColor);
    final baseValueStyle = labelValueStyle.copyWith(color: valueWeightColor);

    var labelStyle = applyCoreTextStyle(baseLabelStyle, labelTextStyle, scheme);
    var valueStyle = applyCoreTextStyle(baseValueStyle, valueTextStyle, scheme);

    if (row.isEmphasized) {
      labelStyle = applyCoreTextStyle(
        labelStyle,
        emphasizedLabelTextStyle,
        scheme,
      );
      // Auto bold for emphasis when no explicit slot weight is set.
      final emphasisHasWeight =
          emphasizedValueTextStyle?.fontWeight != null ||
          row.valueTextStyle?.fontWeight != null;
      valueStyle = applyCoreTextStyle(
        valueStyle,
        emphasizedValueTextStyle,
        scheme,
      );
      if (!emphasisHasWeight && !isNull) {
        valueStyle = valueStyle.copyWith(
          fontWeight: fontWeightFromInt(CoreFontWeight.bold),
        );
      }
    }

    labelStyle = applyCoreTextStyle(labelStyle, row.labelTextStyle, scheme);
    valueStyle = applyCoreTextStyle(valueStyle, row.valueTextStyle, scheme);

    if (isNull) {
      valueStyle = valueStyle.copyWith(
        color: labelWeightColor.scaleAlpha(CoreOpacity.opacity40),
      );
    }

    final valueContent =
        row.valueWidget ??
        Text(
          isNull ? emptyPlaceholder : row.value!,
          style: valueStyle,
          textAlign: layout == .vertical ? null : resolved.valueTextAlign,
          softWrap: valueOverflow == .wrap,
          overflow: valueOverflow == .ellipsis ? .ellipsis : null,
        );

    final labelWidget = Text(row.label, style: labelStyle);

    final Widget rowContent;
    if (layout == .vertical) {
      rowContent = Row(
        crossAxisAlignment: .start,
        children: [
          if (row.leading != null) ...[
            row.leading!,
            Gap(gapStyle: resolved.rowLeadingGapStyle),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                labelWidget,
                Gap(gapStyle: resolved.labelValueGapStyle),
                valueContent,
              ],
            ),
          ),
          if (row.trailing != null) ...[
            Gap(gapStyle: resolved.iconLabelGapStyle),
            row.trailing!,
          ],
        ],
      );
    } else if (alignment == .spaceBetween) {
      rowContent = Row(
        children: [
          if (row.leading != null) ...[
            row.leading!,
            Gap(gapStyle: resolved.iconLabelGapStyle),
          ],
          labelWidget,
          const Spacer(),
          Gap(gapStyle: resolved.columnGapStyle),
          valueContent,
          if (row.trailing != null) ...[
            Gap(gapStyle: resolved.iconLabelGapStyle),
            row.trailing!,
          ],
        ],
      );
    } else {
      rowContent = Row(
        children: [
          if (row.leading != null) ...[
            row.leading!,
            Gap(gapStyle: resolved.iconLabelGapStyle),
          ],
          labelWidget,
          Gap(gapStyle: resolved.columnGapStyle),
          Expanded(child: valueContent),
          if (row.trailing != null) ...[
            Gap(gapStyle: resolved.iconLabelGapStyle),
            row.trailing!,
          ],
        ],
      );
    }

    final paddedRow = Padding(
      padding: resolved.rowPadding,
      child: rowContent,
    );

    final rowOnTap = row.onTap;
    if (rowOnTap != null) {
      // Composed Clickable owns tap / keyboard activation / cursor /
      // focus ring; press shrink is off (wide row) via the nested
      // clickableStyle default.
      return Clickable(
        onPressed: rowOnTap,
        enabled: interactive,
        clickableStyle: resolved.clickableStyle,
        child: paddedRow,
      );
    }
    return paddedRow;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final resolved = resolveDescriptionCard(
      context,
      variant: variant,
      size: size,
      descriptionCardStyle: descriptionCardStyle,
    );
    // Base typography is resolved paint-ready by the resolver: the
    // title slot carries the resolved title colour (per-instance
    // override → `defaultTitleColor`, Core single source — same token
    // Web stringifies into `text-on-surface`); the label/value base
    // is colourless so the per-`rowWeight` colours apply below.
    final titleStyle = resolved.titleTextStyle;
    final labelValueStyle = resolved.labelValueTextStyle;

    // Resolve label / value colours from the Core single-source map
    // (`kCoreDescriptionCardRowWeightColors`). Same `CoreColor` tokens
    // the Web side stringifies into `text-<token>` Tailwind classes.
    final rowColors = kCoreDescriptionCardRowWeightColors[rowWeight]!;
    final defaultLabelColor = colors.resolve(rowColors.labelColor).toValue();
    final defaultValueColor = colors.resolve(rowColors.valueColor).toValue();

    final hasTapTarget = onTap != null || rows.any((row) => row.onTap != null);
    final interactive = CoreDescriptionCardContract.effectiveEnabled(
      enabled: enabled,
      hasTapTarget: hasTapTarget,
    );
    final dimsContent = CoreDescriptionCardContract.dimsContent(
      enabled: enabled,
      hasTapTarget: hasTapTarget,
    );

    // The content — title, rows and the bottom action region — dims as one
    // column while the card is disabled; the box (background / border)
    // stays at full strength.
    final content = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        if (title != null) ...[
          _buildTitleSection(resolved: resolved, titleStyle: titleStyle),
          Gap(gapStyle: resolved.titleContentGapStyle),
          if (showDivider)
            Divider(
              dividerStyle: CoreDividerStyle(
                color: resolved.dividerColor,
              ),
            ),
          Gap(gapStyle: resolved.titleContentGapStyle),
        ],
        _buildRows(
          resolved: resolved,
          labelValueStyle: labelValueStyle,
          labelWeightColor: defaultLabelColor,
          valueWeightColor: defaultValueColor,
          dividerColorOverride: resolved.dividerColor,
          labelTextStyle: resolved.labelTextStyle,
          valueTextStyle: resolved.valueTextStyle,
          emphasizedLabelTextStyle: resolved.emphasizedLabelTextStyle,
          emphasizedValueTextStyle: resolved.emphasizedValueTextStyle,
          scheme: colors,
          interactive: interactive,
        ),
      ],
    );

    final body = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        content,
        if (bottomAction != null) ...[
          Gap(gapStyle: resolved.titleContentGapStyle),
          if (showBottomActionDivider) ...[
            Divider(
              dividerStyle: CoreDividerStyle(
                color: resolved.dividerColor,
              ),
            ),
            Gap(gapStyle: resolved.titleContentGapStyle),
          ],
          bottomAction!,
        ],
      ],
    );
    final cardContent = dimsContent
        ? Opacity(opacity: resolved.disabledContentOpacity, child: body)
        : body;

    // #4362 — composes the shared `OutlinedContainer` surface primitive
    // instead of hand-drawing a `DecoratedBox`, so the active preset's
    // material / injected rest-cast / forced-colours boundary reach this
    // card the same way they reach `Card`. Padding now flows through
    // `containerStyle.padding` — `OutlinedContainer` applies it itself.
    Widget card = OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: cardContent,
    );

    // Caller-supplied shadow override paints on top of the composed
    // surface's elevation. The resolver finished the `CoreColor → Color`
    // conversion so the widget reads paint-ready `BoxShadow`s (mirrors
    // `Card`'s identical `boxShadowOverride` handling).
    if (resolved.boxShadowOverride != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(boxShadow: resolved.boxShadowOverride),
        child: card,
      );
    }

    final cardOnTap = onTap;
    if (cardOnTap != null) {
      // Composed Clickable owns tap / keyboard activation / cursor /
      // focus ring; press shrink is off (wide card) via the nested
      // clickableStyle default.
      return Clickable(
        onPressed: cardOnTap,
        enabled: interactive,
        clickableStyle: resolved.clickableStyle,
        child: card,
      );
    }
    return card;
  }
}

/// Chain sugar for merging a [CoreDescriptionCardStyle] patch into
/// [DescriptionCard.descriptionCardStyle] without hand-reconstructing
/// every field. Mirrors the Web `DescriptionCard.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDescriptionCardStyle.merge` right-side-wins semantics).
///
/// `.outline` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension DescriptionCardStyleChain on DescriptionCard {
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

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
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
