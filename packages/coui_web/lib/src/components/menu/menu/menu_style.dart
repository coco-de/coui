import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/overlay/overlay_fit.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Menu`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="menu" | "menubar">)             // composed Popup panel chrome
///   └─ rowsScroller (<div>)?                          // only a panel held to the viewport's room
///        └─ entry (per item) — one of:
///             ├─ label   (<div role="presentation">)        // CoreMenuItemKind.label
///             │    └─ row (<div>)
///             │         ├─ leadingColumn (<div>)?            // menu skips when no leading
///             │         ├─ labelText (<span>)
///             │         └─ trailing (caller-supplied)?       // menu skips when null
///             ├─ Button(variant: menu) (<button role="menuitem">)   // CoreMenuItemKind.action
///             │         ├─ leadingColumn (<div>)?
///             │         ├─ Text(label)
///             │         └─ trailing (caller-supplied + chevron when submenu)
///             ├─ Button(variant: menu)  // role menuitemcheckbox | menuitemradio
///             │         (same shape as action; mark glyph in leading)
///             ├─ Separator (<div role="separator">)        // CoreMenuItemKind.divider
///             └─ Gap (<div>)                               // CoreMenuItemKind.gap
/// ```
///
/// Without [rowsScroller] the entries are the root's own children.
///
/// The panel box chrome ([root]) is **not** re-implemented here — it is
/// the chrome of the unified `Popup`, sourced by running [resolvePopup]
/// on the menu's forwarded [CoreMenuStyle.popupStyle]. `Menu` keeps its
/// own root `<div>` (so it owns the `role` / `aria-orientation` /
/// passthrough), but the box background / border / radius / padding /
/// shadow / min-width and the inter-row `gap` all come from the single
/// popup resolver.
///
/// `menu.dart` reads each slot's `className` + `inlineStyles` straight
/// from the resolver outputs — no merge / fallback / conversion in the
/// widget body. Per-item interactive chrome (resting / hover
/// (`:hover`) / selected (`aria-selected`) / disabled background +
/// cursor) is owned by the composed `MenuItem` via the raw-forwarded
/// [itemStyle] — not painted here.
///
/// The divider line is a nested `Divider` child that self-resolves
/// from the passthrough [dividerStyle]; the inter-row spacer is painted
/// by the popup panel's flex `gap` (no manual `Gap` interleave in the
/// widget).
class ResolvedMenu implements WebResolvedChrome {
  /// Creates a [ResolvedMenu].
  const ResolvedMenu({
    required this.root,
    required this.submenuStyle,
    required this.itemStyle,
    required this.labelGapStyle,
    required this.row,
    required this.label,
    required this.labelText,
    required this.dividerStyle,
    required this.divider,
    required this.leadingColumn,
    required this.submenuWrapper,
    required this.submenuIndent,
    required this.submenuChevronWrapper,
    this.rowsScroller,
  });

  /// Paint-ready chrome for the outermost `<div role="menu" |
  /// "menubar">` panel — the composed `Popup` box chrome (background /
  /// border / radius / padding / shadow / min-width + inter-row `gap`),
  /// sourced from [resolvePopup] so the panel emit lives in one place. A
  /// panel held to the room the viewport leaves it also carries its cap here
  /// (`max-height`).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the `<div>` that holds the entries and scrolls
  /// them inside the [root] box — `null` while the panel fits, when the
  /// entries are the root's own children.
  ///
  /// The scroller is a box inside the panel rather than the panel itself: the
  /// panel's border, corners, shadow and (under a glass surface) the rim
  /// drawn by pseudo-elements positioned inside it stay where they are while
  /// only the rows move.
  final WebElementChrome? rowsScroller;

  /// Nested style for an inline nested submenu — raw-forwarded to the
  /// recursive child `Menu`'s `menuStyle` (the child self-resolves). The
  /// box-less [CoreMenuStyle.defaultSubmenuStyle] merged with the
  /// per-instance override.
  final CoreMenuStyle submenuStyle;

  /// Nested [CoreMenuItemStyle] raw-forwarded to each interactive row's
  /// composed `MenuItem` — [CoreMenuStyle.effectiveItemStyle], the row slot
  /// folded over its default. The row owns the resting / hover (CSS
  /// `:hover`) / selected (`aria-selected`) fill + cursor (no resolver-side
  /// assembly), and fills whatever this slot leaves `null` from its own
  /// size / tone ladders.
  final CoreMenuItemStyle itemStyle;

  /// Seat gap for the heading row — the same gap the rows under it use,
  /// so a heading's glyph and text sit on the rows' rhythm.
  final CoreGapStyle labelGapStyle;

