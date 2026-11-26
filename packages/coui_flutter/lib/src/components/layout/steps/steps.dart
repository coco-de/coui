import 'package:coui_flutter/coui_flutter.dart';

/// Unified steps component.
///
/// Renders a sequence of steps, showing progress through a multi-step
/// process — numbered indicators joined by connectors
/// ([CoreStepsVariant.numbered], the default) or a list of [StepItem] rows
/// ([CoreStepsVariant.list]).
///
/// Each item stands where its own `CoreStepData.status` says; an item with
/// none is placed against [currentStep] — before it done, at it current,
/// after it to do (`CoreStepStatus.effective`). A failed step draws a cross
/// on the error fill (numbered) or the `circle-x` row (list).
///
/// Set [vertical] to `false` for a horizontal numbered layout. The list
/// variant is always vertical and ignores [vertical]; it fills its
/// parent's width so each row's trailing note pins to the end, and it does
/// not draw item descriptions.
///
/// ```dart
/// Steps(
///   currentStep: 1,
///   items: [
///     CoreStepData(title: 'Create Account'),
///     CoreStepData(title: 'Verify Email'),
///     CoreStepData(title: 'Complete Profile'),
///   ],
/// )
/// ```
///
/// `Steps` is render-only — every colour / size / gap is pre-resolved
/// by [resolveSteps] into a [ResolvedSteps]; this widget never
/// touches the theme's colour scheme or applies `theme.scaling` itself
/// (Epic #1603 C11).
///
/// surface:content — the indicator circles are badge-form faces that
/// sit in the flow, not something mounted over content.
class Steps extends StatelessWidget implements CoreStepsContract {
  /// Creates a [Steps].
  const Steps({
    required this.items,
    this.currentStep = 0,
    this.vertical = true,
    this.variant = CoreStepsVariant.defaultVariant,
    this.stepsStyle,
    super.key,
  });

  @override
  final List<CoreStepData> items;

  @override
  final int currentStep;

  @override
  final bool vertical;

  @override
  final CoreStepsVariant variant;

  @override
  final CoreStepsStyle? stepsStyle;

