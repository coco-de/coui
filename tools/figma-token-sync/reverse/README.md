# reverse — Figma → 코드 방향의 드리프트 감지

이 디렉터리는 **반대 방향**을 본다. 상위 플러그인(`../src/**`)은 코드의 토큰을
Figma 로 내보내지만, 여기서는 **디자이너가 Figma 에서 무엇을 바꿨는지**를 읽어
레포에 보고한다.

`../src/**` 를 스캔하는 기존 Figma 가드들의 사정거리 **밖**에 일부러 두었다 —
플러그인 샌드박스에서 도는 코드와 순수 Node 스크립트는 실행 환경이 다르다.

> ⚠️ **`config.json` 의 `fileKeyStatus` 가 `"confirmed"` 일 때만 걷는다.** 그 값이
> 아니면 `diff_structure.ts` 가 리포트를 만들기 전에 종료 코드 2 로 멈춘다 —
> 잘못된 파일을 기준으로 세운 베이스라인은 이후의 모든 리포트를 조용히 무의미하게
> 만들고, 그 리포트는 형식상 멀쩡해서 틀렸다는 것을 읽어봐야 알 수 있다. 파일이
> 정본 라이브러리인지는 코드가 판정할 수 없고 사람만 판정할 수 있으므로, 그 판정이
> 파일에 기록되기 전까지 막는 자리를 지시문이 아니라 스크립트 안에 둔다.

---

## 왜 채널이 둘인가 — MCP 로 실제로 무엇이 읽히는지 재본 결과

설계가 이 모양인 이유는 취향이 아니라 **측정 결과**다. 파일
`zmwTIM2nCDuBjt5jegLkHT` 를 대상으로 직접 확인했다:

| MCP 도구 | 헤드리스(무인) | 비고 |
|---|---|---|
| `get_metadata` (nodeId 없이) | **동작함** | 페이지 목록을 `- <id>: <name>` 줄로 반환 |
| `get_metadata` (nodeId 지정) | **동작함** | 속성만 있는 XML + 끝에 XML 이 아닌 산문 한 문장 |
| `get_variable_defs` | **실패** | "You currently have nothing selected" — 데스크톱 앱의 살아있는 선택 필요 |
| `get_design_context` | **실패** | 같은 이유 |

또한 이 조직의 Figma 요금제는 `org` 티어라 **Variables REST API 를 쓸 수 없다.**
우회로가 없으므로 그것을 전제한 설계는 하지 않는다.

**귀결**: 무인 크론은 **구조와 기하만** 볼 수 있다(id · name · type ·
x/y/width/height). 색 · 토큰 바인딩 · 타이포 · radius · shadow 는 **원리적으로**
못 본다. 그래서 그 축을 사람이 트리거하는 두 번째 채널로 뺐다.

MCP 예산은 하루 200 호출 · 분당 20 이다. Channel A 는 `페이지 수 + 1` 회만
호출하므로 이 한도에 한참 못 미친다.

---

## 자동 실행 — `figma-absorb` Action

`reverse/incoming/` 에 파일이 커밋돼 main 에 push 되면 `.github/workflows/figma-absorb.yml`
이 **그 커밋을 체크아웃해** 아래 두 채널을 돌리고 이슈 하나를 만든다(`/cc-coui-sync:absorb`
의 결정적 부분 — 절차 정본은 그 스킬). 스케줄 크론이 낡은 체크아웃에서 "리포트 없음" 을
잘못 보고했던 일이 있어 push 트리거로 바꿨다. 베이스라인 승격(`--update-baseline`)은
여기서 하지 않는다 — 사람의 결정이다. 이슈의 `## 디자이너 확인` 표가 비어 있으면
`needs-designer-why` 라벨이 붙고(`issue-designer-why.yml`), 채우면 떨어진다.

## Channel A — 크론 (무인)

