// Self-test for `textStyleNameOf` (src/text-styles.ts) — the rule that turns a
// typography role into the name its canvas text style is stored under — and for
// the line height `upsertTextStyles` writes and `checkTextStyleDrift` reads
// (the last section below).
//
// ## What it defends
//
// This rule exists twice. The authority is the Dart exporter's
// `_textStyleNameOf` (packages/coui_core/bin/export_figma_tokens.dart), whose
// output IS the name `upsertTextStyles` creates the style with. The copy in
// TypeScript is what the builder uses to find that style again.
//
// When the two disagree the failure is silent in the worst way: the builder
// looks up a name nobody created, finds nothing, attaches no style, and
// reports success. The canvas then shows text with no style attached — which
// is exactly the state this whole change set is removing.
//
// So the roles are read FROM the Dart source rather than restated here. A role
// added to the exporter is covered the moment it lands; only the shape of the
// rule is pinned by hand, and only where it is irregular (a size-code leaf —
// `xs` · `sm` · `md` · `xl` · `xl2` — uppercases instead of capitalising).

import { TYPOGRAPHY } from '../src/data';
import { roleLeaf } from '../src/text-nodes';
import {
  checkTextStyleDrift,
  textStyleNameOf,
  upsertTextStyles,
  type TextStyleSpec,
} from '../src/text-styles';

// This tsconfig carries no node types (the plugin itself has no filesystem),
// so the two node globals this test needs are declared the way `process` is
// declared in the sibling selftests rather than by adding @types/node for one
// file. esbuild bundles with `--platform=node`, so both resolve at run time.
declare const process: { exit(code: number): never; cwd(): string };
declare function require(id: string): {
  readFileSync(path: string, encoding: string): string;
  join(...parts: string[]): string;
};

const { readFileSync } = require('fs');
const { join } = require('path');

let failures = 0;

function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

// `process.cwd()`, not `__dirname` — npm runs this from the package root and
// esbuild bundles it to a `.cjs` elsewhere, so only cwd is stable across both.
// The repo root is two up from there. Stated as a constant rather than
// searched: a search that silently picks the wrong file would make this test
// pass against nothing.
const EXPORTER = join(
  process.cwd(),
  '..',
  '..',
  'packages',
  'coui_core',
  'bin',
  'export_figma_tokens.dart',
);
// The TypeScript copy, read as text the same way: the size-code pattern must be
// the same characters on both sides, not merely agree on today's roles.
const PLUGIN_RULE = join(process.cwd(), 'src', 'text-styles.ts');

// The one irregular test, as both copies spell it. A leaf that matches is a size
// code and is uppercased; every other leaf is a word and is capitalised.
const SIZE_CODE_PATTERN = '^[a-z]{1,2}\\d*$';

/**
 * The body of the exporter's `_textStyleNameOf`, whitespace collapsed.
 *
 * Read rather than restated: the point is to notice when the Dart rule
 * CHANGES, and a hand-copy of the rule cannot notice a change to itself.
 */
function exporterRuleBody(): string {
  const src = readFileSync(EXPORTER, 'utf8');
  const start = src.indexOf('String _textStyleNameOf(String role) {');
  assert(start !== -1, '_textStyleNameOf not found — did the exporter rename it?');
  const end = src.indexOf('\n}', start);
  assert(end !== -1, '_textStyleNameOf never closes');
  return src.slice(start, end).replace(/\s+/g, ' ');
}

/** The kebab roles the exporter builds a text style for. */
function rolesFromExporter(): string[] {
  const src = readFileSync(EXPORTER, 'utf8');
  const start = src.indexOf('final typographyRoles =');
  assert(start !== -1, 'typographyRoles block not found — did the exporter rename it?');
  const end = src.indexOf('};', start);
  assert(end !== -1, 'typographyRoles block never closes');
  const block = src.slice(start, end);
  const out: string[] = [];
  for (const m of block.matchAll(/'([a-z0-9]+-[a-z0-9]+)':/g)) out.push(m[1]);
  return out;
}

