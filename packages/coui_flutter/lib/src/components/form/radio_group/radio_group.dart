import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

/// Unified cross-platform radio group with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, semantic enums (`variant`, `size`,
/// `orientation`) stay as widget parameters — they identify the radio
/// group instance — while all chrome / dimensional / nested-slot
/// overrides flow through the single [radioGroupStyle] (a
/// [CoreRadioGroupStyle]). The nested-merge chain:
///
/// ```text
/// design system default for variant
///   → CoreRadioGroupTheme.style
///   → CoreRadioGroupTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.radioGroupStyle
/// ```
///
/// Example:
/// ```dart
/// RadioGroup<String>(
///   value: 'option1',
///   onChanged: (v) => setState(() => _selected = v),
///   options: [
///     (value: 'option1', label: 'Option 1'),
///     (value: 'option2', label: 'Option 2'),
///   ],
/// )
/// ```
class RadioGroup<T> extends StatefulWidget
    implements
        CoreRadioGroupContract<
          T,
          Widget,
          FocusNode,
          WidgetStatesController,
          RadioGroupController<T?>
        > {
  /// Creates a [RadioGroup].
  const RadioGroup({
    this.value,
    this.initialValue,
    this.onChanged,
    super.key,
    this.enabled,
    this.options,
    this.child,
    this.variant = CoreRadioGroupVariant.defaultVariant,
    this.size = CoreComponentSize.md,
    this.orientation = CoreRadioGroupOrientation.vertical,
    this.radioGroupStyle,
    this.name,
    this.focusNode,
    this.statesController,
    this.controller,
  }) : assert(
         child != null || options != null,
         'Provide either child or options.',
       );

  // === State ===

  @override
  final T? value;

  /// Seed selection for the uncontrolled path — when non-null the group
  /// owns its own selection and [value] is not read. The Web twin reads
  /// the same parameter.
  @override
  final T? initialValue;

  @override
  final ValueChanged<T?>? onChanged;

  @override
  final bool? enabled;

  // === Content ===

  @override
  final List<({T value, String label})>? options;

  @override
  final Widget? child;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreRadioGroupVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final CoreRadioGroupOrientation orientation;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreRadioGroupStyle? radioGroupStyle;

  // === Form ===

  @override
  final String? name;

  // === Focus & State ===

  @override
  final FocusNode? focusNode;

  @override
  final WidgetStatesController? statesController;

  @override
  final RadioGroupController<T?>? controller;

  /// Returns a copy of this [RadioGroup] with the given fields replaced.
  RadioGroup<T> copyWith({
    Key? key,
    ValueChanged<T?>? onChanged,
    T? initialValue,
    T? value,
    bool? enabled,
    List<({T value, String label})>? options,
    CoreRadioGroupVariant? variant,
    CoreComponentSize? size,
    CoreRadioGroupOrientation? orientation,
    CoreRadioGroupStyle? radioGroupStyle,
    String? name,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    RadioGroupController<T?>? controller,
    Widget? child,
  }) {
    return RadioGroup(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      options: options ?? this.options,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      orientation: orientation ?? this.orientation,
      radioGroupStyle: radioGroupStyle ?? this.radioGroupStyle,
      name: name ?? this.name,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      controller: controller ?? this.controller,
      child: child ?? this.child,
    );
  }

  @override
  State<RadioGroup<T>> createState() => _RadioGroupState<T>();
}

