import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// A unified cross-platform pagination control.
///
/// `Pagination` renders a row of square page-number buttons flanked
/// by previous / next controls. The active page is highlighted; when
/// the page count exceeds [maxPages] an ellipsis button condenses the
/// hidden range and (optionally) skip-to-first / skip-to-last buttons
/// jump to the edges.
///
/// Every chrome / dimensional override flows through the single
/// [paginationStyle] field — see [CorePaginationStyle] for the merge
/// chain. The behaviour fields (`maxPages` / `showSkipToFirstPage` /
/// `showSkipToLastPage` / `hidePreviousOnFirstPage` /
/// `hideNextOnLastPage` / `showLabel`) stay flat on the widget.
///
/// [enabled] follows the handler (`enabled ?? (onPageChanged != null)`): a
/// pagination with no handler, or an explicit `enabled: false`, draws every
/// number, the `…` and the chevrons in the disabled content colour (the
/// current page on the disabled container fill) and makes no button
/// interactive.
///
/// Mirrors Web `Pagination` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Pagination(
///   page: currentPage,
///   totalPages: 10,
///   onPageChanged: (p) => setState(() => currentPage = p),
/// )
/// ```
///
/// surface:content — a page-nav control that sits in the flow, not
/// something mounted over content.
class Pagination extends StatefulWidget implements CorePaginationContract {
  /// Creates a [Pagination].
  const Pagination({
    required this.page,
    required this.totalPages,
    this.onPageChanged,
    this.enabled,
    this.maxPages = _kDefaultMaxPages,
    this.showSkipToFirstPage = true,
    this.showSkipToLastPage = true,
    this.hidePreviousOnFirstPage = false,
    this.hideNextOnLastPage = false,
    this.showLabel = false,
    this.variant = CorePaginationVariant.defaultVariant,
    this.role = .defaultRole,
    this.paginationStyle,
    super.key,
  });

  /// Default maximum number of page-number buttons to display.
  static const int _kDefaultMaxPages = 3;

  /// One-based current page index.
  final int page;

  @override
  final int totalPages;

  @override
  final CoreValueChanged<int>? onPageChanged;

  @override
  final bool? enabled;

  /// Maximum number of page-number buttons to show at once.
  final int maxPages;

  /// Whether to show a skip-to-first-page button when the leading
  /// ellipsis is visible.
  final bool showSkipToFirstPage;

  /// Whether to show a skip-to-last-page button when the trailing
  /// ellipsis is visible.
  final bool showSkipToLastPage;

  /// Whether to hide the previous button while on the first page.
  final bool hidePreviousOnFirstPage;

  /// Whether to hide the next button while on the last page.
  final bool hideNextOnLastPage;

  /// Whether the previous / next buttons show a text label next to the
  /// chevron.
  final bool showLabel;

  /// The visual variant of the pagination control.
  final CorePaginationVariant variant;

  @override
  final CoreSurfaceRole role;

  @override
  final CorePaginationStyle? paginationStyle;

  /// One-based current page index — alias of [page] satisfying
  /// [CorePaginationContract.currentPage].
  @override
  int get currentPage => page;

