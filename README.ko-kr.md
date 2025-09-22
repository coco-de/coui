# CoUI

[![pub version](https://img.shields.io/pub/v/coui.svg)](https://pub.dev/packages/coui)

**Flutter + Jaspr => CoUI**

Flutter 모바일 앱과 Jaspr 웹 애플리케이션을 위한 통합 디자인 시스템으로, 타입 안전한 Dart 구현의 모던 UI 컴포넌트를 제공합니다. 단일 코드베이스로 모든 플랫폼에서 아름답고 일관된 인터페이스를 구축하세요.

## 🌟 설계 원칙

- **🎯 타입 안전성** - 컴파일 시점에 스타일링 오류 감지
- **🔧 플루언트 API** - 직관적인 메소드 체이닝  
- **📱 크로스 플랫폼** - Flutter 모바일 + Jaspr 웹 지원
- **🎨 모던 디자인** - coui/ui와 DaisyUI에서 영감을 받은 디자인
- **⚡ 성능 최적화** - 최소한의 런타임 오버헤드
- **🛠️ 템플릿 지원** - 코드 생성 및 템플릿 구축에 최적화

## 🚀 시작하기

### 의존성 추가

CoUI를 pubspec.yaml에 추가하세요:

```yaml
dependencies:
  coui: ^0.1.0
  # Flutter 프로젝트용
  coui_flutter: ^0.1.0
  # Jaspr 웹 프로젝트용
  coui_web: ^0.1.0
```

### Flutter 설정

```dart
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CoUITheme.lightTheme(),
      darkTheme: CoUITheme.darkTheme(),
      home: MyHomePage(),
    );
  }
}
```

### Jaspr 웹 설정

Jaspr용 CoUI는 올바른 스타일링을 위해 프로젝트에 Tailwind CSS가 설정되어 있어야 합니다.

```dart
import 'package:jaspr/jaspr.dart';
import 'package:coui_web/coui_web.dart';

class MyComponent extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield CoUIProvider([
      // 여기에 컴포넌트들을 추가하세요
    ]);
  }
}
```

## 💡 사용 예제

### Flutter 예제

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FlutterExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CoButton(
            '클릭하세요',
            variant: CoButtonVariant.primary,
            size: CoButtonSize.lg,
            onPressed: () => print('버튼이 클릭되었습니다!'),
          ),
          CoCard(
            child: CoText('Flutter에서 안녕하세요!'),
            elevation: 2,
          ),
          CoInput(
            placeholder: '텍스트를 입력하세요...',
            onChanged: (value) => print(value),
          ),
        ],
      ),
    );
  }
}
```

### Jaspr 웹 예제

```dart
import 'package:coui_web/coui_web.dart';

