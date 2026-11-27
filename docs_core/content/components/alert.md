---
title: Alert
description: 결제 확인이나 저장 실패처럼 화면 안에서 알려야 할 소식을 정보 · 성공 · 경고 · 오류 톤으로 보여 주는 알림 상자입니다. 제목과 설명을 쌓은 패널과 한 줄 상태 띠, 두 레이아웃이 있습니다.
category: overlay
platforms: [flutter, web]
related: [banner, toast, dialog]
tags: [alert, feedback, status, notification]
template: v2
source: overlay/alert
---

# Alert

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 알림을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="alert" />

## 구조

알림은 패널 하나 안에 앞자리 · 글(제목과 그 아래 설명) · 행동 · 닫기 버튼을 한 줄로 놓습니다. 제목만 필수이고 나머지는 선택입니다.

<Anatomy demo="alert/anatomy">
<AnatomyItem part="container" name="Container">

채움, 모서리, 안쪽 여백, 최소 높이. 채움 색은 variant가 정합니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

톤 아이콘 자리. 비워 두면 variant의 아이콘을 그리고, 위젯을 넘기면 그 위젯이 아이콘을 대신합니다.

</AnatomyItem>
<AnatomyItem part="label" name="title">

알림 제목. 필수이며 접근 가능한 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select=".min-w-0 > div + div > span" side="right" name="description">

제목 아래 보조 설명. 선택 사항이고, 한 줄 상태 띠에서는 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="div[class='shrink-0']" name="action">

닫기 버튼 앞에 놓는 행동. 대개 Button을 넣습니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="onDismiss">

넘기면 끝에 닫기 버튼이 생깁니다.

</AnatomyItem>
</Anatomy>

<a id="앞자리-슬롯-leading"></a>

### 앞자리 슬롯

`leading`은 톤 아이콘을 대신합니다. 둘을 함께 그리지 않고, `null`이면 variant의 톤 아이콘을 그립니다. 두 레이아웃 모두에서 쓸 수 있습니다.

<Preview demo="alert/leading-badge" />

```dart
Alert.warning(
  leading: Badge(tone: CoreBadgeTone.warning, child: Text('베타')),
  title: '미리 보기 기능',
  description: '출시 전까지 동작이 바뀔 수 있습니다.',
)
```

이 자리에는 톤 아이콘의 색과 그 레이아웃의 아이콘 크기가 아이콘 테마로 내려갑니다. 그래서 아이콘 하나를 그대로 넘기면 원래 아이콘과 같은 색 · 크기가 되고, Badge처럼 자기 색을 가진 위젯은 그 색을 그대로 씁니다. 색과 크기가 닿는 곳은 아이콘까지입니다. 아이콘이 아닌 내용(글자만 있는 Text 등)은 색을 받지 않고 줄 높이도 바뀌지 않아, 두 플랫폼 모두 옆의 본문과 같은 색 · 줄 높이를 따릅니다.

<a id="텍스트만-아이콘-없음"></a>

`showIcon: false`는 이 자리를 통째로 끕니다. 톤 아이콘이든 넘긴 `leading`이든 그리지 않고 그 뒤 간격도 함께 빠져, 글자가 패널 안쪽 여백에서 시작합니다. 톤이 있는 variant는 제목이 이미 톤의 색이라, 아이콘 없이도 채움과 제목 색이 톤을 전합니다.

<Preview component="alert" example="text-only" />

<a id="변형-variants"></a>

## Variant

소식이 무엇에 관한 것인지에 따라 다섯 가지 중 하나를 고릅니다. variant는 채움 · 아이콘 · 제목 색과 함께 스크린 리더에 알리는 방식도 정합니다.

<VariantRow name="neutral" component="alert" props="variant=neutral" label="참고해 주세요">

톤이 없는 안내입니다. 화면을 설명하는 메시지를 담을 뿐이라 스크린 리더에 알리지 않습니다. 기본값입니다. 채움이 `surfaceContainer`라 같은 색 면 위에서는 상자 경계가 보이지 않습니다(배치 참고).

