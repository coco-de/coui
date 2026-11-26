import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/chip/chip.dart';
import 'package:coui_web/src/components/form/multiple_choice/multiple_choice_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform single-select option group for CoUI Web.
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
///   ],
///   value: size,
///   onChanged: (v) => setState(() => size = v),
/// )
/// ```
class MultipleChoice<T> extends UiComponent
    implements CoreMultipleChoiceContract<T> {
  /// Creates a [MultipleChoice].
  const MultipleChoice({
    required this.options,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    this.value,
    this.enabled = true,
    this.allowUnselect = CoreMultipleChoiceContract.defaultAllowUnselect,
    this.onChanged,
    this.multipleChoiceStyle,
  }) : super(tag: 'div');

  @override
  final List<CoreMultipleChoiceOption<T>> options;

  @override
  final T? value;

  @override
  final bool enabled;

  @override
  final bool allowUnselect;

  @override
  final void Function(T?)? onChanged;

  @override
  final CoreMultipleChoiceStyle? multipleChoiceStyle;
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', 'radiogroup');
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveMultipleChoice(
      context,
      enabled: enabled,
      multipleChoiceStyle: multipleChoiceStyle,
    );

    final children = <Component>[
      for (final option in options) _buildOption(option, resolved),
    ];

    return Component.element(
      tag: tag,
      id: id,
      classes: [resolved.root.className, ?classes].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
      children: children,
    );
  }

  @override
  MultipleChoice<T> copyWith({
    List<CoreMultipleChoiceOption<T>>? options,
    T? value,
    bool? enabled,
    bool? allowUnselect,
    void Function(T?)? onChanged,
    CoreMultipleChoiceStyle? multipleChoiceStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return MultipleChoice(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      options: options ?? this.options,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      allowUnselect: allowUnselect ?? this.allowUnselect,
      multipleChoiceStyle: multipleChoiceStyle ?? this.multipleChoiceStyle,
    );
  }

  /// One option — a composed [Chip]: neutral · outlined when resting,
  /// primary · outlined · low emphasis when selected. The Chip's Clickable owns tap / keyboard
  /// activation / cursor / press feedback / focus ring; `role` /
  /// `aria-checked` ride its attributes passthrough, and the disabled
  /// state surfaces as the Clickable's own `aria-disabled`.
  Component _buildOption(
    CoreMultipleChoiceOption<T> option,
    ResolvedMultipleChoice resolved,
  ) {
    final selected = value == option.value;
    return Chip(
      label: option.label,
      chipColor: selected
          ? CoreMultipleChoiceContract.defaultSelectedChipColor
          : CoreMultipleChoiceContract.defaultUnselectedChipColor,
      emphasis: selected
          ? CoreMultipleChoiceContract.defaultSelectedChipEmphasis
          : CoreMultipleChoiceContract.defaultUnselectedChipEmphasis,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? () => _handleSelect(option.value) : null,
      attributes: {
        'role': 'radio',
        'aria-checked': '$selected',
      },
      chipStyle: selected
          ? resolved.selectedChipStyle
          : resolved.unselectedChipStyle,
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
}

/// Chain sugar mirroring the Flutter `MultipleChoice.withStyle` extension —
/// merges a [CoreMultipleChoiceStyle] patch into
/// [MultipleChoice.multipleChoiceStyle] via the existing
/// [MultipleChoice.copyWith].
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
