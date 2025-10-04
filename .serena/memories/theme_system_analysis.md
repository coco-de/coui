# CoUI 테마 시스템 분석 및 통합 전략

## 현재 테마 시스템 진단

### 1. Flutter (coui_flutter) - 객체 기반 테마 시스템

**구조**:
- `ThemeData` 클래스: 중앙 집중식 테마 관리
- `Theme.of(context)` 패턴으로 테마 접근
- `ColorScheme`, `Typography`, `IconThemeProperties` 등 구조화된 테마 속성

**핵심 속성**:
```dart
class ThemeData {
  final ColorScheme colorScheme;        // 색상 시스템
  final Typography typography;          // 타이포그래피
  final double radius;                  // 기본 반경 배율 (0.5)
  final double scaling;                 // 크기 배율 (1.0)
  final IconThemeProperties iconTheme;  // 아이콘 테마
  final double? surfaceOpacity;         // 표면 투명도
  final double? surfaceBlur;            // 표면 블러
}
```

**반응형 스케일링**:
- `AdaptiveScaling`: 플랫폼별 자동 스케일링
  - Desktop: 1.0배
  - Mobile: 1.25배
- 반경, 크기, 텍스트 독립 스케일링 가능

**컴포넌트 스타일 적용**:
```dart
ButtonStyle.primary(
  size: ButtonSize.large,
  density: ButtonDensity.comfortable,
  shape: ButtonShape.rectangle,
)
```

### 2. Web (coui_web) - CSS 유틸리티 기반 시스템

**구조**:
- DaisyUI + Tailwind CSS 클래스 기반
- `Styling` 인터페이스: CSS 클래스 추상화
- `ComponentStyle` + `Breakpoints` mixin: 반응형 지원

**스타일 적용 방식**:
```dart
Button(
  style: [
    Button.primaryStyle,    // 'btn-primary'
    Button.lgStyle,         // 'btn-lg'
    Button.wideStyle,       // 'btn-wide'
  ],
)
```

**문제점**:
- **테마 중앙화 부재**: 전역 테마 시스템 없음
- **하드코딩된 CSS 클래스**: DaisyUI 클래스명 직접 사용
- **색상 커스터마이징 제한**: Tailwind config 수정 필요
- **타이포그래피 불일치**: Flutter의 Typography와 연결 안 됨
- **스케일링 부재**: 반응형 크기 조절 메커니즘 없음

## 핵심 불일치 문제점

### 1. 테마 아키텍처 격차

| 측면 | Flutter | Web | 문제 |
|------|---------|-----|------|
| 테마 접근 | `Theme.of(context)` | 없음 | Web에서 전역 테마 설정 불가 |
| 색상 시스템 | `ColorScheme` 객체 | DaisyUI 클래스 | 동적 색상 변경 불가 |
| 타이포그래피 | `Typography` 객체 | Tailwind 클래스 | 폰트/크기 일관성 없음 |
| 스케일링 | `AdaptiveScaling` | 없음 | 반응형 크기 조절 불가 |
| 반경 시스템 | `radiusXs~Xxl` (계산) | 고정 클래스 | 통일된 반경 시스템 없음 |

### 2. 컴포넌트 스타일 API 불일치

**Flutter**:
```dart
Button(
  style: ButtonStyle.primary(
    size: ButtonSize.large,
    density: ButtonDensity.comfortable,
  ),
)
```

**Web**:
```dart
Button.primary(
  size: ButtonSize.lg,
  density: ButtonDensity.comfortable,
)
// 또는
Button(
  style: [Button.primaryStyle, Button.lgStyle],
)
```

**문제**: 
- Flutter는 통합된 `ButtonStyle` 객체
- Web은 분리된 열거형과 CSS 클래스 리스트
- 동일한 코드 작성 불가

### 3. 플랫폼 간 색상 매핑 부재

