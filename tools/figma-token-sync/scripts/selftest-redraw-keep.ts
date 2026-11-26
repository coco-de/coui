// Self-test for src/redraw-keep.ts — a redraw keeps a designer's override on an
// inner layer.
//
// The fact the module is written around, measured in Figma: an instance's
// override on a layer of its main is stored against the main's NODE. Editing
// the main's existing children in place leaves the override standing; removing
// them and creating identical ones drops it. The double below models exactly
// that — an instance stores its overrides by the main node's id, and renders a
// layer from its main unless an override for that id exists — so the test fails
// when the reset removes the children again (checked by reverting it).
//
// Drawn through the real `mint` / `mountSet` / `resetNode` / `recordPropRef` /
// `afterNodeBindLands` / `completePendingMounts` of `identity.ts`, so the hook
// that moves a pending set's references to the kept nodes is exercised too.

import {
  afterNodeBindLands,
  completePendingMounts,
  mint,
  mountSet,
  recordPropRef,
} from '../src/identity';
import { beginLegacyCountdown, captureLegacyCountdown, restoreLegacyCountdown } from '../src/countdown-migration';
import {
  abandonRedrawParking,
  retainTextInRedrawWrapper,
  kDrawnChildrenKey,
  resetRedrawFontCache,
  drainRedrawKeepCost,
  reconcileRedrawnMembers,
  setRedrawKeepsNodes,
} from '../src/redraw-keep';

declare const process: { exit(code: number): never; argv: string[] };

// ─── the double ──────────────────────────────────────────────────────────

interface N {
  id: string;
  type: string;
  name: string;
  parent: N | null;
  children: N[];
  [key: string]: unknown;
}

let seq = 0;
const nodes = new Map<string, N>();
const mixed = Symbol('figma.mixed');
/** Writes the double refuses, as `${id}.${key}` — a refusal is a reason to replace. */
const refuse = new Set<string>();

function make(type: string): N {
  seq += 1;
  const pluginData: Record<string, string> = {};
  const n: N = {
    id: `${type}:${seq}`,
    type,
    name: '',
    parent: null,
    children: [],
    visible: true,
    opacity: 1,
    fills: [],
    strokes: [],
    width: 100,
    height: 100,
    x: 0,
    y: 0,
    removedFlag: false,
  };
  Object.defineProperty(n, 'removed', { get: () => n.removedFlag === true });
  const define = (key: string): void => {
    let store: unknown = n[key];
    Object.defineProperty(n, key, {
      configurable: true,
      enumerable: true,
      get: () => store,
      set(v: unknown) {
        if (refuse.has(`${n.id}.${key}`)) throw new Error(`in set_${key}: refused by the double`);
        store = v;
      },
    });
  };
  for (const key of ['fills', 'strokes', 'opacity', 'width', 'height', 'x', 'y', 'characters']) define(key);
  // Figma refuses an absolute pin under a parent that lays out nothing.
  let positioning: unknown = 'AUTO';
  Object.defineProperty(n, 'layoutPositioning', {
    configurable: true,
    enumerable: true,
    get: () => positioning,
    set(v: unknown) {
      const mode = n.parent?.layoutMode;
      if (v === 'ABSOLUTE' && (typeof mode !== 'string' || mode === 'NONE')) {
        throw new Error('in set_layoutPositioning: Can only set layoutPositioning = ABSOLUTE if the parent node has layoutMode !== NONE');
      }
      positioning = v;
    },
  });
  // `visible` on a layer bound to a BOOLEAN reads that property's default, and a
  // write to it REWRITES the default — measured in Figma: on a main's layer
  // bound to a property, `visible = false` turned the default false (and every
  // instance's value with it), `visible = true` turned it back.
  let visibleStore: unknown = true;
  Object.defineProperty(n, 'visible', {
    configurable: true,
    enumerable: true,
    get: () => {
      const def = boundVisibleDef(n);
      return def ? def.defaultValue : visibleStore;
    },
    set(v: unknown) {
      if (refuse.has(`${n.id}.visible`)) throw new Error('in set_visible: refused by the double');
      const def = boundVisibleDef(n);
      if (def) def.defaultValue = v;
      visibleStore = v;
      watchFlow(n);
    },
  });
  Object.assign(n, {
    loadAsync: () => Promise.resolve(),
    getPluginData: (k: string) => pluginData[k] ?? '',
    setPluginData: (k: string, v: string) => {
      if (v === '') delete pluginData[k];
      else pluginData[k] = v;
    },
    getPluginDataKeys: () => Object.keys(pluginData),
    appendChild(child: N) {
      detach(child);
      n.children.push(child);
      child.parent = n;
      if (n.type === 'COMPONENT_SET') (child as N).variantProperties = parseVariant(child.name);
    },
    insertChild(index: number, child: N) {
      detach(child);
      n.children.splice(index, 0, child);
      child.parent = n;
      if (n.type === 'COMPONENT_SET') (child as N).variantProperties = parseVariant(child.name);
    },
    remove() {
      detach(n);
      n.removedFlag = true;
    },
    resize(w: number, h: number) {
      n.width = w;
      n.height = h;
    },
    resizeWithoutConstraints(w: number, h: number) {
      n.width = w;
      n.height = h;
      watchFlow(n);
    },
    setBoundVariable(field: string, v: unknown) {
      const bv = { ...((n.boundVariables as Record<string, unknown>) ?? {}) };
      if (v == null) delete bv[field];
      else bv[field] = v;
      n.boundVariables = bv;
    },
    createInstance(): N {
      return instanceOf(n);
    },
    findAll(pred: (x: N) => boolean): N[] {
      const out: N[] = [];
      const walk = (x: N): void => {
        for (const k of x.children) {
          if (pred(k)) out.push(k);
          walk(k);
        }
      };
      walk(n);
      return out;
    },
  });
  nodes.set(n.id, n);
  return n;
}

