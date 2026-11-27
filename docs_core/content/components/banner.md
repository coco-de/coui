---
title: Banner
description: 점검 공지나 만료 안내처럼 페이지 전체에 해당하는 소식을 폭을 꽉 채운 띠로 보여 줍니다. 다섯 가지 종류에 두 가지 강조 세기를 조합합니다.
category: display
platforms: [flutter, web]
related: [toast, alert, status]
tags: [feedback, notification, alert]
template: v2
source: display/banner
---

# Banner

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 배너를 확인하고, 만들어진 코드를 복사하세요.

<Playground component="banner" />

`Banner`는 부모의 폭을 채우는 띠입니다. 화면에 스스로 고정되지 않고, 시간이 지나도 사라지지 않으며, 나타나고 사라지는 애니메이션이 없습니다. 언제 보이고 어디에 놓일지는 배너를 그리는 쪽이 정합니다.

## 구조

배너는 아이콘, 글(메시지와 그 아래 설명), 뒤쪽 묶음(행동과 닫기 버튼)을 놓습니다. 메시지만 필수이고 나머지는 선택입니다.

<Anatomy demo="banner/anatomy">
<AnatomyItem part="container" name="Container">

띠의 면입니다. 안쪽 여백은 위아래 12 · 좌우 16, 최소 높이는 72, 모서리는 각진 모양(0)입니다. `weak` 강조에는 아래쪽에 굵기 1의 선이 있습니다. 내용은 최소 높이 안에서 세로 가운데에 옵니다.

</AnatomyItem>
<AnatomyItem part="leading" name="icon">

`variant`가 정하는 아이콘(16)입니다. `showIcon: false`면 아이콘과 그 뒤 간격을 함께 뺍니다.

</AnatomyItem>
<AnatomyItem part="label" name="message">

알림의 첫 줄이며 필수입니다. 글자는 `labelLarge`(굵기 Medium)입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='description']" side="right" name="description">

메시지 아래의 보조 설명입니다. 글자는 `bodySmall`이고 메시지와의 간격은 4입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='action']" side="left" name="action">

행동을 놓는 자리입니다. 보통 `Button`을 넣습니다.

</AnatomyItem>
<AnatomyItem part="trailing" side="right" name="onDismiss">

넘기면 맨 끝에 닫기 버튼(✕)이 생깁니다.

</AnatomyItem>
</Anatomy>

아이콘과 글 사이는 12입니다. 글과 뒤쪽 묶음이 한 줄에 있을 때 둘 사이는 행동이 있으면 12, 닫기 버튼만 있으면 8입니다. 행동과 닫기 버튼 사이는 8입니다.

<a id="변형-variants"></a>
<a id="info"></a>
<a id="success"></a>
<a id="warning"></a>
<a id="destructive-error"></a>

## Variant

`variant`는 **무엇을 말하는 소식인지**를 고릅니다. 종류에 따라 아이콘 모양과 색이 바뀝니다. 아래는 기본 강조(`weak`)의 모습입니다.

<VariantRow name="neutral" component="banner" props="variant=neutral" label="점검 안내">

톤이 없는 공지입니다. 아이콘은 `bell`입니다. 기본값입니다.

</VariantRow>

<VariantRow name="info" component="banner" props="variant=info" label="새 기능">

알아 두면 좋은 정보에 씁니다. 아이콘은 `info`입니다.

</VariantRow>

<VariantRow name="success" component="banner" props="variant=success" label="저장 완료">

작업이 성공했다는 소식에 씁니다. 아이콘은 `circle-check`입니다.

</VariantRow>

<VariantRow name="warning" component="banner" props="variant=warning" label="곧 만료">

사용자의 주의가 필요한 상황에 씁니다. 아이콘은 `triangle-alert`입니다.

</VariantRow>

<VariantRow name="destructive" component="banner" props="variant=destructive" label="결제 실패">

오류나 실패에 씁니다. 아이콘은 `circle-x`입니다.

</VariantRow>

```dart
Banner.info(message: Text('새로운 업데이트가 있어요.'))

Banner.success(message: Text('변경 사항을 저장했어요.'))

Banner.warning(message: Text('구독이 7일 뒤에 끝나요.'))

Banner.destructive(message: Text('네트워크에 연결하지 못했어요.'))
```

<Note>

neutral을 뺀 네 종류에는 이름 있는 생성자 `Banner.info` · `Banner.success` · `Banner.warning` · `Banner.destructive`가 있습니다. neutral은 기본 생성자 `Banner(...)`입니다.

</Note>

### 의미 체인