```
MCP get_metadata → 원문을 디스크에 저장 → 결정적 differ → 마크다운 → GitHub 이슈
```

**보는 것**: 노드의 추가 · 삭제 · 이름 변경 · 이동 · 크기 변경. 두 캡처가 모두
schema 2(아래)면 **컴포넌트 프로퍼티 정의**(추가 · 삭제 · 타입 · 기본값 · 옵션)와
**인스턴스의 원본 참조**까지.
**못 보는 것**: 색 · 토큰 바인딩 · 타이포 · radius · shadow.

> Channel A 의 "변화 없음"을 **시각적 동일성으로 읽지 마라.** 그것은 구조와
> 기하에 대한 진술일 뿐이다. 리포트 본문에도 같은 경고가 박혀 있다.

### 캡처는 플러그인이 만든다 — MCP 는 이 파일을 다 걷지 못한다

정본 입력은 플러그인의 **"구조 → .json"** 이다. 디자이너가 Figma 데스크톱에서
누르면 전 페이지(193)의 노드(46,000여 개)를 몇 초에 읽어 `structure-<UTC>.json`
하나로 내려주고, 그 파일이 이 스크립트가 읽는 베이스라인과 같은 모양이다.

**왜 MCP 가 아닌가**: `get_metadata` 의 페이지 목록 호출은 이 파일에서 Cover 한
장만 돌려주고(알려진 버그), 페이지별 호출로 걷으면 하루 예산 200회 · 한 실행
상한 60회를 넘기며, 그 XML 전부가 에이전트의 컨텍스트를 지나야 한다. 무인
크론이 매 주기 감당할 양이 아니다. MCP 경로는 남겨 두되 작은 파일이나 부분
확인용이다.

```bash
# 디자이너가 내려받은 파일을 reverse/incoming/ 에 커밋한 뒤
cd tools/figma-token-sync
npm run reverse:diff -- --snapshot=reverse/incoming/structure-<stamp>.json --out=/tmp/report.md
```

두 캡처 경로는 `capturedBy` 가 다르고 타입 어휘·반올림이 같다는 보장이 없어,
베이스라인과 다른 경로의 캡처를 비교하려 들면 **종료 코드 2 로 멈춘다.** 전환은
`--update-baseline` 으로 한 번 한다(그 실행의 diff 는 경로 전환 소음이라 판정에
쓰지 않는다). 베이스라인은 노드 한 줄에 하나로 쓰인다 — 46,000 노드를
들여쓰기 JSON 으로 쓰면 40만 줄이라 git diff 가 읽히지 않는다.

### 스냅샷 형식 — schema 1 과 2

`schema` 는 그 캡처가 **어떤 필드를 싣고 있는가**에 대한 주장이다. 쓰는 쪽(플러그인)과
읽는 쪽(differ)이 `snapshot_format.ts` 의 같은 상수를 본다.

| schema | 누가 쓰나 | 노드 한 줄 |
|---|---|---|
| 1 | MCP 캡처 · 이전 플러그인 | `id · name · type · x · y · w · h · depth` |
| 2 | 플러그인 "구조 → .json" | 위 + 소유 노드의 `props` + 인스턴스의 `main` |

- **`props`** — 프로퍼티를 소유하는 노드(컴포넌트 세트, 그리고 세트 밖 단독 컴포넌트)에만
  있다. Figma `componentPropertyDefinitions` 를 key 로 정렬해 `{key, type, default, options?}`
  로 옮긴 것이다(`options` 는 VARIANT 의 `variantOptions`, INSTANCE_SWAP 의 `preferredValues`).
  세트 안의 변형은 정의를 갖지 않으므로 싣지 않는다 — 소유 판정 규칙은
  `ownsComponentProps` 하나를 쓰는 쪽과 읽는 쪽이 같이 본다.