class _RadioGroupState<T> extends State<RadioGroup<T>>
    with FormValueSupplier<T, RadioGroup<T>> {
  /// Focus nodes of the descendant radios in registration (visual)
  /// order — the roving model moves keyboard focus between them with
  /// the arrow keys. Rebuilt (never mutated in place) on every
  /// register / unregister.
  List<({T value, FocusNode node})> _radioFocusNodes = [];

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  void handleRegisterRadioFocus(T value, FocusNode node) {
    _radioFocusNodes = [
      ..._radioFocusNodes.where((e) => e.node != node),
      (value: value, node: node),
    ];
  }

  void handleUnregisterRadioFocus(FocusNode node) {
    _radioFocusNodes = _radioFocusNodes.where((e) => e.node != node).toList();
  }

  /// Moves keyboard focus to the next/previous registered radio,
  /// wrapping at the ends (native radio-group convention). Selection
  /// follows focus via the radios' keyboard-focus auto-select.
  void handleMoveRadioFocus(int delta) {
    if (_radioFocusNodes.isEmpty) return;
    final current = _radioFocusNodes.indexWhere((e) => e.node.hasFocus);
    final base = current == -1
        ? _radioFocusNodes.indexWhere((e) => e.value == widget.value)
        : current;
    final next =
        (base + delta + _radioFocusNodes.length) % _radioFocusNodes.length;
    _radioFocusNodes[next].node.requestFocus();
  }

  bool get _enabled => widget.enabled ?? (widget.onChanged != null);

  void _handleSelect(T value) {
    if (!_enabled) return;
    if (widget.value != value) {
      widget.onChanged?.call(value);
    }
  }

  @override
  void didUpdateWidget(covariant RadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(T value) {
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    final resolved = resolveRadioGroup(
      context,
      variant: widget.variant,
      size: widget.size,
      radioGroupStyle: widget.radioGroupStyle,
    );

    // If using controlled component pattern.
    if (widget.controller != null || widget.initialValue != null) {
      return ControlledComponentAdapter(
        onChanged: widget.onChanged,
        initialValue: widget.initialValue ?? widget.value,
        controller: widget.controller,
        enabled: _enabled,
        builder: (context, data) {
          return _RadioGroupContent<T>(
            value: data.value,
            enabled: _enabled,
            onSelect: (v) {
              data.onChanged(v);
            },
            orientation: widget.orientation,
            variant: widget.variant,
            resolved: resolved,
            scaling: scaling,
            theme: theme,
            registerFocus: handleRegisterRadioFocus,
            unregisterFocus: handleUnregisterRadioFocus,
            moveFocus: handleMoveRadioFocus,
            options: widget.options,
            child: widget.child,
          );
        },
      );
    }

    // Web twin: role="radiogroup" wrapping role="radio" children.
    return Semantics(
      container: true,
      child: _RadioGroupContent<T>(
        value: widget.value,
        enabled: _enabled,
        onSelect: _handleSelect,
        orientation: widget.orientation,
        variant: widget.variant,
        resolved: resolved,
        scaling: scaling,
        theme: theme,
        registerFocus: handleRegisterRadioFocus,
        unregisterFocus: handleUnregisterRadioFocus,
        moveFocus: handleMoveRadioFocus,
        options: widget.options,
        child: widget.child,
      ),
    );
  }
}

/// Internal group content widget that renders options or child.
class _RadioGroupContent<T> extends StatelessWidget {
  const _RadioGroupContent({
    required this.value,
    required this.enabled,
    required this.onSelect,
    required this.orientation,
    required this.variant,
    required this.resolved,
    required this.scaling,
    required this.theme,
    required this.registerFocus,
    required this.unregisterFocus,
    required this.moveFocus,
    this.options,
    this.child,
  });

  final T? value;
  final bool enabled;
  final ValueChanged<T> onSelect;
  final CoreRadioGroupOrientation orientation;
  final CoreRadioGroupVariant variant;
  final ResolvedRadioGroup resolved;
  final double scaling;
  final ThemeData theme;
  final List<({T value, String label})>? options;
  final void Function(T value, FocusNode node) registerFocus;
  final void Function(FocusNode node) unregisterFocus;
  final void Function(int delta) moveFocus;
  final Widget? child;

  Widget _buildOptionsLayout() {
    final items = [
      for (final option in options!)
        Radio<T>(value: option.value, label: option.label),
    ];

    if (orientation == .horizontal) {
      // `Wrap.spacing` / `runSpacing` consume raw doubles — the resolver
      // already applied scaling, so the widget reads `resolved.itemSpacing`
      // directly (no widget-side `* scaling` Anti-C).
      return Wrap(
        spacing: resolved.itemSpacing,
        runSpacing: resolved.itemSpacing,
        children: items,
      );
    }

    // Vertical orientation — `Column.spacing` (Flutter 3.41+) is a native
    // paint-API argument that consumes a raw double. No manual `Gap`
    // interleave between children. A plain row keeps its own width.
    if (variant != .card) {
      return Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: resolved.itemSpacing,
        children: items,
      );
    }

    // Card tiles stretch so a stack of choices reads as one column of equal
    // faces. `_FillBoundedWidth` gives the column a width to stretch to in
    // every parent — the width offered, or the widest tile when the width
    // is unbounded — the same two widths the Web column takes as a block
    // and as a shrink-to-fit flex item.
    return _FillBoundedWidth(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: resolved.itemSpacing,
        children: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = child ?? _buildOptionsLayout();

    return Data.inherit(
      data: _RadioGroupData(
        value: value,
        enabled: enabled,
        onSelect: onSelect,
        variant: variant,
        resolved: resolved,
        scaling: scaling,
        registerFocus: registerFocus,
        unregisterFocus: unregisterFocus,
        moveFocus: moveFocus,
      ),
      child: FocusTraversalGroup(child: content),
    );
  }
}

/// Lays its child out at the full width it is offered, or at the child's
/// widest intrinsic width when the width is unbounded.
///
/// A stretching `Column` asserts under an unbounded width (a `Row` without
/// `Expanded`, a horizontal scroll view), and a `LayoutBuilder` that picks
/// between two layouts throws on intrinsic queries (an `IntrinsicWidth`
/// around a popover panel). This box answers intrinsics from its child, so
/// it lays out in both.
class _FillBoundedWidth extends SingleChildRenderObjectWidget {
  const _FillBoundedWidth({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFillBoundedWidth();
}

class _RenderFillBoundedWidth extends RenderProxyBox {
  BoxConstraints _childConstraints(BoxConstraints constraints, RenderBox box) =>
      constraints.tighten(
        width: constraints.hasBoundedWidth
            ? constraints.maxWidth
            : box.getMaxIntrinsicWidth(constraints.maxHeight),
      );

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    box.layout(_childConstraints(constraints, box), parentUsesSize: true);
    size = box.size;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final box = child;
    if (box == null) return constraints.smallest;
    return box.getDryLayout(_childConstraints(constraints, box));
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final box = child;
    if (box == null) return null;
    return box.getDryBaseline(_childConstraints(constraints, box), baseline);
  }
}

/// Data passed down from RadioGroup to Radio items.
class _RadioGroupData<T> {
  const _RadioGroupData({
    required this.value,
    required this.enabled,
    required this.onSelect,
    required this.variant,
    required this.resolved,
    required this.scaling,
    required this.registerFocus,
    required this.unregisterFocus,
    required this.moveFocus,
  });

  final T? value;
  final bool enabled;
  final ValueChanged<T> onSelect;

  /// The group's variant — a semantic identifier the radios branch on to
  /// draw a tile (`card`) or a plain row.
  final CoreRadioGroupVariant variant;
  final ResolvedRadioGroup resolved;
  final double scaling;

  /// Roving-focus registry callbacks (owned by the group state).
  /// Excluded from `==`/`hashCode` like [onSelect] — identity-stable
  /// behaviour, not rebuild-relevant data.
  final void Function(T value, FocusNode node) registerFocus;
  final void Function(FocusNode node) unregisterFocus;
  final void Function(int delta) moveFocus;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _RadioGroupData<T> &&
        other.value == value &&
        other.enabled == enabled &&
        other.variant == variant &&
        other.resolved == resolved &&
        other.scaling == scaling;
  }

  @override
  int get hashCode => Object.hash(
    value,
    enabled,
    variant,
    resolved,
    scaling,
  );
}

/// A single radio item, inside a [RadioGroup] or on its own.
///
/// Renders a circular radio indicator with optional label, description,
/// prefix, and suffix. Inside a `card` group it draws as a tile.
///
/// Inside a [RadioGroup] the radio reads the group's selection, callback,
/// variant and size. On its own it carries them itself — [groupValue],
/// [onChanged], [groupVariant] and [groupSize] — the same parameters the Web
/// radio takes.
///
/// Example:
/// ```dart
/// RadioGroup<String>(
///   value: selected,
///   onChanged: (v) => setState(() => selected = v),
///   child: Column(
///     children: [
///       Radio(value: 'a', label: 'Option A'),
///       Radio(value: 'b', label: 'Option B'),
///     ],
///   ),
/// )
///
/// // On its own — e.g. one tile of a card-style choice.
/// Radio<String>(
///   value: 'pickup',
///   groupValue: selected,
///   groupVariant: .card,
///   label: 'Pick up',
///   onChanged: (v) => setState(() => selected = v),
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
class Radio<T> extends StatefulWidget
    implements CoreRadioItemContract<T, Widget> {
  /// Creates a [Radio].
  const Radio({
    required this.value,
    super.key,
    this.groupValue,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.groupVariant = CoreRadioGroupVariant.defaultVariant,
    this.groupSize = CoreComponentSize.md,
    this.onChanged,
    this.focusNode,
  });

  @override
  final T value;

  /// The selected value of the set this radio belongs to. Inside a
  /// [RadioGroup] it falls back to the group's selection when left null.
  @override
  final T? groupValue;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final Widget? prefix;

  @override
  final Widget? suffix;

  @override
  final bool enabled;

  /// Variant of a radio on its own. Inside a [RadioGroup] the group's
  /// variant decides and this is not read.
  @override
  final CoreRadioGroupVariant groupVariant;

  /// Size of a radio on its own. Inside a [RadioGroup] the group's size
  /// decides and this is not read, as with [groupVariant].
  @override
  final CoreComponentSize groupSize;

  /// Called with [value] when the user picks this radio. Inside a
  /// [RadioGroup] it falls back to the group's callback when left null.
  @override
  final ValueChanged<T?>? onChanged;

  /// Focus node for keyboard focus management.
  final FocusNode? focusNode;

  @override
  State<Radio<T>> createState() => _RadioState<T>();
}

/// Arrow-key intent moving keyboard focus to a sibling radio
/// (roving radio-group model — selection follows focus via the
/// keyboard-focus auto-select).
class _MoveRadioFocusIntent extends Intent {
  const _MoveRadioFocusIntent(this.delta);

  final int delta;
}

class _RadioState<T> extends State<Radio<T>> {
  late FocusNode _focusNode;
  bool _focusing = false;
  bool _hovered = false;
  bool _pressed = false;
  _RadioGroupData<T>? _groupData;

  void handleHover(bool hovered) {
    if (hovered == _hovered) return;
    setState(() => _hovered = hovered);
  }

  void handlePressedChange(bool pressed) {
    if (pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _groupData = Data.maybeOf<_RadioGroupData<T>>(context);
    _groupData?.registerFocus(widget.value, _focusNode);
  }

  @override
  void didUpdateWidget(covariant Radio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _groupData?.unregisterFocus(_focusNode);
      if (widget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _groupData?.registerFocus(widget.value, _focusNode);
    }
  }

  @override
  void dispose() {
    _groupData?.unregisterFocus(_focusNode);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Inside a [RadioGroup] the radio reads the group. A selection or a
    // callback the caller passes still wins, except the variant and size:
    // the group's decide them. On its own the radio resolves its own
    // bundle from [Radio.groupVariant] / [Radio.groupSize] — the Web
    // radio's standalone path.
    final group = Data.maybeOf<_RadioGroupData<T>>(context);
    final variant = group?.variant ?? widget.groupVariant;
    final resolved =
        group?.resolved ??
        resolveRadioGroup(context, variant: variant, size: widget.groupSize);
    final groupValue = widget.groupValue ?? group?.value;
    final pick = widget.onChanged ?? group?.onSelect;
    final isSelected = groupValue == widget.value;
    final isEnabled = widget.enabled && (group?.enabled ?? true);
    // A radio with no callback from either source draws as enabled but does
    // not respond — the Web radio attaches no handlers in that case.
    final select = isEnabled ? pick : null;
    // A semantic identifier, not a resolved value: the card draws the same
    // row inside a tile and moves the state layer and the focus ring onto it.
    final isCard = variant == .card;

    // Roving tab stop (native radio-group convention): only the
    // selected radio is reachable with Tab — with no selection yet,
    // every radio stays reachable. Arrow keys move focus between
    // siblings (selection follows focus via the keyboard-focus
    // auto-select), and `requestFocus` ignores `skipTraversal`. A radio
    // outside a group has no arrow keys to reach its siblings with, so
    // each one keeps its own tab stop — the Web radio's rule.
    _focusNode.skipTraversal =
        group != null && !(isSelected || groupValue == null);

    // Select the pre-resolved per-state `OutlinedContainer` chrome
    // bundle for the ring — the ring is composed, not hand-decorated
    // (Epic #4349), so the widget only SELECTS between the resolver's
    // selected / unselected bundles, and between their disabled twins.
    final CoreOutlinedContainerStyle ringContainerStyle;
    if (!isEnabled) {
      ringContainerStyle = isSelected
          ? resolved.disabledSelectedRingContainerStyle
          : resolved.disabledUnselectedRingContainerStyle;
    } else if (isSelected) {
      ringContainerStyle = resolved.selectedRingContainerStyle;
    } else {
      ringContainerStyle = resolved.unselectedRingContainerStyle;
    }

    // Resolve sizes. `resolved.innerDotSize` already folds the per-
    // instance `indicatorDotStyle.size` override on top of the size-
    // bucket default and applies scaling once; the widget reads it
    // directly.
    final innerDotSize = isSelected ? resolved.innerDotSize : 0.0;

    // Inner dot colour — resolver already applied slot override → active
    // fill; disabled overrides to the variant disabled-active colour.
    final Color innerDotColor = isEnabled
        ? resolved.dotColor
        : resolved.disabledActiveColor;

    // The halo — the row's hover / pressed state, drawn around the ring
    // rather than inside it. Selecting between three already-resolved
    // colours, strongest first, the same order Chip reads its ramp in; a
    // disabled row never engages. Positioned `-spread` on every side of the
    // ring so it stands `spread` px outside the box while the box keeps
    // its own layout size.
    final Color stateLayerColor;
    if (!isEnabled) {
      stateLayerColor = resolved.restStateLayerColor;
    } else if (_pressed) {
      stateLayerColor = resolved.pressedStateLayerColor;
    } else if (_hovered) {
      stateLayerColor = resolved.hoverStateLayerColor;
    } else {
      stateLayerColor = resolved.restStateLayerColor;
    }
    final stateLayer = Position(
      top: -resolved.stateLayerSpread,
      right: -resolved.stateLayerSpread,
      bottom: -resolved.stateLayerSpread,
      left: -resolved.stateLayerSpread,
      child: AnimatedContainer(
        decoration: BoxDecoration(color: stateLayerColor, shape: .circle),
        duration: resolved.colorTransitionDuration,
        curve: CoreEasing.move.toValue(),
      ),
    );

    // Build radio indicator circle. `OutlinedContainer` owns the ring's
    // fill / border / radius / cast / material — the widget only
    // composes it and centers the (uncomposed) inner dot glyph inside.
    final ring = OutlinedContainer(
      containerStyle: ringContainerStyle,
      // `role` left at its default (`.content`) — matches the class
      // doc's `surface:content`.
      child: Center(
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: innerDotColor,
            shape: .circle,
          ),
          width: innerDotSize,
          height: innerDotSize,
          duration: resolved.dotTransitionDuration,
          curve: CoreEasing.move.toValue(),
        ),
      ),
    );
    // A plain row rings and haloes the indicator. The `Stacks` sizes itself
    // to the ring (the one in-flow child) and does not clip, so the halo can
    // reach past it. A card puts both on the tile instead, so its indicator
    // is the bare ring.
    final Widget radioIndicator = isCard
        ? ring
        : FocusOutline(
            focused: _focusing && isSelected,
            shape: .circle,
            child: Stacks(
              alignment: .center,
              clipBehavior: .none,
              children: [stateLayer, ring],
            ),
          );

    // Build effective suffix (label or explicit suffix). The resolver
    // already materialised the role + size step + per-instance overlay
    // into two paint-ready text styles; the widget only selects by state.
    final labelTextStyle = isEnabled
        ? resolved.labelTextStyle
        : resolved.disabledLabelTextStyle;
    final effectiveSuffix =
        widget.suffix ??
        (widget.label != null
            ? Text(
                widget.label!,
                style: labelTextStyle,
                maxLines: widget.labelMaxLines,
                overflow: widget.labelOverflow?.toValue(),
              )
            : null);

    // The label slot and the description stack in one column, Checkbox's
    // shape. Built only when a description is present, so a labelled radio
    // without one has no Column and no Gap.
    final descriptionTextStyle = isEnabled
        ? resolved.descriptionTextStyle
        : resolved.disabledDescriptionTextStyle;
    final Widget? content;
    if (widget.description != null && effectiveSuffix != null) {
      content = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          effectiveSuffix,
          Gap(gapStyle: resolved.labelDescriptionGapStyle),
          Text(widget.description!, style: descriptionTextStyle),
        ],
      );
    } else if (widget.description != null) {
      // Description with no label — still its own line, still the quieter
      // foreground. Dropping it because the label is absent would make the
      // slot silently conditional on a sibling.
      content = Text(widget.description!, style: descriptionTextStyle);
    } else {
      content = effectiveSuffix;
    }

    final row = Row(
      mainAxisSize: .min,
      // Top-aligned once the column is two lines tall — centring the ring
      // against a label-plus-description block floats it against neither
      // line. A single line stays centred against the ring.
      crossAxisAlignment: widget.description != null ? .start : .center,
      children: [
        if (widget.prefix != null) ...[
          widget.prefix!,
          Gap(gapStyle: resolved.indicatorLabelGapStyle),
        ],
        radioIndicator,
        if (content != null) ...[
          Gap(gapStyle: resolved.indicatorLabelGapStyle),
          Flexible(child: content),
        ],
      ],
    );

    // The card's tile: the state layer covers the whole face, clipped to the
    // tile's corner by the container, and the focus ring goes around the
    // tile instead of the indicator. The layer sits under the padded row so
    // it washes the face, not the text.
    final Widget body;
    if (isCard) {
      final CoreOutlinedContainerStyle tileContainerStyle;
      if (!isEnabled) {
        tileContainerStyle = isSelected
            ? resolved.disabledSelectedTileContainerStyle
            : resolved.disabledUnselectedTileContainerStyle;
      } else if (isSelected) {
        tileContainerStyle = resolved.selectedTileContainerStyle;
      } else {
        tileContainerStyle = resolved.unselectedTileContainerStyle;
      }
      body = FocusOutline(
        focused: _focusing && isSelected,
        focusOutlineStyle: resolved.tileFocusOutlineStyle,
        child: OutlinedContainer(
          containerStyle: tileContainerStyle,
          child: Stacks(
            children: [
              Position.fill(
                child: AnimatedContainer(
                  decoration: BoxDecoration(color: stateLayerColor),
                  duration: resolved.colorTransitionDuration,
                  curve: CoreEasing.move.toValue(),
                ),
              ),
              // The selected stroke is heavier and takes part in layout; the
              // padding gives the difference back, in step with the border
              // the container lerps, so the content holds still.
              AnimatedPadding(
                padding: isSelected
                    ? resolved.selectedTilePadding
                    : resolved.tilePadding,
                duration: resolved.colorTransitionDuration,
                curve: CoreEasing.move.toValue(),
                child: row,
              ),
            ],
          ),
        ),
      );
    } else {
      body = row;
    }

    // The indicator is 12 or 14 at the smaller sizes, under the WCAG
    // minimum, and an unlabelled radio is exactly that wide. The
    // expansion is a floor, so a labelled one — already past it on the
    // main axis — only gains on the cross axis.
    //
    // `Clickable` owns tap / hover / press / keyboard-focus DETECTION for
    // the whole row — label included, which is what puts the halo on when
    // the pointer rests on the text (for a card, the whole tile). Its own
    // ring is off: the radio draws `FocusOutline` around the indicator (or
    // the tile), not around the Clickable's own box. The arrow
    // keys sit on a `Shortcuts` above it so they resolve after the
    // Clickable's own Space / Enter activation.
    return TouchTarget(
      child: SelectionContainer.disabled(
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(.arrowRight): _MoveRadioFocusIntent(1),
            SingleActivator(.arrowDown): _MoveRadioFocusIntent(1),
            SingleActivator(.arrowLeft): _MoveRadioFocusIntent(-1),
            SingleActivator(.arrowUp): _MoveRadioFocusIntent(-1),
          },
          child: Actions(
            actions: {
              _MoveRadioFocusIntent: CallbackAction<_MoveRadioFocusIntent>(
                onInvoke: (intent) {
                  if (isEnabled) group?.moveFocus(intent.delta);
                  return null;
                },
              ),
            },
            // The Web twin's `role="radio"` + `aria-checked`.
            child: Semantics(
              checked: isSelected,
              inMutuallyExclusiveGroup: true,
              child: Clickable(
                onPressed: select == null ? null : () => select(widget.value),
                onHover: handleHover,
                onPressedChange: handlePressedChange,
                onFocus: (value) {
                  if (value && select != null && !isSelected) {
                    select(widget.value);
                  }
                  if (value != _focusing) {
                    setState(() {
                      _focusing = value;
                    });
                  }
                },
                enabled: isEnabled,
                focusOutline: false,
                // A radio is a more specific control than a plain button —
                // the `Semantics` above carries its role and state.
                semanticsButton: false,
                focusNode: _focusNode,
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreRadioGroupStyle] patch into
/// [RadioGroup.radioGroupStyle] without hand-reconstructing every field.
/// Mirrors the Web `RadioGroup.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreRadioGroupStyle.merge` right-side-wins semantics).
///
/// ```dart
/// RadioGroup<String>(value: 'a', onChanged: (v) {}).withStyle(
///   CoreRadioGroupStyle(
///     indicatorActiveColor: CoreColor.token(CoreColors.primary),
///   ),
/// )
/// ```
extension RadioGroupStyleChain<T> on RadioGroup<T> {
  /// Returns a copy of this [RadioGroup] with [patch] merged into
  /// [radioGroupStyle] (patch fields win on conflict).
  RadioGroup<T> withStyle(CoreRadioGroupStyle patch) => copyWith(
    radioGroupStyle: (radioGroupStyle ?? const CoreRadioGroupStyle()).merge(
      patch,
    ),
  );
}
