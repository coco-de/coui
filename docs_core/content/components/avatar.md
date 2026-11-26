---
title: Avatar
description: 사용자 아바타 컴포넌트
category: display
platforms: [flutter, web]
related: [badge, icon]
tags: [user, profile, image]
---

# Avatar

사용자 프로필 이미지 또는 이니셜을 표시하는 아바타 컴포넌트입니다.

## Live Preview

<LivePreview component="avatar" variants="default,rounded" />

## 구조 (Anatomy)

코드가 정본입니다. 부분 이름은 위젯 슬롯과 같고, Figma [`❖ Avatar`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0?node-id=2467-151690) 레이어와도 맞습니다.

| 부분 | 역할 | 슬롯 |
|------|------|------|
| `child` | 커스텀 내용 (`imageUrl` / `initials` 대신) | `child` |
| `badge` | 위에 얹는 배지 | `badge` |

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 사용자 프로필 이미지 또는 이니셜을 표시할 때
- 조직 · 워크스페이스 · 앱처럼 사람이 아닌 주체를 표시할 때 — `shape: CoreAvatarShape.rounded`
- 댓글, 채팅, 팀 멤버 목록에서 사용자를 시각적으로 식별할 때
- 온라인/오프라인 상태를 함께 표시해야 할 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Icon](/components/icon)**: 사용자 이미지 · 이니셜 폴백 없이 글리프 하나만 표시할 때
- **[Badge](/components/badge)**: 사용자 식별이 아니라 상태 문자열이나 개수를 표시할 때

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 이미지 아바타
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  size: CoreComponentSize.md,
)

// 이니셜 아바타
Avatar(
  initials: 'A',
  size: CoreComponentSize.lg,
)

// 링 효과
Avatar(
  imageUrl: user.photoUrl,
  ring: true,
)

// 둥근 사각 타일 — 조직 · 워크스페이스 · 앱
Avatar(
  initials: 'B',
  shape: CoreAvatarShape.rounded,
)

// 커스텀 child
Avatar(
  size: CoreComponentSize.sm,
  child: Icon(LucideIcons.user),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 이미지 아바타
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  size: CoreComponentSize.md,
)

// 이니셜 아바타
Avatar(
  initials: 'A',
  size: CoreComponentSize.lg,
)

// 링 효과
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  size: CoreComponentSize.md,
  ring: true,
)

// 둥근 사각 타일 — 조직 · 워크스페이스 · 앱
Avatar(
  initials: 'B',
  shape: CoreAvatarShape.rounded,
)

// 커스텀 child
Avatar(
  size: CoreComponentSize.sm,
  child: Text('코드').labelSmall.onSurface,
)
```

  </TabItem>
</Tabs>

## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `imageUrl` | `String?` | `null` | 프로필 이미지 URL |
| `initials` | `String?` | `null` | 이니셜 텍스트 |
| `size` | `CoreComponentSize` | `sm` | 아바타 크기 |
| `shape` | `CoreAvatarShape` | `circle` | 외곽선 — 사람은 원(`circle`), 조직 · 워크스페이스 · 앱은 둥근 사각 타일(`rounded`) |
| `ring` | `bool` | `false` | 링 보더 표시 여부 |
| `child` | `W?` | `null` | 커스텀 내용 (imageUrl/initials 대체) |
| `badge` | `W?` | `null` | 아바타 위에 오버레이 되는 배지 (`AvatarBadge`) |
| `avatarStyle` | `CoreAvatarStyle?` | `null` | 인스턴스 스타일 (Style 시스템 참조) |

`badge` 의 위치(`badgeAlignment` · `badgePlacement` · `badgeInset`)·크기(`badgeStyle`) 같은 겉모습은 모두 `avatarStyle: CoreAvatarStyle(badgeAlignment: ..., badgeInset: ...)` 로 전달합니다.

## 스타일 시스템 (Style System)

Avatar 의 겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일은 전부 `CoreAvatarStyle` 하나로 바꿉니다. 종류를 고르는 값 (`size`, `shape`) 과 내용 · 동작 (`ring` / `badge` / `imageUrl` / `initials`) 은 위젯 파라미터로 직접 넘깁니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 내용 · 동작**: 위젯 파라미터로 직접 (`size`, `shape`, `ring`, `imageUrl`, `initials`, `child`, `badge`)
- **겉모습 (색 · 크기 · 간격, 안쪽 부품의 스타일)**: `CoreAvatarStyle` 한 곳으로 (`backgroundColor` / `borderRadius` / `ringColor` / `ringWidth` / `ringOffset` / `badgeInset` / `badgeAlignment` / `badgePlacement` / `initialsFontRatio` / `fallbackTextStyle` / `badgeStyle` / `childIconStyle`). 이니셜 텍스트 색은 `fallbackTextStyle.color` 로 흐릅니다

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreAvatarStyle.defaultsBySize[size]       // 지름 · 이니셜 역할 · 둥근 타일의 모서리 · 배지 크기 · child 아이콘 크기
  → CoreAvatarStyle.defaultsByShape[shape] // 원이면 알약 모서리, 배지 자리
  → CoreAvatarTheme.style                  // 프로젝트 공통
  → widget.avatarStyle                     // 인스턴스별
```