</VariantRow>

<VariantRow name="info" component="alert" props="variant=info" label="새 기능이 있어요">

알아 두면 좋은 정보에 씁니다.

</VariantRow>

<VariantRow name="success" component="alert" props="variant=success" label="저장했어요">

요청이 성공했다는 확인에 씁니다.

</VariantRow>

<VariantRow name="warning" component="alert" props="variant=warning" label="확인이 필요해요">

되돌리기 어렵거나 주의가 필요한 일에 씁니다.

</VariantRow>

<VariantRow name="destructive" component="alert" props="variant=destructive" label="연결이 끊겼어요">

실패와 오류에 씁니다. 웹에서는 스크린 리더가 읽던 문장을 끊고 바로 알립니다.

</VariantRow>

<Note>

neutral을 뺀 네 톤에는 이름 있는 생성자가 있습니다: `Alert.info` · `Alert.success` · `Alert.warning` · `Alert.destructive`. neutral은 기본 생성자 `Alert(...)`입니다.

</Note>

채움은 톤의 불투명한 컨테이너 색(`infoContainer` 등)이고, 아이콘과 제목은 그 위의 `on{Tone}Container`입니다. 그래서 아이콘을 끈 알림도 제목만으로 톤이 읽힙니다. neutral은 제목 색이 따로 없어 레이아웃의 색(stacked는 `onSurface`, inline은 `onSurfaceVariant`)을 쓰고, 설명은 모든 톤에서 `onSurfaceVariant`입니다. 글자 대비는 페이지가 아니라 패널 자기 색에 대해 정해지며, 톤 제목은 약 8:1로 본문 기준(4.5:1)을 넉넉히 넘습니다.

### 의미 체인

알림의 `.info`, `.success`, `.warning`은 같은 이름의 `variant`를 선택합니다. 예를 들어 `Alert(title: '저장 완료').success`는 성공 알림의 테마를 따릅니다.

<a id="레이아웃-layout"></a>
<a id="inline-한-줄-상태-띠"></a>

## 레이아웃

`layout`은 내용을 얼마나 보여 주고 자리를 얼마나 차지할지 정합니다. 채움 · 모서리 · 아이콘 색은 두 레이아웃 모두 variant를 따릅니다.

<Cards columns="2">
<Card component="alert" props="variant=info;description=새 버전에서 고친 내용을 확인해 보세요." label="업데이트를 마쳤어요" title="stacked">

기본값. 제목 아래 설명을 쌓은 패널입니다.

</Card>
<Card demo="alert/inline" title="inline">

한 줄 상태 띠. 설명은 그리지 않습니다.

</Card>
</Cards>

| 항목 | `stacked` (기본) | `inline` |
| --- | --- | --- |
| 모양 | 제목 아래 설명이 쌓인 패널 | 한 줄 상태 띠 |
| 안쪽 여백 | 위아래 12 · 시작 16 · 끝 12 | 위아래 10 · 좌우 14 |
| 최소 높이 | 64 | 없음. 내용 높이입니다(md `Badge`를 앞에 두면 10 + 24 + 10 = 44). |
| 모서리 | 12 | 12 |
| 칸 사이 간격(앞자리와 글, 글과 행동 · 닫기 버튼) | 12 | 10 |
| 톤 아이콘 | 18 | 16 |
| 제목 | `labelLarge` · 600 · 톤 색(neutral은 `onSurface`) | `bodySmall` · 톤 색(neutral은 `onSurfaceVariant`). 한 줄이고 넘치면 말줄임 |
| 제목과 설명 사이 | 2 | – |
| 설명 | `bodySmall` · `onSurfaceVariant` | 그리지 않음 |

