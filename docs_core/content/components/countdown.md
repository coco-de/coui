---
title: Countdown
description: 정수 하나를 큰 숫자로 보여 주는 표시 전용 컴포넌트입니다. 범위를 벗어난 값은 범위의 끝 값으로 보이고, 시간을 세는 일은 앱이 맡습니다.
category: display
platforms: [flutter, web]
related: [number-ticker, stat, progress, loading]
tags: [timer, animation, real-time, event]
template: v2
source: display/countdown
---

# Countdown

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

값, 위 끝(`max`), 글자 역할, 색을 바꿔 보고 만들어진 코드를 복사하세요. 처음 상태는 `max` 를 365 로 올려 120 을 그립니다. `max: 365` 를 끄면 같은 값이 99 로 보입니다. 시간은 흐르지 않으므로 `value` 를 직접 골라 숫자가 바뀌는 모습을 봅니다.

<Playground component="countdown" />

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 값과 범위

`Countdown` 은 `value` 를 `min` 과 `max` 사이로 맞춘 정수(`value.clamp(min, max)`) 하나를 글로 그립니다. 기본 범위는 0 부터 99 까지입니다. 누를 수 있는 부분이나 상태는 없는 표시 전용 컴포넌트입니다.

<Preview demo="countdown/range" />

- `min` 보다 작은 값은 `min` 으로, `max` 보다 큰 값은 `max` 로 보입니다. 값이 잘렸다는 에러나 표시는 없습니다.
- 100 이상을 보이려면 `max` 를 올립니다. 자릿수를 따로 제한하지 않으며, `min` 을 음수로 두면 음수도 그립니다.
- 숫자를 있는 그대로 적습니다. 앞에 0 을 붙이거나(`08`) 천 단위를 나누는(`1,000`) 파라미터는 없습니다.
- `min` 이 `max` 보다 크면 그릴 때 `ArgumentError` 가 납니다.

<a id="애니메이션"></a>

## 값이 바뀔 때

`Countdown` 에는 타이머, 완료 콜백, 단위, 비활성 상태가 없습니다. 부모가 새 `value` 로 다시 그릴 때 숫자가 바뀌고, 그 숫자가 초인지 분인지도 부모가 정합니다.

- **Flutter** — `AnimatedSwitcher` 와 `FadeTransition` 으로, 나가는 숫자와 들어오는 숫자를 가운데에 겹쳐 선형으로 페이드합니다. 처음 그릴 때는 전환이 없고, 범위에 맞춘 결과가 같으면(기본 범위에서 100 → 101, 둘 다 99) 전환하지 않습니다.
- **Web** — 같은 `<span>` 안의 글이 바로 바뀝니다. 숫자끼리 겹치는 페이드는 없습니다. 루트에는 `color` 와 `opacity` 의 CSS transition 이 있어, 글자색을 바꾸면 부드럽게 바뀝니다.

전환 시간은 두 플랫폼 모두 `countdownStyle` 의 `animationDuration` 이고, 기본은 `CoreDuration.fast`(150ms)입니다.

### 타이머 연결하기

1초마다 하나씩 줄이는 예입니다. 타이머는 화면을 벗어날 때 부모가 멈춥니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

class ResendCountdown extends StatefulWidget {
  const ResendCountdown({super.key});

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  late final Timer _timer;
  int _seconds = 59;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds -= 1);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Countdown(value: _seconds);
}
```

</TabItem>
<TabItem label="Web" value="web">

```dart
import 'dart:async';

import 'package:coui_web/coui_web.dart';

class ResendCountdown extends StatefulComponent {
  const ResendCountdown({super.key});

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  Timer? _timer;
  int _seconds = 59;

