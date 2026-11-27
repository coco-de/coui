import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/display/banner/banner_style.dart';

/// A unified banner component for CoUI Web.
///
/// Renders a full-width alert banner with variant-based styling,
/// left accent border, optional icon, dismiss button, and action.
///
/// Per Epic #1302 / #1696 every chrome / dimensional / nested-slot
/// override flows through the single [bannerStyle] (a [CoreBannerStyle]).
/// The semantic enum (`variant`) and behaviour fields (`message` /
/// `description` / `action` / `onDismiss` / `showIcon`) stay flat on
/// the component.
///
/// ```text
/// design system default for banner
///   → CoreBannerTheme.style                  // 프로젝트 공통
///   → component.bannerStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Banner(
///   message: text('Your session will expire in 5 minutes.'),
///   variant: CoreBannerVariant.warning,
///   onDismiss: () => handleDismiss(),
///   action: button([text('Extend')]),
/// )
/// ```
///
/// surface:behind — dismissible and full-width, commonly pinned atop
/// scrollable content as a top-of-page announcement the way a host shell
/// stacks `Dock` or `NavigationBar` over a scrolling body.
///
/// surface:content — a face in the page flow: what shows through it is
/// whatever content it announces over, not a parent panel.
class Banner extends UiComponent implements CoreBannerContract<Component> {
  /// Creates a [Banner].
  const Banner({
    required this.message,
    this.description,
    this.variant = CoreBannerVariant.defaultVariant,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
    super.id,
  }) : super(tag: 'div');

  /// Creates an info banner.
  const Banner.info({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
    super.id,
  }) : variant = CoreBannerVariant.info,
       super(tag: 'div');

  /// Creates a success banner.
  const Banner.success({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
    super.id,
  }) : variant = CoreBannerVariant.success,
       super(tag: 'div');

  /// Creates a warning banner.
  const Banner.warning({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
    super.id,
  }) : variant = CoreBannerVariant.warning,
       super(tag: 'div');

  /// Creates a destructive/error banner.
  const Banner.destructive({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
    super.id,
  }) : variant = CoreBannerVariant.destructive,
       super(tag: 'div');

  @override
  final Component message;

  @override
  final Component? description;

  @override
  final CoreBannerVariant variant;

  @override
  final CoreBannerEmphasis emphasis;

  @override
  final CoreVoidCallback? onDismiss;

  @override
  final Component? action;

  /// Whether to show the default variant icon.
  @override
  final bool showIcon;

