import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform checkbox with token-based rendering.
///
/// The value is Flutter's tristate `bool?` — [checked] is `true` / `false`
/// / `null` for indeterminate — and [onChanged] receives the next value.
/// The semantic `size` stays a widget parameter (it identifies the checkbox
/// instance) while all chrome / dimensional / nested-slot overrides flow
/// through the single [checkboxStyle] (a [CoreCheckboxStyle]):
///
/// ```text
/// design system default
///   → CoreCheckboxTheme.style
///   → parent component slot override
///   → widget.checkboxStyle
/// ```
///
/// Hover / pressed / focus are DETECTION, reported by the composed
/// `Clickable`; the chrome for each comes from the resolver (the halo's
/// two weights, the ring around the box).
///
/// Example:
/// ```dart
/// Checkbox(
///   checked: true,
///   onChanged: (value) => setState(() => _checked = value),
///   label: 'Accept terms',
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
class Checkbox extends StatefulWidget
    implements
        CoreCheckboxContract<
          Widget,
          FocusNode,
          WidgetStatesController,
          CheckboxController
        > {
  /// Creates a [Checkbox].
  const Checkbox({
    required this.checked,
    required this.onChanged,
    super.key,
    this.enabled,
    this.tristate = false,
    this.prefix,
    this.suffix,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.trailing,
    this.size = CoreComponentSize.md,
    this.checkboxStyle,
    this.name,
    this.focusNode,
    this.statesController,
    this.controller,
  });

  // === Value ===

  @override
  final bool? checked;

  @override
  final ValueChanged<bool?>? onChanged;

  @override
  final bool? enabled;

  @override
  final bool tristate;

  // === Content ===

  @override
  final Widget? prefix;

  @override
  final Widget? suffix;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final Widget? trailing;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreComponentSize size;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreCheckboxStyle? checkboxStyle;

  // === Form ===

  @override
  final String? name;

  // === Focus & State ===

  @override
  final FocusNode? focusNode;

  @override
  final WidgetStatesController? statesController;

  @override
  final CheckboxController? controller;

  /// Returns a copy of this [Checkbox] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ///
  /// [checked] is tristate, so `null` cannot mean "keep mine" — pass
  /// [checkedProvided] `true` to set it (to any of the three values).
  Checkbox copyWith({
    Key? key,
    ValueChanged<bool?>? onChanged,
    bool? checked,
    bool checkedProvided = false,
    bool? enabled,
    bool? tristate,
    Widget? prefix,
    Widget? suffix,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    Widget? trailing,
    CoreComponentSize? size,
    CoreCheckboxStyle? checkboxStyle,
    String? name,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    CheckboxController? controller,
  }) {
    return Checkbox(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      checked: checkedProvided ? checked : this.checked,
      enabled: enabled ?? this.enabled,
      tristate: tristate ?? this.tristate,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      trailing: trailing ?? this.trailing,
      size: size ?? this.size,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      name: name ?? this.name,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      controller: controller ?? this.controller,
    );
  }

  @override
  State<Checkbox> createState() => _CheckboxState();
}

/// Chain sugar for merging a [CoreCheckboxStyle] patch into
/// [Checkbox.checkboxStyle] without hand-reconstructing every field.
/// Mirrors the Web `Checkbox.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCheckboxStyle.merge` right-side-wins semantics).
extension CheckboxStyleChain on Checkbox {
  /// Returns a copy of this [Checkbox] with [patch] merged into
  /// [checkboxStyle] (patch fields win on conflict).
  Checkbox withStyle(CoreCheckboxStyle patch) => copyWith(
    checkboxStyle: (checkboxStyle ?? const CoreCheckboxStyle()).merge(patch),
  );
}

