// Drives `verifyFidelity` against the real builders and a document double, and
// proves it FAILS on an injected regression before trusting it to pass.
//
// A check nobody has seen fail is not a check. This project's own history is
// the argument: three separate guards reported green while the defect they
// existed to catch was live, and each time the reason was that the path was
// never taken. So this harness does three things in order — build the page,
// assert a clean readback, then break one value on the canvas and assert the
// readback reports exactly that.
//
// The document double here is deliberately thinner than
// `selftest-registry-runtime`'s: fidelity reads finished nodes, so it needs
// geometry and effects to be REAL (whatever the builders wrote), not validated.
// The two harnesses check different halves — that one asks whether a builder
// may call an API, this one asks whether the result says the right thing.
import { REGISTRY, topoSortRegistry } from '../src/registry';
import { scopeToFragment, verifyFidelity } from '../src/fidelity';
import { findComponentByName, installNodeIndex, kMarkBarName } from '../src/helpers';
import { ICON_KEYS, installGlyphIndex } from '../src/helpers';
import { completePendingMounts, flushTintLayers } from '../src/helpers';
import { applyLetterSpacing } from '../src/text-nodes';
import { CHECKBOX, COMPONENTS } from '../src/data';

type Node = Record<string, any>;

// Stand-in for `figma.mixed`, the sentinel a corner-radius read returns when
// the four corners disagree.
const kMixed = Symbol('figma.mixed');

// Which axis mode governs a given direction, per Figma: the PRIMARY mode
// governs the direction the layout flows in, the COUNTER mode the other one.
// A frame without auto-layout has no modes at all and is FIXED in both.
function axisSizing(node: Node, axis: 'HORIZONTAL' | 'VERTICAL'): string {
  if (node.layoutMode === 'NONE') return 'FIXED';
  const primary = node.layoutMode === axis;
  const mode = primary ? node.primaryAxisSizingMode : node.counterAxisSizingMode;
  return mode === 'AUTO' ? 'HUG' : 'FIXED';
}

// The write direction of the same relation: `layoutSizingHorizontal = 'HUG'`
// sets the governing mode to AUTO. FILL is left as the explicit override the
// getter prefers — it is a statement about the PARENT's layout, not this
// node's own sizing mode.
function applyAxisSizing(node: Node, axis: 'HORIZONTAL' | 'VERTICAL', v: string) {
  if (node.layoutMode === 'NONE' || v === 'FILL') return;
  const primary = node.layoutMode === axis;
  const mode = v === 'HUG' ? 'AUTO' : 'FIXED';
  if (primary) node.primaryAxisSizingMode = mode;
  else node.counterAxisSizingMode = mode;
}

// Reading a property the double does not model is an ERROR, not `undefined`.
//
// Four of this harness's ten misses of the real API were the same shape: a check
// read a property the double had no key for, `undefined` compared equal to
// everything, and 143 components passed while the real file disagreed. Guessing
// which properties to add next is what produced ten of them; refusing the read
// ends the class.
//
// Only during the readback — the builders legitimately probe for optional
// members while constructing.
let strictReads = false;

const wrap = (node: Node): Node =>
  new Proxy(node, {
    get(target, key) {
      if (
        strictReads &&
        typeof key === 'string' &&
        !(key in target) &&
        key !== 'then' &&
        !key.startsWith('__')
      ) {
        throw new Error(
          `double does not model \`${key}\` (read on a ${String(target.type)}). ` +
            'Add it with Figma\'s own default — an unmodelled property reads as ' +
            'undefined and every comparison against undefined passes.',
        );
      }
      return (target as Record<string | symbol, unknown>)[key];
    },
  });

// Every node at or under `root` that could carry an inset — the padding check
// searches the subtree, so an injection has to reach the same nodes.
const membersOfSet = (root: Node): Node[] => {
  const out: Node[] = [];
  const walk = (n: Node) => {
    if (typeof n.paddingLeft === 'number') out.push(n);
    for (const k of n.children ?? []) walk(k);
  };
  walk(root);
  return out;
};

