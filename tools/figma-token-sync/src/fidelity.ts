// Reads the canvas back and asks whether it says what `components.json` said.
//
// ## The axis nothing else measures
//
// Every other gate in this pipeline checks PROVENANCE or STRUCTURE. The
// literal ratchet asks whether a value came from Core. The field-coverage
// guard asks whether a Dart field reached the JSON. The composition guard asks
// whether a child the widget builds is present. The runtime harness asks
// whether a builder throws.
//
// All four are green for a component that carries the right values and paints
// the wrong picture, and this project has shipped that four times over:
//
//   - 218 text styles all rendered at 14px, because the role NAME reached the
//     plugin and the metrics did not. Every guard saw a role key present.
//   - Eleven components declared a shadow and rendered flat, because no
//     builder ever wrote `node.effects`. The value was correct in Core.
//   - Every Card carried a stray file glyph, because a composed container's
//     own placeholder slot defaults ON and nothing turned it off.
//   - Badge's five properties were defined eighty times, once per variant,
//     because the owner was resolved before the set existed.
//
// What those four have in common is that the only way to notice was to look at
// the canvas. This module is that look, done mechanically: for every component
// on the page, read the node Figma actually built and compare the handful of
// values that `components.json` states outright.
//
// ## Why readback and not a pixel diff
//
// A pixel comparison against a Flutter render is the obvious idea and the
// worse one. It needs a second renderer, a font that matches, and a tolerance
// that is either loose enough to miss a 2px padding error or tight enough to
// fail on antialiasing. Worse, its reference is a SECOND statement of the same
// design — so a disagreement leaves you asking which side is wrong.
//
// A readback has one reference, and it is the same one the builders read.
// `components.json` says `padding.l.v === 16`; the node either has 16 or it
// does not, and if it does not exactly one of the two is at fault. No
// tolerance, no fonts, no second renderer.
//
// The cost is honest and worth stating: this cannot see anything the JSON does
// not state. A gap has to be a value with a field behind it. Values the
// builder invents (the literal ratchet counts 211 of them) are invisible here
// precisely because there is nothing to compare them against — which is one
// more reason that count should keep going down.
//
// ## Why inside the plugin
//
// The REST API could read the same nodes, but it needs a token, a file key,
// and a network round trip, and it reads a file that may already have drifted
// from the run that produced it. Inside the plugin the comparison happens in
// the same session that built the components, against the same `components`
// data the builders used, with no transport in between.

import { absenceAssertionFor, absenceMeaning } from './absence';
import {
  describeDuplicateVariants,
  findDuplicateVariantNames,
} from './variant-safety';
import { kSharedSourceHash } from './build-hash';
import { COMPONENTS, TYPOGRAPHY } from './data';
import { indexDocumentComponents, installNodeIndex, kMarkBarName } from './helpers';
import { kAmbientInkKey, kPaintStrengthKey } from './paint';
import { REGISTRY } from './registry';
import { isSurfaceLayer } from './surface-layers';
import { canonicalCollection, composedColorAlias } from './variables';

// One disagreement between the canvas and what the code stated.
export interface FidelityMiss {
  component: string;
  // Dotted path into the component's data, e.g. `padding.l` — so the reader
  // can go straight to the field rather than searching for it.
  field: string;
  expected: string;
  actual: string;
  // What a designer would see. Stated because a number alone does not say
  // whether it matters, and the four defects above all read as "fine" until
  // someone described the symptom.
  looksLike: string;
}

export interface FidelityReport {
  log: string[];
  misses: FidelityMiss[];
  // Components read, and the checks that ran on them. Reported because a
  // sweep that silently checked nothing is the failure mode of every guard in
  // this repo — a zero-miss run has to be distinguishable from a zero-check
  // one.
  componentsRead: number;
  checksRun: number;
  // Values a component states that this module did NOT compare, and why.
  //
  // Chrome under a per-size or per-variant table is stated once per row and
  // drawn once — the preview picks a row and this module cannot know which, so
  // asserting any single row would be inventing a claim. Skipping quietly is
  // worse: `description_card` states padding and three typography roles under
  // `sizes` only, so the padding and text checks compared nothing on it while
  // reading as a pass, and a real disagreement (a card-column gap of 8 against a
  // stated 12) sat there unseen.
  //
  // So the silence is counted and named instead. A number that goes down when
  // someone teaches the check to read a table, and that cannot be mistaken for
  // agreement.
  unchecked: string[];
  /**
   * Fields whose value the host injects at render time (`@hostDerived` in
   * coui_core). Not `unchecked`: that list is a ratchet on gaps this module
   * has not learned to read, and a host-derived field is not a gap — no
   * canvas value could be asserted for it. Listed under its own name so the
   * report still says what it did not look at.
   */
  hostDerived: string[];
  /**
   * Observations that are not disagreements. A label whose letter spacing
   * is the right number but a LITERAL — no variable, no text style — reads
   * correctly today and stops following the type scale tomorrow. That is not
   * a miss (the picture is right) and not silence (the reader should know),
   * so it has its own list. Binding policy is a separate decision; this only
   * says where the literals are.
   */
  notes: FidelityNote[];
  /**
   * Components that state no mark thickness, so the mark-stroke axis compared
   * nothing on them. Not `unchecked` — that list is "stated and not read",
   * and a component with no statement has nothing this module failed to read.
   * Listed so a run over 150 components cannot present "no stroke
   * disagreement" as if 150 marks had been compared when one was.
   */
  strokeUnstated: string[];
  /**
   * Builder fixtures (`RegistryEntry.fixture`) — sets with no contract, so no
   * record to compare against; each is `name (selftest that asserts it)`. Its
   * own list for the reason `hostDerived` has one: it is neither a gap nor a
   * read, and a sweep that drew 155 sets has to account for all 155.
   */
  fixtures: string[];
}

/** Something the canvas shows that is worth knowing and is not wrong. */
export interface FidelityNote {
  component: string;
  field: string;
  detail: string;
}


// `CoreRadius.radius9999` — the scale's "fully round" step, which every platform
// clamps to half the shorter side rather than drawing literally.
const kFullRound = 9999;

// A number's own resolved value out of a schema-v2 `Dim` leaf, or null when
// the field is absent. `{v, ref, via}` is the shape; `v` is the number the
// builder was supposed to paint.
function dimOf(node: unknown): number | null {
  if (node == null || typeof node !== 'object') return null;
  const v = (node as { v?: unknown }).v;
  return typeof v === 'number' ? v : null;
}

function fieldOf(data: unknown, path: readonly string[]): unknown {
  let cur: unknown = data;
  for (const key of path) {
    if (cur == null || typeof cur !== 'object') return undefined;
    cur = (cur as Record<string, unknown>)[key];
  }
  return cur;
}

// A fragment's view of its parent's data — only the fields it reads, with a
// shared prefix stripped so the generic checks find them under the names they
// look for (`itemBorderRadius` → `borderRadius`).
//
// Why a fragment cannot simply be compared against its parent's whole record:
// `CommandItem` draws a row, and `command` also states the PANEL — its
// `borderRadius` is 12 (the palette's corner) while the row paints
// `itemBorderRadius` 8. Handed the whole record, the checks demanded a 12
// somewhere in a set that has no reason to paint one. Handed only `item*`,
// `labelStyle`, `overlineStyle`, `shortcutStyle`, the same checks read the row
// as the component it is.
//
// Applied everywhere the checks read: `fields`, the per-size / per-variant
// tables, and the name lists (`absent` / `hostDerived` / `untokenized` /
// `deprecated`) — a field scoped out of `fields` but left in a table would be
// compared through the table and reported under a name the fragment never
// declared. A stripped name that lands on another declared name throws: two
// parent fields claiming one row field is a declaration error, not a tie to
// break silently.
export function scopeToFragment(
  data: unknown,
  dataFields: readonly string[] | undefined,
): unknown {
  if (dataFields === undefined || data == null || typeof data !== 'object') return data;
  const prefixes = dataFields.filter((f) => f.endsWith('*')).map((f) => f.slice(0, -1));
  const plain = new Set(dataFields.filter((f) => !f.endsWith('*')));
  const rename = (key: string): string | null => {
    if (plain.has(key)) return key;
    for (const prefix of prefixes) {
      if (key.length > prefix.length && key.startsWith(prefix)) {
        const rest = key.slice(prefix.length);
        return rest.charAt(0).toLowerCase() + rest.slice(1);
      }
    }
    return null;
  };
  const scopeRecord = (rec: unknown): unknown => {
    if (rec == null || typeof rec !== 'object' || Array.isArray(rec)) return rec;
    const out: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(rec as Record<string, unknown>)) {
      const scopedKey = rename(key);
      if (scopedKey === null) continue;
      if (scopedKey in out) {
        throw new Error(
          `scopeToFragment: '${key}' and another declared field both scope to '${scopedKey}'`,
        );
      }
      out[scopedKey] = value;
    }
    return out;
  };
  const scopeRelations = (relations: unknown): unknown => {
    const destinations = scopeRecord(relations);
    if (destinations == null || typeof destinations !== 'object' || Array.isArray(destinations)) {
      return destinations;
    }
    return Object.fromEntries(Object.entries(destinations).map(([key, source]) => [
      key, typeof source === 'string' ? (rename(source) ?? source) : source,
    ]));
  };
  const scopeList = (list: unknown): unknown =>
    Array.isArray(list)
      ? list.map((k) => (typeof k === 'string' ? rename(k) : null)).filter((k) => k !== null)
      : list;
  // `{ defaultsBySize: { sm: {…}, md: {…} } }` — table, then row, then a record.
  const scopeTables = (bucket: unknown): unknown => {
    if (bucket == null || typeof bucket !== 'object' || Array.isArray(bucket)) return bucket;
    const out: Record<string, unknown> = {};
    for (const [table, rows] of Object.entries(bucket as Record<string, unknown>)) {
      if (rows == null || typeof rows !== 'object' || Array.isArray(rows)) {
        out[table] = rows;
        continue;
      }
      const scopedRows: Record<string, unknown> = {};
      for (const [row, rec] of Object.entries(rows as Record<string, unknown>)) {
        scopedRows[row] = scopeRecord(rec);
      }
      out[table] = scopedRows;
    }
    return out;
  };
  const d = data as Record<string, unknown>;
  return {
    ...d,
    fields: scopeRecord(d.fields),
    constants: scopeRecord(d.constants),
    absent: scopeRecord(d.absent),
    derivedDefaults: scopeRelations(d.derivedDefaults),
    slots: scopeRecord(d.slots),
    sizes: scopeTables(d.sizes),
    variants: scopeTables(d.variants),
    hostDerived: scopeList(d.hostDerived),
    untokenized: scopeList(d.untokenized),
    deprecated: scopeList(d.deprecated),
  };
}

// The DotIndicator canvas gives each visible marker an ordinal name. Its
// default relation is checkable on every size/selection member: the selected
// marker's box must match an inactive marker in both axes. Unknown relations
// are left in `unchecked`; they must not masquerade as successful checks.
function checkDerivedDefaults(
  data: unknown,
  members: readonly ComponentNode[],
  component: string,
  tally: Tally,
  unchecked: string[],
): FidelityMiss[] {
  const relations = fieldOf(data, ['derivedDefaults']);
  if (relations == null || typeof relations !== 'object' || Array.isArray(relations)) return [];
  const misses: FidelityMiss[] = [];
  for (const [field, source] of Object.entries(relations)) {
    if (component !== 'DotIndicator' || field !== 'activeLength' || source !== 'dotSize') {
      unchecked.push(`${component}.${field} (derived from ${String(source)}; not compared)`);
      continue;
    }
    if (members.length === 0) {
      unchecked.push(`${component}.${field} (no members to compare)`);
      continue;
    }
    for (const member of members) {
      const match = /(?:^|,\s*)Selected=(\d+)(?:,|$)/.exec(member.name);
      const selected = match?.[1];
      const children = member.children;
      const active = children.find((child) => child.name === `dot ${selected}`);
      const inactive = children.find((child) => child.name === `dot ${selected === '1' ? '2' : '1'}`);
      if (selected == null || active == null || inactive == null) {
        unchecked.push(`${component}.${field} (${member.name}: marker not found)`);
        continue;
      }
      // The selected box wraps both the focus instance and the painted
      // rectangle. Checking the wrapper alone could miss an incorrectly sized
      // painted marker inside an otherwise correct cell.
      const painted = active.type === 'RECTANGLE'
        ? active
        : 'children' in active
          ? active.children.find((child) => child.type === 'RECTANGLE')
          : undefined;
      if (painted == null) {
        unchecked.push(`${component}.${field} (${member.name}: painted marker not found)`);
        continue;
      }
      for (const axis of ['width', 'height'] as const) {
        for (const [part, node] of [['box', active], ['paint', painted]] as const) {
          tally.n += 1;
          if (Math.abs(node[axis] - inactive[axis]) > 0.01) {
            misses.push({
              component, field: `derivedDefaults.${field}.${part}.${axis}`,
              expected: `selected ${part} ${axis} equals inactive ${axis} (${inactive[axis]})`,
              actual: `${member.name}: ${node[axis]}`,
              looksLike: 'the selected marker no longer follows the default dot size',
            });
          }
        }
      }
    }
  }
  return misses;
}

