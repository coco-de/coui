import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/empty_state/empty_state_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform empty state for CoUI Web.
///
/// Mirrors Flutter `EmptyState`. Every chrome / dimensional / nested-slot
/// override flows through the single [emptyStateStyle] (a
/// [CoreEmptyStateStyle]). The semantic enum (`variant`) and behaviour
/// fields (`title` / `icon` / `description` / `action`) stay flat on the
/// component. The redesign draws no box of its own — no border, no
/// radius, no background — just a centred content stack.
///
/// ```text
/// design system default for empty state
///   → CoreEmptyStateTheme.style                      // 프로젝트 공통
///   → CoreEmptyStateTheme.variantStyles[variant]
///   → component.emptyStateStyle                      // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// EmptyState(
///   title: text('No items'),
///   description: text('Try adjusting your filters.'),
///   action: Button(child: text('Reset')),
/// )
/// ```
class EmptyState extends UiComponent
    implements CoreEmptyStateContract<Component> {
  /// Creates a [EmptyState].
  EmptyState({
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Creates a compact [EmptyState] for smaller containers.
  ///
  /// Shorthand for `variant: CoreEmptyStateVariant.compact`.
  EmptyState.compact({
    required this.title,
    super.key,
    this.tone = CoreEmptyStateTone.defaultTone,
    this.icon,
    this.showIcon = true,
    this.description,
    this.showDescription = true,
    this.action,
    this.emptyStateStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : variant = CoreEmptyStateVariant.compact,
       super(tag: 'div');

  @override
  final Component title;

  @override
  final CoreEmptyStateVariant variant;

  @override
  final CoreEmptyStateTone tone;

  @override
  final Component? icon;

  @override
  final bool showIcon;

  @override
  final Component? description;

  @override
  final bool showDescription;

  @override
  final Component? action;

  /// Per-instance composite style. See [CoreEmptyStateStyle] for the
  /// merge chain.
  @override
  final CoreEmptyStateStyle? emptyStateStyle;
  @override
  EmptyState copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? title,
    Component? description,
    bool? showDescription,
    Component? icon,
    bool? showIcon,
    Component? action,
    CoreEmptyStateVariant? variant,
    CoreEmptyStateTone? tone,
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
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  /// A failure announces itself; an absence does not.
  ///
  /// "No orders yet" and "Could not load orders" are the same box of
  /// text to a reader, and only one of them is news. Assertive because
  /// the region the user was looking at has failed — the same call the
  /// alert makes for the same reason. The icon tint
  /// (`CoreEmptyStateStyle.defaultsByTone`) is the other half of the
  /// same axis.
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    if (tone == .failure) {
      attributes.add('role', CoreSemanticRole.alert.ariaRole);
    }
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveEmptyState(
      context,
      variant: variant,
      tone: tone,
      emptyStateStyle: emptyStateStyle,
    );

    final effectiveIcon = showIcon ? icon : null;
    final effectiveDescription = showDescription ? description : null;

    final children = <Component>[
      if (effectiveIcon != null) ...[
        div(
          [
            div(
              [effectiveIcon],
              classes: resolved.iconWrapper.className,
              styles: resolved.iconWrapper.inlineStyles,
            ),
          ],
          classes: resolved.iconBox.className,
          styles: resolved.iconBox.inlineStyles,
        ),
        Gap(gapStyle: resolved.iconTitleGapStyle),
      ],
      // Only the text block is width-capped — the stack itself fills
      // whatever width its host gives it.
      div(
        [
          div(
            [title],
            classes: resolved.title.className,
            styles: resolved.title.inlineStyles,
          ),
          if (effectiveDescription != null) ...[
            Gap(gapStyle: resolved.titleDescriptionGapStyle),
            div(
              [effectiveDescription],
              classes: resolved.description.className,
              styles: resolved.description.inlineStyles,
            ),
          ],
        ],
        classes: resolved.textBlock.className,
        styles: resolved.textBlock.inlineStyles,
      ),
      if (action != null) ...[
        Gap(gapStyle: resolved.descriptionActionGapStyle),
        action!,
      ],
    ];

    return div(
      children,
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Chain sugar for merging a [CoreEmptyStateStyle] patch into
/// [EmptyState.emptyStateStyle] via the existing [EmptyState.copyWith].
/// Composition slots (`title` / `icon` / `description` / `action`) keep
/// using the `Text(...).bodyMedium...` chain directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreEmptyStateStyle.merge` right-side-wins semantics).
///
/// ```dart
/// EmptyState(title: text('No results')).withStyle(
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
