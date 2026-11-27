import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

/// Unified bottom dock navigation for Flutter.
///
/// Pins a row of icon + optional label items to the bottom of the screen.
/// Takes a data-only [items] list (`CoreDockItemData<Widget>`) and renders
/// each one directly — no separate widget type for items.
///
/// ```dart
/// Dock(
///   items: [
///     CoreDockItemData<Widget>(
///       icon: Icon(LucideIcons.house),
///       label: 'Home',
///       isActive: true,
///       onPressed: () {},
///     ),
///     CoreDockItemData<Widget>(
///       icon: Icon(LucideIcons.settings),
///       label: 'Settings',
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
///
/// surface:behind — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// surface:functional — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// ## The active pill, and how it travels
///
/// The active item sits in a pill. When a different item becomes active
/// the pill does not fade out here and in there: the departing pill and
/// the arriving one are handed to the morph engine as two bodies, and for
/// the length of a spring the bar carves one silhouette out of a fill that
/// covers it — the same `LiquidMorphClip` a popover leaves its trigger
/// through, on the same Core outline the Web twin carves. The pill reads
/// as one thing stretching across, not as two things swapping.
///
/// The flight is measured, not laid out: the two pills' rectangles are
/// read off the items' render boxes at the moment the active index
/// changes, which is the last frame's layout — correct whenever the bar
/// did not resize in the same frame, and settled correctly by the next
/// frame if it did. Under reduced motion there is no flight; the pill is
/// simply under the new item.
///
/// ## The bar's height
///
/// `CoreDockStyle.height` is the bar's minimum height, not its height. While
/// the item row — and the room kept above and below it for the active pill —
/// fits, the bar is exactly that tall, with the items centred in it; when the
/// row needs more (the label grown by the OS text size, a taller icon) the bar
/// is as tall as the row asks. The bar is sized by its content under whatever
/// height its parent offers, so it grows instead of clipping the content a
/// user asked to see larger.
class Dock extends StatefulWidget implements CoreDockContract<Widget> {
  /// Creates a [Dock].
  const Dock({
    required this.items,
    super.key,
    this.size,
    this.semanticLabel,
    this.dockStyle,
  });

  @override
  final List<CoreDockItemData<Widget>> items;

  @override
  final CoreDockSize? size;

  @override
  final String? semanticLabel;

  @override
  final CoreDockStyle? dockStyle;

  /// Returns a copy of this [Dock] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Dock copyWith({
    Key? key,
    List<CoreDockItemData<Widget>>? items,
    CoreDockSize? size,
    String? semanticLabel,
    CoreDockStyle? dockStyle,
  }) {
    return Dock(
      key: key ?? this.key,
      items: items ?? this.items,
      size: size ?? this.size,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      dockStyle: dockStyle ?? this.dockStyle,
    );
  }

  @override
  State<Dock> createState() => _DockState();
}

/// The two pills of one flight and the tempo it runs at.
class _IndicatorFlight {
  const _IndicatorFlight({
    required this.serial,
    required this.anchor,
    required this.panel,
    required this.spring,
  });

  /// Distinguishes consecutive flights so the clip restarts its clock
  /// rather than updating in place mid-air.
  final int serial;
  final CoreMorphBlob anchor;
  final CoreMorphBlob panel;
  final CoreMorphSpring spring;
}

class _DockState extends State<Dock> {
  /// The box the flight is measured against and carved inside — the
  /// bar's padded content box, which is also where the items are laid out.
  final GlobalKey _trackKey = GlobalKey();
  List<GlobalKey> _itemKeys = const [];
  ResolvedDock? _lastResolved;
  _IndicatorFlight? _flight;
  Timer? _settle;
  int _serial = 0;

