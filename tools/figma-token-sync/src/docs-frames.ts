/// <reference types="@figma/plugin-typings" />

// #4039 (D1) / #4040 (D2) / #4105 — the documentation frames every
// component page carries around its component/set: `_Docs / Header` (the
// description headline bar, above — only when a description exists),
// `_Docs / Properties` (the contract property table) and
// `_Docs / Examples` (the code blocks), below.
//
// ─── Why these are FRAMEs that get rebuilt, not persistent nodes ──────────
//
// Everything mint-by-name protects (#3737) is a COMPONENT/COMPONENT_SET —
// nodes an instance in a consumer file points at by `id`/`key`. These two
// are plain FRAMEs: nothing instantiates them, nothing links to them, so
// they hold no identity worth preserving and a find→remove→recreate is the
// simplest correct update. That freedom is bounded by exactly one rule,
// enforced at the call site (`generate.ts`): they are only ever touched on
// the BUILT path. A hash-skipped entry's frames are not re-rendered — the
// "매회 재생성 장식" the legacy `Section /` headings were, and the reason
// NFR-A's second run still reports all-skip.
//
// ─── Where every string on these frames comes from ───────────────────────
//
// Nothing here invents a value. The property rows read schema v3 `axes`
// (through `axisSpecsOf` — the SAME enumerator the variant builders and
// G10 share, so a promoted axis cannot appear in the table and be missing
// from the set, or vice versa) plus the v2 `fields` subtree; the code
// blocks read v3 `examples` verbatim. The one derived string is the basic
// constructor (S-001), assembled from the axis data below and marked as
// derived in its own block title. Colors and typography bind to Variables
// through `lk`/`makeLabel` exactly as the component builders do.
//
// Raw pixel numbers appear in one place only — the fixed column widths and
// the frame offsets below. Those are table scaffolding with no coui_core
// counterpart to read (there is no "documentation table column width"
// token), and `lockWidth`/`x`/`y` take plain numbers by construction: they
// resize, they do not bind. Every value that CAN bind — padding, gap,
// radius, stroke, color, font size, font family — does.

import { ComponentAxesJson, AxisName, axisSpecsOf } from './axis-combos';
import { roleMetrics } from './compat/v1';
import { renderStateExamples } from './state-examples';
import { axesOf, docsOf, examplesOf, fieldsOf, slugOfName } from './data';
import {
  LabelOpts,
  VarLookup,
  autoFrame,
  lockWidth,
  makeLabel,
  panel,
  stampOwned,
} from './helpers';

/** 세 docs 프레임 이름이 공유하는 접두. 고아 노드 검출(`orphan-nodes.ts`)이
 *  "이 페이지 직계 자식이 docs 프레임인가" 를 **세트 이름을 모르는 채** 물어야
 *  해서 낱말만 따로 둔다 — 그 자리가 `'_Docs'` 를 자기 파일에 다시 적으면 그게
 *  두 번째 어휘이고, 접두가 바뀌는 날 docs 프레임이 고아로 신고된다.
 *  아래 세 상수가 전부 이 접두로 시작한다는 것은 `selftest-orphan-nodes` 가
 *  단언한다 (세 상수를 이 접두로 재조립하지는 않는다 — 변경 표면만 커진다). */
export const kDocsFrameNamePrefix = '_Docs';

export const kPropertiesFrameName = '_Docs / Properties';
export const kExamplesFrameName = '_Docs / Examples';
// #4105 — the description headline bar ABOVE the component (레퍼런스
// 라이브러리의 페이지 상단 설명 바). Rendered only when v3 `docs` carries a
// description — an empty bar would read as "described as nothing" (same
// stance as the omitted code block below).
export const kHeaderFrameName = '_Docs / Header';

// The contract directory the property table is a projection of. One
// `{slug}` hole, so the path is stated once rather than per component.
const kContractPathPrefix = 'packages/coui_core/lib/src/component/contracts/';

