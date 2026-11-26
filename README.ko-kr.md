# CoUI

**Flutter + Jaspr => CoUI**

**Flutter** 모바일/데스크톱 앱과 **Jaspr** 웹 애플리케이션을 위한 통합 디자인 시스템. 타입 안전한 Dart 컴포넌트, 공유 디자인 토큰, 일관된 크로스 플랫폼 API를 제공합니다.

[![CI](https://github.com/coco-de/coui/actions/workflows/ci.yaml/badge.svg)](https://github.com/coco-de/coui/actions/workflows/ci.yaml)

> [!WARNING]
> **실험 단계** — CoUI는 현재 실험 단계입니다. `1.0.0` 이전에 breaking changes가 발생할 수 있으므로 업그레이드할 때 릴리스 노트와 [deprecation 정책](docs/contributing/upgrading.md#deprecation)을 확인해 주세요. 피드백과 기여를 환영합니다.

[English](README.md) · [Docs 사이트](https://coui.cocode.im/) · [디자인 토큰](https://coui.cocode.im/tokens/overview) · [Widgetbook](https://coui.cocode.studio/)

CoUI 자체를 개선하려면 [기여자 단계별 가이드](docs/contributing/README.md)에서
Core → Flutter/Web → Figma 흐름을 따라가세요. [영문 기여 안내](CONTRIBUTING.md)도 있습니다.

## 주요 특징

- **크로스 플랫폼** — Flutter(모바일/데스크톱)와 Jaspr(웹)를 위한 단일 컴포넌트 라이브러리
- **161개 컴포넌트, 양 플랫폼 동일** — 모든 컴포넌트 contract 가 Flutter·Web 양쪽에 같은 파라미터 이름으로 구현되어 있고, 한쪽이 뒤처지면 CI 가 실패합니다
- **디자인 토큰** — 색상·타이포그래피·간격·반경·모션 스케일이 `coui_core` 한 곳에 있고 양 플랫폼이 공유합니다 ([토큰 레퍼런스](https://coui.cocode.im/tokens/overview))
- **3개 디자인 시스템** — CoUI Web, M3 Expressive (Flutter), Liquid Glass (visionOS/AR)
- **다크 모드** — 양 플랫폼 완전 지원
- **타입 안전** — 컴파일 타임 스타일링 검증

## 빠른 시작

### Flutter

pub.dev에서 Flutter 베타를 설치합니다.

```sh
flutter pub add 'coui_flutter:^0.194.2-beta.1'
```

앱 설정:

```dart
import 'package:coui_flutter/coui_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CoUIApp(
      theme: const ThemeData(),
      darkTheme: const ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}
```

컴포넌트 사용:

```dart
Column(
  children: [
    Button(
      variant: CoreButtonVariant.primary,
      onPressed: handleSubmit,
      child: const Text('제출'),
    ),
    const TextField(placeholder: Text('이름을 입력하세요...')),
    const Badge(tone: CoreBadgeTone.primary, child: Text('신규')),
  ],
)
```

### Jaspr Web

pub.dev에 등록된 릴리스를 설치합니다.

```sh
dart pub add coui_web
```

Jaspr 프로젝트에 Tailwind CSS 설정이 필요합니다.

바로 위 Flutter 코드와 **같은 API** 입니다 — 같은 이름, 같은 슬롯:

```dart
import 'package:coui_web/coui_web.dart';

Button(
  variant: CoreButtonVariant.primary,
  onPressed: handleClick,
  child: const Text('클릭'),
)

TextField(placeholder: const Text('검색...'))
```

## 컴포넌트 카테고리

| 카테고리 | Flutter | Web |
|----------|--------:|----:|
| Display | 36 | 36 |
| Layout | 35 | 35 |
| Form | 31 | 32 |
| Infra | 14 | 11 |
| Overlay | 9 | 9 |
| Control | 6 | 6 |
| Navigation | 5 | 5 |
| Menu | 5 | 5 |
| Text | 3 | 3 |
| Icon | 1 | 1 |
| Locale | — | 1 |

**161개 컴포넌트 contract 가 양 플랫폼 모두에 구현되어 있습니다** — `tool/api_sync_check.dart`
가 CI 에서 이 수를 게이트하므로 드리프트가 불가능합니다. 카테고리별 수량 차이는 한쪽
플랫폼에만 필요한 인프라 파일(Flutter 오버레이/렌더 배관, Web 로케일 scope)에서만 나며,
어느 쪽에도 빠진 contract 는 없습니다.

컴포넌트 목록 자체는 한 곳에만 두고 여기 복제하지 않습니다 — 손으로 쓴 목록은 낡고
그다음엔 거짓이 됩니다. **[coui.cocode.im](https://coui.cocode.im/)** 에서 보거나,
docs 사이트·검색 인덱스·네이티브 docs 앱이 모두 읽는
`docs_core/lib/shared/component_catalog.dart` 를 보세요.

## 패키지 구조

```
packages/
  coui/           # 우산 패키지
  coui_core/      # 플랫폼 독립 디자인 토큰, 컨트랙트, 공유 로직
  coui_flutter/   # Flutter 구현 (Material + CoUI 테마)
  coui_web/       # Jaspr 웹 구현 (CoUI 테마 + Tailwind CSS)
  coui_i10n/      # 공유 로컬라이제이션 문자열
  coui_lints/     # 워크스페이스 공통 린트 규칙
  coui_mcp/       # AI 지원 개발을 위한 MCP 서버 (워크스페이스 멤버 아님)
```

| 패키지 | 설명 | README |
|--------|------|--------|
| `coui_core` | 디자인 토큰 (색상 · 타이포그래피 · 간격 · 반경 · 모션), 3개 디자인 시스템 | — |
| `coui_flutter` | Flutter 위젯, 테마, 컨트롤러 | [README](packages/coui_flutter/README.md) |
| `coui_web` | Jaspr 웹 컴포넌트 | [README](packages/coui_web/README.md) |

## 디자인 토큰 시스템 (`coui_core`)

3개 디자인 시스템을 지원하는 통합 디자인 토큰 시스템:

| 디자인 시스템 | 대상 | 형태 | 모션 | 표면 |
|---------------|------|------|------|------|
| **CoUI Web** | Web (Jaspr) | rounded | CSS transition | flat |
| **M3 Expressive** | Flutter App | squircle | Spring physics | tonalElevation |
| **Liquid Glass** | visionOS/AR | glassRounded | Glass physics | glass |

### 토큰 카테고리

| 카테고리 | 클래스 | 토큰 |
|----------|--------|------|
| Color | `CoreColorScheme` | semantic slots, resolved per brightness / contrast |
| Typography | `CoreTypography` | 22 roles (display · headline · title · body · label · code) |
| Spacing | `CoreSpace` | 46 steps (`space0`–`space256`) |
| Shape | `CoreRadius` | 19 levels (`radius0`–`radius64`, `radius9999`) |
| Size | `CoreComponentSize` | 5 (xs/sm/md/lg/xl) |
| Motion | `CoreDuration` + `CoreEasing` + `CoreSpringConfig` | semantic duration aliases, easing curves, 5 spring presets |
| Surface | `CoreSurfaceToken` | 3 types (flat/tonalElevation/glass) |

### CoreThemeData

```dart
import 'package:coui_core/coui_core.dart';

final theme = CoreThemeData(
  // CoUI 기본 색 — 브랜드 팔레트는 CouiSemanticColors(palette)
  colorScheme: CouiSemanticColors.from(CouiColorPresets.source).light,
  brightness: CoreBrightness.light,          // light | dark
  designSystem: DesignSystem.couiWeb,        // couiWeb | m3Expressive | liquidGlass
  typography: CoreTypography.coui,
);

// 다크 모드 변형
final darkTheme = theme.copyWith(
  colorScheme: darkColors,
  brightness: CoreBrightness.dark,
);
```

### Web 테마

`<html>` 의 `data-theme` 속성으로 테마를 전환합니다. `ThemeConfig` 가
`--coui-*` 변수를 정의하는 테마는 `light` 와 `dark` 둘입니다:

```dart
CoUIThemeController.setTheme(CoUIThemeController.dark);
CoUIThemeController.toggleDarkMode();

// 임의 팔레트는 테마 이름이 아니라 CSS 변수로 주입합니다.
CoUIThemeController.setCustomTheme(myColorScheme);
```

## 개발

[Melos](https://melos.invertase.dev/)로 관리되는 Dart 워크스페이스입니다.

```bash
# Melos 설치
dart pub global activate melos

# 워크스페이스 부트스트랩
melos bootstrap

# 분석 실행
melos run analyze:all

# 테스트 실행
melos run test
```

---

Dart & Flutter 커뮤니티를 위해 제작되었습니다.
