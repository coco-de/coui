#!/usr/bin/env node
// 엔트리 소스 해시 — 번들러의 import 그래프로 "이 엔트리를 그리는 소스" 를 정하고 그
// 닫힘의 해시를 낸다.
//
//   node scripts/entry-source-hash.mjs            번들용: JSON 문자열 리터럴을 stdout 에 쓴다
//                                                  (`--define:__ENTRY_SOURCE_HASHES__="$(…)"`)
//   node scripts/entry-source-hash.mjs --report   사람용: 키마다 모듈 수와 폴백 사유를 표로 쓴다
//
// ## 무엇을 해시하나
//
// 한 엔트리의 그림은 세 갈래에서 온다:
//
//   1. 그 엔트리의 빌더가 놓인 모듈과 그것이 (전이적으로) import 하는 모듈 — 빌더가 부르는
//      공유 그리기 코드까지.
//   2. 생성기가 엔트리마다 캔버스에 적용하는 파이프라인 — 텍스트 스타일 붙이기 · 문서 프레임 ·
//      교체 기본값 복구 · 연결 안 된 속성 정리. 빌더가 import 하지 않지만 세트의 그림을 바꾼다.
//   3. 생성기 자신의 텍스트(`generate.ts`) — 위 단계를 잇는 순서와 조건이 거기 있다.
//
// 닫힘은 파일 하나가 아니라 **import 그래프의 닫힘**이라 빌더끼리의 호출 관계가 들어 있다.
// 계산하지 못하는 경우(동적 import · 번들 밖 외부 모듈 · 닫힘이 선언되지 않은 키)는 키를
// 해시 표에서 뺀다 — 런타임이 그 엔트리를 플러그인 전체 해시로 되돌린다.
//
// 번들 출력(`Function.prototype.toString`)이 아니라 **소스 텍스트**를 해시한다. 번들 출력은
// 최상위 이름이 충돌하면 숫자 접미사가 붙고 구문 낮춤 헬퍼가 들어가므로, 코드가 안 바뀌어도
// 다른 모듈 하나가 추가되면 바뀐다.

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/** 번들 설정 — 그래프를 만드는 쪽과 `package.json` 의 번들 단계가 같은 값을 쓴다. */
export const kBundleEntry = 'code.ts';
export const kBundleTarget = 'es2017';

/**
 * 해시에 넣지 않는 모듈 — **그림에 닿지 않는다고 선언한** 것. 이 모듈들은 텍스트가 해시에
 * 들어가지 않고, 닫힘을 따라 들어가지도 않는다(그 너머는 다른 길로 닿아야 한다).
 *
 * 값은 이유다. 이유 없는 제외는 다음 사람이 "왜 빠졌지" 를 재조사하게 만든다.
 * 선언한 경로가 그래프에 없으면 낡은 선언이므로 계산이 실패한다.
 */
export const kNonDrawingModules = {
  'src/registry.ts':
    '어느 배열이 레지스트리를 이루는지만 말한다. 엔트리의 키는 이 파일의 import 에서 정해지고 `needs` 는 키 목록으로 해시에 든다.',
  'src/content-hash.ts': '해시 레시피 자신이다. `kSchemaRev` 는 데이터 해시를 거쳐 들어간다.',
  'src/entry-source.ts': '해시 레시피의 입력을 읽는 배관이다.',
  'src/build-hash.ts': '빌드 신원(전체 해시 · 빌드 ref)을 읽는 배관이다. 폴백 해시는 값으로 들어간다.',
  'src/hash.ts': '`fnv1a` — 해시 함수 자신이다.',
  'src/stale-sets.ts': '읽기 전용 "낡은 세트 보기" 다. 캔버스에 쓰지 않는다.',
  'src/overlapping-siblings.ts': '읽기 전용 "겹친 형제 보기" 다. 감지만 하고 지우지 않는다.',
  'src/orphan-nodes.ts': '읽기 전용 "고아 노드 보기" 다.',
  'src/component-index-cache.ts': '실행 사이에 기억하는 노드 id 색인이다. 조회를 빠르게 할 뿐 그리지 않는다.',
  'src/generation-stamp.ts': '누가 어느 빌드로 그렸는지의 기록(plugin data)이다.',
  'src/run-lock.ts': '실행 잠금 기록이다.',
  'src/last-step.ts': '마지막 단계 · 성장 자국(plugin data)이다.',
  'src/designer-parity.ts':
    '손 편집 보존과 리디자인 대조다. 캔버스를 읽고 세트 옆에 사본을 두지만 세트 자신의 그림은 쓰지 않는다.',
  'src/summary-format.ts': '로그 요약 문구다.',
  'src/growth.ts': '엔트리당 비용 통계다.',
  // components.json 은 데이터다. 엔트리가 읽는 부분은 엔트리 데이터 해시(`entryDataHashOf`)가 맡는다.
  'src/data/components.json':
    '엔트리 데이터 해시가 컴포넌트 단위로 맡는다(최상위 `typography` · `surfaceGlass` · `meta` 는 맡지 않는다 — PR 본문 "알려진 한계").',
};

