/// <reference types="@figma/plugin-typings" />

import {
  VarLookup,
  bestVariantName,
  canonicalCollection,
  findComponentByName,
  indexDocumentComponents,
  installNodeIndex,
  instanceOf,
  loadFonts,
  makeLabel,
  solid,
} from './helpers';

// Where the two frames go.
//
// Its own page, because there is no longer a page that holds components to sit
// beside — each one has `❖ {Name}`, and dropping preview frames onto one
// component's page would put them in that component's bounds check.
const kPreviewPageName = '🎨 Theme Preview';

// Which components the Light/Dark frames show, and the axes each one is asked
// for.
//
// Stated as axis PREFS, never as a full variant name. Every set named here
// grew axes after this file was first written: `Button` now spells
// `Variant=…, Size=…, Selected=…, Hover=…, Disabled=…` (576 variants) and
// `Card` spells `Variant=…, Disabled=…, Focused=…`, so the exact names this
// file compared against — `'Variant=primary'`, `'Variant=outlined'` — matched
// nothing and the first of them threw before a single frame was created.
// `bestVariantName` (helpers.ts) scores only the axes named here, which is the
// same fix the builders use: a set that gains a sixth axis still resolves, and
// a renamed axis degrades to "ignored" instead of taking the preview down.
//
// `TextField`, not `Input`: no REGISTRY entry builds an `Input`, and
// SET_RENAMES retires that name on every generate (src/renames.ts). The
// `Variant=Default` value is the one buildTextField mints, and the same pair
// is already spelled this way at the `TextField` use site in
// components/form-fields.ts.
//
// `Badge` names all four of its design axes. Its old `Variant=primary` held a
// colour and a strength in one value; the set now spells them as `Tone` and
// `Variant` (with the form as `Style`), and `primary` is no longer a variant —
// so the old pair scored on `Size` alone and fell to the first `md` member the
// set lists. The pick mirrors the brand badge the widgetbook theme preview
// draws (`theme_preview.stories.dart`, `Badge(tone: .primary)`): primary at
// the widget's default strength, form and size — tonal, label, md.
interface PreviewPick {
  set: string;
  prefs: Record<string, string>;
}

const kPreviewPicks: readonly PreviewPick[] = [
  { set: 'Button', prefs: { Variant: 'primary', Size: 'md' } },
  { set: 'Card', prefs: { Variant: 'outlined' } },
  { set: 'Badge', prefs: { Tone: 'primary', Variant: 'tonal', Style: 'label', Size: 'md' } },
  { set: 'TextField', prefs: { Variant: 'Default', Size: 'md' } },
];

export interface ResolvedPreviewPick {
  set: string;
  /** undefined for a plain COMPONENT — `instanceOf` reads that as "itself". */
  variantName?: string;
}

export interface ResolvedPreviewPicks {
  picks: ResolvedPreviewPick[];
  /** Named components that are not on the page at all. Reported, not thrown. */
  missing: string[];
}

// Which of `wanted` this page can actually show.
//
// Pure and exported so the resolution is drivable outside Figma — the four
// picks used to be an eagerly-evaluated array literal, so the FIRST name that
// resolved to nothing threw and the command produced no frames at all.
//
// A missing component is reported and skipped rather than thrown for the same
// reason `bestVariantName` scores instead of demanding: one component's
// refactor should not delete the whole preview. A pick that resolves to
// nothing renders as absence plus a ⚠ line, never as a substitute component.
export function resolvePreviewPicks(
  page: PageNode,
  wanted: readonly PreviewPick[] = kPreviewPicks,
): ResolvedPreviewPicks {
  const picks: ResolvedPreviewPick[] = [];
  const missing: string[] = [];
  for (const want of wanted) {
    // Document-wide: under one page per component the set is on `❖ {Name}`,
    // never on the page the frames are being drawn on.
    const present = findComponentByName(page, want.set) !== null;
    if (!present) {
      missing.push(want.set);
      continue;
    }
    picks.push({ set: want.set, variantName: bestVariantName(page, want.set, want.prefs) });
  }
  return { picks, missing };
}

