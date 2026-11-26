import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform stat/metric display with token-based rendering.
///
/// Displays a label, a value with an optional unit, an optional change
/// indicator and an optional description line in a card. A `null` value
/// draws [CoreStatContract.defaultEmptyValue] in the empty-value colour.
/// Uses [CoreStatContract] from `coui_core` for a consistent
/// cross-platform API.
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
class Stat extends StatelessWidget implements CoreStatContract<Widget?> {
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
  });

  static const String _upArrow = '\u{2191}';
  static const String _downArrow = '\u{2193}';
  static const String _rightArrow = '\u{2192}';

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

  /// Optional trailing icon widget.
  @override
  final Widget? icon;

  @override
  final CoreStatStyle? statStyle;

  /// Returns a copy of this [Stat] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Stat copyWith({
    Key? key,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? value,
    String? unit,
    CoreStatVariant? variant,
    CoreComponentSize? size,
    String? change,
    CoreStatChangeType? changeType,
    String? description,
    Widget? icon,
    CoreStatStyle? statStyle,
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
    );
  }

  TextStyle _resolveChangeTextStyle(
    ResolvedStat resolved,
    CoreStatChangeType type,
  ) {
    return switch (type) {
      .positive => resolved.changeTextStylePositive,
      .negative => resolved.changeTextStyleNegative,
      .neutral => resolved.changeTextStyleNeutral,
    };
  }

  String _resolveChangeIcon(CoreStatChangeType type) {
    return switch (type) {
      .positive => _upArrow,
      .negative => _downArrow,
      .neutral => _rightArrow,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStat(
      context,
      variant: variant,
      size: size,
      statStyle: statStyle,
    );

    final currentValue = value;
    final currentUnit = unit;
    final children = <Widget>[
      // Label and icon row.
      Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            label,
            style: resolved.labelTextStyle,
            maxLines: labelMaxLines,
            overflow: labelOverflow?.toValue(),
          ),
          ?icon,
        ],
      ),
      Gap(gapStyle: resolved.contentGapStyle),
      // Value row — the figure and its unit share a baseline. The figure is
      // `Flexible` so a long one still wraps inside the card instead of
      // overflowing; `min` keeps the row shrink-wrapped, which is also what
      // keeps it legal under an unbounded width.
      Row(
        mainAxisSize: .min,
        crossAxisAlignment: .baseline,
        textBaseline: .alphabetic,
        children: [
          Flexible(
            child: currentValue == null
                ? Text(
                    CoreStatContract.defaultEmptyValue,
                    style: resolved.emptyValueTextStyle,
                  )
                : Text(currentValue, style: resolved.valueTextStyle),
          ),
          // A unit qualifies a figure; the empty-value dash is not one.
          if (currentValue != null && currentUnit != null) ...[
            Gap(gapStyle: resolved.valueUnitGapStyle),
            Text(currentUnit, style: resolved.unitTextStyle),
          ],
        ],
      ),
    ];

    final effectiveChangeType = changeType;
    if (change != null && effectiveChangeType != null) {
      final changeTextStyle = _resolveChangeTextStyle(
        resolved,
        effectiveChangeType,
      );
      children
        ..add(Gap(gapStyle: resolved.contentGapStyle))
        ..add(
          Row(
            mainAxisSize: .min,
            children: [
              Text(
                _resolveChangeIcon(effectiveChangeType),
                style: changeTextStyle,
              ),
              Gap(gapStyle: resolved.changeIconGapStyle),
              Text(change!, style: changeTextStyle),
            ],
          ),
        );
    }

    final currentDescription = description;
    if (currentDescription != null) {
      children
        ..add(Gap(gapStyle: resolved.contentGapStyle))
        ..add(Text(currentDescription, style: resolved.descriptionTextStyle));
    }

    // The card box is composed, not drawn here — `OutlinedContainer` owns
    // it, the way `Card`'s does. This is what gets `Stat` the active
    // theme's injected material (glass blur / opacity) and
    // control-shadow fallback, which it drew nothing of while it owned
    // its own `BoxDecoration`.
    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: children,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreStatStyle] patch into [Stat.statStyle]
/// without hand-reconstructing every field. Mirrors the Web
/// `Stat.withStyle` extension so both platforms read identically.
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
