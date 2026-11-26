---
title: FAB
description: 화면의 주요 액션을 강조하는 플로팅 액션 버튼 컴포넌트
category: control
platforms: [flutter, web]
related: [button, tooltip]
tags: [interactive, action, floating]
template: v2
source: control/fab
---

# FAB

화면에서 가장 중요한 행동 하나를 콘텐츠 위에 띄우는 버튼(Floating Action Button)입니다. `trigger` 만 주면 원형, `label` 을 주면 라벨이 붙은 **Extended** 알약, `actions` 를 주면 누를 때 액션 메뉴를 여는 버튼이 됩니다. Flutter 와 Web 이 같은 `Fab` API 를 씁니다.

<a id="live-preview"></a>

## 플레이그라운드

형태 · 크기 · 방향 · `tooltip` 을 바꿔 가며 미리 보고, 아래 코드를 가져다 쓸 수 있습니다.

<Playground component="fab" />

메뉴 형태는 누르면 실제 메뉴가 열리고, 행을 고르거나 바깥을 누르면 닫힙니다. `label` 과 `actions` 는 함께 쓰지 않으므로 형태를 하나만 고릅니다.

## 구조

<Anatomy demo="fab/anatomy">
<AnatomyItem select="[data-docs-part=fab] button" side="right" name="FAB">

메인 버튼. 눌러서 행동을 실행하거나 메뉴를 여닫습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=fab] svg" side="left" name="trigger · closeIcon">

닫혀 있을 때는 `trigger`, 메뉴가 열려 있으면 `closeIcon`(기본 X)을 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="[role=menu]" side="left" name="메뉴 판">

액션 행을 담는 `Popup` 판입니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem]" side="right" name="FabAction">

`actions` 하나가 `MenuItem` 행 하나가 됩니다.

</AnatomyItem>
</Anatomy>

<Note>

위의 열린 메뉴는 문서용 그림입니다. Extended 형태는 `trigger` 가 라벨 앞 아이콘이 되고 라벨이 그 뒤에 놓입니다.

</Note>

<a id="크기-sizes"></a>

## 크기

크기는 `size`(`CoreFabSize.mini` · `regular` · `large`, 기본 `regular`)로 고릅니다. 표의 `size` 열은 문서가 쓰는 크기 이름이고, `Fab` 에 넘기는 값은 `CoreFabSize` 열입니다.

<SizeSpec component="fab" />

<Preview demo="fab/sizes-extended" />

- 원형은 크기마다 지름과 아이콘이 정해집니다. 지름은 밀도를 바꿔도 그대로입니다.
- `regular` 를 기본으로 쓰고, `mini` 는 덜 중요한 보조 행동에, `large` 는 특히 강조할 때 씁니다.
- `mini` 가 48 인 것은 터치 화면의 권장 크기가 48 이기 때문입니다. FAB 은 그보다 작아질 이유가 없습니다.
- Extended 는 높이가 원형의 지름과 같고 폭만 라벨을 따라 늘어납니다. `mini` · `regular` · `large` 의 아이콘과 라벨 글자는 차례로 `Button` 의 `lg` · `xl` · `xl2` 크기 값입니다. `large` 는 높이가 72 이지만 아이콘과 글자는 높이 64 인 `xl2` 의 값입니다.
- 그래서 `fabStyle` 의 `iconStyle` 과 `buttonStyle` 은 Extended 에 닿지 않습니다. Extended 는 `extendedButtonStyle` 로 바꿉니다(아이콘은 `extendedButtonStyle.leadingIconStyle`).

<Code language="dart" title="작은 FAB">
Fab(
  trigger: const Icon(LucideIcons.plus),
  size: CoreFabSize.mini,
  onPressed: handleCreate,
)
</Code>

<a id="기본-사용법-basic-usage"></a>

## 형태

<Cards columns="3">
<Card component="fab" props="form=circle" title="원형">

`label` 과 `actions` 를 주지 않으면 원형입니다.

</Card>
<Card component="fab" props="form=extended" title="Extended">

`label` 을 주면 알약이 되고, `trigger` 는 라벨 앞 아이콘이 됩니다.

</Card>
<Card component="fab" props="form=menu" title="메뉴 트리거">

`actions` 를 주면 누를 때 메뉴를 열고, 열린 동안 `closeIcon` 을 보여 줍니다.

</Card>
</Cards>

<Code language="dart" title="세 형태">
// 원형
Fab(
  trigger: const Icon(LucideIcons.plus),
  onPressed: handleCreate,
)

// Extended — 라벨이 붙은 알약
Fab(
  trigger: const Icon(LucideIcons.plus),
  label: const Text('새 메모'),
  onPressed: handleCreate,
)

// 메뉴 — 누르면 액션 메뉴가 열립니다
Fab(
  trigger: const Icon(LucideIcons.plus),
  actions: [
    FabAction(
      icon: const Icon(LucideIcons.pencil),
      label: const Text('편집'),
      onPressed: handleEdit,
    ),
    FabAction(
      icon: const Icon(LucideIcons.share),
      label: const Text('공유'),
      onPressed: handleShare,
    ),
  ],
)
</Code>

