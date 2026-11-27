import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/web_surface_backdrop.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/scheduler.dart' show Ticker;

part 'glass_navigation_motion.dart';
// [NavigationBarItem] keeps its own directory so the parity manifest maps a
// change to it onto its own catalog slug (`navigation-bar-item`); it stays a
// part of this library because the bar hands each item private composition
// state that no caller outside the bar should construct.
part '../navigation_bar_item/navigation_bar_item.dart';

/// A unified cross-platform navigation container.
///
/// `NavigationBar` replaces the three legacy widgets — `NavigationBar`
/// (horizontal), `NavigationRail` (vertical compact) and
/// `NavigationSidebar` (expanded vertical) — with a single component
/// driven by the [mode] enum. It also collapses the legacy 5-class item
/// hierarchy into one [CoreNavigationBarItem] data model.
///
/// Every chrome / dimensional override flows through the single
/// [navigationBarStyle] field — see [CoreNavigationBarStyle] for the
/// merge chain. The semantic / behaviour fields (`mode` / `variant` /
/// `labelMode` / `labelPosition` / `alignment` / `overflow` /
/// `selectionMark` / `compact` / `selectedIndex` / `onSelected`) stay flat
/// on the widget.
///
/// Mirrors Web `NavigationBar` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// NavigationBar(
///   mode: CoreNavigationBarMode.bar,
///   selectedIndex: index,
///   onSelected: (i) => setState(() => index = i),
///   items: [
///     CoreNavigationBarItem.destination(
///       icon: const Icon(LucideIcons.house),
///       label: 'Home',
///     ),
///     CoreNavigationBarItem.destination(
///       icon: const Icon(LucideIcons.search),
///       label: 'Search',
///     ),
///   ],
/// )
/// ```
///
/// surface:behind — the shell stacks this bar over scrolling content.
///
/// surface:functional — the shell stacks this bar over a body that scrolls
/// beneath it.
class NavigationBar extends StatefulWidget
    implements CoreNavigationBarContract<Widget> {
  /// Creates a [NavigationBar].
  const NavigationBar({
    required this.items,
    this.selectedIndex,
    this.onSelected,
    this.mode = CoreNavigationBarMode.defaultMode,
    this.variant = CoreNavigationBarVariant.defaultVariant,
    this.labelMode,
    this.labelPosition,
    this.alignment = CoreNavigationAlignment.defaultAlignment,
    this.overflow = CoreNavigationOverflow.defaultOverflow,
    this.selectionMark = CoreNavigationSelectionMark.defaultSelectionMark,
    this.indicator,
    this.compact = CoreNavigationCompact.defaultCompact,
    this.header,
    this.footer,
    this.navigationBarStyle,
    super.key,
  });

  @override
  final List<CoreNavigationBarItem<Widget>> items;

  @override
  final int? selectedIndex;

  @override
  final CoreValueChanged<int>? onSelected;

  @override
  final CoreNavigationBarMode mode;

  @override
  final CoreNavigationBarVariant variant;

  @override
  final CoreNavigationLabelMode? labelMode;

  @override
  final CoreNavigationLabelPosition? labelPosition;

  @override
  final CoreNavigationAlignment alignment;

  @override
  final CoreNavigationOverflow overflow;

  @override
  final CoreNavigationSelectionMark selectionMark;

  @override
  final CoreNavigationSelectionIndicator? indicator;

  /// When the bar draws its compact form.
  ///
  /// [CoreNavigationCompact.onScroll] follows the vertical scrolling the
  /// nearest [ScrollNotificationObserver] above the bar hears — the
  /// [Scaffold] the bar is a footer of provides one around its body, and a
  /// shell built without a scaffold places its own above the bar and the
  /// content. Only visible, outermost vertical scrollables in that scope
  /// count; nested editors/lists and inactive tabs do not. A vertical list
  /// inside a horizontal page still counts. Without an observer the bar
  /// keeps its resting size.
  @override
  final CoreNavigationCompact compact;

  @override
  final Widget? header;

  @override
  final Widget? footer;

  @override
  final CoreNavigationBarStyle? navigationBarStyle;

  /// Returns a copy of this [NavigationBar] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  NavigationBar copyWith({
    Key? key,
    List<CoreNavigationBarItem<Widget>>? items,
    int? selectedIndex,
    CoreValueChanged<int>? onSelected,
    CoreNavigationBarMode? mode,
    CoreNavigationBarVariant? variant,
    CoreNavigationLabelMode? labelMode,
    CoreNavigationLabelPosition? labelPosition,
    CoreNavigationAlignment? alignment,
    CoreNavigationOverflow? overflow,
    CoreNavigationSelectionMark? selectionMark,
    CoreNavigationSelectionIndicator? indicator,
    CoreNavigationCompact? compact,
    Widget? header,
    Widget? footer,
    CoreNavigationBarStyle? navigationBarStyle,
  }) {
    return NavigationBar(
      key: key ?? this.key,
      items: items ?? this.items,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      onSelected: onSelected ?? this.onSelected,
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
      labelMode: labelMode ?? this.labelMode,
      labelPosition: labelPosition ?? this.labelPosition,
      alignment: alignment ?? this.alignment,
      overflow: overflow ?? this.overflow,
      selectionMark: selectionMark ?? this.selectionMark,
      indicator: indicator ?? this.indicator,
      compact: compact ?? this.compact,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    );
  }

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

/// Chain sugar for merging a [CoreNavigationBarStyle] patch into
/// [NavigationBar.navigationBarStyle] without hand-reconstructing every
/// field. Mirrors the Web `NavigationBar.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNavigationBarStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreNavigationBarStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// NavigationBar(items: items).surface
/// ```
extension NavigationBarStyleChain on NavigationBar {
  /// Sets the background paint and preserves the other style fields.
  NavigationBar backgroundColor(CoreColor value) =>
      withStyle(CoreNavigationBarStyle(backgroundColor: value));

  /// Returns a copy of this [NavigationBar] with [patch] merged into
  /// [navigationBarStyle] (patch fields win on conflict).
  NavigationBar withStyle(CoreNavigationBarStyle patch) => copyWith(
    navigationBarStyle: (navigationBarStyle ?? const CoreNavigationBarStyle())
        .merge(patch),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  NavigationBar get primary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  NavigationBar get secondary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  NavigationBar get tertiary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  NavigationBar get surface => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  NavigationBar get surfaceContainer => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  NavigationBar get error => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  NavigationBar get success => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  NavigationBar get warning => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  NavigationBar get info => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  NavigationBar get outline => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  NavigationBar get transparent => withStyle(
    const CoreNavigationBarStyle(backgroundColor: .transparent),
  );
}

class _NavigationBarState extends State<NavigationBar> {
  /// Laid-out width of each row-end badge, by destination index.
  ///
  /// A badge is a caller widget, so its width is known only once it has
  /// been laid out — the bar-mode fill-or-scroll decision, taken while
  /// building, reads the width the last layout reported. The first layout
  /// of a badge therefore decides without it, and the report that follows
  /// settles the decision on the next frame.
  final Map<int, double> _rowEndBadgeWidths = <int, double>{};

