/// <reference types="@figma/plugin-typings" />

import { diffLeaves, fingerprintNode, parityReport, readVariantLeaves, renameCopyVariants } from '../src/designer-parity';
import { kInsetArithmeticEpsilon, layoutInsetWitness, matchesLayoutInsetWitness, projectLayoutInsets } from '../src/layout-inset-projection';

type Node = Record<string, any>;
let serial = 0;

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}
function equal(a: unknown, b: unknown, message: string): void {
  assert(JSON.stringify(a) === JSON.stringify(b), `${message}: ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
}
const scene = (n: Node): SceneNode => n as SceneNode;
const setNode = (n: Node): ComponentSetNode => n as ComponentSetNode;

function node(type = 'FRAME', extra: Node = {}): Node {
  const n: Node = {
    id: `fixture-${serial++}`, name: 'arbitrary name', type, visible: true,
    x: 0, y: 0, width: 0, height: 0, children: [],
    layoutMode: 'VERTICAL', layoutWrap: 'NO_WRAP', primaryAxisSizingMode: 'AUTO',
    counterAxisSizingMode: 'AUTO', layoutSizingHorizontal: 'HUG', layoutSizingVertical: 'HUG',
    primaryAxisAlignItems: 'MIN', counterAxisAlignItems: 'MIN', layoutPositioning: 'AUTO',
    layoutGrow: 0, layoutAlign: 'INHERIT', opacity: 1, blendMode: 'PASS_THROUGH',
    isMask: false, clipsContent: true, rotation: 0, fills: [], strokes: [], effects: [],
    layoutGrids: [], fillStyleId: '', strokeStyleId: '', effectStyleId: '', gridStyleId: '',
    cornerRadius: 0, topLeftRadius: 0, topRightRadius: 0, bottomLeftRadius: 0,
    bottomRightRadius: 0, cornerSmoothing: 0, minWidth: null, maxWidth: null,
    minHeight: null, maxHeight: null, componentPropertyReferences: {}, explicitVariableModes: {},
    resolvedVariableModes: {}, boundVariables: {}, paddingTop: 0, paddingRight: 0,
    paddingBottom: 0, paddingLeft: 0, itemSpacing: 0, getPluginData: () => '',
    fontSize: 16, fontName: { family: 'Inter', style: 'Semi Bold' }, lineHeight: { unit: 'PIXELS', value: 22 },
    letterSpacing: { unit: 'PIXELS', value: 0 }, textStyleId: '', textAlignHorizontal: 'LEFT',
    ...extra,
  };
  Object.defineProperties(n, {
    relativeTransform: { configurable: true, get: () => [[1, 0, n.x], [0, 1, n.y]] },
    absoluteTransform: { configurable: true, get: () => [[1, 0, n.absoluteBoundingBox.x], [0, 1, n.absoluteBoundingBox.y]] },
    absoluteBoundingBox: { configurable: true, get: () => {
      const p = n.parent?.absoluteBoundingBox;
      return { x: (p?.x ?? 0) + n.x, y: (p?.y ?? 0) + n.y, width: n.width, height: n.height };
    } },
    absoluteRenderBounds: { configurable: true, get: () => ({ ...n.absoluteBoundingBox, ...n.renderOverride }) },
  });
  return n;
}

function append(parent: Node, ...children: Node[]): void {
  parent.children.push(...children);
  for (const child of children) child.parent = parent;
}

function natural(frame: Node, children: Node[], pad: number[], gap: number, direction: string): void {
  const [top, right, bottom, left] = pad;
  Object.assign(frame, { paddingTop: top, paddingRight: right, paddingBottom: bottom,
    paddingLeft: left, itemSpacing: gap, layoutMode: direction });
  append(frame, ...children);
  let cursor = 0;
  for (const child of children) {
    child.x = left + (direction === 'HORIZONTAL' ? cursor : 0);
    child.y = top + (direction === 'VERTICAL' ? cursor : 0);
    cursor += (direction === 'VERTICAL' ? child.height : child.width) + gap;
  }
  const extent = cursor - (children.length ? gap : 0);
  frame.width = left + right + (direction === 'HORIZONTAL' ? extent : Math.max(0, ...children.map(c => c.width)));
  frame.height = top + bottom + (direction === 'VERTICAL' ? extent : Math.max(0, ...children.map(c => c.height)));
}

function fixture(direction = 'VERTICAL', last = false, chain = 1) {
  const ink = [{ type: 'SOLID', color: { r: 0.1, g: 0.2, b: 0.3 } }];
  const makeText = (characters: string, width: number, height: number): Node =>
    node('TEXT', { characters, name: characters, width, height, fills: ink });
  const makeContent = (): Node => {
    const c = node();
    natural(c, [makeText('Title', 45, 22), ...(last ? [] : [makeText('Description', 89, 20)])],
      direction === 'VERTICAL' ? [0, 0, last ? 0 : 20, 0] : [1, 2, 3, 4], 2, direction);
    return c;
  };
  const content = makeContent();
  let outer = content;
  const pads: number[][] = [];
  for (let i = 0; i < chain; i++) {
    const wrapper = node();
    const pad = direction === 'VERTICAL' ? [i + 1, 0, 0, 0] : [i + 1, 3, 4, 5];
    pads.push(pad);
    natural(wrapper, [outer], pad, 0, direction);
    outer = wrapper;
  }
  const flat = makeContent();
  const sum = pads.reduce((a, p) => a.map((v, i) => v + p[i]),
    [flat.paddingTop, flat.paddingRight, flat.paddingBottom, flat.paddingLeft]);
  const flatChildren = flat.children;
  flat.children = [];
  natural(flat, flatChildren, sum, 2, direction);
  const root = node('COMPONENT', { name: 'Enabled=true, Layout=vertical', x: 100, y: 200, width: 125, height: 132 });
  const copyRoot = node('COMPONENT', { name: root.name, x: 900, y: 400, width: 125, height: 132 });
  append(root, outer); append(copyRoot, flat); outer.x = flat.x = 36;
  const source = node('COMPONENT_SET', { name: 'UnrelatedHarness', children: [root] });
  const copy = node('COMPONENT_SET', { name: 'UnrelatedHarness(리디자인)', children: [copyRoot] });
  return { source, copy, root, copyRoot, outer, content, flat };
}

async function raw(f: ReturnType<typeof fixture>) {
  return readVariantLeaves(setNode(f.source));
}
async function projected(f: ReturnType<typeof fixture>) {
  return readVariantLeaves(setNode(f.source), undefined, { root: setNode(f.copy), renames: [] });
}
async function difference(f: ReturnType<typeof fixture>) {
  return diffLeaves(await readVariantLeaves(setNode(f.copy)), await projected(f));
}

export async function layoutInsetChecks(): Promise<void> {
  const variables = new Map<string, Node>();
  (globalThis as unknown as { figma: unknown }).figma = {
    mixed: Symbol('mixed'), variables: { getVariableByIdAsync: async (id: string) => variables.get(id) ?? null },
    getStyleByIdAsync: async () => ({ type: 'TEXT', boundVariables: {} }),
  };
  let failures = 0;
  let checks = 0;
  const check = async (label: string, fn: () => void | Promise<void>): Promise<void> => {
    checks++;
    try { await fn(); console.log(`  ok  inset projection — ${label}`); }
    catch (e) { failures++; console.error(`FAIL  inset projection — ${label}\n      ${String(e)}`); }
  };
  for (const [direction, last, chain] of [
    ['VERTICAL', false, 1], ['VERTICAL', true, 1], ['HORIZONTAL', false, 1], ['VERTICAL', false, 3],
  ] as const) {
    await check(`${direction}, last=${last}, ${chain} additive frame(s)`, async () => {
      const f = fixture(direction, last, chain);
      assert((await difference(f)).differing.length === 0, 'equivalent effective layouts must match');
      assert(diffLeaves(await readVariantLeaves(setNode(f.copy)), await raw(f)).differing.length === 1,
        'raw collection must still report the representation difference');
      const p = projectLayoutInsets(scene(f.outer));
      assert(p?.frames.length === chain + 1, 'the entire natural chain is proven');
      const nonLayout = (leaves: Record<string, string[]>) => Object.values(leaves).flat().filter(l => !l.startsWith('layout '));
      equal(nonLayout(await projected(f)), nonLayout(await raw(f)), 'all non-layout leaves/multiplicity are preserved');
    });
  }
  const guards: [string, unknown][] = [
    ['type', 'COMPONENT'], ['type', 'INSTANCE'], ['visible', false], ['layoutMode', 'NONE'],
    ['layoutWrap', 'WRAP'], ['primaryAxisSizingMode', 'FIXED'], ['counterAxisSizingMode', 'FIXED'],
    ['layoutSizingHorizontal', 'FILL'], ['layoutSizingVertical', 'FIXED'],
    ['primaryAxisAlignItems', 'SPACE_BETWEEN'], ['counterAxisAlignItems', 'CENTER'],
    ['layoutPositioning', 'ABSOLUTE'], ['layoutGrow', 1], ['layoutAlign', 'STRETCH'],
    ['opacity', 0.5], ['blendMode', 'MULTIPLY'], ['isMask', true], ['clipsContent', undefined],
    ['rotation', 1], ['fills', [{}]], ['strokes', [{}]], ['effects', [{ type: 'DROP_SHADOW' }]],
    ['layoutGrids', [{}]], ['fillStyleId', 'style'], ['strokeStyleId', 'style'], ['effectStyleId', 'style'], ['gridStyleId', 'style'],
    ['cornerRadius', 1], ['topLeftRadius', 1], ['topRightRadius', 1], ['bottomLeftRadius', 1],
    ['bottomRightRadius', 1], ['cornerSmoothing', 0.5], ['minWidth', 1], ['maxWidth', 200], ['minHeight', 1], ['maxHeight', 200],
    ['componentPropertyReferences', { visible: 'show' }], ['explicitVariableModes', { c: 'dark' }],
    ['resolvedVariableModes', undefined], ['boundVariables', { visible: { type: 'VARIABLE_ALIAS', id: 'v' } }],
    ['boundVariables', { paddingTop: {} }], ['boundVariables', 1], ['x', NaN], ['width', Infinity],
    ['width', -1], ['paddingTop', -1], ['paddingLeft', undefined], ['itemSpacing', NaN],
  ];
  for (const [field, value] of guards) for (const target of ['outer', 'content'] as const) {
    await check(`${target}: rejects ${field}=${String(value)}`, () => {
      const f = fixture(); f[target][field] = value;
      assert((projectLayoutInsets(scene(f.outer))?.frames.length ?? 0) < 2, 'guard must retain the raw chain');
    });
  }
  for (const which of ['hidden', 'absolute', 'visible']) {
    await check(`a second ${which} child counts`, () => {
      const f = fixture(); append(f.outer, node('FRAME', { visible: which !== 'hidden', layoutPositioning: which === 'absolute' ? 'ABSOLUTE' : 'AUTO' }));
      assert(projectLayoutInsets(scene(f.outer))?.frames.length === 1, 'count actual children, not just painted/in-flow children');
    });
  }
  for (const mutate of [
    (f: ReturnType<typeof fixture>) => { f.outer.itemSpacing = 1; },
    (f: ReturnType<typeof fixture>) => { f.content.layoutMode = 'HORIZONTAL'; },
    (f: ReturnType<typeof fixture>) => { f.content.x += 1; },
    (f: ReturnType<typeof fixture>) => { f.content.y += 1; },
    (f: ReturnType<typeof fixture>) => { f.outer.width += 1; },
    (f: ReturnType<typeof fixture>) => { f.outer.height += 1; },
    (f: ReturnType<typeof fixture>) => { f.content.resolvedVariableModes = { c: 'dark' }; },
    (f: ReturnType<typeof fixture>) => { Object.defineProperty(f.outer, 'relativeTransform', { value: [[-1, 0, 0], [0, 1, 0]] }); },
    (f: ReturnType<typeof fixture>) => { Object.defineProperty(f.outer, 'absoluteTransform', { value: [[-1, 0, 136], [0, 1, 200]] }); },
    (f: ReturnType<typeof fixture>) => { Object.defineProperty(f.content, 'fills', { get() { throw Error('unsupported getter'); } }); },
  ]) {
    await check(`equations/orientation/scope/transform/getter failure ${checks}`, () => {
      const f = fixture(); mutate(f);
      assert((projectLayoutInsets(scene(f.outer))?.frames.length ?? 0) < 2, 'not a proven additive chain');
    });
  }
  await check('every missing required plain-frame field fails closed', () => {
    const required = ['layoutMode','layoutWrap','primaryAxisSizingMode','counterAxisSizingMode','layoutSizingHorizontal',
      'layoutSizingVertical','primaryAxisAlignItems','counterAxisAlignItems','layoutPositioning','layoutGrow','layoutAlign',
      'opacity','blendMode','isMask','clipsContent','rotation','fills','strokes','effects','layoutGrids','fillStyleId',
      'strokeStyleId','effectStyleId','gridStyleId','cornerRadius','topLeftRadius','topRightRadius','bottomLeftRadius',
      'bottomRightRadius','cornerSmoothing','minWidth','maxWidth','minHeight','maxHeight','componentPropertyReferences',
      'explicitVariableModes','resolvedVariableModes','boundVariables','x','y','width','height','paddingTop','paddingRight',
      'paddingBottom','paddingLeft','itemSpacing','relativeTransform','absoluteTransform','absoluteBoundingBox'];
    for (const field of required) {
      const f = fixture(); delete f.outer[field];
      assert(projectLayoutInsets(scene(f.outer)) == null, `missing ${field}`);
    }
  });
  for (const boundary of ['left', 'right', 'top', 'bottom', 'missing']) {
    await check(`clipping rejects ${boundary} render bounds, with no overflow tolerance`, () => {
      const f = fixture(); const text = f.content.children[0]; const b = f.content.absoluteBoundingBox;
      const tiny = kInsetArithmeticEpsilon / 4;
      if (boundary === 'missing') Object.defineProperty(text, 'absoluteRenderBounds', { value: null });
      else text.renderOverride = { ...text.absoluteRenderBounds,
        ...(boundary === 'left' ? { x: b.x - tiny } : boundary === 'right' ? { width: b.width + tiny } :
          boundary === 'top' ? { y: b.y - tiny } : { height: b.height + tiny }) };
      assert(projectLayoutInsets(scene(f.outer))?.frames.length === 1, 'unknown or clipped painted descendant stays raw');
    });
  }
  await check('arithmetic epsilon is bounded; witnesses never round it', async () => {
    const f = fixture(); f.outer.clipsContent = f.content.clipsContent = false;
    f.content.x += kInsetArithmeticEpsilon / 2;
    assert(projectLayoutInsets(scene(f.outer))?.frames.length === 2, 'only the equation absorbs floating addition error');
    assert((await difference(f)).differing.length === 1, 'different actual leaf position cannot match the exact counterpart witness');
    f.content.x += kInsetArithmeticEpsilon * 2;
    assert(projectLayoutInsets(scene(f.outer))?.frames.length === 1, 'larger arithmetic error rejects');
    assert(kInsetArithmeticEpsilon <= 1e-6, 'do not widen the eligibility epsilon');
  });
  for (const target of ['outer', 'content', 'leaf'] as const) for (const metric of ['x', 'y', 'width', 'height']) {
    await check(`actual ${target} ${metric} changes stay different`, async () => {
      const f = fixture(); const n = target === 'leaf' ? f.content.children[0] : f[target]; n[metric] += 1;
      assert((await difference(f)).differing.length === 1, 'a different effective placement/extent must not disappear');
    });
  }
  for (const change of ['padding', 'gap', 'text', 'color', 'duplicate', 'connector']) {
    await check(`${change} regression remains visible`, async () => {
      const f = fixture();
      if (change === 'padding') f.content.paddingBottom++;
      if (change === 'gap') f.content.itemSpacing++;
      if (change === 'text') f.content.children[0].characters = 'Changed';
      if (change === 'color') f.content.children[0].fills = [{ type: 'SOLID', color: { r: 1, g: 0, b: 0 } }];
      if (change === 'duplicate') append(f.content, node('TEXT', { characters: 'Extra', width: 10, height: 10 }));
      if (change === 'connector') append(f.root, node('RECTANGLE', { width: 1, height: 33, fills: [{ type: 'SOLID', color: { r: 1, g: 0, b: 0 } }] }));
      assert((await difference(f)).differing.length === 1, 'all non-equivalent values and multiplicity must fail');
    });
  }
  await check('plain raw fallback is byte-for-byte and counterpart exceptions cannot break it', async () => {
    const f = fixture(); const before = await raw(f);
    Object.defineProperty(f.copy, 'children', { get() { throw Error('unavailable counterpart'); } });
    equal(await projected(f), before, 'unsupported peer retains the old reader');
  });
  await check('a clipped flat counterpart cannot witness an unclipped layout', async () => {
    const f = fixture();
    f.flat.children[0].renderOverride = { width: f.flat.width + 1 };
    assert((await difference(f)).differing.length === 1, 'counterpart clipping also needs complete render containment');
  });
  await check('material/glass children never lose their existing surface descriptors', async () => {
    for (const name of ['material', 'glass']) {
      const f = fixture();
      append(f.content, node('RECTANGLE', { name, width: 5, height: 5, fills: [{ type: 'SOLID', color: { r: 1, g: 0, b: 0 } }] }));
      equal(await projected(f), await raw(f), `${name} must retain the existing surface reader`);
    }
  });
  await check('a different variant never supplies a geometry witness', async () => {
    const f = fixture(); f.copyRoot.name = 'Enabled=false, Layout=vertical';
    equal(await projected(f), await raw(f), 'same geometry in an unpaired variant does not authorize projection');
  });
  await check('duplicate identical painted leaves preserve their multiplicity', async () => {
    const f = fixture();
    append(f.content, node('TEXT', { characters: 'Title', name: 'Title', width: 45, height: 22, fills: f.content.children[0].fills }));
    append(f.flat, node('TEXT', { characters: 'Title', name: 'Title', x: 0, y: 1, width: 45, height: 22, fills: f.flat.children[0].fills }));
    const leaves = Object.values(await projected(f)).flat();
    assert((await difference(f)).differing.length === 0, 'equivalent duplicate leaves still compare');
    assert(leaves.filter(l => l.startsWith('text "Title"')).length === 2, 'retain both identical descriptors');
  });
  await check('reading frozen source nodes and binding maps performs no writes', async () => {
    const f = fixture();
    const freeze = (n: Node): void => {
      for (const child of n.children) freeze(child);
      Object.freeze(n.children); Object.freeze(n.boundVariables); Object.freeze(n);
    };
    freeze(f.source); freeze(f.copy);
    assert((await difference(f)).differing.length === 0, 'projection works entirely on virtual values');
  });
  await check('bindings, references, identities and manual-edit fingerprint are untouched', async () => {
    const f = fixture();
    variables.set('space', { variableCollectionId: 'spacing' });
    f.outer.resolvedVariableModes = f.content.resolvedVariableModes = { spacing: 'normal' };
    f.content.boundVariables = { paddingBottom: { type: 'VARIABLE_ALIAS', id: 'space' } };
    f.source.componentPropertyDefinitions = { Enabled: { type: 'VARIANT', defaultValue: 'true' } };
    const refs = [f.outer, f.content, f.content.children[0], f.source.componentPropertyDefinitions, f.content.boundVariables];
    const before = await fingerprintNode(setNode(f.source));
    assert((await difference(f)).differing.length === 0, 'literal copy can witness the same authored bound inset');
    equal([f.outer, f.content, f.content.children[0], f.source.componentPropertyDefinitions, f.content.boundVariables].map((x, i) => x === refs[i]),
      [true, true, true, true, true], 'no replacements or binding/property writes');
    equal(await fingerprintNode(setNode(f.source)), before, 'reading never changes fingerprint');
    f.outer.paddingTop++;
    assert(await fingerprintNode(setNode(f.source)) !== before, 'authored/manual edit still changes fingerprint');
    assert(await fingerprintNode(setNode(f.source)) !== await fingerprintNode(setNode(f.copy)), 'fingerprint retains structural distinction');
  });
  await check('unused inherited mode entries and glyph raster bounds do not define layout equality', async () => {
    const f = fixture();
    f.outer.resolvedVariableModes = f.content.resolvedVariableModes = { unused: 'extra' };
    f.content.children[0].renderOverride = { width: 44.0000457763671875 };
    f.flat.children[0].renderOverride = { width: 44 };
    assert((await difference(f)).differing.length === 0, 'exact layout boxes and strict contained rendering suffice');
  });
  await check('used variable modes cannot disappear or change on a counterpart', async () => {
    variables.set('ink', { variableCollectionId: 'colors' });
    for (const mode of [undefined, 'dark']) {
      const f = fixture();
      for (const text of [f.content.children[0], f.flat.children[0]]) {
        text.boundVariables = { fontSize: [{ type: 'VARIABLE_ALIAS', id: 'ink' }] };
        text.resolvedVariableModes = { colors: 'light' };
      }
      f.flat.children[0].resolvedVariableModes = mode == null ? {} : { colors: mode };
      assert((await difference(f)).differing.length === 1, 'a referenced collection missing a mode or changing mode rejects equivalence');
    }
    const f = fixture(); f.content.children[0].boundVariables = { fontSize: [{ type: 'VARIABLE_ALIAS', id: 'unknown' }] };
    assert(await layoutInsetWitness(scene(f.outer), scene(f.root)) == null, 'missing variable metadata rejects');
  });
  await check('mode comparison is symmetric for every shared used collection', () => {
    const a = { geometry: 'g', usedModes: new Map([['c', 'light']]) };
    const b = { geometry: 'g', usedModes: new Map([['c', 'dark'], ['unused-on-other', 'x']]) };
    assert(!matchesLayoutInsetWitness(a, b) && !matchesLayoutInsetWitness(b, a), 'shared mismatch fails both directions');
  });
  await check('member pairing/rename/conflicts and enabled semantics remain official', async () => {
    const f = fixture(); f.copyRoot.name = 'Disabled=false, Layout=vertical';
    const table = [{ component: f.source.name, from: f.copyRoot.name, to: f.root.name, reason: '' }];
    const page = node('PAGE', { name: 'test', children: [f.source, f.copy] });
    const report = (await parityReport(setNode(f.source), page as PageNode, undefined, table)).report;
    equal([report.compared, report.differing.length, report.renamed?.length], [1, 0, 1], 'old disabled false maps to enabled true');
    const currentCopy = node('COMPONENT', { name: f.root.name });
    append(f.copy, currentCopy);
    const conflict = (await parityReport(setNode(f.source), page as PageNode, undefined, table)).report;
    assert(conflict.renameConflicts?.length === 1 && conflict.onlyDesigner.length === 1, 'conflicting old member stays separate');
    const g = await raw(f), d = await readVariantLeaves(setNode(f.copy));
    assert(renameCopyVariants(d, g, table).conflicts.length === 1, 'no independent pairing override');
    f.copy.children = [];
    assert((await difference(f)).onlyGenerated.length === 1, 'missing member remains missing');
  });
  if (failures) throw Error(`${failures}/${checks} inset projection checks failed`);
  console.log(`✅ layout-inset projection: ${checks} checks passed`);
}
