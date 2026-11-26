#!/usr/bin/env node
// 게시 표면 지문과 게시 원장(`PUBLISHED.json`) — "지금 Community 에 올라간 것이
// 어느 커밋인가" 와 "게시를 잊었나" 를 Figma 에 묻지 않고 답한다.
//
// ## 왜 원장인가
//
// classic 플러그인의 게시는 Figma 데스크톱 앱에서만 된다 — 공식 API 도, 무인
// CI 로 쓸 수 있는 비공식 경로도 없다. 공개본을 내려받아 대조하는 길도 막혀
// 있다(익명 조회가 봇 완화에 걸린다). 리포는 원격 상태를 **읽을 수 없으므로**,
// 원장에 적는 행위가 곧 "그 지문을 게시했다" 는 선언이 된다. 그 기록은 게시의
// 마지막 단계(`figma-plugin-publish-record` 워크플로 dispatch)로 묶여 있어 따로
// 기억할 일이 아니다.
//
// ## 왜 kSharedSourceHash 가 아닌가
//
// 그 해시는 **무효화용**이다 — `src/data/*` 를 일부러 빼고 `ui.html`·`manifest.json`
// 은 아예 안 본다(`build-hash.ts` 가 그 트레이드오프를 적어 둔다). 범위를 넓히면
// 세트별 스킵 판정의 입도가 깨진다. 게시 지문은 **실제로 올라가는 파일** 위의 별도
// 값이다: `manifest.json` 과, manifest 가 가리키는 `main`·`ui`.
//
// ## 번들 안의 빌드 ref 는 지문에서 뺀다
//
// `code.js` 에는 `kBuildRef`(branch@commit)가 구워진다. 그대로 해시하면 플러그인
// 코드가 한 글자도 안 바뀐 커밋마다 지문이 바뀌어, 원장과 늘 어긋나는 가드가
// 된다. 그래서 그 한 리터럴만 자리표시자로 바꾼 뒤 해시한다 — 코드가 바뀌면
// `kSharedSourceHash` 리터럴이 바뀌므로 지문도 따라 바뀐다. 운영 번들에서 그
// 리터럴을 **찾지 못하면 던진다**: 조용히 못 뺀 지문은 매 커밋 거짓 drift 를 낸다.
//
// 지문은 같은 환경에서 잰 것끼리만 비교된다 — 기록도 판정도 GitHub 러너(ubuntu ·
// node 버전 고정 · lockfile 의 esbuild)에서 한다. 로컬 빌드의 지문을 원장과
// 견주지 않는다.
//
// ## 원장은 무효화 해시도 함께 적는다 — 소급 커밋 귀속
//
// 지문은 게시 판정용이고, 캔버스 밖으로 나가는 산출물(fidelity 리포트의
// `buildHash`, 디자이너 대조 파일의 `sourceHash`, 세트 스탬프)은 **`kSharedSourceHash`**
// 를 싣는다. 원장이 그 값을 `sharedSourceHash` 로 같이 적어 두면, 산출물의 해시를
// `PUBLISHED.json` 의 git 이력에서 찾아(`git log -S<hash> -- PUBLISHED.json`) 그 게시가
// 적은 `commitSha` 로 되짚을 수 있다 — 산출물 쪽에는 새 배선이 필요 없다. 이 값은
// 판정에 쓰지 않는다(판정은 지문이 한다). 게시한 번들에서 **읽어 오는** 값이라 사람이
// 옮겨 적지 않고, 구워지지 않은 dev 번들로는 기록을 거부한다.
//
//   node scripts/publish-fingerprint.mjs compute          지문 JSON 출력 (code.js 필요)
//   node scripts/publish-fingerprint.mjs validate         원장 형식만 검사 (번들 불필요)
//   node scripts/publish-fingerprint.mjs check            지문 ↔ 원장 판정 JSON, exit 0
//   node scripts/publish-fingerprint.mjs record --label <Figma 버전> --by <누가> --commit <sha>
//                                                         원장을 지금 지문으로 다시 쓴다
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

