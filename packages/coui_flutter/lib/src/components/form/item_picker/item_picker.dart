import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show PointerEnterEvent, PointerExitEvent;

/// Unified cross-platform inline item picker.
///
/// `ItemPicker` renders a searchable, single-select list (or grid) of
/// string items. Typing in the search field filters the items
/// (case-insensitive `contains`); tapping an item selects it.
///
/// Per Epic #1302 원칙 6/7, behaviour / semantic fields (`items`,
/// `selectedValue`, `showSearch`, `enabled`, `layout`, `gridColumns`,
/// `title`, `searchPlaceholder`, `emptyText`, `onChanged`) stay flat on
/// the widget. All chrome / dimensional overrides flow through the
/// single [itemPickerStyle] (a [CoreItemPickerStyle]).
///
/// Example:
/// ```dart
/// ItemPicker(
///   items: ['Apple', 'Banana', 'Cherry'],
///   selectedValue: 'Apple',
///   onChanged: (v) => setState(() => _selected = v),
/// )
/// ```
///
/// surface:content — a picker laid out in the page flow, not mounted over
/// it. Composes `OutlinedContainer` for the panel box (Epic #4349).
class ItemPicker extends StatefulWidget
    implements CoreItemPickerContract<ValueChanged<String>?> {
  /// Creates a [ItemPicker].
  const ItemPicker({
    super.key,
    this.items = const [],
    this.selectedValue,
    this.searchPlaceholder,
    this.showSearch = true,
    this.enabled = true,
    this.layout = CoreItemPickerLayout.defaultLayout,
    this.gridColumns = CoreItemPickerLayout.defaultGridColumns,
    this.title,
    this.emptyText,
    this.onChanged,
    this.itemPickerStyle,
  });

  @override
  final List<String> items;

  @override
  final String? selectedValue;

  @override
  final String? searchPlaceholder;

  @override
  final bool showSearch;

  @override
  final bool enabled;

  @override
  final CoreItemPickerLayout layout;

  @override
  final int gridColumns;

  @override
  final String? title;

  @override
  final String? emptyText;

  @override
  final ValueChanged<String>? onChanged;

  // === Style (chrome / dimensional) ===

  @override
  final CoreItemPickerStyle? itemPickerStyle;

  /// Returns a copy of this [ItemPicker] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ItemPicker copyWith({
    Key? key,
    ValueChanged<String>? onChanged,
    List<String>? items,
    String? selectedValue,
    String? searchPlaceholder,
    bool? showSearch,
    bool? enabled,
    CoreItemPickerLayout? layout,
    int? gridColumns,
    String? title,
    String? emptyText,
    CoreItemPickerStyle? itemPickerStyle,
  }) {
    return ItemPicker(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      items: items ?? this.items,
      selectedValue: selectedValue ?? this.selectedValue,
      searchPlaceholder: searchPlaceholder ?? this.searchPlaceholder,
      showSearch: showSearch ?? this.showSearch,
      enabled: enabled ?? this.enabled,
      layout: layout ?? this.layout,
      gridColumns: gridColumns ?? this.gridColumns,
      title: title ?? this.title,
      emptyText: emptyText ?? this.emptyText,
      itemPickerStyle: itemPickerStyle ?? this.itemPickerStyle,
    );
  }

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