stacked는 최소 높이 안에서 내용이 세로 가운데에 옵니다. 안쪽 행도 가운데 정렬이라 아이콘 · 글 · 행동 · 닫기 버튼이 같은 가운데 선을 나눕니다. 두 줄짜리 알림은 한 덩어리로 읽히고, 제목만 있는 알림은 최소 높이가 열어 둔 상자의 가운데에 놓입니다. 시작과 끝 여백이 다르므로 읽는 방향 기준으로 적혀 있어, 오른쪽에서 왼쪽으로 읽는 언어에서도 같은 쪽에 붙습니다.

inline은 한 줄에 목소리가 하나라 제목이 본문 크기(`bodySmall`)입니다. 톤은 글자 색과 앞자리의 배지나 아이콘이 함께 전합니다. `description`을 넘겨도 그리지 않으며, 제목이 말줄임으로 잘려도 스크린 리더는 전체 제목을 읽습니다.

```dart
Alert(
  layout: CoreAlertLayout.inline,
  leading: Badge(
    tone: CoreBadgeTone.success,
    showDot: true,
    child: Text('동기화됨'),
  ),
  title: '모든 변경 사항을 클라우드에 저장했어요.',
  action: Icon(
    LucideIcons.chevronDown,
    iconStyle: CoreIconStyle(
      size: CoreIconSize.size16,
      color: CoreColor.token(CoreColors.onSurfaceSubtle),
    ),
  ),
)
```

`action` 자리의 아이콘은 알림을 그리는 쪽이 넘긴 내용이라 색을 직접 지정합니다(`onSurfaceSubtle`). 두 플랫폼 코드가 같습니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="토큰"></a>

## 닫기와 행동

알림은 스스로 사라지지 않습니다. 닫기와 행동은 넘긴 콜백과 위젯으로만 일어납니다.

<Preview component="alert" props="variant=success;description=변경 사항이 저장되었습니다.;action=보기;dismiss" label="저장 완료" />

| 항목 | 동작 |
| --- | --- |
| 닫기 | `onDismiss`를 넘기면 끝에 닫기 버튼(✕)이 생깁니다. 누르면 콜백만 부르고, 알림을 화면에서 걷어내는 것은 부모가 합니다. |
| 행동 | `action`은 닫기 버튼 앞에 놓입니다. 어떤 위젯이든 넣을 수 있고, `Button`이면 `alertStyle`의 `actionButtonStyle`이 그 버튼 아래에 깔립니다. 버튼 자신의 `buttonStyle`이 이깁니다. |
| 아이콘 | variant마다 정해져 있습니다. neutral · info는 `info`, success는 `circle-check`, warning은 `triangle-alert`, destructive는 `circle-alert`입니다. `leading`을 넘기면 그 위젯이 대신합니다. |
| 닫기 버튼 모양 | `plain` 버튼에 안쪽 여백 4, 모서리 4, ✕ 아이콘 16, 전환 150ms입니다. ✕ 색은 쉬는 상태와 hover 모두 `onSurfaceVariant`입니다. 색은 `alertStyle`의 `dismissColor`로, 나머지는 `closeButtonStyle`로 바꿉니다(`closeButtonStyle`의 색이 `dismissColor`를 이깁니다). |
| 없는 것 | 표시 시간, 저절로 사라지기, `Escape`로 닫기, 비활성 상태가 없습니다. |

확인만 하면 되는 알림(저장 완료 같은)에는 `onDismiss`를 넘겨, 읽은 뒤 사용자가 직접 닫게 하면 화면 자리를 아낄 수 있습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

화면은 계속 쓸 수 있고, 그중 한 가지를 알려야 할 때 씁니다. 저장 · 제출 결과, 놓치면 안 되는 경고, 화면에 머무는 안내가 그렇습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 보여 줄 내용이 없어 그 자리를 대신 채워야 할 때 | [EmptyState](/components/empty-state) |
| 사용자가 입력한 값이 거부됐을 때(형식 오류, 이미 쓰는 이메일 등) | 그 필드의 오류 표시. [FormField](/components/form-field), [ValidatorHint](/components/validator-hint), [Validated](/components/validated) |
| 잠깐 떴다가 사라지는 확인 | [Toast](/components/toast) |
| 특정 영역이 아니라 페이지 맨 위에 거는 공지 | [Banner](/components/banner) |
| 진행하기 전에 사용자의 확인을 받아야 할 때 | [Dialog](/components/dialog) |