export const kLedgerFile = 'PUBLISHED.json';
export const kBuildRefPlaceholder = '<build-ref>';

const kLedgerFields = [
  'publishFingerprint',
  'sharedSourceHash',
  'commitSha',
  'figmaVersionLabel',
  'publishedAt',
  'publishedBy',
];
const kBuildRefLiteral = /(kBuildRef = true \? )"[^"]*"/;
const kSharedHashLiteral = /kSharedSourceHash = true \? "([0-9a-f]{16})"/;

/** `code.js` with the baked build ref replaced by a fixed placeholder. A
 *  production bundle (one carrying a real `kSharedSourceHash`) that has no
 *  recognisable ref literal is an error, not a pass-through. */
export function neutralizeBuildRef(bundle) {
  if (kBuildRefLiteral.test(bundle)) {
    return bundle.replace(kBuildRefLiteral, `$1"${kBuildRefPlaceholder}"`);
  }
  if (kSharedHashLiteral.test(bundle)) {
    throw new Error(
      'code.js 에 kSharedSourceHash 는 구워져 있는데 kBuildRef 리터럴을 찾지 못했다 — ' +
        '빌드 ref 를 빼지 못한 지문은 매 커밋 거짓 drift 를 낸다. esbuild 출력 모양이 바뀌었는지 확인하라.',
    );
  }
  return bundle;
}

/** The `kSharedSourceHash` baked into a production bundle, or `null` for a
 *  bundle that was not built with the define (a harness / dev bundle). */
export function sharedSourceHashOf(bundle) {
  const match = kSharedHashLiteral.exec(bundle);
  return match === null ? null : match[1];
}

/** The files a Figma publish uploads, in a fixed order: the manifest first,
 *  then what it names as `main` and `ui`. */
export function publishedFilesOf(manifestText) {
  const manifest = JSON.parse(manifestText);
  const files = ['manifest.json'];
  for (const key of ['main', 'ui']) {
    if (typeof manifest[key] === 'string' && !files.includes(manifest[key])) files.push(manifest[key]);
  }
  return files;
}

/** sha256 over `name\0content\0` of each file, the main bundle neutralised —
 *  plus the main bundle's baked `kSharedSourceHash`, which the ledger records
 *  so an artefact carrying that hash can be traced back to the published
 *  commit. Pure over a `read(name) → string` so the selftest drives it without
 *  a build. */
export function publishFingerprint(read) {
  const manifestText = read('manifest.json');
  const manifest = JSON.parse(manifestText);
  const files = publishedFilesOf(manifestText);
  const hash = createHash('sha256');
  let sharedSourceHash = null;
  for (const name of files) {
    let content = read(name);
    if (name === manifest.main) {
      sharedSourceHash = sharedSourceHashOf(content);
      content = neutralizeBuildRef(content);
    }
    hash.update(name).update('\0').update(content).update('\0');
  }
  return { publishFingerprint: hash.digest('hex').slice(0, 32), sharedSourceHash, files };
}

/**
 * The ledger, parsed. `unrecorded` is a legal state — the file exists before
 * anyone has published through the record workflow — and is told apart from a
 * recorded entry and from a malformed file, which throws.
 */
