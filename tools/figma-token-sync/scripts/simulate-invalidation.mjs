#!/usr/bin/env node
// 무효화 재생 시뮬레이션 — 플러그인 `src/` 를 건드린 커밋을 하나씩 재생해 커밋마다
//   (a) 기존 레시피(`kSharedSourceHash` = `src/` 전체 해시)에서 낡아지는 엔트리 수
//   (b) 새 레시피(엔트리별 import 닫힘 해시)에서 낡아지는 엔트리 수
// 를 센다. "낡아진다" = 직전 커밋(`<커밋>^`) 대비 엔트리 해시가 달라졌다.
//
//   node scripts/simulate-invalidation.mjs [--since 2026-11-01] [--tip origin/main] [--json out.json]
//
// 읽기 전용이다 — 각 커밋의 트리를 `git archive` 로 임시 디렉터리에 풀어 번들러의 import 그래프만
// 계산한다. 이 레포의 작업 트리 · 브랜치 · 캔버스를 건드리지 않는다. 스크립트가 `scripts/` 에 있는
// 이유: `src/` 에 두면 이 파일이 `kSharedSourceHash` 에 들어가 해시를 또 움직인다.
//
// ## 무엇이 측정이고 무엇이 추정인가
//
// - 측정(코드 실행 결과): 커밋마다의 낡은 엔트리 집합과 수. 새 레시피는 실제 `entry-source-hash.mjs` 의
//   함수로, 엔트리 목록 · `needs` · 데이터 슬러그는 각 커밋의 레지스트리를 번들해 실행해서 얻는다.
//   기존 레시피는 `build` 스크립트의 정의(`src` 의 `.ts`(`src/data/*` 제외) + `code.ts` 의 내용 해시)를 그대로
//   재현한다 — 빌더 텍스트는 `.ts` 가 바뀔 때만 움직이므로 같은 해시에 이미 들어 있다.
// - 추정: 시간 환산. 엔트리별 재그리기 시간은 변형 수에 비례한다고 보고 실측 로그에서 보정한 값을 곱한다.
//   변형당 시간이 컴포넌트마다 0.3~2.6 초로 갈리고 기계 부하에 따라 달라지므로 거친 값이다.
//   변형 수는 현재 트리의 `npm run audit:sizing` 출력(빌더를 가짜 Figma 에 실제로 돌려 센 값)이다.
//
// 새 레시피를 옛 트리에 적용할 때 선언한 경로 중 그 트리에 없는 것(그때는 없던 모듈)은 건너뛴다.

import * as esbuild from 'esbuild';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative } from 'node:path';
import {
  bundleGraph,
  defaultConfig,
  entrySourceHashes,
  moduleGraph,
  registryKeyModules,
  toolchainOf,
} from './entry-source-hash.mjs';

const args = process.argv.slice(2);
const argOf = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : fallback;
};
const since = argOf('--since', '2026-11-01');
const tip = argOf('--tip', 'HEAD'); // 이 리비전에서 닿는 커밋만 재생한다
const jsonOut = argOf('--json', null);

/** 시간 환산 보정 — 2026-11-05~06 실제 Generate 로그. [이름, 변형 수, 초] */
const kCalibration = [
  ['Button', 972, 1000.6],
  ['Chip', 384, 530.1],
  ['Badge', 324, 264.0],
  ['TextField', 96, 234.3],
  ['Command', 18, 47.4],
  ['MenuItem', 30, 29.0],
  ['CommandItem', 48, 15.5],
  ['Card', 16, 11.8],
];
const kPooledRate = kCalibration.reduce((a, r) => a + r[2], 0) / kCalibration.reduce((a, r) => a + r[1], 0);
const kRates = kCalibration.map((r) => r[2] / r[1]);

const repoRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
// 경로 인자는 레포 루트 기준이다.
const git = (...a) => execFileSync('git', a, { encoding: 'utf8', maxBuffer: 1 << 28, cwd: repoRoot }).trim();
const pkgRel = relative(repoRoot, process.cwd()) || '.';
const sha = (s) => createHash('sha256').update(s).digest('hex').slice(0, 16);

