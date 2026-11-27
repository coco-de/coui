import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform empty state.
///
/// Displays a placeholder view when there is no content, with optional
/// icon, title, description, and action button. The redesign draws no
/// box of its own — no border, no radius, no background — just a
/// centred content stack over whatever surface hosts it.
///
/// Implements [CoreEmptyStateContract] from `coui_core` for a
/// consistent cross-platform API. All chrome (padding / gaps / icon
/// size / typography) flows through [emptyStateStyle] — a single
/// [CoreEmptyStateStyle] slot — so widget-level overrides never split
/// the merge chain.
///
/// Example:
/// ```dart
/// EmptyState(
///   icon: Icon(LucideIcons.inbox),
///   title: Text('No results found'),
///   description: Text('Try adjusting your search criteria'),
///   action: Button(
///     variant: .primary,
///     onPressed: () {},
///     child: Text('Clear Filters'),
///   ),
/// )
/// ```
class EmptyState extends StatelessWidget
    implements CoreEmptyStateContract<Widget> {
  /// Creates a [EmptyState].
  const EmptyState({
    required this.title,
    super.key,
    this.variant = CoreEmptyStateVariant.defaultVariant,
    this.tone = CoreEmptyStateTone.defaultTone,
    this.icon,
    this.showIcon = true,
    this.description,
    this.showDescription = true,
    this.action,
    this.emptyStateStyle,
  });

  /// Creates a compact [EmptyState] for smaller containers.
  ///
  /// Shorthand for `variant: CoreEmptyStateVariant.compact`.
  const EmptyState.compact({
    required this.title,
    super.key,
    this.tone = CoreEmptyStateTone.defaultTone,
    this.icon,
    this.showIcon = true,
    this.description,
    this.showDescription = true,
    this.action,
    this.emptyStateStyle,
  }) : variant = CoreEmptyStateVariant.compact;

  @override
  final Widget title;

  @override
  final CoreEmptyStateVariant variant;

  @override
  final CoreEmptyStateTone tone;

  @override
  final Widget? icon;

  @override
  final bool showIcon;

  @override
  final Widget? description;

  @override
  final bool showDescription;

  @override
  final Widget? action;

  @override
  final CoreEmptyStateStyle? emptyStateStyle;

  /// Returns a copy of this [EmptyState] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  EmptyState copyWith({
    Key? key,
    Widget? title,
    CoreEmptyStateVariant? variant,
    CoreEmptyStateTone? tone,
    Widget? icon,
    bool? showIcon,
    Widget? description,
    bool? showDescription,
    Widget? action,
    CoreEmptyStateStyle? emptyStateStyle,
  }) {
    return EmptyState(
      key: key ?? this.key,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      tone: tone ?? this.tone,
      icon: icon ?? this.icon,
      showIcon: showIcon ?? this.showIcon,
      description: description ?? this.description,
      showDescription: showDescription ?? this.showDescription,
      action: action ?? this.action,
      emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveEmptyState(
      context,
      variant: variant,
      tone: tone,
      emptyStateStyle: emptyStateStyle,
    );

    final effectiveIcon = showIcon ? icon : null;
    final effectiveDescription = showDescription ? description : null;

    final content = Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        if (effectiveIcon != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: resolved.iconBoxColor,
              borderRadius: resolved.iconBoxBorderRadius,
            ),
            child: SizedBox.square(
              dimension: resolved.iconBoxSize,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    size: resolved.iconSize,
                    color: resolved.iconColor,
                  ),
                  child: effectiveIcon,
                ),
              ),
            ),
          ),
          Gap(gapStyle: resolved.iconTitleGapStyle),
        ],
        // Only the text block is width-capped — the stack itself fills
        // whatever width its host gives it.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolved.maxTextWidth),
          child: Column(
            mainAxisSize: .min,
            children: [
              DefaultTextStyle(
                style: resolved.titleTextStyle,
                textAlign: .center,
                child: title,
              ),
              if (effectiveDescription != null) ...[
                Gap(gapStyle: resolved.titleDescriptionGapStyle),
                DefaultTextStyle(
                  style: resolved.descriptionTextStyle,
                  textAlign: .center,
                  child: effectiveDescription,
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          Gap(gapStyle: resolved.descriptionActionGapStyle),
          action!,
        ],
      ],
    );

    // `minHeight` is the height of the whole stack, padding included — the
    // Web's `min-height` on a border-box root. The floor therefore wraps the
    // padding; inside it, `normal` stood 240 + 2 × 32 = 304 tall and `large`
    // 240 + 2 × 40 = 320 where the Web and the design draw 240.
    final stack = ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      child: Padding(
        padding: resolved.padding,
        child: Center(child: content),
      ),
    );

    // A failure announces itself; an absence does not. "No orders yet"
    // and "Could not load orders" are the same box of text to a reader,
    // and only one of them is news. Routed through the same seat the
    // alert uses, so the two components cannot answer this differently.
    // The icon tint (`resolved.iconColor`, via `defaultsByTone`) is the
    // other half — a field that only changed the announcement would be
    // half an axis (`widget/failure-surfaces.md`).
    if (tone != .failure) return stack;

    return CoUISemantics(
      role: .alert,
      container: true,
      child: stack,
    );
  }
}

/// Chain sugar for merging a [CoreEmptyStateStyle] patch into
/// [EmptyState.emptyStateStyle] without hand-reconstructing every field.
/// Mirrors the Web `EmptyState.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreEmptyStateStyle.merge` right-side-wins semantics).
///
/// ```dart
/// EmptyState(title: Text('No results')).withStyle(
///   CoreEmptyStateStyle(minHeight: 320),
/// )
/// ```
extension EmptyStateStyleChain on EmptyState {
  /// Sets the content padding.
  EmptyState contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreEmptyStateStyle(padding: value));

  /// Returns a copy of this [EmptyState] with [patch] merged into
  /// [emptyStateStyle] (patch fields win on conflict).
  EmptyState withStyle(CoreEmptyStateStyle patch) => copyWith(
    emptyStateStyle: (emptyStateStyle ?? const CoreEmptyStateStyle()).merge(
      patch,
    ),
  );
}
