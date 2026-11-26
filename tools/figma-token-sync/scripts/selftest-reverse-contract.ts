// reverse/ 두 스크립트의 **종료 코드 계약**과, 그 계약을 떠받치는 가드들이 실제로
// 발화하는지 확인한다.
//
//   0 = 조치할 차이 없음 · 1 = 차이 있음(사람이 봐야 함) · 2 = 인프라 실패
//
// 왜 이 계약만 따로 테스트하나: 이 계약이 무너지는 방식이 프로덕션에서 보이지
// 않는다. 입력이 없는데 0 으로 끝나는 스크립트는 "변화 없음" 리포트와 출력이
// 완전히 같아서, 크론이 영원히 초록을 보고해도 아무도 알아채지 못한다. 반대로
// 인프라 실패를 1 로 보고하면 깨진 캡처가 "디자이너가 무언가 바꿨다"로 읽힌다.
//
// **두 채널 모두 양성 대조를 가진다.** 전부 2 만 기대하는 하네스는 스크립트가
// 시작조차 못 해도 통과하고, 그 상태에서는 종료 코드를 0↔1 로 뒤집어도 · 모집단
// 하한을 지워도 · 기하 비교를 통째로 없애도 · 파일 키 인터록을 떼어내도 초록이
// 유지된다. 실패시켜 본 적 없는 가드는 가드가 아니므로, 아래 케이스는 각각 자기가
// 어떤 회귀를 죽이는지를 주석에 달고 있다 — 그 회귀를 하나 주입하면 정확히 그
// 케이스가 빨개지고, 실패 메시지가 어느 축이 죽었는지 이름으로 말한다.
//
// **모든 Channel A 케이스는 자기 config 를 심는다.** 기본 config 를 쓰면
// fileKeyStatus 인터록이 다른 모든 판정보다 먼저 발화해서, 케이스가 이름과 다른
// 경로를 테스트하고도 초록으로 통과한다 — 인터록만 켜져 있으면 그 뒤의 가드가
// 전부 죽어 있어도 하네스가 알아채지 못한다는 뜻이다. 인터록 자체는 그것을
// 노린 케이스가 따로 본다.
//
// **가드 하나에 케이스 하나** — 이 하네스의 커버리지는 가드 수가 아니라 *죽일 수
// 있는 회귀* 수로 센다. 프로덕션 코드에 회귀를 하나 주입했을 때 아무 케이스도
// 빨개지지 않으면, 그 가드는 다음 편집이 조용히 지울 수 있다는 뜻이고 레포의 어떤
// 검사도 그것을 말해주지 않는다. 그래서 가드를 고치는 일과 그 가드를 죽이는
// 케이스를 쓰는 일은 같은 작업의 두 반쪽이지 앞뒤가 아니다.
//
// **한 케이스가 두 가드를 재면 둘 다 안 재는 것이다.** 한 픽스처가 여러 가드를
// 동시에 건드리면 그중 먼저 걸리는 하나만 실제로 측정되고, 나머지는 이웃 가드에
// 가려 죽여도 초록으로 남는다 — 실측: 이스케이프 없는 따옴표를 담은 한 픽스처는
// 파서의 malformed 가드와 잘림(rootClosed) 가드에 동시에 걸려서, **둘 중 아무거나
// 하나를 지워도** 나머지가 대신 잡아 통과했다. 두 가드를 동시에 지웠을 때에야
// 빨개졌다. 그래서 가드마다 **그 가드만** 걸리는 픽스처를 따로 세운다.
//
// 픽스처를 갈라 세울 수 없을 때 — 두 가드가 같은 입력에 **원리적으로** 함께
// 걸릴 때(전부-빗나감과 부분-빗나감, 부재와 읽기 실패) — 는 종료 코드 대신
// `expectFailedWith` 로 거부 사유를 못 박는다. 그 못이 없으면 케이스 이름이
// 가리키는 가드를 지워도 이웃이 대신 잡아 초록으로 남는다.
//
// **채널별 케이스만으로는 두 채널이 갈라지는 것을 볼 수 없다.** 각 케이스는 자기
// 채널이 옳은지만 보므로, 둘 다 초록이면서 둘이 서로 다른 말을 하고 있을 수 있다 —
// 이 레포에서 네 라운드 연속으로 나온 결함이 정확히 그 모양이다. 그래서 마지막에
// 두 리포트를 **나란히 놓고** 재는 절을 따로 둔다.
//
// 여기서 건드리는 표면은 문서화된 CLI 플래그 · 종료 코드 · 리포트 본문뿐이다 —
// 내부 함수를 부르지 않는다. 그래야 리팩터가 아니라 **계약 변경**에만 빨개진다.
// 예외가 둘 있고 둘 다 같은 이유다(하네스가 프로덕션과 갈라지지 않게):
// fidelity 봉투는 생산자 코드에서 직접 만들고, 잘림 문구와 바이트 셈은 두 채널이
// 공유하는 서식 모듈에서 가져온다 — 그래야 그 문구가 갈라지는 순간 빨개진다.

// 이 패키지는 `@types/node` 를 의존성에 넣지 않는다 — 루트 tsconfig 의 typeRoots
// 가 `@figma/plugin-typings` 로 고정돼 플러그인 코드가 Node API 에 닿지 못하게
// 막고 있고, 전역 Node 타입을 넣으면 그 격리가 사라진다. 그래서 쓰는 전역만
// 파일 안에서 최소한으로 선언한다(reverse/ 스크립트와 같은 방침).
declare const process: {
  cwd(): string;
  exit(code: number): never;
};
declare function require(id: string): unknown;

// 봉투를 손으로 적지 않고 **생산자에게 만들게 한다.**
//
// 손으로 적은 리터럴은 생산자와 조용히 갈라진다: 미스 한 줄의 필드 이름을
// `entry` 로 적어둔 픽스처는 리포트가 그 자리에 `(미상)` 을 렌더하는데도 종료
// 코드가 1 이라 통과했고, 그래서 "미스가 실제로 렌더된다"는 이 하네스의 유일한
// 양성 대조가 아무것도 확인하지 않고 있었다. 여기서 타입과 직렬화를 모두
// 생산자에게서 가져오면 그 드리프트는 컴파일 에러이거나 렌더 단언 실패다.
import { serialiseFidelityReport } from '../src/fidelity';
import type { FidelityMiss, FidelityReport } from '../src/fidelity';

// 두 채널이 공유하는 서식. 잘림 문구를 하네스가 따로 적으면 그 사본이 프로덕션과
// 갈라지고, 갈라진 사본은 **틀린 쪽을 통과시킨다**. 여기서 가져다 쓰면 한 채널이
// 공유 문구에서 이탈하는 순간 그 채널의 케이스가 빨개진다 — 이 모듈이 존재하는
// 이유(두 채널이 같은 사실을 같은 문장으로 적는다)가 곧 검증 대상이 된다.
//
// 이 import 자체가 예산 화해 검사를 실행시킨다: 모듈이 적재 시점에 세 예산의 합을
// 확인하고 넘으면 던지므로, 누군가 한 채널의 예산을 올려 합이 이슈 본문 상한을
// 넘기면 하네스가 **첫 줄에서** 터진다.
import {
  ageNote,
  brief,
  budgetOf,
  cell as sharedCell,
  evidenceBudget,
  fitToBudget,
  linesCost,
  spend,
  truncationNotice,
  truncationNoticeReserve,
  utf8Bytes,
  CHANNEL_A_BUDGET_BYTES,
  CHANNEL_B_BUDGET_BYTES,
  ISSUE_BODY_LIMIT_BYTES,
  ISSUE_WRAPPER_RESERVE_BYTES,
  MAX_QUOTED_CHARS,
  MAX_TABLE_ROWS,
} from '../reverse/report_format';

const { spawnSync } = require('child_process') as {
  spawnSync(
    cmd: string,
    args: string[],
    opts: { cwd: string; encoding: 'utf8' },
  ): { status: number | null; stdout: string; stderr: string };
};
const {
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  readFileSync,
  existsSync,
  rmSync,
  statSync,
  utimesSync,
} = require('fs') as {
  mkdtempSync(prefix: string): string;
  mkdirSync(p: string, o?: { recursive: boolean }): void;
  writeFileSync(p: string, data: string, enc: 'utf8'): void;
  readFileSync(p: string, enc: 'utf8'): string;
  existsSync(p: string): boolean;
  rmSync(p: string, o?: { recursive: boolean; force: boolean }): void;
  statSync(p: string): { size: number; mtime: { toISOString(): string } };
  utimesSync(p: string, atime: number, mtime: number): void;
};
const { join, resolve } = require('path') as {
  join(...parts: string[]): string;
  resolve(...parts: string[]): string;
};
const { tmpdir } = require('os') as { tmpdir(): string };

const ROOT = resolve(process.cwd());
const DIFF = 'reverse/diff_structure.ts';
const INGEST = 'reverse/ingest_fidelity.ts';

// `npx` 는 호출마다 패키지 해석을 다시 한다 — 이 하네스가 도는 횟수만큼 곱해지면
// 그 오버헤드가 실행 시간의 절반을 넘는다. 로컬 bin 이 있으면 직접 부르고,
// 없는 환경(전역 설치)에서는 npx 로 떨어진다.
const LOCAL_TSX = join(ROOT, 'node_modules', '.bin', 'tsx');
const RUNNER = existsSync(LOCAL_TSX) ? LOCAL_TSX : 'npx';
const RUNNER_PREFIX = RUNNER === 'npx' ? ['tsx'] : [];

let failures = 0;
const scratches: string[] = [];

interface Run {
  status: number | null;
  stdout: string;
  stderr: string;
}

/**
 * 스크립트를 돌려 종료 코드가 기대와 같은지 본다.
 *
 * `cwd` 를 바꿀 수 있는 이유: 몇몇 입력은 **cwd 기준으로** 찾아진다(코드 대조가
 * 읽는 컴포넌트 레지스트리가 그렇다). 그 입력이 없을 때의 경로를 재려면 그 파일이
 * 없는 자리에서 돌리는 수밖에 없다 — 레포의 실제 파일을 지우는 것은 다른 케이스를
 * 전부 망가뜨린다.
 */
function expectExit(
  label: string,
  script: string,
  args: string[],
  want: number,
  cwd: string = ROOT,
): Run {
  // cwd 가 레포 밖이면 상대 경로 스크립트를 찾지 못한다.
  const target = cwd === ROOT ? script : join(ROOT, script);
  const r = spawnSync(RUNNER, [...RUNNER_PREFIX, target, ...args], {
    cwd,
    encoding: 'utf8',
  });
  const got = r.status;
  if (got === want) {
    console.log(`  ✅ ${label} → exit ${got}`);
    return r;
  }
  failures += 1;
  console.log(`  ❌ ${label} → exit ${String(got)} (기대 ${want})`);
  // 계약이 깨졌을 때 무엇이 나왔는지 보이지 않으면 고칠 수가 없다.
  const tail = `${r.stdout}${r.stderr}`.trim().split('\n').slice(-6).join('\n      ');
  if (tail.length > 0) console.log(`      ${tail}`);
  return r;
}

/**
 * 리포트 **본문** 단언.
 *
 * 종료 코드만 보는 케이스는 리포트가 통째로 비어도 · 값이 `(미상)` 으로 렌더돼도
 * 통과한다. 종료 코드는 "몇 건인가" 만 말하고 "그게 무엇인가" 는 본문에만 있다.
 */
function expectBody(label: string, path: string, needles: string[], absent: string[] = []): void {
  if (!existsSync(path)) {
    failures += 1;
    console.log(`  ❌ ${label}`);
    console.log('      리포트가 기록되지 않았다');
    return;
  }
  const body = readFileSync(path, 'utf8');
  const missing = needles.filter((n) => !body.includes(n));
  const present = absent.filter((n) => body.includes(n));
  if (missing.length === 0 && present.length === 0) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  if (missing.length > 0) console.log(`      없어야 하는데 없음: ${missing.join(' · ')}`);
  if (present.length > 0) console.log(`      있으면 안 되는데 있음: ${present.join(' · ')}`);
}

/**
 * 실패가 **어느 가드에서** 났는지 단언한다.
 *
 * 종료 코드 2 는 "무언가 거부했다" 까지만 말한다. 어느 가드가 거부했는지는 메시지에만
 * 있고, 그래서 종료 코드만 보는 케이스는 겨눈 가드를 지워도 **이웃 가드가 대신
 * 잡아주면** 초록으로 남는다 — 그 케이스는 자기 이름과 다른 것을 재고 있는 것이다.
 */
function expectFailedWith(label: string, run: Run, needles: string[]): void {
  const said = `${run.stdout}${run.stderr}`;
  const missing = needles.filter((n) => !said.includes(n));
  if (missing.length === 0) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  console.log(`      다른 가드가 대신 잡았다 — 없는 문구: ${missing.join(' · ')}`);
  const tail = said.trim().split('\n').slice(0, 3).join('\n      ');
  if (tail.length > 0) console.log(`      실제로 난 실패: ${tail}`);
}

/**
 * 리포트 본문에 대한 **술어** 단언.
 *
 * 문자열 포함으로 표현되지 않는 성질을 잰다 — "표가 상한을 넘는 행을 싣지 않았다"
 * 같은 것. `expectBody` 로 쓰면 문구에 매이는데, 문구는 바뀌어도 성질은 남는다.
 * `check` 는 통과하면 `null`, 아니면 무엇이 틀렸는지 한 줄로 돌려준다.
 */
function expectBodyMatch(
  label: string,
  path: string,
  check: (body: string) => string | null,
): void {
  if (!existsSync(path)) {
    failures += 1;
    console.log(`  ❌ ${label}`);
    console.log('      리포트가 기록되지 않았다');
    return;
  }
  const wrong = check(readFileSync(path, 'utf8'));
  if (wrong === null) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  console.log(`      ${wrong}`);
}

function countOf(body: string, needle: string): number {
  return body.split(needle).length - 1;
}

function scratch(): string {
  const dir = mkdtempSync(join(tmpdir(), 'coui-reverse-selftest-'));
  scratches.push(dir);
  return dir;
}

/** 심어둔 인자 하나만 갈아끼운다 — 나머지 픽스처는 정상인 채로 한 자리만 망가뜨릴 때. */
function withArg(args: string[], flag: string, value: string): string[] {
  return [...args.filter((a) => !a.startsWith(`${flag}=`)), `${flag}=${value}`];
}

/**
 * 그 자리에 **디렉터리를 놓는다.**
 *
 * 읽기 실패 래퍼를 재는 유일하게 이식 가능한 방법이다. 권한을 떼는 방식은 root
 * 로 도는 CI 에서 그냥 성공해 버려 케이스가 조용히 무의미해지고, 확인과 읽기
 * 사이에 파일을 지우는 방식은 경합이라 재현되지 않는다. 디렉터리는 `existsSync`
 * 를 통과하고 읽기에서만 던지므로(EISDIR · ENOTDIR) 부재 가드를 지나 래퍼까지
 * 정확히 도달한다.
 */
function replaceWithDirectory(path: string): void {
  rmSync(path, { recursive: true, force: true });
  mkdirSync(path, { recursive: true });
}

/**
 * 두 채널의 표 행 상한.
 *
 * 프로덕션 상수를 **가져다 쓴다.** 여기 리터럴로 적으면 그 사본이 프로덕션과
 * 갈라지고, 갈라진 사본은 **틀린 쪽을 통과시킨다** — 상한을 40 으로 낮춘 회귀에
 * 대해 이 하네스가 "50 에서 잘렸다" 를 기대하며 빨개지는 게 아니라, 자기 사본이
 * 말하는 자리에서 잘렸는지만 보게 된다.
 */
const TABLE_ROW_CAP = MAX_TABLE_ROWS;
/** 상한을 넘기려고 세우는 행 수. 잘림이 실제로 일어나는 자리를 만든다. */
const ROWS_OVER_CAP = 60;

function ok(label: string, cond: boolean, wrong: string): void {
  if (cond) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  console.log(`      ${wrong}`);
}

