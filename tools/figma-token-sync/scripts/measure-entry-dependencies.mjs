#!/usr/bin/env node
// Invalidation simulation over EVERY real registry entry. Uses the production
// esbuild graph, source-hash builder and bundled runtime recipe, never code.js.
// This measures affected recipes, not native Figma time or layout.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import * as esbuild from 'esbuild';
import { bundleGraph, checkDeclarations, moduleGraph, entrySourceHashes, toolchainOf } from './entry-source-hash.mjs';

const read = p => fs.readFileSync(p, 'utf8');
export function sourceFiles(root) {
  const walk = dir => fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p) : p.endsWith('.ts') ? [p] : [];
  });
  return [...walk(path.join(root, 'src')).filter(p => !p.includes('/src/data/')), path.join(root, 'code.ts')].sort();
}
export function locate(root, needle) {
  const found = sourceFiles(root).filter(p => read(p).includes(needle));
  if (found.length !== 1) throw new Error(`Expected exactly one module containing ${needle}: ${found}`);
  return found[0];
}
export function replace(root, needle, replacement) {
  const p = locate(root, needle), original = read(p);
  if (original.split(needle).length !== 2) throw new Error(`Ambiguous mutation ${needle}`);
  fs.writeFileSync(p, original.replace(needle, replacement));
  return () => fs.writeFileSync(p, original);
}
export function withTree(root, run) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'coui-entry-dependencies-'));
  for (const f of ['src', 'reverse', 'code.ts']) fs.cpSync(path.join(root, f), path.join(tmp, f), { recursive: true });
  return Promise.resolve().then(() => run(tmp)).finally(() => fs.rmSync(tmp, { recursive: true, force: true }));
}
const probeSource = `
import { REGISTRY, SOURCE_GROUPS } from './src/registry';
import { entryContentHashOf } from './src/content-hash';
import { entrySourceKeysOf, entrySourceHashOf } from './src/entry-source';
const entries = {};
for (const e of REGISTRY) entries[e.name] = { hash: entryContentHashOf(e), keys: entrySourceKeysOf(e), fallback: entrySourceHashOf(e) === null };
const unknown = { section: 'Display', name: 'UnknownProbe', build: () => ({}) };
console.log(JSON.stringify({ entries, unknown: entryContentHashOf(unknown), groups: Object.fromEntries(Object.entries(SOURCE_GROUPS).map(([k, es]) => [k, es.map(e => e.name)])) }));
`;
export async function probe(root, { omitTable = false } = {}) {
  const graph = moduleGraph(await bundleGraph(esbuild, root));
  const problems = checkDeclarations(graph);
  if (problems.length) throw new Error(problems.join('\n'));
  const table = entrySourceHashes({ graph, registrySource: read(path.join(root, 'src/registry.ts')), readFile: p => fs.readFileSync(path.join(root, p)), toolchain: toolchainOf(esbuild) });
  // Exact whole-source fallback used by package.json, including source paths in
  // the same lexical order; the per-entry recipe itself is production code.
  const shared = createHash('sha256');
  for (const p of sourceFiles(root)) shared.update(fs.readFileSync(p));
  const sharedHash = shared.digest('hex').slice(0, 16);
  const bundled = await esbuild.build({
    stdin: { contents: probeSource, resolveDir: root, loader: 'ts' },
    bundle: true, write: false, platform: 'node', format: 'cjs', target: 'es2017', logLevel: 'silent',
    define: { __ENTRY_SOURCE_HASHES__: omitTable ? 'undefined' : JSON.stringify(JSON.stringify(table.hashes)), __SHARED_SOURCE_HASH__: JSON.stringify(sharedHash), __BUILD_REF__: JSON.stringify('dependency-probe') },
  });
  const out = path.join(root, '.dependency-probe.cjs');
  fs.writeFileSync(out, bundled.outputFiles[0].contents);
  const stdout = execFileSync(process.execPath, [out], { encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
  fs.unlinkSync(out);
  const runtime = JSON.parse(stdout.trim().split('\n').pop());
  return {
    ...runtime, sharedHash, unresolved: table.unresolved,
    filesByKey: Object.fromEntries(Object.entries(table.filesByKey).map(([k, v]) => [k, [...v].sort()])),
    crossBuilderImports: [...graph.edges].flatMap(([from, deps]) => deps.filter(to => from.startsWith('src/components/') && to.startsWith('src/components/')).map(to => ({ from, to }))),
  };
}
export function changed(before, after) {
  const names = Object.keys(before.entries);
  if (JSON.stringify(names) !== JSON.stringify(Object.keys(after.entries))) throw new Error('Registry membership/order changed in scenario');
  return names.filter(n => before.entries[n].hash !== after.entries[n].hash);
}
const edit = (needle, replacement) => root => replace(root, needle, replacement);
const append = (file, code) => root => {
  const p = path.join(root, file), original = read(p);
  fs.writeFileSync(p, original + '\n' + code + '\n');
  return () => fs.writeFileSync(p, original);
};
const dataEdit = slug => root => {
  const p = path.join(root, 'src/data/components.json'), original = read(p), json = JSON.parse(original);
  json.components[slug].fields.__semanticProbe = { v: 1 };
  fs.writeFileSync(p, JSON.stringify(json));
  return () => fs.writeFileSync(p, original);
};
export const scenarios = [
  { name: 'SelectableText drawing', mutate: edit("makeLabel('선택할 수 있는 ',", "makeLabel('선택할 수 있는 probe ',") },
  { name: 'TextBlock drawing (same text family)', mutate: edit("makeLabel('인용한 문단이에요.',", "makeLabel('바꾼 문단이에요.',") },
  { name: 'Command panel only', mutate: edit("const kCommandEmptyCopy = '검색 결과가 없어요.';", "const kCommandEmptyCopy = '결과 없음.';") },
  { name: 'CommandSearch drawing', mutate: edit("const kCommandSearchShortcutCopy = '⌘K';", "const kCommandSearchShortcutCopy = '⌘P';") },
  { name: 'CommandItem child drawing', mutate: edit("const kCommandItemStates = stateAxis(['enabled', 'hover', 'pressed', 'disabled']);", "const kCommandItemStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);") },
  { name: 'Popup child drawing', mutate: edit("const kPopupContentShape = 'rectangular';", "const kPopupContentShape = 'circular';") },
  { name: 'FormLabel sizing helper', mutate: edit('FORM_LABEL.constants.size.choice,', "'lg',") },
  { name: 'Shared field caret/radius drawing', mutate: edit('return (ts.fontSize ?? kFallbackFontSize) * (ts.lineHeight ?? kFallbackLineHeight);', 'return (ts.fontSize ?? kFallbackFontSize) * (ts.lineHeight ?? kFallbackLineHeight) + 1;') },
  { name: 'Shared container elevation drawing', mutate: edit("leaf.choice === 'none' || explicit.layers.length > 0", "leaf.choice === 'none' || explicit.layers.length > 1") },
  { name: 'Shared instance label drawing', mutate: edit('export function setInstanceLabel(inst: InstanceNode, text: string): void {', 'export function setInstanceLabel(inst: InstanceNode, text: string): void {\n  inst.opacity = 0.9;') },
  { name: 'Chip composition helper', mutate: edit('const x = (w - side) / 2;', 'const x = (w - side) / 2 + 1;') },
  { name: 'Plain Button default helper', mutate: edit('export const kPlainButtonForeground = COMPONENTS.button.variants.defaultsByVariant.plain.foregroundColor;', 'export const kPlainButtonForeground = COMPONENTS.button.variants.defaultsByVariant.primary.foregroundColor;') },
  { name: 'Carousel drawing (remaining broad family)', mutate: edit('function buildCarousel(page: PageNode, lk: VarLookup): ComponentSetNode {', "function buildCarousel(page: PageNode, lk: VarLookup): ComponentSetNode {\n  page.name = 'Carousel probe';") },
  { name: 'Icon child source validation', mutate: append('src/components/icon.ts', "console.info('Icon semantic edit probe');") },
  { name: 'Own TextField data', mutate: dataEdit('text_field') },
  { name: 'Command data shared by fragment', mutate: dataEdit('command') },
  { name: 'Global drawing pipeline', mutate: edit('size: codeRole?.fontSize ?? kCodeBlockFallbackSize,', 'size: (codeRole?.fontSize ?? kCodeBlockFallbackSize) + 1,') },
  { name: 'Global generate glue', mutate: edit('const kPageMargin = 120;', 'const kPageMargin = 124;') },
  { name: 'Non-drawing logging', mutate: append('src/summary-format.ts', "console.info('logging semantic edit probe');") },
  { name: 'Non-drawing lock', mutate: append('src/run-lock.ts', "console.info('lock semantic edit probe');") },
  { name: 'Unknown source fallback (missing table)', omitTable: true, mutate: append('src/run-lock.ts', "console.info('fallback semantic edit probe');") },
  { name: 'Opaque Icon source fallback', mutate: root => {
    const restore = append('src/components/icon.ts', "export const opaqueProbe = () => import('./opaque-probe');\n(globalThis as any).__opaqueProbe = opaqueProbe;")(root);
    const leaf = path.join(root, 'src/components/opaque-probe.ts'); fs.writeFileSync(leaf, 'export const probe = 1;');
    return () => { restore(); fs.unlinkSync(leaf); };
  } },
];
export async function measure(root) {
  return withTree(root, async tmp => {
    const baseline = await probe(tmp);
    if (baseline.unresolved.length) throw new Error(`Baseline fallback: ${JSON.stringify(baseline.unresolved)}`);
    const rows = [];
    for (const scenario of scenarios) {
      const before = scenario.omitTable ? await probe(tmp, scenario) : baseline;
      const restore = scenario.mutate(tmp);
      try {
        const after = await probe(tmp, scenario), affected = changed(before, after);
        rows.push({ scenario: scenario.name, count: affected.length, affected, fallback: Object.keys(after.entries).filter(n => after.entries[n].fallback), unresolved: after.unresolved,
          unknownChanged: before.unknown !== after.unknown,
          matrix: Object.fromEntries(Object.keys(before.entries).map(n => [n, { before: before.entries[n].hash, after: after.entries[n].hash, changed: affected.includes(n) }])) });
      } finally { restore(); }
    }
    return { toolchain: toolchainOf(esbuild), registryCount: Object.keys(baseline.entries).length, groupCount: Object.keys(baseline.groups).length, baseline, scenarios: rows };
  });
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const result = await measure(path.resolve(process.argv[2] ?? '.'));
  fs.writeFileSync(path.resolve(process.argv[3] ?? 'entry-dependency-impact.json'), JSON.stringify(result, null, 2) + '\n');
  for (const row of result.scenarios) console.log(`${row.scenario}: ${row.count}/${result.registryCount}`);
}