// Table scaffolding — see the header note on why these are raw numbers.
const kNameColumnWidth = 240;
const kTypeColumnWidth = 200;
const kValueColumnWidth = 440;
// Headline measure — wraps the description at a readable width (same
// scaffolding-number policy as the column widths above).
const kHeaderWidth = 720;
// Vertical air between the component/set and the first frame, and between
// the two frames. Matches `generate.ts`'s own page margin scale (that file
// positions nodes with plain numbers for the same reason).
const kFrameGap = 96;

// The `Primitives/font-family/<n>` token code blocks want, and the single
// weight they render in. `mono` is `CoreFontFamily.mono` (Geist Mono) —
// a family Figma may simply not have on the machine running the plugin;
// `resolveCodeFontFamily` below turns that into a fallback plus one log line,
// never a failed run. Geist Mono has no Hangul, and many snippets carry some:
// `makeLabel` paints those runs in the text face, the face both platforms
// fall back to.
const kCodeFontToken = 'mono';
const kCodeFontStyle = 'Regular';
const kBodyFontToken = 'sans';

// The role a code block's size and line box are read from — the code lines of
// the docs site. Read, not attached: a docs frame has no drain to attach a
// style at, and a label queued for one would be stranded.
const kCodeBlockRole = 'codeSm';
// The size a code block drew at before the scale had a code role — the
// fallback for an export that predates one.
const kCodeBlockFallbackSize = 12;

// v3's `size` axis carries no `default` (only `variant` does — see
// `ComponentAxesJson`), so the derived basic constructor names the scale's
// mid step when the component has it and the first member otherwise.
const kPreferredSizeMember = 'md';

// The `enabled` axis is the one axis with no enum behind it — it is a Dart
// `bool` promoted to a two-value Figma axis (`axis-combos.ts`), so the type
// column says what it actually is rather than naming an enum that does not
// exist.
const kEnabledAxisType = 'bool';

// ─── Fonts ───────────────────────────────────────────────────────────────

export interface CodeFont {
  /** `Primitives/font-family/<token>` the code text actually binds to. */
  token: string;
  /** Literal family that loaded — what `TextNode.fontName` carries. */
  family: string;
  /** Set when mono was wanted but unusable; `generate.ts` logs it once. */
  note: string | null;
}

// Resolved ONCE per run (alongside `loadFonts`), not per component: a
// hundred identical `loadFontAsync` calls for a family that is missing
// would each pay the same failure. The returned token is what every code
// block binds `fontFamily` to, so the binding can never claim a family the
// node did not actually render with — falling back means falling back on
// both at once.
export async function resolveCodeFontFamily(lk: VarLookup): Promise<CodeFont> {
  const bodyFamily = lk.fontFamilyName(kBodyFontToken);
  let family: string;
  try {
    family = lk.fontFamilyName(kCodeFontToken);
  } catch (e) {
    return {
      token: kBodyFontToken,
      family: bodyFamily,
      note:
        `code blocks render in "${bodyFamily}" — font-family/${kCodeFontToken} has no ` +
        `family assigned in this document (${String(e)})`,
    };
  }
  try {
    await figma.loadFontAsync({ family, style: kCodeFontStyle });
  } catch (e) {
    return {
      token: kBodyFontToken,
      family: bodyFamily,
      note:
        `code blocks render in "${bodyFamily}" — "${family}" ${kCodeFontStyle} is not ` +
        `available in this Figma environment (${String(e)})`,
    };
  }
  return { token: kCodeFontToken, family, note: null };
}

// ─── Property rows (D1) ──────────────────────────────────────────────────

export interface PropRow {
  /** JSON path the row is read from — `axes.variant`, `fields.padding`. */
  name: string;
  /** Enum/leaf-shape descriptor. */
  type: string;
  /** Members (+ default) for an axis; token provenance for a field. */
  value: string;
}

