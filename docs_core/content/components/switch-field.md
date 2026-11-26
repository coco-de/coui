---
title: SwitchField
description: 라벨과 설명이 붙은 스위치 한 줄입니다. 행 어디를 눌러도 켜고 끌 수 있고, 바로 반영되는 설정에 씁니다.
category: form
platforms: [flutter, web]
related: [toggle, checkbox, radio-group]
tags: [interactive, form-control, toggle]
template: v2
source: form/switch_field
---

# SwitchField

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

켜짐 · 설명 · 비활성을 바꿔 보며 스위치 필드를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="switch-field" />

스위치 필드는 값을 스스로 바꾸지 않습니다. 라벨 · 설명 · 토글 중 어디를 누르든 `onChanged(!value)` 를 부르므로, 호출자가 새 값을 `value` 로 다시 넘겨야 토글이 움직입니다.

<a id="기본"></a>
<a id="설명-포함"></a>

## 구조

스위치 필드는 라벨 열(라벨과 선택 사항인 설명)과 그 끝의 [Toggle](/components/toggle)로 이루어진 한 줄입니다. 행 전체가 하나의 누르는 영역입니다.

<Anatomy demo="switch-field/anatomy">
<AnatomyItem select="[role=button]" side="top" name="Container">

누르는 영역 전체. 라벨 · 설명 · 토글 어디를 눌러도 값이 바뀝니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

라벨. 설명과 함께 행의 이름으로 읽힙니다. `labelMaxLines` · `labelOverflow` 로 줄 수와 넘침을 정합니다.

</AnatomyItem>
<AnatomyItem select="label + div + div" side="left" name="description">

라벨 아래의 보조 문장. 선택 사항이고, 줄 수 제한 없이 줄을 바꿉니다.

</AnatomyItem>
<AnatomyItem select="[role=switch]" side="right" name="toggle">

켜짐 여부를 보여 주는 토글. 포인터를 받지 않아, 토글 위를 눌러도 행이 받습니다.

</AnatomyItem>
</Anatomy>

라벨 열은 남는 폭을 모두 차지하고 토글은 글이 끝나는 쪽 끝에 놓입니다. 긴 라벨이나 설명은 줄을 바꿀 뿐 토글을 밀어내지 않습니다. 라벨 열과 토글 사이는 12, 라벨과 설명 사이는 2 이고, 행의 내용은 세로 가운데에 놓입니다.

## 크기

토글의 크기는 위젯 속성이 아니라 `switchFieldStyle` 의 `size` 로 고릅니다. 기본은 `lg`(트랙 40 × 24, 썸 20)입니다 — 라벨과 설명 옆에 놓이는 설정 행의 컨트롤이라, 줄 안에 놓는 [Toggle](/components/toggle)의 기본(`md`)보다 한 단계 큽니다.

<Preview demo="switch-field/sizes" />

