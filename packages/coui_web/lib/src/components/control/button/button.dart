import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Whether this button publishes a real anchor.
///
/// Blank [href] is not a destination. Explicit `enabled: false` stays
/// a `<button>` even when a URL was passed.
bool _isAnchor({
  required String? href,
  required bool? enabled,
  required void Function()? onPressed,
}) {
  final destination = href?.trim();
  final hasHref = destination != null && destination.isNotEmpty;
  final effectiveEnabled = enabled ?? (onPressed != null || hasHref);
  return hasHref && effectiveEnabled;
}

/// Unified cross-platform button for CoUI Web with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, semantic enums (`variant`, `size`, `shape`)
/// are widget parameters because they identify the button instance —
/// the design system maps each to a known chrome look. All chrome /
/// dimensional / nested-slot overrides flow through the single
/// [buttonStyle] (a [CoreButtonStyle]).
///
/// Example:
/// ```dart
/// Button(
///   variant: CoreButtonVariant.primary,
///   onPressed: () => print('Clicked!'),
///   child: text('Submit'),
/// )
///
/// // Marketing CTA — a real `<a href>`, not a disabled button.
/// Button(href: '/contact', child: text('Contact'))
/// ```
///
/// surface:behind — whatever a filled button is laid on (a card, a hero
/// image, a page that scrolls under a toolbar). Its box paints its own
/// fill rather than composing `OutlinedContainer` — the root already
/// resolves hover × focus × disabled × selected — so the material is
/// restated on that box. Only a button whose resting fill paints takes it;
/// one that rests unfilled (ghost, plain, menu) has no box to frost.
///
/// surface:content — a control face in the page flow: what shows through a
/// translucent fill is the page it is laid on, not something floating over
/// it. A caller that composes a button into a floating affordance (a
/// toolbar, a menu row) the button itself has no way to detect says so
/// through [role].
class Button extends UiComponent
    implements
        CoreButtonContract<
          Component,
          CorePointerCallback,
          CorePointerCallback,
          CorePointerCallback,
          CorePointerCallback,
          CoreDragCallback,
          CoreAlignment,
          CoreFocusNode,
          CoreStatesController
        > {
  /// Creates a [Button].
  Button({
    required this.child,
    super.key,
    this.variant = CoreButtonVariant.primary,
    this.size = CoreComponentSize.md,
    this.shape = CoreButtonShape.rectangle,
    this.role = .defaultRole,
    this.leading,
    this.trailing,
    this.onPressed,
    this.enabled,
    this.href,
    this.external = false,
    this.buttonStyle,
    this.alignment,
    this.marginAlignment,
    this.expanded = false,
    this.focusNode,
    this.statesController,
    this.disableTransition = false,
    this.disableFocusOutline = false,
    this.disableHoverEffect = false,
    this.enableFeedback,
    this.onFocus,
    this.onHover,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onTertiaryTapCancel,
    this.onLongPressStart,
    this.onLongPressUp,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onSecondaryLongPress,
    this.onTertiaryLongPress,
    super.classes,
    super.css,
    super.id,
    super.attributes,
  }) : super(
         tag:
             _isAnchor(
               href: href,
               enabled: enabled,
               onPressed: onPressed,
             )
             ? _kAnchor
             : _kButton,
         onClick: onPressed == null ? null : (_) => onPressed(),
         onMouseEnter: onHover == null ? null : (_) => onHover(true),
         onMouseLeave: onHover == null ? null : (_) => onHover(false),
       );

  // === Content ===

  @override
  final Component child;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final VoidCallback? onPressed;

  /// Whether the button is enabled. `null` (the default) falls back to
  /// `onPressed != null || href` so a button with neither a callback nor
  /// a destination reads as disabled — matching Flutter. A marketing
  /// link-button (`href` set, `onPressed` null) stays enabled. Pass
  /// `true`/`false` to force it.
  @override
  final bool? enabled;

  /// Destination of a link-button. See [CoreButtonContract.href].
  @override
  final String? href;

  /// Whether the link-button opens in a new browsing context.
  /// See [CoreButtonContract.external].
  @override
  final bool external;

  /// Trimmed [href], or null when absent / blank.
  String? get _href {
    final value = href?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Effective interactive state — explicit [enabled] wins, else a
  /// callback or a destination decides (Flutter parity).
  bool get _effectiveEnabled => enabled ?? (onPressed != null || _href != null);

  /// Enabled link-buttons are a real anchor. A disabled one stays a
  /// `<button disabled>` so `:disabled` chrome still applies and the
  /// URL is not published for crawlers.
  bool get _rendersAnchor =>
      _isAnchor(href: href, enabled: enabled, onPressed: onPressed);

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreButtonVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final CoreButtonShape shape;

  @override
  final CoreSurfaceRole role;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreButtonStyle? buttonStyle;

  // === Layout (behaviour, not chrome) ===

  @override
  final CoreAlignment? alignment;

  @override
  final CoreAlignment? marginAlignment;

  @override
  final bool expanded;

  // === Interaction callbacks ===

  @override
  final CoreValueChanged<bool>? onHover;

  @override
  final CoreValueChanged<bool>? onFocus;

  @override
  final CorePointerCallback? onTapDown;

  @override
  final CorePointerCallback? onTapUp;

  @override
  final VoidCallback? onTapCancel;

  @override
  final CorePointerCallback? onSecondaryTapDown;

  @override
  final CorePointerCallback? onSecondaryTapUp;

  @override
  final VoidCallback? onSecondaryTapCancel;

  @override
  final CorePointerCallback? onTertiaryTapDown;

  @override
  final CorePointerCallback? onTertiaryTapUp;

  @override
  final VoidCallback? onTertiaryTapCancel;

  @override
  final CorePointerCallback? onLongPressStart;

  @override
  final VoidCallback? onLongPressUp;

  @override
  final CoreDragCallback? onLongPressMoveUpdate;

  @override
  final CorePointerCallback? onLongPressEnd;

  @override
  final VoidCallback? onSecondaryLongPress;

  @override
  final VoidCallback? onTertiaryLongPress;

  // === Visual options ===

  @override
  final bool disableTransition;

  @override
  final bool disableFocusOutline;

  /// Whether to suppress the hover visual effect on this instance.
  /// `false` defers to [CoreButtonStyle.disableHoverEffect] (the
  /// project-level toggle, set through the theme's button style).
  final bool disableHoverEffect;

  @override
  final bool? enableFeedback;

  // === Focus & State ===

  @override
  final CoreFocusNode? focusNode;

  @override
  final CoreStatesController? statesController;

  // === Internal ===

  static const _kButton = 'button';
  static const _kAnchor = 'a';
  static const _kTypeAttr = 'type';
  static const _kHrefAttr = 'href';
  static const _kTargetAttr = 'target';
  static const _kRelAttr = 'rel';
  static const _kBlank = '_blank';
  static const _kNoopener = 'noopener noreferrer';
  static const _kDisabledAttr = 'disabled';
  static const _kTabindexAttr = 'tabindex';
  static const _kTabindexDisabled = '-1';
  static const _kTrue = 'true';

  @override
  Button copyWith({
    CoreButtonVariant? variant,
    Component? child,
    CoreComponentSize? size,
    CoreButtonShape? shape,
    CoreSurfaceRole? role,
    Component? leading,
    Component? trailing,
    VoidCallback? onPressed,
    bool? enabled,
    String? href,
    bool? external,
    CoreButtonStyle? buttonStyle,
    CoreAlignment? alignment,
    CoreAlignment? marginAlignment,
    bool? expanded,
    CoreFocusNode? focusNode,
    CoreStatesController? statesController,
    bool? disableTransition,
    bool? disableFocusOutline,
    bool? disableHoverEffect,
    bool? enableFeedback,
    CoreValueChanged<bool>? onFocus,
    CoreValueChanged<bool>? onHover,
    CorePointerCallback? onTapDown,
    CorePointerCallback? onTapUp,
    VoidCallback? onTapCancel,
    CorePointerCallback? onSecondaryTapDown,
    CorePointerCallback? onSecondaryTapUp,
    VoidCallback? onSecondaryTapCancel,
    CorePointerCallback? onTertiaryTapDown,
    CorePointerCallback? onTertiaryTapUp,
    VoidCallback? onTertiaryTapCancel,
    CorePointerCallback? onLongPressStart,
    VoidCallback? onLongPressUp,
    CoreDragCallback? onLongPressMoveUpdate,
    CorePointerCallback? onLongPressEnd,
    VoidCallback? onSecondaryLongPress,
    VoidCallback? onTertiaryLongPress,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
  }) {
    return Button(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      href: href ?? this.href,
      external: external ?? this.external,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      role: role ?? this.role,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      enabled: enabled ?? this.enabled,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      alignment: alignment ?? this.alignment,
      marginAlignment: marginAlignment ?? this.marginAlignment,
      expanded: expanded ?? this.expanded,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      disableTransition: disableTransition ?? this.disableTransition,
      disableFocusOutline: disableFocusOutline ?? this.disableFocusOutline,
      disableHoverEffect: disableHoverEffect ?? this.disableHoverEffect,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      onFocus: onFocus ?? this.onFocus,
      onHover: onHover ?? this.onHover,
      onTapDown: onTapDown ?? this.onTapDown,
      onTapUp: onTapUp ?? this.onTapUp,
      onTapCancel: onTapCancel ?? this.onTapCancel,
      onSecondaryTapDown: onSecondaryTapDown ?? this.onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp ?? this.onSecondaryTapUp,
      onSecondaryTapCancel: onSecondaryTapCancel ?? this.onSecondaryTapCancel,
      onTertiaryTapDown: onTertiaryTapDown ?? this.onTertiaryTapDown,
      onTertiaryTapUp: onTertiaryTapUp ?? this.onTertiaryTapUp,
      onTertiaryTapCancel: onTertiaryTapCancel ?? this.onTertiaryTapCancel,
      onLongPressStart: onLongPressStart ?? this.onLongPressStart,
      onLongPressUp: onLongPressUp ?? this.onLongPressUp,
      onLongPressMoveUpdate:
          onLongPressMoveUpdate ?? this.onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd ?? this.onLongPressEnd,
      onSecondaryLongPress: onSecondaryLongPress ?? this.onSecondaryLongPress,
      onTertiaryLongPress: onTertiaryLongPress ?? this.onTertiaryLongPress,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      id: id ?? this.id,
      attributes: attributes ?? userAttributes,
      child: child ?? this.child,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Anchors must not carry `type=button` — that attribute is for
    // `<button>`. A real `href` is what makes the control crawlable.
    if (_rendersAnchor) {
      final destination = _href;
      if (destination != null) {
        attributes.add(_kHrefAttr, destination);
      }
      if (external) {
        attributes
          ..add(_kTargetAttr, _kBlank)
          ..add(_kRelAttr, _kNoopener);
      }
    } else {
      attributes.add(_kTypeAttr, _kButton);
    }

    // Handle disabled state. Link-buttons that are explicitly disabled
    // take this branch (`_rendersAnchor` is false), so `:disabled`
    // chrome still applies.
    if (!_effectiveEnabled) {
      attributes
        ..add(_kDisabledAttr, '')
        ..add(_kTabindexAttr, _kTabindexDisabled)
        ..addAria(_kDisabledAttr, _kTrue);
    }
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolveButton(
      context,
      variant: variant,
      size: size,
      shape: shape,
      expanded: expanded,
      role: role,
      disableTransition: disableTransition,
      enableFeedback:
          enableFeedback ?? CoreButtonContract.defaultEnableFeedback,
      buttonStyle: buttonStyle,
    );

    // Scope id for per-instance pseudo-state scoped rules (raw hover
    // colour / off-scale focus ring) — the caller's id wins (passthrough),
    // else a generated one (progress pattern).
    final scopeId = id ?? elementScopeId(context, prefix: 'co-button');
    final rules = resolveButtonRules(
      context,
      scopeId: scopeId,
      variant: variant,
      buttonStyle: buttonStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return Component.element(
      tag: tag,
      // The id is only needed when scoped pseudo rules are present (or the
      // caller passed one) — default-path buttons stay id-less so SSR
      // markup doesn't churn.
      id: rules.css.isNotEmpty ? scopeId : id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
      children: [
        // `<style>` is `display: none`, so it never affects the button's
        // inline-flex layout.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        // Dashed border — an SVG overlay stroking with `currentColor`
        // (colour class rides the `<svg>` itself), pattern-deterministic
        // across browsers and tunable via the `dashLength`/`dashSpacing`
        // slots.
        if (resolved.dashOverlay != null && resolved.dashRect != null)
          Component.element(
            tag: 'svg',
            classes: resolved.dashOverlay!.className,
            styles: resolved.dashOverlay!.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [
              Component.element(
                tag: 'rect',
                styles: resolved.dashRect!.inlineStyles,
                children: const [],
              ),
            ],
          ),
        // The leading icon theme wraps the whole content, not just the
        // leading slot — an icon-only button's glyph is its `child`
        // (mirrors the Flutter `IconTheme.merge(leadingIconTheme)` around
        // the container). `IconTheme` emits no DOM.
        IconTheme(
          data: IconThemeData.fromCoreIconStyle(resolved.leadingIconStyle),
          child: _buildContent(resolved: resolved),
        ),
      ],
    );
  }

  Component _buildContent({required ResolvedButton resolved}) {
    final currentLeading = leading;
    final currentTrailing = trailing;

    // Wrapper element only emitted when there is actually something
    // to wrap around the child. The resolver always provides wrapper
    // chrome — the layout call lives here.
    if (currentLeading == null && currentTrailing == null) {
      return child;
    }

    // Interleave explicit `Gap` widgets between leading / child /
    // trailing so the per-side spacing is owned by the nested
    // `iconLabelGapStyle` slot (matching the Flutter widget). `Gap`
    // runs its own resolve / scaling step — no inline `gap` CSS lives
    // on the content wrapper.
    final gap = Gap(gapStyle: resolved.iconLabelGapStyle);

    // When the button is full-width (`expanded`), the label grows to fill
    // so the trailing slot sits flush-right — mirroring the Flutter
    // `Expanded(child)`. Non-expanded buttons keep the label intrinsic.
    final labelChild = expanded
        ? span([child], classes: resolved.expandedLabel.className)
        : child;
    final content = [
      if (currentLeading != null) ...[currentLeading, gap],
      labelChild,
      if (currentTrailing != null) ...[
        gap,
        IconTheme(
          data: IconThemeData.fromCoreIconStyle(resolved.trailingIconStyle),
          child: currentTrailing,
        ),
      ],
    ];

    return span(
      content,
      classes: resolved.content.className,
      styles: resolved.content.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Button.withStyle` extension —
/// merges a [CoreButtonStyle] patch into [Button.buttonStyle] via the
/// existing [Button.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreButtonStyle.merge` right-side-wins semantics).
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
/// sets [CoreButtonStyle.borderRadius] and `.primary` sets
/// [CoreButtonStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Button(child: text('Submit')).radius4.primary
/// ```
extension ButtonStyleChain on Button {
  /// Returns a copy of this [Button] with [patch] merged into
  /// [buttonStyle] (patch fields win on conflict).
  Button withStyle(CoreButtonStyle patch) => copyWith(
    buttonStyle: (buttonStyle ?? const CoreButtonStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Button get radius0 => withStyle(
    const CoreButtonStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Button get radius2 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Button get radius4 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Button get radius6 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Button get radius8 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Button get radius10 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Button get radius12 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Button get radius14 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Button get radius16 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Button get radius20 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Button get radius24 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Button get radius28 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Button get radius32 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Button get radius36 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Button get radius40 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Button get radius48 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Button get radius56 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Button get radius64 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Button get radius9999 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Button get primary => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Button get secondary => withStyle(
    const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Button get tertiary => withStyle(
    const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Button get surface => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Button get surfaceContainer => withStyle(
    const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Button get error => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Button get success => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Button get warning => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Button get info => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Button get outline => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Button get transparent =>
      withStyle(const CoreButtonStyle(backgroundColor: .transparent));
}
