---
title: 테마
description: 컴포넌트 테마, 라이트와 다크, 밀도를 앱 루트에서 정합니다. 서페이스 스타일은 다음 페이지에서 다룹니다.
design: true
---

# 테마

## 테마 구성

프리셋과 컴포넌트 테마를 앱 루트에 넘깁니다. Web도 Flutter와 같은 CoreComponentTheme 슬롯을 받습니다.

<Split>

<Code language="dart" title="Flutter">
CoUIApp(
  theme: ThemeData.fromCore(
    CoreThemePresets.light,
    coreComponentTheme: appComponentTheme,
  ),
  home: const HomePage(),
)
</Code>

<Code language="dart" title="Jaspr Web">
CoUIWeb(
  theme: appTheme,
  child: const App(),
)
</Code>

</Split>

컴포넌트 테마는 컴포넌트마다 슬롯 하나이고, 슬롯은 `style` 과 `variantStyles` 만 받습니다.

```dart
const appComponentTheme = CoreComponentTheme(
  card: CoreCardTheme(
    variantStyles: {
      CoreCardVariant.filled: CoreCardStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    },
  ),
);
```

## 스타일 적용 순서

같은 속성을 여러 곳에서 정하면 아래에 있는 값이 이깁니다. 병합은 컴포넌트가 스타일을 계산할 때 한 번에 이뤄집니다.

| 순서 | 위치 | 범위 |
|---|---|---|
| 1 | `CoreXxxStyle.defaultX` | 컴포넌트 기본값 |
| 2 | `CoreXxxStyle.defaultsByVariant[variant]` | 변형별 기본값 |
| 3 | `CoreXxxTheme.style` | 앱 전체 |
| 4 | `CoreXxxTheme.variantStyles[variant]` | 앱 전체, 변형별 |
| 5 | `widget.xxxStyle` | 위젯 하나 |

<a id="부분-트리만-다른-밝기로"></a>

## 라이트와 다크

두 플랫폼의 전환 방법이 다릅니다. ThemeConfig가 값을 정의한 테마는 light와 dark 두 가지입니다.

| 플랫폼 | 전환 방법 |
|---|---|
| Flutter | `themeMode: CoreThemeMode.system` |
| Jaspr Web | `CoUIThemeController.setTheme('dark')` |

Web 에서 색을 뒤집는 것은 `theme:` 이 아니라 `<html data-theme>` 속성입니다. 고르는 UI 는 [ThemeController](/components/theme-controller)입니다. 한 부분만 다른 밝기로 그릴 때는 `BrightnessScope(brightness: CoreBrightness.light, child: …)` 로 감쌉니다.

<Cards variant="outlined" columns="2">
  <Card title="BrightnessScope 안에서 바뀌는 것">

- 색
- 그림자 세기
- 기본 텍스트와 아이콘 색
- 재질의 채움

</Card>
  <Card title="그대로인 것">

- 컴포넌트 테마
- 타이포그래피
- 밀도와 배율
- 서페이스 기하

</Card>
</Cards>

> 범위 안에서 연 패널도 범위의 밝기이고, 서랍만 자기가 올라가는 자리(기본은 앱 루트)의 밝기입니다. Flutter 에서 브랜드 팔레트를 쓰면 `theme` 과 `darkTheme` 을 모두 넘겨야 범위가 브랜드 색으로 그립니다. 리터럴 색과 Web 에서 실행 중에 바꾼 팔레트(`setCustomTheme`)는 범위에 닿지 않습니다.

## 밀도

간격, 컨트롤 행 높이, 행 모서리를 함께 조정합니다. 기본값은 standard입니다.

| 밀도 | 간격 | 컨트롤 행 | 행 모서리 |
|---|---|---|---|
| `compact` | 16 → 12, 8 → 4 | 40 → 32 | 10 → 8 |
| `standard` | 그대로 | 그대로 | 그대로 |
| `spacious` | 16 → 20 | 40 → 48 | 10 → 12 |

앱 루트의 `density:`(`CoUIApp` · `CoUIWeb` 모두)로 정하고, Web 은 실행 중에 `DensityScope.setDensity(CoreDensity.spacious)` 로 바꿉니다.

> 호출자가 직접 지정한 높이와 칩, 탭, 리스트 행처럼 자체 행을 가진 요소는 밀도를 따르지 않습니다. 4 이하의 간격, 아이콘 · 아바타 같은 크기, 타이포그래피도 그대로입니다. Web 에서 토큰 스케일 밖의 간격은 움직이지 않아 이 자리만 Flutter 와 다릅니다.

## 브랜드 색

강조색은 팔레트가 정합니다. Web 은 브랜드 색 하나로 만든 소스를 `ThemeConfig.from` 에 넘깁니다.

```dart
final config = ThemeConfig.from(
  CoreBrandSchemeSource.fromColor(const CoreColor(0xFF7A3FD1)),
);
```

Flutter 는 같은 소스를 `CouiSemanticColors.from(...)` 으로 읽어 네 스킴(라이트 · 다크 · 고대비 둘)을 만들고 그것으로 테마를 만듭니다. DaisyUI 변수(`--p` · `--b1` 류)를 직접 적는 방식은 동작하지 않습니다.
