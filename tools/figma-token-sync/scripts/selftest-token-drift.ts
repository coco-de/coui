import { checkTokenDrift } from '../src/token-drift';

// Minimal Figma double: only what checkTokenDrift touches.
interface FakeVar { id: string; name: string; valuesByMode: Record<string, unknown>; }
interface FakeColl { name: string; modes: { modeId: string; name: string }[]; variableIds: string[]; }

function installFigma(colls: FakeColl[], vars: FakeVar[]) {
  const byId = new Map(vars.map((v) => [v.id, v]));
  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => colls,
      getVariableByIdAsync: async (id: string) => byId.get(id) ?? null,
    },
  };
}

let failures = 0;
function check(label: string, cond: boolean, detail?: string) {
  if (cond) { console.log(`  ✓ ${label}`); }
  else { console.log(`  ✗ ${label}${detail ? ' — ' + detail : ''}`); failures++; }
}

async function main() {
  // ── 1. clean file: no drift ──────────────────────────────────────────
  installFigma(
    [{ name: '0. Primitives', modes: [{ modeId: 'm1', name: 'Value' }], variableIds: ['v1'] }],
    [{ id: 'v1', name: 'opacity/50', valuesByMode: { m1: 50 } }],
  );
  let r = await checkTokenDrift({
    collections: [{ name: '0. Primitives', modes: ['Value'], variables: [
      { name: 'opacity/50', type: 'FLOAT', valuesByMode: { Value: 50 } },
    ] }],
  });
  console.log('clean file');
  check('no missing', r.missing.length === 0);
  check('no extra', r.extra.length === 0);
  check('no value drift', r.valueDrift.length === 0);
  check('log says clean', r.log[0].includes('드리프트 없음'), r.log[0]);

  // ── 2. the opacity bug: same name, value off by 100x ─────────────────
  installFigma(
    [{ name: '0. Primitives', modes: [{ modeId: 'm1', name: 'Value' }], variableIds: ['v1'] }],
    [{ id: 'v1', name: 'opacity/50', valuesByMode: { m1: 0.5 } }],
  );
  r = await checkTokenDrift({
    collections: [{ name: '0. Primitives', modes: ['Value'], variables: [
      { name: 'opacity/50', type: 'FLOAT', valuesByMode: { Value: 50 } },
    ] }],
  });
  console.log('opacity 100x drift');
  check('detected as value drift', r.valueDrift.length === 1, JSON.stringify(r.valueDrift));
  check('names both sides', r.valueDrift[0].includes('export 50') && r.valueDrift[0].includes('live 0.5'), r.valueDrift[0]);

  // ── 3. the focus-ring bug: declared, absent live ─────────────────────
  installFigma(
    [{ name: '1-1. Semantic/ Color · CoUI', modes: [{ modeId: 'm1', name: 'Light' }], variableIds: ['v1'] }],
    [{ id: 'v1', name: 'color/primary', valuesByMode: { m1: { r: 0, g: 0, b: 0, a: 1 } } }],
  );
  r = await checkTokenDrift({
    collections: [{ name: '1-1. Semantic/ Color · CoUI', modes: ['Light'], variables: [
      { name: 'color/primary', type: 'COLOR', valuesByMode: { Light: { r: 0, g: 0, b: 0, a: 1 } } },
      { name: 'color/focus-ring', type: 'COLOR', valuesByMode: { Light: { r: 0, g: 0, b: 0, a: 1 } } },
    ] }],
  });
  console.log('missing variable');
  check('detected as missing', r.missing.length === 1, JSON.stringify(r.missing));
  check('key is VarLookup-shaped', r.missing[0] === 'Semantic/color/focus-ring', r.missing[0]);

  // ── 4. live-only variable ────────────────────────────────────────────
  installFigma(
    [{ name: '2. Component', modes: [{ modeId: 'm1', name: 'Value' }], variableIds: ['v1', 'v2'] }],
    [
      { id: 'v1', name: 'icon-size/16', valuesByMode: { m1: 16 } },
      { id: 'v2', name: 'toggle/thumb-md', valuesByMode: { m1: 18 } },
    ],
  );
  r = await checkTokenDrift({
    collections: [{ name: '2. Component', modes: ['Value'], variables: [
      { name: 'icon-size/16', type: 'FLOAT', valuesByMode: { Value: 16 } },
    ] }],
  });
  console.log('live-only variable');
  check('detected as extra', r.extra.length === 1 && r.extra[0] === 'Component/toggle/thumb-md', JSON.stringify(r.extra));
  check('not reported as missing', r.missing.length === 0);

  // ── 5. alias compared by path, not id ────────────────────────────────
  installFigma(
    [
      { name: '0. Primitives', modes: [{ modeId: 'm0', name: 'Value' }], variableIds: ['p1'] },
      { name: '1-1. Semantic/ Color · CoUI', modes: [{ modeId: 'm1', name: 'Light' }], variableIds: ['v1'] },
    ],
    [
      { id: 'p1', name: 'color/coui/neutral/black', valuesByMode: { m0: { r: 0, g: 0, b: 0, a: 1 } } },
      { id: 'v1', name: 'color/primary', valuesByMode: { m1: { type: 'VARIABLE_ALIAS', id: 'p1' } } },
    ],
  );
  r = await checkTokenDrift({
    collections: [{ name: '1-1. Semantic/ Color · CoUI', modes: ['Light'], variables: [
      { name: 'color/primary', type: 'COLOR', valuesByMode: { Light: { alias: '0. Primitives/color/coui/neutral/black' } } },
    ] }],
  });
  console.log('matching alias');
  check('no false drift on alias', r.valueDrift.length === 0, JSON.stringify(r.valueDrift));

  // ── 6. alias pointing somewhere else IS drift ────────────────────────
  r = await checkTokenDrift({
    collections: [{ name: '1-1. Semantic/ Color · CoUI', modes: ['Light'], variables: [
      { name: 'color/primary', type: 'COLOR', valuesByMode: { Light: { alias: '0. Primitives/color/coui/neutral/white' } } },
    ] }],
  });
  console.log('alias pointing elsewhere');
  check('detected as drift', r.valueDrift.length === 1, JSON.stringify(r.valueDrift));

  // ── 6b. alias into a collection whose NAME contains slashes ──────────
  //
  // Regression: the first version split the alias path at its first `/`,
  // which lands inside `"1-1. Semantic/ Color · CoUI"` rather than between
  // collection and variable. Every cross-collection alias then reported as
  // drifted. The unit tests above all used slash-free collection names and
  // passed; running against the real file is what caught it.
  installFigma(
    [
      { name: '1-1. Semantic/ Color · CoUI', modes: [{ modeId: 'mc', name: 'Light' }], variableIds: ['c1'] },
      { name: '1-4. Semantic/ Effect', modes: [{ modeId: 'me', name: 'Value' }], variableIds: ['e1'] },
    ],
    [
      { id: 'c1', name: 'color/primary', valuesByMode: { mc: { r: 0, g: 0, b: 0, a: 1 } } },
      { id: 'e1', name: 'focus-ring/color', valuesByMode: { me: { type: 'VARIABLE_ALIAS', id: 'c1' } } },
    ],
  );
  r = await checkTokenDrift({
    collections: [{ name: '1-4. Semantic/ Effect', modes: ['Value'], variables: [
      { name: 'focus-ring/color', type: 'COLOR', valuesByMode: { Value: { alias: '1-1. Semantic/ Color · CoUI/color/primary' } } },
    ] }],
  });
  console.log('alias into slash-containing collection name');
  check('no false drift', r.valueDrift.length === 0, JSON.stringify(r.valueDrift));

  // ── 7. float round-trip noise is NOT drift ───────────────────────────
  installFigma(
    [{ name: '0. Primitives', modes: [{ modeId: 'm1', name: 'Value' }], variableIds: ['v1'] }],
    [{ id: 'v1', name: 'color/x', valuesByMode: { m1: { r: 0.5000000074505806, g: 0.5, b: 0.5, a: 1 } } }],
  );
  r = await checkTokenDrift({
    collections: [{ name: '0. Primitives', modes: ['Value'], variables: [
      { name: 'color/x', type: 'COLOR', valuesByMode: { Value: { r: 0.5, g: 0.5, b: 0.5, a: 1 } } },
    ] }],
  });
  console.log('float round-trip noise');
  check('not reported as drift', r.valueDrift.length === 0, JSON.stringify(r.valueDrift));

  // ── 8. export without the ordering prefix, file still numbered ───────
  //
  // The exporter names its collections without an ordering prefix, but a
  // file Import has not renamed yet still says `0. Primitives` — and an
  // alias crossing into a still-numbered brand collection must resolve too.
  // Comparing the names raw would report every variable as missing.
  installFigma(
    [
      { name: '0. Primitives', modes: [{ modeId: 'mp', name: 'Value' }], variableIds: ['p1'] },
      { name: '1-1. Semantic/ Color · CoUI', modes: [{ modeId: 'mc', name: 'Light' }], variableIds: ['c1'] },
    ],
    [
      { id: 'p1', name: 'color/coui/neutral/black', valuesByMode: { mp: { r: 0, g: 0, b: 0, a: 1 } } },
      { id: 'c1', name: 'color/primary', valuesByMode: { mc: { type: 'VARIABLE_ALIAS', id: 'p1' } } },
    ],
  );
  r = await checkTokenDrift({
    collections: [
      { name: 'Primitives', modes: ['Value'], variables: [
        { name: 'color/coui/neutral/black', type: 'COLOR', valuesByMode: { Value: { r: 0, g: 0, b: 0, a: 1 } } },
      ] },
      { name: 'Semantic/ Color · CoUI', modes: ['Light'], variables: [
        { name: 'color/primary', type: 'COLOR', valuesByMode: { Light: { alias: 'Primitives/color/coui/neutral/black' } } },
      ] },
    ],
  });
  console.log('unprefixed export against a still-numbered file');
  check('no missing', r.missing.length === 0, JSON.stringify(r.missing));
  check('no extra', r.extra.length === 0, JSON.stringify(r.extra));
  check('no value drift', r.valueDrift.length === 0, JSON.stringify(r.valueDrift));

  console.log(failures === 0 ? '\nAll drift self-tests passed.' : `\n${failures} FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}
main();