// The set-or-component a REGISTRY entry produced, by name, or null.
// Every COMPONENT under `node` — the set's members, or the node itself.
function membersOf(node: SceneNode): readonly ComponentNode[] {
  if (node.type === 'COMPONENT') return [node];
  if (node.type !== 'COMPONENT_SET') return [];
  const out: ComponentNode[] = [];
  for (const child of node.children) {
    if (child.type === 'COMPONENT') out.push(child);
  }
  return out;
}

// ── Checks ──────────────────────────────────────────────────────────────────
//
// Each takes the component's data and one built member, and reports what
// disagrees. Split per concern rather than one big walk: a check that cannot
// find its subject must say so as a skip, and a single walk would have to
// invent a "partially applicable" state to express that.

// `padding` → an auto-layout frame's four insets, anywhere in the subtree.
//
// Only meaningful on an auto-layout frame; a `layoutMode === 'NONE'` member
// stores padding fields Figma ignores, so comparing them would report a
// mismatch that has no visual meaning.
//
// Searched over the subtree for the same reason the shadow check is: WHERE a
// stated value lands is a composition choice. HoverCard forwards its padding
// into the `Popup` it composes, so the root carries none and the rendered
// inset is the popup's — the picture is right and the root is bare.
// Comparing the root alone called that a miss on eight components, all of which
// were drawing the padding one node down.
//
// This was invisible until the test double started reporting Figma's real
// default of `0` for an unset inset. While the double left the property
// undefined, `typeof got !== 'number'` skipped every node the builder had not
// touched — so the check passed by not running, on exactly the components where
// it had something to say.
// Every value a component states for `field.path`, across `fields` and every
// per-size / per-variant row.
//
// The preview draws ONE row and the data does not say which, so a single row
// cannot be asserted. What CAN be asserted is that the canvas carries one of
// them: a padding matching no row at all is a value the builder invented, which
// is the thing this module exists to find. Nine components — Button and Chip
// among them — state their padding only under a table, so before this the check
// compared nothing on them and read as a pass.
/**
 * How many values a check actually put side by side.
 *
 * `checksRun` used to be incremented once per check FUNCTION — `+= 1`, `+= 6`,
 * `+= 1` — so it was `componentsRead × 8` by construction: 144 read always meant
 * 1152, whether those checks compared a thousand values or none. The field's own
 * comment says it exists so "a zero-miss run has to be distinguishable from a
 * zero-check one", and a number derived from the other number cannot do that.
 *
 * Every check below bails out when the data states nothing for it. This counts the
 * other side of that bail-out: a value found, and compared.
 */
interface Tally {
  n: number;
}

function statedValues(
  data: unknown,
  path: readonly string[],
): readonly number[] {
  const out = new Set<number>();
  // The flat default AND every per-size / per-variant row — not the flat value
  // alone when it exists. A row is the more specific statement: `command`
  // states `itemPadding` 12/6 as the flat default and 8/4 · 12/6 · 16/8 under
  // its size ladder, and a set whose first member is the `sm` rung paints 8/4.
  // Returning on the flat value read that as "12 stated, 8 painted" — a
  // disagreement the code does not contain. Components with no flat default
  // (`button`, `chip`, `menu_item`) were already judged against their rows;
  // this makes the two shapes answer the same way.
  const direct = dimOf(fieldOf(data, ['fields', ...path]));
  if (direct != null) out.add(direct);
  for (const bucket of ['sizes', 'variants']) {
    const tables = fieldOf(data, [bucket]);
    if (tables == null || typeof tables !== 'object') continue;
    for (const table of Object.values(tables as Record<string, unknown>)) {
      if (table == null || typeof table !== 'object') continue;
      for (const row of Object.values(table as Record<string, unknown>)) {
        const v = dimOf(fieldOf(row, path));
        if (v != null) out.add(v);
      }
    }
  }
  return [...out];
}

function checkPadding(
  data: unknown,
  member: ComponentNode,
  name: string,
  tally: Tally,
): FidelityMiss[] {
  if (member.layoutMode === 'NONE') return [];
  const out: FidelityMiss[] = [];
  const sides: readonly [
    string,
    'paddingLeft' | 'paddingTop' | 'paddingRight' | 'paddingBottom',
  ][] = [
    ['l', 'paddingLeft'],
    ['t', 'paddingTop'],
    ['r', 'paddingRight'],
    ['b', 'paddingBottom'],
  ];
  // A horizontally asymmetric inset is stated in the reading direction
  // (`start` / `end`), and the canvas is drawn left-to-right: `start` is the
  // left edge and `end` the right. Reading only `l` / `r` left such an inset
  // out of the comparison — until a sibling row stated the same side
  // physically (a symmetric 14 under `inline`), when the physical row alone
  // was compared against a member that paints the directional one.
  const directional: Readonly<Record<string, string>> = { l: 'start', r: 'end' };
  for (const [key, prop] of sides) {
    const wanted = [
      ...statedValues(data, ['padding', key]),
      ...(directional[key] ? statedValues(data, ['padding', directional[key]]) : []),
    ];
    if (wanted.length === 0) continue;
    tally.n += 1;
    if (wanted.some((want) => insetSomewhere(member, prop, want))) continue;
    out.push({
      component: name,
      field: `padding.${key}`,
      expected: `one of ${wanted.join(' / ')} on some frame in the component`,
      actual: `${member[prop]} on the root, and nowhere below it`,
      looksLike:
        'the component sits tighter or looser inside its own box than the ' +
        'widget does — visible only next to the app',
    });
  }
  return out;
}

// Whether any auto-layout frame at or under `node` carries `want` on `prop`.
//
// Instances included, unlike the absence walk, and the asymmetry is the point:
// this asks whether the canvas SHOWS the inset, and an instance's inset is
// shown. HoverCard states 16 and forwards it into a `Popup` whose own padding is
// also 16, so the rendered inset is the stated one even though the root frame is
// bare. The absence walk asks the opposite question — whether anything was
// painted that the code did not state — and there attribution decides it, so an
// instance's own chrome must not count against its host.
function insetSomewhere(
  node: SceneNode,
  prop: 'paddingLeft' | 'paddingTop' | 'paddingRight' | 'paddingBottom',
  want: number,
): boolean {
  const self = node as unknown as Record<string, unknown>;
  if (self.layoutMode !== 'NONE' && typeof self[prop] === 'number') {
    if (Math.abs((self[prop] as number) - want) < 0.01) return true;
  }
  const kids = self.children as readonly SceneNode[] | undefined;
  if (kids == null) return false;
  return kids.some((kid) => insetSomewhere(kid, prop, want));
}

// `borderRadius.topLeft` → a rounded corner anywhere in the subtree.
//
// Searched, not read off the root, for the same reason padding is: WHERE a
// stated value lands is a composition choice. TextField rounds the field frame
// inside its label row, Card rounds the `OutlinedContainer` it composes, Slider
// rounds two track rectangles — in every case the root is a bare wrapper at 0.
//
// Read off the root alone this reported 15 of 143 components, and none of the 15
// was wrong. It read as passing here for a second reason worth keeping in view:
// the double had no key for `topLeftRadius`, so `typeof undefined !== 'number'`
// skipped instead of comparing, while the real file answered Figma's default of
// `0` and compared. Two independent omissions, the same shape as the padding
// pair, which is why the double now refuses unmodelled reads outright.
function checkRadius(
  data: unknown,
  member: ComponentNode,
  name: string,
  tally: Tally,
): FidelityMiss[] {
  const wanted = statedValues(data, ['borderRadius', 'topLeft']);
  if (wanted.length === 0) return [];
  tally.n += 1;
  if (wanted.some((want) => radiusSomewhere(member, want))) return [];
  return [
    {
      component: name,
      field: 'borderRadius.topLeft',
      expected: `one of ${wanted.join(' / ')} on some node in the component`,
      actual: `${member.topLeftRadius} on the root, and nowhere below it`,
      looksLike: 'corners rounder or squarer than the widget draws',
    },
  ];
}

// Whether any node at or under `node` carries `want` as its top-left radius.
// Instances included: an instance's rounding is on screen, and Card rounds the
// container it composes rather than a frame of its own.
//
// A surface's material layers are looked past: they copy the corner of the
// surface they sit under, so finding the value there says nothing about where
// the builder put it — a surface rounded wrong would pass on its own layers.
function radiusSomewhere(node: SceneNode, want: number): boolean {
  if (isSurfaceLayer(node)) return false;
  const self = node as unknown as {
    topLeftRadius?: unknown;
    children?: readonly SceneNode[];
  };
  // An ELLIPSE has no corners and needs none: it is already the shape a
  // full-round radius asks for. `Status` rounds a `size × size` box to 9999 in
  // Flutter and draws an ellipse here — the same circle, and reported as a miss
  // until this branch existed. Only accepted for the full-round token, so an
  // ellipse cannot stand in for a 4px corner.
  if (node.type === 'ELLIPSE' && want >= kFullRound) return true;
  if (
    typeof self.topLeftRadius === 'number' &&
    Math.abs(self.topLeftRadius - want) < 0.01
  ) {
    return true;
  }
  const kids = self.children;
  if (kids == null) return false;
  return kids.some((kid) => radiusSomewhere(kid, want));
}

// `boxShadow.layers` → the member's DROP_SHADOW effects.
//
// Counts rather than compares geometry: the count alone catches the defect
// that actually happened (eleven components declared layers and drew none),
// and a per-layer comparison would need to decide what to do about a shadow a
// designer legitimately edited on the main component.
function checkShadow(
  data: unknown,
  member: ComponentNode,
  fieldName: string,
  name: string,
  tally: Tally,
): FidelityMiss[] {
  const layers = fieldOf(data, ['fields', fieldName, 'layers']);
  if (!Array.isArray(layers) || layers.length === 0) return [];
  tally.n += 1;
  // Counted over the whole subtree, not just the member root. A builder is
  // free to put the shadow on the node that owns the surface — DraggablePanel
  // casts its `panelShadow` on the inner panel, because the root is the
  // `Stacks` container and shadowing that would shadow the drag handle too.
  // Reading only the root reported that as a missing shadow, which is the
  // false-positive direction: a check that cries wolf gets argued with, and
  // this one exists to be acted on.
  //
  // A surface's material layers are looked past: their rim is the surface
  // style's, not the component's stated cast, and counting it let a surface
  // that lost its own cast pass.
  let drawn = 0;
  const countShadows = (node: SceneNode): void => {
    if (isSurfaceLayer(node)) return;
    if ('effects' in node) {
      for (const e of node.effects) {
        if (e.type === 'DROP_SHADOW' || e.type === 'INNER_SHADOW') drawn += 1;
      }
    }
    if ('children' in node) {
      for (const child of node.children) countShadows(child);
    }
  };
  countShadows(member);
  if (drawn >= layers.length) return [];
  return [
    {
      component: name,
      field: `${fieldName}.layers`,
      expected: `${layers.length} shadow layer(s)`,
      actual: `${drawn}`,
      looksLike:
        drawn === 0
          ? 'the surface reads as flush with the page — a popover or dialog ' +
            'that should float does not'
          : 'shallower elevation than the widget casts',
    },
  ];
}