// ─── 커밋 목록 ───────────────────────────────────────────────────────────────

const commits = git('log', tip, '--no-merges', `--since=${since}`, '--reverse', '--format=%H', '--', `${pkgRel}/src`, `${pkgRel}/code.ts`)
  .split('\n')
  .filter(Boolean);
if (commits.length === 0) {
  console.error(`${since} 이후 ${pkgRel}/src 를 건드린 커밋이 없다.`);
  process.exit(1);
}
const shas = [`${commits[0]}^`, ...commits];

// ─── 스냅샷 ─────────────────────────────────────────────────────────────────

const walk = (dir) =>
  readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });

/** 기존 레시피의 `kSharedSourceHash` — `build` 스크립트와 같은 파일 집합(내용 해시). */
function sharedTsHash(root) {
  const files = walk(join(root, 'src'))
    .map((p) => relative(root, p))
    .filter((p) => p.endsWith('.ts') && !p.startsWith('src/data/'));
  files.push('code.ts');
  const h = createHash('sha256');
  for (const f of files.sort()) h.update(`${f}\0`).update(readFileSync(join(root, f)));
  return h.digest('hex').slice(0, 16);
}

async function snapshot(rev) {
  const tmp = mkdtempSync(join(tmpdir(), 'coui-sim-'));
  try {
    const tar = spawnSync(
      'sh',
      ['-c', `git archive ${rev} -- ${pkgRel}/src ${pkgRel}/code.ts ${pkgRel}/reverse | tar -x -C ${tmp}`],
      { cwd: repoRoot, encoding: 'utf8' },
    );
    if (tar.status !== 0) throw new Error(`git archive ${rev}: ${tar.stderr}`);
    const root = join(tmp, pkgRel);
    const registrySource = readFileSync(join(root, 'src/registry.ts'), 'utf8');
    const keyModules = registryKeyModules(registrySource);

    // 엔트리 목록 — 그 커밋의 레지스트리 배열을 실제로 실행해 읽는다.
    const ids = [...keyModules.entries()];
    const probe =
      ids.map(([id, mod]) => `import { ${id} } from './${mod.replace(/\.ts$/, '')}';`).join('\n') +
      `\nconst groups = { ${ids.map(([id]) => id).join(', ')} };\n` +
      `const out = {};\nfor (const [k, g] of Object.entries(groups)) out[k] = g.map((e) => ({ name: e.name, needs: e.needs ?? [], dataSlug: e.dataSlug ?? null, dataFrom: (e.fixture && e.fixture.dataFrom) || [] }));\n` +
      `console.log(JSON.stringify(out));\n`;
    writeFileSync(join(root, 'probe.ts'), probe);
    await esbuild.build({
      entryPoints: [join(root, 'probe.ts')],
      outfile: join(root, 'probe.cjs'),
      bundle: true,
      platform: 'node',
      format: 'cjs',
      target: 'es2017',
      logLevel: 'silent',
      absWorkingDir: root,
    });
    const groups = JSON.parse(
      execFileSync('node', [join(root, 'probe.cjs')], { encoding: 'utf8', maxBuffer: 1 << 26 }).trim().split('\n').pop(),
    );

    // 새 레시피 — 선언 중 이 트리에 없는 경로는 건너뛴다.
    const graph = moduleGraph(await bundleGraph(esbuild, root));
    const base = defaultConfig();
    const present = (p) => graph.modules.has(p);
    const config = {
      nonDrawing: Object.fromEntries(Object.entries(base.nonDrawing).filter(([p]) => present(p))),
      pipelineRoots: base.pipelineRoots.filter(present),
      pipelineGlue: base.pipelineGlue.filter(present),
    };
    const table = entrySourceHashes({
      graph,
      registrySource,
      readFile: (p) => readFileSync(join(root, p)),
      toolchain: toolchainOf(esbuild),
      config,
    });

    // 엔트리 데이터 해시 — `content-hash.ts` 의 `entryDataHashOf` 와 같은 입력.
    const components = JSON.parse(readFileSync(join(root, 'src/data/components.json'), 'utf8')).components;
    const schemaRev = /const kSchemaRev = '([^']*)'/.exec(readFileSync(join(root, 'src/content-hash.ts'), 'utf8'))?.[1] ?? '';
    const slugOf = (name) => name.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase();
    const entryByName = new Map();
    for (const [key, group] of Object.entries(groups)) for (const e of group) entryByName.set(e.name, { ...e, key });

    const shared = sharedTsHash(root);
    const entries = new Map();
    for (const e of entryByName.values()) {
      const data = sha(
        JSON.stringify(components[e.dataSlug ?? slugOf(e.name)] ?? null) +
          e.dataFrom.map((s) => JSON.stringify(components[s] ?? null)).join('') +
          schemaRev,
      );
      const keys = new Set([e.key]);
      const seen = new Set([e.name]);
      const stack = [...e.needs];
      let closed = true;
      while (stack.length > 0) {
        const n = stack.pop();
        if (seen.has(n)) continue;
        seen.add(n);
        const dep = entryByName.get(n);
        if (!dep) {
          closed = false;
          continue;
        }
        keys.add(dep.key);
        for (const x of dep.needs) stack.push(x);
      }
      let source = [...keys].sort().map((k) => `${k}=${table.hashes[k]}`);
      const fallback = !closed || [...keys].some((k) => table.hashes[k] === undefined);
      entries.set(e.name, {
        key: e.key,
        keys: [...keys].sort(),
        newHash: fallback ? `fallback:${shared}:${data}` : `${source.join(',')}:${data}`,
        oldHash: `${shared}:${data}`,
        fallback,
      });
    }
    return { rev, entries, filesByKey: table.filesByKey, groups, unresolved: table.unresolved.length };
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

