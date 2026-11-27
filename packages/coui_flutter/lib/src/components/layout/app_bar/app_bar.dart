import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/toolbar_group/toolbar_group_internal.dart';

/// A unified cross-platform application bar.
///
/// `AppBar` lays out a leading cluster, an optional centre area
/// (`title` / `header` / `subtitle`, or a custom `child`) and a
/// trailing cluster, and owns its own chrome: surface colour, bar
/// height, cluster spacing, title typography, the bottom hairline
/// divider and the elevated drop shadow all flow through the single
/// [appBarStyle] field — see [CoreAppBarStyle] for the merge chain.
/// Semantic fields ([variant]) and behaviour flags ([trailingExpanded] /
/// [centerTitle] / [showDivider] / [elevated] / [actionsAxis]) stay flat on
/// the widget.
///
/// The [variant] selects the bar shape: `standard` (64px single row),
/// `compact` (56px single row), `medium` (112px — a 48px top row of
/// leading / actions above a bottom-aligned large title), `dense`
/// (48px single row — the desktop window / tool bar) or `prominent`
/// (56px single row with one large start-aligned title — a tab's first
/// screen).
///
/// Shares its core contract with Web; [scrollController] is Flutter-specific.
///
/// ```dart
/// AppBar(
///   variant: CoreAppBarVariant.medium,
///   leading: [Button(variant: .ghost, child: Icon(LucideIcons.arrowLeft))],
///   title: const Text('Dashboard'),
/// )
/// ```
///
/// surface:behind — floating app chrome sits above scrolling page content.
/// surface:functional — the bar groups navigation and actions above the page.
class AppBar extends StatelessWidget implements CoreAppBarContract<Widget> {
  /// Creates a [AppBar].
  const AppBar({
    super.key,
    this.title,
    this.header,
    this.subtitle,
    this.leading = const [],
    this.trailing = const [],
    this.variant = CoreAppBarVariant.defaultVariant,
    this.trailingExpanded = CoreAppBarContract.defaultTrailingExpanded,
    this.centerTitle = CoreAppBarContract.defaultCenterTitle,
    this.showDivider = CoreAppBarContract.defaultShowDivider,
    this.elevated = CoreAppBarContract.defaultElevated,
    this.actionsAxis = CoreAppBarContract.defaultActionsAxis,
    this.appBarStyle,
    this.scrollController,
    this.child,
  }) : assert(
         child == null || title == null,
         'Cannot provide both child and title',
       );

  /// The primary title content of the bar.
  @override
  final Widget? title;

  /// Secondary content placed above the [title].
  @override
  final Widget? header;

  /// Secondary content placed below the [title].
  @override
  final Widget? subtitle;

  /// Custom centre content — overrides [title] / [header] / [subtitle].
  @override
  final Widget? child;

  /// Widgets in the leading (start) cluster.
  @override
  final List<Widget> leading;

  /// Widgets in the trailing (end) cluster.
  @override
  final List<Widget> trailing;

  /// Bar shape variant (standard / compact / medium / dense / prominent).
  @override
  final CoreAppBarVariant variant;

  /// Whether the trailing cluster expands to fill remaining space.
  @override
  final bool trailingExpanded;

  /// Whether the title is centred instead of start-aligned.
  @override
  final bool centerTitle;

  /// Whether the bottom hairline divider is drawn.
  @override
  final bool showDivider;

  /// Whether the elevated drop shadow is drawn.
  @override
  final bool elevated;

  /// Where the bar's actions stand: in the bar's row (the default), or in
  /// a column beside the content.
  ///
  /// Under `vertical` the bar draws only the [leading] and [trailing]
  /// actions marked `BarAction(axisBehavior: horizontalOnly)`; a
  /// `ToolbarGroup(direction: vertical)` given the same two lists draws the
  /// rest. Enable Scaffold.adaptiveAppBarActions to let the scaffold
  /// detect a reserved right strip and host the column automatically.
  @override
  final CoreAxis actionsAxis;

  /// Per-instance chrome / dimensional style. See [CoreAppBarStyle] for
  /// the merge chain.
  @override
  final CoreAppBarStyle? appBarStyle;

  /// Optional body scroll controller for the glass scroll-edge transition.
  /// The soft edge gains contrast as content moves below the clear title
  /// host. Action capsules retain their glass at rest. The caller owns this
  /// controller; use a floating scaffold header.
  final ScrollController? scrollController;

