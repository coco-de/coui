import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';

/// Command palette — a searchable, keyboard-driven list of grouped
/// commands: a search field, an optional scope-chip row, grouped rows
/// with a fill-marked active row, and a keyboard-hint footer.
///
/// Three shapes ([presentation]) and a density ladder ([size]) cover a
/// page-embedded panel, a dialog and a fullscreen (touch) palette from one
/// component. The shape decides chrome and bounds only — a `dialog` palette
/// is placed inside `Dialog` by the caller, a `fullscreen` one is pushed as
/// a route; scrim and modality are the host's.
///
/// Keyboard: Arrow Up / Down move the active row, Arrow Left / Right move
/// the scope, Enter selects, Escape calls [onDismiss], Home / End jump.
/// Focus stays on the search field throughout — rows are never focus
/// targets, the shared active fill is the only cursor.
///
/// Semantic props (`presentation` / `size` / data / callbacks) stay flat;
/// every piece of chrome flows through the single [commandStyle] slot.
class Command extends StatefulWidget implements CoreCommandContract<Widget> {
  /// Creates a command palette.
  const Command({
    required this.groups,
    this.variant = CoreCommandVariant.defaultVariant,
    this.presentation = CoreCommandPresentation.defaultPresentation,
    this.size = CoreCommandSize.defaultSize,
    this.scopes = const [],
    this.scope,
    this.placeholder,
    this.query = '',
    this.emptyLabel,
    this.emptyDescription,
    this.emptyIcon,
    this.emptyAction,
    this.autofocus = true,
    this.showFooter,
    this.loopNavigation = CoreCommandContract.defaultLoopNavigation,
    this.onQueryChanged,
    this.onScopeChanged,
    this.onSelect,
    this.onDismiss,
    this.commandStyle,
    super.key,
  });

  @override
  final CoreCommandVariant variant;

  @override
  final CoreCommandPresentation presentation;

  @override
  final CoreCommandSize size;

  @override
  final List<CoreCommandGroup<Widget>> groups;

  @override
  final List<CoreCommandScope> scopes;

  @override
  final String? scope;

  @override
  final String? placeholder;

  @override
  final String query;

  @override
  final String? emptyLabel;

  @override
  final String? emptyDescription;

  @override
  final Widget? emptyIcon;

  @override
  final Widget? emptyAction;

  @override
  final bool autofocus;

  @override
  final bool? showFooter;

  @override
  final bool loopNavigation;

  @override
  final void Function(String)? onQueryChanged;

  @override
  final void Function(String?)? onScopeChanged;

  @override
  final void Function(String)? onSelect;

  @override
  final void Function()? onDismiss;

  @override
  final CoreCommandStyle? commandStyle;

  /// Returns a copy with the supplied fields overridden.
  Command copyWith({
    Key? key,
    List<CoreCommandGroup<Widget>>? groups,
    CoreCommandVariant? variant,
    CoreCommandPresentation? presentation,
    CoreCommandSize? size,
    List<CoreCommandScope>? scopes,
    String? scope,
    String? placeholder,
    String? query,
    String? emptyLabel,
    String? emptyDescription,
    Widget? emptyIcon,
    Widget? emptyAction,
    bool? autofocus,
    bool? showFooter,
    bool? loopNavigation,
    void Function(String)? onQueryChanged,
    void Function(String?)? onScopeChanged,
    void Function(String)? onSelect,
    void Function()? onDismiss,
    CoreCommandStyle? commandStyle,
  }) {
    return Command(
      key: key ?? this.key,
      groups: groups ?? this.groups,
      variant: variant ?? this.variant,
      presentation: presentation ?? this.presentation,
      size: size ?? this.size,
      scopes: scopes ?? this.scopes,
      scope: scope ?? this.scope,
      placeholder: placeholder ?? this.placeholder,
      query: query ?? this.query,
      emptyLabel: emptyLabel ?? this.emptyLabel,
      emptyDescription: emptyDescription ?? this.emptyDescription,
      emptyIcon: emptyIcon ?? this.emptyIcon,
      emptyAction: emptyAction ?? this.emptyAction,
      autofocus: autofocus ?? this.autofocus,
      showFooter: showFooter ?? this.showFooter,
      loopNavigation: loopNavigation ?? this.loopNavigation,
      onQueryChanged: onQueryChanged ?? this.onQueryChanged,
      onScopeChanged: onScopeChanged ?? this.onScopeChanged,
      onSelect: onSelect ?? this.onSelect,
      onDismiss: onDismiss ?? this.onDismiss,
      commandStyle: commandStyle ?? this.commandStyle,
    );
  }