// Text style `fontSize` → the size of the text nodes under the member.
//
// The check that would have caught 218 styles rendering at one size. Compares
// the SET of sizes present against the set the data states, rather than
// pairing node to field: the pairing is not knowable from here (a builder is
// free to name its nodes anything), while "the data says 24 appears somewhere
// and no text node is 24" is both knowable and exactly the defect.
function checkTextSizes(
  data: unknown,
  // Every member, not one: a variant axis decides which text nodes exist at all
  // (see the note on `verifyFidelity`), so a role can be present in the set and
  // absent from any given member.
  members: readonly ComponentNode[],
  roleMetrics: Record<string, { fontSize?: number | null }>,
  name: string,
  tally: Tally,
): FidelityMiss[] {
  // size → the field paths that ask for it. Attributed rather than pooled: the
  // pooled version could only say "16px somewhere", leaving the reader to search
  // the component for which of six text fields wanted it, and it had no place to
  // hang an exclusion.
  const wanted = new Map<number, string[]>();
  const walk = (value: unknown, path: string): void => {
    if (value == null || typeof value !== 'object') return;
    if (Array.isArray(value)) {
      for (const item of value) walk(item, path);
      return;
    }
    const record = value as Record<string, unknown>;
    const role = record.role;
    if (typeof role === 'string' && !kDerivedTextSizes.has(`${name}.${path}`)) {
      const explicit = dimOf(record.fontSize);
      const fromRole = roleMetrics[role]?.fontSize;
      const size = explicit ?? (typeof fromRole === 'number' ? fromRole : null);
      if (size != null) {
        const key = Math.round(size);
        const at = wanted.get(key);
        if (at == null) wanted.set(key, [path]);
        else at.push(path);
      }
    }
    for (const key of Object.keys(record)) {
      walk(record[key], path === '' ? key : `${path}.${key}`);
    }
  };
  walk(fieldOf(data, ['fields']), '');
  if (wanted.size === 0) return [];
  tally.n += wanted.size;

  const present = new Set<number>();
  const collect = (node: SceneNode): void => {
    if (node.type === 'TEXT' && typeof node.fontSize === 'number') {
      present.add(Math.round(node.fontSize));
    }
    if ('children' in node) {
      for (const child of node.children) collect(child);
    }
  };
  for (const member of members) collect(member);
  if (present.size === 0) return [];

  const out: FidelityMiss[] = [];
  for (const [size, paths] of wanted) {
    if (present.has(size)) continue;
    out.push({
      component: name,
      field: `${paths.join(' / ')}.fontSize`,
      expected: `${size}px somewhere in this component`,
      actual: `only ${Array.from(present).sort((a, b) => a - b).join(', ')}`,
      looksLike:
        'a typography role the data states does not appear at that size — ' +
        'either the builder drew it at a literal size instead of the role, ' +
        'or that text is not drawn at all',
    });
  }
  return out;
}

// Text fields whose ROLE is not the rendered size — the role still carries the
// colour and the weight, and something else decides how big the words are.
//
// Every entry is visible in the data and would be reported as a miss without
// this list. Listed rather than inferred: what makes a field the size
// authority is which one the resolver hands to `resolveTypographyRole`, and the
// export carries the fields, not that choice.
const kDerivedTextSizes = new Set([
  // RichEditor forwards `kbdStyle` to the `Kbd` inside each toolbar button's
  // tooltip — an overlay that opens on hover, not a pose of the set — so no
  // key cap is drawn here. The role is stated for the code to forward.
  'RichEditor.kbdStyle.keyTextStyle',
  // The headings are words in the DOCUMENT, and the set draws only the empty
  // editor (toolbar + placeholder) — no document, so nothing is drawn at 20 / 18
  // / 16. The sizes are stated for the code on both platforms to read. It is the
  // same missing pose `figma_unread_fields_allowlist.json` names for the other
  // document marks (an axis `Content` = empty / formatted).
  'RichEditor.heading1TextStyle',
  'RichEditor.heading2TextStyle',
  'RichEditor.heading3TextStyle',
  // The composed field / checkbox these components forward a style to is drawn
  // as the shipped TextField / Checkbox member, whose description and error
  // nodes sit behind a boolean off by default (a field here shows only its
  // value or its placeholder; a card checkbox shows no label). The role is
  // stated for the code to forward; no node at that size exists to compare.
  'FormattedInput.segmentInputStyle.descriptionStyle',
  'FormattedInput.segmentInputStyle.errorStyle',
  'ObjectInput.fieldInputStyle.descriptionStyle',
  'ObjectInput.fieldInputStyle.errorStyle',
  'MultiAnswerCard.checkboxStyle.labelStyle',
  'MultiAnswerCard.checkboxStyle.descriptionStyle',
  // The sheet's `footerBarStyle` is installed as the bar theme around the
  // footer, and the footer is drawn as the shipped `Layout=horizontal`
  // BottomActionBar member — the summary's figure exists only in the
  // `summary` layout. The role is stated for the code to forward to whichever
  // bar a caller places; no node at that size exists in the default footer.
  'BottomSheet.footerBarStyle.summaryValueTextStyle',
  // `avatar.initialsFontRatio` is 0.4 and the resolver sizes the initials at
  // `diameter * ratio` — 9.6 / 12.8 / 16 / 19.2 / 25.6 across the five sizes,
  // none of them `bodySmall`'s 13. The role is there for the colour.
  'Avatar.fallbackTextStyle',
  // All three are `labelMedium` and differ only in colour; `buttonTextStyle`
  // (`labelLarge` + weight 500) is what the widget hands the page numbers, and
  // the builder merges each of these in as the colour on top of it.
  'Pagination.textStyle',
  'Pagination.activeTextStyle',
  'Pagination.hoverTextStyle',
  // `NavigationBarItem` declares `dataSlug: 'navigation_bar'` — the widget has
  // its own contract but no Style; its chrome is a fragment of
  // `CoreNavigationBarStyle`. Every OTHER
  // field of that data (padding / radius / per-state colour / labelMedium
  // role) is a real destination property this component draws, so sharing
  // the slug is still the honest source. `sectionLabelTextStyle` alone is
  // not: it styles the BAR's non-destination `label`-kind entries
  // (`_NavigationSectionLabel`), which a single `NavigationBarItem` — always
  // one `item`-kind destination — never renders. Undrawn here is undrawn in
  // the widget too.
  'NavigationBarItem.sectionLabelTextStyle',
  // The status bar is the operating system's own text, authored in iOS points and
  // drawn at `systemBarScale` of them. The role names the REFERENCE size (16 on a
  // phone, 14 on a tablet) and carries the colour and the weight; the screen's
  // width over the width those lengths are authored for decides how big the words
  // are — 5.7 and 5.0 at the canvas — so no node is at the size the role states.
  // Asserting it would demand a 14 that the widget does not draw either.
  'MockupDevice.statusBarTextStyle',
]);

// ── Per-member text — size ladder · letter spacing ──────────────────────────
//
// `checkTextSizes` above asks whether a stated size appears ANYWHERE in the
// set. That is the strongest claim it can make about a role, because the data
// does not say which member draws which text. It is also exactly the claim a
// six-rung ladder drawn at one size satisfies: `bodySmall` is 13, some member
// has a 13, pass — while `xs` was stated at 12 and `xl` at 16 and neither
// number reached a node. Six rungs at one size shipped through that check.
//
// A size ROW is different from a role: it names the member it belongs to.
// `sizes.defaultsBySize.xs.labelStyle.fontSize === 12` is a claim about the
// `Size=xs` members and no other, so it can be asserted on THOSE members —
// "this member", not "somewhere". That is what these checks do, and only for
// the values a row states; a role stated once in `fields` keeps the set-wide
// check, because a variant axis may decide whether that text exists at all
// (`Fab` draws its label only when `Open=true`).

// One typography claim the data makes: where it lives (`path`), and the
// metrics that claim resolves to once the role fills in what the leaf left
// null. `letterSpacingEm` is the em ratio Core states — what reaches a node is
// that ratio times the size the node renders at.
interface TextClaim {
  path: string;
  role: string | null;
  fontSize: number | null;
  letterSpacingEm: number | null;
  // `row` — stated under a per-size row (the ladder), so it names its member.
  // `field` — stated once for the set.
  source: 'field' | 'row';
}

interface RoleMetrics {
  fontSize?: number | null;
  letterSpacing?: number | null;
}

// Every `{role, fontSize?, letterSpacing?}` leaf under `fields`, by dotted path.
function textLeavesOf(value: unknown): Map<string, Record<string, unknown>> {
  const out = new Map<string, Record<string, unknown>>();
  const walk = (node: unknown, path: string): void => {
    if (node == null || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      for (const item of node) walk(item, path);
      return;
    }
    const record = node as Record<string, unknown>;
    if ('role' in record) out.set(path, record);
    for (const key of Object.keys(record)) {
      walk(record[key], path === '' ? key : `${path}.${key}`);
    }
  };
  walk(value, '');
  return out;
}

function roleOf(leaf: Record<string, unknown> | null): string | null {
  const role = leaf?.role;
  return typeof role === 'string' ? role : null;
}

function emOf(leaf: Record<string, unknown> | null): number | null {
  const em = leaf?.letterSpacing;
  if (typeof em === 'number') return em;
  return dimOf(em);
}

// The claim a base leaf makes with `overlay` on top of it — a row's leaf over
// the field's, resolved the way both resolvers and the builders resolve it:
// the row's value wins, the field's fills in, the role answers what neither
// stated. The role is the OVERLAY's when it names one (Toggle's rows swap
// roles up the ladder), else the field's (Checkbox's rows restate only the
// size and keep the field's role — and that role's tracking ratio, which is
// how a 10px rung gets −0.1 and an 18px rung −0.18 from one `bodySmall`).
function resolveClaim(
  path: string,
  base: Record<string, unknown>,
  overlay: Record<string, unknown> | null,
  roleMetrics: Record<string, RoleMetrics>,
  source: 'field' | 'row',
): TextClaim {
  const role = roleOf(overlay) ?? roleOf(base);
  const metrics = role == null ? undefined : roleMetrics[role];
  const stated = dimOf(overlay?.fontSize) ?? dimOf(base.fontSize);
  const fontSize = stated ?? (typeof metrics?.fontSize === 'number' ? metrics.fontSize : null);
  const em = emOf(overlay) ?? emOf(base);
  const letterSpacingEm =
    em ?? (typeof metrics?.letterSpacing === 'number' ? metrics.letterSpacing : null);
  return { path, role, fontSize, letterSpacingEm, source };
}

// `Size=md, State=enabled, Checked=false` → `{Size: 'md', …}`. Read off the
// name rather than `variantProperties`: the name is what the builders wrote
// and what a designer reads, and a standalone COMPONENT has no
// `variantProperties` to read at all.
function variantOf(member: ComponentNode): Record<string, string> {
  const out: Record<string, string> = {};
  for (const pair of member.name.split(',')) {
    const at = pair.indexOf('=');
    if (at < 0) continue;
    out[pair.slice(0, at).trim()] = pair.slice(at + 1).trim();
  }
  return out;
}

function sizeRowOf(data: unknown, sizeKey: string | null): unknown {
  if (sizeKey == null) return null;
  return fieldOf(data, ['sizes', 'defaultsBySize', sizeKey]);
}

// Members grouped by the rung they sit on (`Size=md` → its members), in the
// order the set declares them. A set with no `Size` axis yields nothing, which
// is the right answer: a claim under `defaultsBySize` has no member to land on.
function rungsOf(members: readonly ComponentNode[]): Map<string, ComponentNode[]> {
  const out = new Map<string, ComponentNode[]>();
  for (const member of members) {
    const sizeKey = variantOf(member).Size;
    if (sizeKey == null) continue;
    const at = out.get(sizeKey);
    if (at == null) out.set(sizeKey, [member]);
    else at.push(member);
  }
  return out;
}

// Enum members the exporter keeps off the canvas (`axes.*.hidden` — a
// `@Deprecated` or `@behaviourOnly` member). A row keyed by one of them states
// values for members no set draws, so it makes no claim about the canvas:
// `CoreNavigationBarMode.sidebar` keeps its `defaultsByMode` row while it is
// announced, and its 14px label role would otherwise be demanded of a bar that
// no longer draws a sidebar.
function hiddenMembersOf(data: unknown): Set<string> {
  const out = new Set<string>();
  const axes = fieldOf(data, ['axes']) as Record<string, unknown> | null;
  if (axes == null || typeof axes !== 'object') return out;
  const add = (axis: unknown): void => {
    const hidden = (axis as { hidden?: unknown } | null)?.hidden;
    if (Array.isArray(hidden)) for (const h of hidden) if (typeof h === 'string') out.add(h);
  };
  for (const value of Object.values(axes)) {
    if (Array.isArray(value)) value.forEach(add);
    else add(value);
  }
  return out;
}

function allRowsOf(data: unknown, bucket: 'sizes' | 'variants'): readonly unknown[] {
  const tables = fieldOf(data, [bucket]);
  if (tables == null || typeof tables !== 'object') return [];
  const hidden = hiddenMembersOf(data);
  const out: unknown[] = [];
  for (const table of Object.values(tables as Record<string, unknown>)) {
    if (table == null || typeof table !== 'object') continue;
    for (const [key, row] of Object.entries(table as Record<string, unknown>)) {
      if (hidden.has(key)) continue;
      out.push(row);
    }
  }
  return out;
}

// The claims that hold on ONE member: every text field, resolved through the
// member's own size row when it has one. `rows` are the overlays to consult —
// the member's size row for the ladder, plus every variant row, because a
// variant may restate a role and this module cannot tell which variant a
// member's text came from any more than it can tell which text node is which.
//
// Rows are WALKED for their own leaves, not read at the paths `fields` names.
// Half this library states its type only under a table — `Button` has no
// `labelStyle` in `fields` at all, six rows and nothing above them — and a
// version that treated a row as an overlay ON a field leaf found no path to
// overlay and produced no claim, so eighty components ran this axis and
// compared nothing while reading as a pass. That is the same shape the padding
// check was fixed for, and it is the failure mode this whole module exists to
// name rather than repeat.
function claimsFor(
  data: unknown,
  name: string,
  rows: readonly unknown[],
  roleMetrics: Record<string, RoleMetrics>,
): TextClaim[] {
  const out: TextClaim[] = [];
  const base = textLeavesOf(fieldOf(data, ['fields']));
  const admit = (path: string): boolean => !kDerivedTextSizes.has(`${name}.${path}`);
  for (const [path, leaf] of base) {
    if (!admit(path)) continue;
    out.push(resolveClaim(path, leaf, null, roleMetrics, 'field'));
  }
  for (const row of rows) {
    for (const [path, leaf] of textLeavesOf(row)) {
      if (!admit(path)) continue;
      out.push(resolveClaim(path, base.get(path) ?? {}, leaf, roleMetrics, 'row'));
    }
  }
  return out;
}