  /// Returns a copy with the supplied fields replaced.
  AppBar copyWith({
    Key? key,
    Widget? title,
    Widget? header,
    Widget? subtitle,
    Widget? child,
    List<Widget>? leading,
    List<Widget>? trailing,
    CoreAppBarVariant? variant,
    bool? trailingExpanded,
    bool? centerTitle,
    bool? showDivider,
    bool? elevated,
    CoreAxis? actionsAxis,
    CoreAppBarStyle? appBarStyle,
    ScrollController? scrollController,
  }) => AppBar(
    key: key ?? this.key,
    title: title ?? this.title,
    header: header ?? this.header,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    variant: variant ?? this.variant,
    trailingExpanded: trailingExpanded ?? this.trailingExpanded,
    centerTitle: centerTitle ?? this.centerTitle,
    showDivider: showDivider ?? this.showDivider,
    elevated: elevated ?? this.elevated,
    actionsAxis: actionsAxis ?? this.actionsAxis,
    appBarStyle: appBarStyle ?? this.appBarStyle,
    scrollController: scrollController ?? this.scrollController,
    child: child ?? this.child,
  );

  @override
  Widget build(BuildContext context) => _buildBar(context);

  Widget _buildBar(BuildContext context) {
    final resolved = resolveAppBar(
      context,
      variant: variant,
      appBarStyle: appBarStyle,
    );

    // A centred single-row title sits on the whole bar, so it has one line
    // to fit between the clusters — `trailingExpanded` leaves it no room to
    // centre in (the trailing cluster takes the rest), and `medium` owns a
    // row of its own.
    final barCentered = centerTitle && !trailingExpanded && variant != .medium;
    final titleWidget = title == null
        ? null
        : DefaultTextStyle.merge(
            style: resolved.titleTextStyle,
            textAlign: centerTitle ? .center : null,
            maxLines: barCentered ? 1 : null,
            overflow: barCentered ? .ellipsis : null,
            child: _AppBarRouteTitle(child: title!),
          );

    final center =
        child ??
        Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: centerTitle ? .center : .stretch,
          children: [?header, ?titleWidget, ?subtitle],
        );

    final glass = resolved.actionCapsuleStyle != null;
    Widget? cluster(List<Widget> actions) {
      if (actions.isEmpty) return null;
      if (!glass) {
        return Row(
          mainAxisSize: .min,
          spacing: resolved.actionSpacing,
          children: actions,
        );
      }
      // Explicit groups already own their optical surface. Only contiguous
      // ungrouped actions share a new capsule; never put a platter around one.
      final groups = <Widget>[];
      var pending = <Widget>[];
      void flush() {
        if (pending.isEmpty) return;
        groups.add(
          ToolbarGroupSurface(
            popupStyle: resolved.actionCapsuleStyle,
            children: pending,
          ),
        );
        pending = <Widget>[];
      }

      for (final marked in actions) {
        final action = BarAction.actionOf(marked);
        if (action is ToolbarGroup) {
          flush();
          if (action.children.isNotEmpty) groups.add(action);
        } else {
          pending.add(action);
        }
      }
      flush();
      final row = Row(
        mainAxisSize: .min,
        spacing: resolved.actionSpacing,
        children: groups,
      );
      final surfaceStyle = resolved.actionCapsuleStyle?.surfaceStyle;
      return surfaceStyle == null
          ? row
          : SurfaceTheme(surfaceStyle: surfaceStyle, child: row);
    }

    // Once the actions stand in a column beside the content the bar keeps
    // only the ones that may not leave its row.
    List<Widget> kept(List<Widget> actions) {
      final result = <Widget>[];
      for (final marked in actions) {
        if (CoreAppBarContract.keepsAction(
          BarAction.axisBehaviorOf(marked),
          actionsAxis: actionsAxis,
        )) {
          result.add(marked);
          continue;
        }
        final action = BarAction.actionOf(marked);
        if (action is ToolbarGroup) {
          final retained = kept(action.children);
          if (retained.isNotEmpty) {
            result.add(
              ToolbarGroup(
                key: action.key,
                ariaLabel: action.ariaLabel,
                direction: action.direction,
                popupStyle: action.popupStyle,
                children: retained,
              ),
            );
          }
        }
      }
      return result;
    }

    final leadingRow = cluster(kept(leading));
    final trailingRow = cluster(kept(trailing));