// Builds two frames (Light / Dark) whose background is bound to color/surface
// and whose Semantic variable mode is pinned, so the bg + nested component
// colors flip together. Demonstrates theme-bound backgrounds (daisyUI model).
export async function buildThemePreview(): Promise<string[]> {
  const log: string[] = [];

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const collById = new Map<string, string>();
  for (const c of collections) collById.set(c.id, c.name);
  const vars = await figma.variables.getLocalVariablesAsync();
  const lk = new VarLookup(vars, collById);
  await loadFonts(lk);

  // Document-wide index first, and installed: the child lookups in `helpers`
  // resolve through it, and this command runs with no generate pass to have
  // filled it. Before this the command looked for the single legacy page, found
  // nothing on a current document, and refused with "Run Generate Components
  // first" — on a document where every component was already built.
  const index = await indexDocumentComponents();
  installNodeIndex(index);
  if (index.size === 0) throw new Error('Run "Generate Components" first.');

  const existing = figma.root.children.find(
    (p) => p.type === 'PAGE' && p.name === kPreviewPageName,
  ) as PageNode | undefined;
  const page = existing ?? figma.createPage();
  page.name = kPreviewPageName;
  await figma.setCurrentPageAsync(page);
  // Required before touching `.children` on a PageNode under manifest
  // documentAccess: "dynamic-page" — and everything below reads it.
  await page.loadAsync();

  const semantic = collections.find(
    (c) => canonicalCollection(c.name) === 'Semantic',
  );
  if (!semantic) throw new Error('Semantic collection not found — import variables first.');
  const modeByName: Record<string, string> = {};
  for (const m of semantic.modes) modeByName[m.name] = m.modeId;

  // Everything that can fail is resolved BEFORE the stale frames are removed,
  // so a failure leaves the previous run's frames intact instead of clearing
  // the page and then producing nothing.
  const lightMode = modeByName['Light'];
  const darkMode = modeByName['Dark'];
  if (!lightMode || !darkMode) {
    throw new Error(
      'Semantic collection has no Light/Dark modes (modes present: ' +
        `${semantic.modes.map((m) => m.name).join(' | ')}) — re-import variables.`,
    );
  }

  const { picks, missing } = resolvePreviewPicks(page);
  for (const name of missing) {
    log.push(`⚠ ${name} is not in this document — skipped (nothing substituted for it).`);
  }
  if (picks.length === 0) {
    throw new Error(
      `None of the preview components are in this document (${kPreviewPicks
        .map((p) => p.set)
        .join(', ')}) — run "Generate Components" first.`,
    );
  }

  const surfaceVar = lk.sem('surface');
  const onSurfaceVar = lk.sem('on-surface');

  for (const node of page.children.slice()) {
    if (node.type === 'FRAME' && (node.name === 'Theme / Light' || node.name === 'Theme / Dark')) {
      node.remove();
    }
  }

  // An arrow bound after the guards above, not a hoisted `function` — the
  // narrowed `page`/`semantic` consts stay non-null inside it, so nothing here
  // needs a `!` assertion that a later edit could turn into a lie.
  const makeFrame = (label: string, modeId: string, x: number): FrameNode => {
    const frame = figma.createFrame();
    frame.name = `Theme / ${label}`;
    frame.layoutMode = 'VERTICAL';
    frame.primaryAxisSizingMode = 'AUTO';
    frame.counterAxisSizingMode = 'FIXED';
    frame.itemSpacing = 16;
    frame.paddingLeft = 24;
    frame.paddingRight = 24;
    frame.paddingTop = 24;
    frame.paddingBottom = 24;
    frame.cornerRadius = 16;
    frame.fills = [solid(surfaceVar)];
    frame.setExplicitVariableModeForCollection(semantic, modeId);
    const heading = makeLabel(label, lk, {
      size: 18,
      colorVar: onSurfaceVar,
      style: 'SemiBold',
    });
    frame.appendChild(heading);
    heading.layoutSizingHorizontal = 'HUG';
    for (const pick of picks) {
      // A fresh instance per frame — the two frames pin different Semantic
      // modes, so they cannot share one node.
      frame.appendChild(instanceOf(page, pick.set, pick.variantName));
    }
    frame.resize(280, frame.height);
    frame.primaryAxisSizingMode = 'AUTO';
    frame.x = x;
    frame.y = 120;
    return frame;
  };

  makeFrame('Light', lightMode, 780);
  makeFrame('Dark', darkMode, 1100);
  log.push('✓ Theme preview: Light + Dark frames (bg → color/surface)');
  log.push(
    'showing ' +
      picks.map((p) => `${p.set}[${p.variantName ?? 'single component'}]`).join(', '),
  );
  log.push('Background + component colors flip with the frame mode.');
  return log;
}