- **`main`** — 인스턴스에만 있다. 원본 컴포넌트의 노드 id. 파일 안에 있으면 리포트가 이름까지 적는다.
- **`null` 은 "읽지 못함"** 이다(변형 충돌이 있는 세트, 해석되지 않는 원본). 키를 빼거나 빈
  목록으로 접지 않는다 — 접으면 읽지 못한 세트가 "프로퍼티를 전부 지웠다" 로 보고된다. differ 는
  그 노드를 비교하지 않고 "비교 불가" 로 센다.
- **있는지 여부 자체가 계약이다** — schema 2 의 소유 노드에 `props` 가 없거나, 인스턴스에
  `main` 이 없거나, schema 1 이 그 키를 싣고 있으면 종료 코드 2 로 멈춘다.

**프로퍼티는 표시 이름으로 비교한다.** BOOLEAN · TEXT · INSTANCE_SWAP 의 키는
`Show description#12:3` 처럼 `#<id>` 접미사를 달고 오고, 그 접미사는 세트를 다시 그릴 때마다
바뀐다. 원문 키로 비교하면 매 Generate 가 모든 프로퍼티를 "삭제 + 추가" 로 만든다.

**전환 — 한쪽이라도 schema 1 이면 이 축은 세지 않고, 세지 않았다고 말한다.** 헤드라인이
"구조·기하" 로 좁아지고, 본문 앞에 경고가 붙고, 요약의 프로퍼티 칸이 `비교 안 함` 이 된다.
기존 축(구조·기하)은 그대로 비교하므로 absorb 가 전환 기간에 멈추지 않는다. 베이스라인을
schema 2 로 올리는 것은 한 번이다:

```bash
# main 체크아웃에서 플러그인을 빌드하고 Figma 에서 "구조 → .json" 을 다시 뜬 뒤
npm run reverse:diff -- --snapshot=reverse/incoming/structure-<stamp>.json --update-baseline
```

### 운영 절차 (MCP 경로)

1. MCP 출력을 원문 그대로 작업 디렉터리에 저장한다:
   - `get_metadata`(nodeId 없이) → `<raw-dir>/pages.txt`
   - 각 페이지마다 `get_metadata`(nodeId=페이지 id) → `<raw-dir>/page-<id>.xml`
     - 파일명의 `<id>` 는 영숫자가 아닌 문자를 `-` 로 바꾼 형태다
       (`12:47649` → `page-12-47649.xml`).
2. differ 를 돌린다:

```bash
cd tools/figma-token-sync
npm run reverse:diff -- --raw-dir=reverse/.work/latest --out=/tmp/report.md
```

3. 종료 코드 `1` 이면 `/tmp/report.md` 를 그대로 GitHub 이슈 본문에 붙인다.
4. 변화를 **수용**하기로 했으면 베이스라인을 옮긴다:

```bash
npm run reverse:diff -- --raw-dir=reverse/.work/latest --update-baseline
```

### 옵션

| 플래그 | 뜻 |
|---|---|
| `--snapshot=<file>` | 플러그인 "구조 → .json" 이 내려준 스냅샷 (정본 입력). `--raw-dir` 과 같이 줄 수 없다 |
| `--raw-dir=<dir>` | MCP 원문이 있는 디렉터리 (기본 `reverse/.work/latest`) |
| `--baseline=<path>` | 베이스라인 JSON (기본 `reverse/baseline.structure.json`) |
| `--config=<path>` | 설정 JSON (기본 `reverse/config.json`) |
| `--out=<md>` | 마크다운을 파일로. 없으면 stdout |
| `--json-out=<path>` | 스냅샷 + diff 를 JSON 으로 |
| `--update-baseline` | 이번 스냅샷으로 베이스라인을 덮어쓴다 |

### 왜 id 로 매칭하나

Figma node id 는 편집을 넘어 안정적이고 이름은 그렇지 않다. 이름으로 매칭하면
**이름 변경이 추가+삭제 한 쌍**으로 보여 실제 삭제와 구별되지 않는다. id 로
매칭하기 때문에 이름 변경이 이름 변경으로 보고된다.

