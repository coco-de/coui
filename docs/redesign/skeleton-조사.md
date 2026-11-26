# Skeleton 역할 분리 조사 (1단계 공통 결정 #4)

작성 2026-10-01 · 실측 대상 Figma `9FgsLhiWz0aLsVqcoI6nYJ` · 읽기 전용
대상 페이지 `❖ Skeleton` (`2467:91822`) · 세트 `Skeleton` (`2467:91839`)

이 문서는 결정이 아니라 조사 결과입니다. 마지막 두 절에 내 결정 대기 항목과 Claude Code에 보낼 질문을 모았습니다.

> **상태: 확정** (2026-10-07) — 결정 대기 항목이 모두 정해졌습니다. 결정과 그 반영은 §12 에 모았고, 마지막 결정(D7)은 §12-8 입니다. 코드 반영은 #5277~#5282 가 맡습니다.
>
> **3판 (2026-10-06)** — 2판의 `[검증 정정]` 위에 코드 대조 검토(2026-10-01, 코드 기준 `bc95d287f`)의 **(코드 대조)** 정정을 합쳤고, 2026-10-02 · 10-06 에 받은 답과 결정을 §12 에 모았습니다. 두 검토가 같은 수치를 따로 고친 곳은 `[검증 정정]` 을 남기고 코드 쪽 근거만 덧붙였습니다.
>
> **2판 (2026-10-01, 교차 검증)** — 초판의 수치와 인용을 다른 프로젝트 문서 · 외부 원문과 대조했습니다. 바뀐 곳은 본문에 `[검증 정정]`으로 표시했고, 11절에 무엇을 어떻게 확인했는지 모았습니다. 이번 검증에서 Figma는 새로 열지 않았습니다.
> 가장 큰 정정: **`outline-variant`의 Light 대비는 4.01이 아니라 약 1.70입니다.** 그래서 "outline 계열로 바꾸면 3:1"이라는 초판 결론은 Light에서 성립하지 않고, 3:1에 닿는 토큰은 `outline`(플레이스홀더 글자와 같은 색)뿐입니다.
>
> **코드 대조 검토 (2026-10-01)** — 원문은 그대로 두고, 코드와 다른 사실은 그 자리에 **(코드 대조)** 로 표시해 고쳤습니다. §9 의 질문에는 각 질문 아래에 답을 적었습니다. 코드 대조로 새로 생긴 결정 후보는 §8 의 D8~D16 으로 올렸고, 선택지만 적고 권고는 하지 않았습니다. 이 조사와 직접 관계없이 함께 드러난 결함은 §9-1 에 모았습니다.

---

## 0. 한 문장 요약

Skeleton은 지금 **세 가지 다른 일**을 하나의 컴포넌트로 하고 있고(실제 로딩 자리 표시자 · 빌더가 빈 슬롯을 채운 캔버스용 더미 · 다른 컴포넌트의 미구현 영역 표시), 축 `Enabled`는 **파일 전체에서 쓰이는 인스턴스가 0개**이며 캔버스에서 두 값이 완전히 동일합니다. "역할 분리"의 실체는 변형 축이 아니라 **이 세 용도를 구분할 수단이 없다는 것**입니다.

**(코드 대조)** 세 가지를 바로잡습니다.

- `Enabled` 는 애니메이션이 아니라 **렌더 여부**입니다. `false` 면 아무것도 그리지 않습니다(§1-3).
- 세 용도 중 둘째와 셋째는 같은 빌더 동작입니다. 이름만 다를 뿐 '미구현 영역 표시' 인 것은 없습니다(§2-3).
- 라이브러리 코드(Flutter · Web)에서 Skeleton 을 합성하는 컴포넌트는 하나도 없습니다. 그래서 캔버스의 Skeleton 인스턴스 179개 중 코드의 실제 합성에 대응하는 것은 없습니다 — 빌더가 넣은 대역과, 그 대역을 품은 채 지워진 고아 노드(§3-3)입니다.

---

## 1. 실측 — 세트 자체

### 1-1. 축과 계약

세트 설명: "콘텐츠 로딩 중 자리 표시자를 표시하는 스켈레톤 컴포넌트"

| 축 | 값 | 변형 수 |
|---|---|---|
| `Variant` | rectangular · circular · text | |
| `Enabled` | true · false | 합계 6 |

`_Docs / Properties` 전수 (`packages/coui_core/lib/src/component/contracts/skeleton/`):

| Name | Type | Value |
|---|---|---|
| `axes.variant` | `CoreSkeletonVariant` | rectangular · circular · text (default: rectangular) |
| `axes.enabled` | `bool` | true · false |
| `fields.duration` | dim | `CoreDuration.ms1000` |
| `fields.fromOpacity` | dim | `CoreOpacity.opacity50` |
| `fields.toOpacity` | dim | `1` |
| `fields.lineSpacing` | dim | `CoreSpace.space8` |
| `fields.lineHeight` | dim | `CoreSize.size16` |
| `fields.lastLineWidth` | dim | `0.6` |
| `fields.lines` | dim | `3` |

`withStyle` 예시에 `backgroundColor` · `borderRadius` · `fromOpacity`가 노출되어 있고, `tokenChain` 예시는 `Skeleton(…).radius0`입니다.

**(코드 대조)** 표의 값은 Core 계약(`CoreSkeletonStyle` 의 static const)과 같습니다.

- `backgroundColor` · `borderRadius` 가 이 표에 없는 것은 변형별 기본값 표(`defaultsByVariant`)에 있기 때문입니다.
- `tokenChain` 예시의 `.radius0` 은 익스포터가 체인의 첫 getter 를 기계적으로 찍은 것입니다. 기본 반경이나 권장값을 뜻하지 않습니다.

### 1-2. 그려진 값 (전 변형 · 전 노드)

| 변형 | 노드 | 크기 | 반경 | 반경 변수 | 채움 | 노드 불투명도 |
|---|---|---|---|---|---|---|
| rectangular (true · false 동일) | `tint` RECTANGLE | 160×40 | 8 | `radius/8` @0. Primitives | `color/surface-container` @1-1. Semantic/ Color · CoUI | 0.5 |
| circular (true · false 동일) | `tint` RECTANGLE | 40×40 | 9999 | `radius/9999` | 동일 | 0.5 |
| text (true · false 동일) | `Rectangle` ×3 | 200×16 · 200×16 · 120×16 | 4 | `radius/4` | 동일 | 0.5 |

`text`는 VERTICAL 오토레이아웃 gap 8, 전체 200×64. 세 번째 줄 120 = 200 × 0.6 으로 `fields.lastLineWidth`와 일치합니다.

**(코드 대조)** 값의 출처가 둘로 나뉩니다.

- **계약에서 오는 값**: 반경 8 · 9999 · 4, 채움 `surface-container`, 줄 높이 16, 줄 간격 8, 마지막 줄 비율 0.6, 불투명도 0.5. 0.5 는 `fromOpacity` 이고 맥동의 쉬는 끝(첫 프레임)입니다.
- **빌더의 미리보기 상수**: 크기 160×40 · 40×40, 줄 폭 200. 계약에는 출처가 없습니다(빌더 주석이 그렇게 적습니다).
- 실제 위젯에는 기본 크기가 없습니다. rectangular · circular 는 크기를 주지 않으면 대개 높이 0 으로 그려집니다. text 는 크기를 받지 않고 부모 폭을 채웁니다(마지막 줄 60%).

### 1-3. `Enabled=true`와 `Enabled=false`는 캔버스에서 동일합니다

측정한 모든 속성(크기 · 반경 · 반경 변수 · 채움 색 · 바인딩 변수 · 노드 불투명도 · 페인트 불투명도 · 가시성)에서 두 값이 일치합니다. 축이 캔버스에 아무 차이를 만들지 않습니다.

계약에 `duration` · `fromOpacity` · `toOpacity`가 있으므로 `Enabled`가 **깜빡임 애니메이션의 on/off**일 가능성이 높고, 애니메이션은 Figma 정적 변형으로 그릴 수 없으므로 동일해지는 것이 자연스럽습니다. 다만 이것은 추정이며 §9 Q1으로 확인이 필요합니다.

**(코드 대조)** 추정과 다릅니다. `enabled` 는 깜빡임이 아니라 **렌더 여부**입니다.

- Core 계약 주석이 'When false, renders nothing instead of the skeleton' 입니다.
- Flutter 는 빈 상자(`SizedBox.shrink`)를, Web 은 숨긴 빈 `div` 를 그립니다. 맥동이 멈추는 것은 그 부수효과입니다.
- 캔버스에서 두 값이 같은 이유도 애니메이션 때문이 아닙니다. 빌더가 `Enabled=false` 를 '비활성 chrome 이 선언되지 않았으니 같게 그린다' 고 해석했기 때문입니다. 코드의 뜻(그리지 않음)과 반대인 전제입니다.
- 저장소의 `상태-표현-통일-제안.md` §1-4 는 이미 이렇게 고쳐져 있습니다.

---

## 2. 실측 — 실제 소비 실태

Skeleton 변형들의 `instances`를 전수 조회했습니다(179개).

### 2-1. 변형별 인스턴스 수

| 변형 | 인스턴스 |
|---|---|
| rectangular, Enabled=true | 174 |
| circular, Enabled=true | 1 |
| text, Enabled=true | 4 |
| **Enabled=false (세 변형 전부)** | **0** |

**`Enabled=false`를 쓰는 인스턴스가 파일에 하나도 없습니다.** 축이 캔버스에서 차이도 없고 소비도 없습니다.

### 2-2. 위치별

| 위치 | 수 | 슬롯 이름 | 비고 |
|---|---|---|---|
| ❖ AppBar | 72 | `header content` · `subtitle content` · `child content` | 세트 변형 전수에 반복 |
| ❖ Card | 32 | `media content` · `child content` | 세트 변형 전수에 반복 |
| ❖ ResponsiveGrid | 24 | `children[]` | 25×40으로 리사이즈 |
| ❖ Footer | 6 | `aside content` | |
| ❖ Toast | 6 | `Skeleton` | 64×28, `action` 슬롯 |
| ❖ ScrollArea / FadeScroll | 4 + 4 | `child content` | 160×40 기본값 그대로 |
| ❖ RefreshTrigger | 4 | `child content` | Stage=idle · refreshing · completed 전부. **(코드 대조)** 단계는 idle · pulling · refreshing · completed 넷이고, 인스턴스 4개가 단계마다 하나씩입니다 |
| ❖ DraggablePanel | 4 | `Skeleton` | 296×82, 222×64 (text 변형 2개 포함) |
| ❖ Hero | 3 | `child` · `media` | |
| ❖ Scaffold | 3 | `sidebar content` · `child` · `floatingActionButton content` | circular 1개가 여기 |
| ❖ Dialog | 2 | `Skeleton` | 24×24, `leading` · `trailing` |
| ❖ Drawer | 2 | `Skeleton` | 608×380 (backdrop), 206×64 (content) |
| ❖ Scrollbar / Hidden / OverflowMarquee | 1 + 1 + 1 | `child content` · `child` | |
| 페이지 없음 (고아) | 10 | §3-3 참조 | |

인벤토리의 "Skeleton 16(내용 자리 용도)"은 **16개 컴포넌트 + 고아 10개**로 확인되며, 인스턴스 수는 179개입니다. `[검증 정정]` 초판은 17개로 적었지만 위 표의 컴포넌트를 세면 16개(AppBar · Card · ResponsiveGrid · Footer · Toast · ScrollArea · FadeScroll · RefreshTrigger · DraggablePanel · Hero · Scaffold · Dialog · Drawer · Scrollbar · Hidden · OverflowMarquee)이고, 인벤토리 값과 같습니다. 인스턴스 합계 179는 표와 맞습니다.

**(코드 대조)** 표에 적힌 세트 이름은 16개입니다. 빌더 전체로는 30개 세트가 Skeleton 을 씁니다. 나머지 14개(Swiper · Stacks · AspectRatioBox · ResponsiveContainer · ResponsiveRowColumn · ScrollableClient · ScrollViewInterceptor · StageContainer · Frame · Mask · MediaQueryVisibility · Clickable · Hover · Subfocus)는 페이지가 강등돼 지금은 생성되지 않습니다. 페이지를 되살리면 다시 생깁니다.