  /// Whether a rebuild for a newly reported badge width is already queued.
  bool _badgeWidthRebuildQueued = false;

  /// Whether the glass rail's destinations need more height than the rail
  /// has, so its column scrolls.
  ///
  /// The moving glass selection is drawn only while this is `false`: a drag
  /// along a column that scrolls has to scroll it, and the lens would take
  /// that gesture. Known only once the column has been laid out — the
  /// scroll view reports it after the frame (see [_handleRailMetrics]).
  bool _railOverflows = false;

  /// The glass bar's swell, written by its track and drawn by its capsule.
  final _GlassBarSwell _swell = _GlassBarSwell();

  /// Whether the content's scrolling has the bar compact — the rule's
  /// answer, read only while [NavigationBar.compact] follows the content.
  final CoreNavigationScrollCompaction _compaction =
      CoreNavigationScrollCompaction();

  /// The observer the bar hears the content's scrolling from, while it
  /// follows the content.
  ScrollNotificationObserverState? _contentScroll;

  /// Whether the bar is drawn compact.
  bool get _compact => switch (widget.compact) {
    .never => false,
    .onScroll => _compaction.compact,
    .always => true,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _followContent();
  }

  @override
  void didUpdateWidget(NavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another destination replaces the content the bar followed, and what
    // replaces it starts with the bar in full. So does a bar that stops
    // following.
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        widget.compact != .onScroll) {
      _compaction.reset();
    }
    if (oldWidget.compact != widget.compact) _followContent();
  }

  @override
  void dispose() {
    _contentScroll?.removeListener(_handleContentScroll);
    _swell.dispose();
    super.dispose();
  }

  /// Listens to the nearest scroll observer while the bar follows the
  /// content, and to none otherwise.
  void _followContent() {
    final next = widget.compact == .onScroll
        ? ScrollNotificationObserver.maybeOf(context)
        : null;
    if (identical(next, _contentScroll)) return;
    _contentScroll?.removeListener(_handleContentScroll);
    _contentScroll = next;
    next?.addListener(_handleContentScroll);
  }

