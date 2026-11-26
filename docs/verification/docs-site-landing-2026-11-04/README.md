# 문서사이트 첫 화면 개선

작업 기준: `18a2071e7`. `docs_site`의 랜딩과 정적 카탈로그 썸네일을 수정했다. 배포 전 로컬 구현이다.

## 디자인과 범위

기존 `ThemeData.coui`, Pretendard 및 공통 `--coui-*` 토큰을 사용한다. 개발자가 COUI를 이해하고, 자신의 플랫폼으로 시작하고, 예제를 통해 스타일을 확인하는 흐름을 우선한다. Figma나 공통 라이브러리 테마는 변경하지 않았다.

- 히어로는 두 줄 제목과 플랫폼별 시작 링크를 제공한다. 본문은 36rem, 전체는 최대 52rem이다. 제목은 32–56px로 반응형 처리하고, 여백과 간격은 공통 토큰을 사용한다.
- CTA는 CoUI `Button(href:)`로 렌더한다. 히어로의 클라이언트 island를 제거해 자바스크립트 실행 전에도 링크가 동작한다. 생성된 클라이언트/서버 등록 파일도 갱신했다.
- 대표 예제 위에 기존 스타일 선택지를 노출한다. 선택지는 `SurfaceStyleSwitcher.offered` 한 곳에서 읽고, 기존 전역 스타일 스크립트가 헤더와 본문을 동기화한다.
- 스타일 이름은 `data-style-label`에서 읽는다. CoUI Button 내부의 `<style>` 텍스트가 헤더의 현재 선택 라벨에 섞이지 않게 한다.
- 썸네일 외곽은 CoUI `Card`의 outlined/expand 설정을 사용하고, 제목과 설명은 공유 카탈로그에서 읽는다. 미리보기는 실제 예제 레지스트리를 재사용한다.
- 썸네일은 `inert`/`aria-hidden`으로 표시해 Command의 autofocus, 내부 Tab 진입, 중복된 컨트롤 노출을 막는다. 문서 제목 링크는 썸네일 바깥에서 조작할 수 있다. 전체 카탈로그에도 같은 경계를 적용했다.
- 랜딩에 본문 건너뛰기 링크를 추가했다. 히어로와 갤러리는 `not-content`로 문서 본문 스타일과 분리한다.

## 검증

| Command / 방법 | Expected | Evidence | 판정 |
| --- | --- | --- | --- |
| 변경 파일 `dart analyze --fatal-infos` | 새 분석 이슈 없음 | `No issues found!` | 통과 |
| 변경 파일 `dart format --set-exit-if-changed --output=none` | 포맷 드리프트 없음 | `Formatted 8 files (0 changed)` | 통과 |
| `git diff --check` | 공백 오류 없음 | 출력 없음, exit 0 | 통과 |
| 아래 5개 테스트 파일, 기존 gzip 검사 제외 | 랜딩·카탈로그·스타일·내비게이션·문서 셸 회귀 없음 | `+45: All tests passed!` | 통과 |
| `jaspr serve --port 18471 --web-port 18472 --proxy-port 18473` | 생성 파일 및 웹 컴파일 성공, SSR 응답 성공 | `Server started`, `Serving at http://localhost:18471`, 홈 HTTP 200 | 통과 |
| 브라우저에서 JavaScript 비활성화 후 시작 CTA 클릭 | 기본 링크 이동 | `/getting-started` 도착 | 통과 |
| 홈 첫 방문 및 썸네일 입력창 `focus()` 시도 | 자동 스크롤/포커스 이동 없음 | `scrollY: 0`, `active: BODY`, `attemptedAutofocus: false` | 통과 |
| 본문 건너뛰기 및 카드 다음 Tab | 주 콘텐츠로 이동하고 썸네일 내부 컨트롤 제외 | `skipDestination: main-content`, `nextTile: /components/chat`, `insidePreview: false` | 통과 |
| 플랫폼별 링크 도착 섹션 검사 | 실제 문서의 제목 존재 | `flutterAnchor: Flutter#`, `jasprAnchor: Jaspr Web#` | 통과 |
| 전체 카탈로그 브라우저 검사 | 모든 썸네일 비활성, 자동 스크롤 및 가로 넘침 없음 | `previewCount: 162`, `galleryScrollY: 0`, `active: BODY`, `overflow: 0` | 통과 |
| 5개 스타일 전환 | 선택 상태/문서 속성/헤더 이름 동기화 | Default, Neo-brutalism, Liquid Glass, Neumorphism, Claymorphism 각각 일치; 가로 넘침 0 | 통과 |
| 기본 스타일의 light/dark × 1200px/390px 캡처 | 줄바꿈, 헤더·본문·예제 표시 및 가로 넘침 확인 | 아래 스크린샷; 각 조합 overflow 0 | 통과 |

테스트 명령:

```sh
cd docs_site
dart test \
  test/content/landing_page_test.dart \
  test/components/component_grid_render_test.dart \
  test/content/surface_styles_guide_test.dart \
  test/components/site_navigation_render_test.dart \
  test/components/manual_layout_test.dart \
  --name '^(?!.*gzip)' --reporter expanded
```

## 기존 검사 실패

전체 카탈로그의 gzip 용량 검사는 64KiB 미만을 요구하지만, 이번 수정 전 `HEAD`의 컴포넌트/테스트 소스를 별도로 렌더해도 **73.202KiB**로 실패한다. `inert` 경계를 추가한 현재 구현은 **73.260KiB**다. 허용치를 올리거나 검사를 변경하지 않았다. 따라서 대상 테스트 전체가 통과했다고 표현하지 않는다.

프로덕션 SSG 빌드·배포, 전체 문서 페이지의 시각 회귀, 모든 스타일의 플랫폼별 접근성 감사는 이번 검증 범위에 포함하지 않았다.

## 화면

- [변경 전 데스크톱 다크](before-desktop-dark.png): 자동 스크롤이 발생한 뒤 비교를 위해 맨 위로 돌려 캡처했다.
- [데스크톱 라이트](desktop-light.png)
- [데스크톱 다크](desktop-dark.png)
- [모바일 라이트](mobile-light.png)
- [모바일 다크](mobile-dark.png)

## 배포 요청 후 재검증 (2026-11-05)

배포 워크플로 검사를 추가해 6개 대상 테스트 파일 전체를 다시 실행했다. **57개 통과, 1개 실패**이며, 실패 항목은 위에서 확인한 기존 카탈로그 gzip 용량 검사다(이번 실행 73.265KiB, 제한 64KiB). 이 결과와 이미 확인한 변경 전 실패를 함께 기록한다. 변경 파일 정적 분석은 `No issues found!`, 포맷은 `8 files (0 changed)`, `git diff --check`는 exit 0이다.

배포는 저장소의 수동 `Deploy` 워크플로를 `main`에서 실행하며, 배포 작업이 수행하는 프로덕션 빌드와 산출물 무결성 검사를 추가로 확인한다.
