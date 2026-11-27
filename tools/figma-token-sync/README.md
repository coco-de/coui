# CoUI Token Sync (Figma plugin)

CoUI 디자인 토큰을 단방향(code → Figma)으로 **Figma Variables** 에 임포트한다.
`coui_core` 가 단일 출처이며, 임포트를 재실행하면 기존 변수가 중복 생성되지 않고 갱신된다.

**처음 기여한다면 [Figma 단계별 가이드](../../docs/contributing/figma.md)부터
읽으세요.** 환경 준비 → export → build → Import → Generate → 검증 → 게시를
따라갈 수 있습니다. Core·Flutter·Web까지 함께 고치는 흐름은
[기여자 가이드](../../docs/contributing/README.md), 작은 실습은
[Badge 변경 따라 하기](../../docs/contributing/first-change.md)에 있습니다.
이 README는 각 기능과 유지보수 세부 사항을 다루는 레퍼런스입니다.

소비 프로젝트에서는 **소비 프로젝트 컬렉션 오버라이드**에서 활성화된 CoUI
라이브러리 컬렉션 중 필요한 것만 선택할 수 있다. 플러그인은 선택한 항목만 Figma의
Extended Variable Collection으로 로컬에 생성한다. 이 방식은 원본 라이브러리에 새
변수가 생기면 계속 상속하면서 소비 파일에는 변경한 값만 저장하며, 같은 이름의 독립
로컬 복사본과 달리 라이브러리 컴포넌트의 기존 바인딩에도 실제로 적용된다. Extended
Variable Collection 생성은 Figma Enterprise 플랜 전용이다. 비-Enterprise 파일에서는
잘못된 복사본을 만드는 대신 플랜 제한을 명시적으로 보고한다.

덮어쓰기는 파일에 있는 라이브러리 변수에만 걸린다. 파일을 다시 열면 그 파일이 쓰지 않는
라이브러리 변수가 덮어쓰기와 함께 정리되고, 컴포넌트를 넣어 그 변수가 다시 들어와도 예전
덮어쓰기는 돌아오지 않는다(2026-11-01 실측 — 확장 컬렉션마다 125개이던 덮어쓰기가 다시 연
뒤 45개). 그래서 같은 자리에 **같은 이름의 로컬 토큰으로 다시 맞추기**가 있다: 확장
컬렉션마다 덮어쓰기가 없는 변수에, 이름과 타입이 같은 로컬 변수의 별칭을 모든 모드에
넣는다. 짝이 될 로컬 변수가 둘 이상이면(브랜드마다 로컬 컬렉션을 둔 파일) 그 확장 컬렉션의
기존 덮어쓰기가 가장 많이 가리키는 로컬 컬렉션의 것을 고르고, 그래도 하나로 좁혀지지 않으면
고르지 않는다. 짝이 없는 변수는 로그에 적고, 넣은 뒤 컬렉션을 다시 읽어 실제로 들어갔는지
센다. 덮어쓰기가 `Mismatched variable type` 으로 거부되면 그 원인(같은 키의 사본 중복 — 아래
"소비 파일 점검" 의 「가져온 사본 중복」)과 고치는 명령을 함께 적는다. `npm run
selftest:collection-overrides`.

### 브랜드 확장 컬렉션

브랜드는 라이브러리의 컬렉션이 아니다. 라이브러리에는 CoUI 의 색 컬렉션(`Semantic/ Color ·
CoUI`) 하나만 있고, 다른 코드 브랜드(`export_figma_tokens.dart` 가 읽는
`bin/figma_brands/brands.dart` 의 목록 — 지금 Unibook · Medibooks)는 **CoUI 와 다른 값만 담은
표**로 이 플러그인 번들에 들어 있다(`src/data/brands.json`, 익스포터가 쓰는 추적 생성 파일 —
`check_figma_export_fresh.sh` 가 코드와 같은지 본다). 브랜드 탭의 **브랜드 확장 컬렉션 만들기**
가 소비 파일에서 그 표를 쓴다:

1. 라이브러리의 `Semantic/ Color · CoUI` 를 이 파일의 확장 컬렉션으로 연다 — 이름은
   `Semantic/ Color · CoUI → <브랜드>`(이미 있으면 다시 만들지 않는다).
2. 표의 행마다 **이름이 같은** 확장 변수의 모드마다 색을 덮어쓴다. 이미 그 값이면 쓰지 않고,
   이 파일에 없는 변수(그 변수를 쓰는 컴포넌트가 아직 없다)는 이름을 적는다. 넣은 뒤 컬렉션을
   다시 읽어 실제로 들어갔는지 센다. 표에 없는 덮어쓰기는 지우지 않고 개수만 적는다.
3. 화면과 컴포넌트의 연결은 CoUI 변수 그대로이고 값만 확장이 덮는다 — 노드의 바인딩은
   건드리지 않는다.

토큰 탭의 **이름으로 다시 맞추기**는 이 파일의 확장 컬렉션마다 덮어쓰기가 빈 변수를 이름으로
다시 채운다 — 이름이 위 형태인 코드 브랜드의 확장은 그 브랜드 표로, 그 밖의 확장은 위의 같은
이름의 로컬 변수 별칭으로. 파일을 다시 열거나 컴포넌트를 넣은 뒤에 돌린다. 확장 컬렉션은 Figma
Enterprise 플랜에서만 만들 수 있다. 하네스(Figma 대역)가 고정하는 것은 어느 변수에 어떤 색을
쓰는지, 이름 짝짓기, 다시 읽어 세는 것까지이고, 확장의 실제 생성 · 다시 연 뒤의 정리 · 라이브러리
컴포넌트가 실제로 칠해지는지는 소비 파일에서 사람이 본다. `npm run selftest:brand-extension`.

확장은 `Semantic/ Color · CoUI` 변수에 묶인 노드만 덮는다. 화면이 브랜드마다 따로 게시되던
라이브러리 컬렉션(`Semantic/ Color · <브랜드>`)에 묶여 있으면 그 자리는 브랜드 값이 바뀌어도
따라오지 않는다 — 관리 탭의 소비 파일 점검이 「옛 브랜드 컬렉션」으로 세고, **옛 브랜드 컬렉션
다시 연결**이 같은 이름의 CoUI 변수로 옮긴다(아래 "옛 브랜드 컬렉션").

## 팀 플러그인 배포 패키지

`main` 에서 `tools/figma-token-sync/**` 가 바뀌면 GitHub Actions의
**Figma plugin package** 워크플로가 `npm ci` → 타입 검사 → 전체 selftest →
프로덕션 빌드를 실행하고, 게시 가능한 `coui-token-sync-<sha>.zip` artifact를 30일간
보관한다. 필요하면 Actions 화면의 **Run workflow** 로 같은 작업을 수동 실행할 수 있다.

게시자는 성공한 실행의 Artifacts에서 ZIP을 내려받아 압축을 풀고, Figma Desktop의
`Plugins → Manage plugins`에서 기존 **CoUI Token Sync**의 로컬 버전으로 압축을 푼
`manifest.json`을 연결한 뒤 **Publish new version**을 실행한다. Figma는 클래식
플러그인 게시 API를 제공하지 않으므로 마지막 게시 동작만 수동이다. 새 Development
항목의 **Publish**를 누르면 기존 팀 플러그인 업데이트가 아니라 중복 플러그인이 될 수
있으므로, 반드시 기존 게시 리소스의 업데이트 메뉴를 사용한다.

### 게시 원장 — 공개본이 어느 커밋인가 (`PUBLISHED.json`)

리포는 Community 의 공개본을 읽을 수 없다(공식 API 도, 무인으로 쓸 수 있는 비공식
경로도 없다). 그래서 **원장에 적는 것이 곧 게시했다는 선언**이다 — `PUBLISHED.json`
의 `{publishFingerprint, sharedSourceHash, commitSha, figmaVersionLabel, publishedAt, publishedBy}`.

- **게시의 마지막 단계** — Figma 에서 게시한 직후 Actions → **figma-plugin-publish-record**
  를 dispatch 하고 Figma 가 부여한 버전 라벨을 적는다. 워크플로가 그 커밋을 다시 구워
  지문을 계산하고(사람이 옮겨 적지 않는다), 원장 PR 을 열고, 그 시점 번들 zip 을 90일
  보관한다. 이 dispatch 기록이 "누가 언제 게시했나" 의 감사 흔적이다.
- **잊으면 보인다** — `main` 푸시마다 **Figma plugin package** 의 `publish-drift` 잡이
  지금 main 이 굽는 지문을 원장과 대조해, 다르거나 원장이 비어 있으면 라벨
  `figma-publish-drift` 의 **추적 이슈 하나**를 열거나 갱신하고, 같아지면 닫는다. PR
  마다 알리지 않는다 — 플러그인을 건드리는 모든 PR 에 붙어 곧 무시되기 때문이다.
- **게시 지문은 무효화 해시(`kSharedSourceHash`)와 다른 값이다.** 무효화 해시는
  `src/data/*` 를 일부러 빼고 `ui.html`·`manifest.json` 을 보지 않는다. 게시 지문은
  실제로 올라가는 파일 — `manifest.json` 과 그것이 가리키는 `code.js`·`ui.html` — 위의
  sha256 이고, `code.js` 에 구워진 `kBuildRef`(브랜치@커밋) 한 리터럴만 자리표시자로
  바꿔 해시한다. 그러지 않으면 코드가 그대로인 커밋마다 지문이 바뀐다. 실행 로그의 첫
  줄(`🔒`)은 여전히 `kBuildRef` 를 말한다 — 지문은 번들 자신을 해시하므로 번들에 구울 수
  없고, 사람이 읽는 신원은 ref 가 맡는다.
- **원장은 무효화 해시도 함께 적는다(`sharedSourceHash`)** — 게시한 번들에 구워진
  `kSharedSourceHash` 를 기록 워크플로가 번들에서 읽어 적는다(사람이 옮겨 적지 않고,
  구워지지 않은 dev 번들은 기록을 거부한다). 캔버스 밖으로 나가는 산출물 — fidelity
  리포트의 `buildHash`, 디자이너 대조 파일의 `sourceHash`, 실행 로그 첫 줄(`🔒 … 빌드
  <hash> <branch@sha>`) — 은 전부 이 해시를 싣는다. 그래서 공개본 사용자가 보낸 리포트의
  해시를 `git log -S<hash> -- tools/figma-token-sync/PUBLISHED.json` 으로 찾으면 그
  게시가 적은 `commitSha` 가 나온다. 판정에는 쓰지 않는다 — 판정은 게시 지문이 한다.
- **지문은 같은 환경에서 잰 것끼리만 비교된다** — 기록도 판정도 GitHub 러너(ubuntu ·
  node 24 · lockfile 의 esbuild)에서 한다. 로컬 빌드의 지문을 원장과 견주지 않는다.
- 형식은 `node scripts/publish-fingerprint.mjs validate`, 전체는
  `npm run selftest:publish-ledger` 와 `scripts/guards/structure/check_figma_publish_ledger.sh`
  가 본다. 원장은 CODEOWNERS 에 등록돼 있다.

## 무엇을 생성하는가

- **Primitives** 컬렉션 (모드 `Value`): 라이브러리 브랜드(코드 브랜드 목록의 첫 항목 — CoUI)의
  색상 프리미티브(`color/<brandId>/<family>/<step>` — 고정 hex(`CouiColorPresets.palette`)
  `color/coui/neutral/50` … `color/coui/base/black`; 다른 브랜드의 프리미티브는 없다) + 모든 숫자 스케일
  (space, size, radius, stroke, font-family/size/weight, line-height,
  letter-spacing, opacity, duration, z-index) + 복합 토큰 (shadow /
  easing / spring 은 CSS 문자열, focus-ring 은 float + 색상 별칭) +
  duration/easing **시맨틱 별칭 티어**
  (`duration/alias/instant|fast|normal|moderate|slow`,
  `easing/alias/standard|decelerate|accelerate|spring`) — 각각 같은 컬렉션
  안에서 자신의 raw `duration/<n>` / `easing/<key>` 변수를 값을 중복하지 않고
  **별칭으로 참조한다**(Figma 변수 별칭은 컬렉션 간 사용에만 제한되지 않는다).
  모든 `duration/<n>` primitive 는 또한 자신의 reduced-motion 티어를 명명하는
  `description` 을 가지고 있어서 (전환용이라 0ms 로 억제되는지 vs. 표시용이라
  보존되는지) 그 경계가 Figma 를 벗어나지 않고도 파악 가능하다.
- **Semantic** 컬렉션 (라이브러리 브랜드 하나 — `Semantic/ Color · CoUI`, 모드 `Light` / `Dark` / `HC Light` / `HC Dark`):
  `CoreColorScheme` 어휘 (`surface`, `on-surface`, `primary`, …).
  각 모드 값은 Primitives 의 색상을 별칭으로 참조하므로, 모드를 전환하면
  테마 전체가 전환된다; 두 개의 고대비 모드도 같은 어휘 전부를 재서술하고
  (Figma 모드에는 cascade 가 없다), 그중 고대비가 더 강하게 진술하는 슬롯만
  정상 모드와 다른 색을 가리킨다.

- **Content** · **Content Status** 컬렉션 — 아이콘(Lucide 글리프)이 슬롯에서 받는 색.
  `Semantic/ Content` 는 변수 하나(`content/current`)에 모드 13개(톤 12 + `status`),
  `Semantic/ Content Status` 는 변수 하나(`content/status`)에 모드 12개(상태 4 × 톤 ·
  on-톤 · on-컨테이너)다. 모드는 이름이 같은 `Semantic/ Color · CoUI` 슬롯의 별칭이고
  `status` 모드는 두 번째 컬렉션을 거쳐 한 단 더 간다. 글리프의 선은 `content/current`
  에 묶이고, Generate 가 **슬롯 프레임**(아이콘 인스턴스의 부모)에 그 아이콘의 톤을 모드로
  지정한다(상태 톤은 두 컬렉션 모드를 함께). 모드는 아래로 상속되므로 아이콘을 바꿔 넣거나
  지우고 새로 넣어도 색이 부품의 변형을 따른다. 모드 목록은 익스포터가 코드에서 내고
  `src/data/content-colors.json` 으로 번들에도 들어간다 — 이 파일 · 컬렉션 · 하네스가 같은
  목록에서 나온다. 규칙과 도달 범위는 `.claude/rules/core/design-tokens.md` 의 "글리프 색".

변수 이름은 코드 토큰을 그대로 반영한다 (`color/coui/primary/900`, `space/16`,
`font-weight/semibold`), 그래서 Figma 와 코드가 계속 일치된 상태로 유지된다.

## Generate Components 생성

### 레이아웃 감사

`npm run audit:layout`은 REGISTRY 빌더를 전부 실행해 프레임·숨김 슬롯·자식
크기·sizing·constraints를 `LAYOUT_INVENTORY` JSON으로 출력한다. test double은
Figma의 실제 레이아웃 엔진이 아니므로, 이 결과나 selftest의 `0 stale holders`를
리사이즈 검증의 대체로 사용하지 않는다. [2026-09-11 전면 감사](LAYOUT_AUDIT.md)에
라이브 리사이즈 증거, 발견사항, 미검증 대상과 판정 기준을 기록했다.

플러그인의 **Generate Components** 버튼은 `REGISTRY.length` 개의 컴포넌트(현재 **144개** — 직접 세어봐도 좋다: `REGISTRY` 는 `src/registry.ts` 안의 단일 출처이며, `src/components/` 아래 섹션 파일마다 배열 하나씩)를 **컴포넌트당 페이지 1개**(`❖ {Name}` — 예: `❖ Badge`)로 만들고, 모든 값을 Figma Variable 에 바인딩한다 — 색상 → Semantic, padding/gap → `space`, radius → `radius`, border width → `stroke`, 고정 크기 → `size`, font size → `font-size`. 텍스트는 `font-family/sans` 토큰에서 읽은 `CoreFontFamily.sans`(**Pretendard**, 절대 하드코딩하지 않음)로 렌더되며, 라이브 docs 사이트(coui.cocode.im)와 일치한다. Line-height 는 role 을 알 수 있는 경우 각 role 의 `CoreLineHeight` 를 따르고(display/headline 은 `h140`, title/body/label 은 `h160`), role 이 없는 임의 라벨은 기본값으로 `h160` 을 쓴다. Pretendard 로딩은 조용히 넘어가지 않고 크게 실패한다 — 9개의 정적 weight(Thin–Black) 중 하나라도 로컬에 설치되어 있지 않으면, 다른 weight 로 조용히 대체하지 않고 전체 실행이 조치 가능한(무엇을 해야 하는지 분명한) 에러와 함께 중단된다:

### 페이지 구조 — 컴포넌트당 1페이지, 섹션 접두 정렬

페이지 이름은 `❖ {Name}` 이고, 섹션은 **Control · Form · Display · Layout ·
Navigation · Menu · Overlay · Icon · Text · Infra** 10개 — 각 섹션 블록 앞에
`🖥️ DISPLAY` 형태의 헤더 페이지가 놓여 사이드바가 블록 단위로 읽힌다 (헤더가 섹션을
말하므로 페이지 이름은 섹션 접두 없이 짧다).
섹션은 REGISTRY 가 아니라 **schema v3 의 `section` fold** 에서 파생된다 — coui_flutter 의
카테고리 디렉터리를 exporter 의 `kSectionFold` 단일 상수(coui_core
`section_reader.dart`)가 디렉터리 단위로 접은 결과이며, 컴포넌트별 재분류는 없다.