### 톤과 문구

<Cards columns="2">
<Card demo="alert/do-match-tone" tone="do" eyebrow="이렇게 하세요">

소식의 무게에 맞는 variant를 고릅니다. 되돌릴 수 없는 일은 warning입니다.

</Card>
<Card demo="alert/dont-wrong-tone" tone="dont" eyebrow="이렇게 하지 마세요">

평범한 안내에 destructive를 쓰면 괜한 긴장을 주고, 진짜 오류가 묻힙니다.

</Card>
<Card demo="alert/do-recovery" tone="do" eyebrow="이렇게 하세요">

실패를 알릴 때는 다시 시도 같은 복구 경로를 `action`에 함께 둡니다.

</Card>
<Card demo="alert/dont-dead-end" tone="dont" eyebrow="이렇게 하지 마세요">

할 수 있는 일이 없는 실패 메시지는 막다른 길입니다. 복구할 방법이 정말 없다면 대신 할 수 있는 일을 설명에 적습니다.

</Card>
<Card demo="alert/do-summary-title" tone="do" eyebrow="이렇게 하세요">

핵심은 제목에, 보충은 설명에 나눠 적어 훑어보기 쉽게 합니다.

</Card>
<Card demo="alert/dont-long-description" tone="dont" eyebrow="이렇게 하지 마세요">

긴 설명에 핵심을 묻으면 제목만 읽는 사람은 무엇이 일어나는지 모릅니다.

</Card>
</Cards>

### Alert와 EmptyState

둘을 가르는 기준은 얼마나 나쁜가가 아니라 보여 줄 내용이 남아 있는가입니다. 목록은 그려졌고 한 동작만 실패했다면 남은 내용 옆에 Alert를 둡니다(배치 참고). 그 영역에 보여 줄 것이 없으면 EmptyState가 자리를 대신 채웁니다.

<Cards columns="2">
<Card demo="alert/do-empty-state" tone="do" eyebrow="이렇게 하세요">

목록을 불러오지 못해 비었으면 EmptyState가 그 자리를 채우고 복구 경로를 말합니다.

</Card>
<Card demo="alert/dont-alert-for-empty" tone="dont" eyebrow="이렇게 하지 마세요">

비어 있는 자리에 Alert만 두면 목록이 어디 갔는지 알 수 없습니다.

</Card>
</Cards>

<a id="조합-예제"></a>

## 배치

알림은 페이지 흐름 안, 관련된 내용 바로 위에 둡니다. 결과를 알리는 알림은 그 결과를 만든 영역 가까이에 둡니다.

<Cards columns="2">
<Card demo="alert/placement-form" height="340" title="폼 위">

제출 결과는 폼 맨 위에 둡니다. 닫기 버튼으로 읽은 뒤 치울 수 있게 합니다.

</Card>
<Card demo="alert/placement-list" height="340" title="목록 위의 한 줄 띠">

내용이 남아 있는 영역의 상태는 inline 띠로 짧게 알립니다.

</Card>
</Cards>

```dart
Column(
  children: [
    if (submitError != null)
      Alert.destructive(
        title: '결제하지 못했어요',
        description: submitError!,
        onDismiss: handleErrorDismissed,
      ),
    // ... 폼 입력창
  ],
)
```

<Note>

neutral의 채움은 `surfaceContainer`라 같은 색 면 위에서는 경계가 보이지 않습니다. filled 카드 안이 그렇고, 다크 모드에서는 Popup · Dialog의 면(`surfaceBright`)도 같은 색입니다. 그런 자리에는 톤이 있는 variant를 쓰거나 `alertStyle`로 채움이나 테두리를 바꿉니다.

</Note>

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

## 테마와 스타일

