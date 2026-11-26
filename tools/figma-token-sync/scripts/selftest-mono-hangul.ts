// Self-test for the Hangul painting inside monospace text — `hangulRuns` and
// `paintHangulRunsSans` (src/text-nodes.ts), the two places that call it
// (`makeLabel`, and the text-style attach in src/text-style-attach.ts), and the
// consumer-file command (src/mono-hangul.ts). Runs under plain Node via
// `npm run selftest`.
//
// ## What it defends
//
// The monospace face has no Hangul. Both platforms draw a missing glyph in the
// text face; Figma draws it in a face it picks itself, so every Hangul
// character inside code text differs between the canvas and the code. The
// builder paints those runs in the text face — and a text style, attached
// after the label is drawn, resets every range to its own family, so the paint
// has to happen again after the style lands.
//
// Each of those is breakable on its own and none of them shows up as a wrong
// number anywhere else: the run boundaries (one block forgotten, a surrogate
// pair miscounted), the writes (a size or line height touched, which would
// break the 21px line grid), the attach order (painted before the style, which
// then undoes it), the gate (every label's characters read on a hot path).
//
// What this cannot see: the real canvas. Whether a range write leaves the rest
// of a styled node on its style is not modelled here — the fake resets ranges
// the way the canvas was described to, and the rest is unmeasured.

import { textLabelOpts } from '../src/helpers';
import { roleMetrics, type RoleMetrics } from '../src/compat/v1';
import { createTextStyleAttacher, faceKeyOf } from '../src/text-style-attach';
import {
  hangulRuns,
  hasHangul,
  loadFonts,
  makeLabel,
  paintHangulRunsSans,
  resetPendingTextStyles,
  takePendingTextStyles,
  textFaceOf,
  type SansTarget,
} from '../src/text-nodes';
import { repaintMonoHangul, repaintMonoHangulIn, resolveSansTarget } from '../src/mono-hangul';
import { VarLookup } from '../src/variables';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(id: string): {
  readFileSync(path: string, encoding: string): string;
  join(...parts: string[]): string;
};

const { readFileSync } = require('fs');
const { join } = require('path');

let failures = 0;
const asyncChecks: (() => Promise<void>)[] = [];

function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

