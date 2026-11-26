/// <reference types="@figma/plugin-typings" />

import { COMMAND, CommandSize, kCommandSizes, COMMAND_ITEM_NAME } from '../command-preview';
import { kCommandSearchCopy } from '../command-composition';
import { RegistryEntry } from '../helpers';

import { kPlainDividerAxes, iconOpts, overlayGlyph } from '../overlay-composition';
import { boundOrNull, bindLayoutBound } from '../layout-bound';

import {
  ChromeOpts,
  ColorData,
  VarLookup,
  applyPanelCompChrome,
  applySurfaceMaterial,
  bestVariantName,
  bindTextProp,
  bindVisibleProp,
  defineProp,
  glyphOpts,
  glyphPaint,
  setSlotIcon,
  iconMainIdAt,
  ICON_NAMES,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  mountSet,
  panel,
  textLabelOpts,
  setShadow,
  hostedDivider,
  hideInstanceLabel,
  pinInstanceBox,
  suppressFieldChrome,
  pinComposedCorner,
  bindPad,
  exposeAll,
  setInstanceBoolNamed,
  setInstanceTextNamed,
} from '../helpers';

import { Color, Dim, colorData, dimVal, optField, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';

// One `Kbd.icon(keyContent: Icon(…))` — a SINGLE key cap whose content
// is a glyph, which is what `kbd.dart`'s build returns the moment `keyContent`
// is non-null (`_buildKeyBox(resolved, keyContent!)`, before it ever reaches the
// `keys` loop that joins caps with `Text('+')`).
//
// The cap is a `Kbd` INSTANCE because that is what the widget composes —
// `Command` forwards `kbdStyle` into it and paints none of the cap's chrome
// itself. A `Kbd` instance shows one key until `Show key 2…4` are turned on,
// which is the shape `Kbd.icon` has, so the instance needs no reshaping: only
// its own `KeyContent` TEXT property is cleared (by name — the component
// carries a TEXT property per key), because the glyph replaces the letter.
//
// The glyph is drawn only when the plugin's Lucide subset carries it — see the
// gap named on `buildCommand`. A cap with no glyph is still a real key cap at
// `keyMinSize`; a cap with a DIFFERENT glyph would be a fabricated mark, which
// is the defect this file already removed once (Toast's `circle-check`).
function kbdKey(
  page: PageNode,
  lk: VarLookup,
  glyph: string,
  o: { size: number | Dim; color: ColorData },
): FrameNode {
  const host = panel('kbd', 'HORIZONTAL', lk, {});
  const cap = instanceOf(page, 'Kbd');
  host.appendChild(cap);
  setInstanceTextNamed(cap, 'KeyContent', '');
  if (!ICON_NAMES.includes(glyph)) return host;
  const side = dimVal(o.size);
  const mark = makeIcon(glyph, lk, iconOpts(lk, o.color, o.size));
  // Centred over the cap's box rather than the instance: the box is the node
  // that carries the key's own width, the instance is only the row around it.
  const box = cap.children[0];
  const capWidth = box == null ? cap.width : box.width;
  overlayGlyph(host, mark, (capWidth - side) / 2, (cap.height - side) / 2);
  return host;
}
const kCommandPresentations = ['inline', 'dialog', 'fullscreen'] as const;
// `localizations.commandEmpty` / `commandEmptyHint` / `commandScopeAll` — the
// Korean chrome strings (`coui_i10n/chrome/i18n/ko.i18n.json`), the locale the
// canvas is drawn in.
const kCommandEmptyCopy = '검색 결과가 없어요.';
const kCommandEmptyHintCopy = '다른 단어로 검색하거나 범위를 전체로 넓혀 보세요.';
const kCommandScopeAllCopy = '전체';
const kCommandHeadingCopy = '추천';
// Each group is a run of key caps followed by ONE label — `commandMove` for
// the ↑ ↓ pair (either way, not one direction), `commandMoveScope` for ← →,
// `commandActivate` for ⏎ — the same order `_buildFooter` draws, in the
// Korean copy `ko.i18n.json` gives those keys.
const kCommandFooterHints: readonly { glyphs: readonly string[]; label: string }[] = [
  { glyphs: ['arrow-up', 'arrow-down'], label: '이동' },
  { glyphs: ['arrow-left', 'arrow-right'], label: '범위' },
  { glyphs: ['corner-down-left'], label: '선택' },
];

function buildCommand(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = COMMAND.fields;
  const bg = colorData(f.backgroundColor)!;
  const names: string[] = [];
  const poses: { presentation: (typeof kCommandPresentations)[number]; size: CommandSize; empty: boolean }[] = [];
  for (const presentation of kCommandPresentations) {
    for (const size of kCommandSizes) {
      for (const empty of [false, true]) {
        poses.push({ presentation: presentation, size: size, empty: empty });
        names.push(`Presentation=${presentation}, Size=${size}, Empty=${empty}`);
      }
    }
  }
  const mount = mountSet(page, 'Command', names);

  const scopeNodes: (FrameNode | InstanceNode)[] = [];
  const headingNodes: TextNode[] = [];
  const exposed: InstanceNode[] = [];
  const sizeRows = new Map(Object.entries(COMMAND.sizes.defaultsBySize));
  const presentationRows = new Map(Object.entries(COMMAND.variants.defaultsByPresentation));

  for (let i = 0; i < poses.length; i++) {
    const pose = poses[i];
    const size = pose.size;
    const sz = sizeRows.get(size);
    if (!sz) throw new Error(`Command: \`command.sizes.defaultsBySize\` has no \`${size}\` row`);
    const pr = presentationRows.get(pose.presentation);
    if (!pr) throw new Error(`Command: \`defaultsByPresentation\` has no \`${pose.presentation}\` row`);
    const border = colorData(pr.borderColor);
    const c = mount.getOrCreate(names[i]);
    // The fill goes to the material layer below, not the frame.
    const chrome: ChromeOpts = { radius: pr.borderRadius.topLeft };
    if (border != null && border.color != null && dimVal(pr.borderWidth) > 0) {
      chrome.border = border.color;
      chrome.borderOp = border.opacity;
      chrome.borderArgb = border.argb;
      chrome.strokeN = pr.borderWidth;
    }
    applyPanelCompChrome(c, 'VERTICAL', lk, chrome);
    // A content surface on both platforms — the Flutter panel is a composed
    // `OutlinedContainer` (`theme.surfaceFor(.content)`), the Web panel marks
    // itself `webSurfaceMarkerFor(.content)`. The rim only on a presentation
    // that casts: both key it on `panelShadow`, which the dialog states and
    // the inline and fullscreen palettes leave empty.
    applySurfaceMaterial(c, lk, bg, 'content', {
      radius: pr.borderRadius.topLeft,
      rim: pr.panelShadow.layers.length > 0,
    });
    c.clipsContent = true;
    setShadow(c, pr.panelShadow, lk, null);
    // The width is the host's — inline takes its parent's, dialog is capped,
    // fullscreen is the viewport. The canvas has to pick one to draw at:
    // g7-preview-only: inline 360 (a docs column), dialog at its own cap,
    // fullscreen 390 (a phone).
    const maxW = boundOrNull(pr.panelMaxWidth);
    // g7-preview-only: inline 360 (a docs column) · fullscreen 390 (a phone); dialog draws at its own cap.
    lockWidth(c, pose.presentation === 'dialog' && maxW != null ? maxW : pose.presentation === 'fullscreen' ? 390 : 360);
    bindLayoutBound(c, lk, 'minWidth', boundOrNull(pr.panelMinWidth));
    bindLayoutBound(c, lk, 'maxWidth', maxW);

    // ── search row: [back] glyph · Gap · TextField(plain) ──
    const search = panel('search', 'HORIZONTAL', lk, {
      pl: sz.searchPadding.l, pr: sz.searchPadding.r, pt: sz.searchPadding.t, pb: sz.searchPadding.b,
      gap: sz.searchGapStyle.size,
    });
    search.counterAxisAlignItems = 'CENTER';
    if (pose.presentation === 'fullscreen') {
      // The square Button owns its box and icon rung. Its existing icon slot
      // represents the icon-only child the runtime inherits through IconTheme.
      const back = instanceOf(
        page,
        'Button',
        bestVariantName(page, 'Button', {
          Variant: 'plain',
          Size: size,
          State: 'enabled',
          Shape: 'square',
        }),
      );
      back.name = 'back button';
      hideInstanceLabel(back);
      const buttonRow = COMPONENTS.button.sizes.defaultsBySize[size];
      const side = dimVal(buttonRow.iconShapeIconStyle.size);
      setSlotIcon(
        back,
        'Leading',
        iconMainIdAt(page, side),
        'arrow-left',
        glyphPaint(lk, glyphOpts(lk, colorData(f.backIconStyle.color), side)),
      );
      const extent = dimVal(buttonRow.height);
      pinInstanceBox(back, extent, extent);
      search.appendChild(back);
    } else {
      search.appendChild(
        makeIcon('search', lk, glyphOpts(lk, colorData(f.placeholderColor), sz.searchIconStyle.size)),
      );
    }
    const field = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', { Variant: 'plain', Size: size, State: 'enabled' }),
    );
    search.appendChild(field);
    field.layoutSizingHorizontal = 'FILL';
    setInstanceTextNamed(field, 'Placeholder', kCommandSearchCopy);
    // Command owns the surrounding chrome, including the embedded field's
    // focus border. Forward its transparent override into the instance.
    suppressFieldChrome(field, lk, {
      borderColor: f.searchFieldStyle.focusBorderColor,
    });
    exposed.push(field);
    if (pose.presentation === 'dialog') {
      // `Kbd(keys: ['esc'], kbdStyle:)` after a second `searchGapStyle` — the
      // dialog's way out on the search row (the widget draws it when the
      // dialog can be dismissed, which a hosted dialog always can).
      const esc = instanceOf(page, 'Kbd');
      esc.name = 'esc';
      setInstanceTextNamed(esc, 'KeyContent', 'esc');
      search.appendChild(esc);
    }
    search.counterAxisSizingMode = 'FIXED';
    search.resize(search.width, dimVal(sz.searchInputHeight));
    search.primaryAxisSizingMode = 'AUTO';
    c.appendChild(search);
    search.layoutSizingHorizontal = 'FILL';
    hostedDivider(page, lk, c, { axes: kPlainDividerAxes });

    // ── scope row: Chip instances — `All` selected, the rest unselected ──
    const scope = panel('scope', 'HORIZONTAL', lk, {
      pl: sz.scopePadding.l, pr: sz.scopePadding.r, pt: sz.scopePadding.t, pb: sz.scopePadding.b,
      gap: f.scopeSpacing,
    });
    scope.counterAxisAlignItems = 'CENTER';
    const chips: readonly { label: string; selected: boolean }[] = [
      { label: kCommandScopeAllCopy, selected: true },
      { label: '작업', selected: false },
      { label: '페이지', selected: false },
    ];
    for (const chip of chips) {
      // `Chip(chipColor: .primary, selected:, emphasis: .low)` — `primary` for
      // both, as the widget states it, at the quiet register: a selected chip
      // is the `primary-container` tint, not the solid `primary` fill, so a
      // selected scope never outweighs the search field above it. An
      // unselected chip names no colour, so which `Color` an unselected member
      // is picked from draws the same picture; the pick follows the code
      // rather than the picture.
      // Spelled `Color`, not `Variant`: `bestVariantName` scores a key the set
      // lacks as nothing, so the colour asked for under the wrong axis name
      // would have come back as whichever member enumerates first. `Shape` is
      // spelled for the same reason: the widget names none, so it is
      // `CoreChipShape.defaultShape`.
      const inst = instanceOf(
        page,
        'Chip',
        bestVariantName(page, 'Chip', {
          Color: 'primary',
          Variant: COMPONENTS.chip.axes.variant.default,
          Size: size,
          State: 'enabled',
          Selected: chip.selected ? 'true' : 'false',
          Emphasis: 'low',
          Shape: 'rounded',
        }),
      );
      setInstanceTextNamed(inst, 'Child', chip.label);
      // `scopeChipStyle.borderWidth: 0` — the scope chips carry no border; the
      // selected chip's tint is what marks the scope.
      suppressFieldChrome(inst, lk, {
        borderWidth: optField<Dim>(f.scopeChipStyle, 'borderWidth') ?? null,
      });
      // `scopeChipStyle` is raw-forwarded to `Chip`, so a corner it states is
      // the chip's own — the face and the wash, band and ring that hang off it.
      // It states none: the chip takes the corner of its size row
      // (`widget.size.toChipSize()`, the `Size` picked above), and the instance
      // keeps the radius its member already carries.
      const scopeCorner = optField<{ topLeft: Dim }>(f.scopeChipStyle, 'borderRadius')?.topLeft;
      if (scopeCorner != null) {
        pinComposedCorner(inst, lk, scopeCorner, COMPONENTS.chip.fields.clickableStyle.focusOutlineStyle);
      }
      scope.appendChild(inst);
    }
    c.appendChild(scope);
    scope.layoutSizingHorizontal = 'FILL';
    scopeNodes.push(scope);
    // The rule under the scope row goes with it: `Show scope` off leaves one
    // rule between the search row and the list.
    scopeNodes.push(hostedDivider(page, lk, c, { axes: kPlainDividerAxes }));

    if (pose.empty) {
      // `EmptyState(title:, description:, icon:, action:, emptyStateStyle)`
      // inside the list's floor, so the panel does not jump when results
      // vanish.
      const blank = panel('empty', 'HORIZONTAL', lk, {
        pl: f.emptyPadding.l, pr: f.emptyPadding.r, pt: f.emptyPadding.t, pb: f.emptyPadding.b,
      });
      blank.primaryAxisAlignItems = 'CENTER';
      blank.counterAxisAlignItems = 'CENTER';
      const state = instanceOf(
        page,
        'EmptyState',
        bestVariantName(page, 'EmptyState', { Variant: 'normal', Tone: 'neutral' }),
      );
      setInstanceTextNamed(state, 'Title', kCommandEmptyCopy);
      setInstanceTextNamed(state, 'Description', kCommandEmptyHintCopy);
      setInstanceBoolNamed(state, 'Show action', false);
      blank.appendChild(state);
      // The widget fills the list's width and caps only its text, so the
      // instance takes the slot's width rather than its component's: at the
      // component's own width it overflowed the inline and fullscreen panels.
      state.layoutSizingHorizontal = 'FILL';
      exposed.push(state);
      c.appendChild(blank);
      blank.layoutSizingHorizontal = 'FILL';
      // `emptyStateStyle.minHeight` — the list's floor restated on the
      // composed EmptyState, so the panel does not jump when results vanish.
      bindLayoutBound(blank, lk, 'minHeight', boundOrNull(f.emptyStateStyle.minHeight));
    } else {
      const list = panel('list', 'VERTICAL', lk, {
        pl: pr.listPadding.l, pr: pr.listPadding.r, pt: pr.listPadding.t, pb: pr.listPadding.b,
        gap: f.listSpacing,
      });
      bindLayoutBound(list, lk, 'minHeight', boundOrNull(pr.listMinHeight));
      bindLayoutBound(list, lk, 'maxHeight', boundOrNull(pr.listMaxHeight));
      const heading = panel('heading', 'HORIZONTAL', lk, {});
      // Logical sides — 10 where the text starts; `bindPad` resolves them.
      bindPad(heading, lk, sz.headingPadding);
      const headingLabel = makeLabel(
        kCommandHeadingCopy,
        lk,
        textLabelOpts(lk, textStyleData(f.headingStyle)),
      );
      headingLabel.name = 'heading label';
      heading.appendChild(headingLabel);
      headingLabel.layoutSizingHorizontal = 'FILL';
      list.appendChild(heading);
      heading.layoutSizingHorizontal = 'FILL';
      headingNodes.push(headingLabel);

      const rows: readonly {
        label: string;
        glyph: string;
        active: boolean;
        lines: 1 | 2;
        overline?: string;
        shortcut?: string;
      }[] = [
        { label: '캘린더', glyph: 'calendar', active: true, lines: 1 },
        { label: '이모지 검색', glyph: 'smile', active: false, lines: 1 },
        { label: '계산기', glyph: 'calculator', active: false, lines: 1 },
        { label: '프로필', glyph: 'user', active: false, lines: 2, overline: '계정', shortcut: 'Ctrl+P' },
      ];
      // Each row's `item.icon`, in the tint the row's state hands it
      // (`itemIconStyle` / `itemActiveIconStyle` on the keyboard cursor).
      const glyphSide = dimVal(sz.itemIconStyle.size);
      for (const row of rows) {
        const item = instanceOf(
          page,
          COMMAND_ITEM_NAME,
          `Size=${size}, Active=${row.active}, State=enabled, Lines=${row.lines}`,
        );
        item.name = 'item';
        setInstanceTextNamed(item, 'Child', row.label);
        if (row.overline != null) setInstanceTextNamed(item, 'Overline', row.overline);
        setInstanceBoolNamed(item, 'Show shortcut', row.shortcut != null);
        if (row.shortcut != null) setInstanceTextNamed(item, 'Shortcut', row.shortcut);
        const tint = colorData(
          row.active ? (f.itemActiveIconStyle.color ?? f.itemIconStyle.color) : f.itemIconStyle.color,
        );
        setSlotIcon(item, 'Leading', iconMainIdAt(page, glyphSide), row.glyph, glyphPaint(lk, glyphOpts(lk, tint, glyphSide)));
        list.appendChild(item);
        item.layoutSizingHorizontal = 'FILL';
      }
      c.appendChild(list);
      list.layoutSizingHorizontal = 'FILL';
    }

    if (pose.presentation === 'dialog') {
      hostedDivider(page, lk, c, { axes: kPlainDividerAxes });
      const footer = panel('footer', 'HORIZONTAL', lk, {
        bg: colorData(f.footerBackgroundColor)?.color ?? undefined,
        pl: sz.footerPadding.l, pr: sz.footerPadding.r, pt: sz.footerPadding.t, pb: sz.footerPadding.b,
        gap: f.footerSpacing,
      });
      footer.counterAxisAlignItems = 'CENTER';
      const hintStyle = textStyleData(f.footerStyle);
      const capForeground = colorData(f.kbdStyle.keyTextStyle.color)!;
      for (const hint of kCommandFooterHints) {
        for (const glyph of hint.glyphs) {
          footer.appendChild(
            kbdKey(page, lk, glyph, { size: f.footerKbdIconStyle.size, color: capForeground }),
          );
        }
        // `↑ ↓ 이동` — one label per group, after its last cap.
        footer.appendChild(makeLabel(hint.label, lk, textLabelOpts(lk, hintStyle)));
      }
      c.appendChild(footer);
      footer.layoutSizingHorizontal = 'FILL';
    }
  }
  const set = mount.finish();
  exposeAll(exposed);
  // `scopes` is data — an empty list draws no row. The row's presence is a
  // boolean on the set, off by default: the plain palette is the common one,
  // and the rule under the row hides with it.
  const showScopeProp = defineProp(set, 'Show scope', 'BOOLEAN', false);
  for (const n of scopeNodes) bindVisibleProp(n, showScopeProp);
  const headingProp = defineProp(set, 'Heading', 'TEXT', kCommandHeadingCopy);
  for (const n of headingNodes) bindTextProp(n, headingProp);
  return set;
}

export const COMMAND_BUILDERS: RegistryEntry[] = [
  {
    section: 'Overlay',
    name: 'Command',
    build: buildCommand,
    needs: ['Button', 'Chip', 'CommandItem', 'Divider', 'EmptyState', 'Icon', 'Kbd', 'TextField'],
  },
];
