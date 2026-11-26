import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform card with slot-based layout.
///
/// Provides five layout slots: [media], [header], [body], [footer],
/// and [overlay]. The [media] slot renders at the top without padding,
/// while [header]/[body]/[footer] render below with padding.
///
/// Visual style is controlled by [variant] (filled/outlined). Sizing,
/// elevation, clip-behavior, and all chrome / dimensional overrides
/// flow through the single [cardStyle] (a [CoreCardStyle]).
///
/// Example:
/// ```dart
/// Card(
///   variant: CoreCardVariant.outlined,
///   cardStyle: CoreCardStyle(elevation: CoreCardElevation.soft),
///   media: Image.network(url, height: 120, fit: BoxFit.cover),
///   header: Text('Product Name'),
///   body: Text('Description'),
///   footer: Button(
///     variant: CoreButtonVariant.primary,
///     onPressed: () {},
///     child: Text('Buy Now'),
///   ),
/// )
/// ```
///
/// surface:content — a face in the page flow: what shows through it is the
/// page it is laid on. A caller that floats a card says so through [role].
class Card extends StatelessWidget implements CoreCardContract<Widget> {
  /// Creates a [Card].
  const Card({
    super.key,
    this.onTap,
    this.variant = CoreCardVariant.defaultVariant,
    this.media,
    this.header,
    this.body,
    this.footer,
    this.overlay,
    this.cardStyle,
    this.child,
    this.role = .defaultRole,
  });

  @override
  final CoreCardVariant variant;

  @override
  final Widget? media;

  @override
  final Widget? header;

  @override
  final Widget? body;

  @override
  final Widget? footer;

  @override
  final Widget? overlay;

  @override
  final Widget? child;

  @override
  final VoidCallback? onTap;

  @override
  final CoreCardStyle? cardStyle;

  @override
  final CoreSurfaceRole role;

  /// Returns a copy of this [Card] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Card copyWith({
    Key? key,
    VoidCallback? onTap,
    CoreCardVariant? variant,
    Widget? media,
    Widget? header,
    Widget? body,
    Widget? footer,
    Widget? overlay,
    CoreCardStyle? cardStyle,
    Widget? child,
    CoreSurfaceRole? role,
  }) {
    return Card(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      variant: variant ?? this.variant,
      media: media ?? this.media,
      header: header ?? this.header,
      body: body ?? this.body,
      footer: footer ?? this.footer,
      overlay: overlay ?? this.overlay,
      cardStyle: cardStyle ?? this.cardStyle,
      role: role ?? this.role,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCard(
      context,
      variant: variant,
      mediaPresent: media != null,
      cardStyle: cardStyle,
    );

    final hasSlots =
        media != null ||
        header != null ||
        body != null ||
        footer != null ||
        overlay != null;

    final innerChild =
        child ??
        (hasSlots
            ? _CardSlotLayout(
                body: body,
                bodyFooterGapStyle: resolved.bodyFooterGapStyle,
                footer: footer,
                header: header,
                headerBodyGapStyle: resolved.headerBodyGapStyle,
                headerTextStyle: resolved.headerTextStyle,
                media: media,
                overlay: overlay,
                padding: resolved.padding,
              )
            : const SizedBox.shrink());

    // Slot layout owns its inner padding — drop the container padding
    // so it does not stack. Custom `child` still gets the container
    // padding from the resolver.
    final containerStyle = hasSlots && child == null
        ? resolved.containerStyle.copyWith(padding: .zero)
        : resolved.containerStyle;

    Widget card = OutlinedContainer(
      containerStyle: containerStyle,
      role: role,
      child: DefaultTextStyle.merge(
        style: resolved.bodyTextStyle,
        child: innerChild,
      ),
    );

    // Caller-supplied shadow override paints on top of the container's
    // elevation. The resolver finished the `CoreColor → Color`
    // conversion so the widget reads paint-ready `BoxShadow`s.
    //
    // `borderRadius` must match the resting surface's corner (the same
    // `interactiveBorderRadius` the hover-shadow wrapper already reuses,
    // see `card_style.dart`) — without it this `BoxDecoration` clips the
    // shadow to a plain rectangle, so a rounded card casts a square-cornered
    // shadow that visibly pokes out past its own rounded corners on the Web
    // (CSS keeps `border-radius`/`box-shadow` on one element, so this class
    // of bug can't occur there; Flutter's split-widget shadow layer needs
    // the radius passed explicitly).
    if (resolved.boxShadowOverride != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolved.interactiveBorderRadius,
          boxShadow: resolved.boxShadowOverride,
        ),
        child: card,
      );
    }

    // Sizing semantics — match the Web `width: auto` behaviour for
    // `intrinsic` so a card with a 200-char label takes 200 chars,
    // not the parent's full width.
    if (resolved.width == .infinity) {
      // `expand`: keep the natural stretch behaviour.
    } else if (resolved.width == null && resolved.height == null) {
      card = IntrinsicWidth(child: card);
    } else {
      card = SizedBox(
        width: resolved.width,
        height: resolved.height,
        child: card,
      );
    }

    if (onTap != null) {
      return _CardInteractiveWrapper(
        onTap: onTap,
        resolved: resolved,
        child: card,
      );
    }

    return card;
  }
}