// ── 공유 서식 모듈 ──────────────────────────────────────────────────────────
//
// 두 채널이 **같아야 하는 것**만 이 모듈에 산다. 그래서 여기가 틀리면 두 채널이
// 함께 틀리고, 그 틀림은 나란히 놓고 보기 전까지 보이지 않는다 — 이 레포에서 세 번
// 반복된 실패의 모양이 정확히 그것이다.
console.log('공유 서식 — report_format.ts');
{
  // `|` 는 열을 쪼개고 줄바꿈은 **행을 쪼갠다.** 행이 쪼개지면 남은 조각이 다음
  // 행으로 렌더되어 그 뒤 표 전체가 한 칸씩 밀리는데, 읽는 사람은 밀린 표를 보고도
  // 밀렸다는 것을 알 수 없다. 세 종류(LF · CR · CRLF)를 따로 재는 이유: 한 종류만
  // 막은 이스케이프는 막지 않은 것과 같은 실패를 남긴다.
  ok('cell 이 파이프를 이스케이프한다', sharedCell('a|b') === 'a\\|b', `받은 값: ${sharedCell('a|b')}`);
  ok('cell 이 LF 를 접는다', !sharedCell('a\nb').includes('\n'), `받은 값: ${JSON.stringify(sharedCell('a\nb'))}`);
  ok('cell 이 CR 을 접는다', !sharedCell('a\rb').includes('\r'), `받은 값: ${JSON.stringify(sharedCell('a\rb'))}`);
  ok(
    'cell 이 CRLF 를 공백 하나로 접는다',
    sharedCell('a\r\nb') === 'a b',
    `받은 값: ${JSON.stringify(sharedCell('a\r\nb'))} — 두 문자를 각각 치환하면 공백이 둘이 된다`,
  );
  // 백슬래시를 먼저 escape 하지 않으면 이름 안의 `\` 가 **우리가 넣은 escape 를
  // 무력화한다**: `a\|b` 의 파이프를 `\|` 로 바꾸면 `a\\|b` 가 되고, 마크다운은
  // 그것을 "리터럴 백슬래시 + 열 구분" 으로 읽는다. 막았다고 믿은 자리가 그대로
  // 뚫리는데, 뚫린 표는 밀린 채로 그럴듯하게 렌더된다.
  ok(
    'cell 이 백슬래시를 먼저 이스케이프한다',
    sharedCell('a\\|b') === 'a\\\\\\|b',
    `받은 값: ${JSON.stringify(sharedCell('a\\|b'))} — ` +
      '백슬래시를 두 배로 만들지 않으면 그 뒤의 파이프 escape 가 무력화된다',
  );
  ok(
    'cell 이 홀로 있는 백슬래시도 두 배로 만든다',
    sharedCell('a\\b') === 'a\\\\b',
    `받은 값: ${JSON.stringify(sharedCell('a\\b'))}`,
  );

  // 바이트로 세기로 한 예산을 코드 단위로 세면 한글이 실제의 1/3 로 잡힌다.
  ok('utf8Bytes 가 ASCII 를 1 바이트로 센다', utf8Bytes('abc') === 3, `받은 값: ${utf8Bytes('abc')}`);
  ok('utf8Bytes 가 한글을 3 바이트로 센다', utf8Bytes('가나다') === 9, `받은 값: ${utf8Bytes('가나다')}`);
  ok('utf8Bytes 가 em-dash 를 3 바이트로 센다', utf8Bytes('—') === 3, `받은 값: ${utf8Bytes('—')}`);
  ok('utf8Bytes 가 대리 쌍을 4 바이트로 센다', utf8Bytes('🙂') === 4, `받은 값: ${utf8Bytes('🙂')}`);
  ok(
    'utf8Bytes 가 문자 수와 다른 답을 낸다',
    utf8Bytes('가나다') !== '가나다'.length,
    '한글에서 바이트 수와 코드 단위 수가 같으면 예산이 코드 단위로 세고 있다는 뜻이다',
  );

  // 세 예산의 합이 이슈 본문 상한 안에 있어야 두 채널이 각자 예산을 지켰을 때
  // 이슈 생성이 성공한다. 모듈이 적재 시점에 던지므로 이 단언은 그 계약을 문서로도
  // 남기는 쪽이다 — 누군가 한 채널 예산을 올리면 import 에서 이미 터진다.
  ok(
    '세 예산의 합이 이슈 본문 상한 안이다',
    CHANNEL_A_BUDGET_BYTES + CHANNEL_B_BUDGET_BYTES + ISSUE_WRAPPER_RESERVE_BYTES <=
      ISSUE_BODY_LIMIT_BYTES,
    `${CHANNEL_A_BUDGET_BYTES} + ${CHANNEL_B_BUDGET_BYTES} + ${ISSUE_WRAPPER_RESERVE_BYTES} > ${ISSUE_BODY_LIMIT_BYTES}`,
  );

  // 위 단언은 **지금 값이 옳다**는 것만 말한다 — 상수를 읽어 같은 덧셈을 다시 할
  // 뿐이라, 모듈의 적재 시점 검사를 통째로 지워도 그대로 통과한다. 검사가 실제로
  // 발화하는지 보려면 발화시켜야 한다: 모듈을 복사해 한 채널의 예산만 부풀린 뒤
  // 그것을 적재해 본다. 실패시켜 본 적 없는 가드는 가드가 아니다.
  {
    const dir = scratch();
    const src = readFileSync(join(ROOT, 'reverse', 'report_format.ts'), 'utf8');
    const patched = src.replace(
      /export const CHANNEL_A_BUDGET_BYTES = \d+;/,
      'export const CHANNEL_A_BUDGET_BYTES = 65000;',
    );
    ok(
      '  예산 상수를 부풀린 사본을 만들 수 있다',
      patched !== src,
      '상수 선언 모양이 바뀌어 이 프로브가 아무것도 부풀리지 못했다 — 아래 단언이 공허해진다',
    );
    writeFileSync(join(dir, 'report_format.ts'), patched, 'utf8');
    writeFileSync(join(dir, 'probe.ts'), "import './report_format';\n", 'utf8');
    const probe = spawnSync(RUNNER, [...RUNNER_PREFIX, join(dir, 'probe.ts')], {
      cwd: ROOT,
      encoding: 'utf8',
    });
    ok(
      '  합이 상한을 넘으면 적재 시점에 멈춘다',
      probe.status !== 0,
      '예산 합이 이슈 본문 상한을 넘는데도 모듈이 조용히 적재됐다 — 두 채널이 각자 예산을 지켜도 이슈 생성이 거부된다',
    );
    // 어느 값을 얼마나 되돌려야 하는지가 메시지 안에 있어야 한다. 셋 중 하나라도
    // 빠지면 읽는 사람이 세 파일을 열어 덧셈을 다시 해야 한다.
    expectFailedWith('  메시지가 세 예산을 모두 말한다', probe, [
      'CHANNEL_A_BUDGET_BYTES',
      'CHANNEL_B_BUDGET_BYTES',
      'ISSUE_WRAPPER_RESERVE_BYTES',
    ]);
  }

  // 잘림 문구는 **한 벌**이다. 두 채널이 같은 사실을 다르게 적으면 읽는 사람이 그
  // 차이를 의미로 읽는다.
  ok(
    'truncationNotice 가 실은 수·감춘 수·총수를 모두 말한다',
    ['7', '3', '10'].every((n) => truncationNotice(7, 10).includes(n)),
    `받은 값: ${truncationNotice(7, 10)} — 셋 중 하나라도 빠지면 읽는 사람이 나머지를 셈해야 한다`,
  );

  // fitToBudget 의 핵심은 **못 실은 수를 반환값으로 내보내는 것**이다. 그 수를
  // 본문에 적으려 하면 예산이 바닥났을 때 그 문장부터 사라져 조용한 잘림이 된다.
  {
    const big = 'x'.repeat(100);
    const fit = fitToBudget([big, big, big], 250);
    ok(
      'fitToBudget 이 예산을 넘지 않는다',
      utf8Bytes(fit.text) <= 250,
      `실은 바이트 ${utf8Bytes(fit.text)} > 예산 250`,
    );
    ok(
      'fitToBudget 이 못 실은 절 수를 예산 밖으로 돌려준다',
      fit.omittedSections === 1,
      `omittedSections=${fit.omittedSections} (기대 1) — 이 수가 0 이면 잘림이 조용해진다`,
    );
  }
  // 큰 절 하나가 그 뒤의 작은 절들까지 버리면, 읽는 사람이 보는 양이 발견의
  // **순서**에 따라 달라진다 — 같은 발견 집합이 순서만 다르면 다르게 보인다.
  {
    const fit = fitToBudget(['x'.repeat(500), 'y'.repeat(10)], 100);
    ok(
      'fitToBudget 이 큰 절을 건너뛰고 뒤의 작은 절을 싣는다',
      fit.text.includes('y') && fit.omittedSections === 1,
      `text=${JSON.stringify(fit.text.slice(0, 40))} omitted=${fit.omittedSections}`,
    );
  }

  // ── 인용값의 크기가 실제로 묶여 있는가 ────────────────────────────────────
  //
  // 산문이 유한하다는 주장은 **인용 슬롯 하나가 유한하다**는 것에 얹혀 있다. 그
  // 상한은 문자로 세지만 예산은 바이트라, 둘 사이의 변환이 최악에서도 성립해야
  // 그 주장이 참이다. 문자 수만 재는 단언은 한글·이모지·이스케이프가 늘리는 몫을
  // 못 보고, 못 보는 그 몫이 정확히 상한을 넘기는 크기다.
  {
    const ceiling = MAX_QUOTED_CHARS * 3 + utf8Bytes('…');
    // 세 가지 최악을 따로 잰다 — 한 글자가 3 바이트인 것, 두 코드 단위가 한 글자인
    // 것, 그리고 이스케이프가 한 글자를 두 글자로 늘리는 것.
    for (const [what, sample] of [
      ['한글', '가'.repeat(10000)],
      ['이모지', '🙂'.repeat(10000)],
      ['백슬래시(이스케이프가 늘린다)', '\\'.repeat(10000)],
      ['파이프(이스케이프가 늘린다)', '|'.repeat(10000)],
    ] as [string, string][]) {
      const bytes = utf8Bytes(brief(sample));
      ok(
        `  brief 가 ${what} 에서도 ${ceiling} 바이트 안이다`,
        bytes <= ceiling,
        `${bytes} 바이트 — 인용 슬롯이 유한하지 않으면 산문 전체가 유한하다는 주장이 무너진다`,
      );
    }
    // 반대쪽 — 상한 아래는 손대지 않는다. 무조건 자르면 짧은 값이 말줄임표를 달고
    // 나가 원래 값이 더 길었던 것처럼 읽힌다.
    ok(
      '  brief 가 짧은 값은 자르지 않는다',
      brief('Cover') === 'Cover',
      `받은 값: ${JSON.stringify(brief('Cover'))}`,
    );
  }

  // ── 잘림 문구의 자리를 미리 뗐는가 ────────────────────────────────────────
  //
  // 문구는 예산이 바닥난 **뒤에** 써야 하므로 자리를 미리 떼지 않으면 예산 밖으로
  // 새어 나간다. 뗀 자리가 실제 문구보다 작으면 그게 곧 초과다 — 어떤 (실은 수,
  // 총수) 조합에서도 모자라지 않아야 한다.
  {
    const total = 400;
    const reserve = truncationNoticeReserve(total);
    const worst = Math.max(
      ...[0, 1, 50, total - 1, total].map((shown) => utf8Bytes(truncationNotice(shown, total))),
    );
    ok(
      'truncationNoticeReserve 가 어떤 잘림 문구보다 크다',
      reserve >= worst,
      `뗀 자리 ${reserve} < 실제 최악 ${worst} — 문구가 예산 밖으로 새어 나간다`,
    );
  }

  // ── 증거 예산이 잘리지 않는 것들을 전부 뺐는가 ────────────────────────────
  //
  // 두 채널이 같은 규율을 따른다: 범위를 좁히는 머리말과 다음 행동을 말하는 꼬리말은
  // 잘리지 않고, 잘리는 것은 증거뿐이며, 못 실은 수는 예산 밖에서 말한다. 셋 중
  // 하나라도 빼먹으면 그 채널은 자기 예산 안에 있다고 믿으면서 상대의 몫을 먹는다.
  {
    const head = ['머리말 한 줄', ''];
    const tail = ['꼬리말 한 줄'];
    const notice = truncationNotice(0, 400);
    const got = evidenceBudget(10000, head, tail, notice);
    const want = 10000 - linesCost(head) - linesCost(tail) - linesCost([notice, '']);
    ok(
      'evidenceBudget 이 머리말·꼬리말·잘림 문구를 모두 뺀다',
      got === want,
      `${got} ≠ ${want} — 하나라도 빼먹으면 그만큼 옆 채널 몫을 먹는다`,
    );
    // 증거가 없어 잘릴 것이 없으면 그 자리를 떼지 않는다 — 떼면 쓰지도 않을 자리
    // 때문에 실을 수 있었던 증거가 빠진다.
    ok(
      '  잘릴 것이 없으면 문구 자리를 떼지 않는다',
      evidenceBudget(10000, head, tail, '') > got,
      '빈 문구에도 자리를 떼고 있다',
    );
    // 음수를 0 으로 접으면 "예산이 없다" 가 "예산이 0" 이 되어 조용해진다. 음수를
    // 그대로 두어야 `spend` 가 전부 거절하고 잘림 문구가 발화해 그 상태가 본문에 남는다.
    ok(
      '  머리말이 예산을 넘으면 음수를 그대로 돌려준다',
      evidenceBudget(10, head, tail, notice) < 0,
      '음수를 0 으로 클램프하면 예산이 없다는 사실이 조용히 사라진다',
    );
  }

  // ── 예산이 바닥나면 아무것도 싣지 않는가 ──────────────────────────────────
  {
    const budget = budgetOf(linesCost(['한 줄']));
    const out: string[] = [];
    ok('spend 가 예산 안이면 싣는다', spend(budget, out, ['한 줄']) && out.length === 1, `out=${out.length}`);
    const before = out.length;
    ok(
      'spend 가 예산 밖이면 한 줄도 싣지 않는다',
      !spend(budget, out, ['또 한 줄']) && out.length === before,
      `거절해야 하는데 ${out.length - before} 줄이 실렸다 — 부분적으로 실으면 표가 중간에서 끊긴다`,
    );
  }

  // ── 나이 문장이 한 벌인가 ─────────────────────────────────────────────────
  //
  // 문장은 한 벌이고 주어만 파라미터다 — 두 채널이 각자 적으면 갈라지기 때문이고,
  // 실제로 갈라진 적이 있다(한쪽은 "에 뜬 캡처", 다른 쪽은 "시점의 캔버스").
  // 그래서 여기서 보는 것은 두 가지다: 그 파라미터가 실제로 문장을 가르는가, 그리고
  // **오래됨이 신호인 채널에서만** 경고가 붙는가.
  {
    const long = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const fresh = new Date().toISOString();
    const watched = { label: '이 캡처의 기록 시각', stale: { afterDays: 1, warning: '⚠️ 오래됐다.' } };
    const unwatched = { label: '이 리포트의 생성 시각', stale: null };

    ok(
      'ageNote 가 임계를 넘으면 경고를 붙인다',
      ageNote(long, watched).includes('⚠️ 오래됐다.'),
      `받은 값: ${ageNote(long, watched)}`,
    );
    ok(
      '  임계 아래에서는 경고를 붙이지 않는다',
      !ageNote(fresh, watched).includes('⚠️ 오래됐다.'),
      '갓 뜬 것에도 경고가 붙으면 그 경고는 매 주기 나오고, 매 주기 나오는 경고는 읽히지 않는다',
    );
    ok(
      '  오래됨이 정상인 채널에는 경고가 없다',
      !ageNote(long, unwatched).includes('⚠️'),
      'stale 이 null 인데 경고가 붙었다',
    );
    // 읽을 수 없는 시각과 없는 시각은 **둘 다** 나이를 주장하지 못한다. `Date.parse`
    // 가 NaN 을 내는 값이 그대로 흘러가면 `(NaN일 전)` 이 본문에 실린다.
    for (const [what, at] of [['없는 시각', null], ['읽을 수 없는 시각', 'not-a-date']] as [
      string,
      string | null,
    ][]) {
      const said = ageNote(at, watched);
      ok(
        `  ${what} 에는 나이를 주장하지 않는다`,
        said.includes('알 수 없다') && !said.includes('NaN'),
        `받은 값: ${said}`,
      );
    }
  }
}

// ── Channel A 픽스처 ────────────────────────────────────────────────────────
//
// 한 케이스는 (베이스라인 스냅샷 · 캡처된 페이지 XML · config) 세 벌이고, 셋 다
// 같은 노드 목록에서 렌더된다. 그래서 "아무것도 바꾸지 않은 케이스" 가 정말로
// 0 이 나오고, 한 필드만 바꾼 케이스가 정확히 그 한 건만 만든다.

const FIXTURE_FILE_KEY = 'FIXTURE-FILE-KEY';

/** 베이스라인을 세운 적 없는 상태 — 커밋된 파일과 같은 모양. */
const EMPTY_BASELINE = JSON.stringify(
  {
    schema: 1,
    fileKey: null,
    capturedAt: null,
    capturedBy: 'figma-mcp:get_metadata',
    nodeCount: 0,
    pages: [],
  },
  null,
  2,
);

interface FixNode {
  id: string;
  name: string;
  type: string;
  x?: number;
  y?: number;
  w?: number;
  h?: number;
  /** 기하 속성을 문자 그대로 내보낸다 — 파서가 빈 값을 어떻게 읽는지 보려면 필요하다. */
  rawGeometry?: string;
}

interface FixPage {
  id: string;
  name: string;
  nodes: FixNode[];
}

function geomAttrs(n: FixNode): string {
  if (n.rawGeometry !== undefined) return n.rawGeometry;
  const pairs: [string, number | undefined][] = [
    ['x', n.x],
    ['y', n.y],
    ['width', n.w],
    ['height', n.h],
  ];
  return pairs
    .filter(([, v]) => typeof v === 'number')
    .map(([k, v]) => `${k}="${v as number}"`)
    .join(' ');
}

function pageXml(page: FixPage): string {
  const out = [`<canvas id="${page.id}" name="${page.name}">`];
  for (const n of page.nodes) {
    out.push(`  <${n.type} id="${n.id}" name="${n.name}" ${geomAttrs(n)} />`);
  }
  out.push('</canvas>');
  // get_metadata 는 XML 뒤에 산문을 붙이고 그 산문에는 `<id>` 같은 조각이 들어
  // 있다. 매 픽스처가 이걸 싣는 이유: 잘림 판정을 "끝에서 depth 가 0 인가" 로
  // 하면 그 조각이 여는 태그로 읽혀 멀쩡한 캡처가 잘린 것으로 오판된다. 그
  // 회귀를 넣으면 이 산문을 지나 판정까지 도달하는 케이스가 전부 빨개진다 —
  // 더 앞선 게이트에서 멈추는 인프라 케이스는 여전히 2 로 끝나므로 조용하다.
  out.push('');
  out.push('IMPORTANT: call get_metadata with nodeId=<id> for more detail.');
  return out.join('\n');
}

function snapshotJson(pages: FixPage[], fileKey: string): string {
  const rendered = pages.map((p) => ({
    id: p.id,
    name: p.name,
    // 캔버스 루트도 노드다 — x/y 가 없는 것이 정상이라 "기하 비교 불가" 에서
    // 제외되는 쪽이고, 그 제외가 살아 있는지 보려면 픽스처에 있어야 한다.
    nodes: [
      { id: p.id, name: p.name, type: 'canvas', x: null, y: null, w: null, h: null, depth: 0 },
      ...p.nodes.map((n) => ({
        id: n.id,
        name: n.name,
        type: n.type,
        x: n.x ?? null,
        y: n.y ?? null,
        w: n.w ?? null,
        h: n.h ?? null,
        depth: 1,
      })),
    ],
  }));
  return JSON.stringify(
    {
      schema: 1,
      fileKey,
      capturedAt: null,
      capturedBy: 'figma-mcp:get_metadata',
      nodeCount: rendered.reduce((sum, p) => sum + p.nodes.length, 0),
      pages: rendered,
    },
    null,
    2,
  );
}

