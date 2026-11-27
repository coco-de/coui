import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/menu/menu_item/menu_glide.dart';
import 'package:flutter/scheduler.dart';

/// One interactive row of a menu — the surface `Menu`, `DropdownMenu`,
/// `ContextMenu`, `Menubar` and `Select` all place, drawn once here so the
/// five agree.
///
/// Anatomy, start to end: `[ mark ] [ leading ] [ label / description ]
/// [ shortcut | chevron ] [ trailing ]`, one
/// [CoreMenuItemStyle.contentGapStyle] between each seat. A [description]
/// makes the row grow past its minimum height and top-aligns the two lines;
/// [hasSubmenu] draws the chevron where the [shortcut] would sit.
///
/// Drawn as `Clickable` + `Text` + `Icon` + `Gap`, not as a `Button`: a
/// menu row's accessibility contract is different in kind — a disabled
/// row stays reachable by keyboard (inert, announced as disabled) and the
/// role is `menuItem`, not `button`. The row paints its own state layer,
/// the way `Command`'s rows do: the foreground washed over the fill at
/// [CoreMenuItemStyle.stateLayer]'s hover / focus / pressed weight.
///
/// ```dart
/// MenuItem(
///   label: const Text('Rename'),
///   shortcut: const Text('F2'),
///   leading: const Icon(LucideIcons.pencil),
///   onPressed: () {},
/// )
/// ```
///
/// The Web `MenuItem` shares the same parameter names and order.
class MenuItem extends StatefulWidget implements CoreMenuItemContract<Widget> {
  /// Creates a [MenuItem].
  const MenuItem({
    required this.label,
    super.key,
    this.size = CoreMenuItemSize.defaultSize,
    this.tone = CoreMenuItemTone.defaultTone,
    this.description,
    this.shortcut,
    this.leading,
    this.trailing,
    this.mark,
    this.reserveMark = false,
    this.hasSubmenu = false,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.menuItemStyle,
  });

  @override
  final Widget label;

  @override
  final CoreMenuItemSize size;

  @override
  final CoreMenuItemTone tone;

  @override
  final Widget? description;

  @override
  final Widget? shortcut;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final Widget? mark;

  @override
  final bool reserveMark;

  @override
  final bool hasSubmenu;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreMenuItemStyle? menuItemStyle;