console.log('selftest: text style names');

const roles = rolesFromExporter();

check('the exporter still declares a set of roles to build styles for', () => {
  assert(roles.length > 0, 'read zero roles');
});

check('every exporter role maps to a Group/Leaf name', () => {
  for (const role of roles) {
    const name = textStyleNameOf(role);
    assert(name != null, `${role} → null`);
    assert(/^[A-Z][A-Za-z0-9]*\/[A-Z][A-Za-z0-9]*$/.test(name as string), `${role} → "${name}"`);
  }
});

// The builder finds a style by the role a label carries, and those roles come
// from the components export's scale — a second reader of the same Dart. A role
// one side has and the other lacks is a label that names a style nobody makes,
// or a style no label can reach.
check('the exporter builds a style for exactly the roles the builder draws', () => {
  const drawn = Object.keys(TYPOGRAPHY).map(roleLeaf).sort();
  const built = [...roles].sort();
  assert(
    JSON.stringify(drawn) === JSON.stringify(built),
    `components.json roles ${drawn.join(' ')} ≠ exporter roles ${built.join(' ')}`,
  );
});

check('camelCase and kebab spellings agree — builders know one, the exporter the other', () => {
  for (const role of roles) {
    const camel = role.replace(/-([a-z0-9])/g, (_, c: string) => c.toUpperCase());
    assert(
      textStyleNameOf(camel) === textStyleNameOf(role),
      `${camel} → ${textStyleNameOf(camel)} but ${role} → ${textStyleNameOf(role)}`,
    );
  }
});

// The irregular half of the rule. Capitalising would give `Xl2` or `Sm`, which
// is not the name the exporter writes, so the style would never be found.
check('size-code leaves uppercase rather than capitalise', () => {
  for (const [role, name] of [
    ['label-xl2', 'Label/XL2'],
    ['label-xl', 'Label/XL'],
    ['labelXl2', 'Label/XL2'],
    ['body-xs', 'Body/XS'],
    ['bodyXs', 'Body/XS'],
    ['label-xs', 'Label/XS'],
    ['code-xs', 'Code/XS'],
    ['code-sm', 'Code/SM'],
    ['codeSm', 'Code/SM'],
    ['code-md', 'Code/MD'],
  ] as const) {
    assert(textStyleNameOf(role) === name, `${role} → ${String(textStyleNameOf(role))}, expected ${name}`);
  }
});

// The names the library already publishes keep their spelling — a style is
// adopted by name, so a word leaf turning into `MEDIUM` would orphan every node
// that uses it. `medium` and `small` are the words a careless size-code test
// would catch.
check('word leaves capitalise, and keep the names the library publishes', () => {
  for (const [role, name] of [
    ['body-medium', 'Body/Medium'],
    ['body-small', 'Body/Small'],
    ['label-medium', 'Label/Medium'],
    ['label-small', 'Label/Small'],
    ['displayLarge', 'Display/Large'],
    ['title-large', 'Title/Large'],
  ] as const) {
    assert(textStyleNameOf(role) === name, `${role} → ${String(textStyleNameOf(role))}, expected ${name}`);
  }
});

// A role with no leaf cannot name a style; returning null lets the caller skip
// it and say so, rather than looking up "Undefined/Undefined" and reporting a
// missing style that was never supposed to exist.
check('a role with no leaf is null, not a malformed name', () => {
  assert(textStyleNameOf('body') === null, String(textStyleNameOf('body')));
  assert(textStyleNameOf('') === null, String(textStyleNameOf('')));
});

// The two copies of the rule can only be held together by reading the
// authority. Fragments rather than the whole body: reformatting the Dart
// should not fail this, but changing which half uppercases — the one
// irregularity, and the one whose drift is silent — must.
check('the exporter rule still splits on "-", uppercases size codes, capitalises the rest', () => {
  const body = exporterRuleBody();
  for (const fragment of [
    "role.split('-')",
    `RegExp(r'${SIZE_CODE_PATTERN}').hasMatch(parts[1])`,
    'parts[1].toUpperCase()',
    'cap(parts[1])',
    "cap(parts[0])}/$leaf",
  ]) {
    assert(body.includes(fragment), `exporter rule no longer contains \`${fragment}\`: ${body}`);
  }
});

