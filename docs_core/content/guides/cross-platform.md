---
title: 크로스 플랫폼
description: Flutter와 Jaspr Web에 같은 컴포넌트 세트를 제공합니다. 컴포넌트 계약, 디자인 토큰, 파라미터 이름, 데이터 모델, 린트 규칙을 공유합니다.
design: true
---

# 크로스 플랫폼

## 패키지 구조

API는 coui_core에 계약을 먼저 정의하고 두 플랫폼에서 구현합니다.

```text
coui_core          공유 계약 · 토큰 · 데이터 모델
├── coui_flutter   Flutter 구현
└── coui_web       Jaspr Web 구현
```

```dart
abstract interface class CoreCardContract<W> {
  CoreCardVariant get variant;
  W? get header;
  W? get body;
  W? get footer;
  void Function()? get onTap;
  CoreCardStyle? get cardStyle;
}
```

## 같은 코드

슬롯 이름과 Text가 양쪽에서 같아 Flutter와 Web 코드가 글자 그대로 같습니다.

<Code language="dart" title="Flutter · Web">
Card(
  header: Text('Card Title').titleMedium.semiBold,
  body: Text('Description').bodyMedium.onSurfaceVariant,
  footer: Button(
    variant: CoreButtonVariant.primary,
    onPressed: () {},
    child: Text('Action'),
  ),
)
</Code>

## 스타일 체인

종류와 상태는 컴포넌트가 정하고, 개별 속성을 바꿀 때는 메서드에 값을 전달합니다. 예를 들어 성공 알림의 안쪽 여백을 줄이거나 입력 필드의 기본 테두리 색을 고를 수 있습니다.

<Code language="dart" title="Flutter · Web">
Alert(title: '저장 완료').success.contentPadding(.all(CoreSpace.space8))
TextField().borderColor(.outlineVariant).borderWidth(CoreStrokeWidth.stroke2)
</Code>

| 지원 메서드 | 컴포넌트 |
| --- | --- |
| `.contentPadding(...)`, `.borderColor(...)`, `.borderWidth(...)`, `.foregroundColor(...)` | Alert, Badge, Banner, Button, Chip, DisclosureBadge, Tag |
| `.contentPadding(...)`, `.borderColor(...)`, `.borderWidth(...)` | Card, ChipInput, CodeSnippet, DescriptionCard, Dock, Fieldset, FileInput, FormattedInput, MultiAnswerCard, ObjectInput, OptionItem, OutlinedContainer, PhoneInput, Popup, SidebarHeader, SidebarSearch, Stat, TextArea, TextField |
| `.borderColor(...)`, `.borderWidth(...)`, `.foregroundColor(...)` | ResizableTable, Table |
| `.borderColor(...)`, `.borderWidth(...)` | Accordion, AvatarBadge, AvatarGroup, ColorPicker, Command, Diff, FocusOutline, InputOtp, ItemPicker, MockupBrowser, MockupDevice, Sidebar, TabPane, Tabs |
| `.contentPadding(...)`, `.foregroundColor(...)` | CommandSearch, MenuItem |
| `.contentPadding(...)` | AppBar, Basic, BottomActionBar, CarouselBanner, DotIndicator, EmptyState, Filter, Footer, Hero, ListRow, Listing, MockupCode, NavigationBar, PanelHeader, SidebarItem, SidebarSection, StepItem, Toggle, ToggleGroup |
| `.borderWidth(...)` | CodeDiff, ValidationBadge |
| `.borderColor(...)` | WindowPanel |

체인은 기존 Core 스타일에 해당 필드 하나를 병합합니다. 같은 필드를 다시 지정하면 마지막 값이 적용됩니다. `Filter<T>.contentPadding(...)`은 필터 트랙의 안쪽 여백입니다. 각 항목의 여백은 `toggleGroupStyle.itemPadding`으로 정합니다.

## 다른 것

렌더링 방식과 앱 루트, 테스트만 플랫폼마다 다릅니다.

| 항목 | Flutter | Jaspr Web |
|---|---|---|
| 앱 루트 | `CoUIApp` | `CoUIWeb` |
| 렌더링 | Flutter 위젯 | CSS |
| 라이트와 다크 | `themeMode` | `data-theme` 속성 |
| 테스트 | widget test | unit test |

## 개발 규칙

1. API는 coui_core에 계약을 먼저 정의하고 양쪽에 구현합니다.
2. child 대신 title, content, footer 같은 이름 있는 파라미터를 우선합니다.
3. 가능하면 String을 받아 내부에서 Text로 바꿉니다.
4. 하드코딩한 duration 대신 CoreDuration을 참조합니다.
5. Flutter widget test와 Web unit test를 따로 작성합니다.
6. 루트 analysis_options.yaml의 린트 규칙을 양쪽 패키지에 적용합니다.
7. coui_flutter.dart와 coui_web.dart의 barrel export를 맞춥니다.
