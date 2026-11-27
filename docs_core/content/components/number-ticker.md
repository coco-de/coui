---
title: NumberTicker
description: 값이 바뀌면 지금 보이는 숫자에서 새 숫자까지 이어서 세어 보여 주는 숫자 표시 컴포넌트입니다.
category: display
platforms: [flutter, web]
related: [stat, countdown, progress]
tags: [animation, counter, statistics, dashboard]
template: v2
source: display/number_ticker
---

# NumberTicker

<a id="live-preview"></a>

## 플레이그라운드

NumberTicker는 값이 바뀔 때 숫자를 이어서 세어 보여 줍니다. 통계, 카운터, 대시보드 수치에 씁니다. `value` 를 바꿔 숫자가 움직이는 모습을 확인하고, 만들어진 코드를 복사하세요.

<Playground component="number-ticker" />

- `duration` 과 `curve` 는 그것만 바꾸면 아무것도 움직이지 않습니다. 고른 뒤 `value` 를 바꿔 확인하세요.
- `0부터 세기` 는 `initialValue: 0` 입니다. 처음 나타날 때만 읽는 값이라, 미리보기는 켜고 끌 때마다 컴포넌트를 새로 만듭니다.
- 앱에서는 코드의 `value` 에 적힌 숫자 대신 화면의 상태 값을 넣습니다. 그 값이 바뀌어야 숫자가 셉니다.
- 운영체제의 '동작 줄이기'를 켜 두면 Flutter 미리보기는 500ms 이하의 `duration` 에서 새 숫자를 바로 보입니다. Web 미리보기는 그대로 셉니다.

<a id="기본-사용법-basic-usage"></a>

가장 짧게는 `value` 하나만 줍니다. 아래 코드는 Flutter와 Web이 같습니다.

```dart
// 기본 숫자 표시
NumberTicker(value: 1234)

// 표기와 시간 바꾸기
NumberTicker(
  value: 98765,
  formatter: (number) => '\$${number.toStringAsFixed(2)}',
  numberTickerStyle: CoreNumberTickerStyle(
    duration: Duration(milliseconds: CoreDuration.moderate),
  ),
)
```

<a id="동작-스펙-behavior"></a>

## 애니메이션

