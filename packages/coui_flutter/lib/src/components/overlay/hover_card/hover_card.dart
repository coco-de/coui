import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

/// A unified declarative hover card component.
///
/// Displays a floating card when the user hovers over the [trigger].
/// The card stays open while the pointer is over either the trigger
/// or the card itself, and closes after [closeDelay] once the pointer
/// leaves both regions.
///
/// Per Epic #1302 chrome / dimensional / timing overrides flow through
/// the single [hoverCardStyle] slot. Behavioural fields and the
/// semantic enum (`placement`) stay flat on the widget.
///
/// Example:
/// ```dart
/// HoverCard(
///   trigger: Text('@user'),
///   content: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [Text('User profile card')],
///   ),
/// )
/// ```
///
/// surface:functional — an anchored panel the overlay layer mounts over its
/// trigger.
class HoverCard extends StatefulWidget
    implements CoreHoverCardContract<Widget, VoidCallback> {
  /// Creates a [HoverCard].
  const HoverCard({
    required this.trigger,
    required this.content,
    this.placement = CorePopoverPlacement.bottom,
    this.openDelay,
    this.closeDelay,
    this.onClose,
    this.hoverCardStyle,
    super.key,
  });

  @override
  final Widget trigger;

  @override
  final Widget content;

  @override
  final CorePopoverPlacement placement;

  @override
  final Duration? openDelay;

  @override
  final Duration? closeDelay;

  @override
  final VoidCallback? onClose;

  @override
  final CoreHoverCardStyle? hoverCardStyle;

  /// Returns a copy of this [HoverCard] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  HoverCard copyWith({
    Key? key,
    Widget? trigger,
    Widget? content,
    CorePopoverPlacement? placement,
    Duration? openDelay,
    Duration? closeDelay,
    VoidCallback? onClose,
    CoreHoverCardStyle? hoverCardStyle,
  }) {
    return HoverCard(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      placement: placement ?? this.placement,
      openDelay: openDelay ?? this.openDelay,
      closeDelay: closeDelay ?? this.closeDelay,
      onClose: onClose ?? this.onClose,
      hoverCardStyle: hoverCardStyle ?? this.hoverCardStyle,
    );
  }

  @override
  State<HoverCard> createState() => _HoverCardState();
}

/// Chain sugar for merging a [CoreHoverCardStyle] patch into
/// [HoverCard.hoverCardStyle] without hand-reconstructing every field.
/// Mirrors the Web `HoverCard.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHoverCardStyle.merge` right-side-wins semantics).
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
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CorePopupStyle.borderRadius] and `.primary` sets
/// [CorePopupStyle.backgroundColor] on [CoreHoverCardStyle.panelStyle] — the
/// panel box is a composed `Popup`, and these are its primary fill and
/// corner. A semantic layer that names these after component-specific intent
/// (decided together with design) is a follow-up once more components adopt
/// this pattern.
///
/// ```dart
/// HoverCard(trigger: Text('@user'), content: Text('Bio')).radius4.surface
/// ```
extension HoverCardStyleChain on HoverCard {
  /// Returns a copy of this [HoverCard] with [patch] merged into
  /// [hoverCardStyle] (patch fields win on conflict).
  HoverCard withStyle(CoreHoverCardStyle patch) => copyWith(
    hoverCardStyle: (hoverCardStyle ?? const CoreHoverCardStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  HoverCard get radius0 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.zero),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  HoverCard get radius2 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  HoverCard get radius4 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  HoverCard get radius6 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  HoverCard get radius8 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  HoverCard get radius10 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  HoverCard get radius12 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  HoverCard get radius14 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  HoverCard get radius16 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  HoverCard get radius20 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  HoverCard get radius24 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  HoverCard get radius28 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  HoverCard get radius32 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  HoverCard get radius36 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  HoverCard get radius40 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  HoverCard get radius48 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  HoverCard get radius56 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  HoverCard get radius64 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  HoverCard get radius9999 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  HoverCard get primary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  HoverCard get secondary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.secondary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  HoverCard get tertiary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  HoverCard get surface => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  HoverCard get surfaceContainer => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  HoverCard get error => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.error),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  HoverCard get success => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.success),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  HoverCard get warning => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.warning),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  HoverCard get info => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.info),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  HoverCard get outline => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  HoverCard get transparent => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(backgroundColor: .transparent),
    ),
  );
}

class _HoverCardState extends State<HoverCard> {
  // Shared anchored-overlay engine, called directly (same as Popover /
  // Tooltip) so the hover card no longer routes through the deprecated
  // OverlayManager / PopoverController.
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  PopoverEntryHandle<void>? _activeEntry;
  int _hoverCount = 0;

  /// Popover (card) alignment — which corner of the card sits on the
  /// anchor point. For `placement.bottom`, the card hangs *below* the
  /// trigger, so the card's *top* edge anchors to the trigger's
  /// bottom edge — hence `topCenter` for the bottom placements
  /// (and the inverse for the top placements). Same logic for the
  /// horizontal axis.
  Alignment _resolvePopoverAlignment() {
    return switch (widget.placement) {
      .top || .topStart || .topEnd => Alignment.bottomCenter,
      .bottom || .bottomStart || .bottomEnd => Alignment.topCenter,
      .left || .leftStart || .leftEnd => Alignment.centerRight,
      .right || .rightStart || .rightEnd => Alignment.centerLeft,
    };
  }