  /// One scroll step of the content. Sideways scrolling is not the reader
  /// moving through the content, and the bar's own column scrolling is not
  /// the content at all.
  void _handleContentScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    if (!_isContentScroll(notification.context)) return;
    final was = _compaction.compact;
    final compact = _compaction.update(
      offset: metrics.pixels,
      delta: notification.scrollDelta ?? 0,
      minExtent: metrics.minScrollExtent,
      maxExtent: metrics.maxScrollExtent,
    );
    if (compact != was && mounted) setState(() {});
  }

  /// The observer also forwards layout changes as scroll updates. A nested
  /// list or an offstage tab can report offset zero without the reader
  /// returning to the content's start, so filter the source before feeding
  /// the shared compaction rule. Keep notifications available to everyone
  /// else: only this bar's listener ignores them.
  bool _isContentScroll(BuildContext? source) {
    if (source == null) return true;
    if (!TickerMode.getValuesNotifier(source).value.enabled) return false;
    var seenSource = false;
    var follows = true;
    source.visitAncestorElements((ancestor) {
      if (identical(ancestor, _contentScroll?.context)) return false;
      if (ancestor.widget case Offstage(offstage: true)) {
        follows = false;
        return false;
      }
      if (ancestor case StatefulElement(:final state)) {
        if (identical(state, this)) {
          follows = false;
          return false;
        }
        if (state is ScrollableState) {
          if (seenSource &&
              axisDirectionToAxis(state.axisDirection) == .vertical) {
            follows = false;
            return false;
          }
          seenSource = true;
        }
      }
      return true;
    });
    return follows;
  }

  /// The label position resolved against the layout mode default.
  CoreNavigationLabelPosition get _labelPosition =>
      widget.labelPosition ?? widget.mode.defaultLabelPosition;

  void _handleSelect(int destinationIndex) {
    widget.onSelected?.call(destinationIndex);
  }

  /// The rail's own scroll view reports whether its column fits. The report
  /// arrives after the frame that laid the column out, so re-deciding the
  /// moving selection here cannot mark the tree dirty mid-layout.
  bool _handleRailMetrics(ScrollMetricsNotification notification) {
    if (notification.depth != 0) return false;
    final overflows = notification.metrics.maxScrollExtent > 0;
    if (overflows != _railOverflows) {
      setState(() => _railOverflows = overflows);
    }
    return false;
  }

  /// A row-end badge reports its width from layout, where the widget tree
  /// cannot be marked dirty — the rebuild that re-decides fill or scroll
  /// waits for the end of the frame.
  void _handleRowEndBadgeWidth(int destinationIndex, double width) {
    if (_rowEndBadgeWidths[destinationIndex] == width) return;
    _rowEndBadgeWidths[destinationIndex] = width;
    if (_badgeWidthRebuildQueued) return;
    _badgeWidthRebuildQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _badgeWidthRebuildQueued = false;
      if (mounted) setState(() {});
    });
  }

  /// Estimated natural (unstretched) width of one destination — the
  /// bar-mode equal-fill decision's only input. Icon and label stack
  /// per [_labelPosition]: side by side when horizontal (width = icon +
  /// spacing + label), stacked otherwise (width = the wider of the two,
  /// matching the design's default vertical bar-item layout). A row-end
  /// badge follows the icon + label group after one label spacing.
  double _naturalItemWidth(
    BuildContext context, {
    required int destinationIndex,
    required CoreNavigationBarItem<Widget> item,
    required ResolvedNavigationBar resolved,
    required bool showLabel,
    required TextStyle labelStyle,
  }) {
    final hasIcon = item.icon != null;
    final label = item.label;
    final hasLabel = showLabel && label != null && label.isNotEmpty;
    double contentWidth;
    if (hasIcon && hasLabel) {
      final labelWidth = _measureTextWidth(context, label, labelStyle);
      contentWidth = _labelPosition.isHorizontal
          ? resolved.iconBoxSize + resolved.labelSpacing + labelWidth
          : math.max(_stackedIconWidth(resolved), labelWidth);
    } else if (hasIcon) {
      contentWidth = _labelPosition.isHorizontal
          ? resolved.iconBoxSize
          : _stackedIconWidth(resolved);
    } else if (hasLabel) {
      contentWidth = _measureTextWidth(context, label, labelStyle);
    } else {
      contentWidth = 0;
    }
    if (item.badge != null &&
        widget.mode.badgeAtRowEnd(hasIcon: item.icon != null)) {
      contentWidth +=
          resolved.labelSpacing + (_rowEndBadgeWidths[destinationIndex] ?? 0);
    }
    return resolved.itemPadding.horizontal + contentWidth;
  }

  /// A stacked destination's icon sits in its own box — the glyph plus the
  /// box's inset.
  double _stackedIconWidth(ResolvedNavigationBar resolved) =>
      resolved.iconBoxSize + resolved.iconAnchorPadding.horizontal;

  double _measureTextWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  MainAxisAlignment get _mainAxisAlignment {
    return switch (widget.alignment) {
      .start => .start,
      .center => .center,
      .end => .end,
      .spaceBetween => .spaceBetween,
      .spaceAround => .spaceAround,
      .spaceEvenly => .spaceEvenly,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveNavigationBar(
      context,
      mode: widget.mode,
      variant: widget.variant,
      indicator: widget.indicator,
      navigationBarStyle: widget.navigationBarStyle,
    );
    // The label display mode resolved against the default the bar's chrome
    // was drawn for — the same answer each composed [NavigationBarItem]
    // works out for itself. The floating glass rail hides its captions
    // unless the caller states otherwise.
    final labelMode =
        widget.labelMode ??
        widget.mode.defaultLabelModeFor(floatingGlass: resolved.floatingGlass);

    // Build the rendered children, tracking the running destination
    // index so selection counts destinations only. `naturalWidths` /
    // `growable` feed the bar-mode equal-fill decision below (index-
    // aligned with `children`) — collected in the same pass so a second
    // walk over `widget.items` isn't needed. Only a `.item` destination
    // is growable — a label / divider / gap keeps its own natural size
    // and only the destinations divide the remaining width, mirroring
    // how Web's `flex-1` (destinations only) coexists with fixed-size
    // siblings in the same flex row.
    final children = <Widget>[];
    final naturalWidths = <double>[];
    final growable = <bool>[];
    // The parts each destination draws — an icon, a caption, a badge beside
    // the caption. The rail's moving selection travels a column of equal
    // cells; destinations that draw different parts are different heights
    // (one caption under the selected glyph is enough), so the rail keeps
    // its resting selection then.
    final cellShapes = <(bool, bool, bool)>{};
    var destinationIndex = 0;
    for (final item in widget.items) {
      switch (item.kind) {
        case .item:
          final thisIndex = destinationIndex;
          destinationIndex += 1;
          // The current place, whether or not it can be activated: a
          // disabled destination keeps its selection mark, dimmed, and the
          // item decides what a disabled selection states.
          final selected =
              widget.selectedIndex != null && widget.selectedIndex == thisIndex;
          final showLabel = labelMode.showsLabel(selected: selected);
          final hasIcon = item.icon != null;
          cellShapes.add((
            hasIcon,
            showLabel && (item.label?.isNotEmpty ?? false),
            item.badge != null && widget.mode.badgeAtRowEnd(hasIcon: hasIcon),
          ));
          final labelStyle = !item.enabled
              ? selected
                    ? resolved.disabledSelectedLabelTextStyle
                    : resolved.disabledLabelTextStyle
              : selected
              ? resolved.selectedLabelTextStyle
              : resolved.labelTextStyle;
          naturalWidths.add(
            _naturalItemWidth(
              context,
              destinationIndex: thisIndex,
              item: item,
              resolved: resolved,
              showLabel: showLabel,
              labelStyle: labelStyle,
            ),
          );
          growable.add(true);
          // The bar composes the public item, handing it what it already
          // worked out for the row — the resolved chrome its width estimate
          // used, the destination's place, and (where the bar decides fill
          // or scroll) the badge-width report. The item owns its hover /
          // focus / press state, and asks the bar for nothing else.
          children.add(
            NavigationBarItem._(
              _NavigationItemComposition(
                resolved: resolved,
                index: thisIndex,
                onRowEndBadgeWidth: widget.mode == .bar
                    ? (width) => _handleRowEndBadgeWidth(thisIndex, width)
                    : null,
                // A bar with a compact form keeps each caption in a fold
                // from the start — whatever `compact` says now — so turning
                // compact folds the caption that is there rather than
                // rebuilding the destination around a missing one.
                captionFolded: resolved.hasCompactForm ? _compact : null,
              ),
              key: ValueKey<int>(thisIndex),
              icon: item.icon,
              label: item.label,
              badge: item.badge,
              tooltip: item.tooltip,
              selected: selected,
              enabled: item.enabled,
              onPressed: item.enabled ? () => _handleSelect(thisIndex) : null,
              mode: widget.mode,
              variant: widget.variant,
              labelMode: widget.labelMode,
              labelPosition: widget.labelPosition,
              overflow: widget.overflow,
              selectionMark: widget.selectionMark,
              indicator: widget.indicator,
              showDot: item.showDot,
              navigationBarStyle: widget.navigationBarStyle,
            ),
          );
        case .label:
          naturalWidths.add(
            resolved.sectionLabelPadding.horizontal +
                _measureTextWidth(
                  context,
                  item.label ?? '',
                  resolved.sectionLabelTextStyle,
                ),
          );
          growable.add(false);
          children.add(
            _NavigationSectionLabel(item: item, resolved: resolved),
          );
        case .divider:
          // Matches `_NavigationDividerLine`'s own layout for a
          // horizontal bar: a vertical line inset by `itemSpacing / 2`
          // on each side.
          naturalWidths.add(
            (resolved.dividerStyle.thickness ??
                    CoreDividerStyle.defaultThickness) +
                resolved.itemSpacing,
          );
          growable.add(false);
          children.add(
            _NavigationDividerLine(
              resolved: resolved,
              vertical: widget.mode.isVertical,
            ),
          );
        case .gap:
          // The width the `Gap` below paints — its own resolver, so the
          // estimate carries the same density step and size factor.
          naturalWidths.add(resolveGap(context, gapStyle: item.gapStyle).size);
          growable.add(false);
          children.add(Gap(gapStyle: item.gapStyle));
      }
    }

    // `RenderFlex` bills spacing as `spacing * (childCount - 1)`, so a
    // spaced flex holding nothing reports a *negative* intrinsic — which
    // Flutter documents as illegal and asserts on under
    // `debugCheckIntrinsicSizes`, taking down an otherwise legal empty
    // bar. There is no gap between fewer than two siblings, so there is
    // nothing to bill for: this is arithmetic, not a design decision, and
    // the spacing token itself is untouched.
    final itemSpacing = children.length > 1 ? resolved.itemSpacing : 0.0;

    // With a footer, the bar's padding wraps the items and the footer
    // together (the footer sits inside the chrome), so the items' own
    // layout carries none of it.
    final footer = widget.footer;
    final header = widget.header;
    final framed = footer != null || header != null;
    final itemsPadding = framed ? EdgeInsets.zero : resolved.padding;

    Widget content;
    if (widget.mode == .bar) {
      // Design states every destination FILLs — equal-width shares,
      // edge to edge, matching Web's `flex-1` — up to the destination's
      // `itemMaxWidth`, past which the shares stop growing and the row's
      // alignment places what is left over. That
      // only holds when the row's natural (unstretched) content already
      // fits the available width; once it doesn't, both platforms fall
      // back to natural per-item widths behind a horizontal scroll
      // (Web via `overflow-x-auto`) rather than squeezing icons/labels
      // below their own size. The two states are mutually exclusive —
      // `Expanded` cannot coexist with the scrollable branch's unbounded
      // width, so which one renders is decided once per layout pass.
      //
      // A label / divider / gap keeps its own fixed natural width in
      // both branches — only destinations (`growable`) divide whatever
      // width is left, exactly what Web's `flex-1` does next to a
      // fixed-size flex sibling.
      final itemMaxWidth = resolved.itemMaxWidth;
      final totalNaturalWidth = naturalWidths.isEmpty
          ? 0.0
          : naturalWidths.reduce((a, b) => a + b) +
                itemSpacing * (naturalWidths.length - 1);
      content = LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - itemsPadding.horizontal;
          final canFill =
              constraints.maxWidth.isFinite &&
              available > 0 &&
              totalNaturalWidth <= available;
          if (canFill) {
            // A destination's equal share stops at `itemMaxWidth`: past it
            // every destination takes the cap, and the row's alignment
            // places the width left over — so the destinations gather
            // instead of spreading. Below it they share as `Expanded` does.
            final growableCount = growable.where((v) => v).length;
            var fixedWidth = itemSpacing * (children.length - 1);
            for (var i = 0; i < children.length; i++) {
              if (!growable[i]) fixedWidth += naturalWidths[i];
            }
            final capped =
                itemMaxWidth.isFinite &&
                growableCount > 0 &&
                (available - fixedWidth) / growableCount > itemMaxWidth;
            // The moving glass selection tracks the destinations across the
            // whole row; a footer takes part of that row, so the bar keeps
            // its resting selection then (as on Web). It also measures every
            // destination as an equal share of the whole row, so a row its
            // cap leaves short of the edges (a caller's cap under glass)
            // keeps the resting selection too.
            final movingSelection =
                resolved.floatingGlass &&
                !framed &&
                !capped &&
                growable.every((v) => v);
            // The row itself admits a pointer across `touchTargetSize`: a
            // row of icon-only destinations paints shorter than that, and a
            // destination's own `TouchTarget` only sees a pointer its
            // ancestors let through. Clamped inside, the pointer reaches the
            // destination under it.
            final row = TouchTarget(
              minimum: resolved.touchTargetSize,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: _mainAxisAlignment,
                  crossAxisAlignment: .stretch,
                  spacing: itemSpacing,
                  children: [
                    for (var i = 0; i < children.length; i++)
                      if (!growable[i])
                        children[i]
                      else if (capped)
                        SizedBox(width: itemMaxWidth, child: children[i])
                      else
                        Expanded(child: children[i]),
                  ],
                ),
              ),
            );
            return Padding(
              padding: itemsPadding,
              child: !movingSelection || children.isEmpty
                  ? row
                  : _GlassNavigationTrack(
                      selectedIndex: widget.selectedIndex,
                      enabled: [for (final item in widget.items) item.enabled],
                      onSelected: widget.onSelected,
                      resolved: resolved,
                      swell: _swell,
                      child: row,
                    ),
            );
          }
          // The scrolling row's main axis is unbounded: its destinations
          // keep their natural widths and nothing in them can take a
          // flexible share of leftover room.
          final row = _NavigationRowExtent(
            unbounded: true,
            child: TouchTarget(
              minimum: resolved.touchTargetSize,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: _mainAxisAlignment,
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  spacing: itemSpacing,
                  children: children,
                ),
              ),
            ),
          );
          return SingleChildScrollView(
            scrollDirection: .horizontal,
            padding: itemsPadding,
            child: constraints.maxWidth.isFinite && available > 0
                ? ConstrainedBox(
                    constraints: BoxConstraints(minWidth: available),
                    child: row,
                  )
                : row,
          );
        },
      );
    } else {
      final column = IntrinsicWidth(
        child: Column(
          mainAxisAlignment: _mainAxisAlignment,
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: itemSpacing,
          children: children,
        ),
      );
      // The glass rail's lens travels its destinations the way the bar's
      // does, down the column. It needs a column of equal cells that is all
      // in view: a header or footer shares the column, a label / divider /
      // gap breaks the run, destinations that draw different parts are
      // different heights, and a column that scrolls needs its drag for
      // scrolling. Any of those and the rail keeps its resting selection —
      // the selected destination's own face — as the bar does when its row
      // cannot share out equal cells.
      final movingSelection =
          resolved.floatingGlass &&
          !framed &&
          children.isNotEmpty &&
          growable.every((v) => v) &&
          cellShapes.length == 1 &&
          !_railOverflows;
      final cells = movingSelection
          ? _GlassNavigationTrack(
              axis: .vertical,
              selectedIndex: widget.selectedIndex,
              enabled: [for (final item in widget.items) item.enabled],
              onSelected: widget.onSelected,
              resolved: resolved,
              swell: _swell,
              child: column,
            )
          : column;
      final scroller = SingleChildScrollView(
        padding: itemsPadding,
        // The lens swells past its cell while it is held; a column that is
        // all in view has nothing to clip, and clipping it would cut the
        // lens off at the capsule's box.
        clipBehavior: movingSelection ? .none : .hardEdge,
        // The column itself admits a pointer across `touchTargetSize`: the
        // glass rail's destinations paint narrower than that, and a
        // destination's own `TouchTarget` only sees a pointer its ancestors
        // let through. Outside the track, so the track's own box does not
        // turn the pointer away first.
        child: _labelPosition.isHorizontal
            ? cells
            : TouchTarget(minimum: resolved.touchTargetSize, child: cells),
      );
      content = resolved.floatingGlass
          ? NotificationListener<ScrollMetricsNotification>(
              onNotification: _handleRailMetrics,
              child: scroller,
            )
          : scroller;
    }

    if (framed) {
      content = _NavigationFooterLayout(
        vertical: widget.mode.isVertical,
        padding: resolved.padding,
        spacing: resolved.itemSpacing,
        header: header,
        items: content,
        footer: footer,
      );
    }

    // A `Container` rather than a `ColoredBox` because the bar can now
    // detach and round its own corners — a floating bar reads as one
    // object, and padding cannot express the detachment (padding moves
    // the items and leaves the bar's box where it was).
    //
    // Zero margin and zero radius reproduce the previous `ColoredBox`
    // exactly, so a bar docked to an edge is unchanged.
    // `SurfaceBlur` is the same primitive the surface container uses, so
    // a material preset produces one blur implementation rather than a
    // second one that drifts. It is a no-op when the sigma is absent.
    final capsule = SurfaceBlur(
      borderRadius: resolved.barRadius,
      surfaceBlur: resolved.surfaceBlur,
      surfaceSaturation: resolved.surfaceSaturation,
      surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
      surfaceSheen: resolved.surfaceSheen,
      // The active material's bend. Every surface that draws the material
      // draws all of it — the frost and the chroma without the bend is a
      // blurred panel, not glass, and the bend is the term the material
      // is named for.
      //
      // Falls back rather than being required: a style that states no
      // refraction leaves this null and the surface simply does not
      // bend, which is how every preset but glass renders.
      refraction: resolved.refraction,
      child: Container(
        decoration: BoxDecoration(
          color: resolved.backgroundColor,
          // `BoxDecoration.border` painting distinguishes a literal
          // `null` radius from `BorderRadius.zero` for a non-uniform
          // border (this one — a coloured edge plus three
          // `BorderSide.none` sides): a square bar must pass `null`
          // or the paint-time assertion fires even though zero draws
          // the same rectangle either way. A rounded (floating) bar
          // passes the real value and Flutter mitres the hairline
          // around the corner it actually has.
          borderRadius: resolved.barRadius == BorderRadius.zero
              ? null
              : resolved.barRadius,
          border: resolved.barBorder,
        ),
        // The horizontal bar's hairline lies over its top padding, so
        // it does not add to the bar's height (see `barHairline`).
        // Painted by a foreground box inside the bar's own decoration
        // (not `Container.foregroundDecoration`, which would wrap it):
        // the bar's face stays the outermost decorated box, the one a
        // tree reader takes for the bar.
        child: resolved.barHairline.top == BorderSide.none
            ? content
            : DecoratedBox(
                position: .foreground,
                decoration: BoxDecoration(
                  borderRadius: resolved.barRadius == BorderRadius.zero
                      ? null
                      : resolved.barRadius,
                  border: resolved.barHairline,
                ),
                child: content,
              ),
      ),
    );
    final bar = Semantics(
      container: true,
      label: CoUILocalizations.of(context).navigationLabel,
      child: Padding(
        padding: resolved.barMargin,
        // The compact size is drawn, not laid out: beyond the captions its
        // destinations fold away, the bar keeps its room. It shrinks toward
        // the edge it sits on — the bottom for the horizontal bar; a
        // column's edge is its shell's to know, so it shrinks about its
        // centre. Always in the tree, at scale 1 the identity, so a bar that
        // turns compact keeps its subtree.
        child: AnimatedScale(
          scale: _compact ? resolved.compactScale : 1,
          alignment: widget.mode.isVertical ? .center : .bottomCenter,
          duration: resolved.compactDuration,
          curve: CoreEasing.move.toValue(),
          // The floating glass bar grows a little while its lens is up
          // (`CoreGlassNavigationMotion.barSwell`); no other bar has a lens.
          child: resolved.floatingGlass
              ? _GlassBarSwellTransform(
                  swell: _swell,
                  axis: widget.mode.isVertical ? .vertical : .horizontal,
                  child: capsule,
                )
              : capsule,
        ),
      ),
    );
    return resolved.isGlass && widget.mode == CoreNavigationBarMode.bar
        ? SafeArea(top: false, child: bar)
        : bar;
  }
}

