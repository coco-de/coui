---
title: TimePicker
description: 시 · 분(필요하면 초)을 받는 시간 선택기입니다. 트리거를 눌러 연 팝오버나 대화상자에서 숫자를 입력해 시각을 정할 때 씁니다.
category: form
platforms: [flutter, web]
related: [date-picker, text-field, select]
tags: [interactive, form-control, datetime]
template: v2
source: form/time_picker
---

# TimePicker

<a id="live-preview"></a>
<a id="기본-popover"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 TimePicker 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="time-picker" />

TimePicker 의 트리거는 글자를 칠 수 없는 [TextField](/components/text-field) 이고, 누르면 [Popover](/components/popover)(기본)나 [Dialog](/components/dialog) 로 패널이 열립니다. TimePicker 는 값을 스스로 바꾸지 않습니다 — 저장하면 `onChanged` 에 24시간 문자열(`HH:MM`, 초를 보이면 `HH:MM:SS`)이 오고, 그 값을 `value` 로 다시 넘겨야 트리거가 바뀝니다.

## 구조

닫힌 TimePicker 는 입력창 모양의 트리거 하나입니다. 패널은 트리거를 누르면 열립니다.

<Anatomy demo="time-picker/anatomy">
<AnatomyItem part="container" side="top" name="Container">

트리거 상자입니다. 높이 40, 모서리 10, 1 두께 <code>outlineVariant</code> 테두리이고 부모의 폭을 채웁니다.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="value">

고른 시각입니다. 14 Regular <code>onSurface</code> 이고, 값이 없으면 안내 글자를 <code>placeholder</code> 색으로 보여 줍니다. 글자를 직접 칠 수는 없습니다.

</AnatomyItem>
<AnatomyItem part="leading" side="right" name="clock">

트리거 끝의 시계 아이콘(16 <code>onSurfaceVariant</code>)입니다. 따로 누르는 버튼이 아니라 트리거의 일부입니다.

</AnatomyItem>
</Anatomy>

TimePicker 에는 variant 와 크기 속성이 없습니다. 트리거는 [DatePicker](/components/date-picker) 트리거와 같은 입력창 모양인 TextField 의 `md` 행이고, 높이는 `triggerHeight` 로 바꿉니다.

### 패널

| 부분 | 모습 |
| --- | --- |
| 숫자 칸 | 64 × 60, 모서리 10, 채움 `surfaceContainerHigh`, 테두리 투명. 숫자는 `headlineMedium`(28 Bold) `onSurface` 입니다. 보이는 상자는 칸 하나뿐이고, 안쪽 입력은 따로 테두리를 그리지 않습니다. |
| 칸 이름 | 칸 아래 4 떨어진 시 · 분 · 초 글자(로케일을 따름), 13 `onSurfaceVariant` |
| `:` | 24 Medium `onSurfaceSubtle`, 좌우 여백 8 |
| 오전 · 오후 | 12시간 형식에서만 나옵니다. 숫자 칸에서 16 떨어진 세로 [ToggleGroup](/components/toggle-group) `sm` 하나(AM 위, PM 아래)이고, 높이 `3 + 26 + 2 + 26 + 3 = 60` 으로 숫자 칸과 같습니다. 트랙은 `surfaceContainerHigh`, 고른 칸은 `surfaceRaised` 입니다. |
| 취소 · 저장 | 칸 이름까지 포함한 숫자 칸 줄에서 16 아래, 끝 정렬, 간격 8. 취소는 `ghost`, 저장은 기본 variant 의 [Button](/components/button) 입니다. |
| 패널 상자 | popover 는 [Popup](/components/popup) 판 — 안쪽 여백 16, 모서리 12, 1 두께 `outlineVariant`, 트리거와 간격 4. dialog 는 Dialog 판이고 `dialogTitle` 을 제목으로 씁니다. |

<a id="에러-상태"></a>
<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

트리거는 TextField 의 상태를 따르고, 패널의 숫자 칸에는 자기 상태가 있습니다.

<Preview demo="time-picker/states" />

### 트리거

