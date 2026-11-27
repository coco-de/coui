import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/progress/progress_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

// ─── File-local renderer constants (not design tokens) ────────────
// `_kPercentageMultiplier` and clamp bounds are component math, not
// design tokens. The 2π radial constant lives in this file too.

const String _kDivTag = 'div';
const double _kClampMin = 0;
const double _kPercentageMultiplier = 100;
// Approximate value of 2π used for SVG arc geometry. Native `math.pi`
// import isn't necessary for this single constant.
const double _kTwoPi = 6.28318530717958;

/// Unified cross-platform linear progress indicator for CoUI Web.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [progressStyle] slot. Behaviour fields stay flat on the
/// widget.
///
/// [tone] says what the fill means; the track stays neutral on every
/// tone. Three optional cells sit around the bar — [label] and
/// [valueLabel] on one row above it, [caption] below it. With none of them
/// the element is the bar alone, exactly as before the cells existed.
///
/// Example:
/// ```dart
/// Progress(value: 0.65)
/// Progress(value: 75, min: 0, max: 100)
/// Progress(value: 1, max: 2, segments: 2) // A stepped bar: STEP 1 / 2.
/// Progress(
///   value: 0.62,
///   tone: CoreProgressTone.warning,
///   label: Text('Team plan'),
///   valueLabel: Text('62%'),
///   caption: Text('AI usage · 18 days left'),
/// )
/// ```
class Progress extends UiComponent implements CoreProgressContract<Component> {
  /// Creates a [Progress].
  const Progress({
    super.key,
    this.value,
    this.min = CoreProgressContract.defaultMin,
    this.max = CoreProgressContract.defaultMax,
    this.disableAnimation = false,
    this.segments,
    this.size = CoreProgressSize.defaultSize,
    this.tone = CoreProgressTone.defaultTone,
    this.label,
    this.valueLabel,
    this.caption,
    this.progressStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _kDivTag,
  }) : assert(
         segments == null || segments >= 1,
         'A segmented Progress needs at least one segment',
       );

  @override
  final double? value;

  @override
  final double min;

  @override
  final double max;

  @override
  final bool disableAnimation;

  @override
  final int? segments;

  @override
  final CoreProgressSize size;

  @override
  final CoreProgressTone tone;

  @override
  final Component? label;

  @override
  final Component? valueLabel;

  @override
  final Component? caption;

  @override
  final CoreProgressStyle? progressStyle;

