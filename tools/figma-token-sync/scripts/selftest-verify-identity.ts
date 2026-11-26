// Self-test for identity-idempotence grading and document snapshotting
// (src/verify.ts). Runs under plain Node via `npm run selftest`.
//
// ## What it defends
//
// Two faults, both of which produced a red that no re-run could clear.
//
// **1. The snapshot disagreed with the index about which node is real.**
// `indexDocumentComponents` (src/identity.ts) is first-wins, and generate
// writes to the node that index hands it. `snapshotDocument` took last-wins,
// so on a canvas with a duplicate name — which the live library has, e.g. a
// `Command` set left on a deprecated page — the verifier graded a node
// generate never touched and reported it `misplaced`. Renaming pages does not
// help: the index walks every page and ignores page names.
//
// **2. Placement was asserted for the whole registry even under a scope.**
// A scoped generate calls `placeOnPage` for in-scope entries only, so holding
// the entire registry to its expected page indicts leftovers the run never
// went near. id/key stay document-wide on purpose — out-of-scope nodes must
// not move either — but placement cannot.
//
// The scope itself exists because the unscoped form is unrunnable: Button
// alone (972 variants) measured 549s, and this command builds twice (#4026).

import {
  gradeIdentity,
  gradeKeyPreservation,
  gradePageLayout,
  gradeSecondRun,
  parseRunOutcome,
  snapshotDocument,
  type NodeSnapshot,
  type RunOutcome,
} from '../src/verify';
import { isDemotedPageOf, sectionHeaderPageNameOf } from '../src/data';
import { prefersDuplicateWinner } from '../src/identity';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;