check('the plugin copy tests the same size-code pattern, character for character', () => {
  const src = readFileSync(PLUGIN_RULE, 'utf8');
  const fragment = `/${SIZE_CODE_PATTERN}/.test(parts[1])`;
  assert(src.includes(fragment), `src/text-styles.ts no longer contains \`${fragment}\``);
});

// ─── The line box a style is written with ───────────────────────────────────
//
// A multiplier role's line height is a PERCENT literal with nothing bound over
// it — Figma reads a bound number as px. A fixed-box role (the code roles) is
// the one line height that IS px, so it is written PIXELS and bound to the
// variable the export names. Both directions break silently: a box written as
// PERCENT draws 21% lines, and a binding left on a multiplier style overwrites
// its percent with the variable's px.

interface FakeStyle {
  id: string;
  name: string;
  fontName: FontName;
  fontSize: number;
  lineHeight: LineHeight;
  letterSpacing: LetterSpacing;
  description: string;
  boundVariables: Record<string, { id: string }>;
  setBoundVariable(field: string, v: { id: string } | null): void;
}

const styles: FakeStyle[] = [];
const vars = new Map<string, { id: string; name: string }>();
const collections: { id: string; name: string; variableIds: string[] }[] = [];

function fakeStyle(name: string): FakeStyle {
  const style: FakeStyle = {
    id: `S:${name}`,
    name,
    fontName: { family: 'Pretendard', style: 'Regular' },
    fontSize: 0,
    lineHeight: { unit: 'AUTO' },
    letterSpacing: { unit: 'PERCENT', value: 0 },
    description: '',
    boundVariables: {},
    setBoundVariable(field, v) {
      if (v == null) delete style.boundVariables[field];
      else style.boundVariables[field] = { id: v.id };
    },
  };
  return style;
}

(globalThis as { figma?: unknown }).figma = {
  async getLocalTextStylesAsync() {
    return styles;
  },
  createTextStyle() {
    const style = fakeStyle('');
    styles.push(style);
    return style;
  },
  async loadFontAsync() {},
  variables: {
    async getLocalVariableCollectionsAsync() {
      return collections;
    },
    async getVariableByIdAsync(id: string) {
      return [...vars.values()].find((v) => v.id === id) ?? null;
    },
  },
};

// `byPath` the way `importTokens` builds it: `<Collection>/<name>` → Variable.
const byPath = new Map<string, Variable>();
for (const [coll, names] of [
  ['Primitives', ['font/family/Pretendard', 'font/family/Geist Mono']],
  [
    'Semantic/ Typography',
    ['font-size/code-sm', 'font-weight/code', 'letter-spacing/code-sm', 'line-height/code',
      'font-size/label-large', 'font-weight/label', 'letter-spacing/label-large'],
  ],
] as const) {
  const ids: string[] = [];
  for (const name of names) {
    const v = { id: `V:${coll}/${name}`, name };
    vars.set(`${coll}/${name}`, v);
    byPath.set(`${coll}/${name}`, v as unknown as Variable);
    ids.push(v.id);
  }
  collections.push({ id: `C:${coll}`, name: coll, variableIds: ids });
}

// The shape the exporter writes (`textStyles` in build/tokens.figma.json).
const codeSpec: TextStyleSpec = {
  name: 'Code/SM',
  role: 'code-sm',
  fontFamily: { variable: 'Primitives/font/family/Geist Mono', value: 'Geist Mono' },
  fontSize: { variable: 'Semantic/ Typography/font-size/code-sm', value: 12 },
  fontWeight: { variable: 'Semantic/ Typography/font-weight/code', value: 400 },
  letterSpacing: { variable: 'Semantic/ Typography/letter-spacing/code-sm', value: 0 },
  lineHeightPx: { variable: 'Semantic/ Typography/line-height/code', value: 21 },
};
const labelSpec: TextStyleSpec = {
  name: 'Label/Large',
  role: 'label-large',
  fontFamily: { variable: 'Primitives/font/family/Pretendard', value: 'Pretendard' },
  fontSize: { variable: 'Semantic/ Typography/font-size/label-large', value: 14 },
  fontWeight: { variable: 'Semantic/ Typography/font-weight/label', value: 500 },
  letterSpacing: { variable: 'Semantic/ Typography/letter-spacing/label-large', value: -0.14 },
  lineHeightPercent: 140,
};

