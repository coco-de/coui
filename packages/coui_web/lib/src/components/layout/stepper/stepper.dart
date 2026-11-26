import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/layout/stepper/stepper_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified stepper component for Web.
///
/// Displays a multi-step process with numbered indicators,
/// connectors, and step labels. Supports click-to-navigate via
/// [onStepChanged].
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [stepperStyle] (a [CoreStepperStyle]).
///
/// ```text
/// design system default for stepper
///   → CoreStepperTheme.style                 // 프로젝트 공통
///   → parent component slot override
///   → component.stepperStyle                 // 인스턴스별
/// ```
///
/// surface:content — the indicator circles are badge-form faces that
/// sit in the flow, not something mounted over content.
class Stepper extends UiComponent implements CoreStepperContract {
  /// Creates a [Stepper].
  const Stepper({
    required this.steps,
    this.currentStep = 0,
    this.orientation = CoreStepperOrientation.horizontal,
    this.onStepChanged,
    this.enabled,
    this.stepperStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<CoreStepItem> steps;

  @override
  final int currentStep;

  @override
  final CoreStepperOrientation orientation;

  @override
  final ValueChanged<int>? onStepChanged;

  /// Whether the stepper is enabled. `null` follows [onStepChanged]: a
  /// stepper that navigates is enabled, one that cannot is drawn disabled —
  /// the same circles, lines and words in the disabled palette, not a dimmed
  /// copy.
  @override
  final bool? enabled;

  bool get _effectiveEnabled => enabled ?? (onStepChanged != null);

  /// Per-instance composite style — chrome flat fields plus nested
  /// `labelStyle` / `descriptionStyle` / `indicatorIconStyle` slots.
  /// See [CoreStepperStyle] for the merge chain.
  @override
  final CoreStepperStyle? stepperStyle;

  @override
  Stepper copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreStepItem>? steps,
    int? currentStep,
    CoreStepperOrientation? orientation,
    ValueChanged<int>? onStepChanged,
    bool? enabled,
    CoreStepperStyle? stepperStyle,
  }) {
    return Stepper(
      key: key ?? this.key,
      steps: steps ?? this.steps,
      currentStep: currentStep ?? this.currentStep,
      orientation: orientation ?? this.orientation,
      onStepChanged: onStepChanged ?? this.onStepChanged,
      enabled: enabled ?? this.enabled,
      stepperStyle: stepperStyle ?? this.stepperStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final isVertical = orientation == .vertical;
    final resolved = resolveStepper(
      context,
      vertical: isVertical,
      enabled: _effectiveEnabled,
      currentStep: currentStep,
      stepCount: steps.length,
      stepperStyle: stepperStyle,
    );

    return isVertical
        ? _buildVertical(context, resolved)
        : _buildHorizontal(context, resolved);
  }

  Component _buildVertical(BuildContext context, ResolvedStepper resolved) {
    final stepComponents = <Component>[];
    for (var i = 0; i < steps.length; i++) {
      final item = steps[i];
      final isCompleted = i < currentStep;
      final isNotLast = i < steps.length - 1;
      final stepIndex = i;
      final canNavigate = onStepChanged != null && _effectiveEnabled;

      stepComponents.add(
        div(
          [
            // Indicator column.
            div(
              [
                _buildIndicator(
                  context,
                  resolved,
                  onTap: canNavigate ? () => onStepChanged!(stepIndex) : null,
                  index: i,
                  isCompleted: isCompleted,
                ),
                if (isNotLast)
                  div(
                    [
                      Divider(
                        orientation: .vertical,
                        dividerStyle: resolved.connectorDividerStyles[i],
                      ),
                    ],
                    classes: resolved.connectorWrappers[i].className,
                    styles: resolved.connectorWrappers[i].inlineStyles,
                  ),
              ],
              classes: resolved.indicatorColumns[i].className,
              styles: resolved.indicatorColumns[i].inlineStyles,
            ),
            // Indicator ↔ content gap — `Gap` sibling (mirrors the
            // Flutter `Row` sibling) so the per-side spacing is owned by
            // the nested `indicatorContentGapStyle` slot.
            Gap(gapStyle: resolved.indicatorContentGapStyle),
            // Content column.
            div(
              [
                div(
                  [Text(item.label)],
                  classes: resolved.labels[i].className,
                  styles: resolved.labels[i].inlineStyles,
                ),
                if (item.description != null) ...[
                  // Label ↔ description gap — `Gap` sibling (mirrors the
                  // Flutter `Column` sibling) so the spacing is owned by
                  // the nested `descriptionGapStyle` slot.
                  Gap(gapStyle: resolved.descriptionGapStyle),
                  div(
                    [Text(item.description!)],
                    classes: resolved.descriptions[i].className,
                    styles: resolved.descriptions[i].inlineStyles,
                  ),
                ],
              ],
              classes: resolved.contentColumns[i].className,
              styles: resolved.contentColumns[i].inlineStyles,
            ),
          ],
          classes: resolved.stepWrappers[i].className,
          styles: resolved.stepWrappers[i].inlineStyles,
        ),
      );
    }

    return div(
      stepComponents,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }

  Component _buildHorizontal(BuildContext context, ResolvedStepper resolved) {
    final stepComponents = <Component>[];

    for (var i = 0; i < steps.length; i++) {
      final item = steps[i];
      final isNotFirst = i > 0;
      final isNotLast = i < steps.length - 1;
      final stepIndex = i;
      final canNavigate = onStepChanged != null && _effectiveEnabled;

      stepComponents.add(
        div(
          [
            // The step's track: a half-line, the circle, a half-line. The
            // connector between two steps is the trailing half of one and
            // the leading half of the next — the two meet at the column
            // boundary and read as one line. The first step's leading
            // half and the last step's trailing half are empty wrappers:
            // no step lies beyond them, but they keep the width that
            // centres the circle in its column.
            div(
              [
                div(
                  [
                    if (isNotFirst)
                      Divider(
                        dividerStyle: resolved.connectorDividerStyles[i - 1],
                      ),
                  ],
                  classes: resolved.connectorStart.className,
                  styles: resolved.connectorStart.inlineStyles,
                ),
                _buildIndicator(
                  context,
                  resolved,
                  onTap: canNavigate ? () => onStepChanged!(stepIndex) : null,
                  index: i,
                  isCompleted: i < currentStep,
                ),
                div(
                  [
                    if (isNotLast)
                      Divider(dividerStyle: resolved.connectorDividerStyles[i]),
                  ],
                  classes: resolved.connectorEnd.className,
                  styles: resolved.connectorEnd.inlineStyles,
                ),
              ],
              classes: resolved.track.className,
              styles: resolved.track.inlineStyles,
            ),
            // Indicator ↔ label gap — `Gap` sibling (mirrors the
            // Flutter `Column` sibling) so the spacing is owned by the
            // nested `labelGapStyle` slot.
            Gap(gapStyle: resolved.labelGapStyle),
            // 1×1 grid stack: two invisible state-styled copies reserve
            // the widest label width so the active⇄inactive bold toggle
            // repaints in place — without them the step column resizes
            // and every later indicator shifts (mirrors the Flutter
            // twin's invisible `Text` layers).
            div(
              [
                span(
                  [Text(item.label)],
                  classes: resolved.labelSizerActive.className,
                  styles: resolved.labelSizerActive.inlineStyles,
                  attributes: const {'aria-hidden': 'true'},
                ),
                span(
                  [Text(item.label)],
                  classes: resolved.labelSizerInactive.className,
                  styles: resolved.labelSizerInactive.inlineStyles,
                  attributes: const {'aria-hidden': 'true'},
                ),
                span(
                  [Text(item.label)],
                  classes: resolved.labelText.className,
                ),
              ],
              classes: resolved.labels[i].className,
              styles: resolved.labels[i].inlineStyles,
            ),
          ],
          classes: resolved.stepWrappers[i].className,
          styles: resolved.stepWrappers[i].inlineStyles,
        ),
      );
    }

    return div(
      stepComponents,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }

  Component _buildIndicator(
    BuildContext context,
    ResolvedStepper resolved, {
    required int index,
    required bool isCompleted,
    void Function()? onTap,
  }) {
    final indicator = div(
      [
        if (isCompleted)
          Icon(
            LucideIcons.check,
            iconStyle: resolved.indicatorIconStyles[index],
          )
        else
          span(
            [Text((index + 1).toString())],
            classes: resolved.indicatorNumbers[index].className,
            styles: resolved.indicatorNumbers[index].inlineStyles,
          ),
      ],
      classes: resolved.indicators[index].className,
      styles: resolved.indicators[index].inlineStyles,
    );
    if (onTap == null) return indicator;

    // Web twin of the Flutter indicator slot: the composed Clickable
    // owns tap / keyboard activation (Enter / Space) / cursor / press
    // feedback / focus ring — no hand-rolled role / tabindex / click.
    return Clickable(
      onPressed: onTap,
      attributes: {
        'aria-label': CouiLocalizations.of(
          context,
        ).stepperStepLabel(steps[index].label, index + 1),
        if (index == currentStep) 'aria-current': 'step',
      },
      clickableStyle: resolved.clickableStyle,
      child: indicator,
    );
  }
}

/// Chain sugar mirroring the Flutter `Stepper.withStyle` extension —
/// merges a [CoreStepperStyle] patch into [Stepper.stepperStyle] via the
/// existing [Stepper.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStepperStyle.merge` right-side-wins semantics).
extension StepperStyleChain on Stepper {
  /// Returns a copy of this [Stepper] with [patch] merged into
  /// [stepperStyle] (patch fields win on conflict).
  Stepper withStyle(CoreStepperStyle patch) => copyWith(
    stepperStyle: (stepperStyle ?? const CoreStepperStyle()).merge(patch),
  );
}
