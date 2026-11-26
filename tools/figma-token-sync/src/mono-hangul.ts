/// <reference types="@figma/plugin-typings" />

// Hangul inside monospace text a designer wrote — painted in the text face.
//
// The monospace family has no Hangul. Both platforms fall back to the text
// face for it; Figma cannot be told a fallback and draws a missing glyph in a
// face it picks itself, so the canvas and the code part ways on every Hangul
// character inside code text. Generate paints the labels it draws
// (`makeLabel`, and again after a text style lands). It cannot reach text a
// designer typed into a product file — that text belongs to the file, not to
// the library — so this command does the same painting over the selection, or
// the current page when nothing is selected.
//
// What it changes: the font (and the `fontFamily` binding) of each Hangul run
// that is drawn in the exported monospace family. Size, line height and
// tracking are left alone. Text in another monospace family is reported, not
// touched — that family is not the one code draws, and moving it is a
// different decision. A character typed later takes its neighbour's font, so
// text edited after this runs needs it again.

import { canonicalCollection, VarLookup } from './variables';
import { exportedMonoFamily } from './compat/v1';
import { hangulRuns, paintHangulRunsSans, textFaceOf, type SansTarget } from './text-nodes';

/** What one pass over a set of text nodes did — the command's log reads it. */
export interface MonoHangulReport {
  /** TEXT nodes looked at. */
  scanned: number;
  /** Nodes that had a Hangul run in the monospace family and were painted. */
  painted: number;
  /** Ranges written across those nodes. */
  ranges: number;
  /** Nodes whose Hangul sits in a monospace family the export does not name. */
  otherMono: { name: string; family: string }[];
  /** Nodes left as they were: a face they needed did not load, or Figma
   *  refused the write (a layer of a library component's own main). */
  skipped: { name: string; reason: string }[];
}

/**
 * Paints the monospace Hangul of every node in [nodes]. Separate from the
 * command so it can be driven without a page: scope and the text face are the
 * caller's.
 */
export async function repaintMonoHangulIn(
  nodes: readonly TextNode[],
  sans: SansTarget,
  mono: string,
): Promise<MonoHangulReport> {
  const report: MonoHangulReport = { scanned: 0, painted: 0, ranges: 0, otherMono: [], skipped: [] };
  const loaded = new Set<string>();
  const load = async (font: FontName): Promise<void> => {
    const key = JSON.stringify([font.family, font.style]);
    if (loaded.has(key)) return;
    await figma.loadFontAsync(font);
    loaded.add(key);
  };
  for (const t of nodes) {
    report.scanned += 1;
    const text = t.characters;
    const runs = hangulRuns(text);
    if (runs.length === 0) continue;
    // Which families the Hangul sits in — read before anything is loaded, so a
    // node with nothing to paint costs one read.
    const segs = runs.flatMap(([start, end]) => t.getStyledTextSegments(['fontName'], start, end));
    const inMono = segs.filter((s) => s.fontName.family === mono);
    const elsewhere = segs.find((s) => s.fontName.family !== mono && /mono/i.test(s.fontName.family));
    if (elsewhere != null) report.otherMono.push({ name: t.name, family: elsewhere.fontName.family });
    if (inMono.length === 0) continue;
    try {
      // A range write needs every face the node draws in loaded, not only the
      // ones it writes.
      for (const font of t.getRangeAllFontNames(0, text.length)) await load(font);
      for (const s of inMono) await load({ family: sans.family, style: textFaceOf(s.fontName.style) });
    } catch (e) {
      report.skipped.push({ name: t.name, reason: String(e) });
      continue;
    }
    // One node's refusal is reported, not fatal: the rest of the scope is
    // still the designer's to have painted. A refusal part way through a node
    // leaves its earlier runs painted, which the log's name points at.
    try {
      report.ranges += paintHangulRunsSans(t, sans, { onlyFamily: mono, text });
      report.painted += 1;
    } catch (e) {
      report.skipped.push({ name: t.name, reason: String(e) });
    }
  }
  return report;
}

/**
 * The text face to paint Hangul in, and the variable to bind it to: from this
 * document's own variables when it has them, else from an enabled library's
 * `Primitives`. A product file usually has only the library's — that is the
 * file this command is for.
 */
