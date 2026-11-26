import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/status/status_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform status dot indicator for CoUI Web.
///
/// Displays a small coloured dot to indicate current state
/// (online / offline / error / …). Uses [CoreStatusContract] from
/// `coui_core` for cross-platform API parity with `Status` on Flutter.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [statusStyle] slot. Behavioural / semantic fields (`color`,
/// `size`, `semanticLabel`) stay flat on the widget. Epic #1603 PoC v3
/// (옵션 B 최종): the single root chrome bundle is pre-composed inside
/// [ResolvedStatus] and read back as-is in [build].
///
/// Example:
/// ```dart
/// Status(
///   color: CoreStatusColor.success,
///   size: CoreStatusSize.lg,
///   semanticLabel: 'Online',
/// )
/// ```
class Status extends UiComponent implements CoreStatusContract<Component> {
  /// Creates a [Status].
  Status({
    super.key,
    this.color = CoreStatusColor.neutral,
    this.variant,
    this.size = CoreStatusSize.md,
    this.label,
    this.semanticLabel,
    this.animated = false,
    this.statusStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
  }) : super(tag: _kSpan);

  @override
  final CoreStatusColor color;

  @override
  final CoreStatusVariant? variant;

  @override
  final CoreStatusSize size;

  @override
  final Component? label;

  @override
  final String? semanticLabel;

  @override
  final bool animated;

  @override
  final CoreStatusStyle? statusStyle;

  // === Internal ===

  static const _kSpan = 'span';
  static const _kRoleStatus = 'status';
  static const _kAriaLabel = 'label';
  static const _kPulseClass = 'co-status-pulse';
  static const _kPulseCss =
      '''
@keyframes co-status-pulse{0%,100%{opacity:1}50%{opacity:.4}}
.co-status-pulse{animation:co-status-pulse ${CoreDuration.ms1000}ms ease-in-out infinite}
@media (prefers-reduced-motion:reduce){.co-status-pulse{animation:none}}
''';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // `role="status"` makes changes announce politely — but only when there
    // is a name to announce. The default used to be the literal `'status'`,
    // which said the word "status" and nothing about which state the dot is
    // in: the one thing a reader needed. It was also untranslated. Unnamed,
    // this is a coloured dot beside something that already says what it
    // means, so saying nothing is truthful. The Flutter twin does the same.
    attributes.addRole(_kRoleStatus);
    final label = semanticLabel;
    if (label != null) attributes.addAria(_kAriaLabel, label);
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolveStatus(
      context,
      color: color,
      size: size,
      variant: variant,
      statusStyle: statusStyle,
    );

    final userClasses = classes;
    var finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';
    if (animated) {
      finalClasses = '$finalClasses $_kPulseClass';
    }

    final visibleLabel = label;
    final dotChildren = [
      if (animated)
        Component.element(tag: 'style', children: [RawText(_kPulseCss)]),
      if (resolved.hasBar)
        span(
          [],
          classes: resolved.bar.className,
          styles: resolved.bar.inlineStyles,
        ),
    ];

    if (visibleLabel == null) {
      return span(
        dotChildren,
        id: id,
        classes: finalClasses,
        styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
        attributes: componentAttributes,
        events: this.events,
      );
    }

    // With a visible label the caller's id / classes / css / attributes sit on
    // the row, and the dot inside it keeps only its own chrome.
    return span(
      [
        span(
          dotChildren,
          classes: resolved.root.className,
          styles: resolved.root.inlineStyles,
        ),
        span(
          [visibleLabel],
          classes: resolved.label.className,
          styles: resolved.label.inlineStyles,
        ),
      ],
      id: id,
      classes: [
        resolved.wrapper.className,
        if (userClasses != null && userClasses.isNotEmpty) userClasses,
      ].join(' '),
      styles: Styles.combine([?resolved.wrapper.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }

  @override
  Status copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Key? key,
    CoreStatusColor? color,
    CoreStatusVariant? variant,
    CoreStatusSize? size,
    Component? label,
    String? semanticLabel,
    bool? animated,
    CoreStatusStyle? statusStyle,
  }) {
    return Status(
      key: key ?? this.key,
      color: color ?? this.color,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      label: label ?? this.label,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      animated: animated ?? this.animated,
      statusStyle: statusStyle ?? this.statusStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
    );
  }
}

/// Chain sugar mirroring the Flutter `Status.withStyle` extension —
/// merges a [CoreStatusStyle] patch into [Status.statusStyle] via the
/// existing [Status.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStatusStyle.merge` right-side-wins semantics).
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
/// sets [CoreStatusStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Status(color: CoreStatusColor.success).radius4
/// ```
extension StatusStyleChain on Status {
  /// Returns a copy of this [Status] with [patch] merged into
  /// [statusStyle] (patch fields win on conflict).
  Status withStyle(CoreStatusStyle patch) => copyWith(
    statusStyle: (statusStyle ?? const CoreStatusStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Status get radius0 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Status get radius2 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Status get radius4 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Status get radius6 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Status get radius8 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Status get radius10 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Status get radius12 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Status get radius14 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Status get radius16 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Status get radius20 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Status get radius24 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Status get radius28 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Status get radius32 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Status get radius36 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Status get radius40 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Status get radius48 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Status get radius56 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Status get radius64 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Status get radius9999 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