// The double lays nothing out, so it cannot show what a wider member does to a
// child pinned to it. It records the condition instead: when a node is written,
// two children of one name in its parent's flow means the member was hugging
// both the old node and its new twin — in Figma that sized an 88-wide member's
// STRETCH ring against a wider box and left it 42 wide once the twin went.
const flowClashes: string[] = [];
const expectedFlowPeers = new WeakMap<N, number>();
function inFlow(n: N): boolean {
  return n.visible === true && n.opacity !== 0 && n.layoutPositioning !== 'ABSOLUTE';
}
function watchFlow(n: N): void {
  const parent = n.parent;
  if (!parent || !inFlow(n)) return;
  const twins = parent.children.filter((k) => k !== n && k.name === n.name && k.type === n.type && inFlow(k));
  if (twins.length >= (expectedFlowPeers.get(parent) ?? 1)) flowClashes.push(`${parent.name}/${n.name}`);
}

/** The definition a layer's `visible` is bound to, on the layer's owner (the
 *  set for a variant, the component otherwise). */
function boundVisibleDef(n: N): { type: string; defaultValue: unknown } | null {
  const refs = n.componentPropertyReferences as Record<string, string> | undefined;
  if (!refs || refs.visible === undefined) return null;
  let at: N | null = n.parent;
  while (at !== null && at.type !== 'COMPONENT') at = at.parent;
  if (at === null) return null;
  const owner = at.parent !== null && at.parent.type === 'COMPONENT_SET' ? at.parent : at;
  const defs = owner.componentPropertyDefinitions as Record<string, { type: string; defaultValue: unknown }> | undefined;
  return defs?.[refs.visible] ?? null;
}

function detach(child: N): void {
  if (child.parent) {
    const at = child.parent.children.indexOf(child);
    if (at >= 0) child.parent.children.splice(at, 1);
  }
  child.parent = null;
}

function parseVariant(name: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const part of name.split(',')) {
    const [k, v] = part.split('=').map((s) => s.trim());
    if (k && v !== undefined) out[k] = v;
  }
  return out;
}

/**
 * An instance whose layers MIRROR its main: a layer is the main node at the
 * same path, read live, with the instance's override for that main node's id
 * on top. A main node that is gone takes its override with it — the measured
 * behaviour the module exists for.
 */
function instanceOf(main: N): N {
  const inst = make('INSTANCE');
  inst.name = main.name;
  inst.overridesById = new Map<string, Record<string, unknown>>();
  inst.getMainComponentAsync = () => Promise.resolve(main);
  return inst;
}

/**
 * What `instance` renders for the layer `path` names. The override key is the
 * chain of main-node ids down to it — the id of the main's own layer, then the
 * id inside a nested instance's main — as Figma's `I<instance>;<id>;<id>`.
 */
function rendered(instance: N, path: string[]): Record<string, unknown> | null {
  const main: N = mainOf(instance);
  let at: N | null = null;
  const ids: string[] = [];
  for (let i = 0; i < path.length; i++) {
    const from: N = at === null ? main : at.type === 'INSTANCE' ? mainOf(at) : at;
    at = from.children.find((c) => c.name === path[i] && c.visible !== false) ?? null;
    if (at === null) return null;
    ids.push(at.id);
  }
  if (at === null) return null;
  const key = ids.join(';');
  const overrides = (instance.overridesById as Map<string, Record<string, unknown>>).get(key) ?? {};
  return { id: key, fills: overrides.fills ?? at.fills, width: at.width };
}

const mainByInstance = new WeakMap<N, N>();
function mainOf(instance: N): N {
  return mainByInstance.get(instance)!;
}