export async function resolveSansTarget(): Promise<SansTarget> {
  const local = await localSansTarget();
  if (local != null) return local;
  const fromLibrary = await librarySansTarget();
  if (fromLibrary != null) return fromLibrary;
  throw new Error(
    '본문 서체 변수를 찾지 못했다 — 이 파일의 로컬 변수에도, 켜진 라이브러리의 ' +
      'Primitives 에도 font/family/* 가 없다. CoUI 라이브러리를 Assets 에서 켠 뒤 다시 돌린다.',
  );
}

async function localSansTarget(): Promise<SansTarget | null> {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const collById = new Map(collections.map((c) => [c.id, c.name]));
  const lk = new VarLookup(await figma.variables.getLocalVariablesAsync(), collById);
  try {
    return { family: lk.fontFamilyName('sans'), variable: lk.fontFamily('sans') };
  } catch {
    return null;
  }
}

/**
 * Whether a `Primitives` variable named [name] states the text face — the
 * convention `VarLookup.fontFamily('sans')` resolves by: the family variable
 * that does not name itself monospace. Shared with the consumer-file check
 * (`consumer-audit.ts`), which asks the same question of the same library
 * read-only, so the two cannot name different text faces.
 */
export function isSansFamilyVariableName(name: string): boolean {
  return name === 'font-family/sans' || (name.startsWith('font/family/') && !/mono/i.test(name));
}

async function librarySansTarget(): Promise<SansTarget | null> {
  const libraries = await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync();
  for (const lib of libraries) {
    if (canonicalCollection(lib.name) !== 'Primitives') continue;
    const vars = await figma.teamLibrary.getVariablesInLibraryCollectionAsync(lib.key);
    const candidates = vars.filter((v) => isSansFamilyVariableName(v.name));
    for (const candidate of candidates) {
      const variable = await figma.variables.importVariableByKeyAsync(candidate.key);
      const value = Object.values(variable.valuesByMode)[0];
      if (typeof value === 'string' && value !== '') return { family: value, variable };
    }
  }
  return null;
}

/** The command: the selection, or the current page when nothing is selected. */
export async function repaintMonoHangul(): Promise<string[]> {
  const mono = exportedMonoFamily();
  if (mono == null) {
    throw new Error('이 플러그인의 내보내기에는 고정폭 서체가 없다 — 칠할 기준이 없다');
  }
  const selection = figma.currentPage.selection;
  const roots: readonly SceneNode[] = selection.length > 0 ? selection : figma.currentPage.children;
  const scope =
    selection.length > 0 ? `선택한 ${selection.length}개 노드` : `현재 페이지 (${figma.currentPage.name})`;
  // By id: a selected frame and a text inside it name the same node twice.
  const byId = new Map<string, TextNode>();
  for (const root of roots) {
    if (root.type === 'TEXT') byId.set(root.id, root);
    if ('findAllWithCriteria' in root) {
      for (const t of root.findAllWithCriteria({ types: ['TEXT'] })) byId.set(t.id, t);
    }
  }
  const nodes = [...byId.values()];
  const sans = await resolveSansTarget();
  const r = await repaintMonoHangulIn(nodes, sans, mono);
  const log = [
    `범위: ${scope}`,
    `글 ${r.scanned}개 중 ${mono} 안 한글이 있는 ${r.painted}개 — 구간 ${r.ranges}개를 ${sans.family} 로 칠했다` +
      (sans.variable == null ? ' (변수 없이 글꼴만)' : ''),
  ];
  if (r.painted === 0) log.push(`${mono} 로 그린 한글이 없다 — 변경 없음.`);
  for (const o of r.otherMono) {
    log.push(`⚠ "${o.name}": 한글이 ${o.family} 에 있다 — 내보낸 고정폭(${mono})이 아니라 건드리지 않았다`);
  }
  for (const f of r.skipped) {
    log.push(`⚠ "${f.name}": 건너뛰었다 — ${f.reason}`);
  }
  log.push('글을 고쳐 쓰면 새 글자가 옆 글자의 글꼴을 따르므로, 고친 뒤 다시 돌린다.');
  return log;
}
