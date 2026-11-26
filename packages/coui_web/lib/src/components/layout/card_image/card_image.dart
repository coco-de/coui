import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/layout/basic/basic.dart';
import 'package:coui_web/src/components/layout/card_image/card_image_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified card-image — image thumbnail + optional title / subtitle /
/// leading / trailing slots in a clickable container.
///
/// Mirrors the Flutter `CardImage`: delegates the text slot to `Basic`
/// (already unified), composes the same `OutlinedContainer` primitive
/// for the image frame (not a hand-rolled equivalent), and scales the
/// image on hover using CSS transitions. Colour / scale / gap /
/// direction follow the 3-tier theme resolution (widget param > theme >
/// default).
///
/// surface:content — the card's box is the face, and it sits in the page
/// flow; the image frame inside it is part of that face.
class CardImage extends UiStatefulComponent
    implements CoreCardImageContract<Component> {
  /// Creates a [CardImage].
  const CardImage({
    required this.image,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.enabled,
    this.cardImageStyle,
  });

  @override
  final Component image;

  @override
  final Component? title;

  @override
  final Component? subtitle;

  @override
  final Component? leading;

  @override
  final Component? trailing;

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
    UiMouseEventHandler? onClick,
    CoreVoidCallback? onPressed,
    Component? image,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    Component? title,
    Component? subtitle,
    Component? leading,
    Component? trailing,
    bool? enabled,
    CoreCardImageStyle? cardImageStyle,
  }) {
    return CardImage(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      onClick: onClick ?? this.onClick,
      image: image ?? this.image,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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
  bool _hovered = false;

  bool get _interactive =>
      (component.enabled ?? (component.onPressed != null)) &&
      component.onPressed != null;

  @override
  Component build(BuildContext context) {
    final resolved = resolveCardImage(
      context,
      interactive: _interactive,
      hovered: _hovered,
      // Dimmed only when it is a control that is unavailable — the same case
      // that takes `aria-disabled` below.
      disabled: component.onPressed != null && component.enabled == false,
      cardImageStyle: component.cardImageStyle,
    );

    final hasTextSlot =
        component.title != null ||
        component.subtitle != null ||
        component.leading != null ||
        component.trailing != null;

    // Image layer — composed `OutlinedContainer` frame + inner scale
    // wrapper. Mirrors Flutter `OutlinedContainer > AnimatedScale >
    // image` exactly — the frame is the same unified chrome primitive
    // on both platforms, not a hand-rolled `<div>`
    // (`core/style-contract.md`'s child-component-composition rule).
    // `OutlinedContainer`'s own clip behaviour (default `.antiAlias`)
    // clips the scaled child; it sizes to its flex-item content the
    // same as a plain `<div>` would here, so no `w-fit`/`inline-block`
    // is needed on this side of the composition.
    return div(
      [
        OutlinedContainer(
          containerStyle: resolved.containerStyle,
          child: div(
            [
              div(
                [
                  OutlinedContainer(
                    containerStyle: resolved.frameStyle,
                    child: div(
                      [component.image],
                      classes: resolved.image.className,
                      styles: resolved.image.inlineStyles,
                    ),
                  ),
                ],
                classes: resolved.imageLayer.className,
                styles: resolved.imageLayer.inlineStyles,
              ),
              if (hasTextSlot) Gap(gapStyle: resolved.imageContentGapStyle),
              // --- Text slot (leading / title / subtitle / trailing) ---
              if (hasTextSlot)
                div(
                  [
                    Basic(
                      leading: component.leading,
                      title: component.title,
                      subtitle: component.subtitle,
                      trailing: component.trailing,
                      basicStyle: resolved.contentStyle,
                    ),
                  ],
                  classes: resolved.textSlot.className,
                  styles: resolved.textSlot.inlineStyles,
                ),
            ],
            classes: resolved.body.className,
            styles: resolved.body.inlineStyles,
          ),
        ),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      // The Flutter twin composes `Button`, so it announces as a button
      // and takes Enter and Space. This side had a click handler and
      // nothing else — no role, no tab stop, no keys — so the whole
      // component was mouse-only on one platform and not the other.
      //
      // `<div role="button">` rather than a native `<button>`: the house
      // pattern here, and a button's content model does not admit the
      // image-and-text structure this draws.
      attributes: {
        ...component.componentAttributes,
        // A card with a handler is a control whether or not it is usable
        // right now. Disabled, it stays in the tree and leaves the tab
        // order — announcing "unavailable" is a different thing to say
        // than saying nothing. A card with no handler is not a control
        // at all and takes no role.
        'role': ?(component.onPressed == null ? null : 'button'),
        if (_interactive) 'tabindex': '0',
        if (!_interactive && component.onPressed != null)
          'aria-disabled': 'true',
      },
      events: {
        ...component.events,
        if (_interactive) ...{
          'click': (_) {
            final handler = component.onPressed;
            if (handler != null) handler();
          },
          'keydown': EventHandlers.createKeyboardEventHandler((event) {
            final key = event.key;
            if (key != ' ' && key != 'Enter') return;
            event.preventDefault();
            final handler = component.onPressed;
            if (handler != null) handler();
          }),
        },
        'mouseenter': (_) {
          setState(() => _hovered = true);
        },
        'mouseleave': (_) {
          setState(() => _hovered = false);
        },
      },
    );
  }
}

/// Chain sugar mirroring the Flutter `CardImage.withStyle` extension —
/// merges a [CoreCardImageStyle] patch into [CardImage.cardImageStyle]
/// via the existing [CardImage.copyWith].
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
/// CardImage(image: img(src: 'x.png')).radius4.surface
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
