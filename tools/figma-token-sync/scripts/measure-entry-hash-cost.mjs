#!/usr/bin/env node
// 엔트리 소스 해시의 비용 — 번들 시간 · `code.js` 크기 · 런타임에서 엔트리 해시를 만드는 시간.
//
//   node scripts/measure-entry-hash-cost.mjs [--base origin/main] [--runs 7]
//
// 전(base) = 이 변경이 없는 트리(기본 `origin/main`, `git archive` 로 임시 디렉터리에 푼다),
// 후 = 지금 작업 트리. 두 쪽 모두 `package.json` 의 `build` 가 호출하는 것과 같은 esbuild 플래그다
// (`bundle-owner.mjs` 의 확인 · 기록 단계는 파일 몇 개를 읽고 쓸 뿐이라 뺐다).
// 읽기 전용 — 이 레포의 작업 트리 · 브랜치 · 캔버스를 건드리지 않는다.

import * as esbuild from 'esbuild';
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative } from 'node:path';
import { performance } from 'node:perf_hooks';

const args = process.argv.slice(2);
const argOf = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : fallback;
};
const base = argOf('--base', 'origin/main');
const runs = Number(argOf('--runs', '7'));

const repoRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
const pkgRel = relative(repoRoot, process.cwd()) || '.';
const here = process.cwd();
const median = (xs) => [...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)];

const esbuildBin = join(here, 'node_modules/.bin/esbuild');
const scratch = mkdtempSync(join(tmpdir(), 'coui-cost-out-'));
const outOf = (tag) => join(scratch, `${tag}.js`);

function extract(rev) {
  const tmp = mkdtempSync(join(tmpdir(), 'coui-cost-'));
  const r = spawnSync(
    'sh',
    ['-c', `git archive ${rev} -- ${pkgRel}/src ${pkgRel}/code.ts ${pkgRel}/reverse ${pkgRel}/scripts | tar -x -C ${tmp}`],
    { cwd: repoRoot, encoding: 'utf8' },
  );
  if (r.status !== 0) throw new Error(r.stderr);
  const root = join(tmp, pkgRel);
  symlinkSync(join(here, 'node_modules'), join(root, 'node_modules'));
  return { tmp, root };
}

function bundleWithTable(root, tag = 'new') {
  const t0 = performance.now();
  const table = execFileSync('node', ['scripts/entry-source-hash.mjs'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
  const hashMs = performance.now() - t0;
  const t1 = performance.now();
  const r = spawnSync(
    esbuildBin,
    [
      'code.ts',
      '--bundle',
      '--target=es2017',
      '--define:__SHARED_SOURCE_HASH__="0123456789abcdef"',
      `--define:__ENTRY_SOURCE_HASHES__=${table}`,
      '--define:__BUILD_REF__="measure@0"',
      '--outfile=' + outOf(tag),
      '--log-level=error',
    ],
    { cwd: root, encoding: 'utf8' },
  );
  if (r.status !== 0) throw new Error(r.stderr);
  return { hashMs, bundleMs: performance.now() - t1, table };
}

function bundleOld(root, tag = 'old') {
  const t1 = performance.now();
  const r = spawnSync(
    esbuildBin,
    [
      'code.ts',
      '--bundle',
      '--target=es2017',
      '--define:__SHARED_SOURCE_HASH__="0123456789abcdef"',
      '--define:__BUILD_REF__="measure@0"',
      '--outfile=' + outOf(tag),
      '--log-level=error',
    ],
    { cwd: root, encoding: 'utf8' },
  );
  if (r.status !== 0) throw new Error(r.stderr);
  return performance.now() - t1;
}

/** 런타임에서 모든 엔트리의 해시를 한 번 만드는 시간 — 번들해 노드에서 돌린다. */
async function runtimeHashMs(root, table) {
  const probe = join(scratch, `probe-${table === null ? 'old' : 'new'}-${root === here ? 'here' : 'base'}.ts`);
  writeFileSync(
    probe,
    `import { REGISTRY } from '${join(root, 'src/registry')}';\nimport { entryContentHashOf } from '${join(root, 'src/content-hash')}';\n` +
      `const N = ${runs * 3};\nconst per: number[] = [];\n` +
      `for (let i = 0; i < N; i++) { const s = process.hrtime.bigint(); for (const e of REGISTRY) entryContentHashOf(e); per.push(Number(process.hrtime.bigint() - s) / 1e6); }\n` +
      `per.sort((a, b) => a - b);\nconsole.log(JSON.stringify({ entries: REGISTRY.length, medianMs: per[Math.floor(N / 2)], minMs: per[0] }));\n`,
  );
  const define = {
    __SHARED_SOURCE_HASH__: JSON.stringify('0123456789abcdef'),
    __BUILD_REF__: JSON.stringify('measure@0'),
  };
  if (table !== null) define.__ENTRY_SOURCE_HASHES__ = table;
  const out = probe.replace(/\.ts$/, '.cjs');
  await esbuild.build({
    entryPoints: [probe],
    outfile: out,
    bundle: true,
    platform: 'node',
    format: 'cjs',
    target: 'es2017',
    logLevel: 'silent',
    absWorkingDir: root,
    define,
  });
  return JSON.parse(execFileSync('node', [out], { encoding: 'utf8' }).trim().split('\n').pop());
}

const before = extract(base);
const after = { root: here, tmp: null };
try {
  // 번들 시간 — 첫 실행은 디스크 캐시를 데우므로 버린다.
  const oldMs = [];
  const newBundleMs = [];
  const newHashMs = [];
  bundleOld(before.root);
  bundleWithTable(after.root);
  for (let i = 0; i < runs; i++) {
    oldMs.push(bundleOld(before.root));
    const n = bundleWithTable(after.root);
    newBundleMs.push(n.bundleMs);
    newHashMs.push(n.hashMs);
  }
  const oldSize = statSync(outOf('old')).size;
  const newSize = statSync(outOf('new')).size;
  const table = bundleWithTable(after.root).table;

  const rtOld = await runtimeHashMs(before.root, null); // 전: 변경 이전 트리의 레시피
  const rtNew = await runtimeHashMs(after.root, table);

  const f = (x) => x.toFixed(0);
  console.log(`번들(esbuild, ${runs}회 중앙값) — 전(${base}): ${f(median(oldMs))} ms · 후: ${f(median(newBundleMs))} ms + 닫힘 해시 계산 ${f(median(newHashMs))} ms = ${f(median(newBundleMs) + median(newHashMs))} ms`);
  console.log(`code.js 크기 — 전: ${oldSize} 바이트 · 후: ${newSize} 바이트 (${newSize - oldSize >= 0 ? '+' : ''}${newSize - oldSize})`);
  console.log(
    `런타임 엔트리 해시 ${rtOld.entries}개 한 바퀴(노드, ${runs * 3}회 중앙값) — 전 레시피(표 없음): ${rtOld.medianMs.toFixed(2)} ms · 새 레시피: ${rtNew.medianMs.toFixed(2)} ms`,
  );
} finally {
  rmSync(before.tmp, { recursive: true, force: true });
  rmSync(scratch, { recursive: true, force: true });
}
