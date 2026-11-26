# Figma 레이아웃 전면 재검토 — 2026-09-11

## 결론

**추가 결함이 있다.** 이전 #4785/#4786의 `0 stale wrap holders across 153`
결과는 반응형 레이아웃 전체의 무결성을 뜻하지 않는다. 좁은 형태의 홀더만
찾는 검사이며, 실제 리사이즈를 수행하지 않는 test double 위에서 나온 결과다.

이번 검토는 생성 코드 인벤토리와 라이브 메인에서 만든 임시 인스턴스의
크기 변경을 대조했다. 아래 발견사항은 **검토 결과이며 수정 완료 목록이 아니다.**

## 범위와 증거

- 소스 인벤토리 기준: `2082b2365` (#4786 및 Dock #4787 포함).
- 라이브 파일: [CoUI Library](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ).
- 로컬: **153/153 REGISTRY 빌더 실행**, 인스턴스 내부를 중복 순회하지 않은
  **24,495개 생성 노드**의 프레임/자식/크기/constraints/sizing 인벤토리 수집.
- 라이브: 문서 **198페이지** 확인. 활성/인프라 이름의 **156페이지**를 구조 조사.
  그 시점의 2,739개 component member, 27,937개 노드, 10,144개 프레임 중
  `NONE` 프레임 2,844개, 직접 instance 자식이 있는 `NONE` 프레임 730개 관측.
  이는 **후보 수**이며 결함 수가 아니다. 숨겨진 슬롯도 구조 조사에 포함했다.
- 라이브 메인 **134종** 발견: 당시 REGISTRY와 대응하는 132종 +
  REGISTRY에 없는 `InputOtpCell` 1종 + `NavigationHeader` 1종.
  `NavigationHeader` 는 retired / see RETIRED in `src/renames.ts` — 빌더를 추가하지 않는다.
- **134종 각각 대표 인스턴스**를 생성해 1.5배 크기 변경 후 내부 치수를 확인했다.
  주요 결함은 2배 폭 변경·슬롯 표시·긴 본문으로 추가 재현했다.
- 모든 variant의 라이브 리사이즈 조합 검증은 수행하지 않았다. 생성 코드의
  variant 전수 검사와 라이브 대표 인스턴스 검증은 검증 깊이가 다르다.
- 임시 인스턴스/프레임은 `finally`에서 삭제했다. 첫 폰트 미로드 오류 때
  분리돼 남았던 임시 인스턴스 3개도 확인 후 삭제했다.
- 라이브 노드 수는 관측 시점 값이다. Button 페이지에는 세트 밖의 variant
  component도 존재하므로 그 멤버까지 구조 조사에 포함했다.

### 라이브에서 메인을 찾지 못한 REGISTRY 21종

아래는 빈 페이지뿐 아니라 문서 전체에서 같은 이름의 COMPONENT/COMPONENT_SET도
조회했다. 라이브 미확인을 정상 판정으로 바꾸지 않는다.

`Gap`, `Stacks`, `AspectRatioBox`, `ResponsiveContainer`, `ResponsiveRowColumn`,
`ScrollableClient`, `ScrollViewInterceptor`, `StageContainer`, `Frame`, `Mask`,
`MediaQueryVisibility`, `Breakpoint`, `Swap`, `Clickable`, `Hover`, `Subfocus`,
`Listing`, `Swiper`, `Mockup`, `Basic`, `Validated`.

## 수정 필요가 확인된 주요 컴포넌트

경로는 이 디렉터리를 기준으로 한다. 기본 그림에서 숫자가 맞는지보다
**부모 크기/콘텐츠 변경 후에도 계약이 성립하는지**로 판단했다.

> 상태 — Slider · Range · ChipGroup · ScrollArea(공유 `overflowingContent` 헬퍼라
> FadeScroll · ScrollableClient 의 column 도 함께) · Toast 행은 #4826 에서 안쪽 노드의
> 고정을 풀었고, 하네스가 그 노드들을 이름으로 잡는다(`#4826 inner`). 나머지 행의
> 루트 고정 박스는 #4806 의 스윕이 다뤘다.

| 컴포넌트 | 실제 관측 | 생성 코드의 원인 / 수정 지점 |
|---|---|---|
| **Slider** | root 폭 240→480, `track` 폭 240 유지 | `src/components/form.ts:2637–2697`: root Hug, track FIXED. 내부 rail/fill/thumb 좌표도 최초 폭에서만 계산됨. 트랙 FILL뿐 아니라 값 비율과 thumb 크기를 함께 보존해야 함 |
| **Range** | root 폭 288→576, `slider` 폭 240 유지 | `src/components/form-controls.ts:1244–1339`: Flutter `Expanded`와 달리 canvas 고정 240. active fill과 두 thumb 좌표도 고정 |
| **ChipGroup** | root 폭 160→320, `scroll` 160×96 유지 | `src/components/display-data.ts:1406–1500`: 헤더만 FILL. 스크롤 프레임·FadeScroll instance가 고정이고 chips는 Hug. viewport와 실제 wrap/scroll 모드를 구분해 수정해야 함 |
| **Carousel (slide)** | root 320×180→480×270, `slide`/`nav`/`indicators` 모두 320×180 유지 | `src/components/display-media.ts:1011–1060`: NONE root 아래 세 프레임에 STRETCH 누락. 안쪽 slide instance의 FILL만으로는 부모 프레임을 늘리지 못함 |
| **Resizable** | root 360×160→540×240, `paneRow` 360×160, divider x=179, handle x=172/y=60 유지 | `src/components/layout.ts:2156–2243`: paneRow/line/handle이 일회 좌표뿐. Flutter `Position.fill(paneRow)`와 불일치. 자식 pane의 FILL은 이미 있으나 한 단계 위가 끊김 |
| **ScrollArea** | root 160×96→240×144. scrollbar 높이는 144가 되지만 content는 160×160 유지 | `src/components/primitives-layout.ts:250–265,802–832`: column에 STRETCH를 줬어도 column/rows의 Hug·고정 폭 때문에 실제 콘텐츠 폭이 유지됨. 세로 overflow 길이를 viewport 높이로 억지 축소하지 말고 가로 제약 전달을 고쳐야 함 |
| **FadeScroll** | root 160×96→240×144, `child` 160×160, 상·하 fade 폭 160 유지 | `src/components/primitives-layout.ts:1044–1075`: content, fade band, scrollbar가 초기 좌표/크기에 머묾. 가장자리 고정과 viewport 가로 제약이 필요함 |
| **RefreshTrigger** | root 160×40→240×60, `child`/`overlay` 폭 160 유지 | `src/components/primitives-behaviour.ts:688–716`: `placeAt` 좌표만 기록. Flutter의 전체 영역 overlay와 달리 slot/overlay bounds가 갱신되지 않음 |
| **Diff** | root 360×202.5→540×303.75, before pane 180×202.5 유지 | `src/components/display-media.ts:2091–2157`: split 영역·구분선·knob에 상대 크기/위치 계약 없음. 50% split이 1/3로 변함 |
| **Drawer (backdrop)** | root 640×400→960×600, backdrop 608×380 유지 | `src/components/overlay.ts:905–922`: `backdropScale`을 최초 크기에만 곱하고 CENTER만 설정. 중심은 따라가도 95% 배경 비율은 깨짐. panelWidth 고정과는 별개의 결함 |
| **Toast** | `Show description=true`만으로 content 높이 67인데 root는 56. 긴 Description으로 content 353, root 56 유지 | `src/components/overlay.ts:1249,1319,1357–1386`: NONE root를 숨김 기본 상태의 높이로 한 번 resize. 내용은 Hug로 늘어나지만 배경/외곽 bounds가 늘어나지 않음 |
| **OutlinedContainer** | root 폭 162→324, `content`/`child` 폭 160 유지 | `src/components/primitives-chrome.ts:479–542`: content Hug + child 고정 160×48. 일반 콘텐츠 슬롯을 glyph preview cell로 표현해 가로 제약이 단절됨 |
| **FocusOutline** | root 폭 160→320, `child` 폭 160 유지 | `src/components/primitives-chrome.ts:619–718`: 바깥 focus band의 STRETCH와 별개로 child slot이 고정. 외곽 링을 고쳤다는 것으로 콘텐츠 계약까지 통과시키면 안 됨 |
| **Card (media/child)** | media 켜고 root 폭 260→520: media 프레임은 520인데 media content는 160×40. child 켜도 내부 content는 160×40 | `src/components/display.ts:565–579,658–692`: media는 NONE stack 아래 고정 instance. child holder는 현재 코드에서 STRETCH이지만 내부 instance에 FILL 누락. 표면 홀더 수리만으로 해결되지 않음 |
| **OverflowMarquee (fade)** | root 120×64→180×96, fade x=96/24×64 유지하여 오른쪽 끝에서 떨어짐 | `src/components/primitives-layout.ts:1101–1105`: trailing fade에 MAX/STRETCH 누락. 넓게 남는 child 자체는 마퀴의 의도된 overflow이므로 결함으로 세지 않음 |

### 추가 가로 제약 후보 — 위젯 대응을 더 구체화해야 하는 자리

- **Calendar header**: root 폭 224→336에도 header 224 유지.
  Flutter `_buildHeader`는 `Expanded`와 부모 Column의 stretch를 사용한다
  (`calendar.dart:340–357,483–503`). 날짜 셀의 토큰 크기까지 무조건 FILL로
  바꾸는 것은 다른 결정이다. header와 grid의 가로 계약을 별도로 고쳐야 한다.
- **Hidden**: root 폭 160→240에도 child 160 유지. Flutter는
  `child.layout(constraints)`로 부모 제약을 전달한다 (`hidden.dart:219`).
  arbitrary child를 swap한 경우의 FILL/Hug 계약을 함께 검증해야 한다.
- **TextBlock**: blockquote 폭 155→155, root는 155→232.5.
  현재 빌더의 두 preset 예제와 실제 paragraph/inline-code의 의미가 섞여 있다.
  blockquote와 inline code를 같은 FILL 규칙으로 덮으면 안 된다.

## 소스에서 확인한 추가 위험 / 라이브 검증 불가

- **ScrollableClient** (`src/components/primitives-layout.ts:936–984`):
  두 scrollbar instance를 일회 x/y로 배치, 각 끝단 추종 경로 없음.
  `drawFocusOutline`도 host 최종 resize보다 먼저 호출한다.
- **Swiper** (`src/components/overlay.ts:3000–3053`):
  NONE host 아래 Drawer instance와 handle의 viewport 의존 좌표가 최초 계산값에 머문다.
- **ScrollViewInterceptor** (`src/components/primitives-layout.ts:997–1011`):
  overflowingContent를 fixed viewport 안에 배치한다. 실제 swapped child의
  scroll 축별 제약 전달을 라이브 메인 생성 후 확인해야 한다.

이 셋을 포함한 위 21종은 라이브 메인이 없으므로 코드 검사만으로
"실제 Figma 리사이즈 검증 통과"라고 판정하지 않았다.

## 이전 수정이 라이브에 아직 도달하지 않은 곳

현재 소스의 `wrapForPin`은 Auto Layout + instance FILL을 만든다.
반면 아래 라이브 노드는 옛 NONE holder를 가지고 있다.

| 컴포넌트 | 대표 라이브 노드 | 관측 |
|---|---|---|
| Card | `3587:36466` | holder 162×50 / instance 260×137, MIN×MIN |
| Menu | `3700:6438` | holder 128×283 / instance 220×291. root 220→440에서 holder는 348로 변하지만 instance는 220 유지 |
| InputOtp | `3547:4045` | seg의 FocusOutline이 NONE holder |
| ChipInput | `3547:5266` | FocusOutline NONE holder |
| Select / Autocomplete / PhoneInput | `3514:129671` / `3514:129986` / `3514:128076` | Popover NONE holder |
| DatePicker / TimePicker / ColorPicker | `3514:133523` / `3514:134755` / `3514:132319` | Popover/Dialog 등 NONE holder |
| Calendar / Drawer / Toast / Alert | `3508:84015` / `3514:127273` / `3514:135097` / `3508:89487` | 아이콘용 옛 pin holder |
| Tracker | `3514:123965` | tooltip NONE holder |

아이콘/팝업 holder의 NONE은 현행 생성 구조와의 불일치다. 모든 holder가
부모 전체를 채워야 한다는 뜻은 아니다. tooltip·dialog·icon의 자체 크기와
Card/Menu의 전체 표면 계약은 다르다.

**관측만으로 원인을 '해시 스킵'으로 확정할 수는 없다.** 이전 플러그인 번들,
Generate 미실행/일부 실행, 중단된 생성, 캐시 등 실행 이력을 확인해야 구분된다.
`kSharedSourceHash`는 이미 소스 변경으로 전체 hash를 무효화한다
(`src/build-hash.ts:24–44`, `src/generate.ts:1031–1034`).

## 잘못된 자동 수정을 막기 위한 구분

- **정상적인 고정 크기**: 아이콘, checkbox glyph, 별점의 겹친 별,
  focus dot, token-sized OTP cell, 스와치, 버튼 내부 고정 컨트롤.
- **정상적인 Hug/상한**: 메시지 버블의 내용 폭, Calendar 날짜 셀,
  Dialog/HoverCard의 panelMaxWidth, DraggablePanel.panelWidth,
  팝오버/컨텍스트 메뉴의 자연 높이, 한 줄 navigation의 높이,
  Footer/Steps 등의 내용 높이. 부모 높이를 늘렸다고 내용도 늘어야 하는 것은 아니다.
- **의도된 overflow**: OverflowMarquee의 넓은 child, 세로 scroll의 긴 콘텐츠.
- **추가 판정 필요**: Dock의 bar 폭(검토 중 별도 변경 PR #4787 확인), Window의 외부
  배치 bounds vs panel 크기, MockupCode/MockupDevice의 화면 높이/기기 비율,
  NavigationMenu/Menubar의 bar와 popup 폭, DatePicker trigger의 자연 폭.
  이 항목들은 리사이즈 후보로 기록했지만 이 감사에서 확정 결함 수에 합치지 않았다.

## 이전 검사에서 놓친 이유

1. `isStaleWrapHolder`는 `ABSOLUTE`이며 이름이 같은 instance를 가진
   `NONE` frame만 찾는다 (`src/paint.ts:499–526`). NONE 부모 아래의 일반
   좌표 배치에는 ABSOLUTE가 필요 없으므로 Carousel/Resizable 등이 빠진다.
2. 프레임이 Auto Layout이더라도 FIXED 내부 패널이면 놓친다.
3. `STRETCH` 문자열 존재만 검사해도 ScrollArea는 통과하지만 실제 column은 Hug다.
4. `repairWrapHolder`는 같은 이름 instance가 하나면 다른 자식/칠/슬롯 의미와
   관계없이 후보로 본다. 이름 기반으로 일반 스택까지 자동 변환할 위험이 있다.
5. `collectStaleWrapHolders`는 INSTANCE 내부까지 순회한다. 문제를 소유한
   메인과 그 메인을 소비하는 컴포넌트가 중복 집계될 수 있다.
6. test double의 `resize`/sizing은 실제 Figma 레이아웃 엔진이 아니다.
   대표 인스턴스의 리사이즈와 긴 문구 검증을 별도로 수행해야 한다.

## 재현 명령과 검증

`tools/figma-token-sync`에서:

```sh
npm run audit:layout
npm run typecheck
```

`audit:layout`은 기존 registry-runtime selftest를 실행하면서 `LAYOUT_INVENTORY`
JSON 한 줄을 추가 출력한다. 각 빌더의 모든 frame/component, 숨김 슬롯,
자식 geometry와 sizing을 담는다. 같은 경로여도 속성이 다르면 별도 레코드로
남긴다. 단순히 NONE frame의 개수를 실패로 보지 않는다.

기존 selftest의 다음 두 출력은 이번 검토에서도 통과했다:

```text
#4785: 0 stale wrap holders across 153 built components.
#4701 sweep: 0 full-bleed pinned layers left at a fixed size across 153 builder(s).
```

위 출력과 실제 리사이즈 실패가 **동시에 존재**한다는 것이 이번 재검토의 핵심이다.

## 수정 우선순위

1. **콘텐츠가 잘리는 자리**: Toast 높이, Card media/child,
   OutlinedContainer/FocusOutline 슬롯.
2. **뷰포트 전체를 채우는 자리**: Carousel, Resizable, ScrollArea/FadeScroll,
   RefreshTrigger, Drawer backdrop.
3. **비율·위치 계산이 필요한 자리**: Slider/Range, Diff, trailing fade.
4. 각 컴포넌트별로 생성 코드 수정 → Generate → 작은/기준/큰 인스턴스,
   슬롯 표시/교체, 긴 본문 검증 → 동일한 불변식의 회귀 검사 순으로 완료 판정.
   레이아웃 주석이나 AL/constraints 문자열만으로 완료 처리하지 않는다.