// Run in order, after the synchronous checks: several share module state
// (`loadFonts`' face record) and the fake document.
function checkAsync(label: string, fn: () => Promise<void>): void {
  asyncChecks.push(async () => {
    try {
      await fn();
      console.log(`  ok  ${label}`);
    } catch (e) {
      failures++;
      console.error(`FAIL  ${label}\n      ${String(e)}`);
    }
  });
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// ─── A text node that models ranges ─────────────────────────────────────────
//
// Per-character font and `fontFamily` binding, so a range write can be read
// back exactly where it landed. Every write is logged in order, and every read
// of `characters` is counted, so "nothing touched" and "nothing read" are
// assertions rather than hopes.

interface Write {
  op: string;
  start?: number;
  end?: number;
  value?: unknown;
}

interface FakeStyle {
  id: string;
  name: string;
  fontName: FontName;
  fontSize: number;
  lineHeight: LineHeight;
  letterSpacing: LetterSpacing;
}
const fakeStyles = new Map<string, FakeStyle>();

class FakeText {
  readonly type = 'TEXT';
  readonly removed = false;
  id: string;
  name = 'text';
  private chars = '';
  private node: FontName = { family: 'Pretendard', style: 'Regular' };
  fonts: FontName[] = [];
  familyBinding: (string | null)[] = [];
  bound: Record<string, string> = {};
  writes: Write[] = [];
  characterReads = 0;
  fontSize = 0;
  lineHeight: LineHeight = { unit: 'AUTO' };
  letterSpacing: LetterSpacing = { unit: 'PERCENT', value: 0 };
  fills: unknown = [];
  opacity = 1;
  textDecoration = 'NONE';
  textStyleId = '';
  /** When set, the next range font write throws with it — a write Figma refuses. */
  refuseRangeWrite: string | null = null;

  constructor(id: string) {
    this.id = id;
  }

  get characters(): string {
    this.characterReads++;
    return this.chars;
  }
  set characters(v: string) {
    this.chars = v;
    this.fonts = Array.from({ length: v.length }, () => this.node);
    this.familyBinding = Array.from({ length: v.length }, () => this.bound.fontFamily ?? null);
  }
  get fontName(): FontName {
    return this.node;
  }
  set fontName(f: FontName) {
    this.node = f;
    this.fonts = this.fonts.map(() => f);
    this.writes.push({ op: 'fontName', value: f });
  }

  setBoundVariable(field: string, v: { name: string } | null): void {
    this.writes.push({ op: v == null ? `unbind:${field}` : `bind:${field}`, value: v?.name });
    if (v == null) delete this.bound[field];
    else this.bound[field] = v.name;
    if (field === 'fontFamily') this.familyBinding = this.familyBinding.map(() => v?.name ?? null);
  }

  private range(op: string, start: number, end: number): void {
    if (!(Number.isInteger(start) && Number.isInteger(end) && start >= 0 && start < end && end <= this.chars.length)) {
      throw new Error(`${op}(${start}, ${end}) outside ${this.chars.length} characters`);
    }
  }

  setRangeFontName(start: number, end: number, font: FontName): void {
    this.range('setRangeFontName', start, end);
    if (this.refuseRangeWrite != null) throw new Error(this.refuseRangeWrite);
    this.writes.push({ op: 'rangeFont', start, end, value: font });
    for (let i = start; i < end; i++) this.fonts[i] = font;
  }

  setRangeBoundVariable(start: number, end: number, field: string, v: { name: string }): void {
    this.range('setRangeBoundVariable', start, end);
    this.writes.push({ op: `rangeBind:${field}`, start, end, value: v.name });
    if (field === 'fontFamily') for (let i = start; i < end; i++) this.familyBinding[i] = v.name;
  }

  getStyledTextSegments(fields: string[], start: number, end: number) {
    this.range('getStyledTextSegments', start, end);
    assert(fields.length === 1 && fields[0] === 'fontName', `segments read ${fields.join(',')}`);
    this.writes.push({ op: 'readSegments', start, end });
    const out: { characters: string; start: number; end: number; fontName: FontName }[] = [];
    for (let i = start; i < end; i++) {
      const f = this.fonts[i];
      const last = out[out.length - 1];
      if (last != null && last.fontName.family === f.family && last.fontName.style === f.style) last.end = i + 1;
      else out.push({ characters: '', start: i, end: i + 1, fontName: f });
    }
    for (const seg of out) seg.characters = this.chars.slice(seg.start, seg.end);
    return out;
  }

  getRangeAllFontNames(start: number, end: number): FontName[] {
    const seen = new Map<string, FontName>();
    for (let i = start; i < end; i++) seen.set(JSON.stringify(this.fonts[i]), this.fonts[i]);
    return [...seen.values()];
  }

  async setTextStyleIdAsync(id: string): Promise<void> {
    const style = fakeStyles.get(id);
    if (style == null) throw new Error(`no style ${id}`);
    // A style lays its whole bundle over the node — every range included.
    this.writes.push({ op: 'style', value: id });
    this.textStyleId = id;
    this.node = style.fontName;
    this.fonts = this.fonts.map(() => style.fontName);
    this.fontSize = style.fontSize;
    this.lineHeight = style.lineHeight;
    this.letterSpacing = style.letterSpacing;
    this.textDecoration = 'NONE';
  }

  /** The family each character draws in. */
  families(): string[] {
    return this.fonts.map((f) => f.family);
  }
}

let nodeSeq = 0;
const loadedFonts: string[] = [];
let refuseFont: ((font: FontName) => boolean) | null = null;

interface FakeVariable {
  id: string;
  name: string;
  key?: string;
  variableCollectionId: string;
  valuesByMode: Record<string, unknown>;
}

const doc = {
  localVariables: [] as FakeVariable[],
  localCollections: [] as { id: string; name: string }[],
  libraryCollections: [] as { key: string; name: string }[],
  libraryVariables: new Map<string, FakeVariable[]>(),
  imported: [] as string[],
  page: { name: 'Draft.v2', selection: [] as unknown[], children: [] as unknown[] },
};

(globalThis as { figma?: unknown }).figma = {
  createText(): FakeText {
    return new FakeText(`T:${++nodeSeq}`);
  },
  async loadFontAsync(font: FontName): Promise<void> {
    if (refuseFont?.(font)) throw new Error(`font ${font.family} ${font.style} is not available`);
    loadedFonts.push(`${font.family} ${font.style}`);
  },
  get currentPage() {
    return doc.page;
  },
  variables: {
    async getLocalVariableCollectionsAsync() {
      return doc.localCollections;
    },
    async getLocalVariablesAsync() {
      return doc.localVariables;
    },
    async importVariableByKeyAsync(key: string) {
      for (const vars of doc.libraryVariables.values()) {
        const v = vars.find((x) => x.key === key);
        if (v != null) {
          doc.imported.push(key);
          return v;
        }
      }
      throw new Error(`no library variable ${key}`);
    },
  },
  teamLibrary: {
    async getAvailableLibraryVariableCollectionsAsync() {
      return doc.libraryCollections;
    },
    async getVariablesInLibraryCollectionAsync(key: string) {
      return doc.libraryVariables.get(key) ?? [];
    },
  },
};

function fakeVar(coll: string, name: string, valuesByMode: Record<string, unknown>): FakeVariable {
  return { id: `V:${coll}/${name}`, name, variableCollectionId: coll, valuesByMode };
}

function catalog(): VarLookup {
  const vars = [
    // `textLabelOpts` resolves its fallback colour through `sem` even when the
    // label is then painted with `rawColor`.
    fakeVar('s', 'color/on-surface', { Light: 0, Dark: 0 }),
    fakeVar('p', 'font/family/Pretendard', { Value: 'Pretendard' }),
    fakeVar('p', 'font/family/JetBrains Mono', { Value: 'JetBrains Mono' }),
    fakeVar('p', 'font/family/Geist Mono', { Value: 'Geist Mono' }),
    ...[11, 12, 13, 14].map((n) => fakeVar('p', `font/size/${n}`, { Value: n })),
    fakeVar('t', 'font-size/code-sm', { Mobile: 12, Tablet: 12, Desktop: 12 }),
    fakeVar('t', 'letter-spacing/code-sm', { Mobile: 0, Tablet: 0, Desktop: 0 }),
  ];
  return new VarLookup(
    vars as unknown as Variable[],
    new Map([
      ['s', '1-1. Semantic/ Color · CoUI'],
      ['p', '0. Primitives'],
      ['t', '1-2. Semantic/ Typography'],
    ]),
  );
}

const SANS_VAR = { name: 'font/family/Pretendard' };
const SANS: SansTarget = { family: 'Pretendard', variable: SANS_VAR as unknown as Variable };

function textNode(text: string, font: FontName): FakeText {
  const t = new FakeText(`T:${++nodeSeq}`);
  t.fontName = font;
  t.characters = text;
  t.writes = [];
  t.characterReads = 0;
  return t;
}

const MONO: FontName = { family: 'Geist Mono', style: 'Regular' };

// ─── hangulRuns ─────────────────────────────────────────────────────────────

console.log('selftest: mono Hangul');

check('runs: mixed code and Hangul — each run is its own [start, end)', () => {
  assertEq(hangulRuns('막은 호스트 없음'), [[0, 2], [3, 6], [7, 9]], 'spaces split runs');
  const text = '_book() → 예약하기';
  const at = text.indexOf('예');
  assertEq(hangulRuns(text), [[at, at + 4]], 'the Hangul tail of a code line');
});

check('runs: none in Latin, an emoji, or an empty string', () => {
  assertEq(hangulRuns('const x = 1;'), [], 'Latin');
  assertEq(hangulRuns('😀'), [], 'a surrogate pair');
  assertEq(hangulRuns(''), [], 'empty');
  assert(!hasHangul('const x = 1;') && hasHangul('a가'), 'hasHangul agrees');
});

check('runs: Hangul only — one run, whatever the block', () => {
  assertEq(hangulRuns('ㄱㄴ'), [[0, 2]], 'compatibility Jamo');
  assertEq(hangulRuns('가'), [[0, 1]], 'one syllable');
  assertEq(hangulRuns('ㄱ가ᄀ'), [[0, 3]], 'three blocks side by side are one run');
});

check('runs: adjacent runs split by one character stay two', () => {
  assertEq(hangulRuns('a가b나'), [[1, 2], [3, 4]], 'interleaved');
  assertEq(hangulRuns('😀가'), [[2, 3]], 'counted in UTF-16 units, past a surrogate pair');
});

check('runs: every block edge — in at the bounds, out one past', () => {
  const inside = [0x1100, 0x11ff, 0x3130, 0x318f, 0xac00, 0xd7a3];
  const outside = [0x10ff, 0x1200, 0x312f, 0x3190, 0xabff, 0xd7a4];
  for (const c of inside) assertEq(hangulRuns(String.fromCharCode(c)), [[0, 1]], `U+${c.toString(16)} in`);
  for (const c of outside) assertEq(hangulRuns(String.fromCharCode(c)), [], `U+${c.toString(16)} out`);
});

// ─── paintHangulRunsSans ────────────────────────────────────────────────────

check('paint: writes the text face and its variable on exactly the runs — nothing else', () => {
  const t = textNode('막은 _x 없음', MONO);
  const n = paintHangulRunsSans(t as unknown as TextNode, SANS, { face: 'Regular' });
  assertEq(n, 2, 'two ranges written');
  assertEq(
    t.writes.map((w) => [w.op, w.start, w.end]),
    [
      ['rangeFont', 0, 2],
      ['rangeBind:fontFamily', 0, 2],
      ['rangeFont', 6, 8],
      ['rangeBind:fontFamily', 6, 8],
    ],
    'only range font and family writes, in run order',
  );
  assertEq(t.families(), ['Pretendard', 'Pretendard', ...Array(4).fill('Geist Mono'), 'Pretendard', 'Pretendard'], 'per character');
  assertEq(t.writes[0].value, { family: 'Pretendard', style: 'Regular' }, 'the face asked for');
  assertEq(t.fontSize, 0, 'size untouched');
  assertEq(t.lineHeight, { unit: 'AUTO' }, 'line height untouched');
});

check('paint: no variable → the font alone', () => {
  const t = textNode('가a', MONO);
  paintHangulRunsSans(t as unknown as TextNode, { family: 'Pretendard', variable: null }, { face: 'Regular' });
  assertEq(t.writes.map((w) => w.op), ['rangeFont'], 'no binding');
});

check('paint: no Hangul → no range call and no segment read at all', () => {
  const t = textNode('return x;', MONO);
  assertEq(paintHangulRunsSans(t as unknown as TextNode, SANS), 0, 'zero ranges');
  assertEq(t.writes, [], 'nothing written or read');
});

check('paint: a run in two weights keeps each weight, read from the segments', () => {
  const t = textNode('가나다', MONO);
  t.setRangeFontName(1, 3, { family: 'Geist Mono', style: 'Semi Bold' });
  t.writes = [];
  paintHangulRunsSans(t as unknown as TextNode, SANS);
  const fonts = t.writes.filter((w) => w.op === 'rangeFont').map((w) => [w.start, w.end, (w.value as FontName).style]);
  assertEq(fonts, [[0, 1, 'Regular'], [1, 3, 'SemiBold']], 'Regular, then SemiBold spelled the text face way');
});

check('paint: onlyFamily leaves a segment in another family alone', () => {
  const t = textNode('가나', MONO);
  t.setRangeFontName(1, 2, { family: 'JetBrains Mono', style: 'Regular' });
  t.writes = [];
  paintHangulRunsSans(t as unknown as TextNode, SANS, { onlyFamily: 'Geist Mono' });
  assertEq(t.families(), ['Pretendard', 'JetBrains Mono'], 'only the exported mono is painted');
});

check('textFaceOf: spellings of a weight meet, an unknown one is kept', () => {
  assertEq(textFaceOf('Semi Bold'), 'SemiBold', 'space');
  assertEq(textFaceOf('extrabold'), 'ExtraBold', 'case');
  assertEq(textFaceOf('Italic'), 'Italic', 'unknown');
});

// ─── makeLabel ───────────────────────────────────────────────────────────────

const lk = catalog();

check('makeLabel: a mono label paints its Hangul in the label face', () => {
  const t = makeLabel('_book() → 예약', lk, {
    size: 12,
    style: 'Medium',
    family: 'mono',
    rawColor: { r: 0, g: 0, b: 0 },
  }) as unknown as FakeText;
  const at = '_book() → '.length;
  assertEq(t.families().slice(at), ['Pretendard', 'Pretendard'], 'the Hangul');
  assertEq(t.families()[0], 'Geist Mono', 'the code');
  const font = t.writes.find((w) => w.op === 'rangeFont');
  assertEq((font?.value as FontName).style, 'Medium', 'in the label face');
  assertEq(t.familyBinding.slice(at), ['font/family/Pretendard', 'font/family/Pretendard'], 'bound to the text face');
});

check('makeLabel: a sans label is not painted — its Hangul is already in the text face', () => {
  const t = makeLabel('예약', lk, { size: 12, rawColor: { r: 0, g: 0, b: 0 } }) as unknown as FakeText;
  assert(!t.writes.some((w) => w.op.startsWith('range')), 'no range writes');
});

// ─── the attach ──────────────────────────────────────────────────────────────

checkAsync('attach: the style resets the Hangul to mono; the attach paints it back, after the unbind', async () => {
  const m = roleMetrics('codeSm') as RoleMetrics;
  fakeStyles.set('S:code-sm', {
    id: 'S:code-sm',
    name: 'Code/SM',
    fontName: MONO,
    fontSize: m.fontSize as number,
    lineHeight: { unit: 'PIXELS', value: m.lineHeightPx as number },
    letterSpacing: { unit: 'PIXELS', value: 0 },
  });
  const styleIndex = new Map([['Code/SM', fakeStyles.get('S:code-sm') as unknown as TextStyle]]);
  const attacher = createTextStyleAttacher(styleIndex, new Set([faceKeyOf(MONO)]), () => undefined, {
    sans: SANS,
    isMonoRole: (role) => role === 'codeSm',
  });
  resetPendingTextStyles();
  const o = textLabelOpts(lk, { fontSize: null, fontWeight: null, lineHeight: null, color: null, role: 'codeSm' });
  o.rawColor = { r: 0, g: 0, b: 0 };
  const t = makeLabel('경로 /a/b', lk, o) as unknown as FakeText;
  t.writes = [];
  const queued = takePendingTextStyles();
  assertEq(queued.length, 1, 'the code label kept its role');
  await attacher.attach(queued);
  assertEq(t.textStyleId, 'S:code-sm', 'wears Code/SM');
  assertEq(t.families(), ['Pretendard', 'Pretendard', ...Array(5).fill('Geist Mono')], 'Hangul back in the text face');
  assertEq(t.familyBinding.slice(0, 2), ['font/family/Pretendard', 'font/family/Pretendard'], 'and bound to it');
  const order = t.writes.map((w) => w.op);
  const style = order.indexOf('style');
  const unbind = order.indexOf('unbind:fontFamily');
  const paint = order.indexOf('rangeFont');
  assert(style >= 0 && unbind > style && paint > unbind, `order style → unbind → paint, got ${order.join(' ')}`);
  assertEq(t.lineHeight, { unit: 'PIXELS', value: m.lineHeightPx as number }, 'the line box untouched by the paint');
  assertEq(attacher.stats.hangulRuns, 1, 'counted');
});

checkAsync('attach: a label whose role is not mono is not painted — and its text is not read', async () => {
  fakeStyles.set('S:x', {
    id: 'S:x',
    name: 'Label/Large',
    fontName: { family: 'Pretendard', style: 'Medium' },
    fontSize: 14,
    lineHeight: { unit: 'PERCENT', value: 140 },
    letterSpacing: { unit: 'PIXELS', value: -0.14 },
  });
  const attacher = createTextStyleAttacher(
    new Map([['Label/Large', fakeStyles.get('S:x') as unknown as TextStyle]]),
    new Set([faceKeyOf({ family: 'Pretendard', style: 'Medium' })]),
    () => undefined,
    { sans: SANS, isMonoRole: () => false },
  );
  const t = textNode('라벨', { family: 'Pretendard', style: 'Medium' });
  await attacher.attach([{ node: t as unknown as TextNode, role: 'labelLarge' }]);
  assertEq(t.characterReads, 0, 'characters never read');
  assert(!t.writes.some((w) => w.op.startsWith('range')), 'no range writes');
  assertEq(attacher.stats.hangulRuns, 0, 'nothing counted');
});

checkAsync('attach: a repaint Figma refuses costs the Hangul, not the style', async () => {
  const attacher = createTextStyleAttacher(
    new Map([['Code/SM', fakeStyles.get('S:code-sm') as unknown as TextStyle]]),
    new Set([faceKeyOf(MONO)]),
    () => undefined,
    { sans: SANS, isMonoRole: () => true },
  );
  const t = textNode('가', MONO);
  t.refuseRangeWrite = 'in setRangeFontName: refused';
  await attacher.attach([{ node: t as unknown as TextNode, role: 'codeSm' }]);
  assertEq(t.textStyleId, 'S:code-sm', 'the style is on');
  assertEq(attacher.stats.hangulFailed, 1, 'the failure is counted');
  assert((attacher.stats.hangulFirstError ?? '').includes('refused'), 'with its reason');
});

// ─── the mono faces loadFonts records ────────────────────────────────────────

checkAsync('loadFonts: a mono face that will not load draws in the text face, unpainted and unbound to mono', async () => {
  refuseFont = (f) => f.family === 'Geist Mono';
  const report = await loadFonts(lk);
  refuseFont = null;
  assert(report.monoNote != null && report.monoNote.includes('Geist Mono'), `note: ${String(report.monoNote)}`);
  const t = makeLabel('가 x', lk, { size: 12, family: 'mono', rawColor: { r: 0, g: 0, b: 0 } }) as unknown as FakeText;
  assertEq(t.fontName.family, 'Pretendard', 'drawn in the text face');
  assertEq(t.bound.fontFamily, 'font/family/Pretendard', 'and bound to it');
  assert(!t.writes.some((w) => w.op.startsWith('range')), 'nothing to paint');
  // And back: with the faces loaded, mono draws as mono again.
  const ok = await loadFonts(lk);
  assertEq(ok.monoNote, null, 'no note when every face loads');
  const again = makeLabel('x', lk, { size: 12, family: 'mono', rawColor: { r: 0, g: 0, b: 0 } }) as unknown as FakeText;
  assertEq(again.fontName.family, 'Geist Mono', 'mono again');
});

// ─── the command ─────────────────────────────────────────────────────────────

checkAsync('command core: mono painted, sans untouched, another mono reported, a missing face skipped', async () => {
  const mono = textNode('막은 호스트', MONO);
  const sans = textNode('예약', { family: 'Pretendard', style: 'Regular' });
  const old = textNode('예약', { family: 'JetBrains Mono', style: 'Regular' });
  const bold = textNode('가', { family: 'Geist Mono', style: 'Bold' });
  refuseFont = (f) => f.family === 'Pretendard' && f.style === 'Bold';
  const r = await repaintMonoHangulIn([mono, sans, old, bold] as unknown as TextNode[], SANS, 'Geist Mono');
  refuseFont = null;
  assertEq(mono.families(), ['Pretendard', 'Pretendard', 'Geist Mono', 'Pretendard', 'Pretendard', 'Pretendard'], 'painted');
  assert(!sans.writes.some((w) => w.op.startsWith('range')), 'sans untouched');
  assertEq(old.families(), ['JetBrains Mono', 'JetBrains Mono'], 'the other mono untouched');
  assertEq(r.otherMono, [{ name: 'text', family: 'JetBrains Mono' }], 'and reported');
  assertEq(r.skipped.length, 1, 'the Bold one skipped');
  assertEq(bold.families(), ['Geist Mono'], 'and left as it was');
  assertEq([r.scanned, r.painted, r.ranges], [4, 1, 2], 'the counts');
});

checkAsync('command core: a node Figma refuses to write is reported, and the rest still painted', async () => {
  const locked = textNode('가', MONO);
  locked.refuseRangeWrite = 'in setRangeFontName: cannot edit a remote component';
  const open = textNode('나', MONO);
  const r = await repaintMonoHangulIn([locked, open] as unknown as TextNode[], SANS, 'Geist Mono');
  assertEq(r.skipped.map((x) => x.reason.includes('remote')), [true], 'the refusal, with its reason');
  assertEq(open.families(), ['Pretendard'], 'the next node painted');
  assertEq(r.painted, 1, 'counted once');
});

checkAsync('command: the text face comes from local variables first', async () => {
  doc.localCollections = [{ id: 'p', name: '0. Primitives' }];
  doc.localVariables = [
    fakeVar('p', 'font/family/Pretendard', { Value: 'Pretendard' }),
    fakeVar('p', 'font/family/Geist Mono', { Value: 'Geist Mono' }),
  ];
  const t = await resolveSansTarget();
  assertEq(t.family, 'Pretendard', 'family');
  assertEq((t.variable as unknown as FakeVariable | null)?.name, 'font/family/Pretendard', 'variable');
});

checkAsync('command: a product file with only the library imports the library variable', async () => {
  doc.localCollections = [];
  doc.localVariables = [];
  doc.libraryCollections = [{ key: 'L:prim', name: '0. Primitives' }];
  const lib = (name: string, value: string): FakeVariable => ({ ...fakeVar('lib', name, { Value: value }), key: `K:${name}` });
  doc.libraryVariables.set('L:prim', [lib('font/family/Geist Mono', 'Geist Mono'), lib('font/family/Pretendard', 'Pretendard')]);
  const t = await resolveSansTarget();
  assertEq(t.family, 'Pretendard', 'family from the variable value');
  assertEq(doc.imported, ['K:font/family/Pretendard'], 'the text face, imported by key — not the mono one');
});

checkAsync('command: with no text face anywhere it stops and says so', async () => {
  doc.libraryCollections = [];
  let threw = '';
  try {
    await resolveSansTarget();
  } catch (e) {
    threw = String(e);
  }
  assert(threw.includes('본문 서체 변수를 찾지 못했다'), `threw: ${threw}`);
});

checkAsync('command: the selection, else the page — painted end to end', async () => {
  doc.localCollections = [{ id: 'p', name: '0. Primitives' }];
  doc.localVariables = [fakeVar('p', 'font/family/Pretendard', { Value: 'Pretendard' })];
  const a = textNode('가 a', MONO);
  const b = textNode('나 b', MONO);
  const frame = { type: 'FRAME', findAllWithCriteria: () => [a, b] };
  doc.page.selection = [];
  doc.page.children = [frame];
  const pageLog = await repaintMonoHangul();
  assert(pageLog[0].includes('현재 페이지'), pageLog[0]);
  assertEq([a.families()[0], b.families()[0]], ['Pretendard', 'Pretendard'], 'every text on the page');
  const c = textNode('다', MONO);
  doc.page.selection = [c, frame];
  const selLog = await repaintMonoHangul();
  assert(selLog[0].includes('선택한 2개 노드'), selLog[0]);
  assertEq(c.families(), ['Pretendard'], 'the selected text');
  assert(selLog[1].includes('글 3개'), `each text once: ${selLog[1]}`);
});

// ─── wiring ─────────────────────────────────────────────────────────────────
//
// The message type is a string on both sides with no union between them — a
// one-character difference leaves a button that does nothing, and the compiler
// is silent about it.

const read = (rel: string): string => readFileSync(join(process.cwd(), rel), 'utf8');

check('wiring: code.ts routes mono-hangul to the command', () => {
  const main = read('code.ts');
  assert(/msg\.type === 'mono-hangul'/.test(main), "code.ts must branch on msg.type === 'mono-hangul'");
  assert(/await repaintMonoHangul\(\)/.test(main), 'the branch must call repaintMonoHangul()');
});

check('wiring: ui.html has the button, its handler, its message and a place in the busy list', () => {
  const ui = read('ui.html');
  assert(/id="mono-hangul"/.test(ui), 'button');
  assert(/getElementById\('mono-hangul'\)\.onclick/.test(ui), 'handler');
  assert(/pluginMessage: \{ type: 'mono-hangul' \}/.test(ui), 'message');
  assert(/'apply-brand-extension', 'mono-hangul'/.test(ui), 'busy list — or the button stays live mid-run');
});

check('wiring: the selftest chain runs this file — CI runs only what the chain names', () => {
  const scripts = (JSON.parse(read('package.json')) as { scripts: Record<string, string> }).scripts;
  assert(scripts.selftest.includes('npm run selftest:mono-hangul'), 'selftest chain');
  assert(scripts['selftest:mono-hangul']?.includes('scripts/selftest-mono-hangul.ts'), 'script entry');
});

void (async () => {
  for (const run of asyncChecks) await run();
  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log('✅ mono-hangul selftest passed');
})();