### 2-3. 이름 계열이 세 갈래로 갈립니다 — 이것이 역할 분리의 실체

| 계열 | 예 | 해석 | 수(대략) |
|---|---|---|---|
| **A. `<슬롯> content`** | `child content` · `media content` · `header content` · `subtitle content` · `aside content` · `sidebar content` · `floatingActionButton content` · `children[]` | 빌더가 **비어 있는 child 슬롯을 캔버스에서 보여주려고** 꽂은 더미. 대부분 160×40(= rectangular 기본값) 그대로 | 약 150 |
| **B. `Skeleton`** | Dialog `leading`/`trailing` 24×24 · Toast `action` 64×28 · DraggablePanel `child` · Drawer `backdrop` 608×380 | 의도적으로 배치된 Skeleton. 다만 "로딩 중"이 아니라 **그 자리에 들어갈 무언가의 대역**으로 보임 | 10~14 `[검증 정정]` |
| **C. `child` · `media` · `panel`** | Hero · Scaffold · OverflowMarquee · DraggablePanel | A와 B 중간. 슬롯 이름은 그대로지만 `content` 접미사가 없음 | 약 10 |

**(코드 대조)** 세 계열은 역할이 아니라 **빌더 헬퍼의 구현**에서 갈립니다.

- 세 계열 모두 같은 동작입니다. `W`/`W?` 슬롯(아무 위젯이나 받는 자리)을 Figma 에서 나타내는 수단은 교체 속성(INSTANCE_SWAP)뿐이고, 그 기본값은 컴포넌트 인스턴스여야 합니다. 빌더는 그 기본값으로 Skeleton 을 골랐습니다.
- 이유는 빌더 파일 머리 주석에만 적혀 있습니다: Skeleton 은 '디자인 시스템 자신의 content not here yet 상자' 이고, 색과 반경이 이미 계약에서 오므로 빌더가 색을 지어내지 않아도 된다는 것입니다. 개발자 문서와 플러그인 README 에는 이 규약이 없습니다.
- 이름 차이는 헬퍼가 인스턴스 이름을 바꾸느냐뿐입니다. `<슬롯> content` 로 바꾸는 헬퍼(A), 호출부가 슬롯 이름을 직접 넣는 곳(C), 이름을 바꾸지 않아 기본 이름 `Skeleton` 이 남는 `overlay.ts`(B).
- B 의 DraggablePanel `child` · `panel` 도 코드상 인스턴스 이름은 `Skeleton` 입니다. C 가 아니라 B 입니다.
- 코드(Flutter · Web 컴포넌트와 docs 예제)에는 이 자리 어디에도 Skeleton 이 없습니다.

`[검증 정정]` B의 "약 9"는 2-2 표와 맞지 않습니다. 이름이 `Skeleton`인 것만 세도 Toast 6 · Dialog 2 · Drawer 2로 10이고, DraggablePanel 4개 중 몇 개가 `Skeleton` 이름인지에 따라 최대 14입니다. 9는 인스턴스 수가 아니라 **자리(슬롯) 수**로 센 것일 수 있습니다. A 약 150은 A · B · C 합계(179 − 고아 10 = 169)에서 B · C를 뺀 값이라 B가 늘면 A가 그만큼 줄어듭니다. 정확한 분류는 Figma에서 이름별로 다시 세야 합니다.

A는 Mockup 작업에서 찾은 `OutlinedContainer` 빈 슬롯 결함(160×48, 반경 15)과 **같은 계열의 문제**입니다. 차이는 Mockup 쪽은 빈 프레임을 남겼고 여기는 Skeleton 인스턴스를 꽂았다는 점뿐입니다.

**(코드 대조)** 정책은 같은 계열(슬롯 = 교체 속성 + 대역)이지만 코드 경로는 다릅니다.

- OutlinedContainer 의 빈 칸은 다른 헬퍼가 그립니다. 칠이 없는 160×48 칸 안에 숨긴 Icon 글리프를 넣는 방식입니다. 글리프를 꺼도 칸은 일부러 남깁니다(주석: '빈 상자가 슬롯이 빈 래퍼의 모양').
- 반경 15 는 슬롯의 값이 아닙니다. OutlinedContainer 안쪽 프레임의 반경 16 에서 테두리 1 을 뺀 값입니다.
- 지금 빌더의 대역은 세 가지가 공존합니다: Skeleton 인스턴스, Icon 글리프 + 빈 칸, OutlinedContainer 인스턴스 자체(ContextMenu `child` · Carousel slide).

A가 문제인 이유는 세 가지입니다.

1. **의미가 거짓입니다.** AppBar의 `Variant=medium, Leading=menu` 변형이 캔버스에서 "로딩 중 AppBar"로 보입니다. 실제 AppBar는 로딩 중이 아닙니다.
   **(코드 대조)** 빌더는 이 대역 대부분을 **기본 숨김**으로 그립니다 — AppBar 세 슬롯, Card `media` · `child`, Toast `action`, Dialog `leading` · `trailing`, DraggablePanel `child`, Scrollbar `child`. 고아를 뺀 169개 중 115개가 숨은 인스턴스이고, 기본 자세에서 보이는 것은 54개입니다(ResponsiveGrid 24 · Footer 6 · ScrollArea 4 · FadeScroll 4 · RefreshTrigger 4 · Hero 3 · Scaffold 3 · DraggablePanel `panel` 2 · Drawer 2 · Hidden 1 · OverflowMarquee 1). '로딩 중으로 보인다' 는 이 54개에 해당합니다. 숨은 115개도 2 · 3 의 문제(인스턴스 수 · 편집 전파)는 그대로 만듭니다.
2. **인스턴스 수를 오염시킵니다.** Skeleton이 "많이 품어지는 부품" 3위(인벤토리 핵심 발견 5)인 것은 실제 재사용 때문이 아니라 빈 슬롯 때문입니다.
3. **리디자인 대조를 방해합니다.** Skeleton 세트를 고치면 AppBar · Card · Footer 등 16개 세트의 캔버스가 함께 변합니다. 디자인 의도와 무관한 변경입니다.

샘플 인스턴스의 오버라이드 필드는 전부 `["boundVariables","height","width"]`(+ A 계열은 `name`)입니다. 즉 **크기만 바꾸고 색·반경·변형은 건드리지 않습니다.** A 계열은 사실상 "회색 네모"로만 쓰이고 있습니다.

---

## 3. 문서 사이 충돌 — 조용히 고르지 않고 드러냅니다

### 3-1. state-layer 감사 기록과 실측이 다릅니다

`state-layer-full-audit-2026-08-25.md` §1-2는 Skeleton의 10개 채움을 `surface-container` 50%에서 **`color/surface-container-highest`로 바꿨다**고 기록합니다(근거: `surface-container` 위에서 ΔL* 0.00으로 보이지 않음).

**실측 결과 채움은 여전히 `color/surface-container`, 노드 불투명도 0.5입니다.** 10개 노드 전부입니다.

가능한 설명은 셋 중 하나이고, 어느 쪽인지는 코드만 알 수 있습니다.

- (a) 코드 계약은 바뀌었고 Figma 캔버스가 갱신되지 않았다 → 재생성 필요
- (b) Figma에서만 고쳤고 Generate에서 되돌아갔다 → 기존 소멸 패턴과 일치, 코드 계약은 여전히 `surface-container`
- (c) 감사 기록이 "할 것"을 "했다"로 적었다

`[검증 정정]` 감사 문서 본문을 다시 읽으면 수정 방식이 적혀 있습니다. **Figma에서 Skeleton 원본 노드 10개의 채움을 직접 바꿨고**, Footer · HeroSection 인스턴스 오버라이드도 Figma에서 걷어냈습니다. 코드 계약을 바꿨다는 기록은 없습니다. 그래서 **(b)가 가장 유력**합니다 — 파이프라인이 한 방향(코드 → Figma)이라 손으로 고친 값은 다음 Generate에서 되돌아갑니다. 코드 쪽 확인은 여전히 필요합니다(→ §9 Q2).

`[검증 정정]` 두 문서가 **서로 다른 잣대**를 씁니다. 감사의 "최저 3.20"은 대비비가 아니라 **ΔL\***(인지 가능 여부)이고, 이 문서 5절은 **WCAG 대비비**(3:1 충족 여부)입니다. "감사가 3:1을 넘기는 토큰을 골랐는데 실제로는 못 넘는다"로 읽으면 틀립니다. 감사는 3:1을 주장한 적이 없습니다.

감사에서 이 문서가 놓친 사실이 하나 있습니다. **Skeleton은 놓이는 표면에 따라 아예 안 보입니다.** 현재 채움 `surface-container` 50%를 `surface-container` 위에 놓으면 4모드 모두 ΔL\* 0.00입니다. 이 문서 5절은 배경을 `surface` 하나로만 계산했으므로, 리디자인 때는 표면 6종 전부에서 다시 재야 합니다.

→ §9 Q2.

**(코드 대조)** (a)는 배제됩니다.

- 코드 계약 · Flutter · Web · `components.json` · 빌더가 모두 `surface-container` 입니다.
- 저장소 이력에서 Skeleton 이 `surface-container-highest` 였던 적은 한 번도 없습니다(2026-04 이후 줄곧 `surface-container`).
- (b)와 (c) 중 어느 쪽인지는 코드로 가릴 수 없습니다. 빌더는 Generate 마다 채움을 계약에서 다시 묶으므로, Figma 에서만 고친 값은 되돌아갑니다 — (b)와 맞는 동작입니다.
- `state-layer-full-audit-2026-08-25.md` 는 저장소에 없습니다.

### 3-2. 상태 표현 통일 제안서의 보류 항목

`상태-표현-통일-제안.md` §1-4는 Skeleton의 `Enabled`를 "이름은 상태지만 상호작용 상태가 아닌 것 — 로딩 애니메이션 여부로 보임, 확인 필요"로 남겼습니다. §1-3과 §2-1의 실측이 이 추정을 지지하지만 확정하지는 못합니다. 결정 #1과 #4는 **이 한 축에서 겹칩니다.** 따로 결정하면 모순될 수 있습니다.

**(코드 대조)** 저장소에 있는 `상태-표현-통일-제안.md` 는 그 뒤 코드 대조를 거쳐 고쳐졌습니다.

- §1-4 의 Skeleton 행은 '렌더 여부다 … 애니메이션 여부가 아니다' 입니다.
- 같은 문서는 `Animated` 로 바꾸면 '코드와 반대 뜻이 된다' 고 적고, 축을 빼고 안 그려지는 상태는 레이어 숨김으로 보여 주는 쪽을 적었습니다.
- 이 문서가 인용한 '로딩 애니메이션 여부로 보임' 은 그 이전 판의 문구입니다. 저장소 판 제안서도 축을 빼는 쪽을 적었으므로, 두 결정은 지금 서로 어긋나 있지 않습니다(둘 다 아직 제안입니다).

### 3-3. 페이지에 속하지 않은 고아 노드 10개

Skeleton 인스턴스 10개가 **어떤 페이지에도 속하지 않은 컴포넌트** 안에 있습니다. 부모를 끝까지 타고 올라가면 `parent === null`입니다.

| 고아 상위 노드 | 추정 |
|---|---|
| `3774:342` `Variant=standard, Leading=back, Align=start` | 구 AppBar 변형 |
| `3774:366` `Variant=compact, Leading=back, Align=start` | 구 AppBar 변형 |
| `3774:390` `Variant=medium, Leading=back, Align=start` | 구 AppBar 변형 |
| `2467:93878` `Hero` | 구 Hero 컴포넌트 |

현재 AppBar 세트의 `Leading` 값에 `back`이 있는지, 이 네 노드가 이전 세대 잔존물인지 확인이 필요합니다. Skeleton 조사 범위를 넘어가므로 **별도 `[일반]` 항목 후보**로 적어 둡니다.

**(코드 대조)** 네 노드의 출처는 둘입니다.

