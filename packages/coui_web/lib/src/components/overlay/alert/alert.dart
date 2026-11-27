import 'package:coui_web/coui_web.dart';

/// A unified alert component for CoUI Web.
///
/// Renders a styled alert box with variant-based Tailwind CSS classes,
/// optional title, description, dismiss button, and action widget.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [alertStyle] (a [CoreAlertStyle]). The
/// semantic enums (`variant` / `layout`), the composition slots
/// (`leading` / `action`) and behaviour fields (`title` / `description` /
/// `onDismiss`) stay flat on the component.
///
/// ```text
/// design system default for alert
///   → CoreAlertTheme.style                  // 프로젝트 공통
///   → component.alertStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Alert(
///   title: 'Heads up!',
///   description: 'You can add components using the CLI.',
///   variant: CoreAlertVariant.info,
///   onDismiss: () => handleDismiss(),
/// )
///
/// // A one-line status strip — a badge in place of the glyph.
/// Alert(
///   layout: CoreAlertLayout.inline,
///   leading: Badge(
///     tone: CoreBadgeTone.success,
///     showDot: true,
///     child: Text('Synced'),
///   ),
///   title: 'All changes saved to the cloud.',
/// )
/// ```
///
/// surface:behind — draws its own box rather than composing one, so what
/// shows through it is the page it sits on. Its Flutter twin inherits this
/// through `OutlinedContainer` instead.
///
/// surface:content — a banner in the page flow rather than something
/// mounted over it.
class Alert extends UiComponent implements CoreAlertContract<Component> {
  /// Creates a [Alert].
  const Alert({
    required this.title,
    this.description,
    this.variant = CoreAlertVariant.defaultVariant,
    this.layout = CoreAlertLayout.defaultLayout,
    this.leading,
    this.showIcon = CoreAlertContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.alertStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Creates an info alert.
  const Alert.info({
    required this.title,
    this.description,
    this.layout = CoreAlertLayout.defaultLayout,
    this.leading,
    this.showIcon = CoreAlertContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.alertStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : variant = CoreAlertVariant.info,
       super(tag: 'div');

  /// Creates a success alert.
  const Alert.success({
    required this.title,
    this.description,
    this.layout = CoreAlertLayout.defaultLayout,
    this.leading,
    this.showIcon = CoreAlertContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.alertStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : variant = CoreAlertVariant.success,
       super(tag: 'div');

  /// Creates a warning alert.
  const Alert.warning({
    required this.title,
    this.description,
    this.layout = CoreAlertLayout.defaultLayout,
    this.leading,
    this.showIcon = CoreAlertContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.alertStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : variant = CoreAlertVariant.warning,
       super(tag: 'div');

  /// Creates a destructive/error alert.
  const Alert.destructive({
    required this.title,
    this.description,
    this.layout = CoreAlertLayout.defaultLayout,
    this.leading,
    this.showIcon = CoreAlertContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.alertStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : variant = CoreAlertVariant.destructive,
       super(tag: 'div');

  @override
  final String title;

  @override
  final String? description;

  @override
  final CoreAlertVariant variant;

  @override
  final CoreAlertLayout layout;

  @override
  final Component? leading;

  @override
  final bool showIcon;

  @override
  final CoreVoidCallback? onDismiss;

  @override
  final Component? action;

  /// Per-instance composite style. See [CoreAlertStyle] for the merge
  /// chain.
  @override
  final CoreAlertStyle? alertStyle;

  /// How urgently this alert interrupts, by tone.
  ///
  /// `alert` is an assertive live region: it cuts off whatever the
  /// screen reader is currently saying. That is right for a failure and
  /// wrong for everything else — a success confirmation or an
  /// informational banner announced assertively interrupts the sentence
  /// the user was listening to, every time one renders.
  ///
  /// The neutral variant gets no live region at all. It carries no tone,
  /// so it is a container holding a message rather than an announcement
  /// that something just happened.
  CoreSemanticRole? get _role => switch (variant) {
    .destructive => .alert,
    .warning || .success || .info => .status,
    .neutral => null,
  };

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    final role = _role;
    if (role != null) attributes.add('role', role.ariaRole);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveAlert(
      context,
      variant: variant,
      layout: layout,
      alertStyle: alertStyle,
    );

    // Icon glyph follows the widget's semantic `variant` prop (Epic
    // #1603 옵션 B 최종 — semantic identifiers are widget-only; the
    // theme cannot override them).
    final iconName = switch (variant) {
      .neutral || .info => LucideIcons.info,
      .success => LucideIcons.circleCheck,
      .warning => LucideIcons.triangleAlert,
      .destructive => LucideIcons.circleAlert,
    };

    final contentChildren = <Component>[
      div(
        [Text(title)],
        classes: resolved.title.className,
        styles: resolved.title.inlineStyles,
      ),
      // The inline strip has room for one voice — the title. Its
      // description is not drawn.
      if (layout == .stacked && description != null)
        div(
          [Text(description!)],
          classes: resolved.description.className,
          styles: resolved.description.inlineStyles,
        ),
    ];

    final rowChildren = <Component>[
      // The glyph slot and the gap after it, together: with `showIcon` off
      // the text starts at the panel's inset — the Flutter twin's branch.
      if (showIcon) ...[
        // A caller's `leading` takes the glyph's place outright, under the
        // glyph's colour and size as the ambient `IconTheme` — the same
        // hand-off the Flutter twin makes — so a bare icon there matches the
        // glyph it replaces. It sits in its own structural box rather than
        // the glyph's: that one passes its colour and its line height of 1 to
        // everything inside it, which would recolour a text `leading` here
        // and not on Flutter. `IconTheme` emits no DOM.
        if (leading case final leading?)
          div(
            [
              IconTheme(
                data: IconThemeData.fromCoreIconStyle(
                  resolved.leadingIconStyle,
                ),
                child: leading,
              ),
            ],
            classes: resolved.leading.className,
            styles: resolved.leading.inlineStyles,
          )
        else
          div(
            [Icon(iconName, iconStyle: resolved.iconStyle)],
            classes: resolved.icon.className,
            styles: resolved.icon.inlineStyles,
          ),
        Gap(gapStyle: resolved.iconContentGapStyle),
      ],
      div(
        contentChildren,
        classes: resolved.content.className,
        styles: resolved.content.inlineStyles,
      ),
      if (action != null) ...[
        Gap(gapStyle: resolved.iconContentGapStyle),
        div(
          [
            // Forward the nested action-button style slot to a
            // `Button` action (Epic #1603 옵션 B); other action types
            // render as-is via the asChild pattern.
            if (action case final Button button
                when resolved.actionButtonStyle != null)
              button.copyWith(
                buttonStyle: resolved.actionButtonStyle!.merge(
                  button.buttonStyle,
                ),
              )
            else
              action!,
          ],
          classes: resolved.action.className,
          styles: resolved.action.inlineStyles,
        ),
      ],
      // Dismiss affordance — a unified plain-variant `Button` inside
      // a structural `shrink-0` wrapper. The `plain` variant owns the
      // hover-fade / focus-ring / cursor chrome; the raw-forwarded
      // `closeButtonStyle` slot supplies the tap-target padding /
      // corner radius / hover transition / variant-foreground
      // fade. The close glyph is a `Icon` child whose size comes from
      // the slot's `leadingIconStyle` and whose colour is null so it
      // inherits the button foreground.
      if (onDismiss != null) ...[
        Gap(gapStyle: resolved.iconContentGapStyle),
        div(
          [
            Button(
              onPressed: () => onDismiss?.call(),
              variant: .plain,
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
          classes: resolved.dismiss.className,
          styles: resolved.dismiss.inlineStyles,
        ),
      ],
    ];

    return Component.element(
      tag: tag,
      id: id,
      classes: [resolved.root.className, ?classes].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      // `aria-label` needs `CouiLocalizations.of(context)`, which
      // `configureAttributes` cannot reach (no `BuildContext` there) —
      // merged in here alongside the context-free `role`. Mirrors the
      // Flutter `Alert`'s `CoUISemantics(label: title ?? ...alertLabel)`.
      attributes: {
        ...componentAttributes,
        // `title` is required now, so it is always the better label — the
        // generic localised fallback it used to need is unreachable.
        'aria-label': title,
      },
      events: this.events,
      children: [
        div(rowChildren, classes: resolved.row.className),
      ],
    );
  }

  @override
  Alert copyWith({
    String? title,
    String? description,
    CoreAlertVariant? variant,
    CoreAlertLayout? layout,
    Component? leading,
    bool? showIcon,
    CoreVoidCallback? onDismiss,
    Component? action,
    CoreAlertStyle? alertStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Alert(
      key: key ?? this.key,
      description: description ?? this.description,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      layout: layout ?? this.layout,
      leading: leading ?? this.leading,
      showIcon: showIcon ?? this.showIcon,
      onDismiss: onDismiss ?? this.onDismiss,
      action: action ?? this.action,
      alertStyle: alertStyle ?? this.alertStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the Flutter `Alert.withStyle` extension —
/// merges a [CoreAlertStyle] patch into [Alert.alertStyle] via the
/// existing [Alert.copyWith]. `title`/`description` stay `String` —
/// use `CoreAlertStyle.titleStyle` / `.descriptionStyle` for typography
/// overrides instead of a `Text(...)` chain.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAlertStyle.merge` right-side-wins semantics).
///
/// `.info`, `.success`, `.warning` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension AlertStyleChain on Alert {
  /// Sets the background paint and preserves the other style fields.
  Alert backgroundColor(CoreColor value) =>
      withStyle(CoreAlertStyle(backgroundColor: value));

  /// Returns a copy of this [Alert] with [patch] merged into
  /// [alertStyle] (patch fields win on conflict).
  Alert withStyle(CoreAlertStyle patch) =>
      copyWith(alertStyle: (alertStyle ?? const CoreAlertStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Alert get radius0 => withStyle(
    const CoreAlertStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Alert get radius2 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Alert get radius4 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Alert get radius6 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Alert get radius8 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Alert get radius10 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Alert get radius12 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Alert get radius14 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Alert get radius16 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Alert get radius20 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Alert get radius24 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Alert get radius28 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Alert get radius32 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Alert get radius36 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Alert get radius40 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Alert get radius48 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Alert get radius56 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Alert get radius64 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Alert get radius9999 => withStyle(
    const CoreAlertStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Alert get primary => withStyle(
    const CoreAlertStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Alert get secondary => withStyle(
    const CoreAlertStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Alert get tertiary => withStyle(
    const CoreAlertStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Alert get surface => withStyle(
    const CoreAlertStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Alert get surfaceContainer => withStyle(
    const CoreAlertStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Alert get error => withStyle(
    const CoreAlertStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// Selects `variant: .success` using the component theme.
  Alert get success => copyWith(variant: .success);

  /// Selects `variant: .warning` using the component theme.
  Alert get warning => copyWith(variant: .warning);

  /// Selects `variant: .info` using the component theme.
  Alert get info => copyWith(variant: .info);

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Alert get outline => withStyle(
    const CoreAlertStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Alert get transparent =>
      withStyle(const CoreAlertStyle(backgroundColor: .transparent));
}
