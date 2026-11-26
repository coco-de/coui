---
title: InputOtp
description: 인증 코드처럼 자리 수가 정해진 숫자를 칸마다 한 자리씩 입력받는 컴포넌트입니다. SMS 인증 코드 자동 완성을 지원합니다.
category: form
platforms: [flutter, web]
related: [text-field, formatted-input, form]
tags: [interactive, form-control, authentication]
template: v2
source: form/input_otp
---

# InputOtp

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 입력창을 확인하고, 만들어진 코드를 그대로 복사하세요. 무대의 입력창은 칸을 눌러 실제로 입력할 수 있습니다.

<Playground component="input-otp" />

Flutter 와 Jaspr Web 은 같은 `InputOtp` 를 같은 속성으로 씁니다. 다른 것은 값의 모양 하나입니다 — Flutter 의 값은 문자 코드 목록(`List<int?>`, `'1'` 은 49)이고 Jaspr Web 의 값은 숫자 문자열입니다. 그래서 `initialValue` 를 적는 줄만 두 플랫폼의 코드가 다르고, 나란히 볼 때 코드를 둘로 보여 줍니다.

<Note>

플레이그라운드 무대의 바탕은 `surface` 입니다. 숫자가 들어간 칸의 바탕도 `surface` 라 채운 칸은 테두리(`outline`)로만 무대와 구분되고, 빈 칸(`surfaceContainerLow`)은 무대와 한 단계 다른 채움입니다. 두 모습을 함께 보이려고 처음 값으로 앞의 세 칸을 채워 두었습니다. **처음 값**을 끄면 빈 칸만 남습니다. 이 페이지의 다른 미리보기 판도 `surface` 라 채운 칸은 같은 방식으로 구분됩니다.

</Note>

## 구조

입력창은 칸이 늘어선 줄 하나입니다. 칸 수만큼의 칸과, 정한 간격마다 놓이는 구분 막대로 이루어집니다.

<Anatomy demo="input-otp/anatomy">
<AnatomyItem part="container" side="left" name="Container">

칸 줄 전체. 눈에 보이지 않는 입력창 하나가 이 줄을 덮고 키보드 · 자동 완성 · 포커스를 맡습니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="digit">

입력한 숫자. `obscured: true` 면 숫자 대신 점(10, `onSurface`)을 그립니다.

</AnatomyItem>
<AnatomyItem select="div + div div[aria-hidden=true]" side="top" name="cell">

숫자가 들어간 칸. 바탕 `surface`, 테두리 `outline` 입니다.

</AnatomyItem>
<AnatomyItem select="span[aria-hidden=true]" side="top" name="separator">

구분 막대. `separatorInterval` 칸마다 놓이는 길이 8 · 두께 2 의 둥근 `outline` 막대이고, 좌우로 4 씩 띄웁니다. 기본은 세 칸마다입니다.

</AnatomyItem>
<AnatomyItem select="div ~ div:last-child div[aria-hidden=true]" side="right" name="empty cell">

아직 비어 있는 칸. 바탕 `surfaceContainerLow`, 테두리 `outlineVariant` 입니다.

</AnatomyItem>
</Anatomy>

그림에 보이지 않는 부분이 둘 있습니다. 포커스를 받으면 다음에 입력할 칸(활성 칸)에 커서(2 × 20, `primary`)와 포커스 링이 나타나고, `errorText` 를 주면 칸 줄 아래에 오류 문구가 놓입니다(상태 참고).

## Variant

variant 는 둘이고, 직접 고르지 않습니다. `errorText` 를 주면 `error` 가, 주지 않으면 `defaultVariant` 가 됩니다.

<Preview demo="input-otp/variants" />

| variant | 켜지는 때 | 바뀌는 것 |
| --- | --- | --- |
| `defaultVariant` | `errorText` 가 `null` 일 때 | 기본 모습 |
| `error` | `errorText` 를 줄 때 | 빈 칸 · 채운 칸 · 호버 · 활성 칸의 테두리와 커서, 포커스 링이 `error` 색이 됩니다. 칸 줄 아래에 오류 문구가 놓입니다. |

`CoreInputOtpVariant` 는 앱 전체 기본값에서 variant 별 모습을 바꿀 때 씁니다(`CoreInputOtpTheme.variantStyles`, 테마와 스타일 참고).

<a id="크기-size"></a>

## 크기

크기는 `md` 와 `lg` 두 단계이고 `md` 가 기본값입니다. `lg` 는 인증 번호 입력처럼 코드를 입력하는 것이 화면의 유일한 일일 때 씁니다 — 칸 · 모서리 · 숫자 · 커서가 함께 커집니다.

<SizeSpec component="input-otp" props="initialValue=12" />

앱의 밀도(compact · spacious)를 바꾸면 칸 사이 간격과 칸의 모서리는 한 칸씩 움직이지만, 칸의 크기는 그대로입니다.

### 크기별 세부 값

| | `md` | `lg` |
|---|---|---|
| 칸 | 44 × 52 | 56 × 64 |
| 모서리 | 10 | 14 |
| 숫자 | `titleMedium` 18 · SemiBold | `headlineSmall` 24 · SemiBold |
| 커서 | 2 × 20 | 2 × 24 |
| 가림 점 | 10 | 10 |
| 칸 사이 | 8 | 8 |
| 빈 칸 | `surfaceContainerLow` · `outlineVariant` | `surfaceContainerLow` · `outlineVariant` |
| 채운 칸 | `surface` · `outline` | `surface` · `outline` |
| 호버 보더 | `outline` | `outline` |
| 활성 칸 보더 | `outline` | `outline` |
| 보더 두께 | 1 | 1 |

