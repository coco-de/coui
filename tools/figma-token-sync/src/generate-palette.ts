/// <reference types="@figma/plugin-typings" />

// "Generate Palette" — re-themes the file from the 8 authored inputs of
// `PrimitiveColors.generate` (7 chromatic roles x h/s/l + `neutralHue`),
// supplied as the `color_palette.json` document.
//
// For a brand whose palette is generated. CoUI's own primitives are fixed
// hex (`CouiColorPresets.palette`), not computed from seeds, so this does
// not re-theme CoUI — CoUI's colours change in code and reach Figma through
// the token import.
//
// It creates no new variables: the 64 primitive colors the token import
// already installed are overwritten in place, so the Semantic collection
// (which aliases them by variable id) and every component bound to Semantic
// follow automatically. Numeric primitives are untouched.
//
// The authored JSON carries `s` / `l` as 0-100 because that is what a
// designer reads and writes; Dart's records are 0-1. The conversion happens
// here, and the log echoes a paste-ready Dart snippet in Dart's units so the
// result travels back to a brand's `CoreBrand` palette / an app's
// `AppTheme` without anyone transcribing 64 colors.

import {
  CHROMATIC_ROLES,
  ChromaticRole,
  PaletteInput,
  PaletteSwatch,
  Rgb255,
  generatePrimitivePalette,
} from './color-generator';
import { VarLookup, autoFrame, loadFonts, makeLabel, solid, canonicalCollection } from './helpers';

const PALETTE_PAGE_NAME = '🎨 Palette Generator';
const PALETTE_FRAME_NAME = 'Primitive Palette';
const SWATCH_SIZE = 56;
const SWATCH_RADIUS = 8;
const PERCENT_MAX = 100;
const HUE_MAX = 360;

function toFigmaRgba(c: Rgb255): RGBA {
  return { r: c.r / 255, g: c.g / 255, b: c.b / 255, a: c.a / 255 };
}

// ─── Authored JSON → PaletteInput ───────────────────────────────────────────

function num(raw: unknown, path: string): number {
  if (typeof raw !== 'number' || !isFinite(raw)) {
    throw new Error(`"${path}" must be a number (got ${JSON.stringify(raw)}).`);
  }
  return raw;
}

function inRange(v: number, lo: number, hi: number, path: string): number {
  if (v < lo || v > hi) {
    throw new Error(`"${path}" must be between ${lo} and ${hi} (got ${v}).`);
  }
  return v;
}

function obj(raw: unknown, path: string): Record<string, unknown> {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
    throw new Error(`"${path}" must be an object.`);
  }
  return raw as Record<string, unknown>;
}

/**
 * Parses the `color_palette.json` document. `s` / `l` arrive as 0-100 and
 * leave as 0-1 — `h` is 0-360 in both.
 */
export function parsePaletteJson(rawJson: string): PaletteInput {
  let parsed: unknown;
  try {
    parsed = JSON.parse(rawJson);
  } catch (e) {
    throw new Error(`Invalid JSON: ${String(e)}`);
  }
  const root = obj(parsed, 'root');

  const neutral = obj(root.neutral, 'neutral');
  const neutralHue = inRange(num(neutral.h, 'neutral.h'), 0, HUE_MAX, 'neutral.h');

  const roles = {} as { [K in ChromaticRole]: { h: number; s: number; l: number } };
  for (const role of CHROMATIC_ROLES) {
    const r = obj(root[role], role);
    roles[role] = {
      h: inRange(num(r.h, `${role}.h`), 0, HUE_MAX, `${role}.h`),
      s: inRange(num(r.s, `${role}.s`), 0, PERCENT_MAX, `${role}.s`) / PERCENT_MAX,
      l: inRange(num(r.l, `${role}.l`), 0, PERCENT_MAX, `${role}.l`) / PERCENT_MAX,
    };
  }

  return { neutralHue, ...roles };
}

/** Paste-ready `PrimitiveColors.generate` arguments, in Dart's 0-1 units. */
function dartSnippet(input: PaletteInput): string[] {
  const lines = ['PrimitiveColors.generate('];
  for (const role of CHROMATIC_ROLES) {
    const { h, s, l } = input[role];
    lines.push(`  ${role}HSL: (h: ${h}, s: ${s.toFixed(2)}, l: ${l.toFixed(2)}),`);
  }
  lines.push(`  neutralHue: ${input.neutralHue},`);
  lines.push(');');
  return lines;
}

// ─── Preview ────────────────────────────────────────────────────────────────

