import 'package:coui_flutter/coui_flutter.dart';

/// A field-shaped trigger for the app's search at the top of a [Sidebar] —
/// a search glyph, a placeholder, and the shortcut as a composed [Kbd].
///
/// It is a button, not an input: pressing it hands off to the search
/// surface the app owns. The placeholder is its accessible name.
///
/// ```dart
/// SidebarSearch(
///   placeholder: '검색',
///   shortcut: const ['⌘', 'K'],
///   onPressed: () {},
/// )
/// ```
class SidebarSearch extends StatefulWidget
    implements CoreSidebarSearchContract<Widget> {
  /// Creates a [SidebarSearch].
  const SidebarSearch({
    required this.placeholder,
    super.key,
    this.shortcut,
    this.onPressed,
    this.sidebarSearchStyle,
  });

  @override
  final String placeholder;

  @override
  final List<String>? shortcut;

  @override
  final VoidCallback? onPressed;

  @override
  final CoreSidebarSearchStyle? sidebarSearchStyle;

  /// Returns a copy with the given fields replaced.
  SidebarSearch copyWith({
    Key? key,
    String? placeholder,
    List<String>? shortcut,
    VoidCallback? onPressed,
    CoreSidebarSearchStyle? sidebarSearchStyle,
  }) {
    return SidebarSearch(
      key: key ?? this.key,
      placeholder: placeholder ?? this.placeholder,
      shortcut: shortcut ?? this.shortcut,
      onPressed: onPressed ?? this.onPressed,
      sidebarSearchStyle: sidebarSearchStyle ?? this.sidebarSearchStyle,
    );
  }

  @override
  State<SidebarSearch> createState() => _SidebarSearchState();
}

class _SidebarSearchState extends State<SidebarSearch> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

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

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSidebarSearch(
      context,
      sidebarSearchStyle: widget.sidebarSearchStyle,
    );
    final enabled = widget.onPressed != null;
    final wash = !enabled
        ? null
        : _pressed
        ? resolved.pressedWashColor
        : _focused
        ? resolved.focusWashColor
        : _hovered
        ? resolved.hoverWashColor
        : null;
    final shortcut = widget.shortcut;

    final box = Container(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
        border: Border.all(
          color: resolved.borderColor,
          width: resolved.borderWidth,
        ),
      ),
      child: Stacks(
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
          Padding(
            padding: resolved.padding,
            child: Row(
              spacing: resolved.contentSpacing,
              children: [
                Icon(LucideIcons.search, iconStyle: resolved.iconStyle),
                Expanded(
                  child: Text(
                    widget.placeholder,
                    style: resolved.placeholderTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (shortcut != null && shortcut.isNotEmpty)
                  ExcludeSemantics(
                    child: Kbd(keys: shortcut, kbdStyle: resolved.kbdStyle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return MergeSemantics(
      child: Clickable(
        onPressed: widget.onPressed,
        onHover: _handleHover,
        onFocus: _handleFocus,
        onPressedChange: _handlePressedChange,
        enabled: enabled,
        clickableStyle: resolved.clickableStyle,
        child: box,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarSearchStyle] patch into
/// [SidebarSearch.sidebarSearchStyle]. Mirrors the Web extension.
extension SidebarSearchStyleChain on SidebarSearch {
  /// Sets the background paint and preserves the other style fields.
  SidebarSearch backgroundColor(CoreColor value) =>
      withStyle(CoreSidebarSearchStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged into [sidebarSearchStyle] (patch
  /// fields win on conflict).
  SidebarSearch withStyle(CoreSidebarSearchStyle patch) => copyWith(
    sidebarSearchStyle: (sidebarSearchStyle ?? const CoreSidebarSearchStyle())
        .merge(patch),
  );
}
