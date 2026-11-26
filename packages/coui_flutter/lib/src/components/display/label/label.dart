import 'package:coui_flutter/coui_flutter.dart';

/// Static text label suitable for form fields.
///
/// Renders the label text with an optional leading icon and
/// required indicator (`*`). Supports a disabled state with reduced
/// opacity and a muted text color.
///
/// Chrome / dimensional / text-style overrides flow through the
/// single [labelStyle] slot per Epic #1302.
///
/// ```dart
/// Label(
///   text: 'Email',
///   icon: Icon(LucideIcons.mail),
///   isRequired: true,
/// )
/// ```
class Label extends StatelessWidget implements CoreLabelContract<Widget> {
  /// Creates a [Label].
  const Label({
    required this.text,
    super.key,
    this.icon,
    this.isRequired = false,
    this.disabled = false,
    this.semanticLabel,
    @Deprecated(
      'Label does not wire htmlFor to a control on either platform — use '
      'FormField, which links label and control (since 0.148)',
    )
    this.htmlFor,
    this.labelStyle,
  });

  @override
  final String text;

  @override
  final Widget? icon;

  @override
  final bool isRequired;

  @override
  final bool disabled;

  @override
  final String? semanticLabel;

  @override
  @Deprecated(
    'Label does not wire htmlFor to a control on either platform — use '
    'FormField, which links label and control (since 0.148)',
  )
  final String? htmlFor;

  @override
  final CoreLabelStyle? labelStyle;

  /// Returns a copy of this [Label] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Label copyWith({
    Key? key,
    String? text,
    Widget? icon,
    bool? isRequired,
    bool? disabled,
    String? semanticLabel,
    @Deprecated(
      'Label does not wire htmlFor to a control on either platform — use '
      'FormField, which links label and control (since 0.148)',
    )
    String? htmlFor,
    CoreLabelStyle? labelStyle,
  }) {
    return Label(
      key: key ?? this.key,
      text: text ?? this.text,
      icon: icon ?? this.icon,
      isRequired: isRequired ?? this.isRequired,
      disabled: disabled ?? this.disabled,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      htmlFor: htmlFor ?? this.htmlFor,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveLabel(
      context,
      disabled: disabled,
      labelStyle: labelStyle,
    );

    final effectiveStyle = resolved.textStyle;

    final row = Row(
      mainAxisSize: .min,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(
              size: resolved.iconSize,
              color: effectiveStyle.color,
            ),
            child: icon!,
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
        ],
        Text(text, style: effectiveStyle),
        if (isRequired) ...[
          Gap(gapStyle: resolved.labelRequiredGapStyle),
          Text(
            '*',
            style: effectiveStyle.copyWith(color: resolved.requiredColor),
          ),
        ],
      ],
    );

    final wrapped = disabled
        ? MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: Opacity(opacity: resolved.disabledOpacity, child: row),
          )
        : row;
    final label = semanticLabel != null
        ? Semantics(label: semanticLabel, child: wrapped)
        : wrapped;

    // Deprecated — `identifier` is a test-automation id, not a label↔
    // control accessibility link. Kept only for source compatibility
    // until the two-minor removal window closes. Use `FormField` for
    // an actual label/control association.
    if (htmlFor == null) return label;
    return Semantics(identifier: htmlFor, child: label);
  }
}

/// Chain sugar for merging a [CoreLabelStyle] patch into
/// [Label.labelStyle] without hand-reconstructing every field. Mirrors
/// the Web `Label.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLabelStyle.merge` right-side-wins semantics).
extension LabelStyleChain on Label {
  /// Returns a copy of this [Label] with [patch] merged into
  /// [labelStyle] (patch fields win on conflict).
  Label withStyle(CoreLabelStyle patch) =>
      copyWith(labelStyle: (labelStyle ?? const CoreLabelStyle()).merge(patch));
}
