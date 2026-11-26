# 검증과 문제 해결

[가이드 목차](README.md) · 이전: [첫 변경](first-change.md) · 다음: [Figma](figma.md)

**컴파일이 된다는 것과 같은 화면을 그린다는 것은 다릅니다.** 검사마다
무엇을 보장하는지 구분하고, 바꾼 경로를 확인한 증거를 남깁니다.

## 어떤 검사를 골라야 하나요?

| 변경 | 확인할 것 |
|---|---|
| 문서만 | 링크·파일 경로·명령·예제 API 대조, 사이트 문서는 docs API sync 테스트, 렌더링 변경 시 해당 페이지 확인 |
| Core Style/Contract/토큰 | 해당 Core 테스트, 양 플랫폼의 영향받는 resolver/widget 테스트·분석, export, 관련 시각/행동 회귀 |
| Flutter | 해당 디렉터리 analyze/format, widget 테스트, 실행 앱에서 상태·override·배율 확인 |
| Web | 해당 디렉터리 analyze/format, resolver/컴포넌트 테스트, 실제 DOM·키보드·computed style 확인 |
| Figma exporter/builder | export 결과, typecheck/selftest, 관련 구조 가드, 실제 Import/Generate·리사이즈·identity 확인 |
| 공개 API/기본 동작 | 위 검사 + 소비자 사용처 조사 + [호환성 및 마이그레이션](upgrading.md) |

문서만 고쳤다고 매번 앱 전체 테스트를 새로 작성할 필요는 없습니다. 반대로
기능 변경을 문서 검사만으로 끝내면 안 됩니다. PR에 적용되는 CI는 별도로
통과해야 합니다.

## 로컬 명령 모음 — Badge 예시

선행 조건: [환경 설정](getting-started.md) 완료. 아래 경로의 Badge를 본인의
변경 컴포넌트로 바꿉니다. **각 `cd` 블록은 새 터미널의 루트에서 시작**합니다.

### 분석과 포맷

**루트**에서 실행합니다. 추가 도구는 필요 없습니다 — 둘 다 Dart SDK 명령입니다.

```bash
dart format --set-exit-if-changed --output=none \
  packages/coui_core/lib/src/component/contracts/badge \
  packages/coui_flutter/lib/src/components/display/badge \
  packages/coui_web/lib/src/components/display/badge
dart analyze --fatal-infos packages/coui_core/lib/src/component/contracts/badge
dart analyze --fatal-infos packages/coui_flutter/lib/src/components/display/badge
dart analyze --fatal-infos packages/coui_web/lib/src/components/display/badge
```

예상 결과: 포맷 차이 없음(`0 changed`), analyzer 이슈 없음. 포맷을 적용하려면
같은 경로에 `--set-exit-if-changed --output=none` 없이 `dart format`을 실행한 뒤
diff를 봅니다. 포맷 설정(`trailing_commas: preserve` / `page_width: 80`)은
[analysis_options.yaml](../../analysis_options.yaml)의 `formatter:` 블록이
소유하므로 명령줄에 플래그로 다시 쓰지 않습니다. 테스트나 예제 Dart도
수정했다면 그 경로를 포함합니다. 대규모 패키지 전체 분석은 메모리가 많이
필요하므로 로컬은 변경 디렉터리 중심으로 검사합니다.

### Core

```bash
cd packages/coui_core
dart test test/badge_style_test.dart
```

예상 결과: Style merge·copyWith·동등성·크기 표 검사 통과. 실제 렌더링은
이 테스트가 검증하지 않습니다.

### Flutter

```bash
cd packages/coui_flutter
flutter test test/components/display/badge_test.dart
```

예상 결과: Badge widget 테스트 통과. 추가로 바꾼 동작의 실패/상태 경로를
검증하고, 시각 변경은 실제 프리뷰와 필요한 골든 검사를 합니다.

### Web

```bash
cd packages/coui_web
dart test test/components/display/badge_test.dart test/components/display/badge_style_test.dart
```

예상 결과: 컴포넌트/resolver 테스트 통과. SSR 문자열 테스트는 브라우저가
CSS를 실제로 적용했는지, hydration 후 입력이 동작하는지까지 보장하지 않습니다.

### 문서 API

```bash
cd docs_core
dart test test/registry/docs_api_sync_test.dart
```

예상 결과: `docs_core/content`의 알려진 API 드리프트 검사 통과. 이 테스트는
루트 `CONTRIBUTING.md`와 `docs/contributing/`의 모든 링크/코드 블록을 검사하는
도구가 아닙니다. 해당 문서의 링크, Melos script 이름, 코드 예제는 별도로 대조합니다.

### Figma

