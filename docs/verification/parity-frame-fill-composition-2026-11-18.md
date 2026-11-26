# Frame fill 합성 복구 (#6431)

Web Frame에서 그라디언트가 없을 때 이미지 아래의 caller 색을 보존하고, 이미지와 그라디언트를 함께 받으면 이미지를 앞층에 유지하도록 수정했다. 기존 Native처럼 그라디언트가 있으면 solid 색은 제외한다. 세 입력을 새3층 정책으로 바꾸지 않았으며 공개 API·Core/Native·디자인 기본값·토큰·caller CSS 우선순위는 그대로다. CSS 값의 쉼표를 파싱하지 않고 typed 이미지 목록과 층별 size/position/repeat를 조합한다.

제품/테스트 `cadd3d1287b9bff7d3869a5ec71eecc8fa131543`에서 검증했고, latest main1b362c9a를 ordinary merge한 최종 실행 소스는 `55573fe8a84865f242b65ba7ac9a65c24f17816e`다. cadd→555의 packages/docs_core/docs_site/lock 차이가 없어 기존 bounded 검증과 문서 빌드를 이 근거로 연결한다. 최종 Web816 전수는 source555로 별도 완료했으며, 이후 문서 커밋을 새 전수 캡처 소스로 표시하지 않는다.

Web Frame54개 테스트(신규16), touched fatal-infos 진단0, format 변경0, full contract guard exit0, 새 Jaspr O2 문서359페이지 빌드가 통과했다. 실제 반투명 이미지+색 및 이미지+반투명 그라디언트의 선정 라이트/다크 원본은 Native/Web RGBA exact다. 실제 SSR Dart VM reload와 전후 렌더도 성공했다.

공식 `captureWebEntry`에서 별도로 캡처한 기본 Frame8은 기존 source421 canonical 원본과 PNG bytes·RGBA·computed byRole·captureContext가 모두 exact다. 탐색용 mixed grid의 gradient278px 및 elevated18/15px 최대채널1 차이는 원본 그대로 남겼으며, grid 자체는 strict6/8이다. 이를 임계값 완화나 입증되지 않은 AA 설명으로 통과 처리하지 않았다.

Grid는 canonical reset이 없어 border/padding의 Native 부모 문맥과 다르므로 해당 이미지를 Native 테두리 일치 근거로 쓰지 않는다. 기존 작은 이미지 scaleDown→contain 및 RTL 해석 차이도 수정하지 않았다. 기존174/234칸 직접 감소를 주장하지 않는다. 상세 원본·한계·재현 명령·정리 증빙은 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6431-frame-fill-proof-20261118.je5gv4km/README.md`, 기계 요약은 같은 디렉터리 `validation-summary.json`, 원본8장 선정은 `selected-evidence8.json`이다.

최종 통합555에서 Web816을 모두 새 촬영했다(첫816/816·실패0/retry0·402.677초). Native816은 실제309 캡처를1990파일동일closure/232package tuple·lock근거로명시재사용했다. 제품5831파일SHA/mode·패키지설정불변과docs-only17f801이후변경을구분했다. 최종raw는JSON1632+PNG1656=3288/누락0이며, 이전fresh421대비Web828PNG·모든byRole속성·bodyBounds·판정변화0이다. Root도원본JSON/PNG/두공식리포트를독립확인했다.

| 최종 default816 matrix keys | pass | fail | infra | structural skip |
|---|---:|---:|---:|---:|
| pixel |582|234|0|0|
| property |402|368|0|46|

두report exit1을보존한다. 임계값/필터/skip/baseline/원문/비교기는유지했고전체3814스타일·모든control·전체수동CI·배포·FigmaGenerate완료를주장하지않는다. 실제최종전수와원본421보존·소유실행폐쇄증빙은 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6431-integrated-matrix-20261118.ijmvb_uw` 및 같은 이름JSON에연결했다.
