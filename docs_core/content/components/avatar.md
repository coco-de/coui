---
title: Avatar
description: 사람 · 조직 · 앱을 사진이나 이니셜로 알아보게 하는 컴포넌트입니다. 크기 여섯 단계와 원 · 둥근 타일 두 모양이 있고, 링 · 상태 점 · 겹쳐 놓는 그룹을 더할 수 있습니다.
category: display
platforms: [flutter, web]
related: [badge, icon, hover-card]
tags: [user, profile, image]
template: v2
source: display/avatar
---

# Avatar

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 아바타를 확인하고, 만들어진 코드를 그대로 복사하세요. 아무 값도 주지 않은 `Avatar` 는 지름 32(`sm`)의 원에 `?` 를 그립니다. Flutter와 Web 코드가 같습니다.

<Playground component="avatar" />

<a id="구조-anatomy"></a>

## 구조

아바타는 면 하나에 내용 하나를 담고, 필요하면 배지를 얹습니다. `child` 와 `badge` 는 위젯 슬롯 이름이며 Figma [`❖ Avatar`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0?node-id=2467-151690) 레이어 이름과도 같습니다.

<Anatomy demo="avatar/anatomy">
<AnatomyItem part="container" name="Container">

아바타의 면 — 배경색, 모서리, 지름. 사진과 `child` 는 이 모서리를 따라 잘립니다.

</AnatomyItem>
<AnatomyItem part="label" name="initials">

내용. `child`, 사진(`imageUrl`), 이니셜(`initials`) 가운데 하나를 그립니다. 이 그림은 이니셜입니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-typography-tier] > div" side="right" name="badge">

면 위에 얹는 선택 슬롯. 보통 상태 점인 `AvatarBadge` 를 넣습니다.

</AnatomyItem>
</Anatomy>

`ring: true` 를 주면 면 바깥에 링이 하나 더 둘러집니다(링 효과 섹션).

## 내용

<Preview demo="avatar/content" />

아바타는 아래 순서로 처음 해당하는 것 하나를 가운데에 그립니다.

| 순서 | 조건 | 그리는 것 |
| --- | --- | --- |
| 1 | `child` 가 있음 | `child` |
| 2 | `imageUrl` 이 있음 | 사진. 지름에 맞춰 면을 채우고 넘치는 부분은 잘라 냅니다 |
| 3 | `initials` 가 있음 | 이니셜의 앞 두 글자 |
| 4 | 모두 없음 | `?` |

```dart
Avatar(imageUrl: 'https://example.com/photo.jpg', initials: 'JD')

Avatar(initials: Avatar.getInitials('Jane Doe')) // JD

Avatar(child: Icon(LucideIcons.house))
```

- 이니셜은 적은 그대로 그립니다. 대문자로 바꾸지 않습니다. 이름에서 이니셜을 뽑으려면 `Avatar.getInitials` 를 씁니다(API 섹션).
- 두 글자는 UTF-16 코드 단위로 셉니다. 이모지처럼 코드 단위 두 개를 차지하는 문자는 가운데에서 잘릴 수 있으니 이니셜에 넣지 않습니다.
- `initials: ''` 처럼 빈 문자열을 주면 `?` 도 그리지 않고 빈 면만 남습니다.
- `child` 로 넘긴 `Icon` 이 크기를 적지 않으면 크기 단계의 아이콘 크기를 받습니다. 아바타는 기본으로 아이콘 색을 정하지 않으므로 색은 둘레를 따릅니다. 둘레에서 색을 이어받는 방식은 두 플랫폼이 다릅니다(플랫폼 차이 섹션).

<a id="변형-variants"></a>

## 크기

<Preview demo="avatar/sizes" />

`size` 는 `CoreComponentSize` 여섯 단계이고 기본값은 `sm` 입니다. 두 플랫폼이 같은 표(`CoreAvatarStyle.defaultsBySize`)를 읽습니다.

```dart
Avatar(initials: 'JD', size: CoreComponentSize.md)
```

### 크기 단계마다 바뀌는 것

값은 기본 테마의 논리 px 입니다. 이니셜 굵기는 모든 단계에서 600 입니다.

| 크기 | 지름 | 이니셜 (글자 역할) | 둥근 타일의 모서리 | 배지 | 배지 안쪽 테두리 | `child` 아이콘 |
| --- | --- | --- | --- | --- | --- | --- |
| `xs` | 24 | 11 (`labelXs`) | 6 | 8 | 1 | 12 |
| `sm` | 32 | 13 (`labelMedium`) | 8 | 10 | 1 | 16 |
| `md` | 40 | 15 (`labelXl`) | 10 | 12 | 2 | 20 |
| `lg` | 48 | 18 (`titleMedium`) | 12 | 14 | 2 | 24 |
| `xl` | 64 | 24 (`headlineSmall`) | 16 | 16 | 2 | 32 |
| `xl2` | 96 | 32 (`headlineLarge`) | 24 | 20 | 2 | 48 |