class JasprExample extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div([
      CoButton(
        [text('클릭하세요')],
        style: [
          CoButton.primary,
          CoButton.lg,
        ],
        onClick: (_) => print('버튼이 클릭되었습니다!'),
      ),
      CoCard([
        text('Jaspr 웹에서 안녕하세요!'),
      ]),
      CoInput(
        placeholder: '텍스트를 입력하세요...',
        onInput: (value) => print(value),
      ),
    ]);
  }
}
```

## 📦 패키지 구조

```
packages/
├── coui/              # 핵심 디자인 토큰과 타입
├── coui_flutter      # Flutter 구현
├── coui_web/          # Jaspr 웹 구현
└── coui_cli/          # 코드 생성 CLI 도구
```

## 🎯 컴포넌트 로드맵

### ✅ 1단계: 기초 컴포넌트
필수 구성 요소 - 현재 사용 가능

- **Button** - Primary, secondary, destructive 변형
- **Input** - 유효성 검사 상태가 있는 텍스트 입력  
- **Card** - elevation이 있는 콘텐츠 컨테이너
- **Badge** - 상태 표시기 및 라벨
- **Alert** - 알림 및 경고 메시지
- **Avatar** - 사용자 프로필 이미지 및 대체 이미지
- **Separator** - 시각적 콘텐츠 구분선

### 🔄 2단계: 폼 컴포넌트
폼 입력 및 유효성 검사 (진행 중)

- **Checkbox** - 불확정 상태가 있는 불린 선택
- **RadioGroup** - 단일 선택
- **Switch** - 토글 불린 입력
- **Textarea** - 멀티라인 텍스트 입력
- **Select** - 검색 기능이 있는 드롭다운 선택
- **Combobox** - 사용자 정의 옵션이 있는 검색 가능한 드롭다운
- **Slider** - 범위 값 선택
- **Progress** - 작업 완료 표시기

### 📋 3단계: 네비게이션 및 레이아웃
페이지 구조 및 네비게이션

- **Tabs** - 탭 콘텐츠 인터페이스
- **Breadcrumb** - 네비게이션 계층 구조
- **Pagination** - 페이지 네비게이션 컨트롤
- **Navigation Menu** - 헤더 및 사이드바 네비게이션
- **Menubar** - 애플리케이션 메뉴 바
- **Accordion** - 확장 가능한 콘텐츠 섹션
- **Collapsible** - 콘텐츠 가시성 토글

### 🎨 4단계: 데이터 표시
정보 프레젠테이션

- **Table** - 정렬/필터링이 가능한 구조화된 데이터
- **Data Table** - 액션이 있는 향상된 테이블
- **Calendar** - 날짜 선택 및 표시
- **Date Picker** - 달력 팝업이 있는 날짜 입력
- **Time Picker** - 시간 선택 인터페이스
- **Skeleton** - 로딩 상태 플레이스홀더
- **Tooltip** - 컨텍스트 도움말 및 정보

### 🚀 5단계: 피드백 및 오버레이
사용자 알림 및 대화상자

- **Dialog** - 모달 대화상자 및 확인창
- **Sheet** - 하단 시트 및 사이드 패널
- **Drawer** - 슬라이딩 네비게이션 패널
- **Popover** - 컨텍스트 콘텐츠 오버레이
- **Toast** - 알림 메시지
- **Sonner** - 고급 토스트 알림
- **Context Menu** - 우클릭 및 길게 누르기 메뉴

### 🎮 6단계: 고급 컴포넌트
복잡한 상호작용 및 레이아웃

- **Command** - 명령 팔레트 인터페이스
- **Resizable** - 크기 조절 가능한 패널 및 레이아웃
- **Carousel** - 콘텐츠 슬라이더 및 갤러리
- **Toggle Group** - 다중 토글 선택
- **Input OTP** - 일회용 비밀번호 입력
- **Form** - 폼 유효성 검사 및 제출
- **Charts** - 데이터 시각화 컴포넌트

## 🛠️ 코드 생성 지원

CoUI는 템플릿 생성을 염두에 두고 구축되어 AI 기반 앱 생성 플랫폼에 완벽합니다:

```dart
// 컴포넌트 생성을 위한 CLI 사용법
coui generate button --name="SubmitButton" --variant="primary" --size="lg"
coui generate form --fields="email,password,confirmPassword"
coui generate page --template="dashboard" --components="card,table,chart"
```

## 🎨 테마 및 커스터마이징

### Flutter 테마 설정

```dart
CoUITheme.custom(
  colorScheme: CoUIColorScheme(
    primary: Colors.blue,
    secondary: Colors.green,
    // ... 기타 색상
  ),
  typography: CoUITypography.custom(
    // 사용자 정의 폰트 스타일
  ),
)
```

### Jaspr CSS 변수

```css
:root {
  --coui-primary: 220 100% 50%;
  --coui-secondary: 150 100% 40%;
  --coui-background: 0 0% 100%;
  --coui-foreground: 0 0% 10%;
  /* ... 기타 변수 */
}
```

## 🤝 기여하기

기여를 환영합니다! 자세한 내용은 [기여 가이드](CONTRIBUTING.md)를 참조하세요.

## 📄 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🔗 링크

- **문서**: [coui-docs.web.app](https://coui-docs.web.app)
- **Flutter 예제**: [flutter-coui.web.app](https://flutter-coui.web.app)
- **Jaspr 예제**: [jaspr-coui.web.app](https://jaspr-coui.web.app)
- **Pub.dev**: [pub.dev/packages/coui](https://pub.dev/packages/coui)

## 🌟 영감을 받은 프로젝트

CoUI는 다음 훌륭한 프로젝트들에서 영감을 받았습니다:
- [coui/ui](https://ui.coui.com/) - 모던 React 컴포넌트 라이브러리
- [DaisyUI](https://daisyui.com/) - 시맨틱 CSS 프레임워크
- [Flutter CocnUI](https://flutter-coui-ui.mariuti.com/) - Flutter용 coui/ui
- [Coui Web](https://coui_web-doc.web.app/) - Jaspr용 DaisyUI

---

**Dart & Flutter 커뮤니티를 위해 ❤️로 제작되었습니다*