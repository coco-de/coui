import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/popup/popup_scroll_scope.dart';

/// Unified static menu panel component.
///
/// `Menu` renders a list of rich menu entries inside a bordered
/// panel. It is the cross-platform unification of the legacy Web `Menu`
/// family (`<ul>` / `<details>` based) and the rich item model of the
/// Flutter `MenuButton` family (`leading` / `trailing` / `submenu` /
/// checkbox / radio / divider / gap).
///
/// Every interactive entry (action / checkbox / radio) is a composed
/// [MenuItem]; the menu owns the row density ([size]) and hands one value
/// to every row, so a single menu never mixes heights.
///
/// Construct entries through the [CoreMenuItem] named factories:
///
/// ```dart
/// Menu(
///   items: [
///     CoreMenuItem.label('Navigation'),
///     CoreMenuItem.action('Home', active: true, onPressed: () {}),
///     CoreMenuItem.action(
///       'More',
///       submenu: [CoreMenuItem.action('Settings', onPressed: () {})],
///     ),
///     CoreMenuItem.divider(),
///     CoreMenuItem.checkbox('Show grid', checked: true, onChanged: (_) {}),
///     CoreMenuItem.action('Contact', disabled: true),
///   ],
/// )
/// ```
///
/// surface:functional — its panel is a `Popup`, mounted over the page by
/// whatever opened it.
class Menu extends StatefulWidget implements CoreMenuContract<Widget> {
  /// Creates a [Menu].
  const Menu({
    required this.items,
    this.vertical = true,
    this.size = CoreMenuItemSize.defaultSize,
    this.ariaLabel,
    this.menuStyle,
    this.onActivate,
    super.key,
  });

