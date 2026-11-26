import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/form/fieldset/fieldset_style.dart';
import 'package:coui_web/src/components/form/form_field/form_field_scope.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' show BuildContext, Component, Key;

/// A grouped form section container with an optional legend and description.
///
/// Renders a `<div>` container (not the native `<fieldset>`) whose box is
/// set by [variant] — a faint panel (`filled`, the default), the hairline
/// edge alone (`outlined`), or no box (`plain`) — with an optional
/// [legend] and [description] at the top and a vertical list of
/// [children]. Per Epic #1302, every chrome / dimensional / nested-slot
/// override flows through the single [fieldsetStyle] (a
/// [CoreFieldsetStyle]):
///
/// ```text
/// design system default (variant row, size row)
///   → CoreFieldsetTheme.style
///   → CoreFieldsetTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.fieldsetStyle
/// ```
///
/// Example:
/// ```dart
/// Fieldset(
///   legend: Text('Personal Information'),
///   description: Text('Used for billing and receipts.'),
///   children: [
///     TextField(placeholder: 'Name'),
///     TextField(placeholder: 'Email'),
///   ],
/// )
/// ```
///
/// surface:content — a grouped-field panel that sits in the flow, not
/// something mounted over content.
class Fieldset extends UiComponent implements CoreFieldsetContract<Component> {
  /// Creates a [Fieldset].
  const Fieldset({
    this.legend,
    this.description,
    this.variant = CoreFieldsetVariant.defaultVariant,
    this.children = const [],
    this.enabled = true,
    this.size = CoreFieldsetStyle.defaultSize,
    this.fieldsetStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    super.key,
  }) : super(tag: 'div');

  @override
  final Component? legend;

  @override
  final Component? description;

  @override
  final CoreFieldsetVariant variant;

  @override
  final List<Component> children;

  @override
  final bool enabled;

  @override
  final CoreComponentSize size;

  @override
  final CoreFieldsetStyle? fieldsetStyle;

  @override
  Fieldset copyWith({
    Component? legend,
    Component? description,
    CoreFieldsetVariant? variant,
    List<Component>? children,
    bool? enabled,
    CoreComponentSize? size,
    CoreFieldsetStyle? fieldsetStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Fieldset(
      key: key ?? this.key,
      legend: legend ?? this.legend,
      description: description ?? this.description,
      variant: variant ?? this.variant,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      fieldsetStyle: fieldsetStyle ?? this.fieldsetStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    if (!enabled) attributes.add('data-disabled', '');
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveFieldset(
      context,
      enabled: enabled,
      size: size,
      variant: variant,
      fieldsetStyle: fieldsetStyle,
    );

    final containerClasses = resolved.root.className;
    final containerInline = resolved.root.inlineStyles;
    final mergedStyles = containerInline == null
        ? css
        : Styles.combine([containerInline, ?css]);

    // ── Header (legend, then description) ──
    // The resolver composed the default-typography Tailwind className
    // plus (when the caller supplied a [CoreTextStyle]) the inline-CSS
    // override layered on top, and the legend horizontal padding as the
    // wrapper's inline CSS. The widget skips each element when its slot is
    // null, and the header itself when both are.
    final legendWidget = legend == null
        ? null
        : div(
            [
              Component.element(
                tag: 'span',
                classes: resolved.legend.className,
                styles: resolved.legend.inlineStyles,
                children: [legend!],
              ),
            ],
            classes: resolved.legendWrapper.className,
            styles: resolved.legendWrapper.inlineStyles,
          );
    final descriptionWidget = description == null
        ? null
        : div(
            [description!],
            classes: resolved.description.className,
            styles: resolved.description.inlineStyles,
          );
    final hasHeader = legend != null || description != null;
    final headerWidget = !hasHeader
        ? null
        : div(
            [
              ?legendWidget,
              if (legend != null && description != null)
                Gap(gapStyle: resolved.legendDescriptionGapStyle),
              ?descriptionWidget,
            ],
            classes: resolved.header.className,
            styles: resolved.header.inlineStyles,
          );

    // Publishes the group's disabled constraint to every descendant
    // `FormField` (and, through it, the input each one wraps) — HTML
    // `<fieldset disabled>` semantics: this ALWAYS wins over a nested
    // field's own `enabled: true`. `Fieldset` never states an error of
    // its own, so `hasError` stays `false` here.
    //
    // An enclosing scope folds in too: a `Fieldset` nested inside a
    // disabled one publishes disabled even when it states `enabled:
    // true` itself, the same way nested `<fieldset>`s inherit
    // `disabled`. Only the published constraint folds — this panel's
    // own chrome still reads its own [enabled], so a nested group is
    // not dimmed a second time on top of the outer one.
    //
    // Wrapping each child individually (rather than the whole `div`'s
    // children as one list) keeps `FormFieldScope` — a metadata-only
    // `InheritedComponent` — from adding any DOM node of its own.
    final scope = CoreFormFieldScope(
      disabled:
          !enabled || (FormFieldScope.maybeOf(context)?.disabled ?? false),
      hasError: false,
    );

    // The header sits apart from the fields by its own gap — tighter than
    // the spacing between fields. The fields keep the uniform `gap`.
    final fieldsWidget = children.isEmpty
        ? null
        : div(
            [
              for (final child in children)
                FormFieldScope(scope: scope, child: child),
            ],
            classes: resolved.fields.className,
            styles: resolved.fields.inlineStyles,
          );

    return div(
      [
        ?headerWidget,
        if (hasHeader && children.isNotEmpty)
          Gap(gapStyle: resolved.headerFieldsGapStyle),
        ?fieldsWidget,
      ],
      id: id,
      classes: [
        containerClasses,
        classes ?? '',
      ].where((c) => c.isNotEmpty).join(' '),
      styles: mergedStyles,
      attributes: componentAttributes,
    );
  }
}

/// Chain sugar mirroring the Flutter `Fieldset.withStyle` extension —
/// merges a [CoreFieldsetStyle] patch into [Fieldset.fieldsetStyle] via
/// the existing [Fieldset.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFieldsetStyle.merge` right-side-wins semantics).
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
/// sets [CoreFieldsetStyle.borderRadius] and `.primary` sets
/// [CoreFieldsetStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Fieldset(legend: Text('Info')).radius4.surface
/// ```
extension FieldsetStyleChain on Fieldset {
  /// Returns a copy of this [Fieldset] with [patch] merged into
  /// [fieldsetStyle] (patch fields win on conflict).
  Fieldset withStyle(CoreFieldsetStyle patch) => copyWith(
    fieldsetStyle: (fieldsetStyle ?? const CoreFieldsetStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Fieldset get radius0 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Fieldset get radius2 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Fieldset get radius4 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Fieldset get radius6 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Fieldset get radius8 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Fieldset get radius10 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Fieldset get radius12 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Fieldset get radius14 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Fieldset get radius16 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Fieldset get radius20 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Fieldset get radius24 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Fieldset get radius28 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Fieldset get radius32 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Fieldset get radius36 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Fieldset get radius40 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Fieldset get radius48 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Fieldset get radius56 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Fieldset get radius64 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Fieldset get radius9999 => withStyle(
    const CoreFieldsetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Fieldset get primary => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Fieldset get secondary => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Fieldset get tertiary => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Fieldset get surface => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Fieldset get surfaceContainer => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Fieldset get error => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Fieldset get success => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Fieldset get warning => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Fieldset get info => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Fieldset get outline => withStyle(
    const CoreFieldsetStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Fieldset get transparent => withStyle(
    const CoreFieldsetStyle(backgroundColor: .transparent),
  );
}