모서리는 위에서 아래로 덮입니다. `borderRadius` 를 테마나 인스턴스에 적으면 두 모양 모두 그 모서리로 그려지고, 적지 않으면 원은 알약 모서리, 둥근 타일은 크기 행의 모서리를 씁니다. 테마에는 모양 슬롯이 없습니다 — `shape` 는 `size` 처럼 위젯 파라미터입니다.

`fallbackTextStyle` 은 그 부품 자신의 기본값 · 테마와 같은 순서로 한 번 더 합쳐집니다.

### 크기 단계마다 바뀌는 것

| 크기 | 지름 | 이니셜 | 배지 | 배지 안쪽 테두리 | child 아이콘 |
|------|------|--------|------|------------------|--------------|
| `xs` | 24 | 11 (`labelXs`) | 8 | 1 | 12 |
| `sm` | 32 | 13 (`labelMedium`) | 10 | 1 | 16 |
| `md` | 40 | 15 (`labelXl`) | 12 | 2 | 20 |
| `lg` | 48 | 18 (`titleMedium`) | 14 | 2 | 24 |
| `xl` | 64 | 24 (`headlineSmall`) | 16 | 2 | 32 |
| `xl2` | 96 | 32 (`headlineLarge`) | 20 | 2 | 48 |

- **이니셜** 은 지름처럼 화면 폭과 무관하게 고정입니다. `xl` · `xl2` 의 역할(`headlineSmall` · `headlineLarge`)은 화면 폭에 따라 작아지는 역할이지만, 이니셜은 지름이 그대로인 원을 채우도록 고른 글자라 두 플랫폼 모두 아바타가 자기 내용과 배지를 데스크톱 단계로 고정합니다(`TypographyTierScope(tier: CoreBreakpointTier.desktop)` — [화면 폭에 따른 단계](/guides/typography#화면-폭에-따른-단계)). Figma 에서도 `xl` · `xl2` 의 이니셜은 타이포 모드(Mobile · Tablet · Desktop)를 따르지 않는 고정 크기(`font/size/24` · `32`)에 묶입니다.
- **배지** 는 아바타가 `badge` 슬롯의 `AvatarBadge` 에 크기 단계의 `badgeStyle` 을 넘깁니다. 배지가 `avatarBadgeStyle.size` 를 스스로 적으면 그 값이 이깁니다.
- **배지 안쪽 테두리** 는 점 가장자리 안쪽에 그리는 `surface` 색 고리로, 사진이나 아바타 면 위에서 점의 윤곽을 갈라 줍니다. 혼자 쓰는 `AvatarBadge` 는 2(`stroke2`)이고, 아바타는 작은 두 단계(`xs` · `sm`)에서 1 을 넘깁니다. 안쪽으로 그리므로 점의 크기는 그대로입니다 — Flutter 는 앞쪽 장식(`foregroundDecoration`)의 테두리, Web 은 `inset` `box-shadow` 입니다.
- **child 아이콘** 은 `child` 슬롯 둘레의 아이콘 크기(`childIconStyle`, 지름의 약 절반)입니다. `child` 로 넘긴 `Icon` 이 크기를 적지 않으면 이 크기로 그려지고, 적으면 그 크기가 이깁니다.

### 배지 자리

배지는 `badgeAlignment` 가 가리키는 모서리(기본 `topEnd`)에 놓이고, 놓는 방식은 모양이 정합니다(`badgePlacement`, `defaultsByShape`).

| 모양 | `badgePlacement` | 자리 |
|------|------------------|------|
| 원 | `outline` | 배지 중심이 원 테두리 위, 모서리 방향으로 45° 지점 |
| 둥근 타일 | `corner` | 배지 상자가 상자 모서리에 딱 붙음 |

`badgeInset`(기본 0)은 배지를 가운데 쪽으로 당깁니다 — `corner` 는 상자 가장자리에서, `outline` 은 테두리에서. 자리 계산은 `CoreAvatarStyle.badgeAnchorFor` 한 곳에 있고 두 플랫폼이 그것을 읽으므로, 배지 크기가 달라도 같은 점에 앉습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreAvatarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Avatar fill background colour. Drives both the image placeholder and the initials fallback. `null` → [defaultBackgroundColor]. |
| `diameter` | `double?` | Avatar diameter (logical px). `null` → the diameter the widget's `size` names in [defaultsBySize]; a value here replaces it for this instance only (a one-off such as the 128 profile header). |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` → the shape's corner: the pill ([defaultBorderRadius], through [defaultsByShape]) for a disc, the step's corner in [defaultsBySize] for a rounded tile. A value here wins over both shapes. |
| `ringColor` | `CoreColor?` | Ring (outer border) colour when the widget's `ring` parameter is `true`. `null` → [defaultRingColor]. |
| `ringWidth` | `double?` | Ring (outer border) width (logical px) when the widget's `ring` parameter is `true`. `null` → [defaultRingWidth]. |
| `ringOffset` | `double?` | Ring offset (gap between ring and avatar fill, logical px) when the widget's `ring` parameter is `true`. `null` → [defaultRingOffset]. |
| `badgeInset` | `double?` | Inset of the badge toward the avatar's centre (logical px, pre-scaling) — from the box edges for [CoreAvatarBadgePlacement.corner], from the outline for [CoreAvatarBadgePlacement.outline]. `null` → [defaultBadgeInset]. |
| `badgeAlignment` | `CoreAlignment?` | Corner the badge is overlaid at, relative to the avatar. Platform-neutral [CoreAlignment] — Flutter maps it to an `AlignmentGeometry`, Web maps it to CSS edge offsets. `null` → [defaultBadgeAlignment] (top-end). |
| `badgePlacement` | `CoreAvatarBadgePlacement?` | How the badge sits against [badgeAlignment]'s corner — in the box corner or on the outline. `null` → the shape's row in [defaultsByShape], then [defaultBadgePlacement]. |
| `initialsFontRatio` | `double?` | Ratio of the initials fallback fontSize to the avatar diameter — a single-axis behaviour scalar (`fontSize = diameter * ratio`). Only an instance that states it is sized this way; `null` → the per-size role in [defaultsBySize], whose size, tracking and leading stand. |
| `fallbackTextStyle` | `CoreTextStyle?` | Initials fallback text style (rendered when neither image nor custom child is supplied). Text colour is carried via [CoreTextStyle.color] inside this slot. `null` → the size's role laid over [defaultFallbackTextStyle]. |
| `badgeStyle` | `CoreAvatarBadgeStyle?` | The style the avatar hands the `AvatarBadge` in its `badge` slot — the badge's own `avatarBadgeStyle` is laid over it, so a size or a colour the badge states wins. `null` → the size's row in [defaultsBySize]. |
| `childIconStyle` | `CoreIconStyle?` | Icon style inherited by the `child` slot — an `Icon` you pass as `child` without a size of its own is drawn at this one. `null` → the size's row in [defaultsBySize]. |

<!-- STYLE_TABLE:END -->

### 관련 컴포넌트의 Style 슬롯

| 컴포넌트 | 슬롯 | 담는 것 |
|---------|------|--------|
| `AvatarBadge` | `avatarBadgeStyle: CoreAvatarBadgeStyle?` | 배지 자체의 배경(`backgroundColor`) · 크기(`size`) · 안쪽 테두리(`borderColor` / `borderWidth`). `Avatar` 안에서는 아바타의 `badgeStyle` 위에 덮입니다 |
| `AvatarGroup` | `avatarGroupStyle: CoreAvatarGroupStyle?` | 겹침 간격(`overlap` / `extraSpacing`) + 겹친 아바타를 갈라 보이게 하는 구분 보더(`borderColor` / `borderWidth`) |

### 사용 예 (Flutter)

```dart
Avatar(
  initials: 'A',
  ring: true,
  avatarStyle: CoreAvatarStyle(
    backgroundColor: CoreColor.token(CoreColors.primaryContainer),
    ringColor: CoreColor.token(CoreColors.primary),
    ringWidth: CoreStrokeWidth.stroke3,
    fallbackTextStyle: CoreTextStyle.token(
      CoreTextStyles.labelLarge,
      color: CoreColor.token(CoreColors.onPrimaryContainer),
    ),
  ),
)
```

### 사용 예 (Web)

```dart
Avatar(
  initials: 'A',
  ring: true,
  avatarStyle: CoreAvatarStyle(
    backgroundColor: CoreColor.token(CoreColors.primaryContainer),
    fallbackTextStyle: CoreTextStyle.token(
      CoreTextStyles.labelLarge,
      color: CoreColor.token(CoreColors.onPrimaryContainer),
    ),
  ),
)
```

### 빠른 오버라이드 (Chain)

이미 만든 `Avatar` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다. `.radius16`처럼 Core 토큰 상수 이름과 똑같은 이름의 getter도 있습니다 — `withStyle`을 한 번 더 줄인 sugar로, 이름이 곧 값이라(radius16 == `CoreRadius.radius16`) 어느 컴포넌트에서 써도 뜻이 갈리지 않습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class AvatarChainExample extends StatelessWidget {
  const AvatarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Avatar(initials: 'A').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(ringColor/ringWidth)까지.
        const Avatar(initials: 'B').withStyle(
          const CoreAvatarStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            ringColor: CoreColor.token(CoreColors.tertiary),
            ringWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class AvatarChainExample extends StatelessComponent {
  const AvatarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Avatar(initials: 'A').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(ringColor/ringWidth)까지.
        Avatar(initials: 'B').withStyle(
          const CoreAvatarStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            ringColor: CoreColor.token(CoreColors.tertiary),
            ringWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

## 변형 (Variants)

### 크기

| 크기 | 값 | 픽셀 |
|------|-----|------|
| XS | `CoreComponentSize.xs` | 24px |
| SM | `CoreComponentSize.sm` | 32px |
| MD | `CoreComponentSize.md` | 40px |
| LG | `CoreComponentSize.lg` | 48px |
| XL | `CoreComponentSize.xl` | 64px |
| XL2 | `CoreComponentSize.xl2` | 96px |

### 지름 직접 지정

크기 단계(`xs` ~ `xl2`)는 여섯 개뿐이라 44 나 56 처럼 단계 사이에 있는 지름은 단계로 고를 수 없습니다. 이런 지름은 그 아바타에만 `avatarStyle: CoreAvatarStyle(diameter: …)` 로 정합니다. 아바타 상자 · 사진 · 링은 정한 지름에 맞춰 그려지고, 배지는 그 상자의 모서리에 놓입니다. 배지 자체의 크기는 지름과 상관없이 그대로입니다.

<LivePreview component="avatar" variant="diameter" chain="off" />

```dart
Avatar(
  initials: 'A',
  size: CoreComponentSize.lg,
  avatarStyle: CoreAvatarStyle(diameter: CoreSize.size44),
)
Avatar(
  initials: 'B',
  size: CoreComponentSize.lg,
  avatarStyle: CoreAvatarStyle(diameter: CoreSize.size56),
)
```

**이니셜 글자 크기.** 기본으로 이니셜은 지름이 아니라 고른 크기 단계(`size`)의 글자 크기를 씁니다. 그래서 지름에 가까운 단계를 `size` 로 함께 고릅니다. `size` 를 빼면 기본 크기 `sm` 의 작은 글자가 남습니다. 위 두 아바타는 둘 다 `lg` 라서 지름이 달라도 글자 크기가 같습니다. 글자 크기만 따로 바꾸려면 `fallbackTextStyle` 에 `fontSize` 를 적습니다. 자간과 행간의 비율은 고른 크기 단계 그대로입니다. 글자 크기를 지름에 비례시키려면 `initialsFontRatio` 를 씁니다.

```dart
Avatar(
  initials: 'A',
  size: CoreComponentSize.lg,
  avatarStyle: CoreAvatarStyle(
    diameter: CoreSize.size56,
    fallbackTextStyle: CoreTextStyle(fontSize: CoreFontSize.s20),
  ),
)
```

둥근 타일(`shape: CoreAvatarShape.rounded`)의 모서리도 지름이 아니라 고른 크기 단계의 값을 씁니다. 값은 아래 '모양' 에 있습니다.

**도달 범위 — 여기까지만 참입니다.** `AvatarGroup` 은 안에 든 아바타의 지름을 읽지 않습니다. Flutter 그룹은 줄 높이를 기본 크기(`sm`)의 지름에 맞춰 고정하므로, 그보다 큰 지름(또는 `sm` 보다 큰 `size`)의 아바타는 세로가 눌려 타원으로 그려집니다. Web 그룹은 줄 높이를 고정하지 않습니다. 넘침 표시 `+N` 아바타는 두 플랫폼 모두 첫 아바타의 `size` 단계 지름으로 그려지고 `diameter` 는 쓰지 않습니다. 그래서 지름을 정한 아바타는 `AvatarGroup` 안에 넣지 않습니다.

**Figma.** Avatar 세트는 `ring` · `child` · `badge` 층을 아바타 상자의 가장자리를 기준으로 고정해 그리고, 이니셜은 상자 가운데에 둡니다. 원의 배지는 테두리 위 점에 그려지지만 Figma 의 고정(constraints)은 그 점을 따라가지 못해, 인스턴스 크기를 바꾸면 배지가 모서리 쪽으로 조금 밀립니다 — 각 크기 단계의 멤버는 정확합니다. 먼저 `Size` 를 지름에 가까운 단계로 고른 뒤 인스턴스 크기를 지름에 맞춥니다. 새 인스턴스는 기본 크기 `sm` 로 시작하므로 `Size` 를 고르지 않고 크기만 바꾸면 이니셜이 작게 남습니다. 이니셜 글자 크기가 달라야 하면 그 글자 크기만 직접 바꿉니다. 코드는 이니셜을 앞 두 글자만 그리지만 Figma 의 `Initials` 는 글자 수를 막지 않고 넘치는 글자를 자르지도 않으므로, 1~2글자로 넣습니다.

### 모양

사람은 원, 조직 · 워크스페이스 · 앱은 둥근 사각 타일로 그립니다. 같은 컴포넌트의 `shape` 한 축이고, 바뀌는 것은 모서리 하나입니다 — 지름 · 이니셜 · 이미지 · 링 · 배지는 그대로입니다.

| 모양 | 값 | 모서리 |
|------|-----|--------|
| 원 (기본) | `CoreAvatarShape.circle` | 알약 — 정사각형 상자에서 원이 됩니다 |
| 둥근 타일 | `CoreAvatarShape.rounded` | 크기마다 지름의 1/4 — xs 6 · sm 8 · md 10 · lg 12 · xl 16 · xl2 24 |

둥근 타일의 모서리는 크기 행(`CoreAvatarStyle.defaultsBySize`)에 상수로 적혀 있고 어느 플랫폼도 지름에서 계산하지 않습니다. 그래서 `avatarStyle.diameter` 로 지름만 바꾼 인스턴스는 크기 행의 모서리를 그대로 씁니다 — 모서리를 정하는 것은 그린 크기가 아니라 고른 크기입니다. 사진(`imageUrl`)과 `child` 는 그 모서리로 잘리고, 링은 아바타 모서리를 간격(`ringOffset`)만큼 키운 모서리로 둘러집니다.

```dart
Avatar(initials: 'A', shape: CoreAvatarShape.rounded)
Avatar(initials: 'B', shape: CoreAvatarShape.rounded, size: CoreComponentSize.lg, ring: true)
```

**도달 범위 — 여기까지만 참입니다.** 둥근 타일의 모서리는 지름이 아니라 반경 사다리 위의 값이라 밀도(`CoreDensity`)와 표면 스타일 프리셋이 지름과 따로 옮깁니다. 지름은 크기 행의 고정값이라 움직이지 않으므로, 그 아래에서는 모서리가 지름의 1/4 에서 벗어날 수 있습니다. 밀도가 옮기는 것은 컨트롤 행 띠(6 … 16)의 모서리뿐입니다 — `compact` 는 md · lg · xl (10 → 8 · 12 → 10 · 16 → 14) 을, `spacious` 는 xs · sm · md · lg (6 → 8 · 8 → 10 · 10 → 12 · 12 → 14) 를 옮기고, 나머지 크기와 띠 밖의 xl2 (24) 는 두 밀도 모두에서 그대로입니다. 표면 스타일 프리셋은 반경 사다리 전체에서 값을 재분배하므로 xl2 의 24 도 그 아래에서는 움직입니다. 원의 알약 모서리는 사다리 재분배를 받지 않습니다(모서리를 각지게 하는 스타일만 예외). 둥근 타일을 `AvatarGroup` 에 넣는 경우는 아직 다루지 않습니다 — Flutter 의 그룹 구분 보더는 원으로 그려지므로 타일 모양을 따르지 않습니다.

### 링 효과

```dart
Avatar(imageUrl: url, ring: true)
Avatar(imageUrl: url, ring: false)
```

### 배경색 커스텀

배경색은 위젯 prop 이 아니라 `avatarStyle` 슬롯으로 흐릅니다.

```dart
Avatar(
  initials: 'A',
  avatarStyle: CoreAvatarStyle(
    backgroundColor: CoreColor.token(CoreColors.primaryContainer),
  ),
)
Avatar(
  initials: 'B',
  avatarStyle: CoreAvatarStyle(
    backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
  ),
)
```

## 동작 스펙 (Behavior)

### 이미지 로딩

- `imageUrl` 이 있으면 이미지를 그리고, 없으면 `initials` 로 폴백합니다
- Flutter 는 네트워크 이미지, Web 은 `<img>` 태그로 렌더합니다
- **Web**: `<img>` 의 `alt` 와 루트 `aria-label` 에 `initials`(없으면 `avatar`)가 자동 적용됩니다

### Ring 효과

- 양 플랫폼 모두 `ring: true` 로 활성화하고, 두께와 색은 `avatarStyle` 의 `ringWidth` / `ringColor` 가 정합니다
- 기본값은 `CoreStrokeWidth.stroke2` 두께 · `primary` 색
- `ringOffset` 은 링과 아바타 사이 간격(논리 px)입니다. 양쪽 모두 아바타의 레이아웃 크기를 늘리지 않는 바깥 장식으로 적용합니다
- 링의 모서리는 아바타 모서리를 키운 값입니다 — 간격 층은 `r + ringOffset`, 링 바깥 끝은 `r + ringOffset + ringWidth`. 원은 원으로, 둥근 타일은 같은 곡률의 둥근 사각으로 둘러집니다

```dart
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  ring: true,
)
```

### 이미지 폴백

- Flutter는 이미지 로드 실패 시 이니셜(없으면 `?`)로 폴백합니다. Web은 `<img>` 실패 핸들러가 없어 깨진 이미지 / alt 표시가 남습니다
- `child`가 있으면 imageUrl/initials보다 우선
- 표시용 컴포넌트이며 자체 클릭 콜백 · 비활성 상태 · 로딩 대역은 없습니다. 로딩 중에는 호출부가 `child` 또는 아바타 전체를 대역으로 교체합니다

```dart
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  initials: 'A',
  size: CoreComponentSize.md,
)
```

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**이미지와 이니셜 폴백을 항상 함께 제공하세요.**

```dart
Avatar(
  imageUrl: user.photoUrl,
  initials: 'A',
)
```

Flutter의 실패 폴백과 Web의 이미지 alt 이름에 이니셜이 쓰입니다. Web에서도 시각적 이니셜 폴백이 필요하면 호출부에서 실패 상태에 따라 `imageUrl` 을 제거하세요.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**이미지 없이 빈 아바타를 표시하지 마세요.**

이니셜이나 기본 아이콘 없는 빈 원형은 사용자를 식별할 수 없습니다.

</Callout>

### ✅ Do

<Callout type="tip">

**그룹에는 `AvatarGroup` 의 `max` 를 설정하세요.**

```dart
AvatarGroup(
  max: 5,
  children: teamMembers.map((m) => Avatar(
    imageUrl: m.photo,
    size: CoreComponentSize.sm,
  )).toList(),
)
```

많은 아바타가 나열되면 레이아웃이 깨집니다. 3~5개가 적절합니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**아바타 크기를 컨텍스트에 맞지 않게 사용하지 마세요.**

댓글 목록에 XL(64px) 아바타를 사용하면 콘텐츠보다 아바타가 강조됩니다. 인라인에는 SM(32px), 프로필 헤더에는 LG(48px) 이상을 사용하세요.

</Callout>

### ✅ Do

<Callout type="tip">

**상태 표시는 실시간 정보에만 사용하세요.**

```dart
Avatar(
  imageUrl: user.photoUrl,
  ring: user.isOnline,
)
```

온라인/오프라인 같은 실시간 상태만 뱃지로 표시합니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**정적 역할 정보를 아바타 뱃지로 표시하지 마세요.**

"관리자", "멤버" 같은 역할은 별도 텍스트 레이블로 표시하세요.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Web** — 루트에 `role="img"` 와 `aria-label`(=`initials`, 없으면 영어 리터럴
  `avatar`)이 붙습니다. 이미지 경로는 `<img alt>` 에 같은 값을 씁니다.
  `AvatarBadge` 에는 role 도 aria 도 없습니다.
- **Flutter** — `Semantics` 가 없습니다. `imageUrl` 을 준 경우에만
  `Image.network(semanticLabel: …)` 로 이미지에 이름이 붙고, 이니셜 폴백과
  `child` 경로에는 컨테이너 이름이 없습니다.

### 키보드

없음. 아바타는 양 플랫폼 모두 포커스를 받지 않고(`tabindex` / `Focus` /
`Clickable` 어느 것도 없음), contract 에 `onTap` / `onPressed` 자체가 없어
클릭 가능한 아바타를 만들 경로도 없습니다.

### 스크린 리더

- **Web** — `role="img"` 가 아바타를 하나의 이미지로 접습니다. 읽히는 것은 루트
  `aria-label` 하나이고, 그 값은 **자르지 않은 `initials` 원본**입니다 — 화면에는
  앞 두 글자만 그려집니다.
- **Flutter** — 이미지 경로는 `initials` 원본이 이미지 이름으로 붙지만, 이니셜
  폴백 경로는 잘린 한두 글자가 텍스트로 그대로 읽힙니다.
- `AvatarGroup` 의 넘침 표시는 `initials: '+N'` 인 아바타로 그려지므로 Web 은
  `aria-label="+N"`, Flutter 는 `+N` 텍스트로 읽힙니다.
- 상태 통보(live region)는 양쪽 다 없습니다.

### 포커스 관리

없음 — 포커스를 받지 않으므로 진입·이탈·트랩 어느 것도 해당하지 않습니다.

### 알려진 제약

- **이름 기본값이 번역되지 않습니다.** `initials` 가 없으면 양 플랫폼 모두 영어
  리터럴 `avatar` 를 씁니다. 사람 이름을 읽히려면 `initials` 에 의미 있는 값을
  넣습니다 — Web 은 그 값을 통째로 읽고, Flutter 는 이미지가 있을 때만 통째로,
  이니셜 폴백에서는 잘린 글자만 읽습니다.
- **Web `Avatar` 는 `attributes` 를 받습니다.** 루트의 이름 · 역할을 호출부에서 제공할 수 있습니다. Flutter 는 호출부가 `Semantics(...)` 로 감싸 컨테이너 이름을 얹습니다. Web 의 `copyWith` 는 `classes` · `css` · `attributes` · `eventHandlers` 를 그대로 넘기므로 `.withStyle` · `.radius16` 같은 스타일 체인 뒤에도 전달한 속성이 남습니다.
- **`badge` 슬롯이 Web 에서 통보되지 않습니다.** 루트의 `role="img"` 는 그 안을
  하나의 이미지로 접으므로, 온라인 상태 표시처럼 badge 에 넣은 콘텐츠가 별도
  노드로 노출되지 않습니다. Flutter 는 role 이 없어 badge 자식이 그대로 읽힙니다.
- **이미지 로드 실패의 결과가 플랫폼마다 다릅니다.** Flutter 는 `errorBuilder` 로
  이니셜 폴백을 그리고, Web 은 `<img>` 에 실패 처리가 없어 브라우저의 깨진 이미지
  표시가 남습니다(`alt` 는 계속 읽힙니다).

### 색상 대비

이니셜 폴백은 `primaryContainer` 위의 `onPrimaryContainer` 이고, 이 쌍은 레포 전체 대비
가드가 라이트·다크·고대비 네 모드에서 감사합니다 — 지금 예외로 등록된 위반은
없습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

`imageUrl` / `initials` / `size` / `shape` / `ring` / `child` / `badge` / `avatarStyle` 은 양 플랫폼 동일 API 입니다.

| 항목 | Flutter | Web |
|------|---------|-----|
| 슬롯 타입 | `Widget?` | `Component?` |
| 이미지 렌더 | 네트워크 이미지 위젯 | `<img src>` |
| 링 렌더 | 아바타 밖 `Stacks` 의 간격층 · 보더층 — 두 층의 모서리는 아바타 모서리를 간격 · 두께만큼 키운 값입니다 | 레이아웃 크기를 늘리지 않는 CSS shadow 링 래퍼 — `box-shadow` 의 spread 가 모서리를 같은 만큼 키웁니다 |
| 사진 · `child` 자르기 | `OutlinedContainer` 의 anti-alias 클립이 모서리를 따름 | 아바타 상자의 `overflow: hidden` 이 모서리를 따름 |
| 이미지 실패 | `errorBuilder` 이니셜 폴백 | `<img>` 의 브라우저 실패 표시 |
| 그룹 오버랩 | `Row` 안 `Transform.translate` 로 겹침 | 음수 margin 으로 겹침 |
| 데스크톱 단계 고정 | 아바타 전체를 감싸는 `TypographyTierScope` | 상자 안과 배지 칸 안의 상자 없는 래퍼(`<div style="display: contents" data-coui-typography-tier="desktop">`) — `img` · 이니셜 `span` · `child` · 배지가 그 안에 있으므로, 아바타 상자의 직계 자식을 고르는 선택자(`.my-avatar > img`)는 후손 선택자(`.my-avatar img`)로 고르세요 |

## 관련 컴포넌트 (Related Components)

- **[Badge](/components/badge)**: 상태 텍스트 레이블. Avatar의 badge 대신 텍스트 기반 상태 표시
- **[Icon](/components/icon)**: 아이콘 시스템. Avatar의 커스텀 child로 아이콘 배치 가능
- **[HoverCard](/components/hover-card)**: 호버 미리보기. Avatar에 호버하면 프로필 카드 표시

### 조합 예제

```dart
// 댓글 목록 패턴
ListView.builder(
  itemBuilder: (context, index) {
    final comment = comments[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(
          imageUrl: comment.author.photoUrl,
          initials: Avatar.getInitials(comment.author.name),
          size: CoreComponentSize.sm,
          badge: comment.author.isOnline
              ? AvatarBadge(
                  avatarBadgeStyle: CoreAvatarBadgeStyle(
                    backgroundColor: CoreColor.token(CoreColors.success),
                  ),
                )
              : null,
        ),
        Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.author.name).bodyMedium.semiBold,
            Text(comment.body).bodySmall.onSurfaceVariant,
          ],
        )),
      ],
    );
  },
)
```
