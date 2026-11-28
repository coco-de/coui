---
title: Calendar
description: 달력을 화면에 펼쳐 놓고 날짜를 보고 고릅니다. 하루 · 여러 날 · 기간 선택, 월 · 연도 이동, 날짜 아래의 마커를 지원합니다.
category: display
platforms: [flutter, web]
related: [date-picker, time-picker]
tags: [date, schedule, interactive]
template: v2
source: display/calendar
---

# Calendar

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

선택 모드와 첫 요일을 바꾸고 선택 값 · 마커 · 막은 날짜를 켜 보며, 만들어진 코드를 복사하세요. 미리보기는 2026년 4월을 엽니다. 날짜를 누르면 선택이 바뀌고(`none` 은 바뀌지 않습니다), 위쪽 제목을 누르면 월 · 연도를 고르는 보기로 넘어갑니다. 코드의 `setValue` 는 앱의 상태를 바꾸는 함수입니다.

<Playground component="calendar" />

<Note>

기간 선택(`range`)은 두 달을 나란히 그려 기본 크기에서 폭이 464px 입니다. 자리가 좁으면 Web 미리보기는 옆으로 스크롤하고 Flutter 미리보기는 줄여 그립니다. 이 두 동작은 문서의 미리보기 상자가 하는 일이고 `Calendar` 의 기능이 아닙니다.

</Note>

```dart
// 하루
Calendar.single(onChanged: (value) => print(value))

// 여러 날
Calendar.multi(onChanged: (value) => print(value))

// 기간
Calendar.range(onChanged: (value) => print(value))
```

Flutter와 Web 코드가 같습니다.

## 구조

달력은 머리 줄(이전 버튼 · 제목 · 다음 버튼)과 그 아래의 격자로 이루어집니다. 아래 그림은 하루를 고른 날짜 보기입니다.

<Anatomy demo="calendar/anatomy">
<AnatomyItem select="div[aria-label]" side="left" name="Container">

달력 전체입니다. 날짜 칸의 크기가 폭을 정합니다(배치 섹션).

</AnatomyItem>
<AnatomyItem select="button[aria-label]" side="left" name="previous">

앞 기간으로 옮기는 버튼입니다. 날짜 보기에서는 한 달, 월 보기에서는 한 해, 연도 보기에서는 16년씩 옮깁니다.

</AnatomyItem>
<AnatomyItem select="button[aria-label] + div + div > button" side="top" name="title">

보고 있는 연 · 월입니다. 누르면 월 보기로, 한 번 더 누르면 연도 보기로 넘어갑니다.

</AnatomyItem>
<AnatomyItem select="div + button[aria-label]" side="right" name="next">

다음 기간으로 옮기는 버튼입니다.

</AnatomyItem>
<AnatomyItem select="[role=row]" side="left" name="weekdays">

요일 이름 일곱 칸입니다. 순서는 `firstDayOfWeek` 가 정합니다.

</AnatomyItem>
<AnatomyItem select="[role=gridcell] > button" side="left" name="date cell">

날짜 하나를 담는 정사각형 칸입니다(기본 32px). 대부분 `Button` 이고, 기간 안의 칸은 따로 그립니다. Web 은 기간의 시작 · 끝 칸도 따로 그립니다.

</AnatomyItem>
<AnatomyItem select="div[aria-hidden]" side="right" name="marker">

`markerBuilder` 가 마커를 돌려준 날짜의 숫자 아래에 찍는 점입니다.

</AnatomyItem>
</Anatomy>

월 · 연도를 고르는 보기에는 요일 줄이 없고, 날짜 칸 자리에 월 칸이나 연도 칸이 놓입니다. 기간 선택의 날짜 보기는 두 달을 나란히 놓습니다. 제목은 달마다 하나씩이고 이전 · 다음 버튼은 바깥쪽에 하나씩입니다.

<a id="변형-variants"></a>
<a id="동작-스펙-behavior"></a>

## 선택 모드

`selectionMode` 는 날짜를 눌렀을 때 무엇이 선택되는지 정합니다. 기본값은 `single` 입니다. `Calendar.single` · `Calendar.multi` · `Calendar.range` 는 이 값을 정해 둔 생성자이고, `none` 은 `Calendar(selectionMode: ...)` 로 씁니다.

| 값 | 날짜를 누르면 |
| --- | --- |
| `single` | 그 날짜를 고릅니다. 고른 날짜를 다시 누르면 해제합니다. |
| `multi` | 누른 날짜를 하나씩 더합니다. 고른 날짜를 다시 누르면 뺍니다. |
| `range` | 첫 번째가 시작, 두 번째가 끝입니다. |
| `none` | 선택이 바뀌지 않고 `onChanged` 도 부르지 않습니다. 월 · 연도 이동은 됩니다. |

화면에 있는 달력의 `selectionMode` 를 바꿀 때는 새 `key` 로 다시 만드세요. 그대로 바꾸면 고른 값이 남고, 달을 옮긴 뒤에 `range` 로 바꾸면 두 번째 달이 첫 번째 달의 다음 달이 아닐 수 있습니다.

<a id="단일-선택-single"></a>

### 단일 선택

<Preview demo="calendar/single" />

```dart
Calendar.single(
  initialView: const CoreCalendarView(2026, 4),
  value: CoreCalendarValue.single(DateTime(2026, 4, 15)),
  onChanged: (value) => print(value),
)
```

<a id="다중-선택-multi"></a>

### 다중 선택

<Preview demo="calendar/multi" />

```dart
Calendar.multi(
  initialView: const CoreCalendarView(2026, 4),
  value: CoreCalendarValue.multi([
    DateTime(2026, 4, 7),
    DateTime(2026, 4, 15),
    DateTime(2026, 4, 23),
  ]),
  onChanged: (value) => print(value),
)
```

<a id="범위-선택-range"></a>

### 기간 선택

<Preview demo="calendar/range" />

```dart
Calendar.range(
  initialView: const CoreCalendarView(2026, 4),
  value: CoreCalendarValue.range(
    DateTime(2026, 4, 14),
    DateTime(2026, 4, 23),
  ),
  onChanged: (value) => print(value),
)
```

- 두 번째에 시작보다 이른 날짜를 눌러도, 이른 날짜가 시작이 되도록 정렬합니다.
- 끝을 고르기 전에 시작 날짜를 다시 누르면 해제합니다. 기간이 완성된 뒤에 누른 날짜는 새 시작이 됩니다.
- 날짜 보기는 보고 있는 달과 그 다음 달을 나란히 그리고, 이전 · 다음 버튼은 두 달을 함께 한 달씩 옮깁니다.
- 월 · 연도 보기에서는 격자가 하나입니다. 어느 쪽 제목을 눌러도 두 달 가운데 앞선 달을 기준으로 열립니다.
- 달마다 앞뒤의 이웃 달 날짜까지 그리므로, 두 달의 경계에 있는 날짜는 양쪽에 모두 나타날 수 있고 선택 표시도 두 곳에 그립니다.
- 시작과 끝 칸은 선택 색으로 채우고 안쪽 절반에 띠를 잇습니다. 시작이 줄의 마지막 칸이거나 끝이 줄의 첫 칸이면 띠 없이 선택한 날짜처럼 그립니다.