  @override
  void initState() {
    super.initState();
    // 서버에서 그릴 때는 타이머를 켜지 않습니다.
    if (!kIsWeb) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds -= 1);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => Countdown(value: _seconds);
}
```

</TabItem>
</Tabs>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 남은 시간이나 남은 일수처럼 앱이 계산한 정수를 크게 보여 줄 때
- 일 · 시간 · 분 · 초를 단위마다 하나씩 나눠 보여 줄 때
- 인증번호 재전송이나 세션 만료까지 남은 초를 숫자로 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 이전 값에서 새 값까지 중간 숫자를 거쳐 움직여야 할 때 | [NumberTicker](/components/number-ticker) |
| 진행 정도를 숫자 대신 비율 막대로 보여 줄 때 | [Progress](/components/progress) |
| 라벨 · 값 · 변화량을 묶은 지표를 보여 줄 때 | [Stat](/components/stat) |

<a id="do"></a>
<a id="dont"></a>

### 단위, 범위, 맥락

<Cards columns="2">
<Card demo="countdown/time-row" tone="do" eyebrow="이렇게 하세요">

시 · 분 · 초는 단위마다 `Countdown` 을 하나씩 놓습니다. `Countdown` 하나는 정수 하나만 그립니다.

</Card>
<Card demo="countdown/dont-total-seconds" tone="dont" eyebrow="이렇게 하지 마세요">

남은 시간을 초 하나로 합쳐 넘기면 몇 시간 몇 분인지 바로 읽히지 않습니다.

</Card>
<Card demo="countdown/do-max" tone="do" eyebrow="이렇게 하세요">

99 를 넘을 수 있는 값에는 `max` 를 함께 올립니다.

</Card>
<Card demo="countdown/dont-clamped" tone="dont" eyebrow="이렇게 하지 마세요">

`max` 를 생략하면 120 이 에러 없이 99 로 보입니다.

</Card>
<Card demo="countdown/do-context" tone="do" eyebrow="이렇게 하세요">

무엇이 얼마나 남았는지는 옆의 글로 말합니다.

</Card>
<Card demo="countdown/dont-bare" tone="dont" eyebrow="이렇게 하지 마세요">

숫자만 두면 무엇의 42 인지 알 수 없습니다. 컴포넌트가 보조 기술에 주는 이름도 숫자뿐입니다.

</Card>
</Cards>

### 타이머는 앱이 맡습니다

값을 한 번만 넘기고 저절로 줄어들기를 기대하지 마세요. `Countdown` 은 받은 값을 보여 줄 뿐 스스로 줄이지 않습니다. 줄어드는 숫자가 필요하면 [타이머 연결하기](#타이머-연결하기)처럼 부모가 `value` 를 갱신합니다.

```dart
// 부모가 다른 값을 넘기기 전까지 계속 60 입니다
Countdown(value: 60)
```

## 배치

`Countdown` 은 숫자만 그립니다. 배경, 여백, 테두리, 단위 글은 주변에서 더합니다. Web 의 루트는 `inline-block` 인 `<span>` 입니다.

### 한 줄로 잇기

<Preview demo="countdown/time-row" />

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space4,
  children: [
    Countdown(value: hours),
    Text(':').headlineLarge,
    Countdown(value: minutes, max: 59),
    Text(':').headlineLarge,
    Countdown(value: seconds, max: 59),
  ],
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
div([
  Countdown(value: hours),
  Text(':').headlineLarge,
  Countdown(value: minutes, max: 59),
  Text(':').headlineLarge,
  Countdown(value: seconds, max: 59),
], classes: 'flex items-center gap-${CoreSpace.scale.space4}')
```

</TabItem>
</Tabs>

한 자리 수는 앞에 0 없이 보입니다. 5분 3초는 `5 : 3` 이 됩니다.

<a id="네-단위의-공통-너비-호출부-조합"></a>

### 네 단위의 공통 너비

`Countdown` 은 정수 하나만 그립니다. 일 · 시간 · 분 · 초의 상자와 단위 글은 쓰는 쪽에서 조합합니다. 아래 예제의 네 상자는 너비 하나를 함께 씁니다. 단위 글이 가장 넓은 숫자보다 좁은 이 예제에서 그 너비는 `max(CoreSize.size56, 가장 넓은 숫자의 폭 + 좌우 여백)` 이고, 좌우 여백은 각각 `CoreSpace.space8` 입니다. 여백과 상자 사이 간격은 밀도를 따르며, 글자나 밀도를 바꾸면 그때의 치수로 다시 배치됩니다. 재어 둔 너비를 상수로 적거나 자릿수마다 너비를 어림하지 않습니다.

<Preview demo="countdown/units" />