  @override
  State<Command> createState() => _CommandState();
}

class _CommandState extends State<Command> {
  late final TextEditingController _controller;
  final FocusNode _searchFocus = FocusNode();

  /// Index into the flattened list of enabled, currently-visible items.
  int _highlightedIndex = 0;

  /// The row under the pointer, if any — the hover wash. Hover also moves
  /// [_highlightedIndex] (cmdk: the pointer and the arrow keys share one
  /// cursor), so a hovered row is normally active *and* hovered.
  int? _hoveredIndex;

  /// The row being pressed — the pressed wash.
  int? _pressedIndex;

  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  bool _inScope(CoreCommandGroup<Widget> group) =>
      widget.scope == null ||
      group.scope == null ||
      group.scope == widget.scope;

  List<CoreCommandGroup<Widget>> _visibleGroups() {
    final result = <CoreCommandGroup<Widget>>[];
    for (final group in widget.groups) {
      if (!_inScope(group)) continue;
      final items = group.items
          .where((i) => i.matchesQuery(widget.query))
          .toList();
      if (items.isNotEmpty) {
        result.add(
          CoreCommandGroup(
            items: items,
            heading: group.heading,
            scope: group.scope,
          ),
        );
      }
    }
    return result;
  }

  List<CoreCommandItem<Widget>> _navigableItems(
    List<CoreCommandGroup<Widget>> visible,
  ) {
    return [
      for (final group in visible) ...group.items.where((i) => i.enabled),
    ];
  }

  void _handleQueryChanged(String value) {
    // Reset to the first item (not "none") — cmdk keeps the first result
    // highlighted so Enter always has a target.
    setState(() => _highlightedIndex = 0);
    widget.onQueryChanged?.call(value);
  }