    final Widget content = switch (variant) {
      .standard || .compact || .dense || .prominent when barCentered => Padding(
        padding: resolved.padding,
        child: CustomMultiChildLayout(
          delegate: _CenteredTitleLayout(
            spacing: resolved.spacing,
            textDirection: Directionality.of(context),
          ),
          children: [
            if (leadingRow != null)
              LayoutId(id: _BarSlot.leading, child: leadingRow),
            LayoutId(
              id: _BarSlot.title,
              child: Padding(padding: resolved.titlePadding, child: center),
            ),
            if (trailingRow != null)
              LayoutId(id: _BarSlot.trailing, child: trailingRow),
          ],
        ),
      ),
      .standard || .compact || .dense || .prominent => Padding(
        padding: resolved.padding,
        child: Row(
          spacing: resolved.spacing,
          children: [
            ?leadingRow,
            Flexible(
              fit: trailingExpanded ? .loose : .tight,
              // The inset belongs on the flex item itself, which is what
              // the Web twin does — `titlePadding` rides the same element
              // that carries `flex-1`. Putting it on the bar's outer
              // `Padding` instead would push the leading and trailing
              // clusters too, and those do not carry it on either
              // platform.
              child: Padding(
                padding: resolved.titlePadding,
                child: center,
              ),
            ),
            if (trailingRow != null)
              if (trailingExpanded)
                Expanded(
                  child: Align(alignment: .centerRight, child: trailingRow),
                )
              else
                trailingRow,
          ],
        ),
      ),
      .medium => Column(
        crossAxisAlignment: .stretch,
        children: [
          SizedBox(
            height: resolved.topRowHeight,
            child: Padding(
              padding: resolved.padding,
              child: Row(
                spacing: resolved.spacing,
                children: [
                  ?leadingRow,
                  const Spacer(),
                  ?trailingRow,
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: resolved.titlePadding,
              child: Align(
                alignment: centerTitle ? .bottomCenter : .bottomLeft,
                child: center,
              ),
            ),
          ),
        ],
      ),
    };

    final controller = scrollController;
    final opaque =
        Theme.of(context).reduceTransparency ||
        (MediaQuery.maybeOf(context)?.highContrast ?? false);
    if (glass) {
      final edgeColor = Theme.of(context).colorScheme
          .resolve(
            const CoreColor.token(CoreColors.surface),
          )
          .toValue();
      // A soft scroll edge improves legibility without refracting the whole
      // bar. The action capsules keep their glass even at zero scroll offset.
      Widget edge() {
        final progress = controller == null
            ? 0.0
            : ((controller.hasClients && controller.positions.length == 1
                          ? controller.offset
                          : controller.initialScrollOffset) /
                      CoreAppBarStyle.glassScrollEdgeDistance)
                  .clamp(0.0, 1.0);
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolved.backgroundColor,
              gradient: LinearGradient(
                begin: .topCenter,
                end: .bottomCenter,
                colors: [
                  edgeColor.withValues(alpha: opaque ? 1 : progress * .92),
                  edgeColor.withValues(alpha: opaque ? 1 : 0),
                ],
              ),
            ),
          ),
        );
      }

      // Only the soft edge listens to scrolling. The material, actions and
      // title retain their subtrees and do no per-scroll resolution work.
      return SizedBox(
        height: resolved.height,
        child: Stacks(
          fit: .expand,
          children: [
            if (controller == null)
              edge()
            else
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => edge(),
              ),
            content,
          ],
        ),
      );
    }

    Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: resolved.dividerColor,
                  width: resolved.dividerWidth,
                ),
              )
            : null,
        boxShadow: elevated && !glass ? resolved.elevatedShadow : null,
      ),
      child: SizedBox(height: resolved.height, child: content),
    );
    if (resolved.material != null && resolved.backgroundColor.a > 0) {
      bar = SurfaceBlur(
        surfaceBlur: resolved.material?.blurRadius,
        surfaceSaturation: resolved.material?.saturation,
        surfaceBackdropBrightness: resolved.material?.backdropBrightnessIn(
          Theme.of(context),
        ),
        surfaceSheen: resolved.surfaceSheen,
        refraction: resolved.refraction,
        child: bar,
      );
    }
    return bar;
  }
}

enum _BarSlot { leading, title, trailing }

/// Places a centred title on the **whole** bar, not on the space between
/// the clusters.
///
/// The two sides are held at one width — the wider cluster's — so the room
/// left for the title is symmetric about the bar's centre:
/// `width − 2 × max(leading, trailing) − 2 × spacing`. The title is laid out
/// in at most that room (a longer one ends in an ellipsis) and always sits
/// on the centre. It never shifts toward the narrower cluster: a title that
/// moves with its neighbours lands somewhere else on every screen, which is
/// the thing a centred bar promises not to do. The Web twin sizes its grid's
/// side columns to the same `max` (see `app_bar_style.dart` there), so the
/// two platforms place and clip the title at the same pixel.
class _CenteredTitleLayout extends MultiChildLayoutDelegate {
  _CenteredTitleLayout({required this.spacing, required this.textDirection});