<a id="표시-전용-none"></a>

### 표시 전용

<Preview demo="calendar/none" />

일정이나 정해진 기간을 보여 주기만 할 때 `none` 을 씁니다. `value` 로 넘긴 하루 · 여러 날 · 기간은 그대로 칠합니다. 날짜 칸은 여전히 버튼이라 포커스를 받고 누를 수 있지만, 선택은 바뀌지 않습니다.

```dart
Calendar(
  selectionMode: CoreCalendarSelectionMode.none,
  initialView: const CoreCalendarView(2026, 4),
  value: CoreCalendarValue.range(
    DateTime(2026, 4, 14),
    DateTime(2026, 4, 16),
  ),
)
```

### 선택 값

`value` 와 `onChanged` 의 타입은 `CoreCalendarValue?` 이고, 선택이 없으면 `null` 입니다. 어떤 하위 타입이 오는지는 모드와 누른 순서에 따라 다릅니다.

| 모드 | `onChanged` 가 받는 값 |
| --- | --- |
| `single` | `CoreSingleCalendarValue`. 해제하면 `null` |
| `range` | 시작만 고르면 `CoreSingleCalendarValue`, 끝까지 고르면 `CoreRangeCalendarValue`. 시작을 다시 눌러 해제하면 `null` |
| `multi` | 첫 날짜는 `CoreSingleCalendarValue`, 두 번째부터 `CoreMultiCalendarValue`(빼서 하나가 남아도 같습니다). 모두 빼면 `null` |

```dart
CoreCalendarValue.single(DateTime(2026, 4, 15))
CoreCalendarValue.range(DateTime(2026, 4, 14), DateTime(2026, 4, 23))
CoreCalendarValue.multi([DateTime(2026, 4, 7), DateTime(2026, 4, 15)])
```

받은 값은 모드에 맞춰 꺼냅니다.

```dart
// 다중 선택 — 하나만 골라도 목록으로 받는다
Calendar.multi(
  onChanged: (value) {
    final days = value?.toMulti().dates ?? <DateTime>[];
    print(days);
  },
)

// 기간 선택 — 끝까지 고른 때만 처리한다
Calendar.range(
  onChanged: (value) {
    if (value case CoreRangeCalendarValue(:final start, :final end)) {
      print('$start ~ $end');
    }
  },
)
```

- 달력은 고른 값을 스스로도 갖습니다. `value` 를 주지 않아도 선택이 남습니다.
- 날짜를 누르면 달력이 자기 선택을 먼저 바꾼 뒤 `onChanged` 를 부릅니다.
- `value` 를 주면 그 값에서 시작합니다. 부모가 이전과 다른 값(`==` 비교)을 넘기면 그 값으로 바뀌고, 값이 있다가 `null` 이 되면 선택이 지워집니다.
- `onChanged` 에서 `value` 를 그대로 두는 것만으로는 방금 누른 선택이 되돌아가지 않습니다.
- `value` 가 바뀌어도 보고 있는 달은 옮기지 않습니다.
- `value` 의 날짜는 `DateTime(2026, 4, 15)` 처럼 시각 없이 만드세요. 칠할 때는 날짜만 비교하지만, Flutter 는 누른 날짜를 선택 값과 견줄 때 시각까지 봅니다(플랫폼 차이).

<a id="한-주의-시작-요일-first-day-of-week"></a>

## 한 주의 시작 요일

`firstDayOfWeek` 는 `DateTime.monday` … `DateTime.sunday`(`1..7`) 가운데 하나이고, 생략하면 `DateTime.sunday` 입니다. 이 값 하나가 요일 줄의 순서와 첫 줄을 채우는 이전 달 날짜의 개수를 함께 정합니다. 범위 밖 값은 debug 빌드의 `assert` 가 거부합니다.

<Preview demo="calendar/week-start" />

```dart
Calendar.single(
  firstDayOfWeek: DateTime.monday,
  onChanged: (value) => print(value),
)
```

- **로케일에서 정하지 않습니다.** 한 주의 시작은 같은 언어를 쓰는 지역끼리도 다를 수 있습니다. 킷의 요일 · 월 문구는 언어 단위라, 제품에 필요한 첫 요일은 직접 넘깁니다.
- `DatePicker` · `DateRangePicker` 도 같은 이름의 파라미터를 받아 자신이 여는 `Calendar` 에 넘깁니다.
- 기간 선택의 두 달은 같은 첫 요일을 씁니다. 띠가 접히는 "줄의 첫 칸 · 마지막 칸" 도 이 값이 정합니다.

<a id="뷰-전환"></a>

## 보기 전환

달력은 날짜 · 월 · 연도의 세 보기(`CoreCalendarViewType`)를 오갑니다. 처음에는 늘 날짜 보기이고, 보기를 밖에서 정하는 파라미터는 없습니다.

| 보기 | 격자 | 제목 | 이전 · 다음 |
| --- | --- | --- | --- |
| `date` | 7열. 그 달을 담는 4–6주와 요일 줄 | 로케일의 연 · 월 표기 | 한 달 |
| `month` | 12개월, 4열 × 3행 | 연도 숫자 | 한 해 |
| `year` | 16년, 4열 × 4행 | 로케일의 "연도 선택" 문구 | 16년 |

- 제목을 누를 때마다 날짜 → 월 → 연도로 한 단계씩 올라갑니다. 연도 보기에서는 제목 버튼이 꺼집니다.
- 연도를 고르면 월 보기로, 월을 고르면 날짜 보기로 내려옵니다. 고르지 않고 되돌아가는 버튼은 없습니다.
- 월 · 연도 칸은 선택 값이 걸친 칸을 칠합니다. 선택 · 시작 · 끝은 `primary`, 기간 안은 `secondary` 모양의 `Button` 입니다. 보고 있는 달이라는 이유만으로 따로 표시하지는 않습니다.
- `stateBuilder` · `minDate` · `maxDate` 는 날짜 칸에만 적용합니다. 월 · 연도 칸과 이전 · 다음 버튼은 막지 않습니다.
- 연도 보기의 구간은 달력을 처음 만들 때의 연도를 기준으로 정합니다. 기본값에서는 16의 배수에서 시작해, 2026년이면 2016–2031 입니다. 그 뒤에 달이나 해를 옮겨도 구간은 따라가지 않고, 연도 보기의 이전 · 다음으로만 바뀝니다.

### 오늘과 처음 보이는 달

처음 보이는 달은 다음 순서로 정합니다.

1. `initialView`
2. `value` 의 달 — 기간은 시작 날짜, 다중 선택은 목록의 첫 날짜(목록이 비었으면 오늘의 달)
3. 오늘의 달

`initialView` 는 달력을 처음 만들 때만 읽습니다. 나중에 값을 바꿔도 보는 달은 옮겨지지 않으므로, 코드에서 다른 달로 보내려면 새 `key` 로 다시 만듭니다. 새로 만든 달력의 선택은 `value` 에서 시작합니다.

