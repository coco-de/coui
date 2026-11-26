# 컴포넌트별 재질과 Liquid Glass 내비게이션

`AppBar`와 `NavigationBar`는 `surfaceStyle`을 기존 스타일 슬롯에서 받는다.
우선순위는 **전역 재질 → 컴포넌트 테마 → variant 테마 → 인스턴스 스타일**이다.
`null`은 상속, `defaultStyle`은 명시적인 불투명 재질이다. 재질을 교체해도
팔레트·글꼴·밀도·사용자가 지정한 치수는 그대로 유지한다.

```dart
final theme = ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    appBar: CoreAppBarTheme(
      style: CoreAppBarStyle(surfaceStyle: .liquidGlass),
    ),
    navigationBar: CoreNavigationBarTheme(
      style: CoreNavigationBarStyle(surfaceStyle: .liquidGlass),
    ),
  ),
);

// 이 인스턴스만 불투명하게 그린다. Flutter와 Web의 스타일 API가 같다.
AppBar(
  title: const Text('Settings'),
  appBarStyle: const CoreAppBarStyle(surfaceStyle: .defaultStyle),
);
```

콘텐츠 표면(`Card`, `OutlinedContainer`)도 같은 방식으로 한 개씩 재질을 정한다.
`CoreCardStyle`·`CoreOutlinedContainerStyle`의 `surfaceStyle`이 Flutter와 Web에서 같은
호출이다. 유리 테마 안의 카드 하나만 불투명하게 두려면 `defaultStyle`을 준다.

```dart
Card(
  cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
  body: const Text('Opaque content'),
);
```

Flutter에서 하위 트리 전체에 재질만 지정하려면 `SurfaceTheme`을 쓴다. Web에는 하위 트리
단위 대응이 없다.
이 스코프는 색상·기하·타이포그래피 축을 재적용하지 않는다. 따라서 그림자나
모서리 변경까지 포함한 전체 프리셋 변경은 기존 `CoUIApp.surfaceStyle`을 사용한다.

```dart
SurfaceTheme(
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
  child: Card(child: const Text('Local glass')),
);

SurfaceTheme(
  surfaceStyle: CoreSurfaceStyleId.defaultStyle,
  child: Card(child: const Text('Opaque content')),
);
```

## 스크롤 콘텐츠와 함께 쓰기

배경 콘텐츠가 바 뒤로 지나가야 유리의 블러와 굴절이 보인다. Flutter의
`Scaffold`에서 `floatingHeader`·`floatingFooter`를 사용하고, 본문에는 바 높이만큼
스크롤 패딩을 둔다. Liquid Glass의 floating 헤더는 내부 컨트롤이 재질을 소유하며,
Builder로 AppBar를 감싼 경우에도 Scaffold가 사각 유리를 덧칠하지 않는다.
명시한 scaffoldStyle.headerBackgroundColor는 유지한다. 단일 NavigationBar인
floating 푸터도 바가 재질을 소유한다.

```dart
// State가 생성·dispose하는 동일한 컨트롤러를 본문과 헤더에 전달한다.
Scaffold(
  floatingHeader: true,
  floatingFooter: true,
  headers: [AppBar(
    title: const Text('Discover'),
    centerTitle: true,
    scrollController: scrollController,
  )],
  footers: [NavigationBar(
    labelMode: CoreNavigationLabelMode.all,
    items: destinations,
    selectedIndex: selectedIndex,
    onSelected: onSelected,
  )],
  child: ListView(
    controller: scrollController,
    padding: const EdgeInsets.only(top: 80, bottom: 104),
    children: content,
  ),
);
```

AppBar의 `scrollController`는 Flutter 전용이며 소유권은 호출자에게 있다.
Liquid Glass AppBar는 기본적으로 투명한 제목·레이아웃 호스트다. leading과
trailing의 연속된 액션은 각각 유리 캡슐 하나로 묶이며, 명시한 ToolbarGroup은
다시 감싸지 않는다. 빈 그룹은 자리를 남기지 않는다. 액션의 유리 효과는
정지 상태에서도 유지된다. 처음 24 logical px 동안은 제목 뒤의 대비용
그라데이션만 나타난다. 전체 바에는 블러·굴절·그림자를 추가하지 않는다.
컨트롤러를 생략하면 대비 그라데이션은 투명하게 유지되고 액션 캡슐은 남는다.
Web은 같은 구성을 사용하고, Scaffold 본문 또는 페이지 스크롤을 감지해 CSS
그라데이션 값만 갱신한다. document 재질 선택을 바꾸면 캡슐 구성도 갱신된다.
명시한 AppBar backgroundColor는 유리 굴절 없이 일반 채움으로 유지한다.
투명도 줄이기·고대비에서는 제목 배경과 컨트롤을 불투명하게 처리한다.
`centerTitle: true`인 유리 바는 좌우 액션 폭이 달라도 바의 중앙을 기준으로
제목을 배치한다. medium variant의 큰 제목을 자동 축소하는 API는 포함하지 않는다.