  void _moveHighlight(int delta, int navigableCount) {
    if (navigableCount == 0) return;
    setState(() {
      final next = _highlightedIndex + delta;
      _highlightedIndex = widget.loopNavigation
          ? (next % navigableCount + navigableCount) % navigableCount
          : next.clamp(0, navigableCount - 1);
    });
    // Post-frame — the target's `GlobalKey` is attached during the
    // rebuild `setState` just scheduled, not synchronously here.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollHighlightedIntoView(),
    );
  }

  void _jumpHighlight(int index, int navigableCount) {
    if (navigableCount == 0) return;
    setState(() => _highlightedIndex = index.clamp(0, navigableCount - 1));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollHighlightedIntoView(),
    );
  }

  void _scrollHighlightedIntoView() {
    final target = _itemKeys[_highlightedIndex]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target);
  }

  void _activateHighlighted(List<CoreCommandItem<Widget>> navigable) {
    if (_highlightedIndex < 0 || _highlightedIndex >= navigable.length) {
      return;
    }
    widget.onSelect?.call(navigable[_highlightedIndex].value);
  }

  /// The scope ring: `null` (all) followed by every declared scope. Arrow
  /// Left / Right walk it and stop at the ends; the query is untouched —
  /// narrowing the range is a second action, the words typed are the first.
  void _moveScope(int delta) {
    if (widget.scopes.isEmpty) return;
    final ring = <String?>[null, ...widget.scopes.map((s) => s.value)];
    final at = ring.indexOf(widget.scope);
    final next = (at + delta).clamp(0, ring.length - 1);
    if (next == at) return;
    _selectScope(ring[next]);
  }

  void _selectScope(String? value) {
    setState(() => _highlightedIndex = 0);
    widget.onScopeChanged?.call(value);
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    List<CoreCommandItem<Widget>> navigable,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return .ignored;
    }
    final key = event.logicalKey;
    if (key == .arrowDown) {
      _moveHighlight(1, navigable.length);
      return .handled;
    }
    if (key == .arrowUp) {
      _moveHighlight(-1, navigable.length);
      return .handled;
    }
    if (key == .arrowRight && widget.scopes.isNotEmpty) {
      _moveScope(1);
      return .handled;
    }
    if (key == .arrowLeft && widget.scopes.isNotEmpty) {
      _moveScope(-1);
      return .handled;
    }
    if (key == .home) {
      _jumpHighlight(0, navigable.length);
      return .handled;
    }
    if (key == .end) {
      _jumpHighlight(navigable.length - 1, navigable.length);
      return .handled;
    }
    if (key == .enter) {
      _activateHighlighted(navigable);
      return .handled;
    }
    if (key == .escape && widget.onDismiss != null) {
      widget.onDismiss!();
      return .handled;
    }
    return .ignored;
  }

  bool get _showFooter =>
      widget.showFooter ??
      CoreCommandContract.defaultShowFooterFor(widget.presentation);

  Widget _buildHeader(ResolvedCommand resolved) {
    final back = widget.presentation == .fullscreen && widget.onDismiss != null;
    return SizedBox(
      height: resolved.searchInputHeight,
      child: Padding(
        padding: resolved.searchPadding,
        child: Row(
          children: [
            if (back) ...[
              // The fullscreen shape's way out — the host has no chrome of
              // its own to put a close affordance on.
              Button(
                variant: .plain,
                shape: .square,
                size: widget.size.toComponentSize(),
                onPressed: widget.onDismiss,
                child: Icon(
                  LucideIcons.arrowLeft,
                  iconStyle: resolved.backIconStyle,
                ),
              ),
              Gap(gapStyle: resolved.searchGapStyle),
            ] else ...[
              Icon(LucideIcons.search, iconStyle: resolved.searchIconStyle),
              Gap(gapStyle: resolved.searchGapStyle),
            ],
            Expanded(
              // Part of this composite: walled off from the enclosing
              // `FormField`, which is shown the composite's own value.
              child: Data<FormFieldHandle>.boundary(
                child: TextField(
                  textFieldStyle: resolved.searchFieldStyle,
                  onChanged: _handleQueryChanged,
                  autofocus: widget.autofocus,
                  size: widget.size.toComponentSize(),
                  variant: .plain,
                  hintText:
                      widget.placeholder ??
                      CoUILocalizations.of(context).commandSearch,
                  controller: _controller,
                  focusNode: _searchFocus,
                ),
              ),
            ),
            if (widget.presentation == .dialog && widget.onDismiss != null) ...[
              // The dialog's way out, named where the eye already is — the
              // same `esc` cap the footer composes.
              Gap(gapStyle: resolved.searchGapStyle),
              Kbd(keys: const ['esc'], kbdStyle: resolved.kbdStyle),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScopes(ResolvedCommand resolved) {
    final all = CoUILocalizations.of(context).commandScopeAll;
    return Padding(
      padding: resolved.scopePadding,
      child: Wrap(
        spacing: resolved.scopeSpacing,
        runSpacing: resolved.scopeSpacing,
        children: [
          _buildScopeChip(resolved, label: all, value: null),
          for (final s in widget.scopes)
            _buildScopeChip(resolved, label: s.label, value: s.value),
        ],
      ),
    );
  }

  Widget _buildScopeChip(
    ResolvedCommand resolved, {
    required String label,
    required String? value,
  }) {
    final selected = widget.scope == value;
    // The chip language is `Chip`'s own M3 model — at the quiet (`low`)
    // register a selected chip is the `primaryContainer` tint with no
    // border, an unselected one is surface with an outline. Command opens the
    // slot and does not restate the chip; it asks for the quiet register on
    // both so a selected scope never outweighs the search field above it.
    return Chip(
      label: label,
      size: widget.size.toChipSize(),
      chipColor: .primary,
      selected: selected,
      emphasis: .low,
      onTap: () => _selectScope(value),
      chipStyle: resolved.scopeChipStyle,
    );
  }

  Widget _buildHeading(ResolvedCommand resolved, String heading) {
    return Padding(
      padding: resolved.headingPadding,
      child: Text(heading, style: resolved.headingTextStyle),
    );
  }

  Widget _buildItem(
    ResolvedCommand resolved,
    CoreCommandItem<Widget> item,
    bool active,
    int navIndex,
  ) {
    final enabled = item.enabled;
    final hovered = enabled && _hoveredIndex == navIndex;
    final pressed = enabled && _pressedIndex == navIndex;
    final twoLine = item.overline != null;

    final iconColor = !enabled
        ? resolved.itemDisabledForegroundColor
        : active
        ? resolved.itemActiveIconColor
        : resolved.itemIconColor;

    final Widget text;
    if (twoLine) {
      text = Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text(
            item.overline!,
            style: enabled
                ? resolved.overlineTextStyle
                : resolved.overlineDisabledTextStyle,
          ),
          Text(
            item.label,
            style: enabled
                ? resolved.itemTitleTextStyle
                : resolved.itemTitleDisabledTextStyle,
          ),
        ],
      );
    } else {
      text = Text(
        item.label,
        style: enabled
            ? resolved.itemLabelTextStyle
            : resolved.itemLabelDisabledTextStyle,
      );
    }

    final row = Row(
      children: [
        if (item.icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(
              size: resolved.itemIconStyle.size,
              color: iconColor,
            ),
            child: item.icon!,
          ),
          Gap(gapStyle: resolved.itemGapStyle),
        ],
        Expanded(child: text),
        if (item.shortcut != null) ...[
          Gap(gapStyle: resolved.itemGapStyle),
          Text(
            item.shortcut!,
            style: enabled
                ? resolved.shortcutTextStyle
                : resolved.shortcutDisabledTextStyle,
          ),
        ],
      ],
    );

    // Three fills, one select: the active fill, then a wash over whatever
    // is underneath — pressed outranks hover. Disabled rows take none.
    final fill = enabled && active
        ? resolved.itemHighlightColor
        : resolved.itemHighlightColor.withValues(alpha: 0);
    final wash = !enabled
        ? null
        : pressed
        ? resolved.itemPressedColor
        : hovered
        ? resolved.itemHoverColor
        : null;

    final padded = AnimatedContainer(
      constraints: BoxConstraints(minHeight: resolved.itemMinHeight),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: resolved.itemBorderRadius,
      ),
      duration: resolved.highlightDuration,
      curve: resolved.curve,
      child: Stacks(
        children: [
          if (wash != null)
            Position.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: wash,
                  borderRadius: resolved.itemBorderRadius,
                ),
              ),
            ),
          Padding(
            padding: resolved.itemPadding,
            child: Center(child: row),
          ),
        ],
      ),
    );

    if (!enabled) return padded;

    // The per-row Clickable owns tap / cursor / press feedback; focus and
    // arrow navigation stay on the palette-level `Focus`. `focusOutline:
    // false` — rows are not focus targets, the active fill is the only
    // cursor (`aria-activedescendant` on Web). That cursor reaches a reader
    // as the row's `selected` flag — the Web twin states the same row as
    // `aria-selected="true"`, and a palette row has no other selection for
    // the flag to mean.
    final itemKey = _itemKeys[navIndex] ?? GlobalKey();
    // `_itemKeys` is a State-lifetime GlobalKey memo cache, not data; a
    // fresh Map every build would defeat `ensureVisible`'s need for a key
    // already attached to a live Element when the post-frame callback in
    // `_moveHighlight` runs.
    _itemKeys[navIndex] = itemKey;

    return Clickable(
      key: itemKey,
      onPressed: () => widget.onSelect?.call(item.value),
      // Hover moves the shared cursor (cmdk) and paints the hover wash.
      onHover: (hovered) {
        setState(() {
          _hoveredIndex = hovered
              ? navIndex
              : (_hoveredIndex == navIndex ? null : _hoveredIndex);
          if (hovered) _highlightedIndex = navIndex;
        });
      },
      onTapDown: (_) => setState(() => _pressedIndex = navIndex),
      onTapUp: (_) => setState(() => _pressedIndex = null),
      onTapCancel: () => setState(() => _pressedIndex = null),
      focusOutline: false,
      semanticsSelected: active,
      clickableStyle: resolved.itemClickableStyle,
      child: padded,
    );
  }

  Widget _buildEmpty(ResolvedCommand resolved) {
    final l10n = CoUILocalizations.of(context);
    // An `EmptyState` centres itself in whatever height it is given, so one
    // under the list region's loose bound took all of it. Unbounded, it is as
    // tall as its content and its floor — the Web's `min-height` — and where
    // the region is tight (fullscreen) the box is that height and the stack
    // sits in the middle of it.
    return UnconstrainedBox(
      constrainedAxis: .horizontal,
      child: Padding(
        padding: resolved.emptyPadding,
        child: EmptyState(
          variant: .compact,
          title: Text(widget.emptyLabel ?? l10n.commandEmpty),
          description: Text(widget.emptyDescription ?? l10n.commandEmptyHint),
          icon: widget.emptyIcon,
          action: widget.emptyAction,
          emptyStateStyle: resolved.emptyStateStyle,
        ),
      ),
    );
  }

  Widget _buildResults(
    ResolvedCommand resolved,
    List<CoreCommandItem<Widget>> navigable,
    List<CoreCommandGroup<Widget>> visible,
  ) {
    final Widget body;
    if (visible.isEmpty) {
      body = _buildEmpty(resolved);
    } else {
      final rows = <Widget>[];
      final filtering = widget.query.trim().isNotEmpty;
      for (final (groupIndex, group) in visible.indexed) {
        // Dividers are structure, not results — hidden while a query is
        // filtering so they do not float between surviving rows.
        if (groupIndex > 0 && !filtering) rows.add(const Divider());
        if (group.heading != null) {
          rows.add(_buildHeading(resolved, group.heading!));
        }
        for (final item in group.items) {
          final navIndex = navigable.indexOf(item);
          final active = item.enabled && navIndex == _highlightedIndex;
          rows.add(_buildItem(resolved, item, active, navIndex));
        }
      }
      body = SingleChildScrollView(
        padding: resolved.listPadding,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: resolved.listSpacing,
          children: rows,
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: resolved.listMinHeight,
        // The list's ceiling is where its rows start to scroll. An empty
        // state does not scroll: it is as tall as it needs and no shorter
        // than the floor, as the Web's `min-height` is. Under the ceiling its
        // centring took the whole range — 320 where the Web draws 240.
        maxHeight: visible.isEmpty ? double.infinity : resolved.listMaxHeight,
      ),
      child: body,
    );
  }

  Widget _buildFooter(ResolvedCommand resolved) {
    final l10n = CoUILocalizations.of(context);
    final hintStyle = resolved.footerTextStyle;
    Widget cap(IconName icon) => Kbd.icon(
      keyContent: Icon(icon, iconStyle: resolved.footerKbdIconStyle),
      kbdStyle: resolved.kbdStyle,
    );
    return ColoredBox(
      color: resolved.footerBackgroundColor,
      child: Padding(
        padding: resolved.footerPadding,
        child: Row(
          spacing: resolved.footerSpacing,
          children: [
            cap(LucideIcons.arrowUp),
            cap(LucideIcons.arrowDown),
            Flexible(child: Text(l10n.commandMove, style: hintStyle)),
            if (widget.scopes.isNotEmpty) ...[
              cap(LucideIcons.arrowLeft),
              cap(LucideIcons.arrowRight),
              Flexible(child: Text(l10n.commandMoveScope, style: hintStyle)),
            ],
            cap(LucideIcons.cornerDownLeft),
            Flexible(child: Text(l10n.commandActivate, style: hintStyle)),
            // A dialog names Escape on its search row instead.
            if (widget.onDismiss != null && widget.presentation != .dialog) ...[
              const Spacer(),
              Kbd(keys: const ['esc'], kbdStyle: resolved.kbdStyle),
              Flexible(child: Text(l10n.commandDismiss, style: hintStyle)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(Command oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCommand(
      context,
      variant: widget.variant,
      presentation: widget.presentation,
      size: widget.size,
      commandStyle: widget.commandStyle,
    );

    final visible = _visibleGroups();
    final navigable = _navigableItems(visible);
    final fullscreen = widget.presentation == .fullscreen;

    final panel = OutlinedContainer(
      containerStyle: resolved.panelContainerStyle,
      child: Column(
        mainAxisSize: fullscreen ? .max : .min,
        crossAxisAlignment: .stretch,
        children: [
          _buildHeader(resolved),
          if (widget.scopes.isNotEmpty) _buildScopes(resolved),
          const Divider(),
          Flexible(
            fit: fullscreen ? .tight : .loose,
            child: _buildResults(resolved, navigable, visible),
          ),
          if (_showFooter) ...[const Divider(), _buildFooter(resolved)],
        ],
      ),
    );

    return Focus(
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, navigable),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: resolved.panelMinWidth,
          maxWidth: resolved.panelMaxWidth,
        ),
        child: panel,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreCommandStyle] patch into
/// [Command.commandStyle] without hand-reconstructing every field.
/// Mirrors the Web `Command.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCommandStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Command(groups: groups).withStyle(
///   CoreCommandStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// )
/// ```
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
/// sets [CoreCommandStyle.borderRadius] and `.primary` sets
/// [CoreCommandStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Command(groups: groups).radius4.surface
/// ```
extension CommandStyleChain on Command {
  /// Sets the border color.
  Command borderColor(CoreColor value) =>
      withStyle(CoreCommandStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Command borderWidth(double value) =>
      withStyle(CoreCommandStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  Command backgroundColor(CoreColor value) =>
      withStyle(CoreCommandStyle(backgroundColor: value));

  /// Returns a copy of this [Command] with [patch] merged into
  /// [commandStyle] (patch fields win on conflict).
  Command withStyle(CoreCommandStyle patch) => copyWith(
    commandStyle: (commandStyle ?? const CoreCommandStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Command get radius0 =>
      withStyle(const CoreCommandStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Command get radius2 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Command get radius4 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Command get radius6 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Command get radius8 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Command get radius10 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Command get radius12 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Command get radius14 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Command get radius16 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Command get radius20 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Command get radius24 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Command get radius28 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Command get radius32 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Command get radius36 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Command get radius40 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Command get radius48 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Command get radius56 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Command get radius64 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Command get radius9999 => withStyle(
    const CoreCommandStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Command get primary => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Command get secondary => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Command get tertiary => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Command get surface => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Command get surfaceContainer => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Command get error => withStyle(
    const CoreCommandStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Command get success => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Command get warning => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Command get info => withStyle(
    const CoreCommandStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Command get outline => withStyle(
    const CoreCommandStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Command get transparent => withStyle(
    const CoreCommandStyle(backgroundColor: .transparent),
  );
}