interface Plant {
  /** 없으면 빈 베이스라인 — 첫 실행 경로. */
  baseline?: FixPage[];
  current: FixPage[];
  /** 해당 페이지의 XML 을 통째로 대체한다 — 파서가 거부해야 할 모양을 심을 때. */
  rawXml?: Record<string, string>;
  omitXmlFor?: string[];
  pagesTxt?: string;
  omitPagesTxt?: boolean;
  config?: Record<string, unknown>;
  dropConfig?: string[];
  baselineFileKey?: string;
  /** 정상 베이스라인에서 한 자리만 망가뜨린다 — 나머지는 렌더된 그대로다. */
  baselinePatch?: (snap: Record<string, unknown>) => void;
}

function plant(p: Plant): { dir: string; args: string[] } {
  const dir = scratch();
  const raw = join(dir, 'raw');
  mkdirSync(raw, { recursive: true });

  if (p.omitPagesTxt !== true) {
    const txt =
      p.pagesTxt ??
      ['Pages in this file:', ...p.current.map((pg) => `- ${pg.id}: ${pg.name}`), ''].join('\n');
    writeFileSync(join(raw, 'pages.txt'), txt, 'utf8');
  }

  const skip = new Set(p.omitXmlFor ?? []);
  for (const page of p.current) {
    if (skip.has(page.id)) continue;
    const body = p.rawXml?.[page.id] ?? pageXml(page);
    // 파일명 규칙을 여기 한 번 더 적는다 — 캡처와 파서가 **같은** 규칙을 써야만
    // 파일을 찾으므로, 프로덕션이 규칙을 바꾸면 이 하네스가 파일을 못 찾아
    // 전 케이스가 빨개진다. 그게 이 중복이 하는 일이다.
    writeFileSync(join(raw, `page-${page.id.replace(/[^A-Za-z0-9]+/g, '-')}.xml`), body, 'utf8');
  }

  const baselinePath = join(dir, 'baseline.json');
  let baselineText =
    p.baseline === undefined
      ? EMPTY_BASELINE
      : snapshotJson(p.baseline, p.baselineFileKey ?? FIXTURE_FILE_KEY);
  if (p.baselinePatch !== undefined) {
    const snap = JSON.parse(baselineText) as Record<string, unknown>;
    p.baselinePatch(snap);
    baselineText = JSON.stringify(snap, null, 2);
  }
  writeFileSync(baselinePath, baselineText, 'utf8');

  const cfg: Record<string, unknown> = {
    schema: 1,
    fileKey: FIXTURE_FILE_KEY,
    fileKeyStatus: 'confirmed',
    fileUrl: `https://www.figma.com/design/${FIXTURE_FILE_KEY}/fixture`,
    pages: null,
    geometryEpsilonPx: 0.5,
    populationFloorRatio: 0.5,
    ...(p.config ?? {}),
  };
  for (const key of p.dropConfig ?? []) delete cfg[key];
  const configPath = join(dir, 'config.json');
  writeFileSync(configPath, JSON.stringify(cfg, null, 2), 'utf8');

  return {
    dir,
    args: [`--config=${configPath}`, `--baseline=${baselinePath}`, `--raw-dir=${raw}`],
  };
}

/** 두 노드짜리 표준 페이지. 케이스는 이걸 복제해 한 자리만 바꾼다. */
function cover(nodes: FixNode[]): FixPage {
  return { id: '1:1', name: 'Cover', nodes };
}

const CARD: FixNode = { id: '1:2', name: 'Card', type: 'FRAME', x: 10, y: 20, w: 100, h: 40 };
const LABEL: FixNode = { id: '1:3', name: 'Label', type: 'TEXT', x: 12, y: 22, w: 60, h: 16 };

function withNode(nodes: FixNode[], id: string, patch: Partial<FixNode>): FixNode[] {
  return nodes.map((n) => (n.id === id ? { ...n, ...patch } : n));
}