Flutter의 가로 Glass NavigationBar는 기본적으로 둥근 floating 형태이며,
홈 인디케이터와 화면 가장자리의 SafeArea를 소비한다. `barRadius`, `barMargin`,
`padding`, `itemRadius`, `itemMinHeight`의 명시적 값이 재질 기본값보다 우선한다.
동일 너비의 목적지가 들어가는 경우 선택 캡슐 하나를 스프링 곡선으로 이동한다.
좁은 화면·구분선·섹션·세로 모드는 기존 스크롤 및 항목별 선택 표시를 유지한다.

## 렌더링과 접근성

- 기존 `SurfaceBlur`와 패키지에 포함된 굴절 셰이더를 재사용한다.
  `ImageFilter.isShaderFilterSupported`로 지원 여부를 확인하며, 미지원 엔진에서는
  기존 블러 폴백을 사용한다. 앱의 Impeller 설정을 강제로 바꾸지 않는다.
- 블러 클립은 바의 실제 경계에 한정한다. 바의 바깥 여백은 필터링하지 않는다.
  필터 입력값이 같으면 같은 ImageFilter 객체를 재사용한다.
- 정지한 선택 캡슐에는 추가 필터가 없다. 누르거나 드래그하는 동안만 아이콘과
  텍스트 위에 클립된 굴절 패스를 하나 추가한다. 손을 떼면 광학 효과가 사라지고
  패스를 제거하며, 애니메이션이 끝나면 프레임을 요청하지 않는다.
- 동작 줄이기는 선택 이동과 press/focus 전환을 끈다. Android의
  `MediaQuery.disableAnimations`와 iOS의 `AccessibilityFeatures.reduceMotion`을
  모두 읽으며, 둘 중 하나만 켜져도 같다. 긴 선택 스프링도 표시 시간으로
  오인해 계속 실행하지 않는다.
- `CoUIApp.reduceTransparency` 또는 `ThemeData.reduceTransparency`는 로컬
  재질보다 우선한다. 고대비에서는 테두리를 유지하고 굴절을 끈다.