### 첫 실행

베이스라인이 비어 있으면(`nodeCount: 0`) 이번 실행이 베이스라인을 세우고
**종료 코드 0** 으로 끝난다. 전 노드를 "추가됨"으로 보고하지 않는다 — 첫
리포트가 수천 행짜리 소음이 되면 그 다음 리포트까지 불신하게 된다.

### 모집단 하한 (조용한 통과 방지)

이번 캡처의 노드 수가 `베이스라인 × populationFloorRatio` 아래로 떨어지면
리포트를 만들지 않고 **종료 코드 2** 로 거부한다.

`scripts/guards/structure/check_figma_export_fresh.sh` 의 `FLOOR_BYTES` 와 같은
방어다. 그 가드의 논리는 "추출이 붕괴해 결과가 비면 diff 가 작아 보여 *신선함*
으로 조용히 통과한다"였다. 여기서는 더 나쁘게 나타난다 — 붕괴한 캡처는
살아있는 노드 **전부를 "삭제됨"으로 보고**해서 진짜 대량 삭제와 글자 그대로
구별되지 않는다. 그래서 리포트를 만들기 전에 거부한다.

같은 이유로 **페이지 XML 파일이 하나라도 빠지면** 종료 코드 2 다. 한 페이지의
캡처 누락은 그 페이지 전체의 삭제와 출력이 같다.

---

## Channel B — 디자이너 트리거

플러그인의 `verifyFidelity()` 는 이미 필드 단위로 expected/actual/looksLike 를
만든다. 다만 그 결과가 로그로만 나가서 레포에 남지 않는다. 이 채널은 그 출력을
파일로 받아 검증하고 사람이 읽을 형태로 바꾼다.

**보는 것**: 색 · 토큰 바인딩 · 타이포 · radius · shadow — 즉 Channel A 가
원리적으로 못 보는 축 전부.

### 운영 절차

1. 디자이너가 **Figma 데스크톱 앱**에서 플러그인의 fidelity 를 실행하고 JSON 을
   내려받는다.
2. 그 파일이 `reverse/incoming/fidelity-<타임스탬프>.json` 으로 커밋된다. 대개
   디자이너에게는 checkout 이 없어 파일만 넘기므로, **레포에 넣는 것은 받은
   엔지니어의 일**이다 — 플러그인 패널이 디자이너에게 그렇게 안내한다. 커밋되지
   않은 파일은 크론이 볼 수 없다.
3. 렌더한다:

```bash
cd tools/figma-token-sync
npm run reverse:ingest -- --out=/tmp/fidelity.md
```

파일이 여러 개면 **사전순 마지막 하나만** 읽고, 그 사실을 stderr 로 알린다.

### 이 채널이 거부하는 것

- **리포트가 없다** → 종료 코드 2. 침묵은 동의가 아니다 — 리포트 부재는 "결함
  없음"이 아니라 "아무도 검사하지 않았다"이다.
- **`checksRun` 이 0** → 종료 코드 2. 검사 0 건과 결함 0 건은 출력이 같다.
  이걸 통과로 렌더하면 아무 근거 없는 초록이 된다.
- **봉투가 다르다**(`kind` / `schema` 불일치, 깨진 JSON) → 종료 코드 2.

리포트는 `unchecked` 항목을 **"비교하지 않음"** 이라고 분명히 적는다. 검사되지
않은 것은 이상 없음이 아니다 — 이 구분을 흐리면 부분 검사가 전수 검사처럼
읽힌다. 부분 스윕(`entryFilter` 가 있는 실행)도 리포트 상단에 표시된다.

---

## Channel C — 디자이너 대조