// ── Channel A — 구조 differ ──────────────────────────────────────────────────
console.log('Channel A — diff_structure.ts');
{
  const base = [cover([CARD, LABEL])];

  // ── 인프라 실패(2) ────────────────────────────────────────────────────────

  // 캡처가 통째로 없는데 "차이 없음"으로 끝나면 크론은 영원히 조용하다.
  //
  // 부재 가드를 지워도 읽기 래퍼가 ENOENT 를 잡아 같은 2 를 낸다 — 페이지 XML 과
  // 같은 짝이다. 두 거부가 사람에게 시키는 일이 다르므로 문구로 못 박는다.
  {
    const { args } = plant({ baseline: base, current: base, omitPagesTxt: true });
    const r = expectExit('pages.txt 없음', DIFF, args, 2);
    expectFailedWith('  거부한 것이 부재 가드다 (읽기 실패 래퍼가 아니라)', r, ['pages.txt 가 없음']);
  }

  // 한 페이지의 캡처 누락은 그 페이지 전체 삭제와 출력이 같다 — 구별할 수
  // 없으므로 리포트를 만들기 전에 거부해야 한다.
  //
  // 부재 가드를 지워도 바로 다음 줄의 읽기 래퍼가 ENOENT 를 잡아 같은 2 를 낸다.
  // 두 거부는 사람에게 **다른 것을 시킨다** — 부재는 "그 페이지를 다시 캡처하라",
  // 읽기 실패는 "권한을 확인하라" 다. 문구로 못 박지 않으면 그 갈림이 사라진다.
  {
    const { args } = plant({ baseline: base, current: base, omitXmlFor: ['1:1'] });
    const r = expectExit('페이지 XML 누락', DIFF, args, 2);
    expectFailedWith('  거부한 것이 부재 가드다 (읽기 실패 래퍼가 아니라)', r, [
      '페이지 XML 이 없음',
    ]);
  }

  // 읽기 실패는 **인프라 실패**다. `existsSync` 를 통과해도 읽기는 던진다 — 그
  // 자리가 디렉터리이거나, 권한이 없거나, 확인과 읽기 사이에 사라지면 그렇다.
  // 감싸지 않으면 그 예외가 Node 를 종료 코드 **1** 로 끝내고, 자동화는 그 1 을
  // "디자이너가 무언가 바꿨다" 로 읽어 읽히지도 않은 파일로 이슈를 만든다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    replaceWithDirectory(join(dir, 'raw', 'pages.txt'));
    const r = expectExit('pages.txt 를 읽지 못함 (자리에 디렉터리)', DIFF, args, 2);
    expectFailedWith('  읽기 실패가 1 이 아니라 2 로 나간다', r, ['읽지 못함']);
  }
  // 같은 래퍼를 쓰는 형제 입력 — 한 호출처만 감싸면 다른 쪽으로 같은 실패가 샌다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    const asDir = join(dir, 'baseline-as-dir');
    mkdirSync(asDir, { recursive: true });
    const r = expectExit(
      '베이스라인을 읽지 못함 (자리에 디렉터리)',
      DIFF,
      withArg(args, '--baseline', asDir),
      2,
    );
    expectFailedWith('  부재가 아니라 읽기 실패로 거부한다', r, ['읽지 못함']);
  }

  // 목록은 있는데 한 줄도 읽히지 않으면 파싱이 깨진 것이고, 그대로 진행하면
  // 전 페이지가 삭제된 것으로 보고된다.
  //
  // 어느 가드가 거부했는지를 문구로 못 박는 이유: 이 파싱 가드를 지워도 페이지가
  // 0 개인 캡처는 **하한 두 개가 대신 잡는다**(페이지 수 하한이 먼저, 그 뒤 노드
  // 모집단 하한). 종료 코드만 보면 셋 중 아무거나 하나만 살아 있어도 초록이라,
  // 이 케이스가 자기 이름과 다른 것을 재게 된다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      pagesTxt: 'Pages in this file:\n(none listed)\n',
    });
    const r = expectExit('pages.txt 에서 페이지를 못 읽음', DIFF, args, 2);
    expectFailedWith('  거부한 것이 목록 파싱 가드다 (페이지·노드 하한이 아니라)', r, [
      '페이지를 한 개도 읽지 못함',
    ]);
  }

  // 필터가 전부 빗나가면 노드가 하나도 안 읽히고, 그건 전 페이지 삭제와 같다.
  //
  // 바로 아래 부분-빗나감 가드가 **같은 입력에도 걸린다**(`9:9` 는 파일에 없다).
  // 코드에서 이쪽이 먼저라 지금은 이쪽이 잡지만, 이 가드를 지우면 아래 가드가
  // 대신 잡아 종료 코드가 2 그대로다 — 문구로 못 박지 않으면 초록으로 남는다.
  {
    const { args } = plant({ baseline: base, current: base, config: { pages: ['9:9'] } });
    const r = expectExit('config.pages 가 전부 빗나감', DIFF, args, 2);
    expectFailedWith('  거부한 것이 전부-빗나감 가드다 (부분-빗나감이 아니라)', r, [
      '어떤 페이지와도 맞지 않음',
    ]);
  }

  // 필터가 **일부만** 빗나가는 쪽이 전부 빗나가는 쪽보다 위험하다. 전부 빗나가면
  // 위 가드가 멈추지만, 오타 하나가 섞이면 그 페이지만 조용히 빠진 채 리포트가
  // 정상적으로 나오고 — 종료 코드도 0 이고 본문도 멀쩡하다 — 운영자는 자기가 적은
  // 범위가 다 덮였다고 믿는다. 맞는 id 를 하나 남겨두어야 위 가드를 지나 이 가드에
  // 도달한다.
  {
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [LABEL] };
    const { args } = plant({
      baseline: [cover([CARD, LABEL]), side],
      current: [cover([CARD, LABEL]), side],
      config: { pages: ['1:1', '9:9'] },
    });
    const r = expectExit('config.pages 가 일부만 빗나감', DIFF, args, 2);
    expectFailedWith('  거부한 것이 부분-빗나감 가드다 (전부-빗나감이 아니라)', r, [
      'pages.txt 에 없음',
      '9:9',
    ]);
  }

  // 검증하지 않는 버전 필드는 보장이 아니라 장식이다.
  {
    const { args } = plant({ baseline: base, current: base, config: { schema: 99 } });
    expectExit('config 검증: schema 불일치', DIFF, args, 2);
  }

  // 설정 검증이 없으면 오타 하나가 가드를 조용히 끈다: epsilon 이 없으면
  // `Math.abs(delta) > undefined` 가 **항상 false** 라 이동·크기 변경이 전부
  // 사라지고, 리포트는 멀쩡한 초록으로 나온다.
  {
    const { args } = plant({ baseline: base, current: base, dropConfig: ['geometryEpsilonPx'] });
    expectExit('config 검증: geometryEpsilonPx 누락', DIFF, args, 2);
  }
  // 같은 이유의 형제 — 하한이 NaN 이 되면 어떤 붕괴도 통과한다.
  {
    const { args } = plant({ baseline: base, current: base, dropConfig: ['populationFloorRatio'] });
    expectExit('config 검증: populationFloorRatio 누락', DIFF, args, 2);
  }
  // 범위 밖 값은 **설정 검증**이 거부해야 한다. 종료 코드만 보면 이 케이스는
  // 모집단 하한이 대신 잡아줘도 초록이다 — ratio 를 1 보다 크게 두면 하한이 캡처
  // 크기를 넘어서서 거부가 그쪽에서 나기 때문이다. 그래서 어느 가드가 거부했는지를
  // 문구로 확인한다. 이것 없이는 상한 검사를 통째로 지워도 하네스가 조용하다.
  {
    const { args } = plant({ baseline: base, current: base, config: { populationFloorRatio: 1.5 } });
    const r = expectExit('config 검증: populationFloorRatio 가 1 을 넘음', DIFF, args, 2);
    expectFailedWith('  거부한 것이 설정 검증이다 (모집단 하한이 아니라)', r, [
      'populationFloorRatio',
      'config.json',
    ]);
  }
  // 하한을 0 에 가깝게 두는 것은 하한을 끄는 것과 구별되지 않는다 — 이 하한이 막으려는
  // 실패가 정확히 "대부분이 사라진 캡처" 라서, 0.01 은 어떤 붕괴도 통과시킨다.
  {
    const { args } = plant({ baseline: base, current: base, config: { populationFloorRatio: 0.01 } });
    const r = expectExit('config 검증: populationFloorRatio 가 하한 미만', DIFF, args, 2);
    expectFailedWith('  populationFloorRatio 를 거부한 것이 설정 검증이다', r, ['populationFloorRatio', 'config.json']);
  }
  // epsilon 은 부동소수 잡음을 흡수하라고 있는 값이라, 디자인이 의미를 두는 최소
  // 간격을 넘어서면 잡음 흡수가 아니라 변화 은폐다. 10000 은 프로덕션 주석이 실측으로
  // 적어둔 값 — 노드가 5000px 이동해도 "변화 없음" 으로 나가는 크기다.
  {
    const { args } = plant({ baseline: base, current: base, config: { geometryEpsilonPx: 10000 } });
    const r = expectExit('config 검증: geometryEpsilonPx 가 상한을 넘음', DIFF, args, 2);
    expectFailedWith('  geometryEpsilonPx 를 거부한 것이 설정 검증이다', r, ['geometryEpsilonPx', 'config.json']);
  }

  // 확인되지 않은 파일 키로 걷지 않는다. 이 케이스가 없으면 인터록을 통째로
  // 떼어내도 하네스가 알아채지 못한다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      config: { fileKeyStatus: 'provisional' },
    });
    expectExit('fileKeyStatus 인터록', DIFF, args, 2);
  }

  // 인터록이 **인터록일 뿐** 이라는 양성 대조 — 알면서 진행하겠다고 말하면
  // 걷고, 그때 리포트는 자기가 정본에 대한 주장이 아님을 본문에 적는다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: base,
      config: { fileKeyStatus: 'provisional' },
    });
    const out = join(dir, 'report.md');
    expectExit('--allow-provisional 로 통과', DIFF, [...args, '--allow-provisional', `--out=${out}`], 0);
    expectBody('  provisional 경고가 본문에 남는다', out, [
      '--allow-provisional',
      'provisional',
    ]);
  }

  // 검증되지 않은 베이스라인은 예외를 던져 종료 코드 1 로 새어 나가거나(자동화가
  // 드리프트로 읽는다) 하한을 NaN 으로 만들어 어떤 붕괴도 통과시킨다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      baselinePatch: (snap) => {
        snap.schema = 99;
      },
    });
    expectExit('베이스라인 검증: schema 불일치', DIFF, args, 2);
  }
  // nodeCount 는 모집단 하한이 유일하게 읽는 수다. 실제 노드 수와 어긋나면 그
  // 하한이 조용히 다른 값이 되는데, 타입은 멀쩡해서 다른 어떤 검사에도 안 걸린다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      baselinePatch: (snap) => {
        snap.nodeCount = 1;
      },
    });
    expectExit('베이스라인 검증: nodeCount 가 실제와 다름', DIFF, args, 2);
  }

  // `pages` 가 배열이 아니면 순회가 던지고, 잡히지 않은 예외는 Node 를 종료 코드 1 로
  // 끝낸다 — 자동화는 그 1 을 "디자이너가 무언가 바꿨다" 로 읽어 읽히지도 않은
  // 베이스라인으로 이슈를 만든다. 병합 충돌을 푼 직후의 베이스라인이 정확히 이
  // 모양이 된다: 위쪽 필드는 살아남고 아래쪽만 뭉개진다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      baselinePatch: (snap) => {
        snap.pages = 'not-an-array';
      },
    });
    expectExit('베이스라인 검증: pages 가 배열이 아님', DIFF, args, 2);
  }

  // 두 스냅샷이 다른 파일에서 왔으면 그 차이는 전부 거짓 드리프트다.
  {
    const { args } = plant({ baseline: base, current: base, baselineFileKey: 'OTHER-FILE-KEY' });
    expectExit('베이스라인과 config 의 fileKey 불일치', DIFF, args, 2);
  }

  // 태그로 시작했는데 끝까지 읽어내지 못한 것을 건너뛰면 그 노드가 조용히
  // 사라져 짝 없는 삭제로 보고된다. 아래 이름은 값 안에 이스케이프 없는
  // 따옴표가 들어간 모양이다.
  //
  // **깨진 태그를 루트가 닫힌 뒤에 둔다.** 캔버스 안에 두면 파서가 그 자리에서
  // 멈춰 루트를 닫는 태그를 못 보고, 그러면 잘림 가드가 먼저 걸린다 — 그 픽스처는
  // 두 가드에 동시에 걸려서 **어느 쪽을 지워도** 나머지가 대신 잡아 초록으로
  // 남는다(실측). 루트 밖에 두면 잘림 가드는 만족되고 malformed 가드만 남는다.
  {
    const bad = [
      '<canvas id="1:1" name="Cover">',
      '  <FRAME id="1:2" name="Card" x="10" y="20" width="100" height="40" />',
      '  <TEXT id="1:3" name="Label" x="12" y="22" width="60" height="16" />',
      '</canvas>',
      '<TEXT id="1:9" name="Stray "primary"" x="0" y="0" width="1" height="1" />',
    ].join('\n');
    const { args } = plant({ baseline: base, current: base, rawXml: { '1:1': bad } });
    const r = expectExit('읽어내지 못한 태그', DIFF, args, 2);
    expectFailedWith('  거부한 것이 malformed 가드다 (잘림 가드가 아니라)', r, [
      '읽어내지 못한 태그',
    ]);
  }

  // 잘린 응답은 남은 노드를 전부 "삭제됨" 으로 보고한다. 위 픽스처와 **따로** 세우는
  // 이유가 같다 — 여기에는 깨진 태그가 하나도 없어서 malformed 가드가 잡을 것이
  // 없고, 그래서 잘림 가드만 이 케이스를 살릴 수 있다.
  {
    const cut = [
      '<canvas id="1:1" name="Cover">',
      '  <FRAME id="1:2" name="Card" x="10" y="20" width="100" height="40" />',
      '',
      'IMPORTANT: call get_metadata with nodeId=<id> for more detail.',
    ].join('\n');
    const { args } = plant({ baseline: base, current: base, rawXml: { '1:1': cut } });
    const r = expectExit('중간에서 끊긴 캡처', DIFF, args, 2);
    expectFailedWith('  거부한 것이 잘림 가드다 (malformed 가드가 아니라)', r, [
      '중간에서 끊김',
    ]);
  }

  // 노드 0 개는 "페이지가 비었다" 가 아니라 캡처가 구조를 못 받은 것이다.
  // 붕괴한 페이지를 **작게** 잡아 모집단 하한이 이 케이스를 대신 막지 않도록
  // 한다 — 하한이 막아버리면 이 가드를 지워도 하네스가 초록으로 남는다.
  {
    const big = cover([CARD, LABEL, { id: '1:4', name: 'Icon', type: 'VECTOR', x: 0, y: 0, w: 16, h: 16 }]);
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [] };
    const { args } = plant({
      baseline: [big, side],
      current: [big, side],
      rawXml: {
        '2:1': '<document>\n  <note>You currently have nothing selected.</note>\n</document>',
      },
    });
    expectExit('노드 0 개 캡처', DIFF, args, 2);
  }

  // 붕괴한 캡처는 살아있는 노드를 전부 "삭제됨" 으로 보고해서 진짜 대량 삭제와
  // 글자 그대로 구별되지 않는다.
  {
    const many = cover(
      Array.from({ length: 9 }, (_, i) => ({
        id: `1:${i + 2}`,
        name: `N${i}`,
        type: 'FRAME',
        x: i,
        y: 0,
        w: 10,
        h: 10,
      })),
    );
    const { args } = plant({ baseline: [many], current: [cover([CARD])] });
    expectExit('모집단 붕괴', DIFF, args, 2);
  }

  // 쓰기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로
  // 읽고 존재하지 않는 파일로 이슈를 만든다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    expectExit('리포트 기록 실패 (Channel A)', DIFF, [...args, `--out=${join(dir, 'nope', 'r.md')}`], 2);
  }
  // 같은 래퍼를 쓰는 형제 출력 — 한쪽만 감싸면 다른 쪽으로 같은 실패가 샌다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    expectExit(
      '스냅샷 기록 실패',
      DIFF,
      [...args, `--out=${join(dir, 'r.md')}`, `--json-out=${join(dir, 'nope', 's.json')}`],
      2,
    );
  }

  // ── 차이 없음(0) ──────────────────────────────────────────────────────────

  // 계약의 절반. 이 케이스가 없으면 종료 코드를 0↔1 로 뒤집어도 통과한다.
  {
    const { args } = plant({ baseline: base, current: base });
    expectExit('변화 없음', DIFF, args, 0);
  }

  // 첫 실행은 전 노드를 "추가됨" 으로 보고하지 않고 베이스라인을 세운다.
  {
    const { args } = plant({ current: base });
    expectExit('빈 베이스라인 = 첫 실행', DIFF, args, 0);
  }

  // epsilon 이 실제로 읽히는지 — 0 으로 굳으면 이 케이스가 빨개진다.
  {
    const { args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:2', { x: 10.4 }))],
    });
    expectExit('epsilon 이내 이동은 변화가 아니다', DIFF, args, 0);
  }

  // 없는 값과 0 은 서로 다른 주장이다. `Number('')` 과 `Number(' ')` 은 0 이고
  // 유한해서, 그대로 두면 속성이 사라진 노드가 "원점으로 이동 + 0 폭으로 축소"
  // 로 보고된다 — 아래는 그 둘을 한 노드에 함께 심는다.
  //
  // 종료 코드 0 만 보면 이 케이스는 **비교를 건너뛰기만 해도** 통과한다. 건너뛴
  // 것을 세지 않으면 기하가 통째로 사라진 노드가 "기하 변화 없음" 에 조용히
  // 접히고, 그 침묵은 정말로 아무것도 안 움직인 주기와 글자 그대로 같다. 그래서
  // 세었는지를 본문에서 따로 본다 — 세는 자리를 지우면 여기가 빨개진다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: [
        cover(withNode([CARD, LABEL], '1:2', { rawGeometry: 'x="" y="20" width="  " height="40"' })),
      ],
    });
    const out = join(dir, 'report.md');
    expectExit('빈 기하 속성은 이동도 축소도 아니다', DIFF, [...args, `--out=${out}`], 0);
    expectBody('  비교하지 못한 것을 세어서 말한다', out, [
      '| 기하 비교 불가 | 1 |',
      '값이 없는 것과 0 은 다른 주장이다',
    ]);
  }

  // 양성 대조 — 기하가 멀쩡한 캡처가 "비교 불가" 를 세면 위 케이스는 계수기를
  // 무조건 1 로 굳혀도 통과한다. 캔버스 루트는 x/y 가 없는 것이 정상이라 이
  // 면제가 사라지면 모든 페이지가 매 주기 한 건씩 비교 불가를 낸다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    const out = join(dir, 'report.md');
    expectExit('기하가 온전한 캡처', DIFF, [...args, `--out=${out}`], 0);
    expectBody('  비교 불가가 0 이다 (캔버스 루트는 세지 않는다)', out, ['| 기하 비교 불가 | 0 |']);
  }

  // ── 범위를 좁혀 걸었을 때 ────────────────────────────────────────────────
  //
  // 좁힌 범위 밖의 베이스라인 노드는 **사라진 것이 아니라 보지 않은 것**이다. 이
  // 구분이 무너지면 범위를 좁히는 행위 자체가 대량 삭제 리포트를 지어낸다 — 게다가
  // 그 거짓 삭제는 모집단 하한이 발동하지 않는 크기라 아무 가드도 막지 못한다.
  {
    const side: FixPage = {
      id: '2:1',
      name: 'Scratch',
      nodes: [{ id: '2:2', name: 'Sketch', type: 'FRAME', x: 0, y: 0, w: 20, h: 20 }],
    };
    const planted = plant({
      baseline: [cover([CARD, LABEL]), side],
      current: [cover([CARD, LABEL]), side],
      config: { pages: ['1:1'] },
    });
    const out = join(planted.dir, 'report.md');
    expectExit('범위 밖 페이지는 삭제가 아니다', DIFF, [...planted.args, `--out=${out}`], 0);
    expectBody(
      '  범위 밖 배너가 어느 페이지인지 밝힌다',
      out,
      // 범위 밖 페이지의 이름은 **이 배너에만** 나온다. 배너가 사라지면 부분 실행이
      // 전수 실행처럼 읽히는데 종료 코드는 그대로 0 이라 아무도 알아채지 못한다.
      ['Scratch', '2:1'],
      // 그 노드들이 삭제 칸에 담기면 이 절이 생긴다 — 보지 않은 것과 사라진 것을
      // 같은 칸에 담았다는 뜻이고, 그게 이 구분이 막으려는 정확한 실패다.
      ['## 삭제된 노드'],
    );

    // 좁힌 범위로 베이스라인을 덮으면 범위 밖 페이지가 베이스라인에서 사라지고,
    // 다음 전체 실행이 그것들을 전부 "추가됨" 으로 보고한다 — 커밋된 기준을 잃는
    // 쪽이라 리포트만 봐서는 알 수 없다.
    const r = expectExit(
      '부분 스코프로는 베이스라인을 덮지 않는다',
      DIFF,
      [...planted.args, '--update-baseline'],
      2,
    );
    expectFailedWith('  거부 사유가 잃을 페이지를 이름으로 말한다', r, ['Scratch']);
  }

  // 범위를 좁혔을 때 **삭제로 세어진 것이 사실은 이동일 수 있다.**
  //
  // "비교하지 않음" 으로 갈리는 기준은 그 노드가 베이스라인에서 어느 페이지에
  // 있었는가다. 걷는 페이지에 있던 노드가 걷지 않는 페이지로 옮겨가면 이번 캡처에서
  // 사라지고, 옮겨간 곳을 읽지 않았으므로 옮겨갔다는 증거가 이 실행에 존재하지
  // 않는다 — 그래서 삭제로 세어진다. 판정할 수 없는 것을 판정하지 않고 그 갈림길을
  // 읽는 사람에게 보이는 것이 이 문장이 하는 일이고, 그 문장이 없으면 범위를 좁힌
  // 실행이 **지어낸 삭제를 진짜 삭제로 보고한다**.
  {
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [] };
    const { dir, args } = plant({
      baseline: [cover([CARD, LABEL]), side],
      current: [cover([CARD]), { ...side, nodes: [LABEL] }],
      config: { pages: ['1:1'] },
    });
    const out = join(dir, 'report.md');
    expectExit('좁힌 범위에서 노드가 사라짐', DIFF, [...args, `--out=${out}`], 1);
    expectBody('  그 삭제가 이동일 수 있다고 적는다', out, [
      '범위 밖 페이지로 옮겨간 것일 수 있다',
      '구별할 방법이 이 입력에는 없다',
    ]);
  }

  // 양성 대조 — 사라진 것이 없는데도 그 경고를 달면, 범위를 좁힌 모든 실행이 매번
  // 있지도 않은 삭제를 의심하게 만든다. 위 케이스는 문구를 무조건 찍어도 통과한다.
  {
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [LABEL] };
    const { dir, args } = plant({
      baseline: [cover([CARD, LABEL]), side],
      current: [cover([CARD, LABEL]), side],
      config: { pages: ['1:1'] },
    });
    const out = join(dir, 'report.md');
    expectExit('좁힌 범위에서 사라진 노드가 없음', DIFF, [...args, `--out=${out}`], 0);
    expectBody('  삭제가 없으면 이동 의심을 적지 않는다', out, [], [
      '범위 밖 페이지로 옮겨간 것일 수 있다',
    ]);
  }

  // 코드 대조가 **돌지 않았다는 사실**은 리포트 본문에 남아야 한다. 절이 통째로
  // 빠진 리포트는 "코드가 모르는 이름이 없었다" 로 읽혀서, 입력이 빠진 실행이
  // 완전한 실행보다 깨끗해 보인다. 레지스트리는 cwd 기준으로 찾히므로 그 파일이
  // 없는 자리에서 돌린다 — 레포의 실제 파일을 지우면 다른 케이스가 전부 망가진다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    const out = join(dir, 'report.md');
    expectExit('코드 대조 입력이 없어도 걷는다', DIFF, [...args, `--out=${out}`], 0, scratch());
    expectBody('  대조하지 못했다는 사실이 본문에 남는다', out, [
      '하지 않았다',
      '검사되지 않은 것은 이상 없음이 아니다',
    ]);
  }

  // 레이어 이름에 줄바꿈이 들어갈 수 있다(플러그인/API 로 넣을 수 있고 get_metadata 는
  // 그대로 실어 보낸다). `|` 는 열을 쪼개지만 줄바꿈은 **행 자체를 쪼갠다** — 남은
  // 조각이 다음 행으로 렌더되어 그 뒤 표 전체가 한 칸씩 밀리고, 읽는 사람은 밀린
  // 표를 보고도 밀렸다는 것을 알 수 없다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:3', { name: 'Label\nSPLITSENTINEL' }))],
    });
    const out = join(dir, 'report.md');
    expectExit('이름에 줄바꿈이 든 노드', DIFF, [...args, `--out=${out}`], 1);
    // 문구가 아니라 **구조**를 본다: 이름이 쪼개졌다면 그 꼬리가 자기 줄을 갖는다.
    expectBodyMatch('  줄바꿈이 표 행을 쪼개지 않는다', out, (body) => {
      const split = body.split('\n').filter((l) => l.startsWith('SPLITSENTINEL'));
      return split.length === 0
        ? null
        : `이름의 꼬리가 독립된 행이 됐다 — 그 뒤 표 전체가 한 칸씩 밀린다: ${split[0]}`;
    });
  }

  // 캡처가 언제 떠진 것인지 말하지 않으면 오래된 캡처의 ✅ 가 이번 주기의 답으로
  // 읽힌다. 시각 자체를 단언한다 — 문구가 아니라 데이터라 표현이 바뀌어도 남는다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    const out = join(dir, 'report.md');
    expectExit('캡처 시각이 붙는다', DIFF, [...args, `--out=${out}`], 0);
    const capturedAt = statSync(join(dir, 'raw', 'pages.txt')).mtime.toISOString();
    expectBody(
      '  언제 뜬 캡처인지 본문에 남는다',
      out,
      [capturedAt],
      // 갓 뜬 캡처가 오래됐다고 말하면 그 경고는 **매 주기** 나오고, 매 주기 나오는
      // 경고는 읽히지 않는다 — 아래 케이스는 경고를 무조건 찍어도 통과하게 된다.
      ['이 캡처가 오래됐다면'],
    );
  }

  // 시각을 적는 것과 **그것이 오래됐다고 말하는 것**은 다른 일이고, 후자가 이
  // 문장이 존재하는 이유다. 무인 실행은 매 주기 캡처를 새로 뜨므로, 오래된 캡처는
  // 곧 이번 주기의 캡처 단계가 실패하고 지난 캡처가 다시 비교됐다는 뜻이다 — 그
  // 실행의 출력은 "변화 없음 · 종료 코드 0" 이라 성공한 주기와 글자 그대로 같다.
  //
  // 캡처 시각은 `pages.txt` 의 mtime 에서 온다. 그래서 나이는 그 파일을 과거로
  // 되돌려 만든다 — 문구가 아니라 실제 경로를 지나 오게 하려면 이 방법뿐이다.
  {
    const { dir, args } = plant({ baseline: base, current: base });
    const out = join(dir, 'report.md');
    const old = Date.now() / 1000 - 30 * 24 * 60 * 60;
    utimesSync(join(dir, 'raw', 'pages.txt'), old, old);
    expectExit('오래된 캡처', DIFF, [...args, `--out=${out}`], 0);
    expectBody('  캡처 단계가 실패했을 수 있다고 경고한다', out, [
      '이 캡처가 오래됐다면',
      '지난 캡처가 다시 비교됐을 수 있다',
    ]);
  }

  // fileKey 와 fileUrl 은 각자 "비어 있지 않은 문자열" 검사를 통과하면서 서로 다른
  // 파일을 가리킬 수 있다. 그러면 리포트의 딥링크 **전부**가 엉뚱한 문서를 열고,
  // 열린 문서가 그럴듯하면 틀렸다는 것을 알아챌 방법이 없다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      config: { fileUrl: 'https://www.figma.com/design/SOME-OTHER-KEY/fixture' },
    });
    const r = expectExit('fileKey 와 fileUrl 이 다른 파일', DIFF, args, 2);
    expectFailedWith('  거부 사유가 두 값을 모두 말한다', r, ['fileKey', 'fileUrl']);
  }
  // 파일 키 자리를 읽어내지 못한 URL 은 fileKey 와 대조된 적이 없다 — 대조하지 않은
  // URL 로 만든 딥링크는 검증된 적이 없다는 뜻이라 통과시키면 위와 같은 곳에 닿는다.
  {
    const { args } = plant({
      baseline: base,
      current: base,
      config: { fileUrl: 'https://example.com/not-figma' },
    });
    expectExit('fileUrl 에서 파일 키를 못 읽음', DIFF, args, 2);
  }

  // 행 상한만으로는 문서가 묶이지 않는다 — 표 일곱 개가 각각 상한까지 차면 이슈 본문
  // 상한을 혼자서 넘긴다. 넘기면 그 주기의 발견이 통째로 사라진다.
  {
    const wide = '가'.repeat(200);
    const extra: FixNode[] = Array.from({ length: ROWS_OVER_CAP }, (_, i) => ({
      id: `1:${200 + i}`,
      name: `${wide}${i}`,
      type: 'FRAME',
      x: i,
      y: 0,
      w: 8,
      h: 8,
    }));
    const { dir, args } = plant({ baseline: base, current: [cover([CARD, LABEL, ...extra])] });
    const out = join(dir, 'report.md');
    expectExit('바이트 예산을 넘는 캡처', DIFF, [...args, `--out=${out}`], 1);
    expectBodyMatch('  바이트 예산에서 잘렸다고 말한다 (Channel A)', out, (body) =>
      body.includes('바이트 예산') ? null : '바이트 예산 잘림 문구가 없다',
    );
    // 지켜야 할 성질은 문구가 아니라 크기다 — 이 채널이 Channel B 의 몫까지 먹으면
    // 두 채널이 각자 예산을 지켰다고 믿는 채로 이슈 생성이 거부된다.
    expectBodyMatch('  Channel B 몫을 남긴다', out, (body) => {
      const size = utf8Bytes(body);
      const room = ISSUE_BODY_LIMIT_BYTES - CHANNEL_B_BUDGET_BYTES;
      return size <= room ? null : `Channel A 리포트가 ${size} 바이트 — Channel B 몫을 남기려면 ${room} 이하`;
    });
  }

  // 조용한 잘림은 "그게 전부였다" 로 읽힌다. 종료 코드는 잘렸는지 아닌지를 말하지
  // 않으므로 이 성질은 본문에서만 확인된다.
  {
    const extra: FixNode[] = Array.from({ length: ROWS_OVER_CAP }, (_, i) => ({
      id: `1:${100 + i}`,
      name: `Added${i}`,
      type: 'FRAME',
      x: i,
      y: 0,
      w: 8,
      h: 8,
    }));
    const { dir, args } = plant({ baseline: base, current: [cover([CARD, LABEL, ...extra])] });
    const out = join(dir, 'report.md');
    expectExit('표 상한을 넘는 추가', DIFF, [...args, `--out=${out}`], 1);
    expectBody('  잘림 문구가 공유 서식과 같다 (Channel A)', out, [
      truncationNotice(TABLE_ROW_CAP, ROWS_OVER_CAP),
    ]);
    // 문구와 별개로 **행이 실제로 상한에서 멈췄는지**도 본다. 문구만 찍고 전부
    // 싣는 잘림은 자기가 지키기로 한 것을 지키지 못하면서 지켰다고 말한다.
    expectBodyMatch('  실린 행이 상한을 넘지 않는다', out, (body) => {
      const rows = countOf(body, 'node-id=');
      return rows <= TABLE_ROW_CAP ? null : `표가 ${rows} 행을 실었다 — 상한 ${TABLE_ROW_CAP}`;
    });
  }

  // ── 차이 있음(1) ──────────────────────────────────────────────────────────
  //
  // 축마다 한 건씩. 한 축의 탐지를 지우면 그 케이스만 빨개지므로, 어느 축이
  // 죽었는지가 실패 메시지에서 바로 읽힌다.

  {
    const { args } = plant({
      baseline: base,
      current: [cover([CARD, LABEL, { id: '1:4', name: 'New', type: 'FRAME', x: 0, y: 0, w: 8, h: 8 }])],
    });
    expectExit('추가된 노드', DIFF, args, 1);
  }
  {
    const { args } = plant({ baseline: base, current: [cover([CARD])] });
    expectExit('삭제된 노드', DIFF, args, 1);
  }
  {
    const { args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:3', { name: 'Caption' }))],
    });
    expectExit('이름이 바뀐 노드', DIFF, args, 1);
  }
  {
    // frame → component 승격은 이름도 기하도 그대로라 type 을 안 보면 조용하다.
    const { args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:2', { type: 'COMPONENT' }))],
    });
    expectExit('타입이 바뀐 노드', DIFF, args, 1);
  }
  {
    // 페이지를 옮긴 노드는 id 가 같아 다른 어떤 축에도 걸리지 않는다.
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [] };
    const { args } = plant({
      baseline: [cover([CARD, LABEL]), side],
      current: [cover([CARD]), { ...side, nodes: [LABEL] }],
    });
    expectExit('페이지를 옮긴 노드', DIFF, args, 1);
  }
  {
    const { dir, args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:2', { x: 60 }))],
    });
    const out = join(dir, 'report.md');
    expectExit('이동한 노드', DIFF, [...args, `--out=${out}`], 1);
    // 종료 코드는 "몇 건인가" 만 말한다. 어느 노드가 어디서 어디로 갔는지는
    // 본문에만 있고, 그 본문이 비어도 종료 코드는 1 그대로다. 딥링크까지 함께
    // 보는 이유: 그게 없으면 읽는 사람이 id 를 들고 Figma 를 뒤져야 한다.
    expectBody('  이동이 본문에 특정된다', out, [
      'node-id=1-2',
      '(10, 20) → (60, 20)',
      'Card',
    ]);
  }
  {
    const { args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:2', { w: 140 }))],
    });
    expectExit('크기가 바뀐 노드', DIFF, args, 1);
  }

  // ── 리포트가 이슈 본문에 **들어가는가** ───────────────────────────────────
  //
  // 위 케이스들은 전부 "몇 건인가" 만 잰다. 종료 코드도 표 내용도, 그 리포트가
  // 실제로 사람에게 닿을 수 있는 크기인지에 대해서는 아무 말도 하지 않는다.
  // 행 상한만 있던 시절 이 축이 조용히 깨져 있었다: 표마다 50 행 상한을 지키고
  // 잘림 문구까지 성실히 찍으면서 본문이 67,341 바이트로 나갔고, 그건 이슈 본문
  // 상한(65,536)을 혼자 넘겨 `gh issue create` 가 거부하는 크기다 — 결함이 많을수록
  // 아무도 아무것도 못 보게 되는 리포트였다.

  /** 본문 크기 단언. 크기는 디스크의 파일에서 재서 생산 코드의 셈과 독립시킨다. */
  function expectBodyBytes(label: string, path: string, maxBytes: number): void {
    if (!existsSync(path)) {
      failures += 1;
      console.log(`  ❌ ${label}`);
      console.log('      리포트가 기록되지 않았다');
      return;
    }
    const bytes = statSync(path).size;
    if (bytes <= maxBytes) {
      console.log(`  ✅ ${label} (${bytes} ≤ ${maxBytes} 바이트)`);
      return;
    }
    failures += 1;
    console.log(`  ❌ ${label}`);
    console.log(`      본문 ${bytes} 바이트 — Channel A 예산 ${maxBytes} 초과`);
  }

  // 표 일곱 개를 전부 채운 캡처. 행 상한만으로는 묶이지 않는 크기를 만든다.
  {
    const side: FixPage = { id: '2:1', name: 'Scratch', nodes: [] };
    const mk = (i: number, patch: Partial<FixNode> = {}): FixNode => ({
      id: `1:${i}`,
      name: `카드 표면 ${i}`,
      type: 'FRAME',
      x: i,
      y: 0,
      w: 100,
      h: 40,
      ...patch,
    });
    const beforeNodes: FixNode[] = [];
    const afterNodes: FixNode[] = [];
    const moved: FixNode[] = [];
    // 표 하나의 행 상한(50)을 넘겨야 행 상한과 바이트 예산이 **다른 한도**라는
    // 것이 드러난다 — 둘 중 하나만 살아 있어도 통과하면 이 케이스는 아무것도 못 잡는다.
    const FILL = 55;
    for (let i = 0; i < FILL; i += 1) {
      beforeNodes.push(mk(1000 + i));
      afterNodes.push(mk(1000 + i, { name: `카드 표면 ${i} v2` }));
      beforeNodes.push(mk(2000 + i));
      afterNodes.push(mk(2000 + i, { type: 'COMPONENT' }));
      beforeNodes.push(mk(3000 + i));
      afterNodes.push(mk(3000 + i, { x: 3000 + i + 40 }));
      beforeNodes.push(mk(4000 + i));
      afterNodes.push(mk(4000 + i, { w: 320 }));
      beforeNodes.push(mk(5000 + i));
      afterNodes.push(mk(6000 + i));
      beforeNodes.push(mk(7000 + i));
      moved.push(mk(7000 + i));
    }
    const { dir, args } = plant({
      baseline: [cover(beforeNodes), side],
      current: [cover(afterNodes), { ...side, nodes: moved }],
    });
    const out = join(dir, 'report.md');
    expectExit('표 일곱 개가 전부 찬 리포트', DIFF, [...args, `--out=${out}`], 1);
    expectBodyBytes('  본문이 Channel A 예산 안에 들어간다', out, CHANNEL_A_BUDGET_BYTES);
    expectBody(
      '  바이트 예산에서 잘렸다는 사실과 요약 건수가 함께 남는다',
      out,
      [
        // 잘림을 **예산 밖에서** 말하지 않으면 예산이 바닥났을 때 이 문장부터
        // 사라진다 — 그러면 조용한 잘림이고, 상한을 두는 이유 자체가 뒤집힌다.
        '바이트 예산에서 잘렸다',
        '행 상한과는 다른 한도',
        // 표가 빠져도 **몇 건이었는지는** 남아야 한다. 이게 없으면 예산이 발견을
        // 지운 것과 발견이 없었던 것이 구별되지 않는다.
        `| 이름 변경(renamed) | ${FILL} |`,
        `| 크기 변경(resized) | ${FILL} |`,
      ],
    );
  }

  // 양성 대조 — 작은 리포트가 잘렸다고 말하면 위 케이스는 문구를 무조건 찍어도 통과한다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: [cover(withNode([CARD, LABEL], '1:2', { x: 60 }))],
    });
    const out = join(dir, 'report.md');
    expectExit('작은 리포트', DIFF, [...args, `--out=${out}`], 1);
    expectBody('  잘리지 않은 리포트는 잘렸다고 말하지 않는다', out, [], [
      '바이트 예산에서 잘렸다',
    ]);
  }

  // 위의 LF 케이스와 짝이 되는 나머지 두 모양 — CR 단독과 CRLF, 그리고 `|` 와의
  // 조합. 한 종류만 접는 이스케이프는 접지 않은 것과 같은 실패를 남기고, CRLF 를
  // 문자마다 따로 치환하면 공백이 둘이 되어 이름이 조용히 달라진다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: [
        cover([
          CARD,
          LABEL,
          { id: '1:4', name: 'Card|Grid\r\nSub', type: 'FRAME', x: 0, y: 0, w: 8, h: 8 },
          { id: '1:5', name: 'Icon\rOnly', type: 'FRAME', x: 1, y: 0, w: 8, h: 8 },
        ]),
      ],
    });
    const out = join(dir, 'report.md');
    expectExit('이름에 CR·CRLF·파이프가 든 노드', DIFF, [...args, `--out=${out}`], 1);
    expectBody(
      '  CR·CRLF 가 행을, 파이프가 열을 쪼개지 않는다',
      out,
      // 셀 경계를 걸친 조각으로 단언한다 — 이름만 보면 행이 쪼개져도 통과한다.
      ['| Card\\|Grid Sub | FRAME |', '| Icon Only | FRAME |'],
    );
  }

  // 이름 안의 백슬래시는 **우리가 넣은 escape 를 무력화한다.** `Card\|Grid` 의
  // 파이프를 `\|` 로 바꾸면 `Card\\|Grid` 가 되고, 마크다운은 그것을 "리터럴
  // 백슬래시 + 열 구분" 으로 읽는다 — 막았다고 믿은 자리가 그대로 뚫린다.
  // 공유 서식의 단위 단언과 **따로** 세우는 이유: 그 함수가 옳아도 채널이 그것을
  // 안 부르면 여기가 뚫린다. 이 레포에서 갈라진 것은 언제나 그 지점이었다.
  {
    const { dir, args } = plant({
      baseline: base,
      current: [
        cover([CARD, LABEL, { id: '1:4', name: 'Card\\|Grid', type: 'FRAME', x: 0, y: 0, w: 8, h: 8 }]),
      ],
    });
    const out = join(dir, 'report.md');
    expectExit('이름에 백슬래시+파이프가 든 노드', DIFF, [...args, `--out=${out}`], 1);
    expectBody('  백슬래시가 파이프 이스케이프를 무력화하지 않는다', out, [
      '| Card\\\\\\|Grid | FRAME |',
    ]);
  }

  // 배너에 인용되는 값은 **어떤 예산에도 들어가지 않는다.** Figma 페이지 이름에는
  // 사실상 길이 제한이 없어서, 표를 한 줄도 싣지 않은 "변화 없음" 리포트가 배너
  // 하나 때문에 이슈 본문 상한을 넘길 수 있다 — 예산을 다 지켰다고 믿는 채로.
  {
    const huge = '아주 긴 페이지 이름 '.repeat(1200);
    const main = cover([CARD, LABEL]);
    const wide: FixPage[] = [2, 3, 4].map((i) => ({
      id: `${i}:1`,
      name: `${huge}${i}`,
      nodes: [{ id: `${i}:2`, name: 'S', type: 'FRAME', x: 0, y: 0, w: 8, h: 8 }],
    }));
    const { dir, args } = plant({
      baseline: [main, ...wide],
      current: [main, ...wide],
      config: { pages: ['1:1'] },
    });
    const out = join(dir, 'report.md');
    expectExit('배너에 아주 긴 페이지 이름', DIFF, [...args, `--out=${out}`], 0);
    expectBodyBytes('  긴 이름이 예산을 삼키지 않는다', out, CHANNEL_A_BUDGET_BYTES);
    // 조용히 자르면 잘린 이름이 원래 이름으로 읽히고, 그 이름으로 Figma 를 찾는
    // 사람은 없는 것을 찾게 된다.
    expectBody('  잘랐다는 것이 말줄임표로 보인다', out, ['…']);
  }

  // ── pages.txt 잘림 ────────────────────────────────────────────────────────
  //
  // 페이지 XML 은 루트를 닫는 태그로 잘림을 판정하지만, 페이지 목록에는 종결자가
  // 없어 같은 기법을 쓸 수 없다. 그래서 두 겹으로만 좁힌다 — 페이지 수 하한과,
  // 목록에서 사라진 페이지를 리포트에 의심으로 적는 것.

  // 노드 하한은 **낱알이 달라** 이걸 못 잡는다: 큰 페이지 하나가 노드 대부분을
  // 들고 있으면 작은 페이지들이 목록에서 통째로 사라져도 노드 수는 거의 그대로다.
  {
    const bigPage: FixPage = {
      id: '1:1',
      name: 'Main',
      nodes: Array.from({ length: 60 }, (_, i) => ({
        id: `1:${i + 10}`,
        name: `N${i}`,
        type: 'FRAME',
        x: i,
        y: 0,
        w: 10,
        h: 10,
      })),
    };
    const small = (n: number): FixPage => ({
      id: `${n}:1`,
      name: `P${n}`,
      nodes: [{ id: `${n}:2`, name: 'S', type: 'FRAME', x: 0, y: 0, w: 10, h: 10 }],
    });
    const { args } = plant({
      baseline: [bigPage, small(2), small(3), small(4), small(5)],
      current: [bigPage],
      // 노드는 65 중 61 이 남아 노드 하한(0.5)을 넉넉히 통과한다. 페이지만 5 → 1.
      pagesTxt: 'Pages in this file:\n- 1:1: Main\n',
    });
    expectExit('페이지 목록 붕괴 (노드 하한은 통과하는 크기)', DIFF, args, 2);
  }

  // 하한이 발동하지 않는 크기로 한 페이지만 사라지면 거부하지 못한다 — 페이지
  // 삭제는 정당한 드리프트라 거부하면 가장 흔한 발견을 삼킨다. 대신 그 갈림길을
  // 리포트가 **말해야** 한다. 이 문장이 없으면 잘린 목록이 만든 거짓 삭제가
  // 진짜 삭제와 구별되지 않는다.
  {
    const side: FixPage = { id: '2:1', name: 'Icons', nodes: [LABEL] };
    const gone: FixPage = { id: '3:1', name: 'Tokens', nodes: [CARD] };
    const { dir, args } = plant({
      baseline: [cover([CARD, LABEL]), side, gone],
      current: [cover([CARD, LABEL]), side],
      pagesTxt: 'Pages in this file:\n- 1:1: Cover\n- 2:1: Icons\n',
    });
    const out = join(dir, 'report.md');
    expectExit('목록에서 사라진 페이지', DIFF, [...args, `--out=${out}`], 1);
    expectBody('  삭제인지 목록 잘림인지 구별되지 않는다고 적는다', out, [
      '`pages.txt` 에 없다',
      'Tokens (3:1)',
      '구별되지 않는다',
    ]);
  }
}