배너의 `.info`, `.success`, `.warning`은 같은 이름의 `variant`를 선택합니다. 예를 들어 `Banner(message: const Text('저장 완료')).success`는 성공 배너의 테마를 따릅니다.

<a id="두-축-variant-와-emphasis"></a>

## 강조

배너는 축이 둘입니다. **`variant`는 무엇을 말하는지**, **`emphasis`는 얼마나 세게 말하는지**를 정합니다. 둘은 곱해집니다. `destructive`는 `weak`로도 `solid`로도 쓸 수 있습니다. `emphasis`는 이름 있는 생성자에도 넘길 수 있습니다.

<Preview demo="banner/emphasis" />

| emphasis | 채움 | 아래 선 | 설명 글자색 | 언제 |
| --- | --- | --- | --- | --- |
| `weak` (기본) | 종류의 옅은 컨테이너 색(불투명) | 있음. 모든 종류가 `outline` 색 | `onSurfaceVariant` | 대부분의 경우 |
| `solid` | 종류의 색 그대로(neutral은 `primary`) | 없음 | 메시지와 같은 색 | 사용자가 **놓치면 안 되는** 것: 장애, 강제 점검 |

| variant | `weak` 채움 | `weak` 메시지 · 아이콘 | `solid` 채움 | `solid` 글자 · 아이콘 |
| --- | --- | --- | --- | --- |
| `neutral` | `surfaceContainerLow` | `onSurface` | `primary` | `onPrimary` |
| `info` | `infoContainer` | `onInfoContainer` | `info` | `onInfo` |
| `success` | `successContainer` | `onSuccessContainer` | `success` | `onSuccess` |
| `warning` | `warningContainer` | `onWarningContainer` | `warning` | `onWarning` |
| `destructive` | `errorContainer` | `onErrorContainer` | `error` | `onError` |

`weak`에서는 설명 색이 종류와 관계없이 `onSurfaceVariant`로 한 단 내려가 메시지와 설명이 구분됩니다.

`solid`는 아껴 쓰세요. 일상적인 안내에 쓰면 신호가 닳아서, 정작 급한 일이 생겼을 때 쓸 강도가 남지 않습니다.

<Cards columns="2">
<Card demo="banner/do-solid-outage" tone="do" eyebrow="이렇게 하세요">

지금 서비스를 쓸 수 없는 것처럼 놓치면 안 되는 일에 `solid`를 씁니다.

</Card>
<Card demo="banner/dont-solid-routine" tone="dont" eyebrow="이렇게 하지 마세요">

일상적인 소식을 `solid`로 칠하지 않습니다. `weak`로 충분합니다.

</Card>
</Cards>

```dart
Banner(
  variant: CoreBannerVariant.destructive,
  emphasis: CoreBannerEmphasis.solid,
  message: Text('지금은 결제를 할 수 없어요.'),
  description: Text('복구하고 있어요. 따로 하실 일은 없어요.'),
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>

## 닫기와 행동

배너는 보이고 숨는 상태를 스스로 갖지 않습니다. 닫기와 행동은 넘긴 콜백과 위젯으로만 일어납니다.

<Preview component="banner" props="variant=warning;description=지금 연장하면 작업을 이어서 할 수 있어요.;action=연장하기;dismiss" label="세션이 곧 만료돼요" />

| 항목 | 동작 |
| --- | --- |
| 닫기 | `onDismiss`를 넘기면 끝에 닫기 버튼(✕)이 생깁니다. 누르면 콜백만 부릅니다. 배너를 화면에서 걷어내는 것은 부모가 상태로 처리합니다. |
| 닫기 버튼 모양 | 채움이 없는 `plain` `Button`입니다. 기본 설정에서 40 × 40 원 안에 ✕(18)가 있습니다. ✕ 색은 앞 아이콘 색을 따릅니다. hover에는 그 색을 3%, 누르는 동안에는 12% 덧칠합니다. 전환은 150ms이고, 움직임 줄이기 설정에서는 바로 바뀝니다. `bannerStyle`의 `closeButtonStyle`로 바꿉니다. |
| 행동 | `action`은 닫기 버튼 앞에 놓입니다. 어떤 위젯이든 넣을 수 있고, `Button`을 바로 넣으면 배너의 글자색에 맞춰 줍니다([행동 버튼](#행동-버튼)). |
| 없는 것 | 표시 시간, 저절로 사라지기, `Escape`로 닫기, 나타나고 사라지는 애니메이션, 비활성 상태 |

```dart
if (showBanner)
  Banner.warning(
    message: Text('세션이 곧 만료돼요.'),
    description: Text('지금 연장하면 작업을 이어서 할 수 있어요.'),
    action: Button(
      variant: CoreButtonVariant.plain,
      size: CoreComponentSize.sm,
      onPressed: extendSession,
      child: Text('연장하기'),
    ),
    onDismiss: () => setState(() => showBanner = false),
  )