/// Marks the subtree of a row laid out along an unbounded main axis.
///
/// The bar's scrolling branch gives its destinations no bounded width, and a
/// flex child of an unbounded row throws — a destination reads this to hold
/// its own contents at their natural width instead of sharing out room that
/// is not there. Anywhere outside the scrolling branch the width is bounded.
class _NavigationRowExtent extends InheritedWidget {
  const _NavigationRowExtent({required this.unbounded, required super.child});

  /// Whether the row's main axis is unbounded.
  final bool unbounded;

  /// Whether the row above [context] is laid out on an unbounded main axis.
  static bool unboundedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_NavigationRowExtent>()
            ?.unbounded ??
        false;
  }

  @override
  bool updateShouldNotify(_NavigationRowExtent oldWidget) =>
      unbounded != oldWidget.unbounded;
}

/// Reports the width its child lays out to, each time that width changes.
///
/// A badge is a caller widget; this is the one place its real width is
/// learned. The report is made from layout, so it only records — it does
/// not mark anything dirty.
class _RowEndBadgeWidth extends SingleChildRenderObjectWidget {
  const _RowEndBadgeWidth({required this.onWidth, required Widget super.child});

  /// Receives the child's width after layout.
  final ValueChanged<double> onWidth;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRowEndBadgeWidth(onWidth);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRowEndBadgeWidth renderObject,
  ) {
    renderObject.onWidth = onWidth;
  }
}