Flutter의 `ColorScheme`에는:
- primary, secondary, tertiary
- error, warning, success
- surface, background
- onPrimary, onSecondary 등

DaisyUI에는:
- primary, secondary, accent
- info, success, warning, error
- base-100, base-200, base-300

**매핑 전략 필요**: Flutter ColorScheme ↔ DaisyUI 색상 토큰

### 4. 다크모드 지원 불일치

**Flutter**: 
- `ThemeData.dark()` 생성자
- `brightness` 속성으로 라이트/다크 감지

**Web**: 
- DaisyUI 테마 전환 (data-theme 속성)
- 현재 구현에 다크모드 API 없음

## 통합 솔루션 제안

### Phase 1: 공통 테마 추상화 레이어 (coui_core)

```dart
// packages/coui_core/lib/src/theme/theme_data.dart
abstract class CouiThemeData {
  // 색상 시스템
  CouiColorScheme get colorScheme;
  
  // 타이포그래피
  CouiTypography get typography;
  
  // 스페이싱 & 크기
  CouiScaling get scaling;
  
  // 반경 시스템
  CouiRadius get radius;
  
  // 아이콘 테마
  CouiIconTheme get iconTheme;
  
  // 다크모드
  Brightness get brightness;
}

// 색상 시스템 추상화
abstract class CouiColorScheme {
  Color get primary;
  Color get secondary;
  Color get tertiary;
  Color get error;
  Color get warning;
  Color get success;
  Color get info;
  Color get surface;
  Color get background;
  // ... 기타 색상
}

// 타이포그래피 추상화
abstract class CouiTypography {
  TextStyle get displayLarge;
  TextStyle get displayMedium;
  TextStyle get displaySmall;
  TextStyle get headlineLarge;
  // ... 기타 스타일
}

// 스케일링 시스템
class CouiScaling {
  final double textScaling;
  final double sizeScaling;
  final double radiusScaling;
  
  const CouiScaling({
    this.textScaling = 1.0,
    this.sizeScaling = 1.0,
    this.radiusScaling = 1.0,
  });
  
  static const desktop = CouiScaling();
  static const mobile = CouiScaling(
    textScaling: 1.25,
    sizeScaling: 1.25,
    radiusScaling: 1.25,
  );
}
```

### Phase 2: 플랫폼별 구현

**Flutter 구현**:
```dart
// packages/coui_flutter/lib/src/theme/theme_data_impl.dart
class FlutterThemeData extends CouiThemeData {
  final ThemeData _flutterTheme;
  
  FlutterThemeData(this._flutterTheme);
  
  @override
  CouiColorScheme get colorScheme => 
    FlutterColorScheme(_flutterTheme.colorScheme);
    
  @override
  CouiTypography get typography => 
    FlutterTypography(_flutterTheme.typography);
    
  // ... 기타 구현
}

// 어댑터 패턴
class FlutterColorScheme extends CouiColorScheme {
  final ColorScheme _scheme;
  
  FlutterColorScheme(this._scheme);
  
  @override
  Color get primary => _scheme.primary;
  
  @override
  Color get secondary => _scheme.secondary;
  
  // ... 매핑
}
```