function membersText(members: readonly string[], dflt: string | null): string {
  const joined = members.join(' · ');
  return dflt ? `${joined} (default: ${dflt})` : joined;
}

interface AxisMeta {
  key: string;
  type: string;
  dflt: string | null;
}

function axisMetaOf(axes: ComponentAxesJson, axis: AxisName): AxisMeta {
  if (axis === 'Variant' && axes.variant) {
    return { key: 'variant', type: axes.variant.enum, dflt: axes.variant.default };
  }
  if (axis === 'Size' && axes.size) {
    return { key: 'size', type: axes.size.enum, dflt: null };
  }
  if (axis === 'State' && axes.state) {
    return { key: 'state', type: axes.state.enum, dflt: null };
  }
  return { key: 'enabled', type: kEnabledAxisType, dflt: null };
}

// Presence AND values come from `axisSpecsOf` — the enumerator the builders
// and G10 already share (T-14). Re-deriving "which axes does this component
// have" here would be a second opinion on a question that already has one
// owner, and the two would eventually disagree.
export function axisRowsOf(axes: ComponentAxesJson): PropRow[] {
  const rows: PropRow[] = [];
  for (const spec of axisSpecsOf(axes)) {
    const meta = axisMetaOf(axes, spec.axis);
    rows.push({
      name: `axes.${meta.key}`,
      type: meta.type,
      value: membersText(spec.values, meta.dflt),
    });
  }
  // `axes.other` is recorded, never promoted (seed spec §4-2) — the table
  // is where a reader finds out those enums exist at all, since no Figma
  // axis will ever show them.
  for (let i = 0; i < axes.other.length; i++) {
    const other = axes.other[i];
    rows.push({
      name: `axes.other[${i}]`,
      type: other.enum,
      value: membersText(other.members, null),
    });
  }
  return rows;
}

function isPlainObject(x: unknown): x is Record<string, unknown> {
  return x !== null && typeof x === 'object' && !Array.isArray(x);
}

// Lossless re-encoding of a color leaf's `argb` integer, for the handful of
// leaves that carry no `ref` to name instead. Not a new value — the same
// number in the notation a designer reads.
function argbHex(argb: number): string {
  let hex = (argb >>> 0).toString(16).toUpperCase();
  while (hex.length < 8) hex = `0${hex}`;
  return `#${hex}`;
}

// One leaf → the most specific provenance it carries. `via` (the coui_core
// constant, e.g. `CoreRadius.radius9999`) beats `ref` (the Figma variable
// path) beats the raw value, because that is the order in which the answer
// stops being "where it happens to live" and starts being "what the
// contract says".
function leafSummary(leaf: Record<string, unknown>): string {
  if ('v' in leaf) {
    const via = leaf.via;
    if (typeof via === 'string' && via.length > 0) return via;
    const ref = leaf.ref;
    if (typeof ref === 'string' && ref.length > 0) return ref;
    return String(leaf.v);
  }
  const ref = leaf.ref;
  if (typeof ref === 'string' && ref.length > 0) return ref;
  const argb = leaf.argb;
  return typeof argb === 'number' ? argbHex(argb) : String(argb);
}

function isLeaf(x: Record<string, unknown>): boolean {
  return 'v' in x || 'argb' in x;
}

const kMaxGroupSummaries = 4;

// A field's whole subtree collapsed to one cell. Identical leaves (the
// common case — a `CoreBorderRadius.all(...)` is four copies of the same
// token) collapse to one string rather than repeating it four times.
function collectLeafSummaries(value: unknown, into: string[]): void {
  if (!isPlainObject(value)) {
    into.push(String(value));
    return;
  }
  if (isLeaf(value)) {
    into.push(leafSummary(value));
    return;
  }
  for (const key of Object.keys(value)) collectLeafSummaries(value[key], into);
}

