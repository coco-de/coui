import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Unified stepper component.
///
/// Displays a multi-step process with numbered indicators,
/// connectors, and step labels.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [stepperStyle] (a [CoreStepperStyle]). The
/// semantic enum (`orientation`) and behaviour fields (`steps` /
/// `currentStep` / `onStepChanged`) stay flat on the widget.
///
/// This widget is render-only: [resolveStepper] runs the merge chain,
/// design-system fallback and the `CoreColor → Color` resolution once,
/// and the build methods below read paint-ready [ResolvedStepper]
/// values without touching the theme colour scheme themselves (Epic
/// #1603 C7 / C11).
///
/// ```text
/// design system default for stepper
///   → CoreStepperTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget.stepperStyle                       // 인스턴스별
/// ```
///
/// ```dart
/// Stepper(
///   currentStep: 1,
///   steps: [
///     CoreStepItem(label: 'Account'),
///     CoreStepItem(label: 'Details'),
///     CoreStepItem(label: 'Confirm'),
///   ],
///   onStepChanged: (index) => setState(() => _step = index),
/// )
/// ```
///
/// surface:content — the indicator circles are badge-form faces that
/// sit in the flow, not something mounted over content.
class Stepper extends StatelessWidget implements CoreStepperContract {
  /// Creates a [Stepper].
  const Stepper({
    required this.steps,
    this.currentStep = 0,
    this.orientation = CoreStepperOrientation.horizontal,
    this.onStepChanged,
    this.enabled,
    this.stepperStyle,
    super.key,
  });

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