```

### 행동 버튼

`action`에 `Button`을 **바로** 넣으면 배너가 그 버튼에 다음을 더합니다.

- 글자와 아이콘 색을 메시지 색으로 바꿉니다(`foregroundColor`를 줬다면 그 색). hover에도 같습니다.
- hover에 글자색을 옅게, 누르는 동안에는 더 진하게 덧칠합니다.
- `solid` 강조에서는 키보드 포커스 링과 버튼 사이 간격을 `surface` 색 띠로 채웁니다.
- `plain` 버튼에만 좌우 안쪽 여백 8을 줍니다. 다른 종류는 자기 크기의 여백을 그대로 씁니다.

값은 `배너의 기본값 → bannerStyle.actionButtonStyle → (plain이면) bannerStyle.plainActionButtonStyle → 버튼 자신의 buttonStyle` 순서로 겹치고, 뒤의 것이 이깁니다. `plain`의 좌우 여백 8보다 `actionButtonStyle`에 준 여백이 우선합니다. 이 값들은 앱의 버튼 테마보다도 우선합니다. `Button`을 다른 위젯으로 감싸 넣거나 다른 위젯을 넣으면 아무것도 더하지 않고 그대로 그립니다. 다만 Web에서는 글자색을 따로 정하지 않은 글자와 아이콘이 CSS 상속으로 배너의 글자색을 받습니다. Flutter에서는 배너 바깥에서 쓰던 글자색과 아이콘 색을 그대로 씁니다.

배너는 hover 글자색(`hoverForegroundColor`)도 함께 정해 둡니다. `foregroundColor`만 바꾸면 hover에서 배너의 색이 다시 보일 수 있으므로, 행동 버튼이나 닫기 버튼의 글자색을 직접 정할 때는 `hoverForegroundColor`도 함께 줍니다.

배너는 버튼의 **채움은 바꾸지 않습니다.** 그래서 버튼 종류에 따라 글자가 채움에 묻힐 수 있습니다. 아래 표는 CoUI 기본 색의 라이트 · 다크 모드 기준입니다.

| `action`의 버튼 종류 | `weak` | `solid` |
| --- | --- | --- |
| `plain` · `ghost` | 채움이 없어 메시지와 같은 색 조합입니다. | 왼쪽과 같습니다. |
| `outline` | 버튼의 `surface` 채움 위에 메시지 색 글자가 놓입니다. | **쓰지 마세요.** 글자색이 버튼 채움과 같거나 거의 같아 읽을 수 없습니다. |
| `secondary` · `tonal` · `destructive` | 자기 채움 위에 메시지 색 글자가 놓이므로 색 조합을 직접 확인하세요. | **쓰지 마세요.** 글자와 채움의 대비가 낮아 읽기 어렵습니다. |
| `primary` (종류를 주지 않은 `Button`) | **쓰지 마세요.** 글자와 채움의 대비가 낮고, neutral에서는 글자가 거의 보이지 않습니다. | 글자색이 버튼 채움과 대비됩니다. 다만 neutral은 버튼 채움이 배너와 같아 버튼 경계가 보이지 않습니다. |

<Cards columns="2">
<Card demo="banner/action-plain" tone="do" eyebrow="이렇게 하세요">

`solid` 배너의 행동은 채움이 없는 `plain`이나 `ghost`로 둡니다.

</Card>
<Card demo="banner/action-outline-on-solid" tone="dont" eyebrow="이렇게 하지 마세요">

`solid` 배너에 `outline` 버튼을 넣으면 글자가 버튼 채움에 묻힙니다.

</Card>
</Cards>

<a id="레이아웃-좁은-폭에서-버튼이-다음-줄로"></a>

## 레이아웃

메시지 묶음(메시지와 설명)과 뒤쪽 묶음(행동과 닫기 버튼)은 한 줄에 놓입니다. 메시지 묶음이 `contentMinWidth`(기본 240) 이상을 지킬 수 있는 동안에는 뒤쪽 묶음이 옆에 있고, 지킬 수 없으면 뒤쪽 묶음이 메시지 아래 줄로 내려갑니다. 아래는 폭 320의 모습입니다.

<Preview demo="banner/narrow" />

- 내려간 줄은 아이콘 아래가 아니라 **메시지 글자가 시작하는 위치**에서 시작합니다.
- 메시지 묶음과 내려간 줄 사이는 `trailingRunSpacing`(기본 8)입니다.
- 아이콘은 메시지 묶음의 세로 가운데에 맞춥니다. 버튼 줄이 내려가도 두 줄 전체가 아니라 메시지 쪽에 남습니다.
- 한 줄일 때는 메시지 묶음과 뒤쪽 묶음이 세로 가운데에 맞춰집니다.
- 줄을 바꿀지는 화면 폭의 기준값이 아니라 메시지 최소 폭 + 간격 + 뒤쪽 묶음 폭이 아이콘을 뺀 자리에 들어가는지로 정합니다. 같은 폭이라도 행동이 없으면 한 줄로 남을 수 있습니다.
- 뒤쪽 묶음이 내려가면 메시지 묶음은 남은 폭 전체를 씁니다. 그 폭이 240보다 좁아도 그대로 씁니다.
- 오른쪽에서 왼쪽으로 읽는 언어에서는 좌우가 뒤집힙니다.

**Figma.** Figma의 Banner는 한 줄(넓은 폭) 모습이 기준입니다. 인스턴스를 좁게 줄이면 버튼 줄은 코드처럼 메시지 글자가 시작하는 위치로 내려갑니다. 아이콘 자리는 코드와 다릅니다. Figma에서는 배너 전체(메시지와 버튼 줄)의 세로 가운데에 놓이고, 코드에서는 메시지 묶음의 가운데에 놓입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

페이지 전체에 해당하는 소식을 화면에 남겨 둘 때 씁니다.

- 점검 공지, 서비스 장애처럼 시스템 전체의 상태를 알릴 때
- 세션 만료, 구독 만료처럼 사용자가 해야 할 일을 안내할 때
- 방금 끝낸 작업의 결과를 페이지 위에 계속 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 입력한 값의 검증 결과를 알릴 때 | 그 필드 옆의 안내. [FormField](/components/form-field), [ValidatorHint](/components/validator-hint), [Validated](/components/validated) |
| 특정 내용 옆에 메시지와 복구 방법을 붙일 때 | [Alert](/components/alert) |
| 페이지 흐름에 자리를 차지하지 않고 잠깐 알릴 때 | [Toast](/components/toast) |
| 진행하기 전에 사용자의 응답을 받아야 할 때 | [Dialog](/components/dialog) |

<a id="do"></a>
<a id="dont"></a>

### 종류와 문구

<Cards columns="2">
<Card demo="banner/do-match-tone" tone="do" eyebrow="이렇게 하세요">

소식의 무게에 맞는 종류를 고르고, 바로 할 일이 있으면 `action`을 함께 둡니다.

</Card>
<Card demo="banner/dont-wrong-tone" tone="dont" eyebrow="이렇게 하지 마세요">

단순한 안내에 destructive를 쓰지 않습니다. 남용하면 진짜 오류를 놓치게 됩니다.

</Card>
<Card demo="banner/do-severity-text" tone="do" eyebrow="이렇게 하세요">

심각도는 메시지 글에도 적습니다. 색과 아이콘은 접근성 이름에 담기지 않습니다.

</Card>
<Card demo="banner/dont-color-only" tone="dont" eyebrow="이렇게 하지 마세요">

색과 아이콘만으로 오류를 전하지 않습니다.

</Card>
<Card demo="banner/do-dismissible" tone="do" eyebrow="이렇게 하세요">

읽고 나면 치워도 되는 안내에는 `onDismiss`를 넘겨 사용자가 닫을 수 있게 합니다.

</Card>
<Card demo="banner/dont-undismissible" tone="dont" eyebrow="이렇게 하지 마세요">

치워도 되는 안내를 닫을 수 없게 남겨 두면 콘텐츠 자리를 계속 차지합니다.

</Card>
<Card demo="banner/do-one" tone="do" eyebrow="이렇게 하세요">

가장 중요한 소식 하나만 보여 줍니다.

</Card>
<Card demo="banner/dont-stack" tone="dont" eyebrow="이렇게 하지 마세요">

여러 배너를 한꺼번에 쌓으면 무엇이 급한지 알기 어렵고 콘텐츠 자리를 지나치게 차지합니다.

</Card>
</Cards>

## 배치

배너는 보통 페이지 맨 위, 콘텐츠보다 앞에 폭을 다 써서 놓습니다.

<Preview demo="banner/placement-page" height="240" />

배너는 스스로 화면에 고정되지 않습니다. 스크롤해도 남게 하려면 감싸는 쪽에서 정합니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  children: [
    if (showNotice)
      Banner.info(
        message: Text('새벽 2시에 점검이 있어요.'),
        onDismiss: () => setState(() => showNotice = false),
      ),
    Expanded(child: pageContent),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  styles: Styles(raw: {'position': 'sticky', 'top': '0'}),
  [
    if (showNotice)
      Banner.info(
        message: Text('새벽 2시에 점검이 있어요.'),
        onDismiss: () => setState(() => showNotice = false),
      ),
  ],
)
```

  </TabItem>
