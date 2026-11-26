---
title: Sortable
description: 끌거나 키보드로 옮겨 순서를 바꾸는 목록입니다. 할 일이나 메뉴처럼 사용자가 순서를 직접 정하는 곳에 씁니다.
category: form
platforms: [flutter, web]
related: [table, tree]
tags: [interactive, drag-drop, reorder]
template: v2
source: form/sortable
---

# Sortable

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

축 · 제거 버튼 · 비활성을 바꿔 보며 목록을 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기에서는 핸들을 끌어 순서를 바꿔 볼 수 있습니다.

<Playground component="sortable" />

`Sortable`은 데이터를 바꾸지 않습니다. 핸들을 놓아 자리가 바뀌면 `onReorder(oldIndex, newIndex)`를, 제거 버튼을 누르면 `onRemove(index)`를 부릅니다. 목록을 고쳐 다시 그리는 것은 호출자의 일입니다. 인덱스는 0부터 셉니다.

`newIndex`는 옮기는 항목을 먼저 뺀 목록에 넣을 자리입니다. `removeAt` 다음에 그대로 `insert`하면 되고, 1을 빼는 보정은 필요 없습니다.

```dart
void reorderTasks(int oldIndex, int newIndex) {
  setState(() {
    final next = [...tasks];
    next.insert(newIndex, next.removeAt(oldIndex));
    tasks = next;
  });
}
```

제거 버튼을 켠 코드의 `removeTask`는 [제거 가능한 항목](#제거-가능한-항목)에 있습니다.

## 구조

`Sortable`은 목록과 행의 상자를 그립니다. 행 안의 배치는 `itemBuilder`가 정합니다. `Sortable`이 만든 드래그 핸들과 제거 버튼을 받아 원하는 자리에 놓습니다.

<Anatomy demo="sortable/anatomy">
<AnatomyItem part="container" name="Container">

목록. 행을 `axis` 방향으로 놓고 `itemSpacing`(기본 8)만큼 띄웁니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem]" side="left" name="item">

행 하나의 상자. 배경, 테두리, 모서리, 안쪽 여백, 최소 높이를 `Sortable`이 그립니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="dragHandle">

끌기를 시작하는 곳이자 키보드로 옮기는 곳입니다. `LucideIcons.gripVertical` 아이콘을 두 플랫폼이 같이 씁니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="content">

`itemBuilder`가 넣은 내용입니다. 글자는 행의 기본 글자 모양을 물려받습니다.

</AnatomyItem>
<AnatomyItem part="trailing" side="right" name="removeButton">

제거 버튼. `removable: true`와 `onRemove`를 함께 주면 생깁니다.

</AnatomyItem>
</Anatomy>

### 항목 빌더

`itemBuilder`는 항목마다 아래 인자를 받아 행 안에 놓을 위젯 하나를 돌려줍니다.

| 인자 | 타입 | 설명 |
| --- | --- | --- |
| `context` | `BuildContext` | Flutter 빌더에만 있습니다. |
| `index` | `int` | 항목의 자리. 0부터 셉니다. |
| `dragHandle` | `Widget` · `Component` | 드래그 핸들. 원하는 자리에 놓습니다. |
| `removeButton` | `Widget?` · `Component?` | 제거 버튼. `removable: true`이고 `onRemove`가 있을 때만 들어오고, 아니면 `null`입니다. |