function makeInstance(main: N): N {
  const inst = instanceOf(main);
  mainByInstance.set(inst, main);
  // Its layers are copies of the main's at creation — enough for the reconcile
  // to read the shape of a composed instance inside a main.
  const copy = (src: N): N => {
    const c = make(src.type);
    c.name = src.name;
    c.fills = src.fills;
    for (const k of src.children) (c.appendChild as (x: N) => void)(copy(k));
    return c;
  };
  for (const k of main.children) (inst.appendChild as (x: N) => void)(copy(k));
  return inst;
}

/** A designer's override on `instance`'s layer at `path`: stored by the main node's id. */
function override(instance: N, path: string[], fills: unknown): void {
  const target = rendered(instance, path);
  if (target === null) throw new Error(`no layer at ${path.join(' › ')}`);
  (instance.overridesById as Map<string, Record<string, unknown>>).set(target.id as string, { fills });
}

const page = make('PAGE');
const fakeFigma = {
  mixed,
  currentPage: page,
  createComponent: () => {
    const c = make('COMPONENT');
    (page.appendChild as (x: N) => void)(c);
    return c;
  },
  createFrame: () => make('FRAME'),
  createRectangle: () => make('RECTANGLE'),
  createEllipse: () => make('ELLIPSE'),
  combineAsVariants(kids: N[], parent: N): N {
    const set = make('COMPONENT_SET');
    (parent.appendChild as (c: N) => void)(set);
    for (const k of kids) (set.appendChild as (c: N) => void)(k);
    return set;
  },
  loadFontAsync: () => Promise.resolve(),
  variables: {
    getVariableByIdAsync: () => Promise.resolve(null),
    getVariableCollectionByIdAsync: () => Promise.resolve(null),
  },
};
(globalThis as unknown as { figma: unknown }).figma = fakeFigma;

// A read-through consumer for migration tests. Frame reparenting retains a
// text's main-node ID; component property writes drive every reference to the
// key. This models API semantics only, not Figma's native renderer/UI.
function migrationConsumer(main: N, direct: Map<string, string>, inherited = new Map<string, string>(), paints = new Map<string, unknown>()) {
  const inst = instanceOf(main), values: Record<string, string> = {}, writes: Record<string, string>[] = [];
  const mirror = (src: N, parent: N): N => {
    const n = { ...src, id: `I${inst.id};${src.id}`, parent } as N;
    Object.defineProperty(n, 'children', { get: () => src.children.filter(c => !c.removed).map(c => mirror(c, n)) });
    Object.defineProperty(n, 'characters', { get: () => {
      const key = (src.componentPropertyReferences as Record<string, string> | undefined)?.characters;
      const defs = main.componentPropertyDefinitions as Record<string, { defaultValue: string }>;
      return key ? values[key] ?? defs[key]?.defaultValue : direct.get(src.id) ?? inherited.get(src.id) ?? src.characters;
    }});
    if (paints.has(src.id)) n.fills = paints.get(src.id);
    return n;
  };
  Object.defineProperty(inst, 'children', { get: () => main.children.filter(c => !c.removed).map(c => mirror(c, inst)) });
  Object.defineProperty(inst, 'componentProperties', { get: () => Object.fromEntries(
    Object.entries(main.componentPropertyDefinitions as Record<string, { type: string; defaultValue: string }>).map(([key, d]) => [key, { type: d.type, value: values[key] ?? d.defaultValue }])) });
  Object.defineProperty(inst, 'overrides', { get: () => [...direct.keys()].map(id => ({ id: `I${inst.id};${id}`, overriddenFields: ['characters'] })) });
  inst.setProperties = (patch: Record<string, string>) => { writes.push({ ...patch }); Object.assign(values, patch); };
  (page.appendChild as (n: N) => void)(inst);
  return { node: inst, writes, values };
}

function countdownLegacy() {
  const ownPage = make('PAGE');
  setRedrawKeepsNodes(true);
  const main = mint(ownPage as unknown as PageNode, 'Countdown') as unknown as N;
  expectedFlowPeers.set(main, 4);
  main.componentPropertyDefinitions = {};
  const numbers = ['12', '08', '30', '15'];
  const rows = numbers.map((value, i) => {
    const block = make('FRAME'), digit = make('TEXT'), caption = make('TEXT');
    block.name = 'block'; digit.name = value; digit.characters = value; caption.name = `caption-${i}`; caption.characters = ['일', '시간', '분', '초'][i];
    for (const t of [digit, caption]) { t.fontName = { family: 'Pretendard', style: t === digit ? 'Bold' : 'Regular' }; t.textStyleId = t === digit ? 'numeral-style' : 'caption-style'; t.boundVariables = { fontSize: { id: 'original-font-variable' } }; }
    (main.appendChild as (n: N) => void)(block); (block.appendChild as (n: N) => void)(digit); (block.appendChild as (n: N) => void)(caption);
    return { block, digit, caption };
  });
  const edited = migrationConsumer(main, new Map([[rows[0].digit.id, '1000'], [rows[1].digit.id, '08']]), new Map(), new Map([[rows[0].caption.id, blue]]));
  const plain = migrationConsumer(main, new Map());
  const inherited = migrationConsumer(main, new Map(), new Map([[rows[2].digit.id, '500']]));
  main.getInstancesAsync = async () => [edited.node, plain.node, inherited.node];
  return { ownPage, main, rows, edited, plain, inherited, numbers };
}

