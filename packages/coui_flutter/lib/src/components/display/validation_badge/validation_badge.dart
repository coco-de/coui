import 'package:coui_flutter/coui_flutter.dart';

/// Cross-platform validation badge — communicates the result of a single
/// validation rule (pending / valid / invalid) with a colored chip-style
/// container, an icon, and a label.
///
/// ```dart
/// ValidationBadge(
///   label: '8 characters or more',
///   state: password.length >= 8
///       ? CoreValidationState.valid
///       : CoreValidationState.invalid,
/// );
///
/// ValidationBadge.fromBool(label: 'Has digit', isValid: hasDigit);
///
/// ValidationBadge.withPending(
///   label: 'Has digit',
///   hasInput: password.isNotEmpty,
///   isValid: hasDigit,
/// );
/// ```
///
/// surface:behind — whatever the badge is set inline against (a form
/// field's helper row, a card). It draws its own box rather than
/// composing `OutlinedContainer` — the Web twin's root is a fixed
/// `<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
/// the inline flow it is meant to sit in (#4358) — so the marker is
/// restated here directly.
///
/// surface:content — a state chip in the content layer, not a floating
/// affordance: no sticky, fixed, or overlay mount on either platform.
class ValidationBadge extends StatelessWidget
    implements CoreValidationBadgeContract {
  /// Creates a [ValidationBadge].
  const ValidationBadge({
    required this.label,
    required this.state,
    super.key,
    this.labelMaxLines,
    this.labelOverflow,
    this.pendingIcon,
    this.validIcon,
    this.invalidIcon,
    this.size,
    this.style,
  });

  /// Bool-based factory: `isValid` true → valid, false → invalid.
  factory ValidationBadge.fromBool({
    required String label,
    required bool isValid,
    Key? key,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) => ValidationBadge(
    key: key,
    label: label,
    labelMaxLines: labelMaxLines,
    labelOverflow: labelOverflow,
    state: isValid ? .valid : .invalid,
    validIcon: validIcon,
    invalidIcon: invalidIcon,
    size: size,
    style: style,
  );

  /// Three-state factory: untouched input shows pending; touched input
  /// shows valid/invalid based on [isValid].
  factory ValidationBadge.withPending({
    required String label,
    required bool hasInput,
    required bool isValid,
    Key? key,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    IconName? pendingIcon,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) {
    final state = !hasInput
        ? CoreValidationState.pending
        : isValid
        ? CoreValidationState.valid
        : CoreValidationState.invalid;
    return ValidationBadge(
      key: key,
      label: label,
      labelMaxLines: labelMaxLines,
      labelOverflow: labelOverflow,
      state: state,
      pendingIcon: pendingIcon,
      validIcon: validIcon,
      invalidIcon: invalidIcon,
      size: size,
      style: style,
    );
  }

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final CoreValidationState state;

  @override
  final IconName? pendingIcon;

  @override
  final IconName? validIcon;

  @override
  final IconName? invalidIcon;

  @override
  final CoreValidationBadgeSize? size;

  @override
  final CoreValidationBadgeStyle? style;

  /// Returns a copy of this [ValidationBadge] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ValidationBadge copyWith({
    Key? key,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreValidationState? state,
    IconName? pendingIcon,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) {
    return ValidationBadge(
      key: key ?? this.key,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      state: state ?? this.state,
      pendingIcon: pendingIcon ?? this.pendingIcon,
      validIcon: validIcon ?? this.validIcon,
      invalidIcon: invalidIcon ?? this.invalidIcon,
      size: size ?? this.size,
      style: style ?? this.style,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the effective size (widget → default) here so the resolver
    // receives a concrete non-null `size` — mirrors the Web widget + PoC
    // (Alert / Button) where semantic identifiers are resolved
    // widget-side. `size` is a semantic identifier, so the theme cannot
    // override it (style-contract.md — Theme carries no `size` slot).
    final effectiveSize = size ?? CoreValidationBadgeStyle.defaultSize;

    final resolved = resolveValidationBadge(
      context,
      state: state,
      size: effectiveSize,
      pendingIcon: pendingIcon,
      validIcon: validIcon,
      invalidIcon: invalidIcon,
      widgetStyle: style,
    );

    final chip = Container(
      height: resolved.height,
      padding: .symmetric(
        vertical: resolved.verticalPadding,
        horizontal: resolved.horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        // A width of 0 means no border; Flutter would draw it as a hairline.
        border: resolved.borderWidth > 0
            ? Border.all(
                color: resolved.borderColor,
                width: resolved.borderWidth,
              )
            : null,
        borderRadius: resolved.borderRadius,
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(
            resolved.icon,
            iconStyle: resolved.iconStyle,
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
          Flexible(
            child: Text(
              label,
              style: resolved.textStyle,
              overflow:
                  (labelOverflow ??
                          CoreValidationBadgeContract.defaultLabelOverflow)
                      .toValue(),
              maxLines:
                  labelMaxLines ??
                  CoreValidationBadgeContract.defaultLabelMaxLines,
            ),
          ),
        ],
      ),
    );

    // The rest of the surface material, around the chip. The fill share is
    // already folded into the resolved fill; this adds what a fill cannot
    // carry — the frost, the chroma, the dimming, the edge light and the
    // bend — the way the Web twin's surface marker gets them from the style
    // rule. Wrapped only when the style states something to draw, so every
    // other style keeps the tree it had.
    final surfaceBlur = resolved.surfaceBlur;
    final materialChip =
        (surfaceBlur != null && surfaceBlur > 0) ||
            resolved.surfaceSheen != null
        ? SurfaceBlur(
            borderRadius: resolved.borderRadius,
            surfaceBlur: surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: chip,
          )
        : chip;

    // Web twin: role="status" — validation results have to reach the reader
    // without the user going looking for them.
    return Semantics(liveRegion: true, child: materialChip);
  }
}

/// Chain sugar for merging a [CoreValidationBadgeStyle] patch into
/// [ValidationBadge.style] without hand-reconstructing every field.
/// Mirrors the Web `ValidationBadge.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreValidationBadgeStyle.merge` right-side-wins semantics).
///
/// ```dart
/// ValidationBadge(
///   label: 'Has digit',
///   state: CoreValidationState.valid,
/// ).withStyle(
///   CoreValidationBadgeStyle(iconLabelGapStyle: CoreGapStyle(size: 8)),
/// )
/// ```
extension ValidationBadgeStyleChain on ValidationBadge {
  /// Returns a copy of this [ValidationBadge] with [patch] merged into
  /// [style] (patch fields win on conflict).
  ValidationBadge withStyle(CoreValidationBadgeStyle patch) =>
      copyWith(style: (style ?? const CoreValidationBadgeStyle()).merge(patch));
}