/// Chain sugar for merging a [CoreItemPickerStyle] patch into
/// [ItemPicker.itemPickerStyle] without hand-reconstructing every field.
/// Mirrors the Web `ItemPicker.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreItemPickerStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreItemPickerStyle.borderRadius] and `.primary` sets
/// [CoreItemPickerStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// ItemPicker(items: const ['Apple']).radius4.surface
/// ```
extension ItemPickerStyleChain on ItemPicker {
  /// Sets the border color.
  ItemPicker borderColor(CoreColor value) =>
      withStyle(CoreItemPickerStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  ItemPicker borderWidth(double value) =>
      withStyle(CoreItemPickerStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  ItemPicker backgroundColor(CoreColor value) =>
      withStyle(CoreItemPickerStyle(backgroundColor: value));

  /// Returns a copy of this [ItemPicker] with [patch] merged into
  /// [itemPickerStyle] (patch fields win on conflict).
  ItemPicker withStyle(CoreItemPickerStyle patch) => copyWith(
    itemPickerStyle: (itemPickerStyle ?? const CoreItemPickerStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  ItemPicker get radius0 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ItemPicker get radius2 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ItemPicker get radius4 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ItemPicker get radius6 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ItemPicker get radius8 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ItemPicker get radius10 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ItemPicker get radius12 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ItemPicker get radius14 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ItemPicker get radius16 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ItemPicker get radius20 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ItemPicker get radius24 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ItemPicker get radius28 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ItemPicker get radius32 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ItemPicker get radius36 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ItemPicker get radius40 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ItemPicker get radius48 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ItemPicker get radius56 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ItemPicker get radius64 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ItemPicker get radius9999 => withStyle(
    const CoreItemPickerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ItemPicker get primary => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ItemPicker get secondary => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ItemPicker get tertiary => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ItemPicker get surface => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ItemPicker get surfaceContainer => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ItemPicker get error => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ItemPicker get success => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ItemPicker get warning => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ItemPicker get info => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ItemPicker get outline => withStyle(
    const CoreItemPickerStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ItemPicker get transparent => withStyle(
    const CoreItemPickerStyle(backgroundColor: .transparent),
  );
}

class _ItemPickerState extends State<ItemPicker> {
  String _query = '';
  String? _hoveredItem;
  bool _hovered = false;

  List<String> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final lower = _query.toLowerCase();
    return widget.items
        .where((item) => item.toLowerCase().contains(lower))
        .toList();
  }

  void _handleHoverEnter(PointerEnterEvent _) {
    if (!_hovered) setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  void _handleSelect(String item) {
    if (!widget.enabled) return;
    widget.onChanged?.call(item);
  }

  Widget _buildList(
    ResolvedItemPicker resolved,
    List<String> items,
  ) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final item in items) _buildOption(resolved, item),
      ],
    );
  }

  Widget _buildGrid(
    ResolvedItemPicker resolved,
    List<String> items,
  ) {
    // `GridView.count` consumes raw doubles for `mainAxisSpacing` /
    // `crossAxisSpacing`. The resolver already applied scaling, so the
    // widget reads `resolved.optionSpacing` directly (no widget-side
    // `* scaling` Anti-C).
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: widget.gridColumns,
      mainAxisSpacing: resolved.optionSpacing,
      crossAxisSpacing: resolved.optionSpacing,
      children: [
        for (final item in items) _buildOption(resolved, item),
      ],
    );
  }

  Widget _buildOption(
    ResolvedItemPicker resolved,
    String item,
  ) {
    final isSelected = item == widget.selectedValue;
    final isHovered = _hoveredItem == item;

    final Color background;
    final TextStyle textStyle;
    if (isSelected) {
      background = resolved.selectedColor;
      textStyle = resolved.optionSelectedTextStyle;
    } else if (isHovered && widget.enabled) {
      background = resolved.optionHoverColor;
      textStyle = resolved.optionHoverTextStyle;
    } else {
      background = const Color(0x00000000);
      textStyle = resolved.optionTextStyle;
    }

    // The composed Clickable owns tap / keyboard activation / cursor /
    // focus ring / disabled opacity (Epic composition — no hand-rolled
    // GestureDetector + MouseRegion). Hover state flows back through
    // `onHover` so the widget only SELECTS between the pre-resolved
    // resting / hover / selected chrome bundles. Press-shrink is pinned
    // off via `CoreItemPickerStyle.defaultClickableStyle`
    // (`pressedScale: 1`) — a listbox row's selection feedback is a
    // background highlight, not a squash.
    return Clickable(
      onPressed: () => _handleSelect(item),
      onHover: (hovered) =>
          setState(() => _hoveredItem = hovered ? item : null),
      enabled: widget.enabled,
      // The choice was a background wash and a check mark — seen, never
      // heard. The Web twin states it as `aria-selected` on the option.
      semanticsSelected: isSelected,
      clickableStyle: resolved.clickableStyle,
      child: Container(
        padding: resolved.optionPadding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: resolved.optionBorderRadius,
        ),
        child: Row(
          mainAxisSize: .min,
          // `Row.spacing` (Flutter 3.41+) is a native paint-API argument
          // that consumes a raw double; the resolver already applied
          // scaling. When the check icon is omitted the row has a single
          // child so the spacing has no effect.
          spacing: resolved.optionSpacing,
          children: [
            if (isSelected)
              Icon(
                LucideIcons.check,
                iconStyle: resolved.checkIconStyle,
              ),
            Flexible(
              child: DefaultTextStyle.merge(
                style: textStyle,
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveItemPicker(
      context,
      enabled: widget.enabled,
      itemPickerStyle: widget.itemPickerStyle,
    );
    final filtered = _filteredItems;

    final children = <Widget>[];

    if (widget.showSearch) {
      children
        ..add(
          SizedBox(
            height: resolved.searchHeight,
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            child: Data<FormFieldHandle>.boundary(
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                placeholder: Text(
                  widget.searchPlaceholder ??
                      CoUILocalizations.of(context).itemPickerSearchPlaceholder,
                ),
                enabled: widget.enabled,
                // The panel is the only boundary: the field is the bare
                // variant, and the divider below closes the row.
                variant: .plain,
                prefix: Icon(
                  LucideIcons.search,
                  iconStyle: resolved.searchIconStyle,
                ),
                textFieldStyle: resolved.searchFieldStyle,
              ),
            ),
          ),
        )
        ..add(Divider(dividerStyle: resolved.searchDividerStyle));
    }

    if (filtered.isEmpty) {
      children.add(
        Padding(
          padding: resolved.emptyPadding,
          child: DefaultTextStyle.merge(
            style: resolved.emptyTextStyle,
            child: Text(
              widget.emptyText ?? CoUILocalizations.of(context).itemPickerEmpty,
            ),
          ),
        ),
      );
    } else {
      // The title is a label inside the list, ahead of the options, not a
      // header of the panel.
      final title = widget.title;
      children.add(
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: resolved.maxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: resolved.itemsPadding,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  if (title != null)
                    Padding(
                      padding: resolved.titlePadding,
                      child: DefaultTextStyle.merge(
                        style: resolved.titleTextStyle,
                        child: Text(title),
                      ),
                    ),
                  if (widget.layout == .grid)
                    _buildGrid(resolved, filtered)
                  else
                    _buildList(resolved, filtered),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // `OutlinedContainer` owns the panel's fill / border / radius /
    // cast / material — the widget only composes it (Epic #4349),
    // replacing the hand-rolled `Container` + independently-derived
    // `SurfaceBlur` that used to duplicate the primitive's own
    // material/cast resolution.
    //
    // The pointer steps the panel border (`disabled > hover > rest`):
    // the hovered bundle goes to the same `OutlinedContainer`, so the
    // border change is its own colour transition rather than a second box.
    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: OutlinedContainer(
        containerStyle: widget.enabled && _hovered
            ? resolved.hoveredContainerStyle
            : resolved.containerStyle,
        // `role` left at its default (`.content`) — matches the class
        // doc's `surface:content`.
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: children,
        ),
      ),
    );
  }
}
