---
title: DatePicker
description: 날짜 선택 컴포넌트
category: form
platforms: [flutter, web]
related: [calendar, text-field]
tags: [form-control, date, picker]
template: v2
source: form/date_picker
---

# DatePicker

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 DatePicker 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="date-picker" />

DatePicker 는 읽기 전용 [TextField](/components/text-field) 트리거를 보여 주고, 누르면 [Calendar](/components/calendar) 를 [Popover](/components/popover) 나 [Dialog](/components/dialog) 에 열어 날짜를 고르게 합니다. 날짜 하나는 `DatePicker`, 시작과 끝은 `DateRangePicker` 로 받습니다. 플레이그라운드의 "기간 선택" 은 속성이 아니라, 두 위젯 가운데 어느 것을 그릴지 바꾸는 손잡이입니다.

날짜 값의 타입은 Flutter 가 `DateTime`, Jaspr Web 이 `YYYY-MM-DD` 문자열입니다. 코드의 `selectedDate` · `setDate` 는 앱이 들고 있는 상태입니다. Flutter 의 `DatePicker` 는 넘긴 `value` 만 보여 주므로, `onChanged` 에서 상태를 바꿔 다시 넘깁니다. `onChanged` 를 주지 않으면 Flutter 에서는 `enabled: true` 여도 비활성입니다. Web 의 `DatePicker` 는 고른 값을 스스로 보여 주고, 넘긴 `value` 가 바뀌면 그 값을 따릅니다.

<Note>

이 문서의 Jaspr Web 미리보기 가운데 눌러서 열 수 있는 것은 플레이그라운드뿐입니다. Flutter 미리보기에서 연 패널은 미리보기 상자 안에 열립니다.

</Note>

## 구조

DatePicker 는 라벨, 트리거, 달력 아이콘, 도움말로 이루어지고, 트리거를 누르면 달력이 열립니다.

<Anatomy demo="date-picker/anatomy">
<AnatomyItem part="label" side="left" name="label">

트리거 위의 필드 라벨.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="trigger">

읽기 전용 TextField 의 `md` 모양(높이 40, 모서리 10, `outlineVariant` 테두리, 값 글자 `bodyMedium` 14 Regular)입니다. 부모의 가로 폭을 채웁니다. 값이 없으면 안내 문구를, 있으면 고른 날짜를 `YYYY-MM-DD` 로 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="svg" side="right" name="icon">

트리거 오른쪽의 달력 아이콘. `DateRangePicker` 는 범위 달력 아이콘을 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=picker] div + div + div + div:last-child" side="left" name="description">

트리거 아래 도움말. `errorText` 가 있으면 그 문구로 바뀝니다.

</AnatomyItem>
</Anatomy>

값이 없는 모양과 있는 모양은 같은 트리거이고, `value` 가 있는지가 정합니다. Figma 의 `Show value` · `Value` 는 이 두 모양을 고르는 캔버스 속성이며 코드 속성이 아닙니다. 날짜 글자의 형식은 `YYYY-MM-DD` 이고 형식을 고르는 속성은 없습니다. 범위는 `시작 - 끝` 으로 보여 주며, Flutter 의 `DateRangePicker` 만 `builder` 로 이 글자를 직접 그릴 수 있습니다.

<a id="표시-모드-flutter"></a>
<a id="기본-single-popover"></a>
<a id="단일-다이얼로그-모드"></a>

## 표시 모드

`mode`(`CorePromptMode`)가 달력을 어디에 열지 정합니다. `DatePicker` 의 기본은 `popover`, `DateRangePicker` 의 기본은 `dialog` 입니다. 화면 크기에 따라 모드를 스스로 바꾸지 않습니다.

<Note>

이 페이지에서 달력이 펼쳐진 그림은 실제 `Calendar` 로 그린 것이고, 열고 닫는 동작은 없습니다. 팝오버의 판은 킷의 `Popup` 입니다. 그림은 DatePicker 의 스타일을 읽지 않으므로, `datePickerStyle` 이나 `CoreComponentTheme.datePicker`(그 안의 `calendarStyle` · `popoverStyle` · `dialogStyle` 포함), `CoreComponentTheme.popover` 로 바꾼 값은 그림에 보이지 않습니다. 대화상자 그림의 틀은 Jaspr Web 에서는 대화상자의 기본값으로 그리므로 `CoreComponentTheme.dialog` 로 바꾼 값도 보이지 않습니다. 실제 패널은 플레이그라운드에서 열 수 있습니다.

</Note>

### 팝오버

트리거 옆에 달력을 띄우고 화면을 막지 않습니다. 날짜를 고르면 바로 알리고 닫습니다.

<Preview demo="date-picker/popover-calendar" />

```dart
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  popoverPlacement: CorePopoverPlacement.bottomStart,
)
```

### 다이얼로그

화면 가운데 대화상자에 달력을 보이고 "취소" · "저장" 버튼으로 확정합니다. `dialogTitle` 은 대화상자의 제목입니다.

<Preview demo="date-picker/dialog-panel" />

```dart
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  mode: CorePromptMode.dialog,
  dialogTitle: Text('날짜 선택'),
)
```

<a id="범위-팝오버-모드"></a>
<a id="범위-다이얼로그-모드-daterangepicker-기본"></a>
<a id="날짜-범위-선택-flutter"></a>
<a id="범위-선택-flutter"></a>

## 날짜 범위