  @override
  Progress copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    double? value,
    double? min,
    double? max,
    bool? disableAnimation,
    int? segments,
    CoreProgressSize? size,
    CoreProgressTone? tone,
    Component? label,
    Component? valueLabel,
    Component? caption,
    CoreProgressStyle? progressStyle,
    Key? key,
  }) {
    return Progress(
      key: key ?? this.key,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      disableAnimation: disableAnimation ?? this.disableAnimation,
      segments: segments ?? this.segments,
      size: size ?? this.size,
      tone: tone ?? this.tone,
      label: label ?? this.label,
      valueLabel: valueLabel ?? this.valueLabel,
      caption: caption ?? this.caption,
      progressStyle: progressStyle ?? this.progressStyle,
      attributes: attributes ?? userAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final range = max - min;
    final currentValue = value;
    final isIndeterminate = currentValue == null;
    final percentage = !isIndeterminate && range > 0
        ? ((currentValue - min) / range * _kPercentageMultiplier).clamp(
            _kClampMin,
            _kPercentageMultiplier,
          )
        : _kClampMin;

    final hasLabelRow = label != null || valueLabel != null;
    final labelled = hasLabelRow || caption != null;
    // A stepped bar needs a value to place its steps; an indeterminate one
    // stays continuous.
    final segments = isIndeterminate ? null : this.segments;
    final filled = segments == null
        ? 0
        : CoreProgressContract.filledSegmentsOf(
            value: currentValue!,
            min: min,
            max: max,
            segments: segments,
          );

    final resolved = resolveProgress(
      context: context,
      size: size,
      tone: tone,
      isIndeterminate: isIndeterminate,
      widthPercent: isIndeterminate ? _kClampMin : percentage,
      animated: !isIndeterminate && !disableAnimation,
      labelled: labelled,
      segmented: segments != null,
      progressStyle: progressStyle,
    );

    final scopeId = id ?? elementScopeId(context, prefix: 'co-progress');
    final labelId = '$scopeId-label';
    final captionId = '$scopeId-caption';

    final rootClasses = [
      resolved.root.className,
      ?classes,
    ].where((c) => c.isNotEmpty).join(' ');

    Component buildIndeterminateStyle() => Component.element(
      tag: 'style',
      children: [
        RawText(
          resolveProgressIndeterminateCss(
            context,
            scopeId: scopeId,
            tone: tone,
            progressStyle: progressStyle,
          ),
        ),
      ],
    );
    final indicator = div(
      const [],
      classes: resolved.indicator.className,
      styles: resolved.indicator.inlineStyles,
    );
    // One cell per step — the steps passed in the fill, the rest in the
    // track colour (the Flutter twin's `Row` of `Expanded` cells).
    final cells = [
      for (var i = 0; i < (segments ?? 0); i++)
        div(
          const [],
          classes: i < filled
              ? resolved.filledSegment.className
              : resolved.emptySegment.className,
          styles: i < filled
              ? resolved.filledSegment.inlineStyles
              : resolved.emptySegment.inlineStyles,
        ),
    ];

    return Component.element(
      tag: tag,
      id: scopeId,
      classes: rootClasses,
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?this.css,
      ]),
      attributes: {
        ...componentAttributes,
        'role': 'progressbar',
        if (!isIndeterminate) 'aria-valuenow': '$currentValue',
        'aria-valuemin': '$min',
        'aria-valuemax': '$max',
        // A stepped bar reads its step — "Step 1 of 2" — rather than the
        // raw value; the Flutter twin's semantics value.
        if (segments != null)
          'aria-valuetext': CouiLocalizations.of(
            context,
          ).progressStepValue(filled, segments),
        // A progressbar's children are presentational, so the cells inside
        // it are read only through these references: the label names the
        // bar, the caption describes it. The value label repeats
        // `aria-valuenow` and is not referenced.
        if (label != null) 'aria-labelledby': labelId,
        if (caption != null) 'aria-describedby': captionId,
      },
      events: this.events,
      children: labelled
          ? [
              if (isIndeterminate) buildIndeterminateStyle(),
              if (hasLabelRow) ...[
                div(
                  [
                    // Empty when there is no label — it still takes the
                    // row's free width, so a lone value label sits at the
                    // end (the Flutter twin's `Spacer`).
                    Component.element(
                      tag: _kDivTag,
                      id: label == null ? null : labelId,
                      classes: resolved.label.className,
                      styles: resolved.label.inlineStyles,
                      children: [?label],
                    ),
                    if (valueLabel != null)
                      // The cell keeps the width of the widest value: one grid
                      // cell holds a hidden `100%` and the value, both at the
                      // end, so a value growing from `9%` to `100%` does not
                      // move the label row's other cells.
                      div(
                        [
                          div(
                            const [
                              Text(
                                CoreProgressContract.defaultValueLabelReserve,
                              ),
                            ],
                            classes: resolved.valueLabelReserve.className,
                            styles: resolved.valueLabelReserve.inlineStyles,
                            attributes: const {'aria-hidden': 'true'},
                          ),
                          div(
                            [valueLabel!],
                            classes: resolved.valueLabelValue.className,
                            styles: resolved.valueLabelValue.inlineStyles,
                          ),
                        ],
                        classes: resolved.valueLabel.className,
                        styles: resolved.valueLabel.inlineStyles,
                      ),
                  ],
                  classes: resolved.labelRow.className,
                  styles: resolved.labelRow.inlineStyles,
                ),
                Gap(gapStyle: resolved.labelGapStyle),
              ],
              if (segments != null)
                div(
                  cells,
                  classes: resolved.segmentRow.className,
                  styles: resolved.segmentRow.inlineStyles,
                )
              else
                div(
                  [indicator],
                  classes: resolved.track.className,
                  styles: resolved.track.inlineStyles,
                ),
              if (caption != null) ...[
                Gap(gapStyle: resolved.captionGapStyle),
                Component.element(
                  tag: _kDivTag,
                  id: captionId,
                  classes: resolved.caption.className,
                  styles: resolved.caption.inlineStyles,
                  children: [caption!],
                ),
              ],
            ]
          : segments != null
          ? cells
          : [
              if (isIndeterminate) buildIndeterminateStyle(),
              indicator,
            ],
    );
  }
}