// ── Channel A — 플러그인 스냅샷의 프로퍼티 축 (schema 2) ─────────────────────
//
// 기하가 그대로인 편집 — 세트에 BOOLEAN 하나를 더한 것 — 은 schema 1 의 어떤 칸에도
// 나타나지 않는다. 실제로 `❖ Banner` 에 `Show description` 을 더한 편집이 베이스라인
// 대조에서 "변경 없음" 으로 나갔다. 아래 케이스는 그 축이 **보이는지**, 그리고 한쪽이
// schema 1 일 때 **안 봤다고 말하는지**를 잰다. 두 번째가 없으면 전환 기간의 리포트가
// 원래 결함과 글자 그대로 같은 "변화 없음" 을 낸다.
//
// 스냅샷 파일은 손으로 만든다(JSON 이 곧 계약이다). 모든 케이스가 같은 세트 · 변형 ·
// 인스턴스 트리에서 출발해 한 자리만 바꾼다 — 그래야 한 케이스가 정확히 한 건을 만든다.

const PLUGIN = 'figma-plugin:structure-snapshot';

interface SnapNode {
  id: string;
  name: string;
  type: string;
  depth: number;
  props?: unknown;
  main?: unknown;
}

const SHOW_DESC = { key: 'Show description#12:3', type: 'BOOLEAN', default: true };
const VARIANT_PROP = {
  key: 'Variant',
  type: 'VARIANT',
  default: 'info',
  options: ['info', 'error'],
};

/** 세트 하나(변형 둘) · 단독 컴포넌트 둘 · 인스턴스 하나. */
function bannerTree(patch: (nodes: SnapNode[]) => void = () => {}): SnapNode[] {
  const nodes: SnapNode[] = [
    { id: '1:1', name: 'Cover', type: 'canvas', depth: 0 },
    { id: '1:10', name: '❖ Banner', type: 'component_set', depth: 1, props: [VARIANT_PROP] },
    { id: '1:11', name: 'Variant=info', type: 'component', depth: 2 },
    { id: '1:12', name: 'Variant=error', type: 'component', depth: 2 },
    { id: '1:20', name: 'Icon/Close', type: 'component', depth: 1, props: [] },
    { id: '1:21', name: 'Icon/Check', type: 'component', depth: 1, props: [] },
    { id: '1:30', name: 'Banner usage', type: 'instance', depth: 1, main: '1:11' },
  ];
  patch(nodes);
  return nodes;
}

function patchNode(nodes: SnapNode[], id: string, patch: Partial<SnapNode>): void {
  const i = nodes.findIndex((n) => n.id === id);
  nodes[i] = { ...nodes[i], ...patch };
}

/** 플러그인이 쓰는 모양. schema 1 이면 두 키를 싣지 않는다 — 전환 전 베이스라인. */
function snapDoc(schema: number, nodes: SnapNode[]): string {
  const rendered = nodes.map((n) => {
    const out: Record<string, unknown> = {
      id: n.id,
      name: n.name,
      type: n.type,
      x: 0,
      y: 0,
      w: 10,
      h: 10,
      depth: n.depth,
    };
    if (schema >= 2 && n.props !== undefined) out.props = n.props;
    if (schema >= 2 && n.main !== undefined) out.main = n.main;
    return out;
  });
  return JSON.stringify({
    schema,
    fileKey: FIXTURE_FILE_KEY,
    capturedAt: null,
    capturedBy: PLUGIN,
    nodeCount: rendered.length,
    pages: [{ id: '1:1', name: 'Cover', nodes: rendered }],
  });
}