**Web 구현 (핵심 개선)**:
```dart
// packages/coui_web/lib/src/theme/web_theme.dart
class WebThemeData extends CouiThemeData {
  final WebColorScheme colorScheme;
  final WebTypography typography;
  final CouiScaling scaling;
  
  const WebThemeData({
    required this.colorScheme,
    required this.typography,
    this.scaling = CouiScaling.desktop,
  });
  
  // Tailwind CSS 변수 생성
  Map<String, String> toCssVariables() {
    return {
      '--color-primary': colorScheme.primary.toRgbString(),
      '--color-secondary': colorScheme.secondary.toRgbString(),
      '--font-size-base': '${typography.bodyMedium.fontSize}px',
      '--radius-md': '${radius.medium * scaling.radiusScaling}px',
      // ... 모든 토큰 매핑
    };
  }
  
  // DaisyUI 테마 객체 생성
  Map<String, dynamic> toDaisyUITheme() {
    return {
      'primary': colorScheme.primary.toHex(),
      'secondary': colorScheme.secondary.toHex(),
      'accent': colorScheme.tertiary.toHex(),
      'info': colorScheme.info.toHex(),
      'success': colorScheme.success.toHex(),
      'warning': colorScheme.warning.toHex(),
      'error': colorScheme.error.toHex(),
      // ... 전체 매핑
    };
  }
}

// Web 색상 구현
class WebColorScheme extends CouiColorScheme {
  final String primary;
  final String secondary;
  // ... CSS 색상 문자열
  
  @override
  Color get primaryColor => Color.fromHex(primary);
  
  // CSS 변수 참조도 지원
  String get primaryVar => 'var(--color-primary)';
}

// 테마 제공자
class CouiThemeProvider extends StatelessComponent {
  final WebThemeData theme;
  final Component child;
  
  @override
  Component build(BuildContext context) {
    // CSS 변수 주입
    final cssVars = theme.toCssVariables();
    
    return DomComponent(
      tag: 'div',
      styles: Styles.raw(cssVars),
      attributes: {
        'data-theme': theme.brightness == Brightness.dark ? 'dark' : 'light',
      },
      child: child,
    );
  }
}
```

### Phase 3: 통합 컴포넌트 스타일 시스템

```dart
// packages/coui_core/lib/src/styles/component_style.dart
abstract class CouiComponentStyle<T> {
  // 공통 스타일 속성
  ComponentVariant? get variant;
  ComponentSize? get size;
  ComponentDensity? get density;
  ComponentShape? get shape;
  
  // 플랫폼별 변환
  T toFlutterStyle();
  List<String> toWebClasses();
}

// 버튼 스타일 예시
class CouiButtonStyle extends CouiComponentStyle<FlutterButtonStyle> {
  final ComponentVariant variant;
  final ComponentSize size;
  final ComponentDensity density;
  
  const CouiButtonStyle({
    this.variant = ComponentVariant.primary,
    this.size = ComponentSize.medium,
    this.density = ComponentDensity.normal,
  });
  
  // Flutter 변환
  @override
  FlutterButtonStyle toFlutterStyle() {
    return ButtonStyle(
      variance: _mapVariant(variant),
      size: _mapSize(size),
      density: _mapDensity(density),
    );
  }
  
  // Web CSS 클래스 생성
  @override
  List<String> toWebClasses() {
    return [
      'btn',
      'btn-${variant.name}',
      'btn-${size.name}',
      if (density != ComponentDensity.normal) 'btn-${density.name}',
    ];
  }
}
```

### Phase 4: 런타임 테마 전환 (Web 개선)

```dart
// packages/coui_web/lib/src/theme/theme_controller.dart
class WebThemeController {
  WebThemeData _currentTheme;
  
  // 테마 변경
  void setTheme(WebThemeData newTheme) {
    _currentTheme = newTheme;
    _applyTheme();
  }
  
  // 다크모드 토글
  void toggleDarkMode() {
    final isDark = _currentTheme.brightness == Brightness.dark;
    setTheme(isDark ? lightTheme : darkTheme);
  }
  
  // 동적 CSS 변수 적용
  void _applyTheme() {
    final root = document.documentElement!;
    final cssVars = _currentTheme.toCssVariables();
    
    cssVars.forEach((key, value) {
      root.style.setProperty(key, value);
    });
    
    root.setAttribute(
      'data-theme', 
      _currentTheme.brightness == Brightness.dark ? 'dark' : 'light',
    );
  }
}

// 사용 예시
final themeController = WebThemeController();

// 앱 초기화
void main() {
  themeController.setTheme(WebThemeData.light());
  runApp(MyApp());
}

// 다크모드 토글 버튼
Button(
  onPressed: () => themeController.toggleDarkMode(),
  child: text('Toggle Dark Mode'),
)
```

