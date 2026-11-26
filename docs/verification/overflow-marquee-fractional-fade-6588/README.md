# OverflowMarquee 소수 fade 길이 보존 — #6588

공개 `CoreOverflowMarqueeStyle.fadePortion`의 double 값이 Web CSS에서 정수로 잘렸습니다. 원본 d91의 공개 SSR은 가로·세로12.5/0.5 네 입력에서 실제 실패했고,12/24 정수 대조군 네 입력은 통과했습니다. [private emitter](../../../packages/coui_web/lib/src/components/layout/overflow_marquee/overflow_marquee_style.dart)는 기존 `<=0` 분기와 `toInt()` 평가를 유지하면서 소수일 때 원래 double을 출력합니다. 기본24px와 정수 문자열, 공개 API·Core·Native·State·DOM·타이밍·토큰은 바꾸지 않았습니다.

첫 코드 ab53과 통합 측정68a108은 별도 출처입니다. 이후705502 통합 HEAD는 **ae63bfee07d2e07b9f0a31be5baf01768ec63cb6**이며 제품·회귀 테스트 두 SHA가 같습니다. 아래 실행을 ae63에서 새로 실행했다고 재표기하지 않습니다. ae63에서도 문서 빌드를 별도로 완료했으며 기능·캡처·보고서의 실제68a108 출처는 유지합니다.

그 뒤 도구 merge8bd17을 정상 통합한 **최종 코드 HEAD는1d91e58f413062259606fe4919e29bcc5c1a5917**입니다. Marquee 제품·테스트2SHA와 tool7파일961SHA는 같지만 Native fold host가 바뀌어 정본 Native L/D2를 새로 촬영했습니다.10.550초/2PASS/2JSON+2PNG/NoRoot·누락0, d91·68a108·b2 각각의4raw와12쌍 모두 byte exact입니다.13개 현재 pubspec과 바뀐 Native 소스를 전후 결속했고, 이전13pubspec이 전부 같다고 주장하지 않습니다. 기존9/17/8 기능 실행과68a108 보고서는 재실행·재라벨하지 않았습니다.

## 기능과 실제 관측

- **68a108 기능:** 원본 불변 외부 SSR9통과, 새 repo12+기존 Web5통과, CoreDuration8통과. 외부와 repo의 소수 네 사례는 중복이므로34개 독립 시나리오로 합산하지 않습니다. touched Dart2개 format/fatal-infos0이며, 실제 발견된 기존 문서·library INFO4개 정리 내역도 보존했습니다.
- **기본값 보존:** null style인 기존 무재정의 기본24와 명시 정수12의 양축 전체 SSR4개가 d91 원본과 byte exact입니다. null 인자를 전달한 것이며 인자를 문법적으로 생략했다는 주장은 아닙니다.
- **Native:** d91의3테스트/11paint 관측은 역사 자료입니다.68a108에서 정본 ALL8/default L/D2를 새로 도출·촬영했고,2JSON+2PNG 모두 d91 및 ab53의 원본과 같습니다. NoRoot·누락0입니다.
- **ab53 live CSS6:** Ego19/p1·Chrome156의 실제 SSR DOM에서 양축12.5/0.5/null의 `mask-image`와 `-webkit-mask-image`를 확인했습니다. 가로 root240×80/track720×80, 세로80×240/80×720로 실제 overflow합니다. 이 관측은 CSS 파싱·bounds 확인이며 fractional mask의 Native↔Web 래스터 일치나 CSR 상호작용 검증이 아닙니다.
- **68a108 정본 Web2:** 제품68a108의 package roots와 도구961170의 물리 CLI/CWD를1899개 동일 입력으로 결속해 default L/D2를 fresh 촬영했습니다.11.746초/exit0,2JSON+2PNG, 기존17필드·initial-frame 정책입니다. 촬영800×1200/DPR1 이후 실제 이전1668×1027/DPR2와 관측 환경을 복구했습니다.
- **SSR reload:**68a108에서 실제 style library를 로드한 소유 VM의 `reloadSources`가 성공했습니다. 전후6개 HTTP200/root1/CSS동일, 전체 HTML은 모두 byte exact가 아닙니다. 서버 SSR reload이며 브라우저 client hot reload로 부르지 않습니다. 소유 포트·프로세스·jobbox는 회수했습니다.

