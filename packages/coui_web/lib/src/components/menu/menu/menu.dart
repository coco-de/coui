import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/menu/menu/menu_fit_scope.dart';
import 'package:coui_web/src/components/menu/menu/menu_glide_scope.dart';
import 'package:coui_web/src/components/menu/menu/menu_style.dart';
import 'package:coui_web/src/components/menu/menu_item/menu_item.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified static menu panel component for Web.
///
/// `Menu` renders a list of rich menu entries inside a bordered
/// `<div>` panel. It is the cross-platform unification of the legacy
/// Web `Menu` family (`<ul>` / `<details>` based) and the rich item
/// model of the Flutter `MenuButton` family — sharing the same API as
/// the Flutter `Menu` widget.
///
/// Construct entries through the [CoreMenuItem] named factories:
///
/// ```dart
/// Menu(
///   items: [
///     CoreMenuItem.label('Navigation'),
///     CoreMenuItem.action('Home', active: true, onPressed: () {}),
///     CoreMenuItem.divider(),
///     CoreMenuItem.checkbox('Show grid', checked: true, onChanged: (_) {}),
///   ],
/// )
/// ```
///
/// surface:functional — its panel is a `Popup`, mounted over the page by
/// whatever opened it.
class Menu extends UiStatefulComponent implements CoreMenuContract<Component> {
  /// Creates a [Menu].
  const Menu({
    required this.items,
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
    this.vertical = true,
    this.size = CoreMenuItemSize.defaultSize,
    this.ariaLabel,
    this.menuStyle,
    this.onActivate,
  });

  @override
  final List<CoreMenuItem<Component>> items;

  @override
  final bool vertical;

  @override
  final CoreMenuItemSize size;

  @override
  final String? ariaLabel;

  @override
  final CoreMenuStyle? menuStyle;

  @override
  final void Function()? onActivate;