// Every TEXT node at or under `node`. Instances included or not by the
// caller's choice — see each check for which direction it asks in.
function textNodesUnder(node: SceneNode, intoInstances: boolean): TextNode[] {
  const out: TextNode[] = [];
  const stack: SceneNode[] = [node];
  while (stack.length > 0) {
    const n = stack.pop() as SceneNode;
    if (!intoInstances && n !== node && n.type === 'INSTANCE') continue;
    if (n.type === 'TEXT') out.push(n);
    const kids = (n as unknown as { children?: readonly SceneNode[] }).children;
    if (kids != null) for (const kid of kids) stack.push(kid);
  }
  return out;
}

// Size-row `fontSize` → a TEXT at that size among THAT RUNG's members.
//
// Only row claims: a row names the rung it belongs to (`Size=xs`), which is
// what lets the claim be narrower than "somewhere in the set" at all. Field
// claims stay with `checkTextSizes`.
//
// The rung, and not the single member, is the unit — because a second axis
// decides whether the text exists. `Command` states `labelStyle` at 16 on its
// `md` row and draws rows only when `Empty=false`; asserted per member, its
// `Empty=true` members reported that 16 as missing while the rung drew it four
// times over. Per rung the ladder defect is still caught — six rungs drawn at
// one size means the `xs` rung has no text at its own size in ANY of its members — and an
// orthogonal axis that removes the text cannot manufacture a miss.
function checkTextSizesPerRung(
  data: unknown,
  members: readonly ComponentNode[],
  roleMetrics: Record<string, RoleMetrics>,
  name: string,
  tally: Tally,
): FidelityMiss[] {
  const out: FidelityMiss[] = [];
  for (const [sizeKey, rung] of rungsOf(members)) {
    const row = sizeRowOf(data, sizeKey);
    if (row == null) continue;
    const claims = claimsFor(data, name, [row], roleMetrics).filter(
      (c) => c.source === 'row' && c.fontSize != null,
    );
    if (claims.length === 0) continue;
    // Instances included: a rung's label may be painted by a composed child
    // placed at that rung (`Command` opens onto `CommandItem` rows), and the
    // size the row states is the size that child renders.
    const present = new Set<number>();
    for (const member of rung) {
      for (const t of textNodesUnder(member, true)) {
        if (typeof t.fontSize === 'number') present.add(Math.round(t.fontSize));
      }
    }
    if (present.size === 0) continue;
    // One line per (field, size): several claims of a rung resolve to the same
    // size, and a rung of sixty members would otherwise repeat the sentence.
    const said = new Set<string>();
    for (const claim of claims) {
      tally.n += 1;
      const want = Math.round(claim.fontSize as number);
      if (present.has(want)) continue;
      const key = `${claim.path}|${want}`;
      if (said.has(key)) continue;
      said.add(key);
      out.push({
        component: name,
        field: `${claim.path}.fontSize`,
        expected: `${want}px on some TEXT of a Size=${sizeKey} member`,
        actual: `only ${Array.from(present).sort((a, b) => a - b).join(', ')}`,
        looksLike:
          'the size axis changes the box and not the words — the label is ' +
          'drawn at one size on every rung of the ladder',
      });
    }
  }
  return out;
}

