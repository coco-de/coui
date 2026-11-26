# CoUI

CoUI는 Flutter 앱과 Jaspr 웹을 위한 디자인 시스템입니다. Figma에서 고른 버튼, 폼, 내비게이션을 Dart에서도 같은 컴포넌트 이름과 디자인 토큰으로 구현할 수 있습니다. [CoUI 문서](https://coui.cocode.im/) · [English](README.md)

[![패키지 검사](https://github.com/coco-de/coui/actions/workflows/public-ci.yml/badge.svg)](https://github.com/coco-de/coui/actions/workflows/public-ci.yml)

## 버튼부터 만들어 보기

| 플랫폼 | 설치 | 앱 설정 |
| --- | --- | --- |
| Flutter | `flutter pub add coui_flutter` | 앱의 루트에 `CoUIApp`을 두고 테마를 적용합니다. [Flutter 설정](packages/coui_flutter/README.md) |
| Jaspr Web | `dart pub add coui_web` | 앱을 `CoUIWeb`으로 감싸고 테마의 CSS 변수와 Tailwind 설정을 불러옵니다. [Web 설정](packages/coui_web/README.md) |

기본 버튼은 Flutter와 Web에서 이름과 주요 속성이 같습니다. 플랫폼에 맞게 `coui_flutter.dart` 또는 `coui_web.dart`를 불러오세요.

```dart
Button(
  variant: CoreButtonVariant.primary,
  onPressed: saveChanges,
  child: const Text('변경사항 저장'),
)
```

빠른 시작에서 플랫폼을 고르면 앱 설정부터 첫 컴포넌트까지 따라 할 수 있습니다. [빠른 시작](https://coui.cocode.im/getting-started/) · [Button 미리보기와 코드](https://coui.cocode.im/components/button/)

## 디자인 시스템 둘러보기

- **Foundations**에서 색상, 글자, 간격, 모양, 모션의 기준을 확인합니다. Core의 토큰을 Flutter는 위젯 스타일로, Jaspr는 CSS 변수와 Tailwind 유틸리티로 사용합니다. [디자인 토큰](https://coui.cocode.im/tokens/overview/) · [CoUI Core](packages/coui_core/README.md)
- **Components**에서 직접 조작할 수 있는 미리보기와 Flutter·Web 예제를 함께 봅니다. 문서 상단에서 Liquid Glass 같은 서페이스 스타일을 골라 같은 컴포넌트가 어떻게 달라지는지 확인할 수 있습니다. [컴포넌트 카탈로그](https://coui.cocode.im/components-overview/)
- **Blocks**에서 Hero와 Footer처럼 페이지의 한 구간을 구성하는 레이아웃을 살펴봅니다. [블록 카탈로그](https://coui.cocode.im/blocks/)
- **Resources**에서 Figma 라이브러리를 열고, 브랜드 테마를 설정하거나 편집기에서 MCP로 컴포넌트와 토큰을 조회하는 방법을 확인합니다. [Figma 라이브러리](https://coui.cocode.im/guides/figma-library/) · [테마 구성](https://coui.cocode.im/guides/theming/) · [AI · MCP](https://coui.cocode.im/guides/mcp/)

## 기여하기

기여 가이드에서 개발 환경을 설정하고, Core의 변경을 Flutter·Web·Figma에 반영하고 확인하는 방법을 살펴보세요. [한국어 기여 가이드](docs/contributing/README.md) · [영문 기여 안내](CONTRIBUTING.md)

CoUI는 1.0 이전 버전으로, 릴리스 사이에 공개 API가 바뀔 수 있습니다. 업그레이드할 때 변경 이력과 지원 종료 정책을 확인하세요. [변경 이력](https://coui.cocode.im/changelog/) · [지원 종료 정책](docs/contributing/upgrading.md#deprecation)

## 라이선스와 출처

CoUI는 Cocode Inc.에서 관리합니다. 원본 프로젝트와 제3자 라이선스 조건은 저장소의 NOTICE에 기록되어 있습니다. [라이선스](LICENSE) · [제3자 고지](NOTICE) · [Cocode](https://cocode.im/)