플러그인의 `⇄` 대조(`../src/designer-parity.ts`)는 세트마다 **디자이너 프레임**
(`<이름>(디자이너` 로 시작하는 손 사본 또는 플러그인이 덮어쓰기 직전에 뜬
스냅샷)과 생성본의 보이는 잎 — 채움이나 보더가 있는 박스 · 글자 · 아이콘 ·
벡터 · 오토레이아웃 인셋 — 을 서술자 문자열로 뽑아 변형별 대칭차를 낸다. 그
결과는 로그에 상한 14 줄로 접혀 나가고 그 뒤엔 아무 데도 남지 않는다. 이 채널은
그 대조를 **상한 없이 통째로** 담은 봉투(`designer-parity-<stamp>.json`)를 받아,
사람이 다음 한 걸음을 고를 수 있는 형태로 바꾼다.

**보는 것**: 대조에서 갈린 값이 **어느 축**인지(text-size · letter-spacing ·
text-color · fill · stroke-color · stroke-width · radius · size · node-missing 등),
그 차이가 여러 변형에 반복되면 한 행으로 접은 것, 그리고 축마다 **다음 한 걸음**.

### 다음 한 걸음 — 셋 중 하나

| 분류 | 뜻 | 왜 갈라 놓나 |
|---|---|---|
| `Core 값 수정` | 디자이너 값이 토큰 사다리 위에 있다 | `CoreXxxStyle` default 한 줄을 그 눈금으로 옮기면 끝난다 — 사람이 정할 것이 없다 |
| `결정 필요 — 사다리 밖` | 디자이너 값이 어떤 토큰과도 맞지 않거나(획 1.5 · 모서리 13 · 로우 hex 색), 값이 아니라 노드 유무의 차이다 | 사다리를 늘릴지 값을 되돌릴지는 코드가 정할 수 없다 |
| `사본 의심` | raw-paste 사본의 자간 · 크기 | 사본이 그 축을 잃은 것이지 캔버스의 결정이 아니다 |

사다리는 이 디렉터리에 적지 않고 `packages/coui_core/lib/src` 의 원시토큰
상수(`font_size` · `letter_spacing` · `line_height` · `stroke_width` ·
`radius_scale` · `spacing` · `size`)에서 읽는다. 값을 복제하면 Core 가 사다리를
늘렸을 때 여기가 낡은 사다리로 "사다리 밖" 을 잘못 판정하고, 그 오판은 리포트
모양이 멀쩡해서 읽어봐야 안다. 사다리 파일을 읽지 못하거나 상수가 0 이면
판정을 건너뛰지 않고 **종료 코드 2** 로 멈춘다 — 사다리 없는 "결정 필요" 는
판정이 아니라 파일 부재의 다른 이름이다.

### 사본 신선도 — raw-paste 는 자간 · 크기 축을 믿지 않는다

캔버스의 디자이너 프레임에는 세 종류가 있다: 플러그인이 덮어쓰기 직전에 뜬
스냅샷 프레임, 디자이너가 같은 파일에서 손으로 둔 사본, 그리고 **다른 파일에서
붙여 넣은 로우 사본**. 마지막 것은 텍스트에 변수 바인딩이 하나도 없어(텍스트
스타일 · fontSize · letterSpacing 변수 전부) 자간이 0 으로 읽힌다 — 디자이너가
"자간은 들어가는 게 맞다" 고 확인했으므로, 그런 사본의 자간 · 크기 차이는
캔버스의 결정이 아니라 사본의 결함이다.

봉투의 `freshness.hint` 가 그것을 말한다(`raw-paste` / `bound` / `n/a`). 리포트는
raw-paste 세트의 그 두 축을 `사본 의심` 으로 분류하고, **표보다 먼저** 경고를
둔다 — 표를 먼저 읽고 자간 행을 캔버스의 결정으로 받아들인 뒤에 경고를 만나면
이미 늦다. 나머지 축(획 · 모서리 · 채움 · 보더)은 로우 사본에서도 그대로
판정한다 — 그 값들은 바인딩 없이도 로우 값이 보존된다.

