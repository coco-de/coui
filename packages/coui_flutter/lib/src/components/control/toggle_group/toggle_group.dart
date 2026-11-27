import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform grouped toggle for CoUI Flutter with
/// token-based rendering.
///
/// `ToggleGroup` holds its [items] on one track as mutually exclusive
/// segments; the chosen one is a raised face. It is the shared shape
/// behind a filter's segments, a time picker's AM / PM and a colour
/// picker's mode tabs. It is a **controlled** component: the parent owns
/// the chosen value via [value] and reacts through [onChanged]. With no
/// [onChanged] (or `enabled: false`) the group is inert and paints its
/// flat disabled look.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [toggleGroupStyle] (a [CoreToggleGroupStyle]). Behaviour fields
/// (`items` / `value` / `onChanged` / `enabled`) stay flat on the widget.
///
/// ```text
/// design system default for toggleGroup
///   → CoreToggleGroupTheme.style                  // 프로젝트 공통
///   → widget.toggleGroupStyle                     // 인스턴스별
/// ```
///
/// surface:content — a track that sits in the page flow, not something
/// mounted over content. The track is the surface; the moving chosen face
/// is not (see `ResolvedToggleGroup.unselectedColor`).
///
/// Example:
/// ```dart
/// ToggleGroup<String>(
///   value: _selected,
///   onChanged: (value) => setState(() => _selected = value),
///   items: const [
///     CoreToggleGroupItem(value: 'am', label: 'AM'),
///     CoreToggleGroupItem(value: 'pm', label: 'PM'),
///   ],
/// )
/// ```
class ToggleGroup<T> extends StatelessWidget
    implements CoreToggleGroupContract<Widget, T> {
  /// Creates a [ToggleGroup].
  const ToggleGroup({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled,
    this.size = CoreToggleGroupContract.defaultSize,
    this.direction = CoreToggleGroupContract.defaultDirection,
    this.fillWidth = false,
    this.trailing,
    this.toggleGroupStyle,
  }) : assert(items.length > 0, 'ToggleGroup must have at least one item.');

  @override
  final List<CoreToggleGroupItem<T, Widget>> items;

  @override
  final T? value;

  @override
  final ValueChanged<T>? onChanged;

  @override
  final bool? enabled;

  @override
  final CoreComponentSize size;

  @override
  final CoreAxis direction;

  @override
  final bool fillWidth;

  @override
  final Widget? trailing;

  /// Per-instance composite style. See [CoreToggleGroupStyle] for the
  /// merge chain.
  @override
  final CoreToggleGroupStyle? toggleGroupStyle;

  /// Whether the group accepts input: `enabled`, else whether [onChanged]
  /// is set.
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  /// Returns a copy of this [ToggleGroup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ToggleGroup<T> copyWith({
    Key? key,
    List<CoreToggleGroupItem<T, Widget>>? items,
    T? value,
    ValueChanged<T>? onChanged,
    bool? enabled,
    CoreComponentSize? size,
    CoreAxis? direction,
    bool? fillWidth,
    Widget? trailing,
    CoreToggleGroupStyle? toggleGroupStyle,
  }) {
    return ToggleGroup(
      key: key ?? this.key,
      items: items ?? this.items,
      value: value ?? this.value,
      onChanged: onChanged ?? this.onChanged,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      direction: direction ?? this.direction,
      fillWidth: fillWidth ?? this.fillWidth,
      trailing: trailing ?? this.trailing,
      toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _effectiveEnabled;
    final resolved = resolveToggleGroup(
      context,
      enabled: isEnabled,
      size: size,
      toggleGroupStyle: toggleGroupStyle,
    );
    final handleChanged = onChanged;
    final trailingContent = trailing;

    // The track is a composed `OutlinedContainer` (the actual surface —
    // the per-item chosen face is not), so a material preset reaches it
    // the same way it reaches a `Card`.
    final vertical = direction == CoreAxis.vertical;
    final segments = [
      for (final item in items)
        // A horizontal `fillWidth` track splits its width (each segment
        // `Expanded`); a vertical track stacks segments that stretch to
        // the track's width instead.
        if (fillWidth && !vertical)
          Expanded(
            child: _ToggleGroupItem<T>(
              isSelected: item.value == value,
              item: item,
              onSelect: isEnabled ? handleChanged : null,
              resolved: resolved,
            ),
          )
        else
          _ToggleGroupItem<T>(
            isSelected: item.value == value,
            item: item,
            onSelect: isEnabled ? handleChanged : null,
            resolved: resolved,
          ),
      ?trailingContent,
    ];

    final Widget content;
    if (vertical) {
      // Segments stretch to the widest one (hug) or to the parent's width
      // (`fillWidth`) — the Web column's `align-items: stretch`.
      final column = Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: resolved.itemSpacing,
        children: segments,
      );
      content = fillWidth ? column : IntrinsicWidth(child: column);
    } else {
      content = Row(
        // `fillWidth`: the track takes the parent's width and the
        // segments split it (each `Expanded`), like the Web flex row.
        mainAxisSize: fillWidth ? .max : .min,
        spacing: resolved.itemSpacing,
        children: segments,
      );
    }

    return OutlinedContainer(
      containerStyle: resolved.trackContainerStyle,
      child: content,
    );
  }
}