  static int? _activeIndexOf(List<CoreDockItemData<Widget>> items) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].isActive) return i;
    }

    return null;
  }

  void _syncKeys() {
    if (_itemKeys.length == widget.items.length) return;
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(Dock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final from = _activeIndexOf(oldWidget.items);
    final to = _activeIndexOf(widget.items);
    // A list that changed length has new keys and no old boxes to read;
    // the pill lands on the new item without a flight.
    final sameShape = oldWidget.items.length == widget.items.length;
    _syncKeys();
    if (from == null || to == null || from == to || !sameShape) return;
    // Reduced motion is answered by no flight at all rather than a fast
    // one — a morph is transition-tier motion, and this kit suppresses
    // that tier to zero.
    if (resolveReducedMotion(context)) return;

    _launch(from, to);
  }

  /// One plate, as a body in the track's coordinates: the item's icon row
  /// from the last frame, widened by the indicator padding.
  CoreMorphBlob? _pillOf(int index, ResolvedDock resolved) {
    final track = _trackKey.currentContext?.findRenderObject();
    final item = _itemKeys[index].currentContext?.findRenderObject();
    if (track is! RenderBox || item is! RenderBox || !item.hasSize) {
      return null;
    }

    final origin = item.localToGlobal(Offset.zero, ancestor: track);
    final pad = resolved.indicatorPadding;
    final rect = Rect.fromLTWH(
      origin.dx - pad.left,
      origin.dy - pad.top,
      item.size.width + pad.horizontal,
      item.size.height + pad.vertical,
    );

    return CoreMorphBlob(
      centerX: rect.center.dx,
      centerY: rect.center.dy,
      halfWidth: rect.width / 2,
      halfHeight: rect.height / 2,
      radius: resolved.indicatorRadius.topLeft.x,
    );
  }

  void _launch(int from, int to) {
    final resolved = _lastResolved;
    if (resolved == null) return;
    final anchor = _pillOf(from, resolved);
    final panel = _pillOf(to, resolved);
    if (anchor == null || panel == null) return;

    final spring = resolved.indicatorSpring;
    _settle?.cancel();
    _settle = Timer(
      Duration(
        microseconds: (spring.settleSeconds() * Duration.microsecondsPerSecond)
            .round(),
      ),
      () {
        if (!mounted) return;
        setState(() => _flight = null);
      },
    );
    setState(() {
      _flight = _IndicatorFlight(
        serial: ++_serial,
        anchor: anchor,
        panel: panel,
        spring: spring,
      );
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDock(
      context,
      size: widget.size,
      dockStyle: widget.dockStyle,
    );
    _lastResolved = resolved;
    final flight = _flight;

    final bar = SurfaceBlur(
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
      refraction: Theme.of(context).surfaceRefraction,
      // The rim a surface style lays inside a bar that casts a shadow.
      child: InsetShadow(
        shadows: resolved.insetBoxShadow,
        radius: resolved.barRadius,
        child: Container(
          padding: .symmetric(horizontal: resolved.horizontalPadding),
          decoration: BoxDecoration(
            color: resolved.backgroundColor,
            // All round: the bar is rounded, and a line on one edge of a
            // rounded box has nowhere to end.
            border: .all(
              color: resolved.borderColor,
              width: resolved.borderWidth,
            ),
            borderRadius: resolved.barRadius,
          ),
          // A floor, not a height: the bar is as tall as its row asks and
          // never shorter than this (`CoreDockStyle.height`).
          constraints: BoxConstraints(minHeight: resolved.minHeight),
          child: Stacks(
            key: _trackKey,
            // The row sizes the track, and the track is the whole of the
            // bar inside its line and padding: `expand` would take the
            // height its parent offers — the screen, in a bottom bar slot,
            // and an error under unbounded height — rather than the row's.
            // The minimum reaches the row through the constraints passed
            // on: at its minimum the bar lays its items out exactly as a
            // bar of that fixed height would.
            fit: .passthrough,
            children: [
              // The flight: a fill over the whole track, carved by the
              // morph clip into the silhouette the two pills make right
              // now. Underneath the items, so the icons ride on top of it
              // the way they sit on the settled pill.
              if (flight != null)
                Position.fill(
                  child: IgnorePointer(
                    child: LiquidMorphClip(
                      key: ValueKey(flight.serial),
                      anchor: flight.anchor,
                      panel: flight.panel,
                      spring: flight.spring,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: resolved.indicatorColor,
                        ),
                      ),
                    ),
                  ),
                ),
              // The bar's padding above and below the row — never less than
              // the plate's reach past the icon, which it overhangs without
              // taking layout room: inside the track, so the track — and the
              // flight painted over all of it — holds the plate, and the bar
              // around it with it. The apps are packed, `itemSpacing` apart,
              // and centred in the bar.
              Padding(
                padding: resolved.rowPadding,
                child: Row(
                  mainAxisAlignment: .center,
                  spacing: resolved.itemSpacing,
                  children: [
                    for (final (index, item) in widget.items.indexed)
                      _DockItem(
                        anchorKey: _itemKeys[index],
                        item: item,
                        resolved: resolved,
                        // While the pill is in flight it is the flight; the
                        // settled pill would sit under the destination a
                        // spring early.
                        showIndicator: item.isActive && flight == null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Role, not a noun in the label — see `Footer` for the same fix.
    return CoUISemantics(
      role: .navigation,
      label: widget.semanticLabel ?? CoUILocalizations.of(context).dockLabel,
      container: true,
      // Padding cannot stand in for the margin, because padding moves the
      // items and leaves the bar's own box where it was. Outside the cast,
      // so the cast knocks out the bar's own box and nothing else.
      child: Padding(
        padding: resolved.barMargin,
        // The bar's shadow, painted outside the bar only — a surface style
        // can make the bar translucent, and a decoration shadow would show
        // through it (`cross-platform/api.md`, 그림자는 두 플랫폼이 다른 곳에
        // 칠한다).
        child: InjectedCast(
          shadows: resolved.boxShadow,
          borderRadius: resolved.barRadius,
          child: bar,
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.anchorKey,
    required this.item,
    required this.resolved,
    required this.showIndicator,
  });

  /// Key of the icon row — the box the plate is laid against, and the box
  /// the flight measures.
  final GlobalKey anchorKey;

  final CoreDockItemData<Widget> item;
  final ResolvedDock resolved;

  /// Whether this item draws the settled plate behind its icon.
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    // Render-only: select the per-state icon tint + paint-ready label
    // text style by `isActive`. The resolver already materialised the
    // typography role, weight, colour and per-instance overlay.
    final iconColor = item.isActive
        ? resolved.activeColor
        : resolved.inactiveColor;
    final labelStyle = item.isActive
        ? resolved.activeLabelTextStyle
        : resolved.inactiveLabelTextStyle;

    final icon = IconTheme(
      data: IconThemeData(size: resolved.iconSize, color: iconColor),
      child: item.icon,
    );
    final itemWidth = resolved.itemWidth;
    // The icon row: the cell's width where the cell has one, the icon's own
    // otherwise — the box the plate is laid against.
    final iconRow = KeyedSubtree(
      key: anchorKey,
      child: itemWidth == null
          ? icon
          : SizedBox(
              width: itemWidth,
              child: Center(child: icon),
            ),
    );
    final pad = resolved.indicatorPadding;

    // The plate is a positioned child that overhangs the icon row by the
    // indicator padding; the stack sizes to the row, so the item's layout is
    // exactly what it is without a plate. Always a stack, so the selection
    // moving does not reparent the icon.
    final body = Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        Stacks(
          clipBehavior: .none,
          children: [
            if (showIndicator)
              Position(
                left: -pad.left,
                top: -pad.top,
                right: -pad.right,
                bottom: -pad.bottom,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.indicatorColor,
                    borderRadius: resolved.indicatorRadius,
                  ),
                ),
              ),
            iconRow,
          ],
        ),
        if (resolved.showLabel && item.label != null) ...[
          Gap(gapStyle: resolved.itemIconLabelGapStyle),
          Text(item.label!, style: labelStyle),
        ],
      ],
    );

    final content = Semantics(
      selected: item.isActive,
      button: item.onPressed != null,
      // A fixed cell where the size gives one, so a long name wraps inside
      // it rather than widening it.
      child: itemWidth == null ? body : SizedBox(width: itemWidth, child: body),
    );

    // Non-interactive item (`onPressed == null`) — plain column, no
    // button semantics / cursor / focus ring pollution. Mirrors the
    // chip conditional-wrap precedent.
    if (item.onPressed == null) {
      return content;
    }

    // Flutter twin of the Web dock item: the composed Clickable owns
    // tap / keyboard activation / cursor / press feedback / focus ring
    // (no hand-rolled GestureDetector + MouseRegion).
    return Clickable(
      onPressed: item.onPressed,
      clickableStyle: resolved.clickableStyle,
      child: content,
    );
  }
}

/// Chain sugar for merging a [CoreDockStyle] patch into [Dock.dockStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Dock.withStyle` extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDockStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreDockStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Dock(items: items).surface
/// ```
extension DockStyleChain on Dock {
  /// Sets the background paint and preserves the other style fields.
  Dock backgroundColor(CoreColor value) =>
      withStyle(CoreDockStyle(backgroundColor: value));

  /// Returns a copy of this [Dock] with [patch] merged into [dockStyle]
  /// (patch fields win on conflict).
  Dock withStyle(CoreDockStyle patch) =>
      copyWith(dockStyle: (dockStyle ?? const CoreDockStyle()).merge(patch));

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Dock get primary => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Dock get secondary => withStyle(
    const CoreDockStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Dock get tertiary => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Dock get surface => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Dock get surfaceContainer => withStyle(
    const CoreDockStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Dock get error => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Dock get success => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Dock get warning => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Dock get info => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Dock get outline => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Dock get transparent =>
      withStyle(const CoreDockStyle(backgroundColor: .transparent));
}