```dart
Calendar.single(
  key: ValueKey(month),
  initialView: month,
  value: selected,
  onChanged: setSelected,
)
```

오늘은 `CoreCalendarView.currentTime()` 이 돌려주는 시각의 날짜입니다. `package:clock` 의 `clock.now()` 라서 따로 정하지 않으면 실행 환경의 현재 시각입니다. 오늘 표시(테두리 · SemiBold · `primary`)는 선택에 들지 않은 날짜에만 합니다. 테스트에서는 `package:clock/clock.dart` 의 `withClock` 으로 고정할 수 있고, 두 플랫폼이 같은 시계를 읽습니다. 달력은 그려질 때 시계를 읽으므로 화면을 올리는 코드를 이 안에 둡니다.

```dart
withClock(Clock.fixed(DateTime(2026, 4, 15)), () {
  // 이 안에서 그린 달력은 2026년 4월을 열고, 15일을 오늘로 표시합니다.
});
```

<a id="날짜-마커-markers"></a>

## 날짜 마커

`markerBuilder` 가 날짜마다 `CoreCalendarMarker?` 를 돌려주면 그 날짜 숫자 아래에 점을 찍습니다. `null` 이면 점이 없습니다.

<Preview demo="calendar/markers" />

위 그림은 3일 1건, 9일 2건, 15일 5건, 21일 3건입니다. 15일은 점이 3개에서 멈추고, 고른 날짜라 선택 칸용 점 색을 씁니다. 21일은 마커가 지정한 색(`success`)입니다.

```dart
final schedule = <DateTime, List<String>>{
  DateTime(2026, 4, 15): ['접종', '검진'],
};

Calendar.single(
  initialView: const CoreCalendarView(2026, 4),
  markerBuilder: (date) => switch (schedule[date]) {
    final items? when items.isNotEmpty => CoreCalendarMarker(
      count: items.length,
      semanticsLabel: '일정 ${items.length}건',
    ),
    _ => null,
  },
)
```

- 마커는 데이터입니다. 몇 건인지(`count`, 1 이상), 무엇인지(`semanticsLabel`), 필요하면 분류 색(`color`)을 담습니다. 점의 크기 · 간격 · 모양 · 기본 색은 `calendarStyle` 의 `marker*` 필드가 정합니다. 앱 테마(`CoreCalendarTheme`)에 두면 모든 달력의 점에 적용됩니다.
- 점은 `count` 개를 찍되 `markerMaxCount`(기본 3)에서 멈춥니다.
- 날짜 칸의 접근 가능한 이름에는 `semanticsLabel` 이 더해집니다. 생략하면 전체 `count` 를 담은 로케일 문구(`항목 2개`)가 더해집니다. 문구를 직접 줄 때는 필요한 건수를 문구에 넣으세요.
- 선택한 날짜와 기간의 시작 · 끝에서는 `selectedMarkerColor`, 기간 안에서는 `rangeMarkerColor` 를 씁니다. 마커가 색을 지정했어도 같습니다. 그 밖의 날짜는 `color` → `markerColor` 순서입니다.
- 점은 칸 위에 겹쳐 그려 칸 크기를 바꾸지 않습니다. 점을 눌러도 그 날짜가 눌립니다.
- 빌더는 다시 그릴 때마다 날짜 보기의 날짜 칸(이웃 달 포함)마다 한 번씩 부릅니다. 날짜를 키로 한 `Map` 조회처럼 가볍게 두세요.
- 월 · 연도 보기에는 마커를 그리지 않습니다.
- 기간 선택에서도 쓸 수 있습니다. 다만 지금 Web 은 띠를 잇는 시작 · 끝 칸에서 점이 선택 색에 가려 보이지 않습니다(플랫폼 차이).
- `DatePicker` · `DateRangePicker` 에는 `markerBuilder` 파라미터가 없습니다.

## 상태

<Preview demo="calendar/states" />

위 그림은 4월 14–16일 기간을 넘긴 표시 전용 달력입니다. `minDate`(4월 6일)와 `maxDate`(4월 24일) 밖의 날짜는 막혀 있습니다.

| 상태 | 언제 | 기본 모습 |
| --- | --- | --- |
| 기본 | 아래에 해당하지 않는 날짜 | 채움 없는 `ghost` 버튼, `bodySmall` |
| 오늘 | 선택에 들지 않은 오늘 | `outline` 1px 테두리, SemiBold, 글자색 기본값 `primary`. 채움 없음 |
| 선택 | 선택 값의 날짜 | `primary` 채움, `onPrimary` Medium |
| 시작 · 끝 | 기간의 양 끝 | 선택 채움과 안쪽 절반의 띠 |
| 기간 안 | 양 끝 사이 | `primaryContainer` 띠, `onPrimaryContainer` 글자 |
| 이웃 달 | 앞뒤 달의 날짜 | Flutter 는 불투명도 50%, Web 은 흐려지지 않음. 눌러서 고를 수 있고 보는 달은 그대로입니다 |
| 비활성 | `stateBuilder` · `minDate` · `maxDate` 가 막은 날짜 | 누를 수 없음. 선택에 들지 않은 보통 날짜는 비활성 글자색(선택 · 오늘 · 기간 칸은 플랫폼 차이 참조) |

<a id="날짜-상태-검증"></a>

### 날짜 막기

`stateBuilder` 는 날짜마다 `CoreCalendarDateState.enabled` 나 `disabled` 를 돌려줍니다. 아래 그림은 주말을 막았습니다. 시작과 끝 날짜만 정하면 될 때는 `minDate` · `maxDate` 로 충분합니다.

<Preview demo="calendar/disabled" />

```dart
// 위 그림 — 주말 막기
Calendar.single(
  initialView: const CoreCalendarView(2026, 4),
  stateBuilder: (date) => date.weekday >= DateTime.saturday
      ? CoreCalendarDateState.disabled
      : CoreCalendarDateState.enabled,
)

// 구간으로 막기 — 두 경계 날짜는 고를 수 있다
Calendar.single(
  minDate: DateTime(2026, 4, 6),
  maxDate: DateTime(2026, 4, 24),
)

// 규칙으로 막기 — 지난 날짜
Calendar.single(
  stateBuilder: (date) {
    final now = CoreCalendarView.currentTime();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today)
        ? CoreCalendarDateState.disabled
        : CoreCalendarDateState.enabled;
  },
)
```

