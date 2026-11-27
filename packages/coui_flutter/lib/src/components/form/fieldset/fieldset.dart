import 'package:coui_flutter/coui_flutter.dart';

/// A grouped form section container with an optional legend and description.
///
/// Draws the group's boundary as set by [variant] — a faint panel
/// (`filled`, the default), the hairline edge alone (`outlined`), or no box
/// (`plain`) — with an optional [legend] and [description] at the top and a
/// vertical list of [children] with consistent spacing.
///
/// Per Epic #1302, every chrome / dimensional / nested-slot override
/// flows through the single [fieldsetStyle] (a [CoreFieldsetStyle]):
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
///     TextField(placeholder: Text('Name')),
///     TextField(placeholder: Text('Email')),
///   ],
/// )
/// ```
///
/// surface:content — a grouped-field panel that sits in the flow, not
/// something mounted over content.
class Fieldset extends StatelessWidget implements CoreFieldsetContract<Widget> {
  /// Creates a [Fieldset].
  const Fieldset({
    super.key,
    this.legend,
    this.description,
    this.variant = CoreFieldsetVariant.defaultVariant,
    this.children = const [],
    this.enabled = true,
    this.size = CoreFieldsetStyle.defaultSize,
    this.fieldsetStyle,
  });

  @override
  final Widget? legend;

  @override
  final Widget? description;

  @override
  final CoreFieldsetVariant variant;

  @override
  final List<Widget> children;

  @override
  final bool enabled;

  @override
  final CoreComponentSize size;

  @override
  final CoreFieldsetStyle? fieldsetStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFieldset(
      context,
      size: size,
      variant: variant,
      enabled: enabled,
      fieldsetStyle: fieldsetStyle,
    );

    // The header (legend, then description) sits apart from the fields by
    // its own gap — tighter than the spacing between fields, so it reads as
    // belonging to what it names. The fields keep the uniform
    // `Column.spacing`.
    final hasHeader = legend != null || description != null;
    final header = <Widget>[
      if (legend != null)
        Padding(
          padding: resolved.legendPadding,
          child: DefaultTextStyle(
            style: resolved.legendTextStyle,
            child: legend!,
          ),
        ),
      if (legend != null && description != null)
        Gap(gapStyle: resolved.legendDescriptionGapStyle),
      if (description != null)
        DefaultTextStyle(
          style: resolved.descriptionTextStyle,
          child: description!,
        ),
    ];
    final contentChildren = <Widget>[
      if (hasHeader)
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: header,
        ),
      if (hasHeader && children.isNotEmpty)
        Gap(gapStyle: resolved.headerFieldsGapStyle),
      if (children.isNotEmpty)
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: resolved.fieldSpacing,
          children: children,
        ),
    ];

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
    final scope = CoreFormFieldScope(
      disabled:
          !enabled || (FormFieldScope.maybeOf(context)?.disabled ?? false),
      hasError: false,
    );

    // `OutlinedContainer` owns the panel's fill / border / radius /
    // material — the widget only composes it (Epic #4349). The cast is
    // painted a layer above via `InjectedCast` rather than inside the
    // composed decoration: fieldset's own fill can be non-opaque (the
    // transparent-sentinel default), and `OutlinedContainer` paints its
    // cast fallback straight into `BoxDecoration.boxShadow` regardless
    // of fill opacity — see `resolved.boxShadow`'s doc.
    return Opacity(
      opacity: enabled ? 1.0 : CoreOpacity.opacity50,
      child: SizedBox(
        width: .infinity,
        child: InjectedCast(
          shadows: resolved.boxShadow,
          borderRadius: resolved.castBorderRadius,
          child: OutlinedContainer(
            containerStyle: resolved.containerStyle,
            // `role` left at its default (`.content`) — matches the
            // class doc's `surface:content`.
            // `crossAxisAlignment: .stretch` mirrors the Web
            // `flex flex-col items-stretch` parity — form inputs
            // (the typical fieldset children) expect to fill the
            // container's inline-axis. Legend stays naturally
            // left-aligned because its `Padding` wrapper sets a
            // limited width.
            child: FormFieldScope(
              scope: scope,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: contentChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a copy of this [Fieldset] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Fieldset copyWith({
    Key? key,
    Widget? legend,
    Widget? description,
    CoreFieldsetVariant? variant,
    bool? enabled,
    CoreComponentSize? size,
    CoreFieldsetStyle? fieldsetStyle,
    List<Widget>? children,
  }) {
    return Fieldset(
      key: key ?? this.key,
      legend: legend ?? this.legend,
      description: description ?? this.description,
      variant: variant ?? this.variant,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      fieldsetStyle: fieldsetStyle ?? this.fieldsetStyle,
      children: children ?? this.children,
    );
  }
}

/// Chain sugar for merging a [CoreFieldsetStyle] patch into
/// [Fieldset.fieldsetStyle] without hand-reconstructing every field.
/// Mirrors the Web `Fieldset.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFieldsetStyle.merge` right-side-wins semantics).
///
/// `.outline` selects component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension FieldsetStyleChain on Fieldset {
  /// Sets the background paint and preserves the other style fields.
  Fieldset backgroundColor(CoreColor value) =>
      withStyle(CoreFieldsetStyle(backgroundColor: value));

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

  /// Selects `variant: .outlined` using the component theme.
  Fieldset get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  Fieldset get transparent => withStyle(
    const CoreFieldsetStyle(backgroundColor: .transparent),
  );
}