네이티브 UIKit 뷰를 삽입하는 구현은 아니다. Apple의
[Liquid Glass 재질 가이드](https://developer.apple.com/design/human-interface-guidelines/materials)와
[탭 바 가이드](https://developer.apple.com/design/human-interface-guidelines/tab-bars)를 참고해
Flutter 위젯으로 동작을 구현한다. Impeller 지원 범위는
[Flutter shader 문서](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)를 따른다.
실기기 프레임 시간은 기기·배경 복잡도에 따라 별도 profile 측정이 필요하다.

## 확인용 예제

Widgetbook의 **navigation → AppBar → Default**와
**navigation → NavigationBar → Default**에서 **Addons → Surface material**을
Liquid Glass로 선택한다. Light/Dark 테마와 재질을 각각 바꿀 수 있다. 동일한 화면을 네이티브로 실행하려면:

```sh
cd app/coui_widgetbook
flutter run -d macos -t lib/liquid_glass_preview.dart --enable-impeller
```

## 메뉴와 툴바

[Apple의 Menus and toolbars 지침](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass#Menus-and-toolbars)에
따라 관련 툴바 동작은 배경 하나를 공유하는 `ToolbarGroup`으로 묶는다.
서로 다른 기능은 별도 그룹으로 나누고 그룹 사이에 간격을 둔다.
그룹 안에서는 아이콘 또는 텍스트 표현을 일관되게 사용하며, 아이콘 버튼에는
각각 접근성 라벨을 제공한다. 숨길 버튼은 `children`에서 제외한다.
빈 그룹은 배경을 그리지 않는다. Flutter와 Web 모두 같은 API를 제공한다.

```dart
ToolbarGroup(
  ariaLabel: '편집 기록',
  popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
  children: [
    Semantics(label: '실행 취소', child: Button(
      variant: .ghost,
      shape: .circle,
      onPressed: undo,
      child: const Icon(LucideIcons.undo2),
    )),
    Semantics(label: '다시 실행', child: Button(
      variant: .ghost,
      shape: .circle,
      onPressed: redo,
      child: const Icon(LucideIcons.redo2),
    )),
  ],
);
```

위 코드는 Flutter 예제다. Web에서는 버튼의 `aria-label`을 사용한다.
Liquid Glass AppBar는 명시한 ToolbarGroup을 보존하므로 별도의 투명 스타일
우회 설정이 필요하지 않다. 그룹의 버튼은 기본적으로 44-point 영역을 사용하며,
아이콘을 따로 축소하지 않는다. 명시한 버튼·그룹 스타일은 기본값보다 우선한다.

메뉴의 재질은 `CoreMenuStyle.popupStyle.surfaceStyle`로 지정한다.
DropdownMenu와 ContextMenu도 기존의 `menuStyle` 슬롯으로 같은 설정을 받는다.
Menubar는 `CoreMenubarStyle.surfaceStyle`을 바와 팝업에 전달하며,
`menuPanelStyle.surfaceStyle`로 팝업만 다시 바꿀 수 있다.
Liquid Glass 메뉴는 둥근 패널과 안쪽 행 모서리를 기본으로 사용하고,
명시적인 패널·행 치수는 그대로 우선한다.

```dart
DropdownMenu(
  trigger: moreButton,
  dropdownMenuStyle: const CoreDropdownMenuStyle(
    menuStyle: CoreMenuStyle(
      popupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
    ),
  ),
  items: [
    CoreMenuItem.action('복사', standardAction: .copy, onPressed: copy),
    CoreMenuItem.action('붙여넣기', standardAction: .paste, onPressed: paste),
  ],
);
```

`CoreMenuAction`은 잘라내기·복사·붙여넣기·실행 취소·다시 실행·공유·이름 변경·삭제의
아이콘을 제공한다. 콜백과 번역된 라벨은 앱이 제공하며, `leading`을 지정하면
자동 아이콘보다 우선한다. Menubar의 `CoreMenubarEntry.standardAction`도 같다.
컨텍스트 메뉴 상단과 스와이프 동작의 순서·콜백을 일치시키는 것은 앱의 데이터
구성에서 처리한다. 라이브러리가 라벨을 분석하거나 새로운 스와이프 동작을 만들지는 않는다.

Widgetbook의 **navigation → AppBar → Menus and Toolbars**에서 Surface material을
Liquid Glass로 선택하면 그룹과
실제로 열리는 메뉴를 확인할 수 있다. 네이티브 미리보기는 이 구성을 기본으로 사용한다.
선택 탭은 명암 대비가 있는 캡슐과 팔레트의 `primary` 색으로 구분한다.
`selectedBackgroundColor`, `selectedLabelTextStyle`, `iconStyle.color`의 명시적 값은
기본 강조보다 우선한다. Flutter에서는 캡슐 하나가 스프링 이동하고,
Web도 같은 선택 캡슐과 제스처 정책을 사용한다.

## 선택 표시 제스처

Flutter의 동일 너비 가로 Liquid Glass 바는 누르기 → 렌즈 확대 → 드래그 추적 →
손을 뗀 위치에 정착하는 흐름을 지원한다. 드래그 중에는 중간 탭으로 화면을
전환하지 않고, 유효한 새 항목 위에서 손을 뗄 때 `onSelected`를 한 번 호출한다.
선택값은 계속 부모가 소유한다. 드래그 취소·비활성 항목 위에서 놓기·외부 선택
변경·항목 수 변경은 미리보기를 취소한다. RTL에서는 좌표를 반전한다.

정지 상태는 낮은 대비의 선택 캡슐을 유지한다. 누르면 Impeller 셰이더 렌즈가
아이콘과 텍스트를 확대·굴절하고 가장자리에서 색 분산을 표현한다. 속도와 가속도는
이벤트 시간으로 계산한 뒤 평활화하여 렌즈 크기에 반영한다. 빠른 움직임에서는
가로 방향으로 더 늘어나며, 감속·정지·해제 시 탄성 있게 원래 크기로 돌아온다.
최대 변형을 제한하고 정지 후 타이커를 종료한다. 화면 캡처는 생성하지 않는다.
셰이더 미지원 엔진은 Transform과 광택으로 폴백한다. Apple의 픽셀 단위 복제는
아니다. 동작 줄이기에서는 확대·속도 변형·광학 렌즈와 스프링을 끄지만
직접 조작 중인 위치는 포인터를 따라간다. 좁아서 스크롤하는 바, 섹션이 섞인 바,
세로 모드는 드래그 선택 대신 기존 스크롤·탭 동작을 유지한다.