  /// Paint-ready chrome for the per-item row container `<div>` — flex
  /// row wrapping leading / label / trailing.
  final WebElementChrome row;

  /// Paint-ready chrome for a non-interactive label entry container
  /// `<div role="presentation">`.
  final WebElementChrome label;

  /// Paint-ready chrome for the label text `<span>` inside a label
  /// entry — the `labelSmall` role (12 Medium) in the subtle caption colour.
  final WebElementChrome labelText;

  /// Nested [CoreDividerStyle] slot — forwarded straight to
  /// `Divider(dividerStyle: …)` for divider entries. Carries the resolved
  /// divider colour so the divider self-resolves its own line chrome.
  final CoreDividerStyle dividerStyle;

  /// Paint-ready chrome for the `<div role="presentation">` that holds a
  /// divider entry — the room kept above and below the rule in a column
  /// menu ([CoreMenuStyle.dividerInset]), none in a bar.
  final WebElementChrome divider;

  /// Paint-ready chrome for the fixed-width leading-icon column
  /// `<div>` rendered ahead of each row when at least one item has a
  /// leading slot.
  final WebElementChrome leadingColumn;

  /// Paint-ready chrome for the nested submenu wrapper `<div
  /// class="flex flex-col w-full">` that hosts the inline submenu.
  final WebElementChrome submenuWrapper;

  /// Paint-ready chrome for the `<div>` that indents an inline
  /// submenu panel by one level (`padding-inline-start`).
  final WebElementChrome submenuIndent;

  /// Paint-ready chrome for the `<div>` wrapping an action row's
  /// caller-supplied trailing slot together with the auto-appended
  /// submenu chevron — flex row with the inter-element gap rule.
  final WebElementChrome submenuChevronWrapper;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMenu] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreMenuStyle.defaultX)
