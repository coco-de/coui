import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/chip_group/chip_group_style.dart';
import 'package:coui_web/src/components/layout/fade_scroll/fade_scroll.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Web alias for [CoreChipGroupItemBuilder].
typedef ChipGroupItemBuilder<T> = CoreChipGroupItemBuilder<T, Component>;

/// 선택 가능한 칩 그룹 컴포넌트 (Web).
///
/// Flutter `ChipGroup` 와 동일한 API/렌더링.
///
/// Per Epic #1603 (옵션 B 최종) widget = render only — the resolver
/// finishes className + inlineStyles synthesis, and nested
/// `CoreXxxStyle` slots ([ResolvedChipGroup.titleGapStyle] /
/// [ResolvedChipGroup.fadeScrollStyle]) are forwarded straight to
/// child unified widgets. Inter-chip spacing flows through native
/// `column-gap` on [ResolvedChipGroup.wrap] / [ResolvedChipGroup.scrollInner]
/// (no `Gap` indirection — parity with Flutter `Wrap.spacing` /
/// `Row.spacing`). The widget owns only the semantic enums (`layout` /
/// `selectionMode`) and selection behaviour (no theme / merge / chrome
/// decisions in the body).
class ChipGroup<T> extends UiStatefulComponent
    implements CoreChipGroupContract<T, Component> {
  /// Creates a [ChipGroup].
  const ChipGroup({
    required this.items,
    required this.chipBuilder,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
  final Component? title;

  @override
  final Component? selectionHint;

  @override
  final bool showFade;

  /// Per-instance style override (gaps / fade / text slots).
  @override
  final CoreChipGroupStyle? chipGroupStyle;

  /// Returns a copy of this [ChipGroup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ChipGroup<T> copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    void Function(Set<T>)? onChanged,
    Set<T>? initialValue,
    List<T>? items,
    ChipGroupItemBuilder<T>? chipBuilder,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreChipGroupSelectionMode? selectionMode,
    CoreChipGroupLayout? layout,
    bool? allowDeselect,
    int? maxSelection,
    CoreChipGroupMaxBehavior? maxSelectionBehavior,
    int? minSelection,
    Component? title,
    Component? selectionHint,
    bool? showFade,
    CoreChipGroupStyle? chipGroupStyle,
  }) {
    return ChipGroup(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      items: items ?? this.items,
      chipBuilder: chipBuilder ?? this.chipBuilder,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

/// Chain sugar mirroring the Flutter `ChipGroup.withStyle` extension —
/// merges a [CoreChipGroupStyle] patch into [ChipGroup.chipGroupStyle]
/// via the existing [ChipGroup.copyWith].
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

class _ChipGroupState<T> extends State<ChipGroup<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = component.initialValue ?? <T>{};
  }

  bool _isItemDisabled(
    T item, {
    required bool isMaxReached,
    required CoreChipGroupMaxBehavior maxBehavior,
  }) {
    if (!isMaxReached) return false;
    if (_selected.contains(item)) return false;
    return maxBehavior == .disableRest;
  }

  void _handleItemTap(T item, CoreChipGroupSelectionMode mode) {
    var newSelected = Set.of(_selected);

    if (_selected.contains(item)) {
      final minSelection = component.minSelection ?? 0;
      if (_selected.length > minSelection) {
        if (mode == .single && !component.allowDeselect) return;
        newSelected = {...newSelected}..remove(item);
      }
    } else {
      final maxSelection = component.maxSelection;
      if (maxSelection != null && _selected.length >= maxSelection) {
        final maxBehavior = component.maxSelectionBehavior ?? .disableRest;
        if (maxBehavior == .silentIgnore || maxBehavior == .disableRest) {
          return;
        }
      }
      if (mode == .single) newSelected = <T>{};
      newSelected = {...newSelected, item};
    }

    setState(() => _selected = newSelected);
    component.onChanged?.call(newSelected);
  }

  List<Component> _buildChips(CoreChipGroupSelectionMode mode) {
    final maxBehavior = component.maxSelectionBehavior ?? .disableRest;
    final isMaxReached =
        component.maxSelection != null &&
        _selected.length >= component.maxSelection!;

    return [
      for (final item in component.items)
        component.chipBuilder(
          item,
          onTap: () => _handleItemTap(item, mode),
          enabled: !_isItemDisabled(
            item,
            isMaxReached: isMaxReached,
            maxBehavior: maxBehavior,
          ),
          selected: _selected.contains(item),
        ),
    ];
  }

  Component _buildHeader(ResolvedChipGroup resolved) {
    final titleC = component.title;
    final hintC = component.selectionHint;

    return div(
      [
        if (titleC != null)
          div(
            [titleC],
            classes: resolved.title.className,
            styles: resolved.title.inlineStyles,
          ),
        if (titleC != null && hintC != null)
          Gap(gapStyle: resolved.titleHintGapStyle),
        if (hintC != null)
          div(
            [hintC],
            classes: resolved.hint.className,
            styles: resolved.hint.inlineStyles,
          ),
      ],
      classes: resolved.header.className,
    );
  }

  Component _buildWrapLayout({
    required ResolvedChipGroup resolved,
    required List<Component> chips,
  }) {
    return div(
      chips,
      classes: resolved.wrap.className,
      styles: resolved.wrap.inlineStyles,
    );
  }

  Component _buildScrollLayout({
    required ResolvedChipGroup resolved,
    required List<Component> chips,
  }) {
    // Delegate to the unified `FadeScroll` for scroll-progress-aware
    // edge fades — same component the Flutter side wraps with, so
    // hide/reveal behaviour at both ends is shared across platforms.
    // Fade chrome (offsets + gradient) flows through the nested
    // [ResolvedChipGroup.fadeScrollStyle] slot. Inter-chip spacing is
    // baked into [ResolvedChipGroup.scrollInner.inlineStyles] as
    // native `column-gap` (parity with Flutter `Row.spacing`).
    return FadeScroll(
      direction: .horizontal,
      fadeScrollStyle: resolved.fadeScrollStyle,
      child: div(
        chips,
        classes: resolved.scrollInner.className,
        styles: resolved.scrollInner.inlineStyles,
      ),
    );
  }

  @override
  void didUpdateComponent(covariant ChipGroup<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.initialValue != null &&
        !identical(component.initialValue, oldComponent.initialValue)) {
      _selected = component.initialValue!;
    }
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 — `WebResolvedChrome` contract). `co_chip_group` reads the
    // paint-ready strings (root / header / title / hint / wrap /
    // scrollInner) and nested style slots (titleGapStyle / itemGapStyle
    // / fadeScrollStyle) directly.
    final resolved = resolveChipGroup(
      context,
      showFade: component.showFade,
      chipGroupStyle: component.chipGroupStyle,
    );

    // Semantic enums (`layout` / `selectionMode`) are widget-only
    // identifiers — read straight from the widget prop with the design
    // default fallback. Not theme-overridable (parity with Flutter +
    // chip/badge: a Theme override would stamp on the caller's
    // `layout:` / `selectionMode:`). The resolver stays chrome-only.
    final effectiveLayout = component.layout ?? .wrap;
    final effectiveSelectionMode = component.selectionMode ?? .multi;

    final chips = _buildChips(effectiveSelectionMode);

    final Component chipsContainer;
    switch (effectiveLayout) {
      case .scroll:
        chipsContainer = _buildScrollLayout(resolved: resolved, chips: chips);
      case .wrap:
        chipsContainer = _buildWrapLayout(resolved: resolved, chips: chips);
    }

    return div(
      [
        if (component.title != null || component.selectionHint != null) ...[
          _buildHeader(resolved),
          Gap(gapStyle: resolved.titleGapStyle),
        ],
        chipsContainer,
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
