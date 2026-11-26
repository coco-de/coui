# Deferred component owner lifetime — #6574 / #6575

`RefreshTrigger.refresh()`를 mounted 상태에서 두 번 호출한 뒤 첫 Future가 끝나기 전에 컴포넌트를 제거하면, 대기하던 두 번째 호출이 dispose된 소유자에서 재개했다. 기존 await 직후 `mounted`를 확인하도록 Native·Web을 수정했다. 이미 시작한 Future의 완료·오류, mounted 상태의 두 callback·동일 child는 유지한다. Web `ScrollableClient`는 초기 측정 microtask가 id·geometry를 읽기 전에 소유자 수명을 확인한다.

원본 재현·화면 기준은 `98d052061b`, 검증 코드 커밋은 `b121bf0acc0f93db5a30aff2034a3b3a23dc3039`이며 base는 `b7567dd036`이다. 두 커밋 사이의 upstream 문서·StarRating·Stepper·Menubar 변경은 보존했다. 대상 제품 세 파일은 원본 재현과 최신 base에서 byte 동일했다. 이 PR의 공개 API·Core·DOM 구조·스타일·기본값·기준 이미지 변경은 없다. 수정 파일의 기존 린트도 주석·타입 표현·무효 변환·Future 반환 표현만 정리했다.

| 실제 검증 | 결과 |
|---|---|
| Native 원본 external fixture4 | 원본3PASS/1FAIL → 같은 fixture4PASS |
| Native 저장소 이식4 + 기존17 | 21PASS; 이식4는 같은 논리4를 재실행 |
| Core RefreshTriggerStyle | 19PASS |
| Ego Lite live native Node7 | 원본5PASS/2FAIL → 같은7PASS |
| Web 관련 unit | 33PASS; Core19는 Native에서도 별도 실행 |
| Web SSR / O2 client compile | 2PASS / 두 compile exit0 |
| format / fatal-infos | 변경10파일 format0; 제품·테스트 해당 범위 모두 fatal0 |
| 실제 docs build | exit0, 103.35s; SSR366경로·Jaspr368 HTML+Flutter2 |
| 소유 SSR VM reload | 대상 Web 라이브러리2 로드, reloadSources 성공, 전후 HTTP200 |

Scroll 원본은 A를 실제 제거한 뒤 같은 public id의 다른 B를 올렸으며 id 중복이 없다. B의 최종 offset45/65는 원본에서도 정상이고, 수정한 결함은 이전 A의 지연 callback 오류다. 후보는 오류0과 B의 nonzero240×120 geometry·offset·State/DOM/child 유지를 함께 확인했다.

실제 manifest ALL18에서 default4를 도출해 Native·Ego 각각 수정 전후4개씩 새 촬영했다. 플랫폼별 PNG8장이 전후 byte 동일하다. Native JSON4와 Web rect·clip·root HTML도 동일하다. 실제 정본 pixel report의 cross-platform4칸은 PASS다. 저장된 own-baseline 비교는 원본·후보 모두 Native4PASS/Web4FAIL(exit1)이며 기준8개 Git blob·임계·allowlist를 유지했다. 전후 같은 실패를 통과로 바꾸지 않았다.

Web 화면 제어는 native Ego Lite Chromium156, 800×1200/DPR1에서 기존 정본 SSR HTML·폰트·아이콘·freeze·box-root probe로 촬영했다. 소프트웨어 래스터는 확인하지 않았고 computed-property는 수집하지 않았다. 기존 Chrome150 전체 측정과 별개다. live O2 lifecycle7은 native Ego Node로 실행했으며 Dart Puppeteer driver 실행으로 쓰지 않는다. SSR VM reload도 browser client·Native hot reload를 뜻하지 않는다.

빌드 전후 추적25013파일, 실제232개 패키지의 버전·유효 경로·languageVersion/packageUri·graph·lock을 확인했다. 자동 root/example Pub preflight를 관찰했으며 config URI 표기19개만 달라졌다. 전체 빌드는 회수하고 해시 목록과 대표 HTML3개만 보존했다. 소유 서버·포트·jobbox는 모두 종료·회수했다.

완료 범위는 두 lifecycle 결함이다. #6131 전체834칸의 현재 main 재측정으로 부르지 않는다. 전체606PASS/228FAIL 수치는 b2a4/Chrome150의 과거 측정이다.

내구 증빙 루트: `/Users/minhyeok/orca/artifacts/coui/weever-deferred-owner-lifetime-1h6akysa`. [verification.json](verification.json)의 실제 결과·26개 참조와 SHA를 확인한다. verification JSON SHA256: `aea44ab5641aca01732c3dc444bbc2ba4f264f1e1bcc586ed9bb289a4d425b75`.