- **이니셜** 은 지름처럼 화면 폭이 바뀌어도 같은 단계를 씁니다. `xl` · `xl2` 의 역할(`headlineSmall` · `headlineLarge`)은 좁은 화면에서 작아지는 역할이지만, 이니셜은 지름이 그대로인 면을 채우도록 고른 글자라 두 플랫폼 모두 아바타의 내용과 배지를 데스크톱 단계로 고정합니다([화면 폭에 따른 단계](/guides/typography#화면-폭에-따른-단계)).
- **글자 크기 설정** — Flutter 는 기기의 글자 배율을 이니셜에 적용하지 않습니다. 고정된 지름 안에서 글자만 커지면 두 글자가 넘치기 때문입니다. Web 은 지름과 이니셜이 모두 `rem` 이라 브라우저의 기본 글자 크기를 함께 따릅니다.
- **배지** 크기는 `badge` 슬롯에 넣은 `AvatarBadge` 에 전달됩니다. 배지가 `avatarBadgeStyle` 에 크기를 직접 적으면 그 값이 이깁니다. `AvatarBadge` 가 아닌 위젯은 이 값을 받지 않습니다.
- **배지 안쪽 테두리** 는 점 가장자리 안쪽에 그리는 `surface` 색 고리로, 사진이나 아바타 면 위에서 점의 윤곽을 갈라 줍니다. 혼자 쓰는 `AvatarBadge` 는 2이고, 아바타 안에서는 `xs` · `sm` 단계가 1을 넘깁니다. 안쪽으로 그리므로 점의 크기는 그대로입니다 — Flutter 는 `foregroundDecoration` 의 테두리, Web 은 `inset` `box-shadow` 입니다.
- **`child` 아이콘** 크기는 지름의 절반 안팎입니다(`childIconStyle`). `Icon` 이 크기를 직접 적거나 앱의 아이콘 테마(`CoreComponentTheme.icon`)에 크기를 정해 두었으면 그 값이 이깁니다.

### 지름 직접 지정

크기 단계는 여섯 개뿐이라 44 나 56 처럼 단계 사이에 있는 지름은 단계로 고를 수 없습니다. 이런 지름은 그 아바타에만 `avatarStyle: CoreAvatarStyle(diameter: …)` 로 정합니다. 아바타의 면 · 사진 · 링은 정한 지름에 맞춰 그려지고, 배지는 그 지름을 기준으로 자리를 잡습니다. 배지 자체의 크기는 지름과 상관없이 크기 단계의 값입니다.

<Preview demo="avatar/diameter" />

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

**이니셜 글자 크기.** 기본으로 이니셜은 지름이 아니라 고른 크기 단계(`size`)의 글자 크기를 씁니다. 그래서 지름에 가까운 단계를 `size` 로 함께 고릅니다. `size` 를 빼면 기본 크기 `sm` 의 작은 글자가 남습니다. 위 두 아바타는 둘 다 `lg` 라서 지름이 달라도 글자 크기가 같습니다.

- 글자 크기만 따로 바꾸려면 `fallbackTextStyle` 에 `fontSize` 를 적습니다. 자간과 행간의 비율은 고른 크기 단계의 것을 그대로 씁니다.
- 글자 크기를 지름에 비례시키려면 `initialsFontRatio` 를 씁니다(글자 크기 = 지름 × 비율). `fallbackTextStyle.fontSize` 를 함께 적으면 `fontSize` 가 이깁니다.

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

둥근 타일(`shape: CoreAvatarShape.rounded`)의 모서리도 지름이 아니라 고른 크기 단계의 값을 씁니다(형태 섹션).

`AvatarGroup` 은 안에 든 아바타의 `diameter` 를 읽지 않습니다. `+N` 아바타는 첫 아바타의 `size` 지름으로 그리고, Flutter 의 줄 높이는 고정되어 있습니다. 그래서 지름을 직접 정한 아바타는 그룹에 넣지 않습니다(그룹 섹션).

**Figma.** Avatar 세트의 `Initials` 속성은 글자 수를 제한하지 않지만 코드는 앞 두 글자만 그리므로 1~2글자를 넣습니다. 이니셜은 타이포 모드(Mobile · Tablet · Desktop)를 따르지 않는 고정 크기입니다. 단계에 없는 지름은 먼저 `Size` 를 가까운 단계로 고른 뒤 인스턴스 크기를 맞춥니다. 새 인스턴스는 `sm` 으로 시작하므로 크기만 바꾸면 이니셜이 작게 남습니다. 원의 배지는 Figma 의 고정(constraints)이 테두리 위의 점을 따라가지 못해, 인스턴스 크기를 바꾸면 모서리 쪽으로 조금 밀립니다. 세트에 크기별로 있는 컴포넌트에서는 자리가 정확합니다.

<a id="모양"></a>

## 형태

사람은 원, 조직 · 워크스페이스 · 앱은 둥근 타일로 그립니다. `shape` 하나로 고르며 기본값은 원(`circle`)입니다.

<Cards columns="2">
<Card component="avatar" props="shape=circle;size=xl" label="JD" title="circle">

사람. 모서리는 알약이라 정사각형 면에서 원이 됩니다.

</Card>
<Card component="avatar" props="shape=rounded;size=xl" label="CO" title="rounded">

조직 · 워크스페이스 · 앱. 모서리가 크기마다 지름의 1/4 입니다 — `xs` 6 · `sm` 8 · `md` 10 · `lg` 12 · `xl` 16 · `xl2` 24.

</Card>
</Cards>

```dart
Avatar(initials: 'JD')

Avatar(initials: 'CO', shape: CoreAvatarShape.rounded)
```

`shape` 가 바꾸는 것은 모서리와 배지를 놓는 방식입니다(배지 섹션). 지름, 이니셜, 사진, 링 설정은 그대로입니다. `avatarStyle.borderRadius` 를 적으면 두 모양 모두 그 모서리로 그립니다.

둥근 타일의 모서리는 지름에서 계산하지 않고 크기 단계마다 정해 둔 값입니다. 그래서 `avatarStyle.diameter` 로 지름만 바꾸면 모서리는 크기 단계의 값에 남습니다.

둥근 타일의 모서리는 테마의 밀도(`CoreDensity`)와 표면 스타일에도 영향을 받습니다. 지름은 이 둘에 따라 움직이지 않으므로 모서리가 지름의 1/4 에서 벗어날 수 있습니다.

- `compact` 는 `md` · `lg` · `xl` 의 모서리를 10 → 8 · 12 → 10 · 16 → 14 로 줄입니다.
- `spacious` 는 `xs` · `sm` · `md` · `lg` 의 모서리를 6 → 8 · 8 → 10 · 10 → 12 · 12 → 14 로 키웁니다.
- 나머지 크기는 두 밀도에서 그대로입니다.
- 모서리 범위를 정해 둔 표면 스타일은 반경 단계 위에서 값을 다시 나누므로 `xl2` 의 24 도 달라질 수 있습니다. 원의 알약 모서리는 모든 모서리를 각지게 하는 스타일에서만 바뀝니다.

<a id="ring-효과"></a>

## 링 효과

`ring: true` 는 아바타와 간격을 두고 바깥에 링을 두릅니다.

<Preview demo="avatar/ring" />

```dart
Avatar(initials: 'JD', ring: true)

Avatar(
  initials: 'JD',
  ring: true,
  avatarStyle: CoreAvatarStyle(
    ringColor: CoreColor.token(CoreColors.success),
    ringWidth: CoreStrokeWidth.stroke3,
  ),
)
```

| 값 | 기본값 | 바꾸는 필드 |
| --- | --- | --- |
| 링 두께 | 2 (`CoreStrokeWidth.stroke2`) | `ringWidth` |
| 링 색 | `primary` | `ringColor` |
| 링 간격 | 2 | `ringOffset` |

- 링은 아바타가 차지하는 레이아웃 크기를 늘리지 않고 바깥에 그립니다. 기본값이면 사방으로 4px 가 더 나오므로 둘레에 그만큼 여유를 둡니다.
- 링의 모서리는 아바타 모서리를 키운 값입니다. 간격의 바깥은 `r + ringOffset`, 링의 바깥은 `r + ringOffset + ringWidth` 라서 원은 원으로, 둥근 타일은 둥근 사각으로 둘러집니다.
- 간격은 투명이 아니라 `surface` 색으로 칠합니다. 이 색을 바꾸는 필드는 없으므로 `surface` 가 아닌 바탕에서는 간격이 띠처럼 보입니다.
- Web 은 링을 켜면 바깥에 `<div>` 를 하나 더 둡니다. `id` · `classes` · `css` · `attributes` · `eventHandlers` 는 안쪽의 아바타 요소에 남습니다. 바깥 여백이나 배치 클래스는 아바타를 감싼 자신의 요소에 주세요.

## 배지

`badge` 슬롯은 아바타 위에 위젯 하나를 얹습니다. 상태 점에는 `AvatarBadge` 를 씁니다.

<Preview demo="avatar/badge-placement" />

```dart
Avatar(
  initials: 'JD',
  size: CoreComponentSize.xl,
  badge: AvatarBadge(
    avatarBadgeStyle: CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  ),
)

Avatar(
  initials: 'JD',
  size: CoreComponentSize.xl,
  avatarStyle: CoreAvatarStyle(badgeAlignment: CoreAlignment.bottomEnd),
  badge: AvatarBadge(),
)
```

- `AvatarBadge` 는 원 모양의 점입니다. 혼자 쓰면 지름 12, 면 색 `primary`, 안쪽 테두리는 `surface` 색 2입니다. 아바타 안에서는 크기 단계의 값을 받고, 배지의 `avatarBadgeStyle` 에 적은 값이 그 위를 덮습니다.
- `AvatarBadge` 의 `child` 는 점 가운데에 놓입니다. 점은 `child` 에 맞춰 커지지 않으므로 글이나 숫자를 넣지 않습니다. 아바타 모서리에 읽지 않은 개수를 얹으려면 [Badge](/components/badge)의 `count` 형태를 [Indicator](/components/indicator)로 얹습니다.

### 배지 자리

배지는 `badgeAlignment` 가 가리키는 모서리(기본 `topEnd`)에 놓이고, 놓는 방식(`badgePlacement`)은 모양이 정합니다.

| 모양 | `badgePlacement` | 자리 |
| --- | --- | --- |
| 원 | `outline` | 배지의 중심이 원 테두리 위에 옵니다. `topEnd` 는 오른쪽 위 45° 지점입니다 |
| 둥근 타일 | `corner` | 배지를 감싸는 상자의 모서리가 아바타 상자의 모서리에 맞춰집니다 |

- `badgeInset`(기본 0)은 배지를 가운데 쪽으로 당깁니다. `corner` 는 면의 가장자리에서, `outline` 은 테두리에서 잽니다.
- `badgePlacement` 를 테마나 `avatarStyle` 에 적으면 모양의 기본값 대신 그 방식을 씁니다.
- 두 플랫폼이 같은 계산(`CoreAvatarStyle.badgeAnchorFor`)을 씁니다. 자리의 기준점은 배지 크기와 무관합니다.
- `topEnd` 의 End 는 오른쪽입니다. 오른쪽에서 왼쪽으로 쓰는 화면에서도 좌우가 뒤집히지 않습니다.

## 그룹

`AvatarGroup` 은 여러 아바타를 겹쳐 한 줄로 놓습니다.

<Preview demo="avatar/group" />

```dart
AvatarGroup(
  max: 3,
  children: [
    Avatar(initials: 'AB'),
    Avatar(initials: 'CD'),
    Avatar(initials: 'EF'),
    Avatar(initials: 'GH'),
    Avatar(initials: 'IJ'),
  ],
)
```

위 그림은 겹친 경계가 보이도록 두 번째와 세 번째 아바타의 면 색과 글자색을 바꿨습니다.

- 이웃한 아바타는 `overlap`(기본 16)만큼 겹치고, `extraSpacing`(기본 0)은 그 간격을 다시 벌립니다. 기본 방향(`toLeft`)에서는 뒤의 아바타가 앞의 아바타 위에 그려집니다.
- `max` 보다 아바타가 많으면 앞에서 `max` 개를 그리고, 남은 수를 `+N` 아바타로 덧붙입니다. `max` 는 1 이상으로 줍니다. 0 을 주면 오류가 납니다.
- `+N` 아바타는 첫 아바타의 `size` 만 따릅니다. `shape` 와 `avatarStyle` 은 이어받지 않아, 기본 모양인 원으로 그립니다.
- `direction: CoreAvatarGroupDirection.toRight`(또는 `AvatarGroup.toRight`)는 순서를 뒤집어 첫 아바타를 오른쪽 끝에 놓습니다.

### 그룹의 제한

| 대상 | 지금 동작 | 이렇게 씁니다 |
| --- | --- | --- |
| 두 플랫폼 | `+N` 도 이니셜이라 앞 두 글자만 그립니다. 남은 수가 12 면 화면에는 `+1` 이 보입니다 | 남은 수가 9 이하가 되도록 `max` 를 정합니다 |
| Flutter | 줄 높이가 기본 크기(`sm`)의 지름과 구분 선에 맞춰 고정됩니다. `sm` 보다 큰 `size` 나 지름은 세로만 눌려 원이 아닌 모양이 됩니다 | `xs` · `sm` 아바타를 넣습니다 |
| Flutter | 겹침은 그리는 위치만 옮깁니다. 그룹이 차지하는 폭은 줄지 않아 오른쪽에 빈 자리가 남습니다 | 그룹 오른쪽에 다른 요소를 붙일 때 이 폭을 고려합니다 |
| Flutter | 구분 선은 항상 원입니다 | 둥근 타일은 그룹에 넣지 않습니다 |
| Jaspr Web | `badge` 가 없는 아바타에는 기본 구분 선이 그려지지 않습니다. 아바타의 인라인 스타일이 선의 두께와 색을 덮습니다 | 구분 선이 필요하면 `avatarGroupStyle` 에 `borderWidth` 와 `borderColor` 를 함께 적습니다 |
| Jaspr Web | `badge` 가 있는 아바타는 구분 선이 면과 배지를 감싼 바깥 상자에 붙습니다. 이 상자에는 둥근 모서리가 없어 네모 선이 됩니다 | 그룹 안에서는 `badge` 를 넣지 않습니다 |
| Jaspr Web | `ring: true` 인 아바타는 겹침 여백이 링 안쪽 요소에 붙어 링과 면이 어긋납니다 | 그룹 안에서는 `ring` 을 켜지 않습니다 |
| Jaspr Web | `toRight` 에서는 첫 번째와 두 번째 아바타가 겹치지 않습니다. 위에 그려지는 순서도 Flutter 와 반대입니다 | 두 플랫폼의 모양을 맞추려면 `toLeft` 를 씁니다 |

```dart
AvatarGroup(
  avatarGroupStyle: CoreAvatarGroupStyle(
    borderWidth: CoreStrokeWidth.stroke2,
    borderColor: CoreColor.token(CoreColors.surface),
  ),
  children: [
    Avatar(initials: 'AB'),
    Avatar(initials: 'CD'),
  ],
)
```

<a id="동작-스펙-behavior"></a>

## 상태

`Avatar` 는 표시 전용입니다. 누르기, 선택, 비활성 상태가 없고 hover · pressed · 포커스 모양도 그리지 않습니다. 로딩 중임을 알리는 속성도 없습니다.

### 이미지 로딩

- `child` 가 없고 `imageUrl` 이 있으면 사진을 그립니다. Flutter 는 `Image.network`(`BoxFit.cover`), Web 은 `<img>`(`object-cover`)입니다.
- 아바타가 따로 그리는 로딩 표시는 없습니다. Flutter 는 사진의 첫 장면이 오기 전까지 배경색 면만 보이고, Web 은 `<img>` 하나만 둡니다.
- 불러오기가 끝났거나 실패했는지 알려 주는 콜백은 없습니다. 로딩 대역이 필요하면 앱이 아는 상태에 따라 `child` 를 넘기거나 아바타 자리를 다른 위젯으로 바꿉니다.

### 이미지 폴백

- Flutter 는 사진을 불러오지 못하면 이니셜을 대신 그립니다. 이니셜이 없으면 `?` 입니다.
- Web 은 `<img>` 의 실패를 처리하지 않습니다. 이니셜로 바뀌지 않고, 실패한 이미지가 어떻게 보일지는 브라우저가 정합니다.
- 그래서 Web 에서 이니셜을 대신 보여 주려면, 사진을 쓸 수 없다는 것을 앱이 알았을 때 `imageUrl` 을 넘기지 않습니다.

```dart
Avatar(
  imageUrl: 'https://example.com/photo.jpg',
  initials: 'JD',
  size: CoreComponentSize.md,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

### 이럴 때 씁니다

- 댓글, 채팅, 팀 멤버 목록에서 사용자를 눈으로 구분할 때
- 프로필 사진을 보여 주고, 사진이 없는 자리는 이니셜로 채울 때
- 조직 · 워크스페이스 · 앱처럼 사람이 아닌 주체를 표시할 때 (`shape: CoreAvatarShape.rounded`)
- 사람 옆에 접속 중인지 같은 상태를 점으로 함께 보여 줄 때 (`badge`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 사진이나 이니셜 없이 그림 하나만 표시할 때 | [Icon](/components/icon) |
| 사용자가 아니라 상태 낱말이나 개수를 표시할 때 | [Badge](/components/badge) |
| 접속 상태를 글과 함께 따로 표시할 때 | [Status](/components/status) |

### 내용 · 상태 · 크기

<Cards columns="2">
<Card demo="avatar/do-initials" tone="do" eyebrow="이렇게 하세요">

누구인지 알 수 있는 이니셜을 줍니다. 사진을 쓸 때도 `initials` 를 함께 넘기면 Flutter 의 실패 폴백과 두 플랫폼의 이미지 이름에 쓰입니다.

</Card>
<Card demo="avatar/dont-empty" tone="dont" eyebrow="이렇게 하지 마세요">

내용을 아무것도 주지 않으면 `?` 만 보여 누구인지 알 수 없습니다.

</Card>
<Card demo="avatar/do-role-text" tone="do" eyebrow="이렇게 하세요">

역할처럼 자주 바뀌지 않는 정보는 이름 옆에 글로 적습니다. 점 배지는 접속 중인지처럼 바뀌는 상태에 씁니다.

</Card>
<Card demo="avatar/dont-role-dot" tone="dont" eyebrow="이렇게 하지 마세요">

점의 색만으로 역할을 나타내면 무슨 뜻인지 알 수 없습니다.

</Card>
<Card demo="avatar/do-row-size" tone="do" eyebrow="이렇게 하세요">

댓글처럼 글이 주인공인 줄에는 `sm` 처럼 작은 크기를 씁니다. 프로필 머리처럼 사람이 주인공인 곳에는 `lg` 이상을 씁니다.

</Card>
<Card demo="avatar/dont-row-size" tone="dont" eyebrow="이렇게 하지 마세요">

댓글 줄에 `xl` 을 쓰면 내용보다 아바타가 눈에 띕니다.

</Card>
</Cards>

여러 명을 겹쳐 놓을 때는 `AvatarGroup` 의 `max` 로 보이는 수를 줄입니다(3~5개 권장). 남은 수가 두 자리가 되지 않게 정합니다(그룹 섹션).

## 배치

아바타는 목록 행, 댓글, 머리글에서 이름 앞에 놓습니다.

<Preview demo="avatar/placement-comment" />

Web 에서 `badge` 와 `ring` 이 모두 없는 아바타는 가로 flex 줄의 옆 글이 길면 폭이 눌릴 수 있습니다. 아바타 요소가 `min-width: 0` 을 인라인 스타일로 갖기 때문입니다. 이런 줄에서는 `classes: 'shrink-0'` 을 줍니다.

### 조합 예제

댓글 한 줄입니다. `comment` 는 앱의 데이터입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Avatar(
      imageUrl: comment.author.photoUrl,
      initials: Avatar.getInitials(comment.author.name),
      badge: comment.author.isOnline
          ? AvatarBadge(
              avatarBadgeStyle: CoreAvatarBadgeStyle(
                backgroundColor: CoreColor.token(CoreColors.success),
              ),
            )
          : null,
    ),
    const Gap.space12(),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.author.name).bodyMedium.semiBold,
          Text(comment.body).bodySmall.onSurfaceVariant,
        ],
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [
    Avatar(
      imageUrl: comment.author.photoUrl,
      initials: Avatar.getInitials(comment.author.name),
      classes: 'shrink-0',
      badge: comment.author.isOnline
          ? AvatarBadge(
              avatarBadgeStyle: CoreAvatarBadgeStyle(
                backgroundColor: CoreColor.token(CoreColors.success),
              ),
            )
          : null,
    ),
    const Gap.space12(),
    div(
      [
        Text(comment.author.name).bodyMedium.semiBold,
        Text(comment.body).bodySmall.onSurfaceVariant,
      ],
      classes: 'flex flex-col flex-1 min-w-0',
    ),
  ],
  classes: 'flex flex-row items-start',
)
```

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

색 · 크기 · 간격 같은 겉모습과 안쪽 부품의 스타일은 `avatarStyle`(`CoreAvatarStyle`) 하나로 바꿉니다. 앱 전체에는 `CoreComponentTheme.avatar`(`CoreAvatarTheme`)의 `style` 에 같은 타입을 넣습니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 내용 · 동작** — 위젯 파라미터로 직접 넘깁니다: `size`, `shape`, `ring`, `imageUrl`, `initials`, `child`, `badge`.
- **겉모습과 안쪽 부품의 스타일** — `CoreAvatarStyle` 로 넘깁니다: `backgroundColor` · `diameter` · `borderRadius` · `ringColor` · `ringWidth` · `ringOffset` · `badgeInset` · `badgeAlignment` · `badgePlacement` · `initialsFontRatio` · `fallbackTextStyle` · `badgeStyle` · `childIconStyle`. 이니셜 글자색은 `fallbackTextStyle.color` 로 정합니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤에 있는 것이 앞의 값을 필드마다 덮습니다.

```text
defaultsBySize[size] → defaultsByShape[shape] · CoreAvatarStyle.defaultX  // 디자인 시스템 기본값
  → CoreAvatarTheme.style                                                 // 앱 전체
  → avatarStyle                                                           // 아바타 하나
```

- 크기 단계는 지름, 이니셜의 글자 역할, 둥근 타일의 모서리, 배지 스타일, `child` 아이콘 크기를 정합니다. 모양은 그 위에 배지를 놓는 방식을 정하고, 원이면 모서리를 알약으로 바꿉니다.
- `badgeStyle` · `childIconStyle` · `fallbackTextStyle` 은 안의 필드까지 하나씩 합칩니다. 색만 적어도 크기 단계의 크기와 글자 역할은 남습니다.
- `size` 와 `shape` 는 위젯 파라미터라 테마로 바꿀 수 없습니다. 크기별 · 모양별 테마 자리도 없습니다. 그래서 테마에 `diameter`, `badgeStyle.size`, `fallbackTextStyle.fontSize`, `borderRadius` 를 적으면 모든 크기와 모양이 그 값 하나를 씁니다.
- 아바타의 면은 `OutlinedContainer` 로 그립니다. `CoreComponentTheme.outlinedContainer` 에 적은 값 가운데 아바타가 직접 정하지 않는 것(예: 그림자)은 아바타의 면에도 적용됩니다.
- `AvatarBadge` 와 `AvatarGroup` 은 자신의 테마 자리가 없습니다. 아바타의 `badge` 슬롯에 넣은 `AvatarBadge` 만 `CoreAvatarTheme.style.badgeStyle` 로 앱 전체에서 바꿀 수 있습니다.

### 사용 예

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>

<Split>

<Code language="dart" title="아바타 하나만 바꾸기">
Avatar(
  initials: 'A',
  ring: true,
  avatarStyle: CoreAvatarStyle(
    ringColor: CoreColor.token(CoreColors.success),
    ringWidth: CoreStrokeWidth.stroke3,
    fallbackTextStyle: CoreTextStyle.token(
      CoreTextStyles.labelLarge,
      color: CoreColor.token(CoreColors.onPrimaryContainer),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    avatar: CoreAvatarTheme(
      style: CoreAvatarStyle(
        badgeAlignment: CoreAlignment.bottomEnd,
        ringColor: CoreColor.token(CoreColors.success),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

### 배경색 커스텀

배경색은 위젯 파라미터가 아니라 `avatarStyle` 로 바꿉니다. 기본 면은 `primaryContainer`, 이니셜은 `onPrimaryContainer` 입니다. 면 색을 바꿀 때는 글자색도 짝이 되는 색으로 함께 바꿉니다.

<Preview demo="avatar/background" />

```dart
Avatar(
  initials: 'B',
  avatarStyle: CoreAvatarStyle(
    backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
    fallbackTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onSecondaryContainer),
    ),
  ),
)
```

### 관련 컴포넌트의 Style 슬롯

| 컴포넌트 | 슬롯 | 담는 것 |
| --- | --- | --- |
| `AvatarBadge` | `avatarBadgeStyle: CoreAvatarBadgeStyle?` | 점의 면 색(`backgroundColor`) · 지름(`size`) · 안쪽 테두리(`borderColor` · `borderWidth`). `Avatar` 안에서는 아바타의 `badgeStyle` 위에 덮입니다 |
| `AvatarGroup` | `avatarGroupStyle: CoreAvatarGroupStyle?` | 겹침(`overlap` · `extraSpacing`)과 겹친 아바타를 갈라 보이게 하는 구분 선(`borderColor` · `borderWidth`) |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Avatar` 에 `withStyle` 을 이어 `avatarStyle` 을 덧붙일 수 있습니다. 앞서 있던 `avatarStyle` 위에 합치고, 같은 필드는 나중에 이은 값이 이깁니다. `.radius16` 처럼 Core 토큰과 이름이 같은 getter 는 모서리(`borderRadius`)를, `.primary` 같은 색 getter 는 면 색(`backgroundColor`)만 바꿉니다. 이니셜 글자색은 그대로이므로 진한 면을 고르면 `fallbackTextStyle.color` 도 함께 바꾸세요. Web 에서는 `classes` · `css` · `attributes` · `eventHandlers` 가 체인 뒤에도 남습니다.

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

<a id="접근성-accessibility"></a>

## 접근성

Web 의 아바타는 이름이 붙은 이미지 하나이고, Flutter 의 아바타는 사진을 그릴 때만 따로 이름을 붙입니다. 두 플랫폼 모두 누르거나 포커스를 받는 요소가 아닙니다.

### 역할

| 플랫폼 | 아바타 | 배지 · 그룹 |
| --- | --- | --- |
| Jaspr Web | 아바타 요소(`<div>`)에 `role="img"` 와 `aria-label` 이 붙습니다. 값은 `initials`, 없으면 영어 낱말 `avatar` 입니다. 사진의 `<img alt>` 도 같은 값입니다 | `AvatarBadge` 와 `AvatarGroup` 에는 role 과 aria 속성이 없습니다 |
| Flutter | `Avatar` 가 직접 두는 `Semantics` 는 없습니다. 사진을 그릴 때만 `Image.network` 의 `semanticLabel`(`initials`, 없으면 `avatar`)이 이미지 시맨틱을 만듭니다 | `AvatarBadge` 와 `AvatarGroup` 은 시맨틱을 붙이지 않습니다 |

### 키보드

없음. 아바타는 두 플랫폼 모두 탭 순서에 들어가지 않고 키 입력을 받지 않으며, `onPressed` 같은 누름 파라미터가 없습니다. Web 의 `eventHandlers` 로 이벤트를 붙여도 역할, 탭 순서, 키보드 조작은 생기지 않습니다. 누르는 동작이 필요하면 아바타를 버튼이나 링크 안에 넣고 그 컨트롤에 이름을 붙입니다.

### 스크린 리더

보조 기술에 전달하는 글은 내용과 플랫폼에 따라 다릅니다. 실제로 읽는 말은 브라우저, 운영체제, 스크린 리더에 따라 다를 수 있습니다.

| 그리는 것 | Flutter 의 시맨틱에 담기는 글 | Web 의 `aria-label` |
| --- | --- | --- |
| 사진 (불러오는 중 포함) | `initials` 전체, 없으면 `avatar` | `initials` 전체, 없으면 `avatar` |
| 사진을 불러오지 못함 | 화면의 글자 — 이니셜 앞 두 글자, 없으면 `?` | 그대로 `initials` 전체, 없으면 `avatar` |
| 이니셜 | 화면에 그린 앞 두 글자 | `initials` 전체 |
| 아무 내용 없음 | `?` | `avatar` |
| `child` | `child` 가 가진 시맨틱 | `initials`, 없으면 `avatar` |

`AvatarGroup` 의 `+N` 아바타도 같은 규칙을 따릅니다. 남은 수가 12 면 Web 의 이름은 `+12` 전체이고, Flutter 는 화면의 `+1` 을 전달합니다. 상태가 바뀐 것을 알리는 라이브 영역은 두 플랫폼 모두 없습니다.

#### 이름 주기

<Preview demo="avatar/a11y-name" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 아바타 안의 글 대신 이 이름 하나를 전달합니다
Semantics(
  label: 'JD, 온라인',
  image: true,
  excludeSemantics: true,
  child: Avatar(initials: 'JD', badge: AvatarBadge()),
)

// 바로 옆에 이름이 있어 아바타가 장식일 때
ExcludeSemantics(child: Avatar(initials: 'JD'))
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// attributes 는 기본 aria-label 을 덮어씁니다
Avatar(
  initials: 'JD',
  badge: AvatarBadge(),
  attributes: {'aria-label': 'JD, 온라인'},
)

// 바로 옆에 이름이 있어 아바타가 장식일 때
Avatar(initials: 'JD', attributes: {'aria-hidden': 'true'})
```

  </TabItem>
</Tabs>

### 포커스 관리

없음. 아바타는 포커스를 받지 않으므로 포커스를 옮기거나 가두지 않고, 포커스 링도 그리지 않습니다. `ring: true` 의 링은 포커스 표시가 아닙니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 이름의 기본값 `avatar` 는 번역하지 않는 영어 낱말입니다. 사람을 알아볼 수 있게 `initials` 를 주거나 위의 방법으로 이름을 붙입니다 |
| 공통 | `AvatarBadge` 에는 이름이 없고 점은 색으로만 뜻을 나타냅니다. 상태는 아바타의 이름이나 옆의 글로도 알려 줍니다 |
| 공통 | `AvatarGroup` 에는 그룹 전체의 이름이나 역할이 없습니다. 필요하면 바깥에서 감싸 붙입니다 |
| Flutter | 이름을 받는 파라미터가 없습니다. 이니셜을 그릴 때 전달되는 글은 화면의 앞 두 글자뿐이고, 사진을 불러오지 못하면 사진에 붙던 이름도 함께 사라집니다 |
| Jaspr Web | 배지는 `role="img"` 인 아바타 안에 있습니다. ARIA 는 `img` 역할의 자식을 표시용으로 다루므로, 배지에 담은 정보가 따로 전달된다고 가정하지 않습니다. Flutter 에서는 `badge` 에 넣은 위젯이 가진 시맨틱이 그대로 남아, 두 플랫폼이 다릅니다 |
| Jaspr Web | `AvatarBadge` 와 `AvatarGroup` 은 `attributes` 를 받지 않습니다 |

#### 색상 대비

기본 이니셜은 `primaryContainer` 위의 `onPrimaryContainer` 입니다. 저장소의 대비 검사(`check_contrast.dart`)는 이 짝을 라이트, 다크, 고대비 라이트, 고대비 다크 색에서 확인하며, 예외 목록에 이 짝은 없습니다. 면 색이나 글자색을 직접 바꾸면 이 확인이 그 조합까지 보장하지 않으므로 대비를 따로 확인합니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`imageUrl` · `initials` · `size` · `shape` · `ring` · `child` · `badge` · `avatarStyle` 은 두 플랫폼이 같은 API 입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget?` | `Component?` |
| 사진 | `Image.network` | `<img>` |
| 사진 실패 | `errorBuilder` 가 이니셜을 그립니다 | 처리하지 않습니다. `<img>` 가 그대로 남습니다 |
| 사진 · `child` 자르기 | 아바타 면(`OutlinedContainer`)의 클립이 모서리를 따릅니다 | 아바타 면의 `overflow: hidden` 이 모서리를 따릅니다 |
| 링 | 아바타 바깥에 간격과 선을 두 겹으로 그립니다 | 바깥 래퍼의 두 겹 `box-shadow`. HTML 속성은 안쪽 요소에 남습니다 |
| 접근 가능한 이름 | 사진을 그릴 때만 따로 붙입니다 | 늘 `role="img"` 와 `aria-label` 을 붙입니다 |
| `childIconStyle.color` | 쓰지 않습니다. 아이콘 크기만 전달합니다 | 크기와 색을 모두 전달합니다 |
| 색을 정하지 않은 `child` 아이콘 | 바깥 `IconTheme` 의 색을 이어받습니다 | 아바타의 `childIconStyle` 에도 색이 없으면 바깥 `IconTheme` 의 색 대신 CSS 글자색(`currentColor`)을 따릅니다 |
| 데스크톱 단계 고정 | 아바타 전체를 `TypographyTierScope` 로 감쌉니다 | 내용과 배지를 각각 상자가 없는 래퍼(`<div style="display: contents" data-coui-typography-tier="desktop">`)로 감쌉니다. 그래서 `.my-avatar > img` 같은 직계 자식 선택자 대신 `.my-avatar img` 처럼 후손 선택자를 씁니다 |
| 크기 배율 | 테마의 크기 배율(`scaling`)을 지름 · 링 · 배지 · 그룹 겹침에 곱합니다 | 지름과 배지를 `rem` 으로 냅니다 |
| 브라우저 · 기기의 글자 크기 | 기기의 글자 배율은 이니셜에 적용하지 않습니다 | 지름과 이니셜이 브라우저 기본 글자 크기를 함께 따릅니다 |
| 그룹 겹침 | 그리는 위치만 옮겨 차지하는 폭은 줄지 않습니다 | 음수 `margin-left` 라 차지하는 폭도 줄어듭니다 |
| 그룹의 줄 | 내용만큼의 폭, 고정된 높이 | `display: flex` 인 블록. 높이는 고정하지 않습니다. `toRight` 는 이 블록의 오른쪽 끝부터 채웁니다 |
| 그룹 구분 선 | 모든 아바타를 원 모양 선으로 두릅니다 | `badge` 가 없는 아바타에는 기본 선이 그려지지 않고, `badge` 가 있는 아바타에는 네모 선이 그려집니다 |
| 그룹 `toRight` | 첫 아바타가 오른쪽 끝, 맨 위에 옵니다 | 첫 아바타가 오른쪽 끝에 오지만 둘째와 겹치지 않고, 뒤의 아바타가 위에 옵니다 |
| HTML 속성 | 없음 | `Avatar` 는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 를, `AvatarBadge` 와 `AvatarGroup` 은 `id` 를 받습니다 |

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. Web 에만 있는 속성은 따로 적었습니다.

### `Avatar` 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `imageUrl` | `String?` | `null` | 사진 주소. `child` 가 없을 때 그립니다 |
| `initials` | `String?` | `null` | 이니셜. 앞 두 글자를 그리며, 사진과 Web 아바타의 이름으로는 전체를 씁니다 |
| `size` | `CoreComponentSize` | `sm` | `xs` · `sm` · `md` · `lg` · `xl` · `xl2` |
| `shape` | `CoreAvatarShape` | `circle` | `circle`(원) · `rounded`(둥근 타일) |
| `ring` | `bool` | `false` | 바깥 링을 그립니다 |
| `child` | `W?` | `null` | 사진과 이니셜 대신 그릴 내용 |
| `badge` | `W?` | `null` | 아바타 위에 얹을 위젯. 상태 점은 `AvatarBadge` |
| `avatarStyle` | `CoreAvatarStyle?` | `null` | 이 아바타의 겉모습 |

### `Avatar` 의 Web 전용 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 아바타 요소의 id |
| `classes` | `String?` | `null` | 아바타 요소에 더할 클래스 |
| `css` | `Styles?` | `null` | 아바타 요소에 더할 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성. 기본 `role` · `aria-label` 과 겹치면 이 값이 이깁니다 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 아바타 요소의 DOM 이벤트 |

### `AvatarBadge`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W?` | `null` | 점 가운데에 놓을 내용 |
| `avatarBadgeStyle` | `CoreAvatarBadgeStyle?` | `null` | 점의 겉모습 |
| `id` | `String?` | `null` | Web 전용. 점 요소의 id |

### `CoreAvatarBadgeStyle` 필드

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `backgroundColor` | `CoreColor?` | `primary` | 점의 면 색 |
| `size` | `double?` | 12 | 점의 지름. 아바타 안에서는 크기 단계의 값이 기본값입니다 |
| `borderColor` | `CoreColor?` | `surface` | 점 안쪽 테두리 색 |
| `borderWidth` | `double?` | 2 | 점 안쪽 테두리 두께. `xs` · `sm` 아바타 안에서는 1 이고, 0 이면 그리지 않습니다 |

### `AvatarGroup`

`AvatarGroup.toLeft` · `AvatarGroup.toRight` 생성자는 방향을 고정해, `direction` 을 받지 않습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `children` | `List<Avatar>` | 필수 | 겹쳐 놓을 아바타 |
| `direction` | `CoreAvatarGroupDirection` | `toLeft` | `toLeft` · `toRight` |
| `max` | `int?` | `null` | 보일 아바타 수(1 이상). 넘치면 `+N` 을 덧붙입니다. `null` 이면 모두 그립니다 |
| `avatarGroupStyle` | `CoreAvatarGroupStyle?` | `null` | 겹침과 구분 선 |
| `id` | `String?` | `null` | Web 전용. 그룹 요소의 id |

### `CoreAvatarGroupStyle` 필드

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `overlap` | `double?` | 16 | 이웃과 겹치는 길이 |
| `extraSpacing` | `double?` | 0 | 겹침 위에 더하는 간격 |
| `borderColor` | `CoreColor?` | `surface` | 구분 선 색 |
| `borderWidth` | `double?` | 2 | 구분 선 두께. Web 의 구분 선 제한은 그룹 섹션에 있습니다 |

### 정적 함수 — `getInitials`

`Avatar.getInitials(name)` 은 이름에서 대문자 이니셜 문자열을 만듭니다. 앞뒤 공백을 지우고 공백으로 낱말을 나눕니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `name` | `String` | 필수 | 전체 이름 |

| 입력 | 결과 |
| --- | --- |
| 낱말 하나 — `John` | 앞 두 글자 `JO`. 한 글자 이름이면 그 한 글자 |
| 낱말 둘 이상 — `John Doe` | 앞의 두 낱말의 첫 글자 `JD` |
| 빈 문자열이나 공백 | 빈 문자열 |

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

<Note>

위 표의 설명과 지금 동작이 다른 곳은 다음과 같습니다.

- `diameter` · `initialsFontRatio` — 아바타 하나에만 적는 값이 아닙니다. `CoreAvatarTheme.style` 에 적어도 적용되며, 그때는 모든 크기의 아바타에 닿습니다.
- `badgeAlignment` — 두 플랫폼 모두 `CoreAvatarStyle.badgeAnchorFor` 로 자리를 계산합니다. 가로 자리는 왼쪽에서 재므로 오른쪽에서 왼쪽으로 쓰는 화면에서도 뒤집히지 않습니다.
- `fallbackTextStyle` — Flutter 에서 사진을 불러오지 못해 대신 그리는 이니셜에도 적용됩니다.
- `childIconStyle` — Flutter 는 `size` 만 전달하고 `color` 는 쓰지 않습니다. 색은 Web 에서만 적용됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="avatar/related-badge" title="Badge">

상태 낱말이나 개수를 보여 주는 라벨입니다. 아바타 옆에 상태를 글로 적을 때 씁니다.

[Badge 문서](/components/badge)

</Card>
<Card demo="avatar/related-icon" title="Icon">

아바타의 `child` 에 넣는 아이콘입니다.

[Icon 문서](/components/icon)

</Card>
<Card demo="avatar/related-hover-card" title="HoverCard">

마우스를 올리면 프로필 카드를 여는 컴포넌트입니다. `trigger` 에 아바타를 넣습니다.

[HoverCard 문서](/components/hover-card)

</Card>
</Cards>