/// Chain sugar for merging a [CoreToggleGroupStyle] patch into
/// [ToggleGroup.toggleGroupStyle] without hand-reconstructing every field.
/// Mirrors the Web `ToggleGroup.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToggleGroupStyle.merge` right-side-wins semantics). This is
/// the full-control path — every field of the style is reachable through it.
///
/// ```dart
/// ToggleGroup<String>(...).withStyle(
///   const CoreToggleGroupStyle(
///     borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
///   ),
/// )
/// ```
extension ToggleGroupStyleChain<T> on ToggleGroup<T> {
  /// Sets the content padding.
  ToggleGroup<T> contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreToggleGroupStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  ToggleGroup<T> backgroundColor(CoreColor value) =>
      withStyle(CoreToggleGroupStyle(backgroundColor: value));

  /// Returns a copy of this [ToggleGroup] with [patch] merged into
  /// [toggleGroupStyle] (patch fields win on conflict).
  ToggleGroup<T> withStyle(CoreToggleGroupStyle patch) => copyWith(
    toggleGroupStyle: (toggleGroupStyle ?? const CoreToggleGroupStyle()).merge(
      patch,
    ),
  );
}

/// A single selectable segment.
class _ToggleGroupItem<T> extends StatefulWidget {
  const _ToggleGroupItem({
    required this.isSelected,
    required this.item,
    required this.onSelect,
    required this.resolved,
  });

  final bool isSelected;
  final CoreToggleGroupItem<T, Widget> item;

  /// `null` when the group is disabled — the `Clickable` then ignores
  /// taps and drops out of the focus order.
  final ValueChanged<T>? onSelect;
  final ResolvedToggleGroup resolved;

  @override
  State<_ToggleGroupItem<T>> createState() => _ToggleGroupItemState<T>();
}

class _ToggleGroupItemState<T> extends State<_ToggleGroupItem<T>> {
  // State DETECTION lives here; the layer colour it selects is the
  // resolver's `hoverLayerColor`.
  bool _hovered = false;

  void handleTap() {
    widget.onSelect?.call(widget.item.value);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final item = widget.item;
    final resolved = widget.resolved;
    final labelStyle = isSelected
        ? resolved.selectedLabelTextStyle
        : resolved.unselectedLabelTextStyle;
    final iconTheme = isSelected
        ? resolved.selectedIconTheme
        : resolved.iconTheme;
    final icon = item.icon;
    final enabled = widget.onSelect != null;
    // The layer takes the segment's own shape and sits over its face; a
    // segment that cannot be pressed (disabled group) paints none.
    final layerColor = enabled && _hovered
        ? resolved.hoverLayerColor
        : resolved.restLayerColor;

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring. The segment paints its own chosen
    // fill and shadow, and announces itself as a radio of a mutually
    // exclusive group rather than a button.
    //
    // Segment shape: a fixed-height box, never narrower than it is tall,
    // content centred both ways, `[icon][label box]` in a row. The label
    // box carries its own horizontal inset; an icon-only item is a square
    // of `itemHeight` by the minimum width. `Semantics.label` keeps the
    // label as the accessible name even when it is not painted.
    return Clickable(
      onPressed: enabled ? handleTap : null,
      onHover: (hovered) {
        if (_hovered != hovered) setState(() => _hovered = hovered);
      },
      enabled: enabled,
      semanticsButton: false,
      clickableStyle: resolved.clickableStyle,
      child: AnimatedContainer(
        height: resolved.itemHeight,
        constraints: BoxConstraints(minWidth: resolved.itemMinWidth),
        padding: resolved.itemPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? resolved.selectedColor : resolved.unselectedColor,
          borderRadius: resolved.itemBorderRadius,
          boxShadow: isSelected ? resolved.selectedShadow : const <BoxShadow>[],
        ),
        foregroundDecoration: layerColor == null
            ? null
            : BoxDecoration(
                color: layerColor,
                borderRadius: resolved.itemBorderRadius,
              ),
        duration: resolved.transitionDuration,
        curve: resolved.curve,
        child: Semantics(
          checked: isSelected,
          inMutuallyExclusiveGroup: true,
          enabled: enabled,
          label: item.label,
          child: Row(
            mainAxisSize: .min,
            children: [
              // Caller-supplied icon — the per-state `CoreIconStyle`
              // reaches it through the ambient `IconTheme`.
              if (icon != null) IconTheme.merge(data: iconTheme, child: icon),
              if (item.showLabel)
                Padding(
                  padding: resolved.labelPadding,
                  // The label's line box may be taller than the inset
                  // content area of the fixed segment height; Web lets it
                  // overflow symmetrically (flex centring), so the
                  // `OverflowBox` gives the label the same unbounded
                  // cross axis instead of clipping its bottom.
                  child: OverflowBox(
                    fit: .deferToChild,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Stacks(
                      alignment: .center,
                      children: [
                        // Invisible chosen-typography twin — reserves the
                        // semibold advance width so the group keeps a
                        // constant width when the choice moves. Mirrors
                        // the Web label ghost.
                        Visibility(
                          visible: false,
                          maintainState: true,
                          maintainAnimation: true,
                          maintainSize: true,
                          child: Text(
                            item.label,
                            style: resolved.selectedLabelTextStyle,
                          ),
                        ),
                        Text(item.label, style: labelStyle),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