처음 나타날 때와 값이 바뀔 때의 규칙이 다릅니다. 아래 표의 규칙은 두 플랫폼이 같고, Web의 서버 렌더만 [따로](#서버-렌더-web) 봅니다.

| 상황 | 보이는 것 |
| --- | --- |
| 처음 나타남, `initialValue` 없음 | 애니메이션 없이 `value` 를 바로 보입니다. |
| 처음 나타남, `initialValue` 있음 | `initialValue` 에서 `value` 까지 셉니다. |
| `value` 가 바뀜 | 지금 보이는 숫자에서 새 값까지 셉니다. 새 값이 더 작으면 줄어들며 셉니다. |
| 세는 중에 `value` 가 또 바뀜 | 그 순간 보이는 숫자에서 새 값으로 다시 출발하고, 정한 시간을 처음부터 다시 씁니다. |
| 처음 나타난 뒤 `initialValue` 가 바뀜 | 아무 일도 일어나지 않습니다. |
| `value` 는 그대로이고 `formatter` · `curve` · `numberTickerStyle` 만 바뀜 | 처음부터 새로 세지 않습니다. 새 표기와 글자 모양은 다시 그릴 때 반영됩니다. |
| `duration` 이 `Duration.zero` | 중간 숫자 없이 `value` 를 보입니다. 세는 중에 0으로 바꾸면 곧바로 `value` 가 됩니다. |

위젯이 새로 만들어지면 이전 숫자를 알 수 없습니다. 값에 따라 `key` 를 바꾸면 값이 바뀔 때마다 새로 만들어지므로, `initialValue` 가 없을 때는 세는 과정 없이 새 값이 나타납니다.

### 시간과 곡선

- **시간** 은 `numberTickerStyle` 의 `duration` 입니다. 기본값 `CoreNumberTickerStyle.defaultDuration` 은 `CoreDuration.slow`(500ms)입니다.
- **곡선** 은 `curve` 입니다. 0부터 1까지의 시간 진행 비율을 받아, 값이 얼마나 나아갔는지를 비율로 돌려줍니다.
- `curve` 를 생략하면 두 플랫폼 모두 천천히 출발해 가운데에서 빨라지고 천천히 도착합니다. 식은 같지 않습니다. Flutter는 `CoreEasing.move`(`cubic-bezier(0.42, 0, 0.58, 1)`)를, Web은 2차식 ease-in-out을 씁니다. 같은 곡선이 필요하면 `curve` 를 직접 줍니다.
- 직접 주는 함수는 0에서 0, 1에서 1을 돌려주게 만듭니다. Flutter는 양 끝에서 이 함수를 부르지 않고 출발 값과 `value` 를 그대로 씁니다. Web은 마지막 숫자도 이 함수의 결과로 계산하므로, `curve(1)` 이 1이 아니면 `value` 와 다른 숫자에서 멈춥니다.
- 중간에 1보다 큰 값을 돌려주는 곡선은 숫자가 `value` 를 지나쳤다가 돌아옵니다.

```dart
NumberTicker(
  value: total,
  initialValue: 0,
  curve: (t) => 1 - (1 - t) * (1 - t), // 끝에서 느려지는 곡선
  numberTickerStyle: CoreNumberTickerStyle(
    duration: Duration(milliseconds: CoreDuration.moderate),
  ),
)
```

## 숫자 표기

<Preview demo="number-ticker/formats" />

`formatter` 는 숫자를 받아 화면에 보일 글자를 돌려줍니다. 천 단위 쉼표, 통화 기호, 단위, 지역별 표기는 저절로 붙지 않으므로 여기에서 만듭니다.

```dart
// 반올림한 정수에 천 단위 쉼표를 넣습니다.
String grouped(num number) =>
    number.round().toString().replaceAll(RegExp(r'\B(?=(\d{3})+$)'), ',');

NumberTicker(value: 1234567, formatter: grouped)
NumberTicker(value: 1234567, formatter: (number) => '₩${grouped(number)}')
NumberTicker(value: 99.5, formatter: (number) => '${number.toStringAsFixed(1)}%')
```

- **세는 중의 숫자도 `formatter` 를 지납니다.** 중간 숫자에는 소수점 아래 값이 붙으므로 `round()` 나 `toStringAsFixed()` 로 자릿수를 정합니다.
- **들어오는 값은 `double` 입니다.** 매개변수 타입은 `num` 이고, `value` 에 `int` 를 줘도 같습니다. `'$number'` 처럼 그대로 이어 붙이면 세는 중에는 긴 소수가 보이고, 마지막 숫자도 실행 환경에 따라 `1280.0` 이나 `1280` 이 됩니다.

<a id="현재-fallback-제약과-우회"></a>

### 표기를 생략했을 때

`formatter` 를 생략하면 두 플랫폼의 표기 규칙이 다릅니다. 둘 다 천 단위 쉼표는 넣지 않습니다.

| 플랫폼 | 규칙 | `value: 99.5` 의 마지막 표시 |
| --- | --- | --- |
| Flutter | 늘 정수로 반올림합니다. | `100` |
| Jaspr Web | `value` 가 정수면 정수로, 아니면 소수 둘째 자리까지 보입니다. 세는 중의 숫자도 같은 자릿수입니다. | `99.50` |

두 플랫폼에 같은 소수 자릿수가 필요하면 `formatter` 를 주거나 `NumberTicker.builder` 로 직접 그립니다. 숫자의 단위도 `formatter` 나 `builder` 에서 정합니다.

## 직접 그리기

표시를 직접 만들려면 `NumberTicker.builder` 를 씁니다. `builder(context, number, child)` 의 `number` 는 지금 보일 숫자(매개변수 타입은 `num`, 들어오는 값은 `double`)이고, `child` 는 생성자의 `child` 로 넘긴 것 그대로입니다. 숫자와 함께 바뀌지 않는 부분은 `child` 로 넘깁니다.

<Preview demo="number-ticker/builder" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
NumberTicker.builder(
  value: score,
  child: Icon(LucideIcons.star),
  builder: (context, number, child) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ?child,
      const Gap.space8(),
      Text('${number.round()}점').headlineSmall.onSurface,
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
NumberTicker.builder(
  value: score,
  child: Icon(LucideIcons.star),
  builder: (context, number, child) => div(
    classes: 'inline-flex items-center',
    [
      ?child,
      const Gap.space8(),
      Text('${number.round()}점').headlineSmall.onSurface,
    ],
  ),
)
```

  </TabItem>
</Tabs>

- `value` · `initialValue` · `curve` 와 `duration`(인스턴스와 테마)은 기본 생성자와 같게 동작합니다.
- `textStyle`(인스턴스와 테마)과 고정폭 숫자는 적용되지 않습니다. 글자 모양은 `builder` 안에서 정합니다.
- Web에서는 NumberTicker가 루트 `<span>` 을 만들지 않고 `builder` 의 결과를 그대로 그립니다. 생성자에 준 `id` · `classes` · `css` · `attributes` · 이벤트 핸들러는 반영되지 않으므로, `builder` 가 돌려주는 요소에 직접 답니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 대시보드에서 바뀌는 수치를 눈에 띄게 보일 때
- 랜딩 페이지의 사용자 수, 매출 같은 통계를 세어 올릴 때. Web에서는 [서버 렌더](#서버-렌더-web)를 함께 확인합니다.
- 게임이나 포인트의 점수 변화를 보일 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 남은 시간처럼 정해진 범위(기본 0–99)의 정수를 하나씩 바꿔 보일 때 | [Countdown](/components/countdown) |
| 완료율이나 진행률을 막대로 보일 때 | [Progress](/components/progress) |
| 라벨, 설명, 변화량까지 묶은 지표를 보일 때 | [Stat](/components/stat) |
| 움직일 필요가 없는 숫자를 보일 때 | [Text](/components/text) |

NumberTicker는 시간을 세는 타이머가 아닙니다. 시간에 따라 달라지는 값은 앱에서 계산해 `value` 로 넘깁니다.

<a id="do"></a>
<a id="dont"></a>

### 표기와 갱신

<Cards columns="2">
<Card demo="number-ticker/do-format" tone="do" eyebrow="이렇게 하세요">

숫자의 뜻에 맞는 `formatter` 를 줍니다. 통화 기호와 천 단위 쉼표가 있으면 무슨 값이고 얼마나 큰지 바로 읽힙니다.

</Card>
<Card demo="number-ticker/dont-format" tone="dont" eyebrow="이렇게 하지 마세요">

큰 금액을 `formatter` 없이 두지 않습니다. 생략했을 때의 표기에는 쉼표도 단위도 없습니다.

</Card>
</Cards>

```dart
NumberTicker(
  value: revenue,
  // grouped 는 '숫자 표기' 절의 천 단위 쉼표 함수입니다.
  formatter: (number) => '₩${grouped(number)}',
)
```

값은 의미 있는 변화가 있을 때만 바꿉니다. 새 값이 올 때마다 지금 숫자에서 다시 출발하므로, 매 프레임처럼 `duration` 보다 훨씬 자주 바꾸면 움직임이 부자연스럽고 보이는 숫자가 실제 값보다 뒤처집니다. Web은 새 값이 올 때마다 16ms 타이머를 다시 시작합니다. 그래서 `duration` 이 0이 아닐 때 값이 16ms보다 짧은 간격으로 계속 바뀌면, 그동안에는 보이는 숫자가 움직이지 않습니다.

## 배치

<Preview demo="number-ticker/placement" />

NumberTicker에는 폭, 정렬, 줄 수를 정하는 전용 속성이 없습니다. 놓이는 자리는 부모에서 정합니다.

- 기본 생성자는 숫자마다 폭이 같은 글자 모양(고정폭 숫자)을 요청합니다. 글꼴이 지원하면 숫자만 바뀌는 동안에는 폭이 흔들리지 않습니다. 자릿수가 달라지거나 쉼표, 부호가 생기면 폭이 달라집니다.
- 세는 동안 옆 요소가 밀리지 않게 하려면 폭을 정한 상자에 넣고 끝에 맞춥니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  width: CoreSpace.space128,
  child: Align(
    alignment: AlignmentDirectional.centerEnd,
    heightFactor: 1,
    child: NumberTicker(value: total, initialValue: 0),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  classes: 'flex justify-end',
  styles: Styles(raw: {'width': pinnedLengthCss(CoreSpace.space128)}),
  [NumberTicker(value: total, initialValue: 0)],
)
```

  </TabItem>
</Tabs>

## 테마와 스타일

내용과 동작은 위젯 파라미터(`value` · `initialValue` · `formatter` · `curve` · `builder` · `child`)로 정하고, 세는 시간과 글자 모양은 `numberTickerStyle`(`CoreNumberTickerStyle`)로 정합니다.

<Preview demo="number-ticker/styles" />

- 기본 생성자의 글자는 `titleLarge` 역할(CoUI 기본 타이포그래피에서 20px · SemiBold)입니다. 색은 정하지 않으므로 둘러싼 글자색을 따릅니다.
- `textStyle` 은 기본값 위에 덮입니다. `CoreTextStyle(fontSize: 32)` 처럼 크기만 주면 굵기는 `titleLarge` 의 것이 남습니다. 다른 글자 역할을 주면 크기, 굵기, 줄 높이가 그 역할을 따릅니다.
- 고정폭 숫자는 Flutter에서는 `FontFeature.tabularFigures()`, Web에서는 `tabular-nums` 클래스로 요청합니다.

### 값이 정해지는 순서

뒤에 있는 값이 앞의 값을 필드별로 덮습니다.

```text
CoreNumberTickerStyle.defaultDuration · defaultTextStyle   // 디자인 시스템 기본값
  → CoreComponentTheme.numberTicker.style                  // 앱 전체
  → numberTickerStyle                                      // NumberTicker 하나
```

Flutter는 이렇게 정해진 `duration` 에 '동작 줄이기'를 마지막으로 적용합니다. 설정이 켜져 있으면 500ms 이하의 값은 0이 됩니다.

### 사용 예

<Split>

<Code language="dart" title="NumberTicker 하나만 바꾸기">
NumberTicker(
  value: 1280,
  numberTickerStyle: CoreNumberTickerStyle(
    duration: Duration(milliseconds: CoreDuration.moderate),
    textStyle: CoreTextStyle.token(
      CoreTextStyles.headlineSmall,
      color: CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    numberTicker: CoreNumberTickerTheme(
      style: CoreNumberTickerStyle(
        duration: Duration(milliseconds: CoreDuration.moderate),
        textStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 `numberTickerStyle` 에 값을 덧붙인 사본을 돌려줍니다. 생성자의 `numberTickerStyle` 인자와 같게 동작하고, 겹치는 필드는 뒤에 이은 값이 이깁니다. 아래 예제는 `initialValue: 0` 을 주었으므로 처음 나타날 때 0부터 셉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class NumberTickerChainExample extends StatefulWidget {
  const NumberTickerChainExample({super.key});

  @override
  State<NumberTickerChainExample> createState() => _NumberTickerChainExampleState();
}

class _NumberTickerChainExampleState extends State<NumberTickerChainExample> {
  @override
  Widget build(BuildContext context) {
    return NumberTicker(
      value: 1234,
      initialValue: 0,
    ).withStyle(
      const CoreNumberTickerStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.headlineSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class NumberTickerChainExample extends StatefulComponent {
  const NumberTickerChainExample({super.key});

  @override
  State<NumberTickerChainExample> createState() => _NumberTickerChainExampleState();
}

class _NumberTickerChainExampleState extends State<NumberTickerChainExample> {
  @override
  Component build(BuildContext context) {
    return NumberTicker(value: 1234, initialValue: 0).withStyle(
      const CoreNumberTickerStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.headlineSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 기본값이 있는 곳

시간과 글자의 기본값은 `coui_core` 의 `CoreNumberTickerStyle` 에 있고, Flutter와 Web이 같은 값을 읽습니다. 생략한 `curve` 와 `formatter` 의 동작은 [플랫폼마다 다릅니다](#플랫폼-차이).

| 이름 | 값 | 설명 |
| --- | --- | --- |
| `CoreNumberTickerStyle.defaultDuration` | `CoreDuration.slow` (500ms) | 새 값까지 세는 시간 |
| `CoreNumberTickerStyle.defaultTextStyle` | `CoreTextStyles.titleLarge`, 색 없음 | 기본 생성자의 글자 |

<a id="접근성-accessibility"></a>

## 접근성

NumberTicker는 역할, 이름, 알림을 따로 붙이지 않습니다. 접근성 정보에는 화면에 보이는 글자가 그대로 담깁니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | NumberTicker가 붙이는 `Semantics` 는 없습니다. 안의 `Text` 가 만드는 글자 정보만 있습니다. |
| Jaspr Web | 루트 `<span>` 에 `role` 도 `aria-*` 도 붙이지 않습니다. 직접 넘긴 `attributes` 는 그대로 붙습니다(기본 생성자). |

`NumberTicker.builder` 로 그리면 `builder` 가 돌려주는 위젯이나 요소가 역할을 정합니다.

### 키보드

없음. 누르는 컴포넌트가 아니어서 처리하는 키가 없고, 두 플랫폼 모두 포커스를 받지 않습니다. Web 생성자는 `onKeyDown` · `onKeyUp` 을 받지만 루트에 `tabindex` 를 붙이지 않습니다. `attributes` 로 `tabindex` 를 직접 주지 않으면 포커스가 오지 않아 키 이벤트도 오지 않습니다.

### 스크린 리더

- **이름** — 기본 생성자에서는 `formatter` 가 만든 글자(생략하면 [생략했을 때의 표기](#현재-fallback-제약과-우회))입니다. 별도 라벨은 없으므로 단위와 뜻은 `formatter` 의 글자나 옆의 글이 말하게 합니다.
- **세는 중** — Flutter의 `Text` 접근성 라벨과 Web `<span>` 의 글자는 화면과 함께 중간 숫자로 바뀝니다. 세는 중에 읽으면 중간 숫자가 읽힐 수 있습니다.
- **알림** — 없습니다. 두 플랫폼 모두 live region이 아니어서 값이 바뀐 것을 따로 알리지 않습니다.

#### 최종값만 전하기

화면의 세는 숫자는 보조 기술에서 숨기고, 최종값을 담은 글을 따로 전합니다. 이 글은 세는 동안에는 바뀌지 않고 `value` 로 만든 문장만 담습니다. 바뀐 값을 알릴 필요가 없으면 `liveRegion` 줄(Flutter)이나 `role` 줄(Web)을 뺍니다. 실제로 읽고 알리는 방식은 스크린 리더와 브라우저에 따라 다르므로 대상 환경에서 확인하세요.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  label: '합계 $total원',
  liveRegion: true, // 바뀐 값을 알려야 할 때만
  excludeSemantics: true,
  child: NumberTicker(value: total, initialValue: 0),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div([
  NumberTicker(
    value: total,
    initialValue: 0,
    attributes: const {'aria-hidden': 'true'},
  ),
  span(
    classes: 'sr-only',
    attributes: const {'role': 'status'}, // 바뀐 값을 알려야 할 때만
    [Text('합계 $total원')],
  ),
])
```

  </TabItem>
</Tabs>

Web에서 `NumberTicker.builder` 를 쓰면 `aria-hidden` 은 `builder` 가 돌려주는 요소에 붙입니다.

### 포커스 관리

없음. 포커스를 받지 않고, 오버레이가 아니어서 포커스를 옮기거나 가두거나 돌려놓지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 운영체제나 브라우저의 '동작 줄이기'(`prefers-reduced-motion`)를 켜도 NumberTicker는 그대로 셉니다. 이 설정을 읽지 않고, CSS 전환이 아니라 타이머로 숫자를 바꿉니다. |
| Flutter | '동작 줄이기'가 0으로 만드는 것은 500ms 이하의 `duration` 뿐입니다. 더 길게 주면 설정을 켜도 그대로 셉니다. |
| 공통 | 세는 동안 글자가 계속 바뀝니다. NumberTicker를 그대로 live region으로 만들면(Web `role="status"`, Flutter `Semantics(liveRegion: true)`) 최종값 하나가 아니라 중간 숫자까지 알려질 수 있습니다. [최종값만 전하기](#최종값만-전하기)의 구성을 씁니다. |
| Jaspr Web | `NumberTicker.builder` 에서는 `id` · `classes` · `css` · `attributes` · 이벤트 핸들러가 반영되지 않습니다. `builder` 가 돌려주는 요소에 직접 답니다. |

#### 동작 줄이기에 맞추기

'동작 줄이기'에 관한 두 제약은 앱에서 설정을 읽어 `duration` 을 `Duration.zero` 로 주면 피할 수 있습니다. 아래는 NumberTicker 하나에 주는 방법입니다. `CoreComponentTheme.numberTicker` 의 `style` 에 주면 `duration` 을 따로 정하지 않은 NumberTicker 모두에 적용됩니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

500ms보다 긴 시간을 쓰는 곳에만 필요합니다.

```dart
NumberTicker(
  value: total,
  numberTickerStyle: CoreNumberTickerStyle(
    duration: resolveReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: CoreDuration.ms1000),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

앱의 의존성에 `universal_web` 을 더합니다. 아래 코드는 그릴 때 설정을 읽으므로, 화면이 열린 동안 바꾼 설정은 다시 그릴 때 반영됩니다.

```dart
import 'package:universal_web/web.dart' as web;

final reduceMotion =
    kIsWeb && web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

NumberTicker(
  value: total,
  numberTickerStyle: CoreNumberTickerStyle(
    // null 이면 테마의 값이나 기본값을 씁니다.
    duration: reduceMotion ? Duration.zero : null,
  ),
)
```

  </TabItem>
</Tabs>

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`value` · `initialValue` · `formatter` · `curve` · `builder` · `child` · `numberTickerStyle` 은 두 플랫폼이 같은 이름을 씁니다. 그리는 방식과 몇 가지 동작은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 기본 생성자가 그리는 것 | `Text` | `<span>` (`inline-block` · `tabular-nums` · 글자 역할 클래스) |
| 숫자를 바꾸는 방법 | `AnimatedValueBuilder` 가 화면 프레임마다 지난 시간에 맞춰 다시 그립니다. | 16ms 간격의 타이머(`Timer.periodic`)가 돌 때마다 16ms씩 나아갑니다. 브라우저가 타이머를 늦추면 그만큼 오래 걸립니다. |
| 기본 곡선 | `CoreEasing.move` | 2차식 ease-in-out |
| 직접 준 `curve` 의 양 끝 | 함수를 부르지 않고 출발 값과 `value` 를 씁니다. | 마지막 숫자도 `curve(1)` 로 계산합니다. |
| `formatter` 를 생략한 표기 | 늘 정수 | `value` 가 정수면 정수, 아니면 소수 둘째 자리 |
| '동작 줄이기' | `MediaQuery.disableAnimations` 나 `AccessibilityFeatures.reduceMotion` 이 켜지면 500ms 이하의 `duration` 을 0으로 만듭니다. | 읽지 않습니다. |
| `builder` 의 타입 | `NumberTickerBuilder` (`Widget` 반환) | `WebNumberTickerBuilder` (`Component` 반환) |
| HTML 속성과 이벤트 | 없음 | 기본 생성자의 루트 `<span>` 에 닿습니다. |
| 글자 확대 | `Text` 가 `MediaQuery` 의 글자 배율을 따릅니다. | `rem` 크기라 브라우저의 글자 크기를 따릅니다. |

### 서버 렌더 (Web)

Jaspr가 서버에서 HTML을 만들 때는 타이머를 시작하지 않습니다. 그래서 `initialValue` 가 있는지에 따라 HTML에 담기는 숫자가 다릅니다.

| 설정 | 서버가 만든 HTML | 브라우저 |
| --- | --- | --- |
| `initialValue` 없음 | `value` | 그대로 보이고, 이후 `value` 가 바뀌면 셉니다. |
| `initialValue` 있음 | `initialValue` | 컴포넌트가 브라우저에서 실행되면 `initialValue` 에서 `value` 까지 셉니다. |
| `initialValue` 가 있고 `duration` 이 0 | `value` | `value` |

- `@client` 컴포넌트 바깥의 정적 본문처럼 브라우저에서 실행되지 않는 자리에서는 `initialValue` 가 화면에 계속 남습니다.
- 스크립트를 실행하지 않는 환경에서도 `initialValue` 가 보입니다. HTML에 최종 숫자가 있어야 하면 `initialValue` 를 주지 않습니다.
- `formatter` 에서 숫자를 `'$number'` 로 이어 붙이면 서버(Dart VM)는 `1280.0`, JavaScript로 컴파일한 브라우저는 `1280` 을 만듭니다. `round()` 나 `toStringAsFixed()` 를 씁니다.

<a id="props-parameters"></a>

## API

생성자는 둘입니다. 숫자를 글자로 그리는 기본 생성자와, 표시를 직접 만드는 `NumberTicker.builder` 입니다. `formatter` 는 기본 생성자에만, `builder` 와 `child` 는 `.builder` 에만 있습니다. 표의 `W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

### `NumberTicker` (기본 생성자)

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `num` | 필수 | 보일 값. 바뀌면 새 값까지 셉니다. 안에서는 `double` 로 바꿔 계산합니다. |
| `formatter` | `CoreNumberTickerFormatter?` (`String Function(num)`) | `null` | 숫자를 화면의 글자로 바꿉니다. `null` 이면 [플랫폼마다 다른 표기](#현재-fallback-제약과-우회)를 씁니다. |
| `initialValue` | `num?` | `null` | 처음 나타날 때의 출발 값. 그 뒤의 변경은 읽지 않습니다. |
| `curve` | `double Function(double)?` | `null` | 0–1의 진행 비율을 받는 곡선 함수. `null` 이면 ease-in-out입니다. |
| `numberTickerStyle` | `CoreNumberTickerStyle?` | `null` | 세는 시간과 글자 모양 |

### `NumberTicker.builder`

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `num` | 필수 | 보일 값. 바뀌면 새 값까지 셉니다. |
| `builder` | `W Function(BuildContext, num, W?)` | 필수 | 지금 숫자로 표시를 만듭니다. |
| `child` | `W?` | `null` | `builder` 의 셋째 인자로 그대로 전달합니다. |
| `initialValue` | `num?` | `null` | 처음 나타날 때의 출발 값 |
| `curve` | `double Function(double)?` | `null` | 0–1의 진행 비율을 받는 곡선 함수 |
| `numberTickerStyle` | `CoreNumberTickerStyle?` | `null` | 여기에서는 `duration` 만 적용합니다. |

### 웹 전용

아래 값은 기본 생성자가 그리는 루트 `<span>` 에 닿습니다. `NumberTicker.builder` 도 같은 이름을 받지만 반영하지 않습니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성. `role`, `aria-*`, `data-*` 등 |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트의 id와 배치용 클래스 · 스타일. `css` 는 겹치는 CSS 속성에서 `numberTickerStyle` 이 만든 값보다 뒤에 옵니다. |
| `onClick` · `onMouseEnter` · `onMouseLeave` | `UiMouseEventHandler?` | `null` | 마우스 이벤트 |
| `onKeyDown` · `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 키 이벤트. 루트가 포커스를 받지 않으면 오지 않습니다. |
| `onInput` · `onChange` | `UiInputEventHandler?` | `null` | 생성자는 받지만, 넘긴 함수가 불리지 않습니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 그 밖의 DOM 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreNumberTickerStyle patch)` | `numberTickerStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({value, initialValue, formatter, curve, numberTickerStyle, key})` | 바꾼 값으로 사본을 만듭니다. 생략하거나 `null` 을 준 값은 그대로 남습니다. `builder` 와 `child` 는 바꿀 수 없고, `.builder` 로 만든 것은 `.builder` 로 남아 `formatter` 를 쓰지 않습니다. Web은 웹 전용 속성도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.numberTicker` | `CoreNumberTickerTheme?` | 앱의 모든 NumberTicker에 적용합니다. `style` 에 `CoreNumberTickerStyle` 을 줍니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreNumberTickerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `duration` | `Duration?` | Value interpolation animation duration override. |
| `textStyle` | `CoreTextStyle?` | Text style override (applied to the formatted numeric child). |

<!-- STYLE_TABLE:END -->

<Note>

`textStyle` 은 기본 생성자가 그리는 글자에 적용합니다. `NumberTicker.builder` 에서는 `duration` 만 적용하고, 글자 모양은 `builder` 가 정합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="number-ticker/related-stat" title="Stat">

라벨과 함께 지표 값을 보입니다.

</Card>
<Card demo="number-ticker/related-countdown" title="Countdown">

정해진 범위의 정수를 보입니다. 시간을 줄이는 일은 앱이 합니다.

</Card>
<Card demo="number-ticker/related-progress" title="Progress">

진행률을 막대로 보입니다.

</Card>
</Cards>