`label` 과 `actions` 는 함께 쓰지 않습니다. 둘을 함께 주면 Flutter 의 디버그 빌드는 생성자의 assert 에서 멈추고, Flutter 의 릴리스 빌드와 Web 은 알리지 않고 `label` 을 버린 원형 메뉴 FAB 을 그립니다. 빈 `actions` 목록은 `actions` 가 없는 것과 같습니다.

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="fab/states" />

<Note>

Hover · Pressed · Focus 칸은 그 상태를 고정해 그린 것입니다. Pressed 칸은 Web 에서는 `primaryPressed` 채움과 0.95배 크기를, Flutter 에서는 0.95배 크기를 보여 줍니다. 비활성 채움은 옅은 회색이라 흰 바탕에서도 옅게 보입니다.

</Note>

| 상태 | 보이는 것 |
| --- | --- |
| 기본 | `primary` 채움, `onPrimary` 아이콘 · 라벨, `lg` 그림자, 끝까지 둥근 모서리 |
| Hover | `primaryHover` 채움 |
| Pressed | 0.95배로 줄어듭니다. Web 은 `primaryPressed` 채움도 칠하고, Flutter 는 이 채움을 칠하지 않습니다. `neoBrutalism` 처럼 그림자 쪽으로 눌리는 서페이스 스타일에서는 줄어드는 대신 그림자 쪽으로 옮겨 갑니다 |
| Focus | 2px 간격을 두고 바깥에 링. FAB 은 그 간격을 `surface` 색으로 칠합니다 |
| 비활성 | `actions` 가 없고 `onPressed` 도 없으면 `disabledContainer` 채움과 `disabledContent` 아이콘 · 라벨 |
| 열림 | `trigger` 자리에 `closeIcon` |

### 인터랙션

- 메인 버튼을 누르면 `actions` 가 있을 때는 메뉴를 열거나 닫고(`onPressed` 는 부르지 않습니다), 없을 때는 `onPressed` 를 부릅니다.
- 행을 누르면 그 `FabAction` 의 `onPressed` 를 부른 뒤 메뉴를 닫습니다.
- 메뉴 바깥을 누르면 닫힙니다. Web 에서는 `Escape` 로도 닫힙니다.
- 채움 같은 버튼의 상태 전환은 150ms 입니다.
- 누를 수 있는 FAB 위에서는 커서가 포인터 모양이 되고, 비활성 FAB 위에서는 금지 모양이 됩니다.

## 액션 메뉴

### 액션 행

`actions` 의 각 `FabAction` 은 `MenuItem` 행 하나가 됩니다.

- 행 크기는 FAB 크기와 상관없이 `MenuItem` 의 `lg` 입니다(`CoreFabContract.actionItemSize`). 표준 밀도에서 최소 높이 48, 안쪽 여백 좌우 16 · 위아래 12, 아이콘 24, 아이콘과 라벨 사이 12 입니다. `Menu` 의 기본 행(`sm`, 32)보다 큽니다.
- 최소 높이는 밀도를 따라 compact 에서 40, spacious 에서 56 이 됩니다.
- 행은 열리는 방향과 상관없이 `actions` 에 적은 순서대로 위에서 아래로 놓입니다.
- `label` 이 없으면 아이콘만 있는 행이 되고, `onPressed` 가 없는 행도 누를 수 있으며 누르면 메뉴가 닫힙니다.

<Preview demo="fab/menu" />

<Note>

위 판은 문서용 그림입니다. 실제 메뉴는 화면 위의 오버레이 층에 열립니다. 판과 행은 킷의 `Popup` · `MenuItem` 을 `Fab` 의 기본값으로 그린 것이라 테마 색은 따라갑니다. `CoreFabTheme` 이나 `fabStyle` 로 판 · 행에 건 덮어쓰기는 이 그림의 판 · 행에 닿지 않습니다. 실제 동작은 플레이그라운드의 메뉴 형태를 누르면 보입니다.

</Note>

<a id="controlled-uncontrolled"></a>

### 열림 상태 제어

- `onOpenChanged` 가 없으면 `Fab` 이 열림 상태를 갖습니다(uncontrolled). `open` 은 처음 만들 때만 읽으므로, `open: true` 로 만들면 첫 프레임 뒤에 메뉴가 열리고 이후에 `open` 을 바꿔도 반영되지 않습니다.
- `onOpenChanged` 를 주면 `open` 이 상태입니다(controlled). 메인 버튼 누르기와 행 선택은 `onOpenChanged` 로 새 값을 알리기만 하므로, 부모가 그 값을 `open` 으로 다시 넘겨야 열리고 닫힙니다.
- 바깥 누르기(Web 은 `Escape` 도)는 판을 먼저 닫고 `false` 를 알립니다. 부모가 `open` 을 `false` 로 바꾸지 않으면 메인 버튼이 닫기 아이콘을 계속 보여 줍니다.