  /// Returns a copy of this [Stepper] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Stepper copyWith({
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
    );
  }

  /// Returns the connector segment slot based on [isCompleted]
  /// (completed segments use the active line, upcoming the inactive).
  /// The slot carries a `CoreColor` token + raw thickness — the sibling
  /// `Divider` resolves the colour and scales the thickness itself.
  CoreDividerStyle _connectorDividerStyle(
    ResolvedStepper style,
    bool isCompleted,
  ) => isCompleted
      ? style.connectorActiveDividerStyle
      : style.connectorInactiveDividerStyle;

  /// Composes the per-step indicator slot. Navigable steppers wrap the
  /// indicator circle in a [Clickable] that owns tap / keyboard
  /// activation / cursor / press feedback / focus ring (composition —
  /// no hand-rolled GestureDetector + MouseRegion). Non-navigable and
  /// disabled steppers render the bare indicator (basic cursor, no
  /// affordance) — a disabled stepper carries its own palette, so it must
  /// not take the Clickable's dimming on top.
  Widget _buildIndicatorSlot(ResolvedStepper style, int index) {
    final handler = onStepChanged;
    final indicator = _buildIndicator(style, index);
    if (handler == null || !_effectiveEnabled) return indicator;
    return Clickable(
      onPressed: () => handler(index),
      clickableStyle: style.clickableStyle,
      child: indicator,
    );
  }

  /// The label style of step [index] — current, completed or upcoming.
  TextStyle _labelStyle(ResolvedStepper style, int index) {
    if (index == currentStep) return style.labelActiveTextStyle;
    return index < currentStep
        ? style.labelInactiveTextStyle
        : style.labelUpcomingTextStyle;
  }

  Widget _buildVertical(ResolvedStepper style) {
    final stepWidgets = <Widget>[];

    for (var i = 0; i < steps.length; i++) {
      final item = steps[i];
      final isCompleted = i < currentStep;

      stepWidgets.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              Column(
                children: [
                  _buildIndicatorSlot(style, i),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Padding(
                        padding: .symmetric(
                          vertical: style.connectorMarginVertical,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: style.connectorMinExtent,
                          ),
                          child: Divider(
                            orientation: .vertical,
                            dividerStyle: _connectorDividerStyle(
                              style,
                              isCompleted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Gap(gapStyle: style.indicatorContentGapStyle),
              Expanded(
                child: _VerticalLabelAlignment(
                  label: item.label,
                  labelStyle: _labelStyle(style, i),
                  indicatorHeight: style.indicatorSize,
                  textScaler: style.labelTextScaler,
                  textDirection: style.labelTextDirection,
                  locale: style.labelLocale,
                  textHeightBehavior: style.labelHeightBehavior,
                  padding: i < steps.length - 1
                      ? style.stepPadding
                      : EdgeInsets.zero,
                  child: Padding(
                    // Non-final steps reserve `style.stepPadding`
                    // (paint-ready `EdgeInsets`, scaling pre-applied); the
                    // last step needs no trailing gap.
                    padding: i < steps.length - 1
                        ? style.stepPadding
                        : EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          item.label,
                          style: _labelStyle(style, i),
                        ),
                        if (item.description != null) ...[
                          Gap(gapStyle: style.descriptionGapStyle),
                          Text(
                            item.description!,
                            style: style.descriptionTextStyle,
                          ),
                        ],
                      ],
                    ),
                  ),
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

  Widget _buildHorizontal(ResolvedStepper style) {
    final stepWidgets = <Widget>[];

    for (var i = 0; i < steps.length; i++) {
      final item = steps[i];

      stepWidgets.add(
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            _buildTrack(style, i),
            Gap(gapStyle: style.labelGapStyle),
            // Width-reservation stack: two invisible state-styled
            // copies size the label box to the widest state, so the
            // active⇄inactive bold toggle repaints in place — without
            // them the step column resizes and every later indicator
            // shifts (mirrors the Web twin's invisible grid layers).
            Stacks(
              alignment: .center,
              children: [
                ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: Text(
                      item.label,
                      style: style.labelActiveTextStyle,
                      textAlign: .center,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: Text(
                      item.label,
                      style: style.labelInactiveTextStyle,
                      textAlign: .center,
                    ),
                  ),
                ),
                Text(
                  item.label,
                  style: _labelStyle(style, i),
                  textAlign: .center,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _HorizontalStepRow(
      minColumnWidth: style.indicatorSize,
      children: stepWidgets,
    );
  }

  /// The row a horizontal step's circle sits in: a half-line, the circle, a
  /// half-line. The connector between step `i - 1` and step `i` is the
  /// leading half here and the trailing half of the step before it, so two
  /// halves meet at the column boundary and read as one line. The first
  /// step's leading half and the last step's trailing half draw nothing —
  /// there is no step beyond them — but keep their width, which is what
  /// centres the circle in its column.
  Widget _buildTrack(ResolvedStepper style, int index) {
    final hasPrevious = index > 0;
    final hasNext = index < steps.length - 1;

    return Row(
      children: [
        Expanded(
          child: _buildConnectorHalf(
            style,
            visible: hasPrevious,
            // The line that reaches this step is completed once the
            // current step is this one or later.
            isCompleted: index <= currentStep,
            margin: EdgeInsetsDirectional.only(end: style.connectorMargin),
          ),
        ),
        _buildIndicatorSlot(style, index),
        Expanded(
          child: _buildConnectorHalf(
            style,
            visible: hasNext,
            isCompleted: index < currentStep,
            margin: EdgeInsetsDirectional.only(start: style.connectorMargin),
          ),
        ),
      ],
    );
  }

  /// One half of a horizontal connector: a band the height of the indicator,
  /// with the line centred in it. Offsetting the line's *top* to
  /// `indicatorSize / 2` instead lands its centre half a thickness below the
  /// indicator's, because the line's box is exactly `thickness` tall.
  /// Centring in a band needs no knowledge of the thickness, so it stays
  /// correct if the token changes, and it is the same construction the Web
  /// twin uses (`align-items: center`). An invisible half keeps the band —
  /// and so its width — and draws no line.
  Widget _buildConnectorHalf(
    ResolvedStepper style, {
    required bool visible,
    required bool isCompleted,
    required EdgeInsetsGeometry margin,
  }) {
    return Padding(
      padding: margin,
      child: SizedBox(
        height: style.indicatorSize,
        child: visible
            ? Center(
                child: Divider(
                  dividerStyle: _connectorDividerStyle(style, isCompleted),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildIndicator(
    ResolvedStepper style,
    int index,
  ) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;

    // Completed steps show the (paint-ready) check icon slot; the rest
    // show their number with the per-state text style — the resolver
    // baked every colour / size, so this branch only selects + renders.
    final content = isCompleted
        ? Icon(
            LucideIcons.check,
            iconStyle: style.indicatorIconStyle,
          )
        : Text(
            (index + 1).toString(),
            style: isCurrent
                ? style.indicatorNumberActiveTextStyle
                : style.indicatorNumberInactiveTextStyle,
          );

    // `OutlinedContainer` owns the indicator circle's fill / border /
    // (full-circle) radius / material — the widget only selects the
    // pre-composed per-state bundle and composes it (Epic #4349).
    final containerStyle = isCompleted
        ? style.indicatorCompletedContainerStyle
        : isCurrent
        ? style.indicatorCurrentContainerStyle
        : style.indicatorInactiveContainerStyle;

    return OutlinedContainer(
      containerStyle: containerStyle,
      child: Center(child: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStepper(
      context,
      orientation: orientation,
      enabled: _effectiveEnabled,
      stepperStyle: stepperStyle,
    );
    final isVertical = orientation == .vertical;

    if (isVertical) {
      return _buildVertical(resolved);
    }
    return _buildHorizontal(resolved);
  }
}

/// Chain sugar for merging a [CoreStepperStyle] patch into
/// [Stepper.stepperStyle] without hand-reconstructing every field. Mirrors
/// the Web `Stepper.withStyle` extension so both platforms read
/// identically.
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

/// The row of a horizontal [Stepper]: one column per step, all the same
/// width.
///
/// In a row of a bounded width each column is an equal share of it — never
/// less than [minColumnWidth], so a row too narrow for its circles overflows
/// instead of squeezing them. A label that does not fit its share (a long
/// word, a large text scale, a narrow screen) wraps inside its own column
/// instead of pushing the row past its edge (#5351). In a row of an unbounded
/// width every column takes the width of the widest, so the columns stay
/// equal. The Web twin states the same share as `flex: 1 1 0%` with a
/// `min-width` of the circle.
///
/// A render object rather than a `LayoutBuilder` because the share is a
/// function of the row's width, and a `LayoutBuilder` cannot answer the
/// intrinsic-size questions `IntrinsicWidth` / `IntrinsicHeight` ask —
/// a stepper inside a content-width `Popup` or `Card` would throw.
class _HorizontalStepRow extends MultiChildRenderObjectWidget {
  const _HorizontalStepRow({
    required this.minColumnWidth,
    required super.children,
  });

  final double minColumnWidth;

  @override
  _RenderHorizontalStepRow createRenderObject(BuildContext context) =>
      _RenderHorizontalStepRow(
        minColumnWidth: minColumnWidth,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHorizontalStepRow renderObject,
  ) {
    renderObject
      ..minColumnWidth = minColumnWidth
      ..textDirection = Directionality.of(context);
  }
}

class _HorizontalStepRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHorizontalStepRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HorizontalStepRowParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _HorizontalStepRowParentData
        > {
  _RenderHorizontalStepRow({
    required double minColumnWidth,
    required TextDirection textDirection,
  }) : _minColumnWidth = minColumnWidth,
       _textDirection = textDirection;

  double get minColumnWidth => _minColumnWidth;
  double _minColumnWidth;
  set minColumnWidth(double value) {
    if (value == _minColumnWidth) return;
    _minColumnWidth = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HorizontalStepRowParentData) {
      child.parentData = _HorizontalStepRowParentData();
    }
  }

  Iterable<RenderBox> get _columns sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  /// The width of every step column in a row [width] wide.
  double _columnWidth(double width) {
    if (childCount == 0) return 0;
    if (width.isFinite) return max(minColumnWidth, width / childCount);
    // No width to share: the columns are as wide as the widest one wants
    // to be, so they stay equal.
    var widest = minColumnWidth;
    for (final column in _columns) {
      widest = max(widest, column.getMaxIntrinsicWidth(double.infinity));
    }

    return widest;
  }

  /// Runs the layout through [layoutChild] — a real layout or a dry one —
  /// and returns the row size.
  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild) {
    final columnWidth = _columnWidth(constraints.maxWidth);
    var height = 0.0;
    for (final column in _columns) {
      final size = layoutChild(
        column,
        BoxConstraints(
          minWidth: columnWidth,
          maxWidth: columnWidth,
          maxHeight: constraints.maxHeight,
        ),
      );
      height = max(height, size.height);
    }
    final rowWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : columnWidth * childCount;

    return constraints.constrain(Size(rowWidth, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
    final columnWidth = _columnWidth(constraints.maxWidth);
    final rtl = textDirection == TextDirection.rtl;
    var index = 0;
    for (final column in _columns) {
      // Cross axis `start`: every column hangs from the top.
      final x = rtl
          ? size.width - (index + 1) * columnWidth
          : index * columnWidth;
      (column.parentData! as _HorizontalStepRowParentData).offset = Offset(
        x,
        0,
      );
      index += 1;
    }
  }

  double _widest(double Function(RenderBox column) width) {
    var widest = 0.0;
    for (final column in _columns) {
      widest = max(widest, width(column));
    }

    return widest * childCount;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _widest((column) => column.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _widest((column) => column.getMaxIntrinsicWidth(height));

  /// The tallest column once every one is [width] / count wide — what the
  /// row's height will be when it is laid out there.
  double _intrinsicHeight(
    double width,
    double Function(RenderBox column, double width) columnHeight,
  ) {
    final columnWidth = _columnWidth(width);
    var height = 0.0;
    for (final column in _columns) {
      height = max(height, columnHeight(column, columnWidth));
    }

    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(
    width,
    (column, width) => column.getMinIntrinsicHeight(width),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(
    width,
    (column, width) => column.getMaxIntrinsicHeight(width),
  );

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// In-flow alignment geometry, separate from the authored step insets.
/// Measure the first line at the same width/context as the visible paragraph:
/// its full height can grow through wrapping without moving that first line.
class _VerticalLabelAlignment extends SingleChildRenderObjectWidget {
  const _VerticalLabelAlignment({
    required this.label,
    required this.labelStyle,
    required this.indicatorHeight,
    required this.textScaler,
    required this.textDirection,
    required this.locale,
    required this.textHeightBehavior,
    required this.padding,
    required super.child,
  });

  final String label;
  final TextStyle labelStyle;
  final double indicatorHeight;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final Locale? locale;
  final TextHeightBehavior? textHeightBehavior;
  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderVerticalLabelAlignment(this);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderVerticalLabelAlignment renderObject,
  ) {
    renderObject.configuration = this;
  }
}

class _RenderVerticalLabelAlignment extends RenderShiftedBox {
  _RenderVerticalLabelAlignment(this._configuration) : super(null);

  _VerticalLabelAlignment _configuration;
  _VerticalLabelAlignment get configuration => _configuration;

  set configuration(_VerticalLabelAlignment value) {
    _configuration = value;
    markNeedsLayout();
  }

  double _offset(double width) {
    final c = _configuration;
    final painter = TextPainter(
      text: TextSpan(text: c.label, style: c.labelStyle),
      textDirection: c.textDirection,
      textScaler: c.textScaler,
      locale: c.locale,
      textHeightBehavior: c.textHeightBehavior,
    )..layout(maxWidth: max(0, width - c.padding.horizontal));
    final lines = painter.computeLineMetrics();
    final lineHeight = lines.isEmpty ? 0.0 : lines.first.height;
    painter.dispose();
    // Centre relation only: never density-map or scale these laid-out lengths.
    return max(0, (c.indicatorHeight - lineHeight) / 2);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child!.getMinIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      child!.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) =>
      child!.getMinIntrinsicHeight(width) + _offset(width);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      child!.getMaxIntrinsicHeight(width) + _offset(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final offset = _offset(constraints.maxWidth);
    final childSize = child!.getDryLayout(
      constraints.deflate(EdgeInsets.only(top: offset)),
    );
    return constraints.constrain(
      Size(childSize.width, childSize.height + offset),
    );
  }

  @override
  void performLayout() {
    final offset = _offset(constraints.maxWidth);
    child!.layout(
      constraints.deflate(EdgeInsets.only(top: offset)),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(child!.size.width, child!.size.height + offset),
    );
    (child!.parentData! as BoxParentData).offset = Offset(0, offset);
  }
}