class _RenderRowEndBadgeWidth extends RenderProxyBox {
  _RenderRowEndBadgeWidth(this.onWidth);

  ValueChanged<double> onWidth;

  /// The last width handed to [onWidth].
  double? _reportedWidth;

  @override
  void performLayout() {
    super.performLayout();
    final width = size.width;
    if (width == _reportedWidth) return;
    _reportedWidth = width;
    onWidth(width);
  }
}

/// Places the items and the bar's `footer` inside the bar chrome.
///
/// The footer sits after the items at the end of the main axis — the
/// bottom of a rail or sidebar, the trailing end of a horizontal bar. When
/// the parent fixes the bar's length along that axis (a sized box, a
/// stretched cell), the items take the room the footer leaves and scroll
/// when they need more, so the footer lands on the far edge and stays put.
/// Left to size itself — a loose or unbounded constraint — a vertical bar is
/// as tall as its items and footer together (the items give up room to the
/// footer, and scroll, only once the bounds run out). The bar's padding
/// wraps both.
class _NavigationFooterLayout extends StatelessWidget {
  const _NavigationFooterLayout({
    required this.vertical,
    required this.padding,
    required this.spacing,
    required this.header,
    required this.items,
    required this.footer,
  });

  final bool vertical;
  final EdgeInsets padding;
  final double spacing;
  final Widget? header;
  final Widget items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = vertical
            ? constraints.maxHeight.isFinite
            : constraints.maxWidth.isFinite;
        // A vertical bar spans the room it is given only when its height is
        // pinned; the horizontal bar's destinations already share the
        // bounded width, so it spans that.
        final spans = vertical ? constraints.hasTightHeight : bounded;
        final itemsSlot = spans
            ? Expanded(child: items)
            : bounded
            ? Flexible(child: items)
            : items;
        final children = [?header, itemsSlot, ?footer];
        return Padding(
          padding: padding,
          child: vertical
              ? IntrinsicWidth(
                  child: Column(
                    mainAxisSize: spans ? .max : .min,
                    crossAxisAlignment: .stretch,
                    spacing: spacing,
                    children: children,
                  ),
                )
              : Row(
                  mainAxisSize: spans ? .max : .min,
                  spacing: spacing,
                  children: children,
                ),
        );
      },
    );
  }
}

