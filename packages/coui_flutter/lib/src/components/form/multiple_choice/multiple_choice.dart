import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform single-select option group.
///
/// `MultipleChoice` renders a row of selectable options where exactly
/// one option may be active at a time. When [allowUnselect] is true the
/// active option may be cleared by tapping it again.
///
/// Each option is a composed [Chip] (unselected = neutral · outlined,
/// selected = primary), 32 tall, 8 apart. All chrome / dimensional
/// overrides flow through the single [multipleChoiceStyle] (a
/// [CoreMultipleChoiceStyle]); the chip's own chrome through its
/// `chipStyle` slot.
///
/// Example:
/// ```dart
/// MultipleChoice<String>(
///   options: const [
///     (value: 'sm', label: 'Small'),
///     (value: 'md', label: 'Medium'),
///     (value: 'lg', label: 'Large'),
///   ],
///   value: _size,
///   onChanged: (v) => setState(() => _size = v),
/// )
/// ```
class MultipleChoice<T> extends StatelessWidget
    implements CoreMultipleChoiceContract<T> {
  /// Creates a [MultipleChoice].
  const MultipleChoice({
    required this.options,
    super.key,
    this.value,
    this.enabled = true,
    this.allowUnselect = CoreMultipleChoiceContract.defaultAllowUnselect,
    this.onChanged,
    this.multipleChoiceStyle,
  });

  @override
  final List<CoreMultipleChoiceOption<T>> options;

  @override
  final T? value;

  @override
  final bool enabled;

  @override
  final bool allowUnselect;

  @override
  final ValueChanged<T?>? onChanged;

  @override
  final CoreMultipleChoiceStyle? multipleChoiceStyle;

  /// Returns a copy of this [MultipleChoice] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  MultipleChoice<T> copyWith({
    Key? key,
    ValueChanged<T?>? onChanged,
    List<CoreMultipleChoiceOption<T>>? options,
    T? value,
    bool? enabled,
    bool? allowUnselect,
    CoreMultipleChoiceStyle? multipleChoiceStyle,
  }) {
    return MultipleChoice(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      options: options ?? this.options,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      allowUnselect: allowUnselect ?? this.allowUnselect,
      multipleChoiceStyle: multipleChoiceStyle ?? this.multipleChoiceStyle,
    );
  }

  void _handleSelect(T optionValue) {
    if (!enabled) return;
    final currentOnChanged = onChanged;
    if (currentOnChanged == null) return;
    if (value == optionValue) {
      if (allowUnselect) currentOnChanged(null);
    } else {
      currentOnChanged(optionValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMultipleChoice(
      context,
      enabled: enabled,
      multipleChoiceStyle: multipleChoiceStyle,
    );

    final children = <Widget>[];
    for (var i = 0; i < options.length; i += 1) {
      final option = options[i];
      final selected = value == option.value;
      children.add(
        _MultipleChoiceOption(
          onSelected: () => _handleSelect(option.value),
          label: option.label,
          selected: selected,
          enabled: enabled,
          resolved: resolved,
        ),
      );
    }

    // 좁은 폭에서 옵션이 overflow 로 터지지 않게 줄바꿈한다 —
    // 웹 root 도 flex-wrap 으로 동일 동작.
    return Wrap(
      spacing: resolved.optionSpacing,
      runSpacing: resolved.optionSpacing,
      children: children,
    );
  }
}

/// Chain sugar for merging a [CoreMultipleChoiceStyle] patch into
/// [MultipleChoice.multipleChoiceStyle] without hand-reconstructing every
/// field. Mirrors the Web `MultipleChoice.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMultipleChoiceStyle.merge` right-side-wins semantics).
extension MultipleChoiceStyleChain<T> on MultipleChoice<T> {
  /// Returns a copy of this [MultipleChoice] with [patch] merged into
  /// [multipleChoiceStyle] (patch fields win on conflict).
  MultipleChoice<T> withStyle(CoreMultipleChoiceStyle patch) => copyWith(
    multipleChoiceStyle:
        (multipleChoiceStyle ?? const CoreMultipleChoiceStyle()).merge(patch),
  );
}

/// A single selectable option inside [MultipleChoice] — a composed
/// [Chip]: an unselected option is a neutral outlined chip, a selected
/// one the primary · low-emphasis chip. The `Chip` owns tap / keyboard
/// activation / cursor / press feedback / focus ring, the box and the
/// label, so the option draws nothing of its own.
class _MultipleChoiceOption extends StatelessWidget {
  const _MultipleChoiceOption({
    required this.onSelected,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.resolved,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final ResolvedMultipleChoice resolved;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Chip(
        label: label,
        chipColor: selected
            ? CoreMultipleChoiceContract.defaultSelectedChipColor
            : CoreMultipleChoiceContract.defaultUnselectedChipColor,
        emphasis: selected
            ? CoreMultipleChoiceContract.defaultSelectedChipEmphasis
            : CoreMultipleChoiceContract.defaultUnselectedChipEmphasis,
        selected: selected,
        enabled: enabled,
        onTap: enabled ? onSelected : null,
        chipStyle: selected
            ? resolved.selectedChipStyle
            : resolved.unselectedChipStyle,
      ),
    );
  }
}
