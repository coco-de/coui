import 'package:coui_flutter/coui_flutter.dart';

/// A unified alert component for displaying important messages.
///
/// Renders a styled alert box with variant-based colors, optional icon,
/// title, description, dismiss button, and action widget.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [alertStyle] (a [CoreAlertStyle]). The
/// semantic enums (`variant` / `layout`), the composition slots
/// (`leading` / `action`) and behaviour fields (`title` / `description` /
/// `onDismiss`) stay flat on the widget.
///
/// ```text
/// design system default for alert
///   → CoreAlertTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.alertStyle                     // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Alert(
///   title: 'Heads up!',
///   description: 'You can add components using the CLI.',
///   variant: CoreAlertVariant.info,
///   onDismiss: () => setState(() => _show = false),
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
/// surface:content — a banner in the page flow rather than something
/// mounted over it.
class Alert extends StatelessWidget implements CoreAlertContract<Widget> {
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
  });

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
  }) : variant = CoreAlertVariant.info;

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
  }) : variant = CoreAlertVariant.success;

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
  }) : variant = CoreAlertVariant.warning;

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
  }) : variant = CoreAlertVariant.destructive;

  @override
  final String title;

  @override
  final String? description;

  @override
  final CoreAlertVariant variant;

  @override
  final CoreAlertLayout layout;

  @override
  final Widget? leading;

  @override
  final bool showIcon;

  @override
  final VoidCallback? onDismiss;

  @override
  final Widget? action;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `titleStyle` / `descriptionStyle` / `iconStyle` /
  /// `actionButtonStyle` / `closeButtonStyle` slots. See
  /// [CoreAlertStyle] for the merge chain.
  @override
  final CoreAlertStyle? alertStyle;

  IconName _variantIconName(CoreAlertVariant effectiveVariant) =>
      switch (effectiveVariant) {
        .neutral || .info => LucideIcons.info,
        .success => LucideIcons.circleCheck,
        .warning => LucideIcons.triangleAlert,
        .destructive => LucideIcons.circleAlert,
      };

  /// Returns a copy of this [Alert] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Alert copyWith({
    Key? key,
    String? description,
    String? title,
    CoreAlertVariant? variant,
    CoreAlertLayout? layout,
    Widget? leading,
    bool? showIcon,
    VoidCallback? onDismiss,
    Widget? action,
    CoreAlertStyle? alertStyle,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAlert(
      context,
      variant: variant,
      layout: layout,
      alertStyle: alertStyle,
    );

    // Web has announced this all along and Flutter announced nothing:
    // an alert appearing after load was silent here and interrupting
    // there. Routed through the seat so both platforms read the same
    // decision — the seat turns `alert` / `status` into a live region on
    // Flutter, which is the one announcement axis this platform has.
    //
    // Tone decides urgency. The neutral variant gets no role: it carries
    // no tone, so it is a container holding a message rather than an
    // announcement that something just happened.
    return CoUISemantics(
      role: switch (variant) {
        .destructive => .alert,
        .warning || .success || .info => .status,
        .neutral => null,
      },
      // `title` is required now, so it is always the better label — the
      // generic localised fallback it used to need is unreachable.
      label: title,
      container: true,
      // The panel box is `OutlinedContainer`'s, not this widget's. Drawing
      // it here meant re-implementing a surface a unified component
      // already owns — and a surface drawn that way sits outside anything
      // the style injects into it, so this alert stayed flat under a style
      // whose signature is a hard cast. The container also carries its own
      // padding, so there is no `Padding` wrapper left to apply.
      // The floor goes OUTSIDE the container, not around its content: the
      // container owns the padding, so constraining its child would put the
      // minimum on the content box and add the padding on top of it — the
      // card would come out one padding taller than the token says. Figma
      // states the same minimum on the root frame.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: resolved.minHeight),
        child: OutlinedContainer(
          containerStyle: resolved.containerStyle,
          // Two jobs, two boxes — the same split the Web twin has. The
          // floor makes this column tall and the column centres the row
          // inside it; the row centres its own children on its middle. A
          // title-only alert therefore sits in the middle of the box the
          // floor holds open rather than at its top.
          //
          // `stretch` so the row still gets a tight width for `Expanded`;
          // the default (`center`) would let it shrink to its content.
          child: Column(
            // `min`, not the default `max`: this sits under a floor, and a
            // floor is a minimum, not a height. With `max` the column takes
            // whatever the parent offers and the alert grows to fill the
            // page. `min` still ends up floor-tall — an incoming minimum
            // outranks hugging — which is exactly the box to centre in.
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                // Centred (`Row`'s default cross-axis alignment, left
                // unstated on purpose): the glyph, the text block, the
                // action and the dismiss mark share the row's middle, so a
                // two-line alert reads as one object. The card's minimum
                // height still holds the box open, and `ConstrainedBox`
                // above centres this row inside it, so a title-only alert
                // stays centred rather than pinned to the top.
                children: [
                  // The glyph slot and the gap after it, together: with
                  // `showIcon` off the text starts at the panel's inset.
                  if (showIcon) ...[
                    // A caller's `leading` takes the glyph's place outright,
                    // under the glyph's colour and size as the ambient icon
                    // theme, so a bare icon there matches the glyph it
                    // replaces.
                    if (leading != null)
                      IconTheme(
                        data: IconThemeData(
                          size: resolved.iconStyle.size,
                          color: resolved.iconColor,
                        ),
                        child: leading!,
                      )
                    else
                      // Variant icon, drawn straight onto the panel. It used
                      // to sit in an opaque chip; the chip's only boundary
                      // was a shadow (chip-to-panel contrast measured
                      // 1.07~1.23 across all four modes), which is a boundary
                      // that does not survive a mode that forces colours and
                      // does not enforce shadows.
                      //
                      // Glyph is selected from the widget's semantic
                      // `variant` prop — the theme cannot override semantic
                      // identifiers.
                      Icon(
                        _variantIconName(variant),
                        iconStyle: resolved.iconStyle,
                      ),
                    Gap(gapStyle: resolved.iconContentGapStyle),
                  ],
                  // Content.
                  Expanded(
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        DefaultTextStyle(
                          style: resolved.titleTextStyle,
                          child: Text(
                            title,
                            maxLines: resolved.titleMaxLines,
                            overflow: resolved.titleOverflow,
                          ),
                        ),
                        // The inline strip has room for one voice — the
                        // title. Its description is not drawn.
                        if (layout == .stacked && description != null) ...[
                          Padding(
                            padding: .only(top: resolved.titleBottomPadding),
                            child: DefaultTextStyle(
                              style: resolved.descriptionTextStyle,
                              child: Text(description!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    Gap(gapStyle: resolved.iconContentGapStyle),
                    // A `Button` action takes the `actionButtonStyle` slot
                    // under its own `buttonStyle` (which still wins); any
                    // other widget renders as given — the same as Web.
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
                  // Dismiss affordance — a unified plain-variant button. The
                  // `plain` variant owns the transparent-fill / hover-fade /
                  // focus-ring semantics, and the raw-forwarded
                  // `closeButtonStyle` slot supplies the tap-target padding /
                  // corner radius / hover transition. The close glyph is a
                  // `Icon` child (size from the slot's `leadingIconStyle`;
                  // colour null so it inherits the button's foreground via the
                  // ambient `IconTheme`).
                  if (onDismiss != null) ...[
                    Gap(gapStyle: resolved.iconContentGapStyle),
                    Semantics(
                      label: CoUILocalizations.of(context).dismissLabel,
                      child: Button(
                        onPressed: onDismiss,
                        variant: .plain,
                        buttonStyle: resolved.closeButtonStyle,
                        child: Icon(
                          LucideIcons.x,
                          iconStyle: resolved.closeButtonStyle.leadingIconStyle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreAlertStyle] patch into
/// [Alert.alertStyle] without hand-reconstructing every field. Mirrors
/// the Web `Alert.withStyle` extension so both platforms read
/// identically. `title`/`description` stay `String` (not composition
/// slots) — use [CoreAlertStyle.titleStyle] / `.descriptionStyle` for
/// typography overrides instead of a `Text(...)` chain.
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