## 정본 보고서 결과

| 68a108 보고서 | 키 판정 | 실제 exit |
| --- | --- | --- |
| 플랫폼 own-baseline pixel | 0P/2F — Native2P, Web2F | 1 |
| Native↔Web pixel | 0P/2F | 1 |
| property | 2P/0F | 0 |
| 역사 b2 원본을 현재 committed baseline에 대조 | 2P/0F, 플랫폼4셀 통과 | 0 |

인프라 실패0입니다. committed baseline8개는 b2와 현재가 같고, 새 Native4raw도 b2와 같습니다. 현재 Ego Chrome156 Web과 역사 Chrome150 pixel 차이의 원인은 확정하지 않았습니다. 이전 Ego before PNG와 동일하다고 주장하지 않으며, 실패를 승인하거나 baseline·allowlist·기준·threshold를 바꾸지 않았습니다. 이 소수 입력 수정으로 역사 full-b2 pixel228이 감소했다고 계산하지 않습니다.

68a108 문서 빌드는 CLI99.806초/exit0,361 routes·363 Jaspr+2 Flutter HTML을 생성했습니다. 출력5044개 해시/대표 HTML3개를 남기고 전체 빌드를 회수했으며, tracked24995개와 실제232 package fields/effective roots·graph·lock을 보존했습니다. CLI 자동 Pub preflight는 관측했고 직접 project Pub 실행은0입니다.

최신 ae63 문서 빌드도 CLI102.083초/exit0,361 routes·363 Jaspr+2 Flutter HTML을 생성했습니다. 출력5044개 해시/대표 HTML3개, tracked25038개 전후 동일 및232 fields/effective roots·graph·lock 동일을 확인했습니다. URI 표기 변화0, CLI 자동 root/example Pub preflight는 관측했고 직접 project Pub 실행은0입니다. 포트와 전체 빌드는 회수했습니다. 이 빌드 결과는68a108 측정을 새 HEAD의 fresh 실행으로 바꾸지 않습니다.

최종1d91 문서 빌드도 CLI110.497초/exit0,361 routes·363 Jaspr+2 Flutter HTML,5044출력 해시/대표 HTML3개를 남겼습니다. tracked25053개와 실제232 fields/effective roots·graph·lock은 동일하고 URI 표기 변화0입니다. 실제 root의 resolve/Got dependencies 및 example preflight 로그를 보존했으며, 직접 project Pub은0입니다. 전체 빌드·포트 회수 및 Native 새 jobbox 회수/metadata EOF를 확인했습니다.

## 증거와 한계

[verification.json](verification.json)에 제품·테스트 SHA, source별 결과와 bundle-relative 증거 경로·SHA256을 기록했습니다. 보존 bundle은 `weever-fade-mask-audit-lb2rdvnk`입니다. 통합 Native 인계 `6d756128…1461b`, 정본 Web 인계 `818e2a4c…68be46`와19ref index `d526b619…a8a0e0`, 보고서 요약 `8aca7648…2e472`를 결속합니다. 원본 PNG는 별도 검토·업로드용이며 Git baseline으로 승격하지 않습니다. Root가 Native/Web L/D 원본4장을 실제 확인했으며, 이 시각 검토로 보고서의 pixel 실패를 면제하지 않습니다.

처음 Native image encoding 정지, 외부 runner·metadata 검증기의 setup 실패, Web snapshot의 quoted-path 실패를 모두 보존했습니다. 제품·assertion·기대값을 바꾸어 통과시키지 않았습니다. **FadeScroll legacy live 경로는 HOLD**이며 SSR emission 대조군 하나로 그 경로가 검증됐다고 하지 않습니다. 이번 문서 작성 중 테스트·브라우저·빌드를 새로 실행하지 않았고 root CHANGELOG도 수정하지 않았습니다.