  @override
  final List<CoreMenuItem<Widget>> items;

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
    Key? key,
    List<CoreMenuItem<Widget>>? items,
    bool? vertical,
    CoreMenuItemSize? size,
    String? ariaLabel,
    CoreMenuStyle? menuStyle,
    void Function()? onActivate,
  }) {
    return Menu(
      key: key ?? this.key,
      items: items ?? this.items,
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
  @override
  Widget build(BuildContext context) {
    final resolved = resolveMenu(
      context,
      size: widget.size,
      vertical: widget.vertical,
      menuStyle: widget.menuStyle,
    );
    final hasLeading = widget.items.any((item) => item.hasLeading);
    // A panel with any toggle row reserves the mark column on every
    // interactive row, so the labels of a mixed group stay on one x
    // whether or not each row draws its mark.
    final hasToggle = widget.items.any(
      (item) => item.kind == .checkbox || item.kind == .radio,
    );

    final entries = <Widget>[
      for (var i = 0; i < widget.items.length; i++)
        _MenuEntry(
          style: resolved,
          item: widget.items[i],
          size: widget.size,
          vertical: widget.vertical,
          hasLeadingColumn: hasLeading,
          reserveMark: hasToggle,
          onActivate: widget.onActivate,
        ),
    ];

    // The bordered, elevated floating box is the unified `Popup` — `Menu`
    // composes it (no self-painted `Container`/`DecoratedBox`). The panel
    // chrome (including the 240 / 280 width band) + inter-row spacing all
    // live in `resolved.popupStyle`, which the popup resolver finishes;
    // `Popup` lays the entries along [direction] (`Column.spacing` /
    // `Row.spacing` from the spacing field).
    //
    // A vertical menu's rows scroll when the panel is given less height than
    // they need — a long menu in a short viewport. It is the menu's statement,
    // not the popup's: only a list of rows is built to scroll. A submenu is
    // drawn inside its parent's panel, so the parent's rows scroll and the
    // nested one does not scroll a second time.
    final panel = PopupScrollScope(
      scrolls: widget.vertical && !_NestedMenuScope.of(context),
      child: Popup(
        direction: widget.vertical ? .vertical : .horizontal,
        popupStyle: resolved.popupStyle,
        children: entries,
      ),
    );

    // The container role is stated unconditionally, label or not: a
    // `menuItem` row is only a menu item to a screen reader when a `menu`
    // (or `menuBar`) encloses it — Flutter asserts on the shape, and the
    // Web twin puts the same `role="menu"` on the same box. Announcing
    // the panel only when it happens to be named would leave every
    // unnamed menu's rows announcing as loose commands.
    return CoUISemantics(
      role: widget.vertical ? .menu : .menuBar,
      label: widget.ariaLabel,
      container: true,
      child: MenuRowScope(child: panel),
    );
  }
}

/// Marks a [Menu] as drawn inside another menu's panel — an inline submenu.
class _NestedMenuScope extends InheritedWidget {
  const _NestedMenuScope({required super.child});

  /// Whether the menu built under [context] is nested in another menu.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_NestedMenuScope>() != null;

  @override
  bool updateShouldNotify(_NestedMenuScope oldWidget) => false;
}

/// Renders a single [CoreMenuItem] inside a [Menu].
class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.style,
    required this.item,
    required this.size,
    required this.vertical,
    required this.hasLeadingColumn,
    required this.reserveMark,
    this.onActivate,
  });

  final ResolvedMenu style;
  final CoreMenuItem<Widget> item;
  final CoreMenuItemSize size;
  final bool vertical;
  final bool hasLeadingColumn;

  /// Whether the panel holds a toggle row — every interactive row then
  /// keeps its mark column so labels align across the group.
  final bool reserveMark;

  /// Fired close-first when this row is an action and is activated — see
  /// [CoreMenuContract.onActivate].
  final void Function()? onActivate;

  /// Builds the label row's leading-column widget so a heading lines up
  /// with the rows under it when any entry carries a leading slot.
  Widget? _buildLabelLeading(Widget? leading) {
    if (!hasLeadingColumn) return leading;
    if (leading == null) {
      return ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: style.leadingColumnWidth),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(
        width: style.leadingColumnWidth,
        height: style.leadingColumnWidth,
      ),
      child: leading,
    );
  }

  Widget _buildLabelEntry() {
    final leading = _buildLabelLeading(item.leading);
    final trailing = item.trailing;
    final gap = Gap(gapStyle: style.labelGapStyle);
    return Padding(
      padding: style.labelPadding,
      child: Row(
        mainAxisAlignment: vertical ? .start : .center,
        mainAxisSize: vertical ? .max : .min,
        children: [
          ?leading,
          if (leading != null) gap,
          Flexible(child: Text(item.label, style: style.labelTextStyle)),
          if (trailing != null) gap,
          ?trailing,
        ],
      ),
    );
  }

  /// Builds an interactive row as a composed [MenuItem] — the row owns its
  /// fill, state layer, focus ring, typography and glyph tint (the
  /// `menuItemStyle` raw-forwarded from [ResolvedMenu.itemStyle]); the
  /// menu only maps the entry's data onto the row's seats.
  ///
  /// A horizontal menu lays its rows in a `Row`, which gives each child an
  /// unbounded width; the row's own `Expanded` label needs a bound, so the
  /// item is measured to its intrinsic width there. A vertical panel
  /// stretches its rows to the panel width and needs nothing.
  Widget _buildItem({
    required void Function()? onPressed,
    required bool selected,
    Widget? mark,
    bool hasSubmenu = false,
  }) {
    final row = MenuItem(
      label: Text(item.label),
      size: size,
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
      menuItemStyle: style.itemStyle,
    );
    return vertical ? row : IntrinsicWidth(child: row);
  }

  Widget _buildActionEntry() {
    final hasSubmenu = item.submenu != null && item.submenu!.isNotEmpty;
    final row = _buildItem(
      // Action selected → dismiss the host overlay first (`onActivate`,
      // parity with the hosts' "close then act" order), then run the item's
      // own handler. Submenu parents expand inline, never dismiss, so they
      // skip `onActivate`. Null `onActivate` (standalone `Menu`) is a no-op.
      onPressed: item.onPressed == null
          ? null
          : () {
              if (!hasSubmenu) onActivate?.call();
              item.onPressed!();
            },
      selected: item.active,
      hasSubmenu: hasSubmenu,
    );

    if (!hasSubmenu) return row;

    // Inline nested submenu — indented one level, same density.
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        row,
        Padding(
          padding: EdgeInsetsDirectional.only(start: style.submenuIndent),
          child: _NestedMenuScope(
            child: Menu(
              items: item.submenu!,
              size: size,
              // Inline nested submenu — the resolver-owned submenu style
              // (box-less panel by default, designer-overridable via
              // `CoreMenuStyle.submenuStyle`) raw-forwarded to the child,
              // which self-resolves.
              menuStyle: style.submenuStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleEntry({required bool checked, required IconName mark}) {
    // Which kind of toggle this is comes from the item, not from the
    // glyph it happens to draw. Comparing against a specific icon meant
    // that changing the checkmark — a purely visual decision — silently
    // turned every checkbox into a radio, because the branch stopped
    // matching and fell through to the always-select arm.
    //
    // Web already read `item.kind` here; this closes that asymmetry.
    final isCheckbox = item.kind == .checkbox;

    final row = _buildItem(
      onPressed: item.onChanged == null
          ? null
          : () => item.onChanged!(!isCheckbox || !checked),
      selected: checked,
      // The glyph is bare: the row tints and sizes it through its
      // per-state mark theme (`CoreMenuItemStyle.markIconStyle`).
      mark: checked ? Icon(mark) : null,
    );
    // A toggle row announces what it is — a checkbox that goes on and off
    // on its own, or one choice of a mutually exclusive group — and whether
    // it is checked, as the Web twin's `menuitemcheckbox` /
    // `menuitemradio` + `aria-checked` do. The role is stated here, so the
    // row under it states none (a second role would nest a plain menu item
    // inside this one).
    return CoUISemantics(
      role: isCheckbox ? .menuItemCheckbox : .menuItemRadio,
      checked: checked,
      enabled: !item.disabled,
      child: MenuRowScope(rowRole: null, child: row),
    );
  }

  /// A group boundary inside `role="menu"`/`role="menubar"` — the ARIA
  /// APG menu pattern's `role="separator"` between item groups
  /// (`CoreSemanticRole.separator`'s ARIA spelling, non-focusable
  /// variant). `semantic: true` is what turns that on; a bare `Divider`
  /// used outside a `Menu` stays decorative and silent to assistive
  /// tech.
  Widget _buildDivider() {
    return Padding(
      padding: style.dividerPadding,
      child: Divider(
        orientation: vertical ? .horizontal : .vertical,
        dividerStyle: style.dividerStyle,
        semantic: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (item.kind) {
      .label => _buildLabelEntry(),
      .action => _buildActionEntry(),
      .checkbox => _buildToggleEntry(
        checked: item.checked,
        mark: LucideIcons.check,
      ),
      .radio => _buildToggleEntry(
        checked: item.selected,
        // The glyph is the entry's statement, not what makes it a radio:
        // the kind above does.
        mark: item.radioMark.icon,
      ),
      .divider => _buildDivider(),
      .gap => Gap(gapStyle: CoreGapStyle(size: item.gapSize)),
    };
  }
}

/// Chain sugar for merging a [CoreMenuStyle] patch into
/// [Menu.menuStyle] without hand-reconstructing every field. Mirrors
/// the Web `Menu.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenuStyle.merge` right-side-wins semantics).
extension MenuStyleChain on Menu {
  /// Returns a copy of this [Menu] with [patch] merged into [menuStyle]
  /// (patch fields win on conflict).
  Menu withStyle(CoreMenuStyle patch) =>
      copyWith(menuStyle: (menuStyle ?? const CoreMenuStyle()).merge(patch));
}
