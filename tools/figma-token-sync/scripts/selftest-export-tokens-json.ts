import { exportDartTokens } from '../src/export-dart';
import { buildTokenDoc, fingerprintCollections } from '../src/export-tokens-json';
import { importTokens, TokenDoc } from '../src/import-tokens';

// Selftest for the JSON half of the token export (kobic#12993). Pure logic
// driven by fixtures — no Figma sandbox, so it runs under plain Node.
//
// What it holds in place, beyond "a file comes out":
//
//   * the emitted `alias` strings are the exact keys `importTokens` indexes
//     by, including when a collection name contains `/`. That is the one
//     field where being wrong is silent — an unresolvable alias imports as a
//     name with no value, and the log line scrolls past.
//   * the fingerprint actually changes when the tokens change. A digest that
//     never moves would pass every equality check while proving nothing, so
//     the mutation is injected here and asserted to take.
//   * counts are asserted alongside the content. A fixture that stops
//     producing collections would otherwise satisfy every `every(...)` below
//     vacuously (kobic#10891).

interface FakeMode {
  modeId: string;
  name: string;
}
interface FakeColl {
  id: string;
  name: string;
  modes: FakeMode[];
}
interface FakeVar {
  id: string;
  name: string;
  variableCollectionId: string;
  resolvedType: string;
  valuesByMode: Record<string, unknown>;
  description?: string;
  scopes?: string[];
  hiddenFromPublishing?: boolean;
}

function installFigma(colls: FakeColl[], vars: FakeVar[]) {
  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => colls,
      getLocalVariablesAsync: async () => vars,
    },
  };
}

function build(colls: FakeColl[], vars: FakeVar[]) {
  return buildTokenDoc(colls as any, vars as any);
}

const ONE_MODE = [{ modeId: 'm1', name: 'Value' }];
const TWO_MODES = [
  { modeId: 'm1', name: 'Light' },
  { modeId: 'm2', name: 'Dark' },
];

function float(id: string, coll: string, name: string, value: number): FakeVar {
  return {
    id,
    name,
    variableCollectionId: coll,
    resolvedType: 'FLOAT',
    valuesByMode: { m1: value },
  };
}

let failures = 0;
function check(label: string, cond: boolean, detail?: string) {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    console.log(`  ✗ ${label}${detail ? ' — ' + detail : ''}`);
    failures++;
  }
}

