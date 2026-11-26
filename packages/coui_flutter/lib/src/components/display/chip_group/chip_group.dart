import 'package:coui_flutter/coui_flutter.dart';

/// Flutter alias for [CoreChipGroupItemBuilder].
typedef ChipGroupItemBuilder<T> = CoreChipGroupItemBuilder<T, Widget>;

/// 선택 가능한 칩 그룹 컴포넌트.
///
/// Web `ChipGroup` 와 동일한 API/렌더링.
///
/// ```dart
/// ChipGroup<String>(
///   items: const ['Flutter', 'React', 'Swift'],
///   chipBuilder:
///       (item, {required selected, required enabled, required onTap}) =>
///           Chip(
///             label: item,
///             selected: selected,
///             enabled: enabled,
///             onTap: onTap,
///           ),
///   selectionMode: CoreChipGroupSelectionMode.multi,
/// )
/// ```
class ChipGroup<T> extends StatefulWidget
    implements CoreChipGroupContract<T, Widget> {
  /// Creates a [ChipGroup].
  const ChipGroup({
    required this.items,
    required this.chipBuilder,
    super.key,
    this.selectionMode,
    this.layout,
    this.initialValue,
    this.onChanged,
    this.allowDeselect = true,
    this.maxSelection,
    this.maxSelectionBehavior,
    this.minSelection,
    this.title,
    this.selectionHint,
    this.showFade = true,
    this.chipGroupStyle,
  });

  @override
  final List<T> items;

  @override
  final ChipGroupItemBuilder<T> chipBuilder;

  @override
  final CoreChipGroupSelectionMode? selectionMode;

  @override
  final CoreChipGroupLayout? layout;

  @override
  final Set<T>? initialValue;

  @override
  final void Function(Set<T>)? onChanged;

  @override
  final bool allowDeselect;

  @override
  final int? maxSelection;

  @override
  final CoreChipGroupMaxBehavior? maxSelectionBehavior;

  @override
  final int? minSelection;

  @override
  final Widget? title;

  @override
  final Widget? selectionHint;

  @override
  final bool showFade;

  /// Per-instance style override (gaps / fade / text slots).
  @override
  final CoreChipGroupStyle? chipGroupStyle;

  /// Returns a copy of this [ChipGroup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ChipGroup<T> copyWith({
    Key? key,
    void Function(Set<T>)? onChanged,
    Set<T>? initialValue,
    List<T>? items,
    ChipGroupItemBuilder<T>? chipBuilder,
    CoreChipGroupSelectionMode? selectionMode,
    CoreChipGroupLayout? layout,
    bool? allowDeselect,
    int? maxSelection,
    CoreChipGroupMaxBehavior? maxSelectionBehavior,
    int? minSelection,
    Widget? title,
    Widget? selectionHint,
    bool? showFade,
    CoreChipGroupStyle? chipGroupStyle,
  }) {
    return ChipGroup(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      items: items ?? this.items,
      chipBuilder: chipBuilder ?? this.chipBuilder,
      selectionMode: selectionMode ?? this.selectionMode,
      layout: layout ?? this.layout,
      allowDeselect: allowDeselect ?? this.allowDeselect,
      maxSelection: maxSelection ?? this.maxSelection,
      maxSelectionBehavior: maxSelectionBehavior ?? this.maxSelectionBehavior,
      minSelection: minSelection ?? this.minSelection,
      title: title ?? this.title,
      selectionHint: selectionHint ?? this.selectionHint,
      showFade: showFade ?? this.showFade,
      chipGroupStyle: chipGroupStyle ?? this.chipGroupStyle,
    );
  }

  @override
  State<ChipGroup<T>> createState() => _ChipGroupState<T>();
}