async function redrawCountdown(f: ReturnType<typeof countdownLegacy>, before?: () => void) {
  const legacy = await captureLegacyCountdown(f.main as unknown as ComponentNode);
  if (legacy) beginLegacyCountdown(legacy);
  const main = mint(f.ownPage as unknown as PageNode, 'Countdown') as unknown as N;
  const names = ['Days', 'Hours', 'Minutes', 'Seconds'], keys = names.map(n => `${n}#stable`);
  const defs = main.componentPropertyDefinitions as Record<string, { type: string; defaultValue: string }>;
  keys.forEach((k, i) => { defs[k] ??= { type: 'TEXT', defaultValue: f.numbers[i] }; });
  for (let i = 0; i < 4; i++) {
    const block = make('FRAME'), visible = make('FRAME'), carrier = make('FRAME');
    block.name = 'block'; visible.name = 'visible'; carrier.name = 'intrinsic-carrier'; carrier.opacity = 0; carrier.height = 4;
    (main.appendChild as (n: N) => void)(block); (block.appendChild as (n: N) => void)(visible); (block.appendChild as (n: N) => void)(carrier);
    const label = (j: number, parent: N, caption = false) => {
      const n = make('TEXT'); n.name = caption ? `caption-${j}` : parent === visible ? `digit-${j}` : `measure-${j}`;
      n.characters = caption ? ['일', '시간', '분', '초'][j] : f.numbers[j]; n.fontName = { family: 'Pretendard', style: caption ? 'Regular' : 'Bold' };
      n.textStyleId = caption ? 'caption-style' : 'numeral-style'; n.boundVariables = { fontSize: { id: 'original-font-variable' } };
      if (!caption) n.componentPropertyReferences = { characters: keys[j] };
      (parent.appendChild as (n: N) => void)(n); return n;
    };
    const digit = label(i, visible), caption = label(i, visible, true);
    for (let j = 0; j < 4; j++) if (i !== j) label(j, carrier);
    if (legacy) retainTextInRedrawWrapper({ member: main as unknown as ComponentNode, oldParent: legacy.rows[i].block, freshParent: block as unknown as FrameNode, wrapper: visible as unknown as FrameNode,
      leaves: [{ old: legacy.rows[i].digit, fresh: digit as unknown as TextNode }, { old: legacy.rows[i].caption, fresh: caption as unknown as TextNode }] });
  }
  if (legacy) restoreLegacyCountdown(legacy, keys);
  before?.();
  await reconcileRedrawnMembers();
  return keys;
}

// ─── the builders ────────────────────────────────────────────────────────

const red = [{ type: 'SOLID', color: { r: 1, g: 0, b: 0 } }];
const blue = [{ type: 'SOLID', color: { r: 0, g: 0, b: 1 } }];
const green = [{ type: 'SOLID', color: { r: 0, g: 1, b: 0 } }];

// A leaf the main composes, standing in for `Icon`.
const leaf = make('COMPONENT');
leaf.name = 'Leaf';
const glyph = make('RECTANGLE');
glyph.name = 'glyph';
glyph.fills = red;
(leaf.appendChild as (c: N) => void)(glyph);

interface Draw {
  faceWidth: number;
  faceType?: string;
  /** Extra fields put on the face — a value on a field its type lacks models a
   *  gap in the field table (`kFieldOwners`). */
  faceExtra?: Record<string, unknown>;
}

function draw(host: N, d: Draw): { face: N; icon: N } {
  const face = make(d.faceType ?? 'RECTANGLE');
  face.name = 'face';
  face.fills = red;
  if (d.faceExtra) Object.assign(face, d.faceExtra);
  (face.resize as (w: number, h: number) => void)(d.faceWidth, 20);
  (host.appendChild as (c: N) => void)(face);
  const icon = makeInstance(leaf);
  icon.name = 'icon';
  (host.appendChild as (c: N) => void)(icon);
  return { face, icon };
}

async function redrawSingle(d: Draw): Promise<N> {
  const m = mint(page as unknown as PageNode, 'Single') as unknown as N;
  draw(m, d);
  await reconcileRedrawnMembers();
  return m;
}

// ─── checks ──────────────────────────────────────────────────────────────