/// A non-selectable section header label.
class _NavigationSectionLabel extends StatelessWidget {
  const _NavigationSectionLabel({required this.item, required this.resolved});

  final CoreNavigationBarItem<Widget> item;
  final ResolvedNavigationBar resolved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: resolved.sectionLabelPadding,
      child: Text(
        item.label ?? '',
        style: resolved.sectionLabelTextStyle,
      ),
    );
  }
}

/// A separating divider line between navigation items.
///
/// The line itself is a nested [Divider] that self-resolves from the
/// passthrough [ResolvedNavigationBar.dividerStyle]; the `itemSpacing / 2`
/// inset stays on the surrounding `Padding` layout wrapper, mirroring the
/// Web `<div>` margin box around the divider.
class _NavigationDividerLine extends StatelessWidget {
  const _NavigationDividerLine({
    required this.resolved,
    required this.vertical,
  });

  final ResolvedNavigationBar resolved;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final inset = resolved.itemSpacing / 2;
    // In a vertical layout the divider is a horizontal line spanning the
    // cross-axis; in a horizontal bar it is a vertical line.
    final line = Divider(
      orientation: vertical ? .horizontal : .vertical,
      dividerStyle: resolved.dividerStyle,
    );
    return vertical
        ? Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: inset),
            child: line,
          )
        : Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
            child: line,
          );
  }
}

/// Local interaction state: dragging repaints this track, not the whole bar.
///
/// One track serves both floating glass containers — the bar's row
/// ([Axis.horizontal]) and the rail's column ([Axis.vertical]). The lens's
/// motion, its resistance at either end and the rule for committing a drag
/// are the same on both; only the coordinate read off the pointer differs.
class _GlassNavigationTrack extends StatefulWidget {
  const _GlassNavigationTrack({
    required this.selectedIndex,
    required this.enabled,
    required this.onSelected,
    required this.resolved,
    required this.swell,
    required this.child,
    this.axis = Axis.horizontal,
  });
  final int? selectedIndex;
  final List<bool> enabled;
  final ValueChanged<int>? onSelected;
  final ResolvedNavigationBar resolved;

  /// Where the track hands its bar's swell to the capsule above it.
  final _GlassBarSwell swell;

  final Widget child;

  /// The axis the destinations run along.
  final Axis axis;

  @override
  State<_GlassNavigationTrack> createState() => _GlassNavigationTrackState();
}