- `minDate` · `maxDate` 는 시각을 버리고 날짜로 비교하며, 두 경계 날짜를 포함합니다.
- `stateBuilder` 가 있으면 그 결과만 씁니다. `minDate` · `maxDate` 는 보지 않습니다.
- `stateBuilder` 가 받는 `date` 는 그날 0시입니다. 지난 날짜를 막으면서 `date.isBefore(DateTime.now())` 처럼 지금 시각과 비교하면, 0시가 지난 뒤에는 오늘까지 막힙니다.
- 달력 전체를 끄는 `enabled` 파라미터는 없습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 달력을 화면에 계속 보여 주면서 날짜를 고르게 할 때
- 체크인 · 체크아웃 같은 기간이나 여러 날을 고를 때
- 일정 · 근태 · 식단 · 예약처럼 날짜마다 몇 건이 있는지 점으로 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 달력을 접어 두고 입력 칸을 눌러 팝오버나 대화상자로 열 때 | [DatePicker](/components/date-picker) |
| 날짜 없이 시각만 고를 때 | [TimePicker](/components/time-picker) |
| 월 · 연도 이동이나 날짜 격자 없이 글자로만 받을 때(날짜 해석과 검증은 앱이 맡습니다) | [TextField](/components/text-field) |

<a id="do"></a>
<a id="dont"></a>

### 구간과 규칙을 함께 쓸 때

<Cards columns="2">
<Card demo="calendar/do-combined-rules" tone="do" eyebrow="이렇게 하세요">

구간 검사도 `stateBuilder` 안에 넣습니다. 4월 6–24일의 평일만 고를 수 있습니다.

</Card>
<Card demo="calendar/dont-split-rules" tone="dont" eyebrow="이렇게 하지 마세요">

`minDate` · `maxDate` 와 주말만 막는 `stateBuilder` 를 나란히 넘기면 구간이 무시됩니다. 4월 1–3일과 27–30일이 막히지 않았습니다.

</Card>
</Cards>

```dart
// 이렇게 하세요
Calendar.single(
  stateBuilder: (date) {
    final outside = date.isBefore(DateTime(2026, 4, 6)) ||
        date.isAfter(DateTime(2026, 4, 24));
    final weekend = date.weekday >= DateTime.saturday;
    return outside || weekend
        ? CoreCalendarDateState.disabled
        : CoreCalendarDateState.enabled;
  },
)

// 이렇게 하지 마세요 — minDate · maxDate 를 읽지 않는다
Calendar.single(
  minDate: DateTime(2026, 4, 6),
  maxDate: DateTime(2026, 4, 24),
  stateBuilder: (date) => date.weekday >= DateTime.saturday
      ? CoreCalendarDateState.disabled
      : CoreCalendarDateState.enabled,
)
```

### 고른 날짜를 글로도 보여 주기

날짜 칸에는 선택 여부를 보조 기술에 알리는 속성이 없습니다(접근성 섹션). 고른 결과가 중요한 화면에서는 달력 옆에 고른 날짜를 글로 함께 적으세요.

## 배치

날짜 칸의 크기는 `dayCellSize` 가 정하고, 부모 폭에 맞춰 커지거나 작아지지 않습니다. 좁은 폭에서 기간 선택을 한 달로 접거나 칸을 줄이는 동작도 없습니다. 기본값에서 격자의 폭은 다음과 같습니다.

| 보기 | 폭 |
| --- | --- |
| 날짜 보기 | 224px(`32 × 7`) |
| 날짜 보기, 기간 선택 | 464px(두 달과 사이 16) |
| 월 · 연도 보기 | Flutter 224px, Web 248px |

높이는 달이 걸치는 주의 수를 따릅니다. 기본값의 날짜 보기는 4주 240px, 5주 280px, 6주 320px 이고, 월 보기는 160px, 연도 보기는 200px 입니다. 달이나 보기를 바꾸면 아래 내용이 움직일 수 있으므로, 움직이면 안 되는 화면은 320px 를 확보합니다. 기간 선택은 두 달 가운데 주가 많은 쪽을 따릅니다. Flutter 는 스크롤 뷰 안에서도 높이를 따로 제한할 필요가 없습니다.

기간 선택이 들어갈 폭이 모자랄 수 있으면 옆으로 스크롤하는 상자에 담습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Calendar.range(onChanged: setValue),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(classes: 'overflow-x-auto', [
  div(classes: 'w-max', [
    Calendar.range(onChanged: setValue),
  ]),
])
```

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

종류를 고르는 값과 동작(`selectionMode` · `firstDayOfWeek` · `stateBuilder` · `markerBuilder` 등)은 위젯 파라미터로 넘깁니다. 색 · 크기 · 간격과 안쪽 부품의 스타일은 `calendarStyle`(`CoreCalendarStyle`) 하나로 덮어씁니다([설계 원칙](/principles)).

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreCalendarStyle 의 기본값
  → CoreCalendarTheme.style      // 앱 전체 (CoreComponentTheme.calendar)
  → calendarStyle                // 이 달력 하나
```

- 뒤의 값이 앞의 값을 필드 단위로 덮습니다.
- 안쪽 부품의 스타일(`navButtonStyle` · `dateCellStyle` · `arrowIconStyle` · `headerGridGapStyle`)과 글자 스타일(`headerTextStyle` · `weekdayTextStyle` · `cellTextStyle` · `selectedTextStyle` · `todayTextStyle` · `rangeSelectionTextStyle` · `weekdayLabelTextStyle`)은 그 안의 필드끼리 다시 합칩니다. `markerPadding` 같은 나머지 값은 통째로 바뀝니다.
- `DatePicker` · `DateRangePicker` 가 여는 달력에는 피커 스타일의 `calendarStyle` 칸(`CoreDatePickerStyle.calendarStyle`, 피커의 테마 값 포함)이 마지막 자리로 들어옵니다. 그래서 `CoreCalendarTheme.style` 보다 우선합니다.

### 사용 예

<Preview demo="calendar/themed" />

미리보기는 "달력 하나 바꾸기" 의 스타일을 마커가 있는 표시 전용 달력에 적용한 것입니다.

<Split>

