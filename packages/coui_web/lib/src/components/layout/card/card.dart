import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/card/card_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform card for CoUI Web.
///
/// Provides five layout slots: [media], [header], [body], [footer],
/// and [overlay]. Visual style is controlled by [variant]; sizing,
/// elevation, clip-behaviour, and all chrome / dimensional overrides
/// flow through the single [cardStyle] (a [CoreCardStyle]).
///
/// Example:
/// ```dart
/// Card(
///   variant: CoreCardVariant.outlined,
///   cardStyle: CoreCardStyle(elevation: CoreCardElevation.soft),
///   media: img(src: 'image.jpg', classes: 'w-full'),
///   header: text('Product Name'),
///   body: text('Description'),
///   footer: Button(
///     variant: CoreButtonVariant.primary,
///     child: text('Buy Now'),
///   ),
/// )
/// ```
///
/// surface:behind — draws its own box rather than composing one, so what
/// shows through it is the page it sits on. Its Flutter twin inherits this
/// through `OutlinedContainer` instead.
///
/// surface:content — a face in the page flow: what shows through it is the
/// page it is laid on. A caller that floats a card says so through [role].
class Card extends UiComponent implements CoreCardContract<Component> {
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
    this.role = .defaultRole,
    Component? child,
    List<Component>? children,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : _child = child,
       _children = children,
       super(tag: 'div');

  @override
  final CoreCardVariant variant;

  @override
  final Component? media;

  @override
  final Component? header;

  @override
  final Component? body;

  @override
  final Component? footer;

  @override
  final Component? overlay;

  @override
  final void Function()? onTap;

  @override
  final CoreCardStyle? cardStyle;

  @override
  final CoreSurfaceRole role;

  @override
  Component? get child => _child;

  /// Custom children for completely custom layouts.
  final List<Component>? _children;

  final Component? _child;
  @override
  Card copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreCardVariant? variant,
    Component? media,
    Component? header,
    Component? body,
    Component? footer,
    Component? overlay,
    Component? child,
    List<Component>? children,
    void Function()? onTap,
    CoreCardStyle? cardStyle,
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
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? _children,
      child: child ?? _child,
    );
  }

  @override
  Component build(BuildContext context) {
    final interactive = onTap != null;
    final resolved = resolveCard(
      context,
      variant: variant,
      hasMedia: media != null,
      interactive: interactive,
      singleCustomChild: _child != null && _children == null,
      cardStyle: cardStyle,
      role: role,
    );

    final customChildren = _children;
    final customChild = _child;
    final hasSlots =
        media != null ||
        header != null ||
        body != null ||
        footer != null ||
        overlay != null;
    final hasCustom = customChildren != null || customChild != null;

    final List<Component> childList;
    if (hasSlots && !hasCustom) {
      childList = _buildSlotChildren(resolved);
    } else if (hasCustom) {
      final customs = customChildren ?? [customChild!];
      childList = [
        div(
          customs,
          classes: resolved.customWrapper.className,
          styles: resolved.customWrapper.inlineStyles,
        ),
      ];
    } else {
      childList = const [];
    }

    // Non-interactive: caller chrome (id / classes / css / attributes /
    // events) stays on the styled card root. Interactive: the caller
    // passthrough moves to the composing `Clickable` root (checkbox
    // pilot pattern) and the card body carries only its own resolved
    // chrome — the CSS `:hover` shadow class still fires on this element.
    final userClasses = classes;
    final finalClasses =
        interactive || userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    final cardBody = div(
      childList,
      id: interactive ? null : id,
      classes: finalClasses,
      styles: interactive
          ? resolved.root.inlineStyles
          : Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: interactive ? null : componentAttributes,
      events: interactive ? null : this.events,
    );

    if (!interactive) {
      return cardBody;
    }

    // Web twin of the Flutter card: the composed `Clickable` owns tap /
    // keyboard activation / cursor / focus ring (role="button" +
    // tabindex). Press-shrink is disabled for the large card surface via
    // the nested `clickableStyle` slot; the hover-shadow feedback stays
    // on the card body. Wiring `onPressed: onTap` also activates the
    // previously-dead web `onTap` (it was only a resolver flag before).
    return Clickable(
      onPressed: onTap,
      attributes: componentAttributes,
      classes: classes,
      css: this.css,
      eventHandlers: eventHandlers,
      id: id,
      clickableStyle: resolved.clickableStyle,
      child: cardBody,
    );
  }

  List<Component> _buildSlotChildren(ResolvedCard resolved) {
    final contentItems = <Component>[
      if (header != null)
        div(
          [header!],
          classes: resolved.header.className,
          styles: resolved.header.inlineStyles,
        ),
      if (body != null) ...[
        if (header != null) Gap(gapStyle: resolved.headerBodyGapStyle),
        body!,
      ],
      if (footer != null) ...[
        if (header != null || body != null)
          Gap(gapStyle: resolved.bodyFooterGapStyle),
        footer!,
      ],
    ];

    return [
      if (media != null)
        div(
          [
            media!,
            if (overlay != null)
              div(
                [overlay!],
                classes: resolved.overlayWrapper.className,
                styles: resolved.overlayWrapper.inlineStyles,
              ),
          ],
          classes: resolved.mediaWrapper.className,
        ),
      if (contentItems.isNotEmpty)
        div(
          contentItems,
          classes: resolved.contentWrapper.className,
          styles: resolved.contentWrapper.inlineStyles,
        ),
    ];
  }
}

/// Chain sugar mirroring the Flutter `Card.withStyle` extension —
/// merges a [CoreCardStyle] patch into [Card.cardStyle] via the
/// existing [Card.copyWith]. Composition slots (`media` / `header` /
/// `body` / `footer` / `overlay` / `child`) keep using their own
/// components directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCardStyle.merge` right-side-wins semantics).
///
/// `.outline` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension CardStyleChain on Card {
  /// Sets the background paint and preserves the other style fields.
  Card backgroundColor(CoreColor value) =>
      withStyle(CoreCardStyle(backgroundColor: value));

  /// Sets the padding around the child or the header, body and footer slots.
  Card contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreCardStyle(padding: value));

  /// Sets the border color.
  Card borderColor(CoreColor value) =>
      withStyle(CoreCardStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Card borderWidth(double value) =>
      withStyle(CoreCardStyle(borderWidth: value));

  /// Returns a copy of this [Card] with [patch] merged into
  /// [cardStyle] (patch fields win on conflict).
  Card withStyle(CoreCardStyle patch) =>
      copyWith(cardStyle: (cardStyle ?? const CoreCardStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  Card get radius0 => withStyle(
    const CoreCardStyle(borderRadius: CoreBorderRadius.zero),
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

  /// Selects `variant: .outlined` using the component theme.
  Card get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  Card get transparent =>
      withStyle(const CoreCardStyle(backgroundColor: .transparent));
}