  /// Anchor alignment — which point on the trigger the popover
  /// alignment hooks onto. For `placement.bottom`, the card hangs
  /// below the trigger so the anchor point is the trigger's *bottom*
  /// center (and inverse for top placements).
  Alignment _resolveAnchorAlignment() {
    return switch (widget.placement) {
      .top || .topStart || .topEnd => Alignment.topCenter,
      .bottom || .bottomStart || .bottomEnd => Alignment.bottomCenter,
      .left || .leftStart || .leftEnd => Alignment.centerLeft,
      .right || .rightStart || .rightEnd => Alignment.centerRight,
    };
  }

  void _showPopover(BuildContext context, {required Duration closeDelay}) {
    if (_activeEntry != null) return;

    final resolved = resolveHoverCard(
      context,
      placement: widget.placement,
      widgetOpenDelay: widget.openDelay,
      widgetCloseDelay: widget.closeDelay,
      hoverCardStyle: widget.hoverCardStyle,
    );

    final entry = _handler.show<void>(
      alignment: _resolvePopoverAlignment(),
      context: context,
      anchorAlignment: _resolveAnchorAlignment(),
      consumeOutsideTaps: false,
      follow: false,
      modal: false,
      // Placement-axis offset — scaling pre-applied by the resolver.
      offset: resolved.panelOffset,
      builder: (popoverContext) {
        // Re-resolve on every rebuild so a light↔dark toggle reaches the
        // open panel (the composed `Popup` re-resolves its forwarded
        // `panelStyle` tokens against the live theme). The panel box
        // (background / border / radius / shadow / padding / content colour
        // / width bounds) is a single source of truth in `Popup` — this
        // hover card only forwards its `panelStyle`.
        final liveResolved = resolveHoverCard(
          popoverContext,
          placement: widget.placement,
          widgetOpenDelay: widget.openDelay,
          widgetCloseDelay: widget.closeDelay,
          hoverCardStyle: widget.hoverCardStyle,
        );
        return MouseRegion(
          onEnter: (_) {
            _hoverCount += 1;
          },
          onExit: (_) {
            final count = _hoverCount += 1;
            Future.delayed(closeDelay, () {
              if (count == _hoverCount && _activeEntry != null) {
                _activeEntry?.close();
                widget.onClose?.call();
              }
            });
          },
          // The panel box is a `Popup`, so the hover-card surface
          // (border + radius + padding + shadow + width bounds) is
          // automatically consistent with every other floating panel and
          // inherits future popup-token changes for free. The width ceiling
          // is the hover card's own `defaultPanelStyle` forwarded through
          // the same slot — without it the panel would expand to fit its
          // content on a single line (long rich text would push it
          // off-screen / clip in Flutter Embed previews).
          child: Popup(
            popupStyle: liveResolved.panelStyle,
            children: [widget.content],
          ),
        );
      },
    );

    _activeEntry = entry;
    unawaited(
      entry.future.whenComplete(() {
        _activeEntry = null;
      }),
    );
  }

  @override
  void dispose() {
    _activeEntry?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveHoverCard(
      context,
      placement: widget.placement,
      widgetOpenDelay: widget.openDelay,
      widgetCloseDelay: widget.closeDelay,
      hoverCardStyle: widget.hoverCardStyle,
    );
    final openDelay = resolved.openDelay;
    final closeDelay = resolved.closeDelay;

    // Web twin: role="dialog" on the floating panel.
    // Same as `Popover` — the trigger says whether its card is showing.
    return Semantics(
      container: true,
      expanded: _activeEntry != null,
      child: MouseRegion(
        onEnter: (_) {
          final count = _hoverCount += 1;
          Future.delayed(openDelay, () {
            if (count == _hoverCount &&
                _activeEntry == null &&
                context.mounted) {
              _showPopover(context, closeDelay: closeDelay);
            }
          });
        },
        onExit: (_) {
          final count = _hoverCount += 1;
          Future.delayed(closeDelay, () {
            if (count == _hoverCount && _activeEntry != null) {
              _activeEntry?.close();
              widget.onClose?.call();
            }
          });
        },
        // The trigger is interactive (hover opens the card), so signal
        // that affordance with the same pointer cursor a clickable
        // element would show. Without this the OS hands back whatever
        // the trigger child paints (text caret over `Text`, etc.) and
        // the trigger feels passive.
        cursor: SystemMouseCursors.click,
        hitTestBehavior: .deferToChild,
        child: GestureDetector(
          onLongPress: () {
            _showPopover(context, closeDelay: closeDelay);
          },
          // Interactive-affordance text is not a selection target —
          // mirrors the Web trigger's `select-none` (Clickable precedent).
          // Under the app-level web SelectionArea a selectable text
          // fragment registers the deepest hit-test annotation with a
          // `text` cursor, beating this region's `click`.
          child: SelectionContainer.disabled(child: widget.trigger),
        ),
      ),
    );
  }
}
