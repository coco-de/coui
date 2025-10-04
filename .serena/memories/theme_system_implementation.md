# CoUI Web 테마 시스템 구현 완료

## 구현 완료 사항

### 1. 통합 테마 시스템 생성

**파일 구조**:
```
packages/coui_web/lib/src/theme/
├── brightness.dart          # 라이트/다크 모드 열거형
├── color_scheme.dart        # 색상 스킴 (Material/DaisyUI/shadcn 통합)
├── typography_scale.dart    # 타이포그래피 스케일 시스템
├── spacing_scale.dart       # 스페이싱 스케일 시스템
├── radius_scale.dart        # 반경 스케일 시스템
├── theme_data.dart          # 메인 테마 데이터 클래스
├── theme.dart               # Export 파일
└── README.md                # 사용 문서
```

### 2. 주요 기능

#### 색상 시스템 (ColorScheme)
- **Brightness**: light/dark 모드 지원
- **기본 색상**: primary, secondary, error 및 on-color variants
- **표면 색상**: background, surface
- **유틸리티 색상**: outline
- **CSS 변수 변환**: `toCssVariables()`
- **DaisyUI 테마 변환**: `toDaisyUITheme()`

#### 타이포그래피 스케일 (TypographyScale)
- **Material Design 3 스케일**:
  - Display: 57px, 45px, 36px
  - Headline: 32px, 28px, 24px
  - Title: 22px, 16px, 14px
  - Body: 16px, 14px, 12px
  - Label: 14px, 12px, 11px

- **shadcn 스케일**:
  - Display: 72px, 60px, 48px (더 크고 대담함)
  - Headline: 36px, 30px, 24px
  - 기타 유사하지만 line-height 차이

- **스케일링 지원**: `scale(double factor)` 메서드로 전체 크기 조절

