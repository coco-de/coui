# 첫 변경 — outlined Badge의 선 두께 따라가기

[가이드 목차](README.md) · 이전: [구조와 용어](architecture.md) · 다음: [검증](verification.md)

**실습 목표:** Badge의 기본 선 두께를 기존 `stroke1`에서 `stroke2`로 바꾸는
상황을 가정하고, 한 값이 어디까지 전달되는지 확인합니다. 이것은 변경 절차를
배우는 예시입니다. 실제 제출할 디자인 값은 담당 이슈의 요구사항을 따릅니다.
디자인 변경 요청은 [협업 가이드](design-collaboration.md)에
따라 근거가 되는 결정 문서와 절을 이슈에 연결합니다.

## 1. 변경 전 기준 만들기

[첫 실행](getting-started.md)을 끝내고, 실습 변경을 구별할 수 있는 작업
브랜치를 준비합니다. 독립 이슈라면 **루트**에서 다음과 같이 만듭니다.
`<issue-number>`는 실제 번호로 바꾸세요. GitHub CLI 로그인과 저장소 쓰기
권한이 필요합니다.

```bash
git status --short
gh issue develop <issue-number> --name chore/<issue-number>-badge-outlined --base main --checkout
```

예상 결과: 해당 이슈와 연결된 브랜치가 checkout됩니다. 이미 작업 브랜치가
있으면 새로 만들지 말고 그 브랜치를 사용합니다. 자식 이슈는 부모 브랜치를
base로 사용합니다. [PR 가이드](../../CONTRIBUTING.md#pull-requests)를 참고하세요.

문서 사이트의 `/components/badge`에서 **outlined / md / 동일한 텍스트**를
Web과 Flutter에 표시합니다. Light/Dark, 테마 배율, 표면 스타일을 맞추고
변경 전 화면을 기록합니다. 우선 기본 테마와 scaling 1에서 비교하세요.

## 2. 원본 한 곳 수정

[Core Badge Style](../../packages/coui_core/lib/src/component/contracts/badge/badge_style.dart)의
`defaultBorderWidth`를 찾습니다. 아래는 클래스 안의 **교체할 선언 한 줄**입니다.

```dart
static const double defaultBorderWidth = CoreStrokeWidth.stroke2;
```

`CoreStrokeWidth.stroke2`는 이미 있는 토큰입니다. 토큰 스케일 자체의
`stroke1` 값을 바꾸면 다른 모든 컴포넌트까지 영향을 받으므로 이 실습과 다릅니다.
기본값 변경 이유가 달라졌다면 바로 위 주석도 함께 갱신합니다.

## 3. 양 플랫폼에서 소비되는지 확인

| 단계 | 실제 경로 | 확인할 내용 |
|---|---|---|
| 공유 override | Core `badge_style.dart` | `borderWidth` 필드와 `defaultBorderWidth`의 구분 |
| Flutter resolver | [badge_style.dart](../../packages/coui_flutter/lib/src/components/display/badge/badge_style.dart) | `merged.borderWidth ?? CoreBadgeStyle.defaultBorderWidth` → geometry/scaling |
| Flutter widget | [badge.dart](../../packages/coui_flutter/lib/src/components/display/badge/badge.dart) | resolved 값으로 테두리 렌더 |
| Web resolver | [badge_style.dart](../../packages/coui_web/lib/src/components/display/badge/badge_style.dart) | 같은 fallback → `strokeWidthCss` → root inline CSS |
| Web component | [badge.dart](../../packages/coui_web/lib/src/components/display/badge/badge.dart) | resolved root chrome 적용 |

이 필드는 이미 연결돼 있어 기본값 수정만으로 두 구현에 전달됩니다. 새 필드를
추가하는 작업이라면 이 전체 경로를 구현해야 합니다. 선언만 있으면 완료가 아닙니다.

변경 후 Flutter는 hot restart하고, Jaspr의 재빌드가 끝나면 브라우저를 새로고침합니다.
outlined에서 새 선 두께가 보이는지 확인합니다. filled · tonal처럼 기본 borderColor가
없는 변형에 갑자기 테두리가 생기지 않는지도 확인하세요.

**override가 계속 이기는지도 확인합니다.** 아래는 테마가 있는 기존 build
안에서 사용할 표현식이며 독립 앱 전체 코드는 아닙니다. Flutter는
`package:coui_flutter/coui_flutter.dart`, Web은 `package:coui_web/coui_web.dart`를
import합니다. 양쪽에서 같은 API를 사용합니다.

```dart
Badge(
  variant: CoreBadgeVariant.outlined,
  badgeStyle: const CoreBadgeStyle(borderWidth: CoreStrokeWidth.stroke1),
  child: const Text('Outlined'),
)
```

예상 결과: 기본 Badge는 새 기본값을, 이 인스턴스는 명시한 `stroke1`을
사용합니다. 테마/scaling이 다른 화면에서 물리 픽셀 수만 비교하지 마세요.

## 4. 테스트와 예제 갱신

[검증 명령](verification.md)의 Badge Core/Flutter/Web 테스트를 실행합니다.
기존 테스트가 다루는 merge·override·렌더 조건을 읽고, 이번 변경을 실제로
보장하지 못한다면 **사용자가 관찰할 결과**에 대한 검증을 추가합니다.
`defaultBorderWidth == defaultBorderWidth`처럼 구현을 그대로 되풀이하는
단언은 변경이 맞는지 알려주지 않습니다.

문서 예제는 다음 쌍을 함께 읽습니다.

- [Flutter Badge 예제](../../docs_core/lib/previews/examples/flutter/badge/)
- [Web Badge 예제](../../docs_core/lib/previews/examples/web/badge/)
- [사용자 문서](../../docs_core/content/components/badge.md)

기존 outlined 예제는 이미 기본값을 쓰므로 값을 강제로 넣을 필요가 없습니다.
실제 예제 코드를 바꿨다면 같은 디렉터리의 `_code.dart`도 갱신합니다.
기본값을 숫자로 설명한 문장이 있으면 새 의미와 맞춥니다.

## 5. Figma까지 전달

플러그인 의존성을 설치한 뒤 **루트**에서 실행합니다.

```bash
melos run figma:sync
git diff -- tools/figma-token-sync/src/data/components.json
```

예상 결과: token JSON과 component JSON이 재생성되고 `code.js`가 빌드됩니다.
component JSON의 `components.badge.fields.borderWidth`가 변경된 값을
담는지 확인합니다. [display.ts](../../tools/figma-token-sync/src/components/display.ts)의
`buildBadge`는 `BADGE.fields.borderWidth`를 읽어 `borderData`에 전달합니다.
따라서 이 실습에서는 TypeScript에 두 번째 선 두께를 적지 않습니다.

이어서 [Figma 절차](figma.md)대로 플러그인을 다시 열고 **Import to Variables →
Generate Components**를 실행합니다. outlined의 두께, 변수 연결, 인스턴스
보존을 확인합니다. 빌드 성공만으로 Figma canvas까지 바뀐 것은 아닙니다.

## 6. 제출하기

- [ ] 의도한 기본값과 명시 override가 양 플랫폼에서 동작한다.
- [ ] 기본/outlined, Light/Dark, 관련 크기·상태의 회귀를 확인했다.
- [ ] Figma export 변경분과 실제 생성 결과를 확인했다.
- [ ] 실행 명령·결과·화면을 PR에 기록했다.
- [ ] [호환성 검토](upgrading.md)로 기존 사용자에게 미치는 영향을 설명했다.

연습만 했다면 원래 값으로 **직접 되돌려 편집하고 재-export**해 실습 변경이
남지 않도록 확인합니다. 다른 작업까지 `git restore .`로 지우지 않습니다.

## 새 컴포넌트를 추가한다면?

기본값 변경보다 연결 지점이 많습니다. 레이어별 역할은 [구조와 용어](architecture.md)에서 확인합니다.

1. 유사 컴포넌트와 사용처를 조사하고 사용자용/인프라 성격을 정합니다.
2. `coui_core/lib/src/component/contracts/{name}/`에 Contract·Style·Theme와
   필요한 enum을 만들고 [Core barrel](../../packages/coui_core/lib/coui_core.dart)에 export합니다.
   [CoreComponentTheme](../../packages/coui_core/lib/src/component/core_component_theme.dart)의
   테마 슬롯과 값 연산도 연결합니다.
3. 양쪽 `lib/src/components/{category}/{name}/`에 resolver와 widget을 구현하고
   [Flutter barrel](../../packages/coui_flutter/lib/coui_flutter.dart)과
   [Web barrel](../../packages/coui_web/lib/coui_web.dart)에 공개합니다.
4. 각 패키지 테스트를 작성합니다. 같은 입력·상태·override가 같은 결과를
   만드는지 확인합니다.
5. 사용자 문서 대상이면 `docs_core/content/components/`와 양쪽 example/code를
   작성합니다. 네 preview/code registry, 네 example/code barrel, `component_catalog.dart`,
   preview constraints를 연결합니다. 넓은 컴포넌트는 preview layout도 확인합니다.
6. Widgetbook은 `app/coui_widgetbook/lib/component/`의 현재 이웃 구성과
   `components.g.dart` 연결 방식을 확인합니다. 저장소별 구성 방식이 다르므로
   다른 앱의 annotation 예제를 무조건 복사하지 않습니다.
7. Figma exporter 결과를 확인하고 알맞은 `src/components/*.ts`의 builder 및
   registry 배열에 연결합니다. 합성하는 자식은 `needs`에 선언하고, 축·슬롯·
   sizing을 실제 Contract 및 Flutter 구조와 맞춥니다.
8. [검증](verification.md)과 [Figma 실제 리사이즈](figma.md)를 마친 뒤 PR을 올립니다.

`melos run coui:component:new`는 현재 구현 TODO가 남은 안내 스크립트입니다.
출력 메시지만 보고 파일이 생성됐다고 생각하지 마세요.