// ═══════════════════════════════════════════════════
// INTERACTIVE WRAPPER
// ═══════════════════════════════════════════════════

/// Hover shadow animation and tap handling wrapper for [Card].
///
/// All chrome arrives paint-ready via [resolved] — this widget owns
/// only the hover state.
class _CardInteractiveWrapper extends StatefulWidget {
  const _CardInteractiveWrapper({
    required this.resolved,
    required this.child,
    this.onTap,
  });

  final ResolvedCard resolved;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_CardInteractiveWrapper> createState() =>
      _CardInteractiveWrapperState();
}

class _CardInteractiveWrapperState extends State<_CardInteractiveWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring (Epic composition — no hand-rolled
    // GestureDetector + MouseRegion). Press-shrink is disabled for the
    // large card surface via `resolved.clickableStyle` (`pressedScale:
    // 1`); the interactive feedback is the hover shadow instead. Hover
    // state flows back through `onHover` so this wrapper only animates
    // that shadow.
    return Clickable(
      onPressed: widget.onTap,
      onHover: (hovered) => setState(() => _hovered = hovered),
      clickableStyle: resolved.clickableStyle,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          borderRadius: resolved.interactiveBorderRadius,
          boxShadow: _hovered ? resolved.hoverShadows : null,
        ),
        curve: CoreEasing.move.toValue(),
        duration: resolved.interactiveDuration,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SLOT LAYOUT
// ═══════════════════════════════════════════════════

/// Internal layout for [Card] slot-based content.
///
/// Paint-ready chrome (header `TextStyle`, gaps) flows in from
/// [resolveCard]. This widget owns layout only — no merges,
/// typography lookups, or colour resolution.
class _CardSlotLayout extends StatelessWidget {
  const _CardSlotLayout({
    this.body,
    required this.bodyFooterGapStyle,
    this.footer,
    this.header,
    required this.headerBodyGapStyle,
    required this.headerTextStyle,
    this.media,
    this.overlay,
    required this.padding,
  });

  final Widget? media;
  final Widget? header;
  final Widget? body;
  final Widget? footer;
  final Widget? overlay;
  final EdgeInsets padding;
  final CoreGapStyle headerBodyGapStyle;
  final CoreGapStyle bodyFooterGapStyle;
  final TextStyle headerTextStyle;

  @override
  Widget build(BuildContext context) {
    final hasContent = header != null || body != null || footer != null;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (media != null)
          Stacks(
            children: [
              media!,
              ?overlay,
            ],
          ),
        if (hasContent)
          Padding(
            padding: padding,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                if (header != null)
                  DefaultTextStyle.merge(
                    style: headerTextStyle,
                    child: header!,
                  ),
                if (body != null) ...[
                  if (header != null) Gap(gapStyle: headerBodyGapStyle),
                  body!,
                ],
                if (footer != null) ...[
                  if (header != null || body != null)
                    Gap(gapStyle: bodyFooterGapStyle),
                  footer!,
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreCardStyle] patch into
/// [Card.cardStyle] without hand-reconstructing every field. Mirrors
/// the Web `Card.withStyle` extension so both platforms read
/// identically. Composition slots (`media` / `header` / `body` /
/// `footer` / `overlay` / `child`) keep using their own widgets
/// directly — this extension only covers the [CoreCardStyle] chrome
/// slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCardStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Card(header: Text('Title')).withStyle(
///   CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// )
/// ```
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
/// sets [CoreCardStyle.borderRadius] and `.primary` sets
/// [CoreCardStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Card(header: Text('Title')).radius4.surface
/// ```
extension CardStyleChain on Card {
  /// Returns a copy of this [Card] with [patch] merged into
  /// [cardStyle] (patch fields win on conflict).
  Card withStyle(CoreCardStyle patch) =>
      copyWith(cardStyle: (cardStyle ?? const CoreCardStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Card get radius0 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius0)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Card get radius2 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Card get radius4 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Card get radius6 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Card get radius8 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Card get radius10 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Card get radius12 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Card get radius14 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Card get radius16 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Card get radius20 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Card get radius24 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Card get radius28 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Card get radius32 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Card get radius36 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Card get radius40 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Card get radius48 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Card get radius56 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Card get radius64 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Card get radius9999 => withStyle(
    const CoreCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Card get primary => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Card get secondary => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.secondary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Card get tertiary => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Card get surface => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Card get surfaceContainer => withStyle(
    const CoreCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Card get error => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Card get success => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Card get warning => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Card get info => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Card get outline => withStyle(
    const CoreCardStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Card get transparent =>
      withStyle(const CoreCardStyle(backgroundColor: .transparent));
}
