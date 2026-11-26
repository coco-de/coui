import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/menu/menu/menu_glide_scope.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules target on a row.
const String _kMenuItemRowMarker = 'co-menu-item-row';

/// Class marker the scoped wash rules paint — the overlay inside a row.
const String _kMenuItemWashMarker = 'co-menu-item-wash';

/// Class marker on the label, description and shortcut seats. Each carries
/// its own text colour class, so a row whose active state changes the ink
/// reaches them through this marker rather than through inheritance.
const String _kMenuItemInkMarker = 'co-menu-item-ink';

/// Paint-ready chrome for Web `MenuItem`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="menuitem"> — the composed Clickable's box)
///   ├─ wash (<div>)                     // absolute overlay — :hover / :focus-visible / :active
///   ├─ markSeat (<div>)                 // * only when a mark shows or the column is reserved
///   ├─ leading                          // caller-supplied Component, optional
///   ├─ textColumn (<div>)
///   │    ├─ label
///   │    └─ description                 // * only when the caller gives one
///   ├─ shortcut (<div>)                 // * hidden when hasSubmenu — the chevron takes the seat
///   ├─ chevron                          // * only when hasSubmenu
///   └─ trailing                         // caller-supplied Component, optional
/// ```
///
/// `menu_item.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body. The wash is an overlay rather than a background
/// swap because the row's own fill (`transparent` at rest, `primary`
/// when selected) has to stay visible *under* it — that is what makes it
/// a state layer rather than a replacement. A tone that states an active
/// fill (`critical`) paints that fill on the same overlay, opaque, and
/// the row becomes its own stacking context so the overlay sits behind the
/// text instead of over it.
class ResolvedMenuItem implements WebResolvedChrome {
  /// Creates a [ResolvedMenuItem].
  const ResolvedMenuItem({
    required this.root,
    required this.wash,
    required this.markSeat,
    required this.textColumn,
    required this.label,
    required this.description,
    required this.shortcut,
    required this.leadingIconStyle,
    required this.markIconStyle,
    required this.chevronIconStyle,
    required this.contentGapStyle,
    required this.labelDescriptionGapStyle,
    required this.clickableStyle,
  });

  /// The row box — layout, insets, corner, fill and the resting
  /// foreground every seat inherits.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside an enabled row; the scoped rules paint it.
  final WebElementChrome wash;

  /// Fixed-width seat that keeps the mark column's width whether or not
  /// this row draws a mark.
  final WebElementChrome markSeat;

  /// Column holding the label and, when present, the description.
  final WebElementChrome textColumn;

  /// Label typography.
  final WebElementChrome label;

  /// Description typography — the quieter second line.
  final WebElementChrome description;

  /// Shortcut-hint typography.
  final WebElementChrome shortcut;

  /// Leading glyph chrome — raw-forwarded to the composed `Icon`.
  final CoreIconStyle leadingIconStyle;

  /// Mark glyph chrome — raw-forwarded to the composed `Icon`.
  final CoreIconStyle markIconStyle;

  /// Submenu chevron chrome — raw-forwarded to the composed `Icon`.
  final CoreIconStyle chevronIconStyle;

  /// Seat gap — raw-forwarded to the composed `Gap`.
  final CoreGapStyle contentGapStyle;

  /// Label-to-description gap — raw-forwarded to the composed `Gap`.
  final CoreGapStyle labelDescriptionGapStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `MenuItem`.
///
/// The wash is the foreground at [CoreStateLayer] weight, so it is a
/// derived colour rather than a token — no preset class can name it, and
/// it would collide with the row's own fill if it were emitted as a
/// `background-color` on the row. Both facts point the same way: scoped
/// rules on an overlay. A tone with an active fill states a token colour
/// instead, but the row's fill is inline, which no rule can beat, so that
/// fill rides the overlay too, together with the ink it needs.
class ResolvedMenuItemRules {
  /// Creates a [ResolvedMenuItemRules].
  const ResolvedMenuItemRules({required this.css});