let seq = 0;
const mk = (type: string, name = ''): Node => {
  seq += 1;
  const node: Node = {
    type,
    id: `${type}:${seq}`,
    name,
    children: [] as Node[],
    parent: null as Node | null,
    width: 0,
    height: 0,
    fills: [],
    strokes: [],
    effects: [],
    layoutMode: 'NONE',
    // Figma's own defaults for the properties the absence check reads. A
    // property the double omits reads back `undefined`, and every comparison
    // against `undefined` passes — so leaving these out would make the check
    // *look* like it ran on 143 components while asserting nothing. That is the
    // failure this harness exists to catch, and it has caught it six times on
    // other properties.
    strokeWeight: 1,
    itemSpacing: 0,
    // Figma's own default for an unset corner. Its absence is why the radius
    // check skipped 15 components here and reported all 15 from the real file:
    // `typeof undefined !== 'number'` is a skip, `0 !== 4` is a miss.
    topLeftRadius: 0,
    topRightRadius: 0,
    bottomLeftRadius: 0,
    bottomRightRadius: 0,
    isExposedInstance: false,
    // A fresh Figma TEXT node is 12px. Left undefined, a text node the builder
    // never sized would be skipped here and counted there.
    fontSize: type === 'TEXT' ? 12 : undefined,
    // Figma's own defaults for a fresh TEXT: no tracking (`0%`), no text style.
    // Both read by the letter-spacing check; left unmodelled they would throw
    // on the first label — or, had the double stayed permissive, read as
    // `undefined` and compare equal to everything.
    letterSpacing: type === 'TEXT' ? { unit: 'PERCENT', value: 0 } : undefined,
    textStyleId: type === 'TEXT' ? '' : undefined,
    // `node.boundVariables[field]` — what `setBoundVariable` leaves behind on
    // the real API. Modelled so a check can ask whether a value is bound at
    // all, which is a different question from what the value is.
    boundVariables: {} as Record<string, unknown>,
    // Every node starts visible, and a fresh TEXT starts empty. Both matter to
    // the stacked-text check, which asks how many strings a field actually
    // shows: `undefined` for `visible` would read as hidden and count nothing.
    visible: true,
    characters: type === 'TEXT' ? '' : undefined,
    // Range writes the builder makes when a monospace label holds Hangul — it
    // paints those runs in the text face (`paintHangulRunsSans`). The checks
    // here read node-level fields only, so the double takes the writes and
    // keeps nothing; absent, any Hangul in a code label threw and the whole
    // component read as "did not build".
    setRangeFontName(_start: number, _end: number, _font: unknown) {},
    setRangeBoundVariable(_start: number, _end: number, _field: string, _variable: unknown) {},
    getStyledTextSegments(_fields: string[], start: number, end: number) {
      return [{ start, end, fontName: (self as Node).fontName ?? { family: 'Geist Mono', style: 'Regular' } }];
    },
    // The map that makes a BOOLEAN property mean something. Unset by default,
    // like Figma's.
    componentPropertyReferences: undefined as Record<string, string> | undefined,
    paddingLeft: 0,
    paddingRight: 0,
    paddingTop: 0,
    paddingBottom: 0,
    minWidth: null as number | null,
    maxWidth: null as number | null,
    minHeight: null as number | null,
    maxHeight: null as number | null,
    primaryAxisSizingMode: 'AUTO',
    counterAxisSizingMode: 'AUTO',
    // Figma's own default. Modelled because the readback multiplies it into a
    // fill's alpha: below alpha 1 a TOKEN fill keeps its paint at full strength
    // (a bound colour overwrites the paint's alpha) and the alpha lives here.
    opacity: 1,
    pluginData: {} as Record<string, string>,
    // Real reparenting: one parent per node, so appending somewhere new
    // detaches from wherever the child was. And the parent a child records is
    // the SAME object `mk` hands out — the wrapper below — because the builders
    // compare it (`comp.parent === set`), and a raw object behind a proxy is a
    // different object to `===`.
    appendChild(child: Node) {
      const prev = child.parent as Node | null;
      if (prev && prev !== self) {
        const was = prev.children.indexOf(child);
        if (was >= 0) prev.children.splice(was, 1);
      }
      const at = node.children.indexOf(child);
      if (at >= 0) node.children.splice(at, 1);
      node.children.push(child);
      child.parent = self;
      if (node.type === 'COMPONENT_SET' && child.type === 'COMPONENT') {
        child.variantProperties = Object.fromEntries(
          child.name.split(',').map((p: string) => {
            const [k, v] = p.split('=');
            return [k.trim(), (v ?? '').trim()];
          }),
        );
      }
    },
    // The same reparenting at an index — a tint layer goes in at 0, behind
    // whatever the builder appends next. Absent, `tintLayer` threw and this
    // readback reported the writes that never ran (a missing radius, a missing
    // shadow) instead of the missing function: 13 disagreements, none of them the
    // actual fault.
    insertChild(index: number, child: Node) {
      const prev = child.parent as Node | null;
      if (prev && prev !== self) {
        const was = prev.children.indexOf(child);
        if (was >= 0) prev.children.splice(was, 1);
      }
      const at = node.children.indexOf(child);
      if (at >= 0) node.children.splice(at, 1);
      node.children.splice(index, 0, child);
      child.parent = self;
    },
    resize(w: number, h: number) {
      node.width = w;
      node.height = h;
    },
    // The axis grid sizes a set with this once its members sit at absolute
    // positions: the box changes, the children stay. Same write on the double.
    resizeWithoutConstraints(w: number, h: number) {
      node.width = w;
      node.height = h;
    },
    // Not a no-op. `rescale` scales the box AND the stroke; `resize` scales
    // only the box. The icon path depends on exactly that difference, and a
    // no-op double cannot tell a correct call from the defect it replaced.
    // An instance swap (`forwardChipCloseBox` points a composed chip's close
    // glyph at another `Icon` step): the node takes the new main and its box.
    swapComponent(target: Node) {
      node.mainComponent = target;
      node.width = target.width;
      node.height = target.height;
    },
    rescale(factor: number) {
      node.width *= factor;
      node.height *= factor;
      if (typeof node.strokeWeight === 'number') {
        node.strokeWeight = (node.strokeWeight as number) * factor;
      }
      for (const kid of node.children as Node[]) {
        if (typeof kid.rescale === 'function') kid.rescale(factor);
      }
    },
    remove() {
      if (node.parent) {
        const at = node.parent.children.indexOf(node);
        if (at >= 0) node.parent.children.splice(at, 1);
      }
    },
    // Figma resolves the binding immediately: the property reads back the
    // variable's value. Modelled because the numbers this harness compares
    // arrive this way, not by assignment.
    setBoundVariable(prop: string, v: unknown) {
      const value = (v as { value?: unknown } | null)?.value;
      // Letter spacing is a `{unit, value}` pair, and a number variable bound to
      // it reads back in PIXELS (measured: a label bound to
      // `letter-spacing/title-small` read `{PIXELS, -0.16}`). Stored as a bare
      // number, every bound tracking read as "unset" here — the label had a
      // tracking, and the double made it vanish.
      if (typeof value === 'number') {
        node[prop] = prop === 'letterSpacing' ? { unit: 'PIXELS', value } : value;
      }
      // The alias the real API records, in the shape it records it: a TEXT
      // node's text fields are bound per character range, so Figma exposes
      // them as an ARRAY of aliases; every other field is a single alias.
      const id = (v as { id?: string } | null)?.id;
      if (id == null) return;
      const alias = { type: 'VARIABLE_ALIAS', id };
      node.boundVariables = {
        ...(node.boundVariables as Record<string, unknown>),
        [prop]: node.type === 'TEXT' ? [alias] : alias,
      };
    },
    setPluginData(k: string, v: string) {
      node.pluginData[k] = v;
    },
    getPluginData(k: string) {
      return node.pluginData[k] ?? '';
    },
    // Figma fans a `cornerRadius` write out to all four corners and reports the
    // shared number back (or `mixed` when they differ). Both spellings are in
    // use — `helpers.ts` writes the shorthand, one builder writes a corner — so
    // a double that stored them as unrelated keys would let a check read 0 from
    // one while the other held 8.
    set cornerRadius(v: number) {
      node.topLeftRadius = v;
      node.topRightRadius = v;
      node.bottomLeftRadius = v;
      node.bottomRightRadius = v;
    },
    get cornerRadius(): number | symbol {
      const corners = [
        node.topLeftRadius ?? 0,
        node.topRightRadius ?? 0,
        node.bottomLeftRadius ?? 0,
        node.bottomRightRadius ?? 0,
      ];
      return corners.every((c) => c === corners[0]) ? corners[0] : kMixed;
    },
    // Derived exactly as Figma derives it, because the builders set the axis
    // MODES (`primaryAxisSizingMode = 'AUTO'`) and the check reads the SIZING
    // (`layoutSizingHorizontal`). Storing the two independently is what would
    // make a hugging Button read as FIXED and turn a real check into 143 false
    // positives — which is the other way a check stops being read.
    get layoutSizingHorizontal(): string {
      return node.explicitSizingH ?? axisSizing(node, 'HORIZONTAL');
    },
    set layoutSizingHorizontal(v: string) {
      node.explicitSizingH = v;
      applyAxisSizing(node, 'HORIZONTAL', v);
    },
    get layoutSizingVertical(): string {
      return node.explicitSizingV ?? axisSizing(node, 'VERTICAL');
    },
    set layoutSizingVertical(v: string) {
      node.explicitSizingV = v;
      applyAxisSizing(node, 'VERTICAL', v);
    },
    // Figma refuses to READ definitions off a variant, with this exact message:
    //
    //   in get_componentPropertyDefinitions: Can only get component property
    //   definitions of a component set or non-variant component
    //
    // Stored as a plain field, the double answered `undefined` instead, and a
    // check that scanned every member for misplaced definitions passed 143
    // components here and died on the first component set in Figma. Modelled as
    // an accessor so the refusal is the double's behaviour too.
    get componentPropertyDefinitions(): Record<string, unknown> | undefined {
      if (node.type === 'COMPONENT' && node.parent?.type === 'COMPONENT_SET') {
        throw new Error(
          'in get_componentPropertyDefinitions: Can only get component ' +
            'property definitions of a component set or non-variant component',
        );
      }
      return node.propertyDefs;
    },
    set componentPropertyDefinitions(v: Record<string, unknown> | undefined) {
      node.propertyDefs = v;
    },
    addComponentProperty(pname: string, ptype: string, dflt: unknown) {
      const defs = (node.propertyDefs ?? {}) as Record<string, unknown>;
      const id = `${pname}#${Object.keys(defs).length}:0`;
      defs[id] = { type: ptype, defaultValue: dflt };
      node.propertyDefs = defs;
      return id;
    },
    deleteComponentProperty(id: string) {
      delete (node.propertyDefs as Record<string, unknown>)[id];
    },
    createInstance() {
      const inst = mk('INSTANCE', node.name);
      inst.mainComponent = node;
      const owner =
        node.parent && node.parent.type === 'COMPONENT_SET' ? node.parent : node;
      const defs = (owner.propertyDefs ?? {}) as Record<string, any>;
      const props: Record<string, any> = {};
      for (const k of Object.keys(defs)) props[k] = { type: defs[k].type, value: defs[k].defaultValue };
      inst.componentProperties = props;
      // Bookkeeping AND the effect the bookkeeping has, because in Figma a
      // BOOLEAN property is not a note — the layers whose
      // `componentPropertyReferences.visible` name it appear and disappear with
      // it. A double that only records the value cannot see a builder that
      // reveals a slot, which is how the stacked-text injection reported nothing
      // while the same state was on the real canvas: the value holder starts
      // hidden, `setProperties({Value: true})` is what shows it, and here that
      // call changed nothing.
      inst.setProperties = (patch: Record<string, unknown>) => {
        for (const k of Object.keys(patch)) {
          if (!(k in props)) throw new Error(`setProperties: no such property ${k}`);
          props[k].value = patch[k];
          if (typeof patch[k] !== 'boolean') continue;
          const apply = (n: Node) => {
            const ref = n.componentPropertyReferences;
            if (ref && ref.visible === k) n.visible = patch[k] as boolean;
            for (const kid of n.children ?? []) apply(kid);
          };
          apply(inst);
        }
      };
      for (const kid of node.children) inst.appendChild(clone(kid));
      return inst;
    },
    findAll(pred: (n: Node) => boolean) {
      const out: Node[] = [];
      const walk = (n: Node) => {
        for (const c of n.children) {
          if (pred(c)) out.push(c);
          walk(c);
        }
      };
      walk(node);
      return out;
    },
    findOne(pred: (n: Node) => boolean) {
      return node.findAll(pred)[0] ?? null;
    },
  };
  const self = wrap(node);
  return self;
};

const clone = (src: Node): Node => {
  const copy = mk(src.type === 'COMPONENT' ? 'INSTANCE' : src.type, src.name);
  // `visible` among them, and its absence is the same class of bug this whole
  // file exists to prevent — one level up. A real instance carries its
  // component's hidden layers, so a slot whose BOOLEAN property defaults off
  // arrives hidden. Dropping it here made every composed field look like it drew
  // its placeholder AND its value: 20 reports, none of them real, on the one
  // check written to find exactly that state. A double that omits a property
  // does not only miss defects — it invents them.
  for (const k of ['width', 'height', 'layoutMode', 'fontSize', 'characters', 'topLeftRadius',
                   'paddingLeft', 'paddingTop', 'paddingRight', 'paddingBottom', 'visible',
                   'componentPropertyReferences', 'letterSpacing', 'textStyleId']) {
    if (src[k] !== undefined) copy[k] = src[k];
  }
  // An instance's layers keep their main's bindings — a label inside a
  // composed child is bound exactly as the child's own label is.
  copy.boundVariables = { ...((src.boundVariables as Record<string, unknown>) ?? {}) };
  copy.effects = Array.isArray(src.effects) ? [...src.effects] : [];
  copy.fills = Array.isArray(src.fills) ? [...src.fills] : [];
  copy.strokes = Array.isArray(src.strokes) ? [...src.strokes] : [];
  copy.strokeWeight = typeof src.strokeWeight === 'number' ? src.strokeWeight : 1;
  for (const kid of src.children) copy.appendChild(clone(kid));
  // A nested INSTANCE keeps its own property panel inside the copy — that is
  // what a nested override IS, and it is how a slot's Icon is pointed at a
  // different glyph. Without it, reaching one level down found a node that
  // looked like an instance and threw on `setProperties`.
  const srcProps = src.componentProperties as Record<string, any> | undefined;
  if (srcProps) {
    const own: Record<string, any> = {};
    for (const k of Object.keys(srcProps)) own[k] = { type: srcProps[k].type, value: srcProps[k].value };
    copy.componentProperties = own;
    copy.setProperties = (patch: Record<string, unknown>) => {
      for (const k of Object.keys(patch)) {
        if (!(k in own)) throw new Error(`setProperties: no such property ${k}`);
        own[k].value = patch[k];
      }
    };
  }
  return copy;
};

// One page per component, like production (#4023) — not the single page this
// harness used to build onto.
//
// The topology is the point. With everything on one page, a page-local child
// lookup finds every child and the harness stays green; in production the child
// is on its own `❖ {Name}` page and the same lookup finds nothing. That gap is
// exactly what shipped: `verifyFidelity` looked for one `🧩 Components` page,
// found none on a real document, and reported "Nothing was checked" — while this
// harness reported 143 components read.
const root = mk('DOCUMENT');
const newPage = (name: string) => {
  const p = mk('PAGE', name);
  p.loadAsync = async () => {};
  root.appendChild(p);
  return p;
};
// Where nodes land before a build claims a page — and what the fallback path in
// `findComponentByName` gets handed.
let page = newPage('❖ (scratch)');