종류와 내용(`variant` · `layout` · `title` · `description` · `leading` · `action` · `onDismiss`)은 위젯 속성으로 넘기고, 색 · 크기 · 간격과 안쪽 부품의 스타일은 `alertStyle`(`CoreAlertStyle`) 하나로 덮어씁니다.

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>

<Split>

<Code language="dart" title="알림 하나만 바꾸기">
Alert.success(
  title: '저장 완료',
  description: '변경 사항이 성공적으로 저장되었습니다.',
  alertStyle: CoreAlertStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space24,
      vertical: CoreSpace.space16,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    titleStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    iconStyle: CoreIconStyle(size: CoreIconSize.size20),
  ),
  onDismiss: handleDismiss,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    alert: CoreAlertTheme(
      style: CoreAlertStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
      variantStyles: {
        CoreAlertVariant.warning: CoreAlertStyle(
          borderColor: CoreColor.token(CoreColors.warning),
          borderWidth: CoreStrokeWidth.stroke1,
        ),
      },
    ),
  ),
)
</Code>

</Split>

기본 테두리 굵기는 0입니다. 테두리가 필요하면 `borderColor`와 `borderWidth`를 함께 지정합니다. 기본 스타일에서는 색만 주면 아무것도 그려지지 않습니다. 모든 컨트롤을 테두리로 감싸는 [서페이스 스타일](/guides/surface-styles)(`CoreSurfaceStyleId.neoBrutalism`) 아래에서는 굵기를 적지 않은 알림이 그 스타일의 테두리(`outline` 색)를 받고, 적은 `borderColor`가 그 색을 대신합니다. 굵기를 적으면 스타일이 주는 테두리 대신 적은 테두리를 그립니다. 두 플랫폼 같습니다. 이미 만든 테마에 더할 때 쓰는 `ThemeData.copyWith`의 `coreComponentTheme`은 Flutter에서는 값을 돌려주는 함수, 웹에서는 값 자체를 받습니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

<Preview demo="alert/theme-order" />

뒤로 갈수록 우선합니다. 레이아웃별 기본값은 여백 · 최소 높이 · 간격 · 아이콘 크기 · 제목 글자와 neutral의 제목 색을, 종류별 기본값은 채움 · 아이콘 색 · 톤 제목 색 · 설명 색을 정합니다. 모서리(12) · 테두리(0) · 제목과 설명 사이(2) · 설명 글자(`bodySmall`) · 닫기 버튼의 기본값은 레이아웃과 종류에 상관없이 하나입니다. Alert를 품은 컴포넌트(RichEditor의 `uploadAlertStyle` 같은)는 자기 값을 `alertStyle`로 넘깁니다.

`layout`은 테마에 따로 자리가 없습니다. `CoreAlertTheme.style`과 `alertStyle`로 덮은 여백 · 간격 · 아이콘 크기 · 제목 스타일 · `minHeight`는 두 레이아웃에 똑같이 적용됩니다. 한 레이아웃만 바꾸려면 그 레이아웃의 Alert에만 `alertStyle`을 넘깁니다.

안쪽 부품의 스타일 중 `iconStyle`은 Icon에, `actionButtonStyle` · `closeButtonStyle`은 Button에 넘어가, 그 컴포넌트의 기본값과 테마 위에 한 번 더 얹힙니다. `titleStyle`은 레이아웃의 제목 글자 위에, `descriptionStyle`은 설명 글자(`bodySmall`) 위에 합쳐집니다.

글자 색은 이 순서로 정해집니다(두 플랫폼 같음).

| 자리 | 앞의 것이 이깁니다 |
| --- | --- |
| 제목 | `titleStyle`의 색 → `titleColor` → `foregroundColor` → 종류의 제목 색 → 레이아웃의 제목 색 |
| 설명 | `descriptionStyle`의 색 → `foregroundColor` → 종류의 설명 색 |
| 톤 아이콘 | `iconStyle`의 색 → 종류의 아이콘 색. `foregroundColor`는 아이콘 색을 바꾸지 않습니다. |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 Alert에 `.withStyle(CoreAlertStyle(...))`를 이어 붙이면 그 값이 `alertStyle` 위에 합쳐지고, 뒤에 붙인 것이 이깁니다. `.radius4`처럼 토큰 이름과 같은 짧은 getter도 있어 이름이 곧 값입니다(`.radius16`은 `CoreRadius.radius16`). 모서리 getter는 `borderRadius`를 바꿉니다.

