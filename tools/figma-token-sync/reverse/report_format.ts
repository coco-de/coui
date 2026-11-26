// 두 채널이 **함께 쓰는** 리포트 서식 — 이스케이프 · 바이트 계산 · 예산 · 잘림 문구 ·
// 인용값 상한 · 캡처 시각 진술.
//
// 왜 한 파일인가: 이 레포의 reverse 채널은 같은 하드닝이 한쪽에만 적용되는 사고를
// 반복했다. 한 채널이 셀에서 줄바꿈을 지우고 다른 채널은 안 지웠고, 한 채널만
// 바이트 예산을 가졌고, 한 채널만 캡처 시각을 말했고, 한 채널만 긴 인용값을 잘랐다.
// 네 번 다 증상이 같았다 — 두 리포트가 같은 입력에 다르게 반응하는데, 어느 쪽이
// 맞는지는 나란히 놓고 봐야만 보인다. 그래서 **두 채널이 같아야 하는 것**은 각자
// 구현하지 않고 여기서 가져다 쓴다. 같은 생각을 두 곳에 적으면 그 둘은 결국 갈라진다.
//
// 갈라짐은 예측이 아니라 관측이다: 두 채널이 각자 적은 캡처 시각 문장은 실제로
// 한쪽이 "에 뜬 캡처", 다른 쪽이 "시점의 캔버스" 로 어긋나 있었다. 그래서 이
// 파일의 `ageNote` 는 문장을 복제하지 않고 **주어만 파라미터로** 받는다.
//
// 여기 담는 것: 두 채널이 같은 답을 내야 하는 서식과 셈.
// 여기 담지 않는 것: 각 채널이 무엇을 발견했는지에 대한 판단, 그리고 Node 에 닿는
// 것(파일 읽기 · 종료 코드). 후자를 들이면 이 모듈을 import 하는 비용이 달라진다 —
// 하네스는 서식 상수만 보려고 첫 줄에서 이것을 import 한다.

/**
 * 마크다운 표 셀 이스케이프.
 *
 * `|` 는 열을 쪼개고, 줄바꿈은 **행 자체를 쪼갠다**. 후자가 더 나쁘다 — 열이
 * 깨지면 그 셀이 이상해 보이지만, 행이 깨지면 남은 조각이 **다음 행으로 렌더되어**
 * 그 뒤 표 전체가 한 칸씩 밀린다. 읽는 사람은 밀린 표를 보고도 그것이 밀렸다는
 * 것을 알 수 없다. Figma 레이어 이름은 플러그인/API 로 줄바꿈을 넣을 수 있고,
 * get_metadata 는 그것을 그대로 실어 보낸다.
 *
 * **역슬래시를 파이프보다 먼저 이스케이프한다.** 이름 안의 `\` 를 그대로 두면
 * 그 뒤에 붙는 `\|` 와 합쳐져 파이프 앞에 역슬래시가 **짝수 개** 놓인다. 짝수 개의
 * 역슬래시는 자기들끼리 짝지어 소진되므로 그 파이프는 이스케이프되지 않은 것이고,
 * 이스케이프를 먼저 토큰화한 뒤 행을 쪼개는 렌더러(그것이 CommonMark 의 escape
 * 의미를 따르는 순서다)에서는 살아있는 셀 구분자가 된다 — `cell` 이 막으려는 바로
 * 그 열 분할이다. 파이프를 먼저 바꾸면 그때 넣은 역슬래시까지 다시 이스케이프되어
 * 이번엔 파이프가 리터럴로 보이지 않으므로, 순서가 규칙의 일부다.
 *
 * 행이 쪼개지지 않는 렌더러에서도 이 한 줄은 필요하다: 파이프 바로 앞의 역슬래시를
 * 무조건 벗겨내는 구현(cmark-gfm 의 unescape 단계가 그렇다)에서 `\|` 를 담은
 * 레이어 이름은 **역슬래시가 사라진 채** 렌더된다. 표시된 이름으로 Figma 를 찾는
 * 사람은 없는 것을 찾게 되는데, 그건 이 리포트가 값을 자를 때 말줄임표를 남기는
 * 이유와 같은 문제다.
 *
 * CR 단독과 CRLF 도 같이 지운다. `\n` 만 지우면 Windows 에서 만들어진 이름의
 * `\r` 이 남고, 마크다운 렌더러에 따라 그 CR 이 다시 줄바꿈으로 읽힌다 — 한 종류만
 * 막은 이스케이프는 막지 않은 것과 같은 실패를 남긴다. CRLF 는 공백 **하나**로
 * 접는다(두 문자를 각각 치환하면 공백이 둘이 된다).
 */