export function parseLedger(text) {
  const value = JSON.parse(text);
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${kLedgerFile}: 객체가 아니다`);
  }
  for (const field of kLedgerFields) {
    if (!(field in value)) throw new Error(`${kLedgerFile}: "${field}" 필드가 없다`);
  }
  if (value.publishFingerprint === null) {
    for (const field of kLedgerFields) {
      if (value[field] !== null) {
        throw new Error(`${kLedgerFile}: 미기록인데 "${field}" 가 채워져 있다 — 반쯤 쓴 원장이다`);
      }
    }
    return { state: 'unrecorded' };
  }
  for (const field of kLedgerFields) {
    if (typeof value[field] !== 'string' || value[field].length === 0) {
      throw new Error(`${kLedgerFile}: 기록된 원장인데 "${field}" 가 비어 있다`);
    }
  }
  if (!/^[0-9a-f]{32}$/.test(value.publishFingerprint)) {
    throw new Error(`${kLedgerFile}: publishFingerprint 가 32자 hex 가 아니다`);
  }
  if (!/^[0-9a-f]{16}$/.test(value.sharedSourceHash)) {
    throw new Error(`${kLedgerFile}: sharedSourceHash 가 16자 hex 가 아니다 — dev 번들로 기록했나`);
  }
  if (!/^[0-9a-f]{7,40}$/.test(value.commitSha)) {
    throw new Error(`${kLedgerFile}: commitSha 가 커밋 해시 모양이 아니다`);
  }
  if (Number.isNaN(Date.parse(value.publishedAt))) {
    throw new Error(`${kLedgerFile}: publishedAt 이 날짜가 아니다`);
  }
  return { state: 'recorded', ...value };
}

/** `same` · `drift` · `unrecorded` — what the push-to-main job turns into the
 *  single tracking issue (open/update on the latter two, close on `same`). */
export function driftVerdict(ledger, current) {
  if (ledger.state === 'unrecorded') {
    return { status: 'unrecorded', current: current.publishFingerprint };
  }
  if (ledger.publishFingerprint === current.publishFingerprint) {
    return { status: 'same', current: current.publishFingerprint, ledger };
  }
  return { status: 'drift', current: current.publishFingerprint, ledger };
}

/** The ledger a publish writes. A bundle without a baked `kSharedSourceHash`
 *  (built without the define) is not a published bundle — refused. */
export function ledgerRecord(current, meta) {
  if (typeof current.sharedSourceHash !== 'string') {
    throw new Error('번들에 kSharedSourceHash 가 구워져 있지 않다 — npm run build 로 구운 번들만 기록한다');
  }
  return {
    publishFingerprint: current.publishFingerprint,
    sharedSourceHash: current.sharedSourceHash,
    commitSha: meta.commit,
    figmaVersionLabel: meta.label,
    publishedAt: meta.at,
    publishedBy: meta.by,
  };
}

function argOf(argv, flag) {
  const i = argv.indexOf(flag);
  return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
}

function main(argv, root) {
  const read = (name) => {
    const path = join(root, name);
    if (!existsSync(path)) throw new Error(`${name} 가 없다 — 먼저 npm run build (CI 에서만)`);
    return readFileSync(path, 'utf8');
  };
  const mode = argv[0] ?? 'compute';
  if (mode === 'validate') {
    const ledger = parseLedger(read(kLedgerFile));
    console.log(JSON.stringify({ ok: true, state: ledger.state }));
    return 0;
  }
  if (mode === 'compute') {
    console.log(JSON.stringify(publishFingerprint(read)));
    return 0;
  }
  if (mode === 'check') {
    const verdict = driftVerdict(parseLedger(read(kLedgerFile)), publishFingerprint(read));
    console.log(JSON.stringify(verdict));
    return 0;
  }
  if (mode === 'record') {
    const label = argOf(argv, '--label');
    const by = argOf(argv, '--by');
    const commit = argOf(argv, '--commit');
    if (!label || !by || !commit) {
      console.error('record 에는 --label · --by · --commit 이 모두 필요하다');
      return 2;
    }
    const next = ledgerRecord(publishFingerprint(read), { label, by, commit, at: new Date().toISOString() });
    parseLedger(JSON.stringify(next)); // 쓰기 전에 자기 형식을 통과하는지
    writeFileSync(join(root, kLedgerFile), `${JSON.stringify(next, null, 2)}\n`);
    console.log(JSON.stringify(next));
    return 0;
  }
  console.error(`unknown mode: ${mode} (compute|validate|check|record)`);
  return 2;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  try {
    process.exit(main(process.argv.slice(2), process.cwd()));
  } catch (e) {
    console.error(`✗ ${e instanceof Error ? e.message : String(e)}`);
    process.exit(1);
  }
}
