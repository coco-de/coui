import 'package:coui_flutter/coui_flutter.dart';

/// Unified card-image — image thumbnail + optional title / subtitle /
/// leading / trailing slots in a clickable container.
///
/// Layers on top of the already-unified `Basic` (text row) and
/// `OutlinedContainer` (card box and image frame) primitives, so chrome stays
/// consistent with the rest of CoUI and the `Core{Name}Theme` wiring
/// survives.
///
/// surface:content — the card's box is the face, and it sits in the page
/// flow; the image frame inside it is part of that face.
class CardImage extends StatefulWidget
    implements CoreCardImageContract<Widget> {
  /// Creates a [CardImage].
  const CardImage({
    required this.image,
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.enabled,
    this.cardImageStyle,
  });

  @override
  final Widget image;

  @override
  final Widget? title;

  @override
  final Widget? subtitle;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final CoreVoidCallback? onPressed;

  @override
  final bool? enabled;

  @override
  final CoreCardImageStyle? cardImageStyle;

  /// Returns a copy of this [CardImage] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  CardImage copyWith({
    Key? key,
    CoreVoidCallback? onPressed,
    Widget? image,
    Widget? title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    bool? enabled,
    CoreCardImageStyle? cardImageStyle,
  }) {
    return CardImage(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      image: image ?? this.image,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      enabled: enabled ?? this.enabled,
      cardImageStyle: cardImageStyle ?? this.cardImageStyle,
    );
  }

  @override
  State<CardImage> createState() => _CardImageState();
}

class _CardImageState extends State<CardImage> {
  final _statesController = WidgetStatesController();

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCardImage(
      context,
      // Dimmed only when it is a control that is unavailable — a card with no
      // `onPressed` is content, and `enabled: false` changes nothing about it.
      disabled: widget.onPressed != null && widget.enabled == false,
      cardImageStyle: widget.cardImageStyle,
    );

    final imageLayer = OutlinedContainer(
      containerStyle: resolved.frameStyle,
      child: AnimatedBuilder(
        animation: _statesController,
        builder: (context, child) {
          final hovered = _statesController.value.contains(WidgetState.hovered);
          return AnimatedScale(
            scale: hovered ? resolved.hoverScale : resolved.normalScale,
            curve: CoreEasing.move.toValue(),
            duration: resolved.hoverDuration,
            child: widget.image,
          );
        },
      ),
    );

    final content = OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Flex(
        direction: resolved.direction.toValue(),
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Opacity(opacity: resolved.contentOpacity, child: imageLayer),
          Gap(gapStyle: resolved.imageContentGapStyle),
          Opacity(
            opacity: resolved.contentOpacity,
            child: Basic(
              leading: widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              trailing: widget.trailing,
              basicStyle: resolved.contentStyle,
            ),
          ),
        ],
      ),
    );

    // A card with no `onPressed` is not a control. Wrapping it in a
    // `Button` anyway made it announce as a *disabled* button — so a
    // decorative image card was read out as something the user could
    // have used but was not allowed to, which is worse than saying
    // nothing. The Web twin only takes a role when it is pressable.
    if (widget.onPressed == null) return content;

    return Button(
      onPressed: widget.onPressed,
      variant: .fixed,
      buttonStyle: CoreCardImageStyle.pressableButtonStyle,
      enabled: widget.enabled,
      statesController: _statesController,
      child: content,
    );
  }
}

/// Chain sugar for merging a [CoreCardImageStyle] patch into
/// [CardImage.cardImageStyle] without hand-reconstructing every field.
/// Mirrors the Web `CardImage.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCardImageStyle.merge` right-side-wins semantics).
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
/// sets `borderRadius` and `.primary` sets `backgroundColor` — both on
/// the composed image frame's [CoreOutlinedContainerStyle]
/// ([CoreCardImageStyle.frameStyle]), the single slot that frame chrome
/// enters through. A semantic layer that names these after
/// component-specific intent (decided together with design) is a
/// follow-up once more components adopt this pattern.
///
/// ```dart
/// CardImage(image: Image.asset('x.png')).radius4.surface
/// ```
extension CardImageStyleChain on CardImage {
  /// Returns a copy of this [CardImage] with [patch] merged into
  /// [cardImageStyle] (patch fields win on conflict).
  CardImage withStyle(CoreCardImageStyle patch) => copyWith(
    cardImageStyle: (cardImageStyle ?? const CoreCardImageStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  CardImage get radius0 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.zero,
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  CardImage get radius2 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  CardImage get radius4 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  CardImage get radius6 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  CardImage get radius8 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  CardImage get radius10 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  CardImage get radius12 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  CardImage get radius14 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  CardImage get radius16 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  CardImage get radius20 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  CardImage get radius24 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  CardImage get radius28 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  CardImage get radius32 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  CardImage get radius36 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  CardImage get radius40 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  CardImage get radius48 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  CardImage get radius56 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  CardImage get radius64 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  CardImage get radius9999 => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  CardImage get primary => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  CardImage get secondary => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.secondary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  CardImage get tertiary => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  CardImage get surface => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  CardImage get surfaceContainer => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  CardImage get error => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.error),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  CardImage get success => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.success),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  CardImage get warning => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.warning),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  CardImage get info => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.info),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  CardImage get outline => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  CardImage get transparent => withStyle(
    const CoreCardImageStyle(
      frameStyle: CoreOutlinedContainerStyle(backgroundColor: .transparent),
    ),
  );
}