const asyncChecks: [string, () => Promise<void>][] = [];

asyncChecks.push(['a fixed-box style is written PIXELS and bound to its variable', async () => {
  const log = await upsertTextStyles([codeSpec], byPath);
  const style = styles.find((x) => x.name === 'Code/SM');
  assert(style != null, `no Code/SM created: ${log.join(' | ')}`);
  assert(JSON.stringify(style!.lineHeight) === JSON.stringify({ unit: 'PIXELS', value: 21 }), JSON.stringify(style!.lineHeight));
  assert(style!.boundVariables.lineHeight?.id === 'V:Semantic/ Typography/line-height/code', 'line height bound');
  assert(style!.boundVariables.fontFamily?.id === 'V:Primitives/font/family/Geist Mono', 'family bound to the exported mono');
  assert(style!.fontName.family === 'Geist Mono', `face ${style!.fontName.family}`);
}]);

asyncChecks.push(['a multiplier style sheds a line height binding and writes PERCENT', async () => {
  const stale = fakeStyle('Label/Large');
  stale.setBoundVariable('lineHeight', { id: 'V:Semantic/ Typography/line-height/code' });
  styles.push(stale);
  await upsertTextStyles([labelSpec], byPath);
  assert(stale.boundVariables.lineHeight == null, 'the binding would overwrite the percent');
  assert(JSON.stringify(stale.lineHeight) === JSON.stringify({ unit: 'PERCENT', value: 140 }), JSON.stringify(stale.lineHeight));
}]);

asyncChecks.push(['a spec stating no line height fails before anything is written', async () => {
  const bare = { ...labelSpec, name: 'Label/Bare' } as TextStyleSpec;
  delete bare.lineHeightPercent;
  const log = await upsertTextStyles([bare], byPath);
  assert(!styles.some((x) => x.name === 'Label/Bare'), 'no half-written style');
  assert(log.some((l) => l.includes('Label/Bare') && l.includes('states neither')), log.join(' | '));
  assert(log.some((l) => l.includes('0 adopted, 0 created, 1 failed')), log.join(' | '));
}]);

asyncChecks.push(['drift reads a fixed box as PIXELS, and a binding over a percent as drift', async () => {
  const clean = await checkTextStyleDrift([codeSpec, labelSpec]);
  assert(clean.length === 1 && clean[0].startsWith('✓'), `no drift expected: ${clean.join(' | ')}`);
  const code = styles.find((x) => x.name === 'Code/SM')!;
  code.lineHeight = { unit: 'PERCENT', value: 21 };
  code.setBoundVariable('lineHeight', null);
  const label = styles.find((x) => x.name === 'Label/Large')!;
  label.setBoundVariable('lineHeight', { id: 'V:Semantic/ Typography/line-height/code' });
  const drift = (await checkTextStyleDrift([codeSpec, labelSpec])).join('\n');
  assert(drift.includes('Code/SM.lineHeight: export 21px · live 21%'), drift);
  assert(drift.includes('Code/SM.lineHeight: 바인딩 없음'), drift);
  assert(drift.includes('Label/Large.lineHeight: 바인딩'), drift);
}]);

void (async () => {
  for (const [label, fn] of asyncChecks) {
    try {
      await fn();
      console.log(`  ok  ${label}`);
    } catch (e) {
      failures++;
      console.error(`FAIL  ${label}\n      ${String(e)}`);
    }
  }
  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log(`✅ text-style-name selftest passed (${roles.length} exporter roles)`);
})();