async function main() {
  // ── 1. both artefacts come out of one call ───────────────────────────
  //
  // The pairing is the point: a drift test compares them, so they cannot be
  // two separate reads of a document a designer can edit in between.
  installFigma(
    [{ id: 'c0', name: '0. Primitives', modes: ONE_MODE }],
    [float('v0', 'c0', 'space/16', 16)],
  );
  let out = await exportDartTokens();
  console.log('both artefacts, one snapshot');
  check('two files emitted', out.files.length === 2, out.files.map((f) => f.name).join(', '));
  check('dart stays at files[0]', out.files[0].name === 'figma_tokens.g.dart');
  check('json is files[1]', out.files[1].name === 'tokens.figma.json');

  const doc = JSON.parse(out.files[1].content);
  const headerMatch = /export ([0-9a-f]{8})\)/.exec(out.files[0].content);
  check('dart header carries a fingerprint', headerMatch !== null, out.files[0].content.slice(0, 200));
  check(
    'the two fingerprints are equal — the pair is checkable, not assumed',
    headerMatch !== null && headerMatch[1] === doc.meta.export,
    `dart=${headerMatch && headerMatch[1]} json=${doc.meta.export}`,
  );
  check('meta counts what it emitted', doc.meta.collections === 1 && doc.meta.variables === 1, JSON.stringify(doc.meta));

  // ── 2. the shape importTokens reads ──────────────────────────────────
  console.log('import contract');
  check('collection keeps its Figma name, prefix and all', doc.collections[0].name === '0. Primitives');
  check('modes are names', JSON.stringify(doc.collections[0].modes) === '["Value"]');
  check(
    'values are keyed by mode name, not modeId',
    Object.keys(doc.collections[0].variables[0].valuesByMode).join() === 'Value',
    JSON.stringify(doc.collections[0].variables[0].valuesByMode),
  );

  // ── 3. aliases resolve to the key importTokens indexes by ────────────
  //
  // `importTokens` does `byPath.get(alias)` on `${collection}/${name}` — a
  // whole-string Map lookup, no splitting. A collection name holding a `/`
  // ("Semantic/ Color · CoUI" is one in CoUI DS v1.0) is therefore fine,
  // but only if the exporter writes the same undivided string.
  installFigma(
    [
      { id: 'c0', name: '0. Primitives', modes: ONE_MODE },
      { id: 'c1', name: '1-1. Semantic/ Color · CoUI', modes: ONE_MODE },
    ],
    [
      {
        id: 'v0',
        name: 'color/neutral/white',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { m1: { r: 1, g: 1, b: 1, a: 1 } },
      },
      {
        id: 'v1',
        name: 'surface',
        variableCollectionId: 'c1',
        resolvedType: 'COLOR',
        valuesByMode: { m1: { type: 'VARIABLE_ALIAS', id: 'v0' } },
      },
    ],
  );
  out = await exportDartTokens();
  const aliased = JSON.parse(out.files[1].content);
  console.log('alias paths');
  const surface = aliased.collections[1].variables[0];
  check(
    'alias is `<Collection>/<name>` with the slash-bearing name intact',
    surface.valuesByMode.Value.alias === '0. Primitives/color/neutral/white',
    JSON.stringify(surface.valuesByMode),
  );
  check(
    'colors are {r,g,b,a}',
    JSON.stringify(aliased.collections[0].variables[0].valuesByMode.Value) ===
      '{"r":1,"g":1,"b":1,"a":1}',
    JSON.stringify(aliased.collections[0].variables[0].valuesByMode.Value),
  );

  // Every alias must name something this same document defines — otherwise
  // the import silently lands a variable with no value.
  const paths = new Set<string>();
  for (const c of aliased.collections) {
    for (const v of c.variables) paths.add(`${c.name}/${v.name}`);
  }
  let aliasCount = 0;
  let danglingCount = 0;
  for (const c of aliased.collections) {
    for (const v of c.variables) {
      for (const key of Object.keys(v.valuesByMode)) {
        const val = v.valuesByMode[key];
        if (val && typeof val === 'object' && 'alias' in val) {
          aliasCount++;
          if (!paths.has(val.alias)) danglingCount++;
        }
      }
    }
  }
  check('every alias resolves within the document', danglingCount === 0, `${danglingCount} dangling`);
  check('and there was an alias to check', aliasCount === 1, `${aliasCount} aliases`);

  // ── 4. modes: absent stays absent, present is per-mode ───────────────
  installFigma(
    [{ id: 'c0', name: 'Semantic', modes: TWO_MODES }],
    [
      {
        id: 'v0',
        name: 'surface',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { m1: { r: 1, g: 1, b: 1, a: 1 }, m2: { r: 0, g: 0, b: 0, a: 1 } },
      },
      // Only the first mode has a value. Writing a placeholder for the other
      // would import as a real value over whatever the file holds.
      float('v1', 'c0', 'space/8', 8),
    ],
  );
  const modal = build(
    [{ id: 'c0', name: 'Semantic', modes: TWO_MODES }],
    [
      {
        id: 'v0',
        name: 'surface',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { m1: { r: 1, g: 1, b: 1, a: 1 }, m2: { r: 0, g: 0, b: 0, a: 1 } },
      },
      float('v1', 'c0', 'space/8', 8),
    ],
  );
  console.log('modes');
  const vars = modal.collections[0].variables;
  check('both collection modes are listed', JSON.stringify(modal.collections[0].modes) === '["Light","Dark"]');
  check(
    'a two-mode variable emits both',
    Object.keys(vars[1].valuesByMode).join() === 'Light,Dark',
    JSON.stringify(vars[1].valuesByMode),
  );
  check(
    'a mode with no value is absent, not null',
    Object.keys(vars[0].valuesByMode).join() === 'Light',
    JSON.stringify(vars[0].valuesByMode),
  );

  // ── 5. an unresolvable alias is dropped AND reported ─────────────────
  //
  // Dropping it quietly is the failure mode this guards: the variable would
  // arrive named but valueless, and nothing would say why.
  installFigma(
    [{ id: 'c0', name: 'Semantic', modes: ONE_MODE }],
    [
      {
        id: 'v0',
        name: 'surface',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { m1: { type: 'VARIABLE_ALIAS', id: 'external-library-id' } },
      },
      float('v1', 'c0', 'space/8', 8),
    ],
  );
  out = await exportDartTokens();
  const partial = JSON.parse(out.files[1].content);
  console.log('unresolvable alias');
  check(
    'the variable is not emitted valueless',
    partial.collections[0].variables.length === 1 &&
      partial.collections[0].variables[0].name === 'space/8',
    JSON.stringify(partial.collections[0].variables),
  );
  check(
    'and the drop is reported',
    out.log.some((l) => l.indexOf('! skipped') === 0 && l.indexOf('surface') >= 0),
    out.log.join(' | '),
  );
  check(
    'reported once, not once per pass',
    out.log.filter((l) => l.indexOf('! skipped') === 0).length === 1,
    out.log.join(' | '),
  );

  // ── 6. description and scopes survive; the default scope does not ────
  console.log('description / scopes');
  const meta = build(
    [{ id: 'c0', name: 'Primitives', modes: ONE_MODE }],
    [
      { ...float('v0', 'c0', 'space/16', 16), description: '기본 간격' },
      { ...float('v1', 'c0', 'radius/8', 8), scopes: ['CORNER_RADIUS'] },
      { ...float('v2', 'c0', 'size/24', 24), scopes: ['ALL_SCOPES'] },
    ],
  );
  const byName: Record<string, any> = {};
  for (const v of meta.collections[0].variables) byName[v.name] = v;
  check('description is carried', byName['space/16'].description === '기본 간격');
  check('a narrowed scope is carried', JSON.stringify(byName['radius/8'].scopes) === '["CORNER_RADIUS"]');
  check(
    'ALL_SCOPES is omitted — it is the default a new variable already gets',
    byName['size/24'].scopes === undefined,
    JSON.stringify(byName['size/24']),
  );

  // ── 6b. publish visibility round-trips, and the importer writes it ───
  //
  // The exporter stamps `hiddenFromPublishing` on brand colour ramps no
  // Semantic slot reads (`_stampRampPublishVisibility` in
  // export_figma_tokens.dart). The flag only means something if Import
  // actually writes it — including onto a variable Import itself creates,
  // which is exactly the case a hand-set flag in the file never covered.
  console.log('publish visibility');
  const vis = build(
    [{ id: 'c0', name: 'Primitives', modes: ONE_MODE }],
    [
      { ...float('v0', 'c0', 'color/a', 1), hiddenFromPublishing: true },
      { ...float('v1', 'c0', 'color/b', 1), hiddenFromPublishing: false },
    ],
  );
  const visByName: Record<string, any> = {};
  for (const v of vis.collections[0].variables) visByName[v.name] = v;
  check('a hidden variable carries the flag', visByName['color/a'].hiddenFromPublishing === true);
  check(
    'a published variable carries no key — false is the default a new variable already gets',
    !('hiddenFromPublishing' in visByName['color/b']),
    JSON.stringify(visByName['color/b']),
  );

  type LiveVar = {
    id: string;
    name: string;
    variableCollectionId: string;
    resolvedType: string;
    description: string;
    scopes: string[];
    hiddenFromPublishing: boolean;
    setValueForMode: (modeId: string, value: unknown) => void;
  };
  const liveVar = (id: string, name: string, hidden: boolean): LiveVar => ({
    id,
    name,
    variableCollectionId: 'c0',
    resolvedType: 'FLOAT',
    description: '',
    scopes: ['ALL_SCOPES'],
    hiddenFromPublishing: hidden,
    setValueForMode: () => {},
  });
  const live: LiveVar[] = [
    liveVar('b', 'color/b', true),
    liveVar('c', 'color/c', true),
    liveVar('d', 'color/d', false),
  ];
  const liveColl = {
    id: 'c0',
    name: 'Primitives',
    modes: ONE_MODE,
    renameMode: () => {},
    addMode: () => {},
  };
  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => [liveColl],
      getLocalVariablesAsync: async () => live.slice(),
      createVariable: (name: string, coll: { id: string }, type: string) => {
        const v = liveVar(`new-${name}`, name, false);
        v.variableCollectionId = coll.id;
        v.resolvedType = type;
        live.push(v);
        return v;
      },
    },
    // A document with no effect styles: the shadow-style pass has nothing to bind.
    getLocalEffectStylesAsync: async () => [],
  };
  const visDoc: TokenDoc = {
    collections: [
      {
        name: 'Primitives',
        modes: ['Value'],
        variables: [
          // Created by this Import — the case a hand-set flag never reached.
          { name: 'color/a', type: 'FLOAT', valuesByMode: { Value: 1 }, hiddenFromPublishing: true },
          // A ramp a brand starts reading: the explicit false un-hides it.
          { name: 'color/b', type: 'FLOAT', valuesByMode: { Value: 1 }, hiddenFromPublishing: false },
          // No key: the file's own flag stays in charge.
          { name: 'color/c', type: 'FLOAT', valuesByMode: { Value: 1 } },
          // Already matches: not a change, not counted.
          { name: 'color/d', type: 'FLOAT', valuesByMode: { Value: 1 }, hiddenFromPublishing: false },
        ],
      },
    ],
  };
  const visLog = await importTokens(visDoc);
  const liveByName: Record<string, LiveVar> = {};
  for (const v of live) liveByName[v.name] = v;
  check('the fixture ran — Import created the missing variable', liveByName['color/a'] != null);
  check(
    'a variable Import creates is hidden when the spec says so',
    liveByName['color/a']?.hiddenFromPublishing === true,
  );
  check('an explicit false un-hides a hidden variable', liveByName['color/b'].hiddenFromPublishing === false);
  check('a spec with no key leaves the file flag alone', liveByName['color/c'].hiddenFromPublishing === true);
  check('a matching flag stays as it is', liveByName['color/d'].hiddenFromPublishing === false);
  check(
    'the log counts exactly the two variables whose visibility changed',
    visLog.some((l) => l === '✓ publish visibility: 2 variable(s) changed'),
    visLog.join(' | '),
  );

  // ── 6b. the document's shadow styles are rebuilt from the surface-style casts ──
  //
  // A component wearing `shadow/md` follows the surface style its frame pins
  // only when the style's layers are bound to the `Semantic/ Surface` rows
  // the style bends. The pass creates no style; it rebuilds the ones the
  // document has to the layers the code exports — one per `<i>/x` row, each
  // followed by its mirror, inset when no mirror rows exist — so a step that
  // lost a layer in the code loses it in the file too, even while the old
  // layer's variables linger (Import never deletes). A re-Import gives the
  // same layers.
  console.log('shadow styles');
  {
    const styleModes = ['defaultStyle', 'neumorphism'];
    let nextId = 0;
    type SVar = { id: string; name: string; variableCollectionId: string; resolvedType: string;
      valuesByMode: Record<string, unknown>; description: string; scopes: string[];
      setValueForMode: (m: string, v: unknown) => void };
    const svars: SVar[] = [];
    const scolls: { id: string; name: string; modes: FakeMode[]; renameMode: (id: string, n: string) => void; addMode: (n: string) => string }[] = [];
    const mkColl = (name: string) => {
      const c = {
        id: `sc${nextId++}`,
        name,
        modes: [{ modeId: `sm${nextId++}`, name: 'Mode 1' }],
        renameMode(id: string, n: string) { const m = this.modes.find((x) => x.modeId === id); if (m) m.name = n; },
        addMode(n: string) { const id = `sm${nextId++}`; this.modes.push({ modeId: id, name: n }); return id; },
      };
      scolls.push(c);
      return c;
    };
    const mkVar = (name: string, coll: { id: string }, type: string): SVar => {
      const v: SVar = { id: `sv${nextId++}`, name, variableCollectionId: coll.id, resolvedType: type,
        valuesByMode: {}, description: '', scopes: ['ALL_SCOPES'],
        setValueForMode(m: string, val: unknown) { this.valuesByMode[m] = val; } };
      svars.push(v);
      return v;
    };
    type Shadow = { type: string; color: { r: number; g: number; b: number; a: number }; offset: { x: number; y: number };
      radius: number; spread: number; visible: boolean; blendMode: string; boundVariables?: Record<string, { id: string }> };
    const layer = (y: number, blur: number, spread: number, a: number): Shadow => ({
      type: 'DROP_SHADOW', color: { r: 0, g: 0, b: 0, a }, offset: { x: 0, y }, radius: blur, spread, visible: true, blendMode: 'NORMAL',
    });
    // The file's styles as an older export left them: md two layers deep.
    const md = { name: 'shadow/md', effects: [layer(4, 8, -2, 0.06), layer(2, 4, -1, 0.04)] as Shadow[] };
    const inset = { name: 'shadow/inset', effects: [layer(1, 1, 0, 0.5)] as Shadow[] };
    const orphan = { name: 'shadow/9xl', effects: [layer(40, 80, 0, 0.1)] as Shadow[] };
    // The old second layer's variables are still in the file.
    const surface = mkColl('Semantic/ Surface');
    const leftover = mkVar('shadow/md/1/x', surface, 'FLOAT');
    (globalThis as any).figma = {
      variables: {
        getLocalVariableCollectionsAsync: async () => scolls,
        getLocalVariablesAsync: async () => svars.slice(),
        createVariableCollection: (name: string) => mkColl(name),
        createVariable: (name: string, coll: { id: string }, type: string) => mkVar(name, coll, type),
        createVariableAlias: (v: { id: string }) => ({ type: 'VARIABLE_ALIAS', id: v.id }),
        setBoundVariableForEffect: (e: Shadow, field: string, v: { id: string }) =>
          ({ ...e, boundVariables: { ...(e.boundVariables ?? {}), [field]: { type: 'VARIABLE_ALIAS', id: v.id } } }),
      },
      getLocalEffectStylesAsync: async () => [md, inset, orphan],
    };
    const rows: TokenDoc['collections'][number]['variables'] = [];
    const values = { x: 0, y: 8, blur: 24, spread: 0 } as Record<string, number>;
    for (const l of ['0', '0-mirror']) {
      for (const f of ['x', 'y', 'blur']) {
        const v = l === '0' ? values[f] : -values[f];
        rows.push({ name: `shadow/md/${l}/${f}`, type: 'FLOAT', valuesByMode: { defaultStyle: v, neumorphism: v * 2 } });
      }
      rows.push({ name: `shadow/md/${l}/color`, type: 'COLOR',
        valuesByMode: { defaultStyle: { r: 0, g: 0, b: 0, a: l === '0' ? 0.1 : 0 }, neumorphism: { r: 1, g: 1, b: 1, a: 0.1 } } });
    }
    rows.push({ name: 'shadow/md/0/spread', type: 'FLOAT', valuesByMode: { defaultStyle: -1, neumorphism: -1 } });
    for (const f of ['x', 'y', 'blur', 'spread']) {
      rows.push({ name: `shadow/inset/0/${f}`, type: 'FLOAT', valuesByMode: { defaultStyle: f === 'y' ? 2 : 0, neumorphism: 0 } });
    }
    rows.push({ name: 'shadow/inset/0/color', type: 'COLOR',
      valuesByMode: { defaultStyle: { r: 0, g: 0, b: 0, a: 0.06 }, neumorphism: { r: 0, g: 0, b: 0, a: 0.06 } } });
    // A surface style's material carries one BOOLEAN — whether a role's glass
    // layer shows — and Import creates it as one, with a boolean per mode and
    // no scope to narrow.
    rows.push({ name: 'material/content/glass', type: 'BOOLEAN', valuesByMode: { defaultStyle: false, neumorphism: true } });
    const shadowDoc: TokenDoc = { collections: [{ name: 'Semantic/ Surface', modes: styleModes, variables: rows }] };
    const first = await importTokens(shadowDoc);
    const glassRow = svars.find((v) => v.name === 'material/content/glass');
    const surfaceModes = scolls.find((c) => c.name === 'Semantic/ Surface')?.modes ?? [];
    const glassByMode = Object.fromEntries(
      surfaceModes.map((m) => [m.name, glassRow?.valuesByMode[m.modeId]]),
    );
    check(
      'a BOOLEAN row is created as a BOOLEAN, with each mode its own boolean',
      glassRow?.resolvedType === 'BOOLEAN' &&
        glassByMode.defaultStyle === false &&
        glassByMode.neumorphism === true,
      JSON.stringify({ type: glassRow?.resolvedType, glassByMode }),
    );
    check('a BOOLEAN row keeps the scope a new variable gets', JSON.stringify(glassRow?.scopes) === '["ALL_SCOPES"]');
    const byId = new Map(svars.map((v) => [v.id, v.name]));
    const names = (e: Shadow) => Object.fromEntries(Object.entries(e.boundVariables ?? {}).map(([k, v]) => [k, byId.get(v.id)]));
    check(
      'a style is rebuilt to the exported layers — one cast and its mirror, the old second layer gone',
      md.effects.length === 2 && md.effects.every((e) => e.type === 'DROP_SHADOW'),
      JSON.stringify(md.effects.map((e) => e.type)),
    );
    check(
      'each layer binds offset, blur, spread and colour to its own rows; the mirror shares the cast spread',
      JSON.stringify(md.effects.map(names)) ===
        JSON.stringify(['0', '0-mirror'].map((l) => ({
          offsetX: `shadow/md/${l}/x`, offsetY: `shadow/md/${l}/y`, radius: `shadow/md/${l}/blur`,
          spread: 'shadow/md/0/spread', color: `shadow/md/${l}/color`,
        }))),
      JSON.stringify(md.effects.map(names)),
    );
    check(
      'the layer holds the first mode\'s values, so the style reads as what its rows say',
      md.effects[0].offset.y === 8 && md.effects[0].radius === 24 && md.effects[0].spread === -1 &&
        md.effects[0].color.a === 0.1 && md.effects[1].offset.y === -8 && md.effects[1].spread === -1,
      JSON.stringify(md.effects[0]),
    );
    check('a mirror draws nothing at rest', md.effects[1].color.a === 0);
    check('a leftover variable from an old layer is not bound', !md.effects.some((e) => Object.values(e.boundVariables ?? {}).some((b) => b.id === leftover.id)));
    check(
      'a step with no mirror rows is one inner shadow',
      inset.effects.length === 1 && inset.effects[0].type === 'INNER_SHADOW' && inset.effects[0].offset.y === 2,
      JSON.stringify(inset.effects),
    );
    check('a style with no rows is left alone', orphan.effects.length === 1 && orphan.effects[0].boundVariables == null);
    check(
      'the log counts the rebuilt styles and names the one left alone',
      first.includes('✓ shadow styles: 2 rebuilt from Semantic/ Surface casts') &&
        first.some((l) => l.startsWith('! shadow styles left as they were') && l.includes('shadow/9xl')),
      first.join(' | '),
    );
    await importTokens(shadowDoc);
    check('a re-Import gives the same layers', md.effects.length === 2 && inset.effects.length === 1, String(md.effects.length));
  }

  // ── 7. determinism, and a fingerprint that actually moves ────────────
  //
  // Equal-fingerprint assertions are only worth anything if an unequal input
  // produces an unequal fingerprint. The mutation is injected and asserted to
  // have taken (kobic mutation-testing-validity M-2) — a patch that silently
  // failed to apply would leave this check passing for the wrong reason.
  console.log('fingerprint');
  const colls: FakeColl[] = [{ id: 'c0', name: 'Primitives', modes: ONE_MODE }];
  const base: FakeVar[] = [float('v0', 'c0', 'space/16', 16)];
  const a = fingerprintCollections(build(colls, base).collections);
  const b = fingerprintCollections(build(colls, base).collections);
  check('same input, same fingerprint', a === b, `${a} vs ${b}`);

  const mutated: FakeVar[] = [float('v0', 'c0', 'space/16', 17)];
  const beforeJson = JSON.stringify(build(colls, base).collections);
  const afterJson = JSON.stringify(build(colls, mutated).collections);
  check('the mutation was actually injected', beforeJson !== afterJson);
  const c = fingerprintCollections(build(colls, mutated).collections);
  check('one changed value changes the fingerprint', a !== c, `${a} vs ${c}`);

  // Variable order must not be a source of churn: re-exporting an unchanged
  // file should produce an unchanged diff even if Figma hands them back in
  // another order.
  const shuffled: FakeVar[] = [float('v1', 'c0', 'b/2', 2), float('v0', 'c0', 'a/1', 1)];
  const ordered: FakeVar[] = [float('v0', 'c0', 'a/1', 1), float('v1', 'c0', 'b/2', 2)];
  check(
    'input order does not change the output',
    fingerprintCollections(build(colls, shuffled).collections) ===
      fingerprintCollections(build(colls, ordered).collections),
  );

  // Derived paint aliases are not independent Core tokens. Both exports must
  // report the unsupported v1 shape instead of emitting undefined/NaN channels.
  const composed: FakeVar = {
    id: 'opacity', name: 'color/surface/opacity/88', variableCollectionId: 'semantic', resolvedType: 'COLOR',
    valuesByMode: { m1: { color: { type: 'VARIABLE_ALIAS', id: 'base' }, opacity: 88 } },
  };
  installFigma([{ id: 'semantic', name: 'Semantic', modes: ONE_MODE }], [composed]);
  const composedOut = await exportDartTokens();
  check('composed color is explicitly reported by export', composedOut.log.some((line) => line.includes('composed color')));
  check('composed color does not emit invalid channels', composedOut.files.every((file) => !/NaN|undefined/.test(file.content)));

  console.log(
    failures === 0 ? '\n✅ export-tokens-json selftest passed' : `\n❌ ${failures} check(s) failed`,
  );
  process.exit(failures > 0 ? 1 : 0);
}

main();