class _GlassNavigationTrackState extends State<_GlassNavigationTrack>
    with SingleTickerProviderStateMixin {
  int? _pointer;
  bool _dragging = false;
  double? _position;
  double _grabOffset = 0;

  /// The row's width, as its last build was given it. Unread on a column.
  double _rowExtent = 0;
  late final _GlassNavigationMotion _motion = _GlassNavigationMotion(
    this,
    widget.selectedIndex?.toDouble() ?? 0,
  );

  /// Whether the row runs from the right, as its last build was told.
  bool _rtl = false;

  bool get _vertical => widget.axis == Axis.vertical;

  /// The track's length along its axis.
  ///
  /// The bar's row is given its width before it builds. The rail's column is
  /// as tall as its cells, which only layout knows, so that one is read off
  /// the track's own box — by the pointer handlers, which run after layout,
  /// and never during build.
  double get _mainExtent => _vertical ? context.size!.height : _rowExtent;

  @override
  void initState() {
    super.initState();
    _motion.addListener(_publishSwell);
  }

  @override
  void dispose() {
    // A track that goes while its bar is swollen hands the bar back at rest —
    // after the frame, because the tree is locked while it is torn down.
    final swell = widget.swell;
    if (swell.scale != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => swell.update(1, .5));
    }
    _motion.dispose();
    super.dispose();
  }

  /// Hands the motion's swell to the capsule: the scale, and where along the
  /// capsule it grows from — the point `CoreGlassNavigationMotion` mirrors
  /// from the lens's centre.
  ///
  /// The lens is placed in the capsule's own box, so whatever lies between
  /// the two — the bar's padding, the capsule's border — is counted as it is
  /// laid out. Runs on the motion's clock, after the frame that laid both
  /// out.
  void _publishSwell() {
    if (!mounted) return;
    final track = context.findRenderObject();
    final capsule = widget.swell.capsuleKey.currentContext?.findRenderObject();
    if (track is! RenderBox || !track.hasSize) return;
    if (capsule is! RenderBox || !capsule.hasSize) return;
    final count = widget.enabled.length;
    final spacing = widget.resolved.itemSpacing;
    final extent = _vertical ? track.size.height : track.size.width;
    final cell = (extent - spacing * (count - 1)) / count;
    // From the start edge: a row in a right-to-left locale starts at its
    // right.
    final lens = cell / 2 + _motion.position.value * (cell + spacing);
    final centre = track.localToGlobal(
      _vertical
          ? Offset(track.size.width / 2, lens)
          : Offset(_rtl ? extent - lens : lens, track.size.height / 2),
      ancestor: capsule,
    );
    final length = _vertical ? capsule.size.height : capsule.size.width;
    widget.swell.update(
      _motion.barScale,
      length > 0
          ? CoreGlassNavigationMotion.barSwellOrigin(
              (_vertical ? centre.dy : centre.dx) / length,
            )
          : .5,
    );
  }

  @override
  void didUpdateWidget(_GlassNavigationTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        !listEquals(oldWidget.enabled, widget.enabled) ||
        widget.onSelected == null) {
      _pointer = null;
      _dragging = false;
      _position = null;
      _motion.release(widget.selectedIndex?.toDouble() ?? 0);
    }
  }

  void _handleCancel() {
    if (_pointer == null && _position == null) return;
    _motion.release(widget.selectedIndex?.toDouble() ?? 0);
    setState(() {
      _pointer = null;
      _dragging = false;
      _position = null;
    });
  }

  /// Where [global] falls on the track as it is laid out, before the bar's
  /// swell.
  ///
  /// The swell is drawn only: the pointer is read as if the bar were at
  /// rest, so a finger that stays where it chose a destination keeps that
  /// destination while the bar grows around it, and where the lens goes does
  /// not depend on the point the bar grows from — which follows the lens.
  Offset _laidOut(Offset global) {
    final track = context.findRenderObject()! as RenderBox;
    final swell = widget.swell;
    final capsule = swell.capsuleKey.currentContext?.findRenderObject();
    if (swell.scale == 1 || capsule is! RenderBox || !capsule.hasSize) {
      return track.globalToLocal(global);
    }
    // Where the finger is on the capsule as drawn, scaled back out about the
    // point the capsule is drawn grown from.
    final size = capsule.size;
    final origin = _vertical
        ? Offset(size.width / 2, swell.origin * size.height)
        : Offset(swell.origin * size.width, size.height / 2);
    final drawn = capsule.globalToLocal(global);
    final laidOut = origin + (drawn - origin) * swell.scale;

    return laidOut - track.localToGlobal(Offset.zero, ancestor: capsule);
  }

  /// Where [point] falls along the track, in destinations — 0 at the first
  /// destination's centre, 1 at the second's.
  ///
  /// A row counts from its start edge, the right-hand one in a right-to-left
  /// locale. A column counts from the top in either.
  double _logicalPosition(Offset point) {
    final extent = _mainExtent;
    final count = widget.enabled.length;
    final spacing = widget.resolved.itemSpacing;
    final cell = (extent - spacing * (count - 1)) / count;
    final along = _vertical
        ? point.dy
        : Directionality.of(context) == TextDirection.rtl
        ? extent - point.dx
        : point.dx;
    return (along - cell / 2) / (cell + spacing);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null || event.buttons != kPrimaryButton) return;
    final position = _logicalPosition(_laidOut(event.position));
    final index = position.round().clamp(0, widget.enabled.length - 1);
    if (!widget.enabled[index]) return;
    setState(() {
      _pointer = event.pointer;
      _position = index.toDouble();
      _grabOffset = position - index;
      _motion.moveTo(index.toDouble(), held: true);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _pointer && !_dragging) _handleCancel();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _handleCancel();
  }

  void _move(Offset point) {
    if (_pointer == null) return;
    final raw = _logicalPosition(point) - _grabOffset;
    final bounded = raw.clamp(0.0, widget.enabled.length - 1.0);
    final excess = raw - bounded;
    // Smooth resistance at either end; visual overscroll never becomes an
    // out-of-range selection or grows without bound.
    final resisted = bounded + .22 * excess / (excess.abs() + .55);
    setState(() {
      _position = resisted;
      _motion.moveTo(resisted, held: true);
    });
  }

  void _handleDragStart(DragStartDetails details) {
    if (_pointer == null) return;
    _dragging = true;
    _move(_laidOut(details.globalPosition));
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _move(_laidOut(details.globalPosition));
  }

  void _handleDragEnd(DragEndDetails details) {
    final candidate = _position?.round().clamp(0, widget.enabled.length - 1);
    _motion.release(widget.selectedIndex?.toDouble() ?? 0);
    setState(() {
      _pointer = null;
      _dragging = false;
      _position = null;
    });
    // The host owns selection. If it declines the callback the lens returns
    // to that selection; an accepted value retargets the same live spring.
    if (candidate != null &&
        widget.enabled[candidate] &&
        candidate != widget.selectedIndex) {
      widget.onSelected?.call(candidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vertical) return _buildTrack(rowExtent: null);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildTrack(rowExtent: constraints.maxWidth),
    );
  }

  /// Builds the track. [rowExtent] is the row's width; `null` for a column,
  /// whose length is not known until it has been laid out.
  Widget _buildTrack({required double? rowExtent}) {
    final count = widget.enabled.length;
    final spacing = widget.resolved.itemSpacing;
    if (rowExtent != null) _rowExtent = rowExtent;
    _rtl = !_vertical && Directionality.of(context) == TextDirection.rtl;
    _motion.configure(
      reduced: widget.resolved.duration == Duration.zero,
      // The distance between two destinations' centres. The row's is known
      // here. The column's is not until it has been laid out: the selection
      // indicator states it then (`_GlassSelectionIndicator`), and until it
      // has the motion keeps the distance it last knew.
      itemExtent: rowExtent == null
          ? _motion.itemExtent
          : (rowExtent - spacing * (count - 1)) / count + spacing,
    );
    // The motion can come to rest without its clock ticking — reduced motion
    // snaps it — and the capsule above has already been built this frame, so
    // the swell it draws is put right after the frame.
    if (widget.swell.scale != _motion.barScale) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _publishSwell());
    }
    final selected = widget.selectedIndex;
    final valid =
        selected != null &&
        selected >= 0 &&
        selected < widget.enabled.length &&
        widget.enabled[selected];
    final enabled =
        widget.onSelected != null && widget.enabled.any((value) => value);
    final optical =
        widget.resolved.selectionRefraction != null &&
        (webSurfaceRefractionSupported ||
            (SurfaceRefractionProgram.loaded != null &&
                ui.ImageFilter.isShaderFilterSupported));
    final track = AnimatedBuilder(
      animation: _motion,
      child: widget.child,
      builder: (context, child) => _NavigationSelectionScope(
        lensPosition: _motion.activation > 0 || _position != null
            ? _motion.position.value
            : null,
        opticalLens: optical,
        child: Stacks(
          clipBehavior: .none,
          children: [
            if (_position != null || valid)
              Position.fill(
                child: IgnorePointer(
                  child: _GlassSelectionIndicator(
                    axis: widget.axis,
                    motion: _motion,
                    count: widget.enabled.length,
                    spacing: widget.resolved.itemSpacing,
                    color: widget.resolved.selectedBackgroundColor,
                    radius: widget.resolved.itemRadius,
                  ),
                ),
              ),
            child!,
            if (_position != null || valid)
              Position.fill(
                child: IgnorePointer(
                  child: _GlassSelectionIndicator(
                    axis: widget.axis,
                    motion: _motion,
                    count: widget.enabled.length,
                    spacing: widget.resolved.itemSpacing,
                    color: widget.resolved.selectedBackgroundColor,
                    radius: widget.resolved.itemRadius,
                    overlay: true,
                    refraction: optical
                        ? widget.resolved.selectionRefraction
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!enabled) return track;
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        // The lens follows a drag along the track's own axis; a drag across
        // it is left to whatever is underneath.
        onHorizontalDragStart: _vertical ? null : _handleDragStart,
        onHorizontalDragUpdate: _vertical ? null : _handleDragUpdate,
        onHorizontalDragEnd: _vertical ? null : _handleDragEnd,
        onHorizontalDragCancel: _vertical ? null : _handleCancel,
        onVerticalDragStart: _vertical ? _handleDragStart : null,
        onVerticalDragUpdate: _vertical ? _handleDragUpdate : null,
        onVerticalDragEnd: _vertical ? _handleDragEnd : null,
        onVerticalDragCancel: _vertical ? _handleCancel : null,
        child: track,
      ),
    );
  }
}

/// Keeps visual drag preview separate from committed accessibility selection.
class _NavigationSelectionScope extends InheritedWidget {
  const _NavigationSelectionScope({
    required super.child,
    this.lensPosition,
    this.opticalLens = false,
  });
  final double? lensPosition;
  final bool opticalLens;
  @override
  bool updateShouldNotify(_NavigationSelectionScope oldWidget) =>
      lensPosition != oldWidget.lensPosition ||
      opticalLens != oldWidget.opticalLens;
}

/// Resting fill and optical overlay share one physical geometry and clock.
class _GlassSelectionIndicator extends StatelessWidget {
  const _GlassSelectionIndicator({
    required this.motion,
    required this.count,
    required this.spacing,
    required this.color,
    required this.radius,
    this.axis = Axis.horizontal,
    this.overlay = false,
    this.refraction,
  });
  final _GlassNavigationMotion motion;
  final int count;
  final double spacing;
  final Color color;
  final BorderRadius radius;

  /// The axis the lens travels — the track's.
  final Axis axis;
  final bool overlay;
  final CoreSurfaceRefraction? refraction;
  static final _identityMaterial = ui.ImageFilter.matrix(
    Matrix4.identity().storage,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final vertical = axis == Axis.vertical;
      // The destinations share the track's axis equally. One cell is the
      // lens at rest: a cell long, and as wide as the track is across.
      final along =
          ((vertical ? constraints.maxHeight : constraints.maxWidth) -
              spacing * (count - 1)) /
          count;
      final across = vertical ? constraints.maxWidth : constraints.maxHeight;
      final cell = vertical ? Size(across, along) : Size(along, across);
      // A column's cell is first known here, once the column has been laid
      // out — a row's track states the same distance before it builds.
      if (vertical) motion.itemExtent = along + spacing;
      final lift = motion.activation;
      final energy = motion.energy * lift;
      // A row runs from its start edge; a column runs down in either
      // direction.
      final rtl = !vertical && Directionality.of(context) == TextDirection.rtl;
      final direction = motion.direction * (rtl ? -1 : 1);
      // Pressure expands the lens; travel squashes along motion and bulges
      // across it. Actual bounds change, so the shader and rounded corners use
      // the same geometry instead of stretching a previously painted texture.
      final lensAlong = along * (1 + .06 * lift - .10 * energy);
      final lensAcross = across * (1 + .18 * lift + .18 * energy);
      final lensSize = vertical
          ? Size(lensAcross, lensAlong)
          : Size(lensAlong, lensAcross);
      final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
      final rimColor = Theme.of(context).colorScheme
          .resolve(const CoreColor.token(CoreColors.onSurface))
          .toValue();
      if (overlay && lift == 0) return const SizedBox.shrink();
      // The light falls from above and leans the way the lens travels.
      final lean = .3 * direction;
      final decoration = DecoratedBox(
        key: ValueKey(
          overlay ? 'coui-navigation-lens' : 'coui-navigation-selection',
        ),
        decoration: BoxDecoration(
          color: overlay ? null : color.withValues(alpha: color.a * (1 - lift)),
          borderRadius: radius,
          border: !overlay
              ? null
              : Border.all(
                  color: rimColor.withValues(
                    alpha: (highContrast ? .7 : .22) * lift,
                  ),
                ),
          gradient: !overlay || highContrast
              ? null
              : LinearGradient(
                  begin: vertical
                      ? Alignment(-.7, -1 + lean)
                      : Alignment(-.7 + lean, -1),
                  end: vertical
                      ? Alignment(.7, 1 + lean)
                      : Alignment(.7 + lean, 1),
                  colors: [
                    const Color(0xFFFFFFFF).withValues(alpha: .14 * lift),
                    const Color(0xFFFFFFFF).withValues(alpha: .015 * lift),
                  ],
                ),
        ),
        child: SizedBox.fromSize(size: lensSize),
      );
      Widget lens = decoration;
      final program = SurfaceRefractionProgram.loaded;
      final profile = refraction;
      if (overlay && profile != null) {
        // Smooth activation suppresses small spring ripples in magnification.
        // Shape may wobble without making the text shimmer independently.
        final optical = 1 - (1 - lift) * (1 - lift);
        if (webSurfaceRefractionSupported) {
          lens = WebSurfaceBackdrop(
            key: const ValueKey('coui-navigation-web-optical-lens'),
            refraction: profile,
            borderRadius: radius,
            activation: optical,
            mapSize: cell,
            child: decoration,
          );
        } else if (program != null) {
          lens = ClipRRect(
            borderRadius: radius,
            child: SurfaceBackdrop(
              key: const ValueKey('coui-navigation-optical-lens'),
              material: _identityMaterial,
              program: program,
              refraction: profile.copyWith(
                strength: profile.strength * optical,
                lens: profile.lens * optical,
                dispersion: profile.dispersion * optical,
              ),
              cornerRadius: math.min(
                radius.topLeft.x,
                lensSize.shortestSide / 2,
              ),
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
              child: decoration,
            ),
          );
        }
      }
      final travel = motion.position.value * (along + spacing);
      return Align(
        alignment: vertical
            ? Alignment.topCenter
            : AlignmentDirectional.centerStart,
        child: Transform.translate(
          offset: vertical
              ? Offset(0, travel)
              : Offset(rtl ? -travel : travel, 0),
          child: SizedBox.fromSize(
            size: cell,
            child: OverflowBox(
              minWidth: lensSize.width,
              maxWidth: lensSize.width,
              minHeight: lensSize.height,
              maxHeight: lensSize.height,
              child: lens,
            ),
          ),
        ),
      );
    },
  );
}