</Tabs>

Flutter의 `Banner`는 폭이 정해진 부모 안에 두어야 합니다. `Row`의 자식으로 바로 넣거나 가로 스크롤 안에 두는 것처럼 폭의 한계가 없는 자리에서는 레이아웃 오류가 납니다. `Row` 안에서는 `Expanded`로 감싸세요.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

종류와 내용, 동작(`variant` · `emphasis` · `message` · `description` · `action` · `onDismiss` · `showIcon`)은 위젯 속성으로 넘기고, 겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일은 `bannerStyle`(`CoreBannerStyle`) 하나로 바꿉니다. 테마로는 `variant` · `emphasis` · `showIcon`을 바꿀 수 없습니다.

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>
<a id="테마-오버라이드"></a>

<Split>

<Code language="dart" title="배너 하나만 바꾸기">
Banner.warning(
  message: Text('세션이 곧 만료돼요.'),
  description: Text('지금 연장하면 작업을 이어서 할 수 있어요.'),
  bannerStyle: CoreBannerStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space24,
      vertical: CoreSpace.space16,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    titleStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
    iconStyle: CoreIconStyle(size: CoreIconSize.size20),
  ),
  onDismiss: handleDismiss,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    banner: CoreBannerTheme(
      style: CoreBannerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
      variantStyles: {
        CoreBannerVariant.destructive: CoreBannerStyle(
          borderColor: CoreColor.token(CoreColors.error),
          borderWidth: CoreStrokeWidth.stroke2,
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 두 플랫폼의 코드가 같습니다. 이미 만든 테마에 더할 때 쓰는 `ThemeData.copyWith`의 `coreComponentTheme`은 Flutter에서는 값을 돌려주는 함수, Web에서는 값 자체를 받습니다.

기본 아래 선은 `weak` 강조에만 있습니다. `weak`의 선을 없애려면 `borderWidth: 0`을 줍니다. `borderColor`를 주면 `solid` 강조에도 선이 생깁니다. 유리 같은 [서페이스 스타일](/guides/surface-styles)을 쓰면 배너의 면도 그 재질을 따릅니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

<Preview demo="banner/theme-order" />

```text
종류 × 강조별 색, 크기 · 간격의 기본값        // 디자인 시스템
  → CoreBannerTheme.style                    // 앱 전체
  → CoreBannerTheme.variantStyles[variant]   // 앱 전체, 종류별
  → bannerStyle                              // 배너 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지므로 앞에서 정한 다른 필드는 그대로 남고, 글자 · 간격 · 버튼처럼 안쪽 부품의 스타일은 그 안의 필드끼리 합쳐집니다. 테마에는 `emphasis`별 자리가 없습니다. `style`이나 `variantStyles`에 적은 값은 `weak`와 `solid`에 똑같이 적용됩니다. 한 강조만 바꾸려면 그 배너에 `bannerStyle`을 넘깁니다.

안쪽 부품의 스타일 중 `iconStyle`은 Icon에, `actionButtonStyle` · `plainActionButtonStyle` · `closeButtonStyle`은 Button에 넘어가 그 컴포넌트의 기본값과 테마 위에 한 번 더 얹힙니다. `titleStyle`은 `labelLarge` 위에, `descriptionStyle`은 `bodySmall` 위에 합쳐집니다. `message` · `description`에 넘기는 `Text`에 글자 스타일을 직접 정하면, 정한 값이 배너가 내려 주는 값보다 우선합니다.

색은 이 순서로 정해집니다(두 플랫폼 같음). 앞의 것이 이깁니다.

| 자리 | 순서 |
| --- | --- |
| 메시지 | `titleStyle`의 색 → `foregroundColor` → 종류 × 강조의 글자색 |
| 설명 | `descriptionStyle`의 색 → `foregroundColor` → 종류 × 강조의 설명 색 |
| 앞 아이콘 | `iconStyle`의 색 → 종류 × 강조의 아이콘 색 |
| 닫기 ✕ | `closeButtonStyle`의 색 → `iconStyle`의 색 → 종류 × 강조의 아이콘 색 |
| 행동 `Button`의 글자 | 버튼의 `buttonStyle` → (`plain`이면) `plainActionButtonStyle` → `actionButtonStyle` → `foregroundColor` → 종류 × 강조의 글자색 |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Banner`에 `.withStyle(CoreBannerStyle(...))`를 이어 붙이면 그 값이 `bannerStyle` 위에 합쳐지고, 뒤에 붙인 것이 이깁니다. `.radius16`처럼 토큰 이름과 같은 짧은 getter도 있어 이름이 곧 값입니다(`.radius16`은 `CoreRadius.radius16`). 모서리 getter는 `borderRadius`를, 색 getter는 `backgroundColor`를 바꿉니다.

<Note>

`.backgroundColor(...)`는 배경만 바꿉니다. 글자와 아이콘은 기존 variant의 색을 따릅니다. 아래 예제의 첫 배너처럼 `weak` 배너에 `.backgroundColor(.primary)`를 붙이면 `info`의 글자색이 `primary` 배경에 놓입니다. CoUI 기본 색의 라이트 · 다크 모드 모두 대비가 낮아 읽기 어렵습니다. 둘째 배너의 `foregroundColor`는 글자만 바꾸고 아이콘과 닫기 ✕ 색은 바꾸지 않습니다. 종류와 세기는 `variant`와 `emphasis`로 고르세요.

</Note>

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class BannerChainExample extends StatefulWidget {
  const BannerChainExample({super.key});

  @override
  State<BannerChainExample> createState() => _BannerChainExampleState();
}

class _BannerChainExampleState extends State<BannerChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('배너 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreBannerStyle(
              backgroundColor: .tertiaryContainer,
              foregroundColor: .onTertiaryContainer,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          )
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showFull = true),
            child: const Text('배너 보기'),
          ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class BannerChainExample extends StatefulComponent {
  const BannerChainExample({super.key});

  @override
  State<BannerChainExample> createState() => _BannerChainExampleState();
}

class _BannerChainExampleState extends State<BannerChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('배너 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreBannerStyle(
              backgroundColor: .tertiaryContainer,
              foregroundColor: .onTertiaryContainer,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          )
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showFull = true),
            child: const Text('배너 보기'),
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

배너 자체는 포커스를 받지 않고, 새로 나타나도 스크린 리더에 알리는 영역(live region)으로 표시하지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 루트에 `Semantics(container: true, label:)`를 둡니다. 닫기 버튼은 `Semantics(label:)`로 감싼 `Button`입니다. |
| Jaspr Web | 루트 `<div>`에 `role="banner"`와 `aria-label`을 붙입니다. 닫기 버튼은 네이티브 `<button type="button">`이고 `aria-label`을 갖습니다. |

ARIA의 `banner`는 페이지의 머리 영역을 가리키는 랜드마크 역할입니다.

#### 장식 아이콘

앞 아이콘에는 이름을 붙이지 않습니다. Web은 아이콘을 감싼 `<span>`에 `aria-hidden="true"`를 둡니다.

### 키보드

아래 표는 `action`에 `Button`을 넣은 경우입니다. 다른 위젯의 키보드 동작은 그 위젯을 따릅니다.

| 키 | 동작 |
| --- | --- |
| `Tab` | `action` 버튼 → 닫기 버튼 순서로 포커스를 옮깁니다. 배너 자체는 건너뜁니다. |
| `Shift` · `Tab` | 반대 순서로 옮깁니다. |
| `Enter` · `Space` | 포커스된 버튼을 실행합니다. |
| `Escape` | 배너를 닫지 않습니다. 두 플랫폼 모두 처리하지 않습니다. |

버튼 실행은 Flutter에서는 버튼의 `Enter` · `Space` 단축키가, Web에서는 네이티브 `<button>`의 기본 동작이 맡습니다.

### 스크린 리더

- 배너에 붙이는 이름은 현지화된 고정 문자열입니다(영어 "Banner", 한국어 "배너"). `message`의 내용으로 바뀌지 않습니다.
- 본문은 `message` · `description`에 넘긴 위젯의 글자입니다. Flutter는 `explicitChildNodes`를 켜지 않으므로, 스스로 경계를 만들지 않는 안쪽 글자는 배너 노드의 내용으로 합쳐질 수 있습니다.
- 닫기 버튼의 이름도 현지화됩니다(영어 "Dismiss", 한국어 "닫기").
- **배너는 live region이 아닙니다.** Flutter는 `liveRegion`을 설정하지 않고, Web은 `aria-live`를 붙이지 않습니다. 화면이 열린 뒤에 생긴 변화를 바로 알려야 한다면 [Alert](/components/alert)(neutral 제외)나 [Toast](/components/toast)처럼 알리는 영역으로 표시하는 컴포넌트를 쓰세요.

### 포커스 관리

| 항목 | 동작 |
| --- | --- |
| 진입 | 없음. 오버레이가 아니라 페이지 안의 띠이므로 포커스를 옮기지 않고, 자동 포커스도 없습니다. |
| 이탈 | 없음. `onDismiss`는 콜백만 부르며 배너는 포커스를 옮기지 않습니다. 닫기 버튼에 포커스가 있는 채로 배너를 걷어낼 때는, 포커스를 어디에 둘지 배너를 그리는 쪽에서 정하세요. |
| 가두기 | 없음. |
| 포커스 표시 | 버튼의 포커스 링을 씁니다. `solid` 강조에서는 닫기 버튼과 행동 `Button`의 링과 버튼 사이 간격(2)을 `surface` 색 띠로 칠하고, `weak`에서는 비워 둡니다. 버튼 스타일에 직접 준 값이 우선합니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | **종류가 접근성 정보에 담기지 않습니다.** 종류를 가르는 것은 색과 아이콘인데, 아이콘에는 이름이 없고 배너의 이름도 종류와 상관없이 같습니다. 심각도는 `message` 글에 직접 적으세요(예: `Text('오류: 세션이 만료됐어요')`). |
| 공통 | **배너의 이름을 바꾸는 속성이 없습니다.** 한 화면에 배너가 여러 개면 이름이 모두 같습니다. 이름은 현지화 문자열을 따릅니다. |
| 공통 | 행동 버튼의 채움은 배너에 맞춰 바뀌지 않아, 버튼 종류에 따라 글자가 읽히지 않습니다([행동 버튼](#행동-버튼)). |
| Jaspr Web | `role="banner"`는 페이지 머리 영역의 랜드마크 역할인데 배너마다 붙고, 바꿀 수 없습니다. 페이지에 머리 영역이나 다른 배너가 있으면 `banner` 랜드마크가 여럿이 됩니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

내용 · 종류 · 닫기와 행동의 API는 두 플랫폼이 같습니다. 두 쪽 모두 배너를 화면에 고정하지 않습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `message` · `description` · `action` 타입 | `Widget` | `Component` |
| `onDismiss` 타입 | `VoidCallback?` | `CoreVoidCallback?` |
| 식별 · HTML 속성 | `key` | `key`와 `id`를 받습니다. `classes` · `css` · `attributes`는 생성자에 없고, `copyWith`에 넘겨도 반영되지 않습니다. |
| 부모 폭 | 폭의 한계가 있는 부모가 필요합니다. | 루트가 `w-full`이라 부모의 폭을 채웁니다. |
| 버튼 줄 내리기 | 아이콘 · 글 · 뒤쪽 묶음의 크기를 재는 전용 레이아웃 | `flex-wrap`. 메시지 묶음은 최소 폭을 기준으로 늘어나고, 뒤쪽 묶음은 늘거나 줄지 않습니다. |
| 아이콘 세로 위치 | 같은 레이아웃이 메시지 묶음의 가운데에 놓습니다. | 아이콘 폭만큼 자리를 비워 두고, 아이콘은 메시지 묶음을 기준으로 절대 위치(`absolute`)에 놓아 그 높이의 가운데에 맞춥니다. |
| 의미 | `Semantics(container: true, label:)` | `role="banner"` + `aria-label` |
| 비활성 행동 `Button`(`onPressed: null`)의 글자색 | 배너가 정한 글자색이 그대로 남아, 글자만으로는 비활성인지 알기 어렵습니다. | 기본 설정에서는 비활성 글자색으로 바뀝니다. |
| `Button`이 아닌 `action`의 색 | 글자색을 따로 정하지 않으면 배너 바깥의 색을 씁니다. | 글자색을 따로 정하지 않으면 배너의 글자색을 물려받습니다. |
| 테마 덮기(`ThemeData.copyWith`) | `coreComponentTheme: () => …` 값을 돌려주는 함수 | `coreComponentTheme: …` 값 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 웹에서는 `Widget` 자리가 `Component`, `VoidCallback` 자리가 `CoreVoidCallback`입니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `message` | `Widget` | 필수 | 배너에 보여 줄 메시지 |
| `description` | `Widget?` | `null` | 메시지 아래의 보조 설명 |
| `action` | `Widget?` | `null` | 닫기 버튼 앞에 놓는 행동. 대개 `Button` |

### 종류와 표시

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreBannerVariant` | `neutral` | 무엇을 말하는가: `neutral`, `info`, `success`, `warning`, `destructive` |
| `emphasis` | `CoreBannerEmphasis` | `weak` | 얼마나 세게 말하는가: `weak`, `solid` |
| `showIcon` | `bool` | `true` | false면 앞 아이콘과 그 뒤 간격을 함께 뺍니다. |
| `bannerStyle` | `CoreBannerStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onDismiss` | `VoidCallback?` | `null` | 지정하면 닫기 버튼이 생기고, 누르면 불립니다. |

### 이름 있는 생성자

| 생성자 | 고정되는 값 |
| --- | --- |
| `Banner.info(...)` | `variant: CoreBannerVariant.info` |
| `Banner.success(...)` | `variant: CoreBannerVariant.success` |
| `Banner.warning(...)` | `variant: CoreBannerVariant.warning` |
| `Banner.destructive(...)` | `variant: CoreBannerVariant.destructive` |

`variant`를 뺀 나머지 속성은 기본 생성자와 같습니다. 두 플랫폼의 `copyWith`는 `null`로 넘긴 값을 기존 값으로 두므로, 이미 넣은 `description` · `action` · `onDismiss`를 `copyWith`로 지울 수는 없습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreBannerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Banner panel background fill colour. |
| `foregroundColor` | `CoreColor?` | Foreground colour applied to the title / description / icon when the per-slot style does not override it. |
| `borderColor` | `CoreColor?` | Bottom-rule colour. `null` suppresses the rule entirely. |
| `borderWidth` | `double?` | Bottom-rule thickness (logical px). `null` defers to [defaultBorderWidth]. See that constant for why the rule is bottom-only and why it must not add to the band's height. |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` defers to [defaultBorderRadius]. |
| `minHeight` | `double?` | Minimum band height (logical px). `null` defers to [defaultMinHeight]. |
| `padding` | `CoreEdgeInsets?` | Padding. `null` defers to [defaultPadding]. |
| `iconContentGapStyle` | `CoreGapStyle?` | Gap after the leading icon, and between the text column and an action that shares its line. `null` defers to [defaultIconContentGapStyle]. |
| `contentDismissGapStyle` | `CoreGapStyle?` | Gap before the dismiss button — after the action, or after the text column when there is no action. `null` defers to [defaultContentDismissGapStyle]. |
| `titleDescriptionGapStyle` | `CoreGapStyle?` | Vertical gap between the title and the description, passed to the `Gap` between them. `null` defers to [defaultTitleDescriptionGapStyle]. |
| `contentMinWidth` | `double?` | Narrowest the message column may get while the trailing group sits beside it (logical px). Below it the trailing group moves to its own line under the message. `null` defers to [defaultContentMinWidth]. |
| `trailingRunSpacing` | `double?` | Vertical distance between the message column and the trailing group once the trailing group has moved to its own line (logical px). `null` defers to [defaultTrailingRunSpacing]. |
| `titleStyle` | `CoreTextStyle?` | Title text style override. |
| `descriptionStyle` | `CoreTextStyle?` | Description text style override. |
| `iconStyle` | `CoreIconStyle?` | Leading icon style override. |
| `actionButtonStyle` | `CoreButtonStyle?` | Look of the action (`action:`) button — colours, padding, corners. Laid over the banner variant's foreground colour, so fields set here win, and passed to the action as is when it is a `Button`. |
| `plainActionButtonStyle` | `CoreButtonStyle?` | Extra styling for an action that is a `plain` `Button` — laid over [actionButtonStyle] (and its default) for that variant only, and merged onto [defaultPlainActionButtonStyle]. A caller's [actionButtonStyle] still wins over the default here, so a padding stated there reaches every variant. |
| `closeButtonStyle` | `CoreButtonStyle?` | Look of the close (`onDismiss`) button — colours, padding, corners. Laid over [defaultCloseButtonStyle] and the banner variant's foreground colour, then passed as is to `Button(variant:.plain, buttonStyle: …)` on both platforms. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명과 지금 동작이 다른 부분이 있습니다(두 플랫폼 같음).

- `foregroundColor`는 메시지 · 설명 · 행동 `Button`의 글자에 적용되고, **아이콘과 닫기 ✕의 색은 바꾸지 않습니다.** 두 색은 `iconStyle`의 `color`로 바꿉니다. ✕만 따로 바꾸려면 `closeButtonStyle`을 씁니다.
- `borderColor`를 `null`로 두면 선이 없어지는 것이 아니라 종류 × 강조의 기본값을 씁니다. `weak`에는 `outline` 색 선이 있고 `solid`에는 없습니다. 선을 없애려면 `borderWidth: 0`을 줍니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="banner/related-toast" title="Toast">

잠깐 보였다가 사라지는 알림입니다. 띄우고 시간이 지나면 닫는 함수(`showToast`)는 Flutter에 있습니다.

</Card>
<Card demo="banner/related-alert" title="Alert">

페이지 안의 특정 내용 옆에 두는 알림 상자입니다.

</Card>
<Card demo="banner/related-status" title="Status">

시스템이나 사용자의 상태를 점으로 보여 줍니다.

</Card>
</Cards>