### 운영 절차

1. 디자이너가 **Figma 데스크톱 앱**에서 Generate 를 돌리면 플러그인이 대조 봉투를
   내려준다.
2. 그 파일이 `reverse/incoming/designer-parity-<타임스탬프>.json` 으로 커밋된다.
3. 렌더한다:

```bash
cd tools/figma-token-sync
npm run reverse:designer -- --out=/tmp/designer.md
# 파일을 지정하려면 --file=reverse/incoming/designer-parity-<stamp>.json
```

파일을 생략하면 `incoming/` 의 **사전순 마지막 하나만** 읽고, 그 사실을 stderr
와 리포트 본문 양쪽에 적는다.

### 이 채널이 거부하는 것

- **대조 파일이 없다** → 종료 코드 2. 대조하지 않은 주기를 "차이 없음" 으로 읽지
  않는다.
- **봉투가 다르다**(`kind` / `schema` 불일치, 깨진 JSON, `sets` 가 배열이 아님,
  `freshness.hint` 가 셋 중 하나가 아님, `lines` 원소가 서술자를 실을 모양이
  아님) → 종료 코드 2. 특히 `freshness` 를 느슨하게 받으면 raw-paste 사본의
  자간 차이가 캔버스의 결정으로 렌더된다.
- **사다리를 읽지 못한다** → 종료 코드 2 (위 참조).

기준 프레임이 없는 세트(`designerFrame: null`)는 거부하지 않고 **"정보 없음"**
으로 적는다 — 그 세트는 대조하지 않은 것이지 같은 것이 아니다.

### 서술자 문법은 플러그인 소스에 고정돼 있다

축 파싱은 `collectLeaves` 가 내는 다섯 서술자 형식(`text` · `icon` · `vec` ·
`layout` · `box`)을 뒤집은 것이다. 그 템플릿이 바뀌면 파서는 아무 소리 없이
"모르는 잎" 으로 떨어져 모든 차이가 `node-missing` 으로 뭉개진다 — 종료 코드는
그대로 1 이라 자동화는 아무것도 못 본다. 그래서 `selftest:diff-designer` 가 그
템플릿 조각을 **소스에서 직접** 확인해, 형식이 바뀌면 그 하네스가 먼저 깨진다.

### 예산

이 채널은 absorb 이슈(Channel A + B)에 실리지 않고 자기 이슈를 갖는다 — 그래서
`report_format.ts` 의 세 예산 합산 검사에 들어가지 않고, 상한은 Channel B 와
같은 값을 쓴다(성격이 같다: 컴포넌트마다 표가 하나씩 생기는 무한한 목록). 잘린
행 수와 이름조차 싣지 못한 세트 수는 예산 **밖에서** 문장으로 적는다.

---

## 종료 코드 계약 (세 스크립트 공통)

| 코드 | 뜻 |
|---|---|
| `0` | 조치할 차이 없음 |
| `1` | 차이 있음 — 사람이 봐야 한다 |
| `2` | **인프라 실패** — 입력 누락/파손, 파싱 실패, 모집단 하한 위반, 사다리 부재 |

`1` 과 `2` 를 절대 섞지 않는다. 자동화는 `2` 를 "파이프라인이 깨졌다", `1` 을
"디자이너가 무언가 바꿨다"로 다르게 처리한다. 이 구분이 무너지면 깨진 캡처가
디자인 변경으로 보고된다.

---

## 파일

| 파일 | 역할 |
|---|---|
| `config.json` | fileKey · 기하 임계값 · 모집단 하한 비율 |
| `baseline.structure.json` | 커밋된 구조 베이스라인 |
| `report_format.ts` | 세 채널이 **함께 쓰는** 서식과 셈 (아래) |
| `diff_structure.ts` | Channel A differ |
| `ingest_fidelity.ts` | Channel B 검증/렌더러 |
| `diff_designer.ts` | Channel C 디자이너 대조 렌더러 — 축별 접기 + 다음 한 걸음 분류 |
| `incoming/` | 디자이너가 fidelity · designer-parity JSON 을 놓는 자리 |
| `.work/` | MCP 원문 스크래치 (gitignored) |
| `tsconfig.json` | 이 디렉터리 전용 타입 설정 (아래) |