<Code language="dart" title="부모가 열림 상태를 갖기">
Fab(
  trigger: const Icon(LucideIcons.plus),
  open: menuOpen,
  onOpenChanged: (open) => setState(() => menuOpen = open),
  actions: [
    FabAction(
      icon: const Icon(LucideIcons.pencil),
      label: const Text('편집'),
      onPressed: handleEdit,
    ),
  ],
)
</Code>

### 열리는 방향

| `expandDirection` | 판의 자리 |
| --- | --- |
| `up` (기본) | FAB 위. 판의 오른쪽 끝을 FAB 의 오른쪽 끝에 맞춥니다 |
| `down` | FAB 아래. 오른쪽 끝을 맞춥니다 |
| `left` | FAB 왼쪽. 세로 가운데를 맞춥니다 |
| `right` | FAB 오른쪽. 세로 가운데를 맞춥니다 |
| `fan` | `up` 과 같습니다. 부채꼴 배치는 없습니다 |

- 판은 표준 밀도에서 화면 가장자리와 8 이상 떨어지게 놓입니다(compact 는 4, spacious 는 12). 자리가 모자라면 반대쪽으로 뒤집거나 화면 안으로 밀어 넣습니다.
- FAB 과 판 사이 간격은 `fabStyle.spacing`(기본 16)입니다. `popoverStyle.placementOffset` 을 주면 그 값이 우선합니다.
- `up` · `down` 의 끝 맞춤은 늘 **오른쪽**입니다. 오른쪽에서 왼쪽으로 쓰는 로케일에서도 판은 좌우로 뒤집히지 않습니다.

### 메뉴 너비

- 판의 너비는 내용을 따르되 160(`layout/160`)에서 280(`layout/280`) 사이이고, 행은 판의 너비를 채웁니다.
- 라벨은 줄을 바꾸지 않습니다. 판이 280 까지 넓어져도 라벨이 다 들어가지 않으면 Flutter 는 말줄임(…)으로 끝내고 행 높이는 그대로입니다. Web 은 말줄임표 없이 판 가장자리에서 잘립니다(알려진 제약).

### 패널 여백과 행 모서리

- 판의 안쪽 여백은 6(`CorePopupStyle.defaultListPadding`)이고 행 사이는 2 입니다. 행동 목록이라 `Menu` 와 같은 여백을 씁니다.
- 판의 채움(`surfaceBright`) · 테두리(`outlineVariant`, 1) · 모서리(12) · 그림자(`lg`)는 `Popup` 의 기본값입니다.
- 행 모서리는 8 입니다. `ItemPicker` · `Autocomplete` · `PhoneInput` 의 목록 행과 같은 값이고, 혼자 서는 `MenuItem` `lg` 의 12 는 쓰지 않습니다.

### 애니메이션

- 메뉴는 `Popover` 의 등장 · 퇴장 모션으로 열고 닫습니다. 기본 시간은 열릴 때 150ms, 닫힐 때 100ms 입니다.
- 시간은 `fabStyle.popoverStyle` 의 `openAnimationDuration` · `closeAnimationDuration` 으로 바꿉니다. `fabStyle.duration` 은 지금 두 플랫폼 모두 메뉴 모션에 반영되지 않습니다.
- 행이 하나씩 나타나는 효과(stagger)나 부채꼴 배치는 없습니다.

<Code language="dart" title="메뉴가 열리고 닫히는 시간 바꾸기">
Fab(
  trigger: const Icon(LucideIcons.plus),
  actions: [
    FabAction(
      icon: const Icon(LucideIcons.pencil),
      label: const Text('편집'),
      onPressed: handleEdit,
    ),
  ],
  fabStyle: const CoreFabStyle(
    popoverStyle: CorePopoverStyle(
      openAnimationDuration: Duration(
        milliseconds: CoreDuration.moderate,
      ),
      closeAnimationDuration: Duration(
        milliseconds: CoreDuration.fast,
      ),
    ),
  ),
)
</Code>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

새 항목 만들기 · 글쓰기 · 공유처럼 화면에서 가장 중요한 행동 하나를 강조하고, 스크롤해도 늘 닿아야 할 때 씁니다. 버튼 하나에서 관련 행동 여럿을 열어야 하면 메뉴 FAB 하나로 묶습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 화면 안에 자리 잡는 행동이거나 덜 중요한 행동일 때 | [Button](/components/button) |
| 목록의 항목마다 여는 행동 목록일 때 | [DropdownMenu](/components/dropdown-menu) |
| 화면 아래에 가로로 고정하는 행동 영역일 때 | [BottomActionBar](/components/bottom-action-bar) |
| 어떤 요소에 도움말만 붙일 때 | [Tooltip](/components/tooltip) |

### 개수와 쓰는 자리

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="fab/do-single" tone="do" eyebrow="이렇게 하세요">

한 화면에는 FAB 하나만 둡니다. 화면에서 가장 중요한 행동이 그 자리를 갖습니다.

