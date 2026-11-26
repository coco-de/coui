import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/form/switch_field/switch_field_style.dart';
import 'package:coui_web/src/components/form/toggle/toggle.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform switch field for CoUI Web.
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
///   value: true,
///   onChanged: (v) => print('Changed: $v'),
/// )
/// ```
class SwitchField extends UiComponent implements CoreSwitchFieldContract {
  /// Creates a [SwitchField].
  SwitchField({
    super.key,
    required this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.value = false,
    this.onChanged,
    this.description,
    this.enabled,
    this.switchFieldStyle,
    super.id,
  }) : super(tag: 'div');

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final bool value;

  @override
  final CoreValueChanged<bool>? onChanged;

  @override
  final String? description;

  @override
  final bool? enabled;

  /// Whether the field takes input: [enabled] when stated, otherwise whether
  /// [onChanged] is set — the rule [Toggle] applies to itself.
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  @override
  final CoreSwitchFieldStyle? switchFieldStyle;

  @override
  SwitchField copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    bool? value,
    CoreValueChanged<bool>? onChanged,
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
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSwitchField(
      context,
      enabled: _effectiveEnabled,
      switchFieldStyle: switchFieldStyle,
    );
    // Toggle's semantic size is a `Toggle(size:)` widget param
    // (behavioural identifier, not paint chrome), read off the merge
    // chain via the separate `resolve*` entry point so the resolved
    // struct stays pure chrome (number_ticker separate-resolver pattern).
    final toggleSize = resolveSwitchFieldSize(
      context,
      switchFieldStyle: switchFieldStyle,
    );

    final currentOnChanged = onChanged;

    // Flutter twin: `Clickable(child: Row(textColumn, gap,
    // IgnorePointer(Toggle)))` — the outer Clickable owns the whole-row
    // tap / keyboard / cursor / press-shrink / focus ring, and the
    // inner Toggle is pointer-inert (its own Clickable never sees the
    // click, so the row handler is the single toggle path).
    return Clickable(
      onPressed: _effectiveEnabled && currentOnChanged != null
          ? () => currentOnChanged(!value)
          : null,
      onClick: onClick,
      attributes: componentAttributes,
      classes: classes == null
          ? WebLayout.wFull
          : '${WebLayout.wFull} $classes',
      css: this.css,
      eventHandlers: eventHandlers,
      id: id,
      onChange: onChange,
      onInput: onInput,
      onKeyDown: onKeyDown,
      onKeyUp: onKeyUp,
      onMouseEnter: onMouseEnter,
      onMouseLeave: onMouseLeave,
      enabled: _effectiveEnabled,
      // Generic disabled fade off — the field paints its own disabled
      // tokens (nested clickableStyle slot).
      clickableStyle: resolved.clickableStyle,
      child: div(
        [
          div(
            [
              Component.element(
                tag: 'label',
                classes: resolved.label.className,
                styles: resolved.label.inlineStyles,
                children: [
                  Text(
                    label,
                    maxLines: labelMaxLines,
                    overflow: labelOverflow,
                  ),
                ],
              ),
              if (description != null) ...[
                Gap(gapStyle: resolved.labelDescriptionGapStyle),
                // Neutral <div>, not <p> — the user-agent's default
                // paragraph margin (~1.25em) stacked on top of the
                // 2px design gap and pushed the description ~20px
                // below the label on Web only (Flutter twin has no
                // such implicit margin).
                div(
                  [Text(description!)],
                  classes: resolved.description.className,
                  styles: resolved.description.inlineStyles,
                ),
              ],
            ],
            classes: resolved.textColumn.className,
            styles: resolved.textColumn.inlineStyles,
          ),
          Gap(gapStyle: resolved.labelToggleGapStyle),
          div(
            [
              Toggle(
                onChanged: onChanged,
                value: value,
                enabled: _effectiveEnabled,
                size: toggleSize,
                toggleStyle: resolved.toggleStyle,
              ),
            ],
            classes: WebLayout.pointerEventsNone,
          ),
        ],
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `SwitchField.withStyle` extension —
/// merges a [CoreSwitchFieldStyle] patch into
/// [SwitchField.switchFieldStyle] via the existing
/// [SwitchField.copyWith].
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
