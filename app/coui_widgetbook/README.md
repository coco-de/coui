# CoUI Widgetbook

CoUI Flutter 컴포넌트를 스토리와 Docs 갤러리에서 실행하는 앱입니다.
[기여자 가이드](../../docs/contributing/README.md)의 환경 설정을 먼저 완료하세요.

운영 주소는 **[coui.cocode.studio](https://coui.cocode.studio/)**입니다.
이 디렉터리의 소스를 루트 경로(`/`)로 빌드하여 Firebase Hosting의
`im-cocode-coui` live 사이트에 게시합니다.

## 실행과 생성

아래 명령은 `app/coui_widgetbook`에서 실행합니다.

```bash
dart run build_runner build
flutter run -d chrome
```

원본은 `lib/component/**/*.stories.dart`와 `lib/foundation/*.stories.dart`입니다.
`*.stories.g.dart`와 `components.g.dart`는 생성기로 갱신합니다.
컴포넌트의 `path + name`은 유일해야 합니다. 같은 경로를 두 번 등록하면
일부 스토리가 내비게이션에서 가려집니다.

## 프리뷰 환경

`lib/widgetbook_config.dart`의 구성을 실제 앱과 회귀 테스트가 함께 사용합니다.

- 색상은 `ThemeData.fromCore`로 해결된 Light/Dark 스킴을 사용합니다.
- `CoUILayer`가 토스트·드로어 등의 공통 호스트를 제공합니다.
- `SlangAddon`이 프리뷰마다 키 없는 번역 범위를 제공합니다. Docs는 여러
  프리뷰를 동시에 그리므로 전역 키를 가진 `TranslationProvider`를
  `appBuilder`에 반복 설치하면 안 됩니다.
- 다이얼로그는 버튼으로 열어야 Docs 진입만으로 여러 모달이 뜨지 않습니다.
- 자연 높이가 큰 예제에는 스크롤 가능한 setup을 제공하고, 이미 스크롤을
  소유한 컴포넌트의 자식에 같은 컨트롤러의 스크롤뷰를 중첩하지 않습니다.
- 글꼴은 [fonts/](fonts/README.md)의 정적 파일을 앱 안에 번들합니다.

## 재질 비교

컴포넌트의 스토리를 선택한 뒤 오른쪽 **Addons → Surface material**에서
Default, Liquid Glass, Neo Brutalism, Claymorphism, Neumorphism을 선택합니다.
Theme의 Light/Dark 선택과 독립적이며, 스토리를 옮겨도 재질 선택은 유지됩니다.
컴포넌트 이름 아래의 일반 스토리는 Args와 Addons를 편집할 수 있습니다.
그 아래 시나리오 항목은 고정된 캡처 설정을 보여 주므로 일반 스토리를 선택하세요.

- AppBar와 NavigationBar의 기본 스토리는 스크롤 콘텐츠 위에 실제 바를
  표시합니다. Liquid Glass 전용 컴포넌트를 따로 찾을 필요가 없습니다.
- AppBar의 **Menus and Toolbars** 스토리에서 액션 그룹과 메뉴도 같은
  재질로 비교할 수 있습니다.
- Liquid Glass에서는 공통 프리뷰 배경에도 참조 무늬를 표시합니다.
  재질은 실제 `CoUILayer`의 프리셋 처리 경로를 거치며, 배경 무늬는
  컴포넌트의 스타일을 덮어쓰지 않습니다.
- 재질 선택은 URL에도 저장되어 동일한 설정을 공유할 수 있습니다.
- Flutter Web의 실제 굴절은 Chromium에서 지원하며 Safari와 Firefox에서는
  기존 대체 렌더링을 사용합니다.

## 회귀 검사

같은 디렉터리에서 실행합니다.

```bash
flutter test test --reporter failures-only
flutter build web --release --base-href /
```

`stories_smoke_test.dart`는 생성된 카탈로그에서 모든 스토리를 도출하여
기본 재질과 Liquid Glass 각각의 Light 작업 화면·작은 Dark 프리뷰를
렌더하고, 실제 Widgetbook의 모든 Docs
페이지를 순회합니다. 전역 키 충돌, 레이아웃 오류, ErrorWidget을 실패로 봅니다.
외부 이미지만 기존 parity 테스트의 네트워크 대역을 사용하며, 글꼴은 실제
배포 manifest에서 로드합니다. 테스트 통과가 CDN 접속 성공을 뜻하지는 않습니다.

`story_interactions_test.dart`는 모달 열기/닫기, 날짜 선택, 스크롤,
접기/펼치기, 탭 드래그와 선택 유지, 진행률 단위를 검증합니다.

`surface_material_test.dart`는 재질 5종의 전환, Light/Dark 조합,
내비게이션 선택 유지와 툴바 메뉴에 전달되는 재질을 검증합니다.

배포 전에는 릴리스 빌드를 브라우저에서도 열어 스토리/Docs, Addons,
외부 이미지, 폰트 요청을 확인합니다. HTTP 200만으로 렌더링 검증을 대신하지
않습니다. 게시 방법은 [문서 배포 안내](../../DOCS_DEPLOYMENT.md)를 따릅니다.

GitHub Actions의 `Deploy`를 `main`에서 실행하면 기존
`FIREBASE_SERVICE_ACCOUNT_IM_COCODE_COUI` secret으로 인증하고, 이 디렉터리의
`firebase.json`을 사용해 배포합니다. 기존 `coui.cocode.im/widgetbook/` 링크는
스토리의 hash/query를 보존해 운영 주소로 이동합니다.

## macOS 데스크톱 앱 (팀 내부용)

같은 위젯북을 macOS 네이티브 앱으로도 실행합니다. 웹 빌드와 별개로 **네이티브
Impeller 렌더 경로**(굴절 셰이더, 텍스트 레이아웃, 스케일링, 제스처)를 확인하는
용도입니다. 웹의 굴절은 Chromium의 SVG 백드롭 컴포지터가 그리고 Safari와
Firefox에서는 꺼지지만, 이 앱은 브라우저와 무관하게 네이티브 셰이더로 그립니다.

### 설치

`gh` 로그인이 필요합니다(저장소가 비공개입니다). 이 저장소를 clone하지 않아도
됩니다.

```bash
gh api repos/coco-de/coui/contents/app/coui_widgetbook/scripts/install_macos.sh \
  -H 'Accept: application/vnd.github.raw' | bash
```

`main`의 최신 성공 빌드를 `/Applications`(쓸 수 없으면 `~/Applications`)에 설치하고
실행합니다. 같은 명령을 다시 실행하면 업데이트됩니다. 옵션은
`install_macos.sh --help`에서 확인합니다(`--run <id>`, `--branch <이름>`,
`--zip <경로>`, `--dest <폴더>`, `--no-open`).

- macOS 12 이상에서 Apple Silicon과 Intel 모두 실행됩니다(universal).
- **Developer ID 서명과 공증이 없습니다.** `gh`로 받은 파일에는 quarantine 속성이
  붙지 않아 바로 실행됩니다. 브라우저로 받은 zip은 Gatekeeper가 막으므로 설치
  스크립트를 쓰거나 `xattr -dr com.apple.quarantine "CoUI Widgetbook.app"`을
  실행하세요.
- 앱은 샌드박스에서 실행되며 네트워크 클라이언트와 사용자가 고른 파일의 읽기·쓰기만
  허용합니다.

### 새 빌드 만들기

GitHub Actions의 **Deploy Desktop**은 수동 실행 전용이며 self-hosted Mac 러너에서
돕니다.

```bash
gh workflow run deploy-desktop.yaml -R coco-de/coui --ref main
```

산출물은 30일간 보관되는 `coui-widgetbook-macos` 아티팩트입니다. 아직 빌드가 없거나
만료됐으면 설치 스크립트가 같은 명령을 안내합니다.

### 로컬 빌드

의존성 해석(`melos bootstrap`)을 마친 뒤 같은 스크립트를 실행하면 CI와 같은 검증이
돕니다.

```bash
scripts/build_macos.sh   # build/desktop/ 에 zip · sha256 · info 생성
```

앱 이름과 번들 ID는
[`macos/Runner/Configs/AppInfo.xcconfig`](macos/Runner/Configs/AppInfo.xcconfig)가
정합니다. 스크립트는 빌드 뒤에 번들 ID, 버전, 아키텍처(arm64와 x86_64), 서명,
entitlements를 확인하고 zip을 풀어도 서명이 유지되는지까지 검사하며, 하나라도
어긋나면 실패합니다. Windows와 Linux는 배포 파이프라인이 없습니다.