행 높이(`height`)는 칸을 따라 `md` 에서 52, `lg` 에서 64 가 됩니다. 칸의 색, 구분 막대, 오류 문구는 크기와 상관없이 같습니다. `inputOtpStyle` 에 적은 값은 크기 단계보다 우선합니다. 다만 `lg` 는 칸의 세로(`cellHeight` 64)를 스스로 적으므로, `lg` 위에서 칸 크기를 바꿀 때는 `cellSize` 와 `cellHeight` 를 함께 적습니다.

`lg` 의 숫자는 `headlineSmall` 역할(24)에 굵기만 SemiBold 로 바꾼 것입니다. 칸은 화면 폭과 상관없이 같은 크기라서, 좁은 화면에서 제목 역할이 작아지는 규칙(글자 단계)이 숫자에는 닿지 않습니다 — 숫자는 어느 폭에서나 데스크톱 크기로 그려집니다.

<a id="높이가-다른-셀"></a>

### 칸의 세로 높이

기본 칸은 세로로 조금 긴 44 × 52 입니다. 칸 크기를 바꿀 때 `cellSize`(너비)만 적으면 칸은 그 값의 정사각형이 되고, 세로를 따로 정하려면 `cellHeight` 를 함께 적습니다. 행 높이(`height`)는 칸보다 낮아지지 않으므로 따로 맞추지 않아도 됩니다 — Flutter 에서 칸이 줄어들거나 Jaspr Web 에서 칸이 행 밖으로 넘치는 일이 없습니다.

<Preview demo="input-otp/cell-height" />

```dart
InputOtp(
  length: 6,
  separatorInterval: 0,
  inputOtpStyle: const CoreInputOtpStyle(
    cellSize: CoreSize.size48,
    cellHeight: CoreSize.size56,
  ),
)
```

<a id="동작-스펙-behavior"></a>

## 상태

칸은 숫자가 들어 있는지에 따라 두 모습이고, 입력창 전체는 포커스 · 호버 · 오류 · 비활성 상태를 가집니다.

<Preview demo="input-otp/states" />

그림에는 포커스와 호버가 없습니다 — 플레이그라운드의 입력창을 눌러 활성 칸 · 커서 · 포커스 링을 확인하세요.

| 항목 | 동작 |
| --- | --- |
| 빈 칸 · 채운 칸 | 빈 칸은 `surfaceContainerLow` 바탕에 `outlineVariant` 테두리, 숫자가 들어간 칸은 `surface` 바탕에 `outline` 테두리입니다. |
| 활성 칸 | 포커스를 받으면 다음에 입력할 칸 — 입력한 숫자 바로 다음 칸, 다 채웠으면 마지막 칸 — 이 활성 칸이 됩니다. 바탕은 그 칸의 모습 그대로이고 테두리만 `outline` 입니다. `primary` 테두리는 쓰지 않습니다. |
| 커서 | 활성 칸이 비어 있을 때만 그 가운데에 그립니다. 2 × 20(`lg` 2 × 24), `primary` 입니다. |
| 포커스 링 | 활성 칸 하나의 둘레에만 그립니다. 줄 전체를 감싸지 않습니다. 색은 기본 포커스 링 색이고, 오류일 때는 `error` 입니다. |
| Hover | 포인터를 입력창 위에 올리면 쉬고 있는 칸의 테두리가 `outline` 으로 한 단계 진해집니다(채운 칸은 이미 `outline` 이라 그대로). 칸 하나가 아니라 입력창 전체가 한 단위로 반응합니다. 비활성이면 없고, 포커스를 가진 동안에는 칸이 바뀌지 않으며, 오류일 때는 `error` 를 그대로 둡니다. |
| 오류 | `errorText` 를 주면 테두리 · 커서 · 포커스 링이 `error` 가 되고, 칸 줄 아래 4 띄워 `circle-alert` 아이콘(14)이 붙은 문구가 놓입니다. 호버해도 `error` 그대로입니다. |
| 가림 | `obscured: true` 면 숫자 대신 지름 10 의 `onSurface` 점을 그립니다. |
| 비활성 | 칸 줄을 50% 불투명도로 그리고 입력 · 포커스 · 호버를 받지 않습니다. `errorText` 의 오류 문구는 흐리지 않습니다. |
| 전환 시간 | 칸의 색이 150ms 동안 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |

우선순위는 `비활성 > 오류 > 포커스 > 호버 > 기본` 입니다.

### 상태 전환

- 비어 있음 → 입력 중: 첫 자리를 입력합니다.
- 입력 중 → 다 채움: 마지막 자리를 입력하거나 붙여넣기 · 자동 완성으로 다 채웁니다. 이때 포커스를 놓고 `onCompleted` 를 한 번 부릅니다.
- 다 채움 → 입력 중: `Backspace` 로 자리를 지웁니다. 다시 다 채우면 `onCompleted` 를 다시 부릅니다.

## 입력 방식

<a id="아키텍처-단일-히든-입력-flutterweb-공통"></a>

### 숨은 입력 하나