export function cell(s: string): string {
  return s
    .replace(/\\/g, '\\\\')
    .replace(/\|/g, '\\|')
    .replace(/\r\n?|\n/g, ' ');
}

/**
 * UTF-8 바이트 길이.
 *
 * 예산이 지키려는 상한이 바이트라 코드 단위로 세면 안 된다 — 한글과 `—` 는 한
 * 글자가 3 바이트라, 문자 수로 세면 실제 크기를 크게 낮잡는다. 이 리포트는 거의
 * 전부 한글이므로 그 오차가 곧 상한 초과가 된다.
 *
 * 짝을 이루지 않은 상위 대리(surrogate)만 실제보다 1 바이트 크게 센다(4 vs 3).
 * 예산에서 크게 세는 쪽은 안전한 방향이라 그대로 둔다 — 작게 세는 오차만이
 * 상한을 넘긴 문서를 통과시킨다.
 */
export function utf8Bytes(s: string): number {
  let n = 0;
  for (let i = 0; i < s.length; i += 1) {
    const c = s.charCodeAt(i);
    if (c < 0x80) n += 1;
    else if (c < 0x800) n += 2;
    else if (c >= 0xd800 && c <= 0xdbff) {
      // 대리 쌍은 두 코드 단위가 한 글자(4 바이트)다.
      n += 4;
      i += 1;
    } else n += 3;
  }
  return n;
}

/**
 * 줄 묶음이 문서에 실릴 때 드는 바이트 — **뒤따르는 개행 하나까지** 센다.
 *
 * 두 채널이 각자 이 셈을 하면 한쪽이 개행을 빠뜨려도 그 채널 안에서는 앞뒤가 맞는다.
 * 어긋남은 두 몫의 합이 이슈 본문 상한을 넘길 때 처음 드러나고, 그때는 이미 그
 * 주기의 발견이 통째로 사라진 뒤다. 그래서 "한 줄이 몇 바이트인가" 는 한 곳에서만
 * 답한다.
 *
 * 빈 묶음은 0 이다 — 싣지 않은 것에는 개행도 붙지 않는다.
 */
export function linesCost(lines: string[]): number {
  return lines.length === 0 ? 0 : utf8Bytes(lines.join('\n')) + 1;
}

/** GitHub 이 이슈 본문을 거부하는 크기. 이 위의 모든 예산이 이것에서 나온다. */
export const ISSUE_BODY_LIMIT_BYTES = 65536;

/**
 * 두 채널의 리포트를 **감싸는** 것들의 자리 — 절 제목, 부분 신호 경고, fidelity
 * 리포트가 없을 때 싣는 고정 문구, 마지막의 "이 이슈가 볼 수 없는 것" 문단.
 *
 * 실측 1,093 바이트(셋이 동시에 실리는 최악)에 여유를 크게 뒀다. 그 문장들은 이
 * 파일이 아니라 오케스트레이션 문서에 살아서, 거기서 한 문단이 늘어도 여기서는
 * 아무 일도 일어나지 않는다 — 예산이 실제로 어긋나는 것은 이슈를 만들려는 순간이고
 * 그때 실패하면 그 주기의 발견이 통째로 사라진다.
 */
export const ISSUE_WRAPPER_RESERVE_BYTES = 4096;