플러그인 작업 시 **루트**에서 실행합니다. `figma:check`는 의존성을 lockfile로
다시 설치한 뒤 타입 검사와 selftest를 실행합니다.

```bash
melos run figma:check
```

예상 결과: npm 설치, TypeScript 검사, 등록된 selftest 전부 통과.
`reverse/` 코드를 수정했다면 별도 tsconfig 대상이므로 **루트**에서 추가합니다.

```bash
cd tools/figma-token-sync
npm run typecheck:reverse
npm run selftest:reverse
```

예상 결과: 역방향 리포트 도구의 별도 타입/계약 검사 통과. 실제 Figma
레이아웃·편집 보존·identity는 [Figma 검증](figma.md)으로 확인합니다.

## 시각 회귀와 기준선

의존성·Flutter 테스트 환경·Web 캡처용 브라우저가 준비된 **루트**에서 실행합니다.
브라우저 선택은 [공유 브라우저 런처](../../tool/browser_launch.dart), 캡처 흐름은
[VRT 실행기](../../tool/parity/run_vrt.sh)의 안내를 참고하세요.

```bash
melos run parity:vrt -- badge
```

예상 산출물: `test/parity/captured/`, `test/parity/diff/`,
`test/parity/report/vrt-report.md`. 이 명령은 **각 플랫폼을 자기 과거
기준선과 비교**합니다. Web↔Flutter 비교와 같은 의미가 아닙니다.
기준선 없음은 첫 캡처이지 회귀 통과 증거가 아닙니다.

의도한 변경인지 캡처/diff를 먼저 검토합니다. 기준선을 올리면 잘못된 렌더도
새 정상으로 굳어지므로, 테스트를 초록으로 만들 목적만으로 올리지 않습니다.
승격 계획은 **루트**에서 읽기 전용 dry-run으로 볼 수 있습니다.

```bash
dart run tool/parity/promote.dart --dry-run
```

예상 결과: 승격할 기준선 목록만 출력. `melos run parity:promote`의 기본
동작은 **파일 변경과 커밋 생성**입니다. 일부 키만 승격하거나 `--no-commit`이
필요하면 [promote 도구](../../tool/parity/promote.dart)의 옵션을 확인하세요.

## 증상 → 확인 → 복구

| 증상 | 확인할 것 | 다음 행동 |
|---|---|---|
| clone 권한 오류 | 로그인 계정·저장소 접근 | maintainer에게 접근 요청 |
| SDK/meta/analyzer 의존성 충돌 | 루트 SDK 최소값, 실제 Flutter/Dart PATH | CI와 맞는 Flutter의 번들 Dart로 `flutter pub get` |
| `melos`/`jaspr`를 찾지 못함 | global activate 성공 여부·Pub Cache bin PATH | [설치](getting-started.md) 재확인 |
| `*.g.dart` 또는 locale getter 없음 | 어떤 생성기의 입력을 바꿨는지 | `generate` 또는 `generate:locale` 실행 |
| 로컬 사이트가 이상한 파일 목록만 보임 | 실행한 서버 | `docs:serve` 대신 `docs_site`에서 `jaspr serve` |
| Web 색상은 있지만 hover/focus가 다름 | 실제 computed style·CSS class·inline 충돌 | resolver 출력과 hydrated DOM을 함께 확인 |
| 기본값을 바꿨는데 화면 그대로 | Theme/인스턴스 override, hot restart 여부 | override 없는 같은 조건의 프리뷰로 재확인 |
| Figma만 옛 모습 | component export, bundle build ref, Import/Generate 여부 | [Figma 갱신 순서](figma.md)대로 확인 |
| Figma G1이 stale | `components.json`과 소스/생성기의 차이 | 재-export 후 diff 검토·커밋 |
| G1이 skip인데 성공 코드 | JSON에 미커밋 변경이 있는지 | skip은 검증 아님. 커밋 후 깨끗한 JSON에서 다시 확인 |
| Figma 루트만 늘고 자식 그대로 | builder의 FILL/HUG/FIXED와 constraints | 원본 builder 수정 후 실제 인스턴스를 늘려 확인 |
| 포맷 결과가 로컬과 CI에서 다름 | 그 트리의 옵션 파일이 `formatter:`를 갖는지, `.dart_tool`이 있는지 | `package:` include가 풀리지 않으면 설정이 통째로 무시됩니다 — 부트스트랩 후 재검사 |

## PR에 남길 검증 기록

다음 서식을 실제 결과로 채웁니다. 해당 없는 항목은 이유를 적습니다.

```text
변경 범위:
명령 / 실행 디렉터리:
예상 결과 / 실제 결과:
화면 조건: 플랫폼, variant, size, state, theme, scaling
증거: 로그 또는 스크린샷
미실행/미확인 항목과 이유:
```