  final double spacing;
  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    final rtl = textDirection == .rtl;
    var leadingWidth = 0.0;
    var trailingWidth = 0.0;
    if (hasChild(_BarSlot.leading)) {
      // Full bar height, like `NavigationToolbar`'s leading slot.
      leadingWidth = layoutChild(
        _BarSlot.leading,
        BoxConstraints(
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
        ),
      ).width;
      positionChild(
        _BarSlot.leading,
        Offset(rtl ? size.width - leadingWidth : 0, 0),
      );
    }
    if (hasChild(_BarSlot.trailing)) {
      final trailingSize = layoutChild(
        _BarSlot.trailing,
        BoxConstraints.loose(size),
      );
      trailingWidth = trailingSize.width;
      positionChild(
        _BarSlot.trailing,
        Offset(
          rtl ? 0 : size.width - trailingWidth,
          (size.height - trailingSize.height) / 2,
        ),
      );
    }
    final side = math.max(leadingWidth, trailingWidth);
    final room = math.max(size.width - side * 2 - spacing * 2, 0).toDouble();
    final titleSize = layoutChild(
      _BarSlot.title,
      BoxConstraints.loose(size).copyWith(maxWidth: room),
    );
    final start = (size.width - titleSize.width) / 2;
    positionChild(
      _BarSlot.title,
      Offset(
        rtl ? size.width - titleSize.width - start : start,
        (size.height - titleSize.height) / 2,
      ),
    );
  }

  @override
  bool shouldRelayout(_CenteredTitleLayout oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.textDirection != textDirection;
}

/// Chain sugar for merging a [CoreAppBarStyle] patch into
/// [AppBar.appBarStyle] without hand-reconstructing every field.
/// Mirrors the Web `AppBar.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAppBarStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on. That
/// fixed name-to-value mapping is what makes a short getter safe to
/// reuse across components — a curated nickname (`.rounded`, `.compact`)
/// would silently map to a different value per component, but a
/// primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreAppBarStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// AppBar(title: Text('Dashboard')).surface
/// ```
extension AppBarStyleChain on AppBar {
  /// Sets the background paint and preserves the other style fields.
  AppBar backgroundColor(CoreColor value) =>
      withStyle(CoreAppBarStyle(backgroundColor: value));

  /// Returns a copy of this [AppBar] with [patch] merged into
  /// [appBarStyle] (patch fields win on conflict).
  AppBar withStyle(CoreAppBarStyle patch) => .new(
    key: key,
    title: title,
    header: header,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    variant: variant,
    trailingExpanded: trailingExpanded,
    centerTitle: centerTitle,
    showDivider: showDivider,
    elevated: elevated,
    actionsAxis: actionsAxis,
    scrollController: scrollController,
    appBarStyle: (appBarStyle ?? const CoreAppBarStyle()).merge(patch),
    child: child,
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  AppBar get primary => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  AppBar get secondary => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  AppBar get tertiary => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  AppBar get surface => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  AppBar get surfaceContainer => withStyle(
    const CoreAppBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  AppBar get error => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  AppBar get success => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  AppBar get warning => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  AppBar get info => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  AppBar get outline => withStyle(
    const CoreAppBarStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  AppBar get transparent =>
      withStyle(const CoreAppBarStyle(backgroundColor: .transparent));
}

/// Keeps the full text layout and shaping while its route brings it into view.
class _AppBarRouteTitle extends StatelessWidget {
  const _AppBarRouteTitle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.maybeOf(
      context,
    )?.coreComponentTheme?.pageTransition?.style;
    if (style?.animateAppBarTitle == false) return child;

    final route = ModalRoute.of(context);
    final primary = route?.animation;
    final secondary = route?.secondaryAnimation;
    if (primary == null || secondary == null || resolveReducedMotion(context)) {
      return child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([primary, secondary]),
      child: child,
      builder: (context, child) {
        final progress = math.min(primary.value, 1 - secondary.value);
        if (progress >= 1) return child!;
        final sigma =
            CorePageTransitionStyle.defaultTitleBlurSigma * (1 - progress);
        return Opacity(
          opacity: progress.clamp(0, 1),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
        );
      },
    );
  }
}