- **AppBar 셋은 이전 세대가 아닙니다.** `Leading=back` 은 지금도 그려지는 값입니다. 빌더는 처음 생긴 2026-08-31 부터 지금까지 Leading 에 none · back · close · menu 를 그립니다. 같은 이름의 실제 멤버 셋은 다른 id(3062 · 3063 대역)로 세트 안에 있습니다. 그래서 고아 셋은 이름만 같은 별개의 지워진 노드입니다.
- 빌더는 노드를 복제(`clone()`)하지 않으므로 이 셋은 빌더 산출물이 아닙니다. 외부 스크립트가 만든 노드로 보입니다. 09-08 무렵 숨긴 슬롯의 폭을 재려고 Variant 마다 멤버를 복제했다 지운 기록(#4716)과 수가 맞습니다(추정 — 노드 id 를 남긴 기록은 없습니다).
- **Hero 는 추정이 맞습니다.** 옛 단일 컴포넌트 `HeroSection` 입니다. #5062 가 `Hero` 로 이름을 바꾼 직후, 단일 컴포넌트를 세트로 바꾸는 구조 전환에서 지웠습니다. 이름이 `HeroSection` 이 아니라 `Hero` 인 것이 그 순서와 맞습니다.
- Skeleton 10개는 코드의 슬롯 수와 정확히 맞습니다: AppBar 멤버 하나에 3개 × 3 + 옛 HeroSection 의 `child` 1개.
- 플러그인에는 페이지 밖(`parent === null`) 노드를 찾거나 정리하는 도구가 없습니다. 고아 노드 보기 · 겹친 형제 보기는 페이지 안만 봅니다.

---

## 4. 다른 디자인 시스템은 어떻게 하나

### 4-1. 두 갈래로 갈립니다

**갈래 1 — 범용 한 컴포넌트 + 모양 축 (CoUI와 같은 계열)**

| 시스템 | API |
|---|---|
| MUI | `variant: 'text' \| 'circular' \| 'rectangular' \| 'rounded'` (기본 `text`) + `animation: 'pulse' \| 'wave' \| false` (기본 `pulse`) + `width` · `height` · `children` |
| Ant Design | `active`(애니메이션 on/off, 기본 false) + `loading`(스켈레톤을 그릴지 실제 콘텐츠를 그릴지) + `avatar` · `title` · `paragraph` · `round`, 그리고 `Skeleton.Avatar/Button/Input/Image/Node` |
| shadcn/ui | 단일 `Skeleton` div. 축 없음. 모양은 호출자가 클래스로 |

**갈래 2 — 콘텐츠 종류별 별도 컴포넌트**

| 시스템 | 컴포넌트 |
|---|---|
| Shopify Polaris | `SkeletonBodyText` · `SkeletonDisplayText` · `SkeletonThumbnail` · `SkeletonTabs` · `SkeletonPage` |
| IBM Carbon | `SkeletonText` · `SkeletonPlaceholder` · `SkeletonIcon` + 컴포넌트별 스켈레톤(`DataTableSkeleton` 등) |

Polaris는 `SkeletonPage`를 "콘텐츠가 나타나기 전 UI의 저충실도 표현"으로 정의하고, 대안 패턴으로 Progress bar와 Spinner를 명시적으로 함께 안내합니다.

### 4-2. CoUI에 의미 있는 세 가지 시사점

1. **Ant는 CoUI의 `Enabled`가 섞어 놓은 두 뜻을 분리해 둡니다.** `active`는 애니메이션 여부, `loading`은 스켈레톤이냐 실제 콘텐츠냐입니다. CoUI의 `Enabled` 하나로는 둘 중 어느 쪽인지 이름만으로 알 수 없습니다. 실제로 `상태-표현-통일-제안.md`가 그래서 보류했습니다.
   **(코드 대조)** CoUI 의 `Enabled` 는 둘 중 어느 쪽도 아닌 '그리느냐 마느냐' 입니다(§1-3). 그리고 Flutter 에만 있는 `asSkeleton(enabled:)` 은 Ant 의 `loading` 뜻입니다(끄면 원래 자식을 그림). 같은 단어가 Flutter 의 두 API 에서 다른 뜻으로 쓰입니다.
2. **MUI의 `children`이 A 계열 문제를 구조적으로 푸는 방식입니다.** MUI `Skeleton`은 자식을 받아 그 자식의 폭·높이를 추론합니다. 즉 "콘텐츠 자리"를 Skeleton이 아는 방식이 있습니다. CoUI는 호출자가 숫자로 넣어야 하므로(`Skeleton(width: 200, height: 20)`) 빌더가 기본값 160×40을 꽂게 됩니다.
   **(코드 대조)** 앞부분은 맞고 인과는 다릅니다.
   - CoUI `Skeleton` 은 자식이 없는 잎 컴포넌트입니다. rectangular · circular 는 크기를 주지 않으면 사실상 보이지 않으니, '숫자로 넣어야 한다' 도 그 두 변형에는 맞습니다(text 는 부모 폭을 채움).
   - 하지만 빌더가 160×40 을 꽂는 이유는 이 API 가 아닙니다. 교체 속성의 기본값이 컴포넌트여야 해서 Skeleton 세트의 미리보기 상자를 그대로 물려받은 것입니다(§2-3). 그래서 MUI 식 `children` 을 들여와도 R2 의 빌더 동작은 바뀌지 않습니다.
   - Flutter 에는 자식 트리에서 모양을 가져오는 공개 API `asSkeleton()`(서드파티 skeletonizer)이 이미 있습니다. Web 에는 없고, 규칙(`widget/loading-states.md` '스켈레톤은 하나의 메커니즘이다')이 '표준이 아니다' 라고 적은 바로 그 방식입니다(§9-1).
3. **갈래 2를 통째로 들여올 근거는 약합니다.** Polaris · Carbon의 종류별 컴포넌트는 컴포넌트 수를 크게 늘립니다. CoUI는 이미 133세트이고, 인벤토리 기준 Skeleton은 A등급 Primitive 순서 1입니다. 범용 1개 + 반경·크기를 호출자가 넘기는 지금 구조가 CoUI 규모에 맞습니다. 대신 **"그 자리에 무엇이 들어오는지"를 Skeleton이 알 수 있게 하는 것**(시사점 2)이 갈래 2의 효용을 구조 증가 없이 가져옵니다.

---

## 5. 대비와 접근성 — 왜 "더 진한 토큰"이 답이 아닌지

### 5-1. 합성 후 값 계산

Skeleton tint = 토큰 색 × 노드 불투명도, 배경은 `color/surface`. 네 모드 실측값으로 계산했습니다.

`color/surface` = Light `#fcfcfd` · Dark `#18191b` · HCLight `#fcfcfd` · HCDark `#18191b`

| 토큰 | 불투명도 | Light 대비 | Dark 대비 |
|---|---|---|---|
| `surface-container` (현재) | 0.5 (`fromOpacity`) | **1.10 : 1** | **1.12 : 1** |
| `surface-container` | 1.0 (`toOpacity`) | 1.24 : 1 | 1.26 : 1 |
| `surface-container-high` | 1.0 | 1.43 : 1 | 1.54 : 1 `[검증 정정]` |
| `surface-container-highest` (감사가 제안) | 0.5 | 1.29 : 1 | 1.41 : 1 |
| `surface-container-highest` | 1.0 | 1.72 : 1 | 2.14 : 1 |
| `outline-variant` | 0.5 | 1.29 : 1 | 1.67 : 1 |
| `outline-variant` | 1.0 | ~~4.01~~ **1.70 : 1** `[검증 정정]` | **3.02 : 1** |
| `outline` | 0.5 | 2.11 : 1 | 2.97 : 1 |
| `outline` | 1.0 | **5.68 : 1** | **8.02 : 1** |

`[검증 정정]` 재계산 근거 — WCAG 상대 휘도 공식으로 다시 계산했습니다. 색 값은 다른 프로젝트 문서에 적힌 실측값을 썼습니다.

- `outline-variant` Light `#c3c4c6`은 이 문서 5-2(3)에 적힌 값입니다. `#c3c4c6` 대 `#fcfcfd`는 1.70입니다. 4.01은 HCLight 값(`#7d7f82`, 3.92)과 비슷해 모드를 섞어 적은 것으로 보입니다.
- 그런데 `#c3c4c6`은 `surface-container-highest` Light와 **같은 색**입니다(`on-surface-variant` `#4d4e51`과의 대비가 4.77이 되는 회색 단계가 이것뿐 — `on-surface-variant-회귀-및-placeholder-토큰.md`의 4.77에서 역산). 즉 Light에서는 두 토큰이 같은 값이라 대비도 같아야 하고, 표의 1.72와 1.70이 그 결과입니다(소수점 차이는 반올림).
- `outline`은 Light `#646568` · Dark `#aeafb2`(같은 문서 2절). `placeholder` 글자색과 같은 값입니다.
- `surface-container` Dark는 `#27282b`(`button-state-color-swap.md`)로 계산하면 0.5에서 1.08, 1.0에서 1.19로 표보다 조금 낮게 나옵니다. 초판이 쓴 값을 알 수 없어 고치지 않고 이 차이만 적어 둡니다. 결론은 바뀌지 않습니다.
- `surface-container-highest` Light · Dark 값은 실측이 아니라 **역산**입니다. Figma 변수에서 직접 확인해야 확정됩니다.

**(코드 대조)** 코드의 색 생성기로 뽑은 기본 브랜드(CoUI, monochrome 매핑) 네 모드 값으로 다시 계산한 결과입니다. `surface` 값(Light `#fcfcfd` · Dark `#18191b`)은 문서와 같습니다.

| 토큰 | 불투명도 | Light / Dark / HCLight / HCDark |
|---|---|---|
| `surface-container` | 0.5 | 1.11 / 1.09 / 1.11 / 1.09 |
| `surface-container` | 1.0 | 1.23 / 1.19 / 1.23 / 1.19 |
| `surface-container-high` | 1.0 | 1.42 / 1.54 / 1.42 / 1.54 |
| `surface-container-highest` | 0.5 | 1.29 / 1.40 / 1.29 / 1.40 |
| `surface-container-highest` | 1.0 | 1.70 / 2.11 / 1.70 / 2.11 |
| `outline-variant` | 1.0 | **1.70** / 3.02 / 3.92 / 8.02 |

- 위 `[검증 정정]` 과 같은 결론입니다. 코드에서도 Light 의 `outline-variant` 는 `surface-container-highest` 와 **같은 색**(`#c3c4c6`)이라 1.70 : 1 이고, 4.01 은 HCLight 의 `outline-variant`(`#7d7f82`)를 흰색 위에 놓은 값(4.015)과 같습니다 — HC 값이 Light 칸에 들어간 것으로 보입니다.
- `surface-container-highest` 의 값은 2판에서 역산이었지만, 코드의 생성기 값으로 확인됩니다(1.70 · 2.11). Figma 변수가 코드와 같은지는 따로 대조해야 확정됩니다.
- Dark 의 `surface-container`(`#27282b`)는 1.09 · 1.19 로, 2판이 적은 차이(1.08 · 1.19)와 같습니다. 표의 1.12 · 1.26 은 `#2b2c2f` 정도에서 나옵니다.
- 나머지 차이는 0.03 이하라 결론은 같습니다.

### 5-2. 그래서 나오는 결론 세 가지

**(1) 감사가 제안한 `surface-container-highest`도 3:1에 도달하지 못합니다.** 1.72 : 1(Light) · 2.14 : 1(Dark)입니다. 즉 §3-1의 수정이 실제로 반영되었더라도 WCAG 1.4.11 기준은 통과하지 못합니다. 이 시스템이 단색이라 surface 계단 어디에도 3:1이 없습니다.

**(코드 대조)** 수치는 코드 값으로도 같습니다(1.70 · 2.11).

**(2) `fromOpacity: 0.5`가 있는 한 어떤 토큰으로도 3:1은 불가능합니다.** 50%로 합성하면 `outline`조차 Light 2.11 : 1 · Dark 2.97 : 1입니다. 3:1을 목표로 한다면 **불투명한 두 토큰 사이를 왕복**해야 하고, `fromOpacity`/`toOpacity` 필드 구조 자체가 바뀝니다(구조 변경).

**(2-1) `[검증 정정]` 불투명하게 칠해도 Light에서 3:1에 닿는 것은 `outline` 하나뿐입니다.** `outline-variant`는 Light 1.70이라 통과하지 못합니다. `outline`(`#646568`)은 플레이스홀더 글자와 같은 색이라, 스켈레톤 블록이 본문 글자에 가까운 무게로 그려집니다. Roselli도 3:1을 맞춘 자기 예제를 "ugly"라고 적었습니다(5-3). 3:1을 목표로 두는 것은 사실상 **"스켈레톤을 진한 회색 블록으로 바꾼다"** 는 뜻입니다.

**(코드 대조)** 표의 후보로 한정하면 맞습니다(@0.5 최댓값은 HCDark `outline-variant` 2.97). 세 가지를 덧붙입니다.

- '어떤 토큰으로도' 는 지나칩니다. `outline` @0.5 는 HCDark 3.95, `on-surface` @0.5 는 Light 3.34 · Dark 5.13 입니다.
- Light 에서는 불투명으로 써도 표의 후보 어느 것도 3:1 에 닿지 않습니다(`outline-variant` = `surface-container-highest` = 1.70). Light 에서 3:1 을 넘는 중립 토큰은 `outline`(5.68) 부터입니다. 그런데 코드는 `outline` 을 '컨트롤 경계' 로, `outline-variant` 를 일부러 3:1 아래에 둔 hairline 으로 정의하고, 대비 가드도 그렇게 검사합니다.
- '구조 변경' 은 필드를 지우지 않고 두 번째 색 필드를 더하는 방식으로도 할 수 있습니다. 그 경우 폐기 창(두 마이너)은 붙지 않고, 대신 기본값 변경이 모든 소비자의 렌더를 바꿉니다.

**(3) HCLight · HCDark에서 surface 계단이 전혀 움직이지 않습니다.** 실측상 `surface` · `surface-container` · `-high` · `-highest` 네 토큰 모두 HCLight = Light, HCDark = Dark로 **동일한 값**입니다. 반면 `outline-variant`는 Light `#c3c4c6` → HCLight `#7d7f82`, Dark `#646568` → HCDark `#aeafb2`로 움직이고, `on-surface`도 순검정·순백으로 움직입니다.

**(코드 대조)** 관찰은 코드와 같습니다. 다만 결함이 아니라 **기록된 설계의 결과**입니다.

- 고대비 세트는 surface 계열을 어느 방향으로도 바꾸지 않습니다. 코드 주석과 규칙(`core/theme-axis-composition.md` '고대비 축 — 일부러 하지 않는 두 가지')이 이유를 적습니다: 카드 · 입력 · 팝오버는 배경 톤으로 구분되고 일부만 테두리를 그리므로, 톤을 흰색으로 눕히면 경계가 사라집니다.
- Web 은 HC 블록에서 surface 계열을 통째로 빼고, 테스트가 이를 고정합니다.
- 규칙이 글자로 금지하는 것은 '흰색으로 눕히기' 이고 '계단 벌리기' 를 직접 금하지는 않습니다. 그래도 HC 에서 surface 를 움직이려면 그 기록된 결정을 다시 열어야 합니다.
- Skeleton 하나의 채움만 HC 에서 움직이는 토큰으로 바꾸는 것은 이 규칙과 부딪히지 않습니다. 다만 컴포넌트는 축(HC 여부)을 읽지 않으므로 정상 모드의 모습도 함께 바뀝니다.

> **따라서 "고대비 모드에서 스켈레톤이 더 잘 보여야 한다"를 요구사항으로 두면, 채움 토큰은 surface 계열이 아니라 outline 계열이어야 합니다.** `[검증 정정]` 다만 `outline-variant`는 HC에서만 진해지고(HCLight 3.92 · HCDark 8.02) Light에서는 `surface-container-highest`와 같은 값입니다. "HC에서 진해진다"와 "Light에서 3:1"은 서로 다른 요구이고, 둘 다 원하면 `outline`까지 가야 합니다. surface-container 계열을 아무리 올려도 HC 모드에서 한 톤도 바뀌지 않습니다. 이것은 Skeleton만의 문제가 아니므로 결정 #1·#3과 함께 볼 항목입니다.

**(코드 대조)** 표면 스타일 neoBrutalism 에서는 Skeleton 에 이미 `outline` 색 4px 테두리가 기여됩니다(Light 5.68 : 1, 테두리는 맥동하지 않음). 위 표와 캔버스는 기본 스타일만 봅니다. 한편 규칙(`core/theme-axis-composition.md` 따름정리 3)은 스켈레톤 류를 '의도적으로 경계가 없는 표면' 으로 분류해, 코드 선언과 갈려 있습니다.

### 5-3. 외부 기준이 말하는 것

Adrian Roselli의 접근성 스켈레톤 정리는 다음을 권합니다. `[검증 정정]` 원문을 다시 확인해 단서를 보탰습니다.

- 콘텐츠 컨테이너에 `aria-busy="true"`, 스켈레톤 도형 자체는 `aria-hidden="true"`. 단 원문은 **"`aria-busy`를 지키는 스크린리더는 많지 않다"** 고 적고, 그래서 `aria-hidden`과 함께 쓰라고 합니다
- 시각적으로 숨긴 "Loading" 텍스트를 넣어 **낭독으로** 상태를 전달
- 애니메이션은 `prefers-reduced-motion`을 설정하지 않은 사용자에게만, WCAG 2.2.2에 따라 **5초 후 정지**
- 대부분의 스켈레톤은 대비가 나쁘다고 지적. 원문 예제는 진한 회색으로 3:1을 맞췄지만 저자 스스로 그 결과를 "ugly"라고 평가합니다

`[검증 정정]` Carbon 이슈 #4310("Component skeletons (loading states) need a11y improvements for screen reader users")은 **닫혀 있습니다.** 컴포넌트마다 `role="status"` · `aria-live` 등을 붙이자는 제안이었고, 팀이 "컴포넌트별로 고치지 않고 다른 해법을 찾겠다"며 닫았습니다. 초판의 "남아 있다"는 틀렸습니다. 그래도 결론은 같습니다 — **대비로만 푸는 곳은 없고, 낭독이 실제 접근성 경로**이며, 그 낭독을 컴포넌트 하나하나가 아니라 **콘텐츠 영역 단위**로 처리하려는 방향입니다. CoUI EmptyState 조사(6-3)에서 본 "결과 수 변화 낭독은 WCAG 4.1.3의 영역"과 같은 결입니다.

이것이 §6의 선택지와 직결됩니다. 지금 CoUI 계약에는 낭독·`aria-busy`·`prefers-reduced-motion`·5초 정지에 해당하는 필드가 **하나도 없습니다**(§1-1 전수). 대비를 올리는 것보다 이쪽이 결손이 큽니다.

**(코드 대조)** '필드' 가 없다는 것은 맞습니다. 하지만 낭독과 모션은 Style 필드가 아니라 위젯 동작으로 이미 정해져 있습니다.

- **낭독은 있습니다.** Flutter 는 `Semantics(liveRegion, label)`, Web 은 `role="status"` + `aria-label` 이고, 라벨은 둘 다 로케일의 `loadingLabel`(en 'Loading' · ko '로딩 중')입니다. 다만 **스켈레톤 하나마다** live region 이 붙습니다. 카드 하나를 Skeleton 3개로 조립하면 알림도 3개입니다 — 위 권고(도형은 숨기고 컨테이너 하나가 알림)와 반대 구조입니다.
- **동작 줄이기에서 맥동을 멈추지 않는 것은 결손이 아니라 규칙에 따른 결정**입니다. `widget/loading-states.md` '맥동은 표시 tier 다' 가 '멈춘 스켈레톤은 로딩이 끝났다고 말하는 것과 구별되지 않는다' 며 억제하지 않는다고 정했고, 두 플랫폼 모두 그렇게 구현 · 테스트돼 있습니다. 5초 후 정지도 같은 이유로 규칙과 부딪힙니다(D11).
- **실제로 없는 것**은 `aria-busy`, 도형의 `aria-hidden`, N초 후 정지입니다. Flutter SDK 에는 busy 에 해당하는 시맨틱이 없습니다. Web 컨테이너(Card 등)는 호출자의 `aria-*` 를 이미 통과시키지만, Web Skeleton 자신은 호출자 속성을 받지 못합니다(생성자에 없고 `copyWith` 가 버림).

---

## 6. 역할 분리 — 세 가지로 나누어 보는 안

§2-3의 세 계열을 그대로 역할로 승격시킨 것이 가장 단순합니다.

| 역할 | 지금 어떻게 되어 있나 | 어떻게 해야 하나 (제안) |
|---|---|---|
| **R1. 로딩 자리 표시자** | Skeleton 본래 용도. 다만 낭독·감속 모션·정지 계약이 없음. **(코드 대조)** 낭독은 있습니다(스켈레톤마다). 감속 모션 · 정지가 없는 것은 규칙에 따른 결정입니다(§5-3, D11) | Skeleton을 R1 전용으로 좁히고 §9 Q3의 필드를 보강 |
| **R2. 빈 슬롯의 캔버스 표시** | 빌더가 Skeleton 인스턴스를 꽂음(약 150개) | **Skeleton을 쓰지 않습니다.** 빌더 전용 자리 표시 수단(점선 프레임 등)을 별도로 두고, 생성 결과에서 Skeleton 인스턴스를 제거. **(코드 대조)** 빌더 머리 주석에 적힌 의도된 동작입니다(§2-3). 캔버스에서 손으로 지우면 다음 Generate 가 되살리므로 빌더 헬퍼 다섯 곳을 고쳐야 합니다. 교체 속성의 기본값은 컴포넌트여야 하고 CI 가드가 `W`/`W?` 슬롯마다 교체 속성을 요구하므로, 점선 프레임만으로는 대신할 수 없고 대역 컴포넌트가 필요합니다(D8) |
| **R3. 미구현·미정 영역 표시** | Dialog `leading`/`trailing` 24×24, Drawer `backdrop` 608×380, Toast `action` 64×28 등 | 각 컴포넌트에서 개별 판단. backdrop에 Skeleton이 들어간 것은 결함으로 보임. **(코드 대조)** 이 자리들은 R2 와 같은 대역이고 '미구현' 인 것은 없습니다. Drawer `backdrop` 은 슬롯이 아니라 앱 셸이 띄우는 **앱 화면**(Drawer 가 뒤로 축소하는 navigator)의 대역이라 성격이 다릅니다(608×380 = 640×400 × 0.95, D10) |

R2를 분리하는 것이 결정 #4의 핵심이고, 효과가 가장 큽니다.

- Skeleton 인스턴스 179개 중 약 150개가 사라지고, 16개 세트의 캔버스에서 "로딩 중처럼 보이는" 거짓 표현이 사라집니다. **(코드 대조)** 보이는 것은 54개, 숨은 것은 115개입니다(§2-3).
- Skeleton 리디자인이 다른 16개 세트를 흔들지 않게 됩니다.
- 인벤토리의 "많이 품어지는 부품" 순위가 실제 재사용을 반영하게 됩니다.

다만 R2는 **디자인 결정이 아니라 빌더 동작**입니다. 그래서 `[리디자인]`이 아니라 `[일반]` 이슈 계열이고, EmptyState의 빌더 결함(C11)과 묶어 처리할 여지가 있습니다. 실제로 `OutlinedContainer` 빈 슬롯 결함(Mockup 조사 §5)과 같은 뿌리일 가능성이 높습니다. **(코드 대조)** 같은 정책 계열이지만 코드 경로는 다릅니다(§2-3).

### 6-1. `Enabled` 축 처리 — 세 선택지

| 안 | 내용 | 평가 |
|---|---|---|
| **(a) 삭제** | `axes.enabled` 제거. 애니메이션은 항상 켜고 `prefers-reduced-motion`으로만 끔 | **권장.** 소비 0건(§2-1), 캔버스 차이 0(§1-3), 그리고 **CoUI 안에 선례가 있습니다** — `Loading` 세트는 `Variant: spinner · dots · bar · pulse` + `Size: xs~xl2`뿐이고 애니메이션 on/off 축이 없습니다. 공개 API 제거이므로 `@Deprecated` 예고 후 두 마이너 릴리스가 필요합니다 |
| (b) 이름을 바로잡아 유지 | `Enabled` → `Animated`(Ant의 `active`에 해당) | 뜻은 명확해지지만 변형 수가 6으로 유지되고, 캔버스에서 여전히 구분되지 않습니다 |
| (c) 뜻을 바꿔 유지 | `Enabled`를 Ant의 `loading`처럼 "스켈레톤이냐 실제 콘텐츠냐"로 | 호출자가 조건부 렌더로 이미 하는 일이고, Figma 변형으로는 표현 불가 |

(a)를 권합니다. 근거는 세 관점 모두에서 같은 방향입니다. 외부(Loading 계열은 보통 축을 두지 않고, Ant의 `active`도 기본 false인 선택적 효과) · 실무(소비 0) · CoUI 내부 일관성(`Loading` 선례, 그리고 `상태-표현-통일-제안.md`가 "이름은 상태지만 상호작용 상태가 아닌 것"으로 분류한 축을 줄이는 방향).

**(코드 대조)** 세 안 모두 `Enabled` 를 애니메이션으로 읽은 전제 위에 있습니다. 코드 뜻(렌더 여부)으로 다시 보면 이렇습니다.

- **(a) 삭제** — 폐기 절차(예고 후 두 마이너)는 맞습니다. 다만 지울 것은 Figma 축이 아니라 공개 API 입니다: 계약의 `enabled`, 양 플랫폼 생성자 · `.circle` · `.text` · `copyWith` 의 `enabled`. Figma 축은 익스포터가 계약에서 기계적으로 만들므로 캔버스만 따로 뺄 수 없습니다. 예고 메시지에 적을 대체재는 '항상 애니메이션' 이 아니라 '호출자가 조건부로 그리기' 입니다.
- (a) 의 '애니메이션은 항상 켜고 `prefers-reduced-motion` 으로만 끔' 은 규칙과 부딪힙니다(§5-3, D11).
- **(b) `Animated`** — 이름뿐 아니라 뜻이 바뀝니다. `Animated=false` 는 멈춘 스켈레톤을 남기는데, 규칙은 그 상태를 막습니다.
- **(c)** 가 지금 뜻에 가장 가깝습니다(그리느냐 마느냐). 다만 끄면 자식이 아니라 빈 자리가 남습니다.
- **Loading 선례** — Loading 은 계약에 `enabled` 자체가 없어서(렌더 토글도 없음) 축이 없는 것이고, Loading 도 동작 줄이기에서 멈추지 않습니다. '동작 줄이기로만 끈다' 의 선례가 아니라 반대 사례입니다.

### 6-2. 반경 — 결정 #3과 겹칩니다

실측 반경은 rectangular 8, text 4, circular 9999입니다. `반경-사다리-제안.md`의 사다리(부품 4 / 컨트롤 8 / 패널 12 / 표면 16 + full + 0)에 비추면,

- text 줄 = 4(부품) — 사다리와 맞습니다
- circular = full — 맞습니다
- rectangular = 8(컨트롤) — **Skeleton은 컨트롤이 아닙니다.** 그리고 Skeleton이 대신 서는 대상은 아바타(full)일 수도, 카드(16)일 수도, 썸네일(12)일 수도 있습니다

즉 **Skeleton의 반경은 고정값이 아니라 "대역을 서는 대상의 반경"이어야 합니다.** `tokenChain` 예시에 `Skeleton(…).radius0`이 있고 `withStyle`에 `borderRadius`가 있으므로 호출자가 바꿀 수단은 이미 있습니다. 문제는 **기본값 8이 중립적이지 않다**는 점입니다. 결정 #3에서 "Skeleton의 기본 반경"을 함께 정해야 합니다.

**(코드 대조)** `.radius0` 은 익스포터가 찍은 첫 getter 라 기본값의 신호가 아닙니다(§1-1). 반경 제안서의 실제 파일은 `컨테이너-반경-사다리-제안.md` 이고, Skeleton 항목은 그 문서 §5 표에 있습니다(같은 권고: '대신하는 요소의 반경을 따른다').

---

## 7. 결정 #4가 결정 #1·#3과 겹치는 지점

| 겹침 | 내용 | 따로 결정하면 생기는 문제 |
|---|---|---|
| #1 (상태 표현 통일) | `Enabled` 축의 처리 | #1이 "값 상태는 별도 축"으로 가면 `Enabled`를 남길 근거가 되고, #4가 삭제로 가면 모순 |
| #3 (반경 사다리) | rectangular 기본 반경 8 | #3이 사다리를 확정하고 #4가 Skeleton 반경을 따로 정하면 두 번 바꾸게 됨 |
| 신규 | HC 모드에서 surface 계단이 안 움직인다는 사실(§5-2-3) | Skeleton만의 문제가 아니라 **색 토큰 차원의 문제**입니다. #1 범위에 넣는 것이 맞아 보입니다 **(코드 대조)** 고대비 설계에 기록된 결정입니다(§5-2 (3)). #1 에 올린다면 '결함 수정' 이 아니라 그 결정을 다시 여는 안건입니다 |

**권고: #4는 #1·#3 결정 이후에 확정하고, 지금은 §9의 코드 확인만 먼저 받습니다.** 단 R2(빌더가 꽂은 Skeleton 제거)는 디자인 결정과 무관하므로 **먼저 분리해 진행할 수 있습니다.**

---

## 8. 내 결정 대기 항목

| # | 안건 | 선택지 |
|---|---|---|
| D1 | R2를 분리할 것인가 | 분리(권장) / Skeleton을 빈 슬롯 표시로도 계속 인정 |
| D2 | R2를 어느 이슈로 낼 것인가 | EmptyState 빌더 결함 `[일반]`에 합치기 / Skeleton 전용 `[일반]` 하나 / `OutlinedContainer` 빈 슬롯까지 묶어 "빌더 빈 슬롯" `[일반]` 하나(권장) |
| D3 | `Enabled` 축 | 삭제(권장) / `Animated`로 개명 / 유지. **(코드 대조)** `Enabled` 는 렌더 여부라 `Animated` 개명은 뜻이 바뀝니다. 삭제의 대체재는 '호출자가 조건부로 그리기' 입니다(§6-1) |
| D4 | 접근성 목표 | 3:1 달성을 목표로 둔다(→ `fromOpacity` 구조 변경 + `outline` 불투명. Light에서 `outline-variant`는 1.70이라 부족 `[검증 정정]`) / 낭독과 `aria-busy`를 접근성 경로로 두고 대비는 지각 가능 수준까지만 올린다(권장, 외부 관행과 일치). **(코드 대조)** 낭독은 이미 스켈레톤마다 있고 `aria-busy` 는 없습니다(§5-3, D12). 3:1 을 고르면 D16 이 함께 걸립니다 |
| D5 | HC 모드에서 Skeleton이 더 진해져야 하는가 | 그렇다(→ 채움을 `outline-variant`로. HC에서만 진해지고 Light 값은 지금 감사안과 같음, #1에 상정 `[검증 정정]`) / 아니다(장식으로 간주). **(코드 대조)** 채움 토큰만 바꾸는 것은 규칙과 부딪히지 않지만 정상 모드 모습도 바뀝니다. surface 계열을 HC 에서 움직이는 것은 기록된 결정을 다시 여는 일입니다(§5-2 (3)) |
| D6 | rectangular 기본 반경 | 결정 #3 확정까지 보류(권장) / 지금 8 유지 / 0으로 중립화 |
| D7 | §3-3 고아 노드 10개 | 별도 `[일반]`으로 낸다 / Skeleton 범위 밖으로 두고 기록만 남긴다. **(코드 대조)** 출처가 둘입니다 — Hero 는 의도된 구조 전환의 잔해, AppBar 셋은 외부 스크립트가 만들었다 지운 노드로 보입니다(§3-3) |
| D8 | **(코드 대조)** R2 의 대역 수단 | 빌더 전용 대역 컴포넌트를 새로 둔다(둘 페이지 · 라이브러리 게시 여부 포함) / Skeleton 을 대역으로 계속 쓴다 / `W`/`W?` 슬롯마다 교체 속성을 요구하는 CI 가드를 완화한다 |
| D9 | **(코드 대조)** 대역 규약을 어디까지 맞추나 | Skeleton 인스턴스 · Icon 글리프 + 빈 칸 · OutlinedContainer 인스턴스 셋을 D2 의 이슈에서 같이 / Skeleton 만 / 대역은 그대로 두고 인스턴스 이름 규칙만 하나로 |
| D10 | **(코드 대조)** 슬롯이 아닌 대역 — Drawer `backdrop`(앱 화면), DraggablePanel · Swiper 의 뒤 페이지 | R2 와 같은 수단으로 / 따로 정한다 |
| D11 | **(코드 대조)** 맥동 모션 정책 — 규칙 `widget/loading-states.md` '맥동은 표시 tier 다' 와 §5-3 · §6-1 (a) 의 권고가 부딪힘 | 지금 규칙을 유지한다(동작 줄이기에서도 맥동, 정지 없음) / 규칙을 바꿔 동작 줄이기 정지 또는 N초 후 정지를 들인다(규칙 변경은 개발자가 규칙 PR 로 낸다) |
| D12 | **(코드 대조)** 낭독 단위 | 지금처럼 스켈레톤마다 알림 / 컨테이너 하나로 — Web 은 호출자가 `aria-busy` 를 붙이고 Skeleton 은 숨긴다(Web Skeleton 이 호출자 속성을 받게 고쳐야 함), Flutter 는 대응 시맨틱이 없다 |
| D13 | **(코드 대조)** 캔버스의 `Enabled=false` 를 무엇으로 그리나(D3 와 묶임) | 코드 뜻대로 빈(숨긴) 상태 / 지금처럼 true 와 같게 / D3 에서 축을 빼면 해당 없음 |
| D14 | **(코드 대조)** 맥동 한 주기의 기준 — 지금 Flutter 는 왕복 2초, Web 은 왕복 1초 | `duration` = 왕복 한 주기(Web 기준) / `duration` = 한 방향(Flutter 기준) |
| D15 | **(코드 대조)** Flutter 에만 있는 `asSkeleton()` 경로(skeletonizer, 채움 primary 5% → 10%) | 그대로 둔다 / 폐기 절차를 밟는다 / Web 대응을 만든다 |
| D16 | **(코드 대조)** D4 에서 3:1 을 고를 때의 토큰과 판정 프레임 | Light 는 `outline`(컨트롤 경계 토큰)을 채움에 다시 쓴다 / 새 시맨틱 슬롯을 만든다 — 그리고 쉬는 프레임(0.5) · 정점(1.0) · 둘 다 중 어디서 판정할지 |

---

## 9. Claude Code에 보낼 질문

> **Q1. `axes.enabled`는 정확히 무엇을 켜고 끕니까?**
> Figma 캔버스에서 `Enabled=true`와 `false`가 측정한 모든 속성에서 동일합니다. 계약에 `fields.duration` · `fromOpacity` · `toOpacity`가 있으니 깜빡임 애니메이션의 on/off로 추정하는데, 맞습니까? 아니면 Ant Design의 `loading`처럼 "스켈레톤 대신 실제 자식을 렌더"에 해당합니까? 코드에서 `enabled`가 분기하는 지점을 알려 주세요.

**답 (코드 대조)** 렌더 여부입니다. 깜빡임 on/off 도, Ant `loading` 식 '실제 자식 렌더' 도 아닙니다.

- `false` 면 아무것도 그리지 않습니다. Skeleton 은 자식이 없어 대신 그릴 것도 없습니다.
- 분기 지점: Core 계약 `skeleton_contract.dart` 의 `enabled` 주석('When false, renders nothing'), Flutter `skeleton.dart` 의 `build` 첫 줄 `SizedBox.shrink()`(맥동도 시작하지 않거나 멈춤), Web `skeleton.dart` 의 `build` 첫 줄 숨긴 빈 `div`(`role="status"` · `aria-label` 도 함께 빠짐).
- 기본값은 두 플랫폼의 모든 생성자에서 `true` 입니다.
- Figma 에 축이 생긴 것은 익스포터가 계약에 `bool get enabled` 가 있으면 뜻과 상관없이 축으로 올리는 일반 규칙 때문입니다. 빌더는 `Variant` 만 읽고 `Enabled` 는 읽지 않아 여섯 변형이 세 쌍씩 같습니다(§1-3).

> **Q2. 채움 토큰이 `surface-container`입니까 `surface-container-highest`입니까?**
> `state-layer-full-audit-2026-08-25.md` §1-2는 10개 채움을 `color/surface-container-highest`로 바꿨다고 기록하지만, 2026-10-01 실측상 Figma에는 `color/surface-container`(노드 불투명도 0.5)로 남아 있습니다. 코드 계약의 현재 값이 어느 쪽입니까? 감사 문서상 그 변경은 Figma에서 직접 한 것이라 Generate에서 되돌아갔을 가능성이 높아 보입니다. `surface-container-highest`라면 Figma 재생성이 필요하고, `surface-container`라면 그 감사 항목은 코드에 들어간 적이 없습니다. 아울러 Skeleton이 놓이는 배경(호출처의 표면 색)을 코드가 아는지, 즉 채움이 배경에 따라 달라지는지도 알려 주세요.

**답 (코드 대조)** `surface-container` 입니다.

- Core 계약(세 변형 모두) · Flutter · Web resolver · `components.json` · 빌더가 같고, 이력에서 `-highest` 였던 적이 없습니다. 감사 항목은 코드에 반영된 적이 없습니다((a) 배제, §3-1).
- 캔버스의 노드 불투명도 0.5 는 빌더가 `fromOpacity` 를 맥동의 쉬는 끝으로 그린 값입니다. rectangular · circular 는 `tint` 자식 레이어에, text 는 줄 노드에 싣습니다.

> **Q3. 접근성 관련 계약이 Skeleton에 있습니까?**
> `_Docs / Properties`의 9개 행에는 낭독 텍스트 · `aria-busy` · `prefers-reduced-motion` · 애니메이션 정지 시간에 해당하는 필드가 없습니다. 코드(Web · Flutter 양쪽)에서 다음이 구현되어 있는지 알려 주세요.
> (1) 로딩 상태를 스크린리더에 알리는 수단 (Web `aria-busy`/live region, Flutter `Semantics`)
> (2) 스켈레톤 도형을 접근성 트리에서 숨기는 처리
> (3) `prefers-reduced-motion`(Flutter `disableAnimations`) 대응
> (4) WCAG 2.2.2 기준 5초 후 애니메이션 정지

**답 (코드 대조)**

- (1) **있습니다 — 스켈레톤 하나마다.** Flutter `Semantics(liveRegion: true, label: loadingLabel)`, Web `role="status"` + `aria-label`. 라벨은 렌더 시점에 로케일에서 읽고 두 플랫폼 값이 같습니다. `aria-busy` 는 없습니다(Flutter SDK 에 대응 시맨틱이 없음). Web 은 텍스트 노드 없이 `aria-label` 만 답니다 — 이것만으로 스크린리더가 처음 삽입 때 읽는지는 실기 확인이 필요합니다.
  **(정정, 2026-10-02)** 알림 속성이 붙는다는 데까지만 맞습니다. 실제로 읽히는 횟수는 플랫폼마다 다릅니다 — Flutter iOS 는 스켈레톤 수만큼, Web 은 한 번도 읽히지 않을 가능성이 높습니다(§12-1).
- (2) 명시적 처리는 없습니다. Flutter 도형은 시맨틱 노드를 만들지 않아 드러나지 않고, Web text 줄 `div` 에는 `aria-hidden` 이 없습니다.
- (3) 동작 줄이기에서 **일부러 멈추지 않습니다**(규칙: 맥동은 표시 tier). Flutter 는 동작 줄이기 경로를 의도적으로 거치지 않고(예전에 0 주기로 접혀 크래시가 났던 이력), Web 은 `animation-duration` 을 리터럴로 내서 media query 가 닿지 않습니다. 테스트가 이를 고정합니다.
- (4) 없습니다. 무한 반복이고, 같은 규칙 때문입니다(D11).

> **Q4. 빌더가 빈 child 슬롯에 Skeleton 인스턴스를 꽂는 동작이 의도된 것입니까?**
> Skeleton 인스턴스 179개 중 약 150개가 `child content` · `media content` · `header content` · `aside content` · `children[]` 등 **슬롯 이름을 가진 노드**이고, 크기만 오버라이드되어 있습니다(색 · 반경 · 변형은 기본값). AppBar 72개 · Card 32개 · ResponsiveGrid 24개가 여기 해당합니다. 코드에는 이 자리에 Skeleton이 없을 것으로 보이는데(AppBar의 `child`는 호출자가 넣는 슬롯), 맞습니까? 맞다면 Mockup 조사에서 보고한 `OutlinedContainer` 빈 슬롯 결함(160×48, 반경 15)과 같은 원인입니까?

**답 (코드 대조)** 의도된 동작입니다.

- `W`/`W?` 슬롯은 아무 위젯이나 받는 자리이고, Figma 에서 그 뜻을 나타내는 수단은 교체 속성뿐입니다. 그 기본값은 컴포넌트여야 해서 빌더가 Skeleton 을 골랐습니다. 이유는 빌더 파일 머리 주석에만 있고 개발자 문서에는 없습니다.
- 빌더 파일 다섯 개가 각자 지역 헬퍼로 넣습니다. 공용 헬퍼 하나가 아닙니다.
- 코드에는 이 자리에 Skeleton 이 없습니다. AppBar `child` · Card `media` 등은 계약에서 `W?` 이고 기본값이 비어 있습니다.
- 대부분 기본 숨김이라 보이는 것은 54개입니다(§2-3).
- OutlinedContainer 빈 칸과는 같은 정책 계열이지만 다른 헬퍼 · 다른 대역입니다(§2-3).

> **Q5. `Skeleton`이라는 이름으로 꽂힌 것들(10~14개)은 코드에 실제로 있습니까?**
> Dialog `leading`/`trailing` 24×24, Toast `action` 64×28, Drawer `backdrop` 608×380, Drawer `content` 206×64, DraggablePanel `child` 296×82 · `panel` 222×64입니다. 특히 **Drawer의 `backdrop`에 608×380 Skeleton**이 들어간 것은 결함으로 보입니다(backdrop은 로딩 자리가 아닙니다). 코드에 있는지, 없다면 Q4와 같은 빌더 동작인지 알려 주세요.

**답 (코드 대조)** 코드(Flutter · Web 컴포넌트)에는 어디에도 없습니다. 전부 `overlay.ts` 의 슬롯 헬퍼가 넣고, 그 헬퍼만 인스턴스 이름을 바꾸지 않아 `Skeleton` 으로 남습니다 — Q4 와 같은 빌더 동작입니다.

- Dialog `leading`/`trailing` 24×24 · Toast `action` 64×28: 빌더의 미리보기 상수이고 기본 숨김입니다.
- Drawer `content` 206×64: 패널 폭 256 − 패딩 24×2 − 테두리 1×2.
- DraggablePanel `child` 296×82 · `panel` 222×64: 패널 기하에서 나온 크기입니다.
- **Drawer `backdrop` 은 슬롯이 아닙니다.** 빌더 주석이 '앱 셸이 띄우는 뒤의 앱' 이라고 적습니다. 코드에서 backdrop 은 Drawer 가 뒤로 축소하는 앱 화면(navigator)이고, 608×380 = 미리보기 640×400 × 축소 0.95 입니다. 결함이라기보다 성격이 다른 대역입니다(D10).
- 문서 표에 없는 Swiper `child`(480×320)도 같은 방식이지만 페이지가 강등돼 지금은 생성되지 않습니다.

> **Q6. `fields.lines` · `lineHeight` · `lineSpacing` · `lastLineWidth`는 `text` 변형에만 적용됩니까?**
> rectangular · circular에서는 무시되는 값입니까? 변형별로 유효한 필드가 다르면 문서에 표기해야 합니다.

**답 (코드 대조)** 그렇습니다. 세 층(Flutter · Web · 빌더) 모두 `text` 변형에서만 읽고 rectangular · circular 에서는 무시합니다. 반대로 `width` · `height` 는 `text` 에서 무시됩니다. 잘못 주어도 조용히 무시되고, 막는 장치는 없습니다.

> **Q7. 고아 노드 확인.**
> 현재 AppBar 계약의 `Leading` 열거값에 `back`이 있습니까? Figma에 `Variant=standard/compact/medium, Leading=back, Align=start`인 AppBar 변형 3개와 `Hero` 컴포넌트 1개가 **어떤 페이지에도 속하지 않은 채** 남아 있고, 그 안에 Skeleton 인스턴스 10개가 있습니다(노드 ID `3774:342` · `3774:366` · `3774:390` · `2467:93878`). 이전 세대 잔존물로 보이는데 맞습니까?

**답 (코드 대조)** Core 계약에는 `Leading` 열거값이 없습니다. `leading` 은 호출자가 채우는 위젯 목록이고 정렬은 `centerTitle` 불린입니다.

- `Leading`(none · back · close · menu) · `Align` 은 빌더만 가진 미리보기 축이고, `back` 은 처음부터 지금까지 그려지는 값입니다.
- 그래서 AppBar 고아 셋은 이전 세대가 아니라, 같은 이름의 실제 멤버와 별개로 만들어졌다 지워진 노드입니다(외부 스크립트로 보임 — 추정).
- Hero 고아는 이전 세대가 맞습니다.
- 자세한 것은 §3-3.

## 9-1. 코드 대조로 함께 드러난 것 — `[일반]` 후보

이 조사와 직접 관계는 없지만 코드 대조 중에 드러난 결함입니다. 아직 이슈로 내지 않았습니다.

| # | 무엇 | 왜 문제인가 |
|---|---|---|
| G1 | 맥동 속도가 두 플랫폼에서 2배 다릅니다 | 같은 `duration`(1초)을 Flutter 는 한 방향으로(왕복 2초), Web 은 왕복으로(1초) 씁니다. 곡선도 다릅니다. 규칙(`widget/loading-states.md` '맥동은 표시 tier 다')이 막으려던 '한쪽만 다른 속도' 입니다. 어느 쪽이 기준인지는 D14 |
| G2 | 맥동 알파 계산이 다릅니다 | Flutter 는 알파를 덮어쓰고, Web · Figma 는 곱합니다. 기본 토큰(불투명)에서는 같지만, 반투명 색을 주면 두 플랫폼이 다르게 맥동합니다 |
| G3 | Web Skeleton 이 호출자 속성을 버립니다 | 생성자에 `attributes` 가 없고 `copyWith` 가 받아서 버립니다. 호출자가 `aria-hidden` 을 줄 수 없습니다(D12) |
| G4 | Flutter 에만 두 번째 스켈레톤이 있습니다 | `asSkeleton()`(skeletonizer)이 공개 API 이고 앱 전역에 설정 층이 설치됩니다. 채움 primary 5% → 10%, 1초(토큰이 아닌 리터럴)로 Skeleton 과 모습이 다르고 Web 에는 없습니다. Widgetbook 의 Skeleton 페이지는 이것만 보여 줍니다. 읽는 곳 없는 옛 `SkeletonTheme` 도 공개돼 있습니다(D15) |
| G5 | 슬롯 대역 규약이 빌더 주석에만 있습니다 | 개발자 문서 · 플러그인 README 에 없어서, 캔버스만 보고는 의도인지 결함인지 판정할 수 없습니다 — 이 조사가 그 사례입니다 |
| G6 | 빌더가 `Enabled=false` 를 코드와 반대 전제로 그립니다 | 코드는 '안 그림' 인데 빌더는 '비활성 chrome 없음 → 같게' 로 그립니다(D13) |
| G7 | docs `skeleton.md` 의 접근성 · 플랫폼 표가 부정확합니다 | Web `aria-label` 을 고정 'Loading' 으로 적었지만 실제로는 로케일 값입니다. '같은 duration' 이 G1 의 2배 차이를 가립니다 |
| G8 | Loading 이 동작 줄이기 + 500ms 이하 덮어쓰기에서 Flutter 에서 멈출 수 있습니다 | Loading 은 동작 줄이기 경로를 거쳐 0 주기가 될 수 있고, 반복 애니메이션은 0 주기에서 assertion 을 겁니다. Skeleton 이 같은 원인으로 크래시가 났다가 고친 이력이 있습니다(코드만 읽었고 실행 확인은 안 함) |
| G9 | Hero 의 키 보존 입양 경로가 실행되지 않습니다 | 빌더의 입양(`adoptLooseAs`)이 구조 전환의 제거에 밀려 옛 키가 항상 버려집니다. Slider 에도 같은 모양의 문서-코드 모순이 있고, 세트 없는 `❖ HeroSection` 페이지가 남아 있습니다 |

---

## 10. 다음 단계

1. 위 Q1~Q7을 Claude Code에 전달하고 답을 받습니다. 특히 Q1·Q2가 와야 §6-1과 §3-1을 확정할 수 있습니다. **(코드 대조)** 답은 §9 에 적었습니다.
2. D1·D2를 먼저 결정하면 R2(빌더 빈 슬롯)는 결정 #1·#3을 기다리지 않고 `[일반]` 이슈로 진행할 수 있습니다.
3. D3~D6은 결정 #1(상태 표현 통일)·#3(반경 사다리) 확정 후 함께 닫는 것을 권합니다.
4. 그 다음 Skeleton `[리디자인]` 제안서를 작성합니다. 다룰 것: 역할 범위(R1 전용), 채움 토큰과 모드별 거동, 기본 반경, 접근성 계약 보강, `Enabled` 축 처리.

---

## 11. 2판 교차 검증 기록 (2026-10-01)

Figma는 새로 열지 않았습니다. 프로젝트 문서와 외부 원문, 그리고 재계산만으로 확인했습니다.

| # | 항목 | 초판 | 확인 방법 | 결과 |
|---|---|---|---|---|
| V1 | `outline-variant` Light 대비 | 4.01 | WCAG 휘도 공식 재계산 (`#c3c4c6` 대 `#fcfcfd`) | **1.70으로 정정.** 5-2 결론과 D4 · D5 선택지 문구 수정 |
| V2 | `outline-variant` Light = `surface-container-highest` Light | 언급 없음 | `on-surface-variant` 대 `highest` 4.77에서 역산 | 같은 값으로 보임. Figma 변수 확인 필요 |
| V3 | `outline` 대비 | 없음 | 재계산 | 표에 추가. Light에서 3:1에 닿는 유일한 후보 |
| V4 | 감사 수정의 방식 | (a)(b)(c) 열거 | `state-layer-full-audit-2026-08-25.md` 1-2 원문 | Figma 직접 편집 기록. (b) 유력 |
| V5 | 감사 3.20의 의미 | 대비비처럼 비교 | 같은 문서 0절 · 1-2 | ΔL\*. 잣대가 다름을 3-1에 명시 |
| V6 | 배경별 가시성 | `surface` 하나만 계산 | 같은 문서 1-2 | `surface-container` 위에서 ΔL\* 0 — 3-1에 추가 |
| V7 | 소비 컴포넌트 수 | 17 | 2-2 표 재집계 | **16**. 인벤토리와 일치 |
| V8 | B 계열 수 | 약 9 | 2-2 표 재집계 | 10~14. Figma 재집계 필요 |
| V9 | Carbon #4310 | "남아 있다" | 이슈 원문 | **닫힘.** 5-3 정정 |
| V10 | Roselli 권고 | 4항목 | 원문 | 내용은 맞음. `aria-busy` 지원 부족, 3:1 예제의 평가("ugly") 보탬 |
| V11 | `Loading` 축 선례 | Variant + Size | `컴포넌트-인벤토리.md` | Variant4 Size6로 일치 |
| V12 | `OutlinedContainer` 빈 슬롯(160×48, 반경 15) | Mockup 조사 §5 | `mockup-계열-코드-인계.md` 5절 | 일치. 그 문서도 "OutlinedContainer를 합성하는 모든 컴포넌트를 확인"하라고 적음 |

확인하지 못한 것: MUI · Ant · Polaris 표의 기본값(초판 기재 그대로), `surface-container` Dark 초판 값의 출처(0.04~0.07 차이), 2-1 · 2-2의 인스턴스 수 자체(Figma 실측이라 재실측 전까지 초판 값 유지).

---

## 12. 받은 답과 내린 결정 (2026-10-02 ~ 10-06)

이 절은 기록입니다. 값은 코드에서 읽고, 반영 여부는 각 이슈와 캔버스 상태 점검으로 확인합니다.

### 12-1. Q1~Q7 — 답은 §9 각 질문 아래에

Q1~Q7 의 답은 2026-10-01 코드 대조 검토에서 §9 각 질문 아래에 적었습니다. 그 뒤 Q10 을 조사하며 **Q3 (1) 의 답 하나를 정정**했습니다.

- 스켈레톤마다 알림 **속성이 붙는다**는 데까지만 맞습니다. 실제로 몇 번 읽히는지는 플랫폼마다 다릅니다.
- Flutter iOS 는 처음 나타날 때 스켈레톤 수만큼 대기열에 쌓입니다(엔진 코드로 확인). Android 는 이벤트가 N개 나가지만 실제로 읽는지는 확인하지 못했습니다.
- Web 은 텍스트 내용이 없는 status 영역이 삽입만 되고 바뀌지 않으므로 **한 번도 읽히지 않을 가능성이 높습니다**(명세와 MDN 근거, 스크린리더 실측은 하지 않음).

### 12-2. Q8~Q11 (2026-10-02)

**Q8. `enabled: false` 사용처** — 밖에서 깨지는 호출은 0입니다.

| 범위 | 개수 | 비고 |
|---|---|---|
| 라이브러리 | 2 | 양 플랫폼 `copyWith` 가 값을 그대로 다시 넘기는 내부 코드 |
| 테스트 | 2 | Flutter 골든 `disabled` 장면, Web "enabled: false 면 알림 없음" |
| docs · 예제 · widgetbook | 0 | |
| unibook | 0 | 오히려 coui 의 `Skeleton` 을 숨기고(`hide`) 다시 내보냄 |

- 소비가 0이어도 예고 기간은 줄지 않습니다(`process/deprecation.md` — 두 마이너는 최소값).
- unibook 이 `coui_web` 을 쓰므로 Web 에도 외부 소비자가 있습니다 → 규칙 문장을 고치는 일감(#5236).
- `asSkeleton(enabled:)` 는 같은 단어를 쓰는 별개 공개 API 라 대상이 아닙니다.

**Q9. 빈 슬롯 기본값을 빌더 전용 대역으로**

- (1) 바꾸는 지점이 한 곳이 아니었습니다 — 빌더 파일 5개에 흩어져 있었습니다(지역 헬퍼 3벌, Overlay 인라인 6곳, Card 인라인 4곳).
- (2) 게시에서 빼는 공식 방법은 이름 앞의 `.` 과 Assets 패널의 "Hide when publishing" 입니다. `_` 는 공식 문서에 변수 컬렉션에 대해서만 적혀 있어, 가칭은 `_Slot` 보다 `.Slot` 이 안전합니다.
- (3) 이름이 안 바뀌던 헬퍼도 함께 고칠 수 있었습니다. 같은 헬퍼를 지나는 Popover · HoverCard 트리거와 ContextMenu 대상 이름도 함께 바뀝니다.
- (4) OutlinedContainer 빈 칸은 대역이 아니라 칸 자체(칠 없는 160×48 프레임)라 성격이 다릅니다.
- 결정에 걸리는 조건: 이미 만들어진 문서에서는 교체 속성의 기본값을 빌더가 일부러 다시 쓰지 않습니다(Q14). 대역 전용 컴포넌트에는 CI 가드의 새 예외 범주가 필요합니다(Q13).

**Q10. 로딩 알림의 실제 내용**

| | Flutter | Web |
|---|---|---|
| 붙는 것 | `Semantics(liveRegion: true, label: loadingLabel)` (역할 없음) | 루트 `role="status"` + `aria-label` (텍스트 내용 없음) |
| 문구 | en `Loading` · ko `로딩 중` — 두 플랫폼 같음, 렌더 시점에 로케일에서 읽음 | 같음 |
| 단위 | 스켈레톤 하나당 하나 | 같음 |

- 호출자가 문구를 바꾸는 파라미터는 없습니다(로컬라이제이션을 덮어쓰면 Loading · Progress · Tree 도 함께 바뀜).
- 여러 스켈레톤을 한 번만 알리게 묶는 CoUI 수단은 없습니다. 호출자가 직접 감쌀 수는 있지만, Web Skeleton 은 호출자 속성을 버립니다(§9-1 G3).
- 채움은 놓이는 표면과 상관없이 `surface-container` 고정이라, 같은 색의 filled Card 위에서는 맥동 내내 배경과 구분되지 않습니다(디자이너 ΔL\* 0 실측과 일치).
- 이때 `.transparent` 체인에서 Flutter 는 검정으로 맥동하고 Web 은 투명하다는 차이를 찾았습니다 → #5235.

**Q11. `widget/loading-states.md` 규칙과 WCAG 2.2.2**

- 규칙 원문: "로딩 표시의 애니메이션은 '얼마나 오래 머무르나'이지 '얼마나 빨리 움직이나'가 아니므로, 동작 줄이기 설정에서 억제되지 않는다. 멈춘 스켈레톤은 로딩이 끝났다고 말하는 것과 구별되지 않는다."
- 규칙은 화면 전체 로딩과 부분 로딩을 구분하지 않습니다.
- WCAG 2.2.2 의 로딩 예외는 "그 단계 동안 상호작용할 수 없을 때"입니다. 그래서 카드 하나만 스켈레톤이고 나머지 화면을 쓸 수 있는 경우 5초를 넘기면 예외 밖이라 규칙과 기준이 부딪힙니다. 느린 맥동이 "주의를 끌려는" 깜빡임에 해당하는지는 해석이 갈릴 수 있습니다.
- Skeleton 은 자기가 전체 로딩인지 부분 로딩인지 알 수 없습니다. 같은 규칙이 Loading · Progress 에도 걸립니다. → D11 은 아직 결정 대기입니다.

### 12-3. 결정과 반영 (2026-10-02)

디자이너가 Q8~Q11 답을 보고 `[일반]` 이슈 넷을 열어 처리하기로 결정했습니다.

| 이슈 | 결정 | 반영 |
|---|---|---|
| #5233 빈 슬롯 헬퍼 통합 · 이름 · 문서화 | 흩어진 빈 슬롯 기본값 지정을 공용 헬퍼 하나로 모은다(기본값은 지금처럼 Skeleton). 이름이 안 바뀌던 헬퍼를 고친다. 대역 규약을 개발자 문서로 옮긴다. **대역 교체(`.Slot`)는 이번에 하지 않는다** | PR #5241 머지 · Generate 뒤 캔버스 검수 통과(슬롯 자리 169 · 숨김 115 · 보임 54 · 이름 `Skeleton` 0 · 낡은 세트 0) → 닫힘. 레이어 이름 규칙: 슬롯 자리이면 슬롯 이름 그대로, 홀더가 감싸면 `<슬롯> content`. Drawer backdrop 대역은 `app content` |
| #5234 `enabled` 폐기 | 공개 API 에서 뺀다. 대체는 호출자 조건부 렌더. 두 마이너 예고를 지킨다 | N(예고) PR #5242 → 첫 실림 태그 coui_core 0.152.0 · coui_flutter 0.154.0 · coui_web 0.153.0. 제거는 §12-5 |
| #5235 `.transparent` 맥동 파리티 | 같은 입력이면 두 플랫폼이 같은 결과 | PR #5243 머지 — Flutter 를 Web · Figma 와 같은 **곱하기**로 맞춤(coui_flutter 0.154.0 · coui_web 0.153.0). 맥동 폭은 §12-5 |
| #5236 규칙 문장 | Web 공개 API 제거도 두 마이너 예고를 따른다 | PR #5237 머지 → 닫힘. 조사 중 unibook 이 쓰는 `coui_web` `MockupWindow` 가 0.142.0 에서 예고 없이 지워진 것을 찾았습니다(대체 `MockupBrowser(showControls: true, addressBar: null)`, 목록은 #5236 댓글) |

이 결정으로 §8 과 §9-1 에서 정리된 것:

- **D2 일부** — R2 는 빌더 헬퍼 통합 · 이름 · 문서화까지만 `[일반]` 으로 진행했습니다. 대역 교체 여부(D1)와 수단(D8)은 남았습니다.
- **G2** — 맥동 알파 계산 차이 → #5235 로 해결.
- **G5** — 대역 규약이 빌더 주석에만 있던 것 → `docs/contributing/figma.md` 「빈 슬롯의 대역」으로 해결.

### 12-4. Q12~Q14 (2026-10-02)

디자이너가 **로딩 알림을 영역 단위 한 번으로 바꾸는 방향**을 정하고, 그 수단을 검토하려고 물은 질문입니다(D12 의 방향).

**Q12. `asSkeleton(enabled:)` 는 무엇을 하나**

- 감싼 위젯의 모양대로 그립니다(서드파티 skeletonizer 가 그리기를 가로채 글자는 줄마다 막대로, 이미지는 사각형으로). CoUI `Skeleton` 위젯과 `CoreSkeletonStyle` 을 쓰지 않습니다(primary 5%↔10%, 1초 리터럴, 선형). CoUI 아이콘(SVG)은 가려지지 않습니다.
- 로딩 알림은 0개입니다. 안쪽 의미 정보가 그대로 지나가서, 막대로 바뀐 목업 글자를 스크린리더가 읽습니다.
- Web 에는 대응이 없습니다. `widget/loading-states.md` 가 "표준이 아니다"라고 한 트리 순회 방식이 바로 이것입니다.
- 영역 단위 알림에는 이 API 보다 **페인트를 순회하지 않는 영역 래퍼**가 맞습니다 — Flutter `Semantics(liveRegion, label)` + `ExcludeSemantics`, Web `role="status"` + `aria-label` + 자식 `aria-hidden`. 만들 때 정할 것: Flutter 에는 busy 플래그가 없고, Web Skeleton 은 호출자 속성을 버리므로(G3) 조상 `aria-hidden` 으로 숨길지 Skeleton 에 알림을 끄는 축을 둘지.

**Q13. 계약 없는 빌더 전용 세트(ThemeSwatch)의 가드 처리**

- ThemeSwatch 는 계약 없는 세트를 막는 가드에서 예외 목록으로 빠지고, `dataSlug: 'theme_controller'` 로 ThemeController 레코드와 비교됩니다. 사실 빌더 전용이 아니라 ThemeController 의 일부를 두 플랫폼이 실제로 그리는 조각입니다.
- `.Slot` 은 이 처리를 그대로 쓸 수 없습니다. `dataSlug: 'skeleton'` 을 주면 Skeleton 의 반경 · 채움과 비교돼 점선 프레임이 대조에 실패하고, 안 주면 slug 검사 · Generate 경고 · 대조 검사가 실패합니다. 이름이 `.` 으로 시작하면 TS 와 Python 의 slug 계산도 갈립니다. → 가드에 `.Slot` 에 맞는 **새 예외 범주**가 필요합니다.

**Q14. 교체 속성 기본값이 Skeleton 으로 남는 지점**

- 빌더에 기본값을 되돌리는 줄은 없습니다. 속성을 처음 만들 때 Skeleton 을 넣었고, 그 뒤 `defineProp`(`component-props.ts`)이 교체 속성의 기본값을 일부러 다시 쓰지 않습니다. 빌더는 노드를 교체하지 않고 매번 지운 뒤 새로 만들어 속성에 연결합니다 — 그래서 디자이너 실험 ①의 자동 추종은 빌더 경로에서 일어나지 않습니다.
- "기본값이 빌더가 넣은 Skeleton 일 때만 바꾸기"는 가능합니다. `defineProp` 의 교체 속성 분기에서 현재 기본값 id 가 빌더가 넣는 **바로 그 Skeleton 멤버 id** 와 같을 때만 바꿉니다(멤버 전체와 비교하면 디자이너가 일부러 고른 다른 Skeleton 변형까지 오판).
- 위험: 테스트 더블로는 확인할 수 없어 실제 파일에서만 확인됩니다. 지문과 리디자인 대조는 속성 기본값을 보지 않으므로 건너뛴 세트 목록을 로그에 남겨야 합니다. 게시 → 소비 파일 경로는 재보지 않았습니다.

### 12-5. 결정과 반영 (2026-10-06)

| 이슈 | 결정 | 반영 |
|---|---|---|
| #5235 | 반투명 채움의 맥동 폭은 **이대로**(채움 알파에 비례해 폭이 줄어듦). `fromOpacity` / `toOpacity` 의 뜻은 바꾸지 않는다 | 닫힘. 세 표면(Flutter · Web · Figma)이 같은 곱하기로 그립니다 |
| #5234 | 정리(N+1)와 제거(N+2)를 **지금** 진행한다. 세 패키지 모두 N 뒤 두 마이너가 이미 출시돼 하한을 넘었다 | 제거 PR #5275 — Core · Flutter · Web 의 `enabled` 제거, 테스트 · 골든 · docs 정리. Figma 는 `Enabled=true` 세 멤버를 `Variant=x` 로 개명(key 유지)하고 `Enabled=false` 세 멤버를 은퇴. 플러그인의 「폐기 대상 dry-run」→「폐기된 컴포넌트 제거」→ Generate 로 캔버스에 반영했다 — 세트는 `Variant` 한 축 3 멤버, key 유지, 인스턴스 179 그대로, 낡은 세트 0 → 닫힘. cc-coui `coui-skeleton` 스킬 문서는 coco-de/skills#517 |

- 제거 전 확인: unibook 의 main · development · release 브랜치 어디에도 CoUI `Skeleton(` 호출이 없습니다(0건).
- DS 파일 실측(읽기 전용, 2026-10-06): `Enabled=false` 세 멤버를 가리키는 인스턴스 **0**. 대역 179개는 rectangular 174 · circular 1 · text 4 로 전부 `Enabled=true` 멤버를 가리킵니다.
- 결정 #1(`상태-표현-통일-제안.md`, 2026-10-02 확정)도 Skeleton `Enabled` 는 상호작용 상태가 아니므로 축을 빼라고 권했습니다 — 같은 방향입니다.
- 이 결정으로 **D3**(삭제)이 정해지고 **D13**(캔버스의 `Enabled=false`)과 **G6** 은 축이 사라지면서 해당이 없어졌습니다(캔버스 반영 확인).

### 12-6. 결정과 반영 (2026-10-06 오후) — 분리 형태와 Skeleton 리디자인

디자이너가 남은 두 결정을 차례로 내렸다(대화에서 받아 옮겨 적음). 아래 표가 결정이고, 반영은 각 이슈가 추적한다.

**① 분리 형태 — 빈 슬롯 대역** → [일반] #5277

| 항목 | 결정 | 정리된 결정 대기 |
|---|---|---|
| 대역 수단 | 빌더 전용 대역 컴포넌트 **`.Slot`**(이름 앞 `.` — 라이브러리 게시에서 숨김). 교체 방식은 그대로, 출발점만 Skeleton → `.Slot` | D1(분리) · D8 |
| 모양 | **점선 테두리 + 투명 채움**, 점선 색 **`outline`** | |
| 축 · 반경 | `Shape` 두 칸 — **`rectangle`(반경 0)** · **`circle`(full)**. `text` 모양 자리는 `rectangle` | |
| 범위 | **Skeleton 대역만**. Icon 글리프 대역 · OutlinedContainer 빈 칸은 범위 밖 | D9 |
| Drawer 뒤 앱 화면 | **같은 `.Slot`**, 이름은 `app content` 그대로 | D10 |

**② Skeleton 리디자인**

| 주제 | 결정 | 이슈 | 정리된 결정 대기 |
|---|---|---|---|
| 채움 | **`surface-container-highest`**(흰 배경 1.29↔1.70 · 다크 1.40↔2.11). 3:1 은 목표로 두지 않고 접근성은 로딩 알림이 맡는다. 고대비 모드에서 따로 진해지지 않는다 | [리디자인] #5278 | D4 · D5 · D16 |
| 기본 반경 | rectangular **8 → 4**(부품). text 4 · circular full 그대로. 대신하는 요소의 반경은 호출자가 정한다 | [리디자인] #5278 | D6 |
| 맥동 속도 | 두 플랫폼 모두 **왕복 2초**, 곡선 하나. `duration` = 왕복 한 번 | [일반] #5279 | D14 · G1 |
| 멈춤 | **동작 줄이기를 켠 사용자만 정지**. Skeleton 만 규칙 예외(멈춘 블록은 자리표시로 읽히지만 멈춘 스피너는 고장으로 읽힌다). Loading · Progress 는 그대로 | [일반] #5280 | D11 |
| 로딩 알림 | 영역 래퍼 **`LoadingRegion`**(양 플랫폼 같은 이름)이 한 번 알리고 안쪽 스켈레톤은 알림을 끈다. 문구는 호출자가 바꿀 수 있다. Web 단독 스켈레톤이 안 읽히는 결함도 함께 고친다 | [일반] #5281 | D12 · G3(래퍼 경로로 우회) |
| `asSkeleton` | `SkeletonTheme` 과 함께 **폐기 절차**. 대체는 Skeleton + `LoadingRegion` — 래퍼가 먼저 | [일반] #5282 | D15 · G4 |

순서: #5277(대역) 이 #5278(Skeleton 모양) 보다 먼저다 — 그래야 Skeleton 을 바꿔도 대역을 쓰는 16개 세트가 같이 흔들리지 않는다. #5282 는 #5281 다음이다(예고는 대체재와 같은 릴리스에).

### 12-7. 남은 것

| # | 상태 |
|---|---|
| D7 | 고아 노드 — 기록만 남긴다(§12-8) |
| D13 | 해당 없음 — `Enabled` 축이 사라졌다(12-5) |
| G7 | docs `skeleton.md` 의 애니메이션 · 플랫폼 표 — #5279 에서 함께 고친다 |
| G8 · G9 | §9-1 의 `[일반]` 후보 — 아직 이슈로 내지 않음 |
| #5278 · #5280 의 열린 질문 | 답 받음 — #5278 은 열린 질문 없음(2026-10-06 댓글), #5280 은 멈췄을 때의 채움 = 쉼 끝 50%(2026-10-06 댓글) |

### 12-8. 결정 (2026-10-07)

| # | 결정 |
|---|---|
| D7 | **기록만 남긴다.** §3-3 의 고아 노드 10개(어느 페이지에도 속하지 않은 AppBar 변형 복제 3개와 옛 `HeroSection` 안의 Skeleton)는 Skeleton 범위 밖으로 두고 이 문서에 기록만 남긴다. 화면에 보이지 않고 어떤 컴포넌트에도 영향을 주지 않는다. 감사에서 Skeleton 인스턴스를 셀 때 이 10개가 섞여 들어온다는 것만 기억한다 |

이 결정으로 결정 대기 항목이 모두 정해졌다. 문서 상태를 '확정' 으로 바꾼다.

---

## 참고

- MUI Skeleton API — https://mui.com/material-ui/api/skeleton/
- Ant Design Skeleton — https://ant.design/components/skeleton
- Shopify Polaris Skeleton page — https://polaris-react.shopify.com/components/feedback-indicators/skeleton-page
- Shopify Polaris Skeleton body text — https://polaris-react.shopify.com/components/feedback-indicators/skeleton-body-text
- Adrian Roselli, More Accessible Skeletons — https://adrianroselli.com/2020/11/more-accessible-skeletons.html
- Carbon issue #4310, 스켈레톤 로딩 상태 접근성 — https://github.com/carbon-design-system/carbon/issues/4310
