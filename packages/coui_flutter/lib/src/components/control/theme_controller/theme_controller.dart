import 'package:coui_flutter/coui_flutter.dart';

/// A unified cross-platform theme picker.
///
/// `ThemeController` renders a wrapping grid of selectable theme
/// swatches. Each swatch previews the theme's palette colours and
/// reports the picked theme name through [onThemeChanged].
///
/// Every chrome / dimensional override flows through the single
/// [themeControllerStyle] field — see [CoreThemeControllerStyle] for
/// the merge chain. The semantic / behaviour fields (`themes` /
/// `selectedTheme` / `onThemeChanged` / `size` / `enabled`) stay flat
/// on the widget.
///
/// Each swatch previews the theme's palette as one circle split evenly
/// among the colours the option carries — two colours are two halves,
/// which is the picture the canvas draws; three or four divide the
/// same circle. The swatch button is a bare ring around the palette: no
/// body, and no ring at rest. A hovered or pressed swatch grows a light
/// ring, the selected one wears the strong ring (`selectedBorderColor`)
/// and its label turns to the strong ink; the selection is also announced
/// through the semantics `selected` flag, so it does not depend on colour.
///
/// Mirrors Web `ThemeController` 1:1 — same parameter names, same
/// semantics.
///
/// surface:content — a wrapping grid of swatches that sits in the page
/// flow, not something mounted over content. The swatch buttons draw no
/// fill, so a surface material reaches none of them.
///
/// ```dart
/// ThemeController(
///   selectedTheme: _theme,
///   onThemeChanged: (name) => setState(() => _theme = name),
///   themes: const [
///     CoreThemeOption(
///       name: 'Ocean',
///       primaryColor: CoreColor.fromRGB(14, 165, 233),
///     ),
///     CoreThemeOption(
///       name: 'Forest',
///       primaryColor: CoreColor.fromRGB(34, 197, 94),
///     ),
///   ],
/// )
/// ```
class ThemeController extends StatelessWidget
    implements CoreThemeControllerContract {
  /// Creates a [ThemeController].
  const ThemeController({
    required this.themes,
    required this.onThemeChanged,
    this.selectedTheme,
    this.size = CoreThemeControllerSize.defaultSize,
    this.enabled = true,
    this.themeControllerStyle,
    super.key,
  });

  @override
  final List<CoreThemeOption> themes;

  @override
  final String? selectedTheme;

  @override
  final CoreValueChanged<String> onThemeChanged;

  @override
  final CoreThemeControllerSize size;

  @override
  final bool enabled;

  @override
  final CoreThemeControllerStyle? themeControllerStyle;

  /// Returns a copy of this [ThemeController] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ThemeController copyWith({
    Key? key,
    List<CoreThemeOption>? themes,
    CoreValueChanged<String>? onThemeChanged,
    String? selectedTheme,
    CoreThemeControllerSize? size,
    bool? enabled,
    CoreThemeControllerStyle? themeControllerStyle,
  }) {
    return ThemeController(
      key: key ?? this.key,
      themes: themes ?? this.themes,
      onThemeChanged: onThemeChanged ?? this.onThemeChanged,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      themeControllerStyle: themeControllerStyle ?? this.themeControllerStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveThemeController(
      context,
      size: size,
      themeControllerStyle: themeControllerStyle,
    );
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: resolved.buttonSpacing,
      runSpacing: resolved.buttonSpacing,
      children: [
        for (final option in themes)
          // A floor, not a width: the cell is at least `swatchMinWidth`
          // wide whatever the name is, and a longer name widens its own
          // cell — the name is shown whole, never ellipsised. The button
          // and label stay centred in it.
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: resolved.swatchMinWidth),
            child: _ThemeSwatch(
              onTap: () => onThemeChanged(option.name),
              option: option,
              resolved: resolved,
              scheme: scheme,
              selected: option.name == selectedTheme,
              // The group lock and the per-theme lock compose: either one
              // greys the swatch. Their scopes differ (a read-only form vs
              // a theme a plan does not include), which is why both exist.
              enabled: enabled && option.enabled,
            ),
          ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreThemeControllerStyle] patch into
/// [ThemeController.themeControllerStyle] without hand-reconstructing
/// every field. Mirrors the Web `ThemeController.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreThemeControllerStyle.merge` right-side-wins semantics).
extension ThemeControllerStyleChain on ThemeController {
  /// Returns a copy of this [ThemeController] with [patch] merged into
  /// [themeControllerStyle] (patch fields win on conflict).
  ThemeController withStyle(CoreThemeControllerStyle patch) => copyWith(
    themeControllerStyle:
        (themeControllerStyle ?? const CoreThemeControllerStyle()).merge(
          patch,
        ),
  );
}

/// A single selectable theme swatch button.
class _ThemeSwatch extends StatefulWidget {
  const _ThemeSwatch({
    required this.onTap,
    required this.option,
    required this.resolved,
    required this.scheme,
    required this.selected,
    required this.enabled,
  });

  final VoidCallback onTap;
  final CoreThemeOption option;
  final ResolvedThemeController resolved;
  final CoreColorScheme scheme;
  final bool selected;
  final bool enabled;

  @override
  State<_ThemeSwatch> createState() => _ThemeSwatchState();
}

class _ThemeSwatchState extends State<_ThemeSwatch> {
  // Interaction state DETECTION — the values each state wears are the
  // resolver's; the swatch only says which state it is in.
  bool _hovered = false;
  bool _pressed = false;

  void _handleHover(bool hovered) {
    if (_hovered != hovered) setState(() => _hovered = hovered);
  }

  void _handlePressedChange(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  /// The palette colours this option carries, in the order they are
  /// stated — `primary` is required, the rest join when present.
  List<CoreColor> get _colors => [
    widget.option.primaryColor,
    ?widget.option.secondaryColor,
    ?widget.option.accentColor,
    ?widget.option.neutralColor,
  ];

  // The palette preview is a colour sample, not a surface — it must
  // never receive material (that would hide the very colour the
  // component exists to show), so it stays plain decorative boxes,
  // uncomposed. One circle, divided evenly among the colours: two
  // halves for two colours (the canvas picture), thirds or quarters for
  // more. Divided rather than laid out as separate dots so the swatch
  // reads as one theme rather than a row of tokens, and so the
  // preview's size is the ladder's regardless of how many colours the
  // caller passed.
  //
  // Disabled discards the colours entirely: a locked theme is still a
  // theme that exists, but showing its palette says "you can pick
  // this", which is the one thing a disabled swatch must not say.
  //
  // Pressed draws the same circle a little smaller
  // (`resolved.pressedPreviewSize`) — the ring appears around it at the
  // same moment, so the palette gives way to it.
  //
  // `stretch` is what gives a segment its height. A `Row` hands its
  // children loose vertical constraints, and a `ColoredBox` with no
  // child sizes to the smallest box those allow — zero — so without it
  // every segment is a 0-high strip and the palette paints nothing. The
  // Web twin gets this from `align-items: stretch`, the flex default.
  Widget _palette({required bool pressed}) {
    final resolved = widget.resolved;
    final side = pressed ? resolved.pressedPreviewSize : resolved.previewSize;
    return ClipRRect(
      borderRadius: resolved.previewBorderRadius,
      child: SizedBox(
        width: side,
        height: side,
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            for (final color in _colors)
              Expanded(
                child: ColoredBox(
                  color: widget.enabled
                      ? widget.scheme.resolve(color).toValue()
                      : resolved.disabledPreviewColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    final enabled = widget.enabled;
    final selected = widget.selected;
    // Hover and press only ever light the ring of an unselected, enabled
    // swatch: the selected one already wears the strong ring, and a locked
    // one reacts to nothing.
    final pressed = enabled && _pressed;
    final ringed = enabled && !selected && (_hovered || _pressed);
    final containerStyle = enabled
        ? (selected
              ? resolved.selectedContainerStyle
              : ringed
              ? resolved.hoverContainerStyle
              : resolved.unselectedContainerStyle)
        : (selected
              ? resolved.disabledSelectedContainerStyle
              : resolved.disabledContainerStyle);

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring (no hand-rolled GestureDetector +
    // MouseRegion). The Semantics keeps the per-swatch selection state
    // and label — the selection is announced by `selected`, not by
    // anything painted. The button box itself is a composed
    // `OutlinedContainer` (the palette inside is a colour sample, not
    // material) so the ring animates through the one box.
    final button = Clickable(
      onPressed: widget.onTap,
      onHover: _handleHover,
      onPressedChange: _handlePressedChange,
      enabled: enabled,
      clickableStyle: resolved.clickableStyle,
      child: Semantics(
        selected: selected,
        button: true,
        enabled: enabled,
        label: widget.option.name,
        child: OutlinedContainer(
          containerStyle: containerStyle,
          // `role` left at its default (`.content`) — matches the
          // class doc's `surface:content`.
          child: Center(child: _palette(pressed: pressed)),
        ),
      ),
    );

    return Column(
      mainAxisSize: .min,
      children: [
        button,
        Gap(gapStyle: resolved.labelGapStyle),
        Text(
          widget.option.name,
          style: !enabled
              ? resolved.disabledLabelTextStyle
              : selected
              ? resolved.selectedLabelTextStyle
              : resolved.labelTextStyle,
        ),
      ],
    );
  }
}
