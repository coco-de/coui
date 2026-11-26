# #5526 입력 포커스 테두리 소비 복구

TextField의 raw focusBorderColor와 TextArea의 focusBorderColor가 실제 테두리에 닿지 않았다. 원본 공개24의 enabled20 중18은 요청한 focused stroke와 달랐다. 폭1/active1인 TextArea 두 owner도 실패하므로 추가 shadow가 원인을 가린 결과가 아니다.

## 계약과 변경

Core의 focusBorderColor는 focused border stroke다. Native 원본40 공개 입력은 실제 RenderDecoratedBox로 focus > hover/rest와 disabled 우선순위를 확인했다. 최초 observer identity 오류는 보존하며 Native 후보 실행으로 세지 않는다.

실제 wrapper/frame이 기존 --focus-border-color를 읽는다. 일반 raw/transparent는 normal 단일 선언이고, TextField 자신의 resting/error inline border가 경쟁할 때만 전체 :where로 specificity0인 important reader를 쓴다. TextField의 정상 token 경로는 유지하고 TextArea는 caller token을 따른다. Footer frame은 기존 main textarea focus predicate만 사용한다.

이 PR 자체의 공개 API·Core 값·기본 디자인·widget DOM·의존성·probe·comparator·기준 이미지 변경은 없다. 새 marker는 실제 border paint protocol이며 측정용 값 주입이 아니다. mainbb의 별도7경로를 정상 통합한3c2876에서도 대상 source4+test1은5ed와 byte-exact다.

## 실제 검증

- Web 원본00440 → 후보 c6be의 같은 공개64를 before132/after132 상태로 관측했다. 후보64PASS,42cases/44focused states의 stroke가 바뀌었고 resting64 및 다른 paint/geometry는 보존됐다.
- caller18 중14는 동일하다. own inline rest와 경쟁하는 normal/#ID4는 기존 rest 대신 Core focus를 따르도록 정정됐다. 낮은 class specificity important override는 보존됐다.
- 같은 공개4 입력을 재사용한 hover8 executions/24states에서 state control8PASS, focused contract 원본4FAIL → 후보4PASS다. 새8fixture로 합산하지 않는다.
- 새 public SSR42는 c6be+당시 untracked test에서 PASS/fatal0/format0changed였다. 같은 test bytes가5ed35840에 커밋됐다. 최초8 fixture 기대 실패와 기계적 INFO는 보존했다.
- 실제5ed에서 통합23파일344PASS/0FAIL/skip0/load0(83.383007208s), touched5 fatal0/format0다. 새42를 포함하므로386으로 중복 합산하지 않는다. 대상 source5 동일성으로 mainbb 통합3c에 연결하며3c에서 재실행했다고 쓰지 않는다.
- actual TF basic docs scene L/D + TA default L/D4의 원본/후보 PNG·rawJSON은 byte-exact다. mainbb 통합3c에서 canonical4를 다시 촬영한 CLI0/9.957716583s 결과도 기존 후보와 PNG·JSON·Git baseline bytes가 같다.
- 실Git own baseline8rows는 TF4PASS/TA4FAIL이다. TA Light540/Dark523px 차이는 원본/후보에서 같다. channel32/ratio.001·waiver0 그대로이며 compareCLI1/infra0다.
- mainbb 통합3c의 pinned Jaspr CLI build는 새 실행 exit0/113.889727s이며 postchecks 포함123.050212875s와 구분한다. 361/361 routes,365 HTML(Jaspr363/Flutter2),5044 output hashes와 대표 HTML3개를 보존했다. 이전5ed의139.238880250s/187.521156542s 증거는 역사로 남긴다.
- tracked25196의 bytes/mode/link·HEAD/status와 원본232 config/graph/lock bytes는 그대로다. shadow232의 names/roots/edges/lock·13 pubspec·사용 package source256/domain도 같다. registry cache 메타데이터는 변경됐고 자동 fetch는 미측정이므로 cache/network 전체 불변을 주장하지 않는다. worker directPub0이다.
- port62323은 닫혔고 official jobbox520220KB가 procs0/verifyok로 회수됐다. 전체 build/cache 사본은 남기지 않았다. mainbb canonical 결과의4P4F는 입력 bytes 동일성으로 이전 실제 판정을 승계한 것이며 두 번째 comparator CLI 실행은 아니다.

Web browser 관측은 Root의 Managed Ego 실행이다. software raster와 색 차이 원인은 확인되지 않았고 Native 후보·전체행렬 촬영·cross-platform property PASS를 주장하지 않는다. Web alpha .50과 Native128/255는 기존의 서로 다른 경로로 보존한다.

## 남는 범위와 실패 증거

TextArea raw resting border emission과 noFooter disabled tint는 그대로 남는다. focus 소비 복구를 가족 전체·전역 convention 완결로 확장하지 않는다. c6be resolver guard exit0도 baseline 모드의 net-new0이며 기존37항목을 유지한다(로그의 baseline33 표기는 원문 보존).

초기 Web 생성기의 비지원 toARGB32 compile 오류와, 사라진 TF default key를 기대한 preflight는 원문을 보존했다. 원본00440의 actual ALL3932/defaultStyle840에서 VariantRow name=defaultVariant scene을 선택했고 가짜 default key를 만들지 않았다. 이 manifest 생성은 전체 촬영이 아니다.

영구 기록: docs/parity/evidence/5526-focus-border-consumption/{README.md,evidence.json}. 기존 pending 초안은 외부에 별도 보존하고, 이 기록은 완료된 실행만 요약한다.

추가 main1d의 Window·Figma13경로를 정상 통합한 a5a6b6에서도 대상 Dart5는5ed와 같다. 이 소스의 canonical4 새 촬영은 CLI0/9.107693625s이며 PNG·JSON·기준 이미지 bytes가 모두 이전과 같다. 344검사와113.889727s 문서 빌드는 각각5ed와3c의 실제 실행으로 유지한다. 전체 행렬은 a5a6b6의 독립 snapshot에서 별도 수집한다.
