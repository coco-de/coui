import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform switch field with Toggle.
///
/// Combines a [Toggle] with a label and optional description.
/// Layout: label/description on the left, toggle on the right. All
/// chrome / dimensional overrides flow through the single
/// [switchFieldStyle] slot — there are no flat widget chrome props.
///
/// Example:
/// ```dart
/// SwitchField(
///   label: 'Enable notifications',
///   description: 'Receive push notifications.',
///   value: isEnabled,
///   onChanged: (v) => setState(() => isEnabled = v),
/// )
/// ```
class SwitchField extends StatelessWidget implements CoreSwitchFieldContract {
  /// Creates a [SwitchField].
  const SwitchField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.enabled,
    this.switchFieldStyle,
  });

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final bool value;

  @override
  final ValueChanged<bool>? onChanged;

  @override
  final String? description;

  @override
  final bool? enabled;

  /// Whether the field takes input: [enabled] when stated, otherwise whether
  /// [onChanged] is set — the rule [Toggle] applies to itself.
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  @override
  final CoreSwitchFieldStyle? switchFieldStyle;

  /// Returns a copy of this [SwitchField] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  SwitchField copyWith({
    Key? key,
    ValueChanged<bool>? onChanged,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    bool? value,
    String? description,
    bool? enabled,
    CoreSwitchFieldStyle? switchFieldStyle,
  }) {
    return SwitchField(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      value: value ?? this.value,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      switchFieldStyle: switchFieldStyle ?? this.switchFieldStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSwitchField(
      context,
      enabled: _effectiveEnabled,
      switchFieldStyle: switchFieldStyle,
    );

    return Clickable(
      onPressed: _effectiveEnabled ? () => onChanged?.call(!value) : null,
      enabled: _effectiveEnabled,
      // Generic disabled fade off — the field paints its own disabled
      // tokens (nested clickableStyle slot).
      clickableStyle: resolved.clickableStyle,
      // The whole row is the press area, so its floor is the touch
      // target a theme asks for; the content centres in it.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: resolved.minHeight),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    label,
                    style: resolved.labelTextStyle,
                    maxLines: labelMaxLines,
                    overflow: labelOverflow?.toValue(),
                  ),
                  if (description != null) ...[
                    Gap(gapStyle: resolved.labelDescriptionGapStyle),
                    Text(description!, style: resolved.descriptionTextStyle),
                  ],
                ],
              ),
            ),
            Gap(gapStyle: resolved.labelToggleGapStyle),
            IgnorePointer(
              child: Toggle(
                onChanged: _effectiveEnabled ? onChanged : null,
                value: value,
                enabled: _effectiveEnabled,
                size: resolved.size,
                toggleStyle: CoreToggleStyle(
                  trackActiveColor: resolved.activeColor,
                  trackInactiveColor: resolved.inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSwitchFieldStyle] patch into
/// [SwitchField.switchFieldStyle] without hand-reconstructing every
/// field. Mirrors the Web `SwitchField.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwitchFieldStyle.merge` right-side-wins semantics).
extension SwitchFieldStyleChain on SwitchField {
  /// Returns a copy of this [SwitchField] with [patch] merged into
  /// [switchFieldStyle] (patch fields win on conflict).
  SwitchField withStyle(CoreSwitchFieldStyle patch) => copyWith(
    switchFieldStyle: (switchFieldStyle ?? const CoreSwitchFieldStyle()).merge(
      patch,
    ),
  );
}