  /// The rule text — empty when the row is disabled (a disabled row is
  /// reachable but inert, and a wash under the pointer would say it is
  /// not).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMenuItem] for the given [context].
///
/// Priority (per-field): `menuItemStyle` > `CoreMenuItemTheme.style` >
/// `CoreMenuItemStyle.defaultsBySize[size]` / `defaultsByTone[tone]` >
/// `CoreMenuItemStyle.defaultX` — the same chain the Flutter twin walks.
/// Web EMIT is theme-free: token names go out as classes and the browser
/// resolves them at run time.
///
/// [selected] and [enabled] are build-time semantic state (the Flutter
/// twin receives the same two), not interaction state — hover / focus /
/// press stay with the browser.
ResolvedMenuItem resolveMenuItem(
  BuildContext context, {
  required String scopeClass,
  CoreMenuItemSize size = CoreMenuItemSize.defaultSize,
  CoreMenuItemTone tone = CoreMenuItemTone.defaultTone,
  bool selected = false,
  bool enabled = true,
  bool reserveMark = false,
  CoreMenuItemStyle? menuItemStyle,
}) {
  final itemTheme = context.theme.coreComponentTheme?.menuItem;
  final merged = resolveStyleChain(const CoreMenuItemStyle(), [
    itemTheme?.style,
    menuItemStyle,
  ]);

  final sizeStyle = CoreMenuItemStyle.defaultsBySize[size]!;
  final toneStyle = CoreMenuItemStyle.defaultsByTone[tone]!;

  // ─── Stage 1 RESOLVE ──────────────────────────────
  // A size row on the control ladder goes out as its variable, so a density
  // moves it; the 36 `md` row is off the ladder and goes out as a length.
  // A caller's own minimum stays as stated, as on Flutter.
  final minHeightCss = merged.minHeight == null
      ? controlHeightCss(sizeStyle.minHeight!)
      : '${merged.minHeight! / kRemDivisor}rem';
  final padding = merged.padding ?? sizeStyle.padding!;
  final contentGapStyle = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  final labelDescriptionGapStyle = CoreMenuItemStyle
      .defaultLabelDescriptionGapStyle
      .merge(merged.labelDescriptionGapStyle);
  // Row corner — the per-instance override wins (a hosting panel states its
  // row corner through its nested row slot), else the size row's corner.
  final borderRadius = merged.borderRadius ?? sizeStyle.borderRadius!;
  final leadingIconStyle = sizeStyle.leadingIconStyle!.merge(
    merged.leadingIconStyle,
  );
  final markIconStyle = CoreMenuItemStyle.defaultMarkIconStyle.merge(
    merged.markIconStyle,
  );
  final chevronIconStyle = CoreMenuItemStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final backgroundColor =
      merged.backgroundColor ?? CoreMenuItemStyle.defaultBackgroundColor;
  final selectedBackgroundColor =
      merged.selectedBackgroundColor ??
      CoreMenuItemStyle.defaultSelectedBackgroundColor;
  final clickableStyle = CoreMenuItemStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // The row's foreground: the tone table at rest, the selected pair when
  // chosen, one step down when inert. Every seat inherits it — the label,
  // the glyphs, and the wash that is drawn from it.
  final foregroundColor = _foreground(
    merged: merged,
    toneStyle: toneStyle,
    selected: selected,
    enabled: enabled,
  );
  final fill = selected ? selectedBackgroundColor : backgroundColor;
  // A tone whose active state is a fill paints it on the wash overlay, which
  // must sit behind the text: the row isolates its own stacking context so
  // the overlay's negative z-index stays inside it.
  final hasActiveFill =
      _activeStyle(
        merged: merged,
        toneStyle: toneStyle,
        selected: selected,
        enabled: enabled,
      ) !=
      null;

  // Text roles carry the foreground so the seats need no colour of their
  // own; the description and the shortcut keep the muted colour their
  // size row states unless the row is selected or inert, where the row's
  // own foreground has to win or the second line would stay grey on a
  // filled background.
  final labelStyle = sizeStyle.labelStyle!
      .merge(merged.labelStyle)
      .copyWith(color: foregroundColor);
  final descriptionBase = sizeStyle.descriptionStyle!.merge(
    merged.descriptionStyle,
  );
  final shortcutBase = sizeStyle.shortcutTextStyle!.merge(
    merged.shortcutTextStyle,
  );
  final secondaryColor = selected || !enabled ? foregroundColor : null;
  final descriptionStyle = secondaryColor == null
      ? descriptionBase
      : descriptionBase.copyWith(color: secondaryColor);
  final shortcutStyle = secondaryColor == null
      ? shortcutBase
      : shortcutBase.copyWith(color: secondaryColor);

  // ─── Stage 2 EMIT ─────────────────────────────────
  final fillEmit = emitColor(fill, fill, ColorTarget.background);
  final foregroundEmit = emitColor(
    foregroundColor,
    foregroundColor,
    ColorTarget.text,
  );
  final radiusEmit = emitRadius(borderRadius, borderRadius);
  final labelEmit = emitTypography(labelStyle, labelStyle);
  final descriptionEmit = emitTypography(descriptionStyle, descriptionStyle);
  final shortcutEmit = emitTypography(shortcutStyle, shortcutStyle);

  final rootRaw = <String, String>{
    'min-height': minHeightCss,
    'padding-inline': spaceCss(padding.left),
    'padding-block': spaceCss(padding.top),
    ...?fillEmit.inline,
    ...?radiusEmit.inline,
    ...?foregroundEmit.inline,
  };

  return ResolvedMenuItem(
    root: WebElementChrome(
      className:
          '$scopeClass $_kMenuItemRowMarker relative flex w-full items-center '
          'text-start select-none ${hasActiveFill ? 'isolate ' : ''}'
          '${fillEmit.className} ${radiusEmit.className} '
          '${foregroundEmit.className}',
      inlineStyles: Styles(raw: rootRaw),
    ),
    wash: WebElementChrome(
      className: '$_kMenuItemWashMarker pointer-events-none absolute inset-0',
      inlineStyles: Styles(raw: {...?radiusEmit.inline}),
    ),
    markSeat: WebElementChrome(
      className: 'flex shrink-0 items-center justify-center',
      inlineStyles: Styles(
        raw: {'width': '${markIconStyle.size! / kRemDivisor}rem'},
      ),
    ),
    textColumn: const WebElementChrome(
      className: 'flex min-w-0 flex-1 flex-col items-start',
    ),
    label: WebElementChrome(
      className: '$_kMenuItemInkMarker ${labelEmit.className}',
      inlineStyles: labelEmit.inline == null
          ? null
          : Styles(raw: labelEmit.inline),
    ),
    description: WebElementChrome(
      className: '$_kMenuItemInkMarker ${descriptionEmit.className}',
      inlineStyles: descriptionEmit.inline == null
          ? null
          : Styles(raw: descriptionEmit.inline),
    ),
    shortcut: WebElementChrome(
      className: '$_kMenuItemInkMarker shrink-0 ${shortcutEmit.className}',
      inlineStyles: shortcutEmit.inline == null
          ? null
          : Styles(raw: shortcutEmit.inline),
    ),
    leadingIconStyle: leadingIconStyle,
    markIconStyle: markIconStyle,
    chevronIconStyle: chevronIconStyle,
    contentGapStyle: contentGapStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the row carrying [scopeClass].
///
/// Walks the same chain as [resolveMenuItem] so a theme or instance
/// override of the ramp or the foreground lands here too.
///
/// [glide] is true for a row in a menu a finger may glide over (see
/// `MenuGlideScope`): the row the finger is over carries `data-coui-glide`,
/// and it is washed exactly as a pressed row is, since that is what a finger
/// down on it is. A row that is not in such a menu gets no rule for the mark,
/// so its rules are the ones it always had.
ResolvedMenuItemRules resolveMenuItemRules(
  BuildContext context, {
  required String scopeClass,
  CoreMenuItemTone tone = CoreMenuItemTone.defaultTone,
  bool selected = false,
  bool enabled = true,
  bool glide = false,
  CoreMenuItemStyle? menuItemStyle,
}) {
  if (!enabled) return const ResolvedMenuItemRules(css: '');

  final itemTheme = context.theme.coreComponentTheme?.menuItem;
  final merged = resolveStyleChain(const CoreMenuItemStyle(), [
    itemTheme?.style,
    menuItemStyle,
  ]);
  final toneStyle = CoreMenuItemStyle.defaultsByTone[tone]!;
  final stateLayer = merged.stateLayer ?? CoreMenuItemStyle.defaultStateLayer;
  final foregroundColor = _foreground(
    merged: merged,
    toneStyle: toneStyle,
    selected: selected,
    enabled: enabled,
  );
  final active = _activeStyle(
    merged: merged,
    toneStyle: toneStyle,
    selected: selected,
    enabled: enabled,
  );

  // Scoped by class, not id: the composed `Clickable` takes the element's
  // id for its own pseudo rules whenever a caller overrides the focus
  // ring, and a wash that silently stopped matching in that case would be
  // a bug nobody sees until someone restyles a ring.
  final row = '.$scopeClass';
  const wash = '.$_kMenuItemWashMarker';
  // The pressed rule is written last, so where the pointer hovers a lit row
  // the lit weight is the one that shows.
  final litRow = '$row[${MenuGlideScope.attribute}]';
  final pressedWash = glide
      ? '$row:active > $wash,$litRow > $wash'
      : '$row:active > $wash';
  if (active != null) {
    // The fill replaces the wash: an opaque overlay behind the text
    // (`z-index:-1` inside the row's own stacking context), and the ink the
    // fill needs on the row and on each seat that carries its own colour.
    const ink = '.$_kMenuItemInkMarker';
    final hover = active.hover.toValue();
    final pressed = active.pressed.toValue();
    final foreground = active.foreground?.toValue();
    final states = [
      ':hover',
      ':focus-visible',
      ':active',
      if (glide) '[${MenuGlideScope.attribute}]',
    ];
    final buffer = StringBuffer()
      ..write('$row:hover > $wash,$row:focus-visible > $wash{')
      ..write('background-color:$hover;z-index:-1;}')
      ..write('$pressedWash{background-color:$pressed;z-index:-1;}');
    if (foreground != null) {
      buffer
        ..write('${states.map((state) => '$row$state').join(',')}{')
        ..write('color:$foreground;}')
        ..write('${states.map((state) => '$row$state $ink').join(',')}{')
        ..write('color:$foreground;}');
    }
    return ResolvedMenuItemRules(css: buffer.toString());
  }
  final buffer = StringBuffer()
    ..write('$row:hover > $wash{background-color:')
    ..write(foregroundColor.scaleAlpha(stateLayer.hover).toValue())
    ..write(';}')
    ..write('$row:focus-visible > $wash{background-color:')
    ..write(foregroundColor.scaleAlpha(stateLayer.focus).toValue())
    ..write(';}')
    ..write('$pressedWash{background-color:')
    ..write(foregroundColor.scaleAlpha(stateLayer.pressed).toValue())
    ..write(';}');
  return ResolvedMenuItemRules(css: buffer.toString());
}

/// The fills and ink of a tone whose active state is a fill rather than a
/// wash — or `null` when the row is washed (the tone states none), selected
/// or disabled. Pressed falls back to the hover fill; an unstated ink is
/// `null`, which keeps every seat on its resting colour — the way the
/// Flutter twin reads them.
({CoreColor hover, CoreColor pressed, CoreColor? foreground})? _activeStyle({
  required CoreMenuItemStyle merged,
  required CoreMenuItemStyle toneStyle,
  required bool selected,
  required bool enabled,
}) {
  if (!enabled || selected) return null;
  final hover = merged.hoverBackgroundColor ?? toneStyle.hoverBackgroundColor;
  if (hover == null) return null;
  return (
    hover: hover,
    pressed:
        merged.pressedBackgroundColor ??
        toneStyle.pressedBackgroundColor ??
        hover,
    // `null` keeps every ink at rest — the seats carry their own colours.
    foreground: merged.activeForegroundColor ?? toneStyle.activeForegroundColor,
  );
}

/// The row's foreground for the state it is in — one function so the
/// chrome and the wash cannot disagree about what colour the row is.
CoreColor _foreground({
  required CoreMenuItemStyle merged,
  required CoreMenuItemStyle toneStyle,
  required bool selected,
  required bool enabled,
}) {
  if (!enabled) {
    return merged.disabledForegroundColor ??
        CoreMenuItemStyle.defaultDisabledForegroundColor;
  }
  if (selected) {
    return merged.selectedForegroundColor ??
        CoreMenuItemStyle.defaultSelectedForegroundColor;
  }
  return merged.foregroundColor ?? toneStyle.foregroundColor!;
}
