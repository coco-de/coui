# Native Dot 공개 입력 갱신 — #6459

같은 Theme·key·index·length에서 `dotIndicatorStyle`, `size`, `direction`을 바꾸면 부모 배치만 갱신되고 const private marker가 이전 값을 유지하던 결함을 수정했습니다. 부모가 이미 계산한 `ResolvedDotIndicator`와 방향·interactive 값을 기존 private child에 typed field로 전달합니다. 공개 const 생성자·copyWith·스타일 체인, private widget/State/key 및 기존 AnimatedContainer 소유자, callback 분기와 natural-fit helper를 유지합니다. Core·디자인 값·Web·측정 기준은 바꾸지 않았습니다.

검증 제품은 `25b887f566171fe9fed490312cea2985c8ea05b0` (base `cfb09223347ec213891178713a0b29c4bb55fc14`), 제품 SHA256은 `ad6923ec6f5d4e6e41c46740bd7db4eca52e0167690e8401389dc4a3962d1603`입니다. 문서 후속 커밋에서도 제품·테스트는 이 상태를 유지합니다. 명령·예상값·관측값·19개 원본 receipt SHA는 [verification.json](verification.json)에 기록했습니다.

| 검증 | 실제 결과 |
| --- | --- |
| 원본과 byte-exact 동일 재현 fixture | 원본 3실패 + callback 양성1통과 → 수정본4통과 |
| 영구 회귀/기존 집중 검사 | 신규6 + 기존48 =54통과, fatal0, format2파일/변경0 |
| API/소스 경계 | 공개 AST 및 기존 공개 class/style-chain/helper byte exact; export membership Core931/Native1351/Web1296 동일;232 package graph·lock 변경0 |
| required contract guard | exit0; 기존 non-enforced migration warning7개는 그대로 공개 |
| canonical 정적 Native 제어 | fresh cfb의 default/passive/vertical L/D6과 새6의 PNG·JSON 각각 byte exact |
| 실제 live 입력/애니메이션 | 외부 테스트2통과, 원본/수정8PNG, H/V grow/shrink8시퀀스; root와5개 animation State identity 유지 |
| 문서 O2 빌드 |359 route 생성, exit0/111.112초; tracked22601개 변화0/clean |
| 실제 Flutter CLI 앱 | reload0 libraries/42ms; 전후88×24 및 marker5개8×8; exit0, CLI·VM·port 종료 |

영구 motion 회귀는 실제 cross dimension을 누적16/50ms에 읽습니다. 별도 live motion 원본은 누적0/16/50/100ms와 settle을 분리합니다. 기존 기본 duration은200ms라100ms는 중간 프레임입니다. 수정본이8↔12 사이에서 실제 보간되고 현재 child 크기에 따라 max-main88 fallback 또는 natural fit이 선택되는 것을 확인했습니다. 원본은 같은 입력에서 marker가 그대로였습니다. callback null 전환은 기존 private subtree remount를 유지하는 양성 대조군입니다.

선정8장은 **양쪽에 같은 caller 입력 변경을 적용한 뒤**의 원본4/수정4입니다. 빨강·초록·보라는 caller가 지정한 테스트 색이며 새 Core/디자인 값이 아닙니다. style L/D의 실제 root는104×24→128×28, size light는80×24→70×22, axis dark는36×88→24×100입니다. 크기 차이는 입력이 바뀐 결과와 원본 marker의 stale 상태를 보여 줍니다. PNG를 자르거나 편집하지 않았고 cross-platform pixel 일치를 주장하지 않습니다.

범위는 이 입력 갱신 결함입니다. 전체816 재측정·모든 상호작용·전체 문서 hydration/HTTP 런타임 통과를 주장하지 않습니다. CLI는 실제 앱의 정적 reload smoke이며 동적 입력의 증거는 별도 테스트/readback입니다. headless 환경의 기존 `dir_picker`·`file_saver_ffi` symbol 경고는 보존했고 해당 기능을 실행하지 않았습니다. 기존5326/5327 및 capture-origin HOLD는 별개입니다. exported 구현 library bytes는 의도적으로 바뀌며 공개 계약과 export membership을 보존한 것입니다.