세로 목록은 글자가 남는 폭을 채우게 둡니다. Flutter는 `Expanded`를, 웹은 `flex-1`을 씁니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Sortable(
  itemCount: tasks.length,
  onReorder: reorderTasks,
  itemBuilder: (context, index, dragHandle, removeButton) => Row(
    spacing: CoreSpace.space8,
    children: [
      dragHandle,
      Expanded(child: Text(tasks[index])),
      ?removeButton,
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Sortable(
  itemCount: tasks.length,
  onReorder: reorderTasks,
  itemBuilder: (index, dragHandle, removeButton) => div(
    [
      dragHandle,
      div([Text(tasks[index])], classes: 'flex-1'),
      ?removeButton,
    ],
    classes: 'flex flex-1 items-center gap-${CoreSpace.scale.space8}',
  ),
)
```

  </TabItem>
</Tabs>

<Note>

`dragHandle`을 행에 놓지 않으면 행 전체가 끌리는 영역이 되고, 키보드로는 순서를 바꿀 수 없습니다. 늘 행 안에 놓으세요.

</Note>

## 축

`axis`로 목록이 놓이는 방향을 고릅니다. 타입은 `CoreSortableAxis`이고 기본값은 `vertical`입니다.

<VariantRow name="vertical" component="sortable" props="axis=vertical">

위에서 아래로 쌓고, 행이 목록 폭을 채웁니다. 세로로만 끌리며, 끌리는 항목의 중심이 이웃의 중심을 지나면 놓일 자리가 바뀝니다.

</VariantRow>

<VariantRow name="horizontal" component="sortable" props="axis=horizontal">

한 줄에 가로로 놓고, 자리가 넉넉하면 행은 내용만큼의 폭을 씁니다. 가로로만 끌립니다. 목록이 스스로 줄을 바꾸거나 스크롤하지 않습니다.

</VariantRow>

<VariantRow name="grid" component="sortable" props="axis=grid">

폭에 맞춰 줄을 바꿉니다. 두 방향으로 끌 수 있고, 끌리는 항목의 중심에서 가장 가까운 칸이 놓일 자리입니다.

</VariantRow>

`horizontal`과 `grid`에서는 Flutter `itemBuilder`의 `Row`에 `mainAxisSize: MainAxisSize.min`을 두고 `Expanded`를 넣지 않습니다. 특히 `horizontal`은 행이 받는 폭이 정해지지 않아 `Expanded`가 레이아웃 오류를 냅니다.

Flutter의 `horizontal` 목록은 높이가 정해진 부모 안에서는 행이 그 높이를 다 채웁니다. 행을 내용 높이로 두려면 `Column(mainAxisSize: MainAxisSize.min)`으로 감싸 높이를 열어 두고, 정한 높이로 두려면 `SizedBox`로 감쌉니다.

<Note>

Flutter의 `grid`는 폭이 정해진 곳에서 행 상자가 그 폭을 다 차지해, 항목이 한 줄에 하나씩 놓입니다. 자세한 내용은 [알려진 제약](#알려진-제약)을 보세요. 화면에 있는 목록의 `axis`를 바꿀 때는 `key: ValueKey(axis)`를 함께 주어 목록을 새로 만듭니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="커서"></a>

## 상태

<Preview demo="sortable/states" />

| 상태 | 행 배경 · 테두리 | 핸들 | 행 글자 · 제거 아이콘 |
| --- | --- | --- | --- |
| 기본 | `surface` · `outlineVariant` | `onSurfaceSubtle` | `onSurface` · `onSurfaceVariant` |
| Hover | 배경만 `surfaceContainerHigh` | 기본과 같음 | 기본과 같음. 제거 버튼 위에서는 [플랫폼마다 다릅니다](#제거-가능한-항목). |
| 비활성 (`enabled: false`) | `disabledContainer` · `disabledOutline` | `disabledContent` | 둘 다 `disabledContent`. 단, Flutter에서 제거 버튼에 포인터를 올리면 아이콘이 `onSurface`가 됩니다. |

비활성은 불투명도를 낮추지 않고 전용 색으로 그립니다. `itemBuilder` 안의 글자에 색을 직접 주면 비활성 색이 닿지 않습니다.

| 항목 | 동작 |
| --- | --- |
| 순서를 바꿀 수 있는 조건 | `enabled: true`이고 `onReorder`가 있을 때입니다. 아니면 핸들은 아이콘으로만 그려지고, 끌기 · 포커스 · 키 조작이 없습니다. |
| 끌기 시작 | 핸들을 누른 채 움직이면 시작합니다. 길게 누를 필요가 없습니다. Flutter에서 세로로 스크롤되는 영역 안의 터치 끌기는 [알려진 제약](#알려진-제약)을 보세요. |
| 끌리는 항목 | 포인터를 따라가며 1.02배(`proxyScale`)로 커지고 높이 6(`proxyElevation`)의 그림자를 받습니다. |
| 나머지 항목 | 놓일 자리를 비우며 `animationDuration`(기본 250ms) 동안 옮겨 갑니다. 동작 줄이기를 켜면 바로 옮깁니다. |
| 놓기 | 자리가 바뀌었을 때만 `onReorder`를 부릅니다. |
| 취소 | 시스템이 포인터를 가져가면(`pointercancel`) 원래 자리로 돌아가고 `onReorder`를 부르지 않습니다. 키보드로 옮기는 중에는 `Escape`로 취소합니다. |
| 가장자리 자동 스크롤 | 끄는 동안 포인터가 바깥 스크롤 영역의 가장자리 48 안에 들어오면 그 영역을 스크롤합니다. 대상 영역은 [플랫폼마다 다릅니다](#플랫폼-차이). |
| 핸들 커서 | 웹은 `grab`, 누르는 동안 `grabbing`이고, 끄는 동안에는 목록의 커서도 `grabbing`입니다. Flutter는 `grab`이고 비활성 목록에서는 기본 커서입니다. |

<a id="제거-가능한-항목-removable-items"></a>

## 제거 가능한 항목

`removable: true`와 `onRemove`를 **함께** 주면 행마다 제거 버튼을 만들어 `itemBuilder`의 `removeButton`으로 넘깁니다. 둘 중 하나라도 없으면 `removeButton`은 `null`입니다. 버튼은 `Button(variant: .plain, size: .sm, shape: .square)`이고, 32 × 32 상자에 16짜리 아이콘(`LucideIcons.x`)을 그립니다. 포커스 링은 `Button`이 그립니다.

기본 스타일에서 제거 버튼에 포인터를 올리면 Flutter는 아이콘이 `onSurface`가 되고, 비활성 목록에서도 같습니다. 웹은 색이 바뀌지 않습니다.

<Preview component="sortable" props="removable=true" />

`Sortable`은 항목을 지우지 않습니다. `onRemove`가 알려 주는 인덱스를 빼고 다시 그립니다. `buildTaskRow`는 [항목 빌더](#항목-빌더)처럼 `removeButton`을 행에 놓는 함수입니다.

```dart
void removeTask(int index) {
  setState(() {
    tasks = [
      ...tasks.sublist(0, index),
      ...tasks.sublist(index + 1),
    ];
  });
}

Sortable(
  itemCount: tasks.length,
  onReorder: reorderTasks,
  removable: true,
  onRemove: removeTask,
  itemBuilder: buildTaskRow,
)
```

<Note>

`enabled: false`인 목록에서도 제거 버튼은 눌리고 `onRemove`가 불립니다. 제거 버튼에서 달라지는 것은 평소 색뿐이고, Flutter에서는 포인터를 올리면 활성 목록과 같은 `onSurface`가 됩니다. 지우지 못하게 하려면 `removable: false`로 두세요.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 언제 쓰나

- 사용자가 항목의 우선순위나 순서를 직접 정할 때 (할 일 목록, 메뉴 순서)
- 대시보드 위젯이나 사이드바 메뉴의 순서를 사용자가 바꾸게 할 때
- 카테고리나 태그가 보이는 순서를 관리자가 정할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 순서를 바꿀 필요 없이 데이터를 표로 보여 줄 때 | [Table](/components/table) |
| 항목에 부모와 자식 계층이 있을 때 | [Tree](/components/tree) |
| 순서가 정해진 행과 열의 목록 | [Listing](/components/listing) |
| 순서가 아니라 pane의 크기를 바꿀 때 | [Resizable](/components/resizable) |
| 셀을 화면 폭에 맞춰 배치만 할 때 | [ResponsiveGrid](/components/responsive-grid) |
| 한 목록 밖으로 옮기거나, 놓는 영역(칸반, 휴지통)을 만들 때 | [Drag](/components/drag) |

### 항목과 콜백

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="sortable/do-labeled" tone="do" eyebrow="이렇게 하세요">

항목마다 읽을 수 있는 글자를 넣습니다. 핸들과 제거 버튼의 이름은 항목의 내용을 말하지 않아, 행을 구분하는 글자는 `itemBuilder`가 넣은 것뿐입니다.

</Card>
<Card demo="sortable/dont-icon-only" tone="dont" eyebrow="이렇게 하지 마세요">

아이콘만으로 항목을 만들지 않습니다. 스크린 리더 사용자는 어느 항목인지 알 수 없습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

제거 버튼을 쓸 때는 `removable: true`와 `onRemove`를 함께 줍니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

`removable: true`만 주지 않습니다. 버튼이 만들어지지 않아, 코드에서는 켠 것처럼 보여도 화면에는 아무것도 없습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

행 안의 입력값이나 펼침 상태는 목록 바깥에 데이터와 함께 둡니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

행 안 위젯이 스스로 상태를 들고 있게 하지 않습니다. 항목은 자리로 구분하므로 상태가 데이터를 따라가지 않습니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`axis` · `enabled` · `removable`은 위젯 속성으로 고르고, 색 · 간격 · 모서리 · 글자처럼 보이는 값은 `sortableStyle`(`CoreSortableStyle`) 하나로 덮어씁니다. 앱 전체 기본값은 `CoreComponentTheme.sortable`에 둡니다.

<a id="테마-커스터마이징-theme-customization"></a>

<Split>

<Code language="dart" title="목록 하나만 바꾸기">
Sortable(
  itemCount: tasks.length,
  onReorder: reorderTasks,
  itemBuilder: buildTaskRow,
  sortableStyle: const CoreSortableStyle(
    itemSpacing: CoreSpace.space12,
    handleColor: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    sortable: CoreSortableTheme(
      style: CoreSortableStyle(
        itemBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        handleColor: CoreColor.token(CoreColors.onSurfaceVariant),
        itemSpacing: CoreSpace.space12,
      ),
    ),
  ),
)
</Code>

</Split>

<a id="모양"></a>

### 기본값

| 부분 | 기본값 |
| --- | --- |
| 행 상자 | 최소 높이 48(`lg` 컨트롤 행, 내용이 크면 늘어납니다), 모서리 12, 테두리 1 `outlineVariant` |
| 행 안쪽 여백 | 글이 시작하는 쪽 12, 끝나는 쪽 8, 위아래 0. 내용은 세로 가운데에 놓입니다. |
| 행 사이 | 8 |
| 행 글자 | `bodyLarge`의 값(15, 줄 높이 150%, Regular), `onSurface` |
| 드래그 핸들 | 아이콘 16, 안쪽 여백 0, `onSurfaceSubtle` |
| 제거 버튼 | 32 × 32, 모서리 8, 아이콘 16, `onSurfaceVariant` |
| 끌리는 항목 | 1.02배, 그림자 높이 6 |
| 전환 시간 | 250ms |

### 안쪽 부품의 스타일

| 바꿀 것 | 읽는 값 (앞의 것이 이깁니다) |
| --- | --- |
| 핸들 색 | `handleStyle.foregroundColor` → `handleColor` → 기본값. 비활성 목록은 `disabledHandleColor`를 씁니다. |
| 핸들 안쪽 여백 | `handleStyle.padding` → `handlePadding` → 0 |
| 핸들 포커스 링 | `handleStyle.focusOutlineStyle` |
| 제거 버튼 | `removeButtonStyle` → `removeButtonColor` · `removeButtonBorderRadius` · `removeButtonSize` → 기본값. 비활성 목록의 아이콘 색은 `disabledForegroundColor`가 덮습니다. 단, `iconStyle.color`나 `removeButtonStyle.leadingIconStyle.color`를 주면 두 플랫폼 모두 제거 아이콘이 그 색이 되고, 비활성 목록에서도 그 색이 남습니다. |
| 두 아이콘의 크기 | `iconStyle`의 `size`. 제거 아이콘은 `removeButtonStyle.leadingIconStyle`의 `size`가 있으면 그것이 먼저입니다. |
| 전환 시간 | `removeButtonStyle.animationDuration` → `handleStyle.animationDuration` → `animationDuration` → 250ms. 앞의 두 값을 주면 항목이 옮겨 가는 시간과 행 색이 바뀌는 시간도 그 값이 됩니다. |

핸들은 버튼이 아니라 아이콘으로 그립니다. `handleStyle`에서는 `foregroundColor` · `padding` · `focusOutlineStyle` · `animationDuration` 네 가지만 읽습니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreSortableStyle.defaultX                // 디자인 시스템 기본값
  → CoreComponentTheme.sortable.style     // 앱 전체
  → sortableStyle                         // 인스턴스
```

### 빠른 오버라이드 (Chain)

이미 만든 `Sortable` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다.

<Preview component="sortable" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SortableChainExample extends StatefulWidget {
  const SortableChainExample({super.key});

  @override
  State<SortableChainExample> createState() => _SortableChainExampleState();
}

class _SortableChainExampleState extends State<SortableChainExample> {
  List<String> _items = const ['항목 1', '항목 2', '항목 3'];

  void handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final newItems = [..._items];
      final item = newItems.removeAt(oldIndex);
      newItems.insert(newIndex, item);
      _items = newItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sortable(
      itemCount: _items.length,
      onReorder: handleReorder,
      itemBuilder: (context, index, dragHandle, removeButton) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            dragHandle,
            Text(_items[index]),
          ],
        );
      },
    ).withStyle(
      const CoreSortableStyle(
        itemBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space12,
        ),
        handleColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SortableChainExample extends StatefulComponent {
  const SortableChainExample({super.key});

  @override
  State<SortableChainExample> createState() => _SortableChainExampleState();
}

class _SortableChainExampleState extends State<SortableChainExample> {
  List<String> _items = const ['항목 1', '항목 2', '항목 3'];

  void handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final newItems = [..._items];
      final item = newItems.removeAt(oldIndex);
      newItems.insert(newIndex, item);
      _items = newItems;
    });
  }

  @override
  Component build(BuildContext context) {
    return Sortable(
      itemCount: _items.length,
      onReorder: handleReorder,
      itemBuilder: (index, dragHandle, removeButton) => div(
        [
          dragHandle,
          span([Text(_items[index])]),
        ],
        classes: 'flex items-center flex-1 gap-${CoreSpace.scale.space8}',
      ),
    ).withStyle(
      const CoreSortableStyle(
        itemBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space12,
        ),
        handleColor: CoreColor.token(CoreColors.primary),
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

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 목록과 항목의 시맨틱은 없습니다. 순서를 바꿀 수 있는 목록의 핸들은 자기 시맨틱 노드(`Semantics(container: true)`)에 이름(`label`)과 설명(`hint`)을 싣고, 역할은 따로 정하지 않습니다. 제거 버튼은 `Semantics(button: true, label: …)`로 감싼 `Button`입니다. |
| Jaspr Web | 루트 `<div>`는 `role="list"`, 행은 `role="listitem"`입니다. 순서를 바꿀 수 있는 목록은 행마다 끌기를 받는 `<div>`가 한 겹 더 있고, 이 상자에는 역할도 `tabindex`도 없습니다. 핸들은 `role="application"` · `tabindex="0"`이고 `aria-label`과 `aria-description`을 갖습니다. 제거 버튼은 `aria-label`이 붙은 `<button type="button">`입니다. |

웹의 핸들이 `role="button"`이 아니라 `application`인 이유가 있습니다. 읽기 모드의 스크린 리더는 버튼 위의 `Space`를 클릭으로 바꾸고 화살표를 자기 가상 커서에 씁니다. 그러면 키보드로 옮기는 키가 핸들에 닿지 않습니다.

### 키보드

순서를 바꿀 수 있는 목록(`enabled: true`이고 `onReorder`가 있을 때)의 핸들이 아래 키를 받습니다. 화살표 키는 행 높이와 상관없이 자리 단위로 옮깁니다. 한 번에 한 자리이고, `grid`의 `↑` · `↓`만 한 줄씩입니다. `Home` · `End`는 양 끝으로 바로 옮깁니다.

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 항목을 집습니다. 집은 상태면 그 자리에 놓습니다. 길게 눌러 반복되는 입력은 무시합니다. |
| `↑` · `↓` | `vertical`은 한 칸, `grid`는 한 줄을 옮깁니다. 한 줄의 길이는 첫 줄에 놓인 항목 수입니다. |
| `←` · `→` | `horizontal`과 `grid`에서 한 칸을 옮깁니다. |
| `Home` · `End` | 맨 앞 · 맨 뒤로 옮깁니다. |
| `Escape` | 옮기기를 취소하고 원래 자리로 되돌립니다. |
| `Enter` · `Space` (제거 버튼) | 항목 제거를 요청합니다(`onRemove`). |

- 항목을 집기 전에는 핸들이 `Space`와 `Enter`만 받습니다.
- 집은 동안에는 그 축에서 쓰지 않는 화살표까지 핸들이 받아, 페이지가 스크롤되지 않습니다.
- 목록의 끝은 벽입니다. 마지막 항목에서 `↓`를 눌러도 맨 앞으로 가지 않고, `grid`에서 격자를 벗어나는 `↑` · `↓`는 제자리에 둡니다.
- 놓으면 포인터로 끌 때와 같은 계산(`CoreSortable.resolve`)을 거쳐 `onReorder(oldIndex, newIndex)`가 불립니다.

### 스크린 리더

핸들의 이름은 항목의 자리를 말합니다. 한국어에서는 "3개 중 2번째 항목 순서 바꾸기"이고, 설명은 "Space 나 Enter 로 집고 놓아요. 화살표 키로 옮기고 Esc 로 취소해요."입니다. 영어 이름은 "Reorder item 2 of 3"입니다. 제거 버튼의 이름은 렌더할 때의 언어로 된 닫기 문구(한국어 "닫기", 영어 "Dismiss")입니다.

키보드로 옮길 때는 단계마다 자리를 넣은 문장 하나를 알립니다. 이 문장이 끌기의 일반 문장을 대신하므로 두 번 읽지 않습니다.

| 순간 | 안내 (한국어) | 안내 (영어) |
| --- | --- | --- |
| 집기 | 3개 중 1번째 항목을 집었어요. 화살표 키로 옮겨 주세요. | Picked up item 1 of 3. Use the arrow keys to move it. |
| 이동 | 3개 중 2번째 위치로 옮겼어요. | Moved to position 2 of 3. |
| 놓기 | 3개 중 2번째 위치에 놓았어요. | Dropped at position 2 of 3. |
| 취소 | 취소했어요. 3개 중 1번째 위치로 돌아갔어요. | Cancelled. Returned to position 1 of 3. |

포인터로 끌 때는 자리 없는 일반 문장("집었어요.", "놓았어요.", "취소했어요.")만 나옵니다. 웹은 목록 옆의 숨은 라이브 영역(`aria-live="polite"`)으로 알립니다. Flutter는 플랫폼 알림(`SemanticsService`)을 쓰며, 플랫폼이 알림을 지원하지 않으면 건너뜁니다.

### 포커스 관리

- `Sortable`이 행에 만드는 탭 정지는 핸들과 제거 버튼입니다. 행의 겉 상자는 탭 순서에 들어가지 않습니다.
- 핸들의 포커스 링은 `FocusOutline`이 그립니다. Flutter는 핸들에 포커스가 있으면, 웹은 키보드 포커스(`:focus-visible`)일 때만 그립니다. 링은 `sortableStyle`의 `handleStyle.focusOutlineStyle`로 바꿉니다.
- 키보드로 놓아 자리가 바뀌면 포커스가 새 자리의 핸들로 옮겨 갑니다. 항목은 자리로 구분하므로, 그대로 두면 다음 화살표가 다른 항목을 옮기게 됩니다. 취소하거나 제자리에 놓으면 포커스는 원래 핸들에 남습니다.
- 집은 채로 포커스가 핸들을 떠나면 옮기기가 취소됩니다.
- Flutter에서 `Overlay`가 있는 앱은 든 항목을 떠 있는 복사본으로 그리고 원래 행은 보이지 않게 둡니다. 이 복사본에는 포커스 링이 없습니다.
- 제거한 뒤 `Sortable`은 포커스를 옮기지 않습니다. 남아 있는 같은 자리의 제거 버튼은 그 자리로 온 다음 항목을 지웁니다.
- 목록은 나타날 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 순서를 바꿀 수 없는 목록의 핸들은 포커스를 받지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `enabled: false`인 목록에서도 제거 버튼은 눌리고 `onRemove`가 불립니다. 평소 색만 비활성입니다. |
| 공통 | 끌기의 방향 잠금은 목록이 처음 만들어질 때의 `axis`로 정해집니다. 화면에 있는 목록의 `axis`만 바꾸면 잠금이 새 방향과 어긋납니다. 예를 들어 세로로 시작한 목록을 가로로 바꾸면 끌기는 위아래로만 움직이고 키보드로도 자리가 바뀌지 않습니다. 격자로 시작한 목록을 세로로 바꾸면 포인터로 옆으로도 끌립니다. `key: ValueKey(axis)`를 함께 주어 새로 만드세요. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 화면에서는 `horizontal` 목록의 놓일 자리가 틀리게 계산됩니다. 계산이 앞 항목일수록 왼쪽에 있다고 보기 때문입니다. 화살표 키도 방향을 뒤집지 않아 `←`가 앞 자리, `→`가 뒤 자리입니다. |
| 공통 | 항목은 자리(인덱스)로 구분하고, 항목마다 키를 받는 파라미터가 없습니다. 행 안 위젯이 들고 있는 상태는 순서를 바꿔도 데이터를 따라가지 않습니다. |
| 공통 | 행 글자의 기본값은 CoUI 기본 스케일의 `bodyLarge` 숫자를 그대로 씁니다. 테마의 타이포 설정을 바꿔도 크기 · 줄 높이 · 굵기 · 자간이 따라오지 않습니다. `itemTextStyle`에 역할 토큰만 주어도 이 값들은 그대로라, 바꾸려면 `fontSize`처럼 값을 직접 적습니다. |
| 공통 | 제거 버튼의 이름은 모든 행에서 같은 닫기 문구라 무엇을 지우는지 말하지 않습니다. 핸들의 이름도 자리만 말합니다. |
| 공통 | 핸들에는 누르기(탭) 동작이 없습니다. 항목은 포인터로 끌거나 키보드 키로만 집습니다. |
| 공통 | 포인터로 끌 때는 자리를 안내하지 않습니다. |
| 공통 | `enabled: true`인데 `onReorder`가 없으면 핸들이 활성 색과 `grab` 커서를 보이지만 끌리지 않습니다. |
| 공통 | `iconStyle.color`나 `removeButtonStyle.leadingIconStyle.color`를 주면 제거 아이콘이 늘 그 색이라, 비활성 목록에서도 `disabledForegroundColor`가 적용되지 않습니다. 아이콘 색은 `handleColor`와 `removeButtonColor`로 바꾸세요. |
| Flutter | 목록(`list`)과 항목(`listitem`)에 해당하는 시맨틱이 없어, 같은 코드가 두 플랫폼에서 다르게 읽힙니다. |
| Flutter | `grid`는 행 상자가 받은 폭을 다 차지해, 폭이 정해진 곳에서는 항목이 한 줄에 하나씩 놓입니다. |
| Flutter | `horizontal`은 높이가 정해진 부모 안에서 행이 그 높이를 다 채웁니다. 감싸는 방법은 [축](#축)에 있습니다. |
| Flutter | 내용이 넘쳐 세로로 스크롤되는 영역(`ListView` · `SingleChildScrollView` 등) 안에서는 터치로 핸들을 위아래로 끌어도 끌기가 시작되지 않을 수 있습니다. 끌기보다 짧은 움직임에서 스크롤이 먼저 반응합니다. |
| Flutter | 비활성 목록의 제거 버튼도 포인터를 올리면 아이콘이 `onSurface`가 되어, 활성 버튼처럼 보입니다. |
| Flutter | 항목을 들 때와 놓을 때 그 행의 내용을 새로 만듭니다. 행 안에 둔 상태는 그때 처음 값으로 돌아갑니다. |
| Jaspr Web | `itemBackgroundColor`를 바꾸면 그 색이 인라인 스타일이라 hover 색이 보이지 않습니다. `itemHoverColor`까지 바꾸면 포인터가 벗어난 뒤 직접 정한 배경도 지워집니다. |
| Jaspr Web | 비활성 목록의 핸들도 `grab` 커서를 보입니다. |
| Jaspr Web | 순서를 바꿀 수 있는 목록은 처음 그려진 뒤 다시 그려지기 전까지(첫 끌기나 핸들 포커스 전까지) 행 전체에 `grab` 커서가 보입니다. 끌기는 핸들에서만 시작합니다. |
| Jaspr Web | `iconStyle`에 `color`를 주면 핸들 아이콘이 그 색이 되어 `handleColor`와 비활성 색보다 우선합니다. Flutter의 핸들은 `handleColor`를 따릅니다. |

reduced motion · 고대비 · 최소 터치 타겟처럼 컴포넌트를 가로지르는 축은 [전역 접근성 축](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같고, 아래 동작은 플랫폼마다 다릅니다. 놓일 자리를 정하는 계산(`CoreSortable.resolve`)은 두 플랫폼이 같은 것을 씁니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `itemBuilder` | `BuildContext`를 첫 인자로 받습니다. | `index`부터 받습니다. |
| 시맨틱 | 핸들과 제거 버튼만 이름을 갖습니다. | `role="list"` · `role="listitem"`, 핸들은 `role="application"` |
| 안내 | 플랫폼 알림(`SemanticsService`). 지원하지 않는 플랫폼에서는 건너뜁니다. | 목록 옆의 숨은 라이브 영역 |
| 끌리는 항목 | `Overlay`가 있으면 복사본을 그 위에 그려, 목록의 조상이 잘라 내지 않습니다. | 행 자체를 옮깁니다. 넘치는 부분을 숨기는 조상 안에서는 잘릴 수 있습니다. |
| 들어 올리기 | `animationDuration` 동안 커지고 그림자가 자랍니다. | 바로 커지고 그림자가 생깁니다. |
| 가장자리 자동 스크롤 | 목록을 감싼 스크롤 위젯(`Scrollable`) | `overflow`가 `auto`나 `scroll`인 조상. 페이지 자체의 기본 스크롤은 대상이 아닙니다. |
| 핸들 커서 | `grab`. 비활성 목록은 기본 커서 | `grab`, 누르는 동안 `grabbing`. 비활성 목록도 `grab` |
| 핸들 포커스 링 | 핸들에 포커스가 있으면 | `:focus-visible`일 때만 |
| 제거 버튼 hover | 아이콘이 `onSurface`가 됩니다. 비활성 목록에서도 같습니다. | 색이 바뀌지 않습니다. |
| `horizontal` 행의 높이 | 부모의 높이가 정해져 있으면 그 높이를 다 채웁니다. | 높이를 정한 블록 상자 안에서도 내용 높이입니다. |
| `grid` 배치 | 폭이 정해진 곳에서는 한 줄에 하나씩([알려진 제약](#알려진-제약)) | 폭에 맞춰 줄을 바꿉니다(`flex-wrap`). |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 DOM 이벤트 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 이름을 씁니다. `W`는 위젯의 타입으로, Flutter에서는 `Widget`, 웹에서는 `Component`입니다. 인덱스는 0부터 셉니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `itemCount` | `int` | 필수 | 정렬할 항목 수 |
| `itemBuilder` | `SortableItemBuilder` | 필수 | 행 안의 내용. Flutter는 `W Function(BuildContext, int, W, W?)`, 웹은 `W Function(int, W, W?)`입니다([항목 빌더](#항목-빌더)). |
| `axis` | `CoreSortableAxis` | `CoreSortableContract.defaultAxis` (`vertical`) | 목록이 놓이는 방향(`vertical` · `horizontal` · `grid`) |
| `onReorder` | `CoreSortableReorderCallback?` | `null` | `void Function(int oldIndex, int newIndex)`. 없으면 순서를 바꿀 수 없습니다. |
| `onRemove` | `CoreSortableRemoveCallback?` | `null` | `void Function(int index)`. 제거 버튼을 누르면 불립니다. |
| `enabled` | `bool` | `true` | `false`면 끌기와 키보드 이동을 끄고 비활성 색으로 그립니다. 제거 버튼은 눌립니다. |
| `removable` | `bool` | `false` | `true`이고 `onRemove`가 있으면 제거 버튼을 만듭니다. |
| `sortableStyle` | `CoreSortableStyle?` | `null` | 행 · 핸들 · 제거 버튼의 겉모습과 안쪽 부품의 스타일을 바꾸는 값 묶음 |

웹은 위 파라미터에 더해 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 DOM 이벤트(`onClick` · `onKeyDown` 등)를 받아 루트 `<div>`에 붙입니다. 루트의 `role`은 늘 `list`라 `attributes`로 바꿀 수 없습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreSortableStyle patch)` | `sortableStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({itemCount, onReorder, …})` | 바꾼 값으로 사본을 만듭니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.sortable` | `CoreSortableTheme?` | 앱 전체 기본값. `style: CoreSortableStyle?` 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSortableStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemBackgroundColor` | `CoreColor?` | Item background colour. |
| `itemHoverColor` | `CoreColor?` | Item hover background colour. |
| `itemBorderColor` | `CoreColor?` | Item border colour. |
| `disabledItemBackgroundColor` | `CoreColor?` | Item background colour while the list is disabled. |
| `disabledItemBorderColor` | `CoreColor?` | Item border colour while the list is disabled. |
| `handleColor` | `CoreColor?` | Drag handle colour. |
| `disabledHandleColor` | `CoreColor?` | Drag handle colour while the list is disabled. |
| `disabledForegroundColor` | `CoreColor?` | Item text and remove-button glyph colour while the list is disabled. `null` → [defaultDisabledForegroundColor]. |
| `removeButtonColor` | `CoreColor?` | Remove button colour. |
| `itemBorderRadius` | `CoreBorderRadius?` | Item border radius. |
| `itemBorderWidth` | `double?` | Item border width (logical px). |
| `itemMinHeight` | `double?` | Minimum item height (logical px). |
| `removeButtonBorderRadius` | `CoreBorderRadius?` | Remove button corner radius. |
| `itemSpacing` | `double?` | Spacing between items (logical px). |
| `itemPadding` | `CoreEdgeInsets?` | Inner padding of each sortable item. |
| `handlePadding` | `CoreEdgeInsets?` | Padding around the drag handle. |
| `removeButtonSize` | `double?` | Size of the remove button hit area (logical px, square). |
| `animationDuration` | `Duration?` | How long the reorder shift and the colour change take. |
| `proxyScale` | `double?` | Drag-proxy peak scale multiplier (`1.0` = no change). `null` → [defaultProxyScale]. Flutter feeds `Transform.scale`; Web (no proxy yet) leaves it unconsumed. |
| `proxyElevation` | `double?` | Drag-proxy peak Material elevation. `null` → [defaultProxyElevation]. Flutter feeds `Material.elevation`; Web (no proxy yet) unconsumed. |
| `itemTextStyle` | `CoreTextStyle?` | Text style of each item's label. Laid over [defaultItemTextStyle] (`bodyLarge` role + `onSurface` colour); the text colour is set via [CoreTextStyle.color] in this style, so both platforms take the label typography and colour from this one field. |
| `iconStyle` | `CoreIconStyle?` | Shared icon slot style (size + colour) for both the drag-handle and the remove glyphs. |
| `removeButtonStyle` | `CoreButtonStyle?` | Remove (dismiss) button style override. |
| `handleStyle` | `CoreButtonStyle?` | Drag handle style override. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `proxyScale` · `proxyElevation` 설명과 달리 웹도 두 값을 끌리는 항목에 적용합니다. Flutter는 `Material.elevation` 대신 같은 높이의 그림자를 직접 그립니다. `handleStyle`은 [안쪽 부품의 스타일](#안쪽-부품의-스타일)에 적은 네 가지만 읽습니다. `itemTextStyle`의 기본값은 `bodyLarge` 역할을 따라가는 것이 아니라 CoUI 기본 스케일의 값을 그대로 씁니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Tree" href="/components/tree" more="Tree 보기">

계층 구조의 항목을 펼쳐 보여 주고, 끌어서 옮기게 할 때 씁니다.

</Card>
<Card title="Table" href="/components/table" more="Table 보기">

순서를 바꿀 필요 없이 데이터를 행과 열로 보여 줄 때 씁니다.

</Card>
<Card title="Drag" href="/components/drag" more="Drag 보기">

한 목록 밖으로 옮기거나 놓는 영역을 직접 만들 때 씁니다.

</Card>
</Cards>