function swatchCell(s: PaletteSwatch, variable: Variable, lk: VarLookup): FrameNode {
  const cell = autoFrame(s.step, 'VERTICAL');
  cell.itemSpacing = 4;

  const box = figma.createRectangle();
  box.resize(SWATCH_SIZE, SWATCH_SIZE);
  box.cornerRadius = SWATCH_RADIUS;
  box.fills = [solid(variable)];
  cell.appendChild(box);

  cell.appendChild(makeLabel(s.step, lk, { size: 12, colorVar: lk.sem('on-surface') }));
  return cell;
}

// ─── Command ────────────────────────────────────────────────────────────────

export async function generatePalette(rawJson: string): Promise<string[]> {
  const log: string[] = [];

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const primitives = collections.find(
    (c) => canonicalCollection(c.name) === 'Primitives',
  );
  if (!primitives) {
    throw new Error('Primitives collection not found — run "Import to Variables" first.');
  }
  const valueMode = primitives.modes[0].modeId;

  const existingVars = await figma.variables.getLocalVariablesAsync();
  const collById = new Map<string, string>();
  for (const c of collections) collById.set(c.id, c.name);
  const lk = new VarLookup(existingVars, collById);
  await loadFonts(lk);

  const input = parsePaletteJson(rawJson);
  const swatches = generatePrimitivePalette(input);

  // ─── 1. Overwrite Primitives/color/* in place ─────────────────────────────
  const byName = new Map<string, Variable>();
  for (const v of existingVars) {
    if (v.variableCollectionId === primitives.id) byName.set(v.name, v);
  }

  const bound: { swatch: PaletteSwatch; variable: Variable }[] = [];
  const restored: string[] = [];
  for (const s of swatches) {
    let v = byName.get(s.name);
    if (!v) {
      // Only reachable when the import ran an older exporter (or a swatch was
      // deleted by hand) — recreate it rather than half-theming the file, and
      // say so, because a silently-created variable has no Semantic alias
      // pointing at it.
      v = figma.variables.createVariable(s.name, primitives, 'COLOR');
      byName.set(s.name, v);
      restored.push(s.name);
    }
    v.setValueForMode(valueMode, toFigmaRgba(s.color));
    bound.push({ swatch: s, variable: v });
  }

  log.push(`✓ Repainted ${swatches.length} primitive colors (no variables added).`);
  if (restored.length) {
    log.push(
      `⚠ ${restored.length} were missing and had to be created — re-run ` +
        '"Import to Variables" so the Semantic collection aliases them: ' +
        restored.join(', '),
    );
  }
  log.push('  Semantic + components follow automatically (alias by variable id).');

  // ─── 2. Preview page ──────────────────────────────────────────────────────
  let page = figma.root.children.find((p) => p.name === PALETTE_PAGE_NAME) as PageNode | undefined;
  if (!page) {
    page = figma.createPage();
    page.name = PALETTE_PAGE_NAME;
  }
  await figma.setCurrentPageAsync(page);

  for (const node of page.children.slice()) {
    if (node.name === PALETTE_FRAME_NAME) node.remove();
  }

  const root = autoFrame(PALETTE_FRAME_NAME, 'VERTICAL');
  root.itemSpacing = 24;
  root.appendChild(
    makeLabel(`Primitive Palette  ·  neutral h${input.neutralHue}`, lk, {
      size: 16,
      colorVar: lk.sem('on-surface'),
      style: 'SemiBold',
    }),
  );

  const groups = ['neutral', ...CHROMATIC_ROLES];
  for (const group of groups) {
    const rows = bound.filter((b) => b.swatch.group === group);
    if (!rows.length) continue;

    const section = autoFrame(group, 'VERTICAL');
    section.itemSpacing = 8;
    section.appendChild(
      makeLabel(group, lk, { size: 12, colorVar: lk.sem('on-surface-variant') }),
    );

    const strip = autoFrame('Swatches', 'HORIZONTAL');
    strip.itemSpacing = 8;
    for (const r of rows) strip.appendChild(swatchCell(r.swatch, r.variable, lk));
    section.appendChild(strip);

    root.appendChild(section);
  }

  root.x = 80;
  root.y = 80;

  log.push(`✓ Preview: "${PALETTE_PAGE_NAME}" / ${PALETTE_FRAME_NAME}`);
  log.push('');
  log.push('Paste into color_presets.dart / AppTheme (Dart units, s·l are 0-1):');
  for (const line of dartSnippet(input)) log.push(`  ${line}`);

  return log;
}