class _ChipGroupState<T> extends State<ChipGroup<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue ?? <T>{};
  }

  bool _isItemDisabled(
    T item,
    bool isMaxReached,
    CoreChipGroupMaxBehavior maxBehavior,
  ) {
    if (!isMaxReached) return false;
    if (_selected.contains(item)) return false;
    return maxBehavior == .disableRest;
  }

  void _handleItemTap(T item, CoreChipGroupSelectionMode mode) {
    var newSelected = Set.of(_selected);

    if (_selected.contains(item)) {
      final minSelection = widget.minSelection ?? 0;
      if (_selected.length > minSelection) {
        if (mode == .single && !widget.allowDeselect) return;
        newSelected = {...newSelected}..remove(item);
      }
    } else {
      final maxSelection = widget.maxSelection;
      if (maxSelection != null && _selected.length >= maxSelection) {
        final maxBehavior = widget.maxSelectionBehavior ?? .disableRest;
        if (maxBehavior == .silentIgnore || maxBehavior == .disableRest) {
          return;
        }
      }
      if (mode == .single) newSelected = <T>{};
      newSelected = {...newSelected, item};
    }

    setState(() => _selected = newSelected);
    widget.onChanged?.call(newSelected);
  }

  List<Widget> _buildChips(CoreChipGroupSelectionMode mode) {
    final maxBehavior = widget.maxSelectionBehavior ?? .disableRest;
    final isMaxReached =
        widget.maxSelection != null && _selected.length >= widget.maxSelection!;

    return [
      for (final item in widget.items)
        widget.chipBuilder(
          item,
          onTap: () => _handleItemTap(item, mode),
          enabled: !_isItemDisabled(item, isMaxReached, maxBehavior),
          selected: _selected.contains(item),
        ),
    ];
  }

  Widget _buildScrollLayout({
    required List<Widget> chips,
    required double itemSpacing,
    required double fadeWidth,
    required List<CoreColor> fadeGradient,
  }) {
    // Delegate to the unified `FadeScroll` so scroll-progress-aware
    // edge fades (start fade hides at scrollLeft=0, end fade hides at
    // scrollLeft=max) are shared with the Web implementation. The
    // gradient tokens are resolved by `FadeScroll`'s own resolver.
    return FadeScroll(
      direction: .horizontal,
      fadeScrollStyle: CoreFadeScrollStyle(
        startOffset: widget.showFade ? fadeWidth : 0,
        endOffset: widget.showFade ? fadeWidth : 0,
        gradient: widget.showFade ? fadeGradient : null,
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: itemSpacing,
        children: chips,
      ),
    );
  }

  Widget _wrapWithHeader(
    Widget content, {
    required TextStyle titleStyle,
    required TextStyle hintStyle,
    required CoreGapStyle titleHintGapStyle,
    required CoreGapStyle titleGapStyle,
  }) {
    final titleWidget = widget.title;
    final hintWidget = widget.selectionHint;
    if (titleWidget == null && hintWidget == null) return content;

    // The header stacks the title over the selection hint — two lines, the
    // hint reading as the title's caption.
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        if (titleWidget != null)
          DefaultTextStyle.merge(style: titleStyle, child: titleWidget),
        if (titleWidget != null && hintWidget != null)
          Gap(gapStyle: titleHintGapStyle),
        if (hintWidget != null)
          DefaultTextStyle.merge(style: hintStyle, child: hintWidget),
        Gap(gapStyle: titleGapStyle),
        content,
      ],
    );
  }

  @override
  void didUpdateWidget(covariant ChipGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null &&
        !identical(widget.initialValue, oldWidget.initialValue)) {
      _selected = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveChipGroup(
      context,
      layout: widget.layout,
      selectionMode: widget.selectionMode,
      chipGroupStyle: widget.chipGroupStyle,
    );

    final itemSpacing = resolved.itemSpacing;
    final scaledRowSpacing = resolved.rowSpacing;
    final titleGapStyle = resolved.titleGapStyle;
    final scaledFadeWidth = widget.showFade ? resolved.fadeWidth : 0.0;

    final chips = _buildChips(resolved.selectionMode);

    final Widget content;
    switch (resolved.layout) {
      case .wrap:
        content = Wrap(
          spacing: itemSpacing,
          runSpacing: scaledRowSpacing,
          children: chips,
        );
      case .scroll:
        content = _buildScrollLayout(
          chips: chips,
          itemSpacing: itemSpacing,
          fadeWidth: scaledFadeWidth,
          fadeGradient: resolved.fadeGradient,
        );
    }

    return _wrapWithHeader(
      content,
      titleStyle: resolved.titleTextStyle,
      hintStyle: resolved.hintTextStyle,
      titleHintGapStyle: resolved.titleHintGapStyle,
      titleGapStyle: titleGapStyle,
    );
  }
}

/// Chain sugar for merging a [CoreChipGroupStyle] patch into
/// [ChipGroup.chipGroupStyle] without hand-reconstructing every field.
/// Mirrors the Web `ChipGroup.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChipGroupStyle.merge` right-side-wins semantics).
extension ChipGroupStyleChain<T> on ChipGroup<T> {
  /// Returns a copy of this [ChipGroup] with [patch] merged into
  /// [chipGroupStyle] (patch fields win on conflict).
  ChipGroup<T> withStyle(CoreChipGroupStyle patch) => copyWith(
    chipGroupStyle: (chipGroupStyle ?? const CoreChipGroupStyle()).merge(
      patch,
    ),
  );
}