/**
 * Channel A(구조 드리프트) 리포트에 허용하는 바이트.
 *
 * **행 상한만으로는 문서가 묶이지 않는다.** 표마다 50 행이어도 표가 일곱 개면
 * 350 행이고, 행 하나에 딥링크 URL 과 레이어 이름이 들어가 100 바이트를 훌쩍
 * 넘는다. 실측: 6 페이지 · 1,200 노드 캡처가 59,518 바이트(이슈 본문 상한의
 * 90.8%)를, 표 일곱 개가 전부 찬 캡처가 67,341 바이트(상한 자체를 초과)를 냈다.
 * 두 경우 모두 행 잘림 문구는 성실히 찍혀 있었다 — 행으로만 세는 상한은 자기가
 * 지키기로 한 것을 지키지 못하면서 지켰다고 말한다.
 */
export const CHANNEL_A_BUDGET_BYTES = 32000;

/**
 * Channel B(시각 충실도) 리포트에 허용하는 바이트.
 *
 * 이 값은 **채널 전체**의 상한이고, 그 안의 몫들은 상수로 나눠 갖지 않는다 —
 * 잘리지 않는 산문(머리말 · 배너 · 꼬리말)을 그때그때 재고 남는 전부를 증거에
 * 준다(`evidenceBudget`). 몫을 상수로 적어두면 그 합이 채널 예산과 같다는 것을
 * 아무도 강제하지 않는다: 실측으로 머리말 · 꼬리말 · 절 잘림 문구가 어느 몫에도
 * 들어가지 않은 채 3,452 바이트를 썼고(고정 몫의 추정치는 2,000 이었다), 그 리포트가
 * 29,117 바이트로 이 상한을 1,117 바이트 넘겼다.
 */
export const CHANNEL_B_BUDGET_BYTES = 28000;

// 세 예산의 합이 상한을 넘지 않는지 **적재 시점에** 확인한다.
//
// 왜 여기서 던지는가: 이 조건은 입력이 아니라 위 상수 네 개로만 정해진다. 참이면
// 언제나 참이고 거짓이면 **모든 실행에서** 거짓이라, 조용히 지나갈 방법이 없다 —
// 크론이든 하네스든 첫 실행에서 즉시 터진다. 입력에 따라 갈리는 실패를 이
// 레포가 종료 코드 2 로 정성껏 라우팅하는 이유(자동화가 1 을 "디자이너가 바꿨다"
// 로 읽는다)가 여기에는 적용되지 않는다. 그 규율이 필요한 것은 **어떤 실행에서만**
// 나는 실패이고, 이건 그런 종류가 아니다.
//
// 이 검사가 의미를 가지려면 두 채널이 자기 몫을 **실제로 지켜야** 한다. 그래서
// 채널 예산을 나누는 일은 상수 뺄셈이 아니라 `evidenceBudget` 한 곳에서 일어난다 —
// 여기서 더하는 수를 한쪽이 지키지 않으면 이 확인은 지켜지지 않는 산술에 대한
// 확인이 된다.
//
// 세 값을 전부 메시지에 싣는 이유: 누군가 한 채널의 예산을 올려 이 합이 깨졌을 때,
// 어느 값을 얼마나 되돌려야 하는지가 메시지 안에 있어야 한다.
{
  const declared =
    CHANNEL_A_BUDGET_BYTES + CHANNEL_B_BUDGET_BYTES + ISSUE_WRAPPER_RESERVE_BYTES;
  if (declared > ISSUE_BODY_LIMIT_BYTES) {
    throw new Error(
      '리포트 예산의 합이 이슈 본문 상한을 넘는다 — ' +
        `CHANNEL_A_BUDGET_BYTES=${CHANNEL_A_BUDGET_BYTES} + ` +
        `CHANNEL_B_BUDGET_BYTES=${CHANNEL_B_BUDGET_BYTES} + ` +
        `ISSUE_WRAPPER_RESERVE_BYTES=${ISSUE_WRAPPER_RESERVE_BYTES} = ${declared} > ` +
        `ISSUE_BODY_LIMIT_BYTES=${ISSUE_BODY_LIMIT_BYTES}. ` +
        '이 합이 넘으면 두 채널이 각자 자기 예산을 지켜도 이슈 생성이 거부된다.',
    );
  }
}