화면에 보이는 칸은 **각각 입력창이 아닙니다**. 키보드 · 자동 완성 연결은 보이지 않는 입력창 하나가 맡고, 칸은 그 값을 읽어 그리기만 합니다. Flutter 는 투명한 `TextField` 위에 칸을 겹쳐 그리고(칸은 포인터를 받지 않습니다), Jaspr Web 은 `opacity: 0` 인 `<input>` 하나가 칸 줄 전체를 덮고 그 아래의 칸 `<div>` 는 `pointer-events: none` 입니다.

**왜 입력창이 하나인가**: 칸마다 입력창을 두면 숫자를 칠 때마다 포커스가 입력창 사이를 옮겨 다니고, 그때마다 iOS · Android 의 SMS 자동 완성 연결이 끊어집니다. 실제 기기에서 자동 완성이 되다 말다 하는 원인이 이것입니다. 입력창이 하나면 운영체제와 브라우저의 인증 코드 제안이 끊기지 않습니다.

<a id="인터랙션"></a>

### 입력과 붙여넣기

- **다음 칸으로 넘어가기**: 따로 하는 일이 없습니다. 한 입력창에 계속 치므로 숫자가 다음 칸으로 이어집니다.
- **어느 칸을 눌러도 캐럿은 끝으로**: 가운데 칸이나 빈 칸을 눌러도 캐럿은 지금까지 입력한 값의 끝으로 갑니다. 숨은 입력창 안의 글자 위치는 화면의 칸 격자와 관계가 없어서, 누른 위치로 캐럿을 두면 엉뚱한 자리에 놓이기 때문입니다. Flutter 는 `TextField.onTap` 과 포커스를 얻을 때, Jaspr Web 은 `click` · `focus` 에서 캐럿을 끝으로 옮깁니다.
- **지우기**: `Backspace` 는 캐럿 앞의 자리를 지웁니다. 캐럿은 보통 끝에 있으므로 마지막 자리가 지워지고, 활성 칸이 한 칸 앞으로 옵니다. 입력창의 기본 동작 그대로입니다.
- **붙여넣기**: 붙여넣은 글자에서 숫자만 남깁니다. Flutter 는 "인증번호는 123456 입니다" 처럼 문장을 통째로 붙여넣어도 코드만 남습니다. Jaspr Web 은 브라우저가 칸 수만큼 먼저 자르므로 숫자 앞에 다른 글자가 있으면 코드가 모자라게 들어갑니다(알려진 제약).
- **SMS 자동 완성**: Flutter 는 `AutofillHints.oneTimeCode`(iOS `UITextContentType.oneTimeCode`, Android 자동 완성의 `AUTOFILL_HINT_SMS_OTP`), Jaspr Web 은 `autocomplete="one-time-code"` 와 [WebOTP API](https://developer.mozilla.org/en-US/docs/Web/API/WebOTP_API) 를 씁니다. WebOTP 는 지원하는 브라우저에서만 SMS 가 오면 값을 채우고, 지원하지 않으면 아무 일도 하지 않아 손으로 입력하거나 붙여넣으면 됩니다. Jaspr Web 은 입력창이 활성이고 처음 값으로 다 채워지지 않았을 때만 마운트하면서 WebOTP 를 요청하고, 다 채우거나 입력창이 사라지면 요청을 거둡니다.

### 칸을 눌러 고치기

`allowCellEditing: true` 면 이미 입력한 칸을 눌러 그 숫자를 고를 수 있고, 다음에 치는 숫자가 그 자리를 바꿉니다. 고른 칸에서 `Backspace` 를 누르면 그 숫자가 지워지고 뒤의 숫자가 한 칸씩 앞으로 당겨집니다. 빈 칸을 누르면 캐럿은 입력의 끝으로 갑니다. 활성 칸 표시도 캐럿을 따라갑니다. 포커스와 자동 완성은 이때도 숨은 입력 하나가 맡습니다.

기본값은 `false` 입니다 — 어느 칸을 눌러도 끝에서 이어 쓰고 지웁니다. 플레이그라운드에서 **칸 편집**을 켜고 앞의 칸을 눌러 보세요.

### 값의 모양

Flutter 의 값은 문자 코드 목록(`OTPCodepointList`, 곧 `List<int?>`)입니다. 빈 자리는 `null` 이고 `'1'` 은 49 입니다. 문자열이 필요하면 `String.fromCharCodes(value.nonNulls)` 로 바꿉니다. Jaspr Web 의 값은 숫자 문자열입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
InputOtp(
  length: 6,
  initialValue: '123456'.codeUnits,
  onCompleted: (code) => verifyCode(String.fromCharCodes(code.nonNulls)),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
InputOtp(
  length: 6,
  initialValue: '123456',
  onCompleted: verifyCode,
)
```

  </TabItem>
</Tabs>

처음 값이 칸 수보다 길면 앞의 `length` 자리만 씁니다. 처음 값으로 다 채워져 있으면 `onCompleted` 를 부르지 않습니다 — 한 번 지운 뒤 다시 다 채울 때 부릅니다.

### 다 채웠을 때

콜백은 `onChanged` → (다 채운 순간이면) 포커스 놓기 → `onCompleted` 순서로 옵니다. 포커스를 놓는 것은 모바일 화면 키보드를 내리기 위해서입니다. 이미 다 채운 코드를 같은 길이로 고쳐도 `onCompleted` 는 다시 부르지 않고, 덜 채운 상태로 돌아갔다가 다시 다 채우면 다시 부릅니다. 서버 검증과 제출은 콜백을 받은 쪽의 일입니다.

<a id="유효성"></a>

### 받는 글자

- 숫자(0–9)만 받습니다. 화면 키보드는 숫자 키보드가 됩니다(Flutter `keyboardType: number`, Jaspr Web `inputmode="numeric"`).
- 칸 수(`length`)보다 많이 들어오지 않습니다.
- `enabled: false` 면 입력 · 붙여넣기 · 자동 완성을 모두 받지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- SMS 나 이메일로 받은 인증 코드를 입력받을 때
- 앱 잠금을 푸는 PIN 을 입력받을 때
- 2단계 인증 코드 입력 화면을 만들 때
- 자리 수가 정해져 있고, 입력하면 저절로 다음 칸으로 넘어가야 할 때

SMS 인증 화면처럼 코드를 입력하는 것이 그 화면의 일이면 `autofocus: true` 를 줍니다. 화면이 뜨자마자 키보드가 올라와 바로 입력할 수 있습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 길이가 정해지지 않은 글자를 입력받을 때 | [TextField](/components/text-field) |
| 날짜 · 전화번호처럼 구분 글자가 끼는 형식을 입력받을 때 | [FormattedInput](/components/formatted-input) |

<a id="do"></a>
<a id="dont"></a>

### PIN 과 인증 실패

<Cards columns="2">
<Card component="input-otp" props="length=4;separatorInterval=0;obscured;initialValue=1234" tone="do" eyebrow="이렇게 하세요">

PIN 처럼 남에게 보이면 안 되는 값은 `obscured: true` 로 칸을 가립니다. 구분 막대도 끄면(`separatorInterval: 0`) 한 덩어리로 읽힙니다.

</Card>
<Card component="input-otp" props="length=4;separatorInterval=0;initialValue=1234" tone="dont" eyebrow="이렇게 하지 마세요">

PIN 을 숫자 그대로 보여 주면 옆 사람이 화면에서 읽을 수 있습니다.

</Card>
<Card component="input-otp" props="length=4;separatorInterval=0;initialValue=1234;errorText=PIN 이 맞지 않습니다. 다시 입력해 주세요." tone="do" eyebrow="이렇게 하세요">

인증에 실패하면 `errorText` 로 무엇이 틀렸고 무엇을 하면 되는지 알립니다.

</Card>
<Card component="input-otp" props="length=4;separatorInterval=0;initialValue=1234;errorText=PIN 이 맞지 않습니다" tone="dont" eyebrow="이렇게 하지 마세요">

무엇이 잘못됐는지만 말하면 다음 행동을 알 수 없습니다. 실패를 아예 알리지 않고 입력한 코드를 그대로 두는 것도 같습니다.

</Card>
</Cards>

입력창은 값을 스스로 비우지 않습니다. 다시 입력하게 하려면 새 `key` 로 입력창을 다시 만듭니다.

```dart
InputOtp(
  key: ValueKey(attemptCount),
  length: 6,
  errorText: verifyFailed ? '인증번호가 일치하지 않습니다' : null,
  onCompleted: (code) async {
    final ok = await authService.verify(code);
    setState(() {
      verifyFailed = !ok;
      if (!ok) attemptCount++; // key 가 바뀌어 입력이 비워집니다.
    });
  },
)
```

### 자리 수

코드는 4–8 자리로 둡니다. 자리가 늘수록 칸 줄이 길어집니다 — `md` 기본값(세 칸마다 구분 막대)에서 6 자리 줄은 328, 8 자리 줄은 456 이라, 좌우 여백이 16 씩인 폭 360 화면에서는 7 자리부터 칸이 작아집니다(배치 참고). `lg` 는 6 자리도 400 입니다. 자리가 많으면 옮겨 적는 동안 틀리기도 쉽습니다.

## 배치

### 좁은 자리

칸 줄은 줄바꿈하지 않습니다. 자리가 칸 줄보다 좁으면 칸 · 간격 · 숫자를 같은 비율로 줄여 맞추고 왼쪽에 붙입니다 — Flutter 는 `FittedBox(fit: scaleDown)`, Jaspr Web 은 칸 줄의 폭을 재어 `transform: scale` 을 겁니다. 자리가 넉넉하면 원래 크기로 그리고, 입력창은 내용의 폭만큼만 차지합니다. 키보드와 자동 완성을 맡은 숨은 입력은 줄이지 않습니다.

<Note>

Jaspr Web 의 줄이기는 브라우저에서 입력창이 실행된 뒤에 일어납니다. 서버가 그린 마크업에는 줄이기가 없어서, 그 마크업만 보이는 동안에는 좁은 자리에서 칸 줄이 넘칠 수 있습니다.

</Note>

<a id="스타일-시스템-style-system"></a>
<a id="테마-커스터마이징-theme"></a>

## 테마와 스타일

크기는 위젯 속성 `size` 로 고르고, 칸의 색 · 크기 · 간격 · 모서리, 커서, 구분 막대, 숫자 글자, 오류 문구처럼 보이는 값은 `inputOtpStyle`(`CoreInputOtpStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="입력창 하나만 바꾸기">
InputOtp(
  length: 6,
  onCompleted: verifyCode,
  inputOtpStyle: CoreInputOtpStyle(
    cellSpacing: CoreSpace.space12,
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    filledBorderColor: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    inputOtp: CoreInputOtpTheme(
      style: CoreInputOtpStyle(
        cellSpacing: CoreSpace.space12,
        errorValidatorHintStyle: CoreValidatorHintStyle(
          iconStyle: CoreIconStyle(size: CoreIconSize.size16),
        ),
      ),
      variantStyles: {
        CoreInputOtpVariant.error: CoreInputOtpStyle(
          backgroundColor: CoreColor.token(CoreColors.errorContainer),
        ),
      },
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

```text
CoreInputOtpStyle.default*                          // 디자인 시스템 기본값
  → CoreInputOtpStyle.defaultsBySize[size]           // 크기 단계
  → CoreInputOtpStyle.defaultsByVariant[variant]     // 오류일 때의 테두리 · 커서 색
  → CoreComponentTheme.inputOtp.style                // 앱 전체
  → CoreComponentTheme.inputOtp.variantStyles[variant]
  → inputOtpStyle                                    // 입력창 하나
```

뒤로 갈수록 우선합니다. 크기 단계와 변형 단계를 합친 앞부분은 `CoreInputOtpStyle.chainHeadFor(size, variant)` 하나를 두 플랫폼이 함께 읽습니다.

크기 단계는 칸 · 행 높이 · 모서리 · 커서 높이 · 글자 역할을 적고 색은 적지 않습니다. 변형 단계(`errorText` 가 있을 때의 `error`)는 테두리 색과 커서 색만 적고 크기 단계 뒤에 옵니다. 테마 `style` 은 두 단계보다 뒤에 오므로, 테마에 `cellSize: 48` 을 적으면 `md` 와 `lg` 모두 칸 너비가 48 이 됩니다(`lg` 는 세로 64 를 지킵니다). 크기마다 다른 값이 필요하면 테마 대신 입력창 하나의 `inputOtpStyle` 에 적습니다.

같은 이유로 테마 `style` 이나 `inputOtpStyle` 에 테두리 · 커서 색을 적으면 오류일 때도 그 색이 남습니다. 테마에서는 `variantStyles[CoreInputOtpVariant.error]` 에 오류일 때의 색을 함께 적으면 `style` 보다 뒤에 오므로 그쪽이 이깁니다. `inputOtpStyle` 은 그보다도 뒤에 오므로, 입력창 하나에서 바꿀 때는 오류일 때 그 색을 비워 둡니다.

포커스 링의 색은 크기 단계를 읽지 않습니다. 링은 테마 · `inputOtpStyle` · 변형이 적은 `focusBorderColor` 만 따르고, 아무도 적지 않으면 기본 포커스 링 색입니다.

가림 점의 색은 `onSurface` 로 정해져 있습니다. `textStyle` 로 숫자의 색을 바꿔도 점은 따라가지 않습니다.

### 오류 문구

오류 문구는 `ValidatorHint.error` 를 그대로 씁니다 — 아이콘 · 색 · 글자 역할은 `ValidatorHint` 의 것이고, InputOtp 가 바꾸는 것은 아이콘 크기(14)뿐입니다. 그 밖의 오류 문구 모습은 `errorValidatorHintStyle` 에 `CoreValidatorHintStyle` 로 적고, 칸 줄과의 간격은 `errorTextPadding`(기본 위 4)으로 바꿉니다. 예전의 `errorTextStyle` 은 이 값으로 넘겨지며 더는 권하지 않고(`@Deprecated`), 구분 기호 글자 스타일 `separatorTextStyle` 은 구분 기호가 막대로 바뀌어 아무 효과가 없습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `InputOtp` 위에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `inputOtpStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius4` 처럼 Core 토큰 상수와 같은 이름의 짧은 이름도 있습니다 — 이름이 곧 값이라(`radius4` 는 `CoreRadius.radius4`) 어느 컴포넌트에서 써도 뜻이 같습니다. 모서리 이름은 칸의 모서리(`borderRadius`)를, `.primary` 같은 색 이름은 **빈 칸**의 바탕(`backgroundColor`)을 바꿉니다. 숫자가 들어간 칸은 `filledBackgroundColor` 를 따르므로 그대로입니다.

<Preview component="input-otp" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class InputOtpChainExample extends StatelessWidget {
  const InputOtpChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        InputOtp(length: 6, onCompleted: (_) {}).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        InputOtp(length: 6, onCompleted: (_) {}).withStyle(
          const CoreInputOtpStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class InputOtpChainExample extends StatelessComponent {
  const InputOtpChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        InputOtp(length: 6).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        InputOtp(length: 6).withStyle(
          const CoreInputOtpStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

키보드와 보조 기술이 만나는 것은 숨은 입력 하나입니다. 화면의 칸은 그 값을 그리기만 합니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 입력창 전체를 `Semantics(container: true, label:)` 로 묶어 이름을 붙입니다. 안쪽의 숨은 `TextField` 가 텍스트 필드 노드(값 · 포커스 · 활성 상태)와 `AutofillHints.oneTimeCode` 를 가집니다. |
| Jaspr Web | 루트 `<div>` 가 `role="group"` 과 이름(`aria-label`)을 가집니다. 숨은 `<input>` 은 `type="text"` · `inputmode="numeric"` · `pattern="[0-9]*"` · `maxlength` · `autocomplete="one-time-code"` 와 같은 `aria-label` 을 가지고, 비활성이면 `disabled` 가 붙습니다. 화면의 칸과 구분 막대는 모두 `aria-hidden="true"` 입니다. |

오류 문구는 `ValidatorHint.error` 가 그리고, 역할도 그 컴포넌트의 것입니다 — Jaspr Web `role="alert"`, Flutter 라이브 리전.

### 키보드

숨은 입력 하나가 포커스를 가지므로 키 동작은 입력창의 기본 편집 동작 그대로입니다.

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` · `Tab` | 입력창으로 들어오고 나갑니다. 멈추는 곳은 숨은 입력 하나입니다. |
| `0`–`9` | 다음 칸에 숫자를 넣습니다. 숫자가 아닌 글자는 들어가지 않습니다. |
| `Backspace` | 캐럿 앞의 자리(캐럿이 끝에 있으면 마지막 자리)를 지웁니다. `allowCellEditing: true` 로 고른 칸이 있으면 그 칸을 지우고, 뒤의 숫자는 한 칸씩 앞으로 옵니다. |
| `←` · `→` | 숨은 입력 안의 캐럿을 옮깁니다. `allowCellEditing: true` 면 활성 칸 표시가 캐럿을 따라갑니다. |
| `Ctrl` · `V` (`⌘` · `V`) | 붙여넣은 글자에서 숫자만 남깁니다. |

칸 사이를 옮겨 다니는 전용 키는 없습니다 — 칸은 그리기만 하고 편집되는 것은 숨은 입력 하나라서, 자리 이동은 그 입력 안의 캐럿 이동입니다.

### 스크린 리더

- 이름은 로컬라이제이션의 `inputOtpLabel` 에서 옵니다(영어 "One-time password input", 한국어 "일회용 비밀번호 입력"). 이 이름을 바꾸는 속성은 없고 활성 로케일이 정합니다. Jaspr Web 은 그룹과 숨은 입력에 같은 이름을 붙입니다.
- 입력한 코드는 숨은 입력의 값 하나로 읽힙니다. Jaspr Web 의 칸은 `aria-hidden` 이라 스크린 리더가 칸을 하나씩 오가며 읽지 않습니다 — 자리마다 입력창을 두는 것보다 코드 하나를 입력창 하나로 다루는 쪽이 접근성상 낫다는 것이 일반적인 인증 코드 입력 권고입니다.
- 오류는 `errorText` 문구만 `ValidatorHint.error` 의 알림(Jaspr Web `role="alert"`, Flutter 라이브 리전)으로 전합니다. 오류 아이콘은 문구를 되풀이할 뿐이라 읽히지 않습니다. 입력값과 그룹 이름은 알림 밖에 있어, 오류가 바뀌어도 코드 전체를 다시 읽지 않습니다. 실제로 언제 읽는지는 플랫폼과 보조 기술에 따릅니다.
- 자리를 채우거나 다 채운 것을 따로 알리지는 않습니다.

### 포커스 관리

- **들어올 때**: `autofocus: true` 면 마운트할 때 숨은 입력이 포커스를 받습니다. 기본 모드에서는 어느 칸을 눌러도 캐럿이 입력한 마지막 자리 뒤로 갑니다. `allowCellEditing: true` 면 입력한 칸을 눌렀을 때 그 숫자를 고르고, 빈 칸을 누르면 입력의 끝으로 갑니다.
- **나갈 때**: 마지막 자리를 채워 `onCompleted` 를 부르는 순간 포커스를 스스로 놓습니다(Flutter `FocusNode.unfocus()`, Jaspr Web 은 문서에서 포커스를 가진 요소의 `blur` — 알려진 제약 참고). 모바일 화면 키보드를 내리기 위해서입니다. 포커스를 어디로 보낼지는 정해 두지 않았으므로 `onCompleted` 안에서 정합니다.
- **가두기**: 없습니다. 멈추는 곳이 숨은 입력 하나라 `Tab` 한 번으로 입력창 전체를 지나갑니다. `enabled: false` 면 그 하나도 포커스 순서에서 빠집니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `obscured: true` 는 화면만 가립니다 — 스크린 리더는 입력한 코드를 그대로 읽습니다. Jaspr Web 의 숨은 입력은 `type="text"` 이고(보이지 않는 요소에 `password` 를 주면 브라우저의 비밀번호 관리 기능을 건드릴 수 있어 일부러 text 입니다), Flutter 의 숨은 `TextField` 도 값을 가리지 않습니다. 사용자가 보는 점은 화면의 칸이 그립니다. 보조 기술에서까지 값을 가리는 속성은 두 플랫폼 모두 없습니다. |
| Jaspr Web | `errorText` 가 숨은 입력에 연결되지 않습니다. `aria-invalid` · `aria-describedby` 가 붙지 않아, 입력에 다시 포커스했을 때 오류를 설명으로 함께 읽지 않습니다. |
| Flutter | 화면의 칸을 접근성 트리에서 빼지 않습니다(Jaspr Web 의 `aria-hidden` 에 해당하는 것이 없습니다). 입력한 숫자가 입력창의 값과 따로 칸의 글자로 한 번 더 나타날 수 있습니다. |
| 공통 | 기본 모드에서 `←` · `→` 로 캐럿을 옮기면 다음 숫자는 (다 채우지 않았을 때) 그 자리에 끼어 들어가지만, 활성 칸 표시(링 · 커서)는 값의 끝에 남습니다. |
| Jaspr Web | 숨은 입력의 `maxlength` 때문에 브라우저가 붙여넣은 글자를 칸 수만큼 먼저 자른 뒤 숫자만 남깁니다. 숫자 앞에 다른 글자가 있거나 숫자 사이에 띄어쓰기 · 하이픈이 있으면 코드가 모자라게 들어갑니다. Flutter 는 숫자만 남긴 뒤 자릅니다. |
| Jaspr Web | 칸 사이(`cellSpacing`)는 간격 단계(`CoreSpace`)의 값만 그립니다. 단계 밖의 값을 주면 칸이 간격 없이 붙고, Flutter 는 그 값대로 띄웁니다. |
| Jaspr Web | 다 채우면 입력창 자신이 아니라 문서에서 포커스를 가진 요소를 `blur` 합니다. WebOTP 가 SMS 코드를 채울 때 포커스가 다른 입력에 있으면 그 입력의 포커스가 풀립니다. Flutter 는 입력창 자신의 포커스만 놓습니다. |
| Jaspr Web | 마운트한 뒤 `length` 를 바꿔도 입력한 값을 비우지 않고 `initialValue` 를 다시 읽지 않습니다. 칸 수를 바꿀 때는 새 `key` 로 다시 만드세요. Flutter 는 `length` 가 바뀌면 입력을 비우고 `initialValue` 를 다시 읽습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값의 모양 | 빈 자리를 `null` 로 둔 문자 코드 목록(`List<int?>`) | 숫자 문자열 |
| 실제 입력 | 투명한 `TextField` 하나 | 투명한 `<input>` 하나 |
| 자동 완성 | `AutofillHints.oneTimeCode` | `autocomplete="one-time-code"`, 지원하면 WebOTP |
| 다 채운 뒤 포커스 | 입력창 자신의 `FocusNode.unfocus()` | 문서에서 포커스를 가진 요소의 `blur` |
| `length` 를 바꿀 때 | 입력을 비우고 `initialValue` 를 다시 읽습니다 | 입력한 값을 그대로 둡니다 |
| 칸의 접근성 | 칸이 접근성 트리에 남습니다 | 칸 · 구분 막대가 `aria-hidden` |
| 호버 감지 | 입력창 전체를 감싼 `MouseRegion` 이 위젯 상태로 넘깁니다 | 칸이 `pointer-events: none` 이라, 숨은 입력의 `:hover` 를 루트의 이름 붙은 그룹(`group/input-otp`)이 칸에 넘깁니다 — 위젯 상태가 없습니다 |
| 포커스 링 | 포커스를 가지면 그립니다 | `:focus-visible` 일 때 그립니다(글자 입력창은 마우스로 눌러도 해당합니다) |
| 붙여넣기 | 숫자만 남긴 뒤 칸 수로 자릅니다 | 브라우저가 칸 수로 먼저 자른 뒤 숫자만 남깁니다 |
| 좁은 자리 | `FittedBox(fit: scaleDown)` | 칸 줄의 폭을 재어 `transform: scale`. 브라우저에서 실행된 뒤에만 |
| 칸 사이 간격 | 어떤 값이든 그 값대로 | 간격 단계의 값만 |
| 크기 배율 | 칸 · 커서 · 간격에 테마의 크기 배율을 곱합니다 | `rem` 으로 그려 브라우저의 글자 크기를 따릅니다 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · 이벤트 처리기 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 아래 `O` 는 값의 플랫폼 표현 — Flutter `List<int?>`(`OTPCodepointList`) · Jaspr Web `String` — 을 뜻하는 설명용 기호입니다.

### 값

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `length` | `int` | `6` (`CoreInputOtpContract.defaultLength`) | 칸 수 |
| `separatorInterval` | `int` | `3` (`CoreInputOtpContract.defaultSeparatorInterval`) | 몇 칸마다 구분 막대를 둘지. `0` 이면 없습니다. Figma 의 `Show separator` 불리언이 이 값입니다 — 켜면 기본 간격(`3`), 끄면 `0` |
| `initialValue` | `O?` | `null` | 처음 값. 마운트할 때 읽습니다(Flutter 는 `length` 가 바뀔 때도 다시 읽고 입력한 값을 비웁니다). 칸 수보다 길면 앞의 `length` 자리만 씁니다. |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `size` | `CoreInputOtpSize` | `md` (`CoreInputOtpSize.defaultSize`) | 칸 · 모서리 · 숫자 · 커서의 크기 단계. `md` · `lg` |
| `obscured` | `bool` | `false` | 숫자 대신 점을 그립니다. |
| `allowCellEditing` | `bool` | `false` | 입력한 칸을 눌러 그 숫자를 바꿉니다. |
| `errorText` | `String?` | `null` | 지정하면 오류 variant 가 되고 칸 줄 아래에 문구를 보입니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성 |
| `autofocus` | `bool` | `false` | 마운트할 때 포커스를 받습니다. |
| `inputOtpStyle` | `CoreInputOtpStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `void Function(O)?` | `null` | 값이 바뀔 때마다 |
| `onCompleted` | `void Function(O)?` | `null` | 덜 채운 상태에서 다 채운 상태가 될 때 한 번 |

`withStyle(CoreInputOtpStyle patch)` 는 `inputOtpStyle` 에 `patch` 를 합친 사본을 돌려줍니다(빠른 덮어쓰기 참고). Jaspr Web 의 `InputOtp` 는 루트 `<div>` 에 그대로 붙는 `id` · `classes` · `css` · `attributes` 와 이벤트 처리기도 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreInputOtpStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `cellSpacing` | `double?` | Gap between sibling OTP cells (logical px). `null` defers to [defaultCellSpacing]. Consumed natively as `Row.spacing` on Flutter and `gap-${cellSpacing.tailwindSpace}` on Web. |
| `cellSize` | `double?` | Width of each OTP cell (logical px) — and its height too, unless [cellHeight] says otherwise. |
| `cellHeight` | `double?` | Height of each OTP cell (logical px). `null` follows [cellSize], whose own fallback is [defaultCellHeight] — so a caller who states only a width gets a square cell (a 50 × 58 cell is `cellSize: 50, cellHeight: 58`). |
| `obscuredDotSize` | `double?` | Size (logical px, square) of the dot shown for an obscured character. `null` → [defaultObscuredDotSize]. |
| `height` | `double?` | Overall height of the OTP input row (logical px). Never shorter than the cells' own height — see [defaultHeight]. |
| `backgroundColor` | `CoreColor?` | Background colour of an empty OTP cell. `null` → [defaultBackgroundColor]. |
| `borderColor` | `CoreColor?` | Border colour of an empty OTP cell. `null` falls through to the variant's own (the error variant states `error`), then to [defaultBorderColor]. |
| `filledBackgroundColor` | `CoreColor?` | Background colour of a cell that holds a digit. `null` → [defaultFilledBackgroundColor]. |
| `filledBorderColor` | `CoreColor?` | Border colour of a cell that holds a digit. `null` falls through to the variant's own (the error variant states `error`), then to [defaultFilledBorderColor]. |
| `hoverBorderColor` | `CoreColor?` | Border colour of each OTP cell while the pointer is over the control and no cell holds focus. `null` falls through to the variant's own hover border (the error variant restates `error`), then to [defaultHoverBorderColor]. A disabled control never takes it. |
| `focusBackgroundColor` | `CoreColor?` | Background colour of the active cell. `null` keeps the background of the cell's fill state — [backgroundColor] for an empty cell (whose own fallback is [defaultFocusBackgroundColor]), [filledBackgroundColor] for one that holds a digit. |
| `focusBorderColor` | `CoreColor?` | Border colour of the active cell, empty or filled. `null` falls through to the variant's own (the error variant states `error`), then to [defaultFocusBorderColor]. The variant's or a caller's value also colours the focus ring. |
| `borderRadius` | `CoreBorderRadius?` | Border radius of each OTP cell. |
| `borderWidth` | `double?` | Border stroke width of each OTP cell (logical px) — defaults to [defaultBorderWidth]. |
| `caretColor` | `CoreColor?` | Colour of the caret in the active empty cell. `null` falls through to the variant's own (the error variant states `error`), then to [defaultCaretColor]. |
| `caretWidth` | `double?` | Width of the caret (logical px) — defaults to [defaultCaretWidth]. |
| `caretHeight` | `double?` | Height of the caret (logical px) — defaults to [defaultCaretHeight]. |
| `caretBorderRadius` | `CoreBorderRadius?` | Corner of the caret — defaults to [defaultCaretBorderRadius]. |
| `separatorPadding` | `CoreEdgeInsets?` | Padding around the separator bar — defaults to [defaultSeparatorPadding]. |
| `separatorColor` | `CoreColor?` | Colour of the separator bar — defaults to [defaultSeparatorColor]. |
| `separatorWidth` | `double?` | Length of the separator bar (logical px) — defaults to [defaultSeparatorWidth]. |
| `separatorThickness` | `double?` | Thickness of the separator bar (logical px) — defaults to [defaultSeparatorThickness]. |
| `separatorBorderRadius` | `CoreBorderRadius?` | Corner of the separator bar — defaults to [defaultSeparatorBorderRadius]. |
| `transitionDuration` | `Duration?` | Transition duration for cell focus / value changes — defaults to [defaultTransitionDuration]. |
| `textStyle` | `CoreTextStyle?` | Text style applied to the OTP input value. Layered on top of [defaultTextStyle]. |
| `separatorTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.190)** — The separator is a bar now — style it with separatorColor, separatorWidth, separatorThickness and separatorBorderRadius. This field is no longer read. The separator glyph's text style, from before the separator was a bar. Nothing reads it. |
| `errorTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.190)** — Use errorValidatorHintStyle.messageTextStyle — the error line is a composed ValidatorHint. Still forwarded to it. Text style of the error message. Forwarded to the composed `ValidatorHint` as its `messageTextStyle` (its colour as the hint's accent), under [errorValidatorHintStyle]. |
| `errorTextPadding` | `CoreEdgeInsets?` | Padding above the error line — defaults to [defaultErrorTextPadding]. |
| `errorValidatorHintStyle` | `CoreValidatorHintStyle?` | The style of the composed `ValidatorHint` that draws the error line, laid over [defaultErrorValidatorHintStyle]. The hint fills the rest itself — the `error` accent, the `circle-alert` glyph, the message role. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="label=인증번호;placeholder=6자리 숫자" title="TextField">

자리 수가 정해지지 않은 글자를 입력받습니다.

</Card>
<Card title="FormattedInput" href="/components/formatted-input">

날짜 · 전화번호처럼 구분 글자가 끼는 형식을 입력받습니다.

</Card>
<Card title="Form" href="/components/form">

인증 코드를 포함한 입력 요소를 묶고 한 번에 검증합니다.

</Card>
</Cards>