///   → theme.coreComponentTheme.menu.style
///   → widget.menuStyle
/// ```
///
/// [maxHeight] is the height a host's positioner capped the panel to (see
/// `MenuFitScope`), or `null` while the panel fits: the panel's own box is held
/// to it and the entries scroll in a list inside the box ([ResolvedMenu.root],
/// [ResolvedMenu.rowsScroller]).
ResolvedMenu resolveMenu(
  BuildContext context, {
  required bool vertical,
  CoreMenuItemSize size = CoreMenuItemSize.defaultSize,
  CoreMenuStyle? menuStyle,
  double? maxHeight,
}) {
  final menuTheme = context.theme.coreComponentTheme?.menu;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreMenuStyle(), [
    menuTheme?.style,
    menuStyle,
  ]);

  final popupThemeStyle = context.theme.coreComponentTheme?.popup?.style;
  final materialStyle =
      merged.popupStyle?.surfaceStyle ??
      popupThemeStyle?.surfaceStyle ??
      SurfaceStyleScope.of(context);
  final glass = materialStyle == CoreSurfaceStyleId.liquidGlass;

  // ─── Panel box chrome — composed `Popup` (single source) ──
  // The bordered panel is a `Popup`: run its resolver on the menu's
  // forwarded panel style (menu-divergent fields merged over the popup's
  // own defaults) so the box background / border / radius / padding /
  // shadow / min-width + inter-row `gap` emit lives in one place, not
  // re-implemented here.
  final popupChrome = resolvePopup(
    context,
    direction: vertical ? .vertical : .horizontal,
    // A horizontal menu releases the column's width band first (Core owns
    // that patch, so both platforms release the same two fields).
    // guard-nested-override: horizontalPopupStyle — the horizontal patch is
    // a base under `merged.popupStyle`, so the override reaches it there.
    popupStyle: CoreMenuStyle.defaultPopupStyle
        .merge(glass ? CoreMenuStyle.glassStyle.popupStyle : null)
        .merge(glass ? popupThemeStyle : null)
        .merge(vertical ? null : CoreMenuStyle.defaultHorizontalPopupStyle)
        .merge(merged.popupStyle),
  );

  // Inline-submenu style — raw-forwarded to the recursive child `Menu`
  // (the child self-resolves, like `dividerStyle` → `Divider`). The
  // box-less `defaultSubmenuStyle` merged with the per-instance override.
  final submenuStyle = CoreMenuStyle.defaultSubmenuStyle.merge(
    merged.submenuStyle,
  );

  // Interactive-row Button style — raw-forwarded to each composed
  // `Button(variant: menu)` (the `Button` owns the resting / hover / selected
  // fill + cursor). The menu-divergent default merged with the override.
  // Row chrome — raw-forwarded to each composed `MenuItem`. The Core
  // getter is the one place the row slot is folded over its default, so
  // both platforms fold the same way. The row resolver fills what is
  // still null.
  final itemStyle = CoreMenuStyle.defaultItemStyle
      .merge(glass ? CoreMenuStyle.glassStyle.itemStyle : null)
      .merge(merged.itemStyle);

  // ─── Per-entry resolved chrome values ─────────────────
  // Every value finished merge + fallback so the local builders below
  // run from a single source of truth (closures capture these
  // directly).
  // The label row is the menu's own (a heading, not a `MenuItem`), but it
  // sits in the same column as the rows under it, so it takes the row's
  // insets: the forwarded row chrome first, else the size ladder.
  final sizeStyle = CoreMenuItemStyle.defaultsBySize[size]!;
  // Top and sides are the row's; only the bottom is the heading's own.
  final labelPadding = (itemStyle.padding ?? sizeStyle.padding!).copyWith(
    bottom: merged.labelBottomInset ?? CoreMenuStyle.defaultLabelBottomInset,
  );
  final dividerInset = merged.dividerInset ?? CoreMenuStyle.defaultDividerInset;
  final labelGapStyle = itemStyle.contentGapStyle ?? sizeStyle.contentGapStyle!;
  // Nested divider-style slot — raw-forward the merged token; the
  // child `Divider` resolves the colour / thickness (rule 2.2).
  final dividerStyle = CoreMenuStyle.defaultDividerStyle.merge(
    merged.dividerStyle,
  );
  final leadingColumnWidth =
      merged.leadingColumnWidth ?? CoreMenuStyle.defaultLeadingColumnWidth;
  final submenuIndent =
      merged.submenuIndent ?? CoreMenuStyle.defaultSubmenuIndent;

  // Nested toggle-mark icon-style slot — caller override merges over the
  // design-system default. Forwarded straight to `Icon(iconStyle: …)`
  // for the checkbox checkmark / radio dot leading glyphs.

  // Nested chevron icon-style slot — caller override merges over the
  // design-system default. Forwarded straight to `Icon(iconStyle: …)`
  // for the submenu chevron-right indicator.

  // Nested gap-style slot — forwarded straight to `Gap(gapStyle: …)`
  // for the intra-row spacer between leading-icon column ↔ label ↔
  // trailing.

  // Non-interactive label / header typography (sb-text-style-repackage).
  // The `labelSmall` role class (12 Medium) + variant colour are emitted
  // from the merged `labelTextStyle` overlay — the role class is always
  // present (role is fixed) while a weight class is emitted only when the
  // overlay states a weight, suppressed when a per-instance `fontWeight`
  // override exists so the inline rule below wins. Colour is folded into
  // the same slot's `color`.
  final labelTextOverlay = CoreMenuStyle.defaultLabelTextStyle.merge(
    merged.labelTextStyle,
  );
  final labelTextColor =
      labelTextOverlay.color ?? CoreMenuStyle.defaultLabelTextStyle.color!;

  // ─── Local builders ───────────────────────────────────

  /// Composes the per-row container Tailwind className — flex row /
  /// items-center, full width.
  String buildRowClassName() => WebLayout.flexRowItemsCenterFull;

  /// Composes a non-interactive label entry container's Tailwind
  /// className — flex column wrapping the row.
  String buildLabelClassName() => WebLayout.flexFull;

  /// Composes the label entry inline-CSS bundle — the rows' top and side
  /// padding so headings align with action rows, and the heading's own
  /// bottom inset. Intra-row
  /// spacers are rendered as nested [Gap] children (the row's own
  /// `contentGapStyle`) — no `gap` CSS on the label entry.
  Styles buildLabelInlineStyles() => .new(
    raw: {
      'padding': labelPadding.toValue(),
    },
  );

  /// Composes the non-interactive label text Tailwind className — the
  /// `labelSmall` typography role + design-system semibold weight read from
  /// the merged `labelTextStyle` overlay (sb-text-style-repackage). The
  /// role class is always emitted (role is fixed); the weight class is
  /// suppressed when a per-instance `fontWeight` override is set so the
  /// inline rule wins. Colour + per-instance overrides travel inline via
  /// [buildLabelTextInlineStyles].
  String buildLabelTextClassName() {
    final classList = [
      'text-${CoreTextStyles.labelSmall.name}',
      // `text-start` pins the heading to the leading edge (mirroring the
      // Flutter label entry's start-aligned `Row`) so it never inherits an
      // ancestor's `text-align: center` — the interactive rows below pin the
      // same via the button's expanded-label, so the header must match.
      '${WebLayout.flex1} ${WebLayout.minWZero} text-start',
    ];
    if (merged.labelTextStyle?.fontWeight == null &&
        labelTextOverlay.fontWeight != null) {
      classList.add('font-${labelTextOverlay.fontWeight!.tailwindFontWeight}');
    }
    return classList.join(' ');
  }

  /// Composes the non-interactive label text inline-CSS bundle — the
  /// resolved foreground colour (always emitted so a per-instance
  /// override can win) plus any per-instance `fontSize` / `fontWeight` /
  /// `lineHeight` / `letterSpacing` overrides from the merged
  /// `labelTextStyle` slot via [CoreTextStyleToInlineCss.toInlineCss]
  /// (sb-text-style-repackage). The slot's own `color` is dropped from
  /// that spread so the scheme-resolved colour above wins (`toInlineCss`
  /// emits a bare value without dark-mode resolution).
  Styles buildLabelTextInlineStyles() {
    final raw = {
      // Web EMIT is theme-free — emit the token name (`var(--coui-X)`); the
      // browser resolves it at runtime (`scheme.resolve` is a no-op on Web).
      'color': labelTextColor.toValue(),
    };
    final overrideStyle = merged.labelTextStyle;
    if (overrideStyle != null) {
      raw.addAll(overrideStyle.toInlineCss(includeColor: false));
    }
    return Styles(raw: raw);
  }

  /// Composes the divider holder's inline-CSS bundle — the cross-axis
  /// room above and below the rule in a column menu; a bar keeps its
  /// dividers flush.
  Styles? buildDividerInlineStyles() => vertical
      ? .new(
          raw: {
            'padding-top': spaceCss(dividerInset),
            'padding-bottom': spaceCss(dividerInset),
          },
        )
      : null;

  /// Composes the fixed-width leading-column inline-CSS bundle so
  /// every row's icon column shares the same footprint.
  Styles buildLeadingColumnInlineStyles() {
    final size = '${leadingColumnWidth / kRemDivisor}rem';
    return Styles(raw: {'width': size, 'height': size, 'flex-shrink': '0'});
  }

  /// Composes the submenu indent inline-CSS bundle — `padding-inline-
  /// start` so the nested panel sits one level in.
  Styles buildSubmenuIndentInlineStyles() => .new(
    raw: {
      'padding-inline-start': spaceCss(submenuIndent),
    },
  );

  /// Composes the submenu-chevron wrapper className — flex row only;
  /// the inter-element spacer between the caller's trailing slot and
  /// the auto-appended chevron is a nested [Gap] child (the row's own
  /// `contentGapStyle`).
  Styles buildSubmenuChevronWrapperInlineStyles() => const .new(raw: {});

  // ─── A panel held to the room the viewport leaves it ──
  // The cap goes on the panel's own box and the entries scroll in a list
  // inside it, so the box keeps its border, corners, shadow and glass rim
  // (see `resolveOverlayFitScroller`).
  final cap = maxHeight;
  final root = cap == null
      ? popupChrome.root
      : WebElementChrome(
          className: popupChrome.root.className,
          inlineStyles: Styles.combine([
            ?popupChrome.root.inlineStyles,
            resolveOverlayFitBox(maxHeight: cap),
          ]),
        );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedMenu(
    root: root,
    rowsScroller: cap == null ? null : resolveOverlayFitScroller(),
    submenuStyle: submenuStyle,
    itemStyle: itemStyle,
    labelGapStyle: labelGapStyle,
    row: WebElementChrome(className: buildRowClassName()),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
    labelText: WebElementChrome(
      className: buildLabelTextClassName(),
      inlineStyles: buildLabelTextInlineStyles(),
    ),
    dividerStyle: dividerStyle,
    divider: WebElementChrome(
      className: '',
      inlineStyles: buildDividerInlineStyles(),
    ),
    leadingColumn: WebElementChrome(
      className: WebLayout.flexCenter,
      inlineStyles: buildLeadingColumnInlineStyles(),
    ),
    submenuWrapper: const WebElementChrome(
      className: WebLayout.flexColFull,
    ),
    submenuIndent: WebElementChrome(
      className: '',
      inlineStyles: buildSubmenuIndentInlineStyles(),
    ),
    submenuChevronWrapper: WebElementChrome(
      className: WebLayout.flexRowItemsCenter,
      inlineStyles: buildSubmenuChevronWrapperInlineStyles(),
    ),
  );
}