let failures = 0;
function check(label: string, ok: boolean, detail = ''): void {
  if (ok) console.log(`  ok  ${label}`);
  else {
    failures += 1;
    console.error(`FAIL  ${label}${detail ? `\n      ${detail}` : ''}`);
  }
}

const fillOf = (r: Record<string, unknown> | null): string => JSON.stringify(r?.fills ?? null);

async function singleComponent(keep: boolean): Promise<{ survived: boolean; nested: boolean; landed: boolean; sameId: boolean }> {
  setRedrawKeepsNodes(keep);
  drainRedrawKeepCost();
  // A first build, then a designer's instance with two inner overrides.
  for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
  const m = await redrawSingle({ faceWidth: 40 });
  const inst = makeInstance(m);
  override(inst, ['face'], blue);
  override(inst, ['icon', 'glyph'], green);
  const faceIdBefore = rendered(inst, ['face'])!.id;
  // Generate again with one value changed.
  await redrawSingle({ faceWidth: 64 });
  const face = rendered(inst, ['face']);
  return {
    survived: fillOf(face) === JSON.stringify(blue),
    nested: fillOf(rendered(inst, ['icon', 'glyph'])) === JSON.stringify(green),
    landed: face !== null && face.width === 64,
    sameId: face !== null && face.id === faceIdBefore,
  };
}