// ─── 변형 수 (현재 트리, 가짜 Figma 에 빌더를 실제로 돌려 센 값) ─────────────────

function variantCounts() {
  const out = execFileSync('npm', ['run', '--silent', 'audit:sizing'], { encoding: 'utf8', maxBuffer: 1 << 26 });
  const counts = new Map();
  for (const m of out.matchAll(/^\s+SIZING (\S+) :: (\d+) variants?/gm)) counts.set(m[1], Number(m[2]));
  return counts;
}

// ─── 재생 ───────────────────────────────────────────────────────────────────

const pct = (arr, p) => {
  const s = [...arr].sort((a, b) => a - b);
  if (s.length === 0) return 0;
  return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)];
};
const median = (arr) => pct(arr, 50);
const minutes = (sec) => sec / 60;

console.error(`커밋 ${commits.length}개(${since} 이후, ${pkgRel}/src · code.ts) — 스냅샷 ${shas.length}개를 번들한다…`);
const snaps = [];
for (const rev of shas) {
  try {
    snaps.push(await snapshot(rev));
  } catch (err) {
    console.error(`  ✗ ${rev.slice(0, 9)} 스냅샷 실패: ${String(err).split('\n')[0]}`);
    snaps.push(null);
  }
  if (snaps.length % 10 === 0) console.error(`  … ${snaps.length}/${shas.length}`);
}

const counts = variantCounts();
const variants = (name) => counts.get(name) ?? 1;