  /// Returns a copy of this [MenuItem] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MenuItem copyWith({
    Key? key,
    void Function()? onPressed,
    Widget? label,
    CoreMenuItemSize? size,
    CoreMenuItemTone? tone,
    Widget? description,
    Widget? shortcut,
    Widget? leading,
    Widget? trailing,
    Widget? mark,
    bool? reserveMark,
    bool? hasSubmenu,
    bool? selected,
    bool? enabled,
    CoreMenuItemStyle? menuItemStyle,
  }) {
    return MenuItem(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      label: label ?? this.label,
      size: size ?? this.size,
      tone: tone ?? this.tone,
      description: description ?? this.description,
      shortcut: shortcut ?? this.shortcut,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      mark: mark ?? this.mark,
      reserveMark: reserveMark ?? this.reserveMark,
      hasSubmenu: hasSubmenu ?? this.hasSubmenu,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      menuItemStyle: menuItemStyle ?? this.menuItemStyle,
    );
  }

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> implements MenuGlideRow {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  /// Whether a finger that opened the menu and is still down is on this row
  /// (see [MenuGlideScope]). It reads as a press: the finger is down on the
  /// row, which is what the press weight of the state layer is for.
  bool _glided = false;
  MenuGlideRegistry? _glideRegistry;

  bool get _enabled => widget.enabled ?? (widget.onPressed != null);

  /// Whether the row wears the pressed look: pressed by a pointer on it, or
  /// by a finger gliding over it.
  bool get _pressedLook => _pressed || _glided;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = MenuGlideScope.maybeOf(context);
    if (identical(registry, _glideRegistry)) return;

    _glideRegistry?.remove(this);
    _glideRegistry = registry?..add(this);
  }

  @override
  void dispose() {
    _glideRegistry?.remove(this);
    super.dispose();
  }

  @override
  Rect? get glideBox => menuGlideBoxOf(context);

  @override
  bool get glideEnabled => _enabled;

  @override
  void glideHighlight({required bool highlighted}) {
    if (!mounted || _glided == highlighted) return;

    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() => _glided = highlighted);

      return;
    }
    // Asked for from inside a build (a host's `didUpdateWidget` switching the
    // glide off): the framework refuses a rebuild of a row that is not below
    // the caller, so the row takes the state now and repaints after the frame.
    _glided = highlighted;
    binding.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void glideActivate() {
    if (_enabled) widget.onPressed?.call();
  }

  void _handleHover(bool hovered) {
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _handleFocus(bool focused) {
    if (_focused == focused) return;
    setState(() => _focused = focused);
  }

  void _handlePressedChange(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  /// Whether the pointer or the keyboard is on an enabled, unselected row —
  /// the state the active bundles speak for. A selected row keeps its
  /// selected foreground and a disabled one its disabled foreground.
  bool get _isActive =>
      _enabled && !widget.selected && (_hovered || _focused || _pressedLook);

  /// Picks the bundle for the row's semantic state — disabled outranks
  /// selected, so a disabled row never draws the selected foreground, and
  /// both outrank the active state.
  T _select<T>({
    required T rest,
    required T selected,
    required T disabled,
    required T active,
  }) {
    if (!_enabled) return disabled;
    if (widget.selected) return selected;
    if (_isActive) return active;
    return rest;
  }

  /// The fill a tone states for its active state, or `null` when the tone
  /// is washed instead (or the row is selected or disabled). Pressed
  /// outranks focus, focus outranks hover.
  Color? _activeFill(ResolvedMenuItem resolved) {
    if (!_isActive) return null;
    return _pressedLook ? resolved.pressedFillColor : resolved.hoverFillColor;
  }

  /// The wash over the fill, or `null` at rest. Pressed outranks focus,
  /// focus outranks hover — the ramp is read strongest-first. A disabled
  /// row takes none: it is reachable, not responsive. An unselected row of a
  /// tone that states an active fill takes none either: the fill replaces it.
  Color? _wash(ResolvedMenuItem resolved) {
    if (!_enabled) return null;
    final onSelected = widget.selected;
    if (!onSelected && resolved.hoverFillColor != null) return null;
    if (_pressedLook) {
      return onSelected ? resolved.selectedPressedColor : resolved.pressedColor;
    }
    if (_focused) {
      return onSelected ? resolved.selectedFocusColor : resolved.focusColor;
    }
    if (_hovered) {
      return onSelected ? resolved.selectedHoverColor : resolved.hoverColor;
    }
    return null;
  }

  /// The mark seat: the caller's glyph, the reserved column, or nothing.
  Widget? _buildMark(ResolvedMenuItem resolved) {
    final mark = widget.mark;
    if (mark != null) {
      return IconTheme.merge(
        data: _select(
          rest: resolved.markIconTheme,
          selected: resolved.selectedMarkIconTheme,
          disabled: resolved.disabledMarkIconTheme,
          active: resolved.activeMarkIconTheme,
        ),
        child: mark,
      );
    }
    if (!widget.reserveMark) return null;
    // The glyph's footprint without the glyph — a bounded empty box, so a
    // toggle group's labels line up whether each row is on or off.
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: resolved.markSlotWidth),
    );
  }

  Widget? _buildLeading(ResolvedMenuItem resolved) {
    final leading = widget.leading;
    if (leading == null) return null;
    return IconTheme.merge(
      data: _select(
        rest: resolved.leadingIconTheme,
        selected: resolved.selectedLeadingIconTheme,
        disabled: resolved.disabledLeadingIconTheme,
        active: resolved.activeLeadingIconTheme,
      ),
      child: leading,
    );
  }

  Widget _buildText(ResolvedMenuItem resolved) {
    final label = DefaultTextStyle.merge(
      style: _select(
        rest: resolved.labelTextStyle,
        selected: resolved.selectedLabelTextStyle,
        disabled: resolved.disabledLabelTextStyle,
        active: resolved.activeLabelTextStyle,
      ),
      child: widget.label,
    );
    final description = widget.description;
    if (description == null) return label;
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        label,
        Gap(gapStyle: resolved.labelDescriptionGapStyle),
        DefaultTextStyle.merge(
          style: _select(
            rest: resolved.descriptionTextStyle,
            selected: resolved.selectedDescriptionTextStyle,
            disabled: resolved.disabledDescriptionTextStyle,
            active: resolved.activeDescriptionTextStyle,
          ),
          child: description,
        ),
      ],
    );
  }

  /// The seat after the text: the chevron when the row opens a submenu,
  /// else the shortcut hint. The two never share it.
  Widget? _buildEnd(ResolvedMenuItem resolved) {
    if (widget.hasSubmenu) {
      return Icon(
        LucideIcons.chevronRight,
        iconStyle: _select(
          rest: resolved.chevronIconStyle,
          selected: resolved.selectedChevronIconStyle,
          disabled: resolved.disabledChevronIconStyle,
          active: resolved.activeChevronIconStyle,
        ),
      );
    }
    final shortcut = widget.shortcut;
    if (shortcut == null) return null;
    return DefaultTextStyle.merge(
      style: _select(
        rest: resolved.shortcutTextStyle,
        selected: resolved.selectedShortcutTextStyle,
        disabled: resolved.disabledShortcutTextStyle,
        active: resolved.activeShortcutTextStyle,
      ),
      child: shortcut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final resolved = resolveMenuItem(
      context,
      size: widget.size,
      tone: widget.tone,
      menuItemStyle: widget.menuItemStyle,
    );

    final mark = _buildMark(resolved);
    final leading = _buildLeading(resolved);
    final end = _buildEnd(resolved);
    final trailing = widget.trailing;
    final gap = Gap(gapStyle: resolved.contentGapStyle);

    final row = Row(
      // Two lines top-align (the description model); a single line sits
      // on the row's centre.
      crossAxisAlignment: widget.description == null ? .center : .start,
      children: [
        ?mark,
        if (mark != null) gap,
        ?leading,
        if (leading != null) gap,
        Expanded(child: _buildText(resolved)),
        if (end != null) gap,
        ?end,
        if (trailing != null) gap,
        ?trailing,
      ],
    );

    final fill = widget.selected && enabled
        ? resolved.selectedBackgroundColor
        : _activeFill(resolved) ?? resolved.backgroundColor;
    final wash = _wash(resolved);

    final box = AnimatedContainer(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: resolved.borderRadius,
      ),
      duration: resolved.duration,
      curve: resolved.curve,
      child: Stacks(
        // The row's height is a floor (`minHeight`), not its content's
        // height, and the Stack's default seat is the top. Centred, the
        // content sits mid-row whenever the floor outgrows padding + content
        // (compact density, the lg row, a caller's own minimum) — the way the
        // Web row's `items-center` does.
        alignment: .centerStart,
        children: [
          if (wash != null)
            Position.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: wash,
                  borderRadius: resolved.borderRadius,
                ),
              ),
            ),
          Padding(padding: resolved.padding, child: row),
        ],
      ),
    );

    // The row stays a focus stop while disabled (WAI-ARIA menu pattern:
    // inert, not invisible to the keyboard), so `Clickable` keeps its
    // focus and cursor wiring and only the activation is withheld. The
    // disabled announcement is made through `semanticsEnabled`, and the
    // cursor says the same thing the announcement does.
    // `menuItem` is a claim about the subtree this row sits in, not about
    // the row: Flutter asserts that one has a `menu` ancestor, and ARIA
    // says the same. A row placed outside a menu — a docs preview, a
    // hand-assembled panel — is a command, and announcing it as a menu
    // item would be a claim its surroundings do not support. `Menu` marks
    // its own subtree with [MenuRowScope]; the row reads that mark rather
    // than guessing. A scope with no role means the container announces
    // the row itself (a `Select`'s `option`), so the row stays silent.
    final scope = MenuRowScope.maybeOf(context);
    final role = scope == null ? CoreSemanticRole.button : scope.rowRole;
    final clickable = Clickable(
      onPressed: enabled ? widget.onPressed : null,
      onHover: _handleHover,
      onFocus: _handleFocus,
      onPressedChange: _handlePressedChange,
      semanticsButton: false,
      semanticsEnabled: enabled,
      enableFeedback: enabled,
      mouseCursor: enabled ? null : SystemMouseCursors.forbidden,
      clickableStyle: resolved.clickableStyle,
      child: box,
    );
    if (role == null) return clickable;
    return CoUISemantics(
      role: role,
      selected: widget.selected,
      enabled: enabled,
      child: clickable,
    );
  }
}