크기는 토글에만 닿습니다. 라벨과 설명의 글자, 라벨 열과 토글 사이 간격은 어느 크기에서나 같습니다. 크기마다의 트랙 · 썸 치수는 [Toggle 의 크기 표](/components/toggle#크기)를 따릅니다. Flutter 에서는 기본 크기의 한 줄 행이 트랙 높이 24 와 같습니다.

<Note>

`xs` 는 그대로 안쪽 토글에 넘어가 `sm` 으로 그려집니다. 이 크기는 없어질 예정이고, assert 가 켜진 실행(디버그 빌드, Jaspr 정적 빌드의 사전 렌더)에서 `Toggle` 의 이름으로 한 번 경고를 남깁니다. `sm` 을 쓰세요.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="변형-variants"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>

## 상태

스위치 필드에는 variant 가 없습니다. 켜짐 여부와 `enabled` 가 모양을 정합니다.

<Preview demo="switch-field/states" />

| 항목 | 동작 |
| --- | --- |
| 누를 때 | 행 어디를 누르든 `onChanged(!value)` 를 부릅니다. 토글은 호출자가 새 `value` 를 넘길 때 움직입니다. |
| 켜짐 · 꺼짐 | 켜지면 트랙이 `primary`, 꺼지면 `surfaceContainerHighest`(홀로 쓴 Toggle 의 꺼짐 트랙과 같은 색)입니다. 썸 색은 Toggle 의 기본값을 따릅니다. |
| 라벨 · 설명 | 라벨은 `labelLarge`(14 · Medium)에 `onSurface`, 설명은 `labelSmall`(12 · Medium · 행간 140%)에 `onSurfaceSubtle` 입니다. |
| Hover | 커서만 바뀝니다. 토글이 포인터를 받지 않으므로 트랙 위의 hover 표시도 없습니다. |
| 누르는 동안 크기 | 행 전체가 0.97배로 줄어듭니다. `switchFieldStyle.clickableStyle` 로 바꿀 수 있습니다. |
| Focus | 행에 키보드로 포커스하면 행 둘레에 링을 그립니다. `Tab` 으로 안쪽 토글까지 가면 토글이 트랙 둘레에 자기 링을 그립니다. |
| 비활성 | 라벨 `onSurfaceVariant`, 설명은 활성과 같은 `onSurfaceSubtle`, 토글은 Toggle 의 비활성 색입니다. 행 전체를 반투명하게 흐리지는 않습니다. 두 Tab 정지점이 모두 빠지고 커서는 금지 표시입니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onChanged` 가 있을 때 활성입니다. 토글과 같은 규칙입니다. |

<Note>

`enabled: true` 를 주고 `onChanged` 를 비우면 활성으로 보이고 포커스도 받지만, 눌러도 아무 일이 일어나지 않습니다. 읽기 전용으로 보여 줄 때는 `enabled` 를 적지 않거나 `enabled: false` 를 줍니다.

</Note>

### 전환 렌즈

안쪽 토글의 [전환 렌즈](/components/toggle#전환-렌즈)는 행을 눌러 바꿀 때 뜨지 않습니다. 행이 값을 바꾸면 토글은 그 값을 앱이 코드로 바꾼 값처럼 받기 때문입니다. 안쪽 토글에 키보드 포커스를 두고 `Space` · `Enter` 로 바꿀 때만 렌즈가 뜹니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 라벨 없이 트랙만 놓거나, 트랙 앞뒤에 아이콘 · 글자를 붙일 때 | [Toggle](/components/toggle) |
| 저장 · 제출을 눌러야 반영되는 선택, 여러 항목을 고르는 목록 | [Checkbox](/components/checkbox) |
| 일부만 고른 상태(불확정)가 필요할 때 | [Checkbox](/components/checkbox) |
| 서로 배타적인 선택지 중 하나를 고를 때 | [RadioGroup](/components/radio-group) |
| 두 아이콘이나 내용을 서로 바꿀 때 | [Swap](/components/swap) |

<a id="즉각-반영-vs-폼-제출"></a>

<Note>

스위치 필드는 값이 바뀌면 바로 `onChanged` 를 부르고, 언제 반영할지는 호출자가 정합니다. 사용자는 스위치를 켜는 순간 반영된다고 기대하므로, 설정 화면처럼 바로 반영되는 설정에 씁니다. 저장 버튼을 눌러야 반영되는 폼 안의 값이라면 체크박스가 그 기대에 맞습니다.

</Note>

<a id="do"></a>
<a id="dont"></a>

### 라벨 · 설명 · 반영 시점

<Cards columns="2">
<Card component="switch-field" props="value=true;description=앱을 쓰는 동안 위치를 써서 가까운 매장을 보여 드려요." label="위치 정보 사용" tone="do" eyebrow="이렇게 하세요">

설명으로 켰을 때 무엇이 달라지는지 알려 줍니다. 사용자가 결과를 알고 고를 수 있습니다.

</Card>
<Card component="switch-field" props="value=true" label="알림 끄기" tone="dont" eyebrow="이렇게 하지 마세요">

부정형 라벨은 켰을 때 이중 부정이 되어 헷갈립니다. "알림 받기" 처럼 켜짐이 곧 "켜졌다" 로 읽히게 씁니다.

</Card>
<Card demo="switch-field/settings" tone="do" eyebrow="이렇게 하세요">

바꾸는 즉시 반영되는 설정 목록에 씁니다.

</Card>
<Card component="checkbox" props="checked=true" label="이메일 수신" tone="do" eyebrow="대신 이렇게 하세요">

저장을 눌러야 반영되는 여러 항목의 선택에는 체크박스를 씁니다.

</Card>
<Card component="switch-field" props="value=true;enabled=false" label="베타 기능 사용" tone="do" eyebrow="이렇게 하세요">

바꾼 값을 서버에 저장하는 동안에는 `enabled: false` 로 막아 두 번 누르지 않게 합니다.

</Card>
<Card component="switch-field" props="value=false" label="계정 비활성화" tone="dont" eyebrow="이렇게 하지 마세요">

되돌리기 어려운 동작을 켜는 순간 실행하지 않습니다. 계정 비활성화 · 데이터 초기화는 [Dialog](/components/dialog)로 한 번 확인받습니다.

</Card>
</Cards>

## 배치

스위치 필드는 부모의 폭을 채우는 한 줄입니다. 설정 목록처럼 여러 개를 세로로 쌓아 씁니다.

<Preview demo="switch-field/settings" />

Flutter 는 라벨 열을 `Expanded` 로 두므로 폭이 정해진 부모 안에 놓아야 합니다 — 가로 폭이 정해지지 않은 자리(다른 `Row` 의 바로 아래)에 두면 레이아웃 오류가 나고 그려지지 않습니다. Jaspr Web 은 컨테이너의 폭을 채웁니다(`w-full`).

<a id="조합-예제"></a>

### 설정 묶음

관련된 설정은 [Fieldset](/components/fieldset)으로 묶어 제목을 붙입니다.

<Code language="dart" title="Fieldset 으로 묶기">
Fieldset(
  legend: Text('알림 설정').titleSmall.onSurface,
  children: [
    SwitchField(
      value: pushEnabled,
      onChanged: setPushEnabled,
      label: '푸시 알림',
      description: '새 메시지와 업데이트를 알려 드려요.',
    ),
    SwitchField(
      value: emailEnabled,
      onChanged: setEmailEnabled,
      label: '이메일 알림',
      description: '주간 요약과 중요한 공지를 이메일로 받습니다.',
    ),
  ],
)
</Code>

## 테마와 스타일

토글 크기 · 트랙 색 · 간격 · 글자 · 누르는 동작 · 행의 최소 높이처럼 보이는 값은 `switchFieldStyle`(`CoreSwitchFieldStyle`) 하나로 덮어씁니다. 겉모습을 바꾸는 낱개 파라미터는 없습니다.

<Split>

<Code language="dart" title="스위치 필드 하나만 바꾸기">
SwitchField(
  label: '자동 저장',
  value: autoSave,
  onChanged: setAutoSave,
  switchFieldStyle: CoreSwitchFieldStyle(
    size: CoreComponentSize.xl,
    activeColor: CoreColor.token(CoreColors.success),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    switchField: CoreSwitchFieldTheme(
      style: CoreSwitchFieldStyle(
        minHeight: CoreA11ySize.touchTarget,
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

트랙 색은 스위치 필드가 안쪽 토글의 `toggleStyle` 로 넘깁니다. 그래서 앱 전체 Toggle 테마(`CoreComponentTheme.toggle`)에 준 트랙 색은 스위치 필드 안에서 보이지 않습니다 — 스위치 필드의 트랙 색은 `activeColor` · `inactiveColor` 로 바꿉니다. 썸 색처럼 그 밖의 토글 값은 Toggle 테마를 따르고, 비활성일 때는 두 트랙 색 대신 Toggle 의 비활성 색이 쓰입니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `SwitchField` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `switchFieldStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SwitchFieldChainExample extends StatefulWidget {
  const SwitchFieldChainExample({super.key});

  @override
  State<SwitchFieldChainExample> createState() => _SwitchFieldChainExampleState();
}

class _SwitchFieldChainExampleState extends State<SwitchFieldChainExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchField(
      label: '알림 받기',
      description: '푸시 알림을 받아요.',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreSwitchFieldStyle(
        labelToggleGapStyle: CoreGapStyle(size: CoreSpace.space24),
        labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
        activeColor: CoreColor.token(CoreColors.success),
        labelTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SwitchFieldChainExample extends StatefulComponent {
  const SwitchFieldChainExample({super.key});

  @override
  State<SwitchFieldChainExample> createState() => _SwitchFieldChainExampleState();
}

class _SwitchFieldChainExampleState extends State<SwitchFieldChainExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return SwitchField(
      label: '알림 받기',
      description: '푸시 알림을 받아요.',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreSwitchFieldStyle(
        labelToggleGapStyle: CoreGapStyle(size: CoreSpace.space24),
        labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
        activeColor: CoreColor.token(CoreColors.success),
        labelTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
기본값 (default*)
  → CoreComponentTheme.switchField.style   // 앱 전체
  → switchFieldStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. variant 가 없어 테마에는 `style` 하나뿐입니다. 이렇게 정해진 두 값은 안쪽 토글에 다르게 넘어갑니다.

- **트랙 색**은 토글의 `toggleStyle` 로 넘어갑니다. 토글 순서의 맨 뒤(인스턴스 값)라 Toggle 테마의 트랙 색을 이깁니다.
- **`size`** 는 토글의 `size` 로 넘어가 토글의 크기 행을 고릅니다. 크기 행은 [토글 순서](/components/toggle#값이-정해지는-순서)의 맨 앞(기본값)이라, 앱 전체 Toggle 테마가 트랙 폭 · 높이 · 썸 크기를 적으면 그 치수가 이 `size` 를 이깁니다.

라벨과 설명 글자는 활성 여부에 따라 고른 기본값 위에 테마와 인스턴스의 글자 값이 얹힙니다. 비활성일 때는 `labelTextStyle` · `descriptionTextStyle` 이 아니라 `disabledLabelTextStyle` · `disabledDescriptionTextStyle` 만 얹힙니다.

<a id="접근성-accessibility"></a>

## 접근성

`SwitchField` 는 접근성 정보를 직접 붙이지 않고, 합성한 두 컴포넌트에서 받습니다 — 행 전체의 `Clickable` 이 버튼 역할을, 안쪽 Toggle 이 스위치 역할과 켜짐 여부를 붙입니다. Jaspr Web 에서는 그 스위치가 버튼 요소 안에 들어 있어, 켜짐 상태가 읽히지 않을 수 있습니다(아래 "알려진 제약").

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 행 전체의 `Clickable` 이 `Semantics(button: true)` 로 버튼을 알리고, 비활성이면 비활성으로 알립니다. 켜짐 여부는 안쪽 Toggle 이 `Semantics(toggled:)` 로 붙입니다. `SwitchField` 자신에는 `Semantics` 가 없습니다. |
| Jaspr Web | 행 전체가 `<div role="button">` 입니다 — 활성이면 `tabindex="0"`, 비활성이면 `tabindex` 없이 `aria-disabled="true"` 입니다. `role="switch"` 와 `aria-checked` 는 그 안에 든 안쪽 토글의 요소에 붙고(활성 `tabindex="0"`, 비활성 `tabindex="-1"` · `aria-disabled="true"`), 트랙은 `aria-hidden="true"` 입니다. |

라벨은 Jaspr Web 에서 `<label>` 요소로 그려지지만 `for` 가 없어 어떤 컨트롤과도 연결되지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 켜고 끕니다. 키를 누를 때 바뀝니다. 행에 포커스가 있든 안쪽 토글에 있든 한 번만 바뀝니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. 스위치 필드 하나에서 행과 안쪽 토글, 두 번 멈춥니다. |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

활성화 키는 두 플랫폼 모두 `Clickable` 이 받습니다 — Flutter 는 `Enter` · `Space` 를 `ActivateIntent` 로, Jaspr Web 은 `keydown` 에서 받습니다. Jaspr Web 의 행은 키가 자기 자신에게 눌렸을 때만 반응하므로, 안쪽 토글에서 누른 키가 행까지 올라가 두 번 바뀌는 일은 없습니다.

<Note>

화살표로 켜고 끄는 조작은 없습니다. 비활성 필드는 행과 안쪽 토글 모두 포커스 순서에서 빠집니다.

</Note>

### 스크린 리더

- **이름**: 라벨과 설명 글자는 행(버튼)의 내용으로 함께 읽힙니다. 켜짐 상태를 가진 안쪽 스위치에는 자기 이름이 없습니다 — 스위치 필드가 토글에 `label` · `prefix` · `suffix` 를 넘기지 않기 때문입니다.
- **상태**: 켜짐 · 꺼짐은 안쪽 토글에 실립니다(Flutter `Semantics(toggled:)`, Jaspr Web `aria-checked`). Jaspr Web 에서는 그 요소가 행의 `role="button"` 안에 있어, 브라우저 · 스크린 리더에 따라 켜짐 상태가 읽히지 않을 수 있습니다. 비활성은 행과 안쪽 토글 모두에 붙습니다.
- **알림**: 값이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.

스위치 필드 하나가 Tab 정지점을 둘 만듭니다 — 행 전체와 안쪽 토글. 안쪽 토글은 포인터만 막혀 있고(Flutter `IgnorePointer`, Jaspr Web `pointer-events: none`) 포커스 순서에서는 빠지지 않으며, 그것을 끌 파라미터는 없습니다. 두 정지점 모두 `Space` · `Enter` 로 바뀝니다.

포커스 링은 키보드로 포커스했을 때만 나타납니다 — 행에서는 행 둘레에, 안쪽 토글에서는 트랙 둘레에(Jaspr Web 의 강제 색상 모드는 아래 "알려진 제약"). Jaspr Web 은 행을 마우스로 눌러도 행에 포커스가 가지만 링은 보이지 않습니다. Flutter 는 눌러도 포커스를 옮기지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 켜짐 상태를 가진 `role="switch"` 요소가 행의 `role="button"` 안에 있습니다. WAI-ARIA 는 버튼 안의 요소를 버튼의 내용으로만 다루므로, 브라우저 · 스크린 리더에 따라 안쪽 스위치의 역할과 `aria-checked` 를 읽지 않을 수 있습니다 — 포커스를 받는 요소가 다른 누르는 요소 안에 든 구조입니다. |
| 공통 | 스위치 필드 하나가 같은 일을 하는 Tab 정지점 둘을 만듭니다. 안쪽 토글을 포커스 순서에서 뺄 방법이 없습니다. |
| 공통 | `description` 이 보조 설명(`aria-describedby` · `Semantics(hint:)`)으로 연결되지 않고, 행 이름의 일부로 함께 읽힙니다. |
| 공통 | 행의 이름을 따로 정하거나 설명을 연결할 진입점이 없습니다. Flutter 는 호출부에서 `Semantics` 로 감싸는 우회가 있고, Jaspr Web 은 없습니다. |
| Jaspr Web | 생성자가 `key` · `id` 밖의 속성(`attributes` · `classes` · `css` · 이벤트)을 받지 않고, `copyWith` 에 준 `attributes` · `classes` · `css` 는 버려집니다. `aria-label` 같은 속성을 실을 수 없습니다. |
| 공통 | `enabled: true` 를 주고 `onChanged` 를 비우면, 아무 일도 하지 않는 정지점 두 개가 남습니다. |
| 공통 | `Space` · `Enter` 를 누르고 있으면 키가 반복될 때마다 다시 바뀝니다. |
| 공통 | 행을 눌러 바꾸면 안쪽 토글의 전환 렌즈가 뜨지 않습니다(위 "전환 렌즈"). |
| Flutter | `sm` · `md` 크기에서는 한 줄 행이 20 으로 24 보다 낮습니다(아래 "누르는 영역의 높이"). |
| Jaspr Web | 강제 색상(고대비) 모드에서는 안쪽 토글의 포커스 링이 트랙이 아니라 토글 요소 전체에 그려집니다 — [Toggle 의 알려진 제약](/components/toggle#알려진-제약)과 같습니다. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 언어에서 안쪽 토글의 썸은 [Toggle 의 알려진 제약](/components/toggle#알려진-제약)을 그대로 따릅니다. |

<a id="터치-타깃-눌림-영역-최소-높이"></a>

#### 누르는 영역의 높이

라벨 · 설명 · 토글을 포함한 행 전체가 하나의 누르는 영역이지만, 행 둘레의 누르는 영역을 따로 넓히지는 않습니다. 기본값은 바닥이 없어(`minHeight` 0) 행이 내용 높이 그대로입니다. Flutter 에서 기본 크기 `lg` 의 한 줄 행은 트랙 높이 24 와 같지만, `sm` · `md` 를 고르면 한 줄 행이 라벨 한 줄 높이(20)로 낮아집니다.

터치 화면에서 48 이 필요한 앱은 테마로 바닥을 켭니다(위 "앱 전체 기본값 바꾸기") — 행이 그 높이 이상이 되고 내용은 가운데에 놓이며, 늘어난 높이까지 눌립니다. Flutter 는 이 값에 화면 배율(`scaling`)을 곱하고, Jaspr Web 은 행의 `min-height` 를 rem 으로 내보내 브라우저 글자 크기를 따릅니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>
<a id="수용된-호환-예외와-공통-호출"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 행의 구성 | `Clickable` 안의 `Row`. 라벨 열은 `Expanded`, 토글은 `IgnorePointer` 안 | `Clickable` 의 `<div role="button">` 안의 flex `<div>`. 라벨 열은 `flex-1`, 토글은 `pointer-events: none` 상자 안 |
| 버튼 · 켜짐 상태 | `Semantics(button: true)` · 안쪽 Toggle 의 `Semantics(toggled:)` | `role="button"` 안에 든 안쪽 토글의 `role="switch"` · `aria-checked` — 켜짐 상태가 읽히지 않을 수 있습니다(알려진 제약) |
| 라벨 · 설명 요소 | `Text` 두 개 | `<label>` · `<div>` |
| 폭 | 부모가 폭을 정해야 합니다 | 컨테이너 폭을 채웁니다(`w-full`) |
| 마우스로 눌렀을 때 포커스 | 옮기지 않습니다 | 행으로 옮깁니다(링은 없음) |
| `minHeight` | 화면 배율(`scaling`)을 곱합니다 | rem 으로 내보내 브라우저 글자 크기를 따릅니다 |
| `value` · `onChanged` | 둘 다 넘겨야 합니다 | 생략하면 `false` · `null` 입니다 |
| `const` 생성자 | 있습니다 | 없습니다 |

Jaspr Web 이 `value` · `onChanged` 를 생략하게 해 주는 것은 기존 호출을 깨지 않으려고 받아들인 차이입니다. 두 플랫폼에서 같은 코드를 쓰려면 둘 다 적습니다.

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 값과 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 라벨. 설명과 함께 행의 이름으로 읽힙니다. |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리(`clip` · `fade` · `ellipsis` · `visible`) |
| `description` | `String?` | `null` | 라벨 아래의 보조 문장 |
| `value` | `bool` | 필수 (Web 은 `false`) | 켜짐 여부 |
| `onChanged` | `ValueChanged<bool>?` (Web 은 `CoreValueChanged<bool>?`) | 필수 (Web 은 `null`) | 반대 값을 받습니다. 값은 호출자가 반영합니다. 두 타입 모두 `bool` 하나를 받는 함수입니다. |

### 상태와 겉모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onChanged` 유무로 정합니다. |
| `switchFieldStyle` | `CoreSwitchFieldStyle?` | `null` | 보이는 값 덮어쓰기. 토글 크기(`size`)도 여기서 고릅니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSwitchFieldStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `size` | `CoreComponentSize?` | Toggle size within the switch field. Forwarded to the composed `Toggle` as is, so `xs` is retiring here too (`CoreToggleContract.retiringSizes`) — the notice names `Toggle`. |
| `labelToggleGapStyle` | `CoreGapStyle?` | Horizontal gap between the label section and the toggle. Laid over [defaultLabelToggleGapStyle]. |
| `labelDescriptionGapStyle` | `CoreGapStyle?` | Vertical gap between the label and the description inside the label section. Laid over [defaultLabelDescriptionGapStyle]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the field's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is. |
| `minHeight` | `double?` | Minimum height of the pressable row — label, description and toggle together — before scaling. The row's content is centred in the extra height, and the whole row stays the press area, so a theme can give every labelled switch a touch target (for example `CoreA11ySize.touchTarget`). Falls back to [defaultMinHeight]. |
| `activeColor` | `CoreColor?` | Active (on) track colour. |
| `inactiveColor` | `CoreColor?` | Inactive (off) track colour. |
| `labelTextStyle` | `CoreTextStyle?` | Label text style when enabled (typography + colour). Laid over [defaultLabelTextStyle]. |
| `disabledLabelTextStyle` | `CoreTextStyle?` | Label text style when disabled. Laid over [defaultDisabledLabelTextStyle]. |
| `descriptionTextStyle` | `CoreTextStyle?` | Description text style when enabled. Laid over [defaultDescriptionTextStyle]. |
| `disabledDescriptionTextStyle` | `CoreTextStyle?` | Description text style when disabled. Laid over [defaultDisabledDescriptionTextStyle]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="toggle" props="value=true" label="알림 받기" title="Toggle">

라벨 없이 트랙만, 또는 트랙 앞뒤에 아이콘 · 글자를 붙인 스위치입니다.

</Card>
<Card component="checkbox" props="checked=true" label="동의합니다" title="Checkbox">

저장한 뒤 반영되는 선택과 여러 항목을 고르는 목록에 씁니다.

</Card>
<Card component="radio-group" props="options=2" title="RadioGroup">

서로 배타적인 선택지 중 하나를 고를 때 씁니다.

</Card>
</Cards>
