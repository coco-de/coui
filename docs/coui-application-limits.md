# CoUI 적용 한계 — 테마가 닿는 경계

> 소비자 앱이 “CoUI를 100% 쓰면 테마가 된다”고 읽을 때의 계약.
> CoUI **안쪽** 위젯이 다른 CoUI 위젯을 합성하는 규칙은 `.claude/rules/process/component-creation.md` 와 `.claude/rules/process/application-limits.md`.

## 한 줄

테마는 **CoUI 크롬 + 토큰** 에만 자동으로 흐른다. 코드 버퍼·PTY·수천 행 뷰포트 같은 **호스트 표면** 은 CoUI 위젯이 될 수 없고, `CoreColorScheme` / `CoreTypography` / `Scrollbar` 를 주입해야 한다. 호스트를 CoUI에 넣으면 테마가 쉬워지는 게 아니라 디자인 시스템이 IDE가 된다.

## 테마가 안 먹는 두 원인

같은 증상(“테마를 바꿨는데 안 따라온다”)이 두 층에서 난다. 처방이 다르다.

| 원인 | 무엇이 잘못인가 | 처방 |
|---|---|---|
| **커스텀 크롬** | 버튼·패널·트리·배지·상태 점을 raw `Container` / `<div>` / Material 로 다시 그림 | CoUI 위젯으로 되돌리거나, 스타일 슬롯·합성으로 맞춘다. 그래도 계약이 없으면 **옵트인 확장**(기본 시각 불변) |
| **호스트 표면** | 에디터 캔버스, 터미널 그리드, 가상화 리스트처럼 CoUI가 소유하지 않는 픽셀 | 위젯 승격 금지. 색·서체·스크롤바만 토큰 브리지 |

“100% CoUI”는 **크롬 100%** 이지 **픽셀 100%** 가 아니다.

## 사다리 (위에서 멈추기)

소비자 화면이 CoUI와 안 맞을 때 건너뛰지 않는다.

```
1. 그대로 쓴다
2. Core<X>Style 한 슬롯만 덮는다
3. 동작은 CoUI, 겉만 감싼다 (합성)
4. 계약이 없어서 여러 제품이 같은 구멍을 커스텀 크롬으로 메울 때만 — 옵트인 확장 (기본값 = 오늘)
5. 호스트이거나 한 제품 전용이면 — 토큰만 소비하는 도메인 위젯. CoUI에 넣지 않는다
```

사다리 3까지로 테마가 닿으면 4를 열지 않는다. 5를 4로 위장하지 않는다.

## 층

| 층 | 테마가 닿는 방법 | 예 (illustration) | 이 저장소 근거 |
|---|---|---|---|
| 그대로 | 위젯 + 테마. 추가 작업 없음 | `Button`, `Command`, `Resizable`, `Dialog`, `Banner`, `Icon`, `Gap` | 컴포넌트 카탈로그. 크롬은 `CoreXxxStyle` 기본값 |
| 스타일 슬롯 | 인스턴스/`Theme` 의 단일 슬롯 | `CodeDiff` 본문 서체 바꾸기 — `CoreCodeDiffStyle.bodyTextStyle` / `bodyTypography`. 기본은 이미 코드 역할(`codeMd` / `codeSm`) | `packages/coui_core/.../code_diff_contract.dart` — 본문 타이포는 슬롯, 기본은 코드 역할 |
| 합성 | 여러 CoUI를 조합. 새 컴포넌트 없음 | 상태 점+라벨 = `Status` + `Text`. 상태바 칸 = `OutlinedContainer` + `Text` + `Status` + `Gap`. diff 가로 스크롤 = `ScrollArea` > `CodeDiff` | `ScrollArea` 는 `child` 통째 계약. `Status` 는 점만 (`color` / `size` / `semanticLabel` / `statusStyle`) |
| 옵트인 확장 | 기본 시각 불변. 켜야 커스텀 크롬을 안 짠다 | `Tree` 폴더 선택·확장 상태 소유. `CodeDiff` 행 탭. `Status` 점 모션 | 아래 “지금 여는 구멍” |
| 호스트 | 토큰만 주입. 위젯 승격 금지 | 편집 가능한 코드 표면, PTY/ANSI 터미널, 수천 행 가상 리스트 | `ScrollArea`/`Listing`/`Table` 은 행 builder 가 없다. `CodeSnippet`/`CodeDiff` 는 읽기 전용 |
| 도메인 전용 | 제품 패키지 | 구문 강조 팔레트(UI 색과 분리), 키 바인딩 레지스트리, IDE 상태바 슬롯 구성 | 구문 색을 `CoreColorScheme` 에 섞지 말 것 — UI 토큰과 역할이 다름 |