// Variables answer with their REAL Figma name, and a distinct id each.
//
// One shared `{id: 'var', name: 'v'}` was enough while nothing read a variable
// back. The colour-alpha check reads one: it resolves a paint's bound id to a
// name and only judges names under `Semantic/color/`, so a double that answered
// `'v'` for every accessor would make the new check skip all 143 components while
// reporting a count as if it had compared them. That exact shape — a check that
// runs and asserts nothing because the double omits what it reads — is what this
// harness exists to catch, and it has now caught it on eight properties.
const varsById = new Map<string, { id: string; name: string; valuesByMode?: Record<string, unknown> }>();
const namedVar = (name: string): { id: string; name: string; valuesByMode?: Record<string, unknown> } => {
  const existing = [...varsById.values()].find((v) => v.name === name);
  if (existing) return existing;
  const made = { id: `var:${varsById.size}`, name };
  varsById.set(made.id, made);
  return made;
};
const lkVar = { id: 'var', name: 'v' };
(globalThis as any).figma = {
  root,
  get currentPage() { return page; },
  createComponent: () => { const n = mk('COMPONENT'); page.appendChild(n); return n; },
  createFrame: () => mk('FRAME'),
  createText: () => { const n = mk('TEXT'); n.fontSize = 14; n.characters = ''; return n; },
  createRectangle: () => mk('RECTANGLE'),
  createEllipse: () => mk('ELLIPSE'),
  // The MockupDevice status bar draws its glyphs from Core's path data. The
  // fidelity readback never reads a path, so a plain node carries it.
  createVector: () => mk('VECTOR'),
  createPage: () => { const n = mk('PAGE'); root.appendChild(n); return n; },
  createNodeFromSvg: () => { const f = mk('FRAME'); f.appendChild(mk('VECTOR')); return f; },
  combineAsVariants: (kids: Node[], parent: Node) => {
    const set = mk('COMPONENT_SET');
    parent.appendChild(set);
    for (const k of kids) set.appendChild(k);
    return set;
  },
  group: (kids: Node[], parent: Node) => { const g = mk('GROUP'); parent.appendChild(g); for (const k of kids) g.appendChild(k); return g; },
  variables: {
    // Attaches the alias the real API attaches. Returning the paint untouched
    // meant `boundVariables` never existed on the double, so the colour check
    // found no bound paint anywhere and passed by finding nothing.
    setBoundVariableForPaint: (
      p: Record<string, unknown>,
      field: string,
      variable: { id: string; __paintOpacity?: number },
    ) => {
      const bound = { ...((p.boundVariables as Record<string, unknown>) ?? {}) };
      bound[field] = { type: 'VARIABLE_ALIAS', id: variable.id };
      return { ...p, ...(variable.__paintOpacity == null ? {} : { opacity: variable.__paintOpacity }), boundVariables: bound };
    },
    // Refused, exactly as Figma refuses it: this plugin's manifest is
    // `documentAccess: dynamic-page`, which turns off the whole synchronous variable
    // API. Modelled as a WORKING function before, and that is how the fidelity
    // command shipped dead — every self-test green, and the real run threw on the
    // first component with a bound fill:
    //
    //   in getVariableById: Cannot call with documentAccess: dynamic-page.
    //   Use figma.variables.getVariableByIdAsync instead.
    //
    // A double that answers a question the platform refuses to be asked is worse than
    // one that has never heard of it — the first reports success.
    getVariableById: () => {
      throw new Error(
        'in getVariableById: Cannot call with documentAccess: dynamic-page. Use ' +
          'figma.variables.getVariableByIdAsync instead.',
      );
    },
    setBoundVariableForEffect: (e: unknown) => e,
    // A gradient stop rides a variable through an alias (`ColorStop.boundVariables`),
    // which is how MockupDevice's hardware ramps bind. Absent, that builder failed as
    // a missing function and left the component out of every check below.
    createVariableAlias: (variable: { id: string }) => ({ type: 'VARIABLE_ALIAS', id: variable.id }),
    getLocalVariableCollectionsAsync: async () => [],
    getVariableByIdAsync: async (id: string) => varsById.get(id) ?? null,
    // What the readback uses now — one resolution up front instead of a call per
    // paint.
    getLocalVariablesAsync: async () => [...varsById.values()],
  },
  loadFontAsync: async () => {},
  // A shadow is linked to the document's effect style when one states its layers
  // (`shadow-style.ts`). This document carries none, so every shadow stays the
  // direct value the builder wrote — which is what the shadow checks read.
  getLocalEffectStylesAsync: async () => [],
  setCurrentPageAsync: async (p: Node) => { page = p; },
  triggerUndo: () => {},
  commitUndo: () => {},
  mixed: Symbol('mixed'),
};

// The VarLookup double. Every accessor answers with a variable object CARRYING
// the value it was asked for, because binding is how most numbers reach the
// canvas: `bindInsets` does `setBoundVariable('paddingLeft', lk.space(16))`, it
// never assigns the number.
//
// A variable without a value made `setBoundVariable` a no-op, so every bound
// inset stayed at 0 on the double while the real canvas showed 16. The padding
// check could not see that, because an unset inset also read as `undefined` and
// `typeof got !== 'number'` skipped it — two omissions cancelling out into a
// green check that compared nothing on fifteen components.
const lk: any = new Proxy(
  {},
  {
    // Keyed by accessor, because the variable's NAME is what the colour check
    // reads and `VarLookup.sem('primary')` resolves to `Semantic/color/primary`
    // while `space(16)` resolves to `Primitives/space/16`. A Proxy that ignored
    // the accessor answered one name for all of them.
    get: (_t, accessor: string) => (v: unknown, opacity?: number) => {
      if (accessor === 'semWithOpacity') {
        const base = namedVar(`Semantic/color/${String(v)}`);
        const derived = namedVar(`${base.name}/opacity/${opacity! * 100}`);
        derived.valuesByMode = { light: { color: { type: 'VARIABLE_ALIAS', id: base.id }, opacity: opacity! * 100 } };
        return { ...derived, __paintOpacity: opacity };
      }
      // `letterSpacingOrNull(size, px)` binds only a step that already holds
      // `px` — the real lookup compares every mode's value against it. So the
      // step's value is the PIXELS asked about, not the size the accessor is
      // keyed by: answering the size wrote a label's tracking as `16` (or
      // `10`) and every label on the size tier read as untracked.
      if (accessor === 'letterSpacingOrNull') {
        return { ...namedVar(`Semantic/Typography/letter-spacing/size-${String(v)}`), value: opacity };
      }
      // `tryGet(collection, name)` resolves a variable by its own name, so the
      // answer is named for both arguments (the second one rides in the position
      // the other accessors use for `opacity`). It carries no value: a binding
      // made through it must never move the bound property on the double, and a
      // component variable's number is not one this harness holds.
      if (accessor === 'tryGet') {
        return namedVar(`${String(v)}/${String(opacity)}`);
      }
      const name =
        accessor === 'sem'
          ? `Semantic/color/${String(v)}`
          : accessor === 'size' || accessor === 'sizeOrNull'
            ? `Primitives/space/${String(v)}`
            : `Primitives/${accessor.replace(/OrNull$/, '')}/${String(v)}`;
      return { ...namedVar(name), value: v };
    },
  },
);

// `Icon` is designer-owned — see scripts/selftest-registry-runtime.ts for the
// same seed and the same reasoning. Its entry validates rather than builds, so
// unlike every other component it has to already exist, and the glyphs it swaps
// in come from a library file through an async import the builders cannot make.
function seedIconSet(): Node {
  const iconPage = newPage('❖ Icon');
  const set = mk('COMPONENT_SET', 'Icon');
  const swapKey = set.addComponentProperty('Icon', 'INSTANCE_SWAP', '');
  for (const step of [16, 20, 24, 32, 48]) {
    const variant = mk('COMPONENT', `Size=${step}`);
    variant.width = step;
    variant.height = step;
    const glyphSlot = mk('INSTANCE', 'icon');
    glyphSlot.width = step;
    glyphSlot.height = step;
    glyphSlot.componentPropertyReferences = { mainComponent: swapKey };
    // The glyph's geometry: a stroked VECTOR one instance down, as the real
    // library glyph has. Modelled so `Checkbox` carries real VECTORs under its ✓:
    // the mark-thickness check must NOT read them (the ✓ follows the icon stroke,
    // and only the dash is stated by `markThickness`), and the injected regression
    // below proves it by strokes that disagree with the dash. The weight here is
    // a stand-in; nothing in this harness holds the library's rule.
    const path = mk('VECTOR', 'path');
    path.width = step;
    path.height = step;
    path.strokes = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }];
    path.strokeWeight = step / 12;
    glyphSlot.appendChild(path);
    variant.appendChild(glyphSlot);
    set.appendChild(variant);
  }
  iconPage.appendChild(set);
  return set;
}