// A text node that renders a glyph, not words. Sized on the dimension ladder
// (`Primitives/size|space`), never on a type role — and one character long.
// Both, because the two fail differently: a raw copy pasted from another file
// has no binding to read, and a one-letter label (`+`, `*`, `:`) exists.
function isGlyphText(t: TextNode, varNames: Map<string, string>): boolean {
  if (typeof t.characters === 'string' && t.characters.length <= 1) return true;
  const bound = (t as unknown as { boundVariables?: Record<string, unknown> }).boundVariables;
  const raw = bound?.fontSize;
  const aliases = Array.isArray(raw) ? raw : raw == null ? [] : [raw];
  for (const alias of aliases as { id?: string }[]) {
    const varName = alias?.id == null ? null : varNames.get(alias.id);
    if (varName != null && /^Primitives\/(size|space)\//.test(varName)) return true;
  }
  return false;
}

// The role a label's tracking is bound to (`letter-spacing/<role>`), in the
// type scale's camel-case name, or null when the tracking is not bound to a
// role variable.
function trackingRoleOf(t: TextNode, varNames: Map<string, string>): string | null {
  const bound = (t as unknown as { boundVariables?: Record<string, unknown> }).boundVariables;
  const raw = bound?.letterSpacing;
  const aliases = Array.isArray(raw) ? raw : raw == null ? [] : [raw];
  for (const alias of aliases as { id?: string }[]) {
    const varName = alias?.id == null ? null : varNames.get(alias.id);
    const m = varName == null ? null : /letter-spacing\/([a-z0-9-]+)$/.exec(varName);
    if (m) return m[1].replace(/-([a-z0-9])/g, (_, c: string) => c.toUpperCase());
  }
  return null;
}

function hasTextBinding(t: TextNode, field: string): boolean {
  const styleId = (t as unknown as { textStyleId?: unknown }).textStyleId;
  if (typeof styleId === 'string' && styleId !== '') return true;
  const bound = (t as unknown as { boundVariables?: Record<string, unknown> }).boundVariables;
  const raw = bound?.[field];
  return Array.isArray(raw) ? raw.length > 0 : raw != null;
}

// The px a node's letter spacing was SET to, or null when nobody set it.
//
// `PERCENT` is Figma's untouched default (`0%` on a fresh TEXT) and every
// builder here writes `PIXELS`, so the unit distinguishes "the builder stated
// a tracking" from "the builder stated none" — a distinction both directions
// of the check depend on. A percentage a designer typed by hand would read as
// unstated here; that is the designer file's axis, not this one's.
function writtenLetterSpacingPx(t: TextNode): number | null {
  const ls = t.letterSpacing as unknown;
  if (ls == null || typeof ls !== 'object') return null;
  const { unit, value } = ls as { unit?: string; value?: number };
  if (unit !== 'PIXELS' || typeof value !== 'number') return null;
  return value;
}

// Letter spacing → `role em × the size the node renders at`, ±0.01px.
//
// Core renders tracking as a RATIO: `CoreTextStyle`'s `letterSpacing` is an em
// value that the merge multiplies by whatever size the label ends up at. So a
// role reused one rung up must arrive with a different number of pixels, and
// the way that goes wrong is a role's px carried to a size it was not computed
// for. Nothing in this module read tracking at all until now, and the ratio is
// invisible to every other axis: the size is right, the role name is right, and
// the words sit at the wrong width.
//
// Two directions, because they catch opposite failures and neither can be
// stretched to cover the other.
//
// ── canvas → code: a tracking the builder WROTE must be one the data states
//
// Judged only on nodes whose spacing is in PIXELS. That is not a style choice:
// a `makeLabel` that is given a ratio writes `{unit: 'PIXELS'}`, and a text node
// nobody set keeps Figma's `{unit: 'PERCENT', value: 0}`. So the unit answers
// "did a builder state a tracking here", which is exactly the question this
// direction needs — a component may legitimately hold text the data says nothing
// about (a caller-slot stand-in, sample copy), and asserting a claim on it is
// inventing a statement. Six components' preview stand-ins were reported that
// way, all at 14 because 14 is the library's commonest size and every claim that
// resolves to 14 matched them.
//
// Instances are skipped, as `checkFillAlpha` skips them: an instance's text is
// the instanced component's claim, judged on that component's own rows.
//
// ── code → canvas: a tracking the data STATES must reach a node
//
// The other half — a builder that writes no tracking at all — leaves nothing for
// the first direction to judge, and reads as a pass. So per rung, for each size
// some claim resolves to AND some node renders at, one of those nodes must carry
// a tracking claimed at that size. Scoped to sizes that are actually drawn for
// the same reason `checkTextSizes` is: a role a variant does not render has no
// node to look for, and demanding one manufactures a miss.
function checkLetterSpacing(
  data: unknown,
  members: readonly ComponentNode[],
  roleMetrics: Record<string, RoleMetrics>,
  name: string,
  varNames: Map<string, string>,
  tally: Tally,
  notes: FidelityNote[],
): FidelityMiss[] {
  const out: FidelityMiss[] = [];
  const seen = new Set<string>();
  const variantRows = allRowsOf(data, 'variants');
  const sizeRows = allRowsOf(data, 'sizes');
  let unbound = 0;
  let judged = 0;

  // A member's admissible claims. A member with no size row of its own could
  // have been drawn from any row, so every row's claim is admissible on it.
  const claimsOn = (member: ComponentNode): TextClaim[] => {
    const row = sizeRowOf(data, variantOf(member).Size ?? null);
    const rows = row == null ? [...sizeRows, ...variantRows] : [row, ...variantRows];
    return claimsFor(data, name, rows, roleMetrics);
  };

  // ── canvas → code ─────────────────────────────────────────────────────────
  for (const member of members) {
    const claims = claimsOn(member);
    if (claims.length === 0) continue;
    for (const t of textNodesUnder(member, false)) {
      if (typeof t.fontSize !== 'number' || isGlyphText(t, varNames)) continue;
      const got = writtenLetterSpacingPx(t);
      if (got == null) continue;
      const size = t.fontSize;
      // A label bound to a role no field states, tracked exactly as that role
      // sets it, is the preview's own line (a TextBlock's title over its
      // paragraph): no claim of this component owns it. A label whose
      // tracking leaves its role's is still judged against the claims.
      const role = trackingRoleOf(t, varNames);
      const roleEm = role == null ? null : roleMetrics[role]?.letterSpacing;
      if (
        role != null &&
        roleEm != null &&
        !claims.some((c) => c.role === role) &&
        Math.abs(roleEm * size - got) < 0.01
      ) {
        continue;
      }
      const wanted = trackingClaimsAt(claims, size);
      if (wanted.length === 0) continue;
      tally.n += 1;
      judged += 1;
      if (!hasTextBinding(t, 'letterSpacing')) unbound += 1;
      if (wanted.some((w) => Math.abs(w.px - got) < 0.01)) continue;
      const paths = Array.from(new Set(wanted.map((w) => w.path))).join(' / ');
      const key = `${paths}|${size}|${got.toFixed(2)}`;
      if (seen.has(key)) continue;
      seen.add(key);
      // `makeLabel` never sets `.name` — a real Figma text node auto-renames
      // to its `.characters` once they are set, but the fake DOM under this
      // selftest does not carry that behaviour, so `t.name` reads back as
      // `""` for every builder-drawn label and the report says `on ""`. Fall
      // back to the words themselves, then to the member, so the pointer is
      // never emptier than "some text in this member".
      const nodeLabel = t.name || t.characters.slice(0, 24) || member.name;
      out.push({
        component: name,
        field: `${paths}.letterSpacing`,
        expected: `${wantedWidths(wanted, size)} on "${nodeLabel}"`,
        actual: `${got.toFixed(2)}px in "${member.name}"`,
        looksLike:
          'the words sit tighter or looser than the widget sets them — a ' +
          "role's ratio applied at a neighbouring rung's size, so the label " +
          'is the right size and the wrong width',
      });
    }
  }

  // ── code → canvas ─────────────────────────────────────────────────────────
  //
  // Whole set as one rung when there is no `Size` axis: the claims are the
  // set's, and so is the text.
  const rungs = rungsOf(members);
  const groups: [string, readonly ComponentNode[]][] =
    rungs.size === 0 ? [['', members]] : [...rungs];
  for (const [sizeKey, rung] of groups) {
    const claims = claimsOn(rung[0]);
    if (claims.length === 0) continue;
    // Instances included here and not above: this direction asks whether the
    // stated tracking reached the picture, and a composed child placed at this
    // rung is part of the picture.
    const bySize = new Map<number, TextNode[]>();
    for (const member of rung) {
      for (const t of textNodesUnder(member, true)) {
        if (typeof t.fontSize !== 'number' || isGlyphText(t, varNames)) continue;
        const at = bySize.get(t.fontSize);
        if (at == null) bySize.set(t.fontSize, [t]);
        else at.push(t);
      }
    }
    for (const [size, nodes] of bySize) {
      const wanted = trackingClaimsAt(claims, size);
      if (wanted.length === 0) continue;
      tally.n += 1;
      const reached = nodes.some((t) => {
        const got = writtenLetterSpacingPx(t);
        return got != null && wanted.some((w) => Math.abs(w.px - got) < 0.01);
      });
      if (reached) continue;
      const paths = Array.from(new Set(wanted.map((w) => w.path))).join(' / ');
      const where = sizeKey === '' ? 'this component' : `the Size=${sizeKey} rung`;
      const seenPx = Array.from(
        new Set(
          nodes.map((t) => {
            const got = writtenLetterSpacingPx(t);
            return got == null ? 'unset' : got.toFixed(2);
          }),
        ),
      ).join(', ');
      out.push({
        component: name,
        field: `${paths}.letterSpacing`,
        expected: `${wantedWidths(wanted, size)} on some ${size}px TEXT of ${where}`,
        actual: `${nodes.length} such node(s), tracked ${seenPx}`,
        looksLike:
          'the words sit looser than the widget sets them — the tracking the ' +
          'type scale states never reached the label, which reads as a slightly ' +
          'wider line at the right size',
      });
    }
  }

  if (unbound > 0) {
    notes.push({
      component: name,
      field: 'letterSpacing.binding',
      detail:
        `${unbound} of ${judged} label(s) carry letter spacing as a literal — ` +
        'no variable, no text style. Right today; will not follow the type ' +
        'scale when a role is retuned.',
    });
  }
  return out;
}

// The distinct widths a set of claims asks for, as one phrase. Distinct because
// five fields sharing a role produce five identical numbers, and "-0.14px or
// -0.14px or -0.14px" reads as if they disagreed.
function wantedWidths(
  wanted: readonly { em: number; px: number }[],
  size: number,
): string {
  return Array.from(
    new Set(wanted.map((w) => `${w.px.toFixed(2)}px (${w.em}em × ${size}px)`)),
  ).join(' or ');
}

// The claims that could have set the tracking of a node rendering at `size`,
// each with the pixels it asks for there.
function trackingClaimsAt(
  claims: readonly TextClaim[],
  size: number,
): { path: string; em: number; px: number }[] {
  const out: { path: string; em: number; px: number }[] = [];
  for (const c of claims) {
    if (c.fontSize == null || Math.abs(c.fontSize - size) >= 0.01) continue;
    if (c.letterSpacingEm == null) continue;
    out.push({ path: c.path, em: c.letterSpacingEm, px: c.letterSpacingEm * size });
  }
  return out;
}

// ── Mark stroke ─────────────────────────────────────────────────────────────
//
// A field that states how THICK a mark drawn as a bar is — the indeterminate
// dash of a checkbox. On this canvas such a mark is a RECTANGLE named
// `kMarkBarName`, and its thickness is the rectangle's height.
//
// Only `mark…Thickness`. A glyph drawn from an `Icon` instance (a checkmark) is
// not a bar and is not read here: it follows the icon stroke rule, so no
// component field states its weight, and a field that did would be a second
// source for a value the icon already owns. A divider's or connector's
// thickness is a different rectangle's height and belongs to a different check.
const kMarkStrokeField = /^mark[A-Za-z]*Thickness$/;

function markStrokeFields(data: unknown): string[] {
  const keys = new Set<string>();
  const collect = (record: unknown): void => {
    if (record == null || typeof record !== 'object' || Array.isArray(record)) return;
    for (const key of Object.keys(record as Record<string, unknown>)) {
      if (kMarkStrokeField.test(key)) keys.add(key);
    }
  };
  collect(fieldOf(data, ['fields']));
  for (const row of allRowsOf(data, 'sizes')) collect(row);
  for (const row of allRowsOf(data, 'variants')) collect(row);
  return [...keys];
}

// The height of every mark bar under `node`, hidden ones included. A bar the
// member's state does not show is still geometry the builder drew, and one that
// is only right while it is visible is wrong the moment its state is selected.
function markBarHeightsUnder(node: SceneNode): number[] {
  const out: number[] = [];
  const stack: SceneNode[] = [node];
  while (stack.length > 0) {
    const n = stack.pop() as SceneNode;
    if (n.type === 'RECTANGLE' && n.name === kMarkBarName) {
      const h = (n as unknown as { height?: unknown }).height;
      if (typeof h === 'number') out.push(h);
    }
    const kids = (n as unknown as { children?: readonly SceneNode[] }).children;
    if (kids != null) for (const kid of kids) stack.push(kid);
  }
  return out;
}

// `markThickness` → the mark bar's HEIGHT in EVERY member that draws one.
//
// The defect this reads for: a bar sized from a literal, or from the box, while
// the widget draws it at one thickness on every size. Nothing else here reads a
// bar's height, and the box's own border (a different field, a different node)
// is not this.
//
// What it does NOT read: the checkmark beside the bar. That is an `Icon`
// instance and its stroke belongs to the icon rule, so requiring its vectors to
// equal `markThickness` would report the icon doing its job as a disagreement.
//
// `strokeUnstated` names the components with no such field: they are not
// compared, and a zero-miss line must not read as if they were.
function checkMarkStroke(
  data: unknown,
  members: readonly ComponentNode[],
  name: string,
  tally: Tally,
  unchecked: string[],
  strokeUnstated: string[],
): FidelityMiss[] {
  const fields = markStrokeFields(data);
  if (fields.length === 0) {
    strokeUnstated.push(name);
    return [];
  }
  const out: FidelityMiss[] = [];
  for (const field of fields) {
    const wanted = statedValues(data, [field]);
    if (wanted.length === 0) continue;
    const bars = members.map((m) => markBarHeightsUnder(m));
    if (bars.every((b) => b.length === 0)) {
      unchecked.push(
        `${name}.${field}: states ${wanted.join(' / ')} but no "${kMarkBarName}" bar under any member — nothing compared`,
      );
      continue;
    }
    // Members that draw no bar at all are not judged. A bar is a shape, and a
    // variant may legitimately not draw one; requiring a height there would
    // report the bar's ABSENCE under a field that describes its thickness, and
    // absence has its own check. The count is carried into the sentence so the
    // reader is told how many members the claim was actually put to.
    let failing = 0;
    let judged = 0;
    let first: { member: string; heights: number[] } | null = null;
    members.forEach((member, i) => {
      const heights = bars[i];
      if (heights.length === 0) return;
      tally.n += 1;
      judged += 1;
      if (heights.every((h) => wanted.some((want) => Math.abs(h - want) < 0.01))) return;
      failing += 1;
      if (first == null) first = { member: member.name, heights };
    });
    if (failing === 0 || first == null) continue;
    const sample = first as { member: string; heights: number[] };
    const seenHeights = Array.from(new Set(sample.heights.map((h) => h.toFixed(2)))).join(', ');
    out.push({
      component: name,
      field,
      expected: `a "${kMarkBarName}" bar ${wanted.join(' / ')} tall in every member that draws one`,
      actual:
        `${failing} of the ${judged} member(s) that draw one draw it otherwise — ` +
        `"${sample.member}" draws it ${seenHeights} tall`,
      looksLike:
        'the bar is thicker or thinner than the widget draws it, so it does not ' +
        'read as the same weight as the checkmark beside it',
    });
  }
  return out;
}

// Component property definitions live on the SET, never on a member.
//
// Not a value comparison — a structural one that the harness now also
// enforces at `combineAsVariants`. Kept here too because the harness sees a
// double and this sees the document: a set built by an earlier version of the
// plugin still carries the wrong shape, and only a readback finds it.
function checkPropertyOwner(
  data: unknown,
  node: SceneNode,
  tally: Tally,
): FidelityMiss[] {
  if (node.type !== 'COMPONENT_SET') return [];
  tally.n += 1;
  // Read the SET, never a member. Figma throws on a variant —
  //
  //   in get_componentPropertyDefinitions: Can only get component property
  //   definitions of a component set or non-variant component
  //
  // — so the first version of this check, which scanned members looking for
  // definitions in the wrong place, could not run at all on a real canvas. It
  // passed the harness because the double stored the field as a plain object on
  // every node and answered `undefined` for a member.
  //
  // The state it was looking for is also unreachable now: `addComponentProperty`
  // throws on a variant, which the runtime harness asserts, so a member cannot
  // come to own definitions in the first place. What IS readable and worth
  // asking is the other half of the same question — whether a designer can fill
  // the slots the widget accepts.
  //
  // Asked PER SLOT, not per set. "Does the set have any properties" let
  // DatePicker pass while its `dialogTitle` was in exactly the state TimePicker
  // was reported for, because a sibling slot had supplied the set with
  // properties.
  //
  // Two mechanisms count, and which one applies depends on where the slot's text
  // lives. ColorPicker draws its own title node, so a host `dialogTitle` TEXT
  // property binds straight to it. DatePicker and TimePicker put the title inside
  // a `Dialog` INSTANCE, where a host property cannot reach — the instance is
  // exposed instead, and the designer edits the Dialog's own Title one level in.
  // Accepting only the first would report the second as broken when it is the
  // mechanism Figma provides for that shape.
  //
  // The exposure escape is deliberately the weaker half: any exposed instance in
  // the subtree satisfies any slot. Tightening it needs the builders to say which
  // node a slot rendered as, which they do not record. What remains crisp is the
  // case worth catching — a slot with no property AND nothing exposed, which is a
  // slot the designer cannot touch at all.
  const slots = fieldOf(data, ['slots']);
  if (slots == null || typeof slots !== 'object') return [];
  // Only NON-REPEATED slots. A `List<W>` slot cannot become a component property
  // — there is no Figma property meaning "a list of N children" — and the schema
  // says so where it emits them. Counting them reported Accordion's `items` and
  // ResponsiveRowColumn's `children` as missing something that cannot exist.
  const candidates = Object.entries(
    slots as Record<string, { repeated?: boolean }>,
  ).filter(
    ([name, v]) =>
      v?.repeated !== true && !kAlternativeContentSlots.has(`${node.name}.${name}`),
  );
  if (candidates.length === 0) return [];

  const defs = node.componentPropertyDefinitions;
  const propNames = defs == null ? [] : Object.keys(defs);
  // `Show leading#12:0` / `Leading#13:0` — the id carries the authored name
  // before `#`, and the builders spell a slot's pair as `<slot>` and
  // `Show <slot>` (any case). Case and separators fold away on both sides — the
  // contract's `valueLabel` and the panel's `Value label` are one slot, the
  // folding `figma_slot_swappability.py` applies to the same pairs.
  const fold = (name: string): string => name.toLowerCase().replace(/[^a-z0-9]/g, '');
  const authored = new Set(propNames.map((n) => fold(n.split('#')[0])));
  const exposed = hasExposedInstance(node);

  const out: FidelityMiss[] = [];
  for (const [slot] of candidates) {
    const key = fold(slot);
    if (authored.has(key) || authored.has(`show${key}`)) continue;
    if (exposed) continue;
    out.push({
      component: node.name,
      field: `slots.${slot}`,
      expected: 'a component property, or an exposed instance carrying it',
      actual: `neither — the set declares ${propNames.length} property(s)`,
      looksLike:
        'the design panel offers no way to fill a slot the widget accepts, so ' +
        'the component can only be used exactly as generated',
    });
  }
  return out;
}

// Slots that REPLACE the component's generated content rather than fill a hole
// in it. Figma has no property meaning "swap my entire body for an arbitrary
// widget", so these are non-expressible for the same reason a repeated slot is —
// listed rather than inferred because the signal is in the doc comment
// ("advanced layout"), not in the type.
//
// `RadioGroup.child` is the escape hatch beside `options`: the canvas draws the
// options path, and `child` is what a caller passes INSTEAD of it.
const kAlternativeContentSlots = new Set(['RadioGroup.child']);

// Whether any node at or under `node` is an exposed instance. Reading the flag
// is legal on any node; it is only WRITING it that requires the node to already
// live inside a component.
function hasExposedInstance(node: SceneNode): boolean {
  const self = node as unknown as {
    isExposedInstance?: boolean;
    children?: readonly SceneNode[];
  };
  if (self.isExposedInstance === true) return true;
  const kids = self.children;
  if (kids == null) return false;
  return kids.some((kid) => hasExposedInstance(kid));
}

// `absent: {field: kind}` → the canvas must show nothing for that field.
//
// The other checks in this file compare a stated value against a painted one.
// This one compares a stated *absence*, which had no check at all: a field that
// reached no value arrived as a missing key, indistinguishable from a field the
// reader failed on, so the builders supplied the rendering from their own
// knowledge. `form.ts` hugs a Button at five sites because a button with no
// width hugs its label — correct, and never compared against the code that says
// so. This is the same class as an invented literal, one step further out: not a
// number the builder made up, but a decision it made up.
//
// Scope per assertion is chosen to avoid the false positive that would make the
// check ignorable:
//   · effects — the whole subtree except INSTANCE nodes. An invented shadow is
//     invented wherever it is painted (Panel-style components cast theirs on an
//     inner frame), but an instance's shadow belongs to its own main component
//     and is checked on that component's own row.
//   · sizing — auto-layout members only. A frame without auto-layout is FIXED by
//     construction, so "not FIXED" would fail on every one of them and say
//     nothing.
// Every Semantic colour the canvas paints, at the alpha it paints it — checked
// against the alphas the component STATES for that same token.
//
// This axis was unchecked entirely. `opacity` did not appear in this file, so a
// tinted surface painted opaque read as passing: the export carries
// `{ref: "Semantic/color/primary", opacity: 0.1}`, `colorData` carries it,
// `solid()` applies it, and nothing ever asked the canvas whether it arrived.
// Five separate reports on the same axis — a selected tree row, four `Alert`
// variants, two `Banner` ones, `CodeDiff`'s surfaces — were all found by eye,
// which is the definition of a hole in a readback.
//
// Direction matters: this asks canvas → code, the same way `checkAbsence` does,
// never code → canvas. "Stated therefore painted" cannot be asserted here — a
// hover colour with no pose, a text colour that reaches the canvas as a Text
// Style rather than a fill, and a colour a composed child owns are all legitimate
// reasons for a stated colour to be absent from this subtree, and G16 is the gate
// that judges those at the source. What IS assertable is the converse: a paint
// that binds `Semantic/color/X` inside a component whose code mentions X at all
// must carry one of the alphas the code gives X. That cannot produce a false
// positive from composition, only from a genuine disagreement.
//
// Instances are skipped for the reason `shadowOwners` skips them: an instance's
// fill belongs to the component it instances, and attributing it here would
// report `Alert` for a colour `Button` chose.
function checkFillAlpha(
  data: unknown,
  member: ComponentNode,
  component: string,
  varNames: Map<string, string>,
  composedColors: Map<string, { ref: string; alpha: number }>,
  tally: Tally,
): FidelityMiss[] {
  const stated = statedAlphasByRef(data);
  if (stated.size === 0) return [];
  tally.n += stated.size;
  const factors = statedAlphaFactors(data);
  const out: FidelityMiss[] = [];
  const seen = new Set<string>();

  // Iterative, with an explicit stack. Recursion descends a member's whole subtree
  // and this command reads 144 of them — and this runtime reports a spent stack as
  // `InternalError: stack underflow`, a message that names neither the component nor
  // the check. An explicit stack cannot reach that state.
  // Two plain passes rather than a `for…of` over an `as const` tuple array with a
  // `continue` inside it. The tuple form reads better and it is an unusual shape for
  // this VM to compile — destructuring a literal-array-of-tuples, inside a loop, with
  // early `continue`s — and this file is being read while a VM-level
  // `InternalError: stack underflow` is unexplained. Plain code costs nothing here.
  const visit = (n: SceneNode) => {
    const surfaces: { kind: 'fill' | 'stroke'; paints: unknown }[] = n.type === 'TEXT' && drawsAmbientInk(n) ? [] : [
      { kind: 'fill', paints: (n as unknown as { fills?: unknown }).fills },
      { kind: 'stroke', paints: (n as unknown as { strokes?: unknown }).strokes },
    ];
    for (const surface of surfaces) {
      const kind = surface.kind;
      const paints = surface.paints;
      if (!Array.isArray(paints)) continue;
      for (const paint of paints as readonly Paint[]) {
        if (paint.type !== 'SOLID' || paint.visible === false) continue;
        const colorId = paint.boundVariables?.color?.id;
        const composed = colorId == null ? undefined : composedColors.get(colorId);
        const ref = composed?.ref ?? boundColorRef(paint, varNames);
        if (ref == null) continue;
        // An opaque BOUND color overrides separately written paint opacity.
        // A composed COLOR alias is different: the variable itself supplies
        // the alpha. Only a verified alias whose every mode has the same base
        // and opacity may use that native translucent paint.
        // So the paint object reads correct and the canvas is solid — which is
        // exactly why the check below, which samples `paint.opacity`, passed while
        // `Banner` / `Alert` / `CodeDiff` shipped saturated blocks. Reading the
        // number the plugin wrote can never see a number the platform ignores;
        // this is the shape rule that can.
        const asked = paint.opacity == null ? 1 : paint.opacity;
        if ((composed != null && Math.abs(asked - composed.alpha) > 0.005) ||
            (asked < 0.995 && composed == null && !statesPaintStrength(n))) {
          const key = `${ref}|bound-alpha`;
          if (!seen.has(key)) {
            seen.add(key);
            out.push({
              component,
              field: `boundAlpha(${ref.replace(/^Semantic\/color\//, '')})`,
              expected: composed ? `composed variable alpha ${composed.alpha}` : 'a literal paint below alpha 1, or alpha 1 with the binding',
              actual: `${kind} bound to the Variable AND asking alpha ${asked.toFixed(2)} on "${n.name}"`,
              looksLike: composed ? 'the paint opacity differs from the composed color variable; the rendered background does not match its declared alpha.' :
                'the tint renders at FULL strength — the variable supplies its own ' +
                'alpha and overwrites this one. A 10% background becomes a ' +
                'saturated block, and a component whose text is the same token ' +
                'loses its words.',
            });
          }
          continue;
        }
        const alphas = stated.get(ref);
        if (alphas == null || alphas.size === 0) continue;
        // The RENDERED alpha is the paint's times the layer's. Below alpha 1 a
        // token fill has to keep the paint at full strength — a bound colour
        // overwrites the paint's alpha — so the alpha lives on the node (its own,
        // when it holds nothing; a `tint` layer's, when it does). Reading only the
        // paint reported those as alpha 1 and called them wrong.
        const layerAlpha = (n as unknown as { opacity?: number }).opacity;
        // A tint layer that does not cover its host renders a partial wash — the
        // shape the first canvas run showed, every Banner short of its right and
        // bottom edges by about its padding. Checked here because it is the same
        // question this function already asks (does the stated alpha reach the
        // box?) and the answer was "yes, over 85% of it".
        if (n.name === 'tint' || n.name === 'tint border') {
          const host = n.parent as unknown as { width?: number; height?: number } | null;
          const hw = host == null ? 0 : host.width ?? 0;
          const hh = host == null ? 0 : host.height ?? 0;
          const short = hw - n.width > 0.5 || hh - n.height > 0.5;
          if (short) {
            const key = `${n.name}|short`;
            if (!seen.has(key)) {
              seen.add(key);
              out.push({
                component,
                field: 'tintLayer.size',
                expected: `${hw.toFixed(0)}×${hh.toFixed(0)} — its host's box`,
                actual: `${n.width.toFixed(0)}×${n.height.toFixed(0)}`,
                looksLike:
                  'the tint stops short of the right and bottom edges, which reads ' +
                  'as a gradient or a deliberate inset rather than a background.',
              });
            }
          }
        }
        // A layer at 0 renders nothing, so its fill's alpha is not a claim about
        // anything. `Swap` holds both of its two labels in the stack and crossfades
        // between them (`Opacity(v)`, 0 or 1) — that zero is which slot is SHOWING,
        // not a colour at 0%.
        if (layerAlpha === 0) continue;
        const got =
          (paint.opacity == null ? 1 : paint.opacity) *
          (typeof layerAlpha === 'number' ? layerAlpha : 1);
        if (acceptableAlphas(alphas, factors).some((w) => Math.abs(w - got) < 0.005)) {
          continue;
        }
        const key = `${ref}|${got}`;
        if (seen.has(key)) continue;
        seen.add(key);
        out.push({
          component,
          field: `alpha(${ref.replace(/^Semantic\/color\//, '')})`,
          expected:
            `${kind} alpha ${[...alphas].sort().join(' / ')}` +
            (factors.size === 0
              ? ''
              : `, or that times one of ${[...factors.values()].sort().join(' / ')}`),
          actual: `${got} on "${n.name}"`,
          looksLike:
            got > maxOf(alphas)
              ? 'the surface reads as a solid block of colour where the code ' +
                'tints it — at full alpha the text on top of it stops being ' +
                'legible, which is how this was noticed'
              : 'the surface is fainter than the code paints it',
        });
      }
    }
  };
  const stack: SceneNode[] = [member];
  while (stack.length > 0) {
    const n = stack.pop() as SceneNode;
    // An instance mirrors its main component, so its interior is that component's
    // claim and not this one's — the same skip the recursive form made on entry.
    if (n.type === 'INSTANCE') continue;
    visit(n);
    const kids = (n as unknown as { children?: readonly SceneNode[] }).children;
    if (kids != null) for (const kid of kids) stack.push(kid);
  }
  return out;
}

// A colour leaf's own alpha is not the only alpha the code can state. Several
// components keep the tint as a SEPARATE scalar and multiply at paint time —
// a colour stated at full alpha plus a `…Alpha` scalar that the widget applies
// with `scaleAlpha(…)`. Judged against the leaf alone, every one of those reads
// as the canvas inventing a tint; nine components did, and the canvas was right
// in all of them.
//
// So the accepted set is each stated leaf alpha, and each of those times any
// alpha-shaped scalar the same component states. Loose by construction — a
// component with three such scalars accepts three products per colour — and that
// looseness is the honest bound: which scalar multiplies which colour is a
// resolver's decision, and this module reads the canvas, not the resolver. What
// survives is a paint whose alpha the component's own fields cannot produce at
// all, which is the only claim this direction can make without guessing.
function acceptableAlphas(
  leafAlphas: ReadonlySet<number>,
  factors: ReadonlyMap<string, number>,
): readonly number[] {
  const out: number[] = [];
  for (const alpha of leafAlphas) {
    out.push(alpha);
    for (const factor of factors.values()) out.push(alpha * factor);
  }
  return out;
}

// Every alpha-shaped scalar the component states — a number strictly inside
// (0, 1) whose field name says alpha or opacity. Name-matched rather than
// range-matched alone, because plenty of fields sit in that range without being
// an alpha (a flex factor, a curve control point).
function statedAlphaFactors(data: unknown): ReadonlyMap<string, number> {
  const out = new Map<string, number>();
  const visit = (node: unknown) => {
    if (node == null || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      for (const item of node) visit(item);
      return;
    }
    for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
      const scalar =
        typeof value === 'number'
          ? value
          : dimOf(value) != null
            ? (dimOf(value) as number)
            : null;
      if (scalar != null && scalar > 0 && scalar < 1 && /alpha|opacity/i.test(key)) {
        out.set(key, scalar);
        continue;
      }
      // A state-layer ramp (`CoreStateLayer` — `{hover, focus, pressed}`) is
      // three alpha factors under names that do not say so: each rung is the
      // weight a control lays its ink over itself at. A layer node painted in
      // that ink at a rung's weight is the stated picture, not a fainter one.
      if (
        /stateLayer/i.test(key) &&
        value != null &&
        typeof value === 'object' &&
        !Array.isArray(value)
      ) {
        for (const [rung, weight] of Object.entries(value as Record<string, unknown>)) {
          if (typeof weight === 'number' && weight > 0 && weight < 1) {
            out.set(`${key}.${rung}`, weight);
          }
        }
        continue;
      }
      visit(value);
    }
  };
  visit(fieldOf(data, ['fields']));
  visit(fieldOf(data, ['variants']));
  visit(fieldOf(data, ['sizes']));
  return out;
}

