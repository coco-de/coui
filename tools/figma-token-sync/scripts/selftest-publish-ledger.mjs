#!/usr/bin/env node
// Self-test for scripts/publish-fingerprint.mjs (#4633) — 게시 지문과 원장.
//
// 이 장치가 틀리는 방식은 둘이다:
//
//   1. **지문이 게시 표면이 아닌 것에 흔들린다** — 코드가 그대로인데 커밋마다
//      바뀌면(빌드 ref) 추적 이슈가 매 푸시 열리고 곧 무시된다. 반대로 게시 표면이
//      바뀌었는데 안 흔들리면 "게시 필요" 가 영영 안 뜬다. 둘 다 여기서 고정한다.
//   2. **원장을 잘못 읽는다** — 미기록 · 기록 · 반쯤 쓴 원장을 구별하지 못하면
//      미기록을 drift 로, 깨진 파일을 same 으로 읽는다.
//
// 번들 없이 돈다 — 지문 함수는 `read(name)` 을 받는다.

import {
  driftVerdict,
  kBuildRefPlaceholder,
  ledgerRecord,
  neutralizeBuildRef,
  parseLedger,
  publishFingerprint,
  publishedFilesOf,
  sharedSourceHashOf,
} from './publish-fingerprint.mjs';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

let failures = 0;
function check(label, fn) {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${e instanceof Error ? e.message : String(e)}`);
  }
}
function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}
function throws(fn, what) {
  try {
    fn();
  } catch {
    return;
  }
  throw new Error(`${what}: expected a throw`);
}

const manifest = JSON.stringify({ name: 'CoUI Token Sync', main: 'code.js', ui: 'ui.html' });
const bundle = (hash, ref, body = 'doWork();') =>
  `(() => {\n  var kSharedSourceHash = true ? "${hash}" : "dev";\n  var kBuildRef = true ? "${ref}" : "dev";\n  ${body}\n})();\n`;
const files = (over = {}) => {
  const all = { 'manifest.json': manifest, 'code.js': bundle('abcdef0123456789', 'main@1111111'), 'ui.html': '<pre id="log"></pre>', ...over };
  return (name) => {
    if (!(name in all)) throw new Error(`no ${name}`);
    return all[name];
  };
};

console.log('publish fingerprint — what it covers');
check('the published files come from the manifest, manifest first', () => {
  const list = publishedFilesOf(manifest);
  assert(JSON.stringify(list) === JSON.stringify(['manifest.json', 'code.js', 'ui.html']), JSON.stringify(list));
});
check('the same surface gives the same fingerprint', () => {
  assert(publishFingerprint(files()).publishFingerprint === publishFingerprint(files()).publishFingerprint, 'unstable');
});
check('a different build ref alone does NOT move it (same code, another commit)', () => {
  const a = publishFingerprint(files()).publishFingerprint;
  const b = publishFingerprint(files({ 'code.js': bundle('abcdef0123456789', 'HEAD@2222222') })).publishFingerprint;
  assert(a === b, `${a} ≠ ${b}`);
});
check('a code change moves it (the shared-source hash literal changes)', () => {
  const a = publishFingerprint(files()).publishFingerprint;
  const b = publishFingerprint(files({ 'code.js': bundle('0123456789abcdef', 'main@1111111') })).publishFingerprint;
  assert(a !== b, 'did not move');
});
check('a UI change moves it', () => {
  const a = publishFingerprint(files()).publishFingerprint;
  const b = publishFingerprint(files({ 'ui.html': '<pre id="log"></pre><button>new</button>' })).publishFingerprint;
  assert(a !== b, 'did not move');
});
check('a manifest change moves it', () => {
  const a = publishFingerprint(files()).publishFingerprint;
  const b = publishFingerprint(
    files({ 'manifest.json': JSON.stringify({ name: 'CoUI Token Sync', main: 'code.js', ui: 'ui.html', api: '1.0.0' }) }),
  ).publishFingerprint;
  assert(a !== b, 'did not move');
});
check('the build ref is replaced, not dropped', () => {
  assert(neutralizeBuildRef(bundle('abcdef0123456789', 'main@1')).includes(`"${kBuildRefPlaceholder}"`), 'placeholder missing');
});
check('the fingerprint carries the bundle\'s baked kSharedSourceHash (for back-attribution)', () => {
  assert(publishFingerprint(files()).sharedSourceHash === 'abcdef0123456789', 'not the baked literal');
  assert(sharedSourceHashOf('var x = 1;') === null, 'a dev bundle has no hash');
});
check('a dev bundle (no baked hash) cannot be recorded', () => {
  const dev = publishFingerprint(files({ 'code.js': '(() => { doWork(); })();' }));
  assert(dev.sharedSourceHash === null, 'dev bundle hash');
  throws(() => ledgerRecord(dev, { commit: '1234abc', label: 'v12', by: 'x', at: '2026-09-28T00:00:00.000Z' }), 'dev record');
});
check('a production bundle without a recognisable ref literal throws (no silent per-commit drift)', () => {
  throws(() => neutralizeBuildRef('var kSharedSourceHash = true ? "abcdef0123456789" : "dev"; var ref = "main@1";'), 'shape change');
});

console.log('publish ledger — the three states');
const unrecorded = JSON.stringify({
  publishFingerprint: null,
  sharedSourceHash: null,
  commitSha: null,
  figmaVersionLabel: null,
  publishedAt: null,
  publishedBy: null,
});
const recorded = (fp) =>
  JSON.stringify(
    ledgerRecord(
      { publishFingerprint: fp, sharedSourceHash: 'abcdef0123456789' },
      { commit: '1234abc', label: 'v12', by: 'designcocode', at: '2026-09-28T00:00:00.000Z' },
    ),
  );
check('all-null is unrecorded', () => assert(parseLedger(unrecorded).state === 'unrecorded', 'state'));
check('a record written by ledgerRecord parses back', () => {
  const fp = publishFingerprint(files()).publishFingerprint;
  const l = parseLedger(recorded(fp));
  assert(l.state === 'recorded' && l.publishFingerprint === fp && l.figmaVersionLabel === 'v12', JSON.stringify(l));
  assert(l.sharedSourceHash === 'abcdef0123456789', 'the shared-source hash round-trips');
});
check('a ledger without the shared-source hash field throws (old five-field shape)', () => {
  const { sharedSourceHash: _, ...rest } = JSON.parse(unrecorded);
  throws(() => parseLedger(JSON.stringify(rest)), 'missing sharedSourceHash');
});
check('a half-written ledger throws', () => {
  throws(() => parseLedger(JSON.stringify({ ...JSON.parse(unrecorded), figmaVersionLabel: 'v12' })), 'half');
});
check('a missing field throws', () => {
  const { publishedBy: _, ...rest } = JSON.parse(unrecorded);
  throws(() => parseLedger(JSON.stringify(rest)), 'missing');
});
check('a malformed fingerprint / commit / date throws', () => {
  const ok = JSON.parse(recorded('0'.repeat(32)));
  throws(() => parseLedger(JSON.stringify({ ...ok, publishFingerprint: 'xyz' })), 'fingerprint');
  throws(() => parseLedger(JSON.stringify({ ...ok, commitSha: 'not a sha' })), 'commit');
  throws(() => parseLedger(JSON.stringify({ ...ok, publishedAt: 'yesterday' })), 'date');
  throws(() => parseLedger(JSON.stringify({ ...ok, sharedSourceHash: 'dev' })), 'shared-source hash');
});

console.log('publish ledger — the verdict');
check('unrecorded is its own verdict, not drift', () => {
  const v = driftVerdict(parseLedger(unrecorded), publishFingerprint(files()));
  assert(v.status === 'unrecorded', v.status);
});
check('same fingerprint → same', () => {
  const current = publishFingerprint(files());
  assert(driftVerdict(parseLedger(recorded(current.publishFingerprint)), current).status === 'same', 'same');
});
check('different fingerprint → drift, naming both', () => {
  const current = publishFingerprint(files());
  const v = driftVerdict(parseLedger(recorded('f'.repeat(32))), current);
  assert(v.status === 'drift' && v.current === current.publishFingerprint && v.ledger.publishFingerprint === 'f'.repeat(32), JSON.stringify(v));
});

console.log('publish ledger — the committed file and the wiring');
const here = (...p) => join(process.cwd(), ...p);
const repo = (...p) => join(process.cwd(), '..', '..', ...p);
check('the committed PUBLISHED.json parses', () => {
  parseLedger(readFileSync(here('PUBLISHED.json'), 'utf8'));
});
check('the record workflow computes, writes and opens a PR', () => {
  const wf = readFileSync(repo('.github', 'workflows', 'figma-plugin-publish-record.yaml'), 'utf8');
  assert(/workflow_dispatch:/.test(wf), 'dispatch-only');
  assert(/publish-fingerprint\.mjs record/.test(wf), 'writes the ledger through this script');
  assert(/create-github-app-token/.test(wf), 'opens its PR with the App token (a GITHUB_TOKEN PR gets no checks)');
  assert(/upload-artifact/.test(wf), 'keeps the published bundle once');
  assert(/sharedSourceHash/.test(wf), 'the ledger PR names the shared-source hash (back-attribution key)');
});
check('the package workflow judges drift on push to main', () => {
  const wf = readFileSync(repo('.github', 'workflows', 'figma-plugin-package.yaml'), 'utf8');
  assert(/publish-fingerprint\.mjs check/.test(wf), 'drift check');
  assert(/github\.event_name == 'push'/.test(wf), 'push-only');
});
check('the ledger is registered in CODEOWNERS', () => {
  assert(/^\/tools\/figma-token-sync\/PUBLISHED\.json\s+@/m.test(readFileSync(repo('.github', 'CODEOWNERS'), 'utf8')), 'CODEOWNERS');
});
check('this selftest is in the chain', () => {
  const pkg = JSON.parse(readFileSync(here('package.json'), 'utf8'));
  assert(/ npm run selftest:publish-ledger( |$)/.test(pkg.scripts.selftest), 'chain');
});

if (failures > 0) {
  console.error(`\n${failures} failure(s)`);
  process.exit(1);
}
console.log('\nAll publish-ledger self-tests passed.');
