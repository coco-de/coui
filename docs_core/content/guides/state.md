---
title: 상태 제어
description: 폼과 인터랙티브 컴포넌트가 값을 다루는 패턴입니다. Controlled는 Flutter와 Web에서 같게 동작합니다.
design: true
---

# 상태 제어

## Controlled

부모가 값을 소유하고 onChanged로 갱신받는 기본 패턴입니다. 대부분의 폼 컴포넌트가 이 형태입니다.

<Code language="dart" title="Flutter · Web">
StarRating(
  value: rating,
  onChanged: (v) => setState(() => rating = v),
)
</Code>

> enabled는 핸들러가 있는지로 정해집니다. onChanged가 null이면 컴포넌트가 자동으로 비활성화됩니다.

## Controller

값을 코드에서 바꾸거나 폼, 리액티브 시스템과 묶을 때 씁니다. 아래 컨트롤러는 Flutter에 있습니다.

<Code language="dart" title="Flutter">
final controller = CheckboxController(CheckboxState.unchecked);
controller.addListener(() => print(controller.value));
controller.value = CheckboxState.checked;
</Code>

대표 예: `CheckboxController`, `CarouselController`, `ControlledStarRating`, `ControlledDatePicker`, `ComponentValueController`

## 트리 공유: Data.inherit

부모가 자식 트리로 상태를 내려줄 때 씁니다. 예를 들어 버튼 그룹이 하위 버튼에 상태를 전달합니다.

> rebuild에 영향을 주는 모든 필드를 ==와 hashCode에 넣어야 자식이 정확히 갱신됩니다.

```dart
class GroupState {
  const GroupState({required this.selected, required this.enabled});

  final int selected;
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is GroupState && other.selected == selected && other.enabled == enabled;

  @override
  int get hashCode => Object.hash(selected, enabled);
}

// 부모 — 자식 트리에 상태를 내려 준다
Data.inherit(
  data: GroupState(selected: index, enabled: true),
  child: buttons,
)

// 자식 — 가장 가까운 부모의 상태를 읽는다
final state = Data.of<GroupState>(context);
```

Data.inherit은 Flutter의 이름입니다. Web은 jaspr의 InheritedComponent로 같은 일을 합니다.

## 고르는 기준

| 상황 | 패턴 |
|---|---|
| 값 하나를 화면 상태로 다룰 때 | `Controlled` |
| 코드에서 값을 바꾸거나 리스너가 필요할 때 | `Controller` |
| 여러 자식이 같은 상태를 읽을 때 | `Data.inherit` |
