#!/usr/bin/env node
// Source-only refactor evidence: run the real registry builders through the existing
// fake Figma harness and capture first-build trees before mutation drills.
// These artifacts compare drawing writes/identity; they do not model native layout.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';
import * as esbuild from 'esbuild';

const root = path.resolve(process.argv[2] ?? '.');
const output = path.resolve(process.argv[3] ?? 'builder-artifact.json');
const source = fs.readFileSync(path.join(root, 'scripts/selftest-registry-runtime.ts'), 'utf8');
// Optional audit instrumentation exists only in the temporary Node bundle. It
// records actual JSON leaf reads while a builder runs, never production code.
const tracePrefixes = JSON.parse(process.env.COUI_TRACE_DATA_PREFIXES ?? '[]');
const readerMarker = 'const entry = DRIVE_ORDER[i];';
if (tracePrefixes.length && source.split(readerMarker).length !== 2) throw new Error('Data read instrumentation point changed');
const tracedSource = tracePrefixes.length
  ? source.replace(readerMarker, readerMarker + "\n(globalThis as any).__couiDataReader = entry.name;")
  : source;
const marker = 'const elapsedMs = Date.now() - startedAt;';
if (source.split(marker).length !== 2) throw new Error('Runtime artifact insertion point changed');
const capture = `
if (failures.length > 0) throw new Error('artifact drive failed: ' + failures.map(f => f.name + ': ' + f.error.message).join('; '));
if (globalThis.__couiDataReads) globalThis.__couiDataReader = '(capture)';
const artifactFs = require('node:fs');
const artifactCrypto = require('node:crypto');
const artifactZlib = require('node:zlib');
const digest = value => artifactCrypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
function canonical(value, ancestors = new Set()) {
  if (typeof value === 'function' || typeof value === 'undefined') return undefined;
  if (typeof value === 'symbol') return String(value);
  if (value === null || typeof value !== 'object') return value;
  if (ancestors.has(value)) return { $ref: value.id ?? 'cycle' };
  const next = new Set(ancestors); next.add(value);
  if (Array.isArray(value)) return value.map(v => canonical(v, next));
  if (value instanceof Map) return [...value].map(([k, v]) => [canonical(k, next), canonical(v, next)]);
  if (value instanceof Set) return [...value].map(v => canonical(v, next));
  const result = {};
  // The harness stores effects, property references and sizing behind
  // non-enumerable accessors. Include their values as well as ordinary fields.
  for (const key of Object.getOwnPropertyNames(value).sort()) {
    if (key === 'parent') continue;
    const held = key === 'isExposedInstance' ? exposedInstances.has(value) : value[key];
    const v = canonical(held, next);
    if (v !== undefined) result[key] = v;
  }
  return result;
}
const artifact = { registry: REGISTRY.map(({ build, ...metadata }) => metadata), entries: {}, calls: canonical(callTally) };
if (globalThis.__couiDataReads) artifact.dataReads = Object.fromEntries([...globalThis.__couiDataReads].map(([name, reads]) => [name, [...reads].sort()]));
const trees = {};
for (const [name, node] of builtByName) {
  const tree = canonical(node);
  trees[name] = tree;
  let nodes = 0, instances = [];
  const walk = n => { nodes++; if (n.type === 'INSTANCE') instances.push({ id: n.id, main: n.mainComponent?.id, properties: canonical(n.componentProperties) }); for (const c of n.children ?? []) walk(c); };
  walk(node);
  artifact.entries[name] = { sha256: digest(tree), nodes, id: node.id, members: node.children.map(c => ({ id: c.id, name: c.name })), properties: canonical(node.componentPropertyDefinitions), instances };
}
artifactFs.writeFileSync(process.env.COUI_BUILDER_ARTIFACT, JSON.stringify(artifact, null, 2) + '\\n');
artifactFs.writeFileSync(process.env.COUI_BUILDER_ARTIFACT + '.trees.json.gz', artifactZlib.gzipSync(JSON.stringify(trees)));
console.log('Captured ' + builtByName.size + ' registry builder trees');
process.exit(0);
`;
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'coui-builder-artifact-'));
try {
  const bundle = path.join(tmp, 'artifact.cjs');
  await esbuild.build({
    stdin: { contents: tracedSource.replace(marker, capture + '\n' + marker), resolveDir: path.join(root, 'scripts'), loader: 'ts' },
    outfile: bundle, bundle: true, platform: 'node', format: 'cjs', target: 'es2017', logLevel: 'silent',
    plugins: tracePrefixes.length ? [{ name: 'audit-json-reads', setup(build) {
      build.onLoad({ filter: /\/src\/data\/components\.json$/ }, args => ({ loader: 'js', contents: `
        const data = ${fs.readFileSync(args.path, 'utf8')};
        const prefixes = ${JSON.stringify(tracePrefixes)};
        const seen = new WeakMap();
        globalThis.__couiDataReads = new Map();
        function trace(value, path = '') {
          if (value === null || typeof value !== 'object') return value;
          if (seen.has(value)) return seen.get(value);
          const proxy = new Proxy(value, { get(target, key, receiver) {
            const next = path ? path + '.' + String(key) : String(key);
            const leaf = Reflect.get(target, key, receiver);
            if (typeof key === 'string' && leaf !== undefined && (leaf === null || typeof leaf !== 'object') && prefixes.some(p => next.startsWith(p + '.') || next === p)) {
              const reader = globalThis.__couiDataReader ?? '(module initialization)';
              if (!globalThis.__couiDataReads.has(reader)) globalThis.__couiDataReads.set(reader, new Set());
              globalThis.__couiDataReads.get(reader).add(next);
            }
            return trace(leaf, next);
          } });
          seen.set(value, proxy); return proxy;
        }
        export default trace(data);
      ` }));
    } }] : [],
  });
  // The harness reads Core's radius ladder relative to the plugin workspace.
  process.stdout.write(execFileSync(process.execPath, [bundle], {
    cwd: process.cwd(), env: { ...process.env, COUI_BUILDER_ARTIFACT: output }, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024,
  }));
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