/**
 * 생성기가 **엔트리마다** 캔버스에 적용하는 모듈. 빌더가 import 하지 않아 빌더 닫힘 밖에
 * 있지만 세트의 그림을 바꾼다 — 닫힘을 계산해 모든 엔트리의 해시에 넣는다.
 */
export const kPipelineRoots = [
  'src/text-style-attach.ts',
  'src/docs-frames.ts',
  'src/swap-default-repair.ts',
  'src/unbound-props.ts',
];

/**
 * 텍스트만 해시에 넣는 파일 — import 를 따라가지 않는다. `generate.ts` 는 위 단계를 잇는
 * 순서와 조건을 갖지만, 레지스트리 · 실행 잠금 · 보고 모듈을 import 하므로 닫힘을 따라가면
 * 모든 빌더와 읽기 전용 모듈이 한꺼번에 들어온다.
 */
export const kPipelineGlue = ['src/generate.ts'];

const sha256 = (data) => createHash('sha256').update(data).digest('hex');

/**
 * esbuild metafile → 모듈 그래프. 실제로 번들에 들어온 import 만 간선이다.
 *
 * esbuild 는 값으로 쓰이지 않는 TS import(타입 · 미사용)를 지우고 metafile 에는
 * `external: true` 와 해석되지 않은 상대 경로로 남긴다 — 실행 시간에는 존재하지 않는
 * 의존이라 간선이 아니다. 번들 밖 외부 모듈 · 동적 import · require 는 닫힘을 계산할 수
 * 없으므로 그 모듈을 `opaque` 로 표시한다.
 */
export function moduleGraph(metafile) {
  const edges = new Map();
  const opaque = new Map();
  for (const [mod, info] of Object.entries(metafile.inputs)) {
    const out = [];
    for (const imp of info.imports) {
      if (imp.path === '<runtime>') continue;
      if (imp.kind !== 'import-statement') {
        opaque.set(mod, `${imp.kind} ${imp.path}`);
        continue;
      }
      if (imp.external) {
        if (imp.path.startsWith('.')) continue; // 값으로 쓰이지 않아 지워진 import
        opaque.set(mod, `external ${imp.path}`);
        continue;
      }
      out.push(imp.path);
    }
    edges.set(mod, out);
  }
  return { edges, opaque, modules: new Set(edges.keys()) };
}

/**
 * `roots` 에서 닿는 모듈의 집합. `cuts` 는 들어오지도 지나가지도 않는다.
 * 닫힘 안에 `opaque` 모듈이 하나라도 있으면 `{ files: null, why }` — 계산하지 못했다.
 */
export function closureOf(graph, roots, cuts) {
  const seen = new Set();
  const stack = [...roots];
  while (stack.length > 0) {
    const mod = stack.pop();
    if (seen.has(mod) || cuts.has(mod)) continue;
    seen.add(mod);
    const why = graph.opaque.get(mod);
    if (why !== undefined) return { files: null, why: `${mod}: ${why}` };
    for (const dep of graph.edges.get(mod) ?? []) stack.push(dep);
  }
  return { files: seen, why: null };
}

/** 해시 입력 — 도구 지문 + (경로, 내용) 정렬 목록. 내용이 같아도 구성이 다르면 값이 다르다. */
export function hashFiles(files, readFile, toolchain) {
  const h = createHash('sha256');
  h.update(`${toolchain}\n`);
  for (const f of [...files].sort()) h.update(`${f}\0${sha256(readFile(f))}\n`);
  return h.digest('hex').slice(0, 16);
}

/** registry.ts 의 `import { A, B } from './components/x'` → 식별자(키) → 모듈 경로. */
export function registryKeyModules(registrySource) {
  const out = new Map();
  const re = /import\s*\{([^}]*)\}\s*from\s*'\.\/components\/([\w-]+)'/g;
  let m;
  while ((m = re.exec(registrySource)) !== null) {
    for (const raw of m[1].split(',')) {
      const id = raw.trim().split(/\s+as\s+/).pop().trim();
      if (id !== '') out.set(id, `src/components/${m[2]}.ts`);
    }
  }
  return out;
}