  /// Returns a copy of this [Menu] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Menu copyWith({
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
    List<CoreMenuItem<Component>>? items,
    bool? vertical,
    CoreMenuItemSize? size,
    String? ariaLabel,
    CoreMenuStyle? menuStyle,
    void Function()? onActivate,
  }) {
    return Menu(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      items: items ?? this.items,
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
      vertical: vertical ?? this.vertical,
      size: size ?? this.size,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      menuStyle: menuStyle ?? this.menuStyle,
      onActivate: onActivate ?? this.onActivate,
    );
  }

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  /// Which interactive row holds the menu's single tab stop.
  ///
  /// A menu is one stop from the outside and arrow keys move within it,
  /// so exactly one row carries `tabindex="0"` at a time — including a
  /// disabled row, which stays in the rotation (reachable and inert)
  /// because a user who cannot land on it cannot be told why it does
  /// nothing.
  int _focusedRow = 0;

  final _typeahead = RovingTypeahead();

  /// Panel id — the caller's when given, else a stable per-instance one.
  /// Focus moves through the DOM, so the panel has to be findable.
  late final String _panelId =
      component.id ?? 'co-menu-${identityHashCode(this).toRadixString(36)}';

  /// The entries that take a turn in the arrow-key rotation.
  List<CoreMenuItem<Component>> get _rows =>
      component.items.where(_isInteractive).toList();

  /// Whether [item] is a row a user can land on. Labels, dividers and
  /// gaps are structure, not stops.
  static bool _isInteractive(CoreMenuItem<Component> item) =>
      item.kind == .action || item.kind == .checkbox || item.kind == .radio;

  void _handleKeyDown(web.KeyboardEvent event) {
    // The axis the arrows walk is the axis the menu lays its rows on —
    // pressing "down" in a menubar would otherwise move along nothing.
    final rows = _rows;
    // Start from the row that actually holds focus — a host (a menubar)
    // may have focused a row directly — and fall back to the tab stop.
    final current = rovingIndexOfEvent(event, _panelId) ?? _focusedRow;
    final target = rovingKeyTarget(
      event,
      current: current,
      count: rows.length,
      vertical: component.vertical,
      labels: [for (final row in rows) row.label],
      typeahead: _typeahead,
    );
    if (target == null) return;
    setState(() => _focusedRow = target);
    focusRovingItem(_panelId, target);
  }

  /// Builds the fixed-width leading column so rows stay aligned.
  Component? _buildLeading(
    ResolvedMenu resolved,
    Component? leading,
    bool hasLeading,
  ) {
    if (!hasLeading) return leading;
    return div(
      [?leading],
      classes: resolved.leadingColumn.className,
      styles: resolved.leadingColumn.inlineStyles,
    );
  }

  Component _buildRow({
    required ResolvedMenu resolved,
    required bool hasLeading,
    required Component label,
    Component? leading,
    Component? trailing,
  }) {
    final builtLeading = _buildLeading(resolved, leading, hasLeading);
    final gap = Gap(gapStyle: resolved.labelGapStyle);
    return div(
      [
        ?builtLeading,
        if (builtLeading != null) gap,
        label,
        if (trailing != null) gap,
        ?trailing,
      ],
      classes: resolved.row.className,
    );
  }

  Component _buildLabelEntry(
    ResolvedMenu resolved,
    CoreMenuItem<Component> item,
    bool hasLeading,
  ) {
    return div(
      [
        _buildRow(
          resolved: resolved,
          hasLeading: hasLeading,
          label: span(
            [Text(item.label)],
            classes: resolved.labelText.className,
            styles: resolved.labelText.inlineStyles,
          ),
          leading:
              item.leading ??
              (item.standardAction == null
                  ? null
                  : Icon(item.standardAction!.icon)),
          trailing: item.trailing,
        ),
      ],
      classes: resolved.label.className,
      styles: resolved.label.inlineStyles,
      attributes: const {'role': 'presentation'},
    );
  }

  /// Builds an interactive row as a composed `MenuItem`. The CSS
  /// `:hover` / `aria-selected` fill, the disabled `cursor-not-allowed`
  /// + muting and the focus ring all come from the row itself + the
  /// raw-forwarded [ResolvedMenu.itemStyle] — not a hand-rolled
  /// `<div>` + Dart-re-render hover. The caller's `role` / `aria-*`
  /// attributes pass through; the active row adds `aria-selected="true"`
  /// (→ the variant's `aria-selected:` `primary` / `onPrimary` chrome).
  /// `Button` owns the label typography, so the child is a bare `Text`.
  Component _interactiveRow({
    required void Function()? onPressed,
    required ResolvedMenu resolved,
    required CoreMenuItem<Component> item,
    required bool reserveMark,
    required bool selected,
    required int rowIndex,
    required Map<String, String> attributes,
    String? glideRow,
    Component? mark,
    bool hasSubmenu = false,
  }) {
    // Roving focus: one tab stop for the whole menu, arrows move between
    // rows. A disabled row keeps its place in the rotation — reachable and
    // inert, per the WAI-ARIA menu pattern.
    final roving = rovingItemAttributes(
      _panelId,
      rowIndex,
      active: rowIndex == _focusedRow,
    );
    return MenuItem(
      label: Text(item.label),
      size: component.size,
      tone: item.tone,
      description: item.description == null ? null : Text(item.description!),
      shortcut: item.shortcut == null ? null : Text(item.shortcut!),
      leading:
          item.leading ??
          (item.standardAction == null
              ? null
              : Icon(item.standardAction!.icon)),
      trailing: item.trailing,
      mark: mark,
      reserveMark: reserveMark,
      hasSubmenu: hasSubmenu,
      selected: selected,
      enabled: !item.disabled,
      onPressed: onPressed,
      menuItemStyle: resolved.itemStyle,
      attributes: {
        ...attributes,
        ...roving,
        // The row a gliding finger is over. Its roving id is the row's
        // identity across every menu in the panel, nested ones included.
        if (glideRow != null && roving[kRovingItemAttribute] == glideRow)
          MenuGlideScope.attribute: 'true',
      },
    );
  }

  Component _buildActionEntry(
    ResolvedMenu resolved,
    CoreMenuItem<Component> item, {
    required bool reserveMark,
    required int rowIndex,
    String? glideRow,
  }) {
    final hasSubmenu = item.submenu != null && item.submenu!.isNotEmpty;
    final row = _interactiveRow(
      // Action selected → dismiss the host overlay first (`onActivate`,
      // parity with the hosts' "close then act" order), then run the item's
      // own handler. Submenu parents expand inline, never dismiss.
      onPressed: item.onPressed == null
          ? null
          : () {
              if (!hasSubmenu) component.onActivate?.call();
              item.onPressed!();
            },
      resolved: resolved,
      item: item,
      reserveMark: reserveMark,
      selected: item.active,
      rowIndex: rowIndex,
      glideRow: glideRow,
      hasSubmenu: hasSubmenu,
      attributes: {
        'role': CoreSemanticRole.menuItem.ariaRole,
        'data-href': ?item.href,
      },
    );

    if (!hasSubmenu) return row;

    // Inline nested submenu — indented one level.
    return div(
      [
        row,
        div(
          [
            Menu(
              items: item.submenu!,
              size: component.size,
              menuStyle: resolved.submenuStyle,
            ),
          ],
          classes: resolved.submenuIndent.className,
          styles: resolved.submenuIndent.inlineStyles,
        ),
      ],
      classes: resolved.submenuWrapper.className,
    );
  }

  Component _buildToggleEntry(
    ResolvedMenu resolved,
    CoreMenuItem<Component> item, {
    required bool checked,
    required IconName mark,
    required int rowIndex,
    String? glideRow,
  }) {
    final isCheckbox = item.kind == .checkbox;
    // The glyph only; its size and tint are the row's (`MenuItem` owns
    // the mark seat), so nothing here states chrome.
    final leadingMark = checked ? Icon(mark) : null;
    return _interactiveRow(
      onPressed: item.onChanged == null
          ? null
          : () => item.onChanged!(!isCheckbox || !checked),
      resolved: resolved,
      item: item,
      reserveMark: true,
      selected: checked,
      rowIndex: rowIndex,
      glideRow: glideRow,
      mark: leadingMark,
      attributes: {
        'role': isCheckbox
            ? CoreSemanticRole.menuItemCheckbox.ariaRole
            : CoreSemanticRole.menuItemRadio.ariaRole,
        'aria-checked': '$checked',
      },
    );
  }

  Component _buildEntry(
    ResolvedMenu resolved,
    CoreMenuItem<Component> item,
    bool hasLeading, {
    required bool reserveMark,
    required int rowIndex,
    String? glideRow,
  }) {
    return switch (item.kind) {
      .label => _buildLabelEntry(resolved, item, hasLeading),
      .action => _buildActionEntry(
        resolved,
        item,
        reserveMark: reserveMark,
        rowIndex: rowIndex,
        glideRow: glideRow,
      ),
      .checkbox => _buildToggleEntry(
        resolved,
        item,
        checked: item.checked,
        mark: LucideIcons.check,
        rowIndex: rowIndex,
        glideRow: glideRow,
      ),
      .radio => _buildToggleEntry(
        resolved,
        item,
        checked: item.selected,
        // The glyph is the entry's statement, not what makes it a radio:
        // the kind above does.
        mark: item.radioMark.icon,
        rowIndex: rowIndex,
        glideRow: glideRow,
      ),
      // A group boundary inside `role="menu"`/`role="menubar"` — the ARIA
      // APG menu pattern's `role="separator"` between item groups
      // (`CoreSemanticRole.separator`'s ARIA spelling, non-focusable
      // variant). `semantic: true` is what turns that on; a bare
      // `Divider` used outside a `Menu` stays decorative and silent to
      // assistive tech.
      .divider => div(
        [
          Divider(
            orientation: component.vertical ? .horizontal : .vertical,
            dividerStyle: resolved.dividerStyle,
            semantic: true,
          ),
        ],
        classes: resolved.divider.className,
        styles: resolved.divider.inlineStyles,
        attributes: const {'role': 'presentation'},
      ),
      .gap => Gap(gapStyle: CoreGapStyle(size: item.gapSize)),
    };
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveMenu(
      context,
      size: component.size,
      vertical: component.vertical,
      menuStyle: component.menuStyle,
      // A host that holds its panel to the room the viewport leaves it says so
      // through the scope; only a vertical panel has rows to scroll.
      maxHeight: component.vertical ? MenuFitScope.maybeOf(context) : null,
    );
    final hasLeading = component.items.any((item) => item.hasLeading);
    // A panel with any toggle row reserves the mark column on every
    // interactive row, so the labels of a mixed group stay on one x
    // whether or not each row draws its mark.
    final reserveMark = component.items.any(
      (item) => item.kind == .checkbox || item.kind == .radio,
    );
    // The row a gliding finger is over, when a `ContextMenu` lets one glide.
    // Absent outside that scope, so a menu that is not gliding marks nothing.
    final glideRow = MenuGlideScope.maybeOf(context)?.highlightedRow;
    // Row indices count only the focusable entries — a divider is not a
    // stop on the arrow-key rotation, and numbering it would make one
    // press look like it did nothing.
    var interactiveIndex = -1;

    // Inter-row spacing is rendered by the panel's flex `gap` CSS —
    // emitted by `resolveMenu` into `resolved.root.inlineStyles` — so
    // the widget no longer hand-rolls a `Gap` interleave between
    // adjacent entries.
    final entries = [
      for (final item in component.items)
        _buildEntry(
          resolved,
          item,
          hasLeading,
          reserveMark: reserveMark,
          rowIndex: _isInteractive(item) ? ++interactiveIndex : -1,
          glideRow: glideRow,
        ),
    ];
    // A panel held to the viewport's room keeps its own box — border, corners,
    // shadow, glass rim — and scrolls the entries in a list inside it.
    final scroller = resolved.rowsScroller;

    return div(
      scroller == null
          ? entries
          : [
              div(
                entries,
                classes: scroller.className,
                styles: scroller.inlineStyles,
              ),
            ],
      id: _panelId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': component.vertical ? 'menu' : 'menubar',
        'aria-orientation': component.vertical ? 'vertical' : 'horizontal',
        if (component.ariaLabel != null && component.ariaLabel!.isNotEmpty)
          'aria-label': component.ariaLabel!,
      },
      events: {
        ...component.events,
        'keydown': EventHandlers.chain(
          component.events['keydown'],
          EventHandlers.createKeyboardEventHandler(_handleKeyDown),
        ),
      },
    );
  }
}

/// Chain sugar mirroring the Flutter `Menu.withStyle` extension — merges
/// a [CoreMenuStyle] patch into [Menu.menuStyle] via the existing
/// [Menu.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenuStyle.merge` right-side-wins semantics).
extension MenuStyleChain on Menu {
  /// Returns a copy of this [Menu] with [patch] merged into [menuStyle]
  /// (patch fields win on conflict).
  Menu withStyle(CoreMenuStyle patch) =>
      copyWith(menuStyle: (menuStyle ?? const CoreMenuStyle()).merge(patch));
}