### Phase 5: Tailwind 설정 자동화

```javascript
// packages/coui_web/example/tailwind.config.js
import { generateCouiTheme } from '@coui/web-theme';

export default {
  content: [
    './{lib,web}/**/*.dart',
    './build/jaspr/**/*.html',
  ],
  theme: {
    extend: {
      colors: {
        // Dart 테마에서 생성된 색상 토큰
        ...generateCouiTheme({
          primary: '#3b82f6',
          secondary: '#8b5cf6',
          // ...
        }).colors,
      },
      fontSize: {
        // 타이포그래피 토큰
      },
      borderRadius: {
        // 반경 토큰
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        light: {
          // Dart WebThemeData에서 생성
        },
        dark: {
          // Dart WebThemeData에서 생성
        },
      },
    ],
  },
};
```

## 구현 우선순위

### Milestone 1: 테마 추상화 (2주)
- [x] 분석 완료
- [ ] `coui_core/theme` 패키지 생성
- [ ] `CouiThemeData`, `CouiColorScheme`, `CouiTypography` 정의
- [ ] 플랫폼 인터페이스 설계

### Milestone 2: Web 테마 시스템 구현 (3주)
- [ ] `WebThemeData` 구현
- [ ] CSS 변수 생성 로직
- [ ] `CouiThemeProvider` 컴포넌트
- [ ] `WebThemeController` (다크모드 지원)

### Milestone 3: Flutter 어댑터 (1주)
- [ ] `FlutterThemeData` 어댑터
- [ ] 기존 `ThemeData` 호환성 유지
- [ ] 점진적 마이그레이션 지원

### Milestone 4: 컴포넌트 통합 (4주)
- [ ] `CouiButtonStyle` 구현
- [ ] Button 컴포넌트 양쪽 적용
- [ ] 기타 핵심 컴포넌트 (Input, Card, Dialog)

### Milestone 5: 문서화 및 도구 (2주)
- [ ] 테마 마이그레이션 가이드
- [ ] Tailwind 설정 생성 도구
- [ ] 테마 프리뷰 도구 (Widgetbook/Storybook)

## 즉시 해결 가능한 Quick Wins

### 1. Web에 기본 테마 객체 추가
```dart
// packages/coui_web/lib/src/theme/default_theme.dart
class WebTheme {
  static const lightTheme = WebThemeConfig(
    colors: WebColorTokens(
      primary: '#3b82f6',
      secondary: '#8b5cf6',
      // ...
    ),
  );
}
```

### 2. CSS 변수 기반 색상 시스템
현재 하드코딩된 DaisyUI 클래스 대신 CSS 변수 사용:
```dart
Button(
  style: [
    ButtonStyle('btn-primary', type: StyleType.style),
  ],
)
// ↓
Button(
  css: Styles.background(color: 'var(--color-primary)'),
)
```

### 3. 크기 토큰 시스템
```dart
class SizeTokens {
  static const xs = 'var(--size-xs)';
  static const sm = 'var(--size-sm)';
  static const md = 'var(--size-md)';
  static const lg = 'var(--size-lg)';
  static const xl = 'var(--size-xl)';
}
```

## 예상 효과

### 개발자 경험
- ✅ 동일한 API로 Flutter & Web 컴포넌트 작성
- ✅ 한 곳에서 테마 정의, 양쪽 플랫폼 자동 적용
- ✅ 타입 안전한 테마 토큰 사용

### 일관성
- ✅ 색상, 타이포그래피, 스페이싱 완전 일치
- ✅ 다크모드 자동 동기화
- ✅ 반응형 스케일링 양쪽 지원

### 유지보수성
- ✅ 중앙 집중식 테마 관리
- ✅ 플랫폼별 최적화 유지
- ✅ 점진적 마이그레이션 가능
