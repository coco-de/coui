import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform option row — one choosable line of a list of
/// options (a sheet's "sort by", a filter's "colour").
///
/// Uses [CoreOptionItemContract] from `coui_core`, so the Web `OptionItem`
/// takes the same named properties. Anatomy, start to end:
/// `[ leading ] [ label / description ] [ mark ]`. The mark is the chosen
/// state: a check at the end of the chosen row when [selection] is
/// [CoreOptionItemSelection.single], a [Checkbox] on every row when it is
/// [CoreOptionItemSelection.multiple].
///
/// The row is a bordered card. It owns no state of what is chosen —
/// [selected] says it (a filled card with an accent border), and
/// [onPressed] reports the tap. While pressed it paints a rounded face
/// inside its border, under its content.
///
/// ```dart
/// OptionItem(
///   label: Text('Newest first'),
///   selected: true,
///   onPressed: () {},
/// )
/// ```
///
/// The Web `OptionItem` shares the same parameter names and order.
class OptionItem extends StatefulWidget
    implements CoreOptionItemContract<Widget> {
  /// Creates an [OptionItem].
  const OptionItem({
    required this.label,
    super.key,
    this.description,
    this.leading,
    this.selection = CoreOptionItemSelection.defaultSelection,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.optionItemStyle,
  });

  @override
  final Widget label;

  @override
  final Widget? description;

  @override
  final Widget? leading;

  @override
  final CoreOptionItemSelection selection;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreOptionItemStyle? optionItemStyle;

  /// Returns a copy of this [OptionItem] with the given fields replaced.
  OptionItem copyWith({
    Key? key,
    Widget? label,
    Widget? description,
    Widget? leading,
    CoreOptionItemSelection? selection,
    bool? selected,
    bool? enabled,
    void Function()? onPressed,
    CoreOptionItemStyle? optionItemStyle,
  }) {
    return OptionItem(
      key: key ?? this.key,
      label: label ?? this.label,
      description: description ?? this.description,
      leading: leading ?? this.leading,
      selection: selection ?? this.selection,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      optionItemStyle: optionItemStyle ?? this.optionItemStyle,
    );
  }

  @override
  State<OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<OptionItem> {
  bool _pressed = false;

  /// An explicit `enabled` wins, otherwise the presence of a handler decides.
  bool get _enabled => widget.enabled ?? (widget.onPressed != null);

  void _handlePressedChange(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final resolved = resolveOptionItem(
      context,
      selection: widget.selection,
      optionItemStyle: widget.optionItemStyle,
    );
    final selected = widget.selected;

    final labelStyle = !enabled
        ? selected
              ? resolved.disabledSelectedLabelTextStyle
              : resolved.disabledLabelTextStyle
        : selected
        ? resolved.selectedLabelTextStyle
        : resolved.labelTextStyle;
    final descriptionStyle = enabled
        ? resolved.descriptionTextStyle
        : resolved.disabledDescriptionTextStyle;

    final leading = widget.leading;
    final description = widget.description;

    // The chosen mark. A single selection draws a check on the chosen row
    // only; a multiple selection draws a checkbox on every row. The checkbox
    // is a picture of the row's state — the row takes the tap — so it is
    // out of the focus order, the hit test and the semantics tree.
    final mark = switch (widget.selection) {
      .single =>
        selected
            ? Icon(
                LucideIcons.check,
                iconStyle: enabled
                    ? resolved.checkIconStyle
                    : resolved.disabledCheckIconStyle,
              )
            : null,
      .multiple => ExcludeSemantics(
        child: ExcludeFocus(
          child: IgnorePointer(
            child: Checkbox(
              checked: selected,
              onChanged: null,
              enabled: enabled,
              size: .lg,
            ),
          ),
        ),
      ),
    };

    final row = Row(
      spacing: resolved.spacing,
      // Two lines top-align; a single line sits on the row's centre.
      crossAxisAlignment: description == null ? .center : .start,
      children: [
        if (leading != null)
          IconTheme.merge(
            data: enabled
                ? resolved.leadingIconTheme
                : resolved.disabledLeadingIconTheme,
            child: leading,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              DefaultTextStyle.merge(style: labelStyle, child: widget.label),
              if (description != null) ...[
                Gap(gapStyle: resolved.descriptionGapStyle),
                DefaultTextStyle.merge(
                  style: descriptionStyle,
                  child: description,
                ),
              ],
            ],
          ),
        ),
        ?mark,
      ],
    );

    // A chosen row fills and draws the accent border; a chosen row that is
    // disabled keeps its fill but returns to the resting border.
    final fill = !selected
        ? null
        : enabled
        ? resolved.selectedBackgroundColor
        : resolved.disabledSelectedBackgroundColor;
    final accentBorder = selected && enabled;
    final borderColor = accentBorder
        ? resolved.selectedBorderColor
        : resolved.borderColor;
    final borderWidth = accentBorder
        ? resolved.selectedBorderWidth
        : resolved.borderWidth;
    final faceInsets = accentBorder
        ? resolved.selectedPressedBackgroundInsets
        : resolved.pressedBackgroundInsets;
    final faceRadius = accentBorder
        ? resolved.selectedPressedBackgroundBorderRadius
        : resolved.pressedBackgroundBorderRadius;

    final box = ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      // The border paints over the box and takes no layout: the padding is
      // measured from the card's outer edge, so a thicker chosen border
      // never moves the content.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: resolved.borderRadius,
        ),
        child: Stacks(
          clipBehavior: .none,
          alignment: .centerStart,
          children: [
            if (_pressed && enabled)
              // The face is measured from the inside of the border, over the
              // fill and under the content.
              Position(
                left: faceInsets.left,
                right: faceInsets.right,
                top: faceInsets.top,
                bottom: faceInsets.bottom,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.pressedBackgroundColor,
                    borderRadius: faceRadius,
                  ),
                ),
              ),
            Padding(padding: resolved.padding, child: row),
          ],
        ),
      ),
    );

    return Clickable(
      onPressed: enabled ? widget.onPressed : null,
      onPressedChange: _handlePressedChange,
      semanticsSelected: selected,
      semanticsEnabled: enabled,
      enableFeedback: enabled,
      mouseCursor: enabled ? null : SystemMouseCursors.forbidden,
      clickableStyle: resolved.clickableStyle,
      child: box,
    );
  }
}

/// Chain sugar for merging a [CoreOptionItemStyle] patch into
/// [OptionItem.optionItemStyle] without hand-reconstructing every field.
/// Mirrors the Web `OptionItem.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOptionItemStyle.merge` right-side-wins semantics).
extension OptionItemStyleChain on OptionItem {
  /// Sets the content padding.
  OptionItem contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreOptionItemStyle(padding: value));

  /// Sets the border color.
  OptionItem borderColor(CoreColor value) =>
      withStyle(CoreOptionItemStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  OptionItem borderWidth(double value) =>
      withStyle(CoreOptionItemStyle(borderWidth: value));

  /// Returns a copy of this [OptionItem] with [patch] merged into
  /// [optionItemStyle] (patch fields win on conflict).
  OptionItem withStyle(CoreOptionItemStyle patch) => copyWith(
    optionItemStyle: (optionItemStyle ?? const CoreOptionItemStyle()).merge(
      patch,
    ),
  );
}