<Note>

`.success` · `.warning` · `.info`는 해당 variant를 선택합니다. 오류 색으로 배경만 칠할 때는 `.backgroundColor(.error)`를 씁니다. 기존 `.error` getter도 같은 배경색을 지정합니다.

</Note>

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class AlertChainExample extends StatefulWidget {
  const AlertChainExample({super.key});

  @override
  State<AlertChainExample> createState() => _AlertChainExampleState();
}

class _AlertChainExampleState extends State<AlertChainExample> {
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
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('알림 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreAlertStyle(
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
            child: const Text('알림 보기'),
          ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class AlertChainExample extends StatefulComponent {
  const AlertChainExample({super.key});

  @override
  State<AlertChainExample> createState() => _AlertChainExampleState();
}

class _AlertChainExampleState extends State<AlertChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('알림 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreAlertStyle(
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
            child: const Text('알림 보기'),
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

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreAlertStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Alert panel background fill colour. |
| `foregroundColor` | `CoreColor?` | Foreground colour applied to title / description / icon when the per-slot style does not override it. |
| `borderColor` | `CoreColor?` | Border stroke colour. |
| `titleColor` | `CoreColor?` | Title colour. `null` → the variant's `titleColor` in [defaultsByVariant] (a tone's `on-{tone}-container`), then the layout's row in [defaultsByLayout] ([defaultTitleColor] when stacked) for the variant that states none. Wins over [foregroundColor] for the title on both platforms. |
| `dismissColor` | `CoreColor?` | Dismiss-glyph colour. `null` → [defaultDismissColor]. |
| `borderWidth` | `double?` | Border stroke width (logical px). `null` → [defaultBorderWidth], which is now zero. |
| `borderRadius` | `CoreBorderRadius?` | Border radius. |
| `padding` | `CoreEdgeInsets?` | Padding. `null` → the layout's row in [defaultsByLayout] ([defaultPadding] when stacked). |
| `minHeight` | `double?` | Minimum box height (logical px). `null` → the layout's row in [defaultsByLayout] ([defaultMinHeight] when stacked, none inline). |
| `iconContentGapStyle` | `CoreGapStyle?` | Gap between the leading icon and the content column / trailing slots, passed as is to the `Gap` that separates them. Laid over the layout's row in [defaultsByLayout] ([defaultIconContentGapStyle] when stacked). |
| `titleBottomMargin` | `double?` | Bottom margin between the title and description (logical px). `null` defers to [defaultTitleBottomMargin]. |
| `titleStyle` | `CoreTextStyle?` | Title text style override, merged on top of the layout's row in [defaultsByLayout] ([defaultTitleStyle] when stacked). |
| `descriptionStyle` | `CoreTextStyle?` | Description text style override. |
| `iconStyle` | `CoreIconStyle?` | Leading icon style override, laid over the layout's row in [defaultsByLayout] ([defaultIconStyle] when stacked). Its size is the icon size that a `leading` widget you pass inherits. |
| `actionButtonStyle` | `CoreButtonStyle?` | Look of the action button — colours, padding, corners. Used only when the action you pass is a `Button`, and laid under that button's own `buttonStyle`, which still wins. |
| `closeButtonStyle` | `CoreButtonStyle?` | Close (dismiss) button style override. |

### `CoreAlertStyle` 변형별 기본값 (`CoreAlertVariantStyle`)

| 필드 | `neutral` | `info` | `success` | `warning` | `destructive` |
|------|------|------|------|------|------|
| `backgroundColor` | surfaceContainer | infoContainer | successContainer | warningContainer | errorContainer |
| `descriptionColor` | onSurfaceVariant | onSurfaceVariant | onSurfaceVariant | onSurfaceVariant | onSurfaceVariant |
| `iconColor` | onSurfaceVariant | onInfoContainer | onSuccessContainer | onWarningContainer | onErrorContainer |
| `titleColor` | — | onInfoContainer | onSuccessContainer | onWarningContainer | onErrorContainer |

<!-- STYLE_TABLE:END -->

<a id="접근성-accessibility"></a>

## 접근성

알림 상자 자체는 포커스를 받지 않고, 톤에 따라 스크린 리더에 알리는 방식이 달라집니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `CoUISemantics(role:, label: title, container: true)`. `alert` · `status`는 둘 다 live region 하나로 접힙니다. 닫기 버튼은 로컬라이즈된 이름의 `Semantics(label:)`로 감쌉니다. |
| Jaspr Web | 루트 `<div>`에 톤이 정한 `role`과 `aria-label`(= `title`)이 붙습니다. 닫기 버튼은 네이티브 `<button type="button">`이고 로컬라이즈된 `aria-label`을 갖습니다. |

| variant | Web `role` | Flutter |
| --- | --- | --- |
| `destructive` | `alert` | live region |
| `info` · `success` · `warning` | `status` | live region |
| `neutral` | 없음 | live region 아님 |

`container: true`는 알림을 하나의 시맨틱 경계로 만듭니다. `explicitChildNodes`를 켜지 않으므로, 스스로 경계를 갖지 않는 안쪽 글자(제목 · 설명)는 이 노드로 합쳐져 한 덩어리로 읽힐 수 있습니다. 버튼처럼 스스로 경계를 갖는 자식은 따로 남습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | `action` 안의 버튼 → 닫기 버튼 순서로 포커스를 옮깁니다. 알림 상자 자체는 건너뜁니다. |
| `Shift` · `Tab` | 반대 순서로 옮깁니다. |
| `Enter` · `Space` | 포커스된 버튼을 실행합니다. |
| `Escape` | 알림을 닫지 않습니다. |

두 플랫폼 모두 루트에 `tabindex`나 `Focus`를 두지 않습니다. 버튼 실행은 Flutter가 `Clickable`의 `Enter` · `Space` 단축키를, 웹이 네이티브 `<button>`의 기본 동작을 씁니다.

### 스크린 리더

이름은 필수인 `title`입니다. `description`은 그 안의 글자로 읽힙니다. inline은 설명을 그리지 않고, 제목이 말줄임으로 잘려도 이름은 전체 `title`입니다.

알리는 급함은 톤이 정합니다. destructive만 읽던 문장을 끊고(`alert`), 나머지 톤은 차례를 기다리며(`status`), neutral은 아무것도 알리지 않습니다. 이 세 단계는 웹에서만 모두 구분됩니다. Flutter는 알리는지(neutral과 나머지)만 구분합니다.

닫기 버튼은 두 플랫폼 모두 로컬라이즈된 이름(한국어는 '닫기')을 갖습니다.

### 포커스 관리

| 항목 | 동작 |
| --- | --- |
| 진입 | 없음. 오버레이가 아니라 본문 안의 상자라, 나타나도 포커스를 옮기지 않습니다. |
| 이탈 | 없음. `onDismiss`로 알림을 걷어내면 닫기 버튼에 있던 포커스가 사라지므로, 어디로 돌려놓을지는 알림을 그린 쪽이 정합니다. |
| 가두기 | 없음. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 알리는 급함을 구분하지 못합니다. `alert`와 `status`가 같은 live region 하나로 접혀, destructive도 다른 톤과 같은 방식으로 알립니다. 플랫폼에 알림 축이 하나뿐이라 생기는 차이입니다. |
| Jaspr Web | neutral의 이름이 보조 기술에 닿지 않습니다. `role`이 없어 루트가 일반 요소로 남고, 일반 요소의 `aria-label`은 읽히지 않습니다. 같은 조건에서 Flutter는 이름이 그대로 붙습니다. |
| Jaspr Web | 루트의 `aria-label`은 `attributes`로 덮을 수 없습니다. 이름을 바꾸려면 `title`을 바꿉니다. `role`은 `attributes`로 덮을 수 있습니다. |
| 공통 | neutral의 채움(`surfaceContainer`)과 같은 색 면 위에서는 경계가 사라집니다. filled 카드 안, 그리고 다크 모드의 Popup · Dialog(`surfaceBright`, 같은 neutral 900) 위가 그렇습니다. 두 면의 대비가 1.00:1이라 stacked · inline 모두 패널과 맞붙어 보입니다. 톤이 있는 variant는 자기 컨테이너 색을 가져 영향이 없습니다. 면 색을 바꾸는 것은 색 매핑의 결정이라 그대로 두었습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `leading` · `action` 타입 | `Widget?` | `Component?` |
| 콜백 타입 | `VoidCallback?` | `CoreVoidCallback?` |
| 알리는 방식 | live region 하나(급함 구분 없음) | `role="alert"` · `role="status"`로 급함까지 구분 |
| 닫기 버튼 이름 | `Semantics(label:)` | `aria-label` |
| `leading`의 아이콘 테마 | `IconTheme` | `IconTheme`(같은 이름, 같은 색 · 크기). 아이콘이 아닌 내용은 두 플랫폼 모두 색을 받지 않습니다. |
| inline 제목 말줄임 | `maxLines: 1` · `TextOverflow.ellipsis` | `truncate`(`overflow: hidden` · `text-overflow: ellipsis` · `white-space: nowrap`) |
| 테마 덮기(`ThemeData.copyWith`) | `coreComponentTheme: () => …` 값을 돌려주는 함수 | `coreComponentTheme: …` 값 |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 웹에서는 `Widget` 자리가 `Component`, `VoidCallback` 자리가 `CoreVoidCallback`입니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `title` | `String` | 필수 | 알림 제목. 접근 가능한 이름이 됩니다. |
| `description` | `String?` | `null` | 제목 아래 보조 설명. `inline`에서는 그리지 않습니다. |
| `leading` | `Widget?` | `null` | 톤 아이콘 대신 앞자리에 놓을 위젯 |
| `action` | `Widget?` | `null` | 닫기 버튼 앞에 놓을 행동. 대개 `Button` |

### 종류와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreAlertVariant` | `neutral` | neutral, info, success, warning, destructive |
| `layout` | `CoreAlertLayout` | `stacked` | stacked, inline |
| `showIcon` | `bool` | `true` | false면 앞자리와 그 뒤 간격을 함께 뺍니다. |
| `alertStyle` | `CoreAlertStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onDismiss` | `VoidCallback?` | `null` | 지정하면 닫기 버튼이 생기고, 누르면 불립니다. |

<a id="named-constructors"></a>

### 이름 있는 생성자

| 생성자 | 고정되는 값 |
| --- | --- |
| `Alert.info(...)` | `variant: CoreAlertVariant.info` |
| `Alert.success(...)` | `variant: CoreAlertVariant.success` |
| `Alert.warning(...)` | `variant: CoreAlertVariant.warning` |
| `Alert.destructive(...)` | `variant: CoreAlertVariant.destructive` |

`variant`를 뺀 나머지 속성은 기본 생성자와 같습니다. 두 플랫폼 모두 `key`를 받고, 웹에는 HTML 속성(`id` · `classes` · `css` · `attributes` · `eventHandlers`)이 더 있습니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="alert/related-banner" title="Banner">

특정 영역이 아니라 페이지 맨 위에 거는 공지 띠입니다.

</Card>
<Card demo="alert/related-toast" title="Toast">

잠깐 떴다가 스스로 사라지는 확인입니다.

</Card>
<Card demo="alert/related-dialog" title="Dialog">

진행하기 전에 사용자의 확인 응답을 받습니다.

</Card>
</Cards>