// The bound Semantic variable name on a paint's colour, or null when the paint
// carries a raw colour instead.
//
// Read through `boundVariables` rather than off the paint's `color`, because the
// whole point of binding is that the rgb triple on the paint is a placeholder —
// `solid()` leaves it at black and lets the variable answer. A check that read
// `paint.color` would compare against that placeholder and pass on everything.
// `Math.max` over a set, without spreading it into an argument list. Every element
// of a spread becomes a separate ARGUMENT, and a long argument list is what this
// runtime reports as `InternalError: stack underflow` — a set of stated alphas is
// small today and nothing here bounds it.
function maxOf(values: Iterable<number>): number {
  let out = Number.NEGATIVE_INFINITY;
  for (const v of values) if (v > out) out = v;
  return out;
}

function drawsAmbientInk(node: SceneNode): boolean {
  const holder = node as unknown as { getPluginData?: (key: string) => string };
  return typeof holder.getPluginData === 'function' && holder.getPluginData(kAmbientInkKey) === '1';
}

function statesPaintStrength(node: SceneNode): boolean {
  const holder = node as unknown as { getPluginData?: (key: string) => string };
  return typeof holder.getPluginData === 'function' && holder.getPluginData(kPaintStrengthKey) === '1';
}

function boundColorRef(paint: SolidPaint, names: Map<string, string>): string | null {
  const bound = (paint as unknown as {
    boundVariables?: Record<string, { id?: string } | undefined>;
  }).boundVariables;
  const id = bound?.color?.id;
  if (id == null) return null;
  const name = names.get(id);
  return name != null && name.startsWith('Semantic/color/') ? name : null;
}