async function main() {
  const order = topoSortRegistry(REGISTRY);
  let built = 0;
  // LIVE index, as generate keeps one: each finished component is registered
  // immediately so the next entry's children resolve across pages. Without it
  // every composed component fails here — which is the production behaviour this
  // harness previously could not see.
  const nodeIndex = new Map<string, Node>();
  installNodeIndex(nodeIndex as unknown as ReadonlyMap<string, SceneNode>);
  // Registered BEFORE the loop: each entry gets a fresh page, so the only way
  // `findComponentByName` reaches a set built on another page is the index.
  nodeIndex.set('Icon', seedIconSet());
  const glyphIndex = new Map<string, unknown>();
  for (const name of Object.keys(ICON_KEYS)) {
    glyphIndex.set(name, mk('COMPONENT', `lucide/${name}`));
  }
  installGlyphIndex(glyphIndex as unknown as ReadonlyMap<string, ComponentNode>);
  for (const e of order) {
    page = newPage(`❖ ${e.name}`);
    try {
      const node = await e.build(page as any, lk);
      flushTintLayers();
      completePendingMounts();
      node.name = e.name;
      nodeIndex.set(e.name, node);
      built += 1;
    } catch (err) {
      console.log(`  (build skipped: ${e.name} — ${String(err).split('\n')[0]})`);
    }
  }
  console.log(`built ${built}/${order.length} onto the double (${root.children.length} pages)`);

  // If source metadata stops stating the relation, the builder must fail
  // instead of silently drawing circular active markers from stale assumptions.
  const relation = COMPONENTS.dot_indicator.derivedDefaults;
  const oldSource = relation.activeLength;
  relation.activeLength = 'wrongSource';
  let refused = false;
  try {
    const indicatorBuilder = REGISTRY.find((entry) => entry.name === 'DotIndicator');
    if (!indicatorBuilder) throw new Error('DotIndicator registry entry missing');
    await indicatorBuilder.build(newPage('derived-default guard') as any, lk);
  } catch (error) {
    refused = String(error).includes('activeLength default is not derived from dotSize');
  } finally {
    relation.activeLength = oldSource;
  }
  if (!refused) throw new Error('DotIndicator builder accepted a changed default relationship');

  strictReads = true;
  const clean = await verifyFidelity();
  console.log(`\nBASELINE RUN: read ${clean.componentsRead}, checks ${clean.checksRun}, misses ${clean.misses.length}`);
  for (const m of clean.misses) console.log(`  ✗ ${m.component} · ${m.field}: ${m.expected} vs ${m.actual}`);
  // Printed, and ratcheted below. A value the module declines to compare is not
  // a pass — and until it was printed, nobody could tell the two apart.
  console.log(`  ○ not compared: ${clean.unchecked.length}`);
  for (const u of clean.unchecked) console.log(`      ${u}`);

  // Coverage was PRINTED and never asserted, so `✅ clean run is clean` was scoped
  // to whatever happened to build. A builder that throws takes its component out of
  // the sweep, and every check below it then passes over a smaller set — the line
  // that says everything is fine is the same line either way.
  //
  // Two floors, both derived rather than pinned to a number that would rot:
  //   · every registry entry builds — a partial collapse is not a clean run
  //   · every built component is read — the only reasons to build one and not
  //     read it are missing data, which `unchecked` names, and being a builder
  //     fixture with no contract, which `fixtures` names; all three reconcile
  if (built !== order.length) {
    console.log(
      `\n❌ ${order.length - built} of ${order.length} entries did not build. ` +
        'Every check below ran over the survivors, and a sweep that skipped a ' +
        'component cannot report a clean run for the library.',
    );
    process.exit(1);
  }
  const noData = clean.unchecked.filter((u) => u.indexOf('no data in components.json') >= 0).length;
  const fixtures = clean.fixtures.length;
  if (clean.componentsRead + noData + fixtures !== built) {
    console.log(
      `\n❌ built ${built} but read ${clean.componentsRead} (+${noData} with no data, ` +
        `+${fixtures} fixture(s)) — ` +
        `${built - clean.componentsRead - noData - fixtures} component(s) went missing between ` +
        'building and reading, with nothing accounting for them.',
    );
    process.exit(1);
  }
  // `checksRun` has to answer to the DATA, not to the component count.
  //
  // It was `componentsRead × 8` by construction — three fixed increments per
  // component — so 144 read always meant 1152 checks whether those checks compared
  // a thousand values or none. The field exists to distinguish a zero-miss run from
  // a zero-check one, which a number derived from the other number cannot do.
  //
  // Two components with different amounts of stated chrome must therefore report
  // different counts. Pinning an expected total would rot; this compares two
  // single-entry runs against each other.
  const heavy = await verifyFidelity('Button');
  const light = await verifyFidelity('Gap');
  if (heavy.checksRun === light.checksRun) {
    console.log(
      `\n❌ Button and Gap both report ${heavy.checksRun} check(s) — the count is not ` +
        'reading the data. If it is a fixed increment per component again, it says ' +
        'nothing about whether anything was compared.',
    );
    process.exit(1);
  }
  console.log(
    `  · per-component counts differ (Button ${heavy.checksRun} vs Gap ${light.checksRun}) — ` +
      'the count reads the data',
  );

  if (clean.componentsRead === 0 || clean.checksRun === 0) {
    console.log('\n❌ the sweep checked nothing — that is the failure this file exists to prevent');
    process.exit(1);
  }

  // Zero. Every miss this file has reported was traced to one of five answers:
  // a builder that did not paint a stated value, a check reading the wrong scope,
  // a value the code retired, a role neither platform renders, or a double that
  // modelled the canvas wrongly. None was settled by loosening a comparison.
  //
  // Zero is the useful baseline precisely because it cannot absorb a regression —
  // any new disagreement is the first one. A miss that IS understood and
  // accepted does not raise this number: it gets a named exception set here,
  // checked both ways (named ⇔ still reproduces), the way an understood
  // registry entry gets a name in `kFragmentsComparedThroughParent` rather than
  // a nudge to a count. None is named today.
  //
  // The fifth answer is why no tracking miss is named any more. Checkbox's and
  // RadioGroup's size ladders drop their role (the rung's size is not the
  // role's), so their labels bind letter spacing on the size tier — and the
  // double answered that tier with the SIZE as the value and stored it as a
  // bare number. Twelve rungs read as untracked and were filed as a Core
  // decision about the optical curve; with the binding modelled as the canvas
  // reads it, all twelve agree with the data. Every label that drops its role
  // for another field — a weight or a line height its style states over the
  // role's — takes the same tier, so the double had to be right before those
  // could be read at all.
  const BASELINE = 0;
  // Values the module declined to compare. Ratcheted for the same reason the
  // miss count is: a check that stops comparing things looks exactly like a
  // check that has nothing to report. This number goes DOWN when someone
  // teaches a check to read a per-size table.
  const UNCHECKED_BASELINE = 0;
  // `scopeToFragment` — the checks see a fragment as the component it is.
  {
    const parent = {
      fields: { itemPadding: 1, itemBorderRadius: 2, labelStyle: 3, borderRadius: 4, kbdStyle: 5 },
      sizes: { defaultsBySize: { sm: { itemMinHeight: 6, searchPadding: 7 } } },
      variants: { defaultsByPresentation: { inline: { borderRadius: 8 } } },
      absent: {},
      hostDerived: ['itemHoverColor', 'kbdStyle'],
      derivedDefaults: {itemWidth: 'itemHeight', kbdWidth: 'kbdHeight'},
      untokenized: [],
      deprecated: [],
      slots: { emptyIcon: { type: 'W' } },
      constants: {},
      section: { name: 'Control' },
    };
    const same = (label: string, got: unknown, want: unknown) => {
      if (JSON.stringify(got) !== JSON.stringify(want)) {
        console.log(`\n❌ scopeToFragment · ${label}: got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);
        process.exit(1);
      }
    };
    const scoped = scopeToFragment(parent, ['item*', 'labelStyle']) as Record<string, unknown>;
    same('fields — prefix stripped, plain kept, the rest gone', scoped.fields, {
      padding: 1,
      borderRadius: 2,
      labelStyle: 3,
    });
    same('sizes — tables scoped by the same rule', scoped.sizes, {
      defaultsBySize: { sm: { minHeight: 6 } },
    });
    same('variants — a panel-only row scopes to nothing', scoped.variants, {
      defaultsByPresentation: { inline: {} },
    });
    same('hostDerived — name lists too', scoped.hostDerived, ['hoverColor']);
    same('derived defaults — destination and source scoped', scoped.derivedDefaults, {width: 'height'});
    same("slots — the parent's slots are not the row's", scoped.slots, {});
    same('section — untouched, the page still sits with the parent', scoped.section, {
      name: 'Control',
    });
    if (scopeToFragment(parent, undefined) !== parent) {
      console.log('\n❌ scopeToFragment · no dataFields must be the identity, not a copy');
      process.exit(1);
    }
    let threw = false;
    try {
      scopeToFragment({ fields: { itemPadding: 1, padding: 2 } }, ['item*', 'padding']);
    } catch {
      threw = true;
    }
    if (!threw) {
      console.log('\n❌ scopeToFragment · two parent fields scoping to one name must throw');
      process.exit(1);
    }
    console.log('  ✓ scopeToFragment strips the prefix, scopes every table and list, keeps the page');
  }

  // A registry entry that is a FRAGMENT of a parent's contract declares
  // `dataSlug` + `dataFields` and is compared on its own, against only the
  // parent fields it reads (`scopeToFragment`, exercised just above). This map
  // is for a fragment that CANNOT be — one whose values are only reachable
  // through the instances its parent places. It is empty, and the one entry it
  // ever held is why it should stay that way: `CommandItem` sat here on the
  // claim that `Command` places its members and the checks search instances.
  // Counted, `Command` places 9 of the row's 48 variants — every hover,
  // pressed and disabled row was drawn and never compared. A fragment named
  // here is a fragment nobody is checking; say why in the value.
  const kFragmentsComparedThroughParent = new Map<string, string>([]);
  const uncheckedOutsideFragments = clean.unchecked.filter((u) => {
    const name = u.slice(0, u.indexOf(':'));
    return !(
      kFragmentsComparedThroughParent.has(name) &&
      u.indexOf('no data in components.json') >= 0
    );
  });
  for (const [fragment, parent] of kFragmentsComparedThroughParent) {
    if (!clean.unchecked.some((u) => u.startsWith(`${fragment}:`))) {
      console.log(
        `\n❌ ${fragment} is declared a fragment compared through ${parent} but ` +
          'now has data of its own — remove it from kFragmentsComparedThroughParent.',
      );
      process.exit(1);
    }
  }
  if (clean.misses.length > BASELINE) {
    console.log(
      `\n❌ canvas/JSON disagreements rose to ${clean.misses.length} ` +
        `(baseline ${BASELINE}). A builder started painting a value the data ` +
        'does not state, or stopped painting one it does.',
    );
    for (const m of clean.misses) {
      console.log(`  ✗ ${m.component} · ${m.field}: ${m.expected} vs ${m.actual}`);
    }
    process.exit(1);
  }

  if (uncheckedOutsideFragments.length > UNCHECKED_BASELINE) {
    console.log(
      `\n❌ values not compared rose to ${uncheckedOutsideFragments.length} ` +
        `(baseline ${UNCHECKED_BASELINE}). A component started stating chrome ` +
        'somewhere this module does not read, so it is neither checked nor ' +
        'reported as a gap.',
    );
    process.exit(1);
  }

  // A dynamic default is a real visual relation: break the selected box on
  // one variant and require a miss, then restore it. This verifies the
  // readback rather than counting the relation as checked merely because it
  // appeared in the exported metadata.
  const indicator = findComponentByName(page as never, 'DotIndicator') as unknown as Node;
  const indicatorMember = indicator.children.find((n: Node) => n.name.includes('Selected=1'));
  const activeDot = indicatorMember?.children.find((n: Node) => n.name === 'dot 1');
  if (!activeDot) throw new Error('DotIndicator selected marker missing on test canvas');
  const savedDotWidth = activeDot.width;
  activeDot.width += 3;
  const brokenRelation = await verifyFidelity('DotIndicator');
  if (!brokenRelation.misses.some((m) => m.field === 'derivedDefaults.activeLength.box.width')) {
    throw new Error('a broken active-length relation escaped canvas readback');
  }
  activeDot.width = savedDotWidth;
  const paintedDot = activeDot.children.find((n: Node) => n.type === 'RECTANGLE');
  if (!paintedDot) throw new Error('DotIndicator painted marker missing on test canvas');
  const savedPaintedWidth = paintedDot.width;
  paintedDot.width += 3;
  const brokenPaint = await verifyFidelity('DotIndicator');
  if (!brokenPaint.misses.some((m) => m.field === 'derivedDefaults.activeLength.paint.width')) {
    throw new Error('a broken painted marker escaped canvas readback');
  }
  paintedDot.width = savedPaintedWidth;
  activeDot.name = 'renamed marker';
  const missingMarker = await verifyFidelity('DotIndicator');
  if (!missingMarker.unchecked.some((u) => u.includes('activeLength') && u.includes('marker not found'))) {
    throw new Error('a missing selected marker escaped the unchecked report');
  }
  activeDot.name = 'dot 1';
  const restoredRelation = await verifyFidelity('DotIndicator');
  if (restoredRelation.misses.some((m) => m.field.startsWith('derivedDefaults.activeLength'))) {
    throw new Error('the restored active-length relation still failed');
  }
  console.log('Derived-default injection: selected marker width regression reported and restored.');

  // A composed alias must be checked against its base token, not skipped as
  // an unknown name. Losing opacity in any mode must fail the readback.
  const browser = findComponentByName(page as never, 'MockupBrowser') as unknown as Node;
  const toolbar = browser.children.find((node: Node) => node.name === 'bar');
  const alias = varsById.get(toolbar.fills[0].boundVariables.color.id)!;
  const savedValues = alias.valuesByMode;
  const composedClean = await verifyFidelity('MockupBrowser');
  if (composedClean.misses.some((m) => /alpha|boundAlpha/.test(m.field))) throw new Error('native opacity alias did not read clean');
  alias.valuesByMode = { light: { color: { type: 'VARIABLE_ALIAS', id: 'wrong-base' }, opacity: 88 } };
  const brokenAlias = await verifyFidelity('MockupBrowser');
  if (!brokenAlias.misses.some((m) => m.field.startsWith('boundAlpha('))) throw new Error('an unverified composed alias bypassed the bound-alpha guard');
  alias.valuesByMode = savedValues;
  const savedPaint = toolbar.fills[0];
  toolbar.fills = [{ ...savedPaint, opacity: 1 }];
  const opaqueAlias = await verifyFidelity('MockupBrowser');
  if (!opaqueAlias.misses.some((m) => m.field === 'boundAlpha(surface-container-low)')) throw new Error('opaque toolbar escaped its composed token alpha check');
  toolbar.fills = [savedPaint];
  console.log('Composed-color injections: wrong base alias and lost toolbar opacity reported.');

  // ── Injected regression ──────────────────────────────────────────────────
  // Pick a component the data gives a radius, and break it on the canvas.
  // Document-wide: `Popup` is on its own page, not on whichever page the build
  // loop finished on.
  const target = findComponentByName(page as never, 'Popup') as unknown as Node | null;
  if (!target) { console.log('\n(no Popup on the double — cannot inject)'); process.exit(1); }
  const victim = target.type === 'COMPONENT' ? target : target.children[0];
  const before = victim.topLeftRadius;
  victim.topLeftRadius = (typeof before === 'number' ? before : 0) + 7;
  victim.effects = [];

  const dirty = await verifyFidelity('Popup');
  console.log(`\nINJECTED (Popup radius ${before} -> ${victim.topLeftRadius}, effects cleared)`);
  console.log(`  misses ${dirty.misses.length}`);
  for (const m of dirty.misses) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);

  if (dirty.misses.length === 0) {
    console.log('\n❌ the readback did not notice a broken canvas — the check is inert');
    process.exit(1);
  }
  victim.topLeftRadius = before;

  // ── Injected regression, absence ──────────────────────────────────────────
  // The checks above compare a value the data states. This one compares a
  // value the data DECLINES to state, and it needs its own injection for the
  // reason this file exists: an absence check that reports nothing looks exactly
  // like one that asserts nothing, and the first version of this one asserted
  // nothing on four of its six kinds because the double did not model the
  // properties it read.
  //
  // Button is the subject because it declares both shapes of absence — no
  // shadow, and no width — so one victim exercises the two assertions that
  // read different halves of the API (`effects`, and the axis sizing derived
  // from `primaryAxisSizingMode`).
  const btn = findComponentByName(page as never, 'Button') as unknown as Node | null;
  if (!btn) { console.log('\n(no Button on the double — cannot inject absence)'); process.exit(1); }
  const bv = btn.type === 'COMPONENT' ? btn : btn.children[0];
  const beforeMode = bv.primaryAxisSizingMode;
  bv.effects = [
    { type: 'DROP_SHADOW', visible: true, color: { r: 0, g: 0, b: 0, a: 0.2 }, offset: { x: 0, y: 2 }, radius: 4, blendMode: 'NORMAL' },
  ];
  bv.primaryAxisSizingMode = 'FIXED';

  const absent = await verifyFidelity('Button');
  const absentMisses = absent.misses.filter((m) => m.field.startsWith('absent.'));
  console.log('\nINJECTED (Button given a shadow it does not declare, and pinned to a width)');
  console.log(`  absence misses ${absentMisses.length}`);
  for (const m of absentMisses) {
    console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
  }

  // Both, named: one passing while the other fails is the state where half the
  // table is inert, and a single count cannot tell that apart from both working.
  const sawShadow = absentMisses.some((m) => m.field === 'absent.boxShadow');
  const sawWidth = absentMisses.some((m) => m.field === 'absent.width');
  if (!sawShadow || !sawWidth) {
    console.log(
      `\n❌ absence check is inert — shadow ${sawShadow ? 'seen' : 'MISSED'}, ` +
        `width ${sawWidth ? 'seen' : 'MISSED'}. A canvas that paints what the ` +
        'code declines to state is the defect this half exists to find.',
    );
    process.exit(1);
  }
  bv.effects = [];
  bv.primaryAxisSizingMode = beforeMode;

  // ── Injected regression, per-row padding ──────────────────────────────────
  // Nine components state their padding only under a per-size table, so the
  // padding check used to skip them entirely and read as a pass. It now accepts
  // ANY stated row, which is the strongest claim the data supports — and a
  // claim nobody has seen fail is not a claim. Button is one of the nine.
  const padTarget = membersOfSet(bv);
  const beforePads = padTarget.map((n: Node) => n.paddingLeft);
  for (const n of padTarget) n.paddingLeft = 999;

  const padRun = await verifyFidelity('Button');
  const padMisses = padRun.misses.filter((m) => m.field === 'padding.l');
  console.log('\nINJECTED (Button left padding set to a value no size row states)');
  console.log(`  padding misses ${padMisses.length}`);
  for (const m of padMisses) console.log(`  ✗ ${m.field}: expected ${m.expected}`);
  if (padMisses.length === 0) {
    console.log(
      '\n❌ the per-row padding check is inert — an inset matching no stated ' +
        'size still read as agreement.',
    );
    process.exit(1);
  }
  padTarget.forEach((n: Node, i: number) => { n.paddingLeft = beforePads[i]; });

  // ── Injected regression, directional padding ──────────────────────────────
  // A horizontally asymmetric inset is stated as `start` / `end`, not `l` / `r`
  // (Alert's stacked row is 16 / 12). The padding check used to read only the
  // physical keys, so that row was never compared — and once a sibling row
  // (Alert's inline 14 / 14) stated the same side physically, the check ran on
  // the sibling alone and called the stacked member wrong. Skew the member's
  // left inset: the reported expectation must now carry the directional 16.
  const alertSet = findComponentByName(page as never, 'Alert') as unknown as Node | null;
  if (!alertSet) { console.log('\n(no Alert on the double — cannot inject directional padding)'); process.exit(1); }
  const alertFirst = alertSet.type === 'COMPONENT' ? alertSet : alertSet.children[0];
  const alertPadTarget = membersOfSet(alertFirst);
  const beforeAlertPads = alertPadTarget.map((n: Node) => n.paddingLeft);
  for (const n of alertPadTarget) n.paddingLeft = 999;
  const dirRun = await verifyFidelity('Alert');
  const dirMiss = dirRun.misses.find((m) => m.field === 'padding.l');
  console.log('\nINJECTED (Alert left padding set to a value no row states)');
  console.log(`  ${dirMiss ? `✗ ${dirMiss.field}: expected ${dirMiss.expected}` : 'no padding.l miss'}`);
  if (!dirMiss || !/(^|[^\d.])16([^\d.]|$)/.test(dirMiss.expected)) {
    console.log(
      '\n❌ the padding check does not read a directional inset — Alert states its ' +
        'stacked left as `start` 16, and the expectation it reports omits it.',
    );
    process.exit(1);
  }
  alertPadTarget.forEach((n: Node, i: number) => { n.paddingLeft = beforeAlertPads[i]; });

  // ── Injected regression, slot reachability ────────────────────────────────
  // The third check reads the SET's property definitions, which Figma refuses to
  // serve for a variant — the reason its first version died on the first
  // component set in the real file while passing 143 here. So it gets its own
  // injection: strip a set's properties and its exposure, and the slots it
  // declares must become unreachable.
  //
  // Button, because it declares three non-repeated slots (`child`, `leading`,
  // `trailing`) and is a set. The first attempt used `Select`, which declares no
  // slots at all — so the injection reported nothing and looked like the check
  // being inert, when it was the subject having nothing to check.
  const sel = findComponentByName(page as never, 'Button') as unknown as Node | null;
  if (!sel) { console.log('\n(no Button on the double — cannot inject slots)'); process.exit(1); }
  const beforeDefs = sel.propertyDefs;
  const stripExposure = (n: Node, out: Node[]) => {
    if (n.isExposedInstance === true) { n.isExposedInstance = false; out.push(n); }
    for (const kid of n.children ?? []) stripExposure(kid, out);
    return out;
  };
  const unexposed = stripExposure(sel, []);
  sel.propertyDefs = {};

  const slotRun = await verifyFidelity('Button');
  const slotMisses = slotRun.misses.filter((m) => m.field.startsWith('slots.'));
  console.log('\nINJECTED (Button stripped of properties and exposure)');
  console.log(`  slot misses ${slotMisses.length}`);
  for (const m of slotMisses) console.log(`  ✗ ${m.field}: ${m.actual}`);
  if (slotMisses.length === 0) {
    console.log(
      '\n❌ slot reachability check is inert — a set with no properties and ' +
        'nothing exposed still read as reachable.',
    );
    process.exit(1);
  }
  sel.propertyDefs = beforeDefs;
  for (const n of unexposed) n.isExposedInstance = true;

  // ── Slot names fold across spellings ──────────────────────────────────────
  // The contract spells a slot camelCase (`valueLabel`) and the design panel
  // spells the property that carries it with a space and a capital (`Value
  // label`). Matching on lower-cased text only read `valuelabel` against `value
  // label` and reported a slot the panel DOES offer as unreachable, so the check
  // now folds case and separators on both sides. A fold is a way to over-match
  // too, so both directions are asserted: the panel's own spelling must cover
  // the slot, and a different property whose text merely ends in the slot's
  // word must not.
  //
  // Progress, because it declares three non-repeated slots whose names differ
  // from their properties only in spelling (`label`, `valueLabel`, `caption`).
  const prog = findComponentByName(page as never, 'Progress') as unknown as Node | null;
  if (!prog) { console.log('\n(no Progress on the double — cannot test slot-name folding)'); process.exit(1); }
  const progDefs = prog.propertyDefs;
  const progUnexposed = stripExposure(prog, []);
  const slotMissesOf = async () =>
    (await verifyFidelity('Progress')).misses
      .filter((m) => m.field.startsWith('slots.'))
      .map((m) => m.field)
      .sort();

  prog.propertyDefs = {
    'Label#1:0': { type: 'TEXT' },
    'Value label#2:0': { type: 'TEXT' },
    'Show caption#3:0': { type: 'BOOLEAN' },
  };
  const folded = await slotMissesOf();
  console.log('\nFOLDING (Progress slots covered by `Label` · `Value label` · `Show caption`)');
  console.log(`  slot misses ${folded.length}${folded.length ? ` (${folded.join(', ')})` : ''}`);
  if (folded.length !== 0) {
    console.log(
      '\n❌ slot-name folding is inert — a slot the panel offers under a spaced ' +
        'spelling still read as unreachable.',
    );
    process.exit(1);
  }

  prog.propertyDefs = {
    'Helper label#1:0': { type: 'TEXT' },
    'Show helper caption#2:0': { type: 'BOOLEAN' },
  };
  const unfolded = await slotMissesOf();
  const unfoldedWant = ['slots.caption', 'slots.label', 'slots.valueLabel'];
  console.log('\nFOLDING (Progress slots NOT covered by `Helper label` · `Show helper caption`)');
  console.log(`  slot misses ${unfolded.length}${unfolded.length ? ` (${unfolded.join(', ')})` : ''}`);
  if (unfolded.join() !== unfoldedWant.join()) {
    console.log(
      '\n❌ slot-name folding over-matches — an unrelated property whose name ' +
        'only contains the slot word covered the slot (expected misses: ' +
        `${unfoldedWant.join(', ')}).`,
    );
    process.exit(1);
  }
  prog.propertyDefs = progDefs;
  for (const n of progUnexposed) n.isExposedInstance = true;

  // ── Injected regression, stacked text ─────────────────────────────────────
  // The defect this was written for: a composed field drawing its value twice,
  // the second copy offset behind the first. It reached the canvas and survived
  // every gate — the component was present, its properties were right, and the
  // 44px it was asked about was 44. A designer saw ghosted digits.
  //
  // Re-showing the placeholder is exactly the state that shipped, so the
  // injection is one line. TimePicker, because it is the one that made the
  // disagreement visible: its value is restyled to `displaySmall` while the
  // placeholder stays at the field's own 14.
  const tp = findComponentByName(page as never, 'TimePicker') as unknown as Node | null;
  if (!tp) { console.log('\n(no TimePicker on the double — cannot inject stacked text)'); process.exit(1); }
  const stacks: Node[] = [];
  const findStacks = (n: Node) => {
    if (n.type === 'FRAME' && n.name === 'input') stacks.push(n);
    for (const kid of n.children ?? []) findStacks(kid);
  };
  findStacks(tp);
  const reshown: Node[] = [];
  for (const stack of stacks) {
    for (const kid of stack.children ?? []) {
      if (kid.type === 'TEXT' && kid.visible === false) { kid.visible = true; reshown.push(kid); }
    }
  }
  if (reshown.length === 0) {
    console.log(
      '\n❌ nothing to re-show on TimePicker — either no field is composed into ' +
        'it any more, or the placeholder is no longer hidden, and either way ' +
        'this injection is asserting nothing.',
    );
    process.exit(1);
  }
  const stackRun = await verifyFidelity('TimePicker');
  const stackMisses = stackRun.misses.filter((m) => m.field.includes('input'));
  console.log(`\nINJECTED (TimePicker placeholder re-shown on ${reshown.length} field(s))`);
  console.log(`  stacked-text misses ${stackMisses.length}`);
  for (const m of stackMisses) console.log(`  ✗ ${m.field}: ${m.actual}`);
  if (stackMisses.length === 0) {
    console.log(
      '\n❌ stacked-text check is inert — a field showing its placeholder AND ' +
        'its value read as agreeing.',
    );
    process.exit(1);
  }
  for (const n of reshown) n.visible = false;

  // ── Injected regression, the size ladder ──────────────────────────────────
  //
  // The defect: six rungs of a size ladder drawn at ONE size. It survived the
  // set-wide text check by construction — that check asks whether a stated size
  // appears ANYWHERE in the set, and the role's own size does, so a set drawn
  // entirely at that size answers yes to every rung.
  //
  // So the injection is one the old check CANNOT see: two rungs SWAP sizes.
  // Every size the data states is still present somewhere, and every size is on
  // the wrong member. If the set-wide check reports this, the swap was not the
  // subtle thing it is meant to be; if only it reports it, the per-rung check is
  // inert. Both are asserted below.
  //
  // Checkbox, because its rows state `labelStyle.fontSize` outright — it is the
  // ladder the defect actually shipped on. The two ends are READ from the export:
  // a size typed here would go stale the day the ladder moves, and the injection
  // would then find nothing to swap.
  const labelRungs = CHECKBOX.sizes.defaultsBySize;
  const lowEnd = labelRungs.xs.labelStyle.fontSize.v;
  const highEnd = labelRungs.xl.labelStyle.fontSize.v;
  if (lowEnd === highEnd) {
    console.log(
      `\n❌ Checkbox xs and xl label sizes are both ${lowEnd} — swapping them moves nothing, ` +
        'so this injection asserts nothing. Pick two rungs that differ.',
    );
    process.exit(1);
  }
  const cb = findComponentByName(page as never, 'Checkbox') as unknown as Node | null;
  if (!cb) { console.log('\n(no Checkbox on the double — cannot inject the ladder)'); process.exit(1); }
  const rungOf = (n: Node): string | null => {
    for (const pair of String(n.name).split(',')) {
      const at = pair.indexOf('=');
      if (at >= 0 && pair.slice(0, at).trim() === 'Size') return pair.slice(at + 1).trim();
    }
    return null;
  };
  const textsUnder = (n: Node, out: Node[] = []): Node[] => {
    if (n.type === 'TEXT') out.push(n);
    for (const k of n.children ?? []) textsUnder(k, out);
    return out;
  };
  const swapped: { node: Node; size: number; ls: unknown }[] = [];
  for (const member of cb.children ?? []) {
    const rung = rungOf(member as Node);
    // `lowEnd` lives on `xs`, `highEnd` on `xl` — the two ends of the ladder, so
    // the swap moves each size onto a member that states the other. Only a text
    // wearing exactly the rung's label size is moved: the description rungs
    // (smaller, and stated by their own rows) stay where they are.
    const to = rung === 'xs' ? highEnd : rung === 'xl' ? lowEnd : null;
    const from = rung === 'xs' ? lowEnd : rung === 'xl' ? highEnd : null;
    if (to == null || from == null) continue;
    for (const t of textsUnder(member as Node)) {
      if (t.fontSize !== from) continue;
      swapped.push({ node: t, size: t.fontSize as number, ls: t.letterSpacing });
      t.fontSize = to;
      // The tracking moves with the size, so the LADDER is the only axis that
      // disagrees. Left behind, the letter-spacing check would fire too and the
      // assertion below could not tell which axis noticed.
      t.letterSpacing = { unit: 'PIXELS', value: -0.01 * to };
    }
  }
  if (swapped.length === 0) {
    console.log(
      '\n❌ nothing to swap on Checkbox — its rungs no longer draw the sizes ' +
        'their rows state, so this injection asserts nothing.',
    );
    process.exit(1);
  }
  const ladderRun = await verifyFidelity('Checkbox');
  const perRung = ladderRun.misses.filter((m) => m.expected.includes('on some TEXT of a Size='));
  const setWide = ladderRun.misses.filter((m) => m.expected.includes('somewhere in this component'));
  console.log(`\nINJECTED (Checkbox xs↔xl label sizes swapped, ${swapped.length} node(s))`);
  console.log(`  per-rung misses ${perRung.length}, set-wide misses ${setWide.length}`);
  for (const m of perRung) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
  if (perRung.length === 0) {
    console.log(
      '\n❌ the per-rung size check is inert — a ladder with two rungs wearing ' +
        "each other's size still read as agreement.",
    );
    process.exit(1);
  }
  if (setWide.length > 0) {
    console.log(
      '\n❌ the set-wide check reported this swap, so the injection is not the ' +
        'blind spot it was written for — pick two sizes that both stay present.',
    );
    process.exit(1);
  }
  for (const { node, size, ls } of swapped) { node.fontSize = size; node.letterSpacing = ls; }

  // ── Injected regression, letter spacing: the wrong ratio ──────────────────
  //
  // Tracking is a RATIO in Core — em times whatever size the label renders at —
  // so the way it goes wrong is a number computed for one rung arriving on
  // another. The size is right, the role is right, and the words sit at the
  // wrong width. Nothing else in this module reads it.
  const mdLabels = (cb.children ?? [])
    .filter((m: Node) => rungOf(m as Node) === 'md')
    .flatMap((m: Node) => textsUnder(m as Node))
    .filter((t: Node) => t.fontSize === 14);
  if (mdLabels.length === 0) {
    console.log('\n❌ no 14px label on Checkbox `md` — nothing to mistrack.');
    process.exit(1);
  }
  const beforeLs = mdLabels.map((t: Node) => t.letterSpacing);
  for (const t of mdLabels) t.letterSpacing = { unit: 'PIXELS', value: -0.5 };

  const ratioRun = await verifyFidelity('Checkbox');
  const perNode = ratioRun.misses.filter(
    (m) => m.field.endsWith('.letterSpacing') && !m.expected.includes('px TEXT of '),
  );
  console.log(`\nINJECTED (Checkbox md labels tracked -0.50px, a ratio nothing states)`);
  console.log(`  per-node letter-spacing misses ${perNode.length}`);
  for (const m of perNode) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
  if (perNode.length === 0) {
    console.log(
      '\n❌ the letter-spacing check is inert — a label tracked at a width no ' +
        'stated ratio produces still read as agreement.',
    );
    process.exit(1);
  }
  mdLabels.forEach((t: Node, i: number) => { t.letterSpacing = beforeLs[i]; });

  // ── Injected regression, letter spacing: none at all ──────────────────────
  //
  // The other half, and the one the check above is structurally blind to: a
  // builder that writes no tracking leaves nothing to compare, and a per-node
  // check reads that as a pass. `{unit: 'PERCENT', value: 0}` is what Figma
  // leaves on a text node nobody set, so this is exactly the canvas a forgotten
  // `letterSpacing` produces — and it is what six components' composed children
  // were showing until the forwarder started carrying the ratio.
  //
  // Asserted BOTH ways: the code→canvas direction must fire, and the per-node
  // direction must NOT — one number for both would hide either half going dead.
  const allLabels = (cb.children ?? []).flatMap((m: Node) => textsUnder(m as Node));
  const beforeAll = allLabels.map((t: Node) => t.letterSpacing);
  for (const t of allLabels) t.letterSpacing = { unit: 'PERCENT', value: 0 };

  const untrackedRun = await verifyFidelity('Checkbox');
  const reachMisses = untrackedRun.misses.filter((m) => m.expected.includes('px TEXT of '));
  const stillPerNode = untrackedRun.misses.filter(
    (m) => m.field.endsWith('.letterSpacing') && !m.expected.includes('px TEXT of '),
  );
  console.log(`\nINJECTED (Checkbox tracking cleared on ${allLabels.length} label(s))`);
  console.log(`  code→canvas misses ${reachMisses.length}, per-node misses ${stillPerNode.length}`);
  for (const m of reachMisses) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
  if (reachMisses.length === 0) {
    console.log(
      '\n❌ the code→canvas half is inert — a stated tracking that reached no ' +
        'label at all still read as agreement, which is the shape the defect ' +
        'this axis was written for actually had.',
    );
    process.exit(1);
  }
  if (stillPerNode.length > 0) {
    console.log(
      '\n❌ the per-node half judged an unset tracking. It must not: a node the ' +
        'builder never tracked is a node the data may say nothing about, and ' +
        "asserting a claim on it invents one — that is how six components' " +
        'preview stand-ins were reported as defects.',
    );
    process.exit(1);
  }
  allLabels.forEach((t: Node, i: number) => { t.letterSpacing = beforeAll[i]; });

  // ── Direct check, letter spacing: a null ratio clears the old pixels ──────
  //
  // `applyLetterSpacing` is what every path above funnels through, and its
  // `em == null` branch has its own defect shape: a node this function styled
  // once (PIXELS, some prior rung's size) and is then asked to style again
  // with NO ratio must not keep the old pixels sitting under the new size.
  // That is the exact "right size, wrong width" defect this module exists to
  // catch, reappearing through this one function instead of through a stale
  // caller — so it gets its own check rather than riding on a canvas-wide
  // injection, which could not isolate this branch from the three others that
  // already exercise it.
  {
    const stale = mk('TEXT') as unknown as TextNode;
    // A prior pass wrote PIXELS at some earlier size (`md`'s 14, tracked at
    // its role's ratio) — the shape `writtenLetterSpacingPx` reads as "a
    // builder stated a tracking here".
    (stale as unknown as Node).letterSpacing = { unit: 'PIXELS', value: -0.14 * 14 };
    applyLetterSpacing(stale, lk, { em: null, size: 16, role: null });
    const after = (stale as unknown as Node).letterSpacing as { unit: string; value: number };
    console.log('\nDIRECT (applyLetterSpacing re-styled with em: null after a prior PIXELS write)');
    console.log(`  letterSpacing after: ${JSON.stringify(after)}`);
    if (after.unit !== 'PERCENT' || after.value !== 0) {
      console.log(
        '\n❌ a null ratio left the previous pass\'s pixels in place — the ' +
          'node now reads as tracked at a width nothing in the new style ' +
          'states, which is indistinguishable from a forwarder that forgot ' +
          'to carry the ratio at all.',
      );
      process.exit(1);
    }
  }

  // ── Injected regression, mark thickness ───────────────────────────────────
  //
  // `markThickness` is the height of the indeterminate DASH, a bar the widget
  // draws at one thickness on every size. The checkmark beside it is an `Icon`
  // instance and follows the icon stroke rule, so the axis reads the bar and
  // must not read the vectors.
  const dashes: Node[] = [];
  const vectors: Node[] = [];
  const findMarks = (n: Node) => {
    if (n.type === 'RECTANGLE' && n.name === kMarkBarName) dashes.push(n);
    if (n.type === 'VECTOR') vectors.push(n);
    for (const k of n.children ?? []) findMarks(k);
  };
  findMarks(cb);
  if (dashes.length === 0) {
    console.log(
      '\n❌ no mark bar under Checkbox — the dash is not drawn as a ' +
        'named RECTANGLE, and this injection asserts nothing.',
    );
    process.exit(1);
  }
  if (vectors.length === 0) {
    console.log(
      '\n❌ no VECTOR under Checkbox — the check is not drawn as one, ' +
        'and the second half of this injection asserts nothing.',
    );
    process.exit(1);
  }

  // What the builder binds: the dash's height, and nothing on the check. The ✓ is
  // an `Icon` instance that follows the icon stroke, so a stroke bound under it is
  // the ✓ pinned to the dash's weight and off the icon rule — and the readback
  // below cannot see that, because it reads the dash.
  const boundVectors = vectors.filter((v: Node) => v.boundVariables?.strokeWeight != null);
  if (boundVectors.length > 0) {
    console.log(
      `\n❌ ${boundVectors.length} check vector(s) have their stroke weight bound to a variable — ` +
        'the check must follow the icon stroke, not `checkbox/mark-thickness`.',
    );
    process.exit(1);
  }
  // Bound to THE variable, by name. A dash's height is also bound to a size
  // variable by `bindSize`, so "some variable is bound" holds with the
  // `checkbox/mark-thickness` binding deleted; only the bound variable's own
  // name says which one the canvas follows.
  const boundHeightName = (d: Node): string | null => {
    const id = (d.boundVariables?.height as { id?: string } | undefined)?.id;
    return id == null ? null : (varsById.get(id)?.name ?? null);
  };
  const kMarkThicknessVariable = 'Component/checkbox/mark-thickness';
  const wrongBound = dashes.filter((d: Node) => boundHeightName(d) !== kMarkThicknessVariable);
  if (wrongBound.length > 0) {
    console.log(
      `\n❌ ${wrongBound.length} of ${dashes.length} dash(es) have their height bound to ` +
        `${JSON.stringify(boundHeightName(wrongBound[0]))}, not to ${kMarkThicknessVariable} — ` +
        '`checkbox/mark-thickness` reaches the canvas only through that binding.',
    );
    process.exit(1);
  }

  // The vectors at a weight the dash does not have: the axis must NOT report it.
  // A check that read the vectors would fail here: the icon doing its job would
  // read as a disagreement.
  const beforeWeights = vectors.map((v: Node) => v.strokeWeight);
  for (const v of vectors) v.strokeWeight = 3;
  const vectorRun = await verifyFidelity('Checkbox');
  const vectorMisses = vectorRun.misses.filter((m) => m.field === 'markThickness');
  console.log(`\nINJECTED (Checkbox check vectors stroked at 3 on ${vectors.length} vector(s))`);
  console.log(`  mark-thickness misses ${vectorMisses.length}`);
  vectors.forEach((v: Node, i: number) => { v.strokeWeight = beforeWeights[i]; });
  if (vectorMisses.length > 0) {
    console.log(
      '\n❌ the mark-thickness axis read the checkmark. The check is an Icon ' +
        'instance and follows the icon stroke rule; only the dash is stated by ' +
        '`markThickness`.',
    );
    process.exit(1);
  }

  // The dash at a height the widget does not draw: the axis must report it.
  const beforeHeights = dashes.map((d: Node) => d.height);
  for (const d of dashes) d.height = 3;

  const strokeRun = await verifyFidelity('Checkbox');
  const strokeMisses = strokeRun.misses.filter((m) => m.field === 'markThickness');
  console.log(`\nINJECTED (Checkbox dash drawn 3 tall on ${dashes.length} bar(s))`);
  console.log(`  mark-thickness misses ${strokeMisses.length}`);
  for (const m of strokeMisses) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
  dashes.forEach((d: Node, i: number) => { d.height = beforeHeights[i]; });
  if (strokeMisses.length === 0) {
    console.log(
      '\n❌ the mark-thickness check is inert — a dash drawn at a height the ' +
        'widget does not draw still read as agreement.',
    );
    process.exit(1);
  }
  // A component that states no thickness is not a component that agrees about
  // one, and this axis reads exactly one component in the whole library. If
  // Checkbox ever slid onto that list the axis would compare nothing and report
  // nothing, which is indistinguishable from a clean sweep.
  if (strokeRun.strokeUnstated.includes('Checkbox')) {
    console.log(
      '\n❌ Checkbox is listed as stating no mark thickness while the dash ' +
        'just failed on its thickness — the two lists disagree about the same field.',
    );
    process.exit(1);
  }
  // One member wrong, the rest right. The injection above breaks every dash, so
  // a readback that judged a single member (or stopped at the first) would still
  // report it; this one is reported only by a readback that reaches the member
  // that is wrong. First and last, so a loop that skips either end is caught.
  {
    const members = (cb.children ?? []) as Node[];
    const dashesOf = (m: Node): Node[] => {
      const out: Node[] = [];
      const walk = (n: Node) => {
        if (n.type === 'RECTANGLE' && n.name === kMarkBarName) out.push(n);
        for (const k of n.children ?? []) walk(k);
      };
      walk(m);
      return out;
    };
    const drawing = members.filter((m: Node) => dashesOf(m).length > 0);
    if (drawing.length < 2) {
      console.log(
        `\n❌ ${drawing.length} Checkbox member(s) draw a mark bar — the one-member-wrong ` +
          'injection needs a first and a last that differ.',
      );
      process.exit(1);
    }
    for (const [which, target] of [['first', drawing[0]], ['last', drawing[drawing.length - 1]]] as const) {
      const bars = dashesOf(target);
      const before = bars.map((d: Node) => d.height);
      for (const d of bars) d.height = 3;
      const run = await verifyFidelity('Checkbox');
      bars.forEach((d: Node, i: number) => { d.height = before[i]; });
      const misses = run.misses.filter((m) => m.field === 'markThickness');
      console.log(`\nINJECTED (Checkbox dash drawn 3 tall in the ${which} member only: "${target.name}")`);
      console.log(`  mark-thickness misses ${misses.length}`);
      for (const m of misses) console.log(`  ✗ ${m.field}: expected ${m.expected}, canvas ${m.actual}`);
      const named = misses.length === 1 &&
        misses[0].actual.startsWith(`1 of the ${drawing.length} member(s)`) &&
        misses[0].actual.includes(`"${target.name}" draws it 3.00 tall`);
      if (!named) {
        console.log(
          `\n❌ the one wrong dash (the ${which} member, "${target.name}") was not reported as exactly ` +
            `that — the mark-thickness check does not judge every member that draws a bar.`,
        );
        process.exit(1);
      }
    }
  }
  const restoredStroke = await verifyFidelity('Checkbox');
  if (restoredStroke.misses.some((m) => m.field === 'markThickness')) {
    console.log('\n❌ Checkbox did not read clean on mark thickness after the injections were restored');
    process.exit(1);
  }

  // ── Injected regression, a bound paint's stated strength ──────────────────
  // The colour-alpha check refuses a bound paint below full strength — the shape
  // every forgotten-alpha tint had. A bound paint may state a strength on purpose:
  // written after the binding and marked by `assignPaints`; the marker is the only
  // thing that tells the two apart. No MockupDevice layer states one (the
  // home indicator's bar is `on-surface` at full strength), so the injection
  // makes one: each bar's fill is set to 35% — an alpha the component states
  // (`statusBarBatteryBorderColor`) — and marked the way `assignPaints` marks
  // it. Without an injection the exemption could be an `if (true)` and the clean
  // run above would read exactly the same, so the marker is taken off and the
  // readback must refuse the paint again.
  const device = findComponentByName(page as never, 'MockupDevice') as unknown as Node | null;
  if (!device) { console.log('\n(no MockupDevice on the double — cannot inject strength)'); process.exit(1); }
  const kMarker = 'coui-paint-strength';
  const markedNodes: Node[] = [];
  const bars: Node[] = [];
  const collectDeviceNodes = (n: Node) => {
    if (n.pluginData?.[kMarker] === '1') markedNodes.push(n);
    if (n.name === 'HomeIndicator') bars.push(...(n.children ?? []).filter((k: Node) => k.name === 'Bar'));
    for (const k of n.children ?? []) collectDeviceNodes(k);
  };
  collectDeviceNodes(device);
  const strengthMisses = (run: { misses: { field: string }[] }) =>
    run.misses.filter((m) => m.field.startsWith('boundAlpha(on-surface)') || m.field.startsWith('alpha(on-surface)'));
  if (markedNodes.length !== 0) {
    console.log(`\n❌ MockupDevice states no paint strength, yet ${markedNodes.length} layer(s) carry the marker`);
    process.exit(1);
  }
  // The realistic members (Device × Orientation) draw one home indicator bar
  // each; the flat members draw none.
  if (bars.length !== 4) {
    console.log(`\n❌ expected 4 home indicator bars across MockupDevice's 4 realistic members, found ${bars.length}`);
    process.exit(1);
  }
  const whole = await verifyFidelity('MockupDevice');
  if (strengthMisses(whole).length > 0) {
    console.log('\n❌ MockupDevice\'s full-strength bars read as a miss on a clean canvas');
    process.exit(1);
  }
  const fillsOf = (n: Node) => (n as unknown as { fills: { opacity?: number }[] }).fills;
  const originalFills = bars.map((n) => fillsOf(n).slice());
  const setStrength = (strength: number, marker: string) => {
    bars.forEach((n, i) => {
      (n as unknown as { fills: unknown }).fills = originalFills[i].map((paint) => ({ ...paint, opacity: strength }));
      n.pluginData[kMarker] = marker;
    });
  };
  // Marked: a bound paint under 100% that the component can state is not a miss.
  setStrength(0.35, '1');
  const marked = await verifyFidelity('MockupDevice');
  // The marker taken off: the same paint is the forgotten-alpha shape again.
  setStrength(0.35, '');
  const unmarked = await verifyFidelity('MockupDevice');
  bars.forEach((n, i) => {
    (n as unknown as { fills: unknown }).fills = originalFills[i];
    n.pluginData[kMarker] = '';
  });
  console.log(`\nINJECTED (${bars.length} home indicator bars at 35% on the paint, marker on, then off)`);
  console.log(`  strength misses with the marker ${strengthMisses(marked).length}, without ${strengthMisses(unmarked).length}`);
  if (strengthMisses(marked).length > 0) {
    console.log('\n❌ a marked bound paint at a strength the component states was refused — the marker does not exempt');
    process.exit(1);
  }
  if (!strengthMisses(unmarked).some((m) => m.field.startsWith('boundAlpha(on-surface)'))) {
    console.log('\n❌ an unmarked bound paint below full strength was not refused — the exemption is not the marker');
    process.exit(1);
  }
  const restoredDevice = await verifyFidelity('MockupDevice');
  if (strengthMisses(restoredDevice).length > 0) {
    console.log('\n❌ MockupDevice did not read clean after the strength injection was restored');
    process.exit(1);
  }
  // What this readback cannot see: a marked paint that LOST its strength reads
  // as 100%, and a token the component also states at 100% (the bar's own
  // `on-surface`) makes that an alpha the component states. The write reports
  // that itself (`paintOpacityNotHeld`, drained into the build log by `generate.ts`).

  // Every injection above restores what it broke. Read once more, so "restored"
  // is a measurement and not a claim — a restore that misses a node leaves the
  // next run of this file starting from a canvas that is already wrong.
  const restored = await verifyFidelity('Checkbox');
  if (restored.misses.length > 0) {
    console.log(
      `\n❌ Checkbox did not come back clean — ${restored.misses.length} ` +
        'miss(es) survive:',
    );
    for (const m of restored.misses) console.log(`  ✗ ${m.field}: ${m.expected} vs ${m.actual}`);
    process.exit(1);
  }
  console.log('\n  · Checkbox reads clean again after all four restores');

  console.log('\n✅ clean run is clean, all injected/direct regressions are reported');
}

void main();