function check(label: string, fn: () => void | Promise<void>): Promise<void> {
  return (async () => {
    try {
      await fn();
      console.log(`  ok  ${label}`);
    } catch (e) {
      failures++;
      console.error(`FAIL  ${label}\n      ${String(e)}`);
    }
  })();
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function node(name: string, page: string, id = `id:${name}`, key = `key:${name}`): NodeSnapshot {
  return { name, type: 'COMPONENT_SET', id, key, pageName: page };
}

function snap(...nodes: NodeSnapshot[]): Map<string, NodeSnapshot> {
  return new Map(nodes.map((n) => [n.name, n]));
}

const scopeOf = (...names: string[]) => names.map((name) => ({ name }));

async function main(): Promise<void> {
  console.log('selftest: verify identity');

  await check('identical snapshots grade clean, and every node counts as skipped', () => {
    const before = snap(node('Alpha', '❖ Alpha'), node('Beta', '❖ Beta'));
    const g = gradeIdentity(before, snap(node('Alpha', '❖ Alpha'), node('Beta', '❖ Beta')), scopeOf('Alpha', 'Beta'));
    assert(g.ok, 'expected ok');
    assert(g.skipped === 2, `skipped ${g.skipped}`);
    assert(g.created === 0 && g.recreated === 0 && g.misplaced === 0 && g.migrated === 0, 'expected zero faults');
  });

  await check('a changed id is idChanged AND recreated — run 2 rebuilt what run 1 already had', () => {
    const before = snap(node('Alpha', '❖ Alpha', 'id:1'));
    const after = snap(node('Alpha', '❖ Alpha', 'id:2'));
    const g = gradeIdentity(before, after, scopeOf('Alpha'));
    assert(!g.ok, 'expected not ok');
    assert(g.idChanged === 1, `idChanged ${g.idChanged}`);
    assert(g.recreated === 1, `recreated ${g.recreated}`);
  });

  await check('a changed key is keyChanged — instances in consuming files would break', () => {
    const g = gradeIdentity(
      snap(node('Alpha', '❖ Alpha', 'id:1', 'key:a')),
      snap(node('Alpha', '❖ Alpha', 'id:1', 'key:b')),
      scopeOf('Alpha'),
    );
    assert(!g.ok && g.keyChanged === 1, `keyChanged ${g.keyChanged}`);
  });

  await check('a node that appears only on run 2 is created — run 1 did not converge', () => {
    const g = gradeIdentity(snap(), snap(node('Alpha', '❖ Alpha')), scopeOf('Alpha'));
    assert(!g.ok && g.created === 1, `created ${g.created}`);
  });

  await check('a node present after run 1 and gone after run 2 is missing', () => {
    const g = gradeIdentity(snap(node('Alpha', '❖ Alpha')), snap(), scopeOf('Alpha'));
    assert(!g.ok && g.missing.length === 1, `missing ${g.missing.length}`);
  });

  await check('a node on the wrong page IS misplaced when it is in scope', () => {
    const g = gradeIdentity(
      snap(node('Alpha', 'Somewhere Else')),
      snap(node('Alpha', 'Somewhere Else')),
      scopeOf('Alpha'),
    );
    assert(!g.ok && g.misplaced === 1, `misplaced ${g.misplaced}`);
  });

  // The point of the scope parameter. Before it, a one-component verify run
  // reported every stale page in the file as this run's fault.
  await check('a node on the wrong page is NOT misplaced when it is out of scope', () => {
    const both = snap(node('Alpha', '❖ Alpha'), node('Stale', 'Some Legacy Page'));
    const g = gradeIdentity(both, both, scopeOf('Alpha'));
    assert(g.ok, `expected ok, got misplaced ${g.misplaced}`);
    assert(g.misplaced === 0, `misplaced ${g.misplaced}`);
    // …but it is still held to id/key stability, which is document-wide.
    assert(g.skipped === 2, `skipped ${g.skipped} — out-of-scope nodes are still graded for identity`);
  });

  await check('a node that moved page between the runs is movedOnRun2', () => {
    const g = gradeIdentity(
      snap(node('Alpha', 'Old Page')),
      snap(node('Alpha', '❖ Alpha')),
      scopeOf('Alpha'),
    );
    assert(!g.ok && g.migrated === 1, `migrated ${g.migrated}`);
  });

  // A duplicate name is a canvas-hygiene fault, not an idempotence fault: the
  // run is still idempotent about the node it actually writes. Folding it into
  // `misplaced` produced a red that no re-run could clear.
  await check('duplicate names report in their own bucket and do not fail the run', () => {
    const same = snap(node('Alpha', '❖ Alpha'));
    const dups = new Map([['Alpha', ['❖ Alpha', '❖ Alpha (deprecated · 2026-09-08)']]]);
    const g = gradeIdentity(same, same, scopeOf('Alpha'), dups);
    assert(g.ok, 'a duplicate name must not fail idempotence');
    assert(g.duplicateNames.length === 1 && g.duplicateNames[0] === 'Alpha', 'expected the name reported');
    assert(
      g.log.some((l) => l.includes('duplicate node name') && l.includes('rename the others')),
      'expected an actionable duplicate line',
    );
  });

  // snapshotDocument must agree with indexDocumentComponents about the winner.
  await check('snapshotDocument keeps the FIRST node of a duplicated name and records the rest', async () => {
    const page = (name: string, kids: { name: string; type: string; id: string; key: string }[]) => ({
      name,
      children: kids,
      loadAsync: async () => {},
    });
    (globalThis as unknown as { figma: unknown }).figma = {
      root: {
        children: [
          page('❖ Command', [{ name: 'Command', type: 'COMPONENT_SET', id: 'id:winner', key: 'k1' }]),
          page('❖ Command (deprecated · 2026-09-08)', [
            { name: 'Command', type: 'COMPONENT_SET', id: 'id:loser', key: 'k2' },
          ]),
        ],
      },
    };
    const { byName, duplicates } = await snapshotDocument();
    assert(byName.get('Command')?.id === 'id:winner', `graded ${byName.get('Command')?.id} — must match the index`);
    assert(duplicates.get('Command')?.length === 2, 'expected both pages recorded');
  });

  // #4847 — the shared rule itself, direct: canonical beats non-canonical
  // regardless of which argument (incumbent/candidate) holds which, and
  // neither-canonical falls back to "no, keep the incumbent" (first-wins,
  // since the caller only asks this when a later duplicate is found).
  await check('prefersDuplicateWinner picks the canonical `❖ {name}` page either way round', () => {
    assert(
      prefersDuplicateWinner('Command', '❖ Command (deprecated · 2026-09-08)', '❖ Command'),
      'a canonical candidate must beat a non-canonical incumbent',
    );
    assert(
      !prefersDuplicateWinner('Command', '❖ Command', '❖ Command (deprecated · 2026-09-08)'),
      'a non-canonical candidate must not beat a canonical incumbent',
    );
    assert(
      !prefersDuplicateWinner('Command', 'Some Legacy Page', 'Another Legacy Page'),
      'neither canonical — the incumbent (first-wins) stays',
    );
  });

  // #4847 — the actual regression: a physical page reorder used to flip the
  // winner silently, because "first-wins" had no opinion about WHICH page is
  // the real one. Same fixture as above, pages in the opposite order — the
  // canonical `❖ Command` page must still win even though the deprecated one
  // is now first in the document.
  await check('snapshotDocument keeps the CANONICAL page even when it is second in document order', async () => {
    const page = (name: string, kids: { name: string; type: string; id: string; key: string }[]) => ({
      name,
      children: kids,
      loadAsync: async () => {},
    });
    (globalThis as unknown as { figma: unknown }).figma = {
      root: {
        children: [
          page('❖ Command (deprecated · 2026-09-08)', [
            { name: 'Command', type: 'COMPONENT_SET', id: 'id:loser', key: 'k2' },
          ]),
          page('❖ Command', [{ name: 'Command', type: 'COMPONENT_SET', id: 'id:winner', key: 'k1' }]),
        ],
      },
    };
    const { byName, duplicates } = await snapshotDocument();
    assert(
      byName.get('Command')?.id === 'id:winner',
      `graded ${byName.get('Command')?.id} — the canonical page must win regardless of document order`,
    );
    assert(duplicates.get('Command')?.length === 2, 'expected both pages recorded');
  });


  // ─── #4026 (B4) — 배치 · key · 2회차 판정 ────────────────────────────────

  console.log('selftest: page layout (#4026)');

  const kSections = ['Control', 'Form', 'Display'];
  // `sectionHeaderPageNameOf` 가 만드는 이름을 그대로 쓴다 — 여기서 문자열을
  // 새로 적으면 이모지 표가 바뀌는 날 테스트만 조용히 갈린다.
  const header = (s: string) => sectionHeaderPageNameOf(s);
  const scopeSec = (...pairs: [string, string | null][]) =>
    pairs.map(([name, section]) => ({ name, section }));

  // `all` 을 안 주면 범위와 같다(= 전량 실행). 헤더 판정의 근거가 범위가
  // 아니라 캔버스의 실제 페이지라는 것을 마지막 테스트가 고정한다.
  const gradeLayout = (
    pages: readonly string[],
    scope: { name: string; section: string | null }[],
    all: { name: string; section: string | null }[] = scope,
  ) => gradePageLayout(pages, scope, all, kSections);

  await check('규약에 맞는 페이지 목록은 통과한다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Form'), '❖ Checkbox', 'Palette'],
      scopeSec(['Button', 'Control'], ['Checkbox', 'Form']),
    );
    assert(g.ok, `expected ok — ${g.log.join(' | ')}`);
    assert(g.missingPages.length === 0 && g.duplicatePages.length === 0, 'expected no faults');
  });

  await check('범위 안 엔트리의 페이지가 없으면 ✗', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button'],
      scopeSec(['Button', 'Control'], ['Checkbox', 'Form']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.missingPages.includes('Checkbox'), `missing ${g.missingPages.join(',')}`);
  });

  await check('생성기 소유 페이지 이름 중복은 ✗ — pageToReuse 버그가 만든 188→198 축', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', '❖ Button'],
      scopeSec(['Button', 'Control']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.duplicatePages.includes('❖ Button'), `dup ${g.duplicatePages.join(',')}`);
  });

  await check('헤더 중복도 같은 축으로 잡힌다 — 매 실행 헤더를 새로 심던 회귀', () => {
    const g = gradeLayout(
      [header('Control'), '01. ' + header('Control'), '❖ Button'],
      scopeSec(['Button', 'Control']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.duplicatePages.includes(header('Control')), `dup ${g.duplicatePages.join(',')}`);
  });

  await check('디자이너의 정렬 접두는 이름을 숨기지 못한다 — 접두 달린 헤더도 헤더다', () => {
    const g = gradeLayout(
      ['01. ' + header('Control'), '❖ Button'],
      scopeSec(['Button', 'Control']),
    );
    assert(g.ok, `expected ok — ${g.log.join(' | ')}`);
    assert(g.missingHeaders.length === 0, `missingHeaders ${g.missingHeaders.join(',')}`);
  });

  await check('컴포넌트 페이지 0개인 섹션의 헤더는 ✗ (stray)', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Display')],
      scopeSec(['Button', 'Control']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.strayHeaders.includes('Display'), `stray ${g.strayHeaders.join(',')}`);
  });

  await check('컴포넌트 페이지가 있는데 헤더가 없으면 ✗', () => {
    const g = gradeLayout(['❖ Button'], scopeSec(['Button', 'Control']));
    assert(!g.ok, 'expected fail');
    assert(g.missingHeaders.includes('Control'), `missingHeaders ${g.missingHeaders.join(',')}`);
  });

  await check('구 스킴 잔재는 경고일 뿐 — 비지 않은 페이지는 의도적으로 남긴다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', 'Control / Button'],
      scopeSec(['Button', 'Control']),
    );
    assert(g.ok, `구 스킴은 ok 를 깨지 않아야 한다 — ${g.log.join(' | ')}`);
    assert(g.oldSchemePages.includes('Control / Button'), `old ${g.oldSchemePages.join(',')}`);
    assert(g.log.some((l) => l.startsWith('⚠')), '경고 줄이 있어야 한다');
  });

  await check('디자이너의 스크래치 페이지 중복은 판정 대상이 아니다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', '작업중', '작업중'],
      scopeSec(['Button', 'Control']),
    );
    assert(g.ok, `생성기 소유가 아닌 이름은 안 본다 — ${g.log.join(' | ')}`);
  });

  await check('페이지 순서는 판정하지 않는다 — 배치는 total 이 아니라 relative 다', () => {
    // 같은 집합을 뒤섞은 목록. 순서를 단언하면 디자이너가 옮겨 둔 페이지가
    // 매 실행 빨강이 되고, 그건 재실행으로 지울 수 없는 빨강이다.
    const shuffled = ['❖ Checkbox', 'Palette', header('Form'), '❖ Button', header('Control')];
    const g = gradeLayout(shuffled, scopeSec(['Button', 'Control'], ['Checkbox', 'Form']));
    assert(g.ok, `순서는 자유여야 한다 — ${g.log.join(' | ')}`);
  });

  await check('범위를 좁혀도 남의 섹션 헤더를 stray 로 신고하지 않는다', () => {
    // 한 컴포넌트만 고른 실행. 나머지 섹션들은 **범위 밖 엔트리의** 페이지를
    // 갖고 있고, 헤더도 그래서 있다. 범위로 헤더를 세면 그 아홉이 전부
    // stray 가 되고, 재실행으로 지울 수 없는 빨강이 된다.
    const pages = [header('Control'), '❖ Button', header('Form'), '❖ Checkbox'];
    const all = scopeSec(['Button', 'Control'], ['Checkbox', 'Form']);
    const g = gradeLayout(pages, scopeSec(['Button', 'Control']), all);
    assert(g.ok, `범위 밖 섹션의 헤더는 stray 가 아니다 — ${g.log.join(' | ')}`);
    assert(g.strayHeaders.length === 0, `stray ${g.strayHeaders.join(',')}`);
  });

  await check('범위 밖 엔트리의 페이지 부재는 신고하지 않는다', () => {
    // Checkbox 페이지가 없지만 이번 범위가 아니다 — 이 실행은 그것을 만들
    // 책임이 없고, 만들지 않았다고 빨강이 되면 안 된다.
    const all = scopeSec(['Button', 'Control'], ['Checkbox', 'Form']);
    const g = gradeLayout([header('Control'), '❖ Button'], scopeSec(['Button', 'Control']), all);
    assert(g.ok, `범위 밖 부재는 이 실행의 잘못이 아니다 — ${g.log.join(' | ')}`);
    assert(g.missingPages.length === 0, `missing ${g.missingPages.join(',')}`);
  });

  // ── 강등 페이지 (09-24 실측) ─────────────────────────────────────────────
  // 전 범위 실측이 "페이지 missing 19" 로 빨갛게 나왔다. 19 는 디자이너가 `❖` 를
  // 빼고 들여써 강등한 페이지 — 생성기가 옵트아웃으로 읽어 일부러 건너뛴 것 —
  // 이었고, 배치 판정만 그 규칙을 몰랐다. 재실행으로 지울 수 없는 빨강이다.

  await check('강등 판정은 들여쓰기를 요구한다 — 이름만 같은 페이지는 강등이 아니다', () => {
    assert(isDemotedPageOf('  Stacks', 'Stacks'), '들여쓴 이름은 강등');
    assert(isDemotedPageOf('\tStacks', 'Stacks'), '탭 들여쓰기도 강등');
    assert(!isDemotedPageOf('Stacks', 'Stacks'), '들여쓰지 않으면 강등이 아니다');
    assert(!isDemotedPageOf('  ❖ Stacks', 'Stacks'), '❖ 가 남아 있으면 강등이 아니다');
    assert(!isDemotedPageOf('  StacksX', 'Stacks'), '다른 이름은 강등이 아니다');
  });

  await check('강등 페이지는 "페이지 없음" 이 아니다 — 세어서 따로 드러낸다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Form'), '❖ Checkbox', '  Toggle'],
      scopeSec(['Button', 'Control'], ['Checkbox', 'Form'], ['Toggle', 'Form']),
    );
    assert(g.ok, `강등은 실패가 아니다 — ${g.log.join(' | ')}`);
    assert(g.missingPages.length === 0, `missing ${g.missingPages.join(',')}`);
    assert(g.demotedPages.join(',') === 'Toggle', `demoted ${g.demotedPages.join(',')}`);
    assert(g.log.some((l) => l.startsWith('↷') && l.includes('Toggle')), '강등 줄이 로그에 있어야 한다');
  });

  await check('들여쓰지 않은 동명 페이지는 여전히 "페이지 없음" 이다 — 생성기가 그 옆에 ❖ 를 만든다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Form'), '❖ Checkbox', 'Toggle'],
      scopeSec(['Button', 'Control'], ['Checkbox', 'Form'], ['Toggle', 'Form']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.missingPages.includes('Toggle'), `missing ${g.missingPages.join(',')}`);
    assert(g.demotedPages.length === 0, `demoted ${g.demotedPages.join(',')}`);
  });

  await check('강등 페이지만 남은 섹션의 헤더는 있어도 stray 가 아니다', () => {
    // 생성기는 그 헤더를 새로 심지도 지우지도 않고, 디자이너는 강등 페이지를
    // 헤더 아래 메모로 둔다 — 빨강으로 세면 재실행이 못 지운다.
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Form'), '  Toggle'],
      scopeSec(['Button', 'Control'], ['Toggle', 'Form']),
    );
    assert(g.ok, `헤더는 메모의 자리다 — ${g.log.join(' | ')}`);
    assert(g.strayHeaders.length === 0, `stray ${g.strayHeaders.join(',')}`);
  });

  await check('강등 페이지만 남은 섹션에 헤더가 없어도 missing 이 아니다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', '  Toggle'],
      scopeSec(['Button', 'Control'], ['Toggle', 'Form']),
    );
    assert(g.ok, `생성기는 그 헤더를 만들지 않는다 — ${g.log.join(' | ')}`);
    assert(g.missingHeaders.length === 0, `missingHeaders ${g.missingHeaders.join(',')}`);
  });

  await check('아무 페이지도 없는 섹션의 헤더는 여전히 stray 다', () => {
    const g = gradeLayout(
      [header('Control'), '❖ Button', header('Form')],
      scopeSec(['Button', 'Control']),
      scopeSec(['Button', 'Control'], ['Toggle', 'Form']),
    );
    assert(!g.ok, 'expected fail');
    assert(g.strayHeaders.includes('Form'), `stray ${g.strayHeaders.join(',')}`);
  });

  await check('생성기와 배치 판정이 강등을 같은 함수로 읽는다 — 규칙이 갈리면 이 버그가 돌아온다', () => {
    const src = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
    const uses = src.split('isDemotedPageOf(').length - 1;
    assert(uses >= 2, `generate.ts 가 isDemotedPageOf 를 ${uses}번 부른다 — 강등 판정 두 자리 모두 이 함수여야 한다`);
    assert(!/\^\\s\+\/\.test\(p\.name\)/.test(src), 'generate.ts 에 강등 정규식이 다시 인라인됐다');
  });

  console.log('selftest: key preservation (#4026)');

  const kn = (
    name: string,
    key: string,
    type: 'COMPONENT' | 'COMPONENT_SET' = 'COMPONENT_SET',
  ): NodeSnapshot => ({ name, type, id: `id:${name}`, key, pageName: `❖ ${name}` });

  await check('key 가 그대로면 통과한다', () => {
    const g = gradeKeyPreservation(snap(kn('Alpha', 'k1')), snap(kn('Alpha', 'k1')));
    assert(g.ok, `expected ok — ${g.log.join(' | ')}`);
    assert(g.keyLost.length === 0, 'expected no loss');
  });

  await check('마이그레이션이 key 를 바꾸면 ✗ — NFR-F 의 그 축', () => {
    const g = gradeKeyPreservation(snap(kn('Alpha', 'k1')), snap(kn('Alpha', 'k2')));
    assert(!g.ok, 'expected fail');
    assert(g.keyLost.length === 1 && g.keyLost[0].name === 'Alpha', 'expected Alpha lost');
  });

  await check('COMPONENT → COMPONENT_SET 입양 승격은 제외된다 (BDD "신규 set 노드 제외")', () => {
    const g = gradeKeyPreservation(
      snap(kn('Alpha', 'k1', 'COMPONENT')),
      snap(kn('Alpha', 'k-set', 'COMPONENT_SET')),
    );
    assert(g.ok, `승격은 key 가 달라도 정상 — ${g.log.join(' | ')}`);
    assert(g.promoted.includes('Alpha'), `promoted ${g.promoted.join(',')}`);
  });

  await check('반대 방향(SET → COMPONENT)은 제외되지 않는다 — 승격이 아니다', () => {
    const g = gradeKeyPreservation(
      snap(kn('Alpha', 'k1', 'COMPONENT_SET')),
      snap(kn('Alpha', 'k2', 'COMPONENT')),
    );
    assert(!g.ok, '강등은 key 손실로 잡혀야 한다');
  });

  await check('실행 전에 없던 이름은 대조 대상이 아니다', () => {
    const g = gradeKeyPreservation(snap(), snap(kn('Alpha', 'k1')));
    assert(g.ok, `신규 노드는 짝이 없다 — ${g.log.join(' | ')}`);
  });

  await check('사라진 노드는 경고일 뿐 — RETIRED/rename 과 구별되지 않는다', () => {
    const g = gradeKeyPreservation(snap(kn('Alpha', 'k1')), snap());
    assert(g.ok, `vanished 는 ok 를 깨지 않아야 한다 — ${g.log.join(' | ')}`);
    assert(g.vanished.includes('Alpha'), `vanished ${g.vanished.join(',')}`);
  });

  console.log('selftest: run outcome + second run (#4026)');

  await check('Done. 줄에서 결산을 읽는다', () => {
    const o = parseRunOutcome(['시작', 'Done. 3 built, 98 skipped (unchanged), 101 total across 190 pages. Total: 12.3s.']);
    assert(o !== null, 'expected parse');
    assert(o!.built === 3 && o!.skipped === 98 && o!.total === 101, JSON.stringify(o));
  });

  await check('failed 절이 붙어도 읽는다', () => {
    const o = parseRunOutcome(['Done. 1 built, 99 skipped (unchanged), 101 total, 1 failed (see ✗ above) across 190 pages. Total: 9.0s.']);
    assert(o !== null && o.built === 1 && o.total === 101, JSON.stringify(o));
  });

  await check('Done. 줄이 없으면 null 이다 — 0 이 아니다', () => {
    // 여기서 0 을 돌려주면 파싱 실패가 all-skip 으로 위조된다.
    assert(parseRunOutcome(['아무 말']) === null, 'expected null');
  });

  await check('Done. 줄이 여럿이면 마지막을 읽는다', () => {
    const o = parseRunOutcome([
      'Done. 9 built, 0 skipped (unchanged), 9 total across 9 pages. Total: 1.0s.',
      'Done. 0 built, 101 skipped (unchanged), 101 total across 190 pages. Total: 2.0s.',
    ]);
    assert(o !== null && o.built === 0 && o.skipped === 101, JSON.stringify(o));
  });

  const outcome = (built: number, skipped: number): RunOutcome => ({
    built,
    skipped,
    total: built + skipped,
  });

  await check('2회차가 아무것도 안 그리고 10% 미만이면 통과', () => {
    const g = gradeSecondRun(outcome(40, 61), outcome(0, 101), 100_000, 5_000);
    assert(g.ok, `expected ok — ${g.log.join(' | ')}`);
    assert(g.timingApplicable && g.ratio !== null && g.ratio < 0.1, JSON.stringify(g.ratio));
  });

  await check('2회차가 하나라도 그리면 ✗', () => {
    const g = gradeSecondRun(outcome(40, 61), outcome(1, 100), 100_000, 5_000);
    assert(!g.ok, 'expected fail');
    assert(g.log.some((l) => l.includes('다시 그렸다')), g.log.join(' | '));
  });

  await check('all-skip 으로 보고돼도 시간이 안 줄면 ✗ — 그리고 버리는 구현을 잡는 유일한 신호', () => {
    const g = gradeSecondRun(outcome(40, 61), outcome(0, 101), 100_000, 90_000);
    assert(!g.ok, 'expected fail');
    assert(g.ratio !== null && g.ratio > 0.1, `ratio ${g.ratio}`);
  });

  await check('정확히 10% 는 초과다 (예산은 미만)', () => {
    const g = gradeSecondRun(outcome(40, 61), outcome(0, 101), 100_000, 10_000);
    assert(!g.ok, '10% 는 "미만" 이 아니다');
  });

  await check('1회차도 all-skip 이면 시간 축은 해당 없음 — 통과시키되 적는다', () => {
    const g = gradeSecondRun(outcome(0, 101), outcome(0, 101), 100_000, 90_000);
    assert(g.ok, `잴 대상이 없으면 통과 — ${g.log.join(' | ')}`);
    assert(!g.timingApplicable && g.ratio === null, 'expected N/A');
    assert(g.log.some((l) => l.includes('해당 없음')), g.log.join(' | '));
  });

  await check('결산을 못 읽으면 판정 불가 — 조용히 통과하지 않는다', () => {
    const g = gradeSecondRun(null, null, 100_000, 5_000);
    assert(!g.ok, 'fail-closed 여야 한다');
    assert(g.built === null, 'built null');
  });

  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log('✅ verify-identity selftest passed');
}

void main();