  /// Returns a copy of this [Steps] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Steps copyWith({
    Key? key,
    List<CoreStepData>? items,
    int? currentStep,
    bool? vertical,
    CoreStepsVariant? variant,
    CoreStepsStyle? stepsStyle,
  }) {
    return Steps(
      key: key ?? this.key,
      items: items ?? this.items,
      currentStep: currentStep ?? this.currentStep,
      vertical: vertical ?? this.vertical,
      variant: variant ?? this.variant,
      stepsStyle: stepsStyle ?? this.stepsStyle,
    );
  }

  Widget _buildList(ResolvedSteps style, List<CoreStepStatus> statuses) {
    // A list announces itself as one, and every row as an entry of it, so a
    // reader says "3 of 5". The current step is marked `selected` — the
    // Flutter signal for the row the Web twin marks `aria-current="step"`.
    // Each platform's reader words it its own way; only the row is shared.
    return CoUISemantics(
      role: CoreSemanticRole.list,
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          for (int i = 0; i < items.length; i++)
            CoUISemantics(
              role: CoreSemanticRole.listItem,
              container: true,
              selected: statuses[i] == CoreStepStatus.current ? true : null,
              child: StepItem(
                title: items[i].title,
                status: statuses[i],
                trailing: items[i].trailing,
                stepItemStyle: style.stepItemStyle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVertical(ResolvedSteps style, List<CoreStepStatus> statuses) {
    final stepWidgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final status = statuses[i];

      stepWidgets.add(
        IntrinsicHeight(
          child: Row(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Column(
                children: [
                  _buildIndicatorCircle(style, status, i),
                  if (i < items.length - 1) ...[
                    Gap(gapStyle: style.indicatorConnectorGapStyle),
                    Expanded(
                      child: Divider(
                        orientation: .vertical,
                        dividerStyle: status == CoreStepStatus.done
                            ? style.activeConnectorStyle
                            : style.inactiveConnectorStyle,
                      ),
                    ),
                    Gap(gapStyle: style.indicatorConnectorGapStyle),
                  ],
                ],
              ),
              Gap(gapStyle: style.indicatorContentGapStyle),
              Expanded(
                child: Padding(
                  // Non-final steps reserve `style.stepPadding`
                  // (paint-ready `EdgeInsets`, scaling pre-applied); the
                  // last step needs no trailing gap.
                  padding: i < items.length - 1
                      ? style.stepPadding
                      : EdgeInsets.zero,
                  child: _buildContent(style, item, status, .start),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: stepWidgets,
      ),
    );
  }

  Widget _buildHorizontal(ResolvedSteps style, List<CoreStepStatus> statuses) {
    final stepColumns = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final status = statuses[i];

      stepColumns.add(
        Expanded(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  _buildIndicatorCircle(style, status, i),
                  if (i < items.length - 1) ...[
                    Gap(gapStyle: style.indicatorConnectorGapHorizontalStyle),
                    Expanded(
                      child: Divider(
                        dividerStyle: status == CoreStepStatus.done
                            ? style.activeConnectorStyle
                            : style.inactiveConnectorStyle,
                      ),
                    ),
                    Gap(gapStyle: style.indicatorConnectorGapHorizontalStyle),
                  ],
                ],
              ),
              Padding(
                padding: i < items.length - 1
                    ? style.stepPaddingHorizontal
                    : style.lastStepPaddingHorizontal,
                child: _buildContent(style, item, status, .start),
              ),
            ],
          ),
        ),
      );
    }

    return Row(crossAxisAlignment: .start, children: stepColumns);
  }

  Widget _buildIndicatorCircle(
    ResolvedSteps style,
    CoreStepStatus status,
    int index,
  ) {
    // `OutlinedContainer` owns the indicator circle's fill / (full-
    // circle) radius / material — the widget only selects the
    // pre-composed per-state bundle and composes it (Epic #4349).
    final containerStyle = switch (status) {
      CoreStepStatus.done ||
      CoreStepStatus.current => style.activeIndicatorContainerStyle,
      CoreStepStatus.todo => style.inactiveIndicatorContainerStyle,
      CoreStepStatus.failed => style.failedIndicatorContainerStyle,
    };
    // The mark is the status's own (`CoreStepStatus.indicatorGlyph`) — a
    // finished or failed step draws its glyph, the rest keep their number.
    final mark = switch (status) {
      CoreStepStatus.done => Icon(
        status.indicatorGlyph!,
        iconStyle: style.checkIconStyle,
      ),
      CoreStepStatus.failed => Icon(
        status.indicatorGlyph!,
        iconStyle: style.failedIconStyle,
      ),
      CoreStepStatus.current || CoreStepStatus.todo => Text(
        (index + 1).toString(),
        style: style.labelTextStyle.copyWith(
          color: status == CoreStepStatus.current
              ? style.activeLabelColor
              : style.inactiveLabelColor,
        ),
      ),
    };

    return OutlinedContainer(
      containerStyle: containerStyle,
      child: Center(child: mark),
    );
  }

  Widget _buildContent(
    ResolvedSteps style,
    CoreStepData item,
    CoreStepStatus status,
    CrossAxisAlignment align,
  ) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: align,
      children: [
        Text(
          item.title,
          style:
              (status == CoreStepStatus.current
                      ? style.currentTitleTextStyle
                      : style.titleTextStyle)
                  .copyWith(
                    color: status == CoreStepStatus.todo
                        ? style.inactiveTitleColor
                        : style.titleColor,
                  ),
        ),
        if (item.description != null)
          Text(
            item.description!,
            style: style.descriptionTextStyle.copyWith(
              color: style.descriptionColor,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSteps(
      context,
      variant: variant,
      stepsStyle: stepsStyle,
    );
    // Where each item stands — one Core rule for both platforms, so a list
    // that states some statuses and not others reads the same everywhere.
    final statuses = [
      for (int i = 0; i < items.length; i++)
        CoreStepStatus.effective(
          index: i,
          currentStep: currentStep,
          status: items[i].status,
        ),
    ];

    return switch (variant) {
      CoreStepsVariant.list => _buildList(resolved, statuses),
      CoreStepsVariant.numbered =>
        vertical
            ? _buildVertical(resolved, statuses)
            : _buildHorizontal(resolved, statuses),
    };
  }
}

/// Chain sugar for merging a [CoreStepsStyle] patch into
/// [Steps.stepsStyle] without hand-reconstructing every field. Mirrors
/// the Web `Steps.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStepsStyle.merge` right-side-wins semantics).
extension StepsStyleChain on Steps {
  /// Returns a copy of this [Steps] with [patch] merged into
  /// [stepsStyle] (patch fields win on conflict).
  Steps withStyle(CoreStepsStyle patch) =>
      copyWith(stepsStyle: (stepsStyle ?? const CoreStepsStyle()).merge(patch));
}