const rows = [];
let skipped = 0;
for (let i = 1; i < snaps.length; i++) {
  const a = snaps[i - 1];
  const b = snaps[i];
  if (!a || !b) {
    skipped++;
    continue;
  }
  const files = git('diff', '--name-only', shas[i - 1], shas[i], '--', `${pkgRel}/src`, `${pkgRel}/code.ts`)
    .split('\n')
    .filter(Boolean)
    .map((f) => f.slice(pkgRel.length + 1));
  const ts = files.filter((f) => f.endsWith('.ts'));
  const componentTs = ts.filter((f) => f.startsWith('src/components/'));
  const otherTs = ts.filter((f) => !f.startsWith('src/components/'));
  const cls = otherTs.length > 0 ? 'shared' : componentTs.length > 0 ? 'builder' : 'data';

  const oldStale = [];
  const newStale = [];
  for (const [name, e] of b.entries) {
    const p = a.entries.get(name);
    if (!p || p.oldHash !== e.oldHash) oldStale.push(name);
    if (!p || p.newHash !== e.newHash) newStale.push(name);
  }
  const seconds = (names) => names.reduce((s, n) => s + variants(n), 0) * kPooledRate;
  rows.push({
    sha: commits[i - 1].slice(0, 9),
    cls,
    files,
    total: b.entries.size,
    oldStale: oldStale.length,
    newStale: newStale.length,
    oldButton: oldStale.includes('Button'),
    newButton: newStale.includes('Button'),
    oldSec: seconds(oldStale),
    newSec: seconds(newStale),
    newStaleNames: newStale,
  });
}

// ─── 보고 ───────────────────────────────────────────────────────────────────

const stat = (rs, f) => {
  const xs = rs.map(f);
  return `${median(xs).toFixed(0)} / ${pct(xs, 90).toFixed(0)} / ${Math.max(0, ...xs).toFixed(0)}`;
};
const statMin = (rs, f) => {
  const xs = rs.map((r) => minutes(f(r)));
  return `${median(xs).toFixed(1)} / ${pct(xs, 90).toFixed(1)} / ${Math.max(0, ...xs).toFixed(1)}`;
};
const share = (rs, f) => (rs.length === 0 ? '-' : `${((100 * rs.filter(f).length) / rs.length).toFixed(0)}% (${rs.filter(f).length}/${rs.length})`);

const last = [...snaps].reverse().find(Boolean);
console.log(`재생: ${rows.length} 커밋(스냅샷 실패로 건너뜀 ${skipped}) · 엔트리 ${last ? last.entries.size : '?'}개(마지막 스냅샷)`);
console.log(`시간 환산: 변형당 ${kPooledRate.toFixed(2)}초(보정 8개 컴포넌트의 총 초 / 총 변형 수; 컴포넌트별 ${Math.min(...kRates).toFixed(2)}~${Math.max(...kRates).toFixed(2)}초) — 추정\n`);

const groups = [
  ['전체', rows],
  ['(i) 빌더 파일만 바뀐 커밋', rows.filter((r) => r.cls === 'builder')],
  ['(ii) shared 모듈(components/ 밖 .ts)이 바뀐 커밋', rows.filter((r) => r.cls === 'shared')],
  ['데이터(components.json 등)만 바뀐 커밋', rows.filter((r) => r.cls === 'data')],
];
console.log('| 구분 | 커밋 수 | 기존 낡은 엔트리 수 (중앙/p90/최대) | 새 낡은 엔트리 수 (중앙/p90/최대) | Button 낡음: 기존 → 새 | 커밋당 예상 재그리기 분: 기존 (중앙/p90/최대) | 새 (중앙/p90/최대) |');
console.log('|---|---|---|---|---|---|---|');
for (const [label, rs] of groups) {
  console.log(
    `| ${label} | ${rs.length} (${rows.length === 0 ? 0 : Math.round((100 * rs.length) / rows.length)}%) | ${stat(rs, (r) => r.oldStale)} | ${stat(rs, (r) => r.newStale)} | ${share(rs, (r) => r.oldButton)} → ${share(rs, (r) => r.newButton)} | ${statMin(rs, (r) => r.oldSec)} | ${statMin(rs, (r) => r.newSec)} |`,
  );
}