## 지금 여는 구멍 (옵트인만)

소비자(데스크톱 ADE)가 CoUI 크롬을 버리고 다시 그리게 만드는 구멍 세 개. 기본값을 바꾸지 않는다.

| 구멍 | 오늘 | 옵트인 | 열지 않는 것 |
|---|---|---|---|
| `Tree` | `onNodeSelect` 는 리프만. 확장은 위젯 내부 Set 에 시드되어 리마운트 시 리셋 | 부모 라벨 선택 + `CoreTreeNode.expanded` 가 확장을 소유 | 가상화 트리, 파일 아이콘, 지연 로딩 |
| `CodeDiff` | 읽기 전용. 행 콜백 없음. 모노는 기본값 | nullable 행 탭. `null` 이면 오늘과 동일 | hunk 접기, 다중 파일 셸 |
| `Status` | 점. 모션 필드 없음 | 모션 플래그 기본 off. OS 의 모션 축소 설정(Web `prefers-reduced-motion` · Android 애니메이션 제거 · iOS 동작 줄이기)이면 강등 | 상태바 레이아웃, 상태어 사전 |

추적: Feature `feat(tree)` / `feat(code_diff)` / `feat(status)` — 이 문서와 같은 Epic.

## 넣지 않는 것 (호스트·도메인)

다음을 CoUI 컴포넌트로 승격하지 않는다.

- **편집 가능한 코드 표면** — 거터, 다중 커서, IME 조합, 접기, 인라인 검색. `CodeSnippet` 은 전시용.
- **터미널 / PTY** — ANSI, 스크롤백, 프로세스. 색·모노·`Scrollbar` 만 CoUI.
- **수천 행 가상 리스트** — `ScrollArea` 의 `child` 를 builder 로 바꾸면 기존 소비처의 계약이 깨진다. 가상화는 제품이 하고, 행 픽셀만 CoUI.
- **IDE 상태바 슬롯 구성** — 칸의 의미(워크스페이스 이름·잠금 수…)는 제품. 칸의 크롬은 합성.

호스트가 테마를 타려면: UI 색은 `CoreColorScheme` 하나, 구문/ANSI 팔레트는 별도 스킴, 스크롤바는 `Scrollbar` / nested `scrollbarStyle`.

## 소비자 체크

화면 하나를 테마로 물들이기 전에:

1. raw 크롬(직접 칠한 배경·테두리·버튼)이 있으면 사다리 1–3.
2. 사다리 3으로도 계약이 없으면, 그 구멍이 **다른 제품에도** 필요한지 묻는다. 아니면 5(도메인).
3. 호스트(에디터·터미널·가상 리스트)를 CoUI 위젯으로 제안하지 않는다.
4. 호스트는 토큰 브리지가 있는지 — UI 색과 구문 색을 한 팔레트에 섞지 않았는지 — 만 검사한다.

## 같이 보기

- [제품별 폼 디자인과 반응형 전시](consumer-form-styling.md) — 터치 높이, 오류 메시지, Figma 슬롯, Widgetbook 타이포그래피
- `.claude/rules/process/application-limits.md` — 에이전트용 짧은 원칙 (이 문서의 요약, 이슈 번호 없음)
- `.claude/rules/process/component-creation.md` — CoUI **내부** 에서 통일 컴포넌트를 쓰는 의무
- `.claude/rules/principles/vision.md` — 컴포넌트가 컴포넌트를 합성한다
- `packages/coui_core/lib/src/component/contracts/tree/tree_contract.dart`
- `packages/coui_core/lib/src/component/contracts/code_diff/code_diff_contract.dart`
- `packages/coui_core/lib/src/component/contracts/status/status_contract.dart`
- `packages/coui_core/lib/src/component/contracts/scroll_area/scroll_area_contract.dart`