| 상태 | 모습 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface` |
| 값이 없을 때 | `placeholder` 를, 없으면 `--:--`(초를 보이면 `--:--:--`)를 `placeholder` 색으로 보여 줍니다. |
| Hover | 테두리가 `outline` 으로 한 단 진해집니다. 채움은 바뀌지 않습니다. |
| 눌림 | 채움 위에 `onSurface` 12% 를 덮습니다. |
| Focus | 테두리가 `primary` 로 바뀝니다. 바깥 포커스 링은 키보드로 포커스했을 때만 그립니다. |
| 오류 | `errorText` 가 비어 있지 않으면 테두리가 `error` 가 되고 문구가 트리거 아래에 나옵니다. 포커스해도 테두리와 포커스 링은 `error` 입니다. `enabled: false` 면 오류를 그리지 않습니다. `Fieldset` 으로만 비활성이면 테두리는 비활성 색이 되고 문구는 남습니다. |
| 비활성 | 채움 `disabledContainer`, 값 `disabledContent`, 테두리 `disabledOutline`. 눌러도 열리지 않습니다. `Fieldset` 안의 비활성은 플랫폼마다 다릅니다 — [알려진 제약](#알려진-제약) 참고. |

### 패널 안의 칸

| 상태 | 모습 |
| --- | --- |
| 쉴 때 | 채움 `surfaceContainerHigh`, 숫자 `onSurface`, 테두리 투명 |
| Hover | 칸 모양 그대로 `onSurface` 3% 를 덮습니다. 채움 색과 테두리는 바뀌지 않고, 편집 중인 칸 위에도 같게 덮습니다. |
| 편집 중 | 채움 `primaryContainer`, 숫자 `onPrimaryContainer`, 칸 **안쪽**에 2 두께 `primaryText` 테두리. 마우스로 눌러 들어와도 보입니다. 바깥 링이 아니라 안쪽 테두리인 것은 바깥 링이 옆 칸을 덮거나 패널 가장자리에서 잘리기 때문입니다. 칸 크기와 이웃 칸의 자리는 바뀌지 않습니다. |

### 열기와 닫기

| 동작 | popover(기본) | dialog |
| --- | --- | --- |
| 열기 | 트리거를 누름 | 트리거를 누름 |
| 트리거를 다시 누름 | 닫힘 | 배경막이 트리거를 덮습니다 |
| 저장 | `onChanged` 를 부르고 닫힘 | 같음 |
| 취소 | `onChanged` 없이 닫힘 | 같음 |
| 바깥을 누름 | `onChanged` 없이 닫힘 | 배경막을 누르면 닫힘 |
| `Escape` | Web 만 닫힘 | 두 플랫폼 모두 닫힘 |
| 페이지 스크롤 | 닫지 않음 | 닫지 않음 |
| 전환 시간 | 150ms 동안 열리고 100ms 동안 닫힘 | 200ms |

<a id="초-단위-hhmmss"></a>

## 값과 시간 형식

### 값 형식

- `value` 와 `onChanged` 의 값은 언제나 **24시간** 문자열입니다. `onChanged` 는 `HH:MM` 을, `showSeconds: true` 면 `HH:MM:SS` 를 줍니다. 12시간 형식은 화면에 보이는 모양만 바꿉니다.
- `value` 가 `null` 이거나 빈 문자열이면 트리거에는 안내 글자가 나오고, 패널의 칸은 `00` 에서 시작합니다(12시간 형식이면 오전 12시). 그대로 저장하면 `00:00`(초를 보이면 `00:00:00`)이 옵니다.
- 시와 분을 숫자로 읽지 못하는 값(예: `'02:30 PM'`)도 패널은 `00:00` 에서 시작합니다. 12시간 형식의 트리거는 이런 값을 Flutter 에서는 적힌 그대로 보여 줍니다. Web 은 `:` 앞의 시가 숫자면 시를 12시간으로 바꾸고 `AM` · `PM` 을 덧붙여, `'02:30 PM'` 이 `02:30 PM AM` 으로 보입니다. 시가 숫자가 아니면 Web 도 적힌 그대로입니다.
- 24시간 형식의 트리거는 `value` 를 적힌 그대로 보여 줍니다. `showSeconds: true` 여도 `value` 에 초가 없으면 트리거에는 초가 없습니다.

<Preview demo="time-picker/formats" />

### 12시간 · 24시간

`use24HourFormat` 을 비우면 플랫폼 설정을 따릅니다. Flutter 는 `MediaQuery.alwaysUse24HourFormatOf` 가 참이면 24시간, 아니면 12시간입니다. Web 은 브라우저 언어의 시간 형식을 따르고, 서버에서 렌더할 때는 24시간입니다. 12시간 형식의 패널은 시 칸을 1 ~ 12 로 보여 주고 옆에 오전 · 오후 선택을 둡니다. 선택 칸의 글자는 로케일을 따르지만(`ko` 는 오전 · 오후), 트리거 뒤의 글자는 언제나 `AM` · `PM` 입니다.

### 칸에 입력하기

- 시 · 분 · 초 칸은 숫자를 두 자리까지 받습니다.
- 범위는 입력하는 동안이 아니라 **저장할 때** 맞춥니다. 24시간 형식의 시는 0 ~ 23, 12시간 형식의 시는 0 ~ 12(0 은 12 와 같음), 분과 초는 0 ~ 59 로 맞추고, 빈 칸은 0 입니다. 그래서 12시간 형식에서 `13` 을 치고 저장하면 12 로 줄여 읽어 오전은 00시, 오후는 12시가 됩니다.

<a id="분-간격-minuteinterval"></a>

### 분 간격

`minuteInterval` 은 분 칸이 움직이는 단위입니다. 60 의 약수여야 하므로 어떤 간격이든 `:00` 이 그 배수에 들어 있고, 시간이 바뀌어도 배수가 같은 자리에 반복됩니다. 시 · 초 칸은 바뀌지 않습니다. 60 의 약수가 아닌 값은 assert 를 켠 실행에서 거부됩니다.

- **화살표 키** — 분 칸에서 `↑` 는 다음 배수로, `↓` 는 이전 배수로 옮깁니다(누르고 있으면 반복). 15분 간격이면 `:00 → :15 → :30 → :45 → :00` 입니다. 배수가 아닌 분(`:07`)에서는 위 · 아래의 가장 가까운 배수(`:15` · `:00`)로 갑니다. 수정 키(Shift · Alt · Ctrl · Meta)와 함께 누르면 브라우저 · 프레임워크의 기본 동작(글자 선택 · 캐럿 이동)에 맡깁니다.
- **직접 입력** — 입력하는 동안에는 고치지 않고, 분 칸을 벗어날 때와 저장할 때 가장 가까운 배수로 맞춥니다. `15` 를 치는 도중의 `1` 이 `00` 으로 되돌아가지 않게 하려는 것입니다. 정확히 중간이면 **큰 배수**로 갑니다(반올림). 15분 간격에서 `:07` 은 `:00`, `:08` 은 `:15` 이고, 4분 간격에서 `:02` 는 `:04` 입니다. `:59` 를 넘는 값은 먼저 `:59` 로 줄인 뒤 맞춥니다.
- **`value` 로 들어온 분**은 배수가 아니어도 그대로 보여 주고, 손대지 않아도 저장할 때 같은 규칙으로 맞춥니다. `value: '10:07'`, `minuteInterval: 15` 에서 저장하면 `10:00` 이 옵니다.
- **시간으로 넘기지 않습니다** — 한 시간의 끝은 같은 시의 `:00` 으로 돌아갑니다. 15분 간격에서 `10:53` 은 `11:00` 이 아니라 `10:00` 이고, `↑` 로 `:45` 를 넘겨도 시는 그대로입니다.
- 기본값 `1` 에서는 분 칸을 벗어나도 친 글자를 고쳐 쓰지 않습니다.
- 간격은 **단위이지 경계가 아닙니다** — 고를 수 있는 시각의 범위는 정하지 않습니다([범위 제한](#범위-제한)).

두 플랫폼 모두 같은 규칙을 `coui_core` 의 `CoreMinuteInterval` 에서 읽습니다.

```dart
TimePicker(
  value: appointment,
  showSeconds: true,
  minuteInterval: 15,
  onChanged: setAppointment,
)
```

<a id="경계와-현재-제약"></a>

### 범위 제한

`min` · `max` 는 받기만 하고 패널이 읽지 않습니다. 범위 밖의 시각도 고르고 저장할 수 있습니다. 영업 시간 같은 범위는 `onChanged` 에서 확인하고, 맞지 않으면 `errorText` 로 알립니다.

```dart
TimePicker(
  value: businessHour,
  errorText: businessHourError,
  onChanged: validateAndSaveBusinessHour,
)
```

`validateAndSaveBusinessHour` 는 앱이 만드는 함수입니다 — 범위 안이면 `businessHour` 에 저장하고, 밖이면 `businessHourError` 에 안내 문구를 담습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 예약 · 알림 시각처럼 시와 분(필요하면 초)을 숫자로 정할 때 씁니다.
- 트리거에는 글자를 칠 수 없고, 값은 패널에서 정합니다.
- 키보드로는 패널을 열 수 없습니다. 키보드만으로도 입력해야 하는 화면에는 [TextField](/components/text-field) 나 [FormattedInput](/components/formatted-input) 을 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 날짜를 고를 때. 날짜와 시각이 모두 필요하면 두 컴포넌트를 함께 둡니다 | [DatePicker](/components/date-picker) |
| 정해진 시각 몇 개 가운데 고를 때 | [Select](/components/select) |
| 정해진 형식의 문자열을 직접 치게 할 때 | [FormattedInput](/components/formatted-input) |
| 자유 형식으로 입력받을 때 | [TextField](/components/text-field) |

<a id="do"></a>
<a id="dont"></a>

### 범위와 이름

<Cards columns="2">
<Card demo="time-picker/do-range-check" tone="do" eyebrow="이렇게 하세요">

범위 밖의 시각은 <code>onChanged</code> 에서 확인해 <code>errorText</code> 로 알립니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

<code>min</code> · <code>max</code> 만 넘기고 범위 밖의 시각이 막힌다고 생각하지 않습니다. 패널은 두 값을 읽지 않습니다.

</Card>
<Card demo="time-picker/do-visible-name" tone="do" eyebrow="이렇게 하세요">

이름을 받는 속성이 없으니 화면에 이름 글자를 함께 둡니다. 이 글자는 입력과 연결되지는 않습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

<code>value</code> 에 <code>'02:30 PM'</code> 같은 12시간 글자를 넘기지 않습니다. 읽지 못해 패널이 <code>00:00</code> 에서 시작합니다.

</Card>
</Cards>

<a id="다이얼로그-모드"></a>

## 배치

### 여는 방식

`mode` 를 비우거나 `CorePromptMode.popover` 로 두면 패널이 트리거에 붙어 열리고, `CorePromptMode.dialog` 면 화면 가운데의 대화상자로 열립니다. `dialogTitle` 은 dialog 에서만 보입니다. 화면 크기나 플랫폼에 따라 저절로 바뀌지 않습니다. 위 플레이그라운드에서 `mode` 를 바꿔 확인할 수 있습니다.

```dart
TimePicker(
  value: meetingTime,
  mode: CorePromptMode.dialog,
  dialogTitle: Text('시간 선택'),
  onChanged: setMeetingTime,
)
```

### 팝오버 자리

팝오버의 자리는 `popoverPlacement`(기본 `bottomStart`)로 정합니다. 화면 가장자리에서 자리가 모자라면 반대쪽으로 뒤집고, 그래도 넘치면 밀어 넣습니다. 트리거와의 간격(기본 4)은 `popoverStyle.placementOffset` 입니다.

### 트리거 폭

트리거는 부모가 준 폭을 채웁니다. 폭을 정하려면 폭을 가진 상자 안에 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

여는 방식 · 시간 형식 · 상태 같은 동작은 위젯 속성으로 고르고, 보이는 값은 `timePickerStyle`(`CoreTimePickerStyle`) 하나로 덮어씁니다. 트리거의 값 색은 `contentColor`, 시계는 `trailingIconStyle` 로 바꿉니다. 안에 그리는 부품의 스타일은 그 컴포넌트의 Style 그대로 넘깁니다 — 트리거는 `triggerStyle`(`CoreTextFieldStyle`), 팝오버는 `popoverStyle`(`CorePopoverStyle`, 판은 `popoverStyle.panelStyle`), 대화상자는 `dialogStyle`(`CoreDialogStyle`), 오전 · 오후 선택은 `amPmToggleStyle`(`CoreToggleGroupStyle`), 취소 · 저장 버튼은 `actionButtonStyle`(`CoreButtonStyle`)입니다. 숫자 칸의 `segmentInputStyle`(`CoreTextFieldStyle`)은 `borderColor` 와 `valueStyle` 만 읽습니다. 대화상자의 제목은 `dialogTitle` 에 위젯을 넣어 바꿉니다.

<a id="사용-예-flutter"></a>
<a id="theme-오버라이드"></a>

<Split>

<Code language="dart" title="TimePicker 하나만 바꾸기">
TimePicker(
  value: meetingTime,
  onChanged: setMeetingTime,
  timePickerStyle: CoreTimePickerStyle(
    popoverStyle: CorePopoverStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
      placementOffset: CoreSpace.space8,
    ),
    triggerStyle: CoreTextFieldStyle(
      borderColor: CoreColor.token(CoreColors.outline),
    ),
    segmentSurfaceColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    timePicker: CoreTimePickerTheme(
      style: CoreTimePickerStyle(
        triggerHeight: CoreSize.size48,
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `TimePicker` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `timePickerStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TimePickerChainExample extends StatefulWidget {
  const TimePickerChainExample({super.key});

  @override
  State<TimePickerChainExample> createState() => _TimePickerChainExampleState();
}