<Code language="dart" title="달력 하나 바꾸기">
Calendar.range(
  initialView: const CoreCalendarView(2026, 4),
  calendarStyle: const CoreCalendarStyle(
    dayCellSize: CoreSpace.space36,
    rangeSelectionColor: CoreColor.token(CoreColors.successContainer),
    rangeSelectionTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onSuccessContainer),
    ),
    markerMaxCount: 4,
    markerColor: CoreColor.token(CoreColors.success),
    rangeMarkerColor: CoreColor.token(CoreColors.onSuccessContainer),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    calendar: CoreCalendarTheme(
      style: CoreCalendarStyle(
        dayCellSize: CoreSpace.space36,
        cellSpacing: CoreSpace.space4,
        dateCellStyle: CoreButtonStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 두 플랫폼에서 닿는 범위가 다른 필드는 플랫폼 차이에 모았습니다.

### 글자 역할

| 자리 | 필드와 기본값 |
| --- | --- |
| 요일 줄 | `weekdayTextStyle` · `weekdayLabelTextStyle`. 기본 `bodyXs`(12px), `onSurfaceSubtle` |
| 날짜 | `cellTextStyle`. 기본 `bodySmall`(13px) |
| 제목 | `headerTextStyle`. 기본 `labelMedium`(13px · Medium) |
| 오늘 | `todayTextStyle`. 기본 `bodySmall` SemiBold, `primary` |
| 선택 | `selectedTextStyle`. 기본 `bodySmall` Medium, `onPrimary` |
| 기간 안 | `cellTextStyle` 과 `rangeSelectionTextStyle` 의 색. 기본 `bodySmall`, `onPrimaryContainer` |

요일 줄은 격자의 축 이름이라 날짜보다 한 단계 작고 옅게 둡니다. 제목은 보기를 바꾸는 버튼이라 버튼 라벨의 역할을 씁니다. 오늘과 선택한 날짜는 다른 날짜와 크기가 같고 굵기가 올라갑니다. 월 · 연도 칸의 글자도 `cellTextStyle` 을 따릅니다.

`cellTextStyle` 에 `color` 를 주면 Flutter 에서는 기간 안 칸과 월 · 연도 칸(선택한 칸 포함)의 글자색도 그 색이 됩니다. 이때는 선택 색 위에서도 글자가 읽히는지 확인하세요.

### 크기와 색의 기본값

기본값은 `coui_core` 의 `CoreCalendarStyle` 에 있고 두 플랫폼이 함께 읽습니다. 길이의 단위는 논리 px 입니다.

| 필드 | 기본값 |
| --- | --- |
| `dayCellSize` | 32 |
| `monthCellWidth` | 56 |
| `cellSpacing` | 8 |
| `headerGridGapStyle` | 간격 16 |
| `yearRowSpacing` | 8 |
| `arrowIconStyle` | 아이콘 16 |
| `endpointPillBorderRadius` | `radius8` |
| `fadedOpacity` | 0.5 |
| `yearGridSize` | 16 |
| `monthGridColumns` | 4 |
| `yearGridColumns` | 4 |
| `selectedColor` | `primary` |
| `rangeSelectionColor` | `primaryContainer` |
| `todayBorderColor` | `outline` |
| `todayBorderWidth` | 1 |
| `markerSize` | 4 |
| `markerSpacing` | 2 |
| `markerPadding` | 아래 2 |
| `markerBorderRadius` | `radius9999` (원) |
| `markerMaxCount` | 3 |
| `markerColor` | `primary` |
| `selectedMarkerColor` | `onPrimary` |
| `rangeMarkerColor` | `onPrimaryContainer` |

`navButtonStyle` 은 이전 · 다음 버튼과 제목 버튼에 함께 적용합니다. `dateCellStyle` 은 `Button` 으로 그리는 날짜 칸과 월 · 연도 칸에 적용합니다. 선택 · 오늘 스타일 위에 합치므로 여기에 `backgroundColor` 를 주면 선택한 날짜의 채움까지 바뀝니다. 직접 그리는 칸(기간 안, 그리고 Web 의 띠를 잇는 시작 · 끝)에는 적용되지 않습니다. 두 스타일의 `labelStyle` 이 Flutter 에서 닿지 않는 글자는 플랫폼 차이에 적었습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Calendar` 에 `withStyle` 을 이어 `calendarStyle` 을 덧붙일 수 있습니다. 넘긴 값은 이미 있는 `calendarStyle` 에 합쳐지고, 같은 필드는 나중 값이 이깁니다. 아래 예제는 날짜 칸 크기(`dayCellSize`) 40, 줄 간격(`cellSpacing`) 12, 제목 글자(`headerTextStyle`)를 지정합니다. 함께 적은 `endpointPillBorderRadius` 는 기간의 시작 · 끝 칸에 쓰는 값이고 Web 에만 적용됩니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CalendarChainExample extends StatelessWidget {
  const CalendarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Calendar.single().withStyle(
      const CoreCalendarStyle(
        dayCellSize: CoreSpace.space40,
        cellSpacing: CoreSpace.space12,
        endpointPillBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        headerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
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
class CalendarChainExample extends StatelessComponent {
  const CalendarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Calendar.single().withStyle(
      const CoreCalendarStyle(
        dayCellSize: CoreSpace.space40,
        cellSpacing: CoreSpace.space12,
        endpointPillBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        headerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
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

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 부분 | 두 플랫폼의 역할 |
| --- | --- |
| 루트 | Flutter: `Semantics(container: true)` 와 로케일 이름(`calendarLabel`), 역할 없음. Web: `<div>` 와 `aria-label`(같은 문구), 역할 없음 |
| 격자 | Flutter: table. Web: `role="grid"` |
| 행 | Flutter: row. Web: `role="row"` |
| 요일 칸 | Flutter: columnHeader. Web: `role="columnheader"` |
| 칸 감싸개 | Flutter: cell. Web: `role="gridcell"`(`display: contents`) |
| 날짜 칸 | Flutter: `Button` 의 버튼과 활성 여부. Web: `<button type="button">`, 비활성이면 `disabled` · `tabindex="-1"` · `aria-disabled="true"` |
| 시작 · 끝 | Flutter: `Button`. Web: `<div role="button">` |
| 기간 안 | Flutter: `Clickable` 의 버튼과 활성 여부. Web: `<div role="button">` |
| 이전 · 다음 | Flutter: 버튼, `Semantics(label:)` 로 이름. Web: 버튼의 `aria-label` |
| 제목 | 두 플랫폼 모두 버튼이고, 이름은 제목 글자 |

격자 역할은 루트가 아니라 날짜 · 월 · 연도 격자에 있습니다. 루트에는 이전 · 다음 버튼과 제목도 들어 있기 때문입니다. 월 · 연도 격자는 요일 줄 없이 행과 칸으로 이루어집니다. 세 격자 모두 칸 역할은 버튼을 감싸는 바깥 요소에 두어 버튼 역할과 겹치지 않게 합니다.

Web 의 직접 그린 기간 칸은 활성일 때 `tabindex="0"` 을 갖고, 비활성이면 `tabindex` 없이 `aria-disabled="true"` 를 갖습니다. 비활성이어도 `role="button"` 은 남습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 머리 줄의 버튼과 활성 날짜 칸을 차례로 지납니다. 날짜마다 정지점이 하나입니다. |
| `Enter` · `Space` | 포커스가 있는 버튼 · 날짜 · 월 · 연도 칸을 누릅니다. |

`Calendar` 에는 화살표 키, `Home` · `End`, `PageUp` · `PageDown`, `Escape` 를 처리하는 코드가 없습니다. 날짜 사이를 키로 옮겨 다니는 격자 이동은 제공하지 않습니다. 앱이나 프레임워크가 이 키에 걸어 둔 단축키는 `Calendar` 가 정하지 않습니다.

Flutter 는 `Button` 과 `Clickable` 의 활성화 단축키를 쓰고, Web 은 네이티브 `<button>` 의 기본 동작을 씁니다. Web 의 직접 그린 기간 칸은 `keydown` 에서 `Enter` · `Space` 를 받고 `Space` 의 페이지 스크롤을 막습니다.

### 스크린 리더

- 루트와 이전 · 다음 버튼의 이름은 로케일 문구입니다(`calendarLabel` · `calendarPreviousPeriod` · `calendarNextPeriod`).
- 날짜 칸의 이름은 날짜 숫자입니다. 마커가 있으면 `semanticsLabel`(없으면 `calendarMarkerCount` 문구)이 더해집니다. Flutter 는 `MergeSemantics` 로 합치고, Web 은 칸 안에 화면에는 보이지 않는 글(`sr-only`)을 둡니다. 점은 접근성 트리에서 뺍니다(Flutter `ExcludeSemantics`, Web `aria-hidden`).
- 월 · 연도 · 요일은 날짜 칸의 이름에 넣지 않습니다.
- 선택 · 오늘 · 기간 안이라는 상태도 날짜 칸에 넣지 않습니다. `aria-selected` · `aria-current` 나 Flutter 의 선택 시맨틱이 없습니다.
- 비활성 날짜는 Web 에서 `aria-disabled`, Flutter 에서 `Semantics(enabled: false)` 로 알립니다.
- 선택이나 달 · 보기가 바뀐 사실을 문구로 알리는 라이브 영역이나 안내는 없습니다.

### 포커스 관리

- 칸마다 따로 포커스를 받습니다. 격자 전체를 정지점 하나로 묶는 roving tabindex 는 없습니다. 모두 활성인 한 달 날짜 보기는 날짜 칸이 28–42개이고 머리 줄의 버튼이 3개입니다. 기간 선택은 두 달의 날짜 칸이 모두 정지점이고 머리 줄의 버튼이 4개입니다.
- Flutter 는 `Button` 과 `Clickable` 의 포커스 링을 그립니다. Web 의 `Button` 칸은 `:focus-visible` 포커스 링을 그립니다. Web 의 직접 그린 기간 칸에는 킷의 포커스 링이 없어 브라우저 기본 표시를 따릅니다.
- 마운트할 때 포커스를 가져오지 않고, 달이나 보기를 바꾼 뒤 포커스를 옮겨 주는 코드가 없으며, 포커스를 가두지 않습니다.
- 날짜 칸이 보통 `Button` 에서 기간 모양으로(또는 그 반대로) 바뀌면 그 칸의 위젯 · 요소를 새로 만듭니다. 그래서 키보드로 기간의 끝을 골라 그 칸이 띠를 잇는 모양이 되면, 방금 누른 칸에 포커스가 남지 않습니다. Flutter 는 칸의 위젯 구조가 바뀌고, Web 은 `<button>` 이 `<div>` 로 바뀝니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 격자 역할은 있지만 화살표 키 이동과 roving tabindex 가 없습니다. 원하는 날짜까지 `Tab` 으로 하나씩 지나야 합니다. |
| 공통 | 선택 · 오늘 · 기간은 눈에 보이는 모양으로만 표시합니다. |
| 공통 | 날짜 칸의 이름에 월과 요일이 없습니다. 이웃 달의 날짜까지 그리므로 같은 이름의 칸이 한 격자에 둘 있을 수 있습니다. |
| 공통 | `none` 모드에서도 날짜 칸이 버튼으로 남지만 눌러도 선택이 바뀌지 않습니다. |
| 공통 | 기간 선택에서 칸 모양이 바뀌면 포커스가 유지되지 않습니다. |
| Jaspr Web | 루트의 `aria-label` 은 `attributes` 보다 나중에 합쳐져 덮어쓸 수 없습니다. |

위 항목은 지금 코드의 상태입니다. 필요한 화면에서는 앱에서 보완하세요.

앱 전체에 공통인 접근성 기준은 [접근성](/accessibility) 페이지에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자와 선택 · 이동 규칙은 대부분 같습니다. 아래는 구현이 다른 곳과, 지금 버전에서 결과가 달라지는 곳입니다.

### 만드는 방식

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 기반 | `StatefulWidget` | `UiStatefulComponent` |
| HTML 속성 | 없음(`key` 만) | `id` · `classes` · `css` · `attributes` · 이벤트가 루트 `<div>` 에 닿습니다 |
| 격자 의미 | table · row · cell | grid · row · gridcell |
| 보통 날짜 | `Button` | 네이티브 `<button>` |
| 시작 · 끝 | `Button` 과 그 뒤의 띠 | 직접 그린 `<div>`(채움과 띠) |
| 기간 안 | `Clickable` | `click` · `keydown` 을 받는 `<div>` |
| 마커 | 칸 위에 겹친 점 행 | 칸 위에 절대 위치로 놓은 점 행 |

### 결과가 다른 곳

- **이웃 달** — Flutter 는 `fadedOpacity` 만큼 흐리게 그립니다. Jaspr Web 은 흐려지지 않습니다. 투명도를 상자를 만들지 않는 `display: contents` 요소에 주기 때문이며, `fadedOpacity` 를 바꿔도 보이는 변화가 없습니다.
- **끝 칸 마커** — Flutter 는 점이 보입니다. Jaspr Web 은 띠를 잇는 시작 · 끝 칸에서 점이 채움에 가려집니다. 마커 문구는 칸 안에 남습니다.
- **막힌 기간** — Flutter 는 기간 안의 비활성 칸을 흐리게 그립니다. Jaspr Web 에서 직접 그린 기간 칸은 누를 수 없을 뿐 모습이 활성 칸과 같습니다.
- **막힌 선택 · 오늘** — Flutter 는 선택 · 오늘의 색을 그대로 두어, 누를 수 있는 칸과 색이 같습니다. Jaspr Web 은 `Button` 으로 그리는 칸이 비활성 색이 됩니다. 선택한 날짜는 채움까지 바뀌어 선택 표시가 사라집니다.
- **선택 색** — Flutter 는 `selectedColor` 가 선택한 날짜와 시작 · 끝에 적용됩니다. Jaspr Web 은 띠를 잇는 시작 · 끝 칸에만 적용됩니다. `Button` 으로 그리는 칸(하루 · 여러 날, 띠 없이 그리는 시작 · 끝)은 `primary` 채움 그대로입니다.
- **오늘 채움** — Flutter 는 `todayColor` 가 적용됩니다. Jaspr Web 은 토큰 색(`CoreColor.token`)이 적용되지 않습니다. 직접 지정한 색은 버튼을 감싸는 상자에 칠합니다.
- **끝 모서리** — Flutter 는 `endpointPillBorderRadius` 를 읽지 않고 `Button` 의 모서리를 씁니다. Jaspr Web 은 띠를 잇는 시작 · 끝 칸에 `endpointPillBorderRadius` 가 적용됩니다.
- **월 · 연도 칸 간격** — Flutter 는 칸 사이에 가로 간격이 없습니다. Jaspr Web 은 가로 간격으로 `cellSpacing` 을 둡니다. 그래서 기본값에서는 한 달 날짜 격자보다 폭이 넓습니다.
- **일부 글자** — Flutter 에서 제목의 글자 모양(크기 · 굵기)은 `headerTextStyle` 로, 월 · 연도 칸은 `cellTextStyle` 로 바꿉니다. `navButtonStyle` · `dateCellStyle` 의 `labelStyle` 에 둔 모양은 닿지 않습니다. Jaspr Web 에서는 제목과 월 · 연도 칸에 이 `labelStyle` 도 닿습니다.
- **시각 비교** — Jaspr Web 은 누른 날짜와 연 · 월 · 일만 비교합니다. Flutter 는 선택 값에 시각이 들어 있으면 아래처럼 동작합니다.

Flutter 에서 `value` 에 `DateTime(2026, 4, 15, 9)` 처럼 시각이 들어 있으면, `single` 은 그 날짜를 처음 눌렀을 때 해제하지 않고 시각 없는 같은 날짜를 다시 고릅니다. `multi` 는 그 날짜를 눌러도 목록에서 빠지지 않습니다. `range` 에서 시작만 고른 값에 시각이 있으면, 같은 날짜를 눌렀을 때 해제되지 않고 하루짜리 기간이 됩니다.

### Web 에서 크기 값을 바꿀 때

Web 은 날짜 버튼의 크기를 값 그대로 내보내지만, 요일 칸과 직접 그리는 기간 칸의 크기는 `CoreSize` 단계의 클래스를, 격자의 간격은 `CoreSpace` 단계의 클래스를 씁니다. 단계에 없는 값은 클래스를 쓰는 자리에 적용되지 않습니다.

- `dayCellSize` 는 `CoreSize` 단계의 값(28 · 32 · 36 · 40 · 44 · 48 등)을 씁니다. 단계에 없는 값을 주면 요일 열과 날짜 열이 어긋납니다.
- `cellSpacing` · `yearRowSpacing` 은 `CoreSpace` 단계의 값을 씁니다.
- 밀도(`CoreDensity`)를 바꿔도 날짜 칸과 요일 칸의 크기는 두 플랫폼 모두 그대로입니다.

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 파라미터를 씁니다. 생성자는 `Calendar`, `Calendar.single`, `Calendar.range`, `Calendar.multi` 이고, 이름 있는 세 생성자에는 `selectionMode` 파라미터가 없습니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `selectionMode` | `CoreCalendarSelectionMode` | `single` | 선택 모드 — `none` · `single` · `range` · `multi` |
| `value` | `CoreCalendarValue?` | `null` | 선택 값. 선택 값 절 참조 |
| `onChanged` | `void Function(CoreCalendarValue?)?` | `null` | 날짜를 눌러 선택이 바뀔 때 부릅니다. |
| `initialView` | `CoreCalendarView?` | `null` | 처음 보이는 연 · 월 |
| `firstDayOfWeek` | `int` | `DateTime.sunday` | 한 주가 시작하는 요일(`1..7`) |
| `stateBuilder` | `CoreCalendarDateStateBuilder?` | `null` | 날짜마다 활성 · 비활성을 정합니다. 있으면 `minDate` · `maxDate` 를 보지 않습니다. |
| `minDate` | `DateTime?` | `null` | 고를 수 있는 가장 이른 날짜(포함) |
| `maxDate` | `DateTime?` | `null` | 고를 수 있는 가장 늦은 날짜(포함) |
| `markerBuilder` | `CoreCalendarMarkerBuilder?` | `null` | 날짜별 마커. `null` 을 돌려주면 그 날짜에는 마커가 없습니다. |
| `calendarStyle` | `CoreCalendarStyle?` | `null` | 이 달력의 스타일 덮어쓰기 |

- `CoreCalendarDateStateBuilder` 는 `CoreCalendarDateState Function(DateTime date)` 이고, `CoreCalendarDateState` 는 `enabled` · `disabled` 입니다.
- `CoreCalendarMarkerBuilder` 는 `CoreCalendarMarker? Function(DateTime date)` 입니다.

### Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 루트 `<div>` 의 HTML 속성. `aria-label` 은 덮이지 않습니다. |
| `id` | `String?` | `null` | 루트의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 스타일 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 DOM 이벤트 |
| `onClick` | `UiMouseEventHandler?` | `null` | 루트의 `click` |
| `onMouseEnter` | `UiMouseEventHandler?` | `null` | 루트의 `mouseenter` |
| `onMouseLeave` | `UiMouseEventHandler?` | `null` | 루트의 `mouseleave` |
| `onKeyDown` | `UiKeyboardEventHandler?` | `null` | 루트의 `keydown` |
| `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 루트의 `keyup` |
| `onInput` | `UiInputEventHandler?` | `null` | 루트의 `input` |
| `onChange` | `UiInputEventHandler?` | `null` | 루트의 DOM `change`. 선택 변경은 `onChanged` 로 받습니다. |

### 체인

`withStyle(patch)` 는 `CoreCalendarStyle` 을 지금의 `calendarStyle` 에 합친 새 `Calendar` 를 돌려줍니다. 두 플랫폼에 있습니다.

### `CoreCalendarValue`

| 만드는 법 | 타입 | 담는 값 |
| --- | --- | --- |
| `CoreCalendarValue.single(date)` | `CoreSingleCalendarValue` | `date` |
| `CoreCalendarValue.range(a, b)` | `CoreRangeCalendarValue` | `start` · `end`(앞선 날짜가 `start`) |
| `CoreCalendarValue.multi(dates)` | `CoreMultiCalendarValue` | `dates` |

- `toSingle()` 은 기간이면 시작, 여러 날이면 목록의 첫 날짜를 담습니다. 빈 목록에는 쓸 수 없습니다.
- `toRange()` 는 하루면 시작과 끝이 같은 기간, 여러 날이면 가장 이른 날짜부터 가장 늦은 날짜까지입니다.
- `toMulti()` 는 목록으로 바꿉니다. 기간은 사이의 날짜를 펼칩니다.
- `lookup(year, [month, day])` 은 그 날짜 · 월 · 연도가 선택에 어떻게 걸치는지 `CoreCalendarValueLookup`(`none` · `selected` · `start` · `end` · `inRange`)으로 돌려줍니다.
- `viewYear` · `viewMonth` 는 처음 보이는 달을 정할 때 쓰는 값입니다.

### `CoreCalendarMarker`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `count` | `int` | `1` | 그 날짜의 건수. 1 이상이어야 합니다(`assert`). |
| `color` | `CoreColor?` | `null` | 선택에 들지 않은 날짜의 점 색 |
| `semanticsLabel` | `String?` | `null` | 날짜 이름에 더하는 문구. `null` 이면 로케일의 개수 문구 |

### `CoreCalendarView`

`CoreCalendarView(year, month)` 는 보이는 연 · 월 하나를 담습니다.

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `year` | `int` | 연도 |
| `month` | `int` | 월. 1–12 (`assert`) |

`next` · `previous` · `nextYear` · `previousYear` 는 옮긴 새 값을 돌려줍니다. `CoreCalendarView.now()` 는 오늘의 달, `CoreCalendarView.fromDateTime(date)` 는 그 날짜의 달이고, `CoreCalendarView.currentTime()` 은 달력이 오늘로 보는 시각입니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCalendarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `dayCellSize` | `double?` | Day / month / year cell size (logical px). `null` defers to [defaultDayCellSize]. |
| `monthCellWidth` | `double?` | Month / year grid cell width (logical px). `null` defers to [defaultMonthCellWidth]. |
| `cellSpacing` | `double?` | Gap between calendar grid cells (logical px). `null` defers to [defaultCellSpacing]. Consumed natively as `Column.spacing` on Flutter and `gap-${cellSpacing.tailwindSpace}` on Web. |
| `headerGridGapStyle` | `CoreGapStyle?` | Gap between the header row and the grid, also used between the buttons inside the header row. Laid over [defaultHeaderGridGapStyle] and passed to `Gap(gapStyle: …)` as is. |
| `yearRowSpacing` | `double?` | Row gap between year-grid rows (logical px). `null` defers to [defaultYearRowSpacing]. Consumed natively as `Column.spacing` on Flutter and `gap-${yearRowSpacing.tailwindSpace}` on Web. |
| `endpointPillBorderRadius` | `CoreBorderRadius?` | Border radius for the range endpoint pill. `null` defers to [defaultEndpointPillBorderRadius]. |
| `fadedOpacity` | `double?` | Opacity applied to dates from the previous / next month. `null` defers to [defaultFadedOpacity]. |
| `yearGridSize` | `int?` | Total items in the year grid. `null` defers to [defaultYearGridSize]. |
| `monthGridColumns` | `int?` | Month grid columns. `null` defers to [defaultMonthGridColumns]. |
| `yearGridColumns` | `int?` | Year grid columns. `null` defers to [defaultYearGridColumns]. |
| `navButtonStyle` | `CoreButtonStyle?` | Style applied to navigation buttons (prev / next month / year arrows + the header button that opens the year/month grid). |
| `dateCellStyle` | `CoreButtonStyle?` | Style applied to each date / month / year cell button. |
| `arrowIconStyle` | `CoreIconStyle?` | Icon style used by the prev / next arrow icons inside the nav buttons. |
| `headerTextStyle` | `CoreTextStyle?` | Header label text style (the "May 2026" / "2026" / decade label). `null` defers to [defaultHeaderTextStyle]. |
| `weekdayTextStyle` | `CoreTextStyle?` | Weekday header label text style (Sun / Mon / …). `null` defers to [defaultWeekdayTextStyle]. |
| `cellTextStyle` | `CoreTextStyle?` | Date / month / year cell text style — applied to the cell `Button.labelStyle`. `null` defers to [defaultCellTextStyle]. |
| `selectedColor` | `CoreColor?` | Background colour for the selected (start / end pill) date cell. `null` defers to [defaultSelectedColor]. |
| `selectedTextStyle` | `CoreTextStyle?` | Text style for the selected (start / end pill) date cell. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `selectedTextColor` field removed). `null` defers to [defaultSelectedTextStyle]. |
| `todayColor` | `CoreColor?` | Background colour for today's date cell. `null` defers to Button's secondary variant default. |
| `todayBorderColor` | `CoreColor?` | Border colour of today's date cell. `null` → [defaultTodayBorderColor]. |
| `todayBorderWidth` | `double?` | Border width of today's date cell (logical px, pre-scaling). `null` → [defaultTodayBorderWidth]. |
| `todayTextStyle` | `CoreTextStyle?` | Text style for today's date cell. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `todayTextColor` field removed). `null` defers to [defaultTodayTextStyle]. |
| `rangeSelectionColor` | `CoreColor?` | Range band colour — fills the cells inside a selected range (between start and end, exclusive) and the inner half of each endpoint cell behind its pill. `null` defers to [defaultRangeSelectionColor]. |
| `rangeSelectionTextStyle` | `CoreTextStyle?` | Text style for cells inside a selected range. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `rangeSelectionTextColor` field removed). `null` defers to [defaultRangeSelectionTextStyle]. |
| `weekdayLabelTextStyle` | `CoreTextStyle?` | Weekday header label text style (Sun / Mon / …). Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `weekdayLabelColor` field removed). `null` defers to [defaultWeekdayLabelTextStyle]. |
| `markerSize` | `double?` | Marker dot diameter (logical px). `null` defers to [defaultMarkerSize]. |
| `markerSpacing` | `double?` | Space between two marker dots (logical px). `null` defers to [defaultMarkerSpacing]. Consumed natively as `Row.spacing` on Flutter and an inline `gap` on Web. |
| `markerPadding` | `CoreEdgeInsets?` | Inset of the marker row from the day cell's edges. The row is anchored to the cell's bottom centre, so the bottom inset is the one that shows. `null` defers to [defaultMarkerPadding]. |
| `markerBorderRadius` | `CoreBorderRadius?` | Marker dot corner radius. `null` defers to [defaultMarkerBorderRadius] (a round dot). |
| `markerMaxCount` | `int?` | Most dots drawn for one date. `null` defers to [defaultMarkerMaxCount]. |
| `markerColor` | `CoreColor?` | Marker dot fill on an unselected cell, used when the marker itself names no colour. `null` defers to [defaultMarkerColor]. |
| `selectedMarkerColor` | `CoreColor?` | Marker dot fill on a selected cell (single / multi selection and range endpoints) — always used there, even when the marker names its own colour, so the dots stay legible on the selection fill. `null` defers to [defaultSelectedMarkerColor]. |
| `rangeMarkerColor` | `CoreColor?` | Marker dot fill on a cell inside a selected range (between the endpoints) — always used there, for the same legibility reason as [selectedMarkerColor]. `null` defers to [defaultRangeMarkerColor]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명만으로는 알 수 없거나 지금 동작과 다른 필드입니다.

