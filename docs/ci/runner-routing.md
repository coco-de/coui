# 필수 검사 러너 경로 준비

2026-10-27 #5720의 Reshoot는 38초 실행에 25분 7초 대기했다. 공식 골든 갱신 run40459426747도 18분 33초 대기했다. 조사 당시 조직 러너 17개는 모두 busy였고, 필수·관찰 작업이 모두 `self-hosted` 풀을 사용했다. 보호 규칙을 약화하는 대신 실행 순서와 선택 라벨을 분리한다.

## 코드 변경과 현재 효과

Perf, Web Selection, Parity run only after both Static Guards and Flutter succeed. If either required job fails, is cancelled, or is skipped, these advisory jobs are skipped too. A skipped advisory check is not evidence of verification. After the required job passes on retry, the advisory checks run. Required checks do not depend on advisory jobs. This does not isolate capacity from other repositories or pull requests.

다음 저장소 변수는 **추가 선택 라벨**이다. `self-hosted`는 항상 필요하며, 변수가 비어 있으면 기존 self-hosted 풀을 그대로 사용한다. GitHub-hosted 과금 풀로 자동 전환하지 않는다. 이 변경은 변수·러너·그룹·보호 설정을 생성하거나 수정하지 않는다.

| 변수 | 작업 |
|---|---|
| COUI_LIGHT_RUNNER_LABEL | Static Guards, Reshoot |
| COUI_RENDER_RUNNER_LABEL | Flutter 필수 검사, 공식 golden/preset baseline 생성 및 재검증 |
| COUI_OBSERVE_RUNNER_LABEL | Perf, Web Selection, Parity |

## 외부 설정 전 필요한 확인

1. 풀별 실제 runner ID·호스트·CPU/RAM 및 online 여부, 동시 슬롯 수와 다른 저장소 작업의 사용 범위를 확인한다. 같은 물리 머신에 라벨만 나누면 CPU 격리는 없다.
2. 기존의 범용 `runs-on: self-hosted`도 새 라벨이 붙은 러너를 선택할 수 있다. 따라서 라벨 추가만으로 예약/우선순위가 생기지 않는다. 실제 전용 풀이 필요하면 조직 runner group의 저장소·워크플로 접근 정책 및 모든 관련 소비자의 라우팅을 함께 설계해야 한다.
3. light 풀은 git/python3/Node24/ripgrep 및 기존 shell guard 환경을 지원해야 한다. render 풀은 기존 공식 golden과 같은 macOS/ARM64·Flutter3.50.0·글꼴 환경을 유지해야 한다. observe 풀은 Chrome/Flutter/Web 캡처 의존성이 필요하다.
4. 운영자가 접근 정책과 전용 용량을 승인·준비한 후 선택 라벨을 부착하고, 실제 idle/online runner가 매칭되는 것을 확인한 뒤 저장소 변수를 설정한다. 존재하지 않는 라벨을 먼저 지정하면 필수 검사가 무기한 대기할 수 있다.
5. 한 PR의 실제 체크 이름·러너 이름·대기 및 실행시간과 공식 golden 비교 결과를 확인한다. 실패 시 해당 변수를 비우면 기존 풀로 돌아간다. 보호 검사 삭제·관리자 우회·기준 이미지 자동 승인으로 복구하지 않는다.

## 검증

`actionlint -shellcheck= -pyflakes=`로 변경된 네 워크플로를 검사했다. YAML 전후 구조 비교에서 runs-on/needs/if를 제외한 트리가 동일함을 확인했다. 테스트 명령, SDK 핀, 권한, required check 이름, 제한시간, 트리거 및 골든 승격 뒤 재검증은 그대로다. 외부 설정이나 실제 전용 풀 실험은 아직 실행하지 않았으므로 대기시간 개선을 실측했다고 주장하지 않는다.


## Required-failure retry evidence

In run40461700524, Flutter reached its 45-minute limit while waiting for a Dart coverage isolate. The old `!cancelled()` conditions queued three advisory jobs. While the run remained queued, the failed Flutter job rerun API returned `job cannot be rerun`. Using `success()` prevents this advisory queue after a required failure. Existing runs are unaffected. Required check names, commands, timeouts, golden checks and branch protection remain unchanged. actionlint passes, and a parsed YAML comparison confirms that only the three advisory conditions changed.