class _CheckboxState extends State<Checkbox>
    with FormValueSupplier<bool?, Checkbox> {
  // DETECTION only — the `Clickable` reports these and the chrome for
  // each is already resolved; this state just picks among the bundles.
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    formValue = widget.checked;
  }

  void _notify(bool? next) {
    widget.onChanged?.call(next);
  }

  bool get _enabled => widget.enabled ?? (widget.onChanged != null);

  @override
  void didUpdateWidget(covariant Checkbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked) {
      formValue = widget.checked;
    }
  }

  @override
  void didReplaceFormValue(bool? value) {
    widget.onChanged?.call(value);
  }

  void handleTap() {
    if (widget.tristate) {
      // true → false → null (indeterminate) → true.
      _notify(switch (widget.checked) {
        true => false,
        false => null,
        null => true,
      });
    } else {
      _notify(!(widget.checked ?? false));
    }
  }

  void handleHover(bool hovered) {
    if (hovered == _hovered) return;
    setState(() => _hovered = hovered);
  }

  void handlePressedChange(bool pressed) {
    if (pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  void handleFocus(bool focused) {
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    // Resolver owns every merge, token fallback, colour, and scaling
    // step; this widget is render-only. It only selects among the
    // resolved per-state values using its `checked` / `enabled` props and
    // the `Clickable`'s hover / pressed / focus reports.
    final resolved = resolveCheckbox(
      context,
      size: widget.size,
      checkboxStyle: widget.checkboxStyle,
    );

    final indicatorLabelGapStyle = resolved.indicatorLabelGapStyle;

    final isChecked = widget.checked ?? false;
    final isIndeterminate = widget.checked == null;

    // Select the pre-resolved per-value `OutlinedContainer` chrome bundle
    // — the box is composed, not hand-decorated, so the widget only
    // SELECTS between the resolver's active / unchecked / disabled bundles.
    final CoreOutlinedContainerStyle containerStyle;
    if (!_enabled) {
      containerStyle = resolved.disabledContainerStyle;
    } else if (isChecked || isIndeterminate) {
      containerStyle = resolved.activeContainerStyle;
    } else {
      containerStyle = resolved.uncheckedContainerStyle;
    }

    // The mark takes the disabled ramp's ink when disabled — the resting
    // `onPrimary` over the disabled container is white on grey, which is
    // the invisible-mark defect this selection exists for. The check is an
    // ordinary `Icon`, so it is handed the resolver's icon style for the
    // state; the dash is a plain `Container` and takes the same ink as a
    // `Color`.
    final checkmarkIconStyle = _enabled
        ? resolved.checkmarkIconStyle
        : resolved.disabledCheckmarkIconStyle;
    final checkmarkColor = _enabled
        ? resolved.checkmarkColor
        : resolved.disabledCheckmarkColor;

    // Build the checkbox square. `OutlinedContainer` owns the box's
    // fill / border / radius / cast / material — the widget only
    // composes it and stacks the two glyphs on top.
    final transitionDuration = resolved.transitionDuration;
    final checkboxSquare = OutlinedContainer(
      containerStyle: containerStyle,
      // `role` left at its default (`.content`) — a control box that
      // sits in the flow, matching the class doc's `surface:content`.
      // Stack both check + dash glyphs and scale them in/out by value.
      // Mirrors Web's `scale-0 ↔ scale-100` transition so the animation
      // is identical on both platforms.
      //
      // Neither glyph is a surface — the dash stays a plain `Container`,
      // not composed — material never reaches it.
      child: Center(
        child: Stacks(
          alignment: .center,
          children: [
            AnimatedScale(
              scale: isChecked ? 1.0 : 0.0,
              curve: CoreEasing.move.toValue(),
              duration: transitionDuration,
              child: AnimatedOpacity(
                opacity: isChecked ? 1.0 : 0.0,
                curve: CoreEasing.move.toValue(),
                duration: transitionDuration,
                child: Icon(
                  LucideIcons.check,
                  iconStyle: checkmarkIconStyle,
                ),
              ),
            ),
            AnimatedScale(
              scale: isIndeterminate ? 1.0 : 0.0,
              curve: CoreEasing.move.toValue(),
              duration: transitionDuration,
              child: AnimatedOpacity(
                opacity: isIndeterminate ? 1.0 : 0.0,
                curve: CoreEasing.move.toValue(),
                duration: transitionDuration,
                // A horizontal dash — `indeterminateLength` long, the mark
                // stroke tall, pill-capped. Not a square: the glyph says
                // "some of these", and a square read as a second checked
                // look.
                child: Container(
                  decoration: BoxDecoration(
                    color: checkmarkColor,
                    borderRadius: resolved.indeterminateBorderRadius,
                  ),
                  width: resolved.indeterminateLength,
                  height: resolved.markThickness,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // The halo — the ink washed around the box while hovered or pressed,
    // reaching `stateLayerSpread` beyond it on every side. Strongest wins
    // (pressed over hover), and rest is the same ink at zero alpha so the
    // fade tweens in place rather than from black. Disabled never engages:
    // the `Clickable` reports no hover / press for it, and the guard here
    // is what keeps a force-disabled checkbox that kept its callback from
    // washing.
    final Color stateLayerColor;
    if (!_enabled) {
      stateLayerColor = resolved.stateLayerRestColor;
    } else if (_pressed) {
      stateLayerColor = resolved.stateLayerPressedColor;
    } else if (_hovered) {
      stateLayerColor = resolved.stateLayerHoverColor;
    } else {
      stateLayerColor = resolved.stateLayerRestColor;
    }
    final spread = resolved.stateLayerSpread;
    final haloedSquare = Stacks(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Position(
          left: -spread,
          top: -spread,
          right: -spread,
          bottom: -spread,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: transitionDuration,
              curve: CoreEasing.move.toValue(),
              decoration: BoxDecoration(
                color: stateLayerColor,
                borderRadius: resolved.stateLayerBorderRadius,
              ),
            ),
          ),
        ),
        checkboxSquare,
      ],
    );

    // The ring hugs the BOX, not the row — a focused checkbox is the box
    // lit, with the label untouched. The `Clickable` below therefore draws
    // no ring of its own (`focusOutline: false`) and reports focus up
    // instead.
    final focusedSquare = FocusOutline(
      focused: _enabled && _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: haloedSquare,
    );

    // Label text style is paint-ready from the resolver (typography role
    // + per-instance override + enabled / disabled foreground colour
    // already bound). The widget only picks the right state.
    final mergedLabelStyle = _enabled
        ? resolved.enabledLabelTextStyle
        : resolved.disabledLabelTextStyle;
    final effectiveSuffix =
        widget.suffix ??
        (widget.label != null
            ? Text(
                widget.label!,
                style: mergedLabelStyle,
                maxLines: widget.labelMaxLines,
                overflow: widget.labelOverflow?.toValue(),
              )
            : null);

    // The label and the description stack in one column — the canvas's
    // `content` frame, vertical with its own gap. Built only when a
    // description is actually present so a plain labelled checkbox keeps
    // the exact widget tree it had before (no Column, no Gap).
    final mergedDescriptionStyle = _enabled
        ? resolved.enabledDescriptionTextStyle
        : resolved.disabledDescriptionTextStyle;
    final Widget? content;
    if (widget.description != null && effectiveSuffix != null) {
      content = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          effectiveSuffix,
          Gap(gapStyle: resolved.labelDescriptionGapStyle),
          Text(widget.description!, style: mergedDescriptionStyle),
        ],
      );
    } else if (widget.description != null) {
      // Description with no label — still its own line, still the
      // quieter foreground. Dropping it because the label is absent
      // would make the slot silently conditional on a sibling.
      content = Text(widget.description!, style: mergedDescriptionStyle);
    } else {
      content = effectiveSuffix;
    }

    // The Web twin carries this state as `role="checkbox"` + `aria-checked`
    // on its interactive root (its hidden native input is `aria-hidden`
    // and only carries the form value), and Flutter announces it here. The
    // mixed flag is what makes a reader say partially checked rather than
    // silently rounding down to unchecked.
    //
    // The touch target sits *under* the semantics annotation, not over
    // it. Above it, the widget's outermost render object is a plain
    // proxy carrying no semantics, and the node a reader (or a test
    // looking one up by widget type) finds is whatever encloses the
    // checkbox instead of the checkbox itself — measured, after wrapping
    // it the other way turned two state assertions red.
    //
    // It wraps everything below because the smaller sizes draw a box
    // under the WCAG minimum — 12, 14 and 16 before scaling — and a
    // labelled checkbox is still short of it on the cross axis. Where
    // the row is already large enough the expansion is zero.
    return TouchTarget(
      child: Semantics(
        checked: isChecked,
        mixed: isIndeterminate ? true : null,
        child: Clickable(
          onPressed: _enabled ? handleTap : null,
          onHover: handleHover,
          onPressedChange: handlePressedChange,
          onFocus: handleFocus,
          // Effective enabled drives the whole interaction surface —
          // forbidden cursor, no focus, no activation. The generic
          // disabled fade stays off via the nested clickableStyle slot
          // (the checkbox paints its own disabled tokens).
          enabled: _enabled,
          // A checkbox is a more specific control than a plain button, so the
          // generic role is suppressed and the state above is what the reader
          // announces.
          semanticsButton: false,
          enableFeedback: _enabled,
          // The ring is the box's, drawn above — not the row's.
          focusOutline: false,
          focusNode: widget.focusNode,
          statesController: widget.statesController,
          clickableStyle: resolved.clickableStyle,
          // The whole row is the press area, so its floor is the touch
          // target a theme asks for.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: resolved.minHeight),
            child: Row(
              mainAxisSize: .min,
              // Top-aligned once the column is two lines tall — the canvas
              // states `counterAxisAlignItems: MIN`, and centring a box
              // against a label-plus-description block floats it against
              // neither line. Single-line rows keep centre, which is the
              // alignment every checkbox already rendered with.
              crossAxisAlignment: widget.description != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                // The ambient default for caller-supplied slots — a raw widget
                // handed to `prefix` / `suffix` reads the label's typography
                // instead of whatever the surrounding screen happened to set.
                // The label and description `Text`s above already carry their
                // own resolved style and are unaffected by an ambient one.
                if (widget.prefix != null) ...[
                  DefaultTextStyle.merge(
                    style: mergedLabelStyle,
                    child: widget.prefix!,
                  ),
                  Gap(gapStyle: indicatorLabelGapStyle),
                ],
                focusedSquare,
                if (content != null) ...[
                  Gap(gapStyle: indicatorLabelGapStyle),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: mergedLabelStyle,
                      child: content,
                    ),
                  ),
                ],
                if (widget.trailing != null) ...[
                  Gap(gapStyle: indicatorLabelGapStyle),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
