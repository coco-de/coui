# CoUI 기여자 가이드

CoUI를 처음 고치는 사람을 위한 안내입니다. **공통 디자인 정의를 한 곳에서
바꾸고 Flutter·Web·Figma에 일관되게 전달하는 방법**을 배웁니다.

기본적인 파일 편집과 터미널 사용을 전제로 합니다. Git의 *브랜치*는 변경을
분리하는 작업선, *커밋*은 변경 기록, *PR*은 그 변경을 합치자는 요청입니다.
CoUI 고유 용어는 [구조와 용어](architecture.md)에서 설명합니다.

## 읽는 순서

| 순서 | 가이드 | 읽고 나면 할 수 있는 것 |
|---|---|---|
| 1 | [환경 설정과 첫 실행](getting-started.md) | 의존성 설치, 프리뷰 실행 |
| 2 | [구조와 용어](architecture.md) | 변경할 원본과 영향받는 파일 찾기 |
| 3 | [첫 변경: Badge](first-change.md) | 작은 변경을 Core에서 Figma까지 추적 |
| 4 | [검증과 문제 해결](verification.md) | 검사 선택, 결과 해석, 증거 기록 |
| 5 | [Figma 플러그인 작업](figma.md) | export·build·Import·Generate·게시 구분 |
| 6 | [호환성과 업그레이드](upgrading.md) | API 변경 예고, 릴리스, 소비자 갱신 |

첫날 체크리스트는 [ONBOARDING.md](../../ONBOARDING.md), 영문 기여 입구는
[CONTRIBUTING.md](../../CONTRIBUTING.md)입니다.

## 지금 하려는 일에서 바로 시작하기

- **한 화면의 모양만 바꾸기:** 먼저 소비 앱의 Style/Theme override로
  표현할 수 있는지 확인합니다. [적용 한계](../coui-application-limits.md)를 참고하세요.
- **기본값이나 공통 API 개선:** [변경 위치 지도](architecture.md) →
  [첫 변경](first-change.md).
- **Web만 다르게 보이기:** 같은 조건의 Flutter 결과와 Web resolver/DOM을
  [검증 가이드](verification.md)대로 비교합니다.
- **Figma 인스턴스가 안 늘어나기:** [Figma 가이드](figma.md)에서 builder와
  실제 리사이즈 검증 경로를 찾습니다.
- **새 버전을 프로젝트에 적용하기:** [업그레이드](upgrading.md).
- **디자이너의 리디자인을 받아 반영하기:** [디자이너 · 개발자 협업](design-collaboration.md) —
  리디자인 이슈부터 캔버스 확인까지.

## 이 문서와 규칙의 관계

이 폴더에는 공개 기여에 필요한 설명과 실습이 있습니다.
실행 명령은 [루트 pubspec](../../pubspec.yaml)과
[플러그인 package.json](../../tools/figma-token-sync/package.json)에서 확인합니다.
팀 규칙은 [CoUI 팀 지침 설치 안내](https://github.com/coco-de/skills/tree/main/internal/coui)에서 찾습니다.

명령의 실행 위치는 각 블록 위에 적습니다. `coui/`는 저장소 루트의 예시
이름이며, 실제 clone/worktree 폴더 이름은 달라도 됩니다. `Xxx`, `{name}`,
`<issue-number>`는 설명용 자리표시자이므로 실제 값으로 바꿔야 합니다.

이 가이드를 수정할 때는 경로·명령·예제를 함께 대조하고, 실행하지 않은
검사를 실행했다고 기록하지 않습니다.
