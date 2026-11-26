import 'package:coui_flutter/coui_flutter.dart';

/// A unified label for form fields.
///
/// `FormLabel` renders descriptive text for a form input with an
/// optional required indicator (`*`) appended after the label. It is
/// the unified replacement for the legacy Flutter and Web `FormLabel`
/// — same parameter names, same semantics, full visual parity.
///
/// When [isRequired] is `true`, the [requiredIndicator] is shown after
/// the label; when no custom indicator is supplied an error-coloured
/// asterisk is rendered.
///
/// Every chrome / typography override flows through the single
/// [formLabelStyle] field — see [CoreFormLabelStyle] for the merge
/// chain.
///
/// Mirrors Web `FormLabel` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// FormLabel(label: Text('Email Address'))
/// FormLabel(label: Text('Password'), isRequired: true)
/// ```
class FormLabel extends StatelessWidget
    implements CoreFormLabelContract<Widget> {
  /// Creates a [FormLabel].
  const FormLabel({
    required this.label,
    this.isRequired = false,
    this.requiredIndicator,
    this.size = CoreFormLabelStyle.defaultSize,
    this.enabled = true,
    this.formLabelStyle,
    super.key,
  });

  @override
  final Widget? label;

  @override
  final bool isRequired;

  @override
  final Widget? requiredIndicator;

  @override
  final CoreComponentSize size;

  @override
  final bool enabled;

  @override
  final CoreFormLabelStyle? formLabelStyle;

  /// Returns a copy of this [FormLabel] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FormLabel copyWith({
    Key? key,
    Widget? label,
    bool? isRequired,
    Widget? requiredIndicator,
    CoreComponentSize? size,
    bool? enabled,
    CoreFormLabelStyle? formLabelStyle,
  }) {
    return FormLabel(
      key: key ?? this.key,
      label: label ?? this.label,
      isRequired: isRequired ?? this.isRequired,
      requiredIndicator: requiredIndicator ?? this.requiredIndicator,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      formLabelStyle: formLabelStyle ?? this.formLabelStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFormLabel(
      context,
      size: size,
      enabled: enabled,
      formLabelStyle: formLabelStyle,
    );

    // Matches the Web twin's `aria-hidden` on the required marker: the
    // glyph is a visual shorthand, and a reader announcing "asterisk"
    // after every required label is noise rather than information.
    final defaultRequiredIndicator = ExcludeSemantics(
      child: Text(
        '*',
        style: resolved.labelTextStyle.copyWith(
          color: resolved.requiredColor,
        ),
      ),
    );

    return DefaultTextStyle.merge(
      style: resolved.labelTextStyle,
      child: Row(
        mainAxisSize: .min,
        children: [
          // Bounded so a long label wraps instead of pushing the row
          // past its container. The Web twin is a flex row, where a
          // text child shrinks and wraps by default — Flutter's `Row`
          // gives an unbounded child its full intrinsic width, so
          // without this the two platforms disagree the moment a label
          // is translated into a longer language.
          if (label != null) Flexible(child: label!),
          if (isRequired) ...[
            Gap(gapStyle: resolved.requiredIndicatorGapStyle),
            requiredIndicator ?? defaultRequiredIndicator,
          ],
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreFormLabelStyle] patch into
/// [FormLabel.formLabelStyle] without hand-reconstructing every field.
/// Mirrors the Web `FormLabel.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFormLabelStyle.merge` right-side-wins semantics).
extension FormLabelStyleChain on FormLabel {
  /// Returns a copy of this [FormLabel] with [patch] merged into
  /// [formLabelStyle] (patch fields win on conflict).
  FormLabel withStyle(CoreFormLabelStyle patch) => copyWith(
    formLabelStyle: (formLabelStyle ?? const CoreFormLabelStyle()).merge(patch),
  );
}