function fieldTypeOf(value: unknown): string {
  if (!isPlainObject(value)) return value === null ? 'null' : typeof value;
  if (isLeaf(value)) return 'v' in value ? 'dim' : 'color';
  return 'group';
}

function fieldValueOf(value: unknown): string {
  const summaries: string[] = [];
  collectLeafSummaries(value, summaries);
  const distinct: string[] = [];
  for (const s of summaries) {
    if (distinct.indexOf(s) < 0) distinct.push(s);
  }
  if (distinct.length === 0) return '';
  if (distinct.length <= kMaxGroupSummaries) return distinct.join(' · ');
  return `${distinct.slice(0, kMaxGroupSummaries).join(' · ')} · …`;
}

// One row per TOP-LEVEL field. A nested field (`borderRadius`'s four
// corners) stays one row — the table is a map of the contract's property
// surface, and that surface is the field, not its corners.
export function fieldRowsOf(fields: Record<string, unknown>): PropRow[] {
  const rows: PropRow[] = [];
  for (const key of Object.keys(fields)) {
    const value = fields[key];
    rows.push({
      name: `fields.${key}`,
      type: fieldTypeOf(value),
      value: fieldValueOf(value),
    });
  }
  return rows;
}

export function propRowsOf(name: string): PropRow[] {
  const slug = slugOfName(name);
  const axes = axesOf(slug);
  const rows: PropRow[] = axes ? axisRowsOf(axes) : [];
  return rows.concat(fieldRowsOf(fieldsOf(slug)));
}

// ─── Code blocks (D2) ────────────────────────────────────────────────────

export interface CodeBlock {
  title: string;
  code: string;
}

// S-001 — the one snippet v3 does not store, because it is a function of
// the axes rather than authored prose. Named args only for the axes that
// exist; the ellipsis stands in for the required slots (`child`, `label`,
// …) this data cannot name, and matches how `examples.tokenChain` already
// writes an elided call (`Badge(…).radius0`).
export function basicConstructorOf(name: string, axes: ComponentAxesJson | null): string {
  const args: string[] = [];
  if (axes && axes.variant && axes.variant.members.length > 0) {
    const member = axes.variant.default ?? axes.variant.members[0];
    args.push(`variant: ${axes.variant.enum}.${member}`);
  }
  if (axes && axes.size && axes.size.members.length > 0) {
    const members = axes.size.members;
    const member = members.indexOf(kPreferredSizeMember) >= 0 ? kPreferredSizeMember : members[0];
    args.push(`size: ${axes.size.enum}.${member}`);
  }
  return args.length > 0 ? `${name}(${args.join(', ')}, …)` : `${name}(…)`;
}

// Block titles double as provenance: the two authored ones are named after
// the exact `examples` key they print, and the derived one says so.
export function codeBlocksOf(name: string): CodeBlock[] {
  const slug = slugOfName(name);
  const examples = examplesOf(slug);
  const blocks: CodeBlock[] = [
    { title: 'Basic (derived)', code: basicConstructorOf(name, axesOf(slug)) },
  ];
  // A null snippet is a component coui_core has no example for — the block
  // is omitted rather than filled with a placeholder, so an empty spot on
  // the page reads as "not authored yet" instead of "authored as nothing".
  if (examples.withStyle) blocks.push({ title: 'withStyle', code: examples.withStyle });
  if (examples.tokenChain) blocks.push({ title: 'tokenChain', code: examples.tokenChain });
  return blocks;
}

// ─── Rendering ───────────────────────────────────────────────────────────

function captionOpts(lk: VarLookup): LabelOpts {
  return { size: 12, colorVar: lk.sem('on-surface-variant') };
}

function headingOpts(lk: VarLookup): LabelOpts {
  return { size: 12, colorVar: lk.sem('on-surface-variant'), style: 'SemiBold' };
}