async function main(): Promise<void> {
  console.log('single component — a redraw with a changed value');
  {
    const kept = await singleComponent(true);
    check('the override on the inner layer survives the redraw', kept.survived);
    check('the override inside the composed instance survives too', kept.nested);
    check('the new value lands on the node that stays', kept.landed);
    check('the inner node keeps its id', kept.sameId);
    const cost = drainRedrawKeepCost();
    check('the cost says both top-level children were kept', cost.kept === 2 && cost.replaced === 0, JSON.stringify(cost));
    const k = cost.split;
    check('the split counts the one member it reconciled', k !== undefined && k.members === 1 && k.memberGrowth.count === 1, JSON.stringify(k));
    check(
      'every node snapshotted is read back when every child is kept',
      k !== undefined && k.snapshotNodes > 2 && k.verifyNodes === k.snapshotNodes,
      JSON.stringify(k),
    );
    check(
      'the split never claims more than the keep time',
      k !== undefined && k.snapshotMs + k.applyMs + k.verifyMs + k.tidyMs + k.remapMs <= cost.ms,
      JSON.stringify(cost),
    );
  }

  console.log('field table — a type reads only the fields it has, and a table gap falls back to reading all');
  {
    setRedrawKeepsNodes(true);
    resetRedrawFontCache();
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    await redrawSingle({ faceWidth: 40 });
    await redrawSingle({ faceWidth: 64 });
    const plain = drainRedrawKeepCost();
    check(
      'a rectangle and an instance leave out the fields their types lack',
      plain.split !== undefined && plain.split.skippedReads > 0 && plain.split.fullReadTypes.length === 0,
      JSON.stringify(plain.split),
    );
    check('leaving them out keeps every child', plain.kept === 2 && plain.replaced === 0, JSON.stringify(plain));

    resetRedrawFontCache();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    const m = await redrawSingle({ faceWidth: 40, faceType: 'ELLIPSE', faceExtra: { layoutMode: 'HORIZONTAL' } });
    drainRedrawKeepCost();
    await redrawSingle({ faceWidth: 40, faceType: 'ELLIPSE', faceExtra: { layoutMode: 'VERTICAL' } });
    const gap = drainRedrawKeepCost();
    check(
      'an ellipse that reads a layout value is named and read in full',
      gap.split !== undefined && gap.split.fullReadTypes.indexOf('ELLIPSE') >= 0,
      JSON.stringify(gap.split),
    );
    check(
      'read in full, the changed value lands on the node that stays',
      gap.kept === 2 && (m.children[0] as N).layoutMode === 'VERTICAL',
      JSON.stringify({ gap, layoutMode: (m.children[0] as N).layoutMode }),
    );
    resetRedrawFontCache();
  }

  console.log('drawn-children record — a keep writes the settled children, the next redraw clears it first');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    const m = await redrawSingle({ faceWidth: 40 });
    const getData = m.getPluginData as (k: string) => string;
    check('a first draw keeps nothing and leaves no record', getData(kDrawnChildrenKey) === '', getData(kDrawnChildrenKey));
    await redrawSingle({ faceWidth: 64 });
    const ids = m.children.map((c) => c.id).join(',');
    check('a redraw that kept nodes records exactly the settled children', getData(kDrawnChildrenKey) === ids, `${getData(kDrawnChildrenKey)} vs ${ids}`);
    await redrawSingle({ faceWidth: 64, faceType: 'ELLIPSE' });
    const after = m.children.map((c) => c.id).join(',');
    check('the record follows the children after a partial replace', getData(kDrawnChildrenKey) === after, `${getData(kDrawnChildrenKey)} vs ${after}`);
    drainRedrawKeepCost();
  }

  console.log('clean nodes — a redraw that changes nothing leaves most of the read-back with no write after it');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    await redrawSingle({ faceWidth: 40 });
    drainRedrawKeepCost();
    await redrawSingle({ faceWidth: 40 });
    const same = drainRedrawKeepCost().split;
    await redrawSingle({ faceWidth: 64 });
    const changed = drainRedrawKeepCost().split;
    // Each kept child's own `visible` is written back first (parking hid it),
    // so its root is never clean; what it holds can be.
    check(
      'an unchanged redraw counts clean nodes, and never every node',
      same !== undefined && same.cleanNodes > 0 && same.cleanNodes < same.verifyNodes,
      JSON.stringify(same),
    );
    check(
      'a changed value is a write, so no more nodes are clean than when nothing changed',
      same !== undefined && changed !== undefined && changed.cleanNodes <= same.cleanNodes,
      `${JSON.stringify(same)} / ${JSON.stringify(changed)}`,
    );
  }

  console.log('control — keeping off is the old reset, and the double drops the override');
  {
    const off = await singleComponent(false);
    check('with keeping off the override is lost (the double models it)', !off.survived && !off.nested);
    check('with keeping off the value still lands', off.landed);
  }

  console.log('shape change — that subtree is replaced, the rest kept');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    const m = await redrawSingle({ faceWidth: 40 });
    const inst = makeInstance(m);
    override(inst, ['face'], blue);
    await redrawSingle({ faceWidth: 40, faceType: 'ELLIPSE' });
    const cost = drainRedrawKeepCost();
    check('the changed child is replaced, the unchanged one kept', cost.kept === 1 && cost.replaced === 1, JSON.stringify(cost));
    check('the replaced child is the new type', m.children[0].type === 'ELLIPSE');
    check('the override on the replaced child is gone', fillOf(rendered(inst, ['face'])) !== JSON.stringify(blue));
    check('the builder order holds', m.children.map((c) => c.name).join(',') === 'face,icon');
  }

  console.log('refused write — a value that cannot be carried replaces, never keeps a wrong picture');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    const before = await redrawSingle({ faceWidth: 40 });
    const oldFace = `${before.children[0].id}.width`;
    refuse.add(oldFace);
    let m: N;
    try {
      m = await redrawSingle({ faceWidth: 80 });
    } finally {
      refuse.delete(oldFace);
    }
    const cost = drainRedrawKeepCost();
    check('the refused child is replaced', cost.replaced === 1 && (cost.reasons['refused:resize'] ?? 0) === 1, JSON.stringify(cost));
    check('the picture is the new one', m!.children[0].width === 80);
  }

  console.log('mixed value — not one value to carry, so replaced');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Single') (c.remove as () => void)();
    await redrawSingle({ faceWidth: 40 });
    const m = mint(page as unknown as PageNode, 'Single') as unknown as N;
    const { face } = draw(m, { faceWidth: 40 });
    face.strokeAlign = mixed;
    await reconcileRedrawnMembers();
    const cost = drainRedrawKeepCost();
    check('the mixed child is replaced', (cost.reasons.mixed ?? 0) === 1, JSON.stringify(cost));
  }

  console.log('a slot whose visibility is bound — the redraw never moves its default');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    for (const c of page.children.slice()) if (c.name === 'Slots') (c.remove as () => void)();
    // Two slots on the component: `Show badge` off, `Show hint` on. Each is a
    // top-level layer bound by `visible`; `Show dot` sits inside `face`.
    const drawSlots = async (layoutMode: string): Promise<N> => {
      const m = mint(page as unknown as PageNode, 'Slots') as unknown as N;
      m.layoutMode = layoutMode;
      if (!m.componentPropertyDefinitions) {
        m.componentPropertyDefinitions = {
          'Show badge#1': { type: 'BOOLEAN', defaultValue: false },
          'Show hint#2': { type: 'BOOLEAN', defaultValue: true },
          'Show dot#3': { type: 'BOOLEAN', defaultValue: false },
        };
      }
      const { face } = draw(m, { faceWidth: 40 });
      const dot = make('ELLIPSE');
      dot.name = 'dot';
      (face.appendChild as (c: N) => void)(dot);
      dot.componentPropertyReferences = { visible: 'Show dot#3' };
      for (const [name, key] of [['badge', 'Show badge#1'], ['hint', 'Show hint#2']]) {
        const layer = make('RECTANGLE');
        layer.name = name;
        (m.appendChild as (c: N) => void)(layer);
        layer.componentPropertyReferences = { visible: key };
      }
      await reconcileRedrawnMembers();
      return m;
    };
    const defaults = (m: N): string => {
      const defs = m.componentPropertyDefinitions as Record<string, { defaultValue: unknown }>;
      return Object.keys(defs).map((k) => `${k.split('#')[0]}=${String(defs[k].defaultValue)}`).join(', ');
    };
    // Under auto-layout the bound layers are set aside by an absolute pin and
    // transparency; under a member that lays out nothing by transparency alone.
    // Both are kept, and neither path may touch a default.
    for (const [mode, keptWant, boundReplaced] of [
      ['HORIZONTAL', 4, 0],
      ['NONE', 4, 0],
    ] as const) {
      const first = await drawSlots(mode);
      const before = defaults(first);
      drainRedrawKeepCost();
      const again = await drawSlots(mode);
      const after = defaults(again);
      check(`${mode}: every slot default is what it was before the redraw`, after === before, `${before} → ${after}`);
      check(`${mode}: the slot that is off stays off`, /Show badge=false/.test(after));
      check(`${mode}: the slot that is on stays on`, /Show hint=true/.test(after));
      const cost = drainRedrawKeepCost();
      check(
        `${mode}: ${keptWant} kept, ${boundReplaced} bound layer(s) replaced`,
        cost.kept === keptWant && (cost.reasons['bound-visible'] ?? 0) === boundReplaced && cost.replaced === boundReplaced,
        JSON.stringify(cost),
      );
      const shown = again.children.map((c) => `${c.name}:${String(c.opacity)}/${String(c.layoutPositioning)}`).join(' ');
      check(`${mode}: every kept layer is opaque and back in the flow`, !/:0\//.test(shown) && !/ABSOLUTE/.test(shown), shown);
    }
  }

  console.log('a pending set — references and after-bind work land on the node that stays');
  {
    setRedrawKeepsNodes(true);
    drainRedrawKeepCost();
    const names = ['Kind=a', 'Kind=b'];
    const build = async (width: number): Promise<{ set: N; settled: N[] }> => {
      const mount = mountSet(page as unknown as PageNode, 'Pair', names);
      const faces: N[] = [];
      for (const name of names) {
        const comp = mount.getOrCreate(name) as unknown as N;
        faces.push(draw(comp, { faceWidth: width }).face);
      }
      const set = mount.finish() as unknown as N;
      // The set's properties exist by now; the binds are noted, not written.
      const settled: N[] = [];
      for (const face of faces) {
        // A swap binding: a `visible` one would keep the layer from being parked
        // (see the bound-slot case above).
        recordPropRef(face as unknown as SceneNode, 'mainComponent', 'Face#1:0');
        afterNodeBindLands(face as unknown as SceneNode, (n) => settled.push(n as unknown as N));
      }
      await reconcileRedrawnMembers();
      completePendingMounts();
      return { set, settled };
    };
    const first = await build(40);
    const memberA = first.set.children.find((c) => c.name === 'Kind=a')!;
    const inst = makeInstance(memberA);
    override(inst, ['face'], blue);
    const faceBefore = rendered(inst, ['face'])!.id;
    const again = await build(72);
    const face = rendered(inst, ['face']);
    check('the override inside a set member survives', fillOf(face) === JSON.stringify(blue));
    check('the new value lands', face !== null && face.width === 72);
    check('the node is the same', face !== null && face.id === faceBefore);
    const keptFace = memberA.children.find((c) => c.name === 'face')!;
    const refs = keptFace.componentPropertyReferences as Record<string, string> | undefined;
    check('the noted reference is written on the kept node', refs?.mainComponent === 'Face#1:0', JSON.stringify(refs));
    check(
      'the after-bind work ran on the kept nodes',
      again.settled.length === 2 && again.settled.every((n) => !n.removed && n.parent !== null),
      again.settled.map((n) => `${n.id}${n.removed ? ' (removed)' : ''}`).join(', '),
    );
  }

  console.log('a recycled member — how it sat in its set is not carried into the redraw');
  {
    setRedrawKeepsNodes(true);
    const names = ['Kind=a', 'Kind=b'];
    const build = async (): Promise<N> => {
      const mount = mountSet(page as unknown as PageNode, 'Row', names);
      for (const name of names) draw(mount.getOrCreate(name) as unknown as N, { faceWidth: 40 });
      const set = mount.finish() as unknown as N;
      await reconcileRedrawnMembers();
      completePendingMounts();
      return set;
    };
    const first = await build();
    const stale = first.children.find((c) => c.name === 'Kind=a')!;
    // What an earlier generation left on it: a member that grows in a row the
    // set hugs is squeezed to nothing.
    stale.layoutGrow = 1;
    stale.layoutAlign = 'STRETCH';
    const again = await build();
    const member = again.children.find((c) => c.name === 'Kind=a')!;
    check('the member is the same node', member.id === stale.id);
    check('its grow is cleared', member.layoutGrow === 0, String(member.layoutGrow));
    check('its stretch is cleared', member.layoutAlign === 'INHERIT', String(member.layoutAlign));
  }

  console.log('Countdown: direct-text legacy shape → approved property-linked wrappers');
  {
    const f = countdownLegacy(), ids = f.rows.flatMap(r => [r.block.id, r.digit.id, r.caption.id]);
    const keys = await redrawCountdown(f);
    check('component ID and all four blocks/eight text IDs survive wrapping', f.main.children.flatMap(b => [b.id, ...b.children[0].children.map(n => n.id)]).join() === ids.join());
    check('same-as-default direct override stays explicit; other values remain inherited', JSON.stringify(f.edited.writes) === JSON.stringify([{ [keys[0]]: '1000', [keys[1]]: '08' }]) && f.plain.writes.length === 0);
    check('differing inherited value is captured without relying on direct override list', f.inherited.values[keys[2]] === '500');
    check('all four references read migrated consumer1000', f.edited.node.children.flatMap(b => b.children.flatMap(c => c.children)).filter(n => (n.componentPropertyReferences as Record<string, string> | undefined)?.characters === keys[0]).every(n => n.characters === '1000'));
    check('caption paint override and old numeral style/binding remain', f.edited.node.children[0].children[0].children[1].fills === blue && f.rows[0].digit.textStyleId === 'numeral-style' && (f.rows[0].digit.boundVariables as Record<string, { id: string }>).fontSize.id === 'original-font-variable');
    await redrawCountdown(f);
    check('second redraw retains migrated node IDs and does not repeat override migration', f.main.children.flatMap(b => [b.id, ...b.children[0].children.map(n => n.id)]).join() === ids.join() && f.edited.writes.length === 1);
    const defs = f.main.componentPropertyDefinitions as Record<string, { defaultValue: string }>;
    defs[keys[0]].defaultValue = '99'; defs[keys[1]].defaultValue = '99';
    const edited = f.edited.node.componentProperties as Record<string, { value: string }>, plain = f.plain.node.componentProperties as Record<string, { value: string }>;
    check('later main defaults preserve migrated overrides while plain consumer inherits', edited[keys[0]].value === '1000' && edited[keys[1]].value === '08' && plain[keys[0]].value === '99' && plain[keys[1]].value === '99');
  }
  {
    const f = countdownLegacy(); refuse.add(`${f.rows[0].digit.id}.characters`);
    // Force a real main default change so apply must write the refused field.
    f.numbers[0] = '99'; let stopped = false;
    try { await redrawCountdown(f); } catch { stopped = true; }
    refuse.delete(`${f.rows[0].digit.id}.characters`);
    check('refused migration aborts; original blocks/texts are not deleted', stopped && f.rows.every(r => !r.block.removed && !r.digit.removed && !r.caption.removed));
    abandonRedrawParking();
    let refusedRetry = false;
    try { await captureLegacyCountdown(f.main as unknown as ComponentNode); } catch { refusedRetry = true; }
    check('interrupted migration retains saved values and refuses blind retry', refusedRetry && String((f.main.getPluginData as (key: string) => string)('coui-countdown-text-migration')).includes('1000'));
  }
  {
    const f = countdownLegacy(); let stopped = false;
    try { await redrawCountdown(f, () => (f.rows[0].block.appendChild as (n: N) => void)(make('TEXT'))); } catch { stopped = true; }
    check('unexpected child after registration refuses migration without deleting original text', stopped && f.rows.every(r => !r.digit.removed && !r.caption.removed));
    abandonRedrawParking();
  }

  {
    const f = countdownLegacy(); let stopped = false;
    f.main.getInstancesAsync = async () => { throw new Error('unreadable consumer'); };
    try { await captureLegacyCountdown(f.main as unknown as ComponentNode); } catch { stopped = true; }
    check('unreadable consumer capture stops before reset/property creation', stopped && Object.keys(f.main.componentPropertyDefinitions as object).length === 0 && f.rows.every(r => r.digit.parent === r.block));
  }

  {
    const f = countdownLegacy(); f.edited.node.setProperties = () => undefined;
    let stopped = false;
    try { await redrawCountdown(f); } catch { stopped = true; }
    check('a no-op consumer property setter fails readback and retains recovery data', stopped && String((f.main.getPluginData as (key: string) => string)('coui-countdown-text-migration')).includes('1000') && f.rows.every(r => !r.digit.removed));
    abandonRedrawParking();
  }

  console.log('flow — an old node is never written while its new twin is still laid out beside it');
  check(
    'no write found the old node and its new twin in the flow together',
    flowClashes.length === 0,
    [...new Set(flowClashes)].join(', '),
  );

  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log('\nall redraw-keep checks passed');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
