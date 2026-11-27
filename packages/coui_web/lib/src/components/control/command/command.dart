import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:universal_web/web.dart' as web;

/// Command palette — a searchable, keyboard-driven list of grouped
/// commands: a search field, an optional scope-chip row, grouped rows
/// with a fill-marked active row, and a keyboard-hint footer.
///
/// Three shapes ([presentation]) and a density ladder ([size]) cover a
/// page-embedded panel, a dialog and a fullscreen (touch) palette from one
/// component. The shape decides chrome and bounds only — a `dialog` palette
/// is placed inside `Dialog` by the caller, a `fullscreen` one is routed by
/// the caller; scrim and modality are the host's.
///
/// Keyboard: Arrow Up / Down move the active row, Arrow Left / Right move
/// the scope, Enter selects, Escape calls [onDismiss], Home / End jump.
/// DOM focus stays on the search `<input>` throughout; the active row is
/// announced through `aria-activedescendant`, and rows are never focus
/// targets.
///
/// Semantic props (`presentation` / `size` / data / callbacks) stay flat;
/// every piece of chrome flows through the single [commandStyle] slot.
///
/// surface:content — the panel is a face in the content layer: inline it
/// sits beside cards, as a dialog it is the `Dialog`'s own body, fullscreen
/// it is the page. What floats it (scrim, route) is the host's.
class Command extends UiStatefulComponent
    implements CoreCommandContract<Component> {
  /// Creates a command palette.
  const Command({
    required this.groups,
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
  });

  @override
  final CoreCommandVariant variant;

  @override
  final CoreCommandPresentation presentation;

  @override
  final CoreCommandSize size;

  @override
  final List<CoreCommandGroup<Component>> groups;

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
  final Component? emptyIcon;

  @override
  final Component? emptyAction;

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
    List<CoreCommandGroup<Component>>? groups,
    CoreCommandVariant? variant,
    CoreCommandPresentation? presentation,
    CoreCommandSize? size,
    List<CoreCommandScope>? scopes,
    String? scope,
    String? placeholder,
    String? query,
    String? emptyLabel,
    String? emptyDescription,
    Component? emptyIcon,
    Component? emptyAction,
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
      onClick: onClick ?? this.onClick,
      groups: groups ?? this.groups,
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

int _coCommandIdCounter = 0;

class _CommandState extends State<Command> {
  int _highlightedIndex = 0;

  late final String _rootId =
      component.id ?? 'coui-command-${_coCommandIdCounter++}';

  @override
  void initState() {
    super.initState();
    if (component.autofocus) {
      scheduleNextFrame(() => focusInputWithin(_rootId));
    }
  }

  bool _inScope(CoreCommandGroup<Component> group) =>
      component.scope == null ||
      group.scope == null ||
      group.scope == component.scope;

  List<CoreCommandGroup<Component>> _visibleGroups() {
    final result = <CoreCommandGroup<Component>>[];
    for (final group in component.groups) {
      if (!_inScope(group)) continue;
      final items = group.items
          .where((item) => item.matchesQuery(component.query))
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

  List<CoreCommandItem<Component>> _navigableItems(
    List<CoreCommandGroup<Component>> visible,
  ) {
    return [
      for (final group in visible) ...group.items.where((item) => item.enabled),
    ];
  }

  void _handleQueryChanged(String value) {
    setState(() => _highlightedIndex = 0);
    component.onQueryChanged?.call(value);
  }

  void _moveHighlight(int delta, int navigableCount) {
    if (navigableCount == 0) return;
    setState(() {
      final next = _highlightedIndex + delta;
      _highlightedIndex = component.loopNavigation
          ? (next % navigableCount + navigableCount) % navigableCount
          : next.clamp(0, navigableCount - 1);
    });
    scheduleNextFrame(_scrollHighlightedIntoView);
  }

  void _jumpHighlight(int index, int navigableCount) {
    if (navigableCount == 0) return;
    setState(() => _highlightedIndex = index.clamp(0, navigableCount - 1));
    scheduleNextFrame(_scrollHighlightedIntoView);
  }

  void _scrollHighlightedIntoView() {
    web.document
        .querySelector('#$_rootId [data-command-index="$_highlightedIndex"]')
        ?.scrollIntoView(
          web.ScrollIntoViewOptions(block: 'nearest', inline: 'nearest'),
        );
  }

  /// The scope ring: `null` (all) then every declared scope. Arrow Left /
  /// Right walk it and stop at the ends; the query is untouched.
  void _moveScope(int delta) {
    if (component.scopes.isEmpty) return;
    final ring = <String?>[
      null,
      ...component.scopes.map((scope) => scope.value),
    ];
    final at = ring.indexOf(component.scope);
    final next = (at + delta).clamp(0, ring.length - 1);
    if (next == at) return;
    _selectScope(ring[next]);
  }

  void _selectScope(String? value) {
    setState(() => _highlightedIndex = 0);
    component.onScopeChanged?.call(value);
  }

  void _handleKeyDown(
    web.KeyboardEvent event,
    List<CoreCommandItem<Component>> navigable,
  ) {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        _moveHighlight(1, navigable.length);
      case 'ArrowUp':
        event.preventDefault();
        _moveHighlight(-1, navigable.length);
      case 'ArrowRight':
        if (component.scopes.isNotEmpty) {
          event.preventDefault();
          _moveScope(1);
        }
      case 'ArrowLeft':
        if (component.scopes.isNotEmpty) {
          event.preventDefault();
          _moveScope(-1);
        }
      case 'Home':
        event.preventDefault();
        _jumpHighlight(0, navigable.length);
      case 'End':
        event.preventDefault();
        _jumpHighlight(navigable.length - 1, navigable.length);
      case 'Enter':
        if (_highlightedIndex >= 0 && _highlightedIndex < navigable.length) {
          event.preventDefault();
          component.onSelect?.call(navigable[_highlightedIndex].value);
        }
      case 'Escape':
        if (component.onDismiss != null) {
          event.preventDefault();
          component.onDismiss!();
        }
    }
  }

  bool get _showFooter =>
      component.showFooter ??
      CoreCommandContract.defaultShowFooterFor(component.presentation);

  String _optionId(int navIndex) => '$_rootId-option-$navIndex';

  Component _buildHeader(
    BuildContext context,
    ResolvedCommand resolved,
    List<CoreCommandItem<Component>> navigable,
  ) {
    final back =
        component.presentation == .fullscreen && component.onDismiss != null;
    return div(
      [
        if (back)
          // The fullscreen shape's way out — the host has no chrome of its
          // own to put a close affordance on.
          Button(
            variant: .plain,
            shape: .square,
            size: component.size.toComponentSize(),
            onPressed: component.onDismiss,
            attributes: {
              'aria-label': CouiLocalizations.of(context).commandDismiss,
            },
            child: Icon(
              LucideIcons.arrowLeft,
              iconStyle: resolved.backIconStyle,
            ),
          )
        else
          Icon(LucideIcons.search, iconStyle: resolved.searchIconStyle),
        Gap(gapStyle: resolved.searchGapStyle),
        Component.element(
          tag: 'div',
          classes: resolved.searchInput.className,
          styles: resolved.searchInput.inlineStyles,
          children: [
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            FormFieldHandleScope.boundary(
              child: TextField(
                textFieldStyle: resolved.searchFieldStyle,
                onChanged: _handleQueryChanged,
                attributes: {
                  'aria-autocomplete': 'list',
                  'aria-controls': '$_rootId-listbox',
                  if (navigable.isNotEmpty)
                    'aria-activedescendant': _optionId(_highlightedIndex),
                },
                onKeyDown: (event) => _handleKeyDown(event, navigable),
                placeholder: Text(
                  component.placeholder ??
                      CouiLocalizations.of(context).commandSearch,
                ),
                value: component.query,
                autofocus: component.autofocus,
                size: component.size.toComponentSize(),
                variant: .plain,
              ),
            ),
          ],
        ),
        if (component.presentation == .dialog &&
            component.onDismiss != null) ...[
          // The dialog's way out, named where the eye already is — the same
          // `esc` cap the footer composes.
          Gap(gapStyle: resolved.searchGapStyle),
          Kbd(keys: const ['esc'], kbdStyle: resolved.kbdStyle),
        ],
      ],
      classes: resolved.header.className,
      styles: resolved.header.inlineStyles,
    );
  }

  Component _buildScopes(BuildContext context, ResolvedCommand resolved) {
    final all = CouiLocalizations.of(context).commandScopeAll;
    return div(
      [
        _buildScopeChip(resolved, label: all, value: null),
        for (final scope in component.scopes)
          _buildScopeChip(
            resolved,
            label: scope.label,
            value: scope.value,
          ),
      ],
      classes: resolved.scope.className,
      styles: resolved.scope.inlineStyles,
      attributes: const {'role': 'group'},
    );
  }

  Component _buildScopeChip(
    ResolvedCommand resolved, {
    required String label,
    required String? value,
  }) {
    final selected = component.scope == value;
    // The chip language is `Chip`'s own M3 model — at the quiet (`low`)
    // register a selected chip is the `primaryContainer` tint with no
    // border, an unselected one is surface with an outline. Command opens the
    // slot and does not restate the chip; it asks for the quiet register on
    // both so a selected scope never outweighs the search field above it.
    return Chip(
      label: label,
      size: component.size.toChipSize(),
      chipColor: .primary,
      selected: selected,
      emphasis: .low,
      onTap: () => _selectScope(value),
      chipStyle: resolved.scopeChipStyle,
      attributes: {'aria-pressed': '$selected'},
    );
  }

  Component _buildEmpty(BuildContext context, ResolvedCommand resolved) {
    final l10n = CouiLocalizations.of(context);
    return div(
      [
        EmptyState(
          variant: .compact,
          title: Text(component.emptyLabel ?? l10n.commandEmpty),
          description: Text(
            component.emptyDescription ?? l10n.commandEmptyHint,
          ),
          icon: component.emptyIcon,
          action: component.emptyAction,
          emptyStateStyle: resolved.emptyStateStyle,
        ),
      ],
      classes: resolved.empty.className,
      styles: resolved.empty.inlineStyles,
    );
  }

  Component _buildResults(
    BuildContext context,
    ResolvedCommand resolved,
    List<CoreCommandGroup<Component>> visible,
    List<CoreCommandItem<Component>> navigable,
  ) {
    if (visible.isEmpty) return _buildEmpty(context, resolved);

    final rows = <Component>[];
    final filtering = component.query.trim().isNotEmpty;
    for (final (groupIndex, group) in visible.indexed) {
      // Dividers are structure, not results — hidden while a query is
      // filtering so they do not float between surviving rows.
      if (groupIndex > 0 && !filtering) rows.add(const Divider());
      final heading = group.heading;
      if (heading != null) {
        rows.add(_buildHeading(resolved, heading, groupIndex));
      }
      for (final item in group.items) {
        final navIndex = navigable.indexOf(item);
        final active = item.enabled && navIndex == _highlightedIndex;
        rows.add(_buildItem(resolved, item, active, navIndex));
      }
    }

    return div(
      rows,
      id: '$_rootId-listbox',
      classes: resolved.list.className,
      styles: resolved.list.inlineStyles,
      attributes: const {'role': 'listbox'},
    );
  }

  Component _buildHeading(
    ResolvedCommand resolved,
    String heading,
    int groupIndex,
  ) {
    return div(
      [Text(heading)],
      classes: resolved.heading.className,
      styles: resolved.heading.inlineStyles,
      attributes: {'role': 'presentation', 'data-group': '$groupIndex'},
    );
  }

  Component _buildItem(
    ResolvedCommand resolved,
    CoreCommandItem<Component> item,
    bool active,
    int navIndex,
  ) {
    final chrome = !item.enabled
        ? resolved.itemDisabled
        : active
        ? resolved.itemActive
        : resolved.itemEnabled;
    final twoLine = item.overline != null;
    final content = [
      // The wash overlay — the scoped `:hover` / `:active` rules paint it,
      // so a wash stacks over the active fill instead of replacing it.
      if (item.enabled)
        div(
          const [],
          classes: resolved.itemWash.className,
          styles: resolved.itemWash.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
        ),
      if (item.icon != null) ...[
        IconTheme(
          data: IconThemeData.fromCoreIconStyle(
            !item.enabled
                ? resolved.itemDisabledIconStyle
                : active
                ? resolved.itemActiveIconStyle
                : resolved.itemIconStyle,
          ),
          child: item.icon!,
        ),
        Gap(gapStyle: resolved.itemGapStyle),
      ],
      div(
        [
          if (twoLine) ...[
            div(
              [Text(item.overline!)],
              classes: resolved.overline.className,
              styles: resolved.overline.inlineStyles,
            ),
            div(
              [Text(item.label)],
              classes: resolved.title.className,
              styles: resolved.title.inlineStyles,
            ),
          ] else
            div(
              [Text(item.label)],
              classes: resolved.label.className,
              styles: resolved.label.inlineStyles,
            ),
        ],
        classes: resolved.text.className,
      ),
      if (item.shortcut != null) ...[
        Gap(gapStyle: resolved.itemGapStyle),
        span(
          [Text(item.shortcut!)],
          classes: resolved.shortcut.className,
          styles: resolved.shortcut.inlineStyles,
        ),
      ],
    ];

    // Disabled rows render bare — no Clickable, `pointer-events-none`,
    // never an interactive affordance (chip / tree precedent).
    if (!item.enabled) {
      return div(
        content,
        classes: chrome.className,
        styles: chrome.inlineStyles,
        attributes: const {
          'role': 'option',
          'aria-selected': 'false',
          'aria-disabled': 'true',
          'data-disabled': '',
        },
      );
    }

    // The per-row Clickable owns tap / cursor; keyboard navigation stays on
    // the search `<input>`'s `keydown`. `focusOutline: false` + `tabindex:
    // -1` — rows are not focus targets, the active fill is the cursor and
    // `aria-activedescendant` on the input announces it. The same cursor
    // is the row's `aria-selected` (through `semanticsSelected`, the
    // parameter the Flutter twin states it with).
    return Clickable(
      onPressed: () => component.onSelect?.call(item.value),
      attributes: {
        'id': _optionId(navIndex),
        'role': 'option',
        'tabindex': '-1',
        'data-command-index': '$navIndex',
      },
      classes: WebLayout.wFull,
      // Hover moves the shared cursor (cmdk); the wash itself is CSS.
      onHover: (hovered) {
        if (hovered && _highlightedIndex != navIndex) {
          setState(() => _highlightedIndex = navIndex);
        }
      },
      focusOutline: false,
      semanticsSelected: active,
      clickableStyle: resolved.itemClickableStyle,
      child: div(
        content,
        classes: chrome.className,
        styles: chrome.inlineStyles,
      ),
    );
  }

  Component _buildFooter(BuildContext context, ResolvedCommand resolved) {
    final l10n = CouiLocalizations.of(context);
    return div(
      [
        _kbd(resolved, LucideIcons.arrowUp),
        _kbd(resolved, LucideIcons.arrowDown),
        _footerLabel(resolved, l10n.commandMove),
        if (component.scopes.isNotEmpty) ...[
          _kbd(resolved, LucideIcons.arrowLeft),
          _kbd(resolved, LucideIcons.arrowRight),
          _footerLabel(resolved, l10n.commandMoveScope),
        ],
        _kbd(resolved, LucideIcons.cornerDownLeft),
        _footerLabel(resolved, l10n.commandActivate),
        // A dialog names Escape on its search row instead.
        if (component.onDismiss != null &&
            component.presentation != .dialog) ...[
          const div([], classes: WebLayout.flex1),
          Kbd(keys: const ['esc'], kbdStyle: resolved.kbdStyle),
          _footerLabel(resolved, l10n.commandDismiss),
        ],
      ],
      classes: resolved.footer.className,
      styles: resolved.footer.inlineStyles,
    );
  }

  Component _footerLabel(ResolvedCommand resolved, String label) {
    return div(
      [Text(label)],
      classes: resolved.footerLabel.className,
      styles: resolved.footerLabel.inlineStyles,
    );
  }

  Component _kbd(ResolvedCommand resolved, IconName icon) {
    return Kbd.icon(
      keyContent: Icon(icon, iconStyle: resolved.footerKbdIconStyle),
      kbdStyle: resolved.kbdStyle,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveCommand(
      context,
      variant: component.variant,
      presentation: component.presentation,
      size: component.size,
      commandStyle: component.commandStyle,
    );
    final rules = resolveCommandRules(
      context,
      scopeId: _rootId,
      variant: component.variant,
      commandStyle: component.commandStyle,
    );

    final visible = _visibleGroups();
    final navigable = _navigableItems(visible);

    return div(
      [
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        _buildHeader(context, resolved, navigable),
        if (component.scopes.isNotEmpty) _buildScopes(context, resolved),
        const Divider(),
        _buildResults(context, resolved, visible, navigable),
        if (_showFooter) ...[const Divider(), _buildFooter(context, resolved)],
      ],
      id: _rootId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': 'combobox',
        'aria-expanded': 'true',
        'aria-haspopup': 'listbox',
      },
      events: component.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Command.withStyle` extension —
/// merges a [CoreCommandStyle] patch into [Command.commandStyle] via
/// the existing [Command.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCommandStyle.merge` right-side-wins semantics).
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