/// Marks the subtree a menu draws its rows into.
///
/// A [MenuItem] announces itself as a menu item only inside one of
/// these. `Menu` (and any other panel that owns a `menu` / `menuBar`
/// semantics container) wraps its rows in it; the row asks
/// [encloses] rather than assuming, because the assumption is one
/// Flutter asserts on and a screen reader would repeat.
class MenuRowScope extends InheritedWidget {
  /// Creates a [MenuRowScope].
  const MenuRowScope({
    required super.child,
    super.key,
    this.rowRole = CoreSemanticRole.menuItem,
  });

  /// What a row inside this panel announces itself as. `menuItem` for a
  /// menu; `null` when the container announces its rows itself — a
  /// `Select` wraps each row in the `option` node its listbox needs, and
  /// the row must not add a second role under it (the role is the
  /// container's to state — Primer's model: `MenuItem` is a visual
  /// contract and the container injects the role).
  final CoreSemanticRole? rowRole;

  /// The scope enclosing [context], if any.
  static MenuRowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuRowScope>();

  /// Whether [context] sits inside a menu panel.
  static bool encloses(BuildContext context) => maybeOf(context) != null;

  @override
  bool updateShouldNotify(MenuRowScope oldWidget) =>
      rowRole != oldWidget.rowRole;
}

/// Chain sugar for merging a [CoreMenuItemStyle] patch into
/// [MenuItem.menuItemStyle] without hand-reconstructing every field.
/// Mirrors the Web `MenuItem.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenuItemStyle.merge` right-side-wins semantics).
extension MenuItemStyleChain on MenuItem {
  /// Sets the background paint and preserves the other style fields.
  MenuItem backgroundColor(CoreColor value) =>
      withStyle(CoreMenuItemStyle(backgroundColor: value));

  /// Returns a copy of this [MenuItem] with [patch] merged into
  /// [menuItemStyle] (patch fields win on conflict).
  MenuItem withStyle(CoreMenuItemStyle patch) => copyWith(
    menuItemStyle: (menuItemStyle ?? const CoreMenuItemStyle()).merge(patch),
  );
}