/**
 * 한 표에 싣는 최대 행 수. **두 채널이 같은 값을 쓴다.**
 *
 * 넘치면 몇 행을 생략했는지 `truncationNotice` 로 명시한다 — 조용한 잘림은
 * "그게 전부였다" 로 읽힌다. 두 채널이 이 수를 각자 선언하면 한쪽만 바뀌고, 그러면
 * 같은 크기의 발견이 채널에 따라 다른 분량으로 실려 읽는 사람이 그 차이를 의미로
 * 읽는다.
 */
export const MAX_TABLE_ROWS = 50;

/**
 * 봉투·캡처에서 온 값을 **산문에 인용할 때** 쓰는 길이 상한.
 *
 * 표 안의 값은 절 예산이 묶지만, 배너와 꼬리말에 인용되는 값(페이지 이름 · 필터
 * 문자열 · 생성 시각 · buildHash · 파일명)은 어떤 예산에도 들어가지 않는다. 그
 * 값들은 전부 이 스크립트가 만든 것이 아니라 **캡처와 봉투가 실어 온 것**이라
 * 길이를 스스로 정하지 못한다 — Figma 페이지 이름에는 사실상 길이 제한이 없어서,
 * 이름 하나가 33KB 면 표를 한 줄도 싣지 않은 "변화 없음" 리포트가 103KB 로 나가
 * 이슈 생성이 거부된다.
 */
export const MAX_QUOTED_CHARS = 120;

/**
 * 인용값을 상한에서 자른다. 잘랐다는 것을 말줄임표로 **보이게** 남긴다 — 조용히
 * 자르면 잘린 값이 원래 값으로 읽히고, 그 값으로 Figma 를 찾는 사람은 없는 것을
 * 찾게 된다.
 *
 * 문자로 세지만 그 결과는 바이트로도 묶여 있다: `slice` 가 돌려주는 코드 단위는
 * 최대 `MAX_QUOTED_CHARS` 개이고 한 코드 단위는 UTF-8 에서 3 바이트를 넘지 못한다
 * (대리 쌍은 두 단위가 4 바이트라 단위당 2 바이트다). `cell` 의 이스케이프는 1 바이트
 * 문자만 2 바이트로 늘리므로 이 한계를 넘기지 않는다. 그래서 한 인용값은 한글이든
 * 이모지든 `MAX_QUOTED_CHARS × 3` 바이트에 말줄임표를 더한 크기 안에 있고, 인용
 * 슬롯이 유한한 이상 산문 전체도 유한하다.
 *
 * `unknown` 을 받는 이유: 봉투에서 온 값은 검증이 객체라는 것만 보장하므로 필드가
 * 문자열이라는 보장이 없다. 확인하지 않은 것을 타입으로 주장하면 렌더가 그 주장을
 * 믿고 방어를 뺀다.
 */
export function brief(s: unknown): string {
  const text = String(s ?? '');
  return cell(
    text.length > MAX_QUOTED_CHARS ? `${text.slice(0, MAX_QUOTED_CHARS)}…` : text,
  );
}

/**
 * 표가 상한에서 잘렸다는 문장. **두 채널이 같은 문장을 쓴다.**
 *
 * 같은 사실을 다르게 적으면 읽는 사람이 그 차이를 의미로 읽는다 — 한쪽 리포트의
 * 잘림이 다른 쪽의 잘림보다 심각한 일인 줄 알게 된다.
 */
export function truncationNotice(shown: number, total: number): string {
  return `_표가 ${shown} 행에서 잘렸다 — ${total - shown} 행이 더 있다 (총 ${total})._`;
}

/**
 * 이 표가 낼 수 있는 잘림 문구의 **상한** 바이트.
 *
 * 문구는 예산이 바닥난 **뒤에** 써야 하므로 그 자리를 미리 떼지 않으면 예산 밖으로
 * 새어 나간다. 자리를 얼마나 뗄지를 상수로 적으면 문구가 길어질 때 조용히 모자라게
 * 되므로, 문구 자신에게 최악을 물어본다 — 세 수를 전부 실제보다 크게 넣어 만든다.
 */