`DateRangePicker` 는 시작과 끝을 한 번에 고릅니다. 달력은 두 달을 나란히 보여 줍니다. 값은 Flutter 가 `DateTimeRange(시작, 끝)`, Jaspr Web 이 `(start: 'YYYY-MM-DD', end: 'YYYY-MM-DD')` 레코드입니다. Flutter 의 `DateTimeRange` 는 CoUI 의 클래스이며, 이름 없이 시작과 끝을 차례로 받습니다.

<Preview demo="date-picker/range-calendar" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
DateRangePicker(
  value: selectedRange, // DateTimeRange(checkIn, checkOut)
  onChanged: setRange,
  placeholder: Text('기간을 선택해 주세요'),
  dialogTitle: Text('기간 선택'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
DateRangePicker(
  value: selectedRange, // (start: '2026-12-24', end: '2026-12-27')
  onChanged: setRange,
  mode: CorePromptMode.popover,
  placeholder: const Text('기간을 선택해 주세요'),
)
```

  </TabItem>
</Tabs>

Flutter 의 `DateRangePicker` 는 `builder` 로 고른 범위를 보여 주는 글자를 직접 그릴 수 있습니다. `builder` 가 돌려준 위젯은 입력 필드의 값 글자가 될 수 없어 안내 문구 자리에 놓이고, 사용할 수 있는 상태에서는 값과 같은 색을 입습니다.

```dart
DateRangePicker(
  value: selectedRange,
  onChanged: setRange,
  builder: (context, range) =>
      Text('${range.end.difference(range.start).inDays}박'),
)
```

<a id="변형-variants"></a>
<a id="동작-스펙-behavior"></a>

## 상태

트리거는 TextField 의 상태 모양을 따르고, 눌렀을 때 덮는 채움만 DatePicker 가 더합니다.

<Preview demo="date-picker/states" />

| 항목 | 동작 |
| --- | --- |
| 값 없음 | 안내 문구를 `placeholder` 색으로 보여 줍니다. `placeholder` 를 주지 않으면 로케일의 기본 문구를 씁니다. |
| 값 있음 | 날짜를 `onSurface` 색으로 보여 줍니다. 달력 아이콘은 `onSurfaceVariant` 입니다. |
| Hover | 테두리가 `outline` 으로 한 단 진해집니다. |
| 눌림 | 채움 위에 `onSurface` 12% 를 덮습니다. |
| Focus | 테두리가 `primary` 로 바뀝니다. 키보드로 포커스했을 때만 바깥에 링을 그립니다. |
| 오류 | `errorText` 가 있으면 테두리와 포커스 링이 `error` 가 되고, 글자색과 배경은 그대로입니다. 도움말 자리에 오류 문구를 `error` 색으로 그립니다. `errorText` 는 값을 검증하지 않고 표시만 바꿉니다. 쉬는 상태의 오류 테두리색은 `triggerStyle` 의 `errorBorderColor` 로 바꿉니다. `errorTriggerStyle` 의 `borderColor` 도 아직 읽지만 폐기 예정입니다. |
| 비활성 | 테두리 `disabledOutline`, 채움 `disabledContainer`, 값 `disabledContent` 입니다. 오류가 있어도 트리거는 비활성 모양이고, 오류 문구는 비활성 색으로 남습니다. Flutter 에서 비활성이거나 Web 에서 `enabled: false` 면 눌러도 열리지 않습니다. |
| 비활성이 되는 때 | Flutter 는 `enabled: false` 이거나 `onChanged` 가 없을 때, 그리고 비활성 [Fieldset](/components/fieldset) 안에서 비활성입니다. Web 의 열기 동작은 `enabled` 로만 정합니다. |
| 전환 시간 | Flutter 는 트리거의 테두리 · 채움이 바로 바뀌고, 포커스 링만 150ms 동안 나타납니다. Jaspr Web 의 트리거 색은 앱의 테마 전환 애니메이션(`CoUIWeb` 의 `enableThemeAnimation`, 기본 켜짐)을 따라 150ms 동안 바뀝니다. 팝오버는 두 플랫폼 모두 150ms 동안 열리고 100ms 동안 닫힙니다. |

### 고른 값이 전달되는 때

| 모드 | 날짜 하나 (`DatePicker`) | 범위 (`DateRangePicker`) |
| --- | --- | --- |
| 팝오버 | 고르면 바로 `onChanged` 를 부르고, 150ms 동안 고른 표시를 보인 뒤 닫습니다. 고른 날짜를 다시 누르면 해제되어 `null` 을 알립니다. | 시작만 고른 때에는 알리지 않습니다. 끝까지 고르면 범위를 알리고 닫습니다. 시작 날짜를 다시 누르면 해제되어 `null` 을 알리고 닫습니다. |
| 다이얼로그 | "저장" 을 눌러야 알립니다. "취소", 바깥 누르기, `Escape`(Flutter 는 뒤로 가기도)는 고른 것을 버립니다. | 날짜 하나와 같습니다. |

다이얼로그에서 고른 날짜를 해제한 채 저장하거나, 범위의 시작만 고른 채 저장할 때의 결과는 두 플랫폼이 다릅니다. [플랫폼 차이](/components/date-picker#플랫폼-차이)를 보세요. 달력에서 고른 범위는 언제나 시작이 끝보다 늦지 않습니다. 팝오버 대기 시간 150ms 는 `CoreDatePickerStyle.defaultPopoverDismissDelayMs` 입니다.

<a id="비활성-날짜-지정-flutter"></a>

### 고를 수 있는 날짜 정하기

`min` · `max` 는 날짜 단위로 비교해 범위 밖의 날짜를 고를 수 없게 합니다. 달 · 연도를 고르는 화면에는 적용되지 않습니다. Web 에서는 `YYYY-MM-DD` 문자열로 주고, 날짜로 읽히지 않는 문자열은 주지 않은 것으로 봅니다.

날짜마다 정하려면 `stateBuilder` 를 씁니다. `stateBuilder` 를 주면 `min` · `max` 는 쓰지 않습니다.

<Preview demo="date-picker/weekdays" />

```dart
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  stateBuilder: (date) => date.weekday >= DateTime.saturday
      ? CoreCalendarDateState.disabled
      : CoreCalendarDateState.enabled,
)
```

### 처음 달과 주 시작 요일

- `initialView`(`CoreCalendarView(2026, 12)`)는 달력이 처음 보일 달입니다. 주지 않으면 값이 있는 달, 값도 없으면 이번 달입니다. `DateRangePicker` 에서는 Flutter 만 받습니다.
- `firstDayOfWeek` 는 한 주가 시작하는 요일(`DateTime.monday`…`DateTime.sunday`)이며 두 모드 모두 [Calendar](/components/calendar#한-주의-시작-요일-first-day-of-week) 로 그대로 넘깁니다. 기본값은 일요일이고, 로케일에서 가져오지 않습니다.

<a id="controlled-flutter"></a>
<a id="datepickercontroller-flutter"></a>

### 값을 스스로 드는 `ControlledDatePicker`

Flutter 에만 있는 `ControlledDatePicker` 는 고른 날짜를 안에 들고 있습니다. 처음 값은 `initialValue` 로, 밖에서 바꾸려면 `controller`(`DatePickerController`)로 줍니다. `controller` 의 값이 있으면 `initialValue` 는 쓰지 않습니다. `controller` 의 값이 `null` 이면 처음에는 `initialValue` 가 보이지만 `controller` 의 값은 `null` 로 남으므로, 둘 중 하나만 주세요. `onChanged` 가 없어도 비활성이 되지 않습니다.

```dart
final controller = DatePickerController(DateTime(2026, 12, 24));

ControlledDatePicker(
  controller: controller,
  onChanged: handleDateChanged,
)

// 코드에서 값을 바꿉니다.
controller.value = DateTime(2027, 1, 2);
```

`DatePicker.simple(...)` 은 `ControlledDatePicker` 를 만드는 짧은 길입니다. `placeholder` · `enabled` · `onChanged` · `min` · `max` · `label` · `description` · `errorText` 만 받고, 처음 값은 줄 수 없습니다.

```dart
DatePicker.simple(
  placeholder: '날짜를 선택해 주세요',
  onChanged: handleDateChanged,
)
```

`DatePickerController` 는 `ValueNotifier<DateTime?>` 입니다. 다 쓰면 앱이 `dispose` 합니다. [Form](/components/form) 에 값을 연결하는 기능은 없습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

폼에서 생년월일 · 예약일 같은 날짜를 고르게 할 때, 체크인과 체크아웃처럼 기간을 받을 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 날짜가 아니라 시각을 고를 때 | [TimePicker](/components/time-picker) |
| 달력을 화면에 늘 펼쳐 둘 때 | [Calendar](/components/calendar) |
| 날짜를 글자로 입력받을 때(해석과 검증은 앱이 합니다) | [TextField](/components/text-field) · [FormattedInput](/components/formatted-input) |
| 미리 정해 둔 날짜 몇 개 가운데 하나를 고를 때 | [Select](/components/select) |

<a id="do"></a>
<a id="dont"></a>

### 라벨과 안내 문구

<Cards columns="2">
<Card component="date-picker" props="label=체크인 날짜;placeholder=체크인 날짜를 선택하세요" tone="do" eyebrow="이렇게 하세요">

라벨로 무슨 날짜인지 알리고, 안내 문구로 무엇을 고를지 알려 줍니다.

</Card>
<Card component="date-picker" props="placeholder=YYYY-MM-DD" tone="dont" eyebrow="이렇게 하지 마세요">

트리거에는 글자를 칠 수 없습니다. 입력 형식을 안내 문구로 적으면 직접 쳐야 하는 것처럼 보입니다.

</Card>
<Card component="date-picker" props="range=true;label=투숙 기간;value=2026-12-24;placeholder=기간을 선택해 주세요" tone="do" eyebrow="이렇게 하세요">

기간은 `DateRangePicker` 하나로 받습니다. 시작과 끝이 한 달력에서 이어져 보이고, 순서가 뒤바뀌지 않습니다.

</Card>
<Card demo="date-picker/dont-two-pickers" tone="dont" eyebrow="이렇게 하지 마세요">

`DatePicker` 두 개로 기간을 받으면 시작일이 종료일보다 늦어질 수 있어, 순서를 앱이 따로 맞춰야 합니다.

</Card>
</Cards>

### 고를 수 있는 날짜 좁히기

예약처럼 지난 날짜가 뜻이 없는 입력은 `min` 으로 막습니다. `errorText` 는 검사하지 않으므로, 막아야 하는 날짜는 `min` · `max` · `stateBuilder` 로 고르지 못하게 합니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 권장하지 않음 — 지난 날짜도 예약할 수 있습니다.
DatePicker(value: selectedDate, onChanged: setDate)

// 권장 — 오늘부터만 고를 수 있습니다.
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  min: DateTime.now(),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 권장하지 않음 — 지난 날짜도 예약할 수 있습니다.
DatePicker(value: selectedDate, onChanged: setDate)

// 권장 — 오늘부터만 고를 수 있습니다.
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  min: DateTime.now().toIso8601String().substring(0, 10),
)
```

  </TabItem>
</Tabs>

## 배치

- 트리거는 부모의 가로 폭을 채웁니다. 폭을 줄이려면 부모에 폭을 줍니다.
- Flutter 에서는 가로 폭이 정해지지 않는 `Row` 안에 둘 때 `Expanded` 나 `SizedBox` 로 폭을 줍니다. 폭 없이 글자 너비로 줄어드는 것은 라벨 · 도움말 · 오류가 없고 사용할 수 있는 팝오버 모드뿐입니다. 라벨 · 도움말 · 오류가 있거나, 다이얼로그 모드(`DateRangePicker` 의 기본)이거나, `enabled: false` · `onChanged` 없음으로 비활성이면 폭이 없을 때 레이아웃 오류가 납니다.
- 팝오버는 `popoverPlacement`(기본 `bottomStart`) 자리에서 트리거와 4 떨어져 열립니다. 자리가 모자라면 반대쪽으로 뒤집거나 밀어서 화면 가장자리에서 8 안쪽에 둡니다. 패널 폭은 트리거가 아니라 달력의 폭입니다. 화면이 스크롤되어도 닫히지 않고 트리거를 따라갑니다.
- 다이얼로그는 화면 가운데에 열리고, 폭은 최대 560 입니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **동작과 내용**은 위젯 속성으로 정합니다 — `mode`, `popoverPlacement`, `enabled`, `onChanged`, `min`, `max`, `stateBuilder`, `initialView`, `firstDayOfWeek`, `placeholder`, `label`, `description`, `errorText`, `dialogTitle`.
- **보이는 값**은 `datePickerStyle`(`CoreDatePickerStyle`, 범위는 `dateRangePickerStyle`) 하나로 바꿉니다. 안에 그리는 부품은 그 컴포넌트의 Style 을 그대로 받습니다 — 트리거는 `triggerStyle`(`CoreTextFieldStyle`), 팝오버는 `popoverStyle`(`CorePopoverStyle`), 대화상자는 `dialogStyle`(`CoreDialogStyle`), 달력은 `calendarStyle`(`CoreCalendarStyle`)입니다.
- **내용 바꾸기**는 `dialogTitle`, `placeholderWidget`(날짜 하나), `placeholder`(범위), `builder`(Flutter 범위)에 위젯을 넣습니다.

<Split>

<Code language="dart" title="DatePicker 하나만 바꾸기">
DatePicker(
  value: selectedDate,
  onChanged: setDate,
  datePickerStyle: CoreDatePickerStyle(
    triggerStyle: CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
    popoverStyle: CorePopoverStyle(
      placementOffset: CoreSpace.space8,
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
    calendarStyle: CoreCalendarStyle(
      selectedColor: CoreColor.token(CoreColors.success),
    ),
    labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    datePicker: CoreDatePickerTheme(
      style: CoreDatePickerStyle(
        popoverStyle: CorePopoverStyle(
          placementOffset: CoreSpace.space8,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

`CoreComponentTheme.datePicker` 는 `DateRangePicker` 에도 적용됩니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 인스턴스에 `withStyle` 체인으로 스타일을 덧붙일 수 있습니다. 생성자의 `datePickerStyle`(범위는 `dateRangePickerStyle`)과 같게 동작합니다.

<Note>

Flutter 예제는 값을 스스로 드는 Flutter 전용 `ControlledDatePicker` 로 보여 줍니다. `DatePicker` 에도 같은 `withStyle` 이 있습니다. 다만 Flutter 의 `ControlledDatePicker` 와 `DateRangePicker` 의 `withStyle` 은 `firstDayOfWeek` 를 기본값(일요일)으로 되돌리고, Web 의 `DateRangePicker.withStyle` 은 `firstDayOfWeek` 와 `stateBuilder` 를 버립니다. 이 위젯들에서 그 값을 쓴다면 `withStyle` 대신 생성자 속성으로 스타일을 주세요.

</Note>

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DatePickerChainExample extends StatefulWidget {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child:
          ControlledDatePicker(
            placeholder: '날짜를 선택해 주세요',
            onChanged: (_) {},
          ).withStyle(
            const CoreDatePickerStyle(
              contentColor: CoreColor.token(CoreColors.primary),
              placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
              valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
              trailingIconStyle: CoreIconStyle(
                size: CoreSize.size20,
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
class DatePickerChainExample extends StatefulComponent {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          placeholder: '날짜를 선택해 주세요',
          value: _value,
        ).withStyle(
          const CoreDatePickerStyle(
            contentColor: CoreColor.token(CoreColors.primary),
            placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
            valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
            trailingIconStyle: CoreIconStyle(
              size: CoreSize.size20,
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

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (CoreDatePickerStyle.default*)
  → CoreComponentTheme.datePicker.style        // 앱 전체
  → datePickerStyle (범위: dateRangePickerStyle)  // 인스턴스
```

뒤로 갈수록 우선합니다. 안의 부품은 각자의 테마를 먼저 받고, 그 위에 DatePicker 가 넘기는 값과 `datePickerStyle` 의 부품 스타일이 얹힙니다. 예를 들어 트리거는 TextField 의 `md` 기본값과 `CoreTextFieldTheme` 위에, DatePicker 가 넘기는 값 색 · 안내 문구 색 · 오류 테두리색 · 눌림 채움이 얹히고, 마지막으로 `triggerStyle` 이 얹힙니다. 트리거의 모양은 `triggerStyle` 로 바꿉니다. `popoverStyle.triggerStyle`(`CoreButtonStyle`)은 읽지 않습니다.

<a id="사용-예-flutter"></a>
<a id="옛-평면-필드-새-위치-매핑"></a>

### 옛 필드 → 새 위치 매핑

예전 이름으로 찾는다면 아래 위치를 씁니다.

| 옛 이름 | 새 위치 |
| --- | --- |
| `height` | `triggerStyle.height` |
| `padding` | 트리거는 `triggerStyle.padding`, 팝오버 패널은 `popoverStyle.panelStyle.padding` |
| `borderRadius` | `triggerStyle.borderRadius` |
| 트리거 안의 `gap` | 입력 필드가 정합니다(오른쪽 아이콘 자리) |
| `iconSize` | `trailingIconStyle.size` |
| `popoverPadding` | `popoverStyle.panelStyle.padding` |
| `popoverGap` | `popoverStyle.placementOffset` |

<a id="접근성-accessibility"></a>

## 접근성

트리거는 읽기 전용 입력이고, 달력의 날짜는 하나씩 누를 수 있는 버튼입니다. 키보드만으로는 달력을 열 수 없습니다 — 아래 알려진 제약을 확인하세요.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 바깥 틀 | DatePicker 가 덧붙이는 역할이나 접근성 정보가 없습니다. | 역할 없는 `div`. `errorText` 가 있으면 `aria-invalid="true"`, `enabled: false` 면 `aria-disabled="true"` |
| 트리거 | 읽기 전용 텍스트 필드. 팝오버 모드에서는 열림 여부(`expanded`)를 알립니다. | `input readonly`. 비활성이면 `disabled`, 사용할 수 있는 오류 상태면 `aria-invalid="true"`. 팝오버 모드에서는 트리거를 감싼 `div` 에 `aria-haspopup="dialog"` · `aria-expanded` 가 붙고, 열려 있으면 `aria-controls` 도 붙습니다. |
| 팝오버 패널 | 역할 없음 | `role="dialog"` |
| 대화상자 패널 | 대화상자 역할. `dialogTitle` 이 대화상자의 이름이 됩니다. | `role="dialog"` · `aria-modal="true"`. 제목이 있으면 `aria-labelledby` |
| 달력 | 로케일의 "달력" 문구를 이름으로 가진 영역. 날짜 격자는 표(`table`) · `row` · `cell` · `columnHeader` | 로케일의 "달력" 문구를 `aria-label` 로 가진, 역할 없는 상자. 날짜 격자는 `grid` · `row` · `gridcell` · `columnheader` |
| 날짜 칸 | 버튼(`Button`). 범위 안쪽 칸은 `Clickable` | `Button`. 범위의 시작 · 안쪽 · 끝 칸은 직접 `role="button"` · `tabindex="0"` 을 갖고, 막은 날짜면 `tabindex` 대신 `aria-disabled="true"` 를 갖습니다. |
| `label` · `description` · `errorText` | 트리거와 연결되지 않은 별도 글자 | 트리거와 연결되지 않은 `div` |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` · `Tab` | 트리거에 닿습니다. 포커스가 달력 안에 있을 때는 날짜 하나하나가 따로 멈추는 자리입니다. |
| `Enter` · `Space` | 달력의 날짜와 이전 · 다음 버튼을 누릅니다. **트리거에서는 달력을 열지 않습니다.** |
| `Escape` | 대화상자는 두 플랫폼 모두 닫고 값을 바꾸지 않습니다. 팝오버는 Web 만 닫습니다. |
| `←` `→` `↑` `↓` | 달력에는 날짜를 옮기는 처리가 없습니다. Flutter 는 프레임워크의 기본 방향 이동으로 포커스가 옮겨 갈 수 있지만 달을 넘지 않고, Web 은 아무 일도 하지 않습니다. |
| `Home` · `End` · `PageUp` · `PageDown` | 처리하지 않습니다. 달은 머리 줄의 이전 · 다음 버튼으로 옮깁니다. |

### 스크린 리더

- 트리거는 지금 값(`YYYY-MM-DD`)을 읽습니다. 값이 없으면 안내 문구가 읽힙니다.
- Web 의 입력은 값이 없을 때만 안내 문구(`placeholder`)에서 이름을 얻습니다. `label` 은 입력의 이름이 되지 않습니다.
- 비활성 상태는 두 플랫폼 모두 알립니다. Jaspr Web 은 입력의 `disabled`(`enabled: false` 면 바깥 틀의 `aria-disabled="true"` 도)로, Flutter 는 트리거 TextField 의 비활성 상태로 알립니다.
- 달력의 이전 · 다음 버튼은 로케일의 "이전 기간" · "다음 기간" 으로 읽힙니다.
- 날짜 칸은 날짜 숫자를 읽습니다. 자세한 것은 [Calendar 접근성](/components/calendar#접근성-accessibility)을 보세요.
- 날짜를 골랐다는 알림(라이브 영역)은 따로 없습니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 팝오버를 열 때 | 포커스가 트리거에 남습니다. 달력으로 옮기지 않습니다. | 같습니다. 패널은 오버레이 층에 그려지므로 `Tab` 이 트리거에서 패널로 바로 가지 않습니다. |
| 팝오버를 닫을 때 | DatePicker 가 트리거로 포커스를 되돌리지 않습니다. | 같습니다. |
| 대화상자를 열 때 | 대화상자가 자기 포커스 범위를 세워 포커스가 안으로 들어갑니다. | 포커스를 옮기지 않습니다. 배경은 `inert` 가 됩니다. |
| 대화상자를 닫을 때 | 이전 포커스로 돌아갑니다. | 연 트리거로 되돌리지 않습니다. |
| 가두기 | `Tab` 이 대화상자 안에서 돕니다. 팝오버는 가두지 않습니다. | 배경으로는 나가지 않지만 대화상자 안에서 돌지 않습니다. 팝오버는 가두지 않습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드로는 달력을 열 수 없습니다. 트리거에 `Enter` · `Space` 처리가 없습니다. 키보드 사용자에게는 날짜를 글자로도 입력할 수 있는 길을 함께 주세요. |
| 공통 | 달력 안에서 화살표 · `PageUp` · `PageDown` 으로 날짜를 옮길 수 없습니다. 날짜마다 `Tab` 자리가 있어 한 달을 지나려면 `Tab` 을 여러 번 눌러야 합니다. |
| 공통 | 달력은 고른 날 · 오늘 · 범위 안의 날을 접근성 정보로 알리지 않습니다. |
| 공통 | `label` · `description` · `errorText` 가 트리거의 이름 · 설명에 연결되지 않습니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onChanged` 로 받아 앱이 들고 있어야 합니다. |
| 공통 | 범위 달력은 좁은 화면에서도 두 달을 나란히 둡니다. 휴대폰 폭에서는 자리가 모자라며, Flutter 에서는 넘침이 날 수 있습니다. |
| Flutter | 오류 상태를 접근성 정보로 알리지 않습니다. 오류 문구는 별도의 글자로만 읽힙니다. |
| Flutter | 팝오버는 `Escape` 로 닫히지 않습니다. |
| Flutter | `value` 에 시각이 들어 있으면(`DateTime.now()` 처럼) 달력에서 같은 날짜를 처음 누를 때 해제되지 않고 그날 0시로 다시 고릅니다. |
| Flutter | `ControlledDatePicker` · `DateRangePicker` 의 `withStyle` 은 `firstDayOfWeek` 를 일요일로 되돌립니다. |
| Flutter | `ControlledDatePicker` 에 넘긴 `controller` 를 다른 객체로 바꾸면, 새 `controller` 의 값이 바뀌기 전까지 이전 날짜가 보입니다. |
| Jaspr Web | 값을 고른 뒤에는 입력에 이름이 없습니다. 생성자의 `attributes` 는 바깥 틀에 붙어 입력에 이름을 줄 수 없습니다. |
| Jaspr Web | 대화상자에서 고른 날짜를 해제하고 저장하면, 해제를 알리지 않고 이전 값을 다시 `onChanged` 로 알립니다. 해제한 직후 달력에도 이전 날짜가 다시 표시될 수 있습니다. |
| Jaspr Web | `DateRangePicker` 대화상자에서 시작만 고르고 저장하면 이전 범위(없었으면 `null`)를 다시 알립니다. |
| Jaspr Web | `DateRangePicker` 대화상자에서 범위를 고른 뒤 새 시작 날짜를 누르면, 그 선택이 남지 않고 열 때의 범위(없었으면 빈 상태)로 돌아갑니다. 한 번 더 눌러야 새 시작이 잡힙니다. |
| Jaspr Web | `Text` 가 아닌 `placeholderWidget` 이나 범위 `placeholder` 는 그려지지 않고, `Text` 체인으로 바꾼 글자 모양도 반영되지 않습니다. |
| Jaspr Web | 비활성 `Fieldset` 안에서도 팝오버가 열릴 수 있습니다. 비활성이어야 하면 `enabled: false` 를 직접 주세요. |
| Jaspr Web | `DateRangePicker.withStyle` 은 `stateBuilder` 와 `firstDayOfWeek` 를 버려, 막은 날짜를 다시 고를 수 있게 되고 주 시작이 일요일로 돌아갑니다. |
| Jaspr Web | Dialog 안에서 연 팝오버에서 `Escape` 를 누르면 Dialog 까지 닫힐 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="web-구현"></a>
<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

공통 속성의 이름은 같고, 날짜의 타입과 일부 동작이 다릅니다. 한 플랫폼에만 있는 속성도 있습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 날짜 타입 | `DateTime?`, 범위 `DateTimeRange?` | `String?`(`YYYY-MM-DD`), 범위 `({String start, String end})?` |
| 값 보여 주기 | 넘긴 `value` 만 보여 줍니다. | 고른 값을 스스로 보여 주고, 넘긴 `value` 가 바뀌면 따릅니다. 계속 `null` 을 넘기면 고른 값이 남습니다. |
| 비활성 조건 | `enabled: false`, `onChanged` 없음, 비활성 `Fieldset` | 열기 동작은 `enabled` 로 정합니다. `onChanged` 가 없어도 사용할 수 있습니다. |
| 값을 스스로 드는 위젯 | `ControlledDatePicker` · `DatePickerController` · `DatePicker.simple` | 없습니다. |
| 범위의 `initialView` | 받습니다. | 받지 않습니다. |
| 범위 글자 직접 그리기 | `builder` | 없습니다. |
| 빈 `errorText` | `''` 도 오류 상태입니다. | 빈 문자열은 주지 않은 것과 같습니다. 빈 `label` · `description` 도 그리지 않습니다. |
| 팝오버의 `Escape` | 닫지 않습니다. | 닫습니다. |
| 대화상자 | `showDialog` 로 엽니다. `dialogStyle` 의 바깥 여백 · 배경막 색과 불투명도 · 전환 시간 · 열고 닫을 때의 확대 비율(`scaleAnimationStart` · `scaleAnimationEnd`)은 적용되지 않습니다. | `Dialog` 를 오버레이 층에 그리고, `dialogStyle` 을 그대로 넘깁니다. |
| 대화상자 속 달력 | 머리 줄이 본문 폭을 채우고 날짜 칸은 가운데에 놓입니다. | 달력이 제 폭으로 가운데에 놓입니다. |
| 해제한 채 저장 | `null` 을 알립니다. 범위에서 시작만 고른 채 저장하면 시작과 끝이 같은 하루짜리 범위를 알립니다. | 이전 값을 다시 알립니다. |
| 팝오버 층 | 앵커 오버레이 | 오버레이 호스트의 팝오버 층에 그리므로 조상의 `overflow: hidden` · `transform` 에 잘리지 않습니다. |
| HTML 속성 · DOM 이벤트 | 없습니다. | `id` · `classes` · `css` · `attributes` · DOM 이벤트(바깥 틀에 붙습니다) |

<a id="props-parameters"></a>

## API

공통 속성의 이름은 두 플랫폼이 같고, 날짜와 위젯의 타입이 다릅니다. 한 플랫폼에만 있는 속성은 아래에 따로 적었습니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `DateTime?` (Web `String?`) | `null` | 고른 날짜 |
| `placeholder` | `String?` | `null` | 값이 없을 때의 안내. 없으면 로케일의 기본 문구 |
| `placeholderWidget` | `Widget?` (Web `Component?`) | `null` | 안내를 위젯으로 줍니다. `placeholder` 보다 우선합니다. Web 은 `Text` 만 보입니다. |
| `label` | `String?` | `null` | 트리거 위 라벨 |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 없으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `description` | `String?` | `null` | 트리거 아래 도움말. `errorText` 가 있으면 숨깁니다. |
| `errorText` | `String?` | `null` | 오류 문구. 값을 검증하지 않고 표시만 바꿉니다. |
| `dialogTitle` | `Widget?` (Web `Component?`) | `null` | 대화상자의 제목 |

### 동작과 상태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `mode` | `CorePromptMode?` | `popover` | `popover`, `dialog` |
| `enabled` | `bool` | `true` | false 면 비활성. Flutter 는 `onChanged` 가 없어도 비활성입니다. |
| `popoverPlacement` | `CorePopoverPlacement` | `bottomStart` | 팝오버가 열리는 자리 |
| `datePickerStyle` | `CoreDatePickerStyle?` | `null` | 보이는 값 덮어쓰기 |

### 달력

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `min` | `DateTime?` (Web `String?`) | `null` | 고를 수 있는 가장 이른 날짜 |
| `max` | `DateTime?` (Web `String?`) | `null` | 고를 수 있는 가장 늦은 날짜 |
| `stateBuilder` | `CoreCalendarDateStateBuilder?` | `null` | 날짜마다 고를 수 있는지 정합니다. 주면 `min` · `max` 대신 씁니다. |
| `initialView` | `CoreCalendarView?` | `null` | 처음 보일 달 |
| `firstDayOfWeek` | `int` | `DateTime.sunday` | 한 주의 시작 요일(`DateTime.monday`…`DateTime.sunday`) |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `void Function(DateTime?)?` (Web `void Function(String?)?`) | `null` | 고른 날짜를 받습니다. 해제하면 `null` 입니다. |

Jaspr Web 의 두 위젯은 `id` · `classes` · `css` · `attributes` 와 DOM 이벤트도 받습니다.

### `DateRangePicker`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `DateTimeRange?` (Web `({String start, String end})?`) | Flutter 필수, Web `null` | 고른 범위 |
| `onChanged` | `void Function(DateTimeRange?)?` (Web 레코드) | `null` | 완성한 범위를 받습니다. 해제하면 `null` 입니다. |
| `placeholder` | `Widget?` (Web `Component?`) | `null` | 값이 없을 때의 안내. 없으면 로케일의 기본 문구. Web 은 `Text` 만 보입니다. |
| `mode` | `CorePromptMode` (Web `CorePromptMode?`) | `dialog` | `popover`, `dialog` |
| `dateRangePickerStyle` | `CoreDatePickerStyle?` | `null` | 보이는 값 덮어쓰기 |

`label` · `labelMaxLines` · `labelOverflow` · `description` · `errorText` · `dialogTitle` · `enabled` · `popoverPlacement` · `min` · `max` · `stateBuilder` · `firstDayOfWeek` 는 위와 같습니다. `placeholderWidget` 은 없습니다. `initialView` 와, 범위 글자를 직접 그리는 `builder`(`Widget Function(BuildContext, DateTimeRange)?`)는 Flutter 만 받습니다.

### `DateTimeRange` (Flutter)

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `start` | `DateTime` | 필수(첫 번째 인자) | 시작 날짜 |
| `end` | `DateTime` | 필수(두 번째 인자) | 끝 날짜. 순서를 바로잡지 않으므로 시작 이후의 날짜를 줍니다. |

### Flutter 전용 `ControlledDatePicker`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `DatePickerController?` | `null` | 값을 밖에서 읽고 바꿉니다. 처음 값이 `null` 이 아니면 `initialValue` 대신 씁니다. |
| `initialValue` | `DateTime?` | `null` | 처음 고른 날짜 |

`value` 와 `placeholderWidget` 은 없고, 그 밖에는 `DatePicker` 와 같은 속성을 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDatePickerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `triggerStyle` | `CoreTextFieldStyle?` | Look of the trigger — the read-only `TextField` the picker shows. Laid over [defaultTriggerStyle] and passed to the field as is. The value colour ([contentColor]), placeholder tone ([placeholderColor]), value role ([valueTypography]) and error border ([errorTriggerStyle]'s border colour) sit under it, so this style wins over them. The calendar glyph is styled by [trailingIconStyle] alone. An explicit `popoverStyle.triggerStyle` styled the earlier button trigger and is not read. |
| `popoverStyle` | `CorePopoverStyle?` | Popover style for the popover-mode picker — the look of its dropdown (its trigger part is not read; see [triggerStyle]). |
| `dialogStyle` | `CoreDialogStyle?` | Dialog style for the modal-mode picker — the look of its panel, title and action buttons. |
| `errorTriggerStyle` | `CoreButtonStyle?` | **Deprecated (since 0.173)** — Use triggerStyle: CoreTextFieldStyle(errorBorderColor: …). Override of the trigger button's look while the picker holds an error. Merged on top of [defaultErrorTriggerStyle]; only its `borderColor` is read now — it becomes the trigger field's `errorBorderColor`. `null` takes the default alone. |
| `calendarStyle` | `CoreCalendarStyle?` | Calendar style applied to the inline / popover / dialog calendar grid. Drives nav buttons / date cells / arrow icons / state tokens. |
| `labelStyle` | `CoreTextStyle?` | Label text style (text shown above the trigger). |
| `descriptionStyle` | `CoreTextStyle?` | Description / helper text style (text shown below the trigger when no error). |
| `errorStyle` | `CoreTextStyle?` | Error text style. |
| `valueTypography` | `CoreTextStyle?` | Trigger value text style override (the role applied to both the selected-value text and the placeholder text — colour still comes from [contentColor] / [defaultPlaceholderColor]). `null` leaves the role to the trigger field's own row. |
| `contentColor` | `CoreColor?` | Trigger / label content text colour override. `null` defers to [defaultContentColor]. The Web label row and the trigger field's `valueStyle` both read this slot — for the trigger value **while enabled** (in error or not: an error changes the trigger's edge, see [defaultErrorTriggerStyle], not its label); a disabled value takes the field's own disabled foreground, which this style does not restate. |
| `descriptionColor` | `CoreColor?` | Description / helper text colour override. `null` defers to [defaultDescriptionColor]. |
| `errorColor` | `CoreColor?` | Error text colour override. `null` defers to [defaultErrorColor]. |
| `disabledErrorColor` | `CoreColor?` | Error text colour override while the picker is disabled. `null` defers to [defaultDisabledErrorColor]. |
| `disabledDescriptionColor` | `CoreColor?` | Description text colour override while the picker is disabled. `null` defers to [defaultDisabledDescriptionColor]. [descriptionColor] colours the enabled picker only. |
| `placeholderColor` | `CoreColor?` | Trigger placeholder (no value selected) text colour override. `null` defers to [defaultPlaceholderColor]. |
| `trailingIconStyle` | `CoreIconStyle?` | Trigger trailing (calendar) icon style override. `null` defers to [defaultTrailingIconStyle]. |
| `labelBottomGapStyle` | `CoreGapStyle?` | Style of the vertical `Gap` between the label row and the trigger row. `null` defers to [defaultLabelBottomGapStyle]. |
| `descriptionTopGapStyle` | `CoreGapStyle?` | Style of the vertical `Gap` between the trigger row and the description / error text row. `null` defers to [defaultDescriptionTopGapStyle]. |

<!-- STYLE_TABLE:END -->

<Note>

`contentColor` 는 사용할 수 있는 상태에서 값뿐 아니라 라벨 색도 정합니다(두 플랫폼). Flutter 는 `enabled: false` 이거나 `onChanged` 가 없으면 라벨을 `placeholderColor` 색으로 그립니다. 비활성 `Fieldset` 안에서는 라벨 색은 그대로이고 Fieldset 전체가 흐려집니다. Web 의 라벨은 `enabled: false` 여도 `contentColor` 그대로입니다. Flutter 에서는 `labelStyle` 에 색을 직접 주면 비활성에서도 그 색이 쓰입니다. `dialogStyle` 은 대화상자 패널에 적용되지만, Flutter 에서 대화상자를 띄울 때의 바깥 여백 · 배경막 색과 불투명도 · 전환 시간 · 확대 비율은 바꾸지 않습니다. 이 값은 `CoreComponentTheme.dialog` 로 바꿉니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Calendar" href="/components/calendar" more="Calendar 보기">

화면에 늘 펼쳐 두는 달력입니다. DatePicker 가 여는 패널이 이 달력입니다.

</Card>
<Card component="text-field" props="placeholder=직접 입력" title="TextField">

날짜를 글자로 입력받습니다. 해석과 검증은 앱이 합니다.

</Card>
<Card component="select" props="placeholder=선택하세요" title="Select">

정해 둔 선택지 가운데 하나를 고릅니다.

</Card>
</Cards>

DatePicker 는 [Form](/components/form) 안에 둘 수 있지만, 고른 값은 Form 에 모이지 않습니다.