class _TimePickerChainExampleState extends State<TimePickerChainExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child:
          TimePicker(
            value: _value,
            placeholder: '시간을 선택해 주세요',
            onChanged: (value) => setState(() => _value = value),
          ).withStyle(
            const CoreTimePickerStyle(
              segmentBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
              segmentBorderColor: CoreColor.token(CoreColors.primary),
              contentColor: CoreColor.token(CoreColors.primary),
              triggerHeight: CoreSpace.space48,
              triggerBorderWidth: CoreStrokeWidth.stroke2,
              trailingIconStyle: CoreIconStyle(
                size: CoreIconSize.size20,
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TimePickerChainExample extends StatefulComponent {
  const TimePickerChainExample({super.key});

  @override
  State<TimePickerChainExample> createState() => _TimePickerChainExampleState();
}

class _TimePickerChainExampleState extends State<TimePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          onChanged: (value) => setState(() => _value = value),
        ).withStyle(
          const CoreTimePickerStyle(
            segmentBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            segmentBorderColor: CoreColor.token(CoreColors.primary),
            contentColor: CoreColor.token(CoreColors.primary),
            triggerHeight: CoreSpace.space48,
            triggerBorderWidth: CoreStrokeWidth.stroke2,
            trailingIconStyle: CoreIconStyle(
              size: CoreIconSize.size20,
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

위 예제의 `triggerBorderWidth` 는 패널의 숫자 칸 테두리에만 닿습니다. 트리거의 테두리 굵기는 `triggerStyle.borderWidth` 로 바꿉니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (CoreTimePickerStyle.default*)
  → CoreComponentTheme.timePicker.style   // 앱 전체
  → timePickerStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. 안에 그리는 TextField · Popover · Dialog · ToggleGroup · Button 은 각자 자기 기본값과 테마를 먼저 받고, 그 위에 TimePicker 가 정한 값과 `timePickerStyle` 의 부품 스타일이 얹힙니다. 그래서 TimePicker 가 직접 정하는 값(트리거의 눌림 채움, 값 · 안내 글자와 오류 테두리의 색, 팝오버 안쪽 여백 16, 오전 · 오후 트랙 색)은 `CoreTextFieldTheme` · `CorePopoverTheme` · `CoreToggleGroupTheme` 으로 바뀌지 않으므로 `timePickerStyle` 로 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | TimePicker 가 역할을 더하지 않습니다. | 역할 없는 `<div>` |
| 트리거 | 읽기 전용 텍스트 필드. 팝오버 모드에서는 `Popover` 가 열림 상태(`expanded`)를 알립니다. | 읽기 전용 `<input>`. 팝오버 모드에서는 감싸는 `<div>` 에 `aria-haspopup="dialog"` · `aria-expanded` 가 붙습니다(dialog 모드에는 없습니다). |
| 패널 | 패널 내용이 `dialog` 역할과 로케일의 패널 이름(`ko` 는 "시간 선택 팝오버")을 가집니다. dialog 모드에서는 Dialog 판도 `dialog` 역할이고, `dialogTitle` 이 화면에 들어올 때 읽는 이름입니다. | 패널 내용 `<div>` 에 `role="dialog"` 와 같은 이름의 `aria-label`. 팝오버 모드에서는 팝오버 판에도 `role="dialog"` 가 있고, dialog 모드의 Dialog 판은 `role="dialog"` + `aria-modal="true"` 입니다. `dialogTitle` 을 주면 그 제목이 Dialog 판의 이름이 됩니다(`aria-labelledby`). |
| 시 · 분 · 초 칸 | 이름 없는 텍스트 필드(숫자만 두 자리). 아래의 칸 이름은 따로 읽히는 글자입니다. | `<input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="2" autocomplete="off">` + 로케일의 시 · 분 · 초 `aria-label` |
| 오전 · 오후 | ToggleGroup — 칸마다 선택 여부(`checked`)와 하나만 고른다는 것을 알립니다. | 이름 없는 `role="radiogroup"` 안의 `role="radio"` + `aria-checked` |
| 취소 · 저장 | 글자 라벨이 있는 Button | 글자 라벨이 있는 `<button>` |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 패널 안에서는 시 → 분 → 초 → 오전 · 오후 → 취소 → 저장 순서입니다. 트리거에서 `Tab` 을 눌러도 팝오버 패널로 바로 들어가지 않습니다. 오전 · 오후는 Web 에서 정지점이 하나, Flutter 에서는 칸마다 하나입니다. |
| 숫자 | 칸에 두 자리까지 입력합니다. 시와 초는 이것으로만 바꿉니다. |
| `↑` · `↓` | 분 칸에서 `minuteInterval` 의 다음 · 이전 배수로 옮깁니다. |
| 방향키 · `Home` · `End` | Web 의 오전 · 오후 선택에서 고른 칸을 옮깁니다. |
| `Enter` · `Space` | 오전 · 오후, 취소, 저장을 누릅니다. 닫힌 트리거는 열리지 않고, 숫자 칸에서 `Enter` 를 눌러도 저장되지 않습니다. |
| `Escape` | Web 은 두 모드에서 닫습니다. Flutter 는 dialog 모드에서만 닫습니다. |

TimePicker 는 `PageUp` · `PageDown` 을 따로 처리하지 않습니다.

### 스크린 리더

- 트리거의 이름을 받는 속성이 없습니다. 고른 시각은 입력의 값으로 읽히고, Web 은 값이 없을 때 안내 글자가 이름 노릇을 합니다. 화면에 [FormLabel](/components/form-label) 을 두어도 입력과 연결되지 않습니다.
- 이름이 필요하면 `label` 을 준 [FormField](/components/form-field) 로 감쌉니다. 라벨은 둘러싼 묶음의 이름이 됩니다(Flutter 는 라벨을 단 `Semantics`, Web 은 `role="group"` 의 `aria-labelledby`). 입력 자체의 이름은 아닙니다.
- 패널은 두 모드 모두 로케일의 패널 이름을 가집니다.
- 숫자 칸의 이름은 Web 에만 있습니다.
- 오전 · 오후의 선택 상태는 색뿐 아니라 선택 여부로도 알립니다.
- 오류일 때 Web 의 트리거 입력에는 `aria-invalid` 가 붙지만 오류 문구는 입력과 연결되지 않습니다. Flutter 의 트리거 입력은 오류 상태를 알리지 않습니다.
- 칸의 값이 바뀌어도 TimePicker 가 따로 알리지 않습니다.

### 포커스 관리

| 때 | Flutter | Jaspr Web |
| --- | --- | --- |
| 팝오버를 열 때 | 포커스는 트리거에 남습니다. | 포커스는 트리거에 남습니다. |
| 대화상자를 열 때 | 대화상자 라우트가 자기 포커스 범위를 만듭니다. | 포커스를 옮기지 않습니다. 뒤의 앱 화면은 `inert` 가 되어 다음 `Tab` 이 대화상자 안으로 들어갑니다. |
| 닫을 때 | TimePicker 는 포커스를 옮기지 않습니다. 대화상자는 닫히면 열기 전의 포커스 범위로 돌아갑니다. | TimePicker 는 포커스를 옮기지 않고, 대화상자를 닫아도 트리거로 되돌리지 않습니다. |
| 포커스 가두기 | 팝오버는 포커스가 패널 안에 들어가면 `Tab` 이 그 안에서 돕니다. 대화상자도 안에서 돕니다. | 팝오버에는 없습니다. 패널은 오버레이 층에 그려져 문서 순서로는 트리거 다음이 아닙니다. 대화상자가 열려 있으면 `Tab` 이 뒤의 앱 화면으로 가지 않습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드로 패널을 열 수 없습니다. 트리거에서 `Enter` · `Space` 를 눌러도 열리지 않습니다. |
| 공통 | 팝오버를 열어도 포커스가 패널로 옮겨 가지 않습니다. 닫을 때도 TimePicker 는 포커스를 트리거로 옮기지 않습니다. |
| 공통 | 트리거의 이름을 받는 속성이 없습니다. Web 의 `attributes` 는 바깥 `<div>` 에 붙어 입력에 닿지 않습니다. |
| 공통 | `min` · `max` 를 강제하지 않습니다. 범위는 `onChanged` 에서 확인합니다. |
| 공통 | 시 · 초는 방향키로 바꿀 수 없습니다. 분 칸도 스핀버튼 역할이나 값 범위를 알리지 않아, 방향키로 바뀐 값이 보조 기술에 따로 전달되지 않습니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onChanged` 로 받아 직접 들고 있어야 합니다. |
| 공통 | 12시간 형식의 트리거는 로케일과 무관하게 `AM` · `PM` 을 붙입니다. |
| Flutter | 시 · 분 · 초 입력이 이름 없이 읽힙니다. TimePicker 안의 입력이라 앱에서 이름을 줄 방법이 없습니다. |
| Flutter | dialog 모드에서 `dialogStyle` 의 `barrierColor` · `barrierOpacity` · `transitionDuration` · `routePadding` 이 적용되지 않습니다. |
| Jaspr Web | 저장하지 않고 닫아도 칸에 친 값이 남습니다. 다시 열어 저장하면 그 값이 저장됩니다. 칸은 `value` 가 바뀌어야 다시 계산합니다. |
| Jaspr Web | `use24HourFormat` 만 바꾸면 칸을 다시 계산하지 않습니다. |
| Jaspr Web | `Fieldset(enabled: false)` 안에서 트리거는 비활성처럼 보이지만, 팝오버 모드는 누르면 열리고 저장하면 `onChanged` 를 부릅니다. TimePicker 에도 `enabled: false` 를 줍니다. |

#### 누르는 크기

트리거는 높이 40 으로 WCAG 2.2 AA 의 최소 누르는 크기(24 × 24)보다 큽니다. 색 대비 · 동작 줄이기 같은 공통 기준은 [전역 접근성 축](/accessibility)을 참고하세요.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자 속성의 이름과 뜻은 같고, 아래는 두 플랫폼이 다르게 동작하는 곳입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `use24HourFormat` 을 비웠을 때 | `MediaQuery.alwaysUse24HourFormatOf` | 브라우저 언어의 시간 형식. 서버 렌더는 24시간 |
| 저장하지 않고 닫은 뒤 다시 열기 | `value` 에서 다시 시작 | 닫기 전에 친 값이 남음 |
| 패널을 연 채 `value` 가 바뀔 때 | 칸은 그대로 | 칸이 새 값으로 바뀜 |
| `Escape` | dialog 모드에서만 닫힘 | 두 모드에서 닫힘 |
| 팝오버를 여는 누름 영역 | 트리거 입력 | 트리거와 그 아래 오류 문구까지 |
| 비활성 `Fieldset` 안 | 열리지 않음 | 팝오버 모드는 열리고 저장됨 |
| 오전 · 오후의 `Tab` 정지점 | 칸마다 하나 | 하나(방향키로 옮김) |
| 숫자 칸의 이름 | 없음 | `aria-label` |
| 숫자 칸에서 눌러 포커스하는 곳 | 칸 가운데에 놓인 한 줄 입력(`TextField` `md`, 기본 최소 높이 40)뿐입니다. 그 위 · 아래의 칸 가장자리를 눌러도 포커스가 들어가지 않습니다. | `<input>` 이 칸 전체입니다. |
| dialog 의 배경막 · 전환 · 바깥 여백 | `dialogStyle` 값이 적용되지 않음 | `dialogStyle` 값을 따름 |
| `valueTypography` · `segmentInputStyle.valueStyle` 에 색을 적었을 때 | 칸 상태의 색(`segmentContentColor` · `segmentFocusedContentColor`)이 우선 | 적은 색이 우선 |
| 숫자 칸의 글자 크기 | 기본 숫자는 CoUI 의 28 로 정해진 크기라 화면 폭의 글자 단계나 앱 타이포의 `headlineMedium` 크기를 따르지 않습니다. 같은 줄을 감싼 `TypographyTierScope(tier: desktop)` 가 데스크톱 크기로 지키는 것은 `:` 와, `valueTypography` · `segmentInputStyle.valueStyle` 에 타이포 역할(`CoreTextStyle.token(CoreTextStyles.headlineMedium)`)을 적은 숫자입니다. | 같은 자리를 상자를 만들지 않는 `<div data-coui-typography-tier="desktop">` 로 감쌉니다. 숫자는 앱 타이포의 `headlineMedium` 크기를 따릅니다. 칸 줄이 이 `<div>` 안에 있으므로, CSS 로 칸 줄을 고를 때는 직계 자식이 아니라 후손 선택자를 씁니다. |
| `dialogTitle` | `Widget` | `Component` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등(바깥 `<div>` 에 붙음) |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. 타입이 다른 곳은 괄호에 적었습니다.

### 값과 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `String?` | `null` | 24시간 `HH:MM` 또는 `HH:MM:SS` 값 |
| `onChanged` | `ValueChanged<String>?` (Web `CoreValueChanged<String>?`) | `null` | 저장할 때 24시간 문자열을 받습니다. |
| `placeholder` | `String?` | `null` | 값이 없을 때의 트리거 글자. 비우면 아래 두 속성으로 `--:--` 모양을 만듭니다. |
| `placeholderSegment` | `String` | `'--'` | 안내 글자의 시 · 분 · 초 자리 |
| `placeholderSeparator` | `String` | `':'` | 안내 글자의 자리 사이. 패널의 `:` 는 바뀌지 않습니다. |
| `errorText` | `String?` | `null` | 비어 있지 않으면 오류 상태. `enabled: false` 면 그리지 않습니다. `Fieldset` 으로만 비활성이면 문구는 남습니다. |

### 시간 형식과 범위

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `showSeconds` | `bool` | `false` | 초 칸을 더합니다. 저장하는 값이 `HH:MM:SS` 가 됩니다. |
| `use24HourFormat` | `bool?` | `null` | 비우면 플랫폼 설정을 따릅니다. |
| `minuteInterval` | `int` | `1` | 분 칸의 간격. 60 의 약수(1 · 2 · 3 · 4 · 5 · 6 · 10 · 12 · 15 · 20 · 30 · 60)만 받고, 그 밖의 값은 assert 를 켠 실행에서 거부됩니다. |
| `min` | `String?` | `null` | 가장 이른 시각. 받기만 하고 패널이 읽지 않습니다. |
| `max` | `String?` | `null` | 가장 늦은 시각. 받기만 하고 패널이 읽지 않습니다. |

### 여는 방식과 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `mode` | `CorePromptMode?` | `null` | `popover`(비웠을 때) 또는 `dialog` |
| `popoverPlacement` | `CorePopoverPlacement` | `bottomStart` | 팝오버가 열리는 자리 |
| `dialogTitle` | `Widget?` (Web `Component?`) | `null` | dialog 모드의 제목 |
| `enabled` | `bool` | `true` | false 면 비활성. `onChanged` 유무와 상관없습니다. |
| `timePickerStyle` | `CoreTimePickerStyle?` | `null` | 보이는 값 덮어쓰기 |

Web 은 이 밖에 `id` · `classes` · `css` · `attributes` 와 HTML 이벤트를 받아 바깥 `<div>` 에 붙입니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTimePickerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `popoverStyle` | `CorePopoverStyle?` | Popover style for the popover-mode picker — the look of its dropdown (its trigger part is not read; see [triggerStyle]). |
| `dialogStyle` | `CoreDialogStyle?` | Dialog style for the modal-mode picker — the look of its panel, title and action buttons. |
| `segmentInputStyle` | `CoreTextFieldStyle?` | Style applied to each hour / minute / second segment input (TextField inside the picker panel). |
| `amPmButtonStyle` | `CoreButtonStyle?` | **Deprecated (since 0.174)** — Use amPmToggleStyle — am/pm is a ToggleGroup. Style applied to the am/pm toggle button when `use24HourFormat: false`. `null` leaves the button at its variant's look. |
| `amPmSelectedButtonStyle` | `CoreButtonStyle?` | **Deprecated (since 0.174)** — Use amPmToggleStyle — am/pm is a ToggleGroup. Style applied to the *selected* am/pm toggle button, layered on top of [amPmButtonStyle]. The default carries a transparent border matching the unselected outline button's stroke, so the selected (borderless `primary`) button occupies the same layout footprint and the toggle never resizes when selection moves. |
| `amPmToggleStyle` | `CoreToggleGroupStyle?` | Style of the am/pm `ToggleGroup` shown in the panel when `use24HourFormat: false` — the shared grouped toggle (a track with a raised chosen face), merged over [defaultAmPmToggleStyle] and passed to `ToggleGroup(toggleGroupStyle: …)` as is. |
| `triggerStyle` | `CoreTextFieldStyle?` | Look of the trigger — the read-only `TextField` the picker shows. Laid over [defaultTriggerStyle] and passed to the field as is. The value colour ([contentColor]) and placeholder tone sit under it, so this style wins over them. The clock glyph is styled by [trailingIconStyle] alone. An explicit `popoverStyle.triggerStyle` styled the earlier button trigger and is not read. |
| `actionButtonStyle` | `CoreButtonStyle?` | Style merged into the Cancel / Save action buttons of the popover / dialog panel — single shared slot, mirroring `CoreDialogStyle.actionButtonStyle`. |
| `labelStyle` | `CoreTextStyle?` | Label text style (text shown above the trigger). |
| `descriptionStyle` | `CoreTextStyle?` | Description / helper text style. |
| `errorStyle` | `CoreTextStyle?` | Error text style. |
| `segmentBorderColor` | `CoreColor?` | Custom segment input border colour. Falls back to [defaultSegmentBorderColor] when null. |
| `segmentHoverBorderColor` | `CoreColor?` | **Deprecated (since 0.175)** — Not read — a hovered segment wears a state layer. Not read — a hovered segment wears a state layer, not a border step. Use [segmentStateLayerColor] / [segmentStateLayer]. |
| `segmentStateLayerColor` | `CoreColor?` | Custom colour of the state layer laid over a segment tile while the pointer is over it. Falls back to [defaultSegmentStateLayerColor] when null. The layer covers the tile's own shape (size and corner) over whichever face it wears and changes neither the face colour nor the border. |
| `segmentStateLayer` | `CoreStateLayer?` | Custom weights of the segment tile's state layer (only `hover` is read). Falls back to [defaultSegmentStateLayer] when null. |
| `segmentSurfaceColor` | `CoreColor?` | Custom segment input fill / surface colour. Falls back to [defaultSegmentSurfaceColor] when null. |
| `segmentContentColor` | `CoreColor?` | Custom segment input content text colour. Falls back to [defaultSegmentContentColor] when null. |
| `segmentFocusOutlineStyle` | `CoreFocusOutlineStyle?` | **Deprecated (since 0.174)** — Not read — the edited segment takes an inside border, not a ring; use segmentFocusedBorderColor / segmentFocusedBorderWidth. Segment focus ring override. `null` defers to [defaultSegmentFocusOutlineStyle], and a field left null inside it defers to `CoreFocusOutlineStyle`'s own default. |
| `labelColor` | `CoreColor?` | Custom segment label / description text colour. Falls back to [defaultLabelColor] when null. |
| `contentColor` | `CoreColor?` | Custom trigger content text colour. Falls back to [defaultContentColor] when null. The segment separator has its own [separatorColor]. |
| `valueTypography` | `CoreTextStyle?` | Custom trigger value / segment numeric typography role. Falls back to [defaultValueTypography] when null. |
| `helperTypography` | `CoreTextStyle?` | Custom helper / segment-label typography role. Falls back to [defaultHelperTypography] when null. |
| `segmentBorderRadius` | `CoreBorderRadius?` | Custom segment input border radius (pre-scaling). |
| `triggerHeight` | `double?` | Custom trigger height (pre-scaling) — forwarded as the trigger field's `height`. `null` → the field's own `md` row (40). |
| `triggerBorderWidth` | `double?` | Custom trigger / segment border width (pre-scaling). |
| `triggerContentGapStyle` | `CoreGapStyle?` | **Deprecated (since 0.174)** — Not read — the field owns the gap. Style of the gap between the trigger text and the trailing icon, for the earlier `Button` trigger (its `iconLabelGapStyle`), merged on top of [defaultTriggerContentGapStyle]. |
| `segmentSize` | `double?` | Custom width of each numeric segment field (pre-scaling). Falls back to [defaultSegmentSize] when null. |
| `segmentHeight` | `double?` | Custom height of each numeric segment field (pre-scaling). The AM/PM column beside it keeps the ToggleGroup's own height. Falls back to [defaultSegmentHeight] when null. |
| `segmentFocusedSurfaceColor` | `CoreColor?` | Custom fill of the segment being edited. Falls back to [defaultSegmentFocusedSurfaceColor] when null. |
| `segmentFocusedContentColor` | `CoreColor?` | Custom text colour of the segment being edited. Falls back to [defaultSegmentFocusedContentColor] when null. |
| `segmentFocusedBorderColor` | `CoreColor?` | Custom border colour of the segment being edited (drawn inside the tile). Falls back to [defaultSegmentFocusedBorderColor] when null. |
| `segmentFocusedBorderWidth` | `double?` | Custom width of the edited segment's inside border (pre-scaling, treated like the resting [triggerBorderWidth] stroke). Falls back to [defaultSegmentFocusedBorderWidth] when null. |
| `dialogLabelSpacing` | `double?` | Uniform spacing between the segment field and its label (Flutter `Column.spacing` / Web inline `margin-top`). Falls back to [defaultDialogLabelSpacing] when null. |
| `dialogOuterGapStyle` | `CoreGapStyle?` | Style of the horizontal `Gap` between the segment row and the AM/PM column. Merged on top of [defaultDialogOuterGapStyle]. |
| `actionRowGapStyle` | `CoreGapStyle?` | Style of the vertical `Gap` between the segment row and the action button row (also used between the optional title and the segment row). Merged on top of [defaultActionRowGapStyle]. |
| `separatorPadding` | `CoreEdgeInsets?` | Custom padding around the segment separator glyph (pre-scaling). |
| `separatorTypography` | `CoreTextStyle?` | Custom segment separator (`:`) typography. Falls back to [defaultSeparatorTypography] when null. |
| `separatorColor` | `CoreColor?` | Custom segment separator (`:`) colour. Falls back to [defaultSeparatorColor] when null. |
| `trailingIconStyle` | `CoreIconStyle?` | Trigger trailing (clock) icon style override. `null` → [defaultTrailingIconStyle]. |
| `errorTriggerStyle` | `CoreButtonStyle?` | **Deprecated (since 0.174)** — Use triggerStyle.errorBorderColor. Trigger border colour while the picker holds an error (the rest of the button bundle is not read — the trigger is a `TextField`, whose error look is its own). Merged on top of [defaultErrorTriggerStyle] and folded in as the field's `errorBorderColor`; `triggerStyle` outranks it. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명 가운데 지금 동작과 다른 곳이 있습니다.

- `labelStyle` · `descriptionStyle` · `errorStyle` 은 화면에 쓰이지 않습니다. 오류 문구의 글자는 `triggerStyle.errorStyle` 로 바꿉니다.
- `valueTypography` 는 패널의 숫자 칸에만, `triggerBorderWidth` 는 숫자 칸 테두리에만 닿습니다. 트리거는 `triggerStyle.valueStyle` · `triggerStyle.borderWidth` 로 바꿉니다.
- `segmentInputStyle` 은 `borderColor` 와 `valueStyle` 만 읽습니다.
- `amPmButtonStyle` · `amPmSelectedButtonStyle` 은 읽지 않습니다. `amPmToggleStyle` 을 씁니다.
- `dialogStyle.actionButtonStyle` 은 취소 · 저장 버튼에 닿지 않습니다. `actionButtonStyle` 을 씁니다. Flutter 의 dialog 모드는 `dialogStyle` 의 배경막 · 전환 · 바깥 여백 값도 적용하지 않습니다.
- `actionRowGapStyle` 은 제목과 숫자 칸 사이에는 쓰이지 않습니다.
- `separatorPadding` 의 왼쪽 값은 취소와 저장 사이의 간격으로도 쓰입니다.
- `valueTypography` · `segmentInputStyle.valueStyle` 에 색을 적으면 Web 은 그 색이, Flutter 는 칸 상태의 색이 우선합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="time-picker/related-date-picker" title="DatePicker">

날짜를 고릅니다. 날짜와 시각이 모두 필요하면 TimePicker 와 함께 둡니다.

</Card>
<Card component="text-field" props="placeholder=직접 입력" title="TextField">

시각을 자유 형식 글자로 받습니다.

</Card>
<Card demo="time-picker/related-select" title="Select">

정해진 시각 가운데 하나를 고르게 합니다.

</Card>
</Cards>