// A fixed-width column cell. `lockWidth` after the child is appended (its
// own contract), and the text stretches + wraps inside it so a long token
// path grows the row's height instead of its width.
function cell(text: string, lk: VarLookup, width: number, opts: LabelOpts): FrameNode {
  const f = autoFrame('Cell', 'VERTICAL');
  const label = makeLabel(text, lk, opts);
  label.textAutoResize = 'HEIGHT';
  label.layoutAlign = 'STRETCH';
  f.appendChild(label);
  lockWidth(f, width);
  return f;
}

function tableRow(
  rowName: string,
  lk: VarLookup,
  cells: FrameNode[],
): FrameNode {
  const r = autoFrame(rowName, 'HORIZONTAL');
  r.counterAxisAlignItems = 'MIN';
  r.setBoundVariable('itemSpacing', lk.space(16));
  for (const c of cells) r.appendChild(c);
  return r;
}

function docsFrame(name: string, lk: VarLookup): FrameNode {
  const f = panel(name, 'VERTICAL', lk, {
    bg: 'surface',
    border: 'outline-variant',
    strokeN: 1,
    radius: 12,
    pl: 24,
    pr: 24,
    pt: 24,
    pb: 24,
    gap: 16,
  });
  stampOwned(f);
  return f;
}

// Removes this run's own prior output for `name` on `page`. Scoped to the
// page (not the document node index, which holds only COMPONENT /
// COMPONENT_SET) — every component page carries frames under these same two
// names, so a document-wide lookup would collide by design.
function dropExisting(page: PageNode, name: string): void {
  for (const child of page.children.slice()) {
    if (child.name === name) child.remove();
  }
}

export interface DocsFramesAnchor {
  x: number;
  y: number;
  height: number;
}

export interface DocsFramesResult {
  properties: FrameNode;
  examples: FrameNode;
  /** Description headline bar — null when v3 `docs.description` is null. */
  header: FrameNode | null;
  /** Rows in the properties table — axes + `axes.other` + top-level fields. */
  rowCount: number;
  /** Code blocks rendered — derived basic + each non-null v3 snippet. */
  blockCount: number;
  /** State-example stages rendered (`state-examples.ts`) — 0 on a set with none. */
  stateCellCount: number;
}