function plantSnap(baseline: string, current: string): { out: string; args: string[] } {
  const dir = scratch();
  const baselinePath = join(dir, 'baseline.json');
  const snapshotPath = join(dir, 'structure.json');
  writeFileSync(baselinePath, baseline, 'utf8');
  writeFileSync(snapshotPath, current, 'utf8');
  const configPath = join(dir, 'config.json');
  writeFileSync(
    configPath,
    JSON.stringify({
      schema: 1,
      fileKey: FIXTURE_FILE_KEY,
      fileKeyStatus: 'confirmed',
      fileUrl: `https://www.figma.com/design/${FIXTURE_FILE_KEY}/fixture`,
      pages: null,
      geometryEpsilonPx: 0.5,
      populationFloorRatio: 0.5,
    }),
    'utf8',
  );
  const out = join(dir, 'report.md');
  return {
    out,
    args: [
      `--config=${configPath}`,
      `--baseline=${baselinePath}`,
      `--snapshot=${snapshotPath}`,
      `--out=${out}`,
    ],
  };
}

/** 세트의 정의만 갈아끼운 트리 — 대부분의 케이스가 이 한 자리를 바꾼다. */
function withSetProps(props: unknown): SnapNode[] {
  return bannerTree((ns) => patchNode(ns, '1:10', { props }));
}

console.log('Channel A — 프로퍼티 축 (schema 2)');
{
  const base2 = snapDoc(2, bannerTree());

  // 음성 대조 — 이것 없이는 비교가 무엇이든 1 을 내도 아래 양성 케이스가 전부 초록이다.
  {
    const { out, args } = plantSnap(base2, base2);
    expectExit('schema 2 · 변화 없음', DIFF, args, 0);
    expectBody(
      '  세 축을 모두 봤다고 말한다',
      out,
      ['✅ 구조·기하·프로퍼티 변화 없음'],
      ['비교하지 않았다'],
    );
  }

  // 이슈가 된 편집 그 자체 — 기하 0, 프로퍼티 하나. 비교를 지우거나 이 칸을 셈에서
  // 빼면 종료 코드가 0 이 되어 여기가 빨개진다.
  {
    const { out, args } = plantSnap(base2, snapDoc(2, withSetProps([SHOW_DESC, VARIANT_PROP])));
    expectExit('프로퍼티만 더한 편집(기하 0)이 차이 1 건', DIFF, args, 1);
    expectBody(
      '  표에 세트 · 표시 이름 · 정의가 실린다',
      out,
      [
        '1건의 구조·기하·프로퍼티 변화',
        '## 프로퍼티가 추가된 컴포넌트 (1)',
        '❖ Banner',
        '| Show description |',
        'BOOLEAN · true',
      ],
      ['## 이동한 노드', '## 크기가 바뀐 노드', 'Show description#12:3'],
    );
  }

  // `#<id>` 접미사는 세트를 다시 그릴 때마다 바뀐다. 원문 키로 비교하면 매 Generate 가
  // 모든 BOOLEAN · TEXT 프로퍼티를 "삭제 + 추가" 로 만든다.
  {
    const { args } = plantSnap(
      snapDoc(2, withSetProps([SHOW_DESC, VARIANT_PROP])),
      snapDoc(2, withSetProps([{ ...SHOW_DESC, key: 'Show description#98:7' }, VARIANT_PROP])),
    );
    expectExit('키의 #<id> 접미사만 바뀐 것은 변화가 아니다', DIFF, args, 0);
  }

  {
    const { out, args } = plantSnap(snapDoc(2, withSetProps([SHOW_DESC, VARIANT_PROP])), base2);
    expectExit('프로퍼티 삭제', DIFF, args, 1);
    expectBody('  삭제 표에 직전 정의가 실린다', out, [
      '## 프로퍼티가 삭제된 컴포넌트 (1)',
      'BOOLEAN · true → —',
    ]);
  }

  // 타입이 바뀌면 기본값의 의미도 바뀐다 — 한 사건이 두 칸에 세어지면 안 된다.
  {
    const retyped = { key: 'Variant', type: 'TEXT', default: 'info' };
    const { out, args } = plantSnap(base2, snapDoc(2, withSetProps([retyped])));
    expectExit('프로퍼티 타입 변경', DIFF, args, 1);
    expectBody(
      '  타입 표에만 한 번 실린다',
      out,
      ['## 프로퍼티 타입이 바뀐 컴포넌트 (1)', 'VARIANT → TEXT'],
      ['## 프로퍼티 옵션이 바뀐 컴포넌트'],
    );
  }

  {
    const { out, args } = plantSnap(
      base2,
      snapDoc(2, withSetProps([{ ...VARIANT_PROP, default: 'error' }])),
    );
    expectExit('프로퍼티 기본값 변경', DIFF, args, 1);
    expectBody('  기본값 표에 앞뒤 값이 실린다', out, [
      '## 프로퍼티 기본값이 바뀐 컴포넌트 (1)',
      '"info" → "error"',
    ]);
  }

  {
    const { out, args } = plantSnap(
      base2,
      snapDoc(2, withSetProps([{ ...VARIANT_PROP, options: ['info', 'error', 'warning'] }])),
    );
    expectExit('프로퍼티 옵션 변경', DIFF, args, 1);
    expectBody('  옵션 표에 앞뒤 목록이 실린다', out, [
      '## 프로퍼티 옵션이 바뀐 컴포넌트 (1)',
      '[info, error] → [info, error, warning]',
    ]);
  }

  // 인스턴스가 다른 원본을 가리키게 된 것 — 한 세트의 인스턴스가 두 원본으로
  // 갈라진 상태를 스냅샷만으로 보려는 칸이다. 이름까지 실려야 id 를 들고 찾지 않는다.
  {
    const cur = snapDoc(2, bannerTree((ns) => patchNode(ns, '1:30', { main: '1:12' })));
    const { out, args } = plantSnap(base2, cur);
    expectExit('인스턴스 원본 변경', DIFF, args, 1);
    expectBody('  원본 표에 앞뒤 원본의 이름이 실린다', out, [
      '## 원본이 바뀐 인스턴스 (1)',
      'Variant=info (1:11) → Variant=error (1:12)',
    ]);
  }

  // 읽지 못한 정의(`null`)를 빈 목록으로 접으면 그 세트의 프로퍼티가 전부 "삭제됨" 으로
  // 나간다. 비교를 주장하지 않고 세어서 말해야 한다.
  {
    const { out, args } = plantSnap(base2, snapDoc(2, withSetProps(null)));
    expectExit('정의를 읽지 못한 세트는 비교하지 않는다', DIFF, args, 0);
    expectBody('  비교 불가를 세어 말한다', out, [
      '| 프로퍼티 비교 불가 | 1 |',
      '읽지 못한 것과 없는 것은 다른 주장이다',
    ]);
  }
  // 같은 짝 — 원본을 해석하지 못한 인스턴스.
  {
    const cur = snapDoc(2, bannerTree((ns) => patchNode(ns, '1:30', { main: null })));
    const { out, args } = plantSnap(base2, cur);
    expectExit('원본을 해석하지 못한 인스턴스는 비교하지 않는다', DIFF, args, 0);
    expectBody('  비교 불가를 세어 말한다', out, ['| 인스턴스 원본 비교 불가 | 1 |']);
  }

  // ── 전환 기간 — schema 1 베이스라인 + schema 2 캡처 ──────────────────────
  // 커밋된 베이스라인은 schema 1 이다. 이 조합을 거부하면 absorb 가 전환 내내 빨갛고,
  // 없는 정의를 빈 목록으로 읽으면 모든 세트의 모든 프로퍼티가 "추가됨" 으로 쏟아지며,
  // 조용히 0 으로 세면 원래 결함이 그대로다. 기존 축은 비교하고, 이 축은 안 봤다고 말한다.
  {
    const { out, args } = plantSnap(
      snapDoc(1, bannerTree()),
      snapDoc(2, withSetProps([SHOW_DESC, VARIANT_PROP])),
    );
    expectExit('schema 1 베이스라인 · schema 2 캡처 — 경고와 함께 통과', DIFF, args, 0);
    expectBody(
      '  프로퍼티 축을 안 봤다고, 무엇을 하라고 말한다',
      out,
      [
        '✅ 구조·기하 변화 없음',
        '**컴포넌트 프로퍼티 정의와 인스턴스의 원본 참조는 비교하지 않았다**',
        '프로퍼티 정보 없음',
        '--update-baseline',
        '| 프로퍼티 추가 | 비교 안 함 |',
      ],
      ['구조·기하·프로퍼티 변화 없음', '## 프로퍼티가 추가된 컴포넌트'],
    );
  }
  // 전환 기간에도 기존 축은 살아 있다 — 경고가 비교를 통째로 끄면 여기가 빨개진다.
  {
    const cur = snapDoc(2, bannerTree((ns) => patchNode(ns, '1:20', { name: 'Icon/Dismiss' })));
    const { args } = plantSnap(snapDoc(1, bannerTree()), cur);
    expectExit('schema 1 베이스라인이어도 기존 축은 비교한다', DIFF, args, 1);
  }

  // ── 스냅샷 검증 — schema 2 의 두 키는 있는지 여부가 계약이다 ─────────────
  {
    const { args } = plantSnap(base2, snapDoc(2, withSetProps(undefined)));
    const r = expectExit('검증: 세트에 props 가 없다', DIFF, args, 2);
    expectFailedWith('  거부 사유가 그 자리를 가리킨다', r, ['nodes[1].props', '반드시 싣는다']);
  }
  // 세트 안의 변형은 정의를 갖지 않는다 — 부모를 보지 않는 판정은 이것을 통과시킨다.
  {
    const cur = snapDoc(2, bannerTree((ns) => patchNode(ns, '1:11', { props: [] })));
    const r = expectExit('검증: 세트 안 변형이 props 를 싣는다', DIFF, plantSnap(base2, cur).args, 2);
    expectFailedWith('  소유 판정이 부모를 본다', r, ['nodes[2].props', '세트 밖 컴포넌트만']);
  }
  {
    const cur = snapDoc(2, bannerTree((ns) => patchNode(ns, '1:30', { main: undefined })));
    const r = expectExit('검증: 인스턴스에 main 이 없다', DIFF, plantSnap(base2, cur).args, 2);
    expectFailedWith('  거부 사유가 그 자리를 가리킨다', r, ['nodes[6].main']);
  }
  // schema 1 이 두 키를 싣고 있으면 파일이 자기 모양에 대해 거짓말하는 것이다.
  {
    const lying = JSON.parse(snapDoc(1, bannerTree())) as {
      pages: { nodes: Record<string, unknown>[] }[];
    };
    lying.pages[0].nodes[1].props = [VARIANT_PROP];
    const r = expectExit(
      '검증: schema 1 이 props 를 싣는다',
      DIFF,
      plantSnap(base2, JSON.stringify(lying)).args,
      2,
    );
    expectFailedWith('  거부 사유가 schema 를 말한다', r, ['schema 1 캡처는 프로퍼티를 싣지 않는다']);
  }
  {
    const cur = snapDoc(2, withSetProps([{ key: 'X', type: 'BOOLEAN', default: 3 }]));
    const r = expectExit('검증: 프로퍼티 기본값이 수다', DIFF, plantSnap(base2, cur).args, 2);
    expectFailedWith('  거부 사유가 그 필드를 가리킨다', r, ['props[0].default']);
  }
}

// ── Channel B — fidelity 인제스트 ────────────────────────────────────────────

/**
 * 레지스트리의 컴포넌트 수 — 전체 스윕의 모집단 하한이 이것을 분모로 쓴다.
 *
 * 하네스가 이 수를 리터럴로 적어두면 컴포넌트가 늘 때 조용히 낡는다. 낡은 픽스처는
 * "정상 리포트" 라고 이름 붙은 케이스를 **하한 실패로** 만드는데, 그 빨간불은
 * 프로덕션이 아니라 픽스처가 늙었다는 뜻이라 읽는 사람을 엉뚱한 곳으로 보낸다.
 * 프로덕션이 세는 것과 같은 파일에서 같은 방식으로 센다.
 */
const REGISTRY_SIZE: number = (() => {
  const parsed = JSON.parse(
    readFileSync(join(ROOT, 'src', 'data', 'components.json'), 'utf8'),
  ) as { components?: Record<string, unknown> };
  return Object.keys(parsed.components ?? {}).length;
})();

/**
 * 깨끗한 전체 스윕.
 *
 * `componentsRead` 가 레지스트리 전체인 이유: 필터가 없는 스윕은 레지스트리를 끝까지
 * 돈 것이어야 하고, 그렇지 않으면 모집단 하한이 — 옳게 — 거부한다.
 */
const CLEAN_REPORT: FidelityReport = {
  log: [],
  misses: [],
  componentsRead: REGISTRY_SIZE,
  checksRun: 3,
  unchecked: [],
  hostDerived: [],
  notes: [],
  strokeUnstated: [],
  fixtures: [],
};

// 타입이 생산자의 것이므로 필드 이름이 바뀌면 여기가 **컴파일 에러**로 먼저 깨진다.
const ONE_MISS: FidelityMiss = {
  component: 'Button',
  field: 'fill',
  expected: '#000',
  actual: '#fff',
  looksLike: 'the surface reads solid where the code tints it',
};

const FIDELITY_AT = '2000-01-01T00:00:00.000Z';

function envelope(report: FidelityReport, entryFilter: string | null = null): string {
  return serialiseFidelityReport(report, { generatedAt: FIDELITY_AT, entryFilter });
}

function writeFidelity(dir: string, report: FidelityReport, entryFilter: string | null = null): string {
  const path = join(dir, 'fidelity-20000101-000000.json');
  writeFileSync(path, envelope(report, entryFilter), 'utf8');
  return path;
}

/**
 * 생산자가 만든 정상 봉투에서 **한 자리만** 망가뜨린다.
 *
 * 손으로 적은 깨진 봉투는 의도한 곳 말고 다른 곳도 같이 틀려 있기 쉽고, 그러면
 * 그 케이스는 자기가 겨눈 검증이 아니라 먼저 걸린 검증을 재는 것이 된다.
 */
function writeBrokenFidelity(dir: string, patch: (env: Record<string, unknown>) => void): void {
  const env = JSON.parse(envelope(CLEAN_REPORT)) as Record<string, unknown>;
  patch(env);
  writeFileSync(join(dir, 'fidelity-20000101-000000.json'), JSON.stringify(env), 'utf8');
}