// 하루 단위 — Generate 를 커밋마다 돌리지 않고 하루에 한 번 돌린다면. 그날 첫 커밋 직전 스냅샷과 그날
// 마지막 커밋 스냅샷을 비교한다(같은 엔트리가 고쳐졌다 되돌려지면 그 엔트리는 낡지 않는다).
{
  const dayOf = (i) => git('show', '-s', '--format=%cs', commits[i - 1]);
  const days = new Map();
  for (let i = 1; i < snaps.length; i++) {
    const d = dayOf(i);
    const cur = days.get(d);
    if (!cur) days.set(d, { first: i, last: i });
    else cur.last = i;
  }
  const dayRows = [];
  for (const [day, { first, last: lastI }] of days) {
    const a = snaps[first - 1];
    const b = snaps[lastI];
    if (!a || !b) continue;
    const oldStale = [];
    const newStale = [];
    for (const [name, e] of b.entries) {
      const p = a.entries.get(name);
      if (!p || p.oldHash !== e.oldHash) oldStale.push(name);
      if (!p || p.newHash !== e.newHash) newStale.push(name);
    }
    const sec = (names) => names.reduce((s, n) => s + variants(n), 0) * kPooledRate;
    dayRows.push({
      day,
      commits: lastI - first + 1,
      oldStale: oldStale.length,
      newStale: newStale.length,
      oldButton: oldStale.includes('Button'),
      newButton: newStale.includes('Button'),
      oldSec: sec(oldStale),
      newSec: sec(newStale),
    });
  }
  console.log(`\n하루 단위(Generate 를 하루 한 번 돌린다고 가정, ${dayRows.length}일):`);
  console.log('| 구분 | 일 수 | 낡은 엔트리 수 (중앙/p90/최대) | Button 낡음 | 예상 재그리기 분 (중앙/p90/최대) |');
  console.log('|---|---|---|---|---|');
  console.log(`| 기존 | ${dayRows.length} | ${stat(dayRows, (r) => r.oldStale)} | ${share(dayRows, (r) => r.oldButton)} | ${statMin(dayRows, (r) => r.oldSec)} |`);
  console.log(`| 새 | ${dayRows.length} | ${stat(dayRows, (r) => r.newStale)} | ${share(dayRows, (r) => r.newButton)} | ${statMin(dayRows, (r) => r.newSec)} |`);
}

const fallbackNow = last ? [...last.entries.values()].filter((e) => e.fallback).length : 0;
console.log(`\n폴백(전체 해시로 되돌아간 엔트리): 마지막 스냅샷 ${fallbackNow}개 · 닫힘을 못 구한 키 ${last ? last.unresolved : '?'}개`);

// 새 방식에서 가장 자주 · 많이 무효화를 일으킨 파일 — 커밋 수 × 닿는 엔트리 수.
if (last) {
  const entriesOfKey = new Map(Object.entries(last.groups).map(([k, g]) => [k, g.length]));
  const reach = new Map();
  for (const [key, files] of Object.entries(last.filesByKey)) {
    for (const f of files) reach.set(f, (reach.get(f) ?? 0) + (entriesOfKey.get(key) ?? 0));
  }
  const churn = new Map();
  for (const r of rows) for (const f of r.files) churn.set(f, (churn.get(f) ?? 0) + 1);
  const ranked = [...reach]
    .map(([f, n]) => ({ f, reached: n, commits: churn.get(f) ?? 0 }))
    .filter((x) => x.commits > 0 && x.reached > 0)
    .sort((x, y) => y.commits * y.reached - x.commits * x.reached);
  console.log('\n무효화 기여 상위 5(수정 커밋 수 × 닿는 엔트리 수) — 더 잘게 쪼갤 후보:');
  for (const x of ranked.slice(0, 5)) console.log(`  ${x.f}: 수정 ${x.commits}회 × 엔트리 ${x.reached}개`);
  const everyone = [...reach].filter(([, n]) => n === [...entriesOfKey.values()].reduce((a, b) => a + b, 0)).length;
  console.log(`  (모든 엔트리의 닫힘에 드는 파일 ${everyone}개)`);
}

if (jsonOut) writeFileSync(jsonOut, JSON.stringify({ since, calibration: { pooledRate: kPooledRate }, rows }, null, 2));
