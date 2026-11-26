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