  /// Returns a copy of this [Pagination] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Pagination copyWith({
    Key? key,
    int? page,
    int? totalPages,
    CoreValueChanged<int>? onPageChanged,
    bool? enabled,
    int? maxPages,
    bool? showSkipToFirstPage,
    bool? showSkipToLastPage,
    bool? hidePreviousOnFirstPage,
    bool? hideNextOnLastPage,
    bool? showLabel,
    CorePaginationVariant? variant,
    CoreSurfaceRole? role,
    CorePaginationStyle? paginationStyle,
  }) {
    return Pagination(
      key: key ?? this.key,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      onPageChanged: onPageChanged ?? this.onPageChanged,
      enabled: enabled ?? this.enabled,
      maxPages: maxPages ?? this.maxPages,
      showSkipToFirstPage: showSkipToFirstPage ?? this.showSkipToFirstPage,
      showSkipToLastPage: showSkipToLastPage ?? this.showSkipToLastPage,
      hidePreviousOnFirstPage:
          hidePreviousOnFirstPage ?? this.hidePreviousOnFirstPage,
      hideNextOnLastPage: hideNextOnLastPage ?? this.hideNextOnLastPage,
      showLabel: showLabel ?? this.showLabel,
      variant: variant ?? this.variant,
      role: role ?? this.role,
      paginationStyle: paginationStyle ?? this.paginationStyle,
    );
  }

  @override
  State<Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  /// Identifies the button currently hovered (`'previous'` / `'next'` /
  /// `'ellipsis-leading'` / `'ellipsis-trailing'` / `'page-N'`).
  /// `null` = none.
  String? _hoveredKey;

  bool get _enabled => widget.enabled ?? (widget.onPageChanged != null);

  /// The ladder step the row was last laid out at — reported by
  /// [_PaginationFit] after the frame that chose it. Only focus reads it:
  /// paint, hit testing and semantics follow the render object's choice
  /// in the same frame.
  int _fitStep = 0;

  void _handleHoverChanged(String key, {required bool hovering}) {
    setState(() => _hoveredKey = hovering ? key : null);
  }

  void _handleFitStepChanged(int step) {
    if (!mounted || step == _fitStep) return;
    setState(() => _fitStep = step);
  }

  Widget _buildButton({
    required VoidCallback? onTap,
    required String hoverKey,
    required ResolvedPagination resolved,
    required TextStyle baseTextStyle,
    required bool active,
    required Widget child,
    bool labelled = false,
    String? semanticLabel,
    Color? restingForeground,
  }) {
    final enabled = _enabled;
    final isHovered = enabled && _hoveredKey == hoverKey;
    final CoreOutlinedContainerStyle containerStyle;
    final Color foregroundColor;
    final TextStyle textStyle;
    if (!enabled) {
      // A disabled pagination states one foreground for everything and the
      // disabled container for the current page; nothing is hovered.
      containerStyle = active
          ? resolved.disabledActiveContainerStyle
          : labelled
          ? resolved.labelIdleContainerStyle
          : resolved.idleContainerStyle;
      foregroundColor = resolved.disabledForegroundColor;
      textStyle = active ? resolved.activeButtonTextStyle : baseTextStyle;
    } else if (active) {
      containerStyle = resolved.activeContainerStyle;
      foregroundColor = resolved.activeForegroundColor;
      textStyle = resolved.activeButtonTextStyle;
    } else if (isHovered && onTap != null) {
      containerStyle = labelled
          ? resolved.labelHoverContainerStyle
          : resolved.hoverContainerStyle;
      foregroundColor = resolved.hoverForegroundColor;
      textStyle = baseTextStyle;
    } else {
      containerStyle = labelled
          ? resolved.labelIdleContainerStyle
          : resolved.idleContainerStyle;
      foregroundColor = restingForeground ?? resolved.foregroundColor;
      textStyle = baseTextStyle;
    }

    // The face is `OutlinedContainer`, not a hand-rolled decoration —
    // that is what lets a material preset reach a page button the same
    // way it reaches a `Card`. The per-state bundles a button swaps
    // between size/round the same box (only `backgroundColor` differs),
    // so the swap animates smoothly through the same `AnimatedContainer`
    // `OutlinedContainer` owns rather than rebuilding a new widget type.
    // A [labelled] button swaps between the label bundles instead: the
    // square box fits an icon or a page number, not a word.
    final face = OutlinedContainer(
      containerStyle: containerStyle,
      role: widget.role,
      child: Center(
        child: Semantics(
          enabled: enabled && onTap != null,
          selected: active,
          button: true,
          label: semanticLabel,
          child: IconTheme.merge(
            data: IconThemeData(color: foregroundColor),
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(color: foregroundColor),
              child: child,
            ),
          ),
        ),
      ),
    );

    // A disabled pagination is not wrapped at all: the `Clickable` would dim
    // the whole button on top of the disabled colours (a second, stacked
    // disabled treatment), and there is nothing left for it to own — no tap,
    // no focus, no hover.
    if (!enabled) return face;

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring / disabled opacity (Epic composition
    // — no hand-rolled GestureDetector + MouseRegion). Per-key hover
    // state flows back through `onHover` so the widget only SELECTS
    // between the pre-resolved active / hover / idle style bundles.
    return Clickable(
      onPressed: onTap,
      onHover: (hovered) => _handleHoverChanged(hoverKey, hovering: hovered),
      enabled: onTap != null,
      clickableStyle: resolved.clickableStyle,
      child: face,
    );
  }

  Widget _buildNavigation(
    CorePaginationNavigationEntry entry,
    ResolvedPagination resolved,
    TextStyle baseTextStyle,
    CoUILocalizations localizations,
  ) {
    final previous = entry.direction == CorePaginationDirection.previous;
    final label = previous
        ? localizations.buttonPrevious
        : localizations.buttonNext;
    final icon = Icon(
      previous ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      iconStyle: resolved.iconStyle,
    );
    final child = entry.showsLabel
        ? Row(
            mainAxisSize: .min,
            spacing: CoreSpace.space4,
            children: previous ? [icon, Text(label)] : [Text(label), icon],
          )
        : icon;
    return _buildButton(
      onTap: entry.enabled
          ? () => widget.onPageChanged?.call(entry.targetPage)
          : null,
      hoverKey: previous ? 'previous' : 'next',
      resolved: resolved,
      baseTextStyle: baseTextStyle,
      active: false,
      labelled: entry.showsLabel,
      // An icon-only button keeps the label as its accessible name, so a
      // row that dropped its labels to fit still says "previous" / "next".
      semanticLabel: entry.showsLabel ? null : label,
      child: child,
    );
  }

  Widget _buildEntry(
    CorePaginationEntry entry,
    ResolvedPagination resolved,
    TextStyle baseTextStyle,
    CoUILocalizations localizations,
  ) {
    return switch (entry) {
      CorePaginationNavigationEntry() => _buildNavigation(
        entry,
        resolved,
        baseTextStyle,
        localizations,
      ),
      CorePaginationPageEntry(:final page, :final active) => _buildButton(
        onTap: () => widget.onPageChanged?.call(page),
        hoverKey: 'page-$page',
        resolved: resolved,
        baseTextStyle: baseTextStyle,
        active: active,
        child: Text('$page'),
      ),
      CorePaginationEllipsisEntry(:final leading, :final targetPage) =>
        _buildButton(
          onTap: () => widget.onPageChanged?.call(targetPage),
          hoverKey: leading ? 'ellipsis-leading' : 'ellipsis-trailing',
          resolved: resolved,
          baseTextStyle: baseTextStyle.merge(resolved.ellipsisTextStyle),
          active: false,
          restingForeground: resolved.ellipsisForegroundColor,
          child: const Text('…'),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePagination(
      context,
      variant: widget.variant,
      paginationStyle: widget.paginationStyle,
    );
    final localizations = CoUILocalizations.of(context);
    // sb-text-style-repackage — base button typography (labelLarge role
    // + medium weight + `buttonTextStyle` slot) now resolved paint-ready.
    final baseTextStyle = resolved.buttonTextStyle;

    List<CorePaginationEntry> entriesAt(CorePaginationCompaction compaction) =>
        CorePaginationLayout.entries(
          page: widget.page,
          totalPages: widget.totalPages,
          maxPages: widget.maxPages,
          showSkipToFirstPage: widget.showSkipToFirstPage,
          showSkipToLastPage: widget.showSkipToLastPage,
          hidePreviousOnFirstPage: widget.hidePreviousOnFirstPage,
          hideNextOnLastPage: widget.hideNextOnLastPage,
          showLabel: widget.showLabel,
          compaction: compaction,
        );

    Widget rowAt(CorePaginationCompaction compaction) => Row(
      mainAxisSize: .min,
      spacing: resolved.itemSpacing,
      children: [
        for (final entry in entriesAt(compaction))
          _buildEntry(entry, resolved, baseTextStyle, localizations),
      ],
    );

    final ladder = CorePaginationLayout.ladder(
      page: widget.page,
      totalPages: widget.totalPages,
      maxPages: widget.maxPages,
      showSkipToFirstPage: widget.showSkipToFirstPage,
      showSkipToLastPage: widget.showSkipToLastPage,
      hidePreviousOnFirstPage: widget.hidePreviousOnFirstPage,
      hideNextOnLastPage: widget.hideNextOnLastPage,
      showLabel: widget.showLabel,
    );

    // Every step of the ladder is built and measured; the render object
    // draws the first one as narrow as the width it is given. Steps it
    // did not choose are kept out of focus traversal — they are never
    // painted, hit or announced.
    final row = ladder.length == 1
        ? rowAt(ladder.single)
        : _PaginationFit(
            onStepChanged: _handleFitStepChanged,
            children: [
              for (var i = 0; i < ladder.length; i++)
                ExcludeFocus(
                  excluding: i != _fitStep,
                  child: rowAt(ladder[i]),
                ),
            ],
          );

    return Semantics(
      container: true,
      label: localizations.paginationLabel,
      child: row,
    );
  }
}

/// Lays out each of its children — the rows of a pagination ladder, widest
/// first — at their natural width and shows the first one that fits the
/// incoming width (the last one when none does).
///
/// Only the chosen row is painted, hit tested and exposed to semantics.
/// The choice is reported to [onStepChanged] after the frame so the
/// owner can move focus eligibility to the same row.
class _PaginationFit extends MultiChildRenderObjectWidget {
  const _PaginationFit({required this.onStepChanged, required super.children});

  final ValueChanged<int> onStepChanged;

  @override
  MultiChildRenderObjectElement createElement() => _PaginationFitElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPaginationFit(onStepChanged: onStepChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPaginationFit renderObject,
  ) {
    renderObject.onStepChanged = onStepChanged;
  }
}

/// Reports only the chosen row as onstage — the rows it did not choose are
/// built for measuring, not shown, so a finder (or anything else walking
/// the onstage tree) sees one row, the way it would through an
/// `Offstage`.
class _PaginationFitElement extends MultiChildRenderObjectElement {
  _PaginationFitElement(_PaginationFit super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final chosen = (renderObject as _RenderPaginationFit)._chosen;
    for (final child in children) {
      if (chosen == null || child.renderObject == chosen) {
        visitor(child);
        if (chosen == null) return;
      }
    }
  }
}

class _PaginationFitParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderPaginationFit extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PaginationFitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PaginationFitParentData> {
  _RenderPaginationFit({required this.onStepChanged});

  ValueChanged<int> onStepChanged;

  RenderBox? _chosen;
  int _reportedStep = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PaginationFitParentData) {
      child.parentData = _PaginationFitParentData();
    }
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(maxHeight: constraints.maxHeight);

  bool _fits(double width, double maxWidth) =>
      width <= maxWidth + precisionErrorTolerance;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final childConstraints = _childConstraints(constraints);
    var child = firstChild;
    Size? size;
    while (child != null) {
      size = child.getDryLayout(childConstraints);
      if (_fits(size.width, constraints.maxWidth)) break;
      child = childAfter(child);
    }
    return constraints.constrain(size ?? Size.zero);
  }

  @override
  void performLayout() {
    final childConstraints = _childConstraints(constraints);
    RenderBox? chosen;
    var chosenStep = 0;
    var step = 0;
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      if (chosen == null &&
          (_fits(child.size.width, constraints.maxWidth) ||
              childAfter(child) == null)) {
        chosen = child;
        chosenStep = step;
      }
      child = childAfter(child);
      step++;
    }
    _chosen = chosen;
    size = constraints.constrain(chosen?.size ?? Size.zero);
    if (chosenStep != _reportedStep) {
      _reportedStep = chosenStep;
      // Never notify during layout — hand the step over after the frame.
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => onStepChanged(chosenStep),
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = math.max(height, child.getMinIntrinsicHeight(width));
      child = childAfter(child);
    }
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = math.max(height, child.getMaxIntrinsicHeight(width));
      child = childAfter(child);
    }
    return height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _chosen?.getDistanceToActualBaseline(baseline);

  @override
  bool paintsChild(RenderBox child) => child == _chosen;

  @override
  void paint(PaintingContext context, Offset offset) {
    final chosen = _chosen;
    if (chosen != null) context.paintChild(chosen, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final chosen = _chosen;
    if (chosen == null) return false;
    return chosen.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final chosen = _chosen;
    if (chosen != null) visitor(chosen);
  }
}

/// Chain sugar for merging a [CorePaginationStyle] patch into
/// [Pagination.paginationStyle] without hand-reconstructing every field.
/// Mirrors the Web `Pagination.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePaginationStyle.merge` right-side-wins semantics).
extension PaginationStyleChain on Pagination {
  /// Returns a copy of this [Pagination] with [patch] merged into
  /// [paginationStyle] (patch fields win on conflict).
  Pagination withStyle(CorePaginationStyle patch) => copyWith(
    paginationStyle: (paginationStyle ?? const CorePaginationStyle()).merge(
      patch,
    ),
  );
}