/// Chain sugar for merging a [CoreProgressStyle] patch into
/// [Progress.progressStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `Progress.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreProgressStyle.merge` right-side-wins semantics).
///
/// `.primary`, `.success`, `.warning` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension ProgressStyleChain on Progress {
  /// Sets the background paint and preserves the other style fields.
  Progress backgroundColor(CoreColor value) =>
      withStyle(CoreProgressStyle(backgroundColor: value));

  /// Sets the fill of the progress bar.
  Progress fillColor(CoreColor value) =>
      withStyle(CoreProgressStyle(color: value));

  /// Returns a copy of this [Progress] with [patch] merged into
  /// [progressStyle] (patch fields win on conflict).
  Progress withStyle(CoreProgressStyle patch) => copyWith(
    progressStyle: (progressStyle ?? const CoreProgressStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Progress get radius0 => withStyle(
    const CoreProgressStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Progress get radius2 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Progress get radius4 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Progress get radius6 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Progress get radius8 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Progress get radius10 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Progress get radius12 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Progress get radius14 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Progress get radius16 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Progress get radius20 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Progress get radius24 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Progress get radius28 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Progress get radius32 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Progress get radius36 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Progress get radius40 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Progress get radius48 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Progress get radius56 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Progress get radius64 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Progress get radius9999 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── color (CoreColors base palette) — the fill ──────────────────
  // The palette patches the fill. The track stays unset so it stays the
  // neutral track — patching the track would
  // paint a full bar of the token under the default `primary` fill,
  // so `.success` would not read as a success bar.

  /// Selects `tone: .primary` using the component theme.
  Progress get primary => copyWith(tone: .primary);

  /// `color: CoreColor.token(CoreColors.secondary)`.
  Progress get secondary => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `color: CoreColor.token(CoreColors.tertiary)`.
  Progress get tertiary => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `color: CoreColor.token(CoreColors.surface)`.
  Progress get surface => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `color: CoreColor.token(CoreColors.surfaceContainer)`.
  Progress get surfaceContainer => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `color: CoreColor.token(CoreColors.error)`.
  Progress get error => withStyle(
    const CoreProgressStyle(color: CoreColor.token(CoreColors.error)),
  );

  /// Selects `tone: .success` using the component theme.
  Progress get success => copyWith(tone: .success);

  /// Selects `tone: .warning` using the component theme.
  Progress get warning => copyWith(tone: .warning);

  /// `color: CoreColor.token(CoreColors.info)`.
  Progress get info => withStyle(
    const CoreProgressStyle(color: CoreColor.token(CoreColors.info)),
  );

  /// `color: CoreColor.token(CoreColors.outline)`.
  Progress get outline => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.outline),
    ),
  );

  // ─── backgroundColor — the track ─────────────────────────────────
  // `transparent` says "no surface" on every component, so it clears the
  // track and leaves the fill — a transparent fill would erase the bar.

  /// `backgroundColor: CoreColor.transparent`.
  Progress get transparent => withStyle(
    const CoreProgressStyle(backgroundColor: .transparent),
  );
}