그 fold 는 **근-항등 매핑**이다 — 카테고리 하나가 같은 이름의 섹션 하나로 가고,
`locale`(로컬라이제이션 데이터, 시각 컴포넌트 아님)만 `null` 로 접혀 빠진다. 그래서
이 섹션 목록은 docs 사이트의 그룹
([coui.cocode.im/components-overview](https://coui.cocode.im/components-overview/),
소스는 `docs_core/lib/shared/component_catalog.dart` 의 `kDocsComponentGroups`)과
**1:1 로 일치**하고, 페이지 블록 순서도 그 카탈로그의 큐레이션 순서를 따른다. 둘이
같은 목록인 이유는 애초에 같은 곳(coui_flutter 카테고리 디렉터리)에서 나오기
때문이다 — 서로 다른 두 taxonomy 였던 적이 없고, 같은 것을 두 가지 세밀도로 접고
있었을 뿐이다.

**페이지 순서는 플러그인 페이지에만 주장한다** — ❖ 컴포넌트 페이지와 섹션 헤더가
섹션순 → 카탈로그 큐레이션 순서(카탈로그에 없는 것은 이름 순으로 그 뒤)로 읽히고,
나머지 페이지(디바이더 · 강등 메모 · 시안 · Foundation)는 직접 옮기지 않고 **자기들끼리의
순서**를 지킨다. 결정은 순수 함수 `pageOrderMoves`(`src/data.ts`) 하나가 하고, 실행은
그 결과를 옮길 뿐이다. 이 순서 주장은 파일 페이지 목록 한정이다 — 라이브러리 Assets
패널은 자체 정렬.

- 헤더는 캔버스가 번호를 붙여도(`02. 📝 FORM`) 같은 헤더로 읽는다. 헤더는 자기 블록
  첫 페이지 **바로 위**에 있을 때만 제자리로 친다 — 순서만 맞고 앞 블록의 메모 ·
  디바이더 위에 떠 있는 헤더는 제자리가 아니다. 그래서 헤더와 첫 페이지 **사이**에 둔
  메모는 헤더가 첫 페이지 쪽으로 내려오면서 헤더 위에 남는다 — 강등 메모는 블록 끝에 둔다.
- **페이지 순서 정리**(UI 체크박스, 기본 해제 · `전체 새로 생성` 은 항상 켬)를 켜면
  이미 순서가 맞는 가장 긴 줄을 그대로 두고 나머지 플러그인 페이지만 옮긴다. 정리된
  파일에서는 아무것도 옮기지 않으므로 다시 돌려도 이동 0 이다.
- 끄면 기존 페이지는 하나도 옮기지 않는다. 그래도 **이번 실행이 만든 페이지는 제 섹션
  자리에 놓는다** — `createPage` 는 파일 끝에 붙이므로, 놓지 않으면 새 페이지가 끝에
  쌓인다. 페이지는 있는데 헤더가 없는 섹션은 어느 쪽이든 헤더를 만들어 그 페이지들과 함께
  놓는다 — 헤더가 없으면 새 섹션의 첫 페이지를 놓을 블록이 없다.
- 검증(Verify) 의 두 실행은 정리를 끈 채로 돈다 — 검증이 파일 배치를 바꾸면 안 된다.
- 페이지 하나를 옮기지 못하면(`unloaded font` 등) `⚠` 한 줄을 남기고 나머지를 계속한다.

각 페이지에는 세 가지가 놓인다: ① **ComponentSet** — 컨트랙트의 4축(`Variant` ×
`Size` × `State` × `Enabled`)의 **완전 조합**(예: Button 12×6×2 = 144). 조합은
`src/axis-combos.ts` 의 열거자에서 파생되고, G10 가드가 같은 함수로 분모를 재기 때문에
세트와 표가 어긋날 수 없다. ② **`_Docs / Properties`** — 4축 + 규약 밖 enum(`axes.other`)
+ v2 chrome 필드 전수 표(캡션 = 컨트랙트 경로). ③ **`_Docs / Examples`** — 기본 생성자
(axes 파생) · `withStyle` 체인(문서 예제 원문) · 토큰 getter 체인 코드 블록(코드 폰트는
내보낸 고정폭 서체 `font/family/Geist Mono`, 없으면 sans 폴백 + 경고 로그. 크기와 21px 줄
상자는 `codeSm` 역할에서 읽고, 코드 안 한글 구간은 본문 서체로 칠한다 — 아래 "고정폭 글의
한글" 참조). 컴포넌트 노드에는 docs_site 의
한국어 설명이 `description` 으로, 문서 URL 이 `documentationLinks` 로 찍힌다.

구 단일 `🧩 Components` 페이지는 **마이그레이션 소스**로만 탐색된다(새 문서에는 만들지
않음) — 실행이 노드를 파생 페이지로 **이동**(reparent — `id`/`key` 보존)시키고, 완전히
비면 제거하며, 남은 비-레지스트리 노드가 있으면 목록과 함께 보존·경고한다. 구 단일축
variant 자식들은 `src/renames.ts` 의 명시 이행표(`VARIANT_RENAMES`)로 조합명을 얻고,
4축에 목적지가 없는 자식(값(VALUE)을 인코딩했던 `Toggle State=On` 류)은
`RETIRED_VARIANTS` 대장에 이유와 함께 올라 **옵트인 액션**(dry-run → remove)으로만
정리된다 — Generate 는 어떤 영속 **노드**도 삭제하지 않는다. 컴포넌트 **프로퍼티**는
노드가 아니라 정의라서 규칙이 다르다 — 재활용된 세트는 정의를 계속 들고 있고, 어떤
레이어도 참조하지 않는 정의가 하나라도 있으면 Figma 게시 창이 그 세트를 조용히 뺀다
(아래 "미연결 속성 정리"). 그래서 Generate 는 세트를 그린 직후 **어떤 레이어도 참조하지
않는** 정의만 지우고 한 줄씩 로그에 남긴다. `RETIRED_PROPERTIES` 대장은 레이어 쪽에서
판정할 수 없는 경우와 세트를 다시 그리지 않고 지울 때를 위한 옵트인 액션이다(인스턴스는
떨어지지 않고, 더는 아무것도 토글하지 않는 오버라이드 값만 잃는다).

> **유료 플랜 전제**: 컴포넌트당 페이지 구조는 100+ 페이지를 만든다 — Figma Starter
> 플랜의 파일당 3페이지 제한에서는 동작하지 않는다.

**섹션 스코프 실행**: UI 의 섹션 체크박스 10개로 일부 섹션만 생성할 수 있다(전부 체크 =
전체 실행). 스코프 밖 섹션 페이지는 그 실행에서 불변이고, 스코프 안에서도 엔트리별 해시가
안 바뀐 것은 건너뛴다.

**스코프 실행은 필요한 페이지만 로드한다** — 직전 실행이 문서의 컴포넌트 인덱스(이름 → 노드
id · 페이지)를 문서 plugin data 에 남기고, 다음 스코프 실행은 그 인덱스가 여전히 참이면 그리는
페이지와 `needs` 가 가리키는 페이지만 `loadAsync` 한다(`src/component-index-cache.ts`).
**같은 빌드 · 같은 페이지 목록 · 쓰는 이름이 전부 기록됨 · 쓰는 노드가 전부 같은 이름·같은
페이지로 해석됨** 중 하나라도 어긋나면 예전처럼 전체를 로드하고 캐시를 다시 쓴다 — 로그 첫머리의
`⚡ 컴포넌트 인덱스 캐시 적중` / `… 미사용 — 전체 로드 (사유)` 한 줄이 어느 쪽이었는지 말한다.
적중한 실행은 문서 전체를 훑지 않으므로 중복 이름 경고와 손으로 붙여 넣은 컴포넌트는 다음 전체
로드가 본다. 새 빌드의 첫 실행, 범위 전체 실행, 강제 재생성은 언제나 전체 로드다. **측정할 때는
플러그인을 새로 연 세션에서 Generate 를 첫 동작으로** 돌린다 — 같은 세션의 다른 명령(낡은 세트
보기 등)이 페이지를 먼저 로드하면 `loadAsync` 줄이 그 비용을 보여 주지 않는다.

**5분 예산(NFR-007)은 이 스코프 하나에 대한 값이다** — 레지스트리 전체 크기가 아니라
*한 실행이 스스로 그리기로 한 범위*를 잰다. 스코프된 실행이 5분을 넘으면 경고 한 줄,
10분(2배)을 넘으면 더 잘게 나누라는 R-3 판정이 붙는다.

**전량 실행은 그 예산의 대상이 아니다.** 전 카탈로그를 한 번에 다시 그리는 것은 지원되는
사용(주간 루틴)이고, 이미 전부를 요청한 실행에 "분할하라" 는 답이 되지 않는다. 대신 아무것도
막지 않는 **관찰용 상한 40분**만 있다 — 넘으면 회귀 탐지용으로 `ℹ` 한 줄이 로그에 남는다
(마지막 실측: 2026-09-18 전량 27.8분).


`Input`→`TextField`, `Radio`→`RadioGroup`, 그리고 복합 label+input+helper
목업(과거에는 마찬가지로 "TextField" 라 불렸던) → `FormField` 는 실제
`coui_core` 클래스명에 맞춘 이름 변경이다(#3742) — 예전 Figma 이름은 한 번 인식되면
제자리에서 이름이 바뀌므로(`src/renames.ts`), 플러그인 업그레이드 후 재실행해도
기존 컴포넌트의 `id`/`key` 를 잃지 않는다. 예전에 단일 존재했던 "Rating" 컴포넌트(`StarRating`
과 바이트 단위로 동일한 중복본)는 사라졌다 — `StarRating` 이 항상 올바른 이름이었다. 예전의
단일 "Mockup" variant set 도 사라졌고, 실제 4개의 `coui_core` 클래스와 매칭되는 4개의
독립 컴포넌트로 대체됐다 — Figma 에는 "variant set 을 N개 컴포넌트로 분할"하는 in-place
연산이 없으므로, 이 버전이 처음 실행될 때 그 예전 노드 하나는 (조용히 중복 생성되는 대신)
명시적으로 폐기된다.

**이 플러그인은 열려 있는 Figma 문서를 대상으로 한다(#3740).** `manifest.json` 에 파일
바인딩이 없다 — 잘못된 문서에서 실행하면 그 문서에 조용히 병렬 컴포넌트 세트가 생겨난다.
Generate Components 는 현재 문서의 루트에
[`docs_core/content/_data/figma_library.json`](../../docs_core/content/_data/figma_library.json)
에 기록된 표준 라이브러리 식별자를 찍고(docs_site 의 "Figma 라이브러리" 가이드 참고),
이미 다르게 찍혀 있는 문서가 일치하지 않으면 **경고**만 한다(절대 막지 않음) — 표준
라이브러리를 나중에 옮기는 것은 그 파일 하나만 편집하면 되는 일이고, 여기 코드는
하나도 바뀌지 않는다.

**`Separator` 와 `Datalist` 는 사라졌다(#3744)** — 둘 다 대응하는
`coui_core` 클래스가 없다(`Divider` 가 이미 `Separator` 가 그리던 모든 것을 커버하고,
`Datalist` 는 코드베이스 어디에도 존재한 적이 없다). 이 플러그인에서 빌더를 제거하는 것
자체는 그 예전 Figma 노드를 삭제하지 **않는다**(그게 바로 #3737 의 취지 전부다) — UI 하단의
**Dry-run retired components** / **Remove retired components** 버튼이 명시적인 opt-in
정리 경로이며(`src/renames.ts` 의 `RETIRED`), 항상 먼저 dry-run 한다. `Separator`
인스턴스는 `Divider` 로 옮겨야 한다(`Separator` 의 대칭 `indent` 대신 `indent`/`endIndent`
를 사용); `Datalist` 는 대체재가 없다.

**이름으로 찾아 채우기, 삭제 후 재구축이 아니다(#3737).** 재실행 시 각 영속
컴포넌트/세트를 **이름으로** 찾아 그 자리에서 비우고 다시 채운다 — 이 경로 어디에서도
이 플러그인이 완전히 소유하지 않은 노드에 대해 `.remove()` 를 호출하지 않으므로,
컴포넌트의 Figma `id`/`key`(실제로 인스턴스가 링크하는 대상)는 재실행을 거쳐도
살아남는다. 빌더가 throw 해도 롤백하지 않는다 — 그 항목은 실행 로그에 실패로
보고되고, 반쯤 그려진 컴포넌트가 캔버스에 그대로 남았다가 다음 실행이 그 이름을
민팅할 때 `resetNode` 로 비워진다. 예전의 삭제 후 재구축 설계에서는 throw 가 곧
영구 손실을 의미했지만, 빌드 전에 아무것도 삭제하지 않으므로 이제는 그렇지 않다.
변경 사항이 없는 상태로 재실행하면 모든 항목이 `skipped` 로 보고된다 —
build-recipe 콘텐츠 해시가 노드에 이미 찍혀 있는 것과 일치하므로 아예 손대지
않는다(#3739). Section heading 은 유일한 예외로 매 실행마다 완전 삭제 후 재생성된다
— 아무것도 heading 에 링크하지 않기 때문이다. 바인딩이 해석되도록 **Import to Variables**
를 먼저 실행하라.

**빌더가 없는 `coui_core` 컴포넌트는 없다.** `contracts/` 아래 디렉터리 141개 ·
MAIN `CoreXxxStyle` 클래스 143개에 대해 REGISTRY 는 144개 항목을 갖고, G2
(`check_figma_registry_parity.sh`)의 미등재 ratchet baseline 은 비어 있다 —
이 숫자를 믿지 말고 그 파일이 비어 있는지를 봐라. 세 수가 서로 다른 이유는 세는
단위가 다르기 때문이다(한 디렉터리가 Style 클래스를 둘 이상 담기도 하고, 몇몇
REGISTRY 항목은 형제의 Style 에서 chrome 을 읽는다 — G2 의 D2 면제).

그중 41개(`src/components/primitives-*.ts`)는 자체 chrome 이 거의 없어 주로 다른
컴포넌트의 부품으로 쓰이는 인프라 / 동작 / 레이아웃 primitive(clickable,
focus_outline, gap, mask, popup, scroll\*, frame, stacks, aspect_ratio_box,
outlined_container, window_panel, label, icon, text_block (=Text), form, validated,
theme_controller, …)다. 부품이라는 것이 안 그린다는 뜻은 아니다 — 나머지와 똑같이
컴포넌트당 페이지 하나를 얻으며, 자기 카테고리가 정한 섹션(Layout 17 · Display 9 ·
Infra 7 · 그 외 8)에 놓인다.

### Data-driven defaults (SSOT)

컴포넌트의 **시각적 default 값**(variant 색상, radius, padding, border width)은 빌더 안에 하드코딩되지 않는다 — 단일 출처인 `coui_core` 에서 export 되어 빌드 시점에 읽힌다:

```
coui_core CoreXxxStyle.defaultsByVariant / defaultsBySize / static const default*
  → dart run packages/coui_core/bin/export_figma_components.dart   (melos run export:figma-components)
  → tools/figma-token-sync/src/data/components.json                (schema v2 — {fields, variants, sizes})
  → esbuild --bundle inlines the JSON into code.js
  → builders read COMPONENTS.<slug> via src/data.ts (colorData / textStyleData
    from src/compat/v1.ts adapt the raw leaves, then fillData / borderData /
    labelColor / textLabelOpts paint them)
```

`src/data.ts` 에는 컴포넌트별로 손으로 작성한 인터페이스가 없다 — `tsconfig.json` 의
`resolveJsonModule` 이 커밋된 JSON 의 정확한 리터럴 타입을 `COMPONENTS.<slug>.fields.<key>` 에
부여하므로, 오래된 인터페이스가 실제 exporter 산출물과 몰래 어긋날 수 없다 (스키마 v1 의
손으로 작성한 `ButtonData`/`CardData`/… 인터페이스가 정확히 이 문제를 겪었다 — `as unknown as ComponentsDoc`
가 그 불일치를 `tsc` 로부터 가려버려서, #3754 가 실제 스키마 v2 출력에 대해 검사하기 전까지는
드러나지 않았다). leaf 는 `{v, ref, via}` (Dim), `{ref, argb, opacity, fallbacks}`
(Color), `{role, fontSize?, fontWeight?, letterSpacing?, lineHeight?,
fontFamily?, color?}` (Text — `lineHeight` 는 단위 없는 `CoreLineHeight`
배수이며, `helpers.ts#makeLabel` 이 Figma 의 PERCENT 단위로 변환한다), 또는
Insets/Radius/Gap/Icon 에 특화된 형태다 —
`packages/coui_core/bin/figma_reader/emit.dart` 참조. `coui_core` 에서 default 값을
바꾸고 export + `npm run build` 를 재실행하면 Figma 컴포넌트가 그에 따라 갱신된다 — 플러그인
안에 두 번째 사본이 존재하지 않는다.

**144개 레지스트리 컴포넌트 전부가 스키마 v2 로부터 읽는다** — 모든 빌더가 자신의
`CoreXxxStyle` 이 실제로 노출하는 색상/치수/타이포그래피를 그대로 배선한다. 이것이 "모든
리터럴이 사라졌다" 는 것과 같은 말은 아니다: 옛 손작성 빌더들이 가정했던 필드 중 상당수는
실제 Dart Style 클래스에 존재하지 않는다(자식 컴포넌트에서 합성되어 재선언되지 않는 컨테이너
chrome, 대응 필드가 없는 타이포그래피 role, 안전하게 배치하려면 런타임 측정이 필요한
geometry). 이런 것들은 의도적으로 리터럴로 남아 있으며, 아래 OQ-2 표에 구체적인 필드와 이유가
기록되어 있다 — 이 파일들 안의 문서화되지 않은 리터럴은 버그이고, 문서화된 리터럴은 확인된
갭이다.

10개 컴포넌트(Button/Card/Badge/TextField/Checkbox/Toggle/RadioGroup/Alert/
Status/Stat, form.ts/display.ts/display-data.ts)는 스키마 v2 가 도입되기 전부터
이미 단일 출처였고, 나머지가 따르는 참조 패턴 역할을 한다. G7 의 리터럴-카운트 ratchet
(`scripts/guards/structure/check_figma_builder_literals.sh`) 은 1131(10/101 전환)에서
587(101/101 시도됨, OQ-2 갭은 예외)로 줄었다 — 이는 #3755 시점의 스냅샷이다. 그 뒤로도
ratchet 은 계속 내려가 524 → 388 → 326 → 318 → 304 를 거쳐 **오늘 기준 0**(미설명
리터럴 없음)이다 — `scripts/guards/structure/figma_builder_literals_baseline.txt` 의
날짜별 이력 참조. #3996 에서 빌더가 없던 41개 컴포넌트가 전부 data-driven 으로
새로 작성돼 레지스트리가 101 → 144 로 늘었지만, 그 새 빌더들도 처음부터
리터럴 없이 작성돼 이 숫자를 다시 올리지 않았다.

#### builder-original 제외 판정 (OQ-2, #3755)

⚠️ **이 README 가 과거에 했던 주장에 대한 정정**: 이전에는 "Chat/Window/Calendar 는
대응하는 `coui_core` default 가 없고 의도적으로 builder-original 이다" 라고 적혀
있었다. 그 문장을 작성했을 당시 존재하던 exporter 를 기준으로는 맞는 말이었다. 하지만
**지금은 사실이 아니다** — 스키마 v2 reader(#3724/#3746, `packages/coui_core/bin/figma_reader/`)
는 손으로 관리하는 컴포넌트별 목록이 아니라 analyzer AST 를 통해 모든 `CoreXxxStyle`
클래스를 순회하며, 세 컴포넌트 모두에 대해 실제 필드 데이터를 찾아낸다:

| 컴포넌트 | 스키마 v2 필드 |
|---|---|
| `chat` | 4개 (`avatarSpacing`, `groupSpacing`, `headerTextStyle`, `footerTextStyle`) |
| `window` | 24개 (타이틀 바 높이, 리사이즈 두께, 15개의 snap-preview/snap-bar chrome 필드, window/close/minimize 전환 파라미터, …) |
| `calendar` | 20개 (일/월 셀 크기, 셀 간격, 헤더/연 그리드 간격, 선택/범위 색상, 6개 타이포그래피 role, …) |

(머지되지 않은) Epic D 브랜치에서 생성된 스키마 v2 JSON 을 기준으로 확인한 결과:
**101개 레지스트리 컴포넌트 전부가 비어있지 않은 필드 데이터를 가진 대응 스키마 v2
엔트리를 가지고 있다** — OQ-2 가 제시했던 "coui_core default 가 존재하지 않는다" 는
제외 기준은 오늘 기준 후보를 **0개** 지목한다. 모든 `RegistryEntry.name`
(`src/components/*.ts`) 을 reader 의 snake_case 키로 변환해 `components.json` 의
`components` map 안에 존재하는지 확인함으로써 검증했다 — 정확한 스크립트는 이 파일의
git history 를 참조하라.

이제 OQ-2 의 *다른* 기준이 남는다: "Figma 표현이 코드 구조와 1:1 이 아닌 것". 이 기준은
**필드 존재 여부 검사로는 답할 수 없다** — 각 빌더의 실제 드로잉 로직(루프, 동적 레이아웃,
paint-ready chrome 이 아니라 raw 숫자로 export 된 애니메이션 파라미터 — 예를 들어
`window` 의 `snapPreviewBlurSigma`/`minimizedScale`/`closeAnimationScaleMin` 은
물리/애니메이션 입력값이지 `fillData`/`bindSize` 가 바인딩할 수 있는 대상이 아니다)를 각
컴포넌트의 Dart contract 와 대조하며 사람이 읽어야 한다. 전환 작업이 하나도 손대지 않은
상태에서 101개 전부에 대해 멀리서 이 작업을 하는 것은 전환 작업 자체와 비슷한 규모의
별도 프로젝트가 되며, 판단이 아니라 추측을 만들어낼 것이다.

**결정**: OQ-2 제외 판정은 **전환 시점에, 점진적으로** 이뤄진다 — #3754/#3755 가 실제로
어떤 빌더를 지나갈 때, 기존 `fillData`/`borderData`/`bindSize`/… 표면으로는 정말로 바인딩할
수 없다는 것을 발견하면(필드가 스키마 v2 에는 존재하지만 그 *형태* 가 정적인 paint-ready
값이 아닌 경우 — 예를 들어 애니메이션 곡선 파라미터, 절차적으로 계산되는 그리드 위치 —
또는 옛 빌더가 존재한다고 가정했던 필드가 실제 `CoreXxxStyle` 에 전혀 없는 경우), 그 필드는
**구체적인 이유가 기록된** 채 리터럴로 남는다 — 설명되지 않은 하드코딩 값으로 방치되지
않는다. #3754/#3755 의 전환 작업은 이제 완료되었다(101개 레지스트리 빌더 전부 시도됨) —
이것은 자리표시자가 아니라 필드 단위의 실제 결과다.

아래 표 전반에 걸쳐 두 가지 형태의 갭이 반복된다:

- **합성된 자식(Composed-child) chrome** — 빌더의 박스/타이포그래피가 시각적으로는
  바깥 컴포넌트 자신의 `CoreXxxStyle` 에 재선언되는 것이 아니라, *다른* 실제
  컴포넌트에 속한다(`TextField` 로 만들어진 트리거, `Popup`/`Card` 로 만들어진 패널).
  스키마 v2 reader 는 nested Style 슬롯을 부모의 `fields` 로 평탄화하지 않으므로, 그
  chrome 은 바깥 컴포넌트의 JSON 엔트리에서 아예 접근할 수 없다.
- **`static final` / 계산된 스타일** — reader 는 `static const` 인
  `CoreTextStyle`/`CoreColor` leaf 만 해석한다(`style_reader.dart` 의 AST 순회는
  평가할 표현식이 아니라 리터럴을 필요로 한다); `static final … .copyWith(...)`
  또는 `.merge(...)` 로 선언된 필드는 Dart 소스에 실제 default 가 있음에도 reader
  에게는 보이지 않는다.

6개 컴포넌트는 이 정적 프리뷰가 그리는 것과 그 `CoreXxxStyle` 이 실제로 담고 있는 것
사이에 **재사용 가능한 겹침이 전혀 없는** 것으로 확인됐다(`chat`, `window`, `popover`,
`context_menu`, `switcher`, `indicator`) — 존재하는 필드는 모두 그릴 것이 없는
위치/애니메이션 입력값이거나, (Chat/Window 의 경우) 이 간단한 데모가 렌더하는 것과는
근본적으로 다른 UI 개념(아바타+헤더/풋터 레이아웃, snap-preview chrome)을 스타일링하고
있다. 이들은 필드 단위가 아니라 표 맨 위에 한 번에 기록되어 있다.

| 빌더 | 제외된 필드 | 이유 |
|---|---|---|
| **Chat** | 전체 컴포넌트 (bubble 배경/radius/padding, message 타이포그래피, row gap) | `CoreChatStyle`의 4개 필드(`avatarSpacing`/`groupSpacing`/`headerTextStyle`/`footerTextStyle`)는 이 프리뷰가 렌더링하지 않는 avatar+header/footer 레이아웃을 모델링한다 — 겹치는 부분 없음 |
| **Window** | 전체 컴포넌트 (outer/titlebar/body chrome, traffic-light dot, 텍스트) | 필드가 거의 전부 window-snap-preview 기능(`snapBar`/`snapPreview`/`snapTile`)에 해당하며, 이 프리뷰가 그리는 정지 상태 titlebar+body chrome 과는 다른 UI 개념이다 |
| **Popover** | 전체 컴포넌트 | 필드가 전부 placement/animation timing(`placementOffset`, open/close duration, `viewportPadding`) 뿐이라 — 패널 chrome 이나 typography 를 뒷받침하는 필드가 없음 |
| **ContextMenu** | 전체 컴포넌트 | `fields`/`variants`/`sizes` 가 모두 `{}` 임 |
| **Switcher** | 전체 컴포넌트 | 필드가 `duration` 하나뿐이며 — 시각적이지 않은 animation timing 값임 |
| **Indicator** | 전체 컴포넌트 (유일한 필드: `offset`) | badge 위치를 옮기는 delta 값인데, badge 자체의 렌더링된 픽셀 크기(content-hugged 라 여기서 정적으로 모델링되지 않음)를 함께 알아야만 적용 가능하다 — 이 값을 쓰면 geometry 를 추측하는 위험이 있음 |
| FormField | 라벨 텍스트, input box border/radius/padding, placeholder 텍스트 | `CoreFormFieldStyle` 의 필드가 아니라 — 합성된 FormLabel/child 슬롯에 속함 |
| Fieldset | `legendTextStyle` | `static final … .copyWith(fontWeight:)` 이며 — `static const` leaf 가 아님 |
| Fieldset | field-row chrome | `CoreFieldsetStyle` 에 nested FormField/TextField 슬롯이 없음 |
| FileInput | idle-state 배경 | `backgroundColor` 필드가 없음 — `dragActiveBackgroundColor` 만 있음 |
| InputOtp | `textStyle` (digit 타이포그래피) | `static final … .merge(...)` 임 |
| InputOtp | `focusBorderColor` (첫 셀 강조) | Dart 소스에 짝이 되는 `static const default*` 가 없음 |
| PhoneInput | `dialCodeTextStyle` ("+1" 타이포그래피) | `static final … .copyWith(fontWeight:)` 임 (export 된 `dropdownDialCodeTextStyle` 은 trigger 가 아니라 *dropdown rows* 를 스타일링함) |
| PhoneInput | `chevronIconStyle.size` | JSON 에는 존재하지만 `null` 임 — default 값이 없음 |
| PhoneInput | `height` | `bindSize()` 가 바인딩하는 *size* scale 이 아니라 *space* scale 로 추적됨 — auto-hug 로 남겨둠 |
| ChipInput | `chipStyle` (nested `CoreChipStyle`) | composite child-component Style 슬롯이라 reader 가 평탄화하지 않음 — Dart 소스의 `CoreChipInputStyle.defaultChipStyle` 을 직접 읽어 값을 교정함 |
| ChipInput | `placeholderColor` | internal-only `static const` 이며, 짝이 되는 instance 필드가 없음 |
| ValidatorHint / ValidationBadge | 아이콘 크기 축 | *space* scale 로 추적됨 — `glyphOpts`의 `'fontSize'\|'size'` 옵션 중 어느 것도 일치하지 않음; ValidationBadge 는 로컬 `lk.space(...)` workaround 를 사용함 |
| select | trigger box 배경/보더/radius/padding | nested composite `CorePopoverStyle→panelStyle` 이라 walk 하지 않음 |
| autocomplete | 전체 trigger box + placeholder/magnifier 색상 | `CoreAutocompleteStyle` 은 *dropdown* 필드만 노출함 |
| switch_field | Toggle 자체의 thumb 색상 + track/thumb 치수 | SwitchField 는 합성된 Toggle 에 `activeColor`/`inactiveColor` 만 전달함 |
| switch_field | `labelTextStyle`/`disabledLabelTextStyle` | `.copyWith` 를 사용한 `static final` 임 |
| stepper | `indicatorBorderColor` | `static const default*` 가 전혀 존재하지 않음 |
| stepper | `indicatorNumberActiveStyle`/`indicatorNumberInactiveStyle` | `.copyWith` 를 사용한 `static final` 임 |
| stepper | connector segment 길이 | 실제 컴포넌트는 이 값을 flex-stretch 함 — Style-default 에 대응하는 값이 없음 |
| fab | `buttonStyle` (main circle 배경/radius/glyph 색상) | nested composite `CoreButtonStyle` 이라 walk 하지 않음 |
| filter | `resetButtonStyle` | nested composite `CoreButtonStyle` 이라 walk 하지 않음 |
| item_picker | `selectedTextStyle` | role 이 없는 `CoreTextStyle(color:...)` overlay 임(`.token()` 없음) |
| item_picker | search box 자체의 chrome + placeholder/magnifier 색상 | `searchHeight` 외에는 chrome 필드가 없음 |
| object_input | `fieldInputStyle` (placeholder 색상/타이포그래피) | nested composite `CoreTextFieldStyle` 이라 walk 하지 않음 |
| star_rating | `starSize`/`starSpacing` 바인딩 scale | `CoreFontSize`/`CoreIconSize` 가 아니라 `CoreSpace` 로 추적됨 — 값이 data-driven 이라 바인딩된 Variable 컬렉션이 부정확함 |
| color_picker | trigger box 배경/radius/padding, hex-value 텍스트 스타일 | `.fields` 에 container-chrome 이나 text-style 필드가 없음 |
| date_picker | trigger container 배경/보더/radius/높이/gap, padding | 필드는 value-text + trailing-icon + label/description/error 만 다루며, 이 compact trigger 가 렌더링하는 것은 하나도 없음 |
| time_picker | value-text 타이포그래피 (크기/weight) | `valueTypography` 에 대응하는 필드가 없음(색상은 여전히 `contentColor` 에서 옴) |
| calendar | outer panel 배경/보더/radius/padding | container-chrome 필드가 없음 |
| calendar | `arrowIconStyle` 색상 | leaf 는 `size` 만 가지며, `color` sub-field 는 없음 |
| avatar | per-size 지름/font-size (xs..xl) | `sizes.defaultsBySize` 가 `{}` 임 — per-size dispatch table 이 없음(`initialsFontRatio` 는 존재하지만, 곱셈으로 유도하면 실제 Dart resolver 와 대조 검증되지 않은 값이 됨) |
| progress | track 너비, demo fill 너비 | width 필드가 없음 — chrome 이 아니라 layout/preview 선택임 |
| skeleton | demo box 크기, text-line 전체 너비 | `defaultsByVariant` 항목은 `borderRadius`+`background` 만 가지며, size 필드는 없음 |
| NumberTicker | caption 타이포그래피, value↔caption gap | `CoreNumberTickerStyle` 에는 `duration`+`textStyle` 만 있음 |
| Countdown | unit caption 타이포그래피, block chrome, row gap | `CoreCountdownStyle` 에는 `animationDuration`+`labelStyle` 만 있음 |
| Timeline | title 타이포그래피 | `timestampTextStyle`/`descriptionTextStyle` 만 존재 |
| Timeline | dot↔content gap, title↔timestamp gap | `columnGapStyle`/`contentTopGapStyle`/`dotTopMargin` 는 형태가 동일한 후보들이라 JSON 만으로는 구분할 방법이 없음 |
| CardImage | content padding/gap, title/subtitle 타이포그래피 | `CoreCardImageStyle` 에 해당 필드 없음 |
| Carousel | image↔dot row gap, dot 크기 | 대응 필드 없음 |
| CodeDiff | outer container padding | `linePadding` 는 라인별 값이지 컨테이너 단위가 아님 |
| CodeDiff | `prefixFontWeight` | 각 라인을 prefix + 나머지 텍스트 run 으로 나눠야 함 (구조적 변경 필요) |
| Diff | outer surface fill, "Before"/"After" 라벨 타이포그래피 | `CoreDiffStyle` 에 `backgroundColor`/`labelStyle` 없음 |
| HoverGallery | `height` | 실제 필드는 존재함 (300 vs old 180) 하지만 변환하려면 여러 absolute-positioned 자식들의 offset 을 다시 계산해야 함 |
| HoverGallery | container fill, icon glyph 크기/색상, dot 크기/색상 | 대응 필드 없음 |
| MockupBrowser | toolbar 배경 | toolbar-background 필드 없음, `addressBar*` 만 존재 |
| MockupCode | code body 배경 + 텍스트 색상, `prefixTextStyle` | 실제 필드들은 *light* 패널을 전제로 하는데, 기존 dark 'inverse-surface' 터미널 바디와는 대비되어 잘 보이지 않음 — "shell bg"와 "body bg"를 구분하는 필드가 없음 |
| MockupDevice | 하드웨어 색 · 광학 레이어 | `Device × Orientation` 네 멤버; 레일·베젤·림·안테나·화면·카메라·버튼·상태 표시줄·홈 인디케이터가 전부 `CoreMockupDeviceStyle` 필드·상수와 `defaultsByDevice` 표에서 오고(기하는 `src/mockup-device-geometry.ts` 가 `CoreMockupDeviceLayout` 을 옮긴 것), 캔버스 폭(phone 160/328 · tablet 321/455)만 프리뷰 선택. 상태 표시줄·홈 인디케이터는 라이브러리 인스턴스가 아니라 코드가 그린 프레임이다. 하드웨어 색(몸체·베젤·버튼·카메라)은 디자이너 사본의 값 그대로인 리터럴이라 변수에 바인딩되지 않는다 — 모드도 브랜드 팔레트도 기기 색을 바꾸지 않는다. 안테나 띠의 70 % 처럼 페인트가 말하는 세기는 노드가 아니라 페인트에 얹는다(`assignPaints`). 반투명 흰색·검정을 겹친 광학 레이어(버튼 광택·rim glow·베젤 안쪽 그림자·몸체 드롭 섀도)도 리터럴이다 |
| Window | `titleBarHeight` | 필드는 존재하지만, axis-sizing-mode 충돌 위험 없이 FILL-width auto-layout row 의 높이를 고정할 검증된 방법이 없음 |
| Sortable | row 보더, internal gap, drag-handle 아이콘 색상, 라벨 타이포그래피, remove-아이콘 크기/색상 | `iconStyle` 에는 `size` 만 있음 (`color` 없음); border/gap/typography 필드 없음 |
| Card | header 타이포그래피 | `CoreCardStyle` 에 header-typography 필드 없음 — `bodyTextStyle` 만 있음 |
| TextField / TextArea | container 배경/보더 색상 | `CoreTextFieldStyle`/`CoreTextAreaStyle` 에 `backgroundColor`/`borderColor` 타입 필드 없음 (resolver 가 ambient scheme 을 직접 참조함) |
| TextArea | placeholder fontSize | 적절한 크기의 필드 없음 (색상은 변형 행의 `placeholderColor`) |
| RadioGroup | indicator radius (9999) | `CoreRadioGroupStyle` 필드 없음 — 원형 모양은 configurable default 가 아님 |
| ChipGroup | pill chrome (배경/radius/padding) | `CoreChipGroupStyle` 필드 없음 — chip 은 실제 Chip 컴포넌트로 합성되는 것으로 추정됨 |
| DescriptionCard | row padding, term-column muted 색상 | 대응 필드 없음 |
| EmptyState | 아이콘 색상, "Add item" 버튼 chrome | icon-color 또는 button-chrome 필드 없음 |
| Loading | dot 크기, dot gap | `size` 는 4가지 시각적 variant 전체에 걸친 인디케이터 전체의 bounding dimension 이며, 이 특정 3-dot 렌더링의 개별 dot 지름이 아님 |
| Basic | Title-line 타이포그래피, trailing "⋯" glyph | 대응 필드 없음 |
| Basic | 실제 두 outer gap 중 하나 (`titleContentGapStyle`) | Figma 의 단일 `itemSpacing` 하나로는 Gap 노드를 추가하지 않고서 `leadingTitleGapStyle` 과 `titleContentGapStyle` 을 둘 다 표현할 수 없음 — 전자가 사용되고, 후자는 그것으로 근사됨 |
| pagination | `inactiveBackgroundColor` | 필드 없음 |
| tabs | label→indicator gap, indicator bar 너비, inactive indicator 색상 | 필드 없음; `contentTextStyle` 에 fontWeight override 없음 |
| steps | "current"(아직 완료되지 않은) outlined-circle 상태, connector 렌더링된 길이 | 이를 지원하는 필드 없음 |
| link | muted/tertiary 색상, underline 두께 | `CoreLinkContract` 에는 variant enum 자체가 없음 |
| menubar | per-item trigger padding/radius/active-배경, bar-level inter-trigger gap | 필드 없음 |
| navigation_bar | root container radius/보더 | 필드 없음 |
| navigation_bar | `selectedLabelTextStyle` | Dart 에는 문서화되어 있지만 export 된 JSON 의 `fields` 에는 없음 (exporter 갭) |
| navigation_menu | root padding/radius, top-level trigger 라벨 타이포그래피 | 필드 없음 / exporter 갭 |
| navigation_menu | `chevronIconStyle` | 미사용 — 데모가 "▾" 를 라벨 텍스트에 그대로 박아 넣어 별도 Icon 슬롯이 없음 |
| dock | root radius/inter-app-gap, per-item radius | 필드 없음 |
| dock | 5색 app-아이콘 회전 | 2-상태 `activeColor`/`inactiveColor` 만 존재하고, 앱별 임의 색상은 지원하지 않음 |
| dialog | panel 배경/보더 색상 | 필드 없음 (TextField 의 container-color 갭과 동일한 형태) |
| dialog | Cancel/Confirm pill 모양/색상 | `dialog` 에 button-chrome 필드 없음 |
| drawer | `headerPadding` | 필드는 존재하지만 프리뷰에 별도 header sub-frame 이 없음 — 사용하려면 구조적 변경이 필요함 |
| drawer | nav-item 간격 | 필드 없음 |
| toast | check-아이콘 색상, title 크기/weight | 대응하는 필드 없음 (title 색상은 여전히 `foregroundColor` 에서 가져옴) |
| menu | item radius, highlighted-row 배경, main 라벨 타이포그래피 | 필드 없음 |
| menu | outer panel 배경/보더/radius/padding/너비 | 실제 소스에서는 Popup 으로부터 합성되며, Menu 가 소유하지 않음 |
| dropdown_menu | items 를 제외한 전체 컴포넌트 | `menuOffset` (positioning) 만 존재 — items 는 공유된 `menuItem()` 헬퍼를 통해 간접적으로 혜택을 받음 |
| command | search-아이콘 색상, list-row 간격 | 필드 없음 |
| command | `headingStyle`/`headingPadding`/footer\*/`emptyPadding`/`listMaxHeight` | 필드는 존재하지만 이 프리뷰의 구조에는 대응하는 element 가 없음 |
| hover_card | 배경/보더 색상, 모든 gap/타이포그래피 | 필드 없음 |
| draggable_panel | handle↔panel gap, title↔body 타이포그래피 | 필드 없음 |
| swiper | `panelBorderWidth` (per-variant) | drawer=absent, sheet=0 둘 다 보이는 보더 없이 렌더됨; panel border-color 필드도 없음 |
| Accordion | item card 배경/보더/radius, header row padding, list gap, chevron 색상 | 필드 없음 (`arrowIconStyle` 에는 `size` 만 있음) |
| Collapsible | trigger title 타이포그래피, body panel 배경/radius, header↔body gap, chevron 색상 | 필드 없음 (`iconStyle` 에는 `size` 만 있음) |
| Divider | "OR" 라벨 타이포그래피/색상, preview segment 길이 | 필드 없음 / layout-only |
| Footer | column-title 타이포그래피 | `CoreFooterStyle` 는 일반적인 `bodyTextStyle` 만 노출함 |
| HeroSection | title/subtitle 타이포그래피, 서로의 gap, CTA 버튼 chrome | content 는 `CoreHeroSectionStyle` 의 caller-supplied 슬롯임 |
| Join | per-cell 배경/전경/padding/보더 | `CoreJoinStyle` 은 `borderRadius` 만 갖고 있음 |
| Table | outer container 배경, inter-cell gap, header row 텍스트 크기/weight/색상 | `CoreTableStyle` 는 body row 용 일반적인 `cellTextStyle`+`foregroundColor` 만 노출하며, header 전용 필드는 없음 |
| Tree | glyph 색상, row-to-row list 간격 | `iconStyle` 에는 `size` 만 있음; spacing 필드 없음 |
| Resizable | pane 배경/타이포그래피 | pane content 는 `CoreResizableStyle` 의 일부가 아님 |
| Resizable | drag-handle grip fields | 이 프리뷰는 변환 전에는 grip element 를 렌더한 적이 없음 — 필드는 존재하지만, 지금 추가하면 구조를 새로 추가하는 것이 됨 |

### Verify (opt-in identity self-check, #3739)

플러그인 UI 하단의 버튼 두 개는 의도적으로 Generate Components 의 일부가 **아니고** CI 에서도 실행되지 않는다 — mint-by-name(#3737) 이 실제로 유지되는지 증명하기 위해 존재하는 것이지, 매 실행을 게이트하기 위한 것이 아니다:

- **Verify identity idempotence** — Generate Components 를 두 번 실행해 두 실행 사이에서 모든 영속 component/set 의 `id`/`key` 를 diff 한다. `created N / recreated N / skipped N / idChanged N / keyChanged N` 을 리포트한다(모두 0 이고 `skipped` 만 있는 형태만 통과다). 비교적 빠름(실제 2회 실행).
- **Verify reset completeness** — 항목 하나(이름을 입력)이든 전체 항목(빈칸으로 두면 — **느림, 몇 분 걸림**: 144개 이상의 항목 × 2회 빌드 × 2회 PNG export)이든, scratch 페이지에서 해당 항목을 두 번 빌드하고(두 번째 호출은 첫 번째 호출이 만든 노드를 재활용한다) PNG 바이트 + 서브트리 내 모든 `boundVariables` 키를 diff 한다. 차이가 있으면 `resetNode()`(`src/helpers.ts`)가 지우는 것을 잊은 그 property 의 이름을 정확히 짚어준다.

둘 다 화이트리스트가 아니라 결정적(decisive)이다 — 고정된 필드 목록을 단정하는 대신 실제 문서 상태(바이트 단위 PNG, 재귀적으로 순회한 bound-variable 키)를 되읽으므로, 아무도 reset 목록에 추가할 생각을 못 했던 미래의 property 라도 여전히 잡아낸다.

### 손 편집 보존 + 리디자인 대조 (`src/designer-parity.ts`)

Generate 는 세트를 제자리에서 다시 그리므로, 디자이너가 그 세트를 캔버스에서 직접 고쳐 둔 것은 코드가 바뀌어 그 세트가 다시 그려지는 순간 흔적 없이 사라진다. 그래서 두 가지가 Generate 에 붙어 있다.

**리디자인은 원본 옆 사본에서 한다.** 디자이너는 세트를 ⌘D 로 복제해 같은 페이지 최상위에 `<이름>(리디자인)` 으로 두고 거기서 고친다 — 반영을 누르면 새로 그린 세트를 그 사본과 대조한다. 세트를 직접 고친 경우의 보존은 그 편집이 흔적 없이 사라지지 않게 하는 사고 대비다(절차 전체: `docs/contributing/design-collaboration.md`).

캔버스에는 한 세트를 두고 **네 종류**의 것이 있을 수 있고, 플러그인은 그 넷을 다르게 다룬다:

| 캔버스의 것 | 이름 | 무엇인가 | 플러그인이 하는 일 |
|---|---|---|---|
| 생성본 | `❖ Checkbox` 세트 | 코드가 그린 것 — 반영마다 다시 그려진다 | 지문을 찍고, 리디자인 기준과 대조한다 |
| **손 편집 보존본** | `Checkbox (리디자인 · 2026-09-10 13:35)` (FRAME) | 디자이너가 세트를 직접 고쳤고 플러그인이 뜬 **그 그림** | **대조 기준.** 자동으로 지우지 않는다 |
| **손 사본** | `Checkbox(리디자인)` (COMPONENT_SET 또는 FRAME) | 디자이너가 "이것과 비교하라" 고 직접 둔 것 | **대조 기준** — 보존본보다 우선 |
| 백업 | `Checkbox (이전 · 2026-09-10 13:35)` (FRAME) | 지문이 없어 판단할 수 없을 때 뜬 **어제의 생성본** | 세트당 하나만 남긴다. **대조하지 않는다** |

- **지문** — 플러그인이 세트를 그리고 나면 그 세트의 *보이는 값*(채움·보더가 있는 박스의 크기/모서리/색, 글자의 크기/굵기/행간/색, 아이콘의 글리프/크기/색)을 읽어 해시로 노드에 남긴다(`coui-canvas-fingerprint`). 지문은 **플러그인이 그린 직후에만** 찍는다 — 건너뛴 세트에 찍으면 손 편집된 상태가 기준이 되어 보존이 정확히 그 순간에 침묵한다.
- **덮어쓰기 전 보존 — 이유가 이름과 역할을 가른다.** 다시 그릴 세트의 지금 지문이 남긴 것과 다르면(그 사이에 손이 닿았다) 그 그림을 `<이름> (리디자인 · YYYY-MM-DD HH:mm)` 으로 세트 오른쪽에 복제하고, **그것이 대조 기준이 된다** — 디자이너가 세트를 직접 고친 것이 곧 리디자인의 의도이므로. 지문이 **없어** 손이 닿았는지 판단할 수 없었으면 그 그림은 어제의 생성본일 뿐이라 `<이름> (이전 · …)` 백업으로만 남고 대조에서 빠진다(기본은 뜨지 않고 개수만 보고 — `지문 없는 세트도 보존(첫 실행)` 을 켜면 뜬다). 복제는 인스턴스를 만들어 **안쪽까지 detach** 한 프레임이다: 컴포넌트를 복제하면 라이브러리에 같은 이름의 세트가 둘 생기고, 인스턴스로 두면 마스터가 다시 그려질 때 같이 바뀌어 "이전" 을 보존하지 못한다.
- **백업은 세트당 하나, 손 편집 보존본은 지우지 않는다** — 백업은 어제의 생성본이라 더 최근의 것이 생기면 값이 없어 대체한다(실행마다 쌓이면 페이지가 백업으로 덮인다). 반면 손 편집 보존본은 디자이너가 실제로 그린 것이므로 자동으로 지우면 이 기능이 막으려던 사고(손 편집이 흔적 없이 사라짐)를 이 기능이 저지른다. 이유를 알 수 없는 옛 스냅샷도 남긴다 — 손 편집이었을 수 있다.
- **리디자인 대조** — 세트를 그린 뒤 같은 페이지의 리디자인 기준과 변형 이름으로 짝을 지어 값 차이를 로그에 낸다(`⇄`). 기준의 순위는 **손 사본 > 손 편집 보존본**(사본은 디자이너가 "이것이 기준" 이라고 직접 둔 것이다). 손 사본 이름은 `<이름>(리디자인` 으로 시작하고 **괄호 앞 공백은 선택**이며, 옛 표기 `(디자이너…)` 도 받는다(캔버스에 이미 그 이름으로 둔 사본이 조용히 후보에서 빠지면 어제까지 되던 대조가 멈춘다). 같은 차이가 여러 변형에 반복되면 한 줄로 접는다. **이 줄이 "차이 없음" 인 것은 대조가 읽는 값이 기준과 같다는 기계적 정의다** — 대조가 읽지 않는 축(아래 "못 보는 것")은 사람이 본다. 기준이 **없으면** `⇄ <이름>: 리디자인 사본 없음 — 세트를 직접 고쳐 반영하거나, 같은 페이지에 "<이름>(리디자인)" 을 두면 대조한다` 한 줄을 낸다 — 침묵은 "차이 없음" 과 화면에서 구별되지 않는다. 그리지 않고 대조만 하려면 컴포넌트 탭의 **리디자인 대조** 버튼.

**판정은 이름이 아니라 이유로 한다.** 지문 없이 뜬 백업과 오늘의 생성본을 대조하면 나오는 수는 "코드가 어제와 얼마나 달라졌나" 이지 "리디자인과 얼마나 다른가" 가 아니다 — 리디자인 직후에는 그 수가 전 변형이 되고, 그것은 결함의 수가 아니다(실제로 `192/192 다름` 이 그렇게 나왔다). 이름은 사람이 바꿀 수 있으므로 스냅샷은 뜬 이유를 노드에 함께 남기고(`coui-snapshot-reason`) **그 값만** 기준 자격을 준다 — 이유를 알 수 없는 옛 스냅샷은 후보가 아니다(`pickDesignerFrame`). 기준이 여럿이면 손 사본은 이름 정렬의 마지막, 보존본은 스탬프가 최신인 것을 쓰고 나머지는 첫 줄에 후보로 적는다.

**사본 신선도** — 다른 파일에서 붙여 넣은 사본은 텍스트에 변수 바인딩이 하나도 없고(`textStyleId` 도 없다) 자간이 0 으로 읽힌다. 사본의 TEXT 노드 중 fontSize/letterSpacing 이 변수에 묶인(또는 텍스트 스타일이 붙은) 것이 0 이면 대조 첫 줄 아래에 `⚠ 사본이 로우 텍스트(변수 바인딩 0/N) — 자간·크기 축의 차이는 붙여넣기에서 잃은 값일 수 있다` 를 적는다. 그런 사본에서 나온 자간·크기 차이는 결함이 아니라 붙여넣기가 잃은 값일 수 있다 — 다른 축(획·보더·색·크기 비율)만 신뢰한다.

**전체 결과는 JSON 으로도 내려온다.** 로그의 `⇄` 는 세트당 14 줄에서 잘리지만(사람이 읽는 창의 크기), 결함 목록은 그보다 길 수 있다. 그래서 Generate 끝에도, **리디자인 대조** 버튼에서도 `designer-parity-<UTC>.json` 을 내려보낸다(`fidelity-*.json` 과 같은 경로 — 자동 다운로드 + 로그 끝의 링크). 봉투는 `{ kind: "coui-designer-parity", schema: 1, capturedAt, fileKey, sourceHash, sets: [...] }` 이고, `sets[]` 의 각 항목은 `name · page · designerFrame(없으면 null) · freshness{textNodes, boundTextNodes, hint} · compared · differing · onlyDesigner · onlyGenerated · lines[{variant, designer[], generated[]}]` — `lines` 의 서술자는 로그와 같은 원문이고 상한이 없다. 봉투의 키 이름은 이것을 읽는 쪽의 계약이라 그대로 두고, 화면에 보이는 라벨만 `리디자인` 이다. 사본이 세트 자신의 인스턴스라 대조를 건너뛴 항목만 `skipped` 에 그 이유를 추가로 든다. 이 파일을 읽는 쪽(결함을 코드로 옮기는 작업)은 로그가 아니라 이것을 본다.

Generate 끝과 대조 버튼 끝에는 요약 한 줄이 붙는다 — `⇄ 요약: 대조 N 세트 · 차이 0 → M 세트 · 차이 있음 K 세트 · 사본 없음 J 세트` (건너뛴 세트가 있을 때만 `· 건너뜀 S 세트` 가 뒤에 붙는다).

대조는 경로가 아니라 값의 다중집합으로 한다 — 리디자인 프레임과 빌더의 트리는 구조가 달라(디자이너는 `trigger/value`, 빌더는 `TextField/field/input/Placeholder`) 경로로 짝을 지으면 전부 "없음" 이 된다. 숨은 노드는 하위 트리째 빠진다. 변형 이름은 축을 정렬해 비교하고(축 순서는 세트마다 다르다), 인스턴스 멤버는 이름이 아니라 축 값으로 읽는다(같은 파일 복사·붙여넣기는 멤버를 전부 `Button` 이라는 이름의 인스턴스로 만든다).

대조가 **보는 방식**: 채움·보더의 변수 바인딩은 **변수 이름**으로 비교한다 — 같은 색이라도 다른 변수에 묶였으면 차이이고, 바인딩 대 raw hex 도 차이다. **못 보는 것**: 패딩·간격이 전부 0 인 오토레이아웃 래퍼(래퍼 수는 양쪽이 다르고 그림의 차이가 아니다), 효과(shadow), 노드의 절대 위치, 채움도 보더도 없는 래퍼의 크기.

기준 프레임이 **세트 자신의 인스턴스**로 만들어졌으면 대조하지 않고 그 이유를 적는다 — 인스턴스는 마스터를 그대로 비추므로 재생성 직후 언제나 "차이 없음" 이 되어, 초록이 아무것도 뜻하지 않게 된다. 그런 사본은 선택해 detach 한다(우클릭 → Detach instance).

**지문은 대조와 다른 수집기를 쓴다.** 대조는 구조가 다른 두 트리를 견주므로 느슨해야 하지만, 지문은 같은 노드를 자기 과거와 견주므로 정밀하다 — 숨은 노드·효과·blend·정렬까지 싣고 변수는 이름이 아니라 **id** 로 싣는다(토큰 rename 에 흔들리지 않게). 대신 두 가지를 뺀다: **인스턴스 안은 오버라이드만** 읽고(자식 세트가 먼저 다시 그려지면 부모의 캔버스 값이 손이 닿지 않아도 움직여, 공유 코드가 바뀐 실행마다 합성 세트 전부가 "손 편집" 으로 잡힌다), **기하는 저작된 것만** 싣는다(오토레이아웃 안의 위치·크기는 파생값이라 자식이 커지기만 해도 움직인다 — `layoutSizing` 이 `FIXED` 인 축만 싣는다).

**잔해를 정리한 직후 첫 실행의 🛡 손 편집 감지는 거짓일 수 있다.** 오래된 탭의 늦은 동기화가 세트 안에 끼운 옛 노드(겹친 형제 보기 · 고아 노드 보기가 세는 것)를 손으로 지우면 그 세트의 캔버스 지문이 바뀌고, 다음 실행은 규칙대로 그것을 손 편집으로 읽어 `(리디자인 · …)` 보존본을 뜬다 — 그 보존본은 디자이너 의도가 아니라 **손상된 캔버스의 사본**이라 두면 매 실행 가짜 차이를 보고한다. 정리 뒤 첫 실행이 뜬 보존본은 디자이너에게 확인하고 지운다.

**지문은 다시 그린 세트에만 남는다.** 해시가 같아 건너뛴 세트에는 찍지 않는다 — 건너뛴 세트에 찍으면 손 편집된 상태가 기준이 되어 보존이 정확히 그 순간에 침묵하기 때문이다. 그래서 기존 파일에서 보존을 전 세트에 켜려면 `지문 없는 세트도 보존` 을 켜고 **전체 새로 생성을 한 번** 돌려야 한다. 그 전까지 아직 다시 그려지지 않은 세트는 손 편집 여부를 알 수 없어 개수만 보고된다.

### 다시 그려도 안쪽 노드를 유지한다 (`src/redraw-keep.ts`)

인스턴스가 메인의 안쪽 레이어에 덮어쓴 값(디자이너 사본의 Button 안 ✕ 색, Toggle 글자 색)은 그 레이어의 **노드**에 붙어 있다. 실측: 메인의 기존 자식을 제자리에서 고치면(크기 · 채움) 인스턴스의 덮어쓰기와 중첩 id 가 그대로 남고, 자식을 지우고 같은 자식을 새로 만들면 덮어쓰기가 풀리고 id 가 바뀐다. 그래서 반영은 멤버의 자식을 지우지 않는다.

- **리셋** 은 멤버의 옛 자식을 숨겨 제자리에 두고, 빌더는 그 옆에 새로 그린다. 숨긴 자식은 오토레이아웃에 들어가지 않는다(실측: 숨김 → 같은 이름 형제 추가 · 삭제 → 다시 보이기, 그리고 순서 바꾸기 모두 인스턴스 덮어쓰기가 남는다). **`visible` 이 컴포넌트 속성에 묶인 자식은 숨기지 않는다** — 메인에서 묶인 레이어에 `visible` 을 쓰면 거부되지 않고 그 BOOLEAN 의 기본값이 바뀐다(실측). 그런 자식은 투명하게(`opacity = 0`) 하고, 멤버가 오토레이아웃이면 흐름 밖으로(`layoutPositioning = ABSOLUTE`) 뺀다(실측: INSTANCE · RECTANGLE 모두 거부되지 않고, 되돌린 뒤 속성 기본값 · 인스턴스의 속성 값 · 덮어쓰기가 그대로다). 둘 중 하나라도 거부되면 예전처럼 지우고 `bound-visible` 로 센다. 대조도 묶인 `visible` 에는 쓰지 않는다 — 다르면 그 하위 트리를 교체한다. 빌더가 이름 · 표식으로 자기 레이어를 찾는 자리(서페이스 재질 레이어)는 숨긴 자식을 건너뛴다.
- **대조** — 엔트리가 다 그린 뒤(틴트 · 텍스트 스타일이 새 노드에 붙은 뒤, 지문과 재조립 전), 옛 자식을 같은 타입 · 이름의 새 자식과 짝짓는다. 두 트리의 모양(타입 · 이름 · 자식 수, 인스턴스는 같은 메인과 같은 scale)이 같으면 새 트리가 가진 값을 옛 트리에 쓰고, 옛 트리를 다시 읽어 새 트리와 비교한다. 같으면 옛 노드가 남고 새 노드는 지운다. 모양이 다르거나, 쓰기가 거부되거나, 다시 읽은 값이 다르면 **그 하위 트리는 새것으로 바뀐다** — 예전 리셋과 같은 결과다. 판정 단위는 멤버의 최상위 자식이다.
- **옮기는 값** — 가시성 · 잠금 · 불투명도 · blend · 마스크 · 클립, 채움 · 보더(바인딩 포함 — 처음 쓰면 세기가 100% 로 돌아가는 바인딩 페인트는 두 번 쓴다) · 보더 두께(변마다) · 정렬 · 끝 · 대시, 모서리(모서리마다 · 스무딩), 효과, 그리드, export 설정, 오토레이아웃(방향 · 줄바꿈 · 간격 · 패딩 · 정렬 · z 순서 · 보더 포함), 벡터 경로 · 호 · 별/다각형 · 불리언 연산, 글자(글꼴 · 크기 · 행간 · 자간 · 대소문자 · 장식 · 문단 · 정렬 · 말줄임 · 줄 수 · 내용 · 텍스트 스타일), 공유 스타일(효과 · 채움 · 보더 · 그리드), 크기(`resizeWithoutConstraints`) · sizing 모드 · `textAutoResize` · `layoutSizing*` · `layoutAlign` · `layoutGrow` · 최소/최대 · constraints · `layoutPositioning` · `relativeTransform` · x/y, 변수 바인딩(`boundVariables`), 명시 변수 모드, 인스턴스의 컴포넌트 속성 값과 그 안 레이어의 값, 플러그인 데이터, 속성 참조. `width` · `height` · `scaleFactor` · `isExposedInstance` 는 읽어서 비교만 한다.
- **한 값으로 옮길 수 없는 것은 교체한다** — `figma.mixed`(모서리 · 보더 두께처럼 다른 필드가 부분을 진술하는 것은 건너뛴다), 범위마다 다른 바인딩, 범위마다 다른 글자 서식은 한 값으로 옮길 수 없으므로 교체한다.
- **보류 중인 세트의 참조** — 멤버가 세트 밖에 있는 동안 기록된 속성 참조는 남는 노드로 옮겨지고, 그 멤버를 세트에 스테이징해 쓴다(세트 밖 멤버의 레이어는 세트의 속성 id 를 받지 못한다). 바인드 뒤에 할 일(교체 아이콘 크기 되돌리기)도 남는 노드를 가리킨다.
- **유지하지 않는 곳** — 큰 세트(멤버 64 초과)가 이미 조립된 채 대조에 이르면(한 엔트리가 세트를 둘 마운트해 앞 세트가 먼저 조립된 경우, 즉시 재조립 모드) 그 세트 안에 쓰는 값이 세트 크기만큼 비싸므로 옛 자식을 지운다(예전 리셋). 엔트리가 실패하면 옛 자식은 숨은 채 남고, 다음 실행이 그것부터 짝짓는다.
- **로그** — 느린 엔트리의 `⏱` 첫 줄 끝에 ` · 유지 kept N / replaced M (시간; 이유별 수)`, 그 밖의 엔트리는 교체가 있을 때만 `↺ <이름>: 안쪽 노드 · 유지 …` 한 줄, 실행 끝에 `↺ 다시 그린 멤버의 안쪽 노드: kept N / replaced M`. `replaced` 는 그 레이어에 걸린 인스턴스 덮어쓰기가 풀렸을 수 있다는 뜻이다.

같은 이름의 그 레이어가 남는지를 정하는 것은 노드뿐이다 — 바인드가 교체 아이콘의 메인을 기본값으로 바꾸는 자리처럼 지난 실행의 최종 상태와 이번 실행의 그리기 직후 상태가 다른 레이어는 메인이 달라 교체된다. 반영을 끄려면 `generateComponents(..., { keepInnerNodes: false })`.

### 낡은 세트 보기 (`src/stale-sets.ts`)

**머지·빌드가 끝나도 캔버스는 그 세트를 다시 그리기 전까지 옛 코드다.** PR 이 main 에 들어가고 번들이 다시 빌드돼도, 캔버스의 세트는 마지막 Generate 가 그린 코드 그대로 서 있다. 실제로 한 컴포넌트의 결정 세 건이 머지된 채 캔버스에 없었고, 그 사실을 말해 주는 것이 아무것도 없었다 — 알 수 있는 유일한 길이 Generate 를 돌려 `✓ built` 와 `⏭ skipped` 를 세는 것이었는데, 그건 답을 얻으려고 그리는 일이다.

컴포넌트 탭의 **낡은 세트 보기** 버튼은 그리지 않고 그 질문에 답한다. 읽기 전용이고 선택이 필요 없다 — 질문이 "선택한 것이 낡았나" 가 아니라 "캔버스 중 무엇이 낡았나" 라 전체를 봐야 답이 나온다. 레지스트리 엔트리마다 캔버스에서 그 이름의 세트를 찾아 `coui-content-hash` 를 읽고, 현재 코드의 해시와 대조해 셋으로 나눈다:

- **current** — 스탬프가 현재 코드와 같다. 다음 Generate 가 `⏭ skipped` 할 세트.
- **stale** — 세트는 있는데 스탬프가 다르거나 비어 있다. 다음 Generate 가 다시 그릴 세트. 빈 스탬프도 여기다 — Generate 가 docs 프레임에 실패한 세트의 스탬프를 일부러 비워 두므로(다음 실행에 다시 그리라고), 그건 "없음" 이 아니라 "낡음" 이다.
- **absent** — 그 이름의 COMPONENT / COMPONENT_SET 이 문서 어디에도 없다. 한 번도 그린 적 없거나, 손으로 지웠거나, 페이지가 강등돼 있다.

로그는 `낡은 세트 K / 전체 N — Select, Chip, Foo, Bar, Baz, … (+K-5)` 한 줄과 `없음 M — …` 한 줄이고, 낡은 세트가 0 이면 `캔버스 = 현재 코드 ✅ (전체 N)`. 이름은 5 개까지만 적고 나머지는 `… (+나머지 수)` 로 접는다 — K/N/M 자체는 항상 전체 레지스트리 기준 정확한 개수이고, 접히는 건 이름 나열뿐이다(아래 문단대로 재빌드 직후엔 K 가 전체나 다름없어, 접지 않으면 이 한 줄이 컴포넌트 100여 개 이름이 된다). 같은 문장이 **Generate 의 끝에도** 붙는다 — 부분 실행(섹션 하나, 체크한 몇 개)은 시킨 것만 그리고 `Done` 이라고 말하는데, 그 단어는 나머지 세트가 아직 머지 전 코드라는 것을 말하지 않기 때문이다. 이 요약이 실패해도 실행 로그 자체는 남는다 — 부가 정보이지 실행 결과가 아니라서, Generate 는 이 한 줄을 만드는 중 던진 에러를 삼키고 경고 한 줄로 바꾼다.

**"현재 코드와 같은가" 의 정의는 하나다.** `entryContentHashOf`(엔트리가 그려지는 소스의 import 닫힘 해시 + 그 컴포넌트의 데이터 서브트리)와 그 키(`coui-content-hash`)는 `src/content-hash.ts` 한 곳에 살고, Generate 의 스킵 판정과 이 목록 양쪽이 그것을 **import** 해서 쓰지 어느 쪽도 레시피를 다시 적지 않는다. 예전에는 이 레시피가 `generate.ts` 에 있고 `stale-sets.ts` 가 그걸 다시 import 하는 순환이었는데, 그 역방향 간선 때문에 번들러가 둘 중 어느 파일을 먼저 평가하는지에 결과가 갈렸다(생산 코드의 순서에선 되고, 반대 순서로 로드한 셀프테스트에선 조용히 `undefined` 가 되는 식). 재적으면 두 레시피가 되고, 한쪽이 편집되는 순간 이 목록은 다음 Generate 가 다시 그릴 세트를 "현재" 라고 답한다(또는 그 반대) — 그 상태는 아무 증상 없이 초록으로 보인다. `npm run selftest:stale-sets` 가 그 동일성을 함수 정체성으로, 그리고 소스 파일들의 텍스트로 단언한다(`content-hash.ts` 의 `build.toString()` 결합은 정확히 한 곳, `generate.ts`/`stale-sets.ts` 에는 해싱이 0, 그리고 Generate 의 로그 tail·`code.ts` 의 메시지 라우팅·`ui.html` 의 버튼 배선까지).

**플러그인을 다시 빌드하면, 고친 파일이 닿는 엔트리만 낡음으로 읽힌다.** 엔트리의 소스 해시는 번들 단계(`scripts/entry-source-hash.mjs`)가 esbuild 의 import 그래프로 계산해 번들에 구운 표(`__ENTRY_SOURCE_HASHES__`, 키는 `registry.ts` 의 `SOURCE_GROUPS`)에서 온다. 한 엔트리의 해시는 **세 갈래의 소스 텍스트**다 — 그 엔트리 배열이 놓인 모듈과 그것이 (전이적으로) import 하는 모듈, 생성기가 모든 엔트리에 적용하는 파이프라인(`text-style-attach` · `docs-frames` · `swap-default-repair` · `unbound-props` 의 닫힘), 그리고 `generate.ts` 의 텍스트 — 여기에 `needs` 로 인스턴스를 만드는 엔트리들의 같은 해시가 든다. 번들 출력(`Function.prototype.toString`)이 아니라 **소스 파일의 텍스트**를 해시하므로 다른 모듈이 추가되거나 최상위 이름이 겹쳐도 값이 움직이지 않는다. 그래서:

- 빌더 모듈 하나(`components/foo.ts`)만 고치면 그 모듈을 닫힘에 가진 엔트리만 낡아지고, `helpers.ts` 처럼 모든 엔트리가 import 하는 공유 그리기 코드나 `generate.ts` 를 고치면 전부 낡아진다.
- 빌더가 그림에 쓰지 않는다고 선언한 모듈(`entry-source-hash.mjs` 의 `kNonDrawingModules` — 읽기 전용 보기 · 실행 잠금 · 마지막 단계 · 대조 · 로그 문구)을 고치면 아무것도 낡아지지 않는다. 선언한 경로가 그래프에 없으면 번들이 실패한다.
- `src/data/icons.json` · `icon-keys.json` 은 `icon-nodes.ts` 가 import 하므로 닫힘 안이다. `components.json` 은 닫힘 밖이고 엔트리 데이터 해시가 컴포넌트 단위로 맡는다.
- 닫힘을 계산하지 못한 키(동적 import · 번들 밖 외부 모듈)와 하네스(`tsx`, define 없음)의 엔트리는 **플러그인 전체 해시(`kSharedSourceHash`)로 되돌아간다** — 과잉 무효화는 맞게 그려진 세트를 다시 그릴 뿐이고 과소 무효화는 어긋난 캔버스를 완성처럼 보이게 한다. `npm run build` 는 닫힘을 구한 키 수와 폴백 수를 로그에 적는다.

그래서 이 버튼으로 특정 컴포넌트의 반영 여부를 물을 자리는 **그 엔트리가 닫힘에 가진 파일을 고친 빌드 직후가 아니라 Generate 직후**다 — 빌드 직후의 답은 "다음 Generate 가 무엇을 다시 그리나" 이지 "무엇이 눈에 띄게 달라졌나" 가 아니다. `npm run selftest:entry-hash` 가 무관한 파일 수정은 해시를 안 움직이고 닫힘 안 수정은 움직이는 쌍, 이름이 겹쳐도 해시가 안 움직이는 것, 간선을 빼는 회귀 주입이 이를 실패시키는 것을 단언한다.

**보지 못하는 것**: 해시는 *레시피* 의 동일성이지 *캔버스* 의 동일성이 아니다. 손으로 고친 멤버, 중간에 끊긴 실행, 버전 히스토리에서 되돌린 파일은 스탬프가 그대로라 여기서 **current** 로 나온다 — 그쪽은 지문(위 절)과 **전체 새로 생성** 의 몫이다. 이 목록이 답하는 것은 정확히 "코드가 움직였는데 캔버스가 안 따라온 세트" 하나다.

### 고아 노드 보기 (`src/orphan-nodes.ts`)

`figma.createFrame()` / `instanceOf()` 은 부모에 붙기 전까지 **현재 페이지의 (0,0)** 에 떨어진다. 그래서 빌더가 만들어 놓고 어디에도 붙이지 않은 조각은 정확히 한 모양으로 남는다 — 페이지 직계 · 원점 · `field` / `nav` / `popover panel` 처럼 컴포넌트 **내부** 이름. 세트 밖이라 어떤 변형에도 들어가지 않아 **렌더에는 영향이 없고, 바로 그래서 아무 로그도 그 사실을 말하지 않는다.** 실제로 일곱 컴포넌트에 걸쳐 21 개가 쌓여 있었고 발견 방법은 사람이 페이지를 손으로 훑는 것이었다. 그중 하나는 모드 탭 · 채도 판 · 색상 슬라이더까지 완전히 채워진 패널이었는데, 세트 안에는 현재 코드가 그린 다른 판이 멀쩡히 들어 있었다 — 만들어서 다 채운 뒤 버려진 것이다.

컴포넌트 탭의 **고아 노드 보기** 버튼은 그것을 그리지도 지우지도 않고 센다. 읽기 전용이고 선택이 필요 없다 — 낡은 세트 보기와 같은 이유로, 질문이 "선택한 것이 흘렸나" 가 아니라 "이 문서에 무엇이 떠 있나" 이기 때문이다. 판정은 네 줄이고 순서까지 그대로다:

```
페이지가 '❖ ' 로 시작   (빌더가 그리는 페이지만 — 아래 참조)
  AND  페이지 직계  AND  type ∉ {COMPONENT_SET, COMPONENT}
  AND  이름이 '_Docs' 로 시작하지 않음
  AND  이름에 리디자인 / 디자이너 / 이전 없음      (디자이너 사본 제외)
  AND  x == 0 AND y == 0                        (붙인 적 없다는 신호)
```

**첫 줄이 없으면 원점 조건이 거짓말을 한다.** 사람이 그린 Foundation / Overview 페이지는 콘텐츠 프레임(`Foundation / 01. Color — CoUI` 류 1680×N)을 **(0,0) 에 놓는다** — 그 페이지에서는 그게 자연스러운 자리다. 페이지를 거르지 않으면 이 문서에서만 오탐 10 건이 나고, 0 이 정상값인 목록이 매번 10 으로 시작하면 그 줄은 곧 읽히지 않는다. 반대로 빌더가 그리는 페이지에서 (0,0) 은 **아무것도 놓지 않는 자리**다: 세트는 (120,120) 에, docs 프레임과 디자이너 사본은 그 옆에 놓인다. 흘린 조각이 거기 말고 갈 곳이 없는 이유도 같다 — `figma.createFrame()` 은 `figma.currentPage` 에 떨어지고, 실행 중 그 페이지는 언제나 그 컴포넌트의 페이지다(발견된 21 개가 전부 그랬다). 페이지 이름 접두는 `data.ts` 의 `kComponentPageNamePrefix` 가 소유하고 `componentPageNameOf` 가 그것으로 이름을 만든다.

`COMPONENT` 제외는 원점 조건이 어차피 거르기 때문이 **아니라** 규칙이 자기 의도를 말하게 하려는 것이다. 변형 축이 없는 컴포넌트는 세트가 아니라 맨 `COMPONENT` 로 페이지 직계에 그려지는 것이 정상이고(이 문서에 47 개), `mountSet` 이 큰 세트를 그리는 동안 세트 **옆**에 파킹하는 멤버도 `COMPONENT` 다 — 둘 다 고아가 아니며 타입 조건과 원점 조건 양쪽에서 걸러진다.

로그는 `고아 노드 K / 페이지 N — ❖ Label: icon, Icon · ❖ Filter: reset, … (+M 페이지)` 한 줄이고, 없으면 `고아 노드 없음 ✅ (페이지 N)`. 접히는 축이 둘(페이지 안의 이름 · 페이지 묶음)이라 페이지 축만 단위를 적는다 — 같은 줄에서 둘이 똑같이 `… (+N)` 으로 접히면 무엇이 접혔는지 읽을 수 없다. **K 와 N 은 접히지 않는다.** 같은 문장이 **Generate 의 끝에도** 붙고, 그 자리가 이 검출기의 본론이다 — 새는 순간 그 실행이 스스로 말한다. 요약이 실패해도 실행 로그는 남는다(낡은 세트 요약과 같은 취급). 스캔 직전에 `last-step` 에 `orphan-scan` 을 찍는데, 마커가 없으면 여기서 죽은 실행이 "마지막 엔트리를 그리다 죽었다" 로 읽혀 무로그 사망 조사의 해상도를 흐리기 때문이다. `run:done` 은 여전히 그 뒤에 찍혀 종료 상태로 남는다.

**판정 어휘는 이 파일이 갖지 않는다.** `_Docs` 접두는 `docs-frames.ts` 가, 사본 낱말은 `designer-parity.ts` 가 소유하고 검출기는 import 만 한다. 여기서 다시 적으면 두 번째 어휘가 되고, 표기가 하나 늘어나는 날 **디자이너의 파리티 스냅샷이 고아로 신고된다** — 그건 "지우세요" 로 읽힌다. `npm run selftest:orphan-nodes` 가 그 포함 관계(소유자 파일의 사본 접두 리터럴이 남김없이 공유 목록에 담기는지)와 네 배선점(버튼 · 핸들러 · 메시지 · Generate 꼬리)을 소스 텍스트로 단언한다.

**보지 못하는 것 / 지우지 않는 이유**: 세 가지다. ① 페이지 **직계**만 본다 — 세트나 프레임 **안**에 잘못 붙은 조각은 시야 밖이고, 그건 다른 그물이 필요한 다른 실패다. ② `❖ ` 페이지만 본다 — 빌더가 다른 페이지에 흘리는 경로가 생기면 놓친다(오늘은 그런 경로가 없다는 것이 21 개의 위치로 확인됐을 뿐이다). ③ 원점 조건은 **관측이지 증명이 아니다** — 페이지를 거른 뒤 이 문서에서 오탐이 0 이라는 것이지, 누군가 `❖ ` 페이지의 (0,0) 에 무언가를 두면 오탐이다. 그래서 이 버튼은 **세기만 한다.** 지우는 기능을 붙이자는 제안이 오면 legacy 페이지 제거가 지키는 3단 계약(비어 있지 않으면 남기고 경고 · 현재 페이지면 먼저 비켜서기 · 제거는 로그)을 따라야 하고, 그건 별도 결정이다.

### 겹친 형제 보기 (`src/overlapping-siblings.ts`)

오래 열려 있던 Figma 탭이 며칠 뒤 다시 연결되면 멀티플레이어가 그 탭이 그때 쓴 것을 **삭제 없이 추가로** 병합한다. 쓰기가 붙을 변형 노드가 같은 id 로 남아 있으면, 변형 안에 옛 세션의 자식이 같은 이름으로 **한 벌 더** 들어간다 — 위치만 어긋나 살짝 겹쳐 보일 뿐이고 아무 로그도 말하지 않는다. 실제로 13 세트 · 486 노드가 그렇게 들어가 있었고 찾은 것은 디자이너의 눈이었다. 실행 잠금은 이걸 막지 못한다 — 동시 실행이 아니라 늦게 도착한 쓰기다.

컴포넌트 탭의 **겹친 형제 보기** 버튼은 그것을 그리지도 지우지도 않고 센다. 판정: 세트 변형마다 **직계 자식만** 이름으로 묶어(세트가 아닌 페이지 직계의 **느슨한 컴포넌트** — Menu · DropdownMenu · Drawer · Popover 류 — 는 자기 직계 자식을 변형 하나로 본다. 실제 사고에서 번진 원인이 그 쪽 마스터였다), 한 이름에 둘 이상이고 id 대역(콜론 앞 숫자 — 노드를 만든 세션의 흔적)이 갈리면 최신 대역이 아닌 쪽을 센다. 같은 세션이 만든 정당한 반복(`item` × 4)은 대역이 같아 빠진다. 로그는 `겹친 형제 K / 세트 N — MenuItem: 270 · Fab: 138 · … (+M 세트)` 이고, 없으면 `겹친 형제 없음 ✅ (세트 N)`. 같은 문장이 Generate 끝에도 붙는다(스캔 직전 `last-step` 에 `overlap-scan`).

**같은 잔해는 세 층에 남고, 이 버튼은 그중 하나만 본다**: 변형 직계는 여기, 페이지 직계는 **고아 노드 보기**, 중첩 인스턴스의 프로퍼티(오버라이드 값이 병합된 것 — 노드가 아니라 이름·대역으로 안 보인다)는 **재생성만**이 걷는다. 대역 비교도 관측이지 증명이 아니라 **세기만 한다** — 지우는 것은 그 세트를 다시 반영하는 것(`resetNode` 가 변형 자식을 전부 걷고 다시 그린다) 또는 사람의 결정이다.

**되감김 경고** — 그 병합은 `last-step` 발자국도 옛 값으로 되돌린다(실제로 그게 첫 단서였다). 그래서 끝난 실행은 `last-done` 에 자기 `run:done` 시각을 남기고, 다음 실행은 시작할 때 `last-step` 이 그보다 과거면 `⚠ last-step 가 되감겼다 …` 한 줄을 낸다. 막지는 않는다 — 플러그인은 다른 클라이언트의 탭을 볼 수 없고, **오래된 탭을 닫는 것**이 유일한 근본 예방이다.

### 프로퍼티 orphan 보기 (`src/orphan-props.ts`)

컴포넌트가 프로퍼티를 **선언만 하고 어느 노드도 참조하지 않으면** Properties 패널에 손잡이가 보이는데 토글해도 아무 일이 일어나지 않는다. 오류 없이 조용히 아무것도 안 하는 형태라, 그동안의 발견 경로는 디자이너가 그 손잡이를 실제로 쓰려다 "왜 안 되지" 로 만나는 것뿐이었다.

**빌더가 만드는 orphan 은 이미 CI 가 막는다** — `selftest-registry-runtime` 의 props drill 이 빌더를 Node 더블에 구동해 참조되지 않는 프로퍼티를 거부한다. 하지만 그 그물은 라이브 파일을 읽지 않으므로 **캔버스에 손으로 붙은 프로퍼티**는 보지 못한다. 컴포넌트 탭의 **프로퍼티 orphan 보기** 버튼이 그 나머지 절반이다. 읽기 전용이고 선택이 필요 없다.

```
소유자 = 모든 페이지 직계의 COMPONENT_SET / COMPONENT   (디자이너 사본 제외)
orphan = componentPropertyDefinitions 의 non-VARIANT 키 중
         소유자 하위 트리 전체(중첩 인스턴스 안쪽 포함)의
         componentPropertyReferences 값 어디에도 없는 것
```

고아 노드 보기와 달리 `❖ ` 페이지로 거르지 않는다 — 찾는 것이 바로 빌더 밖에서 손으로 만든 컴포넌트다. 사본 낱말은 `designer-parity.ts` 가 소유하고 여기는 import 만 한다(사본은 원본의 프로퍼티를 복제해 같은 orphan 을 두 번 세게 만든다).

로그는 없으면 `프로퍼티 orphan 없음 ✅ (컴포넌트 N · 프로퍼티 M)`, 있으면 `⚠ 프로퍼티 orphan K (기대 0) / 컴포넌트 N · 프로퍼티 M — FormField: Show label, …` 한 줄이다. **기대값은 0** 이고(`kExpectedOrphanProps`), 캔버스는 CI 가 읽지 못하므로 ratchet baseline 을 코드에 둘 수 없어 기대값을 로그에 싣고 어긋나면 `⚠` 로 로그창을 경고색으로 만든다. 정의 접근 자체가 던지는 세트(두 멤버가 같은 조합을 주장해 "Component set has existing errors" 상태가 된 것)는 실행을 멈추지 않고 `⚠ 읽을 수 없는 컴포넌트 K — …` 줄로 따로 센다 — 그 자체가 별도로 고쳐야 할 결함이다.

Generate 꼬리에는 붙이지 않는다. 이 순회는 전 세트의 전 멤버 하위 트리를 도는데, 질문이 "이번 실행이 흘렸나" 가 아니라 "캔버스에 손으로 붙은 것이 있나" 라서 실행 직후에 물을 이유가 없고, Generate 끝의 비용은 실측으로 추적되는 자리다.

`npm run selftest:orphan-props` 가 Node 더블로 양성(심은 orphan 을 잡는다) · 음성(참조된 것은 통과) · 중첩 인스턴스 추적 · 던지는 세트의 격리, 그리고 다섯 배선점(버튼 · 핸들러 · 메시지 · 비활성 목록 · selftest 체인)을 단언한다. **보지 못하는 것**: 페이지 직계가 아닌 곳(프레임 안)에 놓인 컴포넌트, 그리고 참조가 **맞는 노드**를 가리키는지 — 이 검출기는 "누군가 참조하는가" 까지만 본다.

### 미연결 속성 정리 (`src/unbound-props.ts`)

Figma 게시 창은 **어떤 레이어도 `componentPropertyReferences` 로 참조하지 않는 속성**(BOOLEAN ·
TEXT · INSTANCE_SWAP)이 하나라도 있는 세트를 **아무 표시 없이** 목록에서 뺀다. 새 세트는 한 번도
발행되지 않고 발행된 세트는 그 뒤 수정이 소비 파일에 닿지 않는데, 어디에도 신호가 없다 —
열두 세트가 그렇게 멈춰 있었다(#5323). 그 속성은 빌더가 만든 것이 아니라 재활용된 세트가 들고
있는 잔재다(`defineProp` 은 지우지 않는다): 디자이너가 손으로 붙인 것, 이름에
`(deprecated · …)` 를 달아 남긴 것, 빌더가 더는 그리지 않는 레이어의 것.

**판정 → 확인 → 제거**, 세트를 다시 조립한 직후 한 번(엔트리마다):

1. **판정** — 소유자가 선언한 non-VARIANT 속성 중 이번 실행에서 어떤 결선도 받지 않은 것이
   후보다. 결선은 `addPropRef` 를 거치는 순간 센다(같은 노드의 같은 필드를 다른 속성으로 다시
   결선하면 먼저 속성은 풀린다). 멤버 수에 비례하지 않는다 — 972 멤버 세트도 `componentPropertyReferences`
   를 되읽지 않는다.
2. **확인** — 후보가 있을 때만, 세트 전체 하위 트리(모든 변형을 합쳐서, 숨은 레이어와 중첩
   인스턴스 안쪽 포함)를 실제로 훑는다. 한 변형이라도 참조하면 연결된 것이다. 결선 기록이 놓친
   경로가 있어도 **지우는 쪽으로는 틀리지 않고**, 그 경우 `⚠ 결선 기록에는 없지만 레이어가 참조하는 속성`
   으로 말한다.
3. **제거** — `deleteComponentProperty`. 속성마다 로그 한 줄(`🧹 TextField: 어떤 레이어도 참조하지
   않는 속성 제거 — "Show label (deprecated · FormField로 이관)" (BOOLEAN, 기본값 true)`). 로그 없이
   지우는 경로는 없다. VARIANT 속성과 디자이너 사본(`(리디자인`…)은 대상이 아니고, 거부되면
   던지지 않고 `⚠ 미연결 속성이 남았다` 로 남는다.

그림은 변하지 않는다 — 참조하는 레이어가 없는 속성은 정의상 아무것도 움직이지 않는다. 소비
파일은 효과 없던 오버라이드 값 하나를 잃고 패널 손잡이가 사라질 뿐이고, 레이어가 쓰는 속성의
key 는 그대로라 그 오버라이드는 유지된다.

꼬리 줄 `미연결 속성 정리 — 다시 그린 N 세트 중 … · 남은 세트 0 ✅ (기대 0)` 가 게시 전에 눈으로 볼
수 있는 신호다(남으면 `⚠ 미연결 속성이 남은 세트 K (기대 0)`). **이번 실행이 다시 그린 세트만**
안다 — 해시가 같아 건너뛴 세트는 읽지 않으므로, 캔버스에 손으로 붙은 것까지 전수로 보려면
**프로퍼티 orphan 보기**를 쓴다. `Icon` 처럼 디자이너 소유 세트를 검증만 하는 엔트리
(`RegistryEntry.validateOnly`)는 대상이 아니다.

`npm run selftest:unbound-props` 가 순수 객체로 양성 · 음성 · 변형 합산 · 숨은/중첩 참조 · VARIANT ·
사본 · 같은 필드 재결선 · 거부 · 읽기 불가를 단언하고, `selftest:registry-runtime` 의 *unbound props drill* 이
(a) 모든 빌더가 선언한 속성을 전부 결선하는지, (b) #5323 이 실측한 열두 세트의 잔재를 그대로 심어 다시
그린 뒤 전부 지워지고 빌더의 속성 · key · 레이어 참조는 그대로인지 본다.

**INSTANCE_SWAP 기본값의 원격 사본** (`src/swap-default-repair.ts`) — `defineProp` 은 이미 있는 교체
기본값을 보존한다(디자이너의 선택일 수 있어서). 그 규칙이 라이브러리가 되가져온 **원격 사본**(로컬과 같은 key)
도 함께 보존해, 슬롯 기본값이 로컬 `Icon` 대신 게시본 사본을 가리킨 일이 있다(MenuItem). 엔트리를
그리기 **전에** 기본값을 열어 보고 `remote` 이면서 key 가 이 문서의 로컬 컴포넌트와 같은 것만
로컬로 되돌린다 — key 가 다른 원격 노드는 디자이너의 선택이라 건드리지 않는다.
`npm run selftest:swap-default-repair`.

### 고정폭 글의 한글 (`src/mono-hangul.ts`)

고정폭 서체(Geist Mono)에는 한글이 없다. 앱과 웹은 없는 글자를 본문 서체(Pretendard)로
대신 그리는데, Figma 는 대신할 글꼴을 고를 수 없어 편집기가 고른 글꼴로 그린다 — 그래서
코드 글 안의 한글이 캔버스와 코드에서 다르게 보인다. 플러그인은 한글 구간
(U+1100–11FF · U+3130–318F · U+AC00–D7A3)마다 글꼴을 본문 서체로 쓰고 `fontFamily` 를
본문 서체 변수에 묶는다. 크기 · 행간 · 자간은 건드리지 않는다 — 코드 역할의 21px 줄 격자가
고정폭인 이유이기 때문이다. 같은 일을 세 자리에서 한다:

- **빌더가 그리는 글** — `makeLabel` 이 고정폭으로 그린 라벨(문서 프레임의 코드 블록,
  코드 역할 라벨)의 한글 구간을 그 자리에서 칠한다.
- **텍스트 스타일을 붙인 직후** — 스타일은 노드의 모든 구간을 자기 글꼴로 되돌리므로,
  코드 역할 라벨은 붙인 직후(묶음을 푼 뒤, 지문을 찍기 전)에 다시 칠한다. 칠한 구간 수가
  `↻ 고정폭 라벨의 한글 구간 N개` 로 로그에 남는다.
- **소비 파일의 글** — 디자이너가 제품 파일에 쓴 글은 라이브러리를 다시 생성해도 닿지
  않는다. 브랜드 탭의 **한글 구간 칠하기** 가 선택(없으면 현재 페이지)의 TEXT 중 내보낸
  고정폭 서체로 그린 한글 구간을 칠한다. 본문 서체 변수는 이 파일의 로컬 변수에서, 없으면
  켜진 라이브러리의 `Primitives` 에서 가져온다. 다른 고정폭 서체로 쓴 글은 바꾸지 않고
  이름을 알려준다. 글을 고쳐 쓰면 새 글자가 옆 글자의 글꼴을 따르므로 다시 돌린다.

**실측하지 않은 것**: 텍스트 스타일이 붙은 노드의 일부 구간에 글꼴을 쓰면 그 구간이
스타일에서 갈라질 가능성이 높다(노드의 `textStyleId` 가 섞임으로 읽힌다). 그렇다면 그 뒤
`Code/*` 스타일을 고쳐도 한글 구간에는 닿지 않는다. 캔버스에서 재 보기 전까지는 이것을
보장으로 읽지 않는다. 붙인 뒤의 칠하기가 Figma 에 거부되면 그 라벨은 스타일을 유지한 채
한글만 고정폭에 남고, 로그에 `⚠` 한 줄로 나온다.

`npm run selftest:mono-hangul` 이 구간 나누기(섞인 글 · 한글만 · 한글 없음 · 이웃한 구간 ·
블록 경계 · 굵기), 칠하기가 쓰는 것과 쓰지 않는 것, 스타일을 붙인 뒤 다시 칠하는 순서, 명령의
범위와 본문 서체 해석을 단언한다. `selftest:registry-runtime` 의 docs 드릴은 한글이 든 코드
블록마다 칠한 구간이 한글 구간과 정확히 같은지 본다.

### 소비 파일 점검 (`src/consumer-audit.ts`)

관리 탭의 **소비 파일 점검**은 제품 화면 파일(이 라이브러리를 쓰는 파일)에서 돈다. 현재
페이지 또는 모든 페이지의 보이는 글자를 구간(같은 모양으로 칠한 글자 묶음)마다 읽어
아홉 가지로 나누고, 같은 분류 · 같은 값은 한 줄로 묶어 개수와 함께 보여 준다. 줄을 누르면
그 노드를 선택하고 화면을 옮길 뿐, 노드는 바꾸지 않는다. 다른 명령이 도는 동안에는 UI 가
목록을 막고 `code.ts` 도 선택을 거절한다 — 선택은 현재 페이지를 옮기는데, Generate 는 새
노드를 현재 페이지에 만든다. 언제 · 누가 돌리는지, 분류마다 할 일, 보지 않는 것은
[Figma 플러그인 가이드](../../docs/contributing/figma.md)의 "소비 파일 점검" 에 있다.

**판정은 빌더와 한 벌이다.** 역할과 어디가 다른지는 `text-nodes.ts` 의 `roleDeparture` 에
필드를 하나씩 넘겨 묻고, 역할 목록은 `compat/v1.ts` 의 `roleNames` · `roleMetrics`, CoUI
스타일 이름은 `textStyleNameOf`, 컬렉션 이름은 `canonicalCollection` 을 쓴다 — Generate 가
라벨에 스타일을 붙이는 글자를 이 목록이 "역할에 없다" 고 말하는 일이 없도록. 여기서 더하는
것은 캔버스 값을 그 함수의 모양으로 옮기는 일뿐이다: 행간은 같은 크기에서의 역할의 단위로
(배수 역할은 퍼센트, 고정 줄 상자 역할은 픽셀 — 그림이 같으면 같은 역할), 32비트 숫자는
표시 단위로 반올림, 자동 행간은 역할과 다른 것으로, 역할 변수에 묶인 필드는 진술하지 않은
것으로.

**크기와 자간은 글자가 푸는 타이포 모드의 값과 견준다.** 텍스트 스타일은 크기와 자간을 역할
변수에 묶으므로, 소비 파일에서 스타일이 그리는 크기는 그 글자의 `Semantic/ Typography`
모드(`resolvedVariableModes`) 값이다. 모드마다의 크기 · 자간은 exporter 가 변수를 만드는 그
표(`packages/coui_core/bin/figma_reader/typography_modes.dart`)를 components.json 의
`typography.<역할>.modes` 로 받아 `roleMetricsIn` 이 돌려주고, `roleDeparture` 는 그 줄을
세 번째 인자로 받는다 — 비교 함수는 여전히 하나다. 모드를 읽지 못하면 코드 스케일과 견주고,
모드마다 크기가 다른 역할에는 "그림이 그대로" 라고 말하지 않는다.

CoUI 컴포넌트는 레지스트리의 세트 이름으로 알아보고(`code.ts` 가 넘긴다), 모르는 이름이면
글자가 CoUI 타이포 변수에 묶였거나 CoUI 텍스트 스타일이 붙었는지로 한 번 더 묻는다 — 역할이
살아남은 CoUI 라벨은 스타일만 갖고 노드의 변수 바인딩은 없다. 라이브러리 컴포넌트 안쪽
인스턴스도 원본을 묻고, 원본이 이 파일의 컴포넌트면(슬롯에 바꿔 넣은 것) 그 아래를 화면
글자처럼 읽는다. 인스턴스의 덮어쓰기는 글자를 감싼 모든 인스턴스의 `overrides` 를 모아
`fontName` · `fontSize` · `lineHeight` · `letterSpacing` · `textStyleId` 만 센다 —
`boundVariables` 와 `styledTextSegments` 는 글자만 고쳐도 나와서 뺀다.

본문 서체는 범위 안의 CoUI 스타일 · `font/family` 변수, 없으면 범위 안 CoUI 글자의 서체,
없으면 켜진 라이브러리 `Primitives` 의 서체 변수 이름에서 읽는다(`teamLibrary` 로 목록만
읽는다 — `importVariableByKeyAsync` 는 문서에 쓰는 일이라 부르지 않는다). 어느 변수가
본문 서체인지는 `mono-hangul.ts` 의 `isSansFamilyVariableName` 과 같은 판정이다. 고정폭 한글
칠하기(`mono-hangul.ts`)가 칠한 한글 구간은 같은 글의 코드 역할과 글꼴 말고 같으면 통과로
센다. 건너뛸 레이어 이름은 `figma.clientStorage` 에 기억한다(문서에는 쓰지 않는다).

`npm run selftest:consumer-audit` 이 실제 소비 파일에서 잰 사례를 분류마다, 그리고 한 값만
바꾼 변형과 함께 단언한다(양성만 두면 판정을 상수로 바꿔도 통과한다). 노드 더블 위에서
걷기(숨김 · 빈 글자 · 건너뛸 이름과 못 찾은 이름 · 원격/로컬 인스턴스 · CoUI 슬롯의 로컬
컴포넌트 · 바깥 인스턴스의 덮어쓰기 · 섞인 구간 · 타이포 모드 · 본문 서체의 세 출처)도 보고,
더블은 쓰기를 받으면 던진다. 판정이 역할 이름 · 스타일 이름을 자기 파일에 다시 적지
않았는지와 버튼 · 메시지 · 선택 · 바쁨 배선은 소스 텍스트로 본다. 모드 표가 components.json
에 실리는지는 `packages/coui_core/test/export_figma_components_test.dart` 가 되읽는다.

#### 가져온 사본 중복 (`src/library-copies.ts`)

같은 목록의 맨 위에 오는 열 번째 분류는 글자가 아니라 변수를 본다. 소비 파일이 같은 키의
라이브러리 변수를 두 번 가져오면 원격 사본이 둘이 된다 — id 는 `VariableID:<key>/<원본 노드
id>` 이고 두 사본은 뒤의 id 만 다르다. 옛 사본에 묶인 레이어는 라이브러리가 바뀌어도 조용히
옛 값으로 남고, 사본이 둘인 동안은 확장 컬렉션에서 그 변수를 덮어쓰면 `Mismatched variable
type` 으로 거부된다(옛 사본도 현재 사본도). 드리프트 점검과 글자 점검은 이름으로 견주므로 이
상태를 보지 못한다. 2026-11-01 한 소비 파일에서 상태 색 네 변수가 그랬다.

- **범위와 상관없이 파일 전체를 본다.** 모든 페이지의 노드(숨은 노드 포함 — 숨어도 옛 사본을
  붙든다)의 `boundVariables`, 로컬 스타일(채움 · 효과 · 격자 · 글자), 로컬 변수의 별칭,
  확장 컬렉션의 덮어쓰기 값과 변수 목록을 모아, 같은 키의 원격 사본이 둘 이상인 변수를 찾는다.
- **현재 사본은 `importVariableByKeyAsync(key)` 가 돌려주는 사본이다.** 그런 키에만 묻는다
  — 사본이 둘 이상이면 Figma 는 그중 현재 사본을 돌려준다(실측). 사본이 하나뿐인 변수에
  물으면 라이브러리의 새 판을 가져오는 쓰기가 될 수 있다. 점검에서 문서에 쓸 수 있는 호출은
  이것 하나뿐이고, 노드 · 스타일 · 변수 값은 바꾸지 않는다.
- 옛 사본마다 한 줄 — 참조하는 노드 · 스타일 · 별칭의 수, 현재 사본과의 모드별 값 차이(모드는
  이름으로 맞추고 별칭은 끝의 값까지 따라간다). 줄을 누르면 그 사본을 참조하는 노드를
  선택한다.
- **인스턴스 안은 이 파일이 덮어쓴 필드만 이 파일의 참조다.** 덮어썼는지는 사람이 놓은 바깥
  인스턴스의 `overrides` 로 가른다. 덮어쓰지 않은 바인딩은 원본 컴포넌트의 것이라, 원본이
  이 파일의 컴포넌트면 그 정의에서 한 번 세고, 라이브러리면 「라이브러리 컴포넌트 안」으로
  따로 센다.

**옛 사본 다시 연결**(같은 칸의 버튼)은 문서를 바꾼다. 옛 사본을 참조하는 이 파일의 노드 ·
로컬 스타일 · 로컬 별칭을 현재 사본으로 옮긴다. 채움 · 선 · 효과 · 격자는
`setBoundVariableFor*` 가 돌려주는 **새** 항목 목록을 다시 넣고, 그 밖의 필드는
`setBoundVariable`, 글자 구간은 `setRangeFills` · `setRangeBoundVariable`, 컴포넌트 속성은
`setProperties` 로 옮긴다. 노드는 그 페이지로 옮겨 가서(`setCurrentPageAsync`) 고치고 끝나면
원래 페이지로 돌아오며, 글자 노드는 그 글꼴을 먼저 불러온다. **라이브러리 컴포넌트 안에서
덮어쓰지 않은 자리는 옮기지 않는다** — 인스턴스에서 덮어쓰면 그 레이어에 라이브러리 변경이
닿지 않아 "조용히 옛 값" 을 다른 모양으로 만든다. 그 자리는 라이브러리 업데이트를 받아
옮긴다. 끝에 파일을 다시 걸어 남은 참조를 세고, 0 이면 "파일을 다시 열면 옛 사본이
정리된다" 고 적는다 — 플러그인은 원격 사본을 지울 수 없다(`remove()` → `Removing this node
is not allowed`). 다시 열면 쓰지 않는 라이브러리 변수의 덮어쓰기도 정리되므로, 연 뒤에는
「같은 이름의 로컬 토큰으로 다시 맞추기」를 돌린다.

**보지 않는 것**: 그라데이션 색 지점의 바인딩, 라이브러리 스타일. **실측하지 않은 것**:
인스턴스 안의 덮어쓰기를 덮어쓰기 필드 이름(`fills` · `boundVariables` · `fontName` …)으로
가르는 판정, 그리고 채움 · 선 · 효과 밖의 자리(격자 · 글자 구간 · 컴포넌트 속성 · 그 밖의
필드 · 스타일 · 별칭)를 이 명령으로 옮기는 것 — 셀프테스트의 더블은 API 의 모양만 흉내 낸다.
캔버스에서 색을 확인할 때는 원격 변수에 `resolveForConsumer` 가 null 을 돌려주므로(실측) 묶인
채움의 `color` 로 본다.

#### 옛 브랜드 컬렉션 (`src/brand-collections.ts`)

같은 목록의 맨 위에 오는 또 하나의 변수 분류. 원격 컬렉션 이름이 옛 번호 접두(`1-1. `)를 뺀
뒤 `Semantic/ Color · <코드 브랜드 이름>` 인 컬렉션의 변수를 이 파일이 참조하는 곳을 센다.
브랜드 이름은 `src/data/brands.json` 에서 읽는다 — 목록에 없는 브랜드의 컬렉션과 라이브러리
브랜드의 `Semantic/ Color · CoUI` 는 대상이 아니다. 참조의 범위와 인스턴스 안의 판정은 「가져온
사본 중복」과 같은 걷기(`collectNodeUses` · `collectDocumentUses`)다.

- 변수마다 한 줄 — 참조하는 노드 · 스타일 · 별칭의 수와 짝. 짝은 켜진 라이브러리의
  `Semantic/ Color · CoUI` 에서 **같은 이름 · 같은 타입**의 변수다. 점검은 팀 라이브러리의
  변수 목록(`getVariablesInLibraryCollectionAsync`)만 읽고 가져오지 않는다. 그 컬렉션이 켜진
  라이브러리에 없거나 여러 곳에 있으면 짝을 모른다고 적는다.
- 코드 브랜드의 원시값에 직접 묶인 곳(`Primitives` 의 `color/<브랜드 id>/…`)은 따로 세고 몇
  자리를 `페이지 · 노드 · 필드 · 변수` 로 적는다. CoUI 원시값(`color/coui/…`)은 세지 않는다.

**옛 브랜드 컬렉션 다시 연결**(같은 칸의 버튼)은 문서를 바꾼다. 짝이 있는 변수마다 짝을
`importVariableByKeyAsync` 로 가져와, 그 변수를 참조하는 이 파일의 노드 · 로컬 스타일 · 로컬
별칭(로컬 변수의 모드 값 · 확장 컬렉션의 덮어쓰기 값)을 짝으로 옮긴다. 쓰는 길은 「옛 사본 다시
연결」과 같은 함수(`applyVariableSwap`)다 — 무엇을 무엇으로 옮기는지만 다르다. 라이브러리
컴포넌트 안에서 덮어쓰지 않은 자리, 짝이 없는 이름, 원시값에 직접 묶인 곳은 옮기지 않고 로그에
적는다 — 원시값 자리가 어느 시맨틱 슬롯이어야 하는지는 사람이 정한다. 끝에 파일을 다시 걸어
짝이 있는 참조가 남았는지 세고, 파일을 닫았다가 다시 연 뒤 토큰 탭의 **이름으로 다시 맞추기**를
돌리라고 적는다 — 다시 열면 쓰지 않는 변수의 덮어쓰기가 정리되고, 새로 묶인 CoUI 변수에 브랜드
값이 다시 채워진다. **실측하지 않은 것**: 실제 소비 파일에서 옮긴 뒤 화면이 브랜드 확장의 값으로
그려지는지 — 셀프테스트의 더블은 API 의 모양만 흉내 낸다. `npm run selftest:brand-collections`.

`npm run selftest:library-copies` 가 실측한 모양의 세계(두 사본이 확장 컬렉션의 변수 목록에
함께 있고, 옛 사본은 다른 모드 id 의 컬렉션에 산다)에서 분류 · 참조 수 · 값 차이 · 목록 줄 ·
로그와, 다시 연결이 새 항목을 다시 넣는지(더블의 `setBoundVariableFor*` 도 받은 것을 바꾸지
않는다) · 그 페이지가 현재일 때만 쓰는지 · 글꼴을 먼저 불러오는지(더블은 어기면 던진다) ·
라이브러리 컴포넌트 안과 로컬 인스턴스를 건드리지 않는지를 단언한다.

### 상태 축 계약 (R1–R7, `src/state-axis.ts`)

상호작용 상태(비활성 · 호버 · 포커스 · 눌림)를 컴포넌트 세트가 어떻게 표현하는지의 계약이다.
결정과 실측은 `docs/redesign/상태-표현-통일-제안.md`, 여기는 **제너레이터가 지키는 형태**다.

| | 계약 | 어디서 지켜지나 |
|---|---|---|
| **R1** | 상호작용 상태는 `State` 한 축이다. 값은 소문자이고 순서는 `enabled · hover · focus · pressed · disabled` 의 부분열이다(컴포넌트에 없는 값은 빼되 순서는 지킨다 — 입력 필드는 `enabled · hover · focus · disabled`). `default` 는 쓰지 않는다 | `stateAxis([...])` 가 이름 · 순서 · 중복을 검사해 던진다 |
| **R2** | 값 상태(선택 · 체크 · 켜짐 · 열림 · 펼침 · 오류 · 가상 포커스)는 `State` 에 들어오지 않고 각자 축이다 — `Selected` · `Checked` · `On` · `Open` · `Expanded` · `Error` · `Active` | `InteractionState` 밖의 이름은 `stateAxis` 가 거부한다 |
| **R3** | `State` 에 `focus` 가 있으면 `Show focus ring` 불린을 정의하고 **결선한다**. `State=focus` 멤버는 링을 켠 채 묶지 않고(묶으면 기본값 `false` 를 받는다), 나머지 멤버는 링과 밴드를 이 불린에 묶는다. pressed + 포커스, disabled + 포커스처럼 `State` 하나로 그릴 수 없는 겹침을 위한 Figma 전용 장치다 | `defineShowFocusRing(set)` · `bindShowFocusRing(ring, id)` |
| **R4** | 비활성만 있는 컴포넌트도 `State` 다(`enabled · disabled`). `Enabled` / `Disabled` 불린 축은 쓰지 않는다 | 리뷰 |
| **R5** | 누를 수 없는 표시 요소에는 상태 축을 두지 않는다 | 리뷰 |
| **R6** | 상태는 상호작용 단위에 둔다 — 항목을 여러 개 담는 컨테이너는 상태 축을 갖지 않고 항목 컴포넌트가 `State` 를 가진다. 전체가 한 번에 눌리는 컨테이너(카드)는 예외 | 리뷰 |
| **R7** | 코드에는 아무것도 추가하지 않는다 — 공개 API 는 `enabled`(또는 `disabled`) prop 과 런타임 상태이고, `State` 는 그 조합을 Figma 에서 미리 보여 주는 축이다. 계열 리디자인이 정한 **새 상태 그림**(코드에 없는 hover · disabled 색)은 코드 계약에 들어가야 캔버스에 남는다 — 캔버스는 코드에서 다시 그려진다 | 리뷰 + `core/layer-mapping.md` |

**빌더는 규칙을 직접 적지 않는다.** 값 목록은 `const kXStates = stateAxis([...])`, 불린은
`defineShowFocusRing(set)` (다른 속성들과 같은 자리에서 — 속성 패널의 순서가 호출 순서다),
결선은 `bindShowFocusRing(ring, id)`. 헬퍼는 어긋난 입력을 **정렬하지 않고 던진다**: 변형 이름이
세트의 정체성이라 순서를 고치는 일은 그 세트를 옮기는 작업(변형 개명표 `VARIANT_RENAMES` 와 함께)이지
헬퍼의 일이 아니다.

**가드 두 겹**, 같은 baseline(`scripts/guards/structure/figma_state_axis_baseline.txt`) 을 읽는다:

- `check_figma_state_axis.py` (CI, Structure guards) — 빌더 **소스**를 센다: 헬퍼를 거치지 않은
  `k…States` 목록 · 목록 없이 `State` 축을 쓰는 함수 · `focus` 가 든 목록을 참조하면서
  `defineShowFocusRing(` 과 `bindShowFocusRing(` 을 둘 다 부르지 않는 함수. net-new 0 이고, baseline 에
  있는데 더는 위반이 아닌 줄은 실패한다(ratchet 은 내려가기만 한다). `--self-test` 가 실패할 수 있다는
  증거를 CI 가 매번 낸다. 모집단 하한이 있어 패턴이 매칭을 멈추면 "위반 0" 으로 읽히지 않고 실패한다.
- `selftest-registry-runtime` 의 *state axis drill* — **만들어진 세트**를 본다. `State` 값이 계약 데이터
  (enum)에서 오는 세트는 소스에 목록이 없어 위 가드가 못 보는데, 여기서는 보인다. R1 이름 · 순서와,
  `State=focus` 가 있으면 `Show focus ring` 이 정의돼 **어떤 레이어가 참조하는지**를 묻는다.

baseline 의 줄은 아직 R1 밖이거나 포커스 불린이 없는 세트이고, 줄마다 이유가 있다. 세트를 옮기면 줄이
사라진다 — 축 이름 · 값을 바꾸는 일은 그 세트의 변형 개명표를 같은 PR 에 넣어야 Generate 가 통과하고,
캔버스 쪽 ⇄ 대조는 사본에 **새 축 이름**을 쓴다. `npm run selftest:state-axis`.

### 실행 잠금 (`src/run-lock.ts`)

같은 파일에서 Generate 는 **한 번에 하나**만 돈다. 실행이 시작되면 `figma.root` 의 plugin data 에 세션 · 사용자 · 시작 시각 · 빌드 해시 · 범위를 적고(`🔒` 로그 한 줄), 끝나면 지운다. 다른 세션이 그 표식이 살아 있는 동안 시작하면 첫 줄이 `⛔ 다른 실행이 진행 중 — …` 이고 아무것도 그리지 않는다.

**왜**: `mountSet` 은 큰 세트를 그리는 동안 멤버를 세트 옆에 두고 앵커 하나만 남긴다. 그 사이 다른 세션의 합성자가 그 세트를 조회하면 멤버 하나만 보고 — `restingVariantName` 은 실패로, `bestVariantName` 은 **조용히 그 하나를 골라** — 잘못 그린다. 2026-09-12 에 두 계정이 그렇게 겹쳐 열 개가 primary/xs 버튼으로 그려졌다(#4831).

**살아 있음의 판정**: 표식의 하트비트(엔트리를 시작할 때와, 엔트리 안에서 서브 진행 청취자가 불릴 때마다 — 30초 스로틀)와 `last-step.ts` 가 콤보마다 쓰는 단계 표식 중 **나중 것**이 `kRunLockTtlMs`(10분) 안이면 살아 있다. 그보다 오래 조용하면 죽은 세션으로 보고 인수한다(`⚠` 한 줄). 같은 세션의 재실행은 그대로 통과한다(verify 의 두 번 실행).

**두 번째 방어선**: 그래도 앵커만 남은 세트를 만나면 `findComponentByName` 이 거부한다 — 세트 옆에 그 세트 이름으로 스탬프된 멤버(`coui-mount-set`)가 놓여 있으면 다른 실행이 그리는 중이거나 이전 실행이 죽은 자리다. 그 세트를 합성하는 엔트리는 이름을 대며 ✗ 로 남고, 스킵 판정도 그런 세트는 해시가 같아도 다시 그려 재조립한다.

### 빌드 신원 스탬프 (`src/generation-stamp.ts`)

세트를 그린 뒤 해시(`coui-content-hash`) 옆에 **누가 · 어느 빌드가** 그렸는지를 찍는다(`coui-generation`: 세션 · 사용자 · `kSharedSourceHash` · `kBuildRef`(브랜치@커밋) · 시각). 실행의 첫 줄(`🔒`)도 이 빌드의 해시와 ref 를 말한다.

`kBuildRef` 에는 빌드 시각이 없다 — 같은 커밋의 두 빌드는 같은 빌드이고, 시각이 섞이면 번들 내용이 같은데도 바이트가 달라져 `rebuild_bundle_from_main.sh` 의 "내용 동일 — 다시 쓰지 않는다" 가드가 영영 발동하지 않는다(#4927). 빌드 시각이 필요하면 `code.js.owner.json` 의 `builtAt` 이 매 빌드 갱신된다.

**두 곳이 읽는다.**
- **덮어쓰기 전 판정** — 지문이 달라도 마지막으로 그린 빌드가 이 빌드가 아니면 손 편집으로 읽지 않는다: 빌드가 다르면 같은 캔버스도 다르게 서술하고(지문의 필드는 몇 번 움직였다) 다르게 그리기도 하니 그 차이는 손을 증명하지 않는다. `↔ <이름>: 다른 빌드가 다시 그림 — …` 한 줄을 남기고 스냅샷 없이 다시 그린다. 2026-09-12 에 그렇게 생긴 "손 편집" 37건이 이 줄로 바뀐다.
- **낡은 세트 보기** — 낡음의 사유를 가른다: `사유 — 레시피 변경 K · 다른 빌드 K (해시 (브랜치@커밋) by 이름) · 스탬프 없음 K`. 레시피 변경과 스탬프 없음은 다음 실행이 지운다; **다른 빌드**는 다시 그려도 상대가 다시 그리면 돌아온다 — 두 빌드를 한 커밋으로 맞추는 것이 해법이다.

**보지 못하는 것**: 스탬프는 *마지막으로* 그린 것을 말한다. 다른 빌드가 그린 뒤 사람이 손댔다면 여기서는 구분되지 않는다 — 그 창을 한 실행 길이로 줄이는 것이 위 실행 잠금이다.

### Source layout

```
code.ts                      thin entry — routes UI messages
src/helpers.ts               VarLookup, solid, makeLabel, bind*/panel*/applyChrome,
                             fillData/borderData/labelColor (ColorData appliers), layouts,
                             mint()/mountSet()/resetNode() (#3737 — identity-preserving reuse)
src/renames.ts               controlled set/variant renames + structural (type-change) migrations (#3741/#3742/#3743)
src/variant-safety.ts        S-a/S-b variant identity guards (#3741) — pure logic, `npm run selftest`
src/verify.ts                opt-in identity self-check (#3739) — not CI, see "Verify" above
src/data.ts                  typed accessors over data/components.json (BUTTON/CARD/BADGE/TEXT_FIELD)
src/data/components.json     generated from coui_core (do not edit by hand)
src/import-tokens.ts         token import (upsert build/tokens.figma.json)
src/redraw-keep.ts           다시 그릴 때 멤버의 안쪽 노드를 유지 — 옛 자식을 숨겨 두고 새 트리와
                             대조해 값을 옮긴다 (`npm run selftest:redraw-keep`)
src/generate.ts              mint-by-name build loop, per-entry failure containment,
                             content-hash skip (#3739), progress instrumentation (#3781)
src/designer-parity.ts       손 편집 지문 · 덮어쓰기 전 스냅샷 · 리디자인 대조
                             (순수 부분은 `npm run selftest:designer-parity`)
src/mono-hangul.ts           고정폭 글의 한글 구간을 본문 서체로 칠하는 명령 — 소비 파일용
                             (`npm run selftest:mono-hangul`)
src/consumer-audit.ts        소비 파일의 글자 중 CoUI 역할과 갈라지는 것 목록 — 읽기 전용,
                             소비 파일용 (`npm run selftest:consumer-audit`)
src/library-copies.ts        같은 라이브러리 변수를 두 번 가져온 옛 사본 — 점검의 한 분류와
                             「옛 사본 다시 연결」, 소비 파일용 (`npm run selftest:library-copies`)
src/brand-collections.ts     옛 브랜드 컬렉션(`Semantic/ Color · <브랜드>`)에 묶인 곳 — 점검의 한 분류와
                             「옛 브랜드 컬렉션 다시 연결」, 소비 파일용 (`npm run selftest:brand-collections`)
src/collection-overrides.ts  소비 프로젝트 컬렉션 오버라이드 생성 · 브랜드 확장 컬렉션 만들기 ·
                             이름으로 다시 맞추기 (`npm run selftest:collection-overrides`,
                             `npm run selftest:brand-extension`)
src/icon-content.ts          글리프가 슬롯에서 받는 색 — 토큰을 `Semantic/ Content` 모드로 바꾸고(`src/data/content-colors.json`),
                             빌더가 끝난 뒤 슬롯 프레임에 모드를 지정한다 (하네스의 콘텐츠 색 드릴이 고정)
src/brand-table.ts           코드 브랜드의 값 표(`src/data/brands.json`)와 그 표를 확장에 쓰는 데
                             드는 순수 계획 — figma 호출 없음 (`npm run selftest:brand-extension`)
src/orphan-nodes.ts          페이지 직계에 떠 있는 미부착 노드 세기 — 읽기 전용,
                             지우지 않음 (`npm run selftest:orphan-nodes`)
src/orphan-props.ts          선언만 되고 참조되지 않는 컴포넌트 프로퍼티 세기 — 읽기 전용
                             (`npm run selftest:orphan-props`)
src/state-axis.ts            `State` 축 값 목록(R1)과 `Show focus ring`(R3)을 만드는 곳 —
                             어긋난 입력은 정렬하지 않고 던진다 (`npm run selftest:state-axis`)
src/unbound-props.ts         세트를 그린 직후 어떤 레이어도 참조하지 않는 컴포넌트 프로퍼티 제거 —
                             속성마다 로그 한 줄 (`npm run selftest:unbound-props`)
src/swap-default-repair.ts   INSTANCE_SWAP 기본값이 로컬 컴포넌트의 원격 사본을 가리키면
                             로컬로 되돌림 (`npm run selftest:swap-default-repair`)
src/overlapping-siblings.ts  변형 안에 다른 세션 대역으로 한 벌 더 든 직계 자식 세기 —
                             읽기 전용 (`npm run selftest:overlapping-siblings`)
src/component-index-cache.ts 스코프 실행의 컴포넌트 인덱스 캐시 — 적중 판정 · 해석 · 다음 캐시
                             (`npm run selftest:component-index-cache`)
src/summary-format.ts        로그 요약의 이름 나열 캡 — 낡은 세트 · 고아 노드 공유 (leaf)
src/entry-source.ts          엔트리의 소스 해시 표(번들이 굽는다)를 읽는 런타임 쪽 — 키 · `needs` 전이 · 폴백
                             (`npm run selftest:entry-hash`)
src/mockup-device-geometry.ts MockupDevice 의 기하 — `CoreMockupDeviceLayout` · 상태 표시줄 ·
                             안전 영역을 옮긴 순수 산술 (`npm run selftest:mockup-device` 가
                             캔버스 실측과 대조)
src/theme-preview.ts         Light/Dark theme-bound frames
src/color-generator.ts       pure HSL shade-scale math (no figma API) — accent → 11 shades
src/generate-palette.ts      Generate Palette: upserts Primitives vars + draws swatch preview
src/registry.ts              REGISTRY — single source of truth for every component
src/slot-stand-in.ts         `W`/`W?` 슬롯의 대역(`.Slot`) 인스턴스 · 교체 속성 기본값 —
                             이유와 이름 규칙은 docs/contributing/figma.md "빈 슬롯의 대역"
src/components/
  form.ts  form-fields.ts  form-controls.ts  form-pickers.ts
  display.ts  display-data.ts  display-media.ts
  navigation.ts  overlay.ts  layout.ts
  fixtures.ts                빌더 전용 세트(계약 없음 · 게시 안 됨) — `.Slot`
```

컴포넌트를 추가하는 것은 = 알맞은 section 파일에 `buildXxx(page, lk)` 를 작성하고 그 파일이 export 하는 레지스트리 배열에 항목을 append 하는 것이다. `esbuild --bundle` 이 모든 모듈(그리고 components.json)을 `code.js` 안으로 인라인한다.

## Generate Palette

플러그인의 **Generate Palette** 버튼은 **생성 팔레트 브랜드 전용**이다 — CoUI 자신의 색은
계산하지 않는 고정 hex(`CouiColorPresets.palette`)라 이 버튼으로 다시 칠하지 않는다. 버튼은
`PrimitiveColors.generate` 의 여덟 개 authored input — 일곱 개 chromatic role(`primary`, `secondary`, `tertiary`, `success`, `info`, `warning`, `error`)의 `h`/`s`/`l`, 그리고 `neutralHue` — 로부터 파일 전체를 리테마한다. 이를 `color_palette.json` 형태로 붙여넣으면 된다:

```json
{
  "neutral":   { "h": 220 },
  "primary":   { "h": 220, "s": 65, "l": 55 },
  "secondary": { "h": 260, "s": 60, "l": 50 },
  "tertiary":  { "h": 170, "s": 60, "l": 45 },
  "success":   { "h": 140, "s": 70, "l": 42 },
  "info":      { "h": 200, "s": 75, "l": 50 },
  "warning":   { "h": 45,  "s": 85, "l": 50 },
  "error":     { "h": 0,   "s": 75, "l": 50 }
}
```

**이 작업은 변수를 새로 추가하지 않는다.** 토큰 import 가 이미 설치해 둔 생성 팔레트의 64개 원시 색상이 그 자리에서 다시 칠해질 뿐이라, (변수 id 로 그것들을 별칭으로 참조하는) Semantic 컬렉션과 Semantic 에 바인딩된 모든 컴포넌트가 자동으로 따라간다 — 한 번의 클릭으로 파일 전체가 Light, Dark 모두 리테마된다. 259개의 숫자 프리미티브는 그대로 유지되며, `pure-white` / `pure-black` 은 정의상 hue 와 무관하므로 고정된다. 스와치 프리뷰는 전용 `🎨 Palette Generator` 페이지에 생성되며, 실행할 때마다 다시 만들어진다.

**Import to Variables** 를 먼저 실행해야 한다 — generator 가 동작하려면 Primitives 컬렉션이 존재해야 하기 때문이다. 색상 변수가 없으면 다시 생성하고 그 사실을 알리는데, 이런 방식으로 생성된 변수는 import 가 다시 실행되기 전까지 그것을 가리키는 Semantic 별칭이 없기 때문이다.

Chromatic role 은 **닫힌 집합**이다 — `PrimitiveColors.generate` 에는 여덟 번째 슬롯이 없으므로, 이 시스템에는 "팔레트를 추가"하는 동작이 없고 오직 "팔레트를 바꾸는" 동작만 있다. 그래서 이 버튼은 추가하는 대신 다시 칠하는 것이다.

`s` / `l` 이 **JSON 에서는 0–100** 인 이유는 디자이너가 읽고 쓰는 값이 그것이기 때문이다; Dart 의 record 는 0–1 을 쓴다. 변환은 플러그인 안에서 일어나고, 로그는 Dart 단위로 붙여넣기 바로 가능한 스니펫을 그대로 출력한다:

```text
PrimitiveColors.generate(
  primaryHSL: (h: 220, s: 0.65, l: 0.55),
  …
  neutralHue: 220,
);
```

이것을 브랜드 팔레트를 정의하는 코드(`CoreBrand` 의 `palette:` · 소비 앱의 `AppTheme`)에 붙여넣으면 코드가 동일한 64개 색상을 만들어낸다 — 라운드트립이 옮기는 것은 여덟 줄뿐이며, 색상 표를 옮겨 적는 일은 결코 없다.

이 수학(`src/color-generator.ts`)은 `NeutralScale.fromHue` / `ChromaticScale.fromHSL`(`packages/coui_core/lib/src/color/primitive_colors.dart`)와 `CoreColorConversion.fromHSL`(`packages/coui_core/lib/src/color/color_conversion.dart`)을 손으로 포팅한 것이다 — 같은 상수, 같은 분기 순서. 생성 팔레트 브랜드(Unibook — 시드는 `bin/figma_brands/brands.dart`)의 입력을 이 과정에 통과시킨 결과는 코드의 `PrimitiveColors.generate` 와 같은 64개 값이어야 한다. 라이브러리는 그 브랜드의 원시값을 내보내지 않으므로(브랜드는 값 표다) 이 대조를 돌리는 자동 도구는 없다 — 포팅을 고칠 때는 두 구현의 출력을 같은 입력으로 직접 비교한다.

디자이너가 authoring 한 seed 로부터(이 여덟 개의 입력으로 유도하는 대신) Light/Dark **Semantic** 스킴 전체를 생성하는 것은 별도의, 더 큰 도구로 남아 있다.

## Figma 브랜치에서 돌려도 되는가 — 한 경로만 빼고 된다

디자이너가 정본 파일을 직접 고치는 대신 **Figma 브랜치**를 만들어 그 안에서
Import·Generate 를 돌리고 `Review branch changes` 로 diff 를 확인한 뒤 merge 할 수
있다. 브랜치는 문서를 통째로 복제하므로 root pluginData 도 따라온다.

| 경로 | 브랜치에서 | 왜 |
|---|---|---|
| **Import to Variables · Generate Components** | 된다 | `figma.fileKey` 를 읽지 않는다. 정체성은 mint-by-name 이고, 파일 확인은 root pluginData 스탬프 대조뿐이며 **경고만 하고 막지 않는다**(`checkCanonicalLibrary`). 브랜치는 그 스탬프를 물려받으므로 경고조차 안 뜬다 |
| **충실도 리포트 (채널 B)** | 된다 | fileKey 를 쓰지 않는다 |
| **구조 → .json 스냅샷 (채널 A)** | **거부된다** | 스냅샷이 `figma.fileKey` 를 기록하고, `reverse/diff_structure.ts` 가 `reverse/config.json` 의 키와 다르면 종료 코드 2 로 멈춘다 — "다른 파일끼리 비교하면 그 차이가 전부 디자이너의 변경으로 보고된다". 브랜치는 키가 다르다 |

**귀결**: 구조 스냅샷은 **브랜치를 merge 한 뒤 정본 파일에서** 뜬다. 브랜치에서 떠서
커밋하면 조용히 틀린 리포트가 나오는 게 아니라 그 자리에서 멈추므로, 이 비대칭은
사고가 아니라 안전판이다 — 다만 모르면 "왜 안 되지" 로 시간을 쓴다.

⚠️ **브랜치든 정본이든, 캔버스는 이 컴퓨터의 빌드 산출물을 그린다.** 흡수분을 머지한
뒤 그 체크아웃에서 `npm run build` 를 다시 돌리지 않으면 Generate 는 빌드 시점의
코드를 계속 그린다.

### 번들은 파일 하나 — 주인 표식과 자동 재빌드

`code.js` 는 manifest 가 가리키는 경로 하나뿐이라 **마지막에 빌드한 쪽이 이긴다.** 다른
워크트리(세션)가 자기 브랜치로 구워 Figma 에서 테스트 중이던 번들을 main 재빌드가 덮은
일이 실제로 있었다. 그래서 `npm run build` 는 빌드 전에 `scripts/bundle-owner.mjs check`
로 지금 깔린 번들의 주인(사이드카 `code.js.owner.json` — 워크트리·브랜치·sha·시각)을
보고, **다른 워크트리이면서 다른 브랜치**의 번들이면 멈춘다. 합의됐으면
`COUI_BUNDLE_FORCE=1 npm run build`. 누구 것인지는 `npm run bundle:owner`.

머지 뒤 재빌드를 사람이 기억하지 않게 하려면 `scripts/figma/rebuild_bundle_from_main.sh`
를 쓴다 — **전용 빌드 워크트리**(origin/main detached)에서 굽고 `code.js` 만 목적지로
복사하므로 어떤 체크아웃의 git 상태도 건드리지 않는다. `--check` 는 "main 이 움직였나"
만 답해(0/1) 오르카 자동화의 precheck 로 쓰고, 등록 예는 그 스크립트 머리말에 있다.
빌드 워크트리는 스크립트가 있는 저장소의 것이어야 하고, 승격도 그 저장소의 워크트리가
구운 적재물만 받는다 — 다른 저장소의 main 이 에러 없이 구워지거나 갈아끼워지는 것을
막는다. 거절하는 조건과 우회 방법은 스크립트 머리말에 있다.

## 사용법

1. **코드에서 토큰과 컴포넌트 export (저장소 루트):**

   ```bash
   melos run export:figma-tokens
   melos run export:figma-components
   # → build/tokens.figma.json + tools/figma-token-sync/src/data/components.json
   ```

2. **플러그인 빌드 (의존성 설치는 최초/lockfile 변경 시, build는 소스/export 변경 시):**

   ```bash
   melos run figma:install   # 또는: cd tools/figma-token-sync && npm ci
   melos run figma:build     # 또는: cd tools/figma-token-sync && npm run build
   # → tools/figma-token-sync/code.js 를 작성한다
   ```

3. **Figma 데스크톱에서 로드:** Plugins → Development → Import plugin from
   manifest… → `tools/figma-token-sync/manifest.json` 을 선택.

4. **실행:** 플러그인을 열고 `build/tokens.figma.json` 을 붙여넣거나(또는
   파일을 선택하고) **Import to Variables** 를 클릭한다. 변수와 함께 역할별
   텍스트 스타일 22개도 이름으로 upsert 된다(`src/text-styles.ts`). 코드 역할 셋
   (`Code/XS` · `Code/SM` · `Code/MD`)은 행간이 배수가 아니라 21px 고정 상자라, 그 행간만
   PIXELS 로 쓰고 `line-height/code` 변수에 묶는다(나머지 역할의 행간은 PERCENT 리터럴).
   Import 는 변수를 지우지 않으므로 고정폭 서체를 바꾼 뒤에는 옛 `font/family/JetBrains Mono`
   가 남는다 — 빌더는 내보낸 서체만 정확히 찾으므로 그리기에는 영향이 없지만, 드리프트
   검사에 라이브 전용으로 나오므로 손으로 지운다. 재-export 후에는 언제든 다시 실행할 수 있다.

5. **Generate Components**를 실행해 캔버스를 갱신하고 관련 변형·인스턴스
   리사이즈·기존 연결을 확인한다. build는 bundle만 바꾸며, Import는 Variables와
   텍스트 스타일을 바꾼다. 세트 재생성은 이 별도 단계다. 이미 플러그인이 열려
   있었다면 새 bundle을 읽도록 닫았다 다시 연다.

`coui_core` 의 default 값을 바꾼 뒤에는 위 1~2단계를 다시 돌려야 플러그인 번들에
반영된다 — `melos run figma:sync` 하나로 export(tokens+components) + rebuild 를
한 번에 돌릴 수 있다. `melos run figma:typecheck` / `figma:selftest` 는 CI 의
G6 게이트(`Figma plugin typecheck (G6)`)를 로컬에서 그대로 재현하고,
`melos run figma:check` 는 `npm ci` 부터 그 둘까지 한 번에 실행한다. 저장
중(watch) 반복 빌드에는 `melos run figma:watch`.

## CI guards

이 최신화 작업은 architecture 문서에서 알파벳으로 명명된 가드 집합(G1–G10)을
추적한다. `.github/workflows/ci.yaml` 에 배선된 것들:

- **G1 — 재생성 최신성(regen freshness).** `check_figma_export_fresh.sh` 는
  `components.json` 이 현재 `coui_core` 로부터 exporter 가 재생성할 결과와
  다르면 실패한다.
- **G6 — 플러그인 typecheck.** PR 이 `tools/figma-token-sync/**` 를 건드릴
  때마다(서드파티 action 이 아니라 `git diff` 로 경로를 감지 — 추가 토큰
  권한이 필요 없음) 돈다. `npm ci` 는 *Figma plugin deps* 라는 **별도 스텝**이고
  Structure guards **위**에 있다 — 아래 G13 순서 계약 참조. *Figma plugin
  typecheck (G6)* 단계는 `npm run typecheck && npm run selftest` 만 돈다.
- **G13 순서 계약 — 설치가 소비보다 앞선다.** `check_figma_icon_names.sh` 의
  freshness 블록과 icon-keys 동기 블록은 `node_modules` 가 있어야 돌아간다.
  그래서 `npm ci` 스텝이 그 가드를 부르는 Structure guards 스텝보다 **앞에**
  있어야 하고, `check_ci_guard_deps_order.sh` 가 그 순서를 강제한다.
  이 짝이 깨졌을 때의 증상은 red 가 아니라 **green** 이다 — 두 블록이 조용히
  건너뛰고 성공 줄이 통과했다고 말한다. 실제로 그 상태로 한동안 출하됐다.
  스텝을 재배치할 때 이 짝을 같이 옮겨라.
- **G9 — space/size 중복 제거 ratchet.** `check_space_size_duplication.sh`.
- **G2 — REGISTRY ↔ coui_core 이름 parity.** `check_figma_registry_parity.sh` —
  phantom/mismatch 는 net-new 0, 미등재는 ratchet. 현재 허용 목록은
  `scripts/guards/structure/figma_registry_uncovered_baseline.txt`를 확인한다. Structure guards
  스텝에 배선(G7 과 같은 이유로 path filter 없음).
- **G7 — 빌더 색·치수 리터럴 ratchet.** baseline 1131 에서 시작해 오직 감소만
  허용(현재 0 — 미설명 리터럴 없음, `figma_builder_literals_baseline.txt` 참조).
- **상태 축 계약 (R1 · R3).** `check_figma_state_axis.py` — 빌더 소스의 `State` 값 목록이
  `stateAxis(...)` 를 거치고, `focus` 가 있는 세트가 `Show focus ring` 을 정의하고 결선하는지.
  net-new 0, 기존 예외는 `figma_state_axis_baseline.txt`. 위 "상태 축 계약".
- **G10 — 축 반영률 ratchet.** `selftest-registry-runtime` 안에 산다(별도
  스크립트 없음) — 분자는 빌더가 실제 만든 (Variant/Size/State/Enabled) 조합,
  분모는 `axis-combos.ts` 의 같은 열거자. 신규 갭은 즉시 실패, 기존 갭은
  `scripts/g10-axis-coverage-baseline.json` ratchet. **현재 baseline [] — 축
  보유 50종 전원 완전 커버가 CI 로 상시 강제된다.**

위 가드들의 실패는 `continue-on-error`로 무시하지 않는다. 다른
정적 가드와 마찬가지로 PR 을 실패시킨다.

G2를 포함한 실제 가드 배선은 [ci.yaml](../../.github/workflows/ci.yaml)이
기준이다. 이 README의 과거 가드 개수나 도입 순서로 현재 CI 실행 여부를
판단하지 않는다.

## Notes

- **Generate Components**, **Theme Preview**, **Generate Palette** 를 실행하기
  전에 Pretendard 가 (9개 static weight 전부, Thin–Black) 로컬에 설치되어
  있어야 한다 — 이들 모두 텍스트를 렌더한다. Figma desktop 은 OS 에 설치된
  폰트를 읽는다; weight 가 하나라도 없으면 다른 weight 로 조용히 대체하지
  않고 전체 실행이 크게 실패한다.
- **방향은 토큰 카테고리마다 다르다.** 색상은 코드가 작성한다: CoUI 는 고정 팔레트
  (`CouiColorPresets.palette`), 생성 팔레트 브랜드는 `PrimitiveColors.generate` 의 여덟
  입력값에서 나와 code → Figma 로 흐르므로, Figma 에서 색상 변수를
  수정해도 역으로 흐르지 않는다. Dimension(space, size, radius, font-size …)
  은 반대 방향으로도 흐른다 — **토큰 내보내기** 가 로컬 Variables 를 읽어
  생성된 `figma_tokens.g.dart` 로 만들며, 이것이 소비하는 앱이 디자이너가
  작성한 dimension 토큰을 받아들이는 방식이다. 이 구분을 유지한다:
  Figma 에서 수정된 색상은 다음 import 시 사라지고, Dart 에서 수정된
  dimension 은 다음 export 시 사라진다.
- **토큰 내보내기는 파일 두 개를 함께 낸다** — `figma_tokens.g.dart` 와,
  Import 가 읽는 것과 같은 포맷의 `tokens.figma.json`. 소비하는 리포의 drift
  테스트가 이 둘을 대조하므로, 둘은 **같은 스냅샷**이어야 의미가 있다. 버튼을
  나누면 그 사이에 디자이너가 파일을 고칠 수 있고, 그때의 불일치는 drift 가
  아니라 한쪽이 낡은 것인데 구별되지 않는다. 그래서 한 번의 읽기에서 둘 다
  만들고, 양쪽에 같은 `export` 지문(`.g.dart` 헤더 · JSON `meta.export`)을
  찍어 소비하는 쪽이 짝임을 **가정하지 않고 단언**할 수 있게 한다.
- **Dart 내보내기의 타입과 단위.** FLOAT 변수는 `double` 로 나온다 — 단
  `CoreTextStyle` 이 Figma 와 다르게 적는 두 글자 값은 예외이고, 무엇인지는
  변수의 **scope** 가 말한다(별칭 사슬 전체에 전파된다 — 시맨틱 굵기가 가리키는
  원시값도 같은 타입이어야 참조가 컴파일된다):
  - 굵기(`FONT_WEIGHT`) → `int`. `CoreTextStyle.fontWeight` 의 CSS 100–900
    정수다. 이름은 그대로다(값이 정수가 아니면 `double` 로 두고 로그에 적는다).
  - 자간(`LETTER_SPACING`) → **em**, 이름에 `Em`. Figma 는 묶인 숫자를 px 로
    읽고 `CoreTextStyle.letterSpacing` 은 글자 크기에 곱하는 em 비율이라, 같은
    컬렉션의 짝(`letter-spacing/<키>` ↔ `font-size/<키>`)으로 **모드마다** 나눈다
    (소수 넷째 자리 — Figma 가 넘기는 float32 잡음을 지운다). 짝이 없으면
    값은 px 그대로 두고 이름에 `Px` 를 붙인다(`letter-spacing/size-14` →
    `size14Px`). 별칭은 대상의 단위와 이름을 따른다. 원시 `letter-spacing/*`
    는 scope 가 없는 em 값이라 이름 · 값 그대로 나온다.
  - 자간의 이름을 바꾸는 이유: 값만 em 으로 바꾸면 px 를 직접 글자 크기로 나누던
    소비 코드가 그대로 컴파일되어 **두 번 나눈다**. 옛 이름이 없어지면 그 자리가
    컴파일 오류로 드러난다.
  - scope 가 없는 변수(직접 만든 변수의 기본값 `ALL_SCOPES`)는 무엇인지 알 수
    없어 `double` 그대로다. 굵기 · 자간 변수를 별칭으로 가리키면 그 타입 · 단위를
    따라온다.
  - 단위 설명은 각 멤버의 `/// Figma:` 줄 **위**에 한 줄로 붙는다 — `/// Figma:`
    줄과 바로 뒤의 `static const` 를 짝으로 읽는 소비 쪽 테스트를 깨지 않는다.
  - `tokens.figma.json` 은 Figma 값 그대로(px)다. 두 파일을 대조하는 drift
    테스트는 자간을 `em × 글자 크기` 로 되돌려 비교한다.

  ```dart
  // 생성물 그대로 const 로 배선된다
  const displayLarge = CoreTextStyle(
    fontSize: SemanticTypographyFontSize.displayLarge,
    fontWeight: SemanticTypographyFontWeight.display, // int
    letterSpacing: SemanticTypographyLetterSpacing.displayLargeEm, // em
  );
  ```

  이전 생성물에서 옮길 때: 굵기의 `.toInt()` 는 지워도 된다(남겨도 컴파일된다).
  자간을 `px ÷ fontSize` 로 직접 나누던 자리는 `…Em` 멤버로 바꾼다.
- Primitive colors 는 라이브러리 브랜드(`bin/figma_brands/brands.dart` 의 첫 항목 — CoUI,
  `CouiColorPresets.source`) 색의 스냅샷이다. 팔레트를 변경한 후에는 재-export 한다.
- 브랜드 추가 = `bin/figma_brands/brands.dart` 의 목록에 항목 하나를 더하고 재-export 한다
  (`brands.json` 이 한 표 늘어난다 — 라이브러리의 컬렉션 · 원시값은 늘지 않는다). 손으로 작성한
  램프(`PrimitiveColors.generate` 시드로 재현되지 않는 것)는 그 파일의 명시 팔레트로 적는다.
- **의사결정 기록.** 이 플러그인이 구현하는 디자인 관련 결정들(예: 어떤
  토큰이 왜 그렇게 매핑되는지, 어떤 컴포넌트가 왜 데이터 기반이 아니라
  builder-original 인지)은 오늘은 이 README 와 architecture 문서에 있다.
  이 레포를 읽지 않는 디자이너를 위해 이를 기록하는 전용 docs_site 페이지가
  계획되어 있지만 아직 만들어지지 않았다.
- **Figma Variables 가 표현할 수 없는 것.** Shadow/easing/spring 은 읽을 수
  있는 CSS 문자열로 저장된다 (Figma Variables 는 복합 effect 를 바인딩할
  수 없다) — 이들을 Figma Effect Styles 에 매핑하는 것은 향후 단계이다.
  서페이스 스타일 중 **기하**(반경 재분배 · 선 두께 하한)는 `Semantic/ Surface`
  컬렉션의 모드(스타일마다 하나, 이름은 코드의 스타일 이름)로 export 된다 —
  각 값은 그 스타일이 닿는 `Primitives` 단계의 별칭이고, 빌더는 반경 · 선
  두께를 이 컬렉션에 묶는다(없는 문서는 `Primitives`). 프레임에 모드를 고정하면
  그 스타일의 모서리와 선이 보인다. 스타일이 **그림자**에 하는 일(블러 ·
  오프셋 배율과 더하기, 불투명도 치환, 거울 쌍)도 같은 컬렉션의
  `shadow/<단계>/<n>/x·y·blur·color·spread` 행으로 export 되고, Import 가 문서의
  `shadow/*` 이펙트 스타일을 내보낸 레이어 수대로 다시 짓고(옛 레이어의 남은
  변수는 묶지 않는다), `setShadow` 가 빌더의 그림자를 그 행에 묶는다
  (캐스트마다 거울 레이어 — 쌍을 만들지 않는 스타일에서는 알파 0).
  **재질**은 같은 컬렉션의 `material/*` 행이다 — 역할마다 채움의 몫
  (`fill-opacity`) · 블러(`backdrop-blur`) · 굴절 여부(`glass`, BOOLEAN),
  림(`material/rim/<n>/*`), 그리고 스타일이 *그리지 않던* 표면 · 컨트롤에
  더하는 보더(`material/control-border`)와 캐스트(`material/control-shadow/<n>/*`).
  코드가 재질 표면으로 표시한 요소는 채움을 콘텐츠 뒤의 `material` 레이어에
  그리고(불투명도 · 블러 · 림이 행에 묶인다), 굴절은 visibility 가 `glass`
  행에 묶인 `glass` 레이어의 GLASS 이펙트다 — 다이얼은 변수를 받지 않아
  `components.json` 의 `surfaceGlass` 표로 실린다(`applySurfaceMaterial`).
  기여 보더 · 캐스트는 `addControlBorder` · `addControlShadow` 가 코드와 같은
  조건으로 더한다. 기본 스타일에서 모든 행이 항등이라 모드를 고르지 않은
  프레임은 단일 채움과 같은 그림을 그린다. 다크 모드의 몫 · 채도 · 가장자리
  광택 · 중첩 깊이는 export 되지 않는다.
  **밀도**(`CoreDensity`)는 `Semantic/ Dimension` 컬렉션의 모드(밀도마다 하나,
  기본 `standard` 가 첫 모드)로 export 된다 — `control-size/*`(컨트롤 행 높이),
  `space/*`(밀도가 옮기는 간격), `radius/*`(모서리 — `Semantic/ Surface` 의
  별칭이라 밀도와 스타일이 코드와 같은 순서로 합성된다). 빌더는 패딩 · 간격을
  `space/*` 에, 컨트롤 행(Button · TextField · MenuItem · Command)의 높이를
  `control-size/*` 에 묶는다. 간격 사다리에 있지만 간격이 아닌 높이 · 폭은
  원시 단계(`spaceLadder`)에 묶어 밀도를 따라가지 않는다 — 코드도 그 값은
  옮기지 않는다.
- **배포.** 개발자는 로컬 manifest로 검증한다. 팀 배포용 ZIP은 GitHub Actions가
  만들며, 게시자는 기존 plugin의 **Publish new version**으로 갱신한다.
  위 “팀 플러그인 배포 패키지” 절을 따른다. plugin 게시와 Figma 라이브러리의
  Import/Generate·Publish는 별개다.

## 역방향 — Figma 에서 오는 신호

위 **Notes** 의 방향 정책은 *값(value)* 이 어느 쪽으로 흐르는지를 정한다. 이 절의 두 채널은 **값을 옮기지 않는다 — 신호만 옮긴다.** 산출물은 markdown 리포트와 GitHub 이슈가 전부이며, 토큰 값을 코드에 쓰는 경로는 하나도 새로 만들지 않는다. 그래서 색상이 code → Figma 단방향이고 dimension 이 **Export Dart Code** 로만 역류한다는 정책은 그대로다.

각 카테고리에서 채널이 하는 일:

- **색상** — 값은 여전히 코드가 쓴다. 채널이 색 불일치를 발견하면 그것은 "Figma 가 코드에서 멀어졌다" 는 뜻이고, 조치는 **재-import** 이지 Dart 편집이 아니다. Notes 가 "Figma 에서 수정된 색상은 다음 import 시 사라진다" 고 말하는 그 소멸을, 사람이 겪기 전에 미리 알려주는 것이 채널의 역할이다.
- **Dimension** — 값의 역류 경로는 **Export Dart Code** 하나뿐이다. 채널이 dimension 차이를 보고해도 그 값을 스스로 옮기지 않는다; 사람이 리포트를 읽고 Export Dart Code 를 돌린다.
- **구조와 기하** (페이지·프레임의 존재와 위치) — 토큰이 아니라서 위 정책의 대상이 아니었던 축이다. 여기서 처음 관측된다.

### 두 채널

| | A — 크론 (무인) | B — 디자이너 트리거 |
|---|---|---|
| 무엇이 실행하나 | 스케줄 자동화 (`/cc-coui-sync:absorb`) | 디자이너가 Figma 데스크톱에서 플러그인 실행 |
| 어떻게 읽나 | MCP `get_metadata` | 플러그인의 fidelity 검사 |
| 무엇을 보나 | 구조 + 기하 | 필드 단위 expected/actual |
| 색·토큰 바인딩 | **못 본다** | 본다 |
| 산출물 | `reverse/.work/` 원본 → 차분 → 이슈 | `fidelity-*.json` 다운로드 |

둘은 경쟁하지 않고 서로의 사각을 덮는다. A 는 사람이 아무것도 하지 않아도 매일 돌지만 색을 볼 수 없고, B 는 색까지 보지만 사람이 Figma 를 열어야만 생긴다. 그래서 A 가 조용하다는 것은 **구조가 그대로라는 뜻일 뿐 색이 멀쩡하다는 뜻이 아니다** — 크론이 만드는 이슈는 매번 그 한계를 자기 본문에 적는다.

### 무인으로 읽을 수 있는 것 (실측)

| MCP 호출 | 헤드리스 | 반환 |
|---|---|---|
| `get_metadata` (nodeId 없음) | **동작** | 페이지 목록, `- <id>: <name>` 한 줄씩 (평문) |
| `get_metadata` (nodeId 있음) | **동작** | 속성만 있는 XML (`id` · `name` · `x` · `y` · `width` · `height`) + 끝에 XML 이 아닌 `IMPORTANT:` 산문 |
| `get_variable_defs` | **실패** | `You currently have nothing selected` |
| `get_design_context` | **실패** | 동일 |

크론이 보는 것은 **id · 이름 · 타입 · x · y · width · height** 가 전부다. 색·토큰 바인딩·타이포그래피·radius·shadow 는 무인으로 도달할 수 없으며, 이유가 **둘** 이라 하나를 고쳐도 열리지 않는다:

1. 이 organization 의 플랜 tier 가 `org` 라 **Variables REST API 가 없다.**
2. 바인딩을 반환하는 MCP 호출은 **Figma 데스크톱 앱의 살아있는 선택(selection)** 을 요구한다 — 크론에는 선택할 사람도 앱도 없다.

이 두 사실을 적어 두는 이유는, 크론을 "언젠가 색까지 보게 만들면 되는 것" 으로 오해하고 설계를 얹는 것을 막기 위해서다. 색을 무인으로 보려면 플랜을 올리거나 채널 B 를 쓰는 것 외에 길이 없다.

### 예산

MCP 는 하루 200회, 분당 20회다. 크론은 페이지 호출을 **60회로 제한**하고 그 이상이면 걷지 않고 중단한다 — 한 번의 워크가 예산 대부분을 쓰면 같은 날 고쳐서 재확인할 방법이 사라지기 때문이다. 페이지가 그보다 많으면 `config.json` 의 `pages` 로 범위를 좁힌다.

### 소스 배치

```
reverse/
├── config.json                 # fileKey, fileKeyStatus, pages, 임계값
├── baseline.structure.json     # 커밋된 구조 베이스라인
├── diff_structure.ts           # A 채널 차분
├── ingest_fidelity.ts          # B 채널 검증·렌더
├── incoming/                   # 디자이너가 fidelity-*.json 을 떨구는 곳
├── tsconfig.json               # npm run typecheck:reverse
└── .work/latest/               # 원본 MCP 응답 (gitignore)
```

두 스크립트의 별칭: `npm run reverse:diff` · `npm run reverse:ingest`. 플래그를 넘길 때는 `--` 뒤에 붙인다.

`reverse/` 는 플러그인 번들 밖이며 `src/**` 를 훑는 가드(G1 · G6 · G7 …)의 범위에 들어가지 않는다 — 플러그인이 아니라 그 옆의 관측 도구이기 때문이다. 타입 검사도 자기 `tsconfig.json` 을 쓴다: 플러그인 쪽은 Figma 플러그인 타이핑 위에서 돌지만 이 스크립트들은 Node 에서 돌기 때문이다.

**그래서 이 디렉터리를 검사하는 명령은 플러그인 쪽과 다르다** — `npm run typecheck:reverse` 이고, G6 가 돌리는 `npm run typecheck` 는 이 디렉터리를 **보지 않는다.** 즉 `reverse/` 가 타입 검사되는지는 그 별도 명령이 실제로 실행되는지에 달려 있다. 어느 CI 단계가 그것을 부르는지는 `.github/workflows/ci.yaml` 에서 직접 확인하라 — 여기 적힌 문장이 아니라 그 파일이 답이다. 부르는 단계가 없다면 이 디렉터리는 **사람이 손으로 돌릴 때만** 타입 검사된다.

두 스크립트는 **같은 종료 코드 규약**을 쓴다: `0` 차이 없음 / `1` 사람이 볼 차이 있음 / `2` 인프라 실패. `1` 과 `2` 를 절대 섞지 않는다 — 깨진 파이프라인을 디자인 변경으로 신고하면 그 라벨의 이슈가 곧 무시되고, 진짜 드리프트가 왔을 때 같이 무시된다. 이 레포의 다른 가드와 같은 규약이다.

### 모집단 하한

차분은 새로 파싱한 노드 수가 베이스라인의 절반 아래로 떨어지면 **삭제로 보고하지 않고 `2` 로 중단**한다. `scripts/guards/structure/check_figma_export_fresh.sh` 가 바이트 하한을 따로 두는 것과 같은 방어다: 수확이 붕괴하면 결과가 텅 비고, 텅 빈 결과는 "차이 없음" 또는 "전부 삭제됨" 으로 **조용히 그럴듯하게** 읽힌다. 붕괴는 스스로를 에러라고 말하지 않으므로 별도의 하한이 말해줘야 한다.

### 운영 — 크론 (A)

1. **파일 키를 확인한다.** 디자이너에게 `config.json` 의 `fileUrl` 이 정본 라이브러리 파일인지 확인받고, 그때 `fileKeyStatus` 를 `"confirmed"` 로 바꿔 커밋한다. 그 전까지 `/cc-coui-sync:absorb` 는 MCP 를 한 번도 부르지 않고 중단한다 — 엉뚱한 파일을 걸으면 "디자이너가 전부 바꿨다" 는 거대한 거짓 이슈가 나오고, 그런 이슈를 한 번 받은 사람은 다음 이슈도 읽지 않는다.
2. **베이스라인을 수확한다.** 베이스라인이 빈 상태의 첫 실행은 "이번 실행이 베이스라인을 세운다" 로 끝나며 삭제를 보고하지 않는다.
3. **베이스라인을 승격한다.**

   ```bash
   cd tools/figma-token-sync
   npm run reverse:diff -- --raw-dir=reverse/.work/latest --update-baseline
   ```

   `reverse/baseline.structure.json` 을 커밋한다. **승격은 사람만 한다** — 자동화가 매 실행 자기가 방금 본 것을 정답으로 삼으면 어떤 드리프트도 영원히 보고되지 않고, 항상 초록인 채 아무것도 지키지 않는 가드가 된다. 커밋 메시지에 무엇에 동의했는지 남긴다.
4. **자동화를 켠다.** 스케줄 자동화가 `/cc-coui-sync:absorb` 를 실행하도록 배선한다. 1~3 이 끝나기 전에는 켜지 않는다.

### 크론은 지금 꺼져 있다 — 2 단계가 1/147 만 수확했기 때문

**이 절이 없으면 다음 사람이 침묵을 "아무도 안 켰네" 로 읽고 같은 것을 다시 켠다.** 껐다.

크론은 켜져 있었고 매일 돌았다. 그런데 감시 범위가 **페이지 1 개 · 노드 7 개** 였다 — Cover 한 장. 그 사이 라이브러리에는 컴포넌트가 147 개 있었다.

원인은 2 단계 수확이다. 베이스라인의 `capturedBy` 가 `figma-mcp:get_metadata` 인데, **그 호출은 페이지 목록을 전부 주지 않는다.** 첫 수확에 Cover 만 잡혔고, 그 뒤로는 그 베이스라인과만 대조하므로 나머지 146 개는 애초에 비교 대상이 아니었다. 붕괴가 아니라 **처음부터 좁았던 것**이라 모집단 하한(위 절)도 걸리지 않는다 — 하한은 줄어드는 것을 보지, 처음부터 작은 것을 보지 못한다.

관측된 결과: 이슈 7 건, 닫힌 것 0, 코멘트 0. 마지막 이슈가 보고한 유일한 변화는 Cover 프레임이 `(0,0) → (6,-5)` 로 움직인 것이었다. 같은 기간에 실제로 흡수된 결정들 — 라벨 행간 · Fab 를 메뉴로 · AppBar 계약 · Toast/Chip/Toggle chrome — 은 **한 건도 이 채널을 통해 오지 않았다.** 전부 디자이너가 직접 말해서 왔다.

그래서 이 상태는 무해한 미가동이 아니라 **위 1 단계가 경고한 그 실패가 다른 경로로 도착한 것**이다: 읽히지 않는 이슈가 라벨을 태우고, 나중에 진짜 드리프트가 와도 같이 무시된다.

**되켜려면 순서대로**:

1. 수확을 페이지 전수 열거로 바꾼다 — `get_metadata` 가 아니라 `use_figma` 로 페이지를 배치 로드해 걷는다. 이걸 고치기 전에 켜면 다시 Cover 만 본다.
2. 전수 수확 후 베이스라인을 승격한다(3 단계). 첫 차분은 146 페이지가 통째로 "추가" 로 뜨므로, 그 이슈는 보고가 아니라 승격 대상이다.
3. 기하 축의 소음을 먼저 재본다. Generate 가 레이아웃을 조금만 바꿔도 147 페이지가 전부 "이동" 으로 뜰 수 있다 — 지금 Cover 6 픽셀이 147 배가 되는 형태다. 축을 좁히거나(name/type/page 만) 임계를 두지 않으면 켜자마자 같은 자리로 돌아온다.

**그리고 다 고쳐도 Channel A 는 색·타이포·radius·shadow 를 못 본다** — 헤드리스로 읽히지 않는 축이고, 위 결정 목록의 절반이 거기 있었다. 그 축의 답은 Channel B 이며 아직 한 번도 쓰이지 않았다(`reverse/incoming/` 비어 있음). 감시를 되살리는 것보다 B 를 한 번 돌려보는 쪽이 값이 크다.

커맨드 자체는 살아 있다 — 스케줄만 끈 것이고 `/cc-coui-sync:absorb` 는 필요할 때 손으로 돌린다.

### 운영 — fidelity (B)

1. 디자이너가 Figma 데스크톱에서 플러그인의 fidelity 검사를 실행하고 결과 JSON 을 내려받는다.
2. 그 파일이 `reverse/incoming/` 에 `fidelity-*.json` 이름으로 **커밋된다.** 디자이너에게 checkout 이 없는 것이 보통이라 파일만 넘어오고, 레포에 넣는 것은 받은 엔지니어의 일이다 — 플러그인 패널이 디자이너에게 그렇게 안내한다.
3. 크론이 다음 실행에서 그것을 집어 같은 이슈에 자기 항목으로 싣는다. **리포트가 하나도 없는 주기에는** 크론이 그 사실과 마지막 리포트 날짜를 같은 자리에 적는다 — 빈 절을 남기면 색까지 검사돼 깨끗했다는 뜻으로 읽히기 때문이다. 즉시 보고 싶으면 직접 돌린다:

   ```bash
   cd tools/figma-token-sync
   npm run reverse:ingest          # 기본 --dir=reverse/incoming
   ```

   여러 개가 쌓여 있으면 **사전순 마지막 하나만** 읽고 그 사실을 경고한다 — 파일명에 타임스탬프를 넣으면 그 하나가 최신이 된다. 디렉터리가 비어 있으면 `0` 이 아니라 `2` 로 끝난다: 리포트가 없는 것은 결함이 없다는 뜻이 아니라 아무도 검사하지 않았다는 뜻이라, 침묵을 통과로 읽지 않는다.

리포트는 `buildHash` 를 담는다 — 어느 플러그인 빌드가 그 판정을 냈는지 모르면, 리포트와 현재 코드가 어긋났을 때 둘 중 무엇이 낡았는지 알 수 없기 때문이다.


### Countdown canvas properties and legacy instances

Countdown's four-unit Figma sample exposes `Days`, `Hours`, `Minutes` and
`Seconds` as TEXT properties. They are Figma-only (`Figma 전용, 코드 API 없음`),
with no Code Connect or runtime API bindings. The runtime still accepts one
integer. Defaults and caption text are declared in the builder.

Each numeric property drives its visible text and three invisible measurements.
Native HUG therefore measures all four styled values in each box while keeping
existing density-aware padding, row spacing, chrome and typography. The clipped
carrier has a legal height cancelled by the outer spacing; no document listener
or per-edit geometry update is installed.

On the first upgrade from the old zero-property shape, Generate captures existing
same-document consumer numeric overrides before resetting or binding the main. Redraw keeps
the component, four blocks and eight visible text node identities while adding
the wrappers. After reconciliation it moves captured values into instance TEXT
properties and reads back all four references per property. Instances without
numeric overrides keep inheriting defaults. This migration requires
`keepInnerNodes`; it refuses to upgrade through the destructive reset path.

An incomplete migration retains the private `coui-countdown-text-migration`
plugin-data record with original visible-text IDs and consumer values. Generate
refuses a blind retry while that record exists. Inspect the saved values and
actual consumer/reference readback before recovery; clearing the record alone
is not recovery. The record is removed only after every consumer readback passes.

Mock migration tests verify identity and override transfer logic. They do not
prove Figma's native reparenting, retroactive text binding, raster output, direct
UI editing, GUI reset, mode preservation or reopening; validate these before
production rollout. The designer-approved rollout conditions are consumer direct
on-canvas editing, joint `100 ↔ 99` growth/shrink, reset/reopen, and existing-mode
preservation. An intended `1000` input is not an additional mandatory condition.
`getInstancesAsync` cannot enumerate consumers in other files; external
consumer-file update behavior remains unvalidated coverage, not an added
condition of the designer's approval.