  /// Per-instance composite style. See [CoreBannerStyle] for the
  /// merge chain.
  @override
  final CoreBannerStyle? bannerStyle;
  @override
  Banner copyWith({
    Key? key,
    Component? message,
    Component? description,
    CoreBannerVariant? variant,
    CoreBannerEmphasis? emphasis,
    CoreVoidCallback? onDismiss,
    Component? action,
    bool? showIcon,
    CoreBannerStyle? bannerStyle,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
  }) {
    return Banner(
      key: key ?? this.key,
      message: message ?? this.message,
      description: description ?? this.description,
      variant: variant ?? this.variant,
      emphasis: emphasis ?? this.emphasis,
      onDismiss: onDismiss ?? this.onDismiss,
      action: action ?? this.action,
      showIcon: showIcon ?? this.showIcon,
      bannerStyle: bannerStyle ?? this.bannerStyle,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveBanner(
      context,
      variant: variant,
      emphasis: emphasis,
      hasAction: action != null,
      bannerStyle: bannerStyle,
    );

    // Icon glyph follows the widget's semantic `variant` prop —
    // semantic identifiers and the `showIcon` behaviour flag are
    // widget-only; the theme cannot override them.
    final iconName = switch (variant) {
      .neutral => LucideIcons.bell,
      .info => LucideIcons.info,
      .success => LucideIcons.circleCheck,
      .warning => LucideIcons.triangleAlert,
      .destructive => LucideIcons.circleX,
    };

    final currentAction = action;
    final currentOnDismiss = onDismiss;
    final currentDescription = description;

    final children = <Component>[
      // Variant icon — `Icon` so the glyph set / size / color
      // resolution matches `Alert` and the rest of the library
      // (cautions § "아이콘 통일"). The wrapper `<span>` carries the
      // colour token via Tailwind `text-*` so `currentColor` flows
      // into the iconify-icon SVG.
      if (showIcon) ...[
        // Keeps the icon's width in the row; the glyph hangs off the
        // message column below so it centres on the message block.
        span(
          const [],
          classes: resolved.iconSpacer.className,
          styles: resolved.iconSpacer.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
        ),
        // Icon → content gap (mirrors Flutter
        // `Gap(gapStyle: resolved.iconContentGapStyle)`).
        Gap(gapStyle: resolved.iconContentGapStyle),
      ],
      // The message column and the trailing group share one wrapping box,
      // and the icon stays outside it: when the trailing group wraps it
      // starts where the message text starts, not under the icon. The
      // Flutter twin lays the same two children out in `_BannerBody`.
      div(
        [
          // Message + description. Banner sets the surface-appropriate
          // typography (labelLarge for the message, bodySmall for the
          // description) on the wrapper divs; coui_web Text no longer
          // self-applies its own size, so a plain Text in either slot
          // inherits the wrapper class. The host can still override
          // either slot with a chain modifier — an explicit class on
          // the Text element wins over the wrapper cascade. The vertical
          // gap between the title and description is a `Gap` sibling
          // — matches the Flutter banner 1:1.
          div(
            [
              if (showIcon)
                span(
                  [Icon(iconName, iconStyle: resolved.iconStyle)],
                  classes: resolved.icon.className,
                  styles: resolved.icon.inlineStyles,
                  attributes: const {'aria-hidden': 'true'},
                ),
              div(
                [message],
                classes: resolved.title.className,
                styles: resolved.title.inlineStyles,
              ),
              if (currentDescription != null) ...[
                Gap(gapStyle: resolved.titleDescriptionGapStyle),
                div(
                  [currentDescription],
                  classes: resolved.description.className,
                  styles: resolved.description.inlineStyles,
                ),
              ],
            ],
            classes: resolved.content.className,
            styles: resolved.content.inlineStyles,
          ),
          if (currentAction != null || currentOnDismiss != null)
            div(
              [
                // Action — wrapped so the slot wrapper stays a stable
                // element for the asChild pattern. The nested action-button
                // style slot is forwarded to a Button action; other action
                // types render as-is via the asChild pattern.
                if (currentAction != null)
                  div(
                    [
                      if (currentAction case final Button button)
                        button.copyWith(
                          buttonStyle:
                              (button.variant == CoreButtonVariant.plain
                                      ? resolved.plainActionButtonStyle
                                      : resolved.actionButtonStyle)
                                  .merge(button.buttonStyle),
                        )
                      else
                        currentAction,
                    ],
                    classes: resolved.action.className,
                    styles: resolved.action.inlineStyles,
                  ),
                // Dismiss button — unified `Button(variant: .plain)`; the
                // `plain` variant owns the transparent fill / hover-fade,
                // and `resolved.closeButtonStyle` (raw-forward) supplies the
                // full-round corner (circle on the square shape) / hover
                // transition / variant foreground. The close glyph's colour
                // is null so it inherits the button's foreground. Mirrors
                // the Flutter banner's `Button(variant: .plain)` 1:1.
                if (currentOnDismiss != null) ...[
                  // Action → dismiss gap (mirrors Flutter
                  // `Gap(gapStyle: resolved.contentDismissGapStyle)`).
                  if (currentAction != null)
                    Gap(gapStyle: resolved.contentDismissGapStyle),
                  Button(
                    onPressed: currentOnDismiss,
                    variant: .plain,
                    shape: .square,
                    buttonStyle: resolved.closeButtonStyle,
                    attributes: {
                      'aria-label': CouiLocalizations.of(context).dismissLabel,
                    },
                    child: Icon(
                      LucideIcons.x,
                      iconStyle: resolved.closeButtonStyle.leadingIconStyle,
                    ),
                  ),
                ],
              ],
              classes: resolved.trailing.className,
              styles: resolved.trailing.inlineStyles,
            ),
        ],
        classes: resolved.body.className,
        styles: resolved.body.inlineStyles,
      ),
    ];

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return div(
      children,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      // `aria-label` needs `context` (`CouiLocalizations.of`), so it's
      // added here rather than in `configureAttributes`. Mirrors the
      // Flutter `Banner`'s `Semantics(label: ...bannerLabel)`.
      attributes: {
        ...componentAttributes,
        'role': CoreSemanticRole.banner.ariaRole,
        'aria-label': CouiLocalizations.of(context).bannerLabel,
      },
      events: this.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Banner.withStyle` extension —
/// merges a [CoreBannerStyle] patch into [Banner.bannerStyle] via the
/// existing [Banner.copyWith]. Composition slots (`message` /
/// `description` / `action`) keep using the `Text(...).bodyMedium...`
/// chain directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBannerStyle.merge` right-side-wins semantics).
///
/// `.info`, `.success`, `.warning` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension BannerStyleChain on Banner {
  /// Sets the background paint and preserves the other style fields.
  Banner backgroundColor(CoreColor value) =>
      withStyle(CoreBannerStyle(backgroundColor: value));

  /// Returns a copy of this [Banner] with [patch] merged into
  /// [bannerStyle] (patch fields win on conflict).
  Banner withStyle(CoreBannerStyle patch) => copyWith(
    bannerStyle: (bannerStyle ?? const CoreBannerStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Banner get radius0 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Banner get radius2 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Banner get radius4 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Banner get radius6 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Banner get radius8 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Banner get radius10 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Banner get radius12 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Banner get radius14 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Banner get radius16 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Banner get radius20 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Banner get radius24 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Banner get radius28 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Banner get radius32 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Banner get radius36 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Banner get radius40 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Banner get radius48 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Banner get radius56 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Banner get radius64 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Banner get radius9999 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Banner get primary => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Banner get secondary => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Banner get tertiary => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Banner get surface => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Banner get surfaceContainer => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Banner get error => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// Selects `variant: .success` using the component theme.
  Banner get success => copyWith(variant: .success);

  /// Selects `variant: .warning` using the component theme.
  Banner get warning => copyWith(variant: .warning);

  /// Selects `variant: .info` using the component theme.
  Banner get info => copyWith(variant: .info);

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Banner get outline => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Banner get transparent =>
      withStyle(const CoreBannerStyle(backgroundColor: .transparent));
}
