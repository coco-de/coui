import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/util/element_scope.dart';

/// The trigger that opens a command palette — a search-shaped button an app
/// bar or a sidebar places, which calls [onPressed] when it is activated.
///
/// It looks like a search field and is not one: typing happens in the
/// `Command` the app opens from [onPressed] (usually its dialog
/// presentation), so the trigger is announced as a **button**
/// (`role="button"`) and takes one tab stop. Listening for the shortcut it
/// shows (`⌘K`) is the app's job — the trigger only draws the hint.
///
/// Anatomy, start to end: `[ leading ] [ hint ] [ shortcut ]`, one
/// [CoreCommandSearchStyle.contentGapStyle] between each seat. The hint takes
/// the remaining width and truncates. The width is the parent's — the
/// trigger fills the width it is given.
///
/// Drawn as `Clickable` + `Icon` + `Gap` rather than as a `Button`: a
/// button's face is a centred label, and this face is a start-aligned hint
/// with a key at the end. The trigger paints its own state layer the way a
/// menu row does — the state-layer colour washed over the face at
/// [CoreCommandSearchStyle.stateLayer]'s hover / focus / pressed weight.
///
/// ```dart
/// CommandSearch(
///   shortcut: const Kbd(keys: ['⌘K']),
///   onPressed: () => openCommandPalette(),
/// )
/// ```
///
/// The Flutter `CommandSearch` shares the same parameter names and order.
///
/// surface:behind — whatever the trigger is laid on: the app bar or sidebar
/// that holds it, over a body that scrolls beneath. Its box paints its own
/// fill — the resting face and the state wash — rather than composing
/// `OutlinedContainer`, so it has no primitive to inherit a material from.
///
/// surface:content — a control face in the page flow: what shows through a
/// translucent fill is the page it is laid on, not something floating over
/// it.
class CommandSearch extends UiComponent
    implements CoreCommandSearchContract<Component> {
  /// Creates a [CommandSearch].
  const CommandSearch({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.size = CoreCommandSize.defaultSize,
    this.hint,
    this.leading,
    this.shortcut,
    this.enabled,
    this.onPressed,
    this.commandSearchStyle,
  }) : super(tag: 'div');

  @override
  final CoreCommandSize size;

  @override
  final String? hint;

  @override
  final Component? leading;

  @override
  final Component? shortcut;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreCommandSearchStyle? commandSearchStyle;

  /// Whether the trigger accepts activation — the kit-wide rule: an
  /// explicit [enabled] wins, otherwise the presence of a handler decides.
  bool get _effectiveEnabled => enabled ?? (onPressed != null);

  @override
  CommandSearch copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    CoreCommandSize? size,
    String? hint,
    Component? leading,
    Component? shortcut,
    bool? enabled,
    void Function()? onPressed,
    CoreCommandSearchStyle? commandSearchStyle,
  }) => CommandSearch(
    attributes: attributes ?? componentAttributes,
    classes: classes ?? this.classes,
    css: css ?? this.css,
    eventHandlers: eventHandlers ?? this.eventHandlers,
    id: id ?? this.id,
    key: key ?? this.key,
    size: size ?? this.size,
    hint: hint ?? this.hint,
    leading: leading ?? this.leading,
    shortcut: shortcut ?? this.shortcut,
    enabled: enabled ?? this.enabled,
    onPressed: onPressed ?? this.onPressed,
    commandSearchStyle: commandSearchStyle ?? this.commandSearchStyle,
  );

  @override
  Component build(BuildContext context) {
    final enabled = _effectiveEnabled;
    // Per-instance class the wash rules key on. A class rather than the
    // element id because the composed `Clickable` claims the id for its own
    // scoped rules whenever a caller overrides the focus ring.
    final scopeClass = elementScopeId(context, prefix: 'co-command-search');
    final resolved = resolveCommandSearch(
      context,
      scopeClass: scopeClass,
      size: size,
      enabled: enabled,
      commandSearchStyle: commandSearchStyle,
    );
    final rules = resolveCommandSearchRules(
      context,
      scopeClass: scopeClass,
      enabled: enabled,
      commandSearchStyle: commandSearchStyle,
    );
    // The hint is chrome text: the active locale's palette placeholder
    // unless the caller states one — the same text the opened palette's
    // search field shows.
    final hintText = hint ?? CouiLocalizations.of(context).commandSearch;
    final gap = Gap(gapStyle: resolved.contentGapStyle);

    final seats = <Component>[
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      Component.element(
        tag: 'div',
        classes: resolved.wash.className,
        styles: resolved.wash.inlineStyles,
        children: const [],
      ),
      IconTheme(
        data: IconThemeData.fromCoreIconStyle(resolved.leadingIconStyle),
        child: leading ?? const Icon(LucideIcons.search),
      ),
      gap,
      Component.element(
        tag: 'div',
        classes: resolved.hint.className,
        styles: resolved.hint.inlineStyles,
        children: [Text(hintText)],
      ),
      if (shortcut != null) ...[gap, shortcut!],
    ];

    return Clickable(
      attributes: componentAttributes,
      classes: rootClasses(resolved.root.className),
      // The trigger's own chrome rides in on `css`: `Clickable` composes its
      // resolved styles first and the caller's `css` after, so passing the
      // trigger box here is what puts the height, insets, face and corner
      // over the generic clickable box instead of under it.
      css: Styles.combine([
        ?resolved.root.inlineStyles,
        ?this.css,
      ]),
      eventHandlers: eventHandlers,
      id: id,
      enabled: enabled,
      onPressed: onPressed,
      clickableStyle: resolved.clickableStyle,
      child: Component.fragment(seats),
    );
  }
}

/// Chain sugar for merging a [CoreCommandSearchStyle] patch into
/// [CommandSearch.commandSearchStyle] without hand-reconstructing every
/// field. Mirrors the Flutter `CommandSearch.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCommandSearchStyle.merge` right-side-wins semantics).
extension CommandSearchStyleChain on CommandSearch {
  /// Sets the background paint and preserves the other style fields.
  CommandSearch backgroundColor(CoreColor value) =>
      withStyle(CoreCommandSearchStyle(backgroundColor: value));

  /// Returns a copy of this [CommandSearch] with [patch] merged into
  /// [commandSearchStyle] (patch fields win on conflict).
  CommandSearch withStyle(CoreCommandSearchStyle patch) => copyWith(
    commandSearchStyle: (commandSearchStyle ?? const CoreCommandSearchStyle())
        .merge(patch),
  );
}