/** 선언한 경로가 그래프에 없으면 낡은 선언이다. */
export function checkDeclarations(graph, config = defaultConfig()) {
  const problems = [];
  for (const p of [
    ...Object.keys(config.nonDrawing),
    ...config.pipelineRoots,
    ...config.pipelineGlue,
  ]) {
    if (!graph.modules.has(p)) problems.push(`${p}: 선언했지만 번들 그래프에 없다`);
  }
  return problems;
}

export function defaultConfig() {
  return {
    nonDrawing: kNonDrawingModules,
    pipelineRoots: kPipelineRoots,
    pipelineGlue: kPipelineGlue,
  };
}

/**
 * 키(레지스트리 배열의 식별자)마다 소스 해시를 낸다.
 *
 * 반환의 `hashes` 에는 **계산한 키만** 들어간다 — 빠진 키는 런타임이 전체 해시로 되돌린다.
 * `unresolved` 가 왜 빠졌는지를 말한다.
 */
export function entrySourceHashes({ graph, registrySource, readFile, toolchain, config = defaultConfig() }) {
  const cuts = new Set(Object.keys(config.nonDrawing));
  const keyModules = registryKeyModules(registrySource);
  const hashes = {};
  const unresolved = [];
  const filesByKey = {};

  const pipeline = closureOf(graph, config.pipelineRoots, cuts);
  for (const [key, mod] of keyModules) {
    if (pipeline.files === null) {
      unresolved.push({ key, why: `파이프라인 닫힘을 계산하지 못했다 — ${pipeline.why}` });
      continue;
    }
    if (!graph.modules.has(mod)) {
      unresolved.push({ key, why: `${mod} 가 번들 그래프에 없다` });
      continue;
    }
    const own = closureOf(graph, [mod], cuts);
    if (own.files === null) {
      unresolved.push({ key, why: `닫힘을 계산하지 못했다 — ${own.why}` });
      continue;
    }
    const files = new Set([...own.files, ...pipeline.files, ...config.pipelineGlue]);
    filesByKey[key] = files;
    hashes[key] = hashFiles(files, readFile, toolchain);
  }
  return { hashes, unresolved, filesByKey, keyModules, pipelineFiles: pipeline.files };
}

/** esbuild 로 번들 그래프를 얻는다 — 실제 번들과 같은 진입점 · 타깃. */
export async function bundleGraph(esbuild, cwd = process.cwd()) {
  const result = await esbuild.build({
    entryPoints: [kBundleEntry],
    bundle: true,
    target: kBundleTarget,
    write: false,
    metafile: true,
    logLevel: 'silent',
    absWorkingDir: cwd,
  });
  return result.metafile;
}

export const toolchainOf = (esbuild) => `esbuild ${esbuild.version} target ${kBundleTarget}`;

async function main() {
  const esbuild = await import('esbuild');
  const metafile = await bundleGraph(esbuild);
  const graph = moduleGraph(metafile);
  const problems = checkDeclarations(graph);
  if (problems.length > 0) {
    for (const p of problems) console.error(`❌ ${p}`);
    process.exit(1);
  }
  const result = entrySourceHashes({
    graph,
    registrySource: readFileSync('src/registry.ts', 'utf8'),
    readFile: (p) => readFileSync(p),
    toolchain: toolchainOf(esbuild),
  });
  if (result.keyModules.size === 0) {
    console.error('❌ registry.ts 에서 `./components/*` import 를 하나도 찾지 못했다 — 키를 정할 수 없다.');
    process.exit(1);
  }
  const closed = Object.keys(result.hashes).length;
  console.error(
    `엔트리 소스 해시: 키 ${result.keyModules.size}개 중 닫힘 ${closed}개 · 전체 해시 폴백 ${result.unresolved.length}개`,
  );
  for (const u of result.unresolved) console.error(`  ↩ ${u.key}: ${u.why}`);
  if (process.argv.includes('--report')) {
    for (const [key, mod] of result.keyModules) {
      const files = result.filesByKey[key];
      console.error(`  ${key.padEnd(22)} ${mod.padEnd(38)} ${files ? `${files.size} 파일` : '폴백'}`);
    }
    return;
  }
  // 번들 단계가 `--define:__ENTRY_SOURCE_HASHES__="$(…)"` 로 받는다 — JSON 문자열 리터럴.
  process.stdout.write(JSON.stringify(JSON.stringify(result.hashes)));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