export function truncationNoticeReserve(total: number): number {
  return utf8Bytes(truncationNotice(total, total * 2));
}

/** 이 시각이 무엇의 시각인지, 그리고 오래된 것이 그 자체로 신호인지. */
export interface AgeSubject {
  /**
   * 문장에서 그대로 불리는 이름. `시각` 으로 끝나야 한다 — 뒤에 붙는 조사가 그
   * 끝음절에 달려 있다.
   */
  label: string;
  /**
   * 이만큼 오래된 것이 그 자체로 신호일 때, 그 임계(일)와 덧붙일 문장.
   * 오래된 것이 정상인 채널은 `null`.
   */
  stale: { afterDays: number; warning: string } | null;
}

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * 이 리포트가 **언제의 캔버스**를 말하는지.
 *
 * 두 채널 모두 같은 실패를 갖는다: 새 입력이 들어오지 않아도 리포트는 나온다.
 * Channel A 는 캡처 단계가 조용히 실패하면 지난 캡처를 다시 비교하고, Channel B 는
 * 드롭 디렉터리에 새 파일이 없으면 같은 파일을 다시 렌더한다. 어느 쪽이든 결과는
 * "변화 없음" 이고, 시각을 말하지 않으면 반년 전의 ✅ 가 이번 주기의 답으로 읽힌다.
 *
 * 문장이 **하나**인 이유: 두 채널이 각자 적었을 때 실제로 갈라졌다(한쪽은 "에 뜬
 * 캡처", 다른 쪽은 "시점의 캔버스"). 같은 사실을 다르게 적으면 읽는 사람이 그
 * 차이를 의미로 읽으므로, 여기서는 주어만 파라미터로 받고 문장은 복제하지 않는다.
 */
export function ageNote(at: string | null, subject: AgeSubject): string {
  const quoted = at === null ? '(없음)' : `\`${brief(at)}\``;
  const parsed = at === null ? NaN : Date.parse(at);

  if (!Number.isFinite(parsed)) {
    return (
      `${subject.label}을 읽을 수 없다 (${quoted}) — ` +
      '언제의 캔버스에 대한 진술인지 알 수 없다.'
    );
  }

  const days = Math.floor((Date.now() - parsed) / MS_PER_DAY);
  if (days < 0) {
    return (
      `${subject.label} ${quoted} 은 미래다(시계가 어긋났다) — ` +
      '언제의 캔버스에 대한 진술인지 믿을 수 없다.'
    );
  }

  const base =
    `이 리포트는 ${quoted} (${days}일 전) 시점의 캔버스에 대한 진술이다 — ` +
    '그 이후의 편집에 대해서는 아무 주장도 하지 않는다.';
  return subject.stale !== null && days >= subject.stale.afterDays
    ? `${base} ${subject.stale.warning}`
    : base;
}

/** 남은 바이트 예산. 바닥나면 그 뒤로는 아무것도 싣지 않는다. */
export interface Budget {
  left: number;
}

export function budgetOf(bytes: number): Budget {
  return { left: bytes };
}

/**
 * 예산 안에서만 줄을 싣는다. 실었으면 `true`, 예산이 모자라 아무것도 싣지 않았으면
 * `false` — 잘렸다는 **사실을 문장으로 적는 일은 호출자 몫**이고, 그 문장은
 * 예산 밖에서 싣는다(자리는 `evidenceBudget` 이 미리 뗀다). 잘림을 알리는 문장이
 * 잘림 때문에 사라지면 조용한 잘림이 되는데, 그건 상한을 두는 이유 자체를 뒤집는다.
 */
export function spend(budget: Budget, out: string[], chunk: string[]): boolean {
  const cost = linesCost(chunk);
  if (cost > budget.left) return false;
  budget.left -= cost;
  for (const line of chunk) out.push(line);
  return true;
}

/**
 * 증거에 쓸 수 있는 바이트 — 채널 예산에서 **잘리지 않는 것들**을 뺀 나머지.
 *
 * 두 채널이 같은 규율을 따른다: 리포트의 범위를 좁히는 문장(`head`)과 다음 행동을
 * 말하는 문장(`tail`)은 잘리지 않고, 잘린 것은 증거뿐이며, **몇 개를 못 실었는지는
 * 예산 밖에서** 말한다. 그 셋을 각자 계산하면 한쪽이 무언가를 빼먹고, 빼먹은 쪽은
 * 자기 예산 안에 있다고 믿으면서 상대의 몫을 먹는다 — 실제로 그렇게 됐다.
 *
 * `worstCaseNotice` 는 **최악의 잘림 문구**다. 아직 몇 개를 못 실을지 모르는 시점에
 * 자리를 잡아야 하므로 최악을 기준으로 뗀다. 실제 문구는 그보다 짧거나 아예 안
 * 쓰이고, 남은 자리는 문서를 줄일 뿐이다. 빈 문자열이면 아무 자리도 떼지 않는다 —
 * 증거가 없어 잘릴 것이 없는 리포트를 위해서다.
 *
 * 결과가 음수일 수 있고 그대로 돌려준다. 클램프하면 예산이 없다는 사실이 "예산이
 * 0" 으로 접혀 조용해지는데, 음수를 그대로 두면 `spend` 가 전부 거절하고 잘림
 * 문구가 발화해 그 상태가 본문에 남는다.
 */
export function evidenceBudget(
  channelBytes: number,
  head: string[],
  tail: string[],
  worstCaseNotice: string,
): number {
  const notice = worstCaseNotice === '' ? 0 : linesCost([worstCaseNotice, '']);
  return channelBytes - linesCost(head) - linesCost(tail) - notice;
}

/** 절과 절 사이. 비용 계산이 이 길이를 알아야 예산이 정확해진다. */
const SECTION_GAP = '\n\n';
const SECTION_GAP_BYTES = 2;

/**
 * 절들을 바이트 예산 안에서 조립하고, **몇 개를 못 실었는지** 함께 돌려준다.
 *
 * 못 실은 수를 본문이 아니라 **반환값으로** 내보내는 것이 핵심이다. 잘렸다는
 * 사실을 예산 안에서 쓰려고 하면 예산이 바닥났을 때 그 문장부터 사라진다 —
 * 조용한 잘림이 되고, 그건 상한을 두는 이유 자체를 뒤집는다. 호출자는 이 수를
 * 받아 **예산 밖에서** 문장으로 적는다.
 *
 * 들어가지 않는 절을 만나도 멈추지 않고 계속 시도한다. 큰 절 하나 때문에 그
 * 뒤의 작은 절들까지 버리면, 읽는 사람이 보는 양이 발견의 **순서**에 따라 달라진다.
 *
 * `spend` 와 낱알이 다르다 — 이쪽은 절을 통째로 넣거나 뺀다. 낱알이 갈리는 이유는
 * 증거의 모양이 다르기 때문이다: 여기 오는 절은 변화 종류마다 하나씩인 유한한
 * 목록이라 통째로 빠져도 그 사실이 요약의 건수로 남지만, `spend` 를 쓰는 쪽은
 * 컴포넌트마다 하나씩 생기는 무한한 목록이라 통째로 빼면 잃는 양에 상한이 없다.
 */
export function fitToBudget(
  sections: string[],
  budgetBytes: number,
): { text: string; omittedSections: number } {
  const kept: string[] = [];
  let left = budgetBytes;
  let omittedSections = 0;

  for (const section of sections) {
    const cost = utf8Bytes(section) + (kept.length > 0 ? SECTION_GAP_BYTES : 0);
    if (cost > left) {
      omittedSections += 1;
      continue;
    }
    left -= cost;
    kept.push(section);
  }

  return { text: kept.join(SECTION_GAP), omittedSections };
}
