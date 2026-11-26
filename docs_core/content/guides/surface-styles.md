---
title: 서페이스 스타일
description: 밝기와 별개인 두 번째 테마 축입니다. 라이트와 다크 어디서든 같은 컴포넌트에 다른 재질을 입힙니다.
design: true
---

# 서페이스 스타일

## 스타일 5종

강조색은 서페이스 스타일이 아니라 팔레트에서 정합니다. 프리셋은 채도와 명도만 움직입니다.

| | |
|---|---|
| Default | 불투명, 선으로 경계, 평평 |
| Neo-brutalism | 두꺼운 테두리, 흐림 없는 대각 그림자 |
| Liquid Glass | 반투명 채움과 배경 블러 |
| Claymorphism | 둥글고 부푼 표면, 안쪽 하이라이트 |
| Neumorphism | 페이지와 같은 색, 양방향 그림자 |

## 켜는 법

Flutter는 앱 루트에서, Web은 스코프의 정적 메서드로 정합니다. 읽을 때는 두 플랫폼 모두 SurfaceStyleScope.of(context)를 씁니다.

<Split>

<Code language="dart" title="Flutter">
CoUIApp(
  surfaceStyle:
    CoreSurfaceStyleId.liquidGlass,
  theme: appTheme,
  home: const HomePage(),
)
</Code>

<Code language="dart" title="Jaspr Web">
SurfaceStyleScope.setSurfaceStyle(
  CoreSurfaceStyleId.liquidGlass,
);
</Code>

</Split>

<DesignNote title="Web은 스타일 블록을 넣어야 그려집니다">

실행 중에 만들어 붙이는 `<style>` 안에 `config.surfaceStyleVariableBlocks`를 넣습니다(빠른 시작의 head 단계). `data-coui-style` 속성은 공개 API를 우회하므로 직접 쓰지 않습니다.

</DesignNote>

## 적용 대상

재질은 자기 채움을 그리고, 뒤로 무언가 지나갈 수 있는 표면에만 닿습니다.

| 표면 | 컴포넌트 |
|---|---|
| 떠 있는 패널 | 팝업, 다이얼로그, 툴팁, 토스트, 드로어, 드래그 패널 |
| 도킹 바 | 내비게이션 바, 독, 스캐폴드의 앱 바 |
| 버튼 | 채움이 있는 변형. ghost, link, plain은 제외 |
| 합성 컴포넌트 | Card, HoverCard 등은 기반 표면에서 상속 |

블러는 뒤에 무언가 있을 때만 보여, 평평한 단색 위의 유리는 유리처럼 보이지 않습니다.

## 튜닝

CoreSurfaceTuning으로 프리셋 값을 조정합니다. 지정하지 않은 값은 프리셋을 따릅니다.

| 필드 | 설명 |
|---|---|
| `radiusCap` | 모서리 반경 상한 |
| `shadowOffsetX` / `shadowOffsetY` | 그림자 오프셋. 눌림 피드백도 여기서 파생 |
| `strokeFloor` | 최소 선 두께. `CoreStrokeWidth.stroke2` 이상, 그 프리셋의 포커스 링 폭 미만 |
| `stageTintChroma` | 페이지가 강조색을 받는 정도. 라이트 페이지에서는 거의 보이지 않습니다 |
| `surfaceOpacity` | 채움 알파 (Liquid Glass) |
| `surfaceBlur` | 블러 반경 (Liquid Glass) |
| `refractionModel` | 굴절 법칙 — `snell`(기본) · `paraxial` (Liquid Glass) |
| `surfaceFrost*` · `surfaceBodyShade*` | 서리와 몸체 음영. 켜야 그려지고, 서리는 표면마다 배경 패스 하나를 더 씁니다 (Liquid Glass) |

Flutter 는 `CoUIApp(surfaceTuning:)` 에 하나를, Web 은 `ThemeConfig(surfaceTunings:)` 에 스타일별 맵을 받습니다. 범위를 벗어난 값은 컴파일 에러입니다.

> 접근성 계약, 스타일 id, 재질, 글자 굵기 하한은 튜닝할 수 없습니다.

## 접근성

기기 설정에 맞춰 재질을 줄입니다.

| 기기 설정 | 동작 |
|---|---|
| 투명도 줄이기 | 가장 낮은 단계(solid)를 적용 |
| 고대비, 강제 색상 | 굴절, 서리, 음영을 끔 |
| 동작 줄이기 | 단계 전환에 모션을 쓰지 않음 |

<DesignNote title="도달 범위">

굴절은 Flutter 네이티브와 Web의 Chromium에서만 그려집니다. Flutter Web, Safari, Firefox에서는 휘지 않고 나머지 재질만 그립니다. 헤더의 스타일 스위처는 이 사이트의 데모이고, 킷은 최종 사용자용 스타일 피커를 출하하지 않습니다. 앱이 사용자에게 고르게 하려면 그 UI는 앱이 만들고, Web은 런타임 API인 SurfaceStyleScope.setSurfaceStyle로 바꿉니다.

</DesignNote>

- Flutter: 첫 화면에 유리가 있으면 `runApp` 전에 `await SurfaceRefractionProgram.warmUp()` 을 불러야 첫 프레임부터 휩니다. 표면 위에 `ImageFiltered` · `Clip.antiAliasWithSaveLayer` 같은 레이어가 있으면 그 자리에서는 휘지 않습니다.
- Web: 윤곽 림과 굴절은 하이드레이션 뒤에 붙고, 서리와 몸체 음영은 Chromium 에서만 그려집니다.

## 품질 적응

앱 루트에 `adaptiveQuality: const CoreAdaptiveQuality()` 를 주면, 프레임이 늦는 동안 표면이 재질을 한 단계씩 내려놓고 여유가 생기면 되찾습니다.

| 단계 | 내려놓는 것 |
|---|---|
| `full` | 없음 |
| `noRefraction` | 가장자리의 굴절 |
| `solid` | 배경 패스 전부 — 블러, 채도, 서리, 몸체 음영, 반투명 채움 |

투명도 줄이기가 켜져 있으면 `solid` 가 이깁니다. 앱의 무거운 일은 `AdaptiveQualityScope.holdMeasurement(context)` 로 감싸 유리 탓으로 읽히지 않게 하고, 유리를 그리지 않는 앱은 켜지 않습니다. 컨테이너에 직접 준 굴절과 앱이 직접 쓴 블러는 단계를 따르지 않습니다.

## 유리 패널이 나타나고 사라질 때

팝오버 · 메뉴 · 대화상자는 불투명도 대신 재질을 줄이며 페이드해, 열고 닫는 동안에도 뒤를 흐립니다. 패널에 직접 불투명도를 걸면 첫 프레임부터 흐림을 잃습니다. 서랍 · 토스트 · 전체 화면 대화상자 · Web 툴팁은 이 방식을 따르지 않습니다.
