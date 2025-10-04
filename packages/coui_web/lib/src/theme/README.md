# CoUI Web Theme System

통합 테마 시스템으로 Material Design, DaisyUI, shadcn 스타일을 모두 지원합니다.

## 특징

- ✅ **다중 디자인 시스템 지원**: Material Design 3, shadcn/ui 스타일
- ✅ **타이포그래피 스케일**: 반응형 텍스트 크기 자동 조절
- ✅ **일관된 스페이싱**: 4px 기반 간격 시스템
- ✅ **유연한 반경**: 컴포넌트별 border-radius 커스터마이징
- ✅ **다크모드 지원**: 라이트/다크 테마 자동 전환
- ✅ **CSS 변수**: 런타임 테마 변경 가능

## 사용법

### 1. 기본 테마 사용

```dart
import 'package:coui_web/src/theme/theme.dart';

// Material Design 3 라이트 테마
final theme = ThemeData.lightMaterial;

// shadcn 스타일 다크 테마
final darkTheme = ThemeData.darkShadcn;
```

### 2. 커스텀 테마 생성

```dart
final customTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: '#3b82f6',
    onPrimary: '#ffffff',
    // ... 기타 색상
  ),
  typography: TypographyScale.material3,
  spacing: SpacingScale.material3,
  radius: RadiusScale.shadcn,  // shadcn 스타일 반경 사용
);
```

### 3. 스케일링 적용

```dart
// 모바일용 1.25배 확대
final mobileTheme = theme.scale(
  textScaling: 1.25,
  sizeScaling: 1.25,
  radiusScaling: 1.0,
);

// 태블릿용
final tabletTheme = theme.scale(
  textScaling: 1.1,
  sizeScaling: 1.1,
);
```

### 4. CSS 변수 생성

```dart
// CSS custom properties로 변환
final cssVars = theme.toCssVariables();

// HTML에 적용
// <div style="--color-primary: #3b82f6; ...">
```

### 5. DaisyUI 테마 변환

```dart
// DaisyUI 테마 객체로 변환
final daisyTheme = theme.toDaisyUITheme();

// Tailwind config에서 사용
// daisyui: {
//   themes: [{
//     light: { ...daisyTheme }
//   }]
// }
```

## 테마 구성요소

### 색상 스킴 (ColorScheme)

```dart
ColorScheme(
  brightness: Brightness.light,
  primary: '#3b82f6',
  onPrimary: '#ffffff',
  secondary: '#8b5cf6',
  onSecondary: '#ffffff',
  error: '#ef4444',
  onError: '#ffffff',
  background: '#ffffff',
  onBackground: '#18181b',
  surface: '#ffffff',
  onSurface: '#18181b',
  outline: '#d4d4d8',
)
```

### 타이포그래피 스케일 (TypographyScale)

```dart
TypographyScale.material3  // Material Design 3
TypographyScale.shadcn     // shadcn/ui

// 포함된 스타일:
- displayLarge (57px)
- displayMedium (45px)
- displaySmall (36px)
- headlineLarge (32px)
- headlineMedium (28px)
- headlineSmall (24px)
- titleLarge (22px)
- titleMedium (16px)
- titleSmall (14px)
- bodyLarge (16px)
- bodyMedium (14px)
- bodySmall (12px)
- labelLarge (14px)
- labelMedium (12px)
- labelSmall (11px)
```

### 스페이싱 스케일 (SpacingScale)

```dart
SpacingScale.material3  // 4px 기반
SpacingScale.shadcn     // 4px 기반

// 사이즈:
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- xxl: 48px
```

### 반경 스케일 (RadiusScale)

```dart
RadiusScale.material3  // Material 스타일
RadiusScale.shadcn     // shadcn 스타일

// Material 반경:
- xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 20px, xxl: 28px

// shadcn 반경:
- xs: 2px, sm: 4px, md: 6px, lg: 8px, xl: 12px, xxl: 16px
```

## 플랫폼별 통합

### Flutter (coui_flutter)와 일관성

```dart
// Flutter 테마와 동일한 API
final flutterTheme = ThemeData(/* ... */);

// Web 테마로 변환
final webTheme = ThemeData(
  colorScheme: ColorScheme(
    primary: flutterTheme.colorScheme.primary.toHex(),
    // ...
  ),
  // ...
);
```

## CSS 변수 사용

생성된 CSS 변수를 사용하여 컴포넌트 스타일링:

```css
.button {
  background-color: var(--color-primary);
  color: var(--color-on-primary);
  border-radius: var(--radius-md);
  padding: var(--spacing-md);
}

.text-display {
  font-size: var(--text-display-large);
}
```

## 다크모드 전환

```dart
// 테마 전환
ThemeData currentTheme = ThemeData.lightMaterial;

void toggleDarkMode() {
  currentTheme = currentTheme.brightness == Brightness.light
    ? ThemeData.darkMaterial
    : ThemeData.lightMaterial;

  // CSS 변수 업데이트
  updateCssVariables(currentTheme.toCssVariables());
}
```