// id → name for every local variable, resolved ONCE and passed down.
//
// Not `figma.variables.getVariableById(id)` per paint, which is what stood here and
// what threw on the real canvas:
//
//   in getVariableById: Cannot call with documentAccess: dynamic-page.
//   Use figma.variables.getVariableByIdAsync instead.
//
// This plugin's manifest is `documentAccess: dynamic-page`, so the whole sync
// variable API is refused — and the harness double modelled the sync call, so every
// self-test passed while the command died on the first component it checked. The
// same shape as `layoutPositioning`: a double that answers a question the platform
// refuses to be asked.
//
// Resolved up front rather than awaited inside the walk: the walk is synchronous and
// making it async would thread a promise through every check for a map that does not
// change while it runs.
async function variableNamesById(): Promise<{
  names: Map<string, string>;
  composedColors: Map<string, { ref: string; alpha: number }>;
}> {
  const out = new Map<string, string>();
  const vars = await figma.variables.getLocalVariablesAsync();
  const collections = new Map((await figma.variables.getLocalVariableCollectionsAsync())
    .map((c) => [c.id, canonicalCollection(c.name)]));
  for (const v of vars) {
    const collection = collections.get(v.variableCollectionId);
    out.set(v.id, collection && !v.name.startsWith(`${collection}/`) ? `${collection}/${v.name}` : v.name);
  }
  const composedColors = new Map<string, { ref: string; alpha: number }>();
  for (const v of vars) {
    const composed = composedColorAlias(v);
    const ref = composed == null ? undefined : out.get(composed.baseId);
    if (composed && ref?.startsWith('Semantic/color/')) composedColors.set(v.id, { ref, alpha: composed.alpha });
  }
  return { names: out, composedColors };
}

// Every `{ref, opacity}` colour leaf anywhere in the component's data, grouped by
// ref. Variant and size tables included: a token's alpha is exactly the kind of
// thing one row changes, and reading only `fields` would have missed all four
// `Alert` variants — the only place their 0.1 is stated.
function statedAlphasByRef(data: unknown): Map<string, Set<number>> {
  const out = new Map<string, Set<number>>();
  const visit = (node: unknown) => {
    if (node == null || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      for (const item of node) visit(item);
      return;
    }
    const obj = node as Record<string, unknown>;
    const ref = obj.ref;
    if (typeof ref === 'string' && ref.startsWith('Semantic/color/')) {
      const alpha = typeof obj.opacity === 'number' ? obj.opacity : 1;
      const set = out.get(ref) ?? new Set<number>();
      set.add(alpha);
      out.set(ref, set);
    }
    for (const value of Object.values(obj)) visit(value);
  };
  visit(fieldOf(data, ['fields']));
  visit(fieldOf(data, ['variants']));
  visit(fieldOf(data, ['sizes']));
  return out;
}

function checkAbsence(
  data: unknown,
  member: ComponentNode,
  component: string,
  tally: Tally,
): FidelityMiss[] {
  const absent = fieldOf(data, ['absent']);
  if (absent == null || typeof absent !== 'object') return [];
  const out: FidelityMiss[] = [];
  const auto = member.layoutMode !== 'NONE';

  for (const [field, kind] of Object.entries(absent as Record<string, string>)) {
    const assertion = absenceAssertionFor(kind, field);
    if (assertion == null) continue;
    tally.n += 1;
    const means =
      assertion.kind === 'not-fixed-size'
        ? 'unconstrained — no fixed extent on this axis'
        : absenceMeaning(kind);
    const miss = (expected: string, actual: string, looksLike: string) =>
      out.push({ component, field: `absent.${field}`, expected, actual, looksLike });

    switch (assertion.kind) {
      case 'no-effects': {
        const painted = shadowOwners(member);
        if (painted.length > 0) {
          miss(
            `no shadow (${means})`,
            `${painted.length} drop shadow(s), on "${painted[0]}"`,
            'the component looks lifted where the code says it sits flat',
          );
        }
        break;
      }
      case 'sharp-corners': {
        const r = (member as unknown as { cornerRadius?: unknown }).cornerRadius;
        if (typeof r === 'number' && r !== 0) {
          miss(`radius 0 (${means})`, String(r), 'the corners are rounded where the code says they are square');
        }
        break;
      }
      case 'no-padding': {
        if (!auto) break;
        const insets = [member.paddingLeft, member.paddingRight, member.paddingTop, member.paddingBottom];
        if (insets.some((v) => typeof v === 'number' && v !== 0)) {
          miss(`0 on all sides (${means})`, insets.join('/'), 'the content sits inset where the code says it is flush');
        }
        break;
      }
      case 'no-spacing': {
        if (!auto) break;
        if (typeof member.itemSpacing === 'number' && member.itemSpacing !== 0) {
          miss(`0 (${means})`, `${member.itemSpacing}`, 'the children are spaced apart where the code says they touch');
        }
        break;
      }
      case 'not-fixed-size': {
        // A sizing MODE field governs the axis, so the extent field's absence
        // says nothing about it. Card is the one component with one: `sizing`
        // picks `expand` (the resolver hands the widget an infinite width) or
        // `intrinsic` (`IntrinsicWidth`), and `width` stays null either way.
        // Reading the absence as "hug" reported the 260px preview card as
        // pinned when what pins it is a decision the component does state.
        if (governedBySizingMode(data)) break;
        // Four distinct Figma properties, picked by which field is absent:
        // `width`/`height` are the axis sizing mode, `min*`/`max*` are the
        // constraint slots (null when unconstrained). Reading the axis mode for
        // a `maxWidth` field would conflate "hugs" with "has no ceiling".
        if (!auto) break;
        const bound = field.match(/^(min|max)(Width|Height)$/);
        if (bound) {
          const key = field as 'minWidth' | 'maxWidth' | 'minHeight' | 'maxHeight';
          const v = (member as unknown as Record<string, unknown>)[key];
          if (typeof v === 'number') {
            miss(`no ${bound[1]} constraint (${means})`, `${key} = ${v}`, `the component ${bound[1] === 'min' ? 'refuses to shrink' : 'refuses to grow'} where the code sets no limit`);
          }
          break;
        }
        const axis = field === 'height' ? 'layoutSizingVertical' : 'layoutSizingHorizontal';
        const mode = (member as unknown as Record<string, unknown>)[axis];
        if (mode === 'FIXED') {
          miss(`HUG or FILL (${means})`, 'FIXED', 'the component is pinned to one size where the code lets it size to content');
        }
        break;
      }
    }
  }
  return out;
}

// Field names a component states ONLY under a per-size / per-variant table, for
// the checks that read `fields` and would otherwise skip in silence.
//
// Existence is what is reported, not a comparison: the row the preview draws is
// the builder's choice and is not in the data, so there is nothing here to assert
// against.
function tableOnly(data: unknown, field: string): boolean {
  if (fieldOf(data, ['fields', field]) != null) return false;
  for (const bucket of ['sizes', 'variants']) {
    const tables = fieldOf(data, [bucket]);
    if (tables == null || typeof tables !== 'object') continue;
    for (const table of Object.values(tables as Record<string, unknown>)) {
      if (table == null || typeof table !== 'object') continue;
      for (const row of Object.values(table as Record<string, unknown>)) {
        if (row != null && typeof row === 'object' && field in row) return true;
      }
    }
  }
  return false;
}

// The one structural check here, and it earns the exception: every other check in
// this module compares a value the canvas states against the value
// `components.json` states, and this defect is invisible to all of them because
// both values were right. `TimePicker` drew its digits twice — a 44px value with
// an offset 14px copy of the same characters behind it — while the canvas
// reported the correct 44 for the field it was asked about.
//
// The invariant is the widget's: `TextField` is `Stacks(placeholder?, editable)`
// behind a `Visibility(maintainSize: true)`, so at most ONE of the two ever
// draws. An empty field shows the placeholder; a field with a value shows the
// value. Never both, at any size — equal sizes only make the disagreement small
// enough to miss, since the placeholder is the in-flow child and the value is
// absolute, and nothing keeps them aligned.
//
// Counted per input stack rather than per component: a component may hold several
// fields (the colour picker has four) and the count has to stay local to be a
// statement about one of them.
function checkStackedText(
  members: readonly ComponentNode[],
  component: string,
  tally: Tally,
): readonly FidelityMiss[] {
  const out: FidelityMiss[] = [];
  const visitNode = (node: SceneNode, member: string): void => {
    if (!node.visible) return;
    if (node.type === 'FRAME' && node.name === kInputStackName) {
      tally.n += 1;
      const strings = visibleStringsAtOrigin(node);
      if (strings.length > 1) {
        out.push({
          component,
          field: `${member} · ${kInputStackName}`,
          expected: `at most 1 visible string (Stacks(placeholder?, editable) ` +
            `behind Visibility(maintainSize: true) shows one)`,
          actual: `${strings.length}: ${strings.join(' + ')}`,
          looksLike:
            'The field draws its value twice, the second copy offset behind the ' +
            'first — the placeholder is the in-flow child and the value is ' +
            'absolute, so they never register.',
        });
      }
      return;
    }
  };
  // Explicit stack, same reason as the other two walks here — and this one descends
  // EVERY member, which for `Button` is 576 subtrees in one call.
  for (const member of members) {
    const pending: SceneNode[] = [member];
    while (pending.length > 0) {
      const node = pending.pop() as SceneNode;
      visitNode(node, member.name);
      const kids = (node as unknown as { children?: readonly SceneNode[] }).children;
      if (kids) for (const kid of kids) pending.push(kid);
    }
  }
  return out;
}

const kInputStackName = 'input';
const kValueHolderName = 'value';

// The strings an input stack actually shows: its own visible TEXT children (the
// placeholder) plus those inside a visible `value` holder (the editable).
//
// Instances are walked into rather than skipped, unlike `shadowOwners` — the
// state being looked for lives precisely in composed instances, because it is
// their overrides that reveal the value.
function visibleStringsAtOrigin(stack: SceneNode): readonly string[] {
  const out: string[] = [];
  const kids = (stack as unknown as { children?: readonly SceneNode[] }).children ?? [];
  for (const kid of kids) {
    if (!kid.visible) continue;
    if (kid.type === 'TEXT') out.push(`${kid.name}="${kid.characters}"`);
    if (kid.type !== 'FRAME' || kid.name !== kValueHolderName) continue;
    for (const inner of (kid as FrameNode).children) {
      if (inner.visible && inner.type === 'TEXT') {
        out.push(`${kid.name}/${inner.name}="${inner.characters}"`);
      }
    }
  }
  return out;
}

// Whether the component states a sizing MODE, which decides the extent that its
// `width`/`height` fields leave null.
function governedBySizingMode(data: unknown): boolean {
  const fields = fieldOf(data, ['fields']);
  if (fields == null || typeof fields !== 'object') return false;
  return Object.keys(fields as Record<string, unknown>).some((k) =>
    k.toLowerCase().includes('sizing'),
  );
}

// Names of nodes at or under `node` that cast a drop shadow, skipping instances
// (see `checkAbsence`). Names rather than nodes so the message can point at the
// one that has it.
//
// A shadow at zero alpha casts nothing, and is not counted. That is the shape
// of the cast a surface style contributes to a control that states none: its
// colour is bound to a row that is transparent under the default style, so the
// default render this audit reads sits flat — as the code's own absent shadow
// says — and only a style that contributes a cast lifts it.
function shadowOwners(node: SceneNode): readonly string[] {
  const out: string[] = [];
  // Explicit stack, for the reason `checkFillAlpha`'s walk has one.
  const stack: SceneNode[] = [node];
  while (stack.length > 0) {
    const n = stack.pop() as SceneNode;
    if (n.type === 'INSTANCE') continue;
    const effects = (n as unknown as { effects?: readonly Effect[] }).effects;
    const casts = (e: Effect): boolean =>
      e.type === 'DROP_SHADOW' && e.visible !== false && e.color.a > 0;
    if (effects != null && effects.some(casts)) {
      out.push(n.name);
    }
    const kids = (n as unknown as { children?: readonly SceneNode[] }).children;
    if (kids != null) for (const kid of kids) stack.push(kid);
  }
  return out;
}

// ── Sweep ───────────────────────────────────────────────────────────────────

// Reads every component the REGISTRY produced and reports what the canvas
// says that the code did not.
//
// Chrome is checked on the FIRST member; text sizes are checked across ALL of
// them.
//
// The split is about what a variant axis changes. Padding, radius and shadow
// come from the component's own `fields`, so all 576 Button variants carry the
// same ones and checking each would report one miss 576 times. What a variant
// axis DOES change is which nodes exist: `Fab` draws its action label only when
// `Open=true`, so only its `Open=true` members have the 13px role the data states.
// Reading the first member alone called that missing — the claim that members
// share one recipe was true of the values and false of the content.
//
// Cost is bounded by the shape of the walk: text collection visits nodes, and a
// set's members partition its nodes, so scanning every member of Button costs
// what scanning Button costs.
//
// Property ownership is neither — it belongs to the set, and is read there.
/**
 * The component the walk is on, for the error path — see the assignment in the loop.
 * Module-level on purpose: a VM-level failure leaves no locals to read.
 */