</Card>
<Card demo="fab/dont-two" tone="dont" eyebrow="이렇게 하지 마세요">

FAB 이 둘이면 어느 것이 주요 행동인지 알 수 없습니다. 덜 중요한 쪽을 `Button` 으로 내리거나 메뉴 FAB 하나로 묶습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

지금 쓸 수 없는 행동이면 FAB 을 그리지 않습니다.

```dart
if (canCreate)
  Fab(
    trigger: const Icon(
      LucideIcons.plus,
    ),
    onPressed: handleCreate,
  )
```

</Card>
<Card demo="fab/dont-disabled" tone="dont" eyebrow="이렇게 하지 마세요">

비활성 FAB 은 자리만 차지하고 왜 안 되는지 말하지 못합니다. 이유를 보여야 하면 화면 안의 `Button` 과 안내 문구를 씁니다.

</Card>
<Card demo="fab/do-confirm" tone="do" eyebrow="이렇게 하세요">

삭제처럼 파괴적인 행동은 화면 안의 `destructive` 버튼에 두고, 확인 대화상자를 거칩니다.

</Card>
<Card demo="fab/dont-destructive" tone="dont" eyebrow="이렇게 하지 마세요">

파괴적인 행동을 FAB 에 두지 않습니다. 가장 눈에 띄는 자리에 떠 있어 실수로 누르기 쉽습니다.

</Card>
<Card demo="fab/do-extended" tone="do" eyebrow="이렇게 하세요">

데스크톱처럼 가로 공간이 넉넉한 화면에서는 Extended 로 라벨을 보여 줍니다. 아이콘만 있으면 포인터를 올려 툴팁을 보기 전까지 무슨 행동인지 알기 어렵습니다. 원형은 라벨을 놓을 자리가 없는 좁은 화면의 형태입니다.

</Card>
<Card component="fab" props="form=menu" tone="do" eyebrow="이렇게 하세요">

관련된 보조 행동 여럿은 메뉴 FAB 하나로 묶어 화면을 비웁니다.

</Card>
</Cards>

## 배치

`Scaffold` 의 `floatingActionButton` 에 넣으면 `Scaffold` 아래쪽에 띄웁니다. 가로 자리는 `floatingActionButtonLocation`(`CoreScaffoldFabLocation.endFloat` 기본 · `centerFloat` · `startFloat`)이 정하고, 둘레 여백은 표준 밀도에서 16(`CoreScaffoldStyle.defaultFabPadding`)입니다.

- `endFloat` 는 오른쪽, `startFloat` 는 왼쪽입니다. 오른쪽에서 왼쪽으로 쓰는 로케일에서도 좌우가 바뀌지 않습니다.
- FAB 은 `footers` 까지 포함한 `Scaffold` 전체 위에 놓입니다. `footers` 를 쓰면 아래 막대와 겹칠 수 있습니다.
- Web 의 FAB 은 브라우저 화면이 아니라 `Scaffold` 상자의 아래쪽에 놓입니다. 본문이 길어 상자가 늘어나면 FAB 도 함께 내려갈 수 있습니다.

<Code language="dart" title="Scaffold 의 FAB 자리">
Scaffold(
  floatingActionButtonLocation: CoreScaffoldFabLocation.endFloat,
  floatingActionButton: Fab(
    trigger: const Icon(LucideIcons.plus),
    onPressed: handleCreate,
  ),
  child: content,
)
</Code>

<Cards columns="2">
<Card demo="fab/placement-corner" height="340" title="끝 아래 모서리">

기본 자리인 `endFloat` 의 모습입니다.

</Card>
<Card demo="fab/placement-menu" height="340" title="위로 연 메뉴">

`up` 은 FAB 위에 오른쪽 끝을 맞춰 엽니다. 이 메뉴는 문서용 그림입니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `fabStyle`(`CoreFabStyle`) 하나로 덮어씁니다. 원형은 `buttonStyle` · `iconStyle` · `diameter`, Extended 는 `extendedButtonStyle` 과 `diameter`(높이)가 맡습니다. 메뉴의 행은 `actionItemStyle`, 판은 `popupStyle`, 판을 띄우는 `Popover` 는 `popoverStyle` 입니다. 안에서 그리는 `Button` · `MenuItem` · `Popup` · `Popover` 의 스타일을 그 컴포넌트의 Style 타입 그대로 넘깁니다.

<Split>

<Code language="dart" title="Fab 하나만 바꾸기">
Fab(
  trigger: const Icon(LucideIcons.plus),
  onPressed: handleCreate,
  fabStyle: const CoreFabStyle(
    buttonStyle: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(
        CoreRadiusRole.surface,
      ),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    fab: CoreFabTheme(
      style: CoreFabStyle(
        spacing: CoreSpace.space12,
      ),
    ),
  ),
)
</Code>

</Split>

