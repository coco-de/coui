import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/frame/frame_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform layout primitive (Web).
///
/// `Frame` is the cross-platform analogue of Flutter `Container` /
/// `Row` / `Column` / `Wrap` / `Padding` / `Center` / `Align` /
/// `SizedBox` / `Expanded` / `DecoratedBox` / `Opacity` / `Transform`
/// / `ClipRRect` / `Visibility` and Web `<div>`. Captures the full
/// Figma Frame surface (Auto Layout + Sizing + Fill + Stroke + Effects
/// + Behaviour) on a single component.
///
/// Resolve precedence per slot: widget parameter > theme override
/// (`CoreFrameTheme`) > component default.
class Frame extends UiComponent
    implements CoreFrameContract<Component, String> {
  /// Creates a [Frame].
  const Frame({
    this.direction,
    this.gap,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.alignment,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.flex,
    this.fit,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.backgroundImage,
    this.borderColor,
    this.borderWidth,
    this.borderStyle,
    this.borderRadius,
    this.boxShadow,
    this.innerShadow,
    this.layerBlur,
    this.backdropBlur,
    this.elevation,
    this.clipBehavior = CoreFrameStyle.defaultClipBehavior,
    this.opacity,
    this.transform,
    this.transformAlignment,
    this.visible = true,
    this.onTap,
    this.onHover,
    this.onFocus,
    this.cursor,
    this.a11y,
    this.duration,
    this.frameStyle,
    this.child,
    this.children,
    super.tag = 'div',
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  });

  @override
  final Component? child;

  @override
  final List<Component>? children;

  // --- Layout ---

  @override
  final CoreFrameDirection? direction;

  @override
  final double? gap;

  @override
  final CoreMainAxisAlignment? mainAxisAlignment;

  @override
  final CoreCrossAxisAlignment? crossAxisAlignment;

  @override
  final CoreAlignment? alignment;

  // --- Sizing ---

  @override
  final double? width;

  @override
  final double? height;

  @override
  final double? minWidth;

  @override
  final double? minHeight;

  @override
  final double? maxWidth;

  @override
  final double? maxHeight;

  // --- Flex ---

  @override
  final int? flex;

  @override
  final CoreFlexFit? fit;

  // --- Spacing ---

  @override
  final CoreEdgeInsets? padding;

  @override
  final CoreEdgeInsets? margin;

  // --- Fill ---

  @override
  final CoreColor? backgroundColor;

  @override
  final CoreGradient? gradient;

  @override
  final CoreImageSource? backgroundImage;

  // --- Stroke ---

  @override
  final CoreColor? borderColor;

  @override
  final double? borderWidth;

  @override
  final CoreFrameBorderStyle? borderStyle;

  @override
  final CoreBorderRadius? borderRadius;

  // --- Effects ---

  @override
  final List<CoreShadowLayer>? boxShadow;

  @override
  final List<CoreShadowLayer>? innerShadow;

  @override
  final double? layerBlur;

  @override
  final double? backdropBlur;

  @override
  final CoreFrameElevation? elevation;

  // --- Behaviour ---

  @override
  final CoreClipBehavior clipBehavior;

  @override
  final double? opacity;

  @override
  final String? transform;

  @override
  final CoreAlignment? transformAlignment;

  @override
  final bool visible;

  // --- Interaction ---

  @override
  final void Function()? onTap;

  @override
  final CoreValueChanged<bool>? onHover;

  @override
  final CoreValueChanged<bool>? onFocus;

  @override
  final CoreCursor? cursor;

  // --- HTML / SEO ---
  // `tag` is provided by [UiComponent].

  // --- Accessibility ---

  @override
  final CoreFrameA11y? a11y;

  /// Animation duration for chrome property changes.
  final Duration? duration;

  // --- Style slot ---

  @override
  final CoreFrameStyle? frameStyle;

  // --- Children ---
  // `child` and `children` are provided by [UiComponent].
  @override
  Component build(BuildContext context) {
    if (!visible) {
      // CSS `display:none` removes the element from layout, matching
      // Flutter `Visibility(visible: false)` / `SizedBox.shrink()`.
      return Component.element(
        tag: tag,
        styles: Styles(raw: const {'display': 'none'}),
      );
    }

    final resolved = resolveFrame(
      context,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderStyle: borderStyle,
      borderRadius: borderRadius,
      padding: padding,
      elevation: elevation,
      duration: duration,
      frameStyle: frameStyle,
      direction: direction,
      gap: gap,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      alignment: alignment,
      width: width,
      height: height,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      flex: flex,
      fit: fit,
      margin: margin,
      gradient: gradient,
      backgroundImage: backgroundImage,
      boxShadow: boxShadow,
      innerShadow: innerShadow,
      layerBlur: layerBlur,
      backdropBlur: backdropBlur,
      opacity: opacity,
      transform: transform,
      transformAlignment: transformAlignment,
      cursor: cursor,
    );

    final baseKids =
        children ?? (child != null ? <Component>[child!] : const <Component>[]);
    // Dashed/dotted border — an SVG overlay stroking with `currentColor`
    // (colour class rides the `<svg>` itself so the frame's arbitrary
    // content keeps its own inherited colour), pattern-deterministic
    // across browsers and tunable via the `dashLength`/`dashSpacing` slots.
    final dashOverlay = resolved.dashOverlay;
    final dashRect = resolved.dashRect;
    final kids = dashOverlay != null && dashRect != null
        ? <Component>[
            Component.element(
              tag: 'svg',
              classes: dashOverlay.className,
              styles: dashOverlay.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
              children: [
                Component.element(
                  tag: 'rect',
                  styles: dashRect.inlineStyles,
                  children: const [],
                ),
              ],
            ),
            ...baseKids,
          ]
        : baseKids;

    // Frame-specific interaction events, merged with the base
    // [UiComponent] event map (onClick / onMouseEnter / eventHandlers …).
    final frameEvents = <String, EventCallback>{...events};
    if (onTap != null) {
      frameEvents['click'] = (_) => onTap!();
    }
    if (onHover != null) {
      frameEvents['mouseenter'] = (_) => onHover!(true);
      frameEvents['mouseleave'] = (_) => onHover!(false);
    }
    if (onFocus != null) {
      frameEvents['focusin'] = (_) => onFocus!(true);
      frameEvents['focusout'] = (_) => onFocus!(false);
    }

    // Frame a11y metadata, merged with base [UiComponent] attributes
    // (configureAttributes + user-provided attributes).
    final frameAttributes = <String, String>{...componentAttributes};
    if (a11y != null) {
      if (a11y!.role != null) frameAttributes['role'] = a11y!.role!.ariaRole;
      if (a11y!.label != null) frameAttributes['aria-label'] = a11y!.label!;
      final extra = a11y!.attributes;
      if (extra != null) {
        for (final entry in extra.entries) {
          frameAttributes[entry.key] = entry.value;
        }
      }
    }
    // `tabindex=0` makes a non-form element keyboard-focusable when it
    // has interactive behaviour — needed for focusin/focusout events to
    // fire on a plain `<div>`.
    if (onTap != null && !frameAttributes.containsKey('tabindex')) {
      frameAttributes['tabindex'] = '0';
    }

    return Component.element(
      tag: tag,
      id: a11y?.id ?? id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: frameAttributes.isEmpty ? null : frameAttributes,
      events: frameEvents.isEmpty ? null : frameEvents,
      children: kids,
    );
  }

  @override
  Frame copyWith({
    CoreFrameDirection? direction,
    double? gap,
    CoreMainAxisAlignment? mainAxisAlignment,
    CoreCrossAxisAlignment? crossAxisAlignment,
    CoreAlignment? alignment,
    double? width,
    double? height,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    int? flex,
    CoreFlexFit? fit,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? margin,
    CoreColor? backgroundColor,
    CoreGradient? gradient,
    CoreImageSource? backgroundImage,
    CoreColor? borderColor,
    double? borderWidth,
    CoreFrameBorderStyle? borderStyle,
    CoreBorderRadius? borderRadius,
    List<CoreShadowLayer>? boxShadow,
    List<CoreShadowLayer>? innerShadow,
    double? layerBlur,
    double? backdropBlur,
    CoreFrameElevation? elevation,
    CoreClipBehavior? clipBehavior,
    double? opacity,
    String? transform,
    CoreAlignment? transformAlignment,
    bool? visible,
    void Function()? onTap,
    CoreValueChanged<bool>? onHover,
    CoreValueChanged<bool>? onFocus,
    CoreCursor? cursor,
    CoreFrameA11y? a11y,
    Duration? duration,
    CoreFrameStyle? frameStyle,
    Component? child,
    List<Component>? children,
    String? tag,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Frame(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      direction: direction ?? this.direction,
      gap: gap ?? this.gap,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      alignment: alignment ?? this.alignment,
      width: width ?? this.width,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      flex: flex ?? this.flex,
      fit: fit ?? this.fit,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderStyle: borderStyle ?? this.borderStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      innerShadow: innerShadow ?? this.innerShadow,
      layerBlur: layerBlur ?? this.layerBlur,
      backdropBlur: backdropBlur ?? this.backdropBlur,
      elevation: elevation ?? this.elevation,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      opacity: opacity ?? this.opacity,
      transform: transform ?? this.transform,
      transformAlignment: transformAlignment ?? this.transformAlignment,
      visible: visible ?? this.visible,
      onHover: onHover ?? this.onHover,
      onFocus: onFocus ?? this.onFocus,
      cursor: cursor ?? this.cursor,
      a11y: a11y ?? this.a11y,
      duration: duration ?? this.duration,
      frameStyle: frameStyle ?? this.frameStyle,
      tag: tag ?? this.tag,
      id: id ?? this.id,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `Frame.withStyle` extension —
/// merges a [CoreFrameStyle] patch into [Frame.frameStyle] via the
/// existing [Frame.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFrameStyle.merge` right-side-wins semantics).
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
/// sets [CoreFrameStyle.borderRadius] and `.primary` sets
/// [CoreFrameStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Frame(child: text('Hi')).radius4.primary
/// ```
extension FrameStyleChain on Frame {
  /// Returns a copy of this [Frame] with [patch] merged into
  /// [frameStyle] (patch fields win on conflict).
  Frame withStyle(CoreFrameStyle patch) =>
      copyWith(frameStyle: (frameStyle ?? const CoreFrameStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Frame get radius0 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Frame get radius2 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Frame get radius4 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Frame get radius6 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Frame get radius8 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Frame get radius10 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Frame get radius12 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Frame get radius14 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Frame get radius16 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Frame get radius20 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Frame get radius24 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Frame get radius28 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Frame get radius32 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Frame get radius36 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Frame get radius40 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Frame get radius48 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Frame get radius56 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Frame get radius64 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Frame get radius9999 => withStyle(
    const CoreFrameStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Frame get primary => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Frame get secondary => withStyle(
    const CoreFrameStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Frame get tertiary => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Frame get surface => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Frame get surfaceContainer => withStyle(
    const CoreFrameStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Frame get error => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Frame get success => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Frame get warning => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Frame get info => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Frame get outline => withStyle(
    const CoreFrameStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Frame get transparent =>
      withStyle(const CoreFrameStyle(backgroundColor: .transparent));
}