export let lastFidelityEntry = '(none)';

export async function verifyFidelity(entryName?: string): Promise<FidelityReport> {
  const log: string[] = [];
  const misses: FidelityMiss[] = [];
  let componentsRead = 0;
  let checksRun = 0;
  // Once, before the synchronous walk — the sync `getVariableById` is refused under
  // this manifest's `documentAccess: dynamic-page`.
  const { names: varNames, composedColors } = await variableNamesById();

  // Document-wide, and installed so the shared child lookups in `helpers`
  // resolve too — this command runs on its own, with no generate pass to have
  // filled the index for it.
  const index = await indexDocumentComponents();
  installNodeIndex(index);
  if (index.size === 0) {
    return {
      log: [
        'No components in this document — run 컴포넌트 생성 first. Nothing was ' +
          'checked, which is not the same as nothing being wrong.',
      ],
      misses: [],
      componentsRead: 0,
      checksRun: 0,
      unchecked: [],
      hostDerived: [],
      notes: [],
      strokeUnstated: [],
      fixtures: [],
    };
  }

  // `COMPONENTS` is already the per-slug map (`data.ts` unwraps the document),
  // and the role table is a sibling of it at the document root.
  const components = COMPONENTS as unknown as Record<string, unknown>;
  const roleMetrics = (TYPOGRAPHY ?? {}) as Record<string, RoleMetrics>;

  const entries = entryName
    ? REGISTRY.filter((e) => e.name === entryName)
    : REGISTRY;
  if (entries.length === 0) {
    return {
      log: [`No REGISTRY entry named "${entryName}".`],
      misses: [],
      componentsRead: 0,
      checksRun: 0,
      unchecked: [],
      hostDerived: [],
      notes: [],
      strokeUnstated: [],
      fixtures: [],
    };
  }

  const missing: string[] = [];
  const fixtures: string[] = [];
  const unchecked: string[] = [];
  const hostDerived: string[] = [];
  const notes: FidelityNote[] = [];
  const strokeUnstated: string[] = [];
  for (const entry of entries) {
    // Which component this loop is on, readable from the catch. A runtime-level
    // failure (`InternalError: stack underflow`) unwinds past every local, so the
    // only way the report can name the component is for the name to live outside
    // the loop — and without a name, the next attempt is another whole run spent
    // learning nothing.
    lastFidelityEntry = entry.name;
    // A fixture has no contract, so there is no record to compare it against —
    // its drawing is asserted by the selftest it names instead. Listed rather
    // than skipped, so the count of what was read still adds up.
    if (entry.fixture) {
      fixtures.push(`${entry.name} (${entry.fixture.checkedBy})`);
      continue;
    }
    const node = index.get(entry.name) ?? null;
    if (!node) {
      // Absent is worth its own line, not a miss: it means generation never
      // produced it, and the generate log is where that story lives.
      missing.push(entry.name);
      continue;
    }
    // The entry's own slug unless it says otherwise — a widget that shares
    // another component's Core Style states where its chrome lives.
    const slug =
      entry.dataSlug ?? entry.name.replace(/(?!^)([A-Z])/g, '_$1').toLowerCase();
    const data = scopeToFragment(components[slug], entry.dataFields);
    if (data == null) {
      // No data means nothing to compare against — this component is outside the
      // whole point of this command, and saying so is the only honest report.
      //
      // It was a bare `continue`, which is why 144 built and 143 were read with
      // nothing accounting for the difference. The cause is upstream: the reader
      // enumerates `{category}/{component}/`, one level deep, and a component
      // nested further (`layout/table/resizable_table.dart`) is never read. Its
      // canvas node is built from the builder's own literals and no one can tell
      // whether they match the code.
      unchecked.push(`${entry.name}: no data in components.json — nothing compared`);
      continue;
    }
    // A set whose members claim the same combination twice is in Figma's
    // "existing errors" state, and there every property read throws. Reaching
    // one used to end the whole sweep with the set's name and nothing else —
    // the failure that made a full export impossible while the report itself
    // had no way to say why. Reported and stepped over instead: one broken set
    // is a defect on one component, not a reason to check none of the others.
    // Not counted as read, because nothing was.
    if (node.type === 'COMPONENT_SET') {
      const duplicates = findDuplicateVariantNames(
        node.children.filter((c) => c.type === 'COMPONENT').map((c) => c.name),
      );
      if (duplicates.length > 0) {
        misses.push({
          component: entry.name,
          field: 'variant names',
          expected: 'each member claims its combination once',
          actual: `${duplicates.length} name(s) claimed twice or more`,
          looksLike: describeDuplicateVariants(entry.name, duplicates),
        });
        unchecked.push(
          `${entry.name}: duplicate variant names — property reads throw, so nothing was compared`,
        );
        continue;
      }
    }
    componentsRead += 1;

    const found: FidelityMiss[] = [];
    // One tally per component, handed to every check. Each check adds only when it
    // actually found a stated value to compare — which is why this cannot come out
    // as a multiple of the component count.
    const tally: Tally = { n: 0 };
    for (const miss of checkPropertyOwner(data, node, tally)) found.push(miss);

    const members = membersOf(node);
    const first = members[0];
    if (first) {
      for (const miss of checkPadding(data, first, entry.name, tally)) found.push(miss);
      for (const miss of checkRadius(data, first, entry.name, tally)) found.push(miss);
      for (const field of ['boxShadow', 'panelBoxShadow', 'shadow', 'panelShadow', 'keyShadow']) {
        for (const miss of checkShadow(data, first, field, entry.name, tally)) found.push(miss);
      }
      for (const miss of checkAbsence(data, first, entry.name, tally)) found.push(miss);
      for (const miss of checkFillAlpha(data, first, entry.name, varNames, composedColors, tally)) found.push(miss);
      // `padding` / `borderRadius` are compared against every stated row above,
      // so only the shapes still unread are recorded — a shadow's layer list and
      // a typography role, both of which need the row identity this module does
      // not have.
      for (const field of ['boxShadow']) {
        if (tableOnly(data, field)) unchecked.push(`${entry.name}.${field}`);
      }
      // `hostDerived` — the value reaches the widget from its host at render
      // time (`@hostDerived` in coui_core), so the canvas demo may show any
      // host's value and there is nothing to assert. Listed, not silent: an
      // axis nobody checks must say so.
      for (const miss of checkDerivedDefaults(data, members, entry.name, tally, unchecked)) {
        found.push(miss);
      }
      const hostDerivedFields = fieldOf(data, ['hostDerived']);
      if (Array.isArray(hostDerivedFields)) {
        for (const field of hostDerivedFields) {
          hostDerived.push(`${entry.name}.${String(field)}`);
        }
      }
      for (const miss of checkTextSizes(data, members, roleMetrics, entry.name, tally))
        found.push(miss);
      for (const miss of checkTextSizesPerRung(data, members, roleMetrics, entry.name, tally))
        found.push(miss);
      for (const miss of checkLetterSpacing(
        data,
        members,
        roleMetrics,
        entry.name,
        varNames,
        tally,
        notes,
      ))
        found.push(miss);
      for (const miss of checkMarkStroke(
        data,
        members,
        entry.name,
        tally,
        unchecked,
        strokeUnstated,
      ))
        found.push(miss);
    }
    for (const miss of checkStackedText(members, entry.name, tally)) found.push(miss);
    checksRun += tally.n;

    if (found.length > 0) {
      for (const miss of found) misses.push(miss);
      for (const miss of found) {
        log.push(
          `✗ ${miss.component} · ${miss.field}: expected ${miss.expected}, ` +
            `canvas has ${miss.actual}`,
        );
        log.push(`    ${miss.looksLike}`);
      }
    }
  }

  if (fixtures.length > 0) {
    log.push(
      `○ ${fixtures.length} builder fixture(s) not compared — no contract to ` +
        `compare against; the named selftest asserts each: ${fixtures.join(', ')}`,
    );
  }
  if (missing.length > 0) {
    log.push(
      `○ ${missing.length} entry(s) not on the page: ${missing.join(', ')} — ` +
        'not a fidelity miss; see the generate log for why they are absent.',
    );
  }
  log.push(
    misses.length === 0
      ? `✅ ${componentsRead} component(s) read, ${checksRun} check(s) run, ` +
        'no disagreement with components.json.'
      : `❌ ${misses.length} disagreement(s) across ${componentsRead} ` +
        `component(s) (${checksRun} checks run).`,
  );
  log.push(
    '   Scope: only values components.json states outright. A value the ' +
      'builder invents has nothing to compare against and is invisible here ' +
      '— the literal ratchet counts those separately.',
  );
  if (unchecked.length > 0) {
    log.push(
      `○ ${unchecked.length} stated value(s) not compared — chrome under a ` +
        'per-size / per-variant tables or dynamic relations the canvas audit ' +
        'does not yet compare:',
    );
    for (const u of unchecked) log.push(`    ${u}`);
  }
  if (hostDerived.length > 0) {
    log.push(
      `○ ${hostDerived.length} host-derived value(s) not comparable by design — ` +
        'the host injects the value at render time, so the demo shows its demo ' +
        "host's value and no assertion is possible:",
    );
    for (const h of hostDerived) log.push(`    ${h}`);
  }
  if (notes.length > 0) {
    log.push(
      `ℹ ${notes.length} note(s) — not disagreements; values that are right ` +
        'today and carried as literals:',
    );
    for (const n of notes) log.push(`    ${n.component} · ${n.field}: ${n.detail}`);
  }
  if (strokeUnstated.length > 0) {
    log.push(
      `○ mark stroke: ${strokeUnstated.length} component(s) state no mark ` +
        'thickness — the stroke axis compared nothing on them: ' +
        strokeUnstated.join(', '),
    );
  }
  return {
    log,
    misses,
    componentsRead,
    checksRun,
    unchecked,
    hostDerived,
    notes,
    strokeUnstated,
    fixtures,
  };
}

// ── The exit ────────────────────────────────────────────────────────────────
//
// Everything above produces a typed disagreement — component, field, expected,
// actual, and the symptom a designer would see. All of it has been dying in a
// log pane: the sweep runs, the reader scrolls, the plugin closes, and the next
// person starts from nothing. A miss that is not written down is a miss found
// again.
//
// The plugin cannot write a file or reach the network (`networkAccess: none`),
// so the only exit is a Blob the browser downloads. This turns the report into
// the shape the repo side reads — the same one `export-dart` already uses for
// its `.dart` files, because a second mechanism would be a second thing to keep
// working.

// Bumped when a field moves or changes meaning. Present so the reader can refuse
// an envelope it does not understand instead of quietly reading a field that is
// no longer the one it wants.
const kFidelityEnvelopeSchema = 1;

// Names the producer. A JSON file in a drop directory says nothing about where
// it came from, and the reader must be able to reject an unrelated one rather
// than report its absent fields as an empty sweep.
const kFidelityEnvelopeKind = 'coui-figma-fidelity';

// Indented, because this file lands in a git tree: on one line every change is
// the same change, and the diff stops being able to say what moved.
const kEnvelopeIndent = 2;

/**
 * The report as the JSON envelope the repo side reads.
 *
 * `buildHash` rides along because a miss is only attributable to the code that
 * produced it. Two reports that disagree are unreadable until you know whether
 * the same plugin build wrote them — and the hash is the one value in this
 * session that answers that.
 *
 * `entryFilter` distinguishes a sweep that found nothing from a sweep that
 * looked at one component, which are the same file otherwise. `null` means the
 * whole registry.
 *
 * The caller supplies `generatedAt` rather than this reading the clock, so the
 * name the file is saved under and the instant it claims inside come from a
 * single read — two reads can straddle a second and describe the same run as
 * two.
 */
export function serialiseFidelityReport(
  report: FidelityReport,
  // An object, not two positional strings: both are strings, and swapping them
  // would produce a well-formed envelope that is wrong in a way nothing checks.
  meta: { generatedAt: string; entryFilter: string | null },
): string {
  return JSON.stringify(
    {
      schema: kFidelityEnvelopeSchema,
      kind: kFidelityEnvelopeKind,
      generatedAt: meta.generatedAt,
      buildHash: kSharedSourceHash,
      entryFilter: meta.entryFilter,
      // The report whole, not a projection of it. A hand-listed subset here is a
      // second statement of `FidelityReport`'s shape that nothing keeps in step —
      // and `checksRun` is exactly the field a projection drops, being the one
      // that distinguishes a clean run from a run that compared nothing.
      report,
    },
    null,
    kEnvelopeIndent,
  );
}