// Renders the frames around `anchor` (the component/set's placed box) and
// returns them plus the counts the self-test drill asserts on.
export function renderDocsFrames(
  page: PageNode,
  lk: VarLookup,
  name: string,
  anchor: DocsFramesAnchor,
  codeFont: CodeFont,
): DocsFramesResult {
  dropExisting(page, kHeaderFrameName);
  dropExisting(page, kPropertiesFrameName);
  dropExisting(page, kExamplesFrameName);

  // ── ① Header (description headline, above the component) ──
  //
  // Positioned ABOVE the anchor so the component's own placement
  // (`generate.ts`'s fixed page-margin spot — id-stable across runs) never
  // moves; a negative y is fine on a Figma canvas. The description string
  // is the same one D3 stamps into `node.description` — this bar is its
  // on-canvas surface (레퍼런스 조직), not a second source.
  const docs = docsOf(slugOfName(name));
  let header: FrameNode | null = null;
  if (docs.description !== null) {
    header = docsFrame(kHeaderFrameName, lk);
    page.appendChild(header);
    const headline = makeLabel(docs.description, lk, {
      size: 16,
      colorVar: lk.sem('on-surface'),
      style: 'SemiBold',
    });
    headline.textAutoResize = 'HEIGHT';
    headline.layoutAlign = 'STRETCH';
    header.appendChild(headline);
    if (docs.url) {
      header.appendChild(makeLabel(docs.url, lk, captionOpts(lk)));
    }
    lockWidth(header, kHeaderWidth);
    header.x = anchor.x;
    header.y = anchor.y - kFrameGap - header.height;
  }

  // ── ② Properties ──
  const properties = docsFrame(kPropertiesFrameName, lk);
  page.appendChild(properties);
  properties.appendChild(
    makeLabel(`${kContractPathPrefix}${slugOfName(name)}/`, lk, captionOpts(lk)),
  );
  properties.appendChild(
    tableRow('Header', lk, [
      cell('Name', lk, kNameColumnWidth, headingOpts(lk)),
      cell('Type', lk, kTypeColumnWidth, headingOpts(lk)),
      cell('Value', lk, kValueColumnWidth, headingOpts(lk)),
    ]),
  );
  const rowsFrame = autoFrame('Rows', 'VERTICAL');
  rowsFrame.setBoundVariable('itemSpacing', lk.space(8));
  const rows = propRowsOf(name);
  for (const row of rows) {
    rowsFrame.appendChild(
      tableRow(`Row / ${row.name}`, lk, [
        cell(row.name, lk, kNameColumnWidth, {
          size: 14,
          colorVar: lk.sem('on-surface'),
          style: 'Medium',
        }),
        cell(row.type, lk, kTypeColumnWidth, {
          size: 14,
          colorVar: lk.sem('on-surface-variant'),
        }),
        cell(row.value, lk, kValueColumnWidth, {
          size: 14,
          colorVar: lk.sem('on-surface'),
        }),
      ]),
    );
  }
  properties.appendChild(rowsFrame);
  properties.x = anchor.x;
  properties.y = anchor.y + anchor.height + kFrameGap;

  // ── ③ Examples ──
  const examples = docsFrame(kExamplesFrameName, lk);
  page.appendChild(examples);
  const blocks = codeBlocksOf(name);
  for (const block of blocks) {
    const card = panel(`Block / ${block.title}`, 'VERTICAL', lk, {
      bg: 'surface-container',
      radius: 8,
      pl: 16,
      pr: 16,
      pt: 12,
      pb: 12,
      gap: 8,
    });
    card.appendChild(makeLabel(block.title, lk, headingOpts(lk)));
    // Code hugs rather than wraps — a wrapped snippet is a snippet that no
    // longer says where its own line breaks are.
    const codeRole = roleMetrics(kCodeBlockRole);
    card.appendChild(
      makeLabel(block.code, lk, {
        size: codeRole?.fontSize ?? kCodeBlockFallbackSize,
        colorVar: lk.sem('on-surface'),
        family: codeFont.token,
        lineHeightPx: codeRole?.lineHeightPx ?? undefined,
      }),
    );
    examples.appendChild(card);
  }
  // #6214 — 상태 축이 없는 세트가 hover · pressed 때 그리는 것. 그 세트에만 있고,
  // 세트가 이 페이지에 없으면(드릴의 빈 페이지) 건너뛴다. 코드 블록이 아니므로
  // `blockCount` 에 세지 않는다.
  // 그리다 실패하면 그 자리에 사유를 적고 지나간다 — 예시 하나 때문에 이 프레임
  // 전체가 빠지고 엔트리가 매 실행 다시 그려지는 것보다, 캔버스에서 보이는 한 줄이 낫다.
  let states: ReturnType<typeof renderStateExamples> = null;
  try {
    states = renderStateExamples(page, lk, name);
  } catch (err) {
    examples.appendChild(
      makeLabel(`상태 예시를 그리지 못했다 — ${String(err)}`, lk, captionOpts(lk)),
    );
  }
  if (states !== null) {
    const card = panel(states.block.name, 'VERTICAL', lk, {
      bg: 'surface-container',
      radius: 8,
      pl: 16,
      pr: 16,
      pt: 12,
      pb: 12,
      gap: 8,
    });
    states.block.name = 'content';
    card.appendChild(states.block);
    examples.appendChild(card);
  }
  examples.x = anchor.x;
  examples.y = properties.y + properties.height + kFrameGap;

  return {
    properties,
    examples,
    header,
    rowCount: rows.length,
    blockCount: blocks.length,
    stateCellCount: states?.cellCount ?? 0,
  };
}
