import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/stat/stat_style.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Upward arrow icon character code (U+2191).
const _kUpArrowCode = 0x2191;

/// Downward arrow icon character code (U+2193).
const _kDownArrowCode = 0x2193;

/// Right arrow icon character code (U+2192).
const _kRightArrowCode = 0x2192;

const _kDivTag = 'div';

/// Unified cross-platform stat/metric display for CoUI Web.
///
/// Per Epic #1302 원칙 6/7 the semantic enum (`variant`) and behaviour
/// fields (`label` / `value` / `unit` / `change` / `changeType` /
/// `description` / `icon`) stay flat on the component — chrome /
/// dimensional / nested-slot overrides flow through the single
/// [statStyle] (a [CoreStatStyle]). All paint resolution is delegated to
/// [resolveStat] in `stat_style.dart`. A `null` value draws
/// [CoreStatContract.defaultEmptyValue] in the empty-value colour.
///
/// Example:
/// ```dart
/// Stat(
///   label: 'Total Revenue',
///   value: '45,231',
///   unit: '원',
///   change: '+20.1%',
///   changeType: CoreStatChangeType.positive,
///   description: '지난 30일',
/// )
/// ```
class Stat extends UiComponent implements CoreStatContract<Component?> {
  /// Creates a [Stat].
  const Stat({
    required this.label,
    super.key,
    this.value,
    this.unit,
    this.labelMaxLines,
    this.labelOverflow,
    this.variant = CoreStatVariant.defaultVariant,
    this.size = CoreComponentSize.md,
    this.change,
    this.changeType,
    this.description,
    this.icon,
    this.statStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _kDivTag,
  });

  @override
  final CoreStatVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? value;

  @override
  final String? unit;

  @override
  final String? change;

  @override
  final CoreStatChangeType? changeType;

  @override
  final String? description;

  @override
  final Component? icon;

  @override
  final CoreStatStyle? statStyle;

  static String get _upArrow => .fromCharCode(_kUpArrowCode);
  static String get _downArrow => .fromCharCode(_kDownArrowCode);
  static String get _rightArrow => .fromCharCode(_kRightArrowCode);

  @override
  Stat copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    CoreStatVariant? variant,
    CoreComponentSize? size,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? value,
    String? unit,
    String? change,
    CoreStatChangeType? changeType,
    String? description,
    Component? icon,
    CoreStatStyle? statStyle,
    Key? key,
  }) {
    return Stat(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      change: change ?? this.change,
      changeType: changeType ?? this.changeType,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      statStyle: statStyle ?? this.statStyle,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 — `WebResolvedChrome` contract). `co_stat` reads the
    // paint-ready strings directly without invoking the top-level
    // builder helpers.
    final resolved = resolveStat(
      context,
      variant: variant,
      size: size,
      statStyle: statStyle,
    );

    final currentValue = value;
    final currentUnit = unit;
    final children = <Component>[
      // Label row.
      div(
        [
          span(
            [
              Text(
                label,
                maxLines: labelMaxLines,
                overflow: labelOverflow,
              ),
            ],
            classes: resolved.labelText.className,
            styles: resolved.labelText.inlineStyles,
          ),
          ?icon,
        ],
        classes: resolved.labelRow.className,
        styles: resolved.labelRow.inlineStyles,
      ),
      // Value row — the figure and its unit share a baseline.
      div(
        [
          if (currentValue == null)
            div(
              const [Text(CoreStatContract.defaultEmptyValue)],
              classes: resolved.emptyValueText.className,
              styles: resolved.emptyValueText.inlineStyles,
            )
          else
            div(
              [Text(currentValue)],
              classes: resolved.valueText.className,
              styles: resolved.valueText.inlineStyles,
            ),
          // A unit qualifies a figure; the empty-value dash is not one.
          if (currentValue != null && currentUnit != null)
            span(
              [Text(currentUnit)],
              classes: resolved.unitText.className,
              styles: resolved.unitText.inlineStyles,
            ),
        ],
        classes: resolved.valueRow.className,
        styles: resolved.valueRow.inlineStyles,
      ),
    ];

    // Optional change row — widget picks the pre-composed per-state
    // chrome slot via switch on the semantic enum prop (no secondary
    // resolver call). The slot already bakes layout / typography /
    // colour together.
    final effectiveChangeType = changeType;
    final effectiveChange = change;
    if (effectiveChange != null && effectiveChangeType != null) {
      final changeRow = switch (effectiveChangeType) {
        .positive => resolved.changeRowPositive,
        .negative => resolved.changeRowNegative,
        .neutral => resolved.changeRowNeutral,
      };
      children.add(
        div(
          [
            span([Text(_changeIcon(effectiveChangeType))]),
            span([Text(effectiveChange)]),
          ],
          classes: changeRow.className,
          styles: changeRow.inlineStyles,
        ),
      );
    }

    final currentDescription = description;
    if (currentDescription != null) {
      children.add(
        div(
          [Text(currentDescription)],
          classes: resolved.descriptionText.className,
          styles: resolved.descriptionText.inlineStyles,
        ),
      );
    }

    // Composes the shared OutlinedContainer surface primitive instead of
    // hand-drawing the card's fill, border, radius, and padding, so the
    // active preset reaches this card the same way it reaches
    // DescriptionCard. The composed surface owns the caller chrome
    // passthrough. resolved.root carries only the structural w-full
    // class, layered onto that primitive's own resolved chrome classes.
    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      id: id,
      classes: [resolved.root.className, ?classes].join(' ').trim(),
      css: this.css,
      attributes: componentAttributes,
      child: div(
        children,
        classes: resolved.content.className,
        styles: resolved.content.inlineStyles,
      ),
    );
  }

  static String _changeIcon(CoreStatChangeType type) {
    return switch (type) {
      .positive => _upArrow,
      .negative => _downArrow,
      .neutral => _rightArrow,
    };
  }
}

/// Chain sugar mirroring the Flutter `Stat.withStyle` extension —
/// merges a [CoreStatStyle] patch into [Stat.statStyle] via the
/// existing [Stat.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStatStyle.merge` right-side-wins semantics).
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
/// sets [CoreStatStyle.borderRadius] and `.primary` sets
/// [CoreStatStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Stat(label: 'Total Revenue', value: r'$45,231').radius4.surface
/// ```
extension StatStyleChain on Stat {
  /// Returns a copy of this [Stat] with [patch] merged into [statStyle]
  /// (patch fields win on conflict).
  Stat withStyle(CoreStatStyle patch) =>
      copyWith(statStyle: (statStyle ?? const CoreStatStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Stat get radius0 => withStyle(
    const CoreStatStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius0)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Stat get radius2 => withStyle(
    const CoreStatStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Stat get radius4 => withStyle(
    const CoreStatStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Stat get radius6 => withStyle(
    const CoreStatStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Stat get radius8 => withStyle(
    const CoreStatStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Stat get radius10 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Stat get radius12 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Stat get radius14 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Stat get radius16 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Stat get radius20 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Stat get radius24 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Stat get radius28 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Stat get radius32 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Stat get radius36 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Stat get radius40 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Stat get radius48 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Stat get radius56 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Stat get radius64 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Stat get radius9999 => withStyle(
    const CoreStatStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Stat get primary => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Stat get secondary => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.secondary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Stat get tertiary => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Stat get surface => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Stat get surfaceContainer => withStyle(
    const CoreStatStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Stat get error => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Stat get success => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Stat get warning => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Stat get info => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Stat get outline => withStyle(
    const CoreStatStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Stat get transparent =>
      withStyle(const CoreStatStyle(backgroundColor: .transparent));
}