- `todayColor` — 오늘 칸은 `secondary` 가 아니라 채움 없는 `ghost` 버튼입니다. `null` 이면 채움이 없습니다. Web 은 토큰 색을 적용하지 않습니다.
- `selectedColor` — Web 은 띠를 잇는 기간의 시작 · 끝 칸에만 적용합니다.
- `endpointPillBorderRadius` — Flutter 는 이 값을 읽지 않습니다.
- `fadedOpacity` — Web 에서는 보이는 변화가 없습니다.
- `cellSpacing` — 날짜 격자에서는 줄 사이 간격만 바꿉니다. 날짜 칸 사이의 가로 간격은 없습니다. 월 격자의 줄 간격도 이 값이고, Web 은 월 · 연도 격자의 가로 간격에도 씁니다.
- `rangeSelectionTextStyle` · `weekdayLabelTextStyle` — 글자색(`color`)만 읽습니다. 글자 모양은 `cellTextStyle` · `weekdayTextStyle` 로 바꿉니다. 요일 줄의 색은 `weekdayTextStyle` 에 `color` 가 있으면 그 값이 우선합니다.
- `yearGridSize` — 연도 보기의 첫 구간은 기본값 16의 배수에서 시작합니다. 16 보다 작게 두면 첫 화면에 보던 연도가 없을 수 있습니다.
- `monthGridColumns` · `yearGridColumns` — 칸의 수(월은 12, 연도는 `yearGridSize`)를 나누어떨어지게 하는 값을 씁니다. 그렇지 않으면 그 보기를 열 때 오류가 납니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="calendar/related-date-picker" title="DatePicker">

입력 칸을 눌러 달력을 팝오버나 대화상자로 엽니다.

</Card>
<Card demo="calendar/related-time-picker" title="TimePicker">

날짜가 아니라 시각을 고릅니다.

</Card>
</Cards>
