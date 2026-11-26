import 'package:coui_web/coui_web.dart' hide css, events;
import 'package:coui_web/src/components/layout/steps/steps_style.dart';

/// Unified steps component for Web.
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
/// surface:content — the indicator circles are badge-form faces that
/// sit in the flow, not something mounted over content.
class Steps extends UiComponent implements CoreStepsContract {
  /// Creates a [Steps].
  const Steps({
    required this.items,
    this.currentStep = 0,
    this.vertical = true,
    this.variant = CoreStepsVariant.defaultVariant,
    this.stepsStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

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

  @override
  Steps copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  /// The list variant announces itself as a list — its rows are marked
  /// as its entries where they are composed. The numbered variant states
  /// no role. Caller attributes still win.
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    if (variant == CoreStepsVariant.list) {
      attributes.addRole(CoreSemanticRole.list.ariaRole);
    }
  }

  @override
  Component build(BuildContext context) {
    // Where each item stands — one Core rule for both platforms, so a list
    // that states some statuses and not others reads the same everywhere.
    final statuses = [
      for (var i = 0; i < items.length; i++)
        CoreStepStatus.effective(
          index: i,
          currentStep: currentStep,
          status: items[i].status,
        ),
    ];
    final resolved = resolveSteps(
      context,
      variant: variant,
      vertical: vertical,
      statuses: statuses,
      stepsStyle: stepsStyle,
    );

    final stepRenderers = <Component>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final status = statuses[i];
      final isLast = i == items.length - 1;

      stepRenderers.add(switch (variant) {
        CoreStepsVariant.list => _buildListRow(
          resolved,
          item: item,
          status: status,
        ),
        CoreStepsVariant.numbered =>
          vertical
              ? _buildVerticalStep(
                  resolved,
                  item: item,
                  index: i,
                  status: status,
                  isLast: isLast,
                )
              : _buildHorizontalStep(
                  resolved,
                  item: item,
                  index: i,
                  status: status,
                  isLast: isLast,
                ),
      });
    }

    return div(
      stepRenderers,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }

  /// One row of the list variant — a `StepItem` marked as an entry of the
  /// list, the current one with `aria-current="step"` (the Flutter twin
  /// marks the same row `selected`; each reader words the signal its own
  /// way). The item's description is not drawn — a row has one line.
  Component _buildListRow(
    ResolvedSteps resolved, {
    required CoreStepData item,
    required CoreStepStatus status,
  }) {
    return StepItem(
      title: item.title,
      status: status,
      trailing: item.trailing,
      stepItemStyle: resolved.stepItemStyle,
      attributes: {
        'role': CoreSemanticRole.listItem.ariaRole,
        if (status == CoreStepStatus.current) 'aria-current': 'step',
      },
    );
  }

  Component _buildVerticalStep(
    ResolvedSteps resolved, {
    required CoreStepData item,
    required int index,
    required CoreStepStatus status,
    required bool isLast,
  }) {
    // Explicit `Gap` siblings — own the indicator ↔ content and the
    // pre/post-connector spacing through the nested `CoreGapStyle`
    // slots (matching the Flutter widget; no inline padding / margin
    // CSS in the surrounding chrome).
    final contentGap = Gap(gapStyle: resolved.indicatorContentGapStyle);
    final connectorGap = Gap(gapStyle: resolved.indicatorConnectorGapStyle);
    return div(
      [
        // Indicator column.
        div(
          [
            _buildIndicator(resolved, index: index, status: status),
            if (!isLast) ...[
              connectorGap,
              div(
                const [],
                classes: resolved.connectors[index].className,
                styles: resolved.connectors[index].inlineStyles,
              ),
              connectorGap,
            ],
          ],
          classes: resolved.indicatorColumns[index].className,
          styles: resolved.indicatorColumns[index].inlineStyles,
        ),
        contentGap,
        // Content column.
        div(
          [
            _buildTitle(resolved, item.title, index: index),
            if (item.description != null)
              _buildDescription(resolved, item.description!, index: index),
          ],
          classes: resolved.contentColumns[index].className,
          styles: resolved.contentColumns[index].inlineStyles,
        ),
      ],
      classes: resolved.stepWrappers[index].className,
      styles: resolved.stepWrappers[index].inlineStyles,
    );
  }

  Component _buildHorizontalStep(
    ResolvedSteps resolved, {
    required CoreStepData item,
    required int index,
    required CoreStepStatus status,
    required bool isLast,
  }) {
    final connectorGap = Gap(
      gapStyle: resolved.indicatorConnectorGapHorizontalStyle,
    );
    return div(
      [
        div(
          [
            _buildIndicator(resolved, index: index, status: status),
            if (!isLast) ...[
              connectorGap,
              div(
                const [],
                classes: resolved.connectors[index].className,
                styles: resolved.connectors[index].inlineStyles,
              ),
              connectorGap,
            ],
          ],
          classes: resolved.indicatorRows[index].className,
          styles: resolved.indicatorRows[index].inlineStyles,
        ),
        div(
          [
            _buildTitle(resolved, item.title, index: index),
            if (item.description != null)
              _buildDescription(resolved, item.description!, index: index),
          ],
          classes: resolved.contentColumns[index].className,
          styles: resolved.contentColumns[index].inlineStyles,
        ),
      ],
      classes: resolved.stepWrappers[index].className,
      styles: resolved.stepWrappers[index].inlineStyles,
    );
  }

  /// Builds the indicator circle.
  ///
  /// The fill per status is baked into [ResolvedSteps.indicators]. A done
  /// step draws the check and a failed step the cross — the status's own
  /// mark (`CoreStepStatus.indicatorGlyph`), sized + coloured through
  /// [ResolvedSteps.iconStyle] / [ResolvedSteps.failedIconStyle]; a
  /// current or upcoming step keeps its number.
  Component _buildIndicator(
    ResolvedSteps resolved, {
    required int index,
    required CoreStepStatus status,
  }) {
    final mark = switch (status) {
      CoreStepStatus.done => Icon(
        status.indicatorGlyph!,
        iconStyle: resolved.iconStyle,
      ),
      CoreStepStatus.failed => Icon(
        status.indicatorGlyph!,
        iconStyle: resolved.failedIconStyle,
      ),
      CoreStepStatus.current || CoreStepStatus.todo => span(
        [Text((index + 1).toString())],
        classes: resolved.indicatorNumbers[index].className,
        styles: resolved.indicatorNumbers[index].inlineStyles,
      ),
    };
    return div(
      [mark],
      classes: resolved.indicators[index].className,
      styles: resolved.indicators[index].inlineStyles,
    );
  }

  Component _buildTitle(
    ResolvedSteps resolved,
    String title, {
    required int index,
  }) {
    return div(
      [Text(title)],
      classes: resolved.titles[index].className,
      styles: resolved.titles[index].inlineStyles,
    );
  }

  Component _buildDescription(
    ResolvedSteps resolved,
    String description, {
    required int index,
  }) {
    return div(
      [Text(description)],
      classes: resolved.descriptions[index].className,
      styles: resolved.descriptions[index].inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Steps.withStyle` extension —
/// merges a [CoreStepsStyle] patch into [Steps.stepsStyle] via the
/// existing [Steps.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStepsStyle.merge` right-side-wins semantics).
extension StepsStyleChain on Steps {
  /// Returns a copy of this [Steps] with [patch] merged into
  /// [stepsStyle] (patch fields win on conflict).
  Steps withStyle(CoreStepsStyle patch) =>
      copyWith(stepsStyle: (stepsStyle ?? const CoreStepsStyle()).merge(patch));
}