실행 가능한 예제: [Flutter 소스](https://github.com/coco-de/coui/blob/main/docs_core/lib/previews/examples/flutter/countdown/countdown_units_example.dart), [Web 소스](https://github.com/coco-de/coui/blob/main/docs_core/lib/previews/examples/web/countdown/countdown_units_example.dart). 두 예제가 쓰는 상자 스타일과 단위 글은 [공유 예제 토큰](https://github.com/coco-de/coui/blob/main/docs_core/lib/shared/countdown_units_sample.dart)에 있습니다. 문서에서 따로 테스트하는 조합 예제이며, 라이브러리의 컴포넌트나 API 가 아닙니다.

- Flutter 는 `IntrinsicWidth` 안의 `Row` 에 같은 flex 의 `Expanded` 칸 네 개를 둡니다. 각 칸은 최소 56 이고, 행은 네 칸 모두에 가장 넓은 칸의 폭을 똑같이 줍니다. 칸 사이는 따로 둔 `Gap` 입니다.
- Web 은 `width: max-content` 인 `inline-grid` 에 `repeat(4, 1fr)` 을 적용합니다. 부모의 전체 폭을 채우지 않고, 가장 넓은 칸을 기준으로 네 칸이 함께 커집니다.
- 첫 칸은 `Countdown(value: days, max: 365)` 처럼 그려 100 이상을 받습니다(`days` 의 기본값은 100). `max` 를 생략하면 100 이 99 로 보입니다. 나머지 세 값 8 · 30 · 15 는 `max: 59` 이고, 8 은 앞에 0 없이 `8` 로 보입니다.
- 숫자는 폭이 같은 고정폭 숫자라, 101 → 100 이나 99 → 98 에서는 너비가 그대로입니다. 100 → 99 에서는 100 일 때 숫자와 여백을 합한 폭이 56 을 넘었다면 네 칸이 함께 좁아집니다. Flutter 는 나가는 숫자의 페이드가 끝날 때까지 그 숫자의 폭을 유지합니다.

단위 글을 번역하거나 스타일을 바꿀 때는 글의 폭을 확인하세요. 단위 글에 여백을 합한 폭이 지금 너비보다 커지면 그 폭이 기준이 되어 네 칸이 함께 넓어집니다. 좁은 부모에서는 행을 가로로 스크롤할 자리를 마련합니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`value` · `min` · `max` 는 위젯 파라미터로 넘기고, 숫자의 겉모습과 전환 시간은 `countdownStyle`(`CoreCountdownStyle`) 하나로 바꿉니다.

<Preview demo="countdown/styles" />

- `fontSize` — 글자 크기(논리 px). 기본 글자 역할의 제목 크기는 화면 폭에 따라 바뀌지만, 직접 준 크기는 폭이 달라져도 그대로입니다.
- `color` — 글자색.
- `labelStyle` — 글자 스타일(`CoreTextStyle`). 필드마다 기본값 위에 합쳐지므로, 역할만 바꾸면(`CoreTextStyle.token(CoreTextStyles.titleLarge)`) 색은 `onSurface` 로 남습니다.
- `animationDuration` — 전환 시간. 닿는 대상은 플랫폼마다 다릅니다(플랫폼 차이 섹션).

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreCountdownStyle 의 기본값            // headlineLarge · onSurface · 150ms
  → CoreCountdownTheme.style           // 프로젝트 공통
  → countdownStyle                     // 인스턴스별
```

글자는 위에서 합친 결과를 `기본 글자 → labelStyle → fontSize · color` 순서로 겹쳐 정합니다. `fontSize` 와 `color` 가 같은 뜻의 `labelStyle` 값을 이깁니다. 테마와 인스턴스를 먼저 합치고 나서 겹치므로, **테마에 둔 `fontSize` · `color` 는 인스턴스의 `labelStyle` 에 적은 크기와 색도 이깁니다.** 프로젝트 기본값은 되도록 `labelStyle` 에 두면 인스턴스가 그 위를 덮을 수 있습니다.

### 사용 예

<Split>

<Code language="dart" title="하나만 바꾸기">
Countdown(
  value: 42,
  countdownStyle: CoreCountdownStyle(
    fontSize: CoreFontSize.s60,
    color: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    countdown: CoreCountdownTheme(
      style: CoreCountdownStyle(
        labelStyle: CoreTextStyle.token(CoreTextStyles.displaySmall),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter 와 Web 코드가 같습니다.

### 기본값이 있는 곳

| 이름 | 값 |
| --- | --- |
| `CoreCountdownStyle.defaultLabelStyle` | `headlineLarge` 역할 + `onSurface` 색 |
| `CoreCountdownStyle.defaultAnimationDuration` | `CoreDuration.fast` (150ms) |
| `CoreCountdownContract.defaultMinValue` | 0 |
| `CoreCountdownContract.defaultMaxValue` | 99 |

CoUI 기본 타이포에서 `headlineLarge` 는 데스크톱 폭에서 32, 굵기 700, 줄 높이 140% 입니다. `CoUIApp` · `CoUIWeb` 의 기본 설정에서는 화면 폭이 1024 미만이면 28, 768 미만이면 24 로 내려갑니다. 두 플랫폼 모두 숫자는 폭이 같은 고정폭 숫자(tabular figures)로 그립니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Countdown` 에 `withStyle` 을 이어 `CoreCountdownStyle` 을 덧붙일 수 있습니다. 넘긴 값은 `countdownStyle` 에 합쳐지고, 같은 필드는 나중에 이은 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CountdownChainExample extends StatefulWidget {
  const CountdownChainExample({super.key});

  @override
  State<CountdownChainExample> createState() => _CountdownChainExampleState();
}

class _CountdownChainExampleState extends State<CountdownChainExample> {
  @override
  Widget build(BuildContext context) {
    return const Countdown(value: 42).withStyle(
      const CoreCountdownStyle(
        fontSize: CoreFontSize.s48,
        color: CoreColor.token(CoreColors.primary),
        animationDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CountdownChainExample extends StatefulComponent {
  const CountdownChainExample({super.key});

  @override
  State<CountdownChainExample> createState() => _CountdownChainExampleState();
}

class _CountdownChainExampleState extends State<CountdownChainExample> {
  @override
  Component build(BuildContext context) {
    return Countdown(value: 42).withStyle(
      const CoreCountdownStyle(
        fontSize: CoreFontSize.s48,
        color: CoreColor.token(CoreColors.primary),
        animationDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`Countdown` 은 표시 전용입니다. 두 플랫폼 모두 숫자를 live region 으로 표시하고, 범위에 맞춘 숫자를 이름으로 줍니다.

### 역할

| 플랫폼 | 마크업과 시맨틱 |
| --- | --- |
| Flutter | `Semantics(liveRegion: true, label: …)` 로 숫자를 감쌉니다. 버튼이나 이미지 같은 역할은 지정하지 않습니다. |
| Jaspr Web | `aria-live="polite"` 와 `aria-label` 을 가진 `<span>` 안에 숫자 글이 담긴 `<span>` 이 하나 있습니다. `role` 은 붙이지 않으며, 필요하면 `attributes` 로 넘깁니다. |

### 키보드

없음. 조작할 것이 없는 표시 전용이라 처리하는 키가 없습니다. Flutter 는 포커스 노드를 만들지 않고, Web 은 `tabindex` 를 붙이지 않습니다.

### 스크린 리더

- **이름** — 화면과 같은 `value.clamp(min, max)` 의 결과입니다. Flutter 는 `Semantics` 의 `label` 에, Web 은 `aria-label` 과 안쪽 글에 담깁니다. Flutter 에서는 라벨에 숫자가 두 번 들어갑니다(알려진 제약).
- **알림** — Flutter 는 `liveRegion: true`, Web 은 `aria-live="polite"` 로 표시합니다. 바뀐 값을 언제, 어떻게 읽는지는 보조 기술에 따라 다릅니다.

#### 맥락 더하기

이름에 들어가는 것은 숫자뿐입니다. 무엇이 남았는지는 보이는 글로 옆에 둡니다. 문장 하나로 알려야 하면 아래처럼 합니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Semantics(
  label: '인증번호 재전송까지 $seconds초',
  liveRegion: true,
  excludeSemantics: true, // 안쪽 숫자의 라벨은 빼고 이 문장만 남깁니다
  child: Countdown(value: seconds),
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
// 숫자는 보조 기술에서 숨깁니다. 알릴 문장은 앱이 따로 만든
// live region 에 넣고, 알리고 싶은 때에만 그 글을 바꿉니다.
Countdown(value: seconds, attributes: {'aria-hidden': 'true'})
```

</TabItem>
</Tabs>

### 포커스 관리

없음. 포커스를 받거나 옮기거나 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 단위나 대상을 이름에 넣는 파라미터가 없습니다. 위의 "맥락 더하기"를 씁니다. |
| 공통 | live region 을 끄는 파라미터가 없습니다. 1초마다 `value` 를 바꾸면 라이브 영역의 내용도 1초마다 바뀌고, 시 · 분 · 초처럼 여러 개를 놓으면 하나하나가 live region 입니다. 바뀌는 간격은 부모가 정하므로, 초 단위가 필요 없으면 `value` 를 덜 자주 바꿉니다. 알림을 직접 정하려면 Flutter 는 `ExcludeSemantics` 로 감싸고, Web 은 `attributes: {'aria-hidden': 'true'}` 로 숨긴 뒤 알릴 글을 따로 둡니다. |
| Flutter | `Semantics` 의 `label` 안쪽에 같은 숫자의 `Text` 가 그대로 있어 두 글이 합쳐집니다. 값이 42 로 멈춰 있을 때 시맨틱 라벨은 `42` 한 번이 아니라 줄을 바꿔 이은 `42` 두 번입니다. 숫자를 한 번만 담으려면 `Semantics(label: …, liveRegion: true, excludeSemantics: true)` 로 감쌉니다. |
| Jaspr Web | `aria-live` 와 `aria-label` 은 컴포넌트가 마지막에 넣으므로, `attributes` 로 같은 키를 넘겨도 덮이지 않습니다. |
| Jaspr Web | 루트는 역할이 없는 `<span>` 입니다. ARIA 는 이런 요소에 `aria-label` 로 이름 붙이는 것을 허용하지 않으므로 보조 기술이 그 이름을 쓰지 않을 수 있습니다. 화면의 숫자는 안쪽 글로도 들어 있습니다. |

#### 동작 줄이기

- **Flutter** — 동작 줄이기(Android 의 애니메이션 제거, iOS 의 Reduce Motion)를 켜면 500ms 이하의 `animationDuration` 은 0 이 되어 숫자가 바로 바뀝니다.
- **Web** — HTML `<head>` 에 넣는 CoUI 테마 CSS(`ThemeConfig` 의 `cssVariables`)가 `prefers-reduced-motion` 에서 500ms 이하의 `animationDuration` 으로 만든 transition 시간을 0 으로 만듭니다. `CoreDuration` 에 없는 값(예: 175ms)도 같습니다.
- 500ms 를 넘는 값은 두 플랫폼 모두 줄이지 않습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름 `Countdown` 과 `value` · `min` · `max` · `countdownStyle` 은 두 플랫폼이 같습니다. 그리는 방식은 아래처럼 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 구조 | `Semantics` → `AnimatedSwitcher` → `Text` | `<span>` 안의 글 `<span>` |
| 값 변경 | 두 숫자를 겹쳐 페이드 | 글만 바로 교체 |
| 전환 중 폭 | 두 숫자 중 넓은 쪽 | 바로 새 숫자의 폭 |
| 전환 시간이 닿는 곳 | 숫자 페이드(선형 곡선) | `color` · `opacity` transition(`move` 곡선) |
| 글자색만 변경 | 바로 바뀜 | `animationDuration` 동안 바뀜 |
| 고정폭 숫자 | `FontFeature.tabularFigures()` | `tabular-nums` 클래스 |
| 시맨틱 이름 | `label` 에 숫자가 두 번 | `aria-label` 에 숫자 |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `int` | 필수 | 보여 줄 정수. `min` 과 `max` 사이로 맞춰 그립니다. |
| `min` | `int` | `0` | 범위의 아래 끝(포함) |
| `max` | `int` | `99` | 범위의 위 끝(포함). `min` 보다 작으면 `ArgumentError` 가 납니다. |
| `countdownStyle` | `CoreCountdownStyle?` | `null` | 글자 크기 · 색 · 글자 스타일 · 전환 시간 덮어쓰기 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 id |
| `classes` | `String?` | `null` | 루트에 덧붙이는 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 같은 속성은 컴포넌트의 값을 덮습니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `aria-live` 와 `aria-label` 은 컴포넌트의 값이 남습니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트에 거는 DOM 이벤트 |

### 메서드

- `copyWith(...)` — 준 인자만 바꾼 새 `Countdown` 을 만듭니다. Web 의 `classes` 는 바꿔 끼우지 않고 이미 있는 클래스와 함께 남습니다.
- `withStyle(patch)` — `patch` 를 `countdownStyle` 에 합친 새 `Countdown` 을 만듭니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCountdownStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `fontSize` | `double?` | Display font size override (logical px). |
| `color` | `CoreColor?` | Display text colour override. |
| `animationDuration` | `Duration?` | Digit transition / fade animation duration override. |
| `labelStyle` | `CoreTextStyle?` | Label text style override (applied to the numeric child). |

<!-- STYLE_TABLE:END -->

<Note>

`animationDuration` 이 위 표의 숫자 전환 시간으로 쓰이는 것은 Flutter 입니다. Web 에는 숫자 전환이 없고, 이 값은 루트의 `color` · `opacity` CSS transition 시간이 됩니다. Web 의 `labelStyle` 은 루트 `<span>` 에 적용되고 안쪽 숫자 글이 이어받습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="countdown/related-number-ticker" title="NumberTicker">

값이 바뀌면 중간 숫자를 거치며 움직입니다. 통계 숫자처럼 움직임을 보여야 할 때 씁니다.

</Card>
<Card demo="countdown/related-progress" title="Progress">

진행 정도를 비율 막대로 보여 줍니다.

</Card>
<Card demo="countdown/related-stat" title="Stat">

라벨, 값, 단위, 변화량을 묶은 지표입니다.

</Card>
</Cards>