#### 스페이싱/반경 시스템
- **SpacingScale**: 4px 기반 (xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
- **RadiusScale**:
  - Material 3: xs:4 ~ xxl:28
  - shadcn: xs:2 ~ xxl:16 (더 작고 세련됨)

#### 메인 테마 데이터 (ThemeData)
```dart
class ThemeData {
  final ColorScheme colorScheme;
  final TypographyScale typography;
  final SpacingScale spacing;
  final RadiusScale radius;
  final double textScaling;
  final double sizeScaling;
  final double radiusScaling;
}
```

**프리셋 테마**:
- `ThemeData.lightMaterial` - Material Design 3 라이트
- `ThemeData.darkMaterial` - Material Design 3 다크
- `ThemeData.lightShadcn` - shadcn/ui 라이트
- `ThemeData.darkShadcn` - shadcn/ui 다크

### 3. 핵심 메서드

#### copyWith()
```dart
theme.copyWith(
  colorScheme: customColors,
  textScaling: 1.25,
)
```

#### scale()
```dart
// 모바일용 1.25배 확대
final mobileTheme = theme.scale(
  textScaling: 1.25,
  sizeScaling: 1.25,
  radiusScaling: 1.0,
);
```

#### toCssVariables()
```dart
final cssVars = theme.toCssVariables();
// {
//   '--color-primary': '#3b82f6',
//   '--text-display-large': 'font-size: 57px; line-height: 1.12; ...',
//   '--spacing-md': '16px',
//   '--radius-md': '12px',
//   ...
// }
```

#### toDaisyUITheme()
```dart
final daisyTheme = theme.toDaisyUITheme();
// {
//   'primary': '#3b82f6',
//   'primary-content': '#ffffff',
//   'base-100': '#ffffff',
//   ...
// }
```

### 4. 린트 검사 결과

✅ **테마 파일 오류 없음**:
```
dart analyze /Users/dongwoo/Development/cocode/uiux/coui/packages/coui_web/lib/src/theme/
Analyzing theme...
No issues found!
```

⚠️ **기존 패키지 경고**:
- VoidCallback 중복 export (기존 문제)
- Unused import 경고 (기존 문제)
- 새 테마 시스템과 무관

### 5. 사용 예시

#### 기본 테마 적용
```dart
import 'package:coui_web/src/theme/theme.dart';

final theme = ThemeData.lightMaterial;
final cssVars = theme.toCssVariables();

// HTML에 CSS 변수 적용
// <div style="${cssVars.entries.map((e) => '${e.key}: ${e.value}').join('; ')}">
```

#### 반응형 스케일링
```dart
// 데스크톱
final desktopTheme = ThemeData.lightMaterial;

// 태블릿 (1.1배)
final tabletTheme = desktopTheme.scale(
  textScaling: 1.1,
  sizeScaling: 1.1,
);

// 모바일 (1.25배)
final mobileTheme = desktopTheme.scale(
  textScaling: 1.25,
  sizeScaling: 1.25,
);
```

#### 커스텀 테마
```dart
final customTheme = ThemeData(
  colorScheme: ColorScheme.light.copyWith(
    primary: '#6366f1',  // Indigo
  ),
  typography: TypographyScale.shadcn,
  spacing: SpacingScale.material3,
  radius: RadiusScale.shadcn,
);
```

## 다음 단계

### 1. 테마 프로바이더 구현 (권장)
```dart
// packages/coui_web/lib/src/theme/theme_provider.dart
class ThemeProvider extends StatelessComponent {
  final ThemeData theme;
  final Component child;
  
  @override
  Component build(BuildContext context) {
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

### 2. 테마 컨트롤러 (런타임 전환)
```dart
class ThemeController {
  ThemeData _currentTheme = ThemeData.lightMaterial;
  
  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    _applyToDom();
  }
  
  void toggleDarkMode() {
    _currentTheme = _currentTheme.brightness == Brightness.light
      ? ThemeData.darkMaterial
      : ThemeData.lightMaterial;
    _applyToDom();
  }
  
  void _applyToDom() {
    final root = document.documentElement!;
    final cssVars = _currentTheme.toCssVariables();
    
    cssVars.forEach((key, value) {
      root.style.setProperty(key, value);
    });
  }
}
```

### 3. 컴포넌트 통합
```dart
// Button 컴포넌트에서 테마 사용
class Button extends UiComponent {
  @override
  Component build(BuildContext context) {
    final theme = Theme.of(context);  // 테마 가져오기
    
    return DomComponent(
      tag: 'button',
      styles: Styles.combine([
        Styles.background(color: 'var(--color-primary)'),
        Styles.text(color: 'var(--color-on-primary)'),
        Styles.borderRadius('var(--radius-md)'),
        Styles.padding('var(--spacing-md)'),
      ]),
      child: child,
    );
  }
}
```

### 4. Tailwind 설정 자동 생성
```javascript
// tailwind.config.js 생성기
export function generateTailwindConfig(theme) {
  return {
    theme: {
      extend: {
        colors: {
          primary: theme.colorScheme.primary,
          secondary: theme.colorScheme.secondary,
          // ...
        },
        borderRadius: {
          xs: theme.radius.xs + 'px',
          sm: theme.radius.sm + 'px',
          // ...
        },
      },
    },
  };
}
```

## 성능 최적화

### CSS 변수 캐싱
```dart
class ThemeData {
  Map<String, String>? _cssVariablesCache;
  
  Map<String, String> toCssVariables() {
    return _cssVariablesCache ??= {
      ...colorScheme.toCssVariables(),
      ...typography.toCssVariables(),
      ...spacing.toCssVariables(),
      ...radius.toCssVariables(),
    };
  }
}
```

## 테스트 계획

### 1. 유닛 테스트
- [ ] ColorScheme 변환 테스트
- [ ] Typography 스케일링 테스트
- [ ] ThemeData copyWith 테스트
- [ ] CSS 변수 생성 테스트

### 2. 통합 테스트
- [ ] 테마 전환 테스트
- [ ] 반응형 스케일링 테스트
- [ ] DaisyUI 테마 매핑 테스트

### 3. 시각적 테스트
- [ ] 컴포넌트별 테마 적용 확인
- [ ] 다크모드 전환 확인
- [ ] 스케일링 시각적 확인
