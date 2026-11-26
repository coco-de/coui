# #6443 Tabs / ToggleGroup의 Element 소유 자동 roving ID

기준 main `bad8ebdc8d2c512d216f00c98cb2064f97d51333`, 제품 freeze `774e80bd837bcf2d0e528214c22265e6b0fcf6be`. 두 컴포넌트가 자동 키보드 표적 ID를 구성 객체의 `identityHashCode(this)` 대신 기존 `elementScopeId(context, prefix: ...)`로 만들도록 두 경로만 고쳤습니다. 명시 caller ID는 그대로 우선합니다. 공개 생성자/const/assert/API, Core/Native, 스타일·색·caller CSS, 구조 DOM, State 소유 Menu/Select/TabPane ID, 키보드·선택 구현은 변경하지 않았습니다.

동일한 const Tabs를 두 곳에 배치한 실제 SSR/O2 hydration에서 두 번째 그룹의 키가 첫 그룹으로 이동했습니다. ToggleGroup도 동일한 final 객체를 두 곳에 놓으면 재현됩니다. 기존 `List.length` assert 때문에 ToggleGroup의 실제 const 호출은 컴파일되지 않으며, 이 별도 기존 제약은 보존했습니다.

영구 회귀 4개는 원제품 복사본에서 4/4 실패, 최종 소스에서 4/4 통과했습니다. SSR 30표적/24 unique→30/30, 실제 Chrome 150 키 입력 56회에서 그룹 간 초점 이동 10회→0회였습니다. Arrow/Home/End, ToggleGroup 양 축, Enter/Space 콜백과 네 개 명시 ID 대조군을 확인했습니다. 구성/선택값을 바꾸는 rebuild는 같은 Element owner를 유지하고 keyed remount는 새 owner를 받았습니다. 기존 관련 focus/roving/Tabs/ToggleGroup/accessibility 11파일 160테스트, 변경 Dart 5파일 fatal 0/format 변경 0, 전체 contract guard exit 0(기존 meta 경고 7개)입니다.

같은 authored fixture의 기본 상태를 light/dark × SSR/O2로 대조한 원본 PNG 8개는 before/after 4쌍 모두 PNG byte/RGBA exact였습니다. role별 geometry/computed style/semantics도 각 30행, 총 120쌍 exact입니다. canonical 전체 매트릭스나 Native 이미지 일치를 뜻하지 않습니다.

제품 freeze에서 fresh docs O2 359페이지 빌드 exit 0, 104.23초, tracked 22,560파일 SHA/권한 delta 0, git clean이었습니다. 생성 사이트 Tabs·ToggleGroup 두 경로의 light/dark 및 refresh 8기록에서 client marker를 확인했고 runtime/console/request 오류는 0입니다. 실제 own SSR VM reload도 성공해 HTTP 200→200, 각 응답 30표적이 고유했습니다. 새 요청은 새 Element이므로 자동 ID와 HTML은 동일하지 않으며, 코드 변경 없는 reload라 수신 library는 0개입니다. own browser/server/VM/PID/port를 모두 닫았습니다.

최초 docs 시도는 디스크 ENOSPC로 snapshot 및 after-source JSON 쓰기에 실패했고, 별도 fresh 재시도가 통과했습니다. 부분 JSON·실패 로그를 보존하고 최초 시도 뒤 22,560 tracked파일도 delta 0을 재확인했습니다. 초기 ToggleGroup const fixture 오류, test lint, 임시 docs-UI script quoting 오류도 보존했으며 최종 검증과 구분합니다.

공개 caller ID/attributes를 정규화하거나 중복 ID를 자동 고치지 않습니다. 전체 816/3814, Native 렌더링, 잔여234 감소는 재측정하거나 주장하지 않습니다. JSON에 소스·명령·원본 경로와 SHA-256, fresh/reuse 범위를 연결했습니다. SDK/로그인/공용 캐시 설정이나 의존성·lock 변경은 없습니다.

## main 0a23 통합 재검증 — PR #6445

Root가 main `0a23b3cc9832beef730c01330b6fee2c832ecef6`(기존 CoreOpacity utility 등록 #6444)을 ordinary merge한 소스 `6e056953ffcea3a174167d3a40edcbf9a46cccfa`에서 다시 검증했습니다. main 대비 own 제품 경로는 Tabs/ToggleGroup 두 파일뿐이고 SHA는 원제품 `774e80bd8`과 정확히 같습니다. 공개 API/const·명시 ID·caller CSS를 추가 변경하지 않았습니다.

통합 소스에서 기존 관련 160테스트, 실제 SSR/O2 회귀 4개(키56회·오류0·SSR30 unique·rebuild 유지/remount 교체), opacity actual-browser 6개와 Loading 호환성 47개, opacity config 1개가 모두 통과했습니다. 새 opacity 등록이 default/brand/caller utility와 Loading의 기존 token 경로에 미치는 영향을 확인하기 위한 호환성 검사입니다. own Dart 5파일 fatal0/format 변경0도 재확인했습니다.

동일 통합 소스의 fresh docs O2 359페이지 빌드는 exit0/81.545초, tracked 22,567파일 hash/권한 delta0/git clean이었습니다. 이전 빌드는 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-roving-owner-fix-20261119.8pynk_cn/integration-0a23/previous-docs-build`로 rename 보존했습니다. 새 생성 사이트 두 경로의 light/dark·refresh 8기록에서 runtime/console/request 오류0, 새 own SSR VM reload도 HTTP200→200/각30 unique/success로 통과했습니다(코드 수정 없는 reload, 수신 library0). own build group/browser/server/VM/PID/port는 닫았습니다.

최초 문서 두 파일 원본은 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-root-6443-integration-20261119.y84om0rw/original-roving-docs`에 SHA와 함께 보존했습니다. 기존 774e의 PNG·음성검증·guard 증거를 이 통합 소스의 fresh 결과로 재라벨하지 않습니다. 기존 한계와 전체816/3814·Native·잔여234 감소 미주장은 그대로입니다. 통합 JSON receipt는 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-roving-owner-fix-20261119.8pynk_cn/integration-0a23/integration-summary.json`입니다.
