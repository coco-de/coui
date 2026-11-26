#!/usr/bin/env node
// 번들 주인 표식 — `code.js` 는 이 컴퓨터에 파일 하나뿐이라 마지막에 빌드한 쪽이
// 이긴다. 다른 워크트리(세션)가 자기 브랜치로 구워 Figma 에서 테스트 중이던 번들을
// main 재빌드가 덮은 일이 실제로 있었다. 이 스크립트는 빌드 전에 "지금 깔린 번들이
// 누구 것인가" 를 사이드카(`code.js.owner.json`)로 확인하고, 다른 워크트리·다른
// 브랜치의 번들이면 멈춘다. `COUI_BUNDLE_FORCE=1` 로 명시 우회.
//
//   node scripts/bundle-owner.mjs check   빌드 전 — 남의 번들이면 exit 1
//   node scripts/bundle-owner.mjs stamp   빌드 후 — 사이드카 기록
//   node scripts/bundle-owner.mjs show    사이드카 출력
//
// 사이드카는 gitignore 대상(번들과 같은 수명). CI 의 새 체크아웃에는 사이드카가
// 없으므로 check 는 그냥 통과한다 — 이 가드는 사람 컴퓨터의 공유 번들만 본다.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { hostname } from 'node:os';

const BUNDLE = 'code.js';
const SIDECAR = 'code.js.owner.json';
const HASH_RE = /kSharedSourceHash = true \? "([0-9a-f]{16})"/;

function sh(cmd) {
  try {
    return execSync(cmd, { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  } catch {
    return '';
  }
}

function bundleHash() {
  if (!existsSync(BUNDLE)) return null;
  const m = readFileSync(BUNDLE, 'utf8').match(HASH_RE);
  return m ? m[1] : 'dev';
}

function here() {
  const worktree = sh('git rev-parse --show-toplevel');
  const sha = sh('git rev-parse --short=9 HEAD');
  let ref = sh('git rev-parse --abbrev-ref HEAD');
  if (ref === 'HEAD' || ref === '') ref = `detached@${sha}`;
  return { worktree, ref, sha };
}

function readOwner() {
  if (!existsSync(SIDECAR)) return null;
  try {
    return JSON.parse(readFileSync(SIDECAR, 'utf8'));
  } catch {
    return null;
  }
}

function fmt(o) {
  return `${o.ref} (${o.sha}) · ${o.worktree} · ${o.builtAt}${o.host ? ` · ${o.host}` : ''}`;
}

const mode = process.argv[2] ?? 'check';

if (mode === 'show') {
  const owner = readOwner();
  console.log(owner ? fmt(owner) : '(사이드카 없음)');
  process.exit(0);
}

if (mode === 'stamp') {
  const me = here();
  const record = { ...me, hash: bundleHash(), builtAt: new Date().toISOString(), host: hostname() };
  writeFileSync(SIDECAR, `${JSON.stringify(record, null, 2)}\n`);
  console.log(`🔏 번들 주인 기록: ${fmt(record)}`);
  process.exit(0);
}

if (mode !== 'check') {
  console.error(`unknown mode: ${mode} (check|stamp|show)`);
  process.exit(2);
}

const hash = bundleHash();
if (hash === null) process.exit(0); // 번들 없음 — 지킬 것이 없다

const owner = readOwner();
if (!owner) {
  console.log('ℹ️  깔린 번들에 주인 기록이 없다 — 덮어쓴다 (이전 빌드가 stamp 를 남기지 않음).');
  process.exit(0);
}
if (owner.hash !== hash) {
  console.log('ℹ️  깔린 번들이 주인 기록과 다르다 (stamp 없이 다시 빌드됨) — 덮어쓴다.');
  process.exit(0);
}

const me = here();
const sameWorktree = owner.worktree === me.worktree;
const sameRef = owner.ref === me.ref;
if (sameWorktree || sameRef) process.exit(0);

if (process.env.COUI_BUNDLE_FORCE === '1') {
  console.log(`⚠️  COUI_BUNDLE_FORCE=1 — 남의 번들을 덮는다: ${fmt(owner)}`);
  process.exit(0);
}

console.error('');
console.error('⛔ 깔린 번들은 다른 워크트리·다른 브랜치가 구운 것이다. 덮으면 그 세션이 Figma 에서');
console.error('   테스트 중인 번들이 사라진다 (실제로 한 번 그렇게 덮었다).');
console.error(`   주인:  ${fmt(owner)}`);
console.error(`   나:    ${me.ref} (${me.sha}) · ${me.worktree}`);
console.error('');
console.error('   그래도 덮으려면(그 세션과 합의했거나 main 번들로 되돌리는 것이면):');
console.error('     COUI_BUNDLE_FORCE=1 npm run build');
console.error('   남의 번들을 두고 내 것을 시험하려면 내 워크트리에서 빌드해 code.js 만 옮기는 대신,');
console.error('   manifest 가 읽는 경로를 잠시 내 워크트리로 바꿔라.');
process.exit(1);