console.log('Channel B — ingest_fidelity.ts');
{
  // ── 인프라 실패(2) ────────────────────────────────────────────────────────

  // 부재 가드를 지워도 목록 읽기 래퍼가 ENOENT 를 잡아 같은 2 를 낸다 — Channel A 의
  // `pages.txt` 부재와 같은 짝이고, 두 거부가 사람에게 시키는 일이 다르다.
  {
    const gone = join(scratch(), 'not-here');
    const r = expectExit('디렉터리 없음', INGEST, [`--dir=${gone}`], 2);
    expectFailedWith('  거부한 것이 부재 가드다 (목록 읽기 래퍼가 아니라)', r, ['디렉터리가 없음']);
  }

  // 존재한다고 디렉터리인 것은 아니다. 파일을 `--dir` 로 주면 목록 읽기가 ENOTDIR
  // 을 던지는데, 감싸지 않으면 그 예외가 Node 를 종료 코드 **1** 로 끝내고 자동화는
  // 그것을 "디자이너가 무언가 바꿨다" 로 읽는다 — 오타 하나가 이슈가 된다.
  // 부재 가드는 이 입력을 통과시키므로(파일은 존재한다) 여기 걸리는 것은 래퍼뿐이다.
  {
    const dir = scratch();
    const notADir = join(dir, 'a-file');
    writeFileSync(notADir, 'not a directory', 'utf8');
    const r = expectExit('--dir 가 디렉터리가 아님', INGEST, [`--dir=${notADir}`], 2);
    expectFailedWith('  목록 읽기 실패가 1 이 아니라 2 로 나간다', r, ['디렉터리를 읽지 못함']);
  }

  // 형제 래퍼 — 목록에는 올라오지만 읽을 수 없는 리포트. 파일명 규칙을 만족하는
  // **디렉터리**가 정확히 그 모양이다: 목록 필터를 통과하고 읽기에서만 던진다.
  // 읽기와 파싱을 나눠 잡는 이유도 여기서 드러난다 — 권한 문제를 "JSON 이 깨졌다"
  // 로 보고하면 고칠 곳을 잘못 짚는다.
  {
    const dir = scratch();
    mkdirSync(join(dir, 'fidelity-20000101-000000.json'), { recursive: true });
    const r = expectExit('리포트를 읽지 못함 (자리에 디렉터리)', INGEST, [`--dir=${dir}`], 2);
    expectFailedWith('  읽기 실패를 파싱 실패로 보고하지 않는다', r, ['리포트를 읽지 못함']);
  }

  // 침묵은 동의가 아니다 — 리포트 부재는 "결함 없음"이 아니라 "미실행"이다.
  expectExit('리포트 없음', INGEST, [`--dir=${scratch()}`], 2);

  {
    const dir = scratch();
    writeFileSync(join(dir, 'fidelity-20000101-000000.json'), '{ not json', 'utf8');
    expectExit('JSON 깨짐', INGEST, [`--dir=${dir}`], 2);
  }

  // 봉투가 다르면 그 파일은 우리가 아는 리포트가 아니다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      env.kind = 'something-else';
    });
    expectExit('kind 불일치', INGEST, [`--dir=${dir}`], 2);
  }
  // 스키마가 다르면 필드 의미가 달라져 조용히 잘못 읽는다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      env.schema = 2;
    });
    expectExit('schema 불일치', INGEST, [`--dir=${dir}`], 2);
  }
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      delete env.report;
    });
    expectExit('report 없음', INGEST, [`--dir=${dir}`], 2);
  }

  // 계수기가 깨졌으면 그 위에 얹힌 "미스 0" 도 근거가 없다. 두 필드를 따로
  // 재는 이유: 조건의 한쪽만 지워도 나머지 한쪽이 그것을 가린다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).componentsRead = -1;
    });
    expectExit('componentsRead 가 셈이 아님', INGEST, [`--dir=${dir}`], 2);
  }
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).checksRun = 2.5;
    });
    expectExit('checksRun 이 셈이 아님', INGEST, [`--dir=${dir}`], 2);
  }

  // 검사 0 건과 결함 0 건은 출력이 같다.
  {
    const dir = scratch();
    writeFidelity(dir, { ...CLEAN_REPORT, checksRun: 0 });
    expectExit('checksRun 0', INGEST, [`--dir=${dir}`], 2);
  }
  // 같은 게이트의 형제 — 읽은 컴포넌트가 0 이면 "미스 0" 을 떠받칠 모집단이 아예 없다.
  //
  // **필터를 걸어 재는 이유**: 필터가 없으면 모집단 하한이 0 을 먼저 거부해서, 이
  // 게이트를 지워도 하한이 대신 잡아 초록으로 남는다. 필터가 걸린 스윕은 하한이
  // 면제되므로 이 게이트만 남고, 그때에야 이 케이스가 자기 이름값을 한다.
  {
    const dir = scratch();
    writeFidelity(dir, { ...CLEAN_REPORT, componentsRead: 0 }, 'Alert');
    expectExit('componentsRead 0', INGEST, [`--dir=${dir}`], 2);
  }

  // 전체 스윕이 레지스트리의 절반도 못 읽었으면 그 "미스 0" 은 근거가 없다. 이 채널의
  // 0 은 자동화가 이슈를 **만들지 않는** 쪽이라, 붕괴한 스윕은 그대로 두면 사람 눈에
  // 닿는 흔적을 하나도 남기지 않는다 — 깨끗한 주기와 완전히 같은 모양이다.
  {
    const dir = scratch();
    writeFidelity(dir, { ...CLEAN_REPORT, componentsRead: 1 });
    expectExit('전체 스윕인데 모집단이 붕괴', INGEST, [`--dir=${dir}`], 2);
  }
  // 필터가 걸린 스윕은 좁은 것이 그 실행의 목적이다 — 같은 잣대를 대면 정상 실행이
  // 실패가 된다. 면제가 사라지면 이 케이스가 빨개진다.
  {
    const dir = scratch();
    writeFidelity(dir, { ...CLEAN_REPORT, componentsRead: 1 }, 'Alert');
    expectExit('필터 걸린 스윕은 모집단 하한 면제', INGEST, [`--dir=${dir}`], 0);
  }

  // 그 하한의 **분모**. 레지스트리가 비면 어떤 하한도 0 이 되어 아무것도 읽지 않은
  // 스윕이 통과하는데, 꺼진 하한은 없는 하한보다 나쁘다 — 있다고 적혀 있기 때문이다.
  //
  // 레지스트리 경로는 cwd 가 아니라 **스크립트 자신의 자리**에서 풀린다. 그래서
  // 이 축을 재려면 스크립트를 레지스트리째로 옮겨 심는 수밖에 없다 — 레포의 실제
  // 파일을 비우는 것은 다른 케이스를 전부 망가뜨린다. 옮겨 심은 나무가 그 자체로
  // 멀쩡하다는 것은 바로 아래 대조가 보인다.
  {
    const grove = scratch();
    mkdirSync(join(grove, 'reverse'), { recursive: true });
    mkdirSync(join(grove, 'src', 'data'), { recursive: true });
    for (const f of ['ingest_fidelity.ts', 'report_format.ts']) {
      writeFileSync(join(grove, 'reverse', f), readFileSync(join(ROOT, 'reverse', f), 'utf8'), 'utf8');
    }
    const transplanted = join(grove, 'reverse', 'ingest_fidelity.ts');
    const registry = join(grove, 'src', 'data', 'components.json');
    const drop = scratch();
    writeFidelity(drop, CLEAN_REPORT);

    writeFileSync(registry, JSON.stringify({ components: {} }), 'utf8');
    const r = expectExit('레지스트리가 비어 있음', transplanted, [`--dir=${drop}`], 2);
    expectFailedWith('  거부한 것이 분모 가드다', r, ['레지스트리가 비어 있음']);

    // 분모를 **읽지 못하는** 쪽. 하한을 건너뛰고 통과시키면 이 파일 하나를 지우는
    // 것만으로 하한이 꺼지는데, 꺼진 하한은 없는 하한보다 나쁘다 — 있다고 적혀
    // 있기 때문이다. 감싸지 않으면 그 예외가 종료 코드 1 로 나가 "디자이너가
    // 무언가 바꿨다" 로 읽힌다.
    replaceWithDirectory(registry);
    const unreadable = expectExit('레지스트리를 읽지 못함', transplanted, [`--dir=${drop}`], 2);
    expectFailedWith('  읽기 실패에 하한을 건너뛰지 않는다', unreadable, ['레지스트리를 읽지 못함']);
    rmSync(registry, { recursive: true, force: true });

    // 대조가 없으면 위의 빨간불이 "레지스트리가 비었다" 가 아니라 "옮겨 심은 게
    // 애초에 안 돈다" 여도 똑같이 보인다 — 그러면 이 케이스는 아무것도 재지 않는다.
    writeFileSync(
      registry,
      readFileSync(join(ROOT, 'src', 'data', 'components.json'), 'utf8'),
      'utf8',
    );
    expectExit('  옮겨 심은 스크립트는 정상 레지스트리로 걷는다', transplanted, [
      `--dir=${drop}`,
      `--out=${join(grove, 'out.md')}`,
    ], 0);
  }

  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).misses = { count: 0 };
    });
    expectExit('misses 가 배열이 아님', INGEST, [`--dir=${dir}`], 2);
  }
  // 배열이라는 것만 보고 원소를 안 보면 원소 모양 검사는 렌더가 우연히 하게 된다.
  // 객체가 아닌 원소는 셀이 전부 빈 행으로 렌더되고, 그 행은 값이 실제로 비어 있던
  // 진짜 불일치와 글자 그대로 구별되지 않는다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).misses = [42];
    });
    expectExit('misses 원소가 객체가 아님', INGEST, [`--dir=${dir}`], 2);
  }
  // 빈 객체가 내는 행이 정확히 그 "셀이 전부 빈 행" 이다 — 객체라는 것만 보고
  // 통과시키면 거부하는 근거가 절반만 강제된다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).misses = [{}];
    });
    expectExit('misses 원소가 빈 객체', INGEST, [`--dir=${dir}`], 2);
  }
  // 반대쪽 양성 대조 — 가르는 자리는 값이 아니라 **키**다. 다섯 자리를 갖고 값이
  // 빈 미스는 "비교했고 한쪽이 비어 있었다" 는 진짜 주장이라 통과해야 한다. 이
  // 케이스가 없으면 위 검사를 값 기준으로 조여도 아무도 알아채지 못하고, 그때
  // 진짜 불일치가 조용히 버려진다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).misses = [
        { component: 'Button', field: 'fill', expected: '', actual: '', looksLike: '' },
      ];
    });
    expectExit('값이 빈 미스는 진짜 주장이라 통과한다', INGEST, [`--dir=${dir}`], 1);
  }
  // 모양이 틀린 목록을 걸러내면 빈 배열이 남고, 빈 unchecked 는 "비교 안 된 것
  // 없음" 이라는 적극적 주장으로 렌더된다 — 부분 검사가 전수 검사로 뒤집힌다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).unchecked = [{ name: 'Card' }];
    });
    expectExit('unchecked 가 문자열 배열이 아님', INGEST, [`--dir=${dir}`], 2);
  }
  // strokeUnstated 는 hostDerived 와 같은 급 — 모양이 틀리면 강등하지 않고
  // 거부한다. 강등해서 빈 배열이 남으면 "진술 없어 비교 못 한 마크 획 없음" 이
  // 라는 주장이 되어, 152개 중 151개를 못 읽은 실행이 조용히 통과한다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).strokeUnstated = [{ name: 'Card' }];
    });
    expectExit('strokeUnstated 가 문자열 배열이 아님', INGEST, [`--dir=${dir}`], 2);
  }
  // notes 도 misses 와 같은 급 — 객체가 아니거나 세 자리를 하나도 갖지 않은
  // 원소는 셀이 전부 빈 행으로 렌더돼 진짜 관찰과 구별되지 않는다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).notes = [42];
    });
    expectExit('notes 원소가 객체가 아님', INGEST, [`--dir=${dir}`], 2);
  }
  // null 은 "전체 레지스트리를 훑었다" 는 뜻이라, 다른 모양을 null 로 읽으면
  // 부분 스윕이 전수 스윕으로 보고된다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      env.entryFilter = 42;
    });
    expectExit('entryFilter 가 문자열도 null 도 아님', INGEST, [`--dir=${dir}`], 2);
  }

  // ── 양성 대조 ─────────────────────────────────────────────────────────────
  // 전부 2 만 기대하는 하네스는 스크립트가 시작조차 못 해도 통과한다.

  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('미스 없는 정상 리포트', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    // "컴포넌트 145개" 는 그 스윕이 무엇을 덮었는지 말하지 않지만 "145개 중 145개"
    // 는 말한다. 분모가 빠지면 하한을 간신히 넘긴 실행과 전부 읽은 실행이 같은
    // 문장으로 나가고, 그 ✅ 의 범위를 읽는 사람이 알 수 없다.
    expectBody('  분모와 함께 읽은 수를 말한다', out, [
      `레지스트리 ${REGISTRY_SIZE}개 중 컴포넌트 ${REGISTRY_SIZE}개`,
    ]);
  }

  {
    const dir = scratch();
    writeFidelity(dir, { ...CLEAN_REPORT, misses: [ONE_MISS] });
    const out = join(dir, 'out.md');
    expectExit('미스 있는 리포트', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    // 종료 코드 1 은 미스 행이 전부 `(미상)` 으로 렌더돼도 그대로 1 이다.
    // 그래서 값이 실제로 도착했는지는 본문에서만 확인할 수 있다.
    expectBody(
      '  미스 행이 값을 싣고 렌더된다',
      out,
      ['Button', 'fill', '#000', '#fff'],
      ['(미상)'],
    );
  }

  // 미스의 다섯 자리는 전부 봉투가 실어 온 문자열이라 무엇이든 들어올 수 있다.
  // Channel A 가 레이어 이름에 대해 재는 것과 **같은 축**이고, 그 하드닝이 이
  // 채널에는 오지 않은 적이 세 라운드 있었다.
  {
    const dir = scratch();
    writeFidelity(dir, {
      ...CLEAN_REPORT,
      misses: [{ ...ONE_MISS, field: 'fill\\|stroke', looksLike: 'a\nb' }],
    });
    const out = join(dir, 'out.md');
    expectExit('미스 값에 백슬래시·파이프·줄바꿈', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    expectBody('  값이 행도 열도 쪼개지 않는다', out, ['| fill\\\\\\|stroke |']);
    expectBodyMatch('  줄바꿈이 표 행을 쪼개지 않는다 (Channel B)', out, (body) => {
      const split = body.split('\n').filter((l) => l.startsWith('b |') || l === 'b');
      return split.length === 0 ? null : `값의 꼬리가 독립된 행이 됐다: ${split[0]}`;
    });
  }

  // 필터가 걸린 스윕은 자기가 확인하지 않은 범위를 본문에 밝힌다. 그 배너가
  // 사라지면 부분 스윕이 전수 스윕처럼 읽히는데, 종료 코드는 그대로 0 이다.
  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT, 'Alert');
    const out = join(dir, 'out.md');
    expectExit('필터 걸린 스윕', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody(
      '  부분 스윕 배너가 필터를 밝힌다',
      out,
      ['Alert'],
      // 필터가 걸린 스윕에는 분모가 없다 — 레지스트리 전체를 훑은 것이 아니므로
      // "N개 중" 이라고 말하면 그 실행이 덮지 않은 범위를 덮었다고 주장하게 된다.
      ['레지스트리 '],
    );
  }

  // 비교하지 않은 항목 표의 **행 상한**. 앞의 예산 케이스는 항목이 길어 바이트
  // 예산이 먼저 물어서, 행 상한을 통째로 지워도 전부 초록으로 남는다 — 이 축을
  // 재려면 행은 많고 **바이트는 넉넉한** 픽스처가 따로 있어야 한다.
  {
    const dir = scratch();
    const unchecked = Array.from({ length: ROWS_OVER_CAP }, (_, i) => `C${i}.padding`);
    // 픽스처가 의도한 창을 벗어나면 이 케이스는 이름과 다른 것을 재게 된다.
    ok(
      '  픽스처가 바이트 예산에 걸리지 않을 만큼 짧다',
      utf8Bytes(unchecked.join('\n')) < 2000,
      `${utf8Bytes(unchecked.join('\n'))} 바이트 — 바이트 예산이 먼저 물면 행 상한을 재지 못한다`,
    );
    writeFidelity(dir, { ...CLEAN_REPORT, unchecked });
    const out = join(dir, 'out.md');
    expectExit('비교하지 않은 항목이 행 상한을 넘음', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody('  행 상한에서 자르고 그 사실을 말한다', out, [
      truncationNotice(TABLE_ROW_CAP, ROWS_OVER_CAP),
    ]);
  }

  // strokeUnstated 와 notes 가 Channel B 이슈에 실제로 나온다는 것 — hostDerived
  // 처럼 필드만 추가하고 렌더러가 읽지 않으면, 152개 중 151개를 비교하지 못한
  // 실행도 "불일치 0" 으로만 읽힌다. 이 절이 없으면 이 테스트 자체가 실패해야 한다.
  {
    const dir = scratch();
    writeFidelity(dir, {
      ...CLEAN_REPORT,
      strokeUnstated: ['Checkbox', 'Radio'],
      notes: [
        {
          component: 'Select',
          field: 'letterSpacing.binding',
          detail: '1 of 1 label(s) carry letter spacing as a literal.',
        },
      ],
    });
    const out = join(dir, 'out.md');
    expectExit('진술 없어 비교 못 한 축 — 렌더 확인', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody(
      '  획 축 요약과 note 표가 모두 본문에 실린다',
      out,
      [
        '## 진술 없어 비교 못 한 축 (3)',
        `${REGISTRY_SIZE}개 중 2개가 마크 두께를 진술하지 않아`,
        'Select',
        'letterSpacing.binding',
        'literal',
      ],
    );
    // `unchecked` 는 비어 있으니 "모두 비교됐다" 문장이 그대로 있어야 한다 —
    // strokeUnstated/notes 가 그 ratchet 으로 새어 들어가면 이 문장이 사라진다.
    expectBody(
      '  strokeUnstated/notes 가 unchecked 절로 새지 않는다',
      out,
      ['_없음 — 읽은 값이 모두 비교됐다._'],
    );
  }

  // 양성 대조 — 둘 다 비어 있으면 절 자체가 나오지 않는다. hostDerived 가 0개일 때
  // 자기 절을 안 그리는 것과 같은 규칙이고, CLEAN_REPORT 가 그 경우다.
  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('strokeUnstated·notes 없는 정상 리포트', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody(
      '  둘 다 비어 있으면 절이 안 나온다',
      out,
      [],
      ['## 진술 없어 비교 못 한 축'],
    );
  }

  // 옛 리포트(플러그인이 이 두 필드를 아직 안 보내던 시절)와의 호환 — 필드
  // 자체가 없어도 빈 목록으로 읽혀 통과해야 한다. hostDerived 가 옵셔널인 것과
  // 같은 이유다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      const report = (env.report as Record<string, unknown>);
      delete report.strokeUnstated;
      delete report.notes;
    });
    expectExit('strokeUnstated·notes 필드 자체가 없는 옛 리포트', INGEST, [`--dir=${dir}`], 0);
  }

  // 배너에 인용되는 값은 **어떤 예산에도 들어가지 않는다.** 그 값들은 이 스크립트가
  // 만든 것이 아니라 봉투가 실어 온 것이라 길이를 스스로 정하지 못한다 — 필터 하나가
  // 10KB 이면 예산을 다 지킨 리포트가 채널 몫을 넘긴다. Channel A 가 페이지 이름에
  // 대해 같은 것을 재는데, 그 하드닝이 이 채널에는 오지 않은 적이 있다.
  {
    const dir = scratch();
    // 꼬리에 표식을 둔다 — 상한에서 잘렸다면 이 표식은 본문에 도달하지 못한다.
    // 길이만 재면 상한을 조금 늘린 회귀를 못 잡는다.
    const filter = `${'가'.repeat(400)}TAILSENTINEL`;
    writeFidelity(dir, CLEAN_REPORT, filter);
    const out = join(dir, 'out.md');
    expectExit('배너에 아주 긴 필터', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBodyMatch('  긴 필터가 예산을 삼키지 않는다', out, (body) => {
      const size = utf8Bytes(body);
      return size <= CHANNEL_B_BUDGET_BYTES
        ? null
        : `리포트가 ${size} 바이트 — 채널 예산 ${CHANNEL_B_BUDGET_BYTES} 초과`;
    });
    // 조용히 자르면 잘린 값이 원래 값으로 읽힌다. 자른 자리는 말줄임표로 보인다.
    expectBody('  잘랐다는 것이 말줄임표로 보인다', out, ['…'], ['TAILSENTINEL']);
  }

  // 드롭 디렉터리에 여러 개가 쌓였을 때 **읽지 않은 나머지**를 밝히는 유일한 문장.
  // 이 배너가 없으면 하나만 읽은 실행이 전수 실행처럼 읽히고, 종료 코드는 그대로
  // 0 이다 — 읽지 않은 리포트에 미스가 들어 있어도 아무 흔적이 남지 않는다.
  // stderr 에도 같은 말이 있지만 자동화가 사람에게 건네는 것은 본문뿐이다.
  {
    const dir = scratch();
    writeFileSync(join(dir, 'fidelity-19990101-000000.json'), envelope(CLEAN_REPORT), 'utf8');
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('드롭 디렉터리에 리포트가 둘', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody('  읽지 않은 리포트가 있다고 본문에 적는다', out, [
      // 몇 개 중 몇 개를 읽었는지 · 어느 것을 읽었는지 · 나머지에 대해 무엇을
      // 주장하지 않는지. 셋 중 하나라도 빠지면 읽는 사람이 나머지를 셈해야 한다.
      '리포트가 2개',
      'fidelity-20000101-000000.json',
      '나머지 1개는 읽지 않았다',
    ]);
  }

  // 양성 대조 — 하나뿐인데도 "나머지를 읽지 않았다" 고 말하면 그 배너는 매 주기
  // 나오고, 매 주기 나오는 경고는 읽히지 않는다.
  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('드롭 디렉터리에 리포트가 하나', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBody('  하나뿐이면 읽지 않은 것을 말하지 않는다', out, [], ['읽지 않았다']);
  }

  // 쓰기 실패가 종료 코드 1 로 새어 나가면 자동화는 그것을 "변화 있음" 으로 읽고
  // 존재하지 않는 파일로 이슈를 만든다. Channel A 의 같은 래퍼를 재는 케이스가 이미
  // 있는데 이쪽에도 두는 이유: 같은 하드닝이 한쪽 채널에만 적용된 사고가 이
  // 레포에서 세 번 반복됐다. 한쪽만 감싸면 다른 쪽으로 같은 실패가 그대로 샌다.
  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    expectExit(
      '리포트 기록 실패 (Channel B)',
      INGEST,
      [`--dir=${dir}`, `--out=${join(dir, 'nope', 'r.md')}`],
      2,
    );
  }

  // 이 채널의 산출물은 디자이너가 **한 번** 돌린 결과의 사본이고 드롭 디렉터리에
  // 누적된다. 새 리포트가 들어오지 않으면 같은 파일이 매 주기 다시 렌더되므로,
  // 생성 시각을 말하지 않으면 반년 전의 ✅ 가 이번 주기의 답으로 읽힌다.
  {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('오래된 리포트도 렌더된다', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    // 시각 자체를 단언한다 — 문구가 아니라 **데이터**라서 표현이 바뀌어도 남는다.
    expectBody('  언제의 캔버스인지 본문에 남는다', out, [FIDELITY_AT]);
  }

  // 어느 컴포넌트의 것인지 적히지 않은 행은 보이기는 해도 고칠 곳을 알려주지 않는다.
  // 세어서 말하지 않으면 `(미상)` 묶음이 실재하는 컴포넌트 이름처럼 읽힌다.
  {
    const dir = scratch();
    writeBrokenFidelity(dir, (env) => {
      (env.report as Record<string, unknown>).misses = [
        { field: 'fill', expected: '#000', actual: '#fff', looksLike: 'surface reads solid' },
      ];
    });
    const out = join(dir, 'out.md');
    expectExit('컴포넌트가 적히지 않은 미스', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    // 묶음 제목에도 `(미상)` 이 나오므로 **존재**만으로는 못 가른다. 세어서 말하는
    // 문장이 있어야 두 번 나온다.
    expectBodyMatch('  귀속되지 않은 건수를 세어 말한다', out, (body) => {
      const n = countOf(body, '(미상)');
      return n >= 2
        ? null
        : `'(미상)' 이 ${n}회 — 묶음 제목만 있고 그 수를 세어 말한 문장이 없다`;
    });
  }

  // 한 컴포넌트가 표 상한을 넘을 때. 잘림 문구를 공유 서식에서 가져와 단언하므로,
  // 이 채널이 그 문구에서 이탈하면 여기가 빨개진다 — 두 채널이 같은 사실을 같은
  // 문장으로 적는다는 것이 그 모듈의 존재 이유이자 여기서의 검증 대상이다.
  {
    const dir = scratch();
    const many: FidelityMiss[] = Array.from({ length: ROWS_OVER_CAP }, (_, i) => ({
      component: 'Button',
      field: `field${i}`,
      expected: '#000',
      actual: '#fff',
      looksLike: 'short',
    }));
    writeFidelity(dir, { ...CLEAN_REPORT, misses: many });
    const out = join(dir, 'out.md');
    expectExit('한 컴포넌트가 표 상한을 넘음', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    expectBody('  잘림 문구가 공유 서식과 같다 (Channel B)', out, [
      truncationNotice(TABLE_ROW_CAP, ROWS_OVER_CAP),
    ]);
  }

  // 표마다의 행 상한만으로는 문서가 묶이지 않는다 — 불일치는 컴포넌트별로 쪼개져
  // 렌더되므로 표 하나가 상한 아래여도 표가 수십 개면 이슈 본문 상한을 넘긴다.
  // 넘기면 그 주기의 발견이 통째로 사라진다: 결함이 많을수록 조용해지는 리포트다.
  //
  // 컴포넌트마다 행을 상한 아래로 두는 이유 — 행 잘림이 끼면 이 케이스가 바이트
  // 예산이 아니라 행 상한을 재게 된다.
  {
    const dir = scratch();
    const wide = 'x'.repeat(200);
    const many: FidelityMiss[] = [];
    for (let c = 0; c < 60; c += 1) {
      for (let i = 0; i < 10; i += 1) {
        many.push({
          component: `Comp${c}`,
          field: `f${i}`,
          expected: '#000',
          actual: '#fff',
          looksLike: wide,
        });
      }
    }
    writeFidelity(dir, { ...CLEAN_REPORT, misses: many });
    const out = join(dir, 'out.md');
    expectExit('불일치가 바이트 예산을 넘음', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    expectBodyMatch('  바이트 예산에서 잘렸다고 말한다 (Channel B)', out, (body) =>
      body.includes('바이트') && body.includes('잘렸다')
        ? null
        : '바이트 예산 잘림 문구가 없다 — 예산이 꺼져 있으면 이 문장이 사라진다',
    );
    expectBodyMatch('  잘린 리포트가 채널 예산 안에 있다', out, (body) => {
      const size = utf8Bytes(body);
      return size <= CHANNEL_B_BUDGET_BYTES
        ? null
        : `리포트가 ${size} 바이트 — 채널 예산 ${CHANNEL_B_BUDGET_BYTES} 초과`;
    });
  }

  // 같은 예산을 **코드 단위로** 세면 한글이 실제의 1/3 로 잡힌다. 이 픽스처는 그
  // 오차가 정확히 상한 초과가 되는 창에 있다 — 바이트로 세면 넘고 문자로 세면 안
  // 넘는다. 앞 케이스(ASCII)는 두 셈 모두에서 넘으므로 이 축을 재지 못한다.
  {
    const dir = scratch();
    const wide = '가'.repeat(120);
    const many: FidelityMiss[] = [];
    for (let c = 0; c < 40; c += 1) {
      for (let i = 0; i < 2; i += 1) {
        many.push({
          component: `컴포넌트${c}`,
          field: '필드',
          expected: '기댓값',
          actual: '실젯값',
          looksLike: wide,
        });
      }
    }
    // 픽스처가 의도한 창을 벗어나면 이 케이스는 이름과 다른 것을 재게 된다.
    const blob = many
      .map((m) => `${m.component}${m.field}${m.expected}${m.actual}${m.looksLike}`)
      .join('');
    ok(
      '  픽스처가 바이트/문자 셈이 갈리는 창 안에 있다',
      utf8Bytes(blob) > 24000 && blob.length < 24000,
      `바이트 ${utf8Bytes(blob)} · 문자 ${blob.length} — 둘 다 예산 한쪽에 있으면 이 축을 재지 못한다`,
    );
    writeFidelity(dir, { ...CLEAN_REPORT, misses: many });
    const out = join(dir, 'out.md');
    expectExit('한글 불일치가 바이트 예산을 넘음', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
    expectBodyMatch('  한글에서도 바이트로 세어 잘린다', out, (body) =>
      body.includes('바이트') && body.includes('잘렸다')
        ? null
        : '문자 수로 세면 이 문서는 예산 안이라 잘리지 않는다 — 예산이 코드 단위로 세고 있다',
    );
  }

  // **미스가 하나도 없는데** 예산을 넘기는 경로. 비교하지 않은 항목은 표 하나라
  // 행 상한이 묶어줄 것 같지만, 행 상한은 셀이 좁을 때만 맞는 근사다 — 이 목록의
  // 원소는 "왜 비교하지 않았는지" 를 담은 문장이라 한 행이 100 바이트를 넘는다.
  //
  // 이 축을 따로 재는 이유: 위 케이스들은 전부 `unchecked` 가 비어 있어서, 이 표의
  // 바이트 상한을 통째로 지워도 전부 초록으로 남는다. 그리고 이 경로는 종료 코드가
  // **0** 이라 더 조용하다 — 불일치가 없으니 자동화는 이슈조차 만들지 않는데, 그
  // 리포트가 채널 몫을 넘겨 이슈 본문을 거부시키는 것은 옆 채널이 발견을 실었을 때다.
  //
  // 항목이 **길어야** 이 축을 잰다. 짧은 항목 400개는 행 상한 50 이 먼저 묶어서,
  // 바이트 예산을 통째로 지워도 문서가 채널 몫 안에 남는다 — 그 픽스처로는 이
  // 케이스가 초록인 채 아무것도 지키지 않는다(실제로 그렇게 한 번 썼다). 한 행이
  // 상한의 1/50 을 넘도록 세워야 행 상한이 구해주지 못한다.
  {
    const dir = scratch();
    const why =
      '이 값은 per-size 표 아래에서 한 번만 진술되고 미리보기가 어느 행을 고르는지 이 모듈이 알 수 없어 비교하지 않았다. ';
    const unchecked: string[] = [];
    for (let i = 0; i < 400; i += 1) {
      unchecked.push(`컴포넌트${i}.padding — ${why.repeat(4)}`);
    }
    // 픽스처가 의도한 창을 벗어나면 이 케이스는 이름과 다른 것을 재게 된다.
    ok(
      '  픽스처의 행 상한만으로는 예산을 못 지킨다',
      utf8Bytes(unchecked.slice(0, TABLE_ROW_CAP).join('\n')) > CHANNEL_B_BUDGET_BYTES,
      `행 ${TABLE_ROW_CAP}개가 ${utf8Bytes(unchecked.slice(0, TABLE_ROW_CAP).join('\n'))} 바이트 — 행 상한만으로 예산 안이면 이 케이스는 바이트 예산을 재지 못한다`,
    );
    writeFidelity(dir, { ...CLEAN_REPORT, unchecked });
    const out = join(dir, 'out.md');
    expectExit('비교하지 않은 항목만으로 예산을 넘김', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    expectBodyMatch('  미스가 0 이어도 리포트가 채널 예산 안이다', out, (body) => {
      const size = utf8Bytes(body);
      return size <= CHANNEL_B_BUDGET_BYTES
        ? null
        : `리포트가 ${size} 바이트 — 채널 예산 ${CHANNEL_B_BUDGET_BYTES} 초과`;
    });
    // 감춘 수를 말하지 않으면 잘린 목록이 완전한 목록으로 읽힌다. 총수를 단언하는
    // 이유: 몇 행을 실었는지는 예산에 따라 변해도 **총 400** 은 변하지 않는다.
    expectBody('  감춘 행 수를 말한다', out, [truncationNotice(0, 400).slice(-12)]);
  }
}

// ── 두 채널이 같은 사실을 같은 문장으로 적는가 ───────────────────────────────
//
// 이 레포에서 네 라운드 연속으로 같은 모양의 결함이 나왔다: 한 채널을 하드닝하고
// 다른 채널을 빠뜨렸다. 매번 **그 인스턴스만** 고쳤기 때문에 다음 라운드에 다시
// 나왔다. 채널별 케이스는 각자 자기 채널이 옳은지만 보므로 이 갈라짐을 구조적으로
// 볼 수 없다 — 둘 다 초록인데 둘이 서로 다른 말을 하고 있을 수 있다.
//
// 그래서 여기서는 **한 리포트씩이 아니라 두 리포트를 나란히 놓고** 잰다. 갈라짐은
// 나란히 놓고 봐야만 보인다는 것이 그 네 번이 남긴 교훈이고, 이 절이 그 자리다.
console.log('두 채널 대조 — 같은 사실, 같은 문장');
{
  const chanA = (() => {
    const { dir, args } = plant({
      baseline: [cover([CARD, LABEL])],
      current: [cover([CARD, LABEL])],
    });
    const out = join(dir, 'report.md');
    const old = Date.now() / 1000 - 30 * 24 * 60 * 60;
    utimesSync(join(dir, 'raw', 'pages.txt'), old, old);
    expectExit('Channel A 리포트를 낸다', DIFF, [...args, `--out=${out}`], 0);
    return existsSync(out) ? readFileSync(out, 'utf8') : '';
  })();

  const chanB = (() => {
    const dir = scratch();
    writeFidelity(dir, CLEAN_REPORT);
    const out = join(dir, 'out.md');
    expectExit('Channel B 리포트를 낸다', INGEST, [`--dir=${dir}`, `--out=${out}`], 0);
    return existsSync(out) ? readFileSync(out, 'utf8') : '';
  })();

  // 두 리포트 모두 "언제의 것인가" 를 말하고, **같은 유보 문장**으로 닫는다. 한쪽만
  // 그 유보를 적으면 다른 쪽 리포트의 ✅ 가 더 넓은 주장으로 읽힌다 — 같은 사실을
  // 다르게 적으면 읽는 사람이 그 차이를 의미로 읽는다.
  const RESERVATION = '그 이후의 편집에 대해서는 아무 주장도 하지 않는다';
  ok(
    '두 채널 모두 나이에 대한 유보를 같은 문장으로 적는다',
    chanA.includes(RESERVATION) && chanB.includes(RESERVATION),
    `Channel A ${chanA.includes(RESERVATION) ? '있음' : '없음'} · ` +
      `Channel B ${chanB.includes(RESERVATION) ? '있음' : '없음'} — ` +
      '한쪽만 유보하면 다른 쪽의 ✅ 가 더 넓은 주장으로 읽힌다',
  );
  ok(
    '두 채널 모두 며칠 전인지 수로 말한다',
    /\(\d+일 전\)/.test(chanA) && /\(\d+일 전\)/.test(chanB),
    `Channel A ${/\(\d+일 전\)/.test(chanA)} · Channel B ${/\(\d+일 전\)/.test(chanB)} — ` +
      '시각만 적고 나이를 셈하지 않으면 읽는 사람이 오늘 날짜를 들고 빼야 한다',
  );

  // 잘림 문구는 **한 벌**이다. 두 채널이 같은 상황을 다르게 적으면 한쪽의 잘림이
  // 다른 쪽의 잘림보다 심각한 일인 줄 알게 된다. 채널별 케이스가 각각 공유 서식과
  // 대조하지만, 그 둘이 **서로** 같은지는 여기서만 보인다.
  {
    const rowsA = (() => {
      const extra: FixNode[] = Array.from({ length: ROWS_OVER_CAP }, (_, i) => ({
        id: `1:${100 + i}`,
        name: `Added${i}`,
        type: 'FRAME',
        x: i,
        y: 0,
        w: 8,
        h: 8,
      }));
      const { dir, args } = plant({
        baseline: [cover([CARD, LABEL])],
        current: [cover([CARD, LABEL, ...extra])],
      });
      const out = join(dir, 'report.md');
      expectExit('  Channel A 가 표를 자른다', DIFF, [...args, `--out=${out}`], 1);
      return existsSync(out) ? readFileSync(out, 'utf8') : '';
    })();
    const rowsB = (() => {
      const dir = scratch();
      const many: FidelityMiss[] = Array.from({ length: ROWS_OVER_CAP }, (_, i) => ({
        component: 'Button',
        field: `field${i}`,
        expected: '#000',
        actual: '#fff',
        looksLike: 'short',
      }));
      writeFidelity(dir, { ...CLEAN_REPORT, misses: many });
      const out = join(dir, 'out.md');
      expectExit('  Channel B 가 표를 자른다', INGEST, [`--dir=${dir}`, `--out=${out}`], 1);
      return existsSync(out) ? readFileSync(out, 'utf8') : '';
    })();
    const notice = truncationNotice(TABLE_ROW_CAP, ROWS_OVER_CAP);
    ok(
      '두 채널이 같은 잘림 문장을 쓴다',
      rowsA.includes(notice) && rowsB.includes(notice),
      `Channel A ${rowsA.includes(notice) ? '같음' : '다름'} · ` +
        `Channel B ${rowsB.includes(notice) ? '같음' : '다름'} — 기대한 문장: ${notice}`,
    );
    // 같은 문장을 쓴다는 것만으로는 **같은 자리에서** 자른다는 뜻이 아니다. 두
    // 채널의 행 상한이 갈라지면 같은 크기의 발견이 채널에 따라 다르게 잘린다.
    ok(
      '두 채널의 행 상한이 같다',
      rowsA.includes(`${TABLE_ROW_CAP} 행에서 잘렸다`) &&
        rowsB.includes(`${TABLE_ROW_CAP} 행에서 잘렸다`),
      `상한 ${TABLE_ROW_CAP} 에서 자른다고 말한 채널: ` +
        `A=${rowsA.includes(`${TABLE_ROW_CAP} 행에서 잘렸다`)} B=${rowsB.includes(`${TABLE_ROW_CAP} 행에서 잘렸다`)}`,
    );
  }
}

for (const dir of scratches) rmSync(dir, { recursive: true, force: true });

if (failures > 0) {
  console.log(`\n❌ reverse 계약 ${failures}건 불일치`);
  process.exit(1);
}
console.log('\n✅ reverse 계약 OK');
