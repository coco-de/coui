# Flutter 위젯 트리 probe — SPIKE-5 (#3603)

Epic A(#3594) 선행 스파이크. `.bmad/architecture-*.md` Component ②
(FlutterCaptureBackend)가 전제하는 "위젯 트리를 순회해 probe 대상의 렌더 값을
읽는다"가 실제로 Command · DatePicker · Dialog(구조가 서로 다른 3종)에서
성립하는지 검증한다.

## 완료 정의 대조

- [x] **3종에서 probe 값 추출 성공** — `command_probe_test.dart` /
  `date_picker_probe_test.dart` / `dialog_probe_test.dart`, 7 테스트 전부
  pass. `flutter test test/src/parity_probe/` 로 재현.
- [x] **probe 선언 방식 결정** — 아래 "probe 선언 방식" 절.
- [x] **기본 probe 가 root 하나로 충분한지 판단** — 아래 "root 하나로
  충분한가" 절.
- [x] **실패 시 대안 기록** — 아래 "부딪힌 것과 고친 방법" 절.

## 추출 primitive 3개 (`widget_tree_probe.dart`)

| 함수 | 무엇을 읽나 | 왜 naive 하게 읽으면 안 되나 |
|---|---|---|
| `probeEffectiveTextStyle` | `Text` 의 실효 `TextStyle`(fontWeight/fontSize/fontFamily/letterSpacing/height/color 전부 포함) | `Text.style` 필드를 직접 읽으면 `DefaultTextStyle` 과의 merge 이전 값이다 — **트리가 실제로 페인트하는 값이 아니다**. `Text.build()` 는 merge 결과를 `RichText.text.style` 에 굽는다. |
| `probeBoxDecoration` / `probeAllBoxDecorations` | `BoxDecoration`(borderRadius 4모서리·border width/color·boxShadow 레이어·color 전부 포함) | `Container`/`AnimatedContainer` 는 컴포넌트마다 다른 위젯이지만 전부 내부적으로 `DecoratedBox` 를 만든다 — `DecoratedBox` 하나만 찾으면 호출자가 컴포넌트 내부 구현(Container 인지 AnimatedContainer 인지)을 몰라도 된다. |
| `probeEffectivePadding` | `Padding` 의 실효 `EdgeInsets` | `EdgeInsetsDirectional` 등 방향성 값은 `TextDirection` 기준으로 resolve 해야 물리 좌표가 나온다. |

세 함수 모두 아키텍처 문서 Component ②가 요구하는 필드 전체(텍스트 6종 · 박스
4종 · 여백)를 반환값 하나(`TextStyle`/`BoxDecoration`/`EdgeInsets`)로 이미
담는다 — 필드별로 별도 함수를 만들 필요가 없었다.

## probe 선언 방식 — "역할명 → finder" 매핑을 어디에 두는가

**결정: 컴포넌트마다 손으로 유지하는 매핑 테이블을 새로 만들지 않는다.**
대신 두 계층을 그대로 쓴다:

1. **root** — `find.byType({Component})`. 모든 컴포넌트가 이거 하나로
   시작한다(아래 "root 하나로 충분한가" 참조).
2. **역할 finder** — root 아래에서 **그 역할을 실제로 그리는 위젯의 타입**을
   `find.byType(...)` 로 지정(`find.byType(Button)` = 트리거,
   `find.byType(FocusOutline)` = 포커스 링), 또는 **콘텐츠로** 지정
   (`find.text(item.label)` = 아이템 라벨). 이건 "매핑 테이블"이 아니라
   컴포넌트 소스를 한 번 읽고 아는 사실을 코드로 옮긴 것뿐이다 — 3종 모두
   이 정도로 충분했다(아래 표).

같은 타입의 `DecoratedBox`/`Padding` 이 한 finder 아래 여럿 있으면(포커스
링의 offset band + border band, 컴포넌트 자체 chrome + 자식 chrome 등)
**위치(index)가 아니라 속성으로 필터링**한다 — `probeAllBoxDecorations` 가
리스트를 돌려주고 호출부가 `.firstWhere((d) => d.border != null)` /
`.firstWhere((d) => d.color != null)` 로 고른다. DatePicker(포커스 링 —
border 유무로 구분)와 Dialog(패널 — color 유무로 구분) 둘 다 이 패턴을 실제로
썼다. **왜 index 가 아니라 속성인가**: `FocusOutline.build()` 의 두
`Position` 자식 순서가 바뀌거나 세 번째 decoration 이 추가되면 index 기반
`skip: N` 은 조용히 다른 박스를 가리키게 된다 — 속성 기반 필터는 "border 를
가진 그 박스"라는 의미를 그대로 코드에 남겨 그 변화에 살아남는다.
(`probeBoxDecoration(..., skip:)` 는 자기 완결적으로 단순한 경우를 위해
남겨뒀지만, 후보가 둘 이상이면 `probeAllBoxDecorations` + 필터를 우선한다.)

| 컴포넌트 | root | 역할 finder |
|---|---|---|
| Command | `find.byType(Command)` | 아이템 라벨 = `find.text(item.label)` (콘텐츠) |
| DatePicker | `find.byType(DatePicker)` | 트리거 = `find.byType(Button)`, 포커스 링 = `find.byType(FocusOutline)` (타입) |
| Dialog | `find.byType(Dialog)` | 패널 = root 자신(별도 finder 불필요), 제목 = `find.text('...')` (콘텐츠) |

## root 하나로 충분한가

**Tier1 온보딩 비용 관점에서는 그렇다 — root 선언은 항상 `find.byType({Component})` 한 줄이다.**
세 컴포넌트 다 이 한 줄에서 시작해 문제가 없었고, Dialog 는 심지어 pump 한
위젯의 직계 서브트리가 아니라 `showDialog` 가 push 한 별도 route(Overlay
엔트리) 안에 있는데도 **route 인식 로직 없이** 똑같이 찾아졌다
(`dialog_probe_test.dart` 의 "Navigator route 안에 있어도..." 테스트) —
`WidgetTester` 의 finder 가 기본적으로 활성 Overlay 를 포함한 전체 렌더
트리를 대상으로 하기 때문이다. 이건 SPIKE-5 가 답해야 했던 "컴포넌트마다
트리 형태가 달라 finder 안정성이 불확실하다"는 우려 중 최소한 "root 를 어떻게
찾나"에 대해서는 실측으로 해소됐다는 뜻이다.

**단, root 만으로 끝나는 건 "그 컴포넌트가 렌더하는 무언가가 존재한다"는
확인까지다.** chrome 세부값(트리거 보더, 포커스 링, 특정 텍스트 요소)을
읽으려면 root 다음에 **한 단계** 역할 finder 가 필요했다 — 그 한 단계는
셋 다 갔다(Command 는 텍스트 콘텐츠, DatePicker 는 두 개의 타입 finder,
Dialog 는 root 자신 + 텍스트 콘텐츠). 이 한 단계가 없다고 주장하는 게 아니라,
**그 한 단계가 손 관리 매핑 테이블일 필요는 없다**는 게 이 판단의 요지다.

## 부딪힌 것과 고친 방법 (실패 시 대안)

**Dialog: `showDialog` 의 route context 에 coui `Theme` 조상이 없으면
`resolveDialog` 가 `Theme.of` 에서 assert 로 죽는다.** 처음 작성한 하네스는
`material.MaterialApp` 만 pump 하고 coui `Theme` 로 감싸지 않았는데,
`showDialog` 의 `builder` 콜백이 만드는 새 route 는 `dialog_style.dart` 의
`resolveDialog` 가 `Theme.of(context)` 를 호출하므로 그 route 의 조상 어딘가에
coui `Theme` 가 있어야 한다. **대안**: `MaterialApp` **바깥**을 coui `Theme`
로 감싼다 — `Navigator`/`Overlay` 경계는 `InheritedWidget` 조회를
막지 않으므로 어디서 push 되든 같은 `Theme` 을 상속한다
(`dialog_probe_test.dart` 의 `_pumpAndOpenDialog` 주석 참조). 이건 probe
기법 자체의 한계가 아니라 **하네스가 어떤 ambient context 를 pump 해야
하는지**의 문제이므로, EPIC-001 이 FlutterCaptureBackend 를 만들 때 오버레이/
route 계열 컴포넌트는 이 조상을 빠뜨리지 않게 체크리스트에 넣을 필요가 있다.

**Command: PRD 가 확인한 font-weight 회귀가 이 최소 하네스에서는
재현되지 않았다.** `probeEffectiveTextStyle` 로 읽은 아이템 라벨의
`fontWeight` 는 `FontWeight.w400`(= `CoreFontWeight.regular`, 토큰과 일치)
였다 — PRD 가 스크린샷으로 확인한 "Flutter 는 semibold 처럼 보인다"가 여기선
안 나타났다. **이건 probe 기법이 틀렸다는 뜻이 아니라, 이 최소 하네스
(`pumpTestApp` 기본 테마)가 그 회귀를 유발하는 조건(실제 `CoUIApp`/특정
프리셋/다크모드 등)을 갖추지 않았다는 뜻으로 읽는다.** 회귀 재현·수정은 이
스파이크의 책임이 아니라 FR-024 로 분리된 별도 버그 수정 이슈(#3624 계열)의
책임이다 — `command_probe_test.dart` 의 assertion 은 그대로 두되, 이
assertion 이 실패하기 시작하면 "probe 가 고장났다"가 아니라 "그 회귀가 이
조건에서도 재현되기 시작했다"로 읽으라고 주석에 남겼다.

## 다음(EPIC-001)에 남기는 것

- probe 함수 3개(`widget_tree_probe.dart`)는 그대로 FlutterCaptureBackend 의
  속성 스냅샷 추출부로 재사용 가능한 형태다 — `WidgetTester`/`Finder` 표준
  API 만 쓰고 SPIKE 전용 임시 코드가 없다.
- root+역할 finder 조합이 Tier1 나머지 컴포넌트에도 일반화되는지는 이 3종
  (구조가 가장 다른 대표군)으로 검증했을 뿐, 전수 검증은 아니다 — 특히 "여러
  BoxDecoration 중 속성으로 가른다"는 컴포넌트가 그 속성(border/color)을
  실제로 갖고 있어야 성립하므로, 다른 컴포넌트에서 후보가 애매하면 그때
  판정 기준을 다시 정한다.
- Dialog 의 `Theme` 조상 요구사항처럼, "route/overlay 를 쓰는 컴포넌트는 어떤
  ambient context 가 필요한가"를 컴포넌트별로 하네스 착수 전에 한 번 확인하는
  체크리스트 항목을 EPIC-001 스토리에 남긴다.