/// Unified cross-platform radial progress indicator for CoUI Web.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [radialProgressStyle] slot. Behaviour fields stay flat on
/// the widget.
///
/// Example:
/// ```dart
/// RadialProgress(value: 75, showValueText: true)
/// ```
class RadialProgress extends UiComponent
    implements CoreRadialProgressContract<Component?> {
  /// Creates a [RadialProgress].
  const RadialProgress({
    required this.value,
    super.key,
    this.showValueText = false,
    this.size = CoreRadialProgressContract.defaultSize,
    this.tone = CoreRadialProgressContract.defaultTone,
    this.child,
    this.radialProgressStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _kDivTag,
  });

  @override
  final double value;

  @override
  final bool showValueText;

  @override
  final CoreProgressSize size;

  @override
  final CoreProgressTone tone;

  @override
  final Component? child;

  @override
  final CoreRadialProgressStyle? radialProgressStyle;

  @override
  RadialProgress copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    double? value,
    bool? showValueText,
    CoreProgressSize? size,
    CoreProgressTone? tone,
    Component? child,
    CoreRadialProgressStyle? radialProgressStyle,
    Key? key,
  }) {
    return RadialProgress(
      key: key ?? this.key,
      value: value ?? this.value,
      showValueText: showValueText ?? this.showValueText,
      size: size ?? this.size,
      tone: tone ?? this.tone,
      radialProgressStyle: radialProgressStyle ?? this.radialProgressStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveRadialProgress(
      context: context,
      size: size,
      tone: tone,
      radialProgressStyle: radialProgressStyle,
    );
    final geometry = resolveRadialProgressGeometry(
      context,
      size: size,
      tone: tone,
      radialProgressStyle: radialProgressStyle,
    );
    final clampedValue = value.clamp(
      _kClampMin,
      CoreRadialProgressContract.defaultMaxValue,
    );

    final sizePx = geometry.sizePx;
    final strokeWidthPx = geometry.strokeWidthPx;
    final radius = (sizePx - strokeWidthPx) / 2;
    final circumference = _kTwoPi * radius;
    final offset =
        circumference *
        (1 - clampedValue / CoreRadialProgressContract.defaultMaxValue);

    // `stroke-width` rides a CSS `style` property (not the XML attribute
    // map below) — it's the one piece of this ring's geometry with a
    // `--coui-stroke-width-N` variable behind it, so a neo-brutalism-style
    // `strokeFloor` preset can still reach it even though `radius` /
    // `circumference` / `stroke-dashoffset` (plain SVG numeric attributes,
    // settled once from the unfloored width) cannot follow it live — see
    // `resolveRadialProgressGeometry`'s doc comment.
    final strokeWidthStyle = Styles(
      raw: {'stroke-width': geometry.strokeWidthCssValue},
    );

    final trackCircleAttrs = {
      'cx': '${sizePx / 2}',
      'cy': '${sizePx / 2}',
      'r': '$radius',
      'fill': 'none',
    };
    if (geometry.trackInlineColor != null) {
      trackCircleAttrs['stroke'] = geometry.trackInlineColor!;
    } else if (resolved.trackCircle.className.isNotEmpty) {
      trackCircleAttrs['class'] = resolved.trackCircle.className;
    }

    final arcCircleAttrs = {
      'cx': '${sizePx / 2}',
      'cy': '${sizePx / 2}',
      'r': '$radius',
      'fill': 'none',
      'stroke-linecap': 'round',
      'stroke-dasharray': '$circumference',
      'stroke-dashoffset': '$offset',
      'transform': 'rotate(-90 ${sizePx / 2} ${sizePx / 2})',
    };
    if (geometry.arcInlineColor != null) {
      arcCircleAttrs['stroke'] = geometry.arcInlineColor!;
    } else if (resolved.arcCircle.className.isNotEmpty) {
      arcCircleAttrs['class'] = resolved.arcCircle.className;
    }

    final label = resolved.label;
    final centerChild =
        child ??
        (showValueText && label != null
            ? span(
                [Text('${clampedValue.toInt()}%')],
                classes: label.className,
                styles: label.inlineStyles,
              )
            : null);

    return div(
      [
        Component.element(
          tag: 'svg',
          attributes: {
            'width': '$sizePx',
            'height': '$sizePx',
            'viewBox': '0 0 $sizePx $sizePx',
          },
          children: [
            Component.element(
              tag: 'circle',
              attributes: trackCircleAttrs,
              styles: strokeWidthStyle,
            ),
            Component.element(
              tag: 'circle',
              attributes: arcCircleAttrs,
              styles: strokeWidthStyle,
            ),
          ],
        ),
        ?centerChild,
      ],
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].where((c) => c.isNotEmpty).join(' '),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?this.css,
      ]),
      attributes: {
        ...componentAttributes,
        'role': 'progressbar',
        'aria-valuenow': clampedValue.toInt().toString(),
      },
      events: this.events,
    );
  }
}