### 왜 서식이 따로 한 파일인가

두 채널이 **같은 답을 내야 하는 것**은 각자 구현하지 않고 `report_format.ts` 에서
가져다 쓴다 — 표 셀 이스케이프 · UTF-8 바이트 셈 · 채널 예산과 그 나눗셈 · 행 상한 ·
잘림 문구 · 인용값 상한 · 캡처 시각 진술.

이 파일이 생긴 이유는 설계가 아니라 **관측**이다. 같은 하드닝이 한쪽 채널에만
적용되는 사고가 네 번 반복됐다: 한 채널만 셀에서 줄바꿈을 지웠고, 한 채널만 바이트
예산을 가졌고, 한 채널만 캡처 시각을 말했고, 한 채널만 긴 인용값을 잘랐다. 네 번 다
증상이 같다 — 두 리포트가 같은 입력에 다르게 반응하는데, 어느 쪽이 맞는지는 나란히
놓고 봐야만 보인다.

그리고 갈라짐은 문장에서도 일어난다: 두 채널이 각자 적은 캡처 시각 진술은 실제로
한쪽이 "에 뜬 캡처", 다른 쪽이 "시점의 캔버스" 로 어긋나 있었다. 그래서 여기 사는
`ageNote` 는 문장을 복제하지 않고 **주어만 파라미터로** 받는다.

Node 에 닿는 것(파일 읽기 · 종료 코드)은 여기 두지 않는다. 하네스가 서식 상수만
보려고 첫 줄에서 이것을 import 하므로, Node 의존을 들이면 그 import 의 비용이 달라진다.

### 왜 tsconfig 가 따로 있나

상위 `../tsconfig.json` 은 플러그인 샌드박스에 맞춰져 있다 — `typeRoots` 가
`@figma/plugin-typings` 로 고정되어 있고, 그 고정은 **플러그인 코드가 Node API 에
닿지 못하게** 막으려는 의도다. 여기 스크립트는 반대로 순수 Node 프로그램이라
`figma` 전역이 보여선 안 된다.

그리고 실측으로도 분리가 필요하다: 상위 config 에 `reverse/**/*.ts` 를 넣으면
`scripts/gen-icons.ts` 가 **깨진다.** `import`/`export` 가 없는 파일은 전역
스크립트로 취급돼 최상위 선언이 한 네임스페이스에 쏟아지는데, `process` ·
`require` · `fs` 구조분해 같은 로컬 ambient 를 쓰는 파일이 둘 이상이면 서로
충돌하기 때문이다. 상위 config 는 그런 파일을 하나만 담을 수 있다.

`@types/node` 는 의존성에 넣지 않는다(상위 `scripts/*.ts` 와 같은 방침). 대신 각
파일이 쓰는 Node 전역만 파일 안에서 최소한으로 선언한다.

```bash
npm run typecheck           # 플러그인 (code.ts · src · scripts)
npm run typecheck:reverse   # 이 디렉터리
```

> ⚠️ 두 명령은 서로를 포함하지 않는다 — `typecheck` 는 이 디렉터리를 **보지 않고**,
> 이 디렉터리를 검사하는 것은 `typecheck:reverse` 뿐이다. 그러므로 `reverse/` 가
> 검사되는지는 **그 명령을 부르는 CI 단계가 있는지**로만 답할 수 있다:
> `.github/workflows/ci.yaml` 에서 `typecheck:reverse` 를 찾아 확인하라. 부르는
> 단계가 없다면 이 디렉터리는 사람이 손으로 돌릴 때만 타입 검사된다.
