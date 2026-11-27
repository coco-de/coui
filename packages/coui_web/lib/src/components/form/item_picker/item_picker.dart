import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/item_picker/item_picker_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

int _coItemPickerScopeCounter = 0;

/// Unified cross-platform inline item picker for CoUI Web.
///
/// `ItemPicker` renders a searchable, single-select list (or grid) of
/// string items. Typing in the search field filters the items
/// (case-insensitive `contains`); clicking an item selects it. Uses
/// custom `<div>` rendering for visual parity with Flutter `ItemPicker`.
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
///   onChanged: (v) => print('Selected: $v'),
/// )
/// ```
///
/// surface:behind — draws its own box rather than composing one, so what shows
/// through it is the page it is laid on.
///
/// surface:content — a picker laid out in the page flow, not mounted over
/// it.
class ItemPicker extends UiStatefulComponent
    implements CoreItemPickerContract<CoreValueChanged<String>?> {
  /// Creates a [ItemPicker].
  const ItemPicker({
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
  final CoreValueChanged<String>? onChanged;

  // === Style (chrome / dimensional) ===

  @override
  final CoreItemPickerStyle? itemPickerStyle;

  /// Returns a copy of this [ItemPicker] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ItemPicker copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<String>? items,
    String? selectedValue,
    String? searchPlaceholder,
    bool? showSearch,
    bool? enabled,
    CoreItemPickerLayout? layout,
    int? gridColumns,
    String? title,
    String? emptyText,
    CoreValueChanged<String>? onChanged,
    CoreItemPickerStyle? itemPickerStyle,
  }) {
    return ItemPicker(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
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

/// Chain sugar mirroring the Flutter `ItemPicker.withStyle` extension —
/// merges a [CoreItemPickerStyle] patch into
/// [ItemPicker.itemPickerStyle] via the existing [ItemPicker.copyWith].
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
      borderRadius: CoreBorderRadius.zero,
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
  late final String _scopeId;

  String _query = '';

  /// The option holding the listbox's single tab stop, by value, or `null`
  /// for the default (the selected option, else the first).
  ///
  /// The listbox is one stop from the outside and the arrows walk it (the
  /// WAI-ARIA listbox pattern). Tracked by value rather than position so the
  /// stop stays on its option when the search filter reorders the list.
  String? _activeItem;

  final _typeahead = RovingTypeahead();

  @override
  void initState() {
    super.initState();
    _scopeId =
        'co-item-picker-${kIsWeb ? 'web' : 'ssr'}-'
        '${_coItemPickerScopeCounter++}';
  }

  /// Index of the option holding the tab stop within [filtered].
  int _activeIndexIn(List<String> filtered) {
    for (final candidate in [_activeItem, component.selectedValue]) {
      final index = candidate == null ? -1 : filtered.indexOf(candidate);
      if (index >= 0) return index;
    }
    return 0;
  }

  /// The arrow keys, `Home`/`End` and typeahead over the visible options.
  /// A list walks Up/Down; a grid walks both axes, a row being
  /// [ItemPicker.gridColumns] options. Neither wraps — a listbox is
  /// scanned, not cycled. Enter/Space stay with the option's `Clickable`.
  void _handleListKeyDown(
    web.KeyboardEvent event,
    List<String> filtered,
    String listboxId,
  ) {
    final grid = component.layout == CoreItemPickerLayout.grid;
    final target = rovingKeyTarget(
      event,
      current: _activeIndexIn(filtered),
      count: filtered.length,
      vertical: true,
      wrap: false,
      columns: grid ? component.gridColumns : 1,
      labels: filtered,
      typeahead: _typeahead,
    );
    if (target == null) return;
    setState(() => _activeItem = filtered[target]);
    focusRovingItem(listboxId, target);
  }

  List<String> get _filteredItems {
    if (_query.isEmpty) return component.items;
    final lower = _query.toLowerCase();
    return component.items
        .where((item) => item.toLowerCase().contains(lower))
        .toList();
  }

  void _handleSelect(String item) {
    if (!component.enabled) return;
    component.onChanged?.call(item);
  }

  Component _buildOption(
    BuildContext context,
    String item,
    String scopeId, {
    required Map<String, String> rovingAttributes,
  }) {
    final selected = item == component.selectedValue;
    final option = resolveItemPickerOption(
      context,
      selected: selected,
      enabled: component.enabled,
      scopeId: scopeId,
      itemPickerStyle: component.itemPickerStyle,
    );

    // Web twin of the Flutter option: the composed Clickable owns tap /
    // keyboard activation / cursor / focus ring / disabled opacity; the
    // inner <div> carries only the option chrome. The listbox `role` /
    // `aria-selected` ride on the Clickable root (caller attributes win,
    // overriding the generic button role) so screen readers keep the
    // option semantics under the parent `role="listbox"`. `w-full`
    // spreads the Clickable across its cell (list) / column (grid) so the
    // row highlight fills the width. Press-shrink is pinned off via
    // `CoreItemPickerStyle.defaultClickableStyle` (`pressedScale: 1`).
    return Clickable(
      onPressed: () => _handleSelect(item),
      onFocus: (focused) {
        // Clicking or tabbing onto an option moves the tab stop with it.
        if (focused && _activeItem != item) {
          setState(() => _activeItem = item);
        }
      },
      semanticsSelected: selected,
      attributes: {
        'role': 'option',
        // After the Clickable's own `tabindex`, so the roving value wins.
        ...rovingAttributes,
      },
      classes: WebLayout.wFull,
      enabled: component.enabled,
      clickableStyle: option.clickableStyle,
      child: Component.element(
        tag: 'div',
        classes: option.root.className,
        styles: option.root.inlineStyles,
        children: [
          if (selected)
            Icon(LucideIcons.check, iconStyle: option.checkIconStyle),
          Component.element(tag: 'span', children: [Text(item)]),
        ],
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    // Scope id for the per-instance pseudo-state scoped rules — used to
    // build the shared `.co-item-picker-h-*` class the options carry, the
    // frame's own `.co-item-picker-frame-*` class, and what the `<style>`
    // rules target (the caller's id wins, else a generated one stable
    // across rebuilds via the State's identity).
    final scopeId = component.id ?? _scopeId;
    final resolved = resolveItemPicker(
      context,
      enabled: component.enabled,
      scopeId: scopeId,
      itemPickerStyle: component.itemPickerStyle,
    );
    final rules = resolveItemPickerRules(
      context,
      scopeId: scopeId,
      enabled: component.enabled,
      itemPickerStyle: component.itemPickerStyle,
    );
    final filtered = _filteredItems;
    // Scopes the options' roving markers to this listbox.
    final listboxId = '$scopeId-listbox';

    final children = <Component>[];

    // `<style>` is `display: none`, so it never affects the flex layout.
    if (rules.css.isNotEmpty) {
      children.add(
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      );
    }

    final title = component.title;

    if (component.showSearch) {
      children
        ..add(
          // Part of this composite: walled off from the enclosing
          // `FormField`, which is shown the composite's own value.
          FormFieldHandleScope.boundary(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              placeholder: Text(
                component.searchPlaceholder ??
                    CouiLocalizations.of(context).itemPickerSearchPlaceholder,
              ),
              enabled: component.enabled,
              // The panel is the only boundary: the field is the bare
              // variant, and the divider below closes the row.
              variant: .plain,
              prefix: Icon(
                LucideIcons.search,
                iconStyle: resolved.searchIconStyle,
              ),
              textFieldStyle: resolved.searchFieldStyle,
              type: .search,
            ),
          ),
        )
        ..add(Divider(dividerStyle: resolved.searchDividerStyle));
    }

    if (filtered.isEmpty) {
      children.add(
        Component.element(
          tag: 'div',
          classes: resolved.empty.className,
          styles: resolved.empty.inlineStyles,
          children: [
            Text(
              component.emptyText ??
                  CouiLocalizations.of(context).itemPickerEmpty,
            ),
          ],
        ),
      );
    } else {
      final itemsChrome = resolveItemPickerItems(
        context,
        layout: component.layout,
        gridColumns: component.gridColumns,
        itemPickerStyle: component.itemPickerStyle,
      );
      final activeIndex = _activeIndexIn(filtered);
      // The listbox is the element that directly owns the options — not the
      // root, whose title and search field are not options and would leave
      // every option orphaned from its listbox. The caller's semantic
      // attributes (an `aria-label` naming the list) follow the role here.
      children.add(
        Component.element(
          tag: 'div',
          classes: itemsChrome.root.className,
          styles: itemsChrome.root.inlineStyles,
          attributes: {
            for (final entry in component.componentAttributes.entries)
              if (isSemanticHtmlAttribute(entry.key)) entry.key: entry.value,
            'role': 'listbox',
            if (component.layout == CoreItemPickerLayout.list)
              'aria-orientation': 'vertical',
            if (title != null &&
                !component.componentAttributes.containsKey('aria-label'))
              'aria-label': title,
            if (!component.enabled) 'aria-disabled': 'true',
          },
          events: {
            'keydown': EventHandlers.createKeyboardEventHandler(
              (event) => _handleListKeyDown(event, filtered, listboxId),
            ),
          },
          children: [
            // The title is a label inside the list, ahead of the options,
            // not a header of the panel.
            if (title != null)
              Component.element(
                tag: 'div',
                classes: resolved.title.className,
                styles: resolved.title.inlineStyles,
                attributes: const {'role': 'presentation'},
                children: [Text(title)],
              ),
            for (var i = 0; i < filtered.length; i++)
              _buildOption(
                context,
                filtered[i],
                scopeId,
                rovingAttributes: rovingItemAttributes(
                  listboxId,
                  i,
                  active: i == activeIndex,
                ),
              ),
          ],
        ),
      );
    }

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        for (final entry in component.componentAttributes.entries)
          if (!isSemanticHtmlAttribute(entry.key)) entry.key: entry.value,
      },
      events: component.events,
      children: children,
    );
  }
}