`CoreFabTheme` 은 `style` 하나를 가집니다. `size` 같은 위젯 속성은 테마가 바꾸지 않습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Fab` 에 `withStyle` 로 값을 덧붙일 수 있습니다. 생성자의 `fabStyle` 에 같은 값을 합친 것과 같고, 같은 칸은 나중에 붙인 값이 우선합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FabChainExample extends StatelessWidget {
  const FabChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: const Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: const Text('공유'),
        ),
      ],
    ).withStyle(
      const CoreFabStyle(
        diameter: CoreSize.size72,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size32,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        popupStyle: CorePopupStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
        spacing: CoreSpace.space24,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class FabChainExample extends StatelessComponent {
  const FabChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: Text('공유'),
        ),
      ],
    ).withStyle(
      const CoreFabStyle(
        diameter: CoreSize.size72,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size32,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        popupStyle: CorePopupStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
        spacing: CoreSpace.space24,
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="옛-행-스타일-필드-deprecated"></a>

### 옛 행 스타일 필드

메뉴 행은 `MenuItem` 이고, 행의 겉모습은 `actionItemStyle`(`CoreMenuItemStyle`)로 바꿉니다. 옛 필드는 0.164 부터 `@Deprecated` 이고 아직 동작합니다. `MenuItem` 에 같은 뜻의 칸이 있으면 그 칸으로 옮겨 적용하고, `actionItemStyle` 도 같은 칸을 정하면 `actionItemStyle` 이 우선합니다.

| 옛 | 새 |
| --- | --- |
| `actionButtonStyle` | `actionItemStyle`. `padding` · `borderRadius` · `iconLabelGapStyle`(→ `contentGapStyle`) · `height`(→ `minHeight`) · `leadingIconStyle` · `labelStyle` · `backgroundColor` · `foregroundColor` · `hoverBackgroundColor` 만 옮겨지고, 그림자 · 테두리 · 포커스 아웃라인 같은 버튼 전용 칸은 버려집니다 |
| `actionIconStyle` | `actionItemStyle.leadingIconStyle` |
| `actionLabelTextStyle` | `actionItemStyle.labelStyle` |
| `CoreFabContract.actionButtonSize` | `CoreFabContract.actionItemSize` (`CoreMenuItemSize.lg`) |
| `CoreFabStyle.defaultActionButtonStyle` · `defaultActionLabelTextStyle` · `defaultActionIconStyle` | `CoreFabStyle.defaultActionItemStyle`. 옛 기본값은 `Fab` 이 읽지 않습니다 |

### 값이 정해지는 순서

뒤에 오는 값이 같은 칸을 덮습니다.

1. `CoreFabStyle` 의 기본값과 크기마다의 값
2. 앱 테마의 `CoreComponentTheme.fab.style`
3. 위젯의 `fabStyle` (`withStyle` 포함)

안에서 그리는 `Button` · `MenuItem` · `Popup` 은 각자의 컴포넌트 테마도 읽습니다(`Button` 은 `CoreButtonTheme` 의 `style` 과 `primary` variant 값). 위에서 정해진 칸은 그 테마보다 우선합니다 — 예를 들어 FAB 의 모서리 · 그림자 · 지름, 행의 모서리, 판의 여백 · 너비 범위 · 행 간격이 그렇습니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 메인 FAB | 메뉴 |
| --- | --- | --- |
| Flutter | `Button` — 버튼으로 알립니다. `actions` 가 있으면 열림 상태(expanded)도 알립니다 | 판에는 역할이 없고, 행은 버튼으로 알립니다 |
| Web | 네이티브 `<button type="button">`. `actions` 가 있으면 `aria-expanded` 가 붙고, 버튼을 감싼 트리거 상자에는 `aria-haspopup="dialog"` 와 `aria-expanded`(열리면 `aria-controls`)가 붙습니다 | `role="dialog"` 상자 안의 `role="menu"`, 행은 `role="menuitem"` |

- 열림 상태는 `actions` 가 있을 때만 알립니다. 아무것도 열지 않는 버튼을 '접힘' 으로 알리지 않기 위해서입니다.
- `Fab` 에는 `enabled` 속성이 없습니다. `actions` 가 없고 `onPressed` 가 `null` 이면 비활성 버튼이 되고, 두 플랫폼 모두 비활성 상태로 알립니다. Web 에서는 `disabled` · `aria-disabled="true"` · `tabindex="-1"` 이 붙습니다. 메뉴 FAB 은 누르면 메뉴를 여닫으므로 비활성이 되지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 메인 FAB 으로 들어가고 나옵니다 |
| `Enter` · `Space` (메인 FAB) | `actions` 가 있으면 메뉴를 열거나 닫고, 없으면 `onPressed` |
| `Enter` · `Space` (행) | 그 행의 `onPressed` 를 부르고 메뉴를 닫습니다 |
| `Escape` | **Web 에서만** 메뉴를 닫습니다 |

행 사이를 오가는 화살표 키는 없습니다.

### 스크린 리더

- Extended 는 `label` 의 글자가 이름이 됩니다. `trigger` 에 넣은 `Icon` 은 두 플랫폼 모두 이름을 만들지 않습니다.
- Web 의 `tooltip` 은 `aria-label` 로 나가 이름이 됩니다. `aria-label` 은 보이는 글자를 대신하므로, Extended 나 라벨이 있는 행에 `tooltip` 을 주면 라벨 대신 `tooltip` 문구가 읽힙니다. 라벨의 말을 담아 적습니다.
- Flutter 의 `tooltip` 은 라벨이 아닙니다. `Semantics(tooltip:)` 으로 전해지며, 스크린 리더가 읽는 방식은 플랫폼마다 다를 수 있습니다.
- 액션 행은 `label` 의 글자가 이름이 됩니다. 아이콘만 있는 행은 Web 에서는 `FabAction.tooltip` 이 `aria-label` 이 되어 이름이 되고, Flutter 에서는 이름이 없고 `tooltip` 만 따로 전해집니다.
- 화면의 툴팁은 두 플랫폼 모두 포인터를 올렸을 때 보입니다. 키보드 포커스로는 보이지 않고, 길게 눌러 여는 동작도 없습니다.
- 열림 · 닫힘은 expanded 상태로 알리고, 따로 읽어 주는 라이브 영역은 없습니다.

#### 이름 붙이기

아이콘만 있는 FAB 은 Web 에서는 `tooltip` 으로 이름을 붙입니다. Flutter 에서는 `Semantics(label:)` 로 감싸고, 그 바깥을 `MergeSemantics` 로 감싸 이름이 버튼과 한 접근성 노드로 합쳐지게 합니다.

<Preview demo="fab/a11y-name" />

<Code language="dart" title="Web 에서 이름 붙이기">
Fab(
  trigger: const Icon(LucideIcons.plus),
  tooltip: '새 메모 작성',
  onPressed: handleCreate,
)
</Code>

<Code language="dart" title="Flutter 에서 이름 붙이기">
MergeSemantics(
  child: Semantics(
    label: '새 메모 작성',
    child: Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: handleCreate,
    ),
  ),
)
</Code>

### 포커스 관리

- **열 때**: 포커스는 메인 FAB 에 남습니다. Flutter 는 메뉴를 모달이 아닌 판으로 열어 포커스를 옮기지 않고, Web 의 `Popover` 도 판에 포커스를 주지 않습니다.
- **닫을 때**: 포커스를 따로 되돌리지 않습니다. Web 에서 행에 포커스를 둔 채 메뉴가 닫히면 그 행이 사라지고, 포커스는 FAB 으로 돌아가지 않습니다.
- **가두기**: 포커스를 가두지 않습니다. 메뉴는 모달이 아니라 뒤의 화면을 막지 않으므로, 메뉴가 열려 있어도 스크린 리더는 뒤의 화면을 계속 읽을 수 있습니다. Web 에서는 `Tab` 도 메뉴 안에 갇히지 않습니다.
- **순서**: 메뉴는 앱 화면과 따로 둔 오버레이 층에 그려집니다. Web 의 행은 페이지 요소들 뒤에 놓여, FAB 뒤에 다른 요소가 있으면 `Tab` 이 그 요소들을 먼저 지난 뒤 행에 닿습니다. `Scaffold` 처럼 FAB 이 마지막 요소이면 다음 `Tab` 이 행으로 갑니다. Flutter 는 판이 페이지와 다른 포커스 범위에 있어 `Tab` 으로 행에 닿지 않을 수 있습니다.
- **표시**: 원형과 Extended 모두 링과 FAB 사이 2px 간격을 `surface` 색으로 칠합니다. FAB 은 스크롤하는 콘텐츠 위에 떠 있어 링 옆에 어떤 색이 올지 알 수 없습니다. 그래서 링과 `surface` 띠를 두 색으로 겹쳐, 뒤에 어떤 색이 와도 포커스 표시가 구분되게 합니다. 값은 `CoreFabStyle.defaultButtonStyle` 의 `focusOutlineStyle.offsetColor` 이고, `Button` 의 기본 간격은 투명합니다.

### 알려진 제약

- **Flutter 에서는 `Escape` 로 메뉴를 닫지 못합니다.** 메뉴를 모달이 아닌 판으로 열기 때문입니다. 필요하면 `open` · `onOpenChanged` 로 열림 상태를 부모가 갖고, 부모에서 키를 받아 `open` 을 `false` 로 바꿉니다.
- **Flutter 에서는 키보드로 메뉴의 행에 가기 어려울 수 있습니다.** `Tab` 이 판의 포커스 범위로 들어가지 않을 수 있습니다. 또 행은 메뉴 항목이 아니라 버튼으로 알립니다.
- **Flutter 의 아이콘만 있는 FAB 은 이름이 없습니다.** `tooltip` 은 라벨이 아니라 이름을 대신하지 못합니다. 위의 '이름 붙이기' 처럼 `MergeSemantics` 와 `Semantics(label:)` 로 감쌉니다. 아이콘만 있는 메뉴 행도 같으므로 행에는 `label` 을 줍니다.
- **Flutter 는 누르는 동안 `primaryPressed` 채움을 칠하지 않습니다.** 누른 상태는 크기 변화로만 보이고, 포인터를 올린 채 누르면 Hover 채움이 그대로 남습니다. 안에서 그리는 `Button` 의 동작이라 다른 `Button` 도 같습니다.
- **Web 의 긴 행 라벨은 말줄임표 없이 잘립니다.** 행 라벨은 판(최대 280)에 들어가는 길이로 짧게 씁니다.
- **Web 에서는 열린 메뉴가 FAB 의 자리를 따라가지 않게 됩니다.** 메뉴가 열린 뒤에 다른 떠 있는 패널(`Fab` 이나 `FabAction` 의 `tooltip` 이 띄우는 툴팁 포함)이 열리면, 그 뒤로는 스크롤하거나 창 크기를 바꿔도 메뉴가 그때의 자리에 남습니다. `Fab` 에 `tooltip` 이 있으면, 마우스로 눌러 연 뒤 포인터가 FAB 위에 머물기만 해도 툴팁이 떠서 이 상태가 됩니다.
- **Web 의 `attributes` 는 버튼에 닿지 않습니다.** 메뉴가 없으면 버튼을 감싼 상자에, 있으면 `Popover` 에 붙습니다. `aria-label` 을 `attributes` 로 줘도 버튼 이름이 되지 않으므로 `tooltip` 을 씁니다.
- **Web 의 메뉴는 대화상자 안의 메뉴로 알립니다.** 트리거에 `aria-haspopup="dialog"` 가 붙고, `Fab` 에는 이 값을 바꾸는 속성이 없습니다.
- **`fabStyle.duration` 은 두 플랫폼 모두 반영되지 않습니다.** `popoverStyle` 의 두 시간 값을 씁니다.
- **Flutter 에서 배율(`AdaptiveScaling`)이 1 이 아니면 FAB 이 배율을 두 번 받습니다.** 예를 들어 배율 1.25 의 `regular` 원형은 폭 70 · 높이 87.5 가 되고 아이콘도 함께 커집니다. Extended 의 높이도 같습니다. 기본 배율 1 에서는 영향이 없습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 추가 생성자 속성 | 없음 | `id` · `classes` · `css` · `attributes` 와 DOM 이벤트 속성(`onClick` 등) |
| `label` 과 `actions` 를 함께 줄 때 | 디버그 빌드는 생성자 assert, 릴리스 빌드는 `label` 을 버립니다 | `label` 을 버립니다 |
| 누를 때 | 0.95배 크기. `primaryPressed` 채움은 칠하지 않습니다 | `primaryPressed` 채움과 0.95배 크기 |
| 메뉴 닫기 | 바깥 누르기 · 행 선택 · 메인 FAB 다시 누르기 | 바깥 누르기 · 행 선택 · 메인 FAB 다시 누르기 · `Escape` |
| 행의 역할 | 버튼 | `menuitem` |
| 긴 라벨 | 한 줄 말줄임 | 한 줄. 말줄임표 없이 잘립니다 |
| `tooltip` | `Semantics(tooltip:)`. 라벨은 아닙니다 | `aria-label` (이름) |
| `Scaffold` 의 FAB 자리 | `Scaffold` 상자의 아래쪽 | `Scaffold` 상자의 아래쪽. 본문이 길면 상자와 함께 내려갈 수 있습니다 |
| 그림자 | `BoxShadow` | CSS `box-shadow` |
| 배율 | `AdaptiveScaling` 을 두 번 받습니다(알려진 제약) | 해당 없음 |

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `trigger` | `W` | 필수 | 메인 FAB 의 내용. 보통 아이콘입니다. Extended 에서는 라벨 앞에 놓입니다 |
| `label` | `W?` | `null` | 주면 Extended 알약이 됩니다. `actions` 와 함께 쓰지 않습니다 |
| `onPressed` | `VoidCallback?` | `null` | 메인 FAB 을 눌렀을 때. `actions` 가 있으면 부르지 않고 메뉴를 여닫습니다 |
| `actions` | `List<FabAction>?` | `null` | 메뉴의 행이 되는 액션 목록 |
| `open` | `bool` | `false` | 메뉴 열림. `onOpenChanged` 가 없으면 처음 값만 읽습니다 |
| `onOpenChanged` | `ValueChanged<bool>?` | `null` | 주면 `open` 으로 열림을 제어합니다 |
| `size` | `CoreFabSize` | `CoreFabSize.regular` | `mini` · `regular` · `large` |
| `expandDirection` | `CoreFabExpandDirection` | `CoreFabExpandDirection.up` | 메뉴가 열리는 방향. `up` · `down` · `left` · `right` · `fan`(`up` 과 같음) |
| `closeIcon` | `W?` | `null` | 메뉴가 열린 동안의 아이콘. 없으면 X |
| `tooltip` | `String?` | `null` | 메인 FAB 의 툴팁. Web 에서는 `aria-label` 도 됩니다 |
| `fabStyle` | `CoreFabStyle?` | `null` | FAB · 메뉴의 겉모습. 아래 필드 표를 봅니다 |

### `FabAction`

`FabAction` 은 `CoreFabAction<W>` 의 별칭입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `icon` | `W` | 필수 | 행 앞의 아이콘 |
| `label` | `W?` | `null` | 행의 라벨 |
| `onPressed` | `VoidCallback?` | `null` | 행을 눌렀을 때. 부른 뒤 메뉴가 닫힙니다 |
| `tooltip` | `String?` | `null` | 행의 툴팁. Web 에서는 `aria-label` 도 됩니다 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFabStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `buttonStyle` | `CoreButtonStyle?` | Look of the main FAB circle — background, foreground, shadow, radius, focus ring. Passed to the `Button` inside as is. `null` (or any unset field) defers to [defaultButtonStyle]. |
| `extendedButtonStyle` | `CoreButtonStyle?` | **Extended** (라벨을 가진) FAB 의 버튼 모양 — 배경, 글자색, 그림자, 모서리 등. 안에 있는 `Button` 에 그대로 전달된다. |
| `actionItemStyle` | `CoreMenuItemStyle?` | Look of each action row, passed as is to the row's `MenuItem`. `null` (or any unset field) defers to [defaultActionItemStyle], which sets only the row corner (8): otherwise the row is the `MenuItem` at `CoreFabContract.actionItemSize` as it draws itself. |
| `actionButtonStyle` | `CoreButtonStyle?` | **Deprecated (since 0.164)** — Use actionItemStyle — the action rows are MenuItem rows now, so their look is a CoreMenuItemStyle. Look of the action rows, given as a `Button` style. |
| `actionLabelTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.164)** — Use actionItemStyle.labelStyle — the label belongs to the composed MenuItem row. The action-row label style of the `Button` rows. Still honoured as the row's `labelStyle` under [actionItemStyle] (see [effectiveActionItemStyle]). |
| `actionIconStyle` | `CoreIconStyle?` | **Deprecated (since 0.164)** — Use actionItemStyle.leadingIconStyle — the glyph belongs to the composed MenuItem row. The action-row leading icon style of the `Button` rows. Still honoured as the row's `leadingIconStyle` under [actionItemStyle] (see [effectiveActionItemStyle]). |
| `diameter` | `double?` | Main FAB circular diameter override (logical px). `null` defers to [defaultsBySize] for the active size. Forwarded to the composed `Button`'s `width` / `height` — the single entry point for both, so a `height` / `width` in [buttonStyle] is overridden by this. |
| `iconStyle` | `CoreIconStyle?` | Main FAB icon style override — styles the icon glyph the FAB passes as the composed `Button`'s child (its `size` is the only source of the glyph size; a `color` pins the glyph colour). `null` defers to [defaultsBySize] for the active size. A `leadingIconStyle` stated in [buttonStyle] merges on top of this for every field except `size`. |
| `spacing` | `double?` | Gap between the main FAB and the menu panel (logical px) override. Pure placement-offset scalar — never consumed as a flex gap by `Gap` / CSS `gap`. |
| `duration` | `Duration?` | Menu open / close animation duration override — the panel's own open / close motion, unless [popupStyle] pins one. |
| `popoverStyle` | `CorePopoverStyle?` | Style of the `Popover` that hosts the menu, passed to it as is. `null` (or any unset field) defers to [defaultPopoverStyle], which draws no box, because the visible box is the `Popup` in [popupStyle]. Override it e.g. to tune the placement offset. |
| `popupStyle` | `CorePopupStyle?` | Look of the menu panel — the `Popup` that holds the action rows, passed to it as is. `null` (or any unset field) defers to [defaultPopupStyle] — the Fab's own card. |

<!-- STYLE_TABLE:END -->

<Note>

`duration` 은 지금 두 플랫폼 모두 메뉴가 열리고 닫히는 시간에 반영되지 않습니다. `Popover` 가 읽는 시간은 `popoverStyle` 의 `openAnimationDuration` · `closeAnimationDuration` 입니다. 위 표의 설명은 소스 주석에서 만든 것입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card component="button" label="저장하기" title="Button">

화면 안에 자리 잡는 행동에 씁니다. [Button 문서](/components/button)

</Card>
<Card title="DropdownMenu">

트리거를 눌러 행동 목록을 엽니다. [DropdownMenu 문서](/components/dropdown-menu)

</Card>
<Card title="Tooltip">

아이콘만 있는 요소에 짧은 도움말을 붙입니다. `Fab` 의 `tooltip` 속성도 이 컴포넌트를 씁니다. [Tooltip 문서](/components/tooltip)

</Card>
<Card title="Scaffold">

`floatingActionButton` 자리에 FAB 을 놓습니다. [Scaffold 문서](/components/scaffold)

</Card>
</Cards>
