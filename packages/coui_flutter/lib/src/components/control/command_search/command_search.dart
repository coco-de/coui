import 'package:coui_flutter/coui_flutter.dart';

/// The trigger that opens a command palette — a search-shaped button an app
/// bar or a sidebar places, which calls [onPressed] when it is activated.
///
/// It looks like a search field and is not one: typing happens in the
/// `Command` the app opens from [onPressed] (usually its dialog
/// presentation), so the trigger is announced as a **button** and takes one
/// tab stop. Listening for the shortcut it shows (`⌘K`) is the app's job —
/// the trigger only draws the hint.
///
/// Anatomy, start to end: `[ leading ] [ hint ] [ shortcut ]`, one
/// [CoreCommandSearchStyle.contentGapStyle] between each seat. The hint takes
/// the remaining width and truncates. The width is the parent's — the
/// trigger fills the width it is given, so it needs a bounded one (an
/// `Expanded`, a `SizedBox`, an app bar's centre slot).
///
/// Drawn as `Clickable` + `Icon` + `Text` + `Gap` rather than as a `Button`:
/// a button's face is a centred label, and this face is a start-aligned
/// hint with a key at the end. The trigger paints its own state layer the
/// way a menu row does — the state-layer colour washed over the face at
/// [CoreCommandSearchStyle.stateLayer]'s hover / focus / pressed weight.
///
/// ```dart
/// CommandSearch(
///   shortcut: const Kbd(keys: ['⌘K']),
///   onPressed: () => openCommandPalette(context),
/// )
/// ```
///
/// The Web `CommandSearch` shares the same parameter names and order.
///
/// surface:behind — whatever the trigger is laid on: the app bar or sidebar
/// that holds it, over a body that scrolls beneath. Its box paints its own
/// fill — the resting face and the state wash — rather than composing
/// `OutlinedContainer`, so it has no primitive to inherit a material from.
///
/// surface:content — a control face in the page flow: what shows through a
/// translucent fill is the page it is laid on, not something floating over
/// it.
class CommandSearch extends StatefulWidget
    implements CoreCommandSearchContract<Widget> {
  /// Creates a [CommandSearch].
  const CommandSearch({
    super.key,
    this.size = CoreCommandSize.defaultSize,
    this.hint,
    this.leading,
    this.shortcut,
    this.enabled,
    this.onPressed,
    this.commandSearchStyle,
  });

  @override
  final CoreCommandSize size;

  @override
  final String? hint;

  @override
  final Widget? leading;

  @override
  final Widget? shortcut;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreCommandSearchStyle? commandSearchStyle;

  /// Returns a copy of this [CommandSearch] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  CommandSearch copyWith({
    Key? key,
    CoreCommandSize? size,
    String? hint,
    Widget? leading,
    Widget? shortcut,
    bool? enabled,
    void Function()? onPressed,
    CoreCommandSearchStyle? commandSearchStyle,
  }) {
    return CommandSearch(
      key: key ?? this.key,
      size: size ?? this.size,
      hint: hint ?? this.hint,
      leading: leading ?? this.leading,
      shortcut: shortcut ?? this.shortcut,
      enabled: enabled ?? this.enabled,
      onPressed: onPressed ?? this.onPressed,
      commandSearchStyle: commandSearchStyle ?? this.commandSearchStyle,
    );
  }

  @override
  State<CommandSearch> createState() => _CommandSearchState();
}

class _CommandSearchState extends State<CommandSearch> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.enabled ?? (widget.onPressed != null);

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

  /// The wash over the face, or `null` at rest. Pressed outranks focus,
  /// focus outranks hover — the ramp is read strongest-first. A disabled
  /// trigger takes none.
  Color? _wash(ResolvedCommandSearch resolved) {
    if (!_enabled) return null;
    if (_pressed) return resolved.pressedColor;
    if (_focused) return resolved.focusColor;
    if (_hovered) return resolved.hoverColor;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final resolved = resolveCommandSearch(
      context,
      size: widget.size,
      commandSearchStyle: widget.commandSearchStyle,
    );
    // The hint is chrome text: the active locale's palette placeholder
    // unless the caller states one — the same text the opened palette's
    // search field shows.
    final hint = widget.hint ?? CoUILocalizations.of(context).commandSearch;
    final gap = Gap(gapStyle: resolved.contentGapStyle);
    final shortcut = widget.shortcut;

    final row = Row(
      children: [
        IconTheme.merge(
          data: enabled
              ? resolved.leadingIconTheme
              : resolved.disabledLeadingIconTheme,
          child: widget.leading ?? const Icon(LucideIcons.search),
        ),
        gap,
        Expanded(
          child: Text(
            hint,
            style: enabled
                ? resolved.hintTextStyle
                : resolved.disabledHintTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ),
        if (shortcut != null) ...[gap, shortcut],
      ],
    );

    final wash = _wash(resolved);
    final box = AnimatedContainer(
      height: resolved.height,
      decoration: BoxDecoration(
        color: enabled
            ? resolved.backgroundColor
            : resolved.disabledBackgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      duration: resolved.duration,
      curve: resolved.curve,
      child: Stacks(
        // The trigger's height is a ladder rung, not its content's height,
        // and the Stack's default seat is the top. Centred, the content sits
        // mid-box at every rung and density — the way the Web trigger's
        // `items-center` does. The wash is positioned, so this leaves it be.
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

    // A disabled trigger leaves the tab order, like any disabled button:
    // `Clickable` drops the focus stop and announces it disabled.
    return Clickable(
      onPressed: widget.onPressed,
      onHover: _handleHover,
      onFocus: _handleFocus,
      onPressedChange: _handlePressedChange,
      enabled: enabled,
      clickableStyle: resolved.clickableStyle,
      child: box,
    );
  }
}

/// Chain sugar for merging a [CoreCommandSearchStyle] patch into
/// [CommandSearch.commandSearchStyle] without hand-reconstructing every
/// field. Mirrors the Web `CommandSearch.withStyle` extension so both
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
